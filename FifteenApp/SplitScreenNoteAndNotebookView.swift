////
////  SplitScreenNoteAndNotebookView.swift
////  FifteenApp
////
////  Created by sophie on 2026-05-13.
////
//
//import SwiftUI
//import WebKit
//import QuartzCore
//import UniformTypeIdentifiers
//
//// MARK: - Python Syntax Highlighter
////class PythonSyntaxHighlighter {
////    static func highlight(_ code: String) -> NSAttributedString {
////        let attributedString = NSMutableAttributedString(string: code)
////        
////        // Define color scheme
////        let keywordColor = UIColor(red: 0.85, green: 0.26, blue: 0.85, alpha: 1.0) // Magenta
////        let stringColor = UIColor(red: 0.25, green: 0.68, blue: 0.34, alpha: 1.0)   // Green
////        let numberColor = UIColor(red: 1.0, green: 0.63, blue: 0.0, alpha: 1.0)     // Orange
////        let commentColor = UIColor(red: 0.63, green: 0.63, blue: 0.63, alpha: 1.0)  // Gray
////        let functionColor = UIColor(red: 0.0, green: 0.62, blue: 0.89, alpha: 1.0)  // Blue
////        let defaultColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)     // White
////        
////        // Python keywords
////        let keywords = [
////            "def", "class", "if", "else", "elif", "for", "while", "return", "import",
////            "from", "as", "try", "except", "finally", "with", "lambda", "yield",
////            "pass", "break", "continue", "raise", "assert", "del", "in", "is",
////            "and", "or", "not", "True", "False", "None", "self"
////        ]
////        
////        let baseFont = UIFont(name: "Menlo", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
////        
////        // First, set default color for entire string
////        attributedString.addAttribute(.foregroundColor, value: defaultColor, range: NSRange(location: 0, length: attributedString.length))
////        attributedString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: attributedString.length))
////        
////        // Highlight comments
////        highlightPattern(attributedString, pattern: "#.*?(?=\\n|$)", color: commentColor, font: baseFont)
////        
////        // Highlight strings (both single and double quoted)
////        highlightPattern(attributedString, pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: stringColor, font: baseFont)
////        highlightPattern(attributedString, pattern: "'(?:[^'\\\\]|\\\\.)*'", color: stringColor, font: baseFont)
////        
////        // Highlight numbers
////        highlightPattern(attributedString, pattern: "\\b\\d+\\.?\\d*\\b", color: numberColor, font: baseFont)
////        
////        // Highlight keywords
////        for keyword in keywords {
////            let pattern = "\\b\(keyword)\\b"
////            highlightPattern(attributedString, pattern: pattern, color: keywordColor, font: baseFont)
////        }
////        
////        // Highlight function definitions
////        highlightPattern(attributedString, pattern: "(?<=def )\\w+", color: functionColor, font: baseFont)
////        highlightPattern(attributedString, pattern: "(?<=class )\\w+", color: functionColor, font: baseFont)
////        
////        return attributedString
////    }
////    
////    private static func highlightPattern(_ attributedString: NSMutableAttributedString, pattern: String, color: UIColor, font: UIFont) {
////        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
////        
////        let range = NSRange(location: 0, length: attributedString.length)
////        let matches = regex.matches(in: attributedString.string, options: [], range: range)
////        
////        for match in matches {
////            attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
////            attributedString.addAttribute(.font, value: font, range: match.range)
////        }
////    }
////}
//
//// MARK: - Split Screen Note and Notebook View
//struct SplitScreenNoteAndNotebookView: View {
//    @State private var editedNote: RichNote
//    @State private var notebookContent: String = ""
//    @State private var selectedBlock: Int?
//    @State private var showBlockEditor = false
//    @State private var notebookURL: URL?
//    @State private var showNotebookPicker = false
//    @StateObject private var noteManager = RichNoteManager()
//    @Environment(\.dismiss) var dismiss
//    
//    let note: RichNote
//    
//    init(note: RichNote) {
//        self.note = note
//        self._editedNote = State(initialValue: note)
//    }
//    
//    var body: some View {
//        
//            ZStack {
//                HStack(spacing: 0) {
//                    // Left Side - Note Editor
//                    VStack(spacing: 0) {
//                        // Header
//                        HStack {
//                            Button(action: { dismiss() }) {
//                                Image(systemName: "chevron.left")
//                                    .font(.system(size: 16, weight: .semibold))
//                                    .foregroundColor(.blue)
//                            }
//                            
//                            Text("Edit Note")
//                                .font(.headline)
//                            
//                            Spacer()
//                            
//                            Button(action: { saveNote() }) {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .font(.system(size: 20))
//                                    .foregroundColor(.green)
//                            }
//                        }
//                        .padding(12)
//                        .background(Color(.systemGray6))
//                        .border(Color(.systemGray4), width: 0.5)
//                        
//                        // Note Title
//                        HStack {
//                            Text("Title:")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                                .frame(width: 40)
//                            
//                            TextField("Note title", text: Binding(
//                                get: { editedNote.title },
//                                set: { editedNote.title = $0 }
//                            ))
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                        }
//                        .padding(12)
//                        .background(Color(.systemGray6).opacity(0.5))
//                        
//                        // Blocks List
//                        ScrollView {
//                            VStack(spacing: 8) {
//                                ForEach(Array(editedNote.blocks.enumerated()), id: \.element.id) { index, block in
//                                    BlockEditRow(
//                                        block: block,
//                                        index: index,
//                                        isSelected: selectedBlock == index,
//                                        onSelect: { selectedBlock = index },
//                                        onEdit: { showBlockEditor = true },
//                                        onDelete: { deleteBlock(at: index) }
//                                    )
//                                }
//                            }
//                            .padding(12)
//                        }
//                        
//                        // Add Block Button
//                        HStack(spacing: 8) {
//                            Menu {
//                                Button(action: { addTextBlock() }) {
//                                    Label("Text", systemImage: "text.alignleft")
//                                }
//                                
//                                Button(action: { showNotebookPicker = true }) {
//                                    Label("Image", systemImage: "photo.fill")
//                                }
//                                
//                                Button(action: { addPDFBlock() }) {
//                                    Label("PDF", systemImage: "doc.fill")
//                                }
//                            } label: {
//                                Label("Add Block", systemImage: "plus.circle.fill")
//                                    .frame(maxWidth: .infinity)
//                                    .padding(12)
//                                    .background(Color.blue)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(8)
//                            }
//                        }
//                        .padding(12)
//                        .background(Color(.systemGray6))
//                    }
//                    .frame(maxWidth: .infinity)
//                    
//                    Divider()
//                    
//                    // Right Side - Jupyter Notebook Viewer
//                    VStack(spacing: 0) {
//                        // Notebook Header
//                        HStack {
//                            Text("Jupyter Notebook")
//                                .font(.headline)
//                            
//                            Spacer()
//                            
//                            Button(action: { showNotebookPicker = true }) {
//                                Image(systemName: "folder.fill")
//                                    .font(.system(size: 16))
//                                    .foregroundColor(.blue)
//                            }
//                        }
//                        .padding(12)
//                        .background(Color(.systemGray6))
//                        .border(Color(.systemGray4), width: 0.5)
//                        
//                        // Notebook Display
//                        if let notebookURL = notebookURL, !notebookContent.isEmpty {
//                            ScrollView {
//                                VStack(alignment: .leading, spacing: 12) {
//                                    // Parse and display notebook cells
//                                    NotebookRenderer(content: notebookContent)
//                                }
//                                .padding(12)
//                            }
//                        } else {
//                            VStack(spacing: 12) {
//                                Image(systemName: "doc.text")
//                                    .font(.system(size: 40))
//                                    .foregroundColor(.gray)
//                                
//                                Text("No Notebook Loaded")
//                                    .font(.headline)
//                                    .foregroundColor(.gray)
//                                
//                                Button(action: { showNotebookPicker = true }) {
//                                    Label("Select Notebook", systemImage: "folder.fill")
//                                        .padding(.horizontal, 12)
//                                        .padding(.vertical, 6)
//                                        .background(Color.blue)
//                                        .foregroundColor(.white)
//                                        .cornerRadius(6)
//                                }
//                            }
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                            .background(Color(.systemBackground))
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                }
//            }
//            .fileImporter(
//                isPresented: $showNotebookPicker,
//                allowedContentTypes: [UTType(filenameExtension: "ipynb") ?? .plainText],
//                onCompletion: { result in
//                    handleNotebookSelection(result)
//                }
//            )
//            .toolbar(.hidden, for: .navigationBar)
//        
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func addTextBlock() {
//        let newBlock = RichNoteBlock(type: .text, content: "New text block")
//        editedNote.blocks.append(newBlock)
//    }
//    
//    private func addPDFBlock() {
//        let newBlock = RichNoteBlock(type: .pdf, content: "New PDF", pdfPageCount: 0)
//        editedNote.blocks.append(newBlock)
//    }
//    
//    private func deleteBlock(at index: Int) {
//        editedNote.blocks.remove(at: index)
//        selectedBlock = nil
//    }
//    
//    private func saveNote() {
//        noteManager.saveNote(editedNote)
//        dismiss()
//    }
//    
//    private func handleNotebookSelection(_ result: Result<URL, Error>) {
//        switch result {
//        case .success(let url):
//            notebookURL = url
//            _ = url.startAccessingSecurityScopedResource()
//            
//            do {
//                notebookContent = try String(contentsOf: url, encoding: .utf8)
//            } catch {
//                print("Error reading notebook: \(error)")
//            }
//            
//            url.stopAccessingSecurityScopedResource()
//            
//        case .failure(let error):
//            print("Error selecting notebook: \(error)")
//        }
//    }
//}
//
//// MARK: - Block Edit Row
//struct BlockEditRow: View {
//    let block: RichNoteBlock
//    let index: Int
//    let isSelected: Bool
//    let onSelect: () -> Void
//    let onEdit: () -> Void
//    let onDelete: () -> Void
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Image(systemName: blockIcon)
//                    .foregroundColor(blockColor)
//                    .frame(width: 24)
//                
//                VStack(alignment: .leading, spacing: 2) {
//                    Text("\(blockTitle) Block")
//                        .font(.caption)
//                        .fontWeight(.semibold)
//                    
//                    Text(block.content.prefix(50) + (block.content.count > 50 ? "..." : ""))
//                        .font(.caption2)
//                        .foregroundColor(.gray)
//                        .lineLimit(1)
//                }
//                
//                Spacer()
//                
//                HStack(spacing: 8) {
//                    Button(action: onEdit) {
//                        Image(systemName: "pencil")
//                            .font(.caption)
//                            .foregroundColor(.blue)
//                    }
//                    
//                    Button(action: onDelete) {
//                        Image(systemName: "trash")
//                            .font(.caption)
//                            .foregroundColor(.red)
//                    }
//                }
//            }
//            .padding(8)
//            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
//            .cornerRadius(6)
//            .onTapGesture { onSelect() }
//        }
//    }
//    
//    private var blockIcon: String {
//        switch block.type {
//        case .text:
//            return "text.alignleft"
//        case .image:
//            return "photo.fill"
//        case .pdf:
//            return "doc.fill"
//        }
//    }
//    
//    private var blockColor: Color {
//        switch block.type {
//        case .text:
//            return .blue
//        case .image:
//            return .green
//        case .pdf:
//            return .orange
//        }
//    }
//    
//    private var blockTitle: String {
//        switch block.type {
//        case .text:
//            return "Text"
//        case .image:
//            return "Image"
//        case .pdf:
//            return "PDF"
//        }
//    }
//}
//
//// MARK: - Notebook Renderer
//struct NotebookRenderer: View {
//    let content: String
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            if let cells = parseNotebookCells(content) {
//                ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
//                    NotebookCellView(cell: cell, cellNumber: index + 1)
//                }
//            } else {
//                Text("Unable to parse notebook")
//                    .font(.caption)
//                    .foregroundColor(.red)
//            }
//        }
//    }
//    
//    private func parseNotebookCells(_ jsonString: String) -> [[String: Any]]? {
//        guard let data = jsonString.data(using: .utf8),
//              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//              let cells = json["cells"] as? [[String: Any]] else {
//            return nil
//        }
//        return cells
//    }
//}
//
//// MARK: - Notebook Cell View
//struct NotebookCellView: View {
//    let cell: [String: Any]
//    let cellNumber: Int
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // Cell Type Badge
//            HStack {
//                Text(cellType.uppercased())
//                    .font(.caption2)
//                    .fontWeight(.bold)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(cellTypeColor)
//                    .foregroundColor(.white)
//                    .cornerRadius(4)
//                
//                Text("Cell \(cellNumber)")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                
//                Spacer()
//            }
//            
//            // Cell Content
//            if cellType == "code" {
//                HighlightedCodeCellView(source: cellSource)
//            } else if cellType == "markdown" {
//                MarkdownCellView(source: cellSource)
//            } else {
//                Text("Raw Cell")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//            
//            // Output (if code cell)
//            if cellType == "code", let outputs = cell["outputs"] as? [[String: Any]], !outputs.isEmpty {
//                VStack(alignment: .leading, spacing: 6) {
//                    Text("Output")
//                        .font(.caption)
//                        .fontWeight(.semibold)
//                        .foregroundColor(.gray)
//                    
//                    ForEach(Array(outputs.enumerated()), id: \.offset) { _, output in
//                        OutputCellView(output: output)
//                    }
//                }
//                .padding(8)
//                .background(Color(.systemGray6))
//                .cornerRadius(6)
//            }
//        }
//        .padding(10)
//        .background(Color(.systemBackground))
//        .cornerRadius(8)
//        .border(Color(.systemGray4), width: 0.5)
//    }
//    
//    private var cellType: String {
//        (cell["cell_type"] as? String) ?? "unknown"
//    }
//    
//    private var cellSource: String {
//        if let source = cell["source"] as? [String] {
//            return source.joined()
//        } else if let source = cell["source"] as? String {
//            return source
//        }
//        return ""
//    }
//    
//    private var cellTypeColor: Color {
//        switch cellType {
//        case "code":
//            return .blue
//        case "markdown":
//            return .green
//        default:
//            return .gray
//        }
//    }
//}
//
//
//// MARK: - AttributedText View Wrapper
//extension Text {
//    init(_ attributedString: NSAttributedString, size: CGSize) {
//        let mutableString = NSMutableAttributedString(attributedString: attributedString)
//        mutableString.removeAttribute(.font, range: NSRange(location: 0, length: mutableString.length))
//        self.init("")
//    }
//}
//
//// MARK: - UITextView Wrapper for Attributed Text
//struct SyntaxHighlightedCodeView: UIViewRepresentable {
//    let attributedString: NSAttributedString
//    
//    func makeUIView(context: Context) -> UITextView {
//        let textView = UITextView()
//        textView.attributedText = attributedString
//        textView.isEditable = false
//        textView.isSelectable = true
//        textView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
//        textView.font = UIFont(name: "Menlo", size: 12)
//        return textView
//    }
//    
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        uiView.attributedText = attributedString
//    }
//}
//
//struct HighlightedCodeCellView: View {
//    let source: String
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            Text("Python")
//                .font(.caption2)
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(6)
//                .background(Color.blue)
//            
//            SyntaxHighlightedCodeView(attributedString: PythonSyntaxHighlighter.highlight(source))
//        }
//        .cornerRadius(6)
//       
//    }
//}
//
//// MARK: - Markdown Cell View
//struct MarkdownCellView: View {
//    let source: String
//    
//    var body: some View {
//        Text(source)
//            .font(.caption)
//            .foregroundColor(.primary)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding(8)
//            .background(Color(.systemGray6))
//            .cornerRadius(6)
//    }
//}
//
//// MARK: - Output Cell View
//struct OutputCellView: View {
//    let output: [String: Any]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            if let text = output["text"] as? [String] {
//                Text(text.joined())
//                    .font(.system(.caption2, design: .monospaced))
//                    .foregroundColor(.primary)
//            } else if let data = output["data"] as? [String: Any] {
//                if let textData = data["text/plain"] as? [String] {
//                    Text(textData.joined())
//                        .font(.system(.caption2, design: .monospaced))
//                        .foregroundColor(.primary)
//                }
//            } else if let ename = output["ename"] as? String {
//                Text("Error: \(ename)")
//                    .font(.caption2)
//                    .foregroundColor(.red)
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//}
//
//
//
//
//
//// MARK: - Preview
//struct SplitScreenNoteAndNotebookView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleNote = RichNote(
//            title: "Sample Note",
//            blocks: [
//                RichNoteBlock(type: .text, content: "This is sample text")
//            ]
//        )
//        SplitScreenNoteAndNotebookView(note: sampleNote)
//    }
//}
