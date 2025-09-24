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

extension Data {
    var toJSON: String {
        return String(data: self, encoding: .utf8) ?? "Invalid data"
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
    
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
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

extension String {
    func formattedDate(showTime: Bool = true) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: showTime ? .short : .none)
        }
        return ""
    }
    
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
    
    func toSectionDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures consistent month parsing
        return formatter.date(from: self)
    }
}

extension Date {
    func toISO8601String() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self)
    }
}

extension UINavigationController {
  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    navigationBar.topItem?.backButtonDisplayMode = .minimal
  }
}
