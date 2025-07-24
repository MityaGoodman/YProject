//
//  TransactionsListView.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//

import SwiftUI

struct TransactionsListView: View {
    let direction: Direction
    @StateObject private var vm: TransactionsListViewModel
    @State private var isPresentingNew = false
    @State private var editingTx: Transaction? = nil
    
    init(
        direction: Direction,
        service: TransactionsService,
        balanceManager: BalanceManager,
        categoriesService: CategoriesService,
        bankAccountsService: BankAccountsService
    ) {
        self.direction = direction
        _vm = StateObject(wrappedValue: TransactionsListViewModel(
            service: service,
            balanceManager: balanceManager,
            categoriesService: categoriesService
        ))
        self.bankAccountsService = bankAccountsService
    }
    
    private let bankAccountsService: BankAccountsService
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                HStack {
                    Text("Всего")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(
                        vm.total as NSNumber,
                        formatter: currencyFormatter(code: vm.currencyCode)
                    )
                    .font(.headline)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
                .padding(.top)
                
                if vm.isLoading {
                    Spacer()
                    ProgressView("Загрузка...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else {
                    if let noData = vm.noDataMessage {
                        Spacer()
                        Text(noData)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    } else {
                        List(vm.transactions, id: \.id) { tx in
                            TransactionRow(transaction: tx)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingTx = tx
                                }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            
            Button {
                isPresentingNew = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle(direction == .income
                         ? "Доходы сегодня"
                         : "Расходы сегодня")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    HistoryView(direction: direction, service: vm.service)
                } label: {
                    Image(systemName: "clock")
                }
            }
        }
        .task {
            await vm.loadToday(direction: direction)
        }
        .alert("Ошибка", isPresented: Binding<Bool>(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") {
                vm.errorMessage = nil
            }
        } message: {
            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
            }
        }

        .sheet(isPresented: Binding<Bool>(
            get: { isPresentingNew || editingTx != nil },
            set: { newValue in
                if !newValue {
                    isPresentingNew = false
                    editingTx = nil
                }
            }
        )) {
            if isPresentingNew {
                CreateTransactionView(
                    direction: direction,
                    service: vm.categoriesService,
                    balanceManager: vm.balanceManager,
                    bankAccountsService: bankAccountsService
                ) { newTx in
                    Task {
                        await vm.create(newTx, direction: direction)
                        isPresentingNew = false
                    }
                }
            } else if let tx = editingTx {
                EditTransactionView(
                    transaction: tx,
                    direction: direction,
                    onSave: { updatedTx in
                        Task {
                            await vm.update(updatedTx, direction: direction)
                            editingTx = nil
                        }
                    },
                    onDelete: { toDelete in
                        Task {
                            await vm.delete(toDelete.id, direction: direction)
                            editingTx = nil
                        }
                    }
                )
            }
        }
    }
    
    private func currencyFormatter(code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        return f
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Text(String(transaction.category.emoji))
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category.name)
                    .font(.body)
                if !transaction.comment.isEmpty {
                    Text(transaction.comment)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(
                    transaction.amount as NSNumber,
                    formatter: currencyFormatter(code: transaction.account.currency)
                )
                .font(.body)
                Text(
                    DateFormatter.timeFormatter.string(from: transaction.transactionDate)
                )
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func currencyFormatter(code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        return f
    }
}

private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df
    }()
}
