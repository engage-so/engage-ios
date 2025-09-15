//
//  HtmlTextView.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 02/09/2025.
//

import SwiftUI

struct HtmlTextView: View {
    let text: String
    let isHtml: Bool
    
    init(text: String) {
        self.text = text
        // Check for HTML tags using NSRegularExpression
        let regex = try? NSRegularExpression(pattern: "<[a-zA-Z][^>]*>")
        self.isHtml = regex?.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) != nil
    }
    
    var body: some View {
        if isHtml {
            Text(.init(text.htmlToMarkDown()))
        } else {
            Text(text)
        }
    }
}

extension String {
    func htmlToMarkDown() -> String {
        var text = self
        var loop = true
        
        // Replace line feeds with nothing, which is how HTML notation is read in browsers
        text = text.replacingOccurrences(of: "\n", with: "")
        
        text = text.replacingOccurrences(of: "<html>", with: "")
        text = text.replacingOccurrences(of: "</html>", with: "")
        text = text.replacingOccurrences(of: "<head>", with: "")
        text = text.replacingOccurrences(of: "</head>", with: "")
        text = text.replacingOccurrences(of: "<body>", with: "")
        text = text.replacingOccurrences(of: "</body>", with: "")
        text = text.replacingOccurrences(of: "<p>", with: "")
        text = text.replacingOccurrences(of: "</p>", with: "")
        
        // Line breaks
        text = text.replacingOccurrences(of: "<div>", with: "\n")
        text = text.replacingOccurrences(of: "</div>", with: "")
        text = text.replacingOccurrences(of: "<br>", with: "\n")
        
        // Text formatting
        text = text.replacingOccurrences(of: "<strong>", with: "**")
        text = text.replacingOccurrences(of: "</strong>", with: "**")
        text = text.replacingOccurrences(of: "<b>", with: "**")
        text = text.replacingOccurrences(of: "</b>", with: "**")
        text = text.replacingOccurrences(of: "<em>", with: "*")
        text = text.replacingOccurrences(of: "</em>", with: "*")
        text = text.replacingOccurrences(of: "<i>", with: "*")
        text = text.replacingOccurrences(of: "</i>", with: "*")
        
        // Replace hyperlinks block
        loop = true
        while loop {
            let hyperlinkPattern = "<a[\\s\\S]*?href\\s*=\\s*\"([^\"]+)\"[\\s\\S]*?>([\\s\\S]*?)</a>"
            do {
                let regex = try NSRegularExpression(pattern: hyperlinkPattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let fullMatchRange = Range(match.range, in: text)!
                    let hrefRange = Range(match.range(at: 1), in: text)!
                    let contentRange = Range(match.range(at: 2), in: text)!
                    
                    let href = String(text[hrefRange])
                    let content = String(text[contentRange])
                    let markDownLink = "[\(content)](\(href))"
                    text = text.replacingCharacters(in: fullMatchRange, with: markDownLink)
                } else {
                    loop = false
                }
            } catch {
                print("Error with hyperlink regex: \(error)")
                loop = false
            }
        }
        
        return text
    }
}


extension Text {
    init(_ astring: NSAttributedString) {
        self.init("")
        
        astring.enumerateAttributes(in: NSRange(location: 0, length: astring.length), options: []) { (attrs, range, _) in
            
            var t = Text(astring.attributedSubstring(from: range).string)
            
            if let color = attrs[NSAttributedString.Key.foregroundColor] as? UIColor {
                t  = t.foregroundColor(Color(color))
            }
            
            if let font = attrs[NSAttributedString.Key.font] as? UIFont {
                t  = t.font(.init(font))
            }
            
            if let kern = attrs[NSAttributedString.Key.kern] as? CGFloat {
                t  = t.kerning(kern)
            }
            
            
            if let striked = attrs[NSAttributedString.Key.strikethroughStyle] as? NSNumber, striked != 0 {
                if let strikeColor = (attrs[NSAttributedString.Key.strikethroughColor] as? UIColor) {
                    t = t.strikethrough(true, color: Color(strikeColor))
                } else {
                    t = t.strikethrough(true)
                }
            }
            
            if let underline = attrs[NSAttributedString.Key.underlineStyle] as? NSNumber, underline != 0 {
                if let underlineColor = (attrs[NSAttributedString.Key.underlineColor] as? UIColor) {
                    t = t.underline(true, color: Color(underlineColor))
                } else {
                    t = t.underline(true)
                }
            }
            
            if let link = attrs[NSAttributedString.Key.link] as? NSString {
                if let underlineColor = (attrs[NSAttributedString.Key.underlineColor] as? UIColor) {
                    t = t.underline(true, color: Color(underlineColor))
                } else {
                    t = t.underline(true)
                }
            }
            
            self = self + t
            
        }
    }
}
