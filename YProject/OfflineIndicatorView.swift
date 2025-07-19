//
//  OfflineIndicatorView.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import SwiftUI

struct OfflineIndicatorView: View {
    let isOffline: Bool
    
    var body: some View {
        if isOffline {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                Text("Offline mode")
                    .foregroundColor(.white)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack {
        OfflineIndicatorView(isOffline: true)
        Spacer()
    }
}

