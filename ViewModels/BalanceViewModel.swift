//
//  BalanceViewModel.swift
//  YProject
//
//  Created by Митя on 28.06.2025.
//
import SwiftUI


@MainActor
class BalanceViewModel: ObservableObject {
  @Published var balanceText: String = ""
  @Published var currency: String = ""
  private let service: BankAccountsService
  
  init(service: BankAccountsService) {
    self.service = service
    Task { await load() }
  }
  
  func load() async {
    if let account = await service.fetchPrimaryAccount() {
      balanceText = account.balance.formatted()
      currency    = account.currency
    }
  }
}
