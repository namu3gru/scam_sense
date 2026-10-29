import Foundation

/// Bundled offline content (quiz, learn cards, family tips) in the app's language.
enum ContentLoader {
    static func load<T: Decodable>(_ name: String, as type: T.Type, language: String = AppConfig.language) -> T? {
        guard let url = Bundle.main.url(forResource: "\(name)_\(language)", withExtension: "json")
                ?? Bundle.main.url(forResource: "\(name)_en", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Content \(name): \(error)")
            return nil
        }
    }
}

struct QuizItem: Codable, Identifiable, Hashable {
    enum Kind: String, Codable { case sms, email, dm, call, marketplace, web }
    enum Answer: String, Codable { case scam, legit }

    var id: String
    var channel: Kind
    var sender: String
    var subject: String?
    var body: String
    var cta: String?
    var listing: String?
    var url: String?
    var situation: String?
    var answer: Answer
    var explanation: String
}

struct LearnCard: Codable, Identifiable, Hashable {
    var id: String
    var icon: String
    var title: String
    var summary: String
    var how: String
    var spot: [String]
    var todo: [String]
}

struct FamilyContent: Codable {
    struct Tip: Codable, Hashable, Identifiable {
        var icon: String
        var title: String
        var body: String
        var id: String { title }
    }
    struct Template: Codable, Hashable, Identifiable {
        var icon: String
        var title: String
        var message: String
        var id: String { title }
    }
    var invite: String
    var tips: [Tip]
    var templates: [Template]
}
