//
//  TransactionsListViewModel.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI
import Foundation

@MainActor
final class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isOffline: Bool = false
    @Published var noDataMessage: String? = nil
    
    let service: TransactionsService
    let balanceManager: BalanceManager
    let categoriesService: CategoriesService
    
    init(service: TransactionsService, balanceManager: BalanceManager, categoriesService: CategoriesService) {
        self.service = service
        self.balanceManager = balanceManager
        self.categoriesService = categoriesService
    }
    
    func loadToday(direction: Direction) async {
        isLoading = true
        errorMessage = nil
        isOffline = false
        noDataMessage = nil
        
        do {
            let now = Date()
            let cal = Calendar.current
            let start = cal.startOfDay(for: now)
            let end = cal.date(
                bySettingHour: 23,
                minute: 59,
                second: 59,
                of: now
            )!
            
            let all = try await service.fetch(from: start, to: end)
            let filtered = all.filter { $0.category.isIncome == direction }
            transactions = filtered
            for tx in transactions {
                print("[TransactionsList] id: \(tx.id), amount: \(tx.amount), date: \(tx.transactionDate)")
            }
            if filtered.isEmpty {
                noDataMessage = "Нет транзакций за сегодня"
            }
        } catch let networkError as NetworkError {
            switch networkError {
            case .offlineMode(let localData):
                let filtered = localData.filter { $0.category.isIncome == direction }
                transactions = filtered
                isOffline = true
                errorMessage = "Работа в офлайн режиме"
                if filtered.isEmpty {
                    noDataMessage = "Нет транзакций за сегодня (офлайн)"
                }
            case .networkError:
                errorMessage = "Ошибка сети. Проверьте подключение к интернету."
                isOffline = true
            default:
                errorMessage = "Ошибка загрузки транзакций: \(networkError.localizedDescription)"
            }
        } catch {
            errorMessage = "Ошибка загрузки транзакций: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func create(_ tx: Transaction, direction: Direction) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.create(tx)
            balanceManager.updateBalanceAfterCreate(tx)
            await loadToday(direction: direction)
        } catch {
            errorMessage = "Ошибка создания транзакции: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func update(_ tx: Transaction, direction: Direction) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let oldTransaction = transactions.first { $0.id == tx.id }
            try await service.update(tx)
            
            if let oldTx = oldTransaction {
                balanceManager.updateBalanceAfterEdit(oldTransaction: oldTx, newTransaction: tx)
            }
            
            await loadToday(direction: direction)
        } catch {
            errorMessage = "Ошибка обновления транзакции: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func delete(_ id: Int, direction: Direction) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let transactionToDelete = transactions.first { $0.id == id }
            try await service.delete(id: id)
            if let tx = transactionToDelete {
                balanceManager.updateBalanceAfterDelete(tx)
            }
            
            await loadToday(direction: direction)
        } catch {
            errorMessage = "Ошибка удаления транзакции: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    var currencyCode: String {
        transactions.first?.account.currency ?? "RUB"
    }
}
