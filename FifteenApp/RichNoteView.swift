
import SwiftUI
import PhotosUI
import PDFKit


struct RichNoteView: View {
    @State private var note = RichNote(title: "", blocks: [])
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedPDFURL: URL?
    @State private var showMediaMenu = false
    @State private var showTextBlockEditor = false
    @State private var editingBlockId: UUID?
    @State private var isAddingPDF = false
    @StateObject private var noteManager = RichNoteManager()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("Rich Note")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: saveNote) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                
                // Title Input
                TextField("Note Title", text: $note.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(16)
                    .background(Color(.systemGray6).opacity(0.5))
                
                Divider()
                
                // Content Blocks
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach($note.blocks) { $block in
                            RichNoteBlockView(
                                block: $block,
                                onDelete: {
                                    note.blocks.removeAll { $0.id == block.id }
                                },
                                onEdit: {
                                    editingBlockId = block.id
                                    showTextBlockEditor = true
                                }
                            )
                        }
                    }
                    .padding(12)
                }
                
                Divider()
                
                // Add Content Button Bar
                HStack(spacing: 8) {
                    Button(action: {
                        note.blocks.append(RichNoteBlock(type: .text, content: ""))
                        editingBlockId = note.blocks.last?.id
                        showTextBlockEditor = true
                    }) {
                        Label("Text", systemImage: "text.alignleft")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { showMediaMenu.toggle() }) {
                        Label("Media", systemImage: "photo.stack")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
                .padding(12)
                .background(Color(.systemGray6))
            }
            
            // Media Menu
            if showMediaMenu {
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Add Media")
                                .font(.headline)
                            Spacer()
                            Button(action: { showMediaMenu = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(16)
                        
                        Divider()
                        
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.blue)
                                Text("Add Photos")
                                Spacer()
                            }
                            .padding(12)
                            .contentShape(Rectangle())
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            print("pdf: \(isAddingPDF)")
                            isAddingPDF = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedPDFURL = URL(fileURLWithPath: "")
                            }
                        }) {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.orange)
                                Text("Add PDF")
                                Spacer()
                            }
                            .padding(12)
                            .contentShape(Rectangle())
                        }
                        .fileImporter(
                            isPresented: $isAddingPDF,
                            allowedContentTypes: [.pdf],
                            onCompletion: { result in
                                if case .success(let url) = result {
                                    addPDFBlock(url)
                                    showMediaMenu = false
                                }
                                
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            showMediaMenu = false
                            print("cancel: \(isAddingPDF)")
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.gray)
                                Text("Cancel")
                                Spacer()
                            }
                            .padding(12)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                }
                .background(Color.black.opacity(0.3))
                .ignoresSafeArea()
                .onTapGesture {
                    showMediaMenu = false
                }
            }
            
            // Text Block Editor Sheet
            if showTextBlockEditor, let blockId = editingBlockId,
               let index = note.blocks.firstIndex(where: { $0.id == blockId }) {
                TextBlockEditorSheet(
                    block: $note.blocks[index],
                    isPresented: $showTextBlockEditor
                )
                .transition(.move(edge: .bottom))
            }
        }
        .onChange(of: selectedPhotos) { newPhotos in
            addPhotos(newPhotos)
        }
        .onAppear {
            // Initialize with new note or load existing
            note = RichNote(title: "", blocks: [])
        }
        .navigationBarHidden(true)
    }
    
    private func addPhotos(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        let block = RichNoteBlock(
                            type: .image,
                            content: "",
                            imageData: data,
                            uiImage: uiImage
                        )
                        note.blocks.append(block)
                    }
                }
            }
            selectedPhotos = []
        }
    }
    
    private func addPDFBlock(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let pageCount = PDFDocument(data: data)?.pageCount ?? 0
            
            let block = RichNoteBlock(
                type: .pdf,
                content: filename,
                pdfData: data,
                pdfPageCount: pageCount
            )
            note.blocks.append(block)
        } catch {
            print("Error loading PDF: \(error)")
        }
    }
    
    private func saveNote() {
        var noteToSave = note
        noteToSave.dateModified = Date()
        noteManager.saveNote(noteToSave)
        print("Saved note with ID: \(note.id), Title: \(note.title)")
        dismiss()
    }
}

// MARK: - Rich Note Block View
struct RichNoteBlockView: View {
    @Binding var block: RichNoteBlock
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var showPDFViewer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Block Header
            HStack {
                Image(systemName: blockIcon)
                    .font(.system(size: 14))
                    .foregroundColor(blockColor)
                
                Text(blockTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            
            // Block Content
            if block.type == .text {
                TextBlockContentView(block: block, onEdit: onEdit)
            } else if block.type == .image, let imageData = block.imageData, let uiImage = UIImage(data: imageData) {
                ImageBlockContentView(image: uiImage)
            } else if block.type == .pdf, let pdfData = block.pdfData {
                PDFBlockContentView(
                    pdfData: pdfData,
                    filename: block.content,
                    pageCount: block.pdfPageCount,
                    onShowViewer: { showPDFViewer = true }
                )
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .border(Color(.systemGray4), width: 0.5)
        .sheet(isPresented: $showPDFViewer) {
            if let pdfData = block.pdfData {
                PDFViewerForNote(pdfData: pdfData, 
                                 filename: block.content,
                                 currentPage: 1)
            }
        }
    }
    
    private var blockIcon: String {
        switch block.type {
        case .text:
            return "text.alignleft"
        case .image:
            return "photo.fill"
        case .pdf:
            return "doc.fill"
        }
    }
    
    private var blockColor: Color {
        switch block.type {
        case .text:
            return .blue
        case .image:
            return .green
        case .pdf:
            return .orange
        }
    }
    
    private var blockTitle: String {
        switch block.type {
        case .text:
            return "Text Block"
        case .image:
            return "Image"
        case .pdf:
            return "PDF Document"
        }
    }
}

// MARK: - Text Block Content View
struct TextBlockContentView: View {
    let block: RichNoteBlock
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(block.content.isEmpty ? "Empty text block - tap to edit" : block.content)
                    .font(.body)
                    .foregroundColor(block.content.isEmpty ? .gray : .primary)
                    .lineLimit(5)
                    .padding(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                onEdit()
            }
        }
    }
}

// MARK: - Image Block Content View
struct ImageBlockContentView: View {
    let image: UIImage
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipped()
        }
    }
}

// MARK: - PDF Block Content View
struct PDFBlockContentView: View {
    let pdfData: Data
    let filename: String
    let pageCount: Int
    let onShowViewer: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                VStack(spacing: 4) {
                    Text(filename)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(pageCount) pages")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Button(action: onShowViewer) {
                    Label("View PDF", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        }
    }
}



// MARK: - Rich Note Model
struct RichNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var blocks: [RichNoteBlock]
    let dateCreated: Date
    var dateModified: Date
    var pdfPageNumbers: [String: Int] = [:]
    
    init(title: String, blocks: [RichNoteBlock]) {
        self.id = UUID()
        self.title = title
        self.blocks = blocks
        self.dateCreated = Date()
        self.dateModified = Date()
        self.pdfPageNumbers = [:]
        print("creating new richnote with ID: \(id.uuidString)")
    }
}

// MARK: - Rich Note Block Model
struct RichNoteBlock: Identifiable, Codable {
    enum BlockType: String, Codable {
        case text
        case image
        case pdf
    }
    
    let id: UUID
    let type: BlockType
    var content: String
    let imageData: Data?
    let pdfData: Data?
    let pdfPageCount: Int
    
    @Transient2 var uiImage: UIImage?
    
    init(type: BlockType, content: String, imageData: Data? = nil, pdfData: Data? = nil, pdfPageCount: Int = 0, uiImage: UIImage? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.imageData = imageData
        self.pdfData = pdfData
        self.pdfPageCount = pdfPageCount
        self.uiImage = uiImage
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, content, imageData, pdfData, pdfPageCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(BlockType.self, forKey: .type)
        content = try container.decode(String.self, forKey: .content)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        pdfData = try container.decodeIfPresent(Data.self, forKey: .pdfData)
        pdfPageCount = try container.decodeIfPresent(Int.self, forKey: .pdfPageCount) ?? 0
        
        if let imageData = imageData {
            uiImage = UIImage(data: imageData)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encodeIfPresent(pdfData, forKey: .pdfData)
        try container.encode(pdfPageCount, forKey: .pdfPageCount)
    }
}




@propertyWrapper
struct Transient2<Value> {
    var wrappedValue: Value?
}

// MARK: - Preview
//struct RichNoteView_Previews: PreviewProvider {
//    static var previews: some View {
//        RichNoteView()
//    }
//}
