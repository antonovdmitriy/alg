//
//  WordExampleWebView.swift
//  Älg
//
//  Created by Dmitrii Antonov on 2025-05-30.
//

import SwiftUI
import WebKit
struct WordExampleWebView: UIViewRepresentable {
    let html: String
    let onWordTapped: (String) -> Void
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, onWordTapped: onWordTapped)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WordExampleWebView
        let onWordTapped: (String) -> Void

        init(parent: WordExampleWebView, onWordTapped: @escaping (String) -> Void) {
            self.parent = parent
            self.onWordTapped = onWordTapped
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.scheme == "app-word" {
                let word = url.host ?? ""
                onWordTapped(word)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { result, error in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.contentHeight = height
                    }
                }
            }
        }
    }
}
