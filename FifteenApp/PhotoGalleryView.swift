import SwiftUI
import PhotosUI
import PDFKit

struct PhotoGalleryView: View {
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedPDFURL: URL?
    @State private var galleryPhotos: [GalleryPhoto] = []
    @State private var galleryPDFs: [GalleryPDF] = []
    @State private var selectedPhoto: GalleryPhoto?
    @State private var selectedPDF: GalleryPDF?
    @State private var showPhotoViewer = false
    @State private var showPDFViewer = false
    @State private var activeTab: GalleryTab = .photos
    @StateObject private var photoManager = PhotoManager()
    
    enum GalleryTab {
        case photos
        case pdfs
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Gallery")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        
                        if activeTab == .photos {
                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Button(action: { selectedPDFURL = nil }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                            .fileImporter(
                                isPresented: Binding(
                                    get: { selectedPDFURL == nil },
                                    set: { _ in }
                                ),
                                allowedContentTypes: [.pdf],
                                onCompletion: { result in
                                    if case .success(let url) = result {
                                        addPDFToGallery(url)
                                    }
                                }
                            )
                            .onTapGesture {
                                // Trigger file importer
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    selectedPDFURL = URL(fileURLWithPath: "")
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    
                    // Tab Selector
                    HStack(spacing: 0) {
                        Button(action: { activeTab = .photos }) {
                            VStack(spacing: 4) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 16))
                                Text("Photos")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(activeTab == .photos ? Color.blue.opacity(0.1) : Color.clear)
                            .foregroundColor(activeTab == .photos ? .blue : .gray)
                        }
                        
                        Divider()
                        
                        Button(action: { activeTab = .pdfs }) {
                            VStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 16))
                                Text("PDFs")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(activeTab == .pdfs ? Color.blue.opacity(0.1) : Color.clear)
                            .foregroundColor(activeTab == .pdfs ? .blue : .gray)
                        }
                    }
                    .background(Color(.systemGray6))
                    
                    // Content View
                    if activeTab == .photos {
                        PhotosTabView(
                            galleryPhotos: $galleryPhotos,
                            selectedPhoto: $selectedPhoto,
                            showPhotoViewer: $showPhotoViewer,
                            photoManager: photoManager
                        )
                    } else {
                        PDFsTabView(
                            galleryPDFs: $galleryPDFs,
                            selectedPDF: $selectedPDF,
                            showPDFViewer: $showPDFViewer,
                            photoManager: photoManager
                        )
                    }
                }
                
                // Photo Viewer Sheet
                if showPhotoViewer, let photo = selectedPhoto {
                    PhotoViewerSheet(
                        photo: photo,
                        isPresented: $showPhotoViewer,
                        photos: galleryPhotos,
                        onDelete: deletePhoto
                    )
                    .transition(.move(edge: .bottom))
                }
                
                // PDF Viewer Sheet
                if showPDFViewer, let pdf = selectedPDF {
                    PDFViewerSheet(
                        pdf: pdf,
                        isPresented: $showPDFViewer,
                        pdfs: galleryPDFs,
                        onDelete: deletePDF
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .onChange(of: selectedPhotos) { newPhotos in
                addPhotosToGallery(newPhotos)
            }
            .onAppear {
                galleryPhotos = photoManager.loadPhotos()
                galleryPDFs = photoManager.loadPDFs()
            }
        }
    }
    
    private func addPhotosToGallery(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        let photo = GalleryPhoto(
                            name: UUID().uuidString,
                            uiImage: uiImage,
                            imageData: data
                        )
                        galleryPhotos.append(photo)
                        photoManager.savePhoto(photo)
                    }
                }
            }
            selectedPhotos = []
        }
    }
    
    private func addPDFToGallery(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let pdf = GalleryPDF(
                name: filename,
                pdfData: data,
                pageCount: PDFDocument(data: data)?.pageCount ?? 0
            )
            galleryPDFs.append(pdf)
            photoManager.savePDF(pdf)
        } catch {
            print("Error loading PDF: \(error)")
        }
    }
    
    private func deletePhoto(_ photo: GalleryPhoto) {
        if let index = galleryPhotos.firstIndex(where: { $0.id == photo.id }) {
            galleryPhotos.remove(at: index)
            photoManager.deletePhoto(photo)
        }
        if selectedPhoto?.id == photo.id {
            selectedPhoto = nil
            showPhotoViewer = false
        }
    }
    
    private func deletePDF(_ pdf: GalleryPDF) {
        if let index = galleryPDFs.firstIndex(where: { $0.id == pdf.id }) {
            galleryPDFs.remove(at: index)
            photoManager.deletePDF(pdf)
        }
        if selectedPDF?.id == pdf.id {
            selectedPDF = nil
            showPDFViewer = false
        }
    }
}

// MARK: - Photos Tab View
struct PhotosTabView: View {
    @Binding var galleryPhotos: [GalleryPhoto]
    @Binding var selectedPhoto: GalleryPhoto?
    @Binding var showPhotoViewer: Bool
    let photoManager: PhotoManager
    
    var body: some View {
        if galleryPhotos.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                Text("No Photos Yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Tap the + button to add photos")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(galleryPhotos) { photo in
                        VStack(spacing: 0) {
                            ZStack {
                                if let uiImage = photo.uiImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                                
                                VStack {
                                    HStack {
                                        Spacer()
                                        Menu {
                                            Button(role: .destructive) {
                                                if let index = galleryPhotos.firstIndex(where: { $0.id == photo.id }) {
                                                    galleryPhotos.remove(at: index)
                                                    photoManager.deletePhoto(photo)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            
                                            Button {
                                                UIPasteboard.general.image = photo.uiImage
                                            } label: {
                                                Label("Copy", systemImage: "doc.on.doc")
                                            }
                                            
                                            Button {
                                                sharePhoto(photo)
                                            } label: {
                                                Label("Share", systemImage: "square.and.arrow.up")
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(8)
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedPhoto = photo
                                showPhotoViewer = true
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(photo.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Text(photo.dateAdded.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                        }
                    }
                }
                .padding(12)
            }
        }
    }
    
    private func sharePhoto(_ photo: GalleryPhoto) {
        guard let image = photo.uiImage else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - PDFs Tab View
struct PDFsTabView: View {
    @Binding var galleryPDFs: [GalleryPDF]
    @Binding var selectedPDF: GalleryPDF?
    @Binding var showPDFViewer: Bool
    let photoManager: PhotoManager
    @State private var isFileImporterPresented = false
    
    var body: some View {
        if galleryPDFs.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                Text("No PDFs Yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Tap the + button to add PDF files")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.pdf],
                onCompletion: { result in
                    if case .success(let url) = result {
                        addPDFToGallery(url)
                    }
                }
            )
        } else {
            List {
                ForEach(galleryPDFs) { pdf in
                    HStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                            Text("\(pdf.pageCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 50, height: 70)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pdf.name)
                                .font(.headline)
                                .lineLimit(2)
                            Text(pdf.dateAdded.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(pdf.pageCount) pages")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button(role: .destructive) {
                                if let index = galleryPDFs.firstIndex(where: { $0.id == pdf.id }) {
                                    galleryPDFs.remove(at: index)
                                    photoManager.deletePDF(pdf)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                sharePDF(pdf)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPDF = pdf
                        showPDFViewer = true
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func addPDFToGallery(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let pdf = GalleryPDF(
                name: filename,
                pdfData: data,
                pageCount: PDFDocument(data: data)?.pageCount ?? 0
            )
            galleryPDFs.append(pdf)
            photoManager.savePDF(pdf)
        } catch {
            print("Error loading PDF: \(error)")
        }
    }
    
    private func sharePDF(_ pdf: GalleryPDF) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(pdf.name)
        do {
            try pdf.pdfData.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            print("Error sharing PDF: \(error)")
        }
    }
}

// MARK: - PDF Viewer Sheet
struct PDFViewerSheet: View {
    let pdf: GalleryPDF
    @Binding var isPresented: Bool
    let pdfs: [GalleryPDF]
    let onDelete: (GalleryPDF) -> Void
    
    @State private var currentIndex: Int = 0
    @State private var currentPage: Int = 1
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(pdfs[currentIndex].name)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(currentPage) / \(pdfs[currentIndex].pageCount)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive) {
                            onDelete(pdfs[currentIndex])
                            isPresented = false
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.7))
                
                // PDF Viewer
                PDFKitView(pdfData: pdfs[currentIndex].pdfData, currentPage: $currentPage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Footer
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                currentIndex = max(0, currentIndex - 1)
                                currentPage = 1
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .disabled(currentIndex == 0)
                        
                        VStack(spacing: 4) {
                            Text("Document \(currentIndex + 1) of \(pdfs.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("Page \(currentPage) of \(pdfs[currentIndex].pageCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            withAnimation {
                                currentIndex = min(pdfs.count - 1, currentIndex + 1)
                                currentPage = 1
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .disabled(currentIndex == pdfs.count - 1)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            sharePDF(pdfs[currentIndex])
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(16)
                }
                .background(Color.black.opacity(0.7))
            }
        }
        .onAppear {
            currentIndex = pdfs.firstIndex(where: { $0.id == pdf.id }) ?? 0
        }
    }
    
    private func sharePDF(_ pdf: GalleryPDF) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(pdf.name)
        do {
            try pdf.pdfData.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            print("Error sharing PDF: \(error)")
        }
    }
}

// MARK: - PDFKit Wrapper
struct PDFKitView: UIViewRepresentable {
    let pdfData: Data
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: pdfData)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.delegate = context.coordinator
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update handled through delegate
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

// MARK: - Photo Model
struct GalleryPhoto: Identifiable, Codable {
    let id: UUID
    let name: String
    let dateAdded: Date
    let imageData: Data
    
    @Transient var uiImage: UIImage?
    
    init(name: String, uiImage: UIImage, imageData: Data) {
        self.id = UUID()
        self.name = name
        self.uiImage = uiImage
        self.imageData = imageData
        self.dateAdded = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, dateAdded, imageData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        imageData = try container.decode(Data.self, forKey: .imageData)
        uiImage = UIImage(data: imageData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(imageData, forKey: .imageData)
    }
}

// MARK: - PDF Model
struct GalleryPDF: Identifiable, Codable {
    let id: UUID
    let name: String
    let dateAdded: Date
    let pdfData: Data
    let pageCount: Int
    
    init(name: String, pdfData: Data, pageCount: Int) {
        self.id = UUID()
        self.name = name
        self.pdfData = pdfData
        self.pageCount = pageCount
        self.dateAdded = Date()
    }
}

struct PhotoViewerSheet: View {
    let photo: GalleryPhoto
    @Binding var isPresented: Bool
    let photos: [GalleryPhoto]
    let onDelete: (GalleryPhoto) -> Void
    
    @State private var currentIndex: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(photos[currentIndex].name)
                            .font(.caption)
                            .foregroundColor(.white)
                        Text(photos[currentIndex].dateAdded.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive) {
                            onDelete(photos[currentIndex])
                            isPresented = false
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            UIPasteboard.general.image = photos[currentIndex].uiImage
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.7))
                
                // Photo Carousel
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                            ZStack {
                                if let uiImage = photo.uiImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(offset)
                                        .gesture(
                                            SimultaneousGesture(
                                                MagnificationGesture()
                                                    .onChanged { value in
                                                        scale = value
                                                    }
                                                    .onEnded { _ in
                                                        withAnimation {
                                                            scale = 1.0
                                                        }
                                                    },
                                                DragGesture()
                                                    .onChanged { value in
                                                        offset = value.translation
                                                    }
                                                    .onEnded { _ in
                                                        withAnimation {
                                                            offset = .zero
                                                        }
                                                    }
                                            )
                                        )
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Navigation Arrows
                    HStack {
                        Button(action: {
                            withAnimation {
                                currentIndex = max(0, currentIndex - 1)
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .disabled(currentIndex == 0)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                currentIndex = min(photos.count - 1, currentIndex + 1)
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .disabled(currentIndex == photos.count - 1)
                    }
                    .padding(20)
                }
                
                // Footer
                VStack(spacing: 8) {
                    Text("\(currentIndex + 1) of \(photos.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            UIPasteboard.general.image = photos[currentIndex].uiImage
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        
                        Button(action: { sharePhoto(photos[currentIndex]) }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(16)
                }
                .background(Color.black.opacity(0.7))
            }
        }
        .onAppear {
            currentIndex = photos.firstIndex(where: { $0.id == photo.id }) ?? 0
        }
    }
    
    private func sharePhoto(_ photo: GalleryPhoto) {
        guard let image = photo.uiImage else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Photo Manager
class PhotoManager: NSObject, ObservableObject {
    private let photosKey = "SavedPhotos"
    private let pdfsKey = "SavedPDFs"
    
    func savePhoto(_ photo: GalleryPhoto) {
        var photos = loadPhotos()
        photos.append(photo)
        
        if let encoded = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(encoded, forKey: photosKey)
        }
    }
    
    func deletePhoto(_ photo: GalleryPhoto) {
        var photos = loadPhotos()
        photos.removeAll { $0.id == photo.id }
        
        if let encoded = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(encoded, forKey: photosKey)
        }
    }
    
    func loadPhotos() -> [GalleryPhoto] {
        if let data = UserDefaults.standard.data(forKey: photosKey),
           let decoded = try? JSONDecoder().decode([GalleryPhoto].self, from: data) {
            return decoded
        }
        return []
    }
    
    func savePDF(_ pdf: GalleryPDF) {
        var pdfs = loadPDFs()
        pdfs.append(pdf)
        
        if let encoded = try? JSONEncoder().encode(pdfs) {
            UserDefaults.standard.set(encoded, forKey: pdfsKey)
        }
    }
    
    func deletePDF(_ pdf: GalleryPDF) {
        var pdfs = loadPDFs()
        pdfs.removeAll { $0.id == pdf.id }
        
        if let encoded = try? JSONEncoder().encode(pdfs) {
            UserDefaults.standard.set(encoded, forKey: pdfsKey)
        }
    }
    
    func loadPDFs() -> [GalleryPDF] {
        if let data = UserDefaults.standard.data(forKey: pdfsKey),
           let decoded = try? JSONDecoder().decode([GalleryPDF].self, from: data) {
            return decoded
        }
        return []
    }
}

// MARK: - Helper for Transient Property
@propertyWrapper
struct Transient<Value> {
    var wrappedValue: Value?
}

