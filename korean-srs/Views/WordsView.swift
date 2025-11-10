//
//  WordsView.swift
//  korean-srs
//
//  Created by Auto on 11/10/25.
//

import SwiftUI
import SwiftData

struct WordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.dateCreated, order: .reverse) private var words: [Word]
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateAdded
    
    private var filteredWords: [Word] {
        let filtered: [Word]
        if searchText.isEmpty {
            filtered = words
        } else {
            filtered = words.filter { word in
                word.frontText.localizedCaseInsensitiveContains(searchText) ||
                word.backText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch sortOption {
        case .dateAdded:
            return filtered.sorted { $0.dateCreated > $1.dateCreated }
        case .nextReview:
            return filtered.sorted { $0.nextReviewDate < $1.nextReviewDate }
        case .alphabetical:
            return filtered.sorted { $0.frontText.localizedCaseInsensitiveCompare($1.frontText) == .orderedAscending }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if filteredWords.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredWords) { word in
                            wordRow(word)
                        }
                        .onDelete(perform: deleteWords)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Words")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Label(option.title, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
    
    private func wordRow(_ word: Word) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(word.frontText)
                    .font(.headline)
                Spacer()
                Text(word.backText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Label {
                    Text(word.nextReviewDate, style: .date)
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Label("\(word.interval)d", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(word.repetitions)", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deleteWords(at offsets: IndexSet) {
        let wordsToDelete = offsets.map { filteredWords[$0] }
        for word in wordsToDelete {
            modelContext.delete(word)
        }
        try? modelContext.save()
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No words yet")
                .font(.title3.weight(.semibold))
            Text("Add words in the Add tab to build your study list.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private enum SortOption: CaseIterable {
    case dateAdded
    case nextReview
    case alphabetical
    
    var title: String {
        switch self {
        case .dateAdded: return "Date Added"
        case .nextReview: return "Next Review"
        case .alphabetical: return "Alphabetical"
        }
    }
    
    var systemImage: String {
        switch self {
        case .dateAdded: return "calendar.badge.plus"
        case .nextReview: return "calendar"
        case .alphabetical: return "textformat.abc"
        }
    }
}

#Preview {
    WordsView()
        .modelContainer(for: Word.self, inMemory: true)
}

