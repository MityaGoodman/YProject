//
//  ArticlesView.swift
//  YProject
//
//  Created by Митя on 04.07.2025.
//

import SwiftUI

struct ArticlesView: View {
    @StateObject private var vm: ArticlesViewModel
    
    init(service: TransactionsService, categoriesService: CategoriesService) {
        _vm = StateObject(wrappedValue: ArticlesViewModel(service: service, categoriesService: categoriesService))
    }
    
    var body: some View {
        NavigationStack {
            if vm.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Загрузка статей...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
            } else {
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
        }
        .navigationTitle("Мои статьи")
        .task {
            await vm.loadCategories()
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

    }
}
