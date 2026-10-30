import Foundation
import SwiftData

/// The SwiftData operations every repository needs, over one shared `ModelContext`.
/// Repositories keep what is specific to them (which model, how a payload is encoded);
/// fetching, saving and the common write shapes live here once.
final class SwiftDataStore {
    /// Kept alive here: a `ModelContext` does not retain its container, and using it after the container is freed crashes.
    private let modelContainer: ModelContainer

    private var context: ModelContext { modelContainer.mainContext }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetch<Model: PersistentModel>(_ type: Model.Type, where predicate: Predicate<Model>? = nil) throws -> [Model] {
        try context.fetch(FetchDescriptor<Model>(predicate: predicate))
    }

    func first<Model: PersistentModel>(_ type: Model.Type, where predicate: Predicate<Model>? = nil) throws -> Model? {
        var descriptor = FetchDescriptor<Model>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Single-row models (e.g. a cached response): every existing row is replaced by `model`.
    func replaceAll<Model: PersistentModel>(with model: Model) throws {
        try context.delete(model: Model.self)
        context.insert(model)
        try context.save()
    }

    /// Keyed models (e.g. user state by API `_id`): updates the row matching `predicate`, or inserts a new one.
    func upsert<Model: PersistentModel>(
        where predicate: Predicate<Model>,
        update: (Model) -> Void,
        create: () -> Model
    ) throws {
        if let existing = try first(Model.self, where: predicate) {
            update(existing)
        } else {
            context.insert(create())
        }
        try context.save()
    }
}
