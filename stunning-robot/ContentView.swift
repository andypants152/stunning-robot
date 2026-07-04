//
//  ContentView.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import SwiftUI
import Observation
import Combine

@Observable
class GameModel {
    var position: CGPoint = .zero
    var velocity: CGPoint = CGPoint(x: 4, y: 3)
    var isRunning = false
    
    func update() {
        position.x += velocity.x
        position.y += velocity.y
        
        let boxSize: CGFloat = 50
        let screenWidth: CGFloat = 400
        let screenHeight: CGFloat = 600
        
        // Bounce off left/right edges
        if position.x <= 0 || position.x >= screenWidth - boxSize {
            velocity.x *= -1
        }
        // Bounce off top/bottom edges
        if position.y <= 0 || position.y >= screenHeight - boxSize {
            velocity.y *= -1
        }
    }
}

struct ContentView: View {
    @State private var game = GameModel()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(x: game.position.x, y: game.position.y, width: 50, height: 50)
            context.stroke(Path(rect), with: .color(.white))
        }
        .frame(width: 400, height: 600)
        .background(.black)
        .onAppear {
            game.isRunning = true
            Timer.publish(every: 1.0/120, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if game.isRunning { game.update() }
                }
                .store(in: &cancellables)
        }
        .onTapGesture { game.isRunning.toggle() }
        .onDisappear {
            cancellables.removeAll()
        }
    }
}
