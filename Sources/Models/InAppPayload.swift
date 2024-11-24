//
//  InAppPayload.swift
//
//
//  Created by Ifeanyi Onuoha on 10/11/2024.
//

import SwiftUI

enum ContentType: String, Codable {
    case text, image, button, row
}

struct InAppPayload: Codable {
    let position: Position
    let background: String
    let closeBtn: Bool?
    let txtColor: String
    let btnColor: String
    let btnTxtColor: String
    let borderRadius: Int? // Inapplicable to carousel
    let vAlign: Align? // Carousel only
    let contents: [[Content]]
    
    var isCarousel: Bool {
        position == .carousel
    }
    
    var radius: CGFloat {
        CGFloat(borderRadius ?? 16)
    }
    
    var backgroundColor: Color {
        Color.fromHex(hex: background)
    }
    
    var textColor: Color {
        Color.fromHex(hex: txtColor)
    }
    
    var buttonColor: Color {
        Color.fromHex(hex: btnColor)
    }
    
    var buttonTextColor: Color {
        Color.fromHex(hex: btnTxtColor)
    }
    
    var alignment: Alignment {
        switch position {
        case .top:
            Alignment.top
        case .bottom:
            Alignment.bottom
        default:
            Alignment.center
        }
    }
}


enum Position: String, Codable {
    case top, bottom, center, carousel
}

enum Align: String, Codable {
    case between, end
}

enum Action: String, Codable {
    case dismiss, permission, intent, url, go
}


struct Content: Codable, Hashable {    
    let type: ContentType
    
    // Properties for Txt type
    let content: String?
    
    // Properties for Image type
    let url: String?
    let width: Int? // Percentage; 100 default
    
    // Properties for Button type
    let borderRadius: Int?
    let buttonWidth: String? // "auto" or percentage as string
    let action: Action?
    let actionObj: String?
    
    // Properties for Row type
    let align: Align?
    let contents: [Content]?
    
    var butonRadius: CGFloat {
        CGFloat(borderRadius ?? 8)
    }
    
    var buttonFillWidth: Bool {
        buttonWidth != "auto"
    }
    
    var buttonMaxWidth: Double {
        if buttonWidth != nil && Double(buttonWidth ?? "100") != nil {
            return Double(buttonWidth ?? "100")! / 100
        }
        return 100
    }
    
    var imageMaxWidth: Double {
        if width != nil {
            return Double(width!) / 100
        }
        return 100
    }
}
