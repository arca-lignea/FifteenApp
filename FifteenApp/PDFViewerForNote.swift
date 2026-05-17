//
//  PDFViewerForNote.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-03.
//

import SwiftUI

// MARK: - PDF Viewer
struct PDFViewerForNote: View {
    let pdfData: Data
    let filename: String
    @Environment(\.dismiss) var dismiss
    @State var currentPage: Int
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
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
                }
                .padding(16)
                .background(Color(.systemGray6))
                
                PDFKitView(pdfData: pdfData, currentPage: $currentPage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
