//
//  ServiceFactory.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation
@MainActor
final class ServiceFactory {
    static func createLocalServices(
        networkClient: NetworkClient,
        config: Config
    ) throws -> (
        transactionsService: LocalTransactionsService,
        bankAccountsService: LocalBankAccountsService,
        categoriesService: LocalCategoriesService
    ) {
        let apiTransactionsService = APITransactionsService(networkClient: networkClient)
        let apiBankAccountsService = APIBankAccountsService(networkClient: networkClient)
        let apiCategoriesService = APICategoriesService(networkClient: networkClient)
        let transactionsStorage = try SwiftDataTransactionsStorage()
        let bankAccountsStorage = try SwiftDataBankAccountsStorage()
        let categoriesStorage = try SwiftDataCategoriesStorage()
        let backupStorage = try SwiftDataBackupStorage()
        let backupManager = BackupManager(backupStorage: backupStorage)
        let syncManager = SyncManager(
            backupManager: backupManager,
            transactionsService: apiTransactionsService,
            bankAccountsService: apiBankAccountsService
        )
        let localTransactionsService = LocalTransactionsService(
            apiService: apiTransactionsService,
            localStorage: transactionsStorage,
            syncManager: syncManager
        )
        let localBankAccountsService = LocalBankAccountsService(
            apiService: apiBankAccountsService,
            localStorage: bankAccountsStorage,
            syncManager: syncManager
        )
        let localCategoriesService = LocalCategoriesService(
            apiService: apiCategoriesService,
            localStorage: categoriesStorage
        )
        return (
            transactionsService: localTransactionsService,
            bankAccountsService: localBankAccountsService,
            categoriesService: localCategoriesService
        )
    }
}

// MARK: - Mock Implementations for Fallback

private class MockTransactionsStorage: TransactionsStorage {
    func getAllTransactions() async -> [Transaction] { return [] }
    func getTransactions(from: Date, to: Date) async -> [Transaction] { return [] }
    func updateTransaction(_ transaction: Transaction) async {}
    func deleteTransaction(id: Int) async {}
    func createTransaction(_ transaction: Transaction) async {}
    func saveTransactions(_ transactions: [Transaction]) async {}
}

private class MockBankAccountsStorage: BankAccountsStorage {
    func getBankAccount() async -> BankAccount? { return nil }
    func updateBankAccount(_ account: BankAccount) async {}
    func saveBankAccount(_ account: BankAccount) async {}
}

private class MockCategoriesStorage: CategoriesStorage {
    func getAllCategories() async -> [Category] { return [] }
    func saveCategories(_ categories: [Category]) async {}
}

private class MockBackupStorage: BackupStorage {
    func addBackupEntry(_ entry: BackupEntry) async {}
    func getBackupEntries() async -> [BackupEntry] { return [] }
    func removeBackupEntry(id: Int) async {}
    func clearBackup() async {}
}

private class MockSyncManager: SyncManager {
    init() {
        let mockBackupStorage = MockBackupStorage()
        let mockBackupManager = BackupManager(backupStorage: mockBackupStorage)
        let mockTransactionsService = MockTransactionsService(cache: TransactionsFileCache(fileURL: URL(fileURLWithPath: "")))
        let mockBankAccountsService = MockBankAccountService(account: nil)
        super.init(
            backupManager: mockBackupManager,
            transactionsService: mockTransactionsService,
            bankAccountsService: mockBankAccountsService
        )
    }
}

