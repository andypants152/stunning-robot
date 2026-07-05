//
//  BouncingBoxView.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import UIKit

final class BouncingBoxView: UIView {
    static let highScoreDefaultsKey = "highScore"
    private let maxFlickSpeed: CGFloat = 1000 // Caps flick speed to prevent tunneling/glitches

    private(set) var highScore: Int = 0

    var onScoreUpdate: ((Int) -> Void) = { _ in }
    var onStateUpdate: ((GameState) -> Void) = { _ in }
    var onHighScoreUpdate: ((Int) -> Void) = { _ in }

    private let boxLayer = CAShapeLayer()
    private let boxSize: CGFloat = 50
    private let targetSize: CGFloat = 40

    private lazy var physicsEngine = PhysicsEngine(
        initialPosition: CGPoint(x: 120, y: 120),
        initialVelocity: CGPoint(x: 240, y: 180),
        boxSize: boxSize
    )
    private lazy var targetManager = TargetManager(targetSize: targetSize)

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
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
        clipsToBounds = false

        boxLayer.fillColor = UIColor.clear.cgColor
        boxLayer.strokeColor = UIColor.white.cgColor
        boxLayer.lineWidth = 3
        boxLayer.frame = bounds
        layer.addSublayer(boxLayer)

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

    // Note: didMoveToWindow is intentionally omitted. 
    // SwiftUI's scenePhase via setSceneActive() is the authoritative source for pausing/resuming.

    override func layoutSubviews() {
        super.layoutSubviews()

        physicsEngine.clampPosition(in: bounds)
        updateBoxLayer()

        if bounds.size != lastLaidOutBoundsSize {
            lastLaidOutBoundsSize = bounds.size
            if gameState == .playing {
                spawnAllTargets()
            }
        }
    }

    func startGame() {
        gameState = .playing
        physicsEngine.reset(
            position: CGPoint(x: bounds.width / 2 - boxSize / 2, y: bounds.height / 2 - boxSize / 2),
            velocity: CGPoint(x: 240, y: 180)
        )
        score = 0
        onScoreUpdate(score)
        onStateUpdate(gameState)
        physicsEngine.removeAllParticles()
        startDisplayLink()
        spawnAllTargets()
    }

    func stopGame() {
        gameState = .gameOver
        onStateUpdate(gameState)
        stopDisplayLink()
        targetManager.removeAllTargets()
        physicsEngine.removeAllParticles()
    }

    func setSceneActive(_ isActive: Bool) {
        if isActive {
            if gameState == .playing {
                startDisplayLink()
            }
        } else {
            stopDisplayLink()
        }
    }

    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: Self.highScoreDefaultsKey)
        onHighScoreUpdate(highScore)
    }

    private func saveHighScore() {
        if score > highScore {
            highScore = score
            onHighScoreUpdate(highScore)
        }
    }

    private func startDisplayLink() {
        guard gameState == .playing else { return }
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

        // Tightened dt clamp to further prevent tunneling during high-speed or background/foreground transitions
        let elapsed = min(displayLink.timestamp - lastTimestamp, 1.0 / 30.0)
        if physicsEngine.update(dt: elapsed, bounds: bounds) {
            awardCornerBonus()
        }
        updateBoxLayer()
        physicsEngine.updateParticles(dt: elapsed)
        checkCollisions()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let gestureVelocity = gesture.velocity(in: self)
        var velocity = gestureVelocity

        switch gesture.state {
        case .began, .changed:
            break
        case .ended:
            velocity = CGPoint(x: gestureVelocity.x * 1.2, y: gestureVelocity.y * 1.2)
        default:
            return
        }

        // Cap velocity to prevent tunneling and physics glitches
        let magnitude = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        if magnitude > maxFlickSpeed {
            let scale = maxFlickSpeed / magnitude
            velocity = CGPoint(x: velocity.x * scale, y: velocity.y * scale)
        }
        
        physicsEngine.velocity = velocity
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if gameState == .menu || gameState == .gameOver {
            startGame()
        }
    }

    private func awardCornerBonus() {
        score += 100
        onScoreUpdate(score)
        saveHighScore()
        physicsEngine.spawnCornerConfetti(in: bounds, parentLayer: layer)
    }

    private func updateBoxLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        boxLayer.path = UIBezierPath(rect: physicsEngine.playerRect).cgPath
        CATransaction.commit()
    }

    private func spawnAllTargets() {
        targetManager.spawnAll(
            bounds: bounds,
            playerRect: physicsEngine.playerRect,
            parentLayer: layer,
            parentView: self
        )
    }

    private func checkCollisions() {
        let updatedScore = targetManager.checkCollisions(
            playerRect: physicsEngine.playerRect,
            score: score,
            physicsEngine: physicsEngine,
            parentLayer: layer,
            onScoreUpdate: onScoreUpdate,
            triggerPenaltyFlash: triggerPenaltyFlash
        )

        if updatedScore != score {
            score = updatedScore
            saveHighScore()
        }
    }

    private func triggerPenaltyFlash() {
        UIView.animate(withDuration: 0.1, animations: {
            self.backgroundColor = .systemRed
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.backgroundColor = .black
            }
        }
    }
}
