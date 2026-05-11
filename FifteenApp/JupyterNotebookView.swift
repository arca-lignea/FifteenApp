import SwiftUI
import UniformTypeIdentifiers

struct JupyterNotebookView: View {
    @State private var notebook: Notebook?
    @State private var isDocumentPickerPresented = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let notebook = notebook {
                notebookContent(notebook)
            } else {
                uploadPrompt
            }

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .fileImporter(
            isPresented: $isDocumentPickerPresented,
            allowedContentTypes: [UTType(filenameExtension: "ipynb") ?? .plainText],
            onCompletion: handleFileSelection
        )
    }

    // MARK: - Views

    private var uploadPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("Upload Jupyter Notebook")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select a .ipynb file to display")
                .font(.body)
                .foregroundColor(.secondary)

            Button(action: { isDocumentPickerPresented = true }) {
                Label("Choose File", systemImage: "doc.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }

    private func notebookContent(_ notebook: Notebook) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Notebook Title and Upload Button
                HStack {
                    VStack(alignment: .leading) {
                        Text("Jupyter Notebook")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(notebook.cells.count) cells")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        self.notebook = nil
                        errorMessage = nil
                    }) {
                        Label("New", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                Divider()

                // Cells
                ForEach(notebook.cells, id: \.id) { cell in
                    NotebookCellView(cell: cell)
                }
            }
            .padding()
        }
    }

    // MARK: - File Handling

    private func handleFileSelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            isLoading = true
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                do {
                    // Start accessing the security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        throw NSError(domain: "FileAccess", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to access file. Please try again."])
                    }

                    let data = try Data(contentsOf: url)
                    let notebook = try JSONDecoder().decode(Notebook.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.notebook = notebook
                        self.errorMessage = nil
                        isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to load notebook: \(error.localizedDescription)"
                        isLoading = false
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
}

// MARK: - Models

struct Notebook: Codable {
    let cells: [Cell]
    let metadata: NotebookMetadata?

    enum CodingKeys: String, CodingKey {
        case cells
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cells = try container.decode([Cell].self, forKey: .cells)
        self.metadata = try container.decodeIfPresent(NotebookMetadata.self, forKey: .metadata)
    }
}

struct Cell: Codable, Identifiable {
    let id: UUID = UUID()
    let cellType: String
    let source: [String]
    let outputs: [Output]?
    let metadata: CellMetadata?

    enum CodingKeys: String, CodingKey {
        case cellType = "cell_type"
        case source
        case outputs
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cellType = try container.decode(String.self, forKey: .cellType)
        
        let sourceData = try container.decode(SourceType.self, forKey: .source)
        self.source = sourceData.asArray
        
        self.outputs = try container.decodeIfPresent([Output].self, forKey: .outputs)
        self.metadata = try container.decodeIfPresent(CellMetadata.self, forKey: .metadata)
    }

    var content: String {
        source.joined()
    }
}

// Helper to decode source which can be a string or array
private enum SourceType: Codable {
    case string(String)
    case array([String])

    var asArray: [String] {
        switch self {
        case .string(let str):
            return [str]
        case .array(let arr):
            return arr
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode source")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .array(let arr):
            try container.encode(arr)
        }
    }
}

struct Output: Codable {
    let outputType: String
    let data: OutputData?
    let text: [String]?
    let executionCount: Int?
    let metadata: OutputMetadata?

    enum CodingKeys: String, CodingKey {
        case outputType = "output_type"
        case data
        case text
        case executionCount = "execution_count"
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.outputType = try container.decode(String.self, forKey: .outputType)
        self.data = try container.decodeIfPresent(OutputData.self, forKey: .data)
        
        let textData = try container.decodeIfPresent(SourceType.self, forKey: .text)
        self.text = textData?.asArray
        
        self.executionCount = try container.decodeIfPresent(Int.self, forKey: .executionCount)
        self.metadata = try container.decodeIfPresent(OutputMetadata.self, forKey: .metadata)
    }

    var content: String {
        if let text = text {
            return text.joined()
        }
        return data?.content ?? ""
    }
}

struct OutputData: Codable {
    let textPlain: [String]?
    let textHtml: [String]?
    let textMarkdown: [String]?
    let imagePng: String?
    let imageJpeg: String?

    enum CodingKeys: String, CodingKey {
        case textPlain = "text/plain"
        case textHtml = "text/html"
        case textMarkdown = "text/markdown"
        case imagePng = "image/png"
        case imageJpeg = "image/jpeg"
    }

    var content: String {
        if let text = textPlain {
            return text.joined()
        } else if let html = textHtml {
            return html.joined()
        } else if let markdown = textMarkdown {
            return markdown.joined()
        }
        return "[Image content]"
    }
}

struct OutputMetadata: Codable {}

struct NotebookMetadata: Codable {
    let kernelspec: KernelSpec?
    let language_info: LanguageInfo?

    enum CodingKeys: String, CodingKey {
        case kernelspec
        case language_info
    }
}

struct KernelSpec: Codable {
    let display_name: String?
    let language: String?
    let name: String?
}

struct LanguageInfo: Codable {
    let name: String?
    let version: String?
    let mimetype: String?
}

struct CellMetadata: Codable {}

// MARK: - Cell Views

struct NotebookCellView: View {
    let cell: Cell

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch cell.cellType {
            case "markdown":
                MarkdownCellView(content: cell.content)
            case "code":
                CodeCellView(content: cell.content, outputs: cell.outputs ?? [])
            case "raw":
                RawCellView(content: cell.content)
            default:
                Text(cell.content)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MarkdownCellView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(content)
                .font(.body)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CodeCellView: View {
    let content: String
    let outputs: [Output]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Code Input
            VStack(alignment: .leading) {
                HStack {
                    Text("In")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // Python code with syntax highlighting and horizontal scroll
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init), id: \.self) { line in
                            SyntaxHighlightedLine(code: line)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(6)

            // Outputs
            if !outputs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(outputs.indices, id: \.self) { index in
                        OutputCellView(output: outputs[index], index: index)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SyntaxHighlightedLine: View {
    let code: String
    
    private let keywords = ["print", "def", "class", "if", "else", "elif", "for", "while", "return", "import", "from", "as", "try", "except", "with", "lambda", "yield", "pass", "break", "continue", "None", "True", "False"]
    private let stringKeywords = ["str", "int", "float", "list", "dict", "set", "tuple", "bool"]

    var body: some View {
        Text(attributedCode())
            .font(.system(.body, design: .monospaced))
            .lineLimit(1)
    }

    private func attributedCode() -> AttributedString {
        var result = AttributedString(code)
        
        // Highlight comments first (everything after #)
        if let commentRange = result.range(of: "#") {
            result[commentRange.lowerBound..<result.endIndex].foregroundColor = .green
            return result  // Return early since comment consumes rest of line
        }
        
        // Highlight strings
        highlightStrings(&result)
        
        // Highlight keywords
        for keyword in keywords {
            highlightKeyword(keyword, in: &result, color: .purple)
        }
        
        // Highlight built-in types
        for keyword in stringKeywords {
            highlightKeyword(keyword, in: &result, color: .blue)
        }
        
        // Highlight numbers
        highlightNumbers(&result)
        
        return result
    }

    private func highlightStrings(_ result: inout AttributedString) {
        let text = String(result.characters)
        var searchRange = text.startIndex..<text.endIndex
        
        while let quoteRange = text.range(of: "\"", range: searchRange) {
            guard let endQuoteRange = text.range(of: "\"", range: quoteRange.upperBound..<text.endIndex) else {
                break
            }
            
            let stringRange = quoteRange.lowerBound..<endQuoteRange.upperBound
            if let attributedRange = result.range(of: String(text[stringRange])) {
                result[attributedRange].foregroundColor = .red
            }
            searchRange = endQuoteRange.upperBound..<text.endIndex
        }
    }

    private func highlightKeyword(_ keyword: String, in result: inout AttributedString, color: Color) {
        let pattern = "\\b\(keyword)\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let text = String(result.characters)
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches.reversed() {
            let nsRange = match.range
            if let range = Range(nsRange, in: text),
               let attributedRange = result.range(of: String(text[range])) {
                result[attributedRange].foregroundColor = color
            }
        }
    }

    private func highlightNumbers(_ result: inout AttributedString) {
        let pattern = "[0-9]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let text = String(result.characters)
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches.reversed() {
            let nsRange = match.range
            if let range = Range(nsRange, in: text),
               let attributedRange = result.range(of: String(text[range])) {
                result[attributedRange].foregroundColor = .orange
            }
        }
    }
}

struct OutputCellView: View {
    let output: Output
    let index: Int

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Out[\(output.executionCount ?? index)]")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text(output.content)
                .font(.system(.body, design: .monospaced))
                .lineLimit(nil)
                .textSelection(.enabled)
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(6)
    }
}

struct RawCellView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    JupyterNotebookView()
}
