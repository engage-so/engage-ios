//
//  Engage.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation
import FirebaseMessaging

public final class Engage: EngageProtocol {
    static public let shared = Engage()
    
    private func userId(uid: String?) -> String {
        let id = uid ?? UserDefaults.standard.value(forKey: Constants.uid) as? String
        guard id != nil else {
            let anonymous = UUID().uuidString
            UserDefaults.standard.setValue(anonymous, forKey: Constants.uid)
            return anonymous
        }
        return id!
    }
    
    
    public func initialize(publicKey: String) -> Engage {
        UserDefaults.standard.setValue(publicKey, forKey: Constants.publicKey)
        NotificationService.shared.initialise()
        
        return .shared
    }
    
    public func identify(uid: String, properties: [String : Any]) async {
        let id = UserDefaults.standard.value(forKey: Constants.uid) as? String
        if id != nil && id != uid {
            await merge(source: id!, destination: uid)
        }
        
        UserDefaults.standard.setValue(uid, forKey: Constants.uid)
        
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
        
        let _ = try? await Network.shared.request(.identify(uid: uid, data: data.toData))
        guard UserDefaults.standard.value(forKey: Constants.hasUsageActivity) as? Bool ?? false else {
            UserDefaults.standard.setValue(true, forKey: Constants.hasUsageActivity)
            return
        }
        
        let token = await Messaging.messaging().getToken()
        if token != nil {
            await self.setDeviceToken(deviceToken: token!)
        }
    }
    
    public func setDeviceToken(deviceToken: String, uid: String? = nil) async {
        UserDefaults.standard.setValue(deviceToken, forKey: Constants.deviceToken)
        
        let uid = userId(uid: uid)
        let data: [String : Any] = ["device_token": deviceToken, "device_platform": "ios", "app_version": Bundle.version, "app_build": Bundle.build, "app_last_active": Date()]
        
        let _ = try? await Network.shared.request(.setDeviceToken(uid: uid, data: data.toData))
        guard UserDefaults.standard.value(forKey: Constants.hasUsageActivity) as? Bool ?? false else {
            UserDefaults.standard.setValue(true, forKey: Constants.hasUsageActivity)
            return
        }
    }
    
    public func logout(deviceToken: String? = nil, uid: String? = nil) async {
        let uid = userId(uid: uid)
        let token = deviceToken ?? UserDefaults.standard.value(forKey: Constants.deviceToken) as? String ?? ""
        
        let _ = try? await Network.shared.request(.logout(uid: uid, deviceToken: token))
    }
    
    public func addToAccount(aid: String, role: String? = nil, uid: String? = nil) async {
        let uid = userId(uid: uid)
        var account: [String : Any] = ["id": aid]
        if role != nil {
            account["role"] = role
        }
        let accounts = [account]
        let data: [String : Any] = ["accounts": accounts]
        let _ = try? await Network.shared.request(.addToAccount(uid: uid, data: data.toData))
    }
    
    public func addAttributes(properties: [String : Any], uid: String? = nil) async {
        let uid = userId(uid: uid)
        await identify(uid: uid, properties: properties)
    }
    
    public func removeFromAccount(aid: String, uid: String? = nil) async {
        let uid = userId(uid: uid)
        let _ = try? await Network.shared.request(.removeFromAccount(uid: uid, aid: aid))
    }
    
    public func changeAccountRole(aid: String, role: String, uid: String? = nil) async {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["role": role]
        let _ = try? await Network.shared.request(.changeAccountRole(uid: uid, aid: aid, data: data.toData))
    }
    
    public func convertToCustomer(uid: String? = nil) async {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["type": "customer"]
        let _ = try? await Network.shared.request(.convertToCustomer(uid: uid, data: data.toData))
    }
    
    public func convertToAccount(uid: String? = nil) async {
        let uid = userId(uid: uid)
        let data: [String : Any] = ["type": "account"]
        let _ = try? await Network.shared.request(.convertToCustomer(uid: uid, data: data.toData))
    }
    
    public func merge(source: String, destination: String) async {
        let data: [String : Any] = ["source": source, "destination": destination]
        let _ = try? await Network.shared.request(.merge(data: data.toData))
    }
    
    public func track(event: String, value: Any? = nil, date: Date? = nil, uid: String? = nil) async {
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
        let _ = try? await Network.shared.request(.track(uid: uid, data: data.toData))
        guard UserDefaults.standard.value(forKey: Constants.hasUsageActivity) as? Bool ?? false else {
            UserDefaults.standard.setValue(true, forKey: Constants.hasUsageActivity)
            return
        }
    }
    
    public func onMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        NotificationHandler.shared.setOnMessageOpened(handler)
    }
    
    public func onMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        NotificationHandler.shared.setOnMessageReceived(handler)
    }
    
    public func showDialog(isCarousel: Bool) {
        DialogHandler.shared.showDialog(isCarousel: isCarousel)
    }
    
    public func openChat(uid: String) {
        DialogHandler.shared.openChat(uid: uid)
    }
}

extension Messaging {
    func getToken() async -> String? {
        try? await withCheckedThrowingContinuation { continuation in
            self.token { token, error in
                if let error = error {
                    continuation.resume(returning: nil)
                    return
                }
                guard let token = token else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }
}
