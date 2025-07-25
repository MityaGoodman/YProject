//
//  SwiftDataStorage.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation
import SwiftData

// MARK: - SwiftData Storage Implementation

@MainActor
final class SwiftDataTransactionsStorage: TransactionsStorage {
    private let storage: GenericSwiftDataStorage<TransactionModel, Transaction>
    
    init() throws {
        self.storage = GenericSwiftDataStorage<TransactionModel, Transaction>(
            toDomain: { model in
                let dummyAccount = BankAccount(dict: [:])
                let dummyCategory = Category(dict: [:])
                return model.toTransaction(account: dummyAccount, category: dummyCategory)
            },
            toModel: { transaction in
                TransactionModel(transaction: transaction)
            }
        )
    }
    
    func getAllTransactions() async -> [Transaction] {
        await storage.getAll()
    }
    
    func getTransactions(from: Date, to: Date) async -> [Transaction] {
        await storage.getFiltered(predicate: #Predicate<TransactionModel> { transaction in
            transaction.transactionDate >= from && transaction.transactionDate <= to
        })
    }
    
    func updateTransaction(_ transaction: Transaction) async {
        let txId = transaction.id
        await storage.update(transaction, updateBlock: { model in
            model.amount = transaction.amount
            model.transactionDate = transaction.transactionDate
            model.comment = transaction.comment
            model.updatedAt = Date()
        }, predicate: #Predicate<TransactionModel> { model in
            model.id == txId
        })
    }
    
    func deleteTransaction(id: Int) async {
        let txId = id
        await storage.delete(predicate: #Predicate<TransactionModel> { model in
            model.id == txId
        })
    }
    
    func createTransaction(_ transaction: Transaction) async {
        await storage.create(transaction)
    }
    
    func saveTransactions(_ transactions: [Transaction]) async {
        await storage.saveAll(transactions)
    }
}

@MainActor
final class SwiftDataBankAccountsStorage: BankAccountsStorage {
    private let storage: GenericSwiftDataStorage<BankAccountModel, BankAccount>
    
    init() throws {
        self.storage = GenericSwiftDataStorage<BankAccountModel, BankAccount>(
            toDomain: { $0.toBankAccount() },
            toModel: { BankAccountModel(account: $0) }
        )
    }
    
    func getBankAccount() async -> BankAccount? {
        await storage.getAll().first
    }
    
    func updateBankAccount(_ account: BankAccount) async {
        let accountId = account.id
        await storage.update(account, updateBlock: { model in
            model.balance = account.balance
            model.currency = account.currency
            model.updatedAt = Date()
        }, predicate: #Predicate<BankAccountModel> { model in
            model.id == accountId
        })
    }
    
    func saveBankAccount(_ account: BankAccount) async {
        await storage.saveAll([account])
    }
}

@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorage {
    private let storage: GenericSwiftDataStorage<CategoryModel, Category>
    
    init() throws {
        self.storage = GenericSwiftDataStorage<CategoryModel, Category>(
            toDomain: { $0.toCategory() },
            toModel: { CategoryModel(category: $0) }
        )
    }
    
    func getAllCategories() async -> [Category] {
        await storage.getAll()
    }
    
    func saveCategories(_ categories: [Category]) async {
        await storage.saveAll(categories)
    }
}

