import Foundation


enum Direction {
    case income
    case outcome
}


struct Category {
    let id: Int
    let name: String
    let emoji: Character
    let isIncome: Direction
    init (dict: [String: Any]) {
        id = dict["id"] as? Int ?? 0
        name = dict["name"] as? String ?? ""
        emoji = (dict["emoji"] as? String ?? "❓").first!
        let isIncomeBool = dict["isIncome"] as? Bool ?? false
        isIncome = isIncomeBool ? .income : .outcome
    }
}


struct BankAccount {
    let id: Int
    let userId: Int
    let name: String
    var balance: Decimal
    var currency: String
    let createdAt: Date
    var updatedAt: Date
    init (dict: [String: Any]) {
        id = dict["id"] as? Int ?? 0
        userId = dict["userId"] as? Int ?? 0
        name = dict["name"] as? String ?? ""
        balance = Decimal(string: dict["balance"] as? String ?? "0") ?? 0
        currency = dict["currency"] as? String ?? ""
        let createdStr = dict["createdAt"] as? String ?? ""
        var updatedStr = dict["updatedAt"] as? String ?? ""
        let formatter  = ISO8601DateFormatter()
        createdAt = formatter.date(from: createdStr) ?? Date(timeIntervalSince1970: 0)
        updatedAt = formatter.date(from: updatedStr) ?? Date(timeIntervalSince1970: 0)
    }
}


struct Transaction {
    var id: Int
    let account: BankAccount
    let category: Category
    var amount: Decimal
    let transactionDate: Date
    var comment: String
    let createdAt: Date
    var updatedAt: Date
    
}


extension Transaction {
    static func parse(jsonObject: Any) -> Transaction? {
        let formatter  = ISO8601DateFormatter()
        let dict = jsonObject as? [String: Any] ?? [:]
        var id = dict["id"] as? Int ?? 0
        let accountDict = dict["account"] as? [String: Any] ?? [:]
        let categoryDict = dict["category"] as? [String: Any] ?? [:]
        var jAmount = dict["amount"] as? String ?? ""
        var amount = Decimal(string: jAmount) ?? 0
        let transactionDateString = dict["transactionDate"] as? String ?? ""
        var comment = dict["comment"] as? String ?? ""
        let createdStr = dict["createdAt"] as? String ?? ""
        var updatedStr = dict["updatedAt"] as? String ?? ""
        let createdAt = formatter.date(from: createdStr) ?? Date(timeIntervalSince1970: 0)
        var updatedAt = formatter.date(from: updatedStr) ?? Date(timeIntervalSince1970: 0)
        let transactionDate = formatter.date(from: transactionDateString) ?? Date(timeIntervalSince1970: 0)
        let account = BankAccount(dict: accountDict)
        let category = Category(dict: categoryDict)
        
        return Transaction(id: id, account: account, category: category, amount: amount, transactionDate: transactionDate, comment: comment, createdAt: createdAt, updatedAt: updatedAt)
    }
    var jsonObject: Any {
        let formatter  = ISO8601DateFormatter()
        return [
          "id": id,
          "account": account.jsonObject,
          "category": category.jsonObject,
          "amount": amount.description,
          "transactionDate": formatter.string(from: transactionDate),
          "comment": comment,
          "createdAt": formatter.string(from: createdAt),
          "updatedAt": formatter.string(from: updatedAt)
        ]
      }
}

extension Category {
  var jsonObject: Any {
    return [
      "id": id,
      "name": name,
      "emoji": String(emoji),
      "isIncome": (isIncome == .income)
    ]
  }
}

extension BankAccount {
  var jsonObject: Any {
    let formatter = ISO8601DateFormatter()
    return [
      "id": id,
      "userId": userId,
      "name": name,
      "balance": balance.description,
      "currency": currency,
      "createdAt": formatter.string(from: createdAt),
      "updatedAt": formatter.string(from: updatedAt)
    ]
  }
}

extension Transaction: Hashable {
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class TransactionsFileCache {
    private var transactionsSet: Set<Transaction> = []
    private let fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        loadFromFile()
    }
    
    private func loadFromFile() {
            do {
                let data = try Data(contentsOf: fileURL)
                let obj  = try JSONSerialization.jsonObject(with: data, options: [])
                guard let arr = obj as? [Any] else { return }
                let parsed = arr.compactMap { Transaction.parse(jsonObject: $0) }
                transactionsSet = Set(parsed)
            } catch {
                transactionsSet = []
            }
        }

    private func saveToFile() {
            let foundationArray = transactionsSet.map { $0.jsonObject }
            do {
                let data = try JSONSerialization.data(
                    withJSONObject: foundationArray,
                    options: [.prettyPrinted]
                )
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                print("Не удалось сохранить транзакции в файл: \(error)")
            }
        }
    
    var transactions: [Transaction] {
        Array(transactionsSet)
    }
    
    func add(_ transaction: Transaction) {
        transactionsSet.insert(transaction)
        saveToFile()
    }
    
    func remove(id: Int) {
      if let old = transactionsSet.first(where: { $0.id == id }) {
        transactionsSet.remove(old)
        saveToFile()
      }
    }
}

protocol CategoriesService {
  func fetchAll() async -> [Category]
  func fetch(by isIncome: Direction) async -> [Category]
}

protocol BankAccountsService {
  func fetchPrimaryAccount() async -> BankAccount?
  func updateBalance(_ account: BankAccount, to newBalance: Decimal) async
}

protocol TransactionsService {
  func fetch(from: Date, to: Date) async -> [Transaction]
  func create(_ transaction: Transaction) async
  func update(_ transaction: Transaction) async
  func delete(id: Int) async
}

final class MockCategoriesService: CategoriesService {
    private let all: [Category]
    
    init(all: [Category]) {
        self.all = all
    }
    
    func fetchAll() async -> [Category] {
        return all
    }
    
    func fetch(by isIncome: Direction) async -> [Category] {
        return all.filter { $0.isIncome == isIncome }
    }
}

final class MockBankAccountService: BankAccountsService {
    private var account: BankAccount?
    
    init(account: BankAccount?) {
        self.account = account
    }
    
    func fetchPrimaryAccount() async -> BankAccount? {
        return account
    }
    
    func updateBalance(_ account: BankAccount, to newBalance: Decimal) async {
        self.account?.balance = newBalance
    }
}

final class MockTransactionsService: TransactionsService {
    private var cache: TransactionsFileCache
    
    init (cache: TransactionsFileCache) {
        self.cache = cache
    }
    
    func fetch(from: Date, to: Date) async -> [Transaction] {
        return cache.transactions.filter {$0.transactionDate >= from && $0.transactionDate <= to }
    }
    
    func create(_ transaction: Transaction) async {
        cache.add(transaction)
    }
    
    func update(_ transaction: Transaction) async {
        cache.remove(id: transaction.id)
        cache.add(transaction)
    }
    
    func delete(id: Int) async {
        cache.remove(id: id)
    }
}

//* (csv-parser)
extension Transaction {
    init?(csvFields fields: [String], dateFormatter: ISO8601DateFormatter = .init()) {
        guard fields.count == 8,
            let id = Int(fields[0]),
            let accountId = Int(fields[1]),
            let categoryId = Int(fields[2]),
            let amount = Decimal(string: fields[3]),
            let transactionDate = dateFormatter.date(from: fields[4]),
            let createdAt = dateFormatter.date(from: fields[6]),
            let updatedAt = dateFormatter.date(from: fields[7])
        else
        {
            return nil
        }
        self.id = id
        self.account = BankAccount(dict: [:])
        self.category = Category(dict: [:])
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = fields[5]
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func parseCSV(_ csv: String) -> [Transaction] {
            let lines = csv
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
            guard lines.count > 1 else { return [] }
            let dataLines = lines.dropFirst()
            let formatter = ISO8601DateFormatter()
            return dataLines.compactMap { line in
                let fields = line.components(separatedBy: ",")
                return Transaction(csvFields: fields, dateFormatter: formatter)
            }
        }
}
