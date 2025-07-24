//
//  YProjectApp.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI

@main
struct YProjectApp: App {
    @State private var splashFinished = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if splashFinished {
                    MyTabView()
                } else {
                    SplashScreen(isFinished: $splashFinished)
                }
            }
        }
    }
}

