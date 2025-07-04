//
//  CreateTransactionView.swift
//  YProject
//
//  Created by Митя on 03.07.2025.
//

import SwiftUI

struct CreateTransactionView: View {
    let direction: Direction
    let onSave: (Transaction) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var comment    = ""
    @State private var date       = Date()
    @State private var selectedCategory: Category? = nil

    @State private var categories: [Category] = []
    private let categoriesService: CategoriesService

    private let dummyAccount = BankAccount(dict: [
        "id": 0, "userId": 0, "name": "Основной",
        "balance": "0", "currency": "₽",
        "createdAt": ISO8601DateFormatter().string(from: Date()),
        "updatedAt": ISO8601DateFormatter().string(from: Date())
    ])

    init(
        direction: Direction,
        service: CategoriesService = MockCategoriesService(all: allCategories),
        onSave: @escaping (Transaction) -> Void
    ) {
        self.direction = direction
        self.categoriesService = service
        self.onSave = onSave
    }
    
    private var categorySection: some View {
      Section("Категория") {
        Picker("Категория", selection: $selectedCategory) {
          ForEach(categories, id: \.id) { cat in
            HStack {
              Text(String(cat.emoji))
              Text(cat.name)
            }
            .tag(Optional(cat))
          }
        }
        .pickerStyle(.menu)
      }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Сумма") {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                }

                categorySection

                Section("Комментарий") {
                    TextField("Комментарий", text: $comment)
                }

                Section("Дата") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Новый \(direction == .income ? "доход" : "расход")")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        guard
                            let cat = selectedCategory,
                            let amt = Decimal(string: amountText)
                        else { return }
                        let tx = Transaction(
                            id: Int(Date().timeIntervalSince1970),
                            account: dummyAccount,
                            category: cat,
                            amount: amt,
                            transactionDate: date,
                            comment: comment,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        onSave(tx)
                        dismiss()
                    }
                    .disabled(selectedCategory == nil || Decimal(string: amountText) == nil)
                }
            }
            .task {
                let all = await categoriesService.fetch(by: direction)
                categories = all
                selectedCategory = all.first
            }
        }
    }
}
