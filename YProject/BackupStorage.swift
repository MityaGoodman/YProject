//
//  BackupStorage.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation
import SwiftData

// MARK: - Backup Storage Implementation

@MainActor
final class SwiftDataBackupStorage: BackupStorage {
    private let storage: GenericSwiftDataStorage<BackupEntryModel, BackupEntry>
    
    init() throws {
        self.storage = GenericSwiftDataStorage<BackupEntryModel, BackupEntry>(
            toDomain: { $0.toBackupEntry() ?? BackupEntry(id: 0, action: .create, data: "", timestamp: Date()) },
            toModel: { BackupEntryModel(entry: $0) }
        )
    }
    
    func addBackupEntry(_ entry: BackupEntry) async {
        await storage.create(entry)
    }
    
    func getBackupEntries() async -> [BackupEntry] {
        await storage.getAll()
    }
    
    func removeBackupEntry(id: Int) async {
        await storage.delete(predicate: #Predicate<BackupEntryModel> { model in
            model.id == id
        })
    }
    
    func clearBackup() async {
        await storage.saveAll([])
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

