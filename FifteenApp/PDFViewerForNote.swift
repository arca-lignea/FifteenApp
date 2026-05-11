//
//  PDFViewerForNote.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-03.
//

import SwiftUI

// MARK: - PDF Viewer for Note
struct PDFViewerForNote: View {
    let pdfData: Data
    let filename: String
    @Environment(\.dismiss) var dismiss
    
    @State var currentPage: Int
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
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
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.7))
                
                // PDF View
                PDFKitView(pdfData: pdfData, currentPage: $currentPage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
