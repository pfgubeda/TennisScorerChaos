import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var match: TennisMatch
    
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var playerOneServing: Bool = true // Default player one serves first
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            VStack(spacing: 0) {               
                if isLandscape {
                    // ATP-style scoreboard for landscape
                    atpStyleScoreboard(width: geometry.size.width)
                        .frame(height: geometry.size.height * 0.5) // Make scoreboard bigger
                } else {
                    // Simplified scoreboard for portrait
                    simpleScoreboard
                }
                
                Spacer()
                
                // Match status
                if match.isCompleted {
                    matchCompletedView
                } else {
                    // Current game scoring buttons
                    if let currentSet = match.sets.last, !currentSet.isCompleted,
                       let currentGame = currentSet.games.last, !currentGame.isCompleted {
                        scoringButtonsView(currentSet: currentSet, currentGame: currentGame)
                    }
                }
            }
            .navigationTitle(match.isCompleted ? "Match Details" : "Match Score")
            .navigationBarTitleDisplayMode(.inline)
            .background(colorScheme == .dark ? Color.black : Color.gray.opacity(0.1))
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                    self.orientation = UIDevice.current.orientation
                }
            }
            .onDisappear {
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
                NotificationCenter.default.removeObserver(self)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if(!match.isCompleted){
                        Button {
                            playerOneServing.toggle()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    // Simple scoreboard for portrait mode
    private var simpleScoreboard: some View {
        VStack(spacing: 16) {
            // Player names with serving indicator
            HStack {
                    HStack(spacing: 8) {
                        if playerOneServing {
                            Image(systemName: "tennisball.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        Text(match.playerOneName)
                            .font(.title3)
                            .fontWeight(playerOneServing ? .bold : .regular)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        if !playerOneServing {
                            Image(systemName: "tennisball.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        Text(match.playerTwoName)
                            .font(.title3)
                            .fontWeight(!playerOneServing ? .bold : .regular)
                    }
            }
            .padding(.horizontal)
            
            // Current game score - larger and more prominent
            if let currentSet = match.sets.last, !currentSet.isCompleted,
               let currentGame = currentSet.games.last, !currentGame.isCompleted {
                HStack {
                    VStack(alignment: .center) {
                        Text(pointString(currentGame.playerOnePoints, isTiebreak: currentGame.isTiebreak))
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(playerOneServing ? .blue : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .center) {
                        Text(pointString(currentGame.playerTwoPoints, isTiebreak: currentGame.isTiebreak))
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(!playerOneServing ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                )
                .shadow(radius: 1)
                .padding(.horizontal)
            }
            
            // Set scores in a more compact format
            VStack(spacing: 20) {
                Text("SET SCORES")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                // Set scores grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(match.sets.indices, id: \.self) { index in
                        let set = match.sets[index]
                        setScoreCard(set: set, index: index)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // Set score card for vertical layout
    private func setScoreCard(set: TennisSet, index: Int) -> some View {
        VStack() {
            Text("Set \(index + 1)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Spacer()
                Text("\(set.playerOneGames)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(set.isCompleted && set.playerOneWon ? .blue : .primary)
                
                Spacer()
                
                Text("\(set.playerTwoGames)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(set.isCompleted && !set.playerOneWon ? .red : .primary)
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
        )
        .shadow(radius: 1)
    }
    
    // ATP-style scoreboard for landscape mode - now with dynamic width
    private func atpStyleScoreboard(width: CGFloat) -> some View {
        // Calculate column widths based on available space
        let playerColumnWidth = max(width * 0.25, 150) // 25% of width or minimum 150
        let setColumnWidth = max((width - playerColumnWidth) / (CGFloat(match.sets.count) + 1) * 0.8, 70) // Distribute remaining space
        let gameColumnWidth = max((width - playerColumnWidth) / (CGFloat(match.sets.count) + 1) * 1.2, 100) // Game column slightly wider
        
        return HStack(alignment: .center, spacing: 0) {
            // Player names column
            VStack(alignment: .leading, spacing: 0) {
                // Player one name
                HStack {
                    if playerOneServing {
                        Image(systemName: "tennisball.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    Text(match.playerOneName)
                        .font(.title2)
                        .fontWeight(playerOneServing ? .bold : .regular)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 15)
                .frame(height: 60, alignment: .leading)
                .background(
                    playerOneServing 
                    ? (colorScheme == .dark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                    : (colorScheme == .dark ? Color.black : Color.white)
                )
                
                // Player two name
                HStack {
                    if !playerOneServing {
                        Image(systemName: "tennisball.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    Text(match.playerTwoName)
                        .font(.title2)
                        .fontWeight(!playerOneServing ? .bold : .regular)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 15)
                .frame(height: 60, alignment: .leading)
                .background(
                    !playerOneServing 
                    ? (colorScheme == .dark ? Color.red.opacity(0.2) : Color.red.opacity(0.1))
                    : (colorScheme == .dark ? Color.black : Color.white)
                )
            }
            .frame(width: playerColumnWidth)
            
            // Set scores
            ForEach(match.sets.indices, id: \.self) { index in
                let set = match.sets[index]
                VStack(alignment: .center, spacing: 0) {
                    // Player one score
                    Text("\(set.playerOneGames)")
                        .font(.title2)
                        .fontWeight(set.isCompleted && set.playerOneWon ? .bold : .regular)
                        .foregroundColor(set.isCompleted && set.playerOneWon ? .blue : .primary)
                        .frame(width: setColumnWidth, height: 60)
                        .background(
                            set.isCompleted && set.playerOneWon 
                            ? (colorScheme == .dark ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1))
                            : (colorScheme == .dark ? Color.black : Color.white)
                        )
                    
                    // Player two score
                    Text("\(set.playerTwoGames)")
                        .font(.title2)
                        .fontWeight(set.isCompleted && !set.playerOneWon ? .bold : .regular)
                        .foregroundColor(set.isCompleted && !set.playerOneWon ? .red : .primary)
                        .frame(width: setColumnWidth, height: 60)
                        .background(
                            set.isCompleted && !set.playerOneWon 
                            ? (colorScheme == .dark ? Color.red.opacity(0.3) : Color.red.opacity(0.1))
                            : (colorScheme == .dark ? Color.black : Color.white)
                        )
                }
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)),
                    alignment: .leading
                )
            }
            
            // Current game score
            if let currentSet = match.sets.last, !currentSet.isCompleted,
               let currentGame = currentSet.games.last, !currentGame.isCompleted {
                VStack(alignment: .center, spacing: 0) {
                    // Player one score
                    Text(pointString(currentGame.playerOnePoints, isTiebreak: currentGame.isTiebreak))
                        .font(.system(size: 36, weight: .bold))
                        .fontWeight(playerOneServing ? .bold : .regular)
                        .foregroundColor(playerOneServing ? .blue : .primary)
                        .frame(width: gameColumnWidth, height: 60)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                    
                    // Player two score
                    Text(pointString(currentGame.playerTwoPoints, isTiebreak: currentGame.isTiebreak))
                        .font(.system(size: 36, weight: .bold))
                        .fontWeight(!playerOneServing ? .bold : .regular)
                        .foregroundColor(!playerOneServing ? .red : .primary)
                        .frame(width: gameColumnWidth, height: 60)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                }
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)),
                    alignment: .leading
                )
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
        .padding()
    }
    
    // Match completed view
    private var matchCompletedView: some View {
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
    }
    
    // Scoring buttons view
    private func scoringButtonsView(currentSet: TennisSet, currentGame: TennisGame) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                // Player One Button
                Button {
                    currentGame.addPointToPlayerOne()
                    updateMatchState(currentSet: currentSet, currentGame: currentGame)
                    
                    // Change server if game completed
                    if currentGame.isCompleted {
                        playerOneServing.toggle()
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack {
                            if playerOneServing {
                                Image(systemName: "tennisball.fill")
                                    .foregroundColor(.yellow)
                            }
                            
                            Text(match.playerOneName)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .fontWeight(playerOneServing ? .bold : .regular)
                        }
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
                }
                
                // Player Two Button
                Button {
                    currentGame.addPointToPlayerTwo()
                    updateMatchState(currentSet: currentSet, currentGame: currentGame)
                    
                    // Change server if game completed
                    if currentGame.isCompleted {
                        playerOneServing.toggle()
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack {
                            if !playerOneServing {
                                Image(systemName: "tennisball.fill")
                                    .foregroundColor(.yellow)
                            }
                            
                            Text(match.playerTwoName)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .fontWeight(!playerOneServing ? .bold : .regular)
                        }
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.7), Color.red]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.red.opacity(0.4), radius: 5, x: 0, y: 3)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 30)
    }
    
    private func pointString(_ points: Int, isTiebreak: Bool) -> String {
        if isTiebreak {
            return "\(points)"
        } else {
            switch points {
            case 0: return "0"
            case 1: return "15"
            case 2: return "30"
            case 3: return "40"
            case 4: return "AD"
            default: return "40" // This should never happen with the fixed logic
            }
        }
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

// Helper for single-edge borders
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(
            EdgeBorder(width: width, edges: edges)
                .foregroundColor(color)
        )
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var line = Path()
            switch edge {
            case .top:
                line.move(to: CGPoint(x: rect.minX, y: rect.minY))
                line.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            case .leading:
                line.move(to: CGPoint(x: rect.minX, y: rect.minY))
                line.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            case .bottom:
                line.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                line.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            case .trailing:
                line.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                line.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            path.addPath(line.strokedPath(StrokeStyle(lineWidth: width)))
        }
        return path
    }
} 

#Preview {
    NavigationStack {
        MatchDetailView(match: TennisMatch.sampleMatch)
            .modelContainer(for: TennisMatch.self, inMemory: true)
    }
}

// Helper extension to create a sample match for previews
extension TennisMatch {
    static var sampleMatch: TennisMatch {
        let match = TennisMatch(
            playerOneName: "Roger Federer",
            playerTwoName: "Rafael Nadal",
            bestOfSets: 3,
            advantageSet: true,
            tiebreakInFinalSet: true
        )
        
        // Add a set with some games
        let firstSet = match.addNewSet()
        let game = firstSet.addNewGame()
        game.playerOnePoints = 2
        game.playerTwoPoints = 1
        
        return match
    }
}
