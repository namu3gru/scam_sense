import Foundation

enum QuizLevel: Int, CaseIterable {
    case rookie, spotter, fighter, sensei

    static let thresholds = [0, 150, 500, 1200]

    static func level(for points: Int) -> QuizLevel {
        allCases.last { points >= thresholds[$0.rawValue] } ?? .rookie
    }

    var title: LocalizedStringResource {
        switch self {
        case .rookie: "Rookie"
        case .spotter: "Scam Spotter"
        case .fighter: "Fraud Fighter"
        case .sensei: "Scam Sensei"
        }
    }

    var symbol: String {
        switch self {
        case .rookie: "leaf.fill"
        case .spotter: "eye.fill"
        case .fighter: "shield.lefthalf.filled"
        case .sensei: "crown.fill"
        }
    }

    var next: QuizLevel? { QuizLevel(rawValue: rawValue + 1) }
    var floor: Int { Self.thresholds[rawValue] }
}

struct QuizProgress: Codable {
    var points = 0
    var answered = 0
    var correct = 0
    var streak = 0
    var bestStreak = 0
    var lastCompletedDay: String?
    var daysCompleted = 0
    var seen: [String] = []
    var todayKey: String?
    var todayIDs: [String] = []
    var todayAnswers: [String: Bool] = [:]
}

/// "Spot the Scam": 5 free questions a day, streaks, points and levels. Fully offline.
@MainActor
@Observable
final class QuizStore {
    static let perDay = 5
    static let pointsPerCorrect = 10

    private(set) var items: [QuizItem] = []
    private(set) var progress = QuizProgress()
    private let key = "quizProgress.v1"

    init() {
        items = ContentLoader.load("quiz", as: [QuizItem].self) ?? []
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(QuizProgress.self, from: data) {
            progress = saved
        }
    }

    static func dayKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    var level: QuizLevel { QuizLevel.level(for: progress.points) }

    /// 0...1 progress toward the next level.
    var levelProgress: Double {
        guard let next = level.next else { return 1 }
        return Double(progress.points - level.floor) / Double(next.floor - level.floor)
    }

    var pointsToNext: Int? { level.next.map { $0.floor - progress.points } }

    /// Streak as shown today: broken if the last completed day is before yesterday.
    var currentStreak: Int {
        guard let last = progress.lastCompletedDay else { return 0 }
        let today = Self.dayKey()
        let yesterday = Self.dayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        return (last == today || last == yesterday) ? progress.streak : 0
    }

    var accuracy: Int {
        progress.answered == 0 ? 0 : Int((Double(progress.correct) / Double(progress.answered) * 100).rounded())
    }

    /// Today's five questions (picked once per day, unseen ones first).
    /// Call `ensureToday()` first (from onAppear / task), never from a view body.
    var today: [QuizItem] {
        guard progress.todayKey == Self.dayKey() else { return [] }
        return progress.todayIDs.compactMap { id in items.first { $0.id == id } }
    }

    var todayAnsweredCount: Int { progress.todayKey == Self.dayKey() ? progress.todayAnswers.count : 0 }
    var todayCorrect: Int { progress.todayKey == Self.dayKey() ? progress.todayAnswers.values.filter { $0 }.count : 0 }
    var todayDone: Bool { progress.lastCompletedDay == Self.dayKey() }

    func ensureToday() {
        let key = Self.dayKey()
        guard progress.todayKey != key || progress.todayIDs.isEmpty else { return }
        progress.todayKey = key
        progress.todayIDs = pick(Self.perDay, excluding: [])
        progress.todayAnswers = [:]
        save()
    }

    /// Picks `count` items, unseen first, with at least one legit and two scams in the set.
    func pick(_ count: Int, excluding: Set<String>) -> [String] {
        var pool = items.filter { !progress.seen.contains($0.id) && !excluding.contains($0.id) }
        if pool.count < count {
            progress.seen = []
            pool = items.filter { !excluding.contains($0.id) }
        }
        var rng = SystemRandomNumberGenerator()
        pool.shuffle(using: &rng)
        var chosen: [QuizItem] = []
        if let legit = pool.first(where: { $0.answer == .legit }) { chosen.append(legit) }
        for item in pool.filter({ $0.answer == .scam }).prefix(2) { chosen.append(item) }
        for item in pool where chosen.count < count && !chosen.contains(item) { chosen.append(item) }
        chosen.shuffle(using: &rng)
        return chosen.prefix(count).map(\.id)
    }

    func practiceSet() -> [QuizItem] {
        let ids = pick(Self.perDay, excluding: Set(progress.todayIDs))
        return ids.compactMap { id in items.first { $0.id == id } }
    }

    /// Records an answer. Daily answers count toward today's set and the streak.
    @discardableResult
    func answer(_ item: QuizItem, saidScam: Bool, daily: Bool) -> Bool {
        let correct = (item.answer == .scam) == saidScam
        progress.answered += 1
        if correct {
            progress.correct += 1
            progress.points += Self.pointsPerCorrect
        }
        if !progress.seen.contains(item.id) { progress.seen.append(item.id) }
        if daily, progress.todayKey == Self.dayKey() {
            progress.todayAnswers[item.id] = correct
            if progress.todayAnswers.count >= Self.perDay && !todayDone { completeDay() }
        }
        save()
        return correct
    }

    private func completeDay() {
        let today = Self.dayKey()
        let yesterday = Self.dayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        progress.streak = progress.lastCompletedDay == yesterday ? progress.streak + 1 : 1
        progress.bestStreak = max(progress.bestStreak, progress.streak)
        progress.lastCompletedDay = today
        progress.daysCompleted += 1
        // Bonus for a perfect day keeps the habit rewarding.
        if progress.todayAnswers.values.allSatisfy({ $0 }) { progress.points += 10 }
    }

    func reset() {
        progress = QuizProgress()
        save()
    }

    /// Test hook: a believable mid-journey state for screenshots.
    func seedDemo() {
        progress.points = 380
        progress.answered = 44
        progress.correct = 39
        progress.streak = 6
        progress.bestStreak = 9
        progress.daysCompleted = 9
        progress.lastCompletedDay = Self.dayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(progress) { UserDefaults.standard.set(data, forKey: key) }
    }
}
