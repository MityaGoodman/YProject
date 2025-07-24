//
//  AppContainerModel.swift
//  YProject
//
//  Created by Митя on 23.07.2025.
//

import Foundation
import SwiftData

final class AppContainerModel {
    static let shared = AppContainerModel()
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private init() {
        let schema = Schema([
            TransactionModel.self,
            BankAccountModel.self,
            CategoryModel.self,
            BackupEntryModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema)
        self.modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        self.modelContext = ModelContext(modelContainer)
    }
}

