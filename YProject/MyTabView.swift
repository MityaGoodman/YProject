//
//  TabView.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI

struct TabView: View {
    var body: some View {
        TabView {
            Text("Расходы")
                .tabItem {
                    Image(systemName: "minus.circle.fill")
                    Text("Расходы")
                }
            Text("Доходы")
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Доходы")
                }
            Text("Счет")
                .tabItem {
                    Image(systemName: "banknote.fill")
                    Text("Счет")
                }
            Text("Статьи")
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Статьи")
                }
            Text("Настройки")
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки")
                }
        }
        .accentColor(Color("AccentColor"))
    }
}
