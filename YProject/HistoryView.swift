//
//  HistoryView.swift
//  YProject
//
//  Created by Митя on 21.06.2025.
//




import SwiftUI

struct HistoryView: View {
    let direction: Direction
    @StateObject private var vm: HistoryViewModel
    @State private var showAnalysis = false
    
    init(
        direction: Direction,
        service: TransactionsService
    ) {
        self.direction = direction
        _vm = StateObject(
            wrappedValue: HistoryViewModel(
                direction: direction,
                service: service
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                HStack {
                    Text("Начало")
                    Spacer()
                    DatePicker(
                        "",
                        selection: $vm.start,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }
                HStack {
                    Text("Конец")
                    Spacer()
                    DatePicker(
                        "",
                        selection: $vm.end,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }
            }
            .padding(.horizontal)
            
            HStack {
                Text("Сумма")
                Spacer()
                Text(
                    vm.total as NSNumber,
                    formatter: currencyFormatter(code: vm.currencyCode)
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)
            
            if vm.isLoading {
                Spacer()
                ProgressView("Загрузка истории...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else {
                List(vm.transactions, id: \.id) { tx in
                    TransactionRow(transaction: tx)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Моя история")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AnalysisViewControllerWrapper(
                        start: vm.start,
                        end: vm.end,
                        transactions: vm.transactions
                    )
                } label: {
                    Image(systemName: "doc.plaintext")
                }
            }
        }
        .onChange(of: vm.start) { _ in Task { await vm.refresh() } }
        .onChange(of: vm.end)   { _ in Task { await vm.refresh() } }
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

    }
    
    private func currencyFormatter(code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        return f
    }
}
