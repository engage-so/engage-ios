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
