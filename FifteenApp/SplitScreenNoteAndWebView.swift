import SwiftUI
import WebKit

struct SplitScreenNoteAndWebView: View {
    let originalNote: RichNote
    @State private var editingNote: RichNote
    @State private var selectedTextBlockId: UUID?
    @State private var editingTextBlockId: UUID?
    @State private var selectedTab: Int = 0
    @State private var webURL: String = "https://www.google.com"
    @State private var isSaving = false
    @State private var showDiscardConfirmation = false
    @State private var urlInput: String = "https://www.google.com"
    @State private var showWebMenu = false
    @State private var showBrowsingHistory = false
    @State private var showURLInputSheet = false
    @State private var browsingHistory: [BrowsingHistoryItem] = []
    @State private var webViewInitialized = false
    @StateObject private var noteManager = RichNoteManager()
    @StateObject private var webViewState = WebViewState()
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(note: RichNote) {
        self.originalNote = note
        self._editingNote = State(initialValue: note)
    }
    
    var hasChanges: Bool {
        let titleChanged = editingNote.title != originalNote.title
        let blockCountChanged = editingNote.blocks.count != originalNote.blocks.count
        let blocksChanged = !blocksAreEqual()
        print("hasChanges \(titleChanged || blockCountChanged || blocksChanged)")
        print("isSaving \(self.isSaving)")
        return titleChanged || blockCountChanged || blocksChanged
    }
    
    private func blocksAreEqual() -> Bool {
        guard editingNote.blocks.count == originalNote.blocks.count else { return false }
        
        for (index, block) in editingNote.blocks.enumerated() {
            if block.id != originalNote.blocks[index].id {
                return false
            }
            if block.type != originalNote.blocks[index].type {
                return false
            }
            if block.content != originalNote.blocks[index].content {
                return false
            }
        }
        
        return true
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            splitScreenLayout.toolbar(.hidden, for: .navigationBar)
        } else {
            stackedLayout.toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Split Screen Layout (iPad/Landscape)
    @ViewBuilder
    private var splitScreenLayout: some View {
        ZStack {
            HStack(spacing: 1) {
                // Left Panel - Text Editor
                VStack(spacing: 0) {
                    editorHeader
                    editorContent
                }
                .background(Color(.systemBackground))
                
                Divider()
                    .frame(width: 1)
                
                // Right Panel - Web Browser
                VStack(spacing: 0) {
                    webBrowserHeader
                    webBrowserContent
                }
                .background(Color(.systemGray6))
            }
            
            // Floating Action Buttons
            VStack {
                HStack {
                    Spacer()
                    
                    saveButton
                        .padding(16)
                }
                
                Spacer()
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardConfirmation) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .onAppear {
            loadBrowsingHistory()
        }
    }
    
    // MARK: - Stacked Layout (Phone/Portrait)
    @ViewBuilder
    private var stackedLayout: some View {
        ZStack {
            VStack(spacing: 0) {
                editorHeader
                
                TabView(selection: Binding(
                    get: { selectedTab },
                    set: { selectedTab = $0 }
                )) {
                    editorContent
                        .tag(0)
                    
                    webBrowserContent
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            
            // Floating Save Button
            VStack {
                HStack {
                    Spacer()
                    
                    saveButton
                        .padding(16)
                }
                
                Spacer()
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardConfirmation) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .onAppear {
            loadBrowsingHistory()
            initializeWebView()
        }
    }
    
    // MARK: - Editor Header
    @ViewBuilder
    private var editorHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    if hasChanges {
                        showDiscardConfirmation = true
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("Edit Note")
                    .font(.headline)
                
                Spacer()
                
                if hasChanges {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                }
            }
            .padding(16)
            
            Divider()
            
            // Title Input
            TextField("Note Title", text: $editingNote.title)
                .font(.headline)
                .padding(12)
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Editor Content
    @ViewBuilder
    private var editorContent: some View {
        if editingNote.blocks.filter({ $0.type == .text }).isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("No Text Blocks")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Add text blocks to edit")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(editingNote.blocks.filter { $0.type == .text }, id: \.id) { block in
                        if let index = editingNote.blocks.firstIndex(where: { $0.id == block.id }) {
                            InPlaceTextBlockEditorView(
                                block: $editingNote.blocks[index],
                                isSelected: selectedTextBlockId == block.id,
                                isEditing: editingTextBlockId == block.id,
                                onSelect: { selectedTextBlockId = block.id },
                                onEditingChanged: { isEditing in
                                    editingTextBlockId = isEditing ? block.id : nil
                                }
                            )
                        }
                    }
                }
                .padding(12)
            }
        }
    }
    
    // MARK: - Web Browser Header
    @ViewBuilder
    private var webBrowserHeader: some View {
        VStack(spacing: 0) {
            Divider()
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Web Browser Content
    @ViewBuilder
    private var webBrowserContent: some View {
        ZStack {
            WebViewContainer(state: webViewState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Loading Indicator
            if webViewState.isLoading {
                VStack {
                    ProgressView()
                        .tint(.blue)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .padding(16)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(12)
            }
            
            // Floating Controls (Top Right Corner)
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // Back Button
                        Button(action: { webViewState.webView?.goBack() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .background(webViewState.canGoBack ? Color.blue : Color.gray.opacity(0.5))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .disabled(!webViewState.canGoBack)
                        
                        // Forward Button
                        Button(action: { webViewState.webView?.goForward() }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .background(webViewState.canGoForward ? Color.blue : Color.gray.opacity(0.5))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .disabled(!webViewState.canGoForward)
                        
                        // History Button
                        Button(action: { showBrowsingHistory.toggle() }) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        
                        // URL Input Button
                        Button(action: { showURLInputSheet = true }) {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        
                        // Menu Button
                        Button(action: { showWebMenu.toggle() }) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                    }
                    .padding(12)
                }
                
                Spacer()
            }
            
            // Browsing History
            if showBrowsingHistory {
                VStack(spacing: 0) {
                    Spacer()
                    
                    browsingHistoryMenu
                }
                .background(Color.black.opacity(0.3))
                .ignoresSafeArea()
                .onTapGesture {
                    showBrowsingHistory = false
                }
            }
            
            // Web Menu
            if showWebMenu {
                VStack(spacing: 0) {
                    Spacer()
                    
                    webMenuContent
                }
                .background(Color.black.opacity(0.3))
                .ignoresSafeArea()
                .onTapGesture {
                    showWebMenu = false
                }
            }
        }
        .sheet(isPresented: $showURLInputSheet) {
            URLInputSheet(
                urlInput: $urlInput,
                isPresented: $showURLInputSheet,
                onSubmit: { loadURL(urlInput) }
            )
        }
    
    }
    
    // MARK: - Browsing History Menu
    @ViewBuilder
    private var browsingHistoryMenu: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text("Browsing History")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showBrowsingHistory = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            
            Divider()
            
            if browsingHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No History")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(browsingHistory.reversed()) { item in
                            Button(action: {
                                urlInput = item.url
                                loadURL(item.url)
                                showBrowsingHistory = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.body)
                                                .lineLimit(1)
                                                .foregroundColor(.primary)
                                            
                                            Text(item.url)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            removeHistoryItem(item)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
            
            Divider()
            
            if !browsingHistory.isEmpty {
                Button(action: clearBrowsingHistory) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("Clear History")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(12)
                    .contentShape(Rectangle())
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Web Menu Content
    @ViewBuilder
    private var webMenuContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Options")
                    .font(.headline)
                Spacer()
                Button(action: { showWebMenu = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            
            Divider()
            
            Button(action: {
                webViewState.webView?.reload()
                showWebMenu = false
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                    Text("Reload")
                    Spacer()
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            Button(action: {
                urlInput = "https://www.google.com"
                loadURL("https://www.google.com")
                showWebMenu = false
            }) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.blue)
                    Text("Home")
                    Spacer()
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            Button(action: {
                if let url = URL(string: urlInput) {
                    UIPasteboard.general.url = url
                }
                showWebMenu = false
            }) {
                HStack {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundColor(.blue)
                    Text("Copy URL")
                    Spacer()
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            Button(action: { showWebMenu = false }) {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.gray)
                    Text("Close")
                    Spacer()
                }
                .padding(12)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Save Button
    @ViewBuilder
    private var saveButton: some View {
        Button(action: saveNote) {
            if isSaving {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 56, height: 56)
        .background(Color.blue)
        .clipShape(Circle())
        .shadow(radius: 8)
        .disabled(isSaving || !hasChanges)
    }
    
    // MARK: - Methods
    
    private func initializeWebView() {
        // Only initialize once
        if webViewInitialized {
            return
        }
        
        webViewInitialized = true
        
        // Load most recent URL from history
        if let mostRecentItem = browsingHistory.last {
            urlInput = mostRecentItem.url
            loadURL(mostRecentItem.url)
        } else {
            // Default to Google if no history
            urlInput = "https://www.google.com"
            loadURL("https://www.google.com")
        }
    }
    
    private func loadURL(_ urlString: String) {
        var urlString = urlString.trimmingCharacters(in: .whitespaces)
        
        // Add https:// if no scheme
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webViewState.webView?.load(request)
            webURL = urlString
            
            // Add to history
            addToHistory(url: urlString, title: urlString)
        }
    }
    
    private func addToHistory(url: String, title: String) {
        let item = BrowsingHistoryItem(url: url, title: title, timestamp: Date())
        
        // Remove duplicate if exists
        browsingHistory.removeAll { $0.url == url }
        
        // Add new item
        browsingHistory.append(item)
        
        // Limit history to 50 items
        if browsingHistory.count > 50 {
            browsingHistory.removeFirst()
        }
        
        saveBrowsingHistory()
    }
    
    private func removeHistoryItem(_ item: BrowsingHistoryItem) {
        browsingHistory.removeAll { $0.id == item.id }
        saveBrowsingHistory()
    }
    
    private func clearBrowsingHistory() {
        browsingHistory.removeAll()
        saveBrowsingHistory()
        showBrowsingHistory = false
    }
    
    private func saveBrowsingHistory() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let encoded = try encoder.encode(browsingHistory)
            UserDefaults.standard.set(encoded, forKey: "BrowsingHistory")
            UserDefaults.standard.synchronize()
        } catch {
            print("Error saving browsing history: \(error)")
        }
    }
    
    private func loadBrowsingHistory() {
        if let data = UserDefaults.standard.data(forKey: "BrowsingHistory"),
           let decoded = try? JSONDecoder().decode([BrowsingHistoryItem].self, from: data) {
            browsingHistory = decoded
        }
    }
    
    private func saveNote() {
        isSaving = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var noteToSave = editingNote
            noteToSave.dateModified = Date()
            noteManager.saveNote(noteToSave)
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Browsing History Item
struct BrowsingHistoryItem: Identifiable, Codable {
    let id: UUID
    let url: String
    let title: String
    let timestamp: Date
    
    init(url: String, title: String, timestamp: Date) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.timestamp = timestamp
    }
}


// MARK: - Web View State
class WebViewState: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var webView: WKWebView?
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    
    override init() {
        super.init()
        
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        self.webView = webView
        
        // Load initial URL
        if let url = URL(string: "https://www.google.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    // MARK: - WKNavigationDelegate Methods
    
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

// MARK: - Web View Container
struct WebViewContainer: UIViewRepresentable {
    let state: WebViewState
    
    func makeUIView(context: Context) -> WKWebView {
        guard let webView = state.webView else {
            return WKWebView()
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}


// MARK: - Preview
struct SplitScreenNoteAndWebView_Previews: PreviewProvider {
    static var previews: some View {
        SplitScreenNoteAndWebView(note: RichNote(title: "Sample Note", blocks: [
            RichNoteBlock(type: .text, content: "This is sample text for editing")
        ]))
    }
}
