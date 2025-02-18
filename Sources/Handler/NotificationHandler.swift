//
//  NotificationHandler.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation

public final class NotificationHandler: NotificationHandlerProtocol {
    static let shared = NotificationHandler()
    
    private var onMessageOpened: MessageHandler?
    private var onMessageReceived: MessageHandler?
    
    public func trackMessageOpened(userInfo: [AnyHashable : Any]) {
        if let id = userInfo[Constants.messageId] as? String {
            print("Identifier: \(id)")
            let data: [String : Any] = ["event": "opened"]
            
            try? Network.shared.request(.trackNotification(id: id, data: data.toData))
            onMessageOpened?(userInfo)
        }
    }
    
    public func trackMessageDelivered(userInfo: [AnyHashable : Any]) {
        if let id = userInfo[Constants.messageId] as? String {
            print("Identifier: \(id)")
            let data: [String : Any] = ["event": "delivered"]
            
            try? Network.shared.request(.trackNotification(id: id, data: data.toData))
            onMessageReceived?(userInfo)
        }
    }
    
    public func setOnMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        onMessageOpened = handler
    }
    
    public func setOnMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        onMessageReceived = handler
    }
}
