//
//  LocalCategoriesService.swift
//  YProject
//
//  Created by Митя on 19.07.2025.
//

import Foundation

final class LocalCategoriesService: CategoriesService {
    private let apiService: CategoriesService
    private let localStorage: CategoriesStorage
    
    init(
        apiService: CategoriesService,
        localStorage: CategoriesStorage
    ) {
        self.apiService = apiService
        self.localStorage = localStorage
    }
    
    func fetchAll() async -> [Category] {
        let serverCategories = await apiService.fetchAll()
        await localStorage.saveCategories(serverCategories)
        return serverCategories
    }
    
    func fetch(by isIncome: Direction) async -> [Category] {
        let allCategories = await fetchAll()
        return allCategories.filter { $0.isIncome == isIncome }
    }
}

