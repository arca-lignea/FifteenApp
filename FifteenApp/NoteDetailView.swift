//
//  NoteDetailView.swift
//  FifteenApp
//
//  Created by sophie on 2026-05-10.
//

import SwiftUI

// MARK: - Note Detail View
struct NoteDetailView: View {
    let note: RichNote
    let noteManager: RichNoteManager
    @Environment(\.dismiss) var dismiss
    
    @State private var editedNote: RichNote
    @State private var showEditSheet = false
    @State private var viewingBlockId: UUID?
    @State private var pdfPageNumbers: [UUID: Int] = [:]
    @State private var selectedEditView: String = ""
    @State private var editViewActive = false
    
    init(note: RichNote, noteManager: RichNoteManager) {
        self.note = note
        self.noteManager = noteManager
        self._editedNote = State(initialValue: note)
        // Initialize pdfPageNumbers from saved state
        var initialPageNumbers: [UUID: Int] = [:]
        for (uuidString, pageNumber) in note.pdfPageNumbers {
            if let uuid = UUID(uuidString: uuidString) {
                initialPageNumbers[uuid] = pageNumber
            }
        }
        self._pdfPageNumbers = State(initialValue: initialPageNumbers)
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
                        
                        NavigationLink(destination: EditNoteView(note: editedNote))
                        {
                            Image(systemName: "pencil.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            
                        }
                        
                        NavigationLink(destination: SplitScreenNoteEditorView(note: editedNote))
                        {
                            Image(systemName: "pencil.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                            
                        }
                        
                        NavigationLink(destination: SplitScreenNoteAndWebView(note: editedNote))
                        {
                            Image(systemName: "pencil.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.yellow)
                            
                        }
                        
                        NavigationLink(destination: SplitScreenNoteAndCodeView(note: editedNote))
                        {
                            Image(systemName: "pencil.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.pink)
                            
                        }
                        
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    
                    // Note Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Title
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Created")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(note.dateCreated.formatted(date: .abbreviated, time: .standard))
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Divider()
                                        .frame(height: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Modified")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(note.dateModified.formatted(date: .abbreviated, time: .standard))
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(8)
                            
                            // Blocks
                            if note.blocks.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "square.stack.3d.up")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                    Text("No Content")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(32)
                            } else {
                                ForEach(note.blocks) { block in
                                    NoteBlockDetailView(block: block,
                                                        currentPage: pdfPageNumbers[block.id] ?? 1)
                                }
                            }
                        }
                        .padding(16)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 8) {
                        Divider()
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                let allText = note.blocks
                                    .filter { $0.type == .text }
                                    .map { $0.content }
                                    .joined(separator: "\n\n")
                                UIPasteboard.general.string = allText.isEmpty ? note.title : note.title + "\n\n" + allText
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { shareNote() }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(.systemBackground))
                    
                }
                
                // Edit Sheet
                //if showEditSheet {
                //    EditNoteView(note: editedNote).transition(.move(edge: .bottom))
                //}
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func shareNote() {
        var shareText = note.title + "\n\n"
        for block in note.blocks where block.type == .text {
            shareText += block.content + "\n\n"
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}
