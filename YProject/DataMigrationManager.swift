//
//  DataMigrationManager.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation

// MARK: - Storage Type

enum StorageType: String, CaseIterable {
    case swiftData = "SwiftData"
    case coreData = "CoreData"
    case userDefaults = "UserDefaults"
}

// MARK: - Data Migration Manager

final class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private init() {}
    
    func migrateData(
        from oldStorage: StorageType,
        to newStorage: StorageType,
        transactionsStorage: TransactionsStorage,
        bankAccountsStorage: BankAccountsStorage,
        categoriesStorage: CategoriesStorage
    ) async {
        print("Начинаем миграцию данных с \(oldStorage.rawValue) на \(newStorage.rawValue)")
        
        do {
            // Миграция транзакций
            await migrateTransactions(
                from: oldStorage,
                to: newStorage,
                storage: transactionsStorage
            )
            
            // Миграция банковских счетов
            await migrateBankAccounts(
                from: oldStorage,
                to: newStorage,
                storage: bankAccountsStorage
            )
            
            // Миграция категорий
            await migrateCategories(
                from: oldStorage,
                to: newStorage,
                storage: categoriesStorage
            )
            
            // Очистка старого хранилища
            await clearOldStorage(oldStorage)
            
            print("Миграция данных завершена успешно")
        } catch {
            print("Ошибка при миграции данных: \(error)")
        }
    }
    
    private func migrateTransactions(
        from oldStorage: StorageType,
        to newStorage: StorageType,
        storage: TransactionsStorage
    ) async {
        print("Миграция транзакций...")
        
        // Получаем все транзакции из старого хранилища
        let oldTransactions = await getTransactionsFromStorage(oldStorage)
        
        // Сохраняем в новое хранилище
        await storage.saveTransactions(oldTransactions)
        
        print("Мигрировано \(oldTransactions.count) транзакций")
    }
    
    private func migrateBankAccounts(
        from oldStorage: StorageType,
        to newStorage: StorageType,
        storage: BankAccountsStorage
    ) async {
        print("Миграция банковских счетов...")
        
        // Получаем банковский счет из старого хранилища
        let oldAccount = await getBankAccountFromStorage(oldStorage)
        
        if let account = oldAccount {
            // Сохраняем в новое хранилище
            await storage.saveBankAccount(account)
            print("Мигрирован банковский счет: \(account.name)")
        }
    }
    
    private func migrateCategories(
        from oldStorage: StorageType,
        to newStorage: StorageType,
        storage: CategoriesStorage
    ) async {
        print("Миграция категорий...")
        
        // Получаем категории из старого хранилища
        let oldCategories = await getCategoriesFromStorage(oldStorage)
        
        // Сохраняем в новое хранилище
        await storage.saveCategories(oldCategories)
        
        print("Мигрировано \(oldCategories.count) категорий")
    }
    
    private func getTransactionsFromStorage(_ storage: StorageType) async -> [Transaction] {
        switch storage {
        case .swiftData:
            // Получаем из SwiftData
            let swiftDataStorage = try? await SwiftDataTransactionsStorage()
            return await swiftDataStorage?.getAllTransactions() ?? []
        case .coreData:
            // добавлю CoreData
            return []
        case .userDefaults:
            // добавлю UserDefaults
            return []
        }
    }
    
    private func getBankAccountFromStorage(_ storage: StorageType) async -> BankAccount? {
        switch storage {
        case .swiftData:
            let swiftDataStorage = try? await SwiftDataBankAccountsStorage()
            return await swiftDataStorage?.getBankAccount()
        case .coreData:
            return nil
        case .userDefaults:
            return nil
        }
    }
    
    private func getCategoriesFromStorage(_ storage: StorageType) async -> [Category] {
        switch storage {
        case .swiftData:
            let swiftDataStorage = try? await SwiftDataCategoriesStorage()
            return await swiftDataStorage?.getAllCategories() ?? []
        case .coreData:
            return []
        case .userDefaults:
            return []
        }
    }
    
    private func clearOldStorage(_ storage: StorageType) async {
        print("Очистка старого хранилища: \(storage.rawValue)")
        
        switch storage {
        case .swiftData:
            // SwiftData очищается автоматически при миграции
            break
        case .coreData:
            // В будущем добавлю очистку CoreData
            break
        case .userDefaults:
            // В будущем добавлю очистку UserDefaults
            break
        }
    }
}

