//
//  ArticlesViewModel.swift
//  YProject
//
//  Created by Митя on 04.07.2025.
//

import SwiftUI

@MainActor
final class ArticlesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var allUsedCategories: [Category] = []
    
    private let txService: TransactionsService
    
    init(service: TransactionsService) {
        self.txService = service
    }
    
    func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let s = Array(a.lowercased())
        let t = Array(b.lowercased())
        let n = s.count, m = t.count
        guard n > 0 else { return m }
        guard m > 0 else { return n }
        
        var dp = [[Int]](repeating: [Int](repeating: 0, count: m+1), count: n+1)
        
        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }
        
        for i in 1...n {
            for j in 1...m {
                let cost = s[i-1] == t[j-1] ? 0 : 1
                dp[i][j] = min(
                    dp[i-1][j] + 1,
                    dp[i][j-1] + 1,
                    dp[i-1][j-1] + cost
                )
            }
        }
        return dp[n][m]
    }
    
    func isFuzzyMatch(_ text: String, query: String, maxDistance: Int) -> Bool { // реализация fuzzy-search
        let distance = levenshteinDistance(text, query)
        return distance <= maxDistance
    }
    
    func loadCategories() async {
        let txs = await txService.fetch(
            from: Date(timeIntervalSince1970: 0),
            to: Date()
        )
        let usedIDs = Set(txs.map { $0.category.id })
        let used = allCategories.filter { usedIDs.contains($0.id) }
        allUsedCategories = used.sorted { $0.name < $1.name }
    }
    
    var filteredCategories: [Category] {
        guard !searchText.isEmpty else { return allUsedCategories }
        let threshold = max(1, searchText.count / 2)
        return allUsedCategories.filter { cat in
            if cat.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            return isFuzzyMatch(cat.name, query: searchText, maxDistance: threshold)
        }
    }
}

