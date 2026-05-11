//
//  TextBlockEditorSheet.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-04.
//
import SwiftUI

// MARK: - Text Block Editor Sheet
struct TextBlockEditorSheet: View {
    @Binding var block: RichNoteBlock
    @Binding var isPresented: Bool
    
    @State private var editingText: String = ""
    @State private var characterCount: Int = 0
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("Edit Text")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        block.content = editingText
                        isPresented = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                
                // Character Count
                HStack {
                    Text("\(characterCount) characters")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Text Editor
                TextEditor(text: $editingText)
                    .font(.body)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                    .onChange(of: editingText) { newValue in
                        characterCount = newValue.count
                    }
            }
        }
        .onAppear {
            editingText = block.content
            characterCount = block.content.count
        }
    }
}
