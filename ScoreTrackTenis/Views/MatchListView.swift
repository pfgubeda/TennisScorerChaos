import SwiftUI
import SwiftData

struct MatchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TennisMatch.date, order: .reverse) private var matches: [TennisMatch]
    
    @State private var showingNewMatchSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(matches) { match in
                    NavigationLink {
                        MatchDetailView(match: match)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("\(match.playerOneName) vs \(match.playerTwoName)")
                                .font(.headline)
                            
                            HStack {
                                Text(match.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if match.isCompleted {
                                    Text("Winner: \(match.winner ?? "Unknown")")
                                        .font(.subheadline)
                                        .foregroundStyle(.green)
                                } else {
                                    Text("In Progress")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteMatches)
            }
            .navigationTitle("Tennis Matches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewMatchSheet = true
                    } label: {
                        Label("Add Match", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewMatchSheet) {
                MatchConfigurationView()
            }
        }
    }
    
    private func deleteMatches(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(matches[index])
        }
    }
} 