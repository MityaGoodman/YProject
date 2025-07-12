//
//  BalanceSheet.swift
//  YProject
//
//  Created by Митя on 26.06.2025.
//

import SwiftUI



struct BalanceSheet: View {
    @StateObject private var vm: BalanceViewModel
    
    init(balanceManager: BalanceManager) {
        _vm = StateObject(wrappedValue: BalanceViewModel(balanceManager: balanceManager))
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
    
    


