//
//  Engage.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

public final class Engage: EngageProtocol {
    static public let shared = Engage()
    
    private func userId(uid: String?) -> String {
        let id = uid ?? UserDefaults.standard.value(forKey: "uid") as? String
        guard id != nil else {
            let anonymous = UUID().uuidString
            UserDefaults.standard.setValue(anonymous, forKey: "uid")
            return anonymous
        }
        return id!
    }
    
    
    public func initialise(publicKey: String) -> Engage {
        UserDefaults.standard.setValue(publicKey, forKey: "publicKey")
        
        return .shared
    }
    
    public func identify(uid: String, properties: [String : Any]) {
        UserDefaults.standard.setValue(uid, forKey: "uid")
        
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
        
        try? Network.shared.request(.identify(uid: uid, data: data.toData))
    }
    
    public func setDeviceToken(deviceToken: String, uid: String? = nil) {
        UserDefaults.standard.setValue(deviceToken, forKey: "deviceToken")
        
        let uid = userId(uid: uid)
        let data: [String : Any] = ["device_token": deviceToken, "device_platform": "ios", "app_version": Bundle.version, "app_build": Bundle.build, "app_last_active": Date()]
        
        try? Network.shared.request(.setDeviceToken(uid: uid, data: data.toData))
    }
    
    public func logout(deviceToken: String? = nil, uid: String? = nil) {
        let uid = userId(uid: uid)
        let token = deviceToken ?? UserDefaults.standard.value(forKey: "deviceToken") as? String ?? ""
        
        try? Network.shared.request(.logout(uid: uid, deviceToken: token))
    }
    
    public func addToAccount(aid: String, role: String? = nil, uid: String? = nil) {
        let uid = userId(uid: uid)
        var account: [String : Any] = ["id": aid]
        if role != nil {
            account["role"] = role
        }
        let accounts = [account]
        let data: [String : Any] = ["accounts": accounts]
        try? Network.shared.request(.addToAccount(uid: uid, data: data.toData))
    }
    
    public func addAttributes(properties: [String : Any], uid: String? = nil) {
        let uid = userId(uid: uid)
        identify(uid: uid, properties: properties)
    }
    
    public func removeFromAccount(aid: String, uid: String? = nil) {
        let uid = userId(uid: uid)
        try? Network.shared.request(.removeFromAccount(uid: uid, aid: aid))
    }
    
    public func changeAccountRole(aid: String, role: String, uid: String? = nil) {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["role": role]
        try? Network.shared.request(.changeAccountRole(uid: uid, aid: aid, data: data.toData))
    }
    
    public func convertToCustomer(uid: String? = nil) {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["type": "customer"]
        try? Network.shared.request(.convertToCustomer(uid: uid, data: data.toData))
    }
    
    public func convertToAccount(uid: String? = nil) {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["type": "account"]
        try? Network.shared.request(.convertToCustomer(uid: uid, data: data.toData))
    }
    
    public func merge(source: String, destination: String) {
        let data: [String : Any] = ["source": source, "destination": destination]
        try? Network.shared.request(.merge(data: data.toData))
    }
    
    public func track(event: String, value: Any? = nil, date: Date? = nil, uid: String? = nil) {
        let uid = userId(uid: uid)
        var data: [String : Any] = [:]
        data["event"] = event
        if (value is Date && date == nil) {
            data["timestamp"] = value
        } else if (value is [String: Any]) {
            data["properties"] = value
        } else if (value != nil) {
            data["value"] = value
        }
        if (date != nil) {
            data["timestamp"] = date
        }
        try? Network.shared.request(.track(uid: uid, data: data.toData))
    }
}
