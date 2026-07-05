//
//  TargetSystem.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import UIKit

enum TargetType: CaseIterable {
    case green   // +10, common, safe
    case blue    // +25, medium risk
    case red     // -15, penalty
    case purple  // +50, rare, fast
    case yellow  // +5, decoy, erratic
}

extension TargetType {
    var color: UIColor {
        switch self {
        case .green: return .systemGreen
        case .blue:  return .systemBlue
        case .red:   return .systemRed
        case .purple:return .systemPurple
        case .yellow:return .systemYellow
        }
    }

    var points: Int {
        switch self {
        case .green: return 10
        case .blue:  return 25
        case .red:   return -15
        case .purple:return 50
        case .yellow:return 5
        }
    }

    var spawnWeight: Double {
        switch self {
        case .green: return 40.0
        case .blue:  return 30.0
        case .red:   return 20.0
        case .purple:return 5.0
        case .yellow:return 5.0
        }
    }

    var baseSpeed: CGFloat {
        switch self {
        case .green: return 150
        case .blue:  return 200
        case .red:   return 180
        case .purple:return 300
        case .yellow:return 250
        }
    }
}
