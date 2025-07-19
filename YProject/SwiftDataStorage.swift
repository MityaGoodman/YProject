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
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        let schema = Schema([
            TransactionModel.self,
            BankAccountModel.self,
            CategoryModel.self,
            BackupEntryModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema)
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = ModelContext(modelContainer)
    }
    
    func getAllTransactions() async -> [Transaction] {
        do {
            let descriptor = FetchDescriptor<TransactionModel>()
            let models = try modelContext.fetch(descriptor)
            let dummyAccount = BankAccount(dict: [:])
            let dummyCategory = Category(dict: [:])
            return models.map { $0.toTransaction(account: dummyAccount, category: dummyCategory) }
        } catch {
            print("Ошибка при получении транзакций: \(error)")
            return []
        }
    }
    
    func getTransactions(from: Date, to: Date) async -> [Transaction] {
        do {
            let descriptor = FetchDescriptor<TransactionModel>(
                predicate: #Predicate<TransactionModel> { transaction in
                    transaction.transactionDate >= from && transaction.transactionDate <= to
                }
            )
            let models = try modelContext.fetch(descriptor)
            let dummyAccount = BankAccount(dict: [:])
            let dummyCategory = Category(dict: [:])
            return models.map { $0.toTransaction(account: dummyAccount, category: dummyCategory) }
        } catch {
            print("Ошибка при получении транзакций за период: \(error)")
            return []
        }
    }
    
    func updateTransaction(_ transaction: Transaction) async {
        do {
            let transactionId = transaction.id
            let descriptor = FetchDescriptor<TransactionModel>(
                predicate: #Predicate<TransactionModel> { model in
                    model.id == transactionId
                }
            )
            let models = try modelContext.fetch(descriptor)
            if let model = models.first {
                model.amount = transaction.amount
                model.transactionDate = transaction.transactionDate
                model.comment = transaction.comment
                model.updatedAt = Date()
            }
            try modelContext.save()
        } catch {
            print("Ошибка при обновлении транзакции: \(error)")
        }
    }
    
    func deleteTransaction(id: Int) async {
        do {
            let transactionId = id
            let descriptor = FetchDescriptor<TransactionModel>(
                predicate: #Predicate<TransactionModel> { model in
                    model.id == transactionId
                }
            )
            let models = try modelContext.fetch(descriptor)
            for model in models {
                modelContext.delete(model)
            }
            try modelContext.save()
        } catch {
            print("Ошибка при удалении транзакции: \(error)")
        }
    }
    
    func createTransaction(_ transaction: Transaction) async {
        do {
            let model = TransactionModel(transaction: transaction)
            modelContext.insert(model)
            try modelContext.save()
        } catch {
            print("Ошибка при создании транзакции: \(error)")
        }
    }
    
    func saveTransactions(_ transactions: [Transaction]) async {
        do {
            let descriptor = FetchDescriptor<TransactionModel>()
            let existingModels = try modelContext.fetch(descriptor)
            for model in existingModels {
                modelContext.delete(model)
            }
            for transaction in transactions {
                let model = TransactionModel(transaction: transaction)
                modelContext.insert(model)
            }
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении транзакций: \(error)")
        }
    }
}

@MainActor
final class SwiftDataBankAccountsStorage: BankAccountsStorage {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        let schema = Schema([
            TransactionModel.self,
            BankAccountModel.self,
            CategoryModel.self,
            BackupEntryModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema)
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = ModelContext(modelContainer)
    }
    
    func getBankAccount() async -> BankAccount? {
        do {
            let descriptor = FetchDescriptor<BankAccountModel>()
            let models = try modelContext.fetch(descriptor)
            return models.first?.toBankAccount()
        } catch {
            print("Ошибка при получении банковского счета: \(error)")
            return nil
        }
    }
    
    func updateBankAccount(_ account: BankAccount) async {
        do {
            let accountId = account.id
            let descriptor = FetchDescriptor<BankAccountModel>(
                predicate: #Predicate<BankAccountModel> { model in
                    model.id == accountId
                }
            )
            let models = try modelContext.fetch(descriptor)
            if let model = models.first {
                model.balance = account.balance
                model.currency = account.currency
                model.updatedAt = Date()
            }
            try modelContext.save()
        } catch {
            print("Ошибка при обновлении банковского счета: \(error)")
        }
    }
    
    func saveBankAccount(_ account: BankAccount) async {
        do {
            let descriptor = FetchDescriptor<BankAccountModel>()
            let existingModels = try modelContext.fetch(descriptor)
            for model in existingModels {
                modelContext.delete(model)
            }
            let model = BankAccountModel(account: account)
            modelContext.insert(model)
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении банковского счета: \(error)")
        }
    }
}

@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorage {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        let schema = Schema([
            TransactionModel.self,
            BankAccountModel.self,
            CategoryModel.self,
            BackupEntryModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema)
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = ModelContext(modelContainer)
    }
    
    func getAllCategories() async -> [Category] {
        do {
            let descriptor = FetchDescriptor<CategoryModel>()
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toCategory() }
        } catch {
            print("Ошибка при получении категорий: \(error)")
            return []
        }
    }
    
    func saveCategories(_ categories: [Category]) async {
        do {
            let descriptor = FetchDescriptor<CategoryModel>()
            let existingModels = try modelContext.fetch(descriptor)
            for model in existingModels {
                modelContext.delete(model)
            }
            for category in categories {
                let model = CategoryModel(category: category)
                modelContext.insert(model)
            }
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении категорий: \(error)")
        }
    }
}

