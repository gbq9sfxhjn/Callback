import Foundation
import UIKit

public protocol App {
	var id: String { get }
	var name: String { get }
	var appStoreID: Int { get }
	var documentationURL: URL { get }
}

public struct LaunchResult {
	let query: String
	let queryParams: [URLQueryItem]
	
	public func value(for param: String) -> String? {
		queryParams.first(where: { $0.name == param })?.value
	}
}

public typealias LaunchCallback = (Result<LaunchResult, AppLauncher.Error>) -> Void

public class AppLauncher {
	var completions: [String: LaunchCallback] = [:]
	
	public static var sourceApp = "MyApp"
	public static var callbackURLScheme = "x-cc"
	
	public static let shared = AppLauncher()
	
	fileprivate init() { }
	
	public enum Error: Swift.Error {
		case appNotInstalled
		case couldNotOpenURL
		case wrongParams
		
		/// Returned from external app
		case canceled
		case badCallback(url: URL)
		case appError(code: Int, message: String)
	}
	
	enum CallbackType: String {
		case success = "g"
		case error = "b"
		case cancel = "u"
		
		func callbackURL(uuid: String) -> URL {
			URL(string: "\(AppLauncher.callbackURLScheme)://\(uuid)/\(rawValue)")!
		}
	}
	
	public func launch(url: String, params: [String: Any] = [:]) async throws -> LaunchResult {
		return try await withCheckedThrowingContinuation { continuation in
			let opened = launch(url: url, params: params) { result in
				continuation.resume(with: result)
			}
			if !opened {
				continuation.resume(throwing: AppLauncher.Error.couldNotOpenURL)
			}
		}
	}
	
	public func launch(url: String, params: [String: Any] = [:], completion: LaunchCallback? = nil) -> Bool {
		guard var comps = URLComponents(string: url) else { return false }
		var params = params
		params["x-source"] = AppLauncher.sourceApp
		
		let uuid = "\(UInt64.random(in: .min ... .max))"
		if let completion = completion {
			completions[uuid] = completion
			params["x-success"] = CallbackType.success.callbackURL(uuid: uuid)
			params["x-error"] = CallbackType.error.callbackURL(uuid: uuid)
			params["x-cancel"] = CallbackType.cancel.callbackURL(uuid: uuid)
		}
		
		comps.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
		guard let launchURL = comps.url else { return false }

		print("#### launching launchURL :: \(launchURL)")
		guard UIApplication.shared.canOpenURL(launchURL) else { return false }
		UIApplication.shared.open(launchURL, options: [:]) { success in
			if !success {
				self.completions.removeValue(forKey: uuid)
				completion?(.failure(Error.couldNotOpenURL))
			}
		}
		return true
	}
	
	/// Try to open a callback URL forwarded from app/scene delegate
	/// Returns true if handled by relevant callback
	public func open(callbackURL: URL) -> Bool {
		print("#### open callbackURL :: \(callbackURL)")
		guard let scheme = callbackURL.scheme, scheme == AppLauncher.callbackURLScheme else { return false }
		guard let uuid = callbackURL.host, let completion = completions[uuid] else { return false }
		guard
			callbackURL.pathComponents.count > 1,
			let type = CallbackType(rawValue: callbackURL.pathComponents[1]),
			let comps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
		else {
			completion(.failure(.badCallback(url: callbackURL)))
			return false
		}
		switch type {
		case .success:
			let result = LaunchResult(query: comps.query ?? "", queryParams: comps.queryItems ?? [])
			completion(.success(result))
		case .error:
			completion(.failure(.appError(code: 0, message: "")))
		case .cancel:
			completion(.failure(.canceled))
		}
		completions.removeValue(forKey: uuid)
		return true
	}
}

