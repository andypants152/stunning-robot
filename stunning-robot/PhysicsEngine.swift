//
//  PhysicsEngine.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import UIKit

final class PhysicsEngine {
    var position: CGPoint
    var velocity: CGPoint

    private let boxSize: CGFloat
    private let minSpeed: CGFloat
    private var particles: [Particle] = []

    var playerRect: CGRect {
        CGRect(x: position.x, y: position.y, width: boxSize, height: boxSize)
    }

    init(
        initialPosition: CGPoint,
        initialVelocity: CGPoint,
        boxSize: CGFloat,
        minSpeed: CGFloat = 100
    ) {
        self.position = initialPosition
        self.velocity = initialVelocity
        self.boxSize = boxSize
        self.minSpeed = minSpeed
    }

    func reset(position: CGPoint, velocity: CGPoint) {
        self.position = position
        self.velocity = velocity
    }

    func update(dt: CFTimeInterval, bounds: CGRect) -> Bool {
        position.x += velocity.x * dt
        position.y += velocity.y * dt
        return bounce(bounds: bounds)
    }

    func clampPosition(in bounds: CGRect) {
        guard bounds.width > boxSize, bounds.height > boxSize else { return }

        position.x = min(max(position.x, 0), bounds.width - boxSize)
        position.y = min(max(position.y, 0), bounds.height - boxSize)
    }

    func spawnParticles(at point: CGPoint, color: UIColor, parentLayer: CALayer) {
        for _ in 0..<8 {
            let particle = CAShapeLayer()
            particle.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 6, height: 6)).cgPath
            particle.fillColor = color.cgColor
            particle.position = point
            particle.opacity = 1.0
            parentLayer.addSublayer(particle)

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

    func spawnCornerConfetti(in bounds: CGRect, parentLayer: CALayer) {
        let cornerPoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: bounds.width, y: 0),
            CGPoint(x: 0, y: bounds.height),
            CGPoint(x: bounds.width, y: bounds.height)
        ]

        let colors: [UIColor] = [.systemRed, .systemGreen, .systemBlue, .systemYellow, .systemPurple, .systemOrange]

        for corner in cornerPoints {
            for _ in 0..<12 {
                let confetti = CAShapeLayer()
                confetti.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 10, height: 10)).cgPath
                confetti.fillColor = colors.randomElement()?.cgColor
                confetti.position = corner
                confetti.opacity = 1.0
                parentLayer.addSublayer(confetti)

                let direction = CGPoint(
                    x: corner.x == 0 ? 1 : -1,
                    y: corner.y == 0 ? 1 : -1
                )
                let angle = atan2(direction.y, direction.x) + CGFloat.random(in: -0.45...0.45)
                let speed = CGFloat.random(in: 250..<450)

                particles.append(
                    Particle(
                        layer: confetti,
                        velocity: CGPoint(x: cos(angle) * speed, y: sin(angle) * speed)
                    )
                )
            }
        }
    }

    func updateParticles(dt: CFTimeInterval) {
        let fadePerSecond: Float = 1.4

        for index in particles.indices.reversed() {
            let particle = particles[index]
            var position = particle.layer.position
            position.x += particle.velocity.x * CGFloat(dt)
            position.y += particle.velocity.y * CGFloat(dt)
            particle.layer.position = position
            particle.layer.opacity -= fadePerSecond * Float(dt)

            if particle.layer.opacity <= 0 {
                particle.layer.removeFromSuperlayer()
                particles.remove(at: index)
            }
        }
    }

    func removeAllParticles() {
        for particle in particles {
            particle.layer.removeFromSuperlayer()
        }
        particles.removeAll()
    }

    private func bounce(bounds: CGRect) -> Bool {
        let maxX = bounds.width - boxSize
        let maxY = bounds.height - boxSize
        var hitVerticalEdge = false
        var hitHorizontalEdge = false

        if position.x <= 0 {
            hitVerticalEdge = velocity.x < 0
            position.x = 0
            velocity.x = max(abs(velocity.x), minSpeed)
        } else if position.x >= maxX {
            hitVerticalEdge = velocity.x > 0
            position.x = maxX
            velocity.x = -max(abs(velocity.x), minSpeed)
        }

        if position.y <= 0 {
            hitHorizontalEdge = velocity.y < 0
            position.y = 0
            velocity.y = max(abs(velocity.y), minSpeed)
        } else if position.y >= maxY {
            hitHorizontalEdge = velocity.y > 0
            position.y = maxY
            velocity.y = -max(abs(velocity.y), minSpeed)
        }

        return hitVerticalEdge && hitHorizontalEdge
    }
}

private struct Particle {
    let layer: CAShapeLayer
    let velocity: CGPoint
}
