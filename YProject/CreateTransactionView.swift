//
//  CreateTransactionView.swift
//  YProject
//
//  Created by Митя on 03.07.2025.
//

import SwiftUI
import Combine

struct AmountAndDateFilteringModifier: ViewModifier {
    @Binding var text: String
    @Binding var date: Date
    
    private var separator: String {
        Locale.current.decimalSeparator ?? "."
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(Just(text)) { newValue in
                let filtered = newValue.filter { char in
                    char.isNumber || String(char) == separator
                }
                let parts = filtered.split(separator: Character(separator))
                let rebuilt: String
                if parts.count <= 1 {
                    rebuilt = filtered
                } else {
                    rebuilt = parts[0] + separator + parts[1]
                }
                if rebuilt != newValue {
                    self.text = rebuilt
                }
            }
            .onAppear {
                if date > Date() { date = Date() }
            }
            .datePickerStyle(.compact)
            .environment(\.locale, Locale.current)
    }
}



struct CreateTransactionView: View {
    let direction: Direction
    let onSave: (Transaction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var amountText = ""
    @State private var comment    = ""
    @State private var date       = Date()
    @State private var selectedCategory: Category? = nil
    @State private var showValidationAlert = false
    
    
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
                        .modifier(AmountAndDateFilteringModifier(
                            text: $amountText,
                            date: $date
                        ))
                }
                
                categorySection
                
                Section("Комментарий") {
                    TextField("Комментарий", text: $comment)
                }
                
                Section("Дата") {
                    DatePicker(
                        "",
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                }
            }
            .navigationTitle("Новый \(direction == .income ? "доход" : "расход")")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let fmt = NumberFormatter()
                        fmt.locale      = Locale.current
                        fmt.numberStyle = .decimal
                        
                        guard
                            let cat    = selectedCategory,
                            let num    = fmt.number(from: amountText)
                        else {
                            showValidationAlert = true
                            return
                        }
                        let amt = num.decimalValue // третья звездочка
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
            .alert("Пожалуйста, заполните все поля", isPresented: $showValidationAlert) { // 4-ая звездочка
                Button("ОК", role: .cancel) { }
            }
        }
    }
}
