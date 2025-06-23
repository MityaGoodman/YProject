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
            
            List(vm.transactions, id: \.id) { tx in
                TransactionRow(transaction: tx)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Моя история")
        .onChange(of: vm.start) { _ in Task { await vm.refresh() } }
        .onChange(of: vm.end)   { _ in Task { await vm.refresh() } }
    }
    
    private func currencyFormatter(code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        return f
    }
}
