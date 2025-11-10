//
//  ContentView.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.dateCreated, order: .reverse) private var words: [Word]
    
    var body: some View {
        TabView {
            AddWordView()
                .tabItem {
                    Label("Add Words", systemImage: "plus.circle")
                }
            
            WordsView()
                .tabItem {
                    Label("Words", systemImage: "list.bullet")
                }
            
            StudyView()
                .tabItem {
                    Label("Study", systemImage: "book")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Word.self, inMemory: true)
}

