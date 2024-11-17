//
//  EngageProtocol.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

public protocol EngageProtocol {
    func initialise(publicKey: String) async -> Engage
    func identify(uid: String, properties: [String: Any]) -> Void
    func setDeviceToken(deviceToken: String, uid: String?) -> Void
    func logout(deviceToken: String?, uid: String?) -> Void
    func addToAccount(aid: String, role: String?, uid: String?) -> Void
    func addAttributes(properties: [String: Any], uid: String?) -> Void
    func removeFromAccount(aid: String, uid: String?) -> Void
    func changeAccountRole(aid: String, role: String, uid: String?) -> Void
    func convertToCustomer(uid: String?) -> Void
    func convertToAccount(uid: String?) -> Void
    func merge(source: String, destination: String) -> Void
    func track(event: String, value: Any?, date: Date?, uid: String?) -> Void
    func onMessageOpened(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
    func onMessageReceived(_ handler: @escaping ([AnyHashable : Any]) -> Void) -> Void
    func showDialog(isCarousel: Bool) -> Void
}
