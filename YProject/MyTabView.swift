//
//  MyTabView.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI

struct MyTabView: View {
    private let localTransactionsService: LocalTransactionsService
    private let localBankAccountsService: LocalBankAccountsService
    private let localCategoriesService: LocalCategoriesService
    
    @StateObject private var balanceManager: BalanceManager
    @StateObject private var transactionsViewModel: TransactionsListViewModel
    @StateObject private var balanceViewModel: BalanceViewModel
    
    @State private var isOffline: Bool = false
    
    private static func createViewModels(
        transactionsService: LocalTransactionsService,
        bankAccountsService: BankAccountsService,
        categoriesService: LocalCategoriesService
    ) -> (BalanceManager, TransactionsListViewModel, BalanceViewModel) {
        let balanceManager = BalanceManager(bankAccountsService: bankAccountsService, transactionsService: transactionsService)
        let transactionsViewModel = TransactionsListViewModel(
            service: transactionsService,
            balanceManager: balanceManager,
            categoriesService: categoriesService
        )
        let balanceViewModel = BalanceViewModel(bankAccountsService: bankAccountsService, transactionsService: transactionsService)
        return (balanceManager, transactionsViewModel, balanceViewModel)
    }
    
    init() {
        let networkClient = NetworkClient(baseURL: Config.baseURL, token: Config.bearerToken)
        let config = Config()
        
        do {
            let services = try ServiceFactory.createLocalServices(networkClient: networkClient, config: config)
            self.localTransactionsService = services.transactionsService
            self.localBankAccountsService = services.bankAccountsService
            self.localCategoriesService = services.categoriesService
            
            let (balanceManager, transactionsViewModel, balanceViewModel) = Self.createViewModels(
                transactionsService: services.transactionsService,
                bankAccountsService: services.bankAccountsService,
                categoriesService: services.categoriesService
            )
            _balanceManager = StateObject(wrappedValue: balanceManager)
            _transactionsViewModel = StateObject(wrappedValue: transactionsViewModel)
            _balanceViewModel = StateObject(wrappedValue: balanceViewModel)
        } catch {
            print("Ошибка создания локальных сервисов: \(error), используем API сервисы")
            
            let apiTransactionsService = APITransactionsService(networkClient: networkClient)
            let apiBankAccountsService = APIBankAccountsService(networkClient: networkClient)
            let apiCategoriesService = APICategoriesService(networkClient: networkClient)
            
            let mockTransactionsStorage = MockTransactionsStorage()
            let mockBankAccountsStorage = MockBankAccountsStorage()
            let mockCategoriesStorage = MockCategoriesStorage()
            let mockBackupStorage = MockBackupStorage()
            let mockBackupManager = BackupManager(backupStorage: mockBackupStorage)
            let mockSyncManager = MockSyncManager()
            
            self.localTransactionsService = LocalTransactionsService(
                apiService: apiTransactionsService,
                localStorage: mockTransactionsStorage,
                syncManager: mockSyncManager
            )
            self.localBankAccountsService = LocalBankAccountsService(
                apiService: apiBankAccountsService,
                localStorage: mockBankAccountsStorage,
                syncManager: mockSyncManager
            )
            self.localCategoriesService = LocalCategoriesService(
                apiService: apiCategoriesService,
                localStorage: mockCategoriesStorage
            )
            
            let (balanceManager, transactionsViewModel, balanceViewModel) = Self.createViewModels(
                transactionsService: localTransactionsService,
                bankAccountsService: apiBankAccountsService,
                categoriesService: localCategoriesService
            )
            _balanceManager = StateObject(wrappedValue: balanceManager)
            _transactionsViewModel = StateObject(wrappedValue: transactionsViewModel)
            _balanceViewModel = StateObject(wrappedValue: balanceViewModel)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView {
            NavigationStack {
                TransactionsListView(
                    direction: .outcome,
                    service: localTransactionsService,
                    balanceManager: balanceManager,
                    categoriesService: localCategoriesService,
                    bankAccountsService: localBankAccountsService
                )
                
            }
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Расходы")
                }
            NavigationStack {
                TransactionsListView(
                    direction: .income,
                    service: localTransactionsService,
                    balanceManager: balanceManager,
                    categoriesService: localCategoriesService,
                    bankAccountsService: localBankAccountsService
                )
            }
                .tabItem {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                    Text("Доходы")
                }
            NavigationStack {
                BalanceSheet(balanceViewModel: balanceViewModel)
            }
                .tabItem {
                    Image(systemName: "banknote.fill")
                    Text("Счет")
                }
            NavigationStack {
                ArticlesView(service: localTransactionsService, categoriesService: localCategoriesService)
            }
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Статьи")
                }
            Text("Настройки")
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки")
                }
            }
            .accentColor(Color("Color"))
            
            OfflineIndicatorView(isOffline: isOffline)
                .animation(.easeInOut(duration: 0.3), value: isOffline)
        }
        .onReceive(transactionsViewModel.$isOffline) { offline in
            isOffline = offline
        }
        .onReceive(balanceViewModel.$isOffline) { offline in
            isOffline = isOffline || offline
        }
    }
}

struct MyTabView_Previews: PreviewProvider {
    static var previews: some View {
        MyTabView()
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
