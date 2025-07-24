//
//  LottieView.swift
//  YProject
//
//  Created by Митя on 24.07.2025.
//

import SwiftUI
import UIKit
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    let completion: (() -> Void)?

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play { finished in
            if finished {
                completion?()
            }
        }
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
