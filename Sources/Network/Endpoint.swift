//
//  Endpoint.swift
//  
//
//  Created by Ifeanyi Onuoha on 28/03/2024.
//

import SwiftUI

enum Endpoint {
    case identify(uid: String, data: Data?)
    case setDeviceToken(uid: String, data: Data?)
    case logout(uid: String, deviceToken: String)
    case addToAccount(uid: String, data: Data?)
    case removeFromAccount(uid: String, aid: String)
    case changeAccountRole(uid: String, aid: String, data: Data?)
    case convertToCustomer(uid: String, data: Data?)
    case convertToAccount(uid: String, data: Data?)
    case merge(data: Data?)
    case track(uid: String, data: Data?)
}

extension Endpoint {
    var host: String {
        "api.engage.so/v1"
    }
    
    var path: String {
        switch self {
        case .identify(let uid, _):
            return "/users/\(uid)"
        case .setDeviceToken(let uid, _):
            return "/users/\(uid)"
        case .logout(let uid, let deviceToken):
            return "/users/\(uid)/tokens/\(deviceToken)"
        case .addToAccount(let uid, _):
            return "/users/\(uid)/accounts"
        case .removeFromAccount(let uid, let aid):
            return "/users/\(uid)/accounts/\(aid)"
        case .changeAccountRole(let uid, let aid, _):
            return "/users/\(uid)/accounts/\(aid)"
        case .convertToCustomer(let uid, _):
            return "/users/\(uid)/convert"
        case .convertToAccount(let uid, _):
            return "/users/\(uid)/convert"
        case .merge(_):
            return "/users/merge"
        case .track(let uid, _):
            return "/users/\(uid)/events"
        }
    }
    
    var queryItems: [String: String] {
        switch self {
        default:
            return [:]
        }
    }
}

extension Endpoint {
    enum MethodType {
        case get
        case put(data: Data?)
        case post(data: Data?)
        case delete
    }
}


extension Endpoint {
    var url: URL? {
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        urlComponent.host = host
        urlComponent.path = path
        
        if !queryItems.isEmpty {
            urlComponent.queryItems = queryItems.compactMap { item in
                URLQueryItem(name: item.key, value: item.value)
            }
        }
        
        return urlComponent.url
    }
    
    var type: MethodType {
        switch self {
        case .identify(_, let data):
            return .put(data: data)
        case .setDeviceToken(_, let data):
            return .put(data: data)
        case .logout(_, _):
            return .delete
        case .addToAccount(_, let data):
            return .post(data: data)
        case .removeFromAccount(_, _):
            return .delete
        case .changeAccountRole(_, _, let data):
            return .put(data: data)
        case .convertToCustomer(_, let data):
            return .post(data: data)
        case .convertToAccount(_, let data):
            return .post(data: data)
        case .merge(let data):
            return .post(data: data)
        case .track(_, let data):
            return .post(data: data)
        }
    }
    
    var request: URLRequest {
        var request: URLRequest
        
        request = URLRequest(url: url!)
        request.timeoutInterval = 20.0
        
        switch type {
            
        case .get:
            request.httpMethod = "GET"
        case .delete:
            request.httpMethod = "DELETE"
        case .put(let data):
            request.httpMethod = "PUT"
            if let data = data {
                request.httpBody = data
                return request
            }
        case .post(let data):
            request.httpMethod = "POST"
            if let data = data {
                request.httpBody = data
                return request
            }
        }
        
        let publicKey = UserDefaults.value(forKey: "publicKey") ?? ""
        let auth = "\(publicKey)".data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        return request
    }
}
