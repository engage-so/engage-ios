//
//  Extension.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

let dateFormatter = ISO8601DateFormatter()

func convertDatesToStrings(_ object: Any) -> Any {
    if let date = object as? Date {
        return dateFormatter.string(from: date)
    } else if let dict = object as? [String: Any] {
        return dict.mapValues { convertDatesToStrings($0) }
    } else if let array = object as? [Any] {
        return array.map { convertDatesToStrings($0) }
    }
    return object
}

extension Dictionary {
    var toData: Data? {
        let jsonWithDatesAsString = convertDatesToStrings(self)
        return try? JSONSerialization.data(withJSONObject: jsonWithDatesAsString)
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
