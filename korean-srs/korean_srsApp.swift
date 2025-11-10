//
//  korean_srsApp.swift
//  korean-srs
//
//  Created by Justin Haddad on 11/1/25.
//

import SwiftUI
import SwiftData

@main
struct korean_srsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Word.self)
    }
}
