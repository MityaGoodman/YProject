//
//  SplashScreen.swift
//  YProject
//
//  Created by Митя on 24.07.2025.
//

import SwiftUI

struct SplashScreen: View {
    @Binding var isFinished: Bool

    var body: some View {
        LottieView(name: "animation", completion: {
            isFinished = true
        })
        .ignoresSafeArea()
        .background(Color.white)
    }
}
