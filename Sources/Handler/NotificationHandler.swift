//
//  NotificationHandler.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation

final class NotificationHandler: NotificationHandlerProtocol {
    static let shared = NotificationHandler()
    
    private var onMessageOpened: MessageHandler?
    private var onMessageReceived: MessageHandler?
    
    func trackMessageOpened(userInfo: [AnyHashable : Any]) {
        if let id = userInfo[Constants.messageId] as? String {
            print("Identifier: \(id)")
            let data: [String : Any] = ["event": "opened"]
            
            try? Network.shared.request(.trackNotification(id: id, data: data.toData))
            onMessageOpened?(userInfo)
        }
    }
    
    func trackMessageDelivered(userInfo: [AnyHashable : Any]) {
        if let id = userInfo[Constants.messageId] as? String {
            print("Identifier: \(id)")
            let data: [String : Any] = ["event": "delivered"]
            
            try? Network.shared.request(.trackNotification(id: id, data: data.toData))
            onMessageReceived?(userInfo)
        }
    }
    
    func setOnMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        onMessageOpened = handler
    }
    
    func setOnMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        onMessageReceived = handler
    }
}
