//
//  BouncingBoxRepresentable.swift
//  stunning-robot
//
//  Created by Andy Meyer on 7/4/26.
//
import SwiftUI

struct BouncingBoxRepresentable: UIViewRepresentable {
    let onScoreUpdate: (Int) -> Void
    let onHighScoreUpdate: ((Int) -> Void)
    let onStateUpdate: (BouncingBoxView.GameState) -> Void

    func makeUIView(context: Context) -> BouncingBoxView {
        let view = BouncingBoxView()
        view.onScoreUpdate = onScoreUpdate
        view.onHighScoreUpdate = onHighScoreUpdate
        view.onStateUpdate = onStateUpdate
        return view
    }

    func updateUIView(_ uiView: BouncingBoxView, context: Context) {
        uiView.onScoreUpdate = onScoreUpdate
        uiView.onStateUpdate = onStateUpdate
        uiView.onHighScoreUpdate = onHighScoreUpdate
    }
}
