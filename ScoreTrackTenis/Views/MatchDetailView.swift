import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var match: TennisMatch
    
    var body: some View {
        VStack {
            // Match header
            HStack {
                VStack {
                    Text(match.playerOneName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Sets: \(match.sets.filter { $0.playerOneWon }.count)")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack {
                    Text(match.playerTwoName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Sets: \(match.sets.filter { !$0.playerOneWon && $0.isCompleted }.count)")
                        .font(.headline)
                }
            }
            .padding()
            
            // Score display
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(match.sets) { set in
                        SetScoreView(set: set, match: match)
                    }
                }
                .padding()
            }
            
            // Match status
            if match.isCompleted {
                VStack {
                    Text("Match Completed")
                        .font(.headline)
                    
                    if let winner = match.winner {
                        Text("Winner: \(winner)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
            } else {
                // Current game scoring buttons
                if let currentSet = match.sets.last, !currentSet.isCompleted,
                   let currentGame = currentSet.games.last, !currentGame.isCompleted {
                    
                    VStack {
                        Text("Current Game")
                            .font(.headline)
                        
                        Text(currentGame.scoreString())
                            .font(.title)
                            .padding()
                        
                        HStack(spacing: 40) {
                            Button {
                                currentGame.addPointToPlayerOne()
                                updateMatchState(currentSet: currentSet, currentGame: currentGame)
                            } label: {
                                VStack {
                                    Text(match.playerOneName)
                                        .font(.headline)
                                    Text("Point")
                                        .font(.subheadline)
                                }
                                .padding()
                                .frame(width: 120)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button {
                                currentGame.addPointToPlayerTwo()
                                updateMatchState(currentSet: currentSet, currentGame: currentGame)
                            } label: {
                                VStack {
                                    Text(match.playerTwoName)
                                        .font(.headline)
                                    Text("Point")
                                        .font(.subheadline)
                                }
                                .padding()
                                .frame(width: 120)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func updateMatchState(currentSet: TennisSet, currentGame: TennisGame) {
        // Check if game is completed
        if currentGame.isCompleted {
            // Check if set is completed
            let isFinalSet = match.sets.count == match.bestOfSets
            currentSet.checkSetCompletion(
                advantageSet: match.advantageSet,
                isFinalSet: isFinalSet,
                tiebreakInFinalSet: match.tiebreakInFinalSet
            )
            
            if currentSet.isCompleted {
                // Check if match is completed
                match.checkMatchCompletion()
                
                // If match is not completed, add a new set
                if !match.isCompleted {
                    let newSet = match.addNewSet()
                    let newGame = newSet.addNewGame()
                    
                    // Check if this should be a tiebreak game
                    if currentSet.playerOneGames == 6 && currentSet.playerTwoGames == 6 {
                        newGame.isTiebreak = true
                    }
                }
            } else {
                // Add a new game to the current set
                let newGame = currentSet.addNewGame()
                
                // Check if this should be a tiebreak game
                if currentSet.playerOneGames == 6 && currentSet.playerTwoGames == 6 {
                    newGame.isTiebreak = true
                }
            }
        }
    }
}

struct SetScoreView: View {
    @Bindable var set: TennisSet
    let match: TennisMatch
    
    var body: some View {
        VStack {
            Text("Set \(match.sets.firstIndex(where: { $0.id == set.id })! + 1)")
                .font(.headline)
            
            HStack {
                Text("\(match.playerOneName): \(set.playerOneGames)")
                    .font(.title3)
                    .fontWeight(set.isCompleted && set.playerOneWon ? .bold : .regular)
                
                Spacer()
                
                Text("\(match.playerTwoName): \(set.playerTwoGames)")
                    .font(.title3)
                    .fontWeight(set.isCompleted && !set.playerOneWon ? .bold : .regular)
            }
            
            if set.isCompleted {
                Text("Set completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
} 