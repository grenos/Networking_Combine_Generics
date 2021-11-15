//
//  PostData.swift
//  Networking_Combine_Generics
//
//  Created by Vasileios  Gkreen on 14/11/21.
//

import SwiftUI
import Combine

struct MovieStar: Codable {
	let name: String
	let movies: [String]
}


enum UploadError: Error {
	case uploadFailed
	case decodeFailed
}

struct PostData: View {
	
	@State private var requests = Set<AnyCancellable>()
	
	var body: some View {
		Button("Send Data") {
			let movies = ["The Lord of the Rings", "Elizabeth"]
			let cate = MovieStar(name: "Cate Blanchett", movies: movies)
			let url = URL(string: "https://reqres.in/api/users")!
			
			self.upload(cate, to: url) { (result: Result<MovieStar, UploadError>) in
				switch result {
					case .success(let star):
						print("Received back \(star.name)")
					case .failure(let error):
						print(error)
						break
				}
			}
		}
		.padding()
	}
	
	
	//MARK: with DataTask
	
	//	func upload(_ data: MovieStar, to url: URL) {
	//		let encoder = JSONEncoder()
	//
	//		var request = URLRequest(url: url)
	//		request.httpMethod = "POST"
	//		request.setValue("application/json", forHTTPHeaderField: "Content-type")
	//		request.httpBody = try? encoder.encode(data)
	//
	//		URLSession.shared.dataTask(with: request) { data, response, error in
	//			if let data = data {
	//				let result = String(decoding: data, as: UTF8.self)
	//				print(result)
	//			} else if let error = error {
	//				print(error.localizedDescription)
	//			} else {
	//				print("Unknown result ... No data and no error")
	//			}
	//		}.resume()
	//
	//	}
	
	
	// MARK: with Generics and Result
	
//	func upload<Input: Encodable, Output: Decodable>(_ data: Input,
//													 to url: URL,
//													 httpMethod: String = "POST",
//													 contentType: String = "application/json",
//													 completion: @escaping (Result<Output, UploadError>) -> Void ) {
//
//		var request = URLRequest(url: url)
//		request.httpMethod = httpMethod
//		request.setValue(contentType, forHTTPHeaderField: "Content-Type")
//
//		let encoder = JSONEncoder()
//		request.httpBody = try? encoder.encode(data)
//
//		URLSession.shared.dataTask(with: request) { data, response, error in
//			DispatchQueue.main.async {
//				if let data = data {
//					do {
//						let decoded = try JSONDecoder().decode(Output.self, from: data)
//						completion(.success(decoded))
//					} catch {
//						completion(.failure(.decodeFailed))
//					}
//				} else if error != nil {
//					completion(.failure(.uploadFailed))
//				} else {
//					print("Unknown result: no data and no error!")
//				}
//			}
//		}.resume()
//	}
	
	
	
	
	func upload<Input: Encodable, Output: Decodable>(_ data: Input,
													 to url: URL,
													 runAtQueue: DispatchQueue = .main,
													 httpMethod: String = "POST",
													 contentType: String = "application/json",
													 completion: @escaping (Result<Output, UploadError>) -> Void ) {
		
		var request = URLRequest(url: url)
		request.httpMethod = httpMethod
		request.setValue(contentType, forHTTPHeaderField: "Content-Type")
		
		let encoder = JSONEncoder()
		request.httpBody = try? encoder.encode(data)
		
		URLSession.shared.dataTaskPublisher(for: request)
			.map(\.data)
			.decode(type: Output.self, decoder: JSONDecoder())
			.map(Result.success)
			.catch { error -> Just<Result<Output, UploadError>> in error is DecodingError // emit a result just once with "Just"
				? Just(.failure(.decodeFailed))
				: Just(.failure(.uploadFailed))
			}
			.receive(on: runAtQueue)
			.sink(receiveValue: completion)
			.store(in: &requests)
	}
	
}

struct PostData_Previews: PreviewProvider {
	static var previews: some View {
		PostData()
	}
}
