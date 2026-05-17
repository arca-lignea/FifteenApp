//
//  RichNotesListView.swift
//  FifteenApp
//
//  Created by sophie on 2026-05-12.
//

import SwiftUI
import PDFKit

// MARK: - Navigation Enum
enum RichNotesListNavigation: Hashable {
    case noteDetail(RichNote)
    case addNote
    case importExportNote
    case editNote(RichNote)
    case basicEditor(RichNote)
    case splitScreen(RichNote)
    case noteAndWeb(RichNote)
    case noteAndCode(RichNote)
    case noteAndNotebook(RichNote)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .noteDetail(let note):
            hasher.combine(note.id)
        case .addNote:
            hasher.combine("addNote")
        case .importExportNote:
            hasher.combine("importExportNote")
        case .editNote(let note):
            hasher.combine(note.id)
        case .basicEditor(let note):
            hasher.combine(note.id)
        case .splitScreen(let note):
            hasher.combine(note.id)
        case .noteAndWeb(let note):
            hasher.combine(note.id)
        case .noteAndCode(let note):
            hasher.combine(note.id)
        case .noteAndNotebook(let note):
            hasher.combine(note.id)
        }
        
    }
    
    static func == (lhs: RichNotesListNavigation, rhs: RichNotesListNavigation) -> Bool {
        switch (lhs, rhs) {
        case (.noteDetail(let note1), .noteDetail(let note2)):
            return note1.id == note2.id
        case (.addNote, .addNote):
            return true
        case (.importExportNote, .importExportNote):
            return true
        case (.editNote(let note1), .editNote(let note2)):
            return note1.id == note2.id
        case (.basicEditor(let note1), .basicEditor(let note2)):
            return note1.id == note2.id
        case (.splitScreen(let note1), .splitScreen(let note2)):
            return note1.id == note2.id
        case (.noteAndWeb(let note1), .noteAndWeb(let note2)):
            return note1.id == note2.id
        case (.noteAndCode(let note1), .noteAndCode(let note2)):
            return note1.id == note2.id
        case (.noteAndNotebook(let note1), .noteAndNotebook(let note2)):
            return note1.id == note2.id
        default:
            return false
        }
    }
}

// MARK: - Rich Notes List View
struct RichNotesListView: View {
    @State private var savedNotes: [RichNote] = []
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateModified
    @State private var showDeleteConfirmation = false
    @State private var noteToDelete: RichNote?
    @StateObject private var noteManager = RichNoteManager()
    @Environment(\.dismiss) var dismiss
    
    enum SortOption: String, CaseIterable {
        case dateModified = "Date Modified"
        case dateCreated = "Date Created"
        case titleAZ = "Title (A-Z)"
        case titleZA = "Title (Z-A)"
        case blockCount = "Block Count"
    }
    
    var filteredAndSortedNotes: [RichNote] {
        var filtered = savedNotes
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.blocks.contains { block in
                    block.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Sort
        switch sortOption {
        case .dateModified:
            return filtered.sorted { $0.dateModified > $1.dateModified }
        case .dateCreated:
            return filtered.sorted { $0.dateCreated > $1.dateCreated }
        case .titleAZ:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleZA:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .blockCount:
            return filtered.sorted { $0.blocks.count > $1.blocks.count }
        }
    }
    
    var body: some View {
        NavigationStack {
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
                        
                        Text("Saved Notes")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: { refreshNotes() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            
                            NavigationLink(value: RichNotesListNavigation.addNote) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            
                            NavigationLink(value: RichNotesListNavigation.importExportNote) {
                                Image(systemName: "square.and.arrow.up.on.square")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search notes...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    
                    // Sort Options
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: { sortOption = option }) {
                                        Text(option.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(sortOption == option ? Color.blue : Color(.systemGray6))
                                            .foregroundColor(sortOption == option ? .white : .gray)
                                            .cornerRadius(6)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                        }
                        Divider()
                    }
                    
                    // Stats Bar
                    if !savedNotes.isEmpty {
                        HStack(spacing: 16) {
                            Label("\(savedNotes.count) notes", systemImage: "doc.text")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Label("\(savedNotes.reduce(0) { $0 + $1.blocks.count }) blocks", systemImage: "square.stack.3d.up")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGray6).opacity(0.5))
                    }
                    
                    // Notes List
                    if filteredAndSortedNotes.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "note.text")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Notes Found")
                                .font(.headline)
                                .foregroundColor(.gray)
                            if !searchText.isEmpty {
                                Text("Try adjusting your search")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                VStack(spacing: 8) {
                                    Text("Create a new note to get started")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    NavigationLink(value: RichNotesListNavigation.addNote) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add New Note")
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredAndSortedNotes) { note in
                                    NavigationLink(value: RichNotesListNavigation.noteDetail(note)) {
                                        RichNoteListCard(note: note)
                                    }
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = note.title + "\n\n" + extractAllText(from: note)
                                        } label: {
                                            Label("Copy All Text", systemImage: "doc.on.doc")
                                        }
                                        
                                        NavigationLink(value: RichNotesListNavigation.editNote(note)) {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            noteToDelete = note
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(12)
                        }
                    }
                }
            }
            .navigationDestination(for: RichNotesListNavigation.self) { destination in
                switch destination {
                case .noteDetail(let note):
                    NoteDetailView(note: note, noteManager: noteManager)
                case .addNote:
                    RichNoteView()
                case .editNote(let note):
                    EditNoteView(note: note)
                case .importExportNote:
                    RichNoteImportExportView()
                case .basicEditor(let note):
                    EditNoteView(note: note)
                case .splitScreen(let note):
                    SplitScreenNoteEditorView(note: note)
                case .noteAndWeb(let note):
                    SplitScreenNoteAndWebView(note: note)
                case .noteAndCode(let note):
                    SplitScreenNoteAndCodeView(note: note)
                case .noteAndNotebook(let note):
                    JupyterNotebookView()
                }
            }
            .onAppear {
                refreshNotes()
            }
            .alert("Delete Note?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                }
                Button("Cancel", role: .cancel) {
                    noteToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this note? This action cannot be undone.")
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private func refreshNotes() {
        savedNotes = noteManager.loadNotes()
    }
    
    private func deleteNote(_ note: RichNote) {
        withAnimation {
            savedNotes.removeAll { $0.id == note.id }
            noteManager.deleteNote(note)
        }
        noteToDelete = nil
    }
    
    private func extractAllText(from note: RichNote) -> String {
        var text = ""
        for block in note.blocks {
            if block.type == .text {
                text += block.content + "\n"
            }
        }
        return text
    }
}

// MARK: - Rich Note List Card
struct RichNoteListCard: View {
    let note: RichNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Icons Row
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Label("\(note.blocks.count)", systemImage: "square.stack.3d.up")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(note.dateModified.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Block Type Icons
                HStack(spacing: 6) {
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
            
            // Preview
            if let textBlock = note.blocks.first(where: { $0.type == .text }) {
                Text(textBlock.content)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
            
            // Date Info
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Created")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(note.dateCreated.formatted(date: .abbreviated, time: .standard))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .frame(height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Modified")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(note.dateModified.formatted(date: .abbreviated, time: .standard))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .border(Color(.systemGray4), width: 0.5)
    }
}

// MARK: - Preview
struct RichNotesListView_Previews: PreviewProvider {
    static var previews: some View {
        RichNotesListView()
    }
}

