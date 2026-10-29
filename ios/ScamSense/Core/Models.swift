import Foundation
import SwiftUI

// MARK: - Server result (apps_api/apps/scam.py SCHEMA)

enum Verdict: String, Codable, Hashable, CaseIterable {
    case scam
    case suspicious
    case likelySafe = "likely_safe"

    static func from(score: Int) -> Verdict {
        score >= 80 ? .scam : (score >= 40 ? .suspicious : .likelySafe)
    }

    var label: LocalizedStringResource {
        switch self {
        case .scam: "Scam"
        case .suspicious: "Suspicious"
        case .likelySafe: "Likely safe"
        }
    }

    var bigLabel: LocalizedStringResource {
        switch self {
        case .scam: "SCAM"
        case .suspicious: "SUSPICIOUS"
        case .likelySafe: "LIKELY SAFE"
        }
    }

    var symbol: String {
        switch self {
        case .scam: "xmark.octagon.fill"
        case .suspicious: "exclamationmark.triangle.fill"
        case .likelySafe: "checkmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .scam: Theme.scam
        case .suspicious: Theme.warn
        case .likelySafe: Theme.safe
        }
    }

    /// Full-width header fill and the text color that keeps contrast high on it.
    var headerFill: Color {
        switch self {
        case .scam: Color(hex: 0xC2261C)
        case .suspicious: Color(hex: 0xF4A41C)
        case .likelySafe: Color(hex: 0x0D7550)
        }
    }

    var headerText: Color {
        self == .suspicious ? Color(hex: 0x231600) : .white
    }
}

struct RedFlag: Codable, Hashable {
    var flag: String
    var why: String
}

struct ReportPlace: Codable, Hashable {
    var name: String
    var how: String
}

struct ScamResult: Codable, Hashable {
    var verdict: Verdict
    var riskScore: Int
    var scamType: String
    var headline: String
    var redFlags: [RedFlag]
    var safeSigns: [String]
    var whatToDo: [String]
    var ifAlreadyActed: [String]
    var reportTo: [ReportPlace]
    var familyMessage: String

    enum CodingKeys: String, CodingKey {
        case verdict, headline
        case riskScore = "risk_score"
        case scamType = "scam_type"
        case redFlags = "red_flags"
        case safeSigns = "safe_signs"
        case whatToDo = "what_to_do"
        case ifAlreadyActed = "if_already_acted"
        case reportTo = "report_to"
        case familyMessage = "family_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let score = min(100, max(0, (try? c.decode(Int.self, forKey: .riskScore)) ?? 50))
        riskScore = score
        let raw = (try? c.decode(String.self, forKey: .verdict)) ?? ""
        verdict = Verdict(rawValue: raw) ?? Verdict.from(score: score)
        scamType = (try? c.decode(String.self, forKey: .scamType)) ?? ""
        headline = (try? c.decode(String.self, forKey: .headline)) ?? ""
        redFlags = (try? c.decode([RedFlag].self, forKey: .redFlags)) ?? []
        safeSigns = (try? c.decode([String].self, forKey: .safeSigns)) ?? []
        whatToDo = (try? c.decode([String].self, forKey: .whatToDo)) ?? []
        ifAlreadyActed = (try? c.decode([String].self, forKey: .ifAlreadyActed)) ?? []
        reportTo = (try? c.decode([ReportPlace].self, forKey: .reportTo)) ?? []
        familyMessage = (try? c.decode(String.self, forKey: .familyMessage)) ?? ""
    }

    /// "None" or empty means the AI found no scam pattern.
    var hasScamType: Bool {
        let t = scamType.trimmingCharacters(in: .whitespaces).lowercased()
        return !t.isEmpty && t != "none" && t != "없음"
    }

    /// The SAMPLE the mock server returns, bundled for the onboarding demo (works offline).
    static func bundledSample(language: String = AppConfig.language) -> ScamResult? {
        guard let url = Bundle.main.url(forResource: "sample_\(language)", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ScamResult.self, from: data)
    }
}

// MARK: - Quota (entitlements.status)

struct QuotaStatus: Codable, Hashable {
    var pro: Bool
    var proUntil: Double?
    var limit: Int
    var used: Int
    var remaining: Int
    var period: String
    var resetsAt: Double

    enum CodingKeys: String, CodingKey {
        case pro, limit, used, remaining, period
        case proUntil = "pro_until"
        case resetsAt = "resets_at"
    }

    var resetsDate: Date { Date(timeIntervalSince1970: resetsAt) }
}

struct RunResponse: Codable {
    var result: ScamResult
    var status: QuotaStatus
    var model: String?
}

struct RunRequest: Codable {
    var imageBase64: String?
    var text: String?
    var channel: String
    var context: String?
    var language: String
    var country: String

    enum CodingKeys: String, CodingKey {
        case text, channel, context, language, country
        case imageBase64 = "image_base64"
    }
}

// MARK: - Input

enum Channel: String, Codable, CaseIterable, Identifiable, Hashable {
    case sms, email, call, social, website, marketplace

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .sms: "Text"
        case .email: "Email"
        case .call: "Call"
        case .social: "Social/DM"
        case .website: "Website"
        case .marketplace: "Marketplace"
        }
    }

    var symbol: String {
        switch self {
        case .sms: "message.fill"
        case .email: "envelope.fill"
        case .call: "phone.fill"
        case .social: "bubble.left.and.bubble.right.fill"
        case .website: "globe"
        case .marketplace: "bag.fill"
        }
    }
}

enum Audience: String, CaseIterable, Identifiable {
    case me, parent, family
    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .me: "Me"
        case .parent: "A parent or grandparent"
        case .family: "My whole family"
        }
    }

    var subtitle: LocalizedStringResource {
        switch self {
        case .me: "I want a second opinion before I tap."
        case .parent: "I worry about someone I love getting tricked."
        case .family: "We want to look out for each other."
        }
    }

    var symbol: String {
        switch self {
        case .me: "person.fill"
        case .parent: "figure.and.child.holdinghands"
        case .family: "person.3.fill"
        }
    }
}

enum Country: String, CaseIterable, Identifiable {
    case us = "US", kr = "KR"
    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .us: "United States"
        case .kr: "South Korea"
        }
    }

    static var fromLocale: Country {
        Locale.current.region?.identifier == "KR" ? .kr : .us
    }
}

// MARK: - History

struct CheckRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var text: String?
    var thumbnail: Data?
    var channel: Channel?
    var context: String?
    var result: ScamResult
    var isDemo = false

    var preview: String {
        let t = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return String(t.prefix(140)) }
        return String(localized: "Screenshot")
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfBlank: String? { trimmed.isEmpty ? nil : self }
}

extension ScamResult {
    init(verdict: Verdict, riskScore: Int, scamType: String, headline: String, redFlags: [RedFlag] = [],
         safeSigns: [String] = [], whatToDo: [String] = [], ifAlreadyActed: [String] = [],
         reportTo: [ReportPlace] = [], familyMessage: String = "") {
        self.verdict = verdict
        self.riskScore = riskScore
        self.scamType = scamType
        self.headline = headline
        self.redFlags = redFlags
        self.safeSigns = safeSigns
        self.whatToDo = whatToDo
        self.ifAlreadyActed = ifAlreadyActed
        self.reportTo = reportTo
        self.familyMessage = familyMessage
    }
}
