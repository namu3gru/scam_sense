import Foundation

/// Past checks, kept only on this iPhone (Application Support/history.json).
@MainActor
@Observable
final class HistoryStore {
    private(set) var records: [CheckRecord] = []

    /// Free users see this many recent checks; Pro keeps the full history visible.
    static let freeVisible = 10

    private let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }()

    init() {
        if let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode([CheckRecord].self, from: data) {
            records = saved
        }
    }

    func add(_ record: CheckRecord) {
        records.insert(record, at: 0)
        save()
    }

    func delete(_ ids: Set<UUID>) {
        records.removeAll { ids.contains($0.id) }
        save()
    }

    func clear() {
        records = []
        save()
    }

    func replaceAll(_ new: [CheckRecord]) {
        records = new
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}
