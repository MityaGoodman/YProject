import Foundation

// MARK: - Storage Protocols

protocol TransactionsStorage {
    func getAllTransactions() async -> [Transaction]
    func getTransactions(from: Date, to: Date) async -> [Transaction]
    func updateTransaction(_ transaction: Transaction) async
    func deleteTransaction(id: Int) async
    func createTransaction(_ transaction: Transaction) async
    func saveTransactions(_ transactions: [Transaction]) async
}

protocol BankAccountsStorage {
    func getBankAccount() async -> BankAccount?
    func updateBankAccount(_ account: BankAccount) async
    func saveBankAccount(_ account: BankAccount) async
}

protocol CategoriesStorage {
    func getAllCategories() async -> [Category]
    func saveCategories(_ categories: [Category]) async
}

// MARK: - Backup Storage Protocol

enum BackupAction {
    case create
    case update
    case delete
}

struct BackupEntry {
    let id: Int
    let action: BackupAction
    let data: Any
    let timestamp: Date
}

protocol BackupStorage {
    func addBackupEntry(_ entry: BackupEntry) async
    func getBackupEntries() async -> [BackupEntry]
    func removeBackupEntry(id: Int) async
    func clearBackup() async
}

