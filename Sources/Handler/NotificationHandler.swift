//
//  NotificationHandler.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation
import UserNotifications
import UIKit

public final class NotificationHandler: NotificationHandlerProtocol {
    static public let shared = NotificationHandler()
    
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
    
    public func setAPNsToken(_ deviceToken: Data) {
        NotificationService.shared.setAPNsToken(deviceToken)
    }
    
    public func requestNotificationPermission(
        options: UNAuthorizationOptions = [],
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: options, completionHandler: completionHandler)
    }
}
