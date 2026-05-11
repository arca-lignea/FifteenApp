//
//  PDFKitView.swift
//  FifteenApp
//
//  Created by sophie on 2026-04-03.
//

import SwiftUI
import PhotosUI
import PDFKit

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
        // initialise to the saved page
        if let document = uiView.document,
           document.pageCount > currentPage - 1,
           let page = document.page(at: currentPage - 1) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                uiView.go(to: page)
            }
        }
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
