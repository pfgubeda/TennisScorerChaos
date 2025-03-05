import Foundation
import SwiftData

@Model
class TennisMatch {
    var playerOneName: String
    var playerTwoName: String
    var bestOfSets: Int
    var advantageSet: Bool
    var tiebreakInFinalSet: Bool
    var date: Date
    var isCompleted: Bool
    
    @Relationship(deleteRule: .cascade)
    var sets: [TennisSet] = []
    
    var winner: String? {
        guard isCompleted else { return nil }
        
        let playerOneSets = sets.filter { $0.playerOneWon }.count
        let playerTwoSets = sets.filter { !$0.playerOneWon }.count
        
        return playerOneSets > playerTwoSets ? playerOneName : playerTwoName
    }

    init(){
        self.playerOneName = ""
        self.playerTwoName = ""
        self.bestOfSets = 3
        self.advantageSet = true
        self.tiebreakInFinalSet = true
        self.date = Date()
        self.isCompleted = false
    }
    
    init(playerOneName: String, playerTwoName: String, bestOfSets: Int = 3, advantageSet: Bool = true, tiebreakInFinalSet: Bool = true) {
        self.playerOneName = playerOneName
        self.playerTwoName = playerTwoName
        self.bestOfSets = bestOfSets
        self.advantageSet = advantageSet
        self.tiebreakInFinalSet = tiebreakInFinalSet
        self.date = Date()
        self.isCompleted = false
    }
    
    func addNewSet() -> TennisSet {
        let newSet = TennisSet()
        sets.append(newSet)
        return newSet
    }
    
    func checkMatchCompletion() {
        let setsToWin = bestOfSets / 2 + 1
        let playerOneSets = sets.filter { $0.playerOneWon }.count
        let playerTwoSets = sets.filter { !$0.playerOneWon && $0.isCompleted }.count
        
        if playerOneSets >= setsToWin || playerTwoSets >= setsToWin {
            isCompleted = true
        }
    }
}

@Model
class TennisSet {
    var isCompleted: Bool = false
    var playerOneWon: Bool = false
    
    @Relationship(deleteRule: .cascade)
    var games: [TennisGame] = []

    init(){

    }
    
    init(isCompleted: Bool, playerOneWon: Bool, games: [TennisGame]) {
        self.isCompleted = isCompleted
        self.playerOneWon = playerOneWon
        self.games = games
    }
    
    var playerOneGames: Int {
        return games.filter { $0.playerOneWon }.count
    }
    
    var playerTwoGames: Int {
        return games.filter { !$0.playerOneWon && $0.isCompleted }.count
    }
    
    func addNewGame() -> TennisGame {
        let newGame = TennisGame()
        games.append(newGame)
        return newGame
    }
    
    func checkSetCompletion(advantageSet: Bool, isFinalSet: Bool, tiebreakInFinalSet: Bool) {
        let p1Games = playerOneGames
        let p2Games = playerTwoGames
        
        // Regular set with tiebreak at 6-6
        if !isFinalSet || (isFinalSet && tiebreakInFinalSet) {
            if (p1Games >= 6 || p2Games >= 6) && abs(p1Games - p2Games) >= 2 {
                isCompleted = true
                playerOneWon = p1Games > p2Games
            } else if p1Games == 7 && p2Games == 6 {
                isCompleted = true
                playerOneWon = true
            } else if p1Games == 6 && p2Games == 7 {
                isCompleted = true
                playerOneWon = false
            }
        } 
        // Final set with no tiebreak (advantage set)
        else if isFinalSet && !tiebreakInFinalSet {
            if (p1Games >= 6 || p2Games >= 6) && abs(p1Games - p2Games) >= 2 {
                isCompleted = true
                playerOneWon = p1Games > p2Games
            }
        }
    }
}

@Model
class TennisGame {
    var isCompleted: Bool = false
    var playerOneWon: Bool = false
    var playerOnePoints: Int = 0
    var playerTwoPoints: Int = 0
    var isTiebreak: Bool = false
    
    init(){
        
    }
    
    init(isCompleted: Bool, playerOneWon: Bool, playerOnePoints: Int, playerTwoPoints: Int, isTiebreak: Bool) {
        self.isCompleted = isCompleted
        self.playerOneWon = playerOneWon
        self.playerOnePoints = playerOnePoints
        self.playerTwoPoints = playerTwoPoints
        self.isTiebreak = isTiebreak
    }
    
    func addPointToPlayerOne() {
        if !isCompleted {
            // If player two has advantage (4 points) and player one scores, go back to deuce
            if !isTiebreak && playerTwoPoints == 4 && playerOnePoints == 3 {
                playerOnePoints = 3
                playerTwoPoints = 3
            } else {
                playerOnePoints += 1
            }
            checkGameCompletion()
        }
    }
    
    func addPointToPlayerTwo() {
        if !isCompleted {
            // If player one has advantage (4 points) and player two scores, go back to deuce
            if !isTiebreak && playerOnePoints == 4 && playerTwoPoints == 3 {
                playerOnePoints = 3
                playerTwoPoints = 3
            } else {
                playerTwoPoints += 1
            }
            checkGameCompletion()
        }
    }
    
    func checkGameCompletion() {
        if isTiebreak {
            // Tiebreak rules: first to 7 with a 2-point lead
            if (playerOnePoints >= 7 || playerTwoPoints >= 7) && abs(playerOnePoints - playerTwoPoints) >= 2 {
                isCompleted = true
                playerOneWon = playerOnePoints > playerTwoPoints
            }
        } else {
            // Regular game: 0, 15, 30, 40, game (or advantage rules)
            if playerOnePoints >= 4 && playerOnePoints - playerTwoPoints >= 2 {
                isCompleted = true
                playerOneWon = true
            } else if playerTwoPoints >= 4 && playerTwoPoints - playerOnePoints >= 2 {
                isCompleted = true
                playerOneWon = false
            }
        }
    }
    
    func pointsToString(points: Int, isTiebreak: Bool) -> String {
        if isTiebreak {
            return "\(points)"
        }
        
        switch points {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        default: return "A"
        }
    }
    
    func scoreString() -> String {
        if isTiebreak {
            return "\(playerOnePoints)-\(playerTwoPoints)"
        }
        
        if playerOnePoints >= 3 && playerTwoPoints >= 3 {
            if playerOnePoints == playerTwoPoints {
                return "Deuce"
            } else if playerOnePoints > playerTwoPoints {
                return "Advantage Player 1"
            } else {
                return "Advantage Player 2"
            }
        }
        
        return "\(pointsToString(points: playerOnePoints, isTiebreak: isTiebreak))-\(pointsToString(points: playerTwoPoints, isTiebreak: isTiebreak))"
    }
} 
