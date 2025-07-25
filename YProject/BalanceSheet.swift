//
//  BalanceSheet.swift
//  YProject
//
//  Created by Митя on 26.06.2025.
//

import SwiftUI
import Charts


struct BalanceSheet: View {
    @StateObject private var vm: BalanceViewModel
    
    // Готовим данные для графика (30 последних дней)
    private var chartData: [BalanceChartData] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        var result: [BalanceChartData] = []
        // Вычисляем initialBalance как текущий баланс - сумма всех транзакций за период
        let periodTxs = vm.transactions.filter { $0.transactionDate >= startDate && $0.transactionDate <= now }
        let periodSum = periodTxs.reduce(Decimal(0)) { sum, tx in
            let sign: Decimal = (tx.category.isIncome == .income) ? 1 : -1
            return sum + tx.amount * sign
        }
        let currentBalance = Decimal(string: vm.balanceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        var runningBalance = currentBalance - periodSum
        for i in 0..<30 {
            let day = calendar.date(byAdding: .day, value: -29 + i, to: now)!
            let dayTxs = periodTxs.filter { calendar.isDate($0.transactionDate, inSameDayAs: day) }
            let daySum = dayTxs.reduce(Decimal(0)) { sum, tx in
                let sign: Decimal = (tx.category.isIncome == .income) ? 1 : -1
                return sum + tx.amount * sign
            }
            runningBalance += daySum
            print("[BalanceChart] day: \(day), daySum: \(daySum), runningBalance: \(runningBalance)")
            result.append(BalanceChartData(date: day, balance: runningBalance))
        }
        return result
    }

    // Готовим данные для графика по месяцам (все месяцы в диапазоне, даже если нет транзакций)
    private var monthlyChartData: [BalanceChartData] {
        let calendar = Calendar.current
        let txs = vm.transactions
        // Если транзакций нет — показываем только текущий месяц
        guard !txs.isEmpty else {
            let now = Date()
            let firstDay = firstDayOfMonth(for: now)
            return [BalanceChartData(date: firstDay, balance: 0)]
        }
        // Находим диапазон месяцев
        let minDate = txs.map { firstDayOfMonth(for: $0.transactionDate) }.min()!
        let maxDate = firstDayOfMonth(for: Date())
        // Генерируем массив месяцев от minDate до maxDate
        var months: [Date] = []
        var current = minDate
        while current <= maxDate {
            months.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }
        // Группируем транзакции по месяцу
        let grouped = Dictionary(grouping: txs) { firstDayOfMonth(for: $0.transactionDate) }
        // Считаем баланс на конец каждого месяца
        var result: [BalanceChartData] = []
        var runningBalance: Decimal = 0
        for month in months {
            let monthTxs = grouped[month] ?? []
            let monthSum = monthTxs.reduce(Decimal(0)) { sum, tx in
                let sign: Decimal = (tx.category.isIncome == .income) ? 1 : -1
                return sum + tx.amount * sign
            }
            runningBalance += monthSum
            result.append(BalanceChartData(date: month, balance: runningBalance))
        }
        return result
    }
    
    init(balanceViewModel: BalanceViewModel) {
        _vm = StateObject(wrappedValue: balanceViewModel)
    }
    @State private var isShowingCurrencyMenu = false
    @State private var isEditing = false
    @StateObject private var shake = ShakeDetector()
    @State private var isHidden = false
    
    var body: some View {
        NavigationStack {
            if isEditing {
                Form {
                    Section {
                        LabeledContent {
                            if isHidden {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 20)
                            } else {
                                TextField("0", text: $vm.balanceText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.body.weight(.semibold))
                            }
                        } label: {
                            Label("💰 Баланс", systemImage: "f")
                                .font(.body.weight(.medium))
                                .labelStyle(.titleOnly)
                        }
                    }
                    .padding(.vertical, 4)
                    Section {
                        Button {
                            isShowingCurrencyMenu = true
                        } label: {
                            HStack {
                                Text("Валюта")
                                    .font(.body.weight(.medium))
                                Spacer()
                                Text(vm.currency)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            // .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Валюта", isPresented: $isShowingCurrencyMenu) {
                            Button("Российский рубль ₽") { vm.currency = "₽" }
                            Button("Американский доллар $") { vm.currency = "$" }
                            Button("Евро €")            { vm.currency = "€" }
                            Button("Отмена", role: .cancel) { }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            else {
                if vm.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Загрузка баланса...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else {
                    Form {
                        Section {
                            LabeledContent {
                                if isHidden {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(height: 20)
                                } else {
                                    Text(vm.balanceText)
                                        .font(.body.weight(.semibold))
                                }
                            } label: {
                                Label("💰 Баланс", systemImage: "f")
                                    .font(.body.weight(.medium))
                                    .labelStyle(.titleOnly)
                            }
                        }
                        .padding(.vertical, 4)
                        Section {
                            LabeledContent {
                                Text(vm.currency)
                            } label: {
                                Text("Валюта")
                            }
                        }
                        .padding(.vertical, 4)
                        if !isEditing {
                            BalanceChartView(data: chartData, monthlyData: monthlyChartData)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("Мой счёт")
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Сохранить" : "Редактировать") {
                    if isEditing {
                        Task {
                            await vm.saveChanges()
                        }
                    }
                    withAnimation {
                        isEditing.toggle()
                    }
                }
            }
        }
        .refreshable {
            await vm.load()
        }
        .task {
            await vm.load()
            await vm.loadTransactions()
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

        .onReceive(shake.$didShake) { didShake in // вторая звездочка + ShakeDetector
            if didShake {
                withAnimation(.easeInOut) { isHidden.toggle() }
            }
            
        }
            }
    }
    
    private func firstDayOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: 1))!
    }



