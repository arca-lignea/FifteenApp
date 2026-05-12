//
//  SavedNotesView.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-03.
//

import SwiftUI
import PDFKit

struct SavedNotesView: View {
    @State private var savedNotes: [RichNote] = []
    @State private var selectedNote: RichNote?
    @State private var showNoteViewer = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateModified
    @StateObject private var noteManager = RichNoteManager()
    @Environment(\.dismiss) var dismiss
    
    enum SortOption: String, CaseIterable {
        case dateModified = "Date Modified"
        case dateCreated = "Date Created"
        case titleAZ = "Title (A-Z)"
        case titleZA = "Title (Z-A)"
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
                        
                        Button(action: { refreshNotes() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
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
                                Text("Create a new note to get started")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                    } else {
                        List {
                            ForEach(filteredAndSortedNotes) { note in
                                Section
                                {
                                    VStack {
                                        NavigationLink(value: NavigationDestinationEnum.noteDetail(note) )
                                        {
                                            //SavedNoteRowView(note: note)
                                            
                                        }
                                    }
                                }
//                                .contextMenu {
//                                    Button {
//                                        selectedNote = note
//                                        showNoteViewer = true
//                                    } label: {
//                                        Label("View", systemImage: "eye")
//                                    }
//                                    
//                                    Button {
//                                        UIPasteboard.general.string = note.title + "\n\n" + extractAllText(from: note)
//                                    } label: {
//                                        Label("Copy All Text", systemImage: "doc.on.doc")
//                                    }
//                                    
//                                    Button(role: .destructive) {
//                                        deleteNote(note)
//                                    } label: {
//                                        Label("Delete", systemImage: "trash")
//                                    }
//                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationDestination(for: NavigationDestinationEnum.self) { destination in
                if case .noteDetail(let note) = destination {
                        NoteDetailView(note: note, noteManager: noteManager)
                }
            }
            .onAppear {
                refreshNotes()
            }
            .sheet(isPresented: $showNoteViewer) {
                if let note = selectedNote {
                    NoteDetailView(note: note, noteManager: noteManager)
                }
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


// MARK: - Saved Note Row View
struct SavedNoteRowView: View {
    let note: RichNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and Block Count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.headline)
                        .lineLimit(1)
                    
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
                
                // Block Type Icons
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
            
            // Preview
            if let textBlock = note.blocks.first(where: { $0.type == .text }) {
                Text(textBlock.content)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}



// MARK: - Note Block Detail View
//struct NoteBlockDetailView: View {
//    let block: RichNoteBlock
//    
//    @State private var showPDFViewer = false
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Block Header
//            HStack {
//                Image(systemName: blockIcon)
//                    .font(.system(size: 14))
//                    .foregroundColor(blockColor)
//                
//                Text(blockTitle)
//                    .font(.caption)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.gray)
//                
//                Spacer()
//            }
//            .padding(12)
//            .background(Color(.systemGray6).opacity(0.5))
//            
//            // Block Content
//            if block.type == .text {
//                VStack(alignment: .leading, spacing: 0) {
//                    Divider()
//                    
//                    Text(block.content)
//                        .font(.body)
//                        .lineSpacing(1.2)
//                        .padding(12)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                }
//            } else if block.type == .image, let imageData = block.imageData, let uiImage = UIImage(data: imageData) {
//                VStack(spacing: 0) {
//                    Divider()
//                    
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(maxHeight: 300)
//                        .clipped()
//                }
//            } else if block.type == .pdf {
//                VStack(spacing: 0) {
//                    Divider()
//                    
//                    VStack(spacing: 12) {
//                        Image(systemName: "doc.fill")
//                            .font(.system(size: 40))
//                            .foregroundColor(.orange)
//                        
//                        VStack(spacing: 4) {
//                            Text(block.content)
//                                .font(.headline)
//                                .lineLimit(1)
//                            
//                            Text("\(block.pdfPageCount) pages")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        
//                        Button(action: { showPDFViewer = true }) {
//                            Label("View PDF", systemImage: "eye")
//                                .frame(maxWidth: .infinity)
//                                .padding(10)
//                                .background(Color.orange.opacity(0.1))
//                                .foregroundColor(.orange)
//                                .cornerRadius(6)
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(16)
//                }
//            }
//        }
//        .background(Color(.systemBackground))
//        .cornerRadius(8)
//        .border(Color(.systemGray4), width: 0.5)
//        .sheet(isPresented: $showPDFViewer) {
//            if let pdfData = block.pdfData {
//                PDFViewerForNote(pdfData: pdfData, filename: block.content)
//            }
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
//            return "PDF Document"
//        }
//    }
//}


// MARK: - Preview
struct SavedNotesView_Previews: PreviewProvider {
    static var previews: some View {
        SavedNotesView()
    }
}
