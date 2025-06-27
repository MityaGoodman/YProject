//
//  BalanceSheet.swift
//  YProject
//
//  Created by Митя on 26.06.2025.
//

import SwiftUI



struct BalanceSheet: View {
    @State private var balanceText = "-670 000"
    @State private var currency: String = "₽"
    @State private var isShowingCurrencyMenu = false
    @State private var isEditing = false
    @State private var service = MockBankAccountService(account:
                                                            BankAccount(dict: [
                                                                "id": 0,
                                                                "userId": 0,
                                                                "name": "Основной счёт",
                                                                "balance": "670000",
                                                                "currency": "₽",
                                                                "createdAt": ISO8601DateFormatter().string(from: Date()),
                                                                "updatedAt": ISO8601DateFormatter().string(from: Date())
                                                            ])
    )
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
                                TextField("0", text: $balanceText)
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
                                Text(currency)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            // .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Валюта", isPresented: $isShowingCurrencyMenu) {
                            Button("Российский рубль ₽") { currency = "₽" }
                            Button("Американский доллар $") { currency = "$" }
                            Button("Евро €")            { currency = "€" }
                            Button("Отмена", role: .cancel) { }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            else {
                Form {
                    Section {
                        LabeledContent {
                            if isHidden {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 20)
                            } else {
                                Text(balanceText)
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
                            Text(currency)
                        } label: {
                            Text("Валюта")
                        }
                    }
                    .padding(.vertical, 4)
                    
                }
            }
        }
        .navigationTitle("Мой счёт")
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Сохранить" : "Редактировать") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
            }
        }
        .refreshable { //первая звездочка
            await reload()
        }
        .task {
            await reload()
        }
        .onReceive(shake.$didShake) { didShake in // вторая звездочка + ShakeDetector
            if didShake {
                withAnimation(.easeInOut) { isHidden.toggle() }
            }
            
        }
    }
        private func reload() async {
            guard let acct = await service.fetchPrimaryAccount() else { return }
            let formatter = NumberFormatter()
            formatter.groupingSeparator = " "
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            let amt = formatter.string(from: acct.balance as NSNumber) ?? "\(acct.balance)"
            balanceText = amt
            currency    = acct.currency
        }
    }
    
    
