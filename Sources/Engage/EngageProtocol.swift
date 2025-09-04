//
//  EngageProtocol.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

public protocol EngageProtocol {
    func initialize(publicKey: String) async -> Engage
    func identify(uid: String, properties: [String: Any]) async -> Void
    func setDeviceToken(deviceToken: String, uid: String?) async -> Void
    func logout(deviceToken: String?, uid: String?) async -> Void
    func addToAccount(aid: String, role: String?, uid: String?) async -> Void
    func addAttributes(properties: [String: Any], uid: String?) async -> Void
    func removeFromAccount(aid: String, uid: String?) async -> Void
    func changeAccountRole(aid: String, role: String, uid: String?) async -> Void
    func convertToCustomer(uid: String?) async -> Void
    func convertToAccount(uid: String?) async -> Void
    func merge(source: String, destination: String) async -> Void
    func track(event: String, value: Any?, date: Date?, uid: String?) async -> Void
    func onMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
    func onMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
}
