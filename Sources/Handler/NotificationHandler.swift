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
    
    func trackMessageOpened(id: String) {
        let data: [String : Any] = ["event": "opened"]
        
        try? Network.shared.request(.trackNotification(id: id, data: data.toData))
        onMessageOpened?(data)
    }
    
    func trackMessageDelivered(id: String) {
        let data: [String : Any] = ["event": "delivered"]
        
        try? Network.shared.request(.trackNotification(id: id, data: data.toData))
        onMessageReceived?(data)
    }
    
    func setOnMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        onMessageOpened = handler
    }
    
    func setOnMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) {
        onMessageReceived = handler
    }
}
