//
//  ChainRequests.swift
//  Networking_Combine_Generics
//
//  Created by Vasileios  Gkreen on 15/11/21.
//

import Combine
import SwiftUI

struct NewsItem: Decodable, Identifiable {
	let id: Int
	let title: String
	let strap: String
	let url: URL
	let main_image: String
	let published_date: Date
}

struct ChainRequests: View {
	
	@State private var requests = Set<AnyCancellable>()
	@State private var items = [NewsItem]()
	
	
	func fetch1<T: Decodable>(_ url: URL, defaultValue: T, runAtQueue: DispatchQueue = .main) -> AnyPublisher<T, Never> {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		
		return URLSession.shared.dataTaskPublisher(for: url)
			.retry(1) // if the request fails retry one more time
			.map(\.data) // get only the data from the response
			.decode(type: T.self, decoder: decoder) // decode data with our decoder top the User struct
			.replaceError(with: defaultValue) // in case of error replace it with our default user
			.receive(on: runAtQueue) // push that data to the main thread if you update UI
			.eraseToAnyPublisher() // erases type of specific publisher and sends back a any publisher
	}

	
    var body: some View {
		NavigationView {
			VStack {
				Button("Fetch news") {
					let url = URL(string: "https://www.hackingwithswift.com/samples/news.json")!
					fetch1(url, defaultValue: [URL]())
						.flatMap { urls in
							urls.publisher.flatMap { url in
								fetch1(url, defaultValue: [NewsItem]())
							}
						}
						.collect()
						.sink { values in
							let allItems = values.joined()
							items = allItems.sorted { $0.id > $1.id }
						}
						.store(in: &requests)
				}
				
				List(items) { item in
					VStack(alignment: .leading) {
						Text(item.title)
							.font(.headline)
						Text(item.strap)
							.foregroundColor(.secondary)
					}
				}
				.listStyle(PlainListStyle())
			}
			.navigationTitle("Hacking with Swift")
		}
    }
}

struct ChainRequests_Previews: PreviewProvider {
    static var previews: some View {
        ChainRequests()
    }
}
