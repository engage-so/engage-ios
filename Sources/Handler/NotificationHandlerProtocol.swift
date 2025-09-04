//
//  NotificationHandlerProtocol.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation
import UserNotifications

public protocol NotificationHandlerProtocol {
    func trackMessageOpened(userInfo: [AnyHashable : Any]) async -> Void
    func trackMessageDelivered(userInfo: [AnyHashable : Any]) async -> Void
    func setOnMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
    func setOnMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
    func setAPNsToken(_ deviceToken: Data) -> Void
    func requestNotificationPermission(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) -> Void
}
