//
//  FifteenAppApp.swift
//  FifteenApp
//
//  Created by sophie on 2025-12-24.
//

import SwiftUI

@main
struct FifteenAppApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)

        }
    }
}
