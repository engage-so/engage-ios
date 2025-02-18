//
//  NotificationHandlerProtocol.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation

public protocol NotificationHandlerProtocol {
    func trackMessageOpened(userInfo: [AnyHashable : Any]) -> Void
    func trackMessageDelivered(userInfo: [AnyHashable : Any]) -> Void
    func setOnMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
    func setOnMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
}
