//
//  ArticlesView.swift
//  YProject
//
//  Created by Митя on 04.07.2025.
//

import SwiftUI

struct ArticlesView: View {
    @StateObject private var vm: ArticlesViewModel
    
    init(
        service: TransactionsService = MockTransactionsService(
            cache: TransactionsFileCache(
                fileURL: FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)
                    .first!
                    .appendingPathComponent("transactions.json")
            )
        )
    ) {
        _vm = StateObject(wrappedValue: ArticlesViewModel(service: service))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("", text: $vm.searchText, prompt: Text("🔍 Search"))
                }
                .padding(.vertical, 4)
                Section("Статьи") {
                    ForEach(vm.filteredCategories, id: \.id) { cat in
                        HStack {
                            Text(String(cat.emoji))
                            Text(cat.name)
                        }
                    }
                }
                
            }
        }
        .navigationTitle("Мои статьи")
        .task {
            await vm.loadCategories()
        }
    }
}
