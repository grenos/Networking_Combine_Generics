//
//  FetchData.swift
//  Networking_Combine_Generics
//
//  Created by Vasileios  Gkreen on 14/11/21.
//

import SwiftUI
import Combine

struct User: Decodable {
	var id: UUID
	var name: String
	
	// decalre a default value in case the api doesn't return any results
	static let `dfault` = User(id: UUID(), name: "Anonymous")
}


struct FetchData: View {
	
	@State private var requests = Set<AnyCancellable>()
	
	var body: some View {
		Button("Fetch Data") {
			let url = URL(string: "https://www.hackingwithswift.com/samples/user-24601.json")
			fetch(url!, defaultValue: User.dfault, runAtQueue: .global(qos: .userInitiated) ) {
				print($0.name)
			}
		}
		.padding()
	}
	
	
	//	MARK: Using data task
	//	func fetch(_ url: URL) {
	//		URLSession.shared.dataTask(with: url) { data, response, error in
	//			if let error = error {
	//				print(User.dfault.name)
	//			} else if let data = data {
	//				let decoder = JSONDecoder()
	//
	//				do {
	//					let user = try decoder.decode(User.self, from: data)
	//					print(user.name)
	//				} catch {
	//					print("Error Decoding User data")
	//				}
	//			}
	//		}.resume()
	//	}
	
	
	//	MARK: Using Combine
	//	func fetch(_ url: URL) {
	//		let decoder = JSONDecoder()
	//
	//		URLSession.shared.dataTaskPublisher(for: url)
	//			.map(\.data) // get only the data from the response
	//			.decode(type: User.self, decoder: decoder) // decode data with our decoder top the User struct
	//			.replaceError(with: User.dfault) // in case of error replace it with our default user
	//			.sink(receiveValue: { print($0.name) }) // return our data
	//			.store(in: &requests) // and store it otherwise it will be lost
	//	}
	

		
	//	MARK: Using Combine AND Generics
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
	
	
	
}

struct FetchData_Previews: PreviewProvider {
	static var previews: some View {
		FetchData()
	}
}
