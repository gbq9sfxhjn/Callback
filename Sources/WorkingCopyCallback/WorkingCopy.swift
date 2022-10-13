//
//  WorkingCopy.swift
//

import Foundation
import Callback

public enum WorkingCopyError: Error {
	case noURLKey
	case badCallback
}

public class WorkingCopy: App {
	public let id = "working-copy"
	public let name = "Working Copy"
	public let appStoreID = 896694807
	public let documentationURL = URL(string: "https://workingcopyapp.com/url-schemes.html")!
	
	public let urlKey: String
	
	public init(urlKey: String) {
		self.urlKey = urlKey
	}
	
	public struct FileStatus: Decodable {
		/// The filename
		let name: String
		
		/// Relative to the root of the repository
		let path: String
		let status: String  // TODO: enum
		let kind: String
		let size: UInt64
	}
	
	public struct Repository: Decodable {
		let name: String
		let branch: String
		let head: String
		
		let remotes: [RepositoryRemote]?
		let status: String?
	}
	
	public struct RepositoryRemote: Decodable {
		let fetch: Int
		let push: Int
		let name: String
		let url: URL
	}
	
	private func decode<T>(_ type: T.Type, from result: LaunchResult) throws -> T where T: Decodable {
		guard let json = result.value(for: "json"),
			  let jsonData = json.data(using: .utf8),
			  let value = try? JSONDecoder().decode(type, from: jsonData) else {
				  throw WorkingCopyError.badCallback
			  }
		return value
	}
	
	public func filesStatus(
		repositoryName: String,
		path: String? = nil,
		includeUnchanged: Bool = false
	) async throws -> [FileStatus] {
		var params: [String: Any] = [
			"key": urlKey,
			"repo": repositoryName,
		]
		if let path = path {
			params["path"] = path
		}
		if includeUnchanged {
			params["unchanged"] = "1"
		}
		let result = try await AppLauncher.shared.launch(url: "working-copy://x-callback-url/status", params: params)
		return try decode([FileStatus].self, from: result)
	}
	
	public func getRepositories() async throws -> [Repository] {
		let params: [String: Any] = [
			"key": urlKey,
		]
		let result = try await AppLauncher.shared.launch(url: "working-copy://x-callback-url/repos", params: params)
		return try decode([Repository].self, from: result)
	}
	
	// TODO
//	public func readFile(
//		repositoryName: String,
//		path: String
//	) async throws -> Data {
//
//	}
}
