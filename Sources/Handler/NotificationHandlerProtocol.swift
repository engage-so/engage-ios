//
//  NotificationHandlerProtocol.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation

public protocol NotificationHandlerProtocol {
    func trackMessageOpened(id: String) -> Void
    func trackMessageDelivered(id: String) -> Void
}
