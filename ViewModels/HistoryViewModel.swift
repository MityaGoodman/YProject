//
//  HistoryViewModel.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var start: Date
    @Published var end: Date
    
    private let service: TransactionsService
    private let direction: Direction
    private var calendar = Calendar.current
    
    init(
      direction: Direction,
      service: TransactionsService,
      now: Date = .init()
    ) {
        self.direction = direction
        self.service = service
        
        let endOfToday = calendar.date(
            bySettingHour: 23, minute: 59, second: 59, of: now
        )!
        let startOfMonthAgo = calendar.date(
            byAdding: .month, value: -1,
            to: calendar.startOfDay(for: now)
        )!
        
        self.end = endOfToday
        self.start = startOfMonthAgo
        
        Task { await refresh() }
    }
    
    func refresh() async {
        if start > end {
            start = calendar.startOfDay(for: end)
        }
        
        let adjustedEnd = calendar.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: end
        )!
        
        let all = await service.fetch(from: calendar.startOfDay(for: start), to: adjustedEnd)
        let filtered = all.filter { $0.category.isIncome == direction }
        transactions = filtered
    }
    
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    var currencyCode: String {
        transactions.first?.account.currency ?? "RUB"
    }
}
