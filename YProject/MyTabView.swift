//
//  MyTabView.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI

struct MyTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TransactionsListView(direction: .outcome)
                
            }
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Расходы")
                }
            NavigationStack {
                TransactionsListView(direction: .income)
            }
                .tabItem {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                    Text("Доходы")
                }
            NavigationStack {
                BalanceSheet()
            }
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
        .accentColor(Color("Color"))
    }
}

struct MyTabView_Previews: PreviewProvider {
    static var previews: some View {
        MyTabView()
    }
}
