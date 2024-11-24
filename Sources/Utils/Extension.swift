//
//  Extension.swift
//
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import SwiftUI

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

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        let alpha: CGFloat = hexSanitized.count == 8 ? CGFloat((rgb & 0xFF000000) >> 24) / 255.0 : 1.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {
   static func fromHex(hex: String) -> Color {
        guard let uiColor = UIColor(hex: hex) else {
            return Color.init(red: 0, green: 0, blue: 0)
        }
        if #available(iOS 15.0, *) {
            return Color(uiColor: uiColor)
        } else {
            return Color(uiColor)
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
