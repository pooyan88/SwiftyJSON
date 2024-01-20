//
//  ViewController.swift
//  Swifty JSON
//
//  Created by Pooyan J on 10/30/1402 AP.
//

import UIKit
import SwiftyJSON
import Alamofire

class ViewController: UIViewController {
    
    struct User {
        let userId: Int
        let id: Int
        let title: String
        let body: String
    }
    
    typealias SuccessBlock = (JSON) -> Void
    typealias ErrorBlock = (Error) -> Void
    
    enum NetworkError: Error {
        case decodingDataCorrupted
        case decodingKeyNotFound
        case decodingValueNotFound
        case decodingTypeMisMatch
        case decodingUnknown
        case noConnection
        case gettingDataError
        case generalDecodingError
    }
    
    
    var successResponse: SuccessBlock!
    var errorResponse: ErrorBlock!
    let url = "https://jsonplaceholder.typicode.com/posts"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toStruct()
    }
}

extension ViewController {
    
    func toStruct() {
        req { json in
            let users = json.arrayValue.map { json in
                return User(
                           userId: json["userId"].intValue,
                           id: json["id"].intValue,
                           title: json["title"].stringValue,
                           body: json["body"].stringValue
                       )
            }
            for user in users {
                print("User ID: \(user.userId), ID: \(user.id), Title: \(user.title), Body: \(user.body)")
            }
        }
    }
    
    func req(completion: @escaping (JSON)-> Void) {
        Task { @MainActor in
            do {
                let response = try await baseRequestAPICall()
                let json = try JSON(data: response)
                completion(json)
            } catch {
                print("shit")
            }
        }
    }
    
     func baseRequestAPICall(shouldShowBackendError: Bool = true) async throws -> Data {
        return await withCheckedContinuation { continuation in
            AF.request(url).validate().responseData { [weak self] response in
                if let data = response.data {
                    continuation.resume(returning: data)
                } else if let errorData = response.error, let error = errorData.errorDescription {
                    self?.handleBaseRequestAPICallError(errorData, response, shouldShowBackendError: shouldShowBackendError)
                    continuation.resume(returning: Data())
                } else {
                    self?.handleBaseRequestAPICallError(.sessionTaskFailed(error: response.error ?? NetworkError.decodingDataCorrupted), response, shouldShowBackendError: shouldShowBackendError)
                    continuation.resume(returning: Data())
                }
                return
        }
    }
}
    
    private func handleBaseRequestAPICallError(_ error: AFError, _ response: AFDataResponse<Data>, shouldShowBackendError: Bool) {
        switch error {
        case .responseSerializationFailed(let reason):
            print("*** Error => responseSerializationFailed => response code: \(response.response?.statusCode.description ?? "?") | ", reason)
        case .serverTrustEvaluationFailed:
            print("*** Certificate Pinning Error => response code:\(response.response?.statusCode.description ?? "?")")
        case .sessionTaskFailed(let error):
            print("*** sessionTaskFailed Error => response code:\(response.response?.statusCode.description ?? "?") | ", error)
        default:
            print("*** other Error => response code:\(response.response?.statusCode.description ?? "?") | ", error)
        }
    }
}
