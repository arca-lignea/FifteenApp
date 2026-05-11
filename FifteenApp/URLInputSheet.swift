//
//  URLInputSheet.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-12.
//

import SwiftUI


struct URLInputSheet: View {
    @Binding var urlInput: String
    @Binding var isPresented: Bool
    let onSubmit: () -> Void
    
    @FocusState private var isFocused: Bool
    
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
                    
                    Text("Enter URL")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        onSubmit()
                        isPresented = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                
                Divider()
                
                // URL Input Field
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        TextField("https://www.example.com", text: $urlInput)
                            .font(.system(size: 16))
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .focused($isFocused)
                        
                        if !urlInput.isEmpty {
                            Button(action: { urlInput = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                }
                .padding(16)
                
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
}
