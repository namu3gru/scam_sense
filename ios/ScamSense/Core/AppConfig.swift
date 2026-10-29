import Foundation

/// Everything the owner may need to change before release lives here.
enum AppConfig {
    /// Shared app token for the backend (APP_TOKEN in apps_api/.env).
    /// Paste the real value here before submitting to the App Store.
    static let appToken = "REPLACE_WITH_APP_TOKEN"

    static let defaultBaseURL = "https://api.namu3gru.com"
    static let slug = "scam"

    /// Numeric App Store id once the app record exists (used in the "invite a parent" message).
    static let appStoreID: String? = nil

    static let supportEmail = "support@namu3gru.com"
    static let privacyURL = URL(string: "https://scamsense.namu3gru.com/privacy")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let supportURL = URL(string: "https://scamsense.namu3gru.com/support")!

    static let monthlyID = "com.namu3gru.ScamSense.pro.monthly"
    static let yearlyID = "com.namu3gru.ScamSense.pro.yearly"
    static let productIDs = [yearlyID, monthlyID]

    /// Launch arguments land in UserDefaults: `-apiBaseURL http://127.0.0.1:8112 -apiToken dev`.
    static var baseURL: URL {
        let raw = UserDefaults.standard.string(forKey: "apiBaseURL") ?? defaultBaseURL
        return URL(string: raw) ?? URL(string: defaultBaseURL)!
    }

    static var token: String {
        UserDefaults.standard.string(forKey: "apiToken") ?? appToken
    }

    static var appStoreLink: String? {
        appStoreID.map { "https://apps.apple.com/app/id\($0)" }
    }

    /// Language the AI answers in and the bundled content uses: follows the iPhone language.
    static var language: String {
        (Bundle.main.preferredLocalizations.first ?? "en").hasPrefix("ko") ? "ko" : "en"
    }
}
