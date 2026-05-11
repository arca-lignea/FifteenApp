//
//  SplitScreenNoteAndCodeView.swift
//  FifteenApp
//
//  Created by sophie on 2026-05-07.
//

import SwiftUI

struct SplitScreenNoteAndCodeView: View {
    let originalNote: RichNote
    @State private var editingNote: RichNote
    @State private var selectedTextBlockId: UUID?
    @State private var editingTextBlockId: UUID?
    @State private var selectedTab: Int = 0
    @State private var isSaving = false
    @State private var showDiscardConfirmation = false
    @State private var showCodeFileImporter = false
    @State private var codeContent: String = ""
    @State private var codeFileName: String = "No file selected"
    @State private var codeFileURL: URL?
    @State private var currentLineNumber: Int = 1
    @State private var showCodeMenu = false
    @State private var codeFiles: [CodeFile] = []
    @State private var selectedCodeFileId: UUID?
    @StateObject private var noteManager = RichNoteManager()
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
            splitScreenLayout
        } else {
            stackedLayout
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
                
                // Right Panel - Code Viewer
                VStack(spacing: 0) {
                    codeViewerHeader
                    codeViewerContent
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
            loadCodeFiles()
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
                    
                    codeViewerContent
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
            loadCodeFiles()
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
    
    // MARK: - Code Viewer Header
    @ViewBuilder
    private var codeViewerHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "curlybraces")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text(codeFileName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: { showCodeMenu.toggle() }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            
            Divider()
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Code Viewer Content
    @ViewBuilder
    private var codeViewerContent: some View {
        ZStack {
            if codeContent.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("No Code File")
                    .font(.headline)
                        .foregroundColor(.gray)
                    Text("Select a Python file to view")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
            } else {
                CodeViewer(
                    content: codeContent,
                    fileName: codeFileName,
                    selectedCodeFileId: $selectedCodeFileId,
                    codeFiles: codeFiles
                )
            }
            
            // Floating Controls (Top Right)
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // Open File Button
                        Button(action: { showCodeFileImporter = true }) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        
                        // Files List Button
                        if !codeFiles.isEmpty {
                            Button(action: { showCodeMenu.toggle() }) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                        }
                    }
                    .padding(12)
                }
                
                Spacer()
            }
            
            // Code Files Menu
            if showCodeMenu {
                VStack(spacing: 0) {
                    Spacer()
                    
                    codeFilesMenu
                }
                .background(Color.black.opacity(0.3))
                .ignoresSafeArea()
                .onTapGesture {
                    showCodeMenu = false
                }
            }
        }
        .fileImporter(
            isPresented: $showCodeFileImporter,
            allowedContentTypes: [.pythonScript],
            onCompletion: { result in
                if case .success(let url) = result {
                    loadCodeFile(url)
                }
            }
        )
    }
    
    // MARK: - Code Files Menu
    @ViewBuilder
    private var codeFilesMenu: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                Text("Code Files")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showCodeMenu = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            
            Divider()
            
            if codeFiles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No Files")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(codeFiles) { file in
                            Button(action: {
                                selectedCodeFileId = file.id
                                codeContent = file.content
                                codeFileName = file.fileName
                                showCodeMenu = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(file.fileName)
                                                .font(.body)
                                                .lineLimit(1)
                                                .foregroundColor(.primary)
                                            
                                            Text("\(file.content.split(separator: "\n").count) lines")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedCodeFileId == file.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 14))
                                        }
                                        
                                        Button(action: {
                                            removeCodeFile(file)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .padding(12)
                                    .background(selectedCodeFileId == file.id ? Color.blue.opacity(0.1) : Color(.systemGray6).opacity(0.5))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
            
            Divider()
            
            Button(action: {
                showCodeFileImporter = true
                showCodeMenu = false
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                    Text("Add File")
                    Spacer()
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            
            if !codeFiles.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: clearCodeFiles) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("Clear All")
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
    
    private func loadCodeFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let fileName = url.lastPathComponent
            
            let codeFile = CodeFile(
                id: UUID(),
                fileName: fileName,
                content: content,
                fileURL: url,
                timestamp: Date()
            )
            
            // Remove if already exists
            codeFiles.removeAll { $0.fileName == fileName }
            
            // Add new file
            codeFiles.append(codeFile)
            
            // Set as selected
            selectedCodeFileId = codeFile.id
            codeContent = content
            codeFileName = fileName
            
            saveCodeFiles()
        } catch {
            print("Error loading code file: \(error)")
        }
    }
    
    private func removeCodeFile(_ file: CodeFile) {
        codeFiles.removeAll { $0.id == file.id }
        
        if selectedCodeFileId == file.id {
            selectedCodeFileId = codeFiles.first?.id
            if let selectedFile = codeFiles.first {
                codeContent = selectedFile.content
                codeFileName = selectedFile.fileName
            } else {
                codeContent = ""
                codeFileName = "No file selected"
            }
        }
        
        saveCodeFiles()
    }
    
    private func clearCodeFiles() {
        codeFiles.removeAll()
        selectedCodeFileId = nil
        codeContent = ""
        codeFileName = "No file selected"
        saveCodeFiles()
        showCodeMenu = false
    }
    
    private func saveCodeFiles() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let encoded = try encoder.encode(codeFiles)
            UserDefaults.standard.set(encoded, forKey: "CodeFiles")
            UserDefaults.standard.synchronize()
        } catch {
            print("Error saving code files: \(error)")
        }
    }
    
    private func loadCodeFiles() {
        if let data = UserDefaults.standard.data(forKey: "CodeFiles"),
           let decoded = try? JSONDecoder().decode([CodeFile].self, from: data) {
            codeFiles = decoded
            
            // Load first file if available
            if let firstFile = codeFiles.first {
                selectedCodeFileId = firstFile.id
                codeContent = firstFile.content
                codeFileName = firstFile.fileName
            }
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

// MARK: - Code File Model
struct CodeFile: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let content: String
    let fileURL: URL?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, fileName, content, fileURL, timestamp
    }
    
    init(id: UUID, fileName: String, content: String, fileURL: URL? = nil, timestamp: Date) {
        self.id = id
        self.fileName = fileName
        self.content = content
        self.fileURL = fileURL
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fileName = try container.decode(String.self, forKey: .fileName)
        content = try container.decode(String.self, forKey: .content)
        fileURL = try container.decodeIfPresent(URL.self, forKey: .fileURL)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(fileURL, forKey: .fileURL)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - Code Viewer
struct CodeViewer: View {
    let content: String
    let fileName: String
    @Binding var selectedCodeFileId: UUID?
    let codeFiles: [CodeFile]
    
    @State private var searchText: String = ""
    @State private var highlightedLineNumber: Int?
    
    var filteredLines: [(number: Int, content: String)] {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        
        if searchText.isEmpty {
            return lines.enumerated().map { ($0.offset + 1, String($0.element)) }
        } else {
            return lines.enumerated()
                .filter { $0.element.localizedCaseInsensitiveContains(searchText) }
                .map { ($0.offset + 1, String($0.element)) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search code...", text: $searchText)
                    .font(.caption)
                    .autocapitalization(.none)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6).opacity(0.7))
            .cornerRadius(6)
            .padding(8)
            
            // Code Display
            ScrollView([.vertical, .horizontal]) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredLines, id: \.number) { lineNumber, lineContent in
                        HStack(alignment: .top, spacing: 8) {
                            // Line Number
                            Text(String(format: "%3d", lineNumber))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                                .frame(width: 40, alignment: .trailing)
                            
                            // Line Content with Syntax Highlighting
                            SyntaxHighlightedLine(code: lineContent)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(highlightedLineNumber == lineNumber ? Color.yellow.opacity(0.2) : Color.clear)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .font(.system(size: 12, design: .monospaced))
            
            // Stats
            HStack(spacing: 16) {
                Text("Lines: \(content.split(separator: "\n").count)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text("Chars: \(content.count)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(8)
            .background(Color(.systemGray6).opacity(0.5))
        }
    }
}

// MARK: - Syntax Highlighted Line
//struct SyntaxHighlightedLine: View {
//    let content: String
//    
//    var body: some View {
//        HStack(spacing: 0) {
//            ForEach(tokenize(content), id: \.self) { token in
//                Text(token.text)
//                    .foregroundColor(token.color)
//                    .font(.system(size: 12, weight: .regular, design: .monospaced))
//            }
//        }
//    }
//    
//    private func tokenize(_ line: String) -> [Token] {
//        var tokens: [Token] = []
//        var currentToken = ""
//        var i = line.startIndex
//        
//        while i < line.endIndex {
//            let char = line[i]
//            let nextChar = line.index(after: i) < line.endIndex ? line[line.index(after: i)] : " "
//            
//            // Keywords
//            let keywords = ["def", "class", "if", "else", "elif", "for", "while", "return", "import", "from", "as", "try", "except", "finally", "with", "pass", "break", "continue", "True", "False", "None", "and", "or", "not", "in", "is", "lambda", "yield"]
//            
//            // Comments
//            if char == "#" {
//                if !currentToken.isEmpty {
//                    tokens.append(Token(text: currentToken, color: .primary))
//                    currentToken = ""
//                }
//                let comment = String(line[i...])
//                tokens.append(Token(text: comment, color: .green))
//                break
//            }
//            
//            // Strings
//            if char == "\"" || char == "'" {
//                if !currentToken.isEmpty {
//                    tokens.append(Token(text: currentToken, color: .primary))
//                    currentToken = ""
//                }
//                let quote = char
//                var stringContent = String(char)
//                i = line.index(after: i)
//                
//                while i < line.endIndex && line[i] != quote {
//                    stringContent.append(line[i])
//                    i = line.index(after: i)
//                }
//                
//                if i < line.endIndex {
//                    stringContent.append(line[i])
//                }
//                
//                tokens.append(Token(text: stringContent, color: .red))
//                i = line.index(after: i)
//                continue
//            }
//            
//            // Numbers
//            if char.isNumber {
//                currentToken.append(char)
//                if !nextChar.isNumber && nextChar != "." {
//                    tokens.append(Token(text: currentToken, color: .blue))
//                    currentToken = ""
//                }
//                i = line.index(after: i)
//                continue
//            }
//            
//            // Whitespace
//            if char.isWhitespace {
//                if !currentToken.isEmpty {
//                    let color: Color = keywords.contains(currentToken) ? .purple : .primary
//                    tokens.append(Token(text: currentToken, color: color))
//                    currentToken = ""
//                }
//                tokens.append(Token(text: String(char), color: .primary))
//                i = line.index(after: i)
//                continue
//            }
//            
//            // Operators
//            if "()[]{}:,;.=+-*/<>!&|".contains(char) {
//                if !currentToken.isEmpty {
//                    let color: Color = keywords.contains(currentToken) ? .purple : .primary
//                    tokens.append(Token(text: currentToken, color: color))
//                    currentToken = ""
//                }
//                tokens.append(Token(text: String(char), color: .orange))
//                i = line.index(after: i)
//                continue
//            }
//            
//            currentToken.append(char)
//            i = line.index(after: i)
//        }
//        
//        if !currentToken.isEmpty {
//            let color: Color = keywords.contains(currentToken) ? .purple : .primary
//            tokens.append(Token(text: currentToken, color: color))
//        }
//        
//        return tokens.isEmpty ? [Token(text: content, color: .primary)] : tokens
//    }
//}
//
//struct Token: Hashable {
//    let text: String
//    let color: Color
//}

// MARK: - In-Place Text Block Editor View
//struct InPlaceTextBlockEditorView: View {
//    @Binding var block: RichNoteBlock
//    let isSelected: Bool
//    let isEditing: Bool
//    let onSelect: () -> Void
//    let onEditingChanged: (Bool) -> Void
//    
//    @State private var editingText: String = ""
//    @FocusState private var isFocused: Bool
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Card Header
//            HStack {
//                Image(systemName: "text.alignleft")
//                    .font(.system(size: 14))
//                    .foregroundColor(.blue)
//                
//                Text("Text Block")
//                    .font(.caption)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.gray)
//                
//                Spacer()
//                
//                if isEditing {
//                    HStack(spacing: 8) {
//                        Text("\(editingText.count)")
//                            .font(.caption2)
//                            .foregroundColor(.gray)
//                        
//                        Button(action: {
//                            block.content = editingText
//                            onEditingChanged(false)
//                        }) {
//                            Image(systemName: "checkmark.circle.fill")
//                                .font(.system(size: 16))
//                                .foregroundColor(.green)
//                        }
//                    }
//                } else {
//                    Button(action: {
//                        editingText = block.content
//                        onEditingChanged(true)
//                    }) {
//                        Image(systemName: "pencil.circle")
//                            .font(.system(size: 16))
//                            .foregroundColor(.blue)
//                    }
//                }
//            }
//            .padding(12)
//            .background(Color(.systemGray6).opacity(0.5))
//            
//            Divider()
//            
//            // Card Content
//            if isEditing {
//                // Editing Mode - TextEditor
//                TextEditor(text: $editingText)
//                    .font(.body)
//                    .lineSpacing(1.2)
//                    .padding(12)
//                    .frame(minHeight: 150)
//                    .scrollContentBackground(.hidden)
//                    .focused($isFocused)
//                    .onChange(of: editingText) { newValue in
//                        block.content = newValue
//                    }
//            } else {
//                // Preview Mode
//                VStack(alignment: .leading, spacing: 0) {
//                    if block.content.isEmpty {
//                        Text("Tap edit to add text")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                            .padding(12)
//                    } else {
//                        Text(block.content)
//                            .font(.body)
//                            .lineSpacing(1.2)
//                            .padding(12)
//                            .frame(maxHeight: 200)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//            }
//        }
//        .background(Color(.systemBackground))
//        .cornerRadius(8)
//        .border(isSelected ? Color.blue : Color.gray.opacity(0.3), width: 2)
//        .onTapGesture {
//            onSelect()
//        }
//        .onAppear {
//            editingText = block.content
//            if isEditing {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    isFocused = true
//                }
//            }
//        }
//    }
//}

// MARK: - Helper Extensions


//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//    
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(
//            roundedRect: rect,
//            byRoundingCorners: corners,
//            cornerRadii: CGSize(width: radius, height: radius)
//        )
//        return Path(path.cgPath)
//    }
//}

// MARK: - UTType Extension
import UniformTypeIdentifiers

extension UTType {
    static let pythonScript = UTType(filenameExtension: "py") ?? .plainText
}

// MARK: - Preview
struct SplitScreenNoteAndCodeView_Previews: PreviewProvider {
    static var previews: some View {
        SplitScreenNoteAndCodeView(note: RichNote(title: "Sample Note", blocks: [
            RichNoteBlock(type: .text, content: "This is sample text for editing")
        ]))
    }
}
