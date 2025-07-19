//
//  LocalTransactionsService.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation

final class LocalTransactionsService: TransactionsService {
    private let apiService: TransactionsService
    private let localStorage: TransactionsStorage
    private let syncManager: SyncManager
    
    init(
        apiService: TransactionsService,
        localStorage: TransactionsStorage,
        syncManager: SyncManager
    ) {
        self.apiService = apiService
        self.localStorage = localStorage
        self.syncManager = syncManager
    }
    
    func fetch(from: Date, to: Date) async throws -> [Transaction] {
        do {
            return try await syncManager.getTransactionsWithSync(
                from: from,
                to: to,
                localStorage: localStorage
            )
        } catch {
            // При ошибке возвращаем данные из локального хранилища, но выбрасываем ошибку
            let localTransactions = await localStorage.getTransactions(from: from, to: to)
            throw NetworkError.offlineMode(localData: localTransactions)
        }
    }
    
    func create(_ transaction: Transaction) async throws {
        await syncManager.syncBackupBeforeOperation()
        do {
            try await apiService.create(transaction)
            await syncManager.handleSuccessfulTransactionOperation(
                transaction,
                action: .create,
                localStorage: localStorage
            )
        } catch {
            // Сохраняем в backup для последующей синхронизации
            await syncManager.handleFailedTransactionOperation(transaction, action: .create)
            throw error
        }
    }
    
    func update(_ transaction: Transaction) async throws {
        await syncManager.syncBackupBeforeOperation()
        do {
            try await apiService.update(transaction)
            await syncManager.handleSuccessfulTransactionOperation(
                transaction,
                action: .update,
                localStorage: localStorage
            )
        } catch {
            // Сохраняем в backup для последующей синхронизации
            await syncManager.handleFailedTransactionOperation(transaction, action: .update)
            throw error
        }
    }
    
    func delete(id: Int) async throws {
        await syncManager.syncBackupBeforeOperation()
        let localTransactions = await localStorage.getAllTransactions()
        guard let transaction = localTransactions.first(where: { $0.id == id }) else { return }
        do {
            try await apiService.delete(id: id)
            await syncManager.handleSuccessfulTransactionOperation(
                transaction,
                action: .delete,
                localStorage: localStorage
            )
        } catch {
            // Сохраняем в backup для последующей синхронизации
            await syncManager.handleFailedTransactionOperation(transaction, action: .delete)
            throw error
        }
    }
}

