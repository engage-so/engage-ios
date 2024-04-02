//
//  Extension.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

extension Dictionary {
    var toData: Data? {
        try? JSONSerialization.data(withJSONObject: self)
    }
}

extension Bundle {
    static var version: String {
        let version = main.infoDictionary?["CFBundleShortVersionString"] as? String
        guard version != nil else { return "" }
        return "\(version!)"
    }
    static var build: String {
        let build = main.infoDictionary?["CFBundleVersion"] as? String
        guard build != nil else { return "" }
        return "\(build!)"
    }
}
