import SwiftUI
import PDFKit

struct SplitScreenNoteEditorView: View {
    let originalNote: RichNote
    let pdfPageNumbersCopy: [UUID: Int] // compare with this to detect if page numbers have changed
    @State private var editingNote: RichNote
    @State private var selectedTextBlockId: UUID?
    @State private var selectedPDFBlockId: UUID?
    @State private var editingTextBlockId: UUID?
    @State private var selectedTab: Int = 0
    @State private var showPDFFullScreen = false
    @State private var isSaving = false
    @State private var showDiscardConfirmation = false
    @State private var pdfPageNumbers: [UUID: Int] = [:]
    @StateObject private var noteManager = RichNoteManager()
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
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
        self.pdfPageNumbersCopy = initialPageNumbers
    
    }
    
    var hasChanges: Bool {
        let titleChanged = editingNote.title != originalNote.title
        let blockCountChanged = editingNote.blocks.count != originalNote.blocks.count
        let blocksChanged = !blocksAreEqual()
        let pageNumbersChanged = (pdfPageNumbers != pdfPageNumbersCopy)
        //print(pageNumbersChanged)
        return titleChanged || blockCountChanged || blocksChanged || pageNumbersChanged
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
            // Landscape/iPad - Split Screen
            splitScreenLayout.toolbar(.hidden, for: .navigationBar)
        } else {
            // Portrait - Stacked Layout
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
                
                // Right Panel - PDF Viewer
                VStack(spacing: 0) {
                    pdfViewerHeader
                    pdfViewerContent
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
                    
                    pdfViewerContent
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
    
    // MARK: - PDF Viewer Header
    @ViewBuilder
    private var pdfViewerHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PDF Preview")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showPDFFullScreen = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            
            Divider()
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - PDF Viewer Content
    @ViewBuilder
    private var pdfViewerContent: some View {
        let pdfBlocks = editingNote.blocks.filter { $0.type == .pdf }
        
        if pdfBlocks.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("No PDFs")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Add a PDF block to view")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(pdfBlocks) { pdfBlock in
                        PDFPreviewCardView(
                            block: pdfBlock,
                            isSelected: selectedPDFBlockId == pdfBlock.id,
                            currentPage: Binding(
                                get: { pdfPageNumbers[pdfBlock.id] ?? 1 },
                                set: { pdfPageNumbers[pdfBlock.id] = $0 }
                            ),
                            onSelect: { selectedPDFBlockId = pdfBlock.id },
                            onFullScreen: { showPDFFullScreen = true }
                        )
                    }
                }
                .padding(12)
            }
        }
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
    
    private func saveNote() {
        isSaving = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var noteToSave = editingNote
            noteToSave.dateModified = Date()
            
            // Save PDF page numbers
            var pageNumbersDict: [String: Int] = [:]
            for (uuid, pageNumber) in pdfPageNumbers {
                pageNumbersDict[uuid.uuidString] = pageNumber
            }
            noteToSave.pdfPageNumbers = pageNumbersDict
            
            noteManager.saveNote(noteToSave)
            isSaving = false
            dismiss()
        }
    }
}



// MARK: - PDF Preview Card View
struct PDFPreviewCardView: View {
    let block: RichNoteBlock
    let isSelected: Bool
    @Binding var currentPage: Int
    let onSelect: () -> Void
    let onFullScreen: () -> Void
    
    @State private var showFullScreenPDF = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            HStack {
                Image(systemName: "doc.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.content)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text("\(block.pdfPageCount) pages")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { showFullScreenPDF = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            
            Divider()
            
            // PDF Preview
            if let pdfData = block.pdfData {
                PDFPreviewView(
                    pdfData: pdfData,
                    currentPage: $currentPage
                )
                .frame(height: 400)
                
                // Page Navigation
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        Button(action: {
                            if currentPage > 1 {
                                currentPage -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                        }
                        .disabled(currentPage <= 1)
                        
                        Spacer()
                        
                        Text("Page \(currentPage) of \(block.pdfPageCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < block.pdfPageCount {
                                currentPage += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .disabled(currentPage >= block.pdfPageCount)
                    }
                    .padding(12)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .border(isSelected ? Color.blue : Color.gray.opacity(0.3), width: 2)
        .onTapGesture {
            onSelect()
        }
        .sheet(isPresented: $showFullScreenPDF) {
            if let pdfData = block.pdfData {
                FullScreenPDFViewer(
                    pdfData: pdfData,
                    filename: block.content,
                    currentPage: $currentPage,
                    isPresented: $showFullScreenPDF
                )
            }
        }
    }
}

// MARK: - PDF Preview View (UIViewRepresentable)
struct PDFPreviewView: UIViewRepresentable {
    let pdfData: Data
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: pdfData)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.delegate = context.coordinator
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = uiView.document,
           document.pageCount > currentPage - 1,
           let page = document.page(at: currentPage - 1) {
            uiView.go(to: page)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        @Binding var currentPage: Int
        
        init(currentPage: Binding<Int>) {
            self._currentPage = currentPage
        }
        
        func pdfViewPageChanged(_ notification: Notification) {
            if let pdfView = notification.object as? PDFView,
               let document = pdfView.document,
               let currentPage = pdfView.currentPage {
                self.currentPage = (document.index(for: currentPage) ?? 0) + 1
            }
        }
    }
}

// MARK: - Full Screen PDF Viewer
struct FullScreenPDFViewer: View {
    let pdfData: Data
    let filename: String
    @Binding var currentPage: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(filename)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("Page \(currentPage)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.7))
                
                // PDF View
                PDFPreviewView(pdfData: pdfData, currentPage: $currentPage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Preview
struct SplitScreenNoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        SplitScreenNoteEditorView(note: RichNote(title: "Sample Note", blocks: [
            RichNoteBlock(type: .text, content: "This is sample text for editing")
        ]))
    }
}
