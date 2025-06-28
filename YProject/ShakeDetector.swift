//
//  ShakeDetector.swift
//  YProject
//
//  Created by Митя on 28.06.2025.
//

import Foundation
import CoreMotion
import Combine

final class ShakeDetector: ObservableObject {
    @Published var didShake: Bool = false
    private let mgr = CMMotionManager()
    private var lastShakeDate = Date.distantPast

    init(threshold: Double = 2.5, interval: TimeInterval = 0.5) {
        guard mgr.isAccelerometerAvailable else { return }
        mgr.accelerometerUpdateInterval = 0.1
        mgr.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let d = data else { return }
            let mag = sqrt(d.acceleration.x*d.acceleration.x
                         + d.acceleration.y*d.acceleration.y
                         + d.acceleration.z*d.acceleration.z)
            let now = Date()
            if mag > threshold && now.timeIntervalSince(self?.lastShakeDate ?? .distantPast) > interval {
                self?.lastShakeDate = now
                self?.didShake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.didShake = false
                }
            }
        }
    }

    deinit {
        mgr.stopAccelerometerUpdates()
    }
}

