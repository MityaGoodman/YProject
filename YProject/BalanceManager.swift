//
//  BalanceManager.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation
import Combine

@MainActor
final class BalanceManager: ObservableObject {
    @Published var currentBalance: Decimal = 0
    @Published var currency: String = "₽"
    
    private let bankAccountsService: BankAccountsService
    private let transactionsService: TransactionsService
    private var cancellables = Set<AnyCancellable>()
    private var currentAccount: BankAccount?
    
    init(bankAccountsService: BankAccountsService, transactionsService: TransactionsService) {
        self.bankAccountsService = bankAccountsService
        self.transactionsService = transactionsService
    }
    
    func loadCurrentBalance() async throws {
        if let account = await bankAccountsService.fetchPrimaryAccount() {
            currentAccount = account
            currentBalance = account.balance
            currency = account.currency
        } else {
            throw NetworkError.networkError(NSError(domain: "BalanceManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось загрузить счет"]))
        }
    }
    
    func updateBalanceAfterCreate(_ transaction: Transaction) {
        let amount = transaction.amount
        if transaction.category.isIncome == .income {
            currentBalance += amount
        } else {
            currentBalance -= amount
        }
        
        updateBalanceOnServer()
    }
    
    func updateBalanceAfterEdit(oldTransaction: Transaction, newTransaction: Transaction) {
        let oldAmount = oldTransaction.amount
        let newAmount = newTransaction.amount
        let oldDirection = oldTransaction.category.isIncome
        let newDirection = newTransaction.category.isIncome
        
        if oldDirection == .income {
            currentBalance -= oldAmount
        } else {
            currentBalance += oldAmount
        }
        
        if newDirection == .income {
            currentBalance += newAmount
        } else {
            currentBalance -= newAmount
        }
        updateBalanceOnServer()
    }
    
    func updateBalanceAfterDelete(_ transaction: Transaction) {
        let amount = transaction.amount
        if transaction.category.isIncome == .income {
            currentBalance -= amount
        } else {
            currentBalance += amount
        }

        updateBalanceOnServer()
    }
    
    private func updateBalanceOnServer() {
        guard let account = currentAccount else {
            print("❌ Нет текущего счета для обновления баланса")
            return
        }
        
        Task {
            await bankAccountsService.updateBalance(account, to: currentBalance)
        }
    }
    
    var formattedBalance: String {
        return currentBalance.formatted()
    }

    func updateBalanceManually(to newBalance: Decimal, currency: String) {
        currentBalance = newBalance
        self.currency = currency
        
        updateAccountOnServer(balance: newBalance, currency: currency)
    }
    
    private func updateAccountOnServer(balance: Decimal, currency: String) {
        guard let account = currentAccount else {
            print("❌ Нет текущего счета для обновления")
            return
        }
        
        Task {
            await bankAccountsService.updateAccount(account, balance: balance, currency: currency)
        }
    }
    
    func fetchAllTransactions() async -> [Transaction] {
        do {
            let from = Date(timeIntervalSince1970: 0)
            let to = Date()
            return try await transactionsService.fetch(from: from, to: to)
        } catch {
            print("Ошибка загрузки транзакций: \(error)")
            return []
        }
    }
}

