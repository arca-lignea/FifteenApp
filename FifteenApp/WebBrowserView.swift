import SwiftUI
import WebKit

struct WebBrowserView: View {
    @State private var urlString: String = "https://www.apple.com"
    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @StateObject private var webViewManager = WebViewManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // URL Input Bar
            HStack(spacing: 8) {
                // Back Button
                Button(action: {
                    webViewManager.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoBack)
                .foregroundColor(canGoBack ? .blue : .gray)
                
                // Forward Button
                Button(action: {
                    webViewManager.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .disabled(!canGoForward)
                .foregroundColor(canGoForward ? .blue : .gray)
                
                // URL TextField
                TextField("Enter URL", text: $urlString, onCommit: {
                    loadURL()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
                .autocapitalization(.none)
                
                // Reload Button
                Button(action: {
                    webViewManager.reload()
                }) {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.blue)
            }
            .padding(12)
            .background(Color(.systemGray6))
            
            // Web View
            WebView(
                manager: webViewManager,
                urlString: $urlString,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward
            )
        }
        .onAppear {
            loadURL()
        }
    }
    
    private func loadURL() {
        var urlToLoad = urlString.trimmingCharacters(in: .whitespaces)
        
        // Add scheme if missing
        if !urlToLoad.lowercased().hasPrefix("http://") &&
           !urlToLoad.lowercased().hasPrefix("https://") {
            urlToLoad = "https://" + urlToLoad
        }
        
        webViewManager.load(urlString: urlToLoad)
    }
}

// MARK: - WebView (UIViewRepresentable)
struct WebView: UIViewRepresentable {
    let manager: WebViewManager
    @Binding var urlString: String
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        manager.webView = webView
        
        // Load initial URL
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update handled through manager
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            isLoading: $isLoading,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward
        )
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var canGoBack: Bool
        @Binding var canGoForward: Bool
        
        init(isLoading: Binding<Bool>, canGoBack: Binding<Bool>, canGoForward: Binding<Bool>) {
            self._isLoading = isLoading
            self._canGoBack = canGoBack
            self._canGoForward = canGoForward
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = false
                self.canGoBack = webView.canGoBack
                self.canGoForward = webView.canGoForward
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

// MARK: - WebViewManager (ObservableObject)
class WebViewManager: NSObject, ObservableObject {
    var webView: WKWebView?
    
    func load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    func reload() {
        webView?.reload()
    }
    
    func goBack() {
        if webView?.canGoBack ?? false {
            webView?.goBack()
        }
    }
    
    func goForward() {
        if webView?.canGoForward ?? false {
            webView?.goForward()
        }
    }
    
    func stop() {
        webView?.stopLoading()
    }
}

// MARK: - Preview
struct WebBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        WebBrowserView()
    }
}
