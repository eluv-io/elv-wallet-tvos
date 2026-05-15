import SwiftUI
import WebKit

/// SwiftUI wrapper around WKWebView, used by sign-in to load the activation URL.
///
/// Clears cookies + WebKit data on first load so app-level sign-outs aren't
/// silently undone by stale auth-provider cookies (mirrors the Android side).
struct WebView: UIViewRepresentable {
  let url: String

  func makeUIView(context _: Context) -> WKWebView {
    let dataStore = WKWebsiteDataStore.default()
    dataStore.removeData(
      ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
      modifiedSince: .distantPast
    ) {}

    let config = WKWebViewConfiguration()
    config.websiteDataStore = dataStore
    let webView = WKWebView(frame: .zero, configuration: config)

    if let url = URL(string: url) {
      webView.load(URLRequest(url: url))
    }
    return webView
  }

  func updateUIView(_: WKWebView, context _: Context) {}
}
