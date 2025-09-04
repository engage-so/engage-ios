//
//  HtmlTextView.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 02/09/2025.
//

import SwiftUI
import WebKit

struct HtmlTextView: View {
    let html: String
    let isHtml: Bool
    
    init(html: String) {
        self.html = html
        // Check for HTML tags using NSRegularExpression
        let regex = try? NSRegularExpression(pattern: "<[a-zA-Z][^>]*>")
        self.isHtml = regex?.firstMatch(in: html, range: NSRange(location: 0, length: html.utf16.count)) != nil
    }
    
    var body: some View {
        if isHtml {
            WebView(html: html)
        } else {
            Text(html)
        }
    }
}

struct WebView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Basic CSS to ensure readability and transparent background
        let styledHtml = """
        <html>
        <head>
        <style>
        body { 
            background: transparent; 
            color: \(UIColor.label.hexString); 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 16px;
        }
        a { color: #0000EE; text-decoration: underline; }
        </style>
        </head>
        <body>
        \(html)
        </body>
        </html>
        """
        uiView.loadHTMLString(styledHtml, baseURL: nil)
    }
}

// Extension to get hex color for system label
extension UIColor {
    var hexString: String {
        let components = cgColor.components ?? [0, 0, 0, 1]
        let r = components[0]
        let g = components[1]
        let b = components[2]
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
