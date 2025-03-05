import SwiftUI
import SwiftData

struct MatchConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var playerOneName: String = ""
    @State private var playerTwoName: String = ""
    @State private var bestOfSets: Int = 3
    @State private var advantageSet: Bool = true
    @State private var tiebreakInFinalSet: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    TextField("Player 1", text: $playerOneName)
                    TextField("Player 2", text: $playerTwoName)
                }
                
                Section("Match Format") {
                    Picker("Best of Sets", selection: $bestOfSets) {
                        Text("1 Set").tag(1)
                        Text("3 Sets").tag(3)
                        Text("5 Sets").tag(5)
                    }
                    
                    Toggle("Advantage Set", isOn: $advantageSet)
                    Toggle("Tiebreak in Final Set", isOn: $tiebreakInFinalSet)
                }
                
                Section {
                    Button("Start Match") {
                        createMatch()
                    }
                    .disabled(playerOneName.isEmpty || playerTwoName.isEmpty)
                }
            }
            .navigationTitle("New Tennis Match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createMatch() {
        let newMatch = TennisMatch(
            playerOneName: playerOneName,
            playerTwoName: playerTwoName,
            bestOfSets: bestOfSets,
            advantageSet: advantageSet,
            tiebreakInFinalSet: tiebreakInFinalSet
        )
        
        // Add the first set to start the match
        let firstSet = newMatch.addNewSet()
        // Add the first game to the first set
        firstSet.addNewGame()
        
        modelContext.insert(newMatch)
        dismiss()
    }
} 