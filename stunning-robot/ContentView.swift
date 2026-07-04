//
//  ContentView.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import SwiftUI

struct ContentView: View {
    @State private var currentScore: Int = 0
    @State private var currentState: BouncingBoxView.GameState = .menu
    @AppStorage(BouncingBoxView.highScoreDefaultsKey) private var currentHighScore: Int = 0


    var body: some View {
        ZStack {
            BouncingBoxRepresentable(
                onScoreUpdate: { currentScore = $0 },
                onHighScoreUpdate: { currentHighScore = $0 },
                onStateUpdate: { currentState = $0 }
            )
            .ignoresSafeArea()

            VStack {
                Text("Score: \(currentScore)")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(.top, 50)
                
                Text("Best: \(currentHighScore)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.top, 4)

                Spacer()

                if currentState == .menu {
                    Text("Tap to Start")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.8))
                } else if currentState == .gameOver {
                    Text("Tap to Restart")
                        .font(.title)
                        .foregroundStyle(.orange)
                        .onTapGesture { }
                }
            }
        }
    }
}
