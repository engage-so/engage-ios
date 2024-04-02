//
//  EngageProtocol.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

protocol EngageProtocol {
    func initialise(publicKey: String) async -> Engage
    func identify(uid: String, properties: [String: Any]) async -> Void
    func setDeviceToken(deviceToken: String, uid: String?) async -> Void
    func logout(deviceToken: String, uid: String?) async -> Void
    func addToAccount(aid: String, role: String?, uid: String?) async -> Void
    func addAttributes(properties: [String: Any], uid: String?) async -> Void
    func removeFromAccount(aid: String, uid: String?) async -> Void
    func changeAccountRole(aid: String, role: String, uid: String?) async -> Void
    func convertToCustomer(uid: String?) async -> Void
    func convertToAccount(uid: String?) async -> Void
    func merge(source: String, destination: String) async -> Void
    func track(event: String, properties: [String: Any]?, uid: String?) async -> Void
}
