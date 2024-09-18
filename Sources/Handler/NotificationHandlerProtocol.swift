//
//  NotificationHandlerProtocol.swift
//
//
//  Created by Ifeanyi Onuoha on 16/09/2024.
//

import Foundation

protocol NotificationHandlerProtocol {
    func trackMessageOpened(id: String) -> Void
    func trackMessageDelivered(id: String) -> Void
}
