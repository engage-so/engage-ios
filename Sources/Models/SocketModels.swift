//
//  SocketModels.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 20/08/2025.
//

import Foundation

struct MessageModel: Codable, Identifiable {
    let messageId: String
    let from: UserModel
    let body: String
    let uid: String
    let user: String
    let parentId: String
    let date: String
    let lastUpdated: String
    let id: String
    let outbound: Bool
    let read: Bool
    let cid: String
    let status: String?
}

struct ThreadModel: Codable, Identifiable {
    let id: String
    let from: UserModel
    let uid: String
    let excerpt: String
    let inbound: Bool
    let status: String
    let read: [String]
    let date: String
    let lastUpdated: String
}

struct UserModel: Codable {
    var id: String
    var name: String? = nil
    var avatar: String? = nil
    var email: String? = nil
    var identified: Bool = false
}

struct AccountModel: Codable {
    var id: String? = nil
    var features: FeaturesModel? = nil
}

struct FeaturesModel: Codable {
    let help: HelpModel
    let chat: ChatModel
    let widget: WidgetModel
}

struct HelpModel: Codable {
    let site: String
    let defaultLocale: String
    let sk: String
}

struct ChatModel: Codable {
    let title: String
    let subtitle: String
    let welcome: String?
    let ignoreAnonymous: Bool
    let availability: [String]
    let position: String
}

struct WidgetModel: Codable {
    let bgColor: String
    let textColor: String
    let textColorSoft: String
}
