//
//  EditTransactionView.swift
//  YProject
//
//  Created by Митя on 12.07.2025.
//

import SwiftUI
import Combine

struct EditTransactionView: View {
    let direction: Direction
    let onSave: (Transaction) -> Void
    let onDelete: (Transaction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var amountText: String
    @State private var comment:    String
    @State private var date:       Date
    @State private var selectedCategory: Category
    @State private var showValidationAlert = false
    
    @State private var categories: [Category] = []
    private let categoriesService: CategoriesService
    private let originalTransaction: Transaction
    
    init(
        transaction: Transaction,
        direction: Direction,
        service: CategoriesService = MockCategoriesService(all: allCategories),
        onSave: @escaping (Transaction) -> Void,
        onDelete: @escaping (Transaction) -> Void
    ) {
        self.direction = direction
        self.categoriesService = service
        self.onSave = onSave
        self.onDelete = onDelete
        self.originalTransaction = transaction
        
        _amountText = State(initialValue: transaction.amount.description)
        _comment    = State(initialValue: transaction.comment)
        _date       = State(initialValue: transaction.transactionDate)
        _selectedCategory = State(initialValue: transaction.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Сумма") {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .modifier(AmountAndDateFilteringModifier(
                            text: $amountText,
                            date: $date
                        ))
                }
                Section("Категория") {
                    Picker("Категория", selection: $selectedCategory) {
                        ForEach(categories, id: \.id) { cat in
                            Label(cat.name, systemImage: String(cat.emoji))
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Комментарий") {
                    TextField("Комментарий", text: $comment)
                }
                Section("Дата и время") {
                    DatePicker(
                        "",
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }
            }
            .navigationTitle("Редактировать")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Удалить", role: .destructive) {
                        onDelete(originalTransaction)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { // тоже 3 звезда
                    let fmt: NumberFormatter = {
                        let f = NumberFormatter()
                        f.locale      = Locale.current
                        f.numberStyle = .decimal
                        return f
                    }()
                    
                    Button("Сохранить") {
                        guard let num = fmt.number(from: amountText) else {
                            showValidationAlert = true
                            return }
                        let newAmount = num.decimalValue
                        var tx = originalTransaction
                        tx.amount = newAmount
                        tx.comment = comment
                        tx.transactionDate = date
                        tx.category = selectedCategory
                        tx.updatedAt = Date()
                        onSave(tx)
                        dismiss()
                    }
                    .disabled(fmt.number(from: amountText) == nil)
                }
            }
            .task {
                let all = await categoriesService.fetch(by: direction)
                categories = all
            }
            .alert("Пожалуйста, заполните все поля", isPresented: $showValidationAlert) { // тоже 4 звезда
                Button("ОК", role: .cancel) { }
            }
        }
    }
}
