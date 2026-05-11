//
//  InPlaceTextBlockEditorView.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-11.
//

import SwiftUI

// MARK: - In-Place Text Block Editor View
struct InPlaceTextBlockEditorView: View {
    @Binding var block: RichNoteBlock
    let isSelected: Bool
    let isEditing: Bool
    let onSelect: () -> Void
    let onEditingChanged: (Bool) -> Void
    
    @State private var editingText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text("Text Block")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if isEditing {
                    HStack(spacing: 8) {
                        Text("\(editingText.count)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            block.content = editingText
                            onEditingChanged(false)
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    Button(action: {
                        editingText = block.content
                        onEditingChanged(true)
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            
            Divider()
            
            // Card Content
            if isEditing {
                // Editing Mode - TextEditor
                TextEditor(text: $editingText)
                    .font(.body)
                    .lineSpacing(1.2)
                    .padding(12)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .onChange(of: editingText) { newValue in
                        block.content = newValue
                    }
            } else {
                // Preview Mode
                VStack(alignment: .leading, spacing: 0) {
                    if block.content.isEmpty {
                        Text("Tap edit to add text")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(12)
                    } else {
                        Text(block.content)
                            .font(.body)
                            .lineSpacing(1.2)
                            .padding(12)
                            .frame(maxHeight: 200)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .border(isSelected ? Color.blue : Color.gray.opacity(0.3), width: 2)
        .onTapGesture {
            onSelect()
        }
        .onAppear {
            editingText = block.content
            if isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
    }
}
