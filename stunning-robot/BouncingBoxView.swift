//
//  BouncingBoxView.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import UIKit

final class BouncingBoxView: UIView {
    static let highScoreDefaultsKey = "highScore"

    private struct Particle {
        let layer: CAShapeLayer
        let velocity: CGPoint
    }

    private var particles: [Particle] = []
    
    private(set) var highScore: Int = 0
    
    private let collisionSoundPlayer = CollisionSoundPlayer()

    var onScoreUpdate: ((Int) -> Void) = { _ in }
    var onStateUpdate: ((GameState) -> Void) = { _ in }
    var onHighScoreUpdate: ((Int) -> Void) = { _ in } {
        didSet {
            onHighScoreUpdate(highScore)
        }
    }

    private let boxLayer = CAShapeLayer()
    private let boxSize: CGFloat = 50

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var position = CGPoint(x: 120, y: 120)
    private var velocity = CGPoint(x: 240, y: 180)

    private var targetRect = CGRect(x: 200, y: 300, width: 40, height: 40)
    private let targetLayer = CAShapeLayer()
    private var lastLaidOutBoundsSize: CGSize = .zero
    private var score: Int = 0
    private var gameState: GameState = .menu

    enum GameState {
        case menu
        case playing
        case gameOver
    }

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
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        loadHighScore()

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

        if bounds.size != lastLaidOutBoundsSize {
            lastLaidOutBoundsSize = bounds.size
            spawnTarget()
        }
    }

    func startGame() {
        gameState = .playing
        position = CGPoint(x: bounds.width / 2 - boxSize / 2, y: bounds.height / 2 - boxSize / 2)
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
        saveHighScore()
    }

    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: Self.highScoreDefaultsKey)
    }

    private func saveHighScore() {
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: Self.highScoreDefaultsKey)
            onHighScoreUpdate(highScore)
        }
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
        guard gameState == .playing else { return }
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
        updateParticles()
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

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if gameState == .menu || gameState == .gameOver {
            startGame()
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
            onScoreUpdate(score)
            let collisionPoint = CGPoint(x: targetRect.midX, y: targetRect.midY)
            
            collisionSoundPlayer.play()
            spawnTarget()
            spawnParticles(at: collisionPoint)
            saveHighScore()
        }
    }
    
    private func spawnParticles(at point: CGPoint) {
        for _ in 0..<8 {
            let particle = CAShapeLayer()
            particle.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 6, height: 6)).cgPath
            particle.fillColor = UIColor.systemYellow.cgColor
            particle.position = point
            particle.opacity = 1.0
            layer.addSublayer(particle)
            
            let angle = CGFloat.random(in: 0..<2 * .pi)
            let speed = CGFloat.random(in: 100..<300)
            particles.append(
                Particle(
                    layer: particle,
                    velocity: CGPoint(x: cos(angle) * speed, y: sin(angle) * speed)
                )
            )
        }
    }
    
    private func updateParticles() {
        for index in particles.indices.reversed() {
            let particle = particles[index]
            var position = particle.layer.position
            position.x += particle.velocity.x * 0.016 // ~60fps delta
            position.y += particle.velocity.y * 0.016
            particle.layer.position = position
            particle.layer.opacity -= 0.04
            
            if particle.layer.opacity <= 0 {
                particle.layer.removeFromSuperlayer()
                particles.remove(at: index)
            }
        }
    }
}
