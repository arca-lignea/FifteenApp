//
//  RichNoteImportExportView.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-09.
//


import SwiftUI
import UniformTypeIdentifiers

struct RichNoteImportExportView: View {
    @State private var savedNotes: [RichNote] = []
    @State private var selectedNotes: Set<UUID> = []
    @State private var showExportOptions = false
    @State private var showImportFileImporter = false
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var exportMessage = ""
    @State private var importMessage = ""
    @State private var isProcessing = false
    @StateObject private var noteManager = RichNoteManager()
    @Environment(\.dismiss) var dismiss
    
    var selectedNotesCount: Int {
        selectedNotes.count
    }
    
    var body: some View {
        NavigationView {
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
                        
                        Text("Import/Export")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Export Section
                            exportSection
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Import Section
                            importSection
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Notes List
                            notesListSection
                        }
                        .padding(16)
                    }
                }
                
                // Success Notifications
                if showExportSuccess {
                    successNotification(message: exportMessage, isShowing: $showExportSuccess)
                }
                
                if showImportSuccess {
                    successNotification(message: importMessage, isShowing: $showImportSuccess)
                }
            }
            .onAppear {
                loadNotes()
            }
            .fileImporter(
                isPresented: $showImportFileImporter,
                allowedContentTypes: [.json],
                onCompletion: handleImportFile
            )
        }
    }
    
    // MARK: - Export Section
    @ViewBuilder
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Notes")
                        .font(.headline)
                    Text("Export selected notes as JSON")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                if selectedNotesCount > 0 {
                    Text("\(selectedNotesCount) selected")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: { selectedNotes.removeAll() }) {
                        Text("Clear Selection")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if selectedNotesCount > 0 {
                        exportSelectedNotes()
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("Export Selected")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(selectedNotesCount > 0 ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(selectedNotesCount == 0 || isProcessing)
                
                Button(action: exportAllNotes) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("Export All")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(savedNotes.isEmpty ? Color.gray.opacity(0.3) : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(savedNotes.isEmpty || isProcessing)
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Import Section
    @ViewBuilder
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import Notes")
                        .font(.headline)
                    Text("Import notes from JSON file")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Button(action: { showImportFileImporter = true }) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14))
                    Text("Choose File")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isProcessing)
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Notes List Section
    @ViewBuilder
    private var notesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Notes (\(savedNotes.count))")
                    .font(.headline)
                
                Spacer()
                
                if selectedNotesCount > 0 {
                    Text("\(selectedNotesCount) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if savedNotes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No Notes")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                VStack(spacing: 8) {
                    ForEach(savedNotes) { note in
                        NoteSelectionRowView(
                            note: note,
                            isSelected: selectedNotes.contains(note.id),
                            onToggle: {
                                if selectedNotes.contains(note.id) {
                                    selectedNotes.remove(note.id)
                                } else {
                                    selectedNotes.insert(note.id)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Success Notification
    @ViewBuilder
    private func successNotification(message: String, isShowing: Binding<Bool>) -> some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text(message)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    isShowing.wrappedValue = false
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadNotes() {
        savedNotes = noteManager.loadNotes().sorted { $0.dateModified > $1.dateModified }
    }
    
    private func exportSelectedNotes() {
        let notesToExport = savedNotes.filter { selectedNotes.contains($0.id) }
        exportNotes(notesToExport, filename: "rich_notes_selected_\(Date().formatted(date: .abbreviated, time: .omitted)).json")
    }
    
    private func exportAllNotes() {
        exportNotes(savedNotes, filename: "rich_notes_all_\(Date().formatted(date: .abbreviated, time: .omitted)).json")
    }
    
    private func exportNotes(_ notes: [RichNote], filename: String) {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(notes)
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try jsonData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    isProcessing = false
                    shareFile(at: tempURL)
                    
                    exportMessage = "\(notes.count) note(s) exported successfully"
                    showExportSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    exportMessage = "Export failed: \(error.localizedDescription)"
                    showExportSuccess = true
                }
            }
        }
    }
    
    private func handleImportFile(_ result: Result<URL, Error>) {
        isProcessing = true
        
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                isProcessing = false
                importMessage = "Unable to access file"
                showImportSuccess = true
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let importedNotes = try decoder.decode([RichNote].self, from: data)
                    
                    DispatchQueue.main.async {
                        var currentNotes = noteManager.loadNotes()
                        var importCount = 0
                        
                        for importedNote in importedNotes {
                            // Check if note already exists
                            if !currentNotes.contains(where: { $0.id == importedNote.id }) {
                                currentNotes.append(importedNote)
                                importCount += 1
                            }
                        }
                        
                        // Save all notes
                        if let encoded = try? JSONEncoder().encode(currentNotes) {
                            UserDefaults.standard.set(encoded, forKey: "SavedRichNotes")
                            UserDefaults.standard.synchronize()
                        }
                        
                        isProcessing = false
                        loadNotes()
                        
                        importMessage = "\(importCount) note(s) imported successfully"
                        showImportSuccess = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        isProcessing = false
                        importMessage = "Import failed: \(error.localizedDescription)"
                        showImportSuccess = true
                    }
                }
            }
            
        case .failure(let error):
            isProcessing = false
            importMessage = "File selection failed: \(error.localizedDescription)"
            showImportSuccess = true
        }
    }
    
    private func shareFile(at url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Note Selection Row View
struct NoteSelectionRowView: View {
    let note: RichNote
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label("\(note.blocks.count)", systemImage: "square.stack.3d.up")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(note.dateModified.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if note.blocks.contains(where: { $0.type == .text }) {
                        Image(systemName: "text.alignleft")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    if note.blocks.contains(where: { $0.type == .image }) {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    if note.blocks.contains(where: { $0.type == .pdf }) {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - JSON UTType Extension
extension UTType {
    static var json: UTType {
        UTType(tag: "json", tagClass: .filenameExtension, conformingTo: .data) ?? .data
    }
}

// MARK: - Preview
struct RichNoteImportExportView_Previews: PreviewProvider {
    static var previews: some View {
        RichNoteImportExportView()
    }
}
