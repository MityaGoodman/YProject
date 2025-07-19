//
//  APIServices.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation

// MARK: - API Models

// MARK: Category API Models
struct APICategory: Codable {
    let id: Int
    let name: String
    let emoji: String
    let isIncome: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, emoji, isIncome
    }
    
    func toDomain() -> Category {
        return Category(
            id: id,
            name: name,
            emoji: emoji.first ?? "❓",
            isIncome: isIncome ? .income : .outcome
        )
    }
}

struct APICategoryRequest: Codable {
    let name: String
    let emoji: String
    let isIncome: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, emoji
        case isIncome = "is_income"
    }
}

// MARK: Bank Account API Models
struct APIBankAccount: Codable {
    let id: Int
    let name: String
    let balance: String
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, balance, currency
    }
    
    func toDomain() -> BankAccount {
        return BankAccount(
            id: id,
            userId: 0,
            name: name,
            balance: Decimal(string: balance) ?? 0,
            currency: currency,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

struct APIBankAccountRequest: Codable {
    let name: String
    let balance: String
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case name, balance, currency
    }
}

// MARK: Transaction API Models
struct APITransaction: Codable {
    let id: Int
    let account: APIBankAccount
    let category: APICategory
    let amount: String
    let transactionDate: String
    let comment: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, account, category, amount, comment, transactionDate, createdAt, updatedAt
    }
    
    func toDomain() -> Transaction {
        let formatter = ISO8601DateFormatter()
        return Transaction(
            id: id,
            account: account.toDomain(),
            category: category.toDomain(),
            amount: Decimal(string: amount) ?? 0,
            transactionDate: formatter.date(from: transactionDate) ?? Date(),
            comment: comment,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date()
        )
    }
}

struct APITransactionRequest: Codable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: String
    let comment: String
    
    enum CodingKeys: String, CodingKey {
        case amount, comment, accountId, categoryId, transactionDate
    }
    
    init(accountId: Int, categoryId: Int, amount: String, transactionDate: String, comment: String) {
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        print("🔧 APITransactionRequest создан: accountId=\(accountId), categoryId=\(categoryId), amount=\(amount), date=\(transactionDate), comment=\(comment)")
    }
}

struct APITransactionRequestV2: Codable {
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: String
    let comment: String
    
    enum CodingKeys: String, CodingKey {
        case amount, comment
        case accountId = "account_id"
        case categoryId = "category_id"
        case transactionDate = "transaction_date"
    }
}

struct APITransactionCreateResponse: Codable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: String
    let comment: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, amount, comment, transactionDate, createdAt, updatedAt
        case accountId = "accountId"
        case categoryId = "categoryId"
    }
}

struct EmptyRequestBody: Codable {
    init() {}
}

// MARK: API Services

// MARK: Categories Service
class APICategoriesService: CategoriesService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func fetchAll() async -> [Category] {
        do {
            print("🌐 Отправляем запрос к /api/v1/categories")
            print("🔗 Полный URL: \(Config.baseURL)/api/v1/categories")
            let apiCategories: [APICategory] = try await networkClient.request(
                endpoint: "/api/v1/categories",
                method: .GET,
                responseType: [APICategory].self
            )
            print("✅ Получено API категорий: \(apiCategories.count)")
            print("📋 Первая категория: \(apiCategories.first?.name ?? "нет")")
            let categories = apiCategories.map { $0.toDomain() }
            print("🔄 Преобразовано в доменные категории: \(categories.count)")
            return categories
        } catch {
            print("❌ Error fetching categories: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetch(by isIncome: Direction) async -> [Category] {
        do {
            print("🔄 Загружаем категории для направления: \(isIncome == .income ? "income" : "outcome")")
            let isIncomeString = isIncome == .income ? "true" : "false"
            let apiCategories: [APICategory] = try await networkClient.request(
                endpoint: "/api/v1/categories/type/\(isIncomeString)",
                method: .GET,
                responseType: [APICategory].self
            )
            print("✅ Получено категорий для \(isIncomeString): \(apiCategories.count)")
            return apiCategories.map { $0.toDomain() }
        } catch {
            print("❌ Error fetching categories by type: \(error)")
            let all = await fetchAll()
            return all.filter { $0.isIncome == isIncome }
        }
    }
}

// MARK: Bank Accounts Service
class APIBankAccountsService: BankAccountsService {
    private let networkClient: NetworkClient
    private var primaryAccount: BankAccount?
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func fetchPrimaryAccount() async -> BankAccount? {
        do {
            let apiBankAccounts: [APIBankAccount] = try await networkClient.request(
                endpoint: "/api/v1/accounts",
                method: .GET,
                responseType: [APIBankAccount].self
            )
            let accounts = apiBankAccounts.map { $0.toDomain() }
            primaryAccount = accounts.first
            return primaryAccount
        } catch {
            print("Error fetching bank accounts: \(error)")
            return primaryAccount
        }
    }
    
    func updateBalance(_ account: BankAccount, to newBalance: Decimal) async {
        do {
            print("💰 Обновляем баланс счета \(account.id) на \(newBalance)")
            let request = APIBankAccountRequest(
                name: account.name,
                balance: newBalance.description,
                currency: account.currency
            )
            
            let _: APIBankAccount = try await networkClient.request(
                endpoint: "/api/v1/accounts/\(account.id)",
                method: .PUT,
                body: request,
                responseType: APIBankAccount.self
            )
            
            print("✅ Баланс обновлен успешно")
            primaryAccount?.balance = newBalance
        } catch {
            print("❌ Error updating balance: \(error)")
            print("❌ Попробуем PATCH метод...")
            
            do {
                let request = APIBankAccountRequest(
                    name: account.name,
                    balance: newBalance.description,
                    currency: account.currency
                )
                
                let _: APIBankAccount = try await networkClient.request(
                    endpoint: "/api/v1/accounts/\(account.id)",
                    method: .PATCH,
                    body: request,
                    responseType: APIBankAccount.self
                )
                
                print("✅ Баланс обновлен через PATCH")
                primaryAccount?.balance = newBalance
            } catch {
                print("❌ PATCH тоже не работает: \(error)")
            }
        }
    }
    
    func updateAccount(_ account: BankAccount, balance: Decimal, currency: String) async {
        do {
            print("💰 Обновляем счет \(account.id): баланс=\(balance), валюта=\(currency)")
            let request = APIBankAccountRequest(
                name: account.name,
                balance: balance.description,
                currency: currency
            )
            
            let _: APIBankAccount = try await networkClient.request(
                endpoint: "/api/v1/accounts/\(account.id)",
                method: .PUT,
                body: request,
                responseType: APIBankAccount.self
            )
            
            print("✅ Счет обновлен успешно")
            primaryAccount?.balance = balance
            primaryAccount?.currency = currency
        } catch {
            print("❌ Error updating account: \(error)")
        }
    }
}

// MARK: Transactions Service
class APITransactionsService: TransactionsService {
    private let networkClient: NetworkClient
    private var cachedTransactions: [Transaction] = []
    private var primaryAccount: BankAccount?
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    private func fetchPrimaryAccount() async -> BankAccount? {
        if let account = primaryAccount {
            return account
        }
        
        do {
            let apiBankAccounts: [APIBankAccount] = try await networkClient.request(
                endpoint: "/api/v1/accounts",
                method: .GET,
                responseType: [APIBankAccount].self
            )
            let accounts = apiBankAccounts.map { $0.toDomain() }
            primaryAccount = accounts.first
            return primaryAccount
        } catch {
            print("Error fetching bank accounts: \(error)")
            return primaryAccount
        }
    }
    
    func fetch(from: Date, to: Date) async throws -> [Transaction] {
        print("🌐 Загружаем транзакции...")
        
        let primaryAccount = await fetchPrimaryAccount()
        guard let account = primaryAccount else {
            print("❌ Нет основного счета")
            throw NetworkError.networkError(NSError(domain: "APITransactionsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет основного счета"]))
        }
        
        let formatter = ISO8601DateFormatter()
        let fromString = formatter.string(from: from)
        let toString = formatter.string(from: to)
        
        print("📅 Период: \(fromString) - \(toString)")
        print("🏦 Счет: \(account.id)")
        
        let apiTransactions: [APITransaction] = try await networkClient.request(
            endpoint: "/api/v1/transactions/account/\(account.id)/period?from=\(fromString)&to=\(toString)",
            method: .GET,
            responseType: [APITransaction].self
        )
        print("✅ Получено транзакций: \(apiTransactions.count)")
        cachedTransactions = apiTransactions.map { $0.toDomain() }
        return cachedTransactions
    }
    
    func create(_ transaction: Transaction) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let request = APITransactionRequest(
            accountId: transaction.account.id,
            categoryId: transaction.category.id,
            amount: transaction.amount.description,
            transactionDate: formatter.string(from: transaction.transactionDate),
            comment: transaction.comment
        )
        
        print("🌐 Создаем транзакцию...")
        print("📋 Данные запроса: accountId=\(request.accountId), categoryId=\(request.categoryId), amount=\(request.amount), date=\(request.transactionDate), comment=\(request.comment)")
        
        do {
            let _: APITransactionCreateResponse = try await networkClient.request(
                endpoint: "/api/v1/transactions",
                method: .POST,
                body: request,
                responseType: APITransactionCreateResponse.self
            )
            
            print("✅ Транзакция создана успешно")
            cachedTransactions.append(transaction)
        } catch {
            print("❌ Error creating transaction: \(error)")
            print("❌ Детали ошибки: \(error.localizedDescription)")
            
            print("🔄 Пробуем альтернативную структуру...")
            let requestV2 = APITransactionRequestV2(
                accountId: transaction.account.id,
                categoryId: transaction.category.id,
                amount: transaction.amount,
                transactionDate: formatter.string(from: transaction.transactionDate),
                comment: transaction.comment
            )
            
            let _: APITransactionCreateResponse = try await networkClient.request(
                endpoint: "/api/v1/transactions",
                method: .POST,
                body: requestV2,
                responseType: APITransactionCreateResponse.self
            )
            
            print("✅ Транзакция создана с альтернативной структурой")
            cachedTransactions.append(transaction)
        }
    }
    
    func update(_ transaction: Transaction) async throws {
        let formatter = ISO8601DateFormatter()
        let request = APITransactionRequest(
            accountId: transaction.account.id,
            categoryId: transaction.category.id,
            amount: transaction.amount.description,
            transactionDate: formatter.string(from: transaction.transactionDate),
            comment: transaction.comment
        )
        
        let _: APITransaction = try await networkClient.request(
            endpoint: "/api/v1/transactions/\(transaction.id)",
            method: .PUT,
            body: request,
            responseType: APITransaction.self
        )
        
        if let index = cachedTransactions.firstIndex(where: { $0.id == transaction.id }) {
            cachedTransactions[index] = transaction
        }
    }
    
    func delete(id: Int) async throws {
        let _: EmptyResponse = try await networkClient.request(
            endpoint: "/api/v1/transactions/\(id)",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
        
        cachedTransactions.removeAll { $0.id == id }
    }
}


