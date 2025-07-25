//
//  GenericSwiftDataStorage.swift
//  YProject
//
//  Created by Митя on 23.07.2025.
//

import Foundation
import SwiftData

@MainActor
final class GenericSwiftDataStorage<T: PersistentModel, DomainType> {
    private let modelContainer: ModelContainer = AppContainerModel.shared.modelContainer
    private let modelContext: ModelContext = AppContainerModel.shared.modelContext
    
    private let toDomain: (T) -> DomainType
    private let toModel: (DomainType) -> T
    
    init(toDomain: @escaping (T) -> DomainType, toModel: @escaping (DomainType) -> T) {
        self.toDomain = toDomain
        self.toModel = toModel
    }
    
    func getAll() async -> [DomainType] {
        do {
            let descriptor = FetchDescriptor<T>()
            let models = try modelContext.fetch(descriptor)
            return models.map(toDomain)
        } catch {
            print("Ошибка при получении всех объектов: \(error)")
            return []
        }
    }
    
    func getFiltered(predicate: Predicate<T>) async -> [DomainType] {
        do {
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let models = try modelContext.fetch(descriptor)
            return models.map(toDomain)
        } catch {
            print("Ошибка при фильтрации объектов: \(error)")
            return []
        }
    }
    
    func create(_ domain: DomainType) async {
        do {
            let model = toModel(domain)
            modelContext.insert(model)
            try modelContext.save()
        } catch {
            print("Ошибка при создании объекта: \(error)")
        }
    }
    
    func update(_ domain: DomainType, updateBlock: (T) -> Void, predicate: Predicate<T>) async {
        do {
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let models = try modelContext.fetch(descriptor)
            if let model = models.first {
                updateBlock(model)
                try modelContext.save()
            }
        } catch {
            print("Ошибка при обновлении объекта: \(error)")
        }
    }
    
    func delete(predicate: Predicate<T>) async {
        do {
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let models = try modelContext.fetch(descriptor)
            for model in models {
                modelContext.delete(model)
            }
            try modelContext.save()
        } catch {
            print("Ошибка при удалении объекта: \(error)")
        }
    }
    
    func saveAll(_ domains: [DomainType]) async {
        do {
            let descriptor = FetchDescriptor<T>()
            let existingModels = try modelContext.fetch(descriptor)
            for model in existingModels {
                modelContext.delete(model)
            }
            for domain in domains {
                let model = toModel(domain)
                modelContext.insert(model)
            }
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении всех объектов: \(error)")
        }
    }
}

