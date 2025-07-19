import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class TransactionModel {
    var id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String
    var createdAt: Date
    var updatedAt: Date
    
    init(transaction: Transaction) {
        self.id = transaction.id
        self.accountId = transaction.account.id
        self.categoryId = transaction.category.id
        self.amount = transaction.amount
        self.transactionDate = transaction.transactionDate
        self.comment = transaction.comment
        self.createdAt = transaction.createdAt
        self.updatedAt = transaction.updatedAt
    }
    
    func toTransaction(account: BankAccount, category: Category) -> Transaction {
        return Transaction(
            id: id,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class BankAccountModel {
    var id: Int
    var userId: Int
    var name: String
    var balance: Decimal
    var currency: String
    var createdAt: Date
    var updatedAt: Date
    
    init(account: BankAccount) {
        self.id = account.id
        self.userId = account.userId
        self.name = account.name
        self.balance = account.balance
        self.currency = account.currency
        self.createdAt = account.createdAt
        self.updatedAt = account.updatedAt
    }
    
    func toBankAccount() -> BankAccount {
        return BankAccount(
            id: id,
            userId: userId,
            name: name,
            balance: balance,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class CategoryModel {
    var id: Int
    var name: String
    var emoji: String
    var isIncome: Bool
    
    init(category: Category) {
        self.id = category.id
        self.name = category.name
        self.emoji = String(category.emoji)
        self.isIncome = category.isIncome == .income
    }
    
    func toCategory() -> Category {
        return Category(
            id: id,
            name: name,
            emoji: Character(emoji),
            isIncome: isIncome ? .income : .outcome
        )
    }
}

@Model
final class BackupEntryModel {
    var id: Int
    var action: String
    var dataType: String
    var dataJson: String
    var timestamp: Date
    
    init(entry: BackupEntry) {
        self.id = entry.id
        self.action = BackupEntryModel.actionToString(entry.action)
        self.dataType = BackupEntryModel.getDataType(entry.data)
        self.dataJson = BackupEntryModel.serializeData(entry.data)
        self.timestamp = entry.timestamp
    }
    
    func toBackupEntry() -> BackupEntry? {
        guard let action = stringToAction(action),
              let data = deserializeData(dataJson, type: dataType) else {
            return nil
        }
        
        return BackupEntry(
            id: id,
            action: action,
            data: data,
            timestamp: timestamp
        )
    }
    
    private static func actionToString(_ action: BackupAction) -> String {
        switch action {
        case .create: return "create"
        case .update: return "update"
        case .delete: return "delete"
        }
    }
    
    private func stringToAction(_ string: String) -> BackupAction? {
        switch string {
        case "create": return .create
        case "update": return .update
        case "delete": return .delete
        default: return nil
        }
    }
    
    private static func getDataType(_ data: Any) -> String {
        if data is Transaction { return "transaction" }
        if data is BankAccount { return "bankAccount" }
        return "unknown"
    }
    
    private static func serializeData(_ data: Any) -> String {
        if let transaction = data as? Transaction {
            let json = transaction.jsonObject
            if let data = try? JSONSerialization.data(withJSONObject: json, options: []),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
        if let account = data as? BankAccount {
            let json = account.jsonObject
            if let data = try? JSONSerialization.data(withJSONObject: json, options: []),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
        return ""
    }
    
    private func deserializeData(_ json: String, type: String) -> Any? {
        return nil
    }
}

