//
//  BackupStorage.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation
import SwiftData

// MARK: - Backup Storage Implementation

final class SwiftDataBackupStorage: BackupStorage {
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
    
    func addBackupEntry(_ entry: BackupEntry) async {
        do {
            let model = BackupEntryModel(entry: entry)
            modelContext.insert(model)
            try modelContext.save()
        } catch {
            print("Ошибка при добавлении записи в бекап: \(error)")
        }
    }
    
    func getBackupEntries() async -> [BackupEntry] {
        do {
            let descriptor = FetchDescriptor<BackupEntryModel>()
            let models = try modelContext.fetch(descriptor)
            return models.compactMap { $0.toBackupEntry() }
        } catch {
            print("Ошибка при получении записей бекапа: \(error)")
            return []
        }
    }
    
    func removeBackupEntry(id: Int) async {
        do {
            let entryId = id
            let descriptor = FetchDescriptor<BackupEntryModel>(
                predicate: #Predicate<BackupEntryModel> { model in
                    model.id == entryId
                }
            )
            let models = try modelContext.fetch(descriptor)
            for model in models {
                modelContext.delete(model)
            }
            try modelContext.save()
        } catch {
            print("Ошибка при удалении записи из бекапа: \(error)")
        }
    }
    
    func clearBackup() async {
        do {
            let descriptor = FetchDescriptor<BackupEntryModel>()
            let models = try modelContext.fetch(descriptor)
            for model in models {
                modelContext.delete(model)
            }
            try modelContext.save()
        } catch {
            print("Ошибка при очистке бекапа: \(error)")
        }
    }
}

// MARK: - Backup Manager

final class BackupManager {
    let backupStorage: BackupStorage
    
    init(backupStorage: BackupStorage) {
        self.backupStorage = backupStorage
    }
    
    func syncBackupWithBackend(
        transactionsService: TransactionsService,
        bankAccountsService: BankAccountsService
    ) async -> [Int] {
        let backupEntries = await backupStorage.getBackupEntries()
        var syncedIds: [Int] = []
        for entry in backupEntries {
            switch entry.action {
            case .create:
                if let transaction = entry.data as? Transaction {
                    do {
                        try await transactionsService.create(transaction)
                        syncedIds.append(entry.id)
                    } catch {
                        print("Ошибка синхронизации создания транзакции: \(error)")
                    }
                } else if let account = entry.data as? BankAccount {
                    await bankAccountsService.updateAccount(account, balance: account.balance, currency: account.currency)
                    syncedIds.append(entry.id)
                }
            case .update:
                if let transaction = entry.data as? Transaction {
                    do {
                        try await transactionsService.update(transaction)
                        syncedIds.append(entry.id)
                    } catch {
                        print("Ошибка синхронизации обновления транзакции: \(error)")
                    }
                } else if let account = entry.data as? BankAccount {
                    await bankAccountsService.updateAccount(account, balance: account.balance, currency: account.currency)
                    syncedIds.append(entry.id)
                }
            case .delete:
                if let transaction = entry.data as? Transaction {
                    do {
                        try await transactionsService.delete(id: transaction.id)
                        syncedIds.append(entry.id)
                    } catch {
                        print("Ошибка синхронизации удаления транзакции: \(error)")
                    }
                }
            }
        }
        for id in syncedIds {
            await backupStorage.removeBackupEntry(id: id)
        }
        return syncedIds
    }
    
    func backupTransaction(_ transaction: Transaction, action: BackupAction) async {
        let entry = BackupEntry(
            id: transaction.id,
            action: action,
            data: transaction,
            timestamp: Date()
        )
        await backupStorage.addBackupEntry(entry)
    }
    
    func backupBankAccount(_ account: BankAccount, action: BackupAction) async {
        let entry = BackupEntry(
            id: account.id,
            action: action,
            data: account,
            timestamp: Date()
        )
        await backupStorage.addBackupEntry(entry)
    }
}

