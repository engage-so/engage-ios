//
//  NotificationHandler.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation

public final class NotificationHandler: NotificationHandlerProtocol {
    static public let shared = NotificationHandler()
    
    func trackMessageOpened(id: String) {
        let data: [String : Any] = ["event": "opened"]
        
        try? Network.shared.request(.trackNotification(id: id, data: data.toData))
    }
    
    func trackMessageDelivered(id: String) {
        let data: [String : Any] = ["event": "delivered"]
        
        try? Network.shared.request(.trackNotification(id: id, data: data.toData))
    }
}
