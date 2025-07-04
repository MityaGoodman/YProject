//
//  TransactionsListViewModel.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI

@MainActor
final class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private let service: TransactionsService
    
    init(service: TransactionsService) {
        self.service = service
    }
    
    func loadToday(direction: Direction) async {
        let now = Date()
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = cal.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: now
        )!

        let all = await service.fetch(from: start, to: end)
        let filtered = all.filter { $0.category.isIncome == direction }
        transactions = filtered
    }
    
    func create(_ tx: Transaction) async {
        await service.create(tx)
    }
    
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    var currencyCode: String {
        transactions.first?.account.currency ?? "RUB"
    }
}
