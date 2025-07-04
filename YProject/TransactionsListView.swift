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
    
    init(
        direction: Direction,
        service: TransactionsService = MockTransactionsService(
            cache: TransactionsFileCache(
                fileURL: FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)
                    .first!
                    .appendingPathComponent("transactions.json")
            )
        )
    ) {
        self.direction = direction
        _vm = StateObject(wrappedValue: TransactionsListViewModel(service: service))
    }
    
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
                
                List(vm.transactions, id: \.id) { tx in
                    TransactionRow(transaction: tx)
                }
                .listStyle(.plain)
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
                    HistoryView(direction: direction)
                } label: {
                    Image(systemName: "clock")
                }
            }
        }
        .task {
            await vm.loadToday(direction: direction)
        }
        .sheet(isPresented: $isPresentingNew) {
            CreateTransactionView(direction: direction) { newTx in
                Task {
                    await vm.create(newTx)
                    await vm.loadToday(direction: direction)
                }
                isPresentingNew = false
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
