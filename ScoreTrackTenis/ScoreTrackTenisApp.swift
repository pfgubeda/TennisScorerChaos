//
//  ScoreTrackTenisApp.swift
//  ScoreTrackTenis
//
//  Created by Pablo Fernandez Gonzalez on 5/3/25.
//

import SwiftUI
import SwiftData

@main
struct ScoreTrackTenisApp: App {

    var body: some Scene {
        WindowGroup {
            MatchListView()
        }
        .modelContainer(for: [TennisMatch.self, TennisSet.self, TennisGame.self])
    }
}
