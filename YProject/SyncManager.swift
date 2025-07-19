//
//  SyncManager.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation

// MARK: - Sync Manager

class SyncManager {
    let backupManager: BackupManager
    private let transactionsService: TransactionsService
    private let bankAccountsService: BankAccountsService
    
    init(
        backupManager: BackupManager,
        transactionsService: TransactionsService,
        bankAccountsService: BankAccountsService
    ) {
        self.backupManager = backupManager
        self.transactionsService = transactionsService
        self.bankAccountsService = bankAccountsService
    }
    
    func syncBackupBeforeOperation() async {
        let syncedIds = await backupManager.syncBackupWithBackend(
            transactionsService: transactionsService,
            bankAccountsService: bankAccountsService
        )
        if !syncedIds.isEmpty {
            print("Синхронизировано \(syncedIds.count) записей из бекапа")
        }
    }
    
    func handleSuccessfulTransactionOperation(
        _ transaction: Transaction,
        action: BackupAction,
        localStorage: TransactionsStorage
    ) async {
        switch action {
        case .create:
            await localStorage.createTransaction(transaction)
        case .update:
            await localStorage.updateTransaction(transaction)
        case .delete:
            await localStorage.deleteTransaction(id: transaction.id)
        }
        await backupManager.backupStorage.removeBackupEntry(id: transaction.id)
    }
    
    func handleFailedTransactionOperation(
        _ transaction: Transaction,
        action: BackupAction
    ) async {
        await backupManager.backupTransaction(transaction, action: action)
    }
    
    func handleSuccessfulBankAccountOperation(
        _ account: BankAccount,
        action: BackupAction,
        localStorage: BankAccountsStorage
    ) async {
        switch action {
        case .create, .update:
            await localStorage.updateBankAccount(account)
        case .delete:
            break
        }
        await backupManager.backupStorage.removeBackupEntry(id: account.id)
    }
    
    func handleFailedBankAccountOperation(
        _ account: BankAccount,
        action: BackupAction
    ) async {
        await backupManager.backupBankAccount(account, action: action)
    }
    
    func getTransactionsWithSync(
        from: Date,
        to: Date,
        localStorage: TransactionsStorage
    ) async throws -> [Transaction] {
        await syncBackupBeforeOperation()
        let serverTransactions = try await transactionsService.fetch(from: from, to: to)
        await localStorage.saveTransactions(serverTransactions)
        return serverTransactions
    }
}

