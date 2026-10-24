import SwiftUI
import WebKit

@main
struct TapCareApp: App {
    var body: some Scene {
        WindowGroup {
            WebView()
                .ignoresSafeArea()   // the page pads itself with the safe-area insets
        }
    }
}

/// The page's own background, so there is no white flash before it loads (matches the light and dark palette).
private let pageBackground = UIColor { trait in
    trait.userInterfaceStyle == .dark
        ? UIColor(red: 0x11 / 255, green: 0x18 / 255, blue: 0x27 / 255, alpha: 1)
        : UIColor(red: 0xF7 / 255, green: 0xF8 / 255, blue: 0xFA / 255, alpha: 1)
}

struct WebView: UIViewRepresentable {
    static let scheme = "tapcare"

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // keeps accounts, readings and settings between launches
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: WebView.scheme)

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = pageBackground
        web.scrollView.backgroundColor = pageBackground
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.allowsLinkPreview = false
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator

        if let url = URL(string: "\(WebView.scheme)://app/index.html") {
            web.load(URLRequest(url: url))
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        /// Pages inside the app stay in the app; links to websites, phone numbers or email open outside.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
                decisionHandler(.allow); return
            }
            if scheme == WebView.scheme || scheme == "about" || scheme == "data" || scheme == "blob" {
                decisionHandler(.allow); return
            }
            if navigationAction.navigationType == .linkActivated || ["tel", "mailto", "sms"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel); return
            }
            decisionHandler(.allow)   // fonts and other page resources
        }

        /// Links that ask for a new window open in Safari.
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url { UIApplication.shared.open(url) }
            return nil
        }
    }
}

/// Serves the bundled web folder from tapcare://app/… so the page has a stable origin
/// (browser storage keeps working across launches).
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    private let root = Bundle.main.url(forResource: "web", withExtension: nil)

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, let root = root else {
            task.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL
        guard file.path.hasPrefix(root.standardizedFileURL.path),
              let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        let types = ["html": "text/html", "js": "text/javascript", "css": "text/css",
                     "png": "image/png", "jpg": "image/jpeg", "svg": "image/svg+xml",
                     "json": "application/json", "woff2": "font/woff2"]
        let mime = types[file.pathExtension.lowercased()] ?? "application/octet-stream"
        let headers = ["Content-Type": mime.hasPrefix("text") ? "\(mime); charset=utf-8" : mime,
                       "Content-Length": "\(data.count)"]
        if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) {
            task.didReceive(response)
        }
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
