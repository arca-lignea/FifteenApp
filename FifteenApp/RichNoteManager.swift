//
//  RichNoteManager.swift
//  FifteenApp
//
//  Created by sophie on 2026-05-10.
//

import SwiftUI

// MARK: - Rich Note Manager
class RichNoteManager: NSObject, ObservableObject {
    private let notesKey = "SavedRichNotes"
    
    func saveNote(_ note: RichNote) {
        var notes = loadNotes()
        
        // Remove existing note with same ID if it exists
        notes.removeAll { $0.id == note.id }
        
        // Add the updated note
        notes.append(note)
        
        // Encode and save
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let encoded = try encoder.encode(notes)
            UserDefaults.standard.set(encoded, forKey: notesKey)
            UserDefaults.standard.synchronize() // Force immediate save
            print("Note saved successfully: \(note.id)")
        } catch {
            print("Error encoding note: \(error)")
        }
    }
    
    
    
    func deleteNote(_ note: RichNote) {
        var notes = loadNotes()
        notes.removeAll { $0.id == note.id }
        
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func loadNotes() -> [RichNote] {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([RichNote].self, from: data) {
            print("note count: \(decoded.count)")
            //print("Decoded: \(decoded)")
            
            return decoded
        }
        return []
    }
}
