//
//  EditNoteView.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-04.
//

import SwiftUI
import PhotosUI
import PDFKit

struct EditNoteView: View {
    let originalNote: RichNote
    @State private var editingNote: RichNote
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedPDFURL: URL?
    @State private var showMediaMenu = false
    @State private var showTextBlockEditor = false
    @State private var editingBlockId: UUID?
    @State private var showDiscardConfirmation = false
    @State private var pdfPageNumbers: [UUID: Int] = [:]
    @State private var isSaving = false
    @State private var showPasteNotification = false
    @State private var pasteNotificationMessage = ""
    @State private var isAddingPDF = false
    @StateObject private var noteManager = RichNoteManager()
    @Environment(\.dismiss) var dismiss
    
    init(note: RichNote) {
        self.originalNote = note
        self._editingNote = State(initialValue: note)
        // Initialize pdfPageNumbers from saved state
        var initialPageNumbers: [UUID: Int] = [:]
        for (uuidString, pageNumber) in note.pdfPageNumbers {
            if let uuid = UUID(uuidString: uuidString) {
                initialPageNumbers[uuid] = pageNumber
            }
        }
        self._pdfPageNumbers = State(initialValue: initialPageNumbers)
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

            ZStack {
                mainContent
                mediaMenuOverlay
                textBlockEditorSheet
                pasteNotificationOverlay
            }
            .onChange(of: selectedPhotos) { newPhotos in
                addPhotos(newPhotos)
            }
            .alert("Discard Changes?", isPresented: $showDiscardConfirmation) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .toolbar(.hidden, for: .navigationBar)
        
    }
    
    // MARK: - Body Sub-Views
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            titleInputView
            metadataView
            contentBlocksView
            addButtonBarView
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
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
            
            Button(action: saveNote) {
                if isSaving {
                    ProgressView()
                        .tint(.blue)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .disabled(isSaving)
        }
        .padding(16)
        .background(Color(.systemGray6))
    }
    
    @ViewBuilder
    private var titleInputView: some View {
        VStack(spacing: 0) {
            TextField("Note Title", text: $editingNote.title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(16)
            
            Divider()
        }
        .background(Color(.systemGray6).opacity(1))
    }
    
    @ViewBuilder
    private var metadataView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(editingNote.dateCreated.formatted(date: .abbreviated, time: .standard))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Modified")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(editingNote.dateModified.formatted(date: .abbreviated, time: .standard))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if hasChanges {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Unsaved")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(1))
            .cornerRadius(8)
        }
        .padding(12)
    }
    
    @ViewBuilder
    private var contentBlocksView: some View {
        if editingNote.blocks.isEmpty {
            emptyStateView
        } else {
            blocksScrollView
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No Content")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Add text, images, or PDFs")
                .font(.caption)
                .foregroundColor(.gray)
            Text("or paste an image (Cmd+V)")
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var blocksScrollView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(editingNote.blocks.enumerated()), id: \.element.id) { index, block in
                    EditableRichNoteBlockView(
                        block: $editingNote.blocks[index],
                        currentPage: pdfPageNumbers[block.id] ?? 1,
                        blockIndex: index,
                        totalBlocks: editingNote.blocks.count,
                        onDelete: {
                            editingNote.blocks.remove(at: index)
                        },
                        onMoveUp: {
                            if index > 0 {
                                editingNote.blocks.swapAt(index, index - 1)
                            }
                        },
                        onMoveDown: {
                            if index < editingNote.blocks.count - 1 {
                                editingNote.blocks.swapAt(index, index + 1)
                            }
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
    }
    
    @ViewBuilder
    private var addButtonBarView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 8) {
                Button(action: {
                    editingNote.blocks.append(RichNoteBlock(type: .text, content: ""))
                    editingBlockId = editingNote.blocks.last?.id
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
                
                pasteImageButton
                
                Spacer()
            }
            .padding(12)
            .background(Color(.systemGray6))
        }
    }
    
    @ViewBuilder
    private var pasteImageButton: some View {
        PasteButton(supportedContentTypes: [.image]) { itemProviders in
            for provider in itemProviders {
                // Load the NSItemProvider as a UIImage
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            addImageBlock(image)
                        }
                    }
                }
            }
        }
        .buttonStyle(.bordered)
    }
    
    @ViewBuilder
    private var mediaMenuOverlay: some View {
        if showMediaMenu {
            VStack(spacing: 0) {
                Spacer()
                
                mediaMenuContent
            }
            .background(Color.black.opacity(0.3))
            .ignoresSafeArea()
            .onTapGesture {
                showMediaMenu = false
            }
        }
    }
    
    @ViewBuilder
    private var mediaMenuContent: some View {
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
            
            pdfPickerButton
            
            Divider()
                .padding(.horizontal, 16)
            
            Button(action: { showMediaMenu = false }) {
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
    
    @ViewBuilder
    private var pdfPickerButton: some View {
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
    }
    
    @ViewBuilder
    private var textBlockEditorSheet: some View {
        if showTextBlockEditor, let blockId = editingBlockId,
           let index = editingNote.blocks.firstIndex(where: { $0.id == blockId }) {
            TextBlockEditorSheet(
                block: $editingNote.blocks[index],
                isPresented: $showTextBlockEditor
            )
            .transition(.move(edge: .bottom))
        }
    }
    
    @ViewBuilder
    private var pasteNotificationOverlay: some View {
        if showPasteNotification {
            VStack {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    
                    Text(pasteNotificationMessage)
                        .font(.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding(16)
                
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    // MARK: - Methods
    
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
                        editingNote.blocks.append(block)
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
            editingNote.blocks.append(block)
        } catch {
            print("Error loading PDF: \(error)")
        }
    }

    
    private func addImageBlock(_ uiImage: UIImage) {
        if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
            let block = RichNoteBlock(
                type: .image,
                content: "",
                imageData: imageData,
                uiImage: uiImage
            )
            editingNote.blocks.append(block)
            
            showPasteNotification = true
            pasteNotificationMessage = "Image pasted successfully"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showPasteNotification = false
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        
        if let image = pasteboard.image {
            addImageBlock(image)
            showMediaMenu = false
        } else {
            showPasteNotification = true
            pasteNotificationMessage = "No image in clipboard"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showPasteNotification = false
                }
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

// MARK: - Existing Sub-Views (EditableRichNoteBlockView, TextBlockEditorSheet, etc.)
// ... (keep all the existing sub-views as they were)

// MARK: - Editable Rich Note Block View
struct EditableRichNoteBlockView: View {
    @Binding var block: RichNoteBlock
    let currentPage: Int
    let blockIndex: Int
    let totalBlocks: Int
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onEdit: () -> Void
    
    @State private var showPDFViewer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Block Header with Actions
            HStack(spacing: 8) {
                Image(systemName: blockIcon)
                    .font(.system(size: 14))
                    .foregroundColor(blockColor)
                
                Text("\(blockTitle) #\(blockIndex + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Movement Buttons
                Button(action: onMoveUp) {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .disabled(blockIndex == 0)
                
                Button(action: onMoveDown) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .disabled(blockIndex == totalBlocks - 1)
                
                // Menu
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
                EditableTextBlockContentView(block: block, onEdit: onEdit)
            } else if block.type == .image, let imageData = block.imageData, let uiImage = UIImage(data: imageData) {
                EditableImageBlockContentView(image: uiImage)
            } else if block.type == .pdf {
                EditablePDFBlockContentView(
                    block: block,
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
                                 currentPage: currentPage)
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
            return "Text"
        case .image:
            return "Image"
        case .pdf:
            return "PDF"
        }
    }
}

// MARK: - Editable Text Block Content View
struct EditableTextBlockContentView: View {
    let block: RichNoteBlock
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                if block.content.isEmpty {
                    HStack {
                        Text("Tap to add text")
                            .font(.body)
                            .foregroundColor(.gray)
                        Spacer()
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                } else {
                    HStack(alignment: .top) {
                        Text(block.content)
                            .font(.body)
                            .lineLimit(5)
                        
                        Spacer()
                        
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                onEdit()
            }
        }
    }
}

// MARK: - Editable Image Block Content View
struct EditableImageBlockContentView: View {
    let image: UIImage
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
                .clipped()
        }
    }
}

// MARK: - Editable PDF Block Content View
struct EditablePDFBlockContentView: View {
    let block: RichNoteBlock
    let onShowViewer: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                VStack(spacing: 4) {
                    Text(block.content)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(block.pdfPageCount) pages")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Button(action: onShowViewer) {
                    Label("Preview", systemImage: "eye")
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






