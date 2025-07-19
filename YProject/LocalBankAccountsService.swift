//
//  LocalBankAccountsService.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation

final class LocalBankAccountsService: BankAccountsService {
    private let apiService: BankAccountsService
    private let localStorage: BankAccountsStorage
    private let syncManager: SyncManager
    
    init(
        apiService: BankAccountsService,
        localStorage: BankAccountsStorage,
        syncManager: SyncManager
    ) {
        self.apiService = apiService
        self.localStorage = localStorage
        self.syncManager = syncManager
    }
    
    func fetchPrimaryAccount() async -> BankAccount? {
        do {
            await syncManager.syncBackupBeforeOperation()
            let serverAccount = await apiService.fetchPrimaryAccount()
            if let account = serverAccount {
                await localStorage.saveBankAccount(account)
            }
            return serverAccount
        } catch {
            // При ошибке возвращаем данные из локального хранилища
            return await localStorage.getBankAccount()
        }
    }
    
    func updateBalance(_ account: BankAccount, to newBalance: Decimal) async {
        var updatedAccount = account
        updatedAccount.balance = newBalance
        await updateAccount(updatedAccount, balance: newBalance, currency: updatedAccount.currency)
    }
    
    func updateAccount(_ account: BankAccount, balance: Decimal, currency: String) async {
        var updatedAccount = account
        updatedAccount.balance = balance
        updatedAccount.currency = currency
        await syncManager.syncBackupBeforeOperation()
        await apiService.updateAccount(updatedAccount, balance: balance, currency: currency)
        await syncManager.handleSuccessfulBankAccountOperation(
            updatedAccount,
            action: .update,
            localStorage: localStorage
        )
    }
}

