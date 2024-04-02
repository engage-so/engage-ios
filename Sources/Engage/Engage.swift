//
//  Engage.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

final class Engage: EngageProtocol {
    static let shared = Engage()
    
    private func userId(uid: String?) -> String {
        let id = uid ?? UserDefaults.value(forKey: "uid") as? String
        guard id != nil else {
            let anonymous = UUID().uuidString
            UserDefaults.setValue(anonymous, forKey: "uid")
            return anonymous
        }
        return id!
    }
    
    
    func initialise(publicKey: String) async -> Engage {
        UserDefaults.setValue(publicKey, forKey: "publicKey")
        
        return .shared
    }
    
    func identify(uid: String, properties: [String : Any]) async {
        UserDefaults.setValue(uid, forKey: "uid")
        
        var data: [String : Any] = [:]
        var meta: [String : Any] = [:]
        let standardAttributes: [String] = ["is_account", "first_name", "last_name", "email", "number", "created_at", "tz"]
        
        properties.forEach({ key, value in
            if standardAttributes.contains(key) {
                data[key] = value
            } else {
                meta[key] = value
            }
        })
        
        data["meta"] = meta
        
        try? await Network.shared.request(.identify(uid: uid, data: data.toData))
    }
    
    func setDeviceToken(deviceToken: String, uid: String? = nil) async {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["device_token": deviceToken, "device_platform": "iOS", "app_version": Bundle.version, "app_build": Bundle.build]
        
        try? await Network.shared.request(.setDeviceToken(uid: uid, data: data.toData))
    }
    
    func logout(deviceToken: String, uid: String? = nil) async {
        let uid = userId(uid: uid)
        
        try? await Network.shared.request(.logout(uid: uid, deviceToken: deviceToken))
    }
    
    func addToAccount(aid: String, role: String? = nil, uid: String? = nil) async {
        let uid = userId(uid: uid)
        var account: [String : Any] = ["id": aid]
        if role != nil {
            account["role"] = role
        }
        let accounts = [account]
        let data: [String : Any] = ["accounts": accounts]
        try? await Network.shared.request(.addToAccount(uid: uid, data: data.toData))
    }
    
    func addAttributes(properties: [String : Any], uid: String? = nil) async {
        let uid = userId(uid: uid)
        await identify(uid: uid, properties: properties)
    }
    
    func removeFromAccount(aid: String, uid: String? = nil) async {
        let uid = userId(uid: uid)
        try? await Network.shared.request(.removeFromAccount(uid: uid, aid: aid))
    }
    
    func changeAccountRole(aid: String, role: String, uid: String? = nil) async {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["role": role]
        try? await Network.shared.request(.changeAccountRole(uid: uid, aid: aid, data: data.toData))
    }
    
    func convertToCustomer(uid: String? = nil) async {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["type": "customer"]
        try? await Network.shared.request(.convertToCustomer(uid: uid, data: data.toData))
    }
    
    func convertToAccount(uid: String? = nil) async {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["type": "account"]
        try? await Network.shared.request(.convertToCustomer(uid: uid, data: data.toData))
    }
    
    func merge(source: String, destination: String) async {
        let data: [String : Any] = ["source": source, "destination": destination]
        try? await Network.shared.request(.merge(data: data.toData))
    }
    
    func track(event: String, properties: [String : Any]? = nil, uid: String? = nil) async {
        let uid = userId(uid: uid)
        var data: [String : Any] = [:]
        
        data["event"] = event
        data["properties"] = properties
        data["timestamp"] = Date().description
        try? await Network.shared.request(.track(uid: uid, data: data.toData))
    }
}
