//
//  BalanceViewModel.swift
//  YProject
//
//  Created by Митя on 28.06.2025.
//
import SwiftUI
import Combine


@MainActor
class BalanceViewModel: ObservableObject {
  @Published var balanceText: String = ""
  @Published var currency: String = ""
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?
  @Published var isOffline: Bool = false
  
  private let balanceManager: BalanceManager
  
  init(balanceManager: BalanceManager) {
    self.balanceManager = balanceManager
    setupBindings()
  }
  
  private func setupBindings() {
    balanceManager.$currentBalance
      .sink { [weak self] balance in
        self?.balanceText = balance.formatted()
      }
      .store(in: &cancellables)
    
    balanceManager.$currency
      .sink { [weak self] currency in
        self?.currency = currency
      }
      .store(in: &cancellables)
  }
  
  func load() async {
    isLoading = true
    errorMessage = nil
    isOffline = false
    
    do {
      try await balanceManager.loadCurrentBalance()
    } catch {
      errorMessage = "Ошибка загрузки баланса: \(error.localizedDescription)"
      isOffline = true
    }
    
    isLoading = false
  }
  
  func saveChanges() async {
    isLoading = true
    errorMessage = nil
    
    do {
      let formatter = NumberFormatter()
      formatter.locale = Locale.current
      formatter.numberStyle = .decimal
      
      guard let number = formatter.number(from: balanceText) else {
        errorMessage = "Неверный формат баланса"
        isLoading = false
        return
      }
      
      let newBalance = number.decimalValue
      
      balanceManager.updateBalanceManually(to: newBalance, currency: currency)
      
    } catch {
      errorMessage = "Ошибка сохранения баланса: \(error.localizedDescription)"
    }
    
    isLoading = false
  }
  
  private var cancellables = Set<AnyCancellable>()
}
