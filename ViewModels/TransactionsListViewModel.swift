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
    
    func create(_ tx: Transaction, direction: Direction) async {
        await service.create(tx)
        await loadToday(direction: direction)
    }
    
    func update(_ tx: Transaction, direction: Direction) async {
        await service.update(tx)
        await loadToday(direction: direction)
    }
    
    func delete(_ id: Int, direction: Direction) async {
        await service.delete(id: id)
        await loadToday(direction: direction)
    }
    
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    var currencyCode: String {
        transactions.first?.account.currency ?? "RUB"
    }
}
