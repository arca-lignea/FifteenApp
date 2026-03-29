import SwiftUI
import WebKit

struct WebBrowserView2: View {
    @State private var urlString: String = "https://www.apple.com"
    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var showBookmarks = false
    @StateObject private var webViewManager = WebViewManager2()
    @StateObject private var bookmarkManager = BookmarkManager()
    
    var body: some View {
        ZStack {
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
                    
                    // Bookmark Button
                    Button(action: {
                        bookmarkManager.toggleBookmark(url: urlString, title: webViewManager.pageTitle)
                    }) {
                        Image(systemName: bookmarkManager.isBookmarked(url: urlString) ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(bookmarkManager.isBookmarked(url: urlString) ? .orange : .gray)
                    
                    // Show Bookmarks Button
                    Button(action: {
                        showBookmarks.toggle()
                    }) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
                .padding(12)
                .background(Color(.systemGray6))
                
                // Web View
                WebView2(
                    manager: webViewManager,
                    urlString: $urlString,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward
                )
            }
            
            // Bookmarks Sidebar
            if showBookmarks {
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Bookmarks")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                showBookmarks = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        
                        if bookmarkManager.bookmarks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "star.slash")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                                Text("No Bookmarks Yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                        } else {
                            List {
                                ForEach(bookmarkManager.bookmarks) { bookmark in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bookmark.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(bookmark.url)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    .onTapGesture {
                                        urlString = bookmark.url
                                        loadURL()
                                        showBookmarks = false
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            UIPasteboard.general.string = bookmark.url
                                        }) {
                                            Label("Copy URL", systemImage: "doc.on.doc")
                                        }
                                        
                                        Button(action: {
                                            bookmarkManager.removeBookmark(url: bookmark.url)
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .background(Color(.systemBackground))
                        }
                    }
                    .frame(width: 280)
                    .background(Color(.systemBackground))
                    .shadow(radius: 5)
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
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
        
        urlString = urlToLoad
        webViewManager.load(urlString: urlToLoad)
    }
}

// MARK: - Bookmark Model
struct Bookmark: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let dateAdded: Date
    
    init(title: String, url: String) {
        self.id = UUID()
        self.title = title.isEmpty ? url : title
        self.url = url
        self.dateAdded = Date()
    }
}

// MARK: - BookmarkManager
class BookmarkManager: NSObject, ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    
    private let bookmarksKey = "SavedBookmarks"
    
    override init() {
        super.init()
        loadBookmarks()
    }
    
    func toggleBookmark(url: String, title: String = "") {
        if isBookmarked(url: url) {
            removeBookmark(url: url)
        } else {
            addBookmark(title: title, url: url)
        }
    }
    
    func addBookmark(title: String, url: String) {
        let cleanURL = url.trimmingCharacters(in: .whitespaces)
        
        // Check if already bookmarked
        if bookmarks.contains(where: { $0.url == cleanURL }) {
            return
        }
        
        let bookmark = Bookmark(title: title, url: cleanURL)
        bookmarks.append(bookmark)
        bookmarks.sort { $0.dateAdded > $1.dateAdded }
        saveBookmarks()
    }
    
    func removeBookmark(url: String) {
        bookmarks.removeAll { $0.url == url }
        saveBookmarks()
    }
    
    func isBookmarked(url: String) -> Bool {
        let cleanURL = url.trimmingCharacters(in: .whitespaces)
        return bookmarks.contains { $0.url == cleanURL }
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: bookmarksKey)
        }
    }
    
    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            self.bookmarks = decoded
        }
    }
}

// MARK: - WebView (UIViewRepresentable)
struct WebView2: UIViewRepresentable {
    let manager: WebViewManager2
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
            manager: manager,
            isLoading: $isLoading,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward
        )
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let manager: WebViewManager2
        @Binding var isLoading: Bool
        @Binding var canGoBack: Bool
        @Binding var canGoForward: Bool
        
        init(manager: WebViewManager2, isLoading: Binding<Bool>, canGoBack: Binding<Bool>, canGoForward: Binding<Bool>) {
            self.manager = manager
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
                self.manager.pageTitle = webView.title ?? webView.url?.host ?? ""
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
class WebViewManager2: NSObject, ObservableObject {
    var webView: WKWebView?
    @Published var pageTitle: String = ""
    
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
struct WebBrowserView_Previews2: PreviewProvider {
    static var previews: some View {
        WebBrowserView2()
    }
}
