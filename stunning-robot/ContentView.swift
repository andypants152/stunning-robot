//
//  ContentView.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var currentScore: Int = 0
    
    var body: some View {
        ZStack {

            BouncingBoxRepresentable(
                onScoreUpdate: { currentScore = $0}
            )
            .ignoresSafeArea()
        
        
            VStack {
                Text("Score: \(currentScore)")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()
            }
        }
    }
}

struct BouncingBoxRepresentable: UIViewRepresentable {
    let onScoreUpdate: (Int) -> Void

    func makeUIView(context: Context) -> BouncingBoxView {
        let view = BouncingBoxView()
        view.onScoreUpdate = onScoreUpdate
        return view
    }
    
    func updateUIView(_ uiView: BouncingBoxView, context: Context) {
        uiView.onScoreUpdate = onScoreUpdate
    }
}

final class BouncingBoxView: UIView {
    // ✅ BRIDGES TO SWIFTUI
    var onScoreUpdate: ((Int) -> Void) = { _ in }
    var onStateUpdate: ((GameState) -> Void) = { _ in }
    
    private let boxLayer = CAShapeLayer()
    private let boxSize: CGFloat = 50
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var position = CGPoint(x: 120, y: 120)
    private var velocity = CGPoint(x: 240, y: 180)
    
    private var targetRect = CGRect(x: 200, y: 300, width: 40, height: 40)
    private var targetLayer = CAShapeLayer()
    private var score: Int = 0
    private var gameState: GameState = .menu // Add enum below

    enum GameState { case menu, playing, gameOver }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isOpaque = true
        backgroundColor = .black
        
        boxLayer.fillColor = UIColor.clear.cgColor
        boxLayer.strokeColor = UIColor.white.cgColor
        boxLayer.lineWidth = 3
        layer.addSublayer(boxLayer)
        
        targetLayer.fillColor = UIColor.systemRed.cgColor
        targetLayer.strokeColor = UIColor.white.cgColor
        targetLayer.lineWidth = 2
        layer.addSublayer(targetLayer)
        updateTargetLayer()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        addGestureRecognizer(panGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopDisplayLink()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window == nil {
            stopDisplayLink()
        } else {
            startDisplayLink()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        clampPosition()
        updateBoxLayer()
        
        spawnTarget()
    }
    
    // ✅ START/STOP & STATE MANAGEMENT
    func startGame() {
        gameState = .playing
        position = CGPoint(x: bounds.width/2 - boxSize/2, y: bounds.height/2 - boxSize/2)
        velocity = CGPoint(x: 240, y: 180)
        score = 0
        onScoreUpdate(score)
        onStateUpdate(gameState)
        startDisplayLink()
    }
    
    func stopGame() {
        gameState = .gameOver
        onStateUpdate(gameState)
        stopDisplayLink()
    }
    
    private func startDisplayLink() {
        guard displayLink == nil else { return }
        
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: 60,
                maximum: 120,
                preferred: 120
            )
        } else {
            link.preferredFramesPerSecond = 60
        }
        
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTimestamp = nil
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
    }
    
    @objc private func step(_ displayLink: CADisplayLink) {
        guard bounds.width > boxSize, bounds.height > boxSize else { return }
        
        defer { lastTimestamp = displayLink.timestamp }
        guard let lastTimestamp else {
            updateBoxLayer()
            return
        }
        
        let elapsed = min(displayLink.timestamp - lastTimestamp, 1.0 / 15.0)
        position.x += velocity.x * elapsed
        position.y += velocity.y * elapsed
        
        bounce()
        updateBoxLayer()
        checkCollisions()

    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let gestureVelocity = gesture.velocity(in: self)
        
        switch gesture.state {
        case .began, .changed:
            velocity = gestureVelocity
        case .ended:
            velocity = CGPoint(
                x: gestureVelocity.x * 1.2,
                y: gestureVelocity.y * 1.2
            )
        default:
            break
        }
    }
    
    private func bounce() {
        let maxX = bounds.width - boxSize
        let maxY = bounds.height - boxSize
        
        if position.x <= 0 {
            position.x = 0
            velocity.x = abs(velocity.x)
        } else if position.x >= maxX {
            position.x = maxX
            velocity.x = -abs(velocity.x)
        }
        
        if position.y <= 0 {
            position.y = 0
            velocity.y = abs(velocity.y)
        } else if position.y >= maxY {
            position.y = maxY
            velocity.y = -abs(velocity.y)
        }
    }
    
    private func clampPosition() {
        guard bounds.width > boxSize, bounds.height > boxSize else { return }
        
        position.x = min(max(position.x, 0), bounds.width - boxSize)
        position.y = min(max(position.y, 0), bounds.height - boxSize)
    }
    
    private func updateBoxLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        boxLayer.path = UIBezierPath(
            rect: CGRect(
                x: position.x,
                y: position.y,
                width: boxSize,
                height: boxSize
            )
        ).cgPath
        CATransaction.commit()
    }
    
    private func updateTargetLayer() {
        targetLayer.path = UIBezierPath(rect: targetRect).cgPath
    }

    private func spawnTarget() {
            let minX: CGFloat = 50
            let maxX = max(minX + 1, bounds.width - 90)
            let maxY = max(minX + 1, bounds.height - 90)
            targetRect.origin = CGPoint(x: CGFloat.random(in: minX..<maxX), y: CGFloat.random(in: minX..<maxY))
            updateTargetLayer()
        }

    private func checkCollisions() {
            let playerRect = CGRect(x: position.x, y: position.y, width: boxSize, height: boxSize)
            if playerRect.intersects(targetRect) {
                score += 1
                onScoreUpdate(score) // ✅ Pushes to SwiftUI
                spawnTarget()
            }
        }
    
}
