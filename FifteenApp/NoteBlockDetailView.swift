
import SwiftUI

// MARK: - Note Block Detail View
struct NoteBlockDetailView: View {
    let block: RichNoteBlock
    
    @State private var showPDFViewer = false
    @State private var showFullSizeImage = false
    @State private var fullSizeImage: UIImage?
    let currentPage: Int
    
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
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            
            // Block Content
            if block.type == .text {
                textBlockView
            } else if block.type == .image, let imageData = block.imageData, let uiImage = UIImage(data: imageData) {
                imageBlockView(uiImage: uiImage)
            } else if block.type == .pdf {
                pdfBlockView
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
        .sheet(item: Binding(
            get: { fullSizeImage.map { ImageHolder(image: $0) } },
            set: { if $0 == nil { fullSizeImage = nil } }
        )) { holder in
            FullSizeImageViewer(
                image: holder.image
            )
        }
    }
    
    @ViewBuilder
    private var textBlockView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            
            Text(block.content)
                .font(.body)
                .lineSpacing(1.2)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func imageBlockView(uiImage: UIImage) -> some View {
        VStack(spacing: 0) {
            Divider()
            
            ZStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipped()
                
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                    
                    Spacer()
                }
            }
            .onTapGesture {
                fullSizeImage = uiImage
                showFullSizeImage = true
            }
        }
    }
    
    @ViewBuilder
    private var pdfBlockView: some View {
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
                
                Button(action: { showPDFViewer = true }) {
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
            return "PDF Document"
        }
    }
}

// MARK: - Image Holder (for sheet binding)
struct ImageHolder: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Full Size Image Viewer
struct FullSizeImageViewer: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureOffset = CGSize.zero
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: shareImage) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.7))
                
                // Image View with Zoom and Pan
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(x: offset.width + gestureOffset.width,
                                y: offset.height + gestureOffset.height)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scale = max(1.0, scale)
                                        }
                                    },
                                DragGesture()
                                    .updating($gestureOffset) { value, state, _ in
                                        state = value.translation
                                    }
                                    .onEnded { value in
                                        offset.width += value.translation.width
                                        offset.height += value.translation.height
                                    }
                            )
                        )
                    
                    // Reset Button (appears when zoomed)
                    if scale > 1.0 {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }) {
                                    Image(systemName: "arrow.down.left.and.arrow.up.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(16)
                            
                            Spacer()
                        }
                    }
                }
                
                // Footer Info
                VStack(spacing: 8) {
                    Divider()
                        .opacity(0)
                    
                    HStack {
                        if scale > 1.0 {
                            Text("Zoom: \(String(format: "%.1f", scale))x")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Pinch to zoom • Drag to pan")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("Double-tap to reset")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                }
                .background(Color.black.opacity(0.7))
            }
        }
        .onTapGesture(count: 2) {
            // Double tap to reset zoom
            withAnimation {
                scale = 1.0
                offset = .zero
            }
        }
    }
    
    private func shareImage() {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}
