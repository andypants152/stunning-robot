//
//  TargetManager.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import UIKit

final class TargetManager {
    private var targets: [Target] = []
    private let collisionSoundPlayer = CollisionSoundPlayer()
    private let targetSize: CGFloat
    private var currentBounds: CGRect = .zero

    init(targetSize: CGFloat) {
        self.targetSize = targetSize
    }

    func spawnAll(bounds: CGRect, playerRect: CGRect, parentLayer: CALayer, parentView: UIView) {
        currentBounds = bounds
        removeAllTargets()

        for type in TargetType.allCases {
            let targetRect = availableTargetRect(avoiding: playerRect)
            let layer = CAShapeLayer()
            layer.fillColor = type.color.cgColor
            layer.strokeColor = UIColor.white.cgColor
            layer.lineWidth = 2
            layer.path = UIBezierPath(rect: targetRect).cgPath
            parentLayer.addSublayer(layer)

            let label = UILabel()
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            label.textAlignment = .center
            label.text = String(type.points)
            label.isHidden = false
            label.center = CGPoint(x: targetRect.midX, y: targetRect.midY)
            label.sizeToFit()
            parentView.addSubview(label)

            targets.append(Target(rect: targetRect, layer: layer, label: label, type: type))
        }
    }

    func removeAllTargets() {
        for target in targets {
            target.remove()
        }
        targets.removeAll()
    }

    func checkCollisions(
        playerRect: CGRect,
        score: Int,
        physicsEngine: PhysicsEngine,
        parentLayer: CALayer,
        onScoreUpdate: (Int) -> Void,
        triggerPenaltyFlash: () -> Void
    ) -> Int {
        var currentScore = score

        for index in targets.indices.reversed() {
            let target = targets[index]
            guard playerRect.intersects(target.rect) else { continue }

            currentScore += target.type.points
            if currentScore < 0 { currentScore = 0 }
            onScoreUpdate(currentScore)

            let collisionPoint = CGPoint(x: target.rect.midX, y: target.rect.midY)
            physicsEngine.spawnParticles(at: collisionPoint, color: target.type.color, parentLayer: parentLayer)
            collisionSoundPlayer.play(for: target.type)

            if target.type.points < 0 {
                triggerPenaltyFlash()
            }

            respawnTarget(at: index, playerRect: playerRect)
        }

        return currentScore
    }

    private func respawnTarget(at index: Int, playerRect: CGRect) {
        guard index < targets.count else { return }

        var target = targets[index]
        let newRect = availableTargetRect(avoiding: playerRect, excludingTargetAt: index, fallback: target.rect)

        target.rect = newRect
        target.layer.path = UIBezierPath(rect: newRect).cgPath
        target.label.center = CGPoint(x: newRect.midX, y: newRect.midY)

        targets[index] = target
    }

    private func availableTargetRect(
        avoiding playerRect: CGRect,
        excludingTargetAt excludedIndex: Int? = nil,
        fallback: CGRect? = nil
    ) -> CGRect {
        let placementBounds = targetPlacementBounds
        let fallbackRect = clampedTargetRect(fallback ?? placementBounds.originRect(size: targetSize), in: placementBounds)

        for _ in 0..<30 {
            let origin = CGPoint(
                x: CGFloat.random(in: placementBounds.minX...placementBounds.maxX),
                y: CGFloat.random(in: placementBounds.minY...placementBounds.maxY)
            )
            let candidateRect = CGRect(origin: origin, size: CGSize(width: targetSize, height: targetSize))

            if canPlace(candidateRect, avoiding: playerRect, excluding: excludedIndex) {
                return candidateRect
            }
        }

        for candidateRect in deterministicFallbackRects(in: placementBounds) {
            if canPlace(candidateRect, avoiding: playerRect, excluding: excludedIndex) {
                return candidateRect
            }
        }

        return fallbackRect
    }

    private var targetPlacementBounds: CGRect {
        let inset: CGFloat = 50
        let minX = min(inset, max(0, currentBounds.width - targetSize))
        let minY = min(inset, max(0, currentBounds.height - targetSize))
        let maxX = max(minX, currentBounds.width - inset - targetSize)
        let maxY = max(minY, currentBounds.height - inset - targetSize)

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func deterministicFallbackRects(in bounds: CGRect) -> [CGRect] {
        let origins = [
            CGPoint(x: bounds.minX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.minY),
            CGPoint(x: bounds.minX, y: bounds.maxY),
            CGPoint(x: bounds.maxX, y: bounds.maxY),
            CGPoint(x: bounds.midX, y: bounds.midY),
            CGPoint(x: bounds.midX, y: bounds.minY),
            CGPoint(x: bounds.midX, y: bounds.maxY),
            CGPoint(x: bounds.minX, y: bounds.midY),
            CGPoint(x: bounds.maxX, y: bounds.midY)
        ]

        return origins.map { CGRect(origin: $0, size: CGSize(width: targetSize, height: targetSize)) }
    }

    private func canPlace(_ rect: CGRect, avoiding playerRect: CGRect, excluding excludedIndex: Int?) -> Bool {
        !rect.intersects(playerRect) && !overlapsExistingTarget(rect, excluding: excludedIndex)
    }

    private func clampedTargetRect(_ rect: CGRect, in bounds: CGRect) -> CGRect {
        CGRect(
            x: min(max(rect.minX, bounds.minX), bounds.maxX),
            y: min(max(rect.minY, bounds.minY), bounds.maxY),
            width: targetSize,
            height: targetSize
        )
    }

    private func overlapsExistingTarget(_ rect: CGRect, excluding excludedIndex: Int?) -> Bool {
        for (index, existing) in targets.enumerated() {
            if excludedIndex == index { continue }

            if rect.intersects(existing.rect) {
                return true
            }
        }

        return false
    }
}

private struct Target {
    var rect: CGRect
    var layer: CAShapeLayer
    var label: UILabel
    var type: TargetType

    func remove() {
        layer.removeFromSuperlayer()
        label.removeFromSuperview()
    }
}

private extension CGRect {
    func originRect(size: CGFloat) -> CGRect {
        CGRect(x: minX, y: minY, width: size, height: size)
    }
}
