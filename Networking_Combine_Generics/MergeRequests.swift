//
//  MergeRequests.swift
//  Networking_Combine_Generics
//
//  Created by Vasileios  Gkreen on 15/11/21.
//

import SwiftUI
import Combine


struct Message: Decodable, Identifiable {
	var id: Int
	var from: String
	var message: String
}

struct MergeRequests: View {
	
	@State private var requests = Set<AnyCancellable>()
	@State private var messages = [Message]()
	@State private var favorites = Set<Int>()
	
	
	func fetch<T: Decodable>(_ url: URL, defaultValue: T, runAtQueue: DispatchQueue = .main, completion: @escaping (T) -> Void) {
		let decoder = JSONDecoder()
		
		URLSession.shared.dataTaskPublisher(for: url)
			.retry(1) // if the request fails retry one more time
			.map(\.data) // get only the data from the response
			.decode(type: T.self, decoder: decoder) // decode data with our decoder top the User struct
			.replaceError(with: defaultValue) // in case of error replace it with our default user
			.receive(on: runAtQueue) // push that data to the main thread if you update UI
			.sink(receiveValue: completion) // return our data
			.store(in: &requests) // and store it otherwise it will be lost
	}
	
	
	
	func fetch2<T: Decodable>(_ url: URL, defaultValue: T, runAtQueue: DispatchQueue = .main) -> AnyPublisher<T, Never> {
		let decoder = JSONDecoder()
		
		return URLSession.shared.dataTaskPublisher(for: url)
			.delay(for: .seconds(Double.random(in: 1...5)), scheduler: RunLoop.main) // introduce a fake delay to simulate calls returning at diferent times
			.retry(1) // if the request fails retry one more time
			.map(\.data) // get only the data from the response
			.decode(type: T.self, decoder: decoder) // decode data with our decoder top the User struct
			.replaceError(with: defaultValue) // in case of error replace it with our default user
			.receive(on: runAtQueue) // push that data to the main thread if you update UI
			.eraseToAnyPublisher() // erases type of specific publisher and sends back a any publisher
	}
	
	
	
	
    var body: some View {
		NavigationView {
			List(messages) { message in
				HStack {
					VStack(alignment: .leading) {
						Text(message.from)
							.font(.headline)
						
						Text(message.message)
							.foregroundColor(.secondary)
					}
					
					if favorites.contains(message.id) {
						Spacer()
						
						Image(systemName: "heart.fill")
							.foregroundColor(.red)
					}
				}
			}
			.navigationTitle("Messages")
			.onAppear {
//				let messagesURL = URL(string: "https://www.hackingwithswift.com/samples/user-messages.json")!
//
//				fetch(messagesURL, defaultValue: [Message]()) {
//					messages = $0
//				}
//
//				DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//					let favoritesURL = URL(string: "https://www.hackingwithswift.com/samples/user-favorites.json")!
//
//					fetch(favoritesURL, defaultValue: Set<Int>()) {
//						favorites = $0
//					}
				
				let messagesURL = URL(string: "https://www.hackingwithswift.com/samples/user-messages.json")!
				let messagesTask = fetch2(messagesURL, defaultValue: [Message]())
				
				let favoritesURL = URL(string: "https://www.hackingwithswift.com/samples/user-favorites.json")!
				let favoritesTask = fetch2(favoritesURL, defaultValue: Set<Int>())
				
				/*
					Zip up together multiple requests as long as they have the same error type.
					Result: combine will wait for the requests to finish and only then will send back the results.
				*/
				let combined = Publishers.Zip(messagesTask, favoritesTask)
				combined.sink { loadedMessages, loadedFavorites in
					messages = loadedMessages
					favorites = loadedFavorites
				}
				.store(in: &requests)
				
			}
		}
    }
}

struct MergeRequests_Previews: PreviewProvider {
    static var previews: some View {
        MergeRequests()
    }
}
