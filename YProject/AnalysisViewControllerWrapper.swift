//
//  AnalysisViewControllerWrapper.swift
//  YProject
//
//  Created by Митя on 12.07.2025.
//

import SwiftUI

struct AnalysisViewControllerWrapper: UIViewControllerRepresentable {
  let start: Date
  let end: Date
  let transactions: [Transaction]

  func makeUIViewController(context: Context) -> AnalysisViewController {
    AnalysisViewController(start: start, end: end, transactions: transactions)
  }
  func updateUIViewController(_ vc: AnalysisViewController, context: Context) {
      
  }
}
