import Foundation

enum APIError: LocalizedError, Equatable {
    case freeLimit(QuotaStatus?)
    case proCap(QuotaStatus?)
    case aiFailed(String)
    case invalidInput(String)
    case tooLarge
    case badToken
    case offline
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .freeLimit:
            String(localized: "You've used your free checks for this week.")
        case .proCap:
            String(localized: "You've reached today's fair-use limit of 50 checks. It resets tomorrow.")
        case .aiFailed:
            String(localized: "We couldn't check this one right now. Don't worry, it didn't count toward your checks. Please try again.")
        case .invalidInput:
            String(localized: "Paste a message or add a screenshot first.")
        case .tooLarge:
            String(localized: "That screenshot is too large. Try cropping it.")
        case .badToken:
            String(localized: "This version of ScamSense needs an update. Please update the app.")
        case .offline:
            String(localized: "Can't reach ScamSense. Check your internet connection and try again.")
        case .server:
            String(localized: "Something went wrong on our side. Please try again in a minute.")
        }
    }
}

/// The three endpoints of apps_api for slug "scam".
struct APIClient {
    var baseURL: URL { AppConfig.baseURL }

    private func request(_ path: String, method: String = "GET", body: Data? = nil, timeout: TimeInterval = 20) -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent("v1/\(AppConfig.slug)/\(path)"))
        req.httpMethod = method
        req.timeoutInterval = timeout
        req.setValue(AppConfig.token, forHTTPHeaderField: "X-App-Token")
        req.setValue(DeviceID.value, forHTTPHeaderField: "X-Device-ID")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return req
    }

    func status() async throws -> QuotaStatus {
        try await send(request("status"))
    }

    func redeem(signedTransaction: String) async throws -> QuotaStatus {
        let body = try JSONEncoder().encode(["signed_transaction": signedTransaction])
        return try await send(request("entitlement", method: "POST", body: body))
    }

    func run(_ payload: RunRequest) async throws -> RunResponse {
        let body = try JSONEncoder().encode(payload)
        return try await send(request("run", method: "POST", body: body, timeout: 120))
    }

    private struct LimitDetail: Decodable {
        struct Inner: Decodable { var code: String; var status: QuotaStatus? }
        var detail: Inner
    }

    private struct MessageDetail: Decodable { var detail: String }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.offline
        }
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch code {
        case 200..<300:
            do { return try JSONDecoder().decode(T.self, from: data) } catch { throw APIError.server(code) }
        case 401:
            throw APIError.badToken
        case 402:
            let detail = try? JSONDecoder().decode(LimitDetail.self, from: data)
            if detail?.detail.code == "pro_cap" { throw APIError.proCap(detail?.detail.status) }
            throw APIError.freeLimit(detail?.detail.status)
        case 413:
            throw APIError.tooLarge
        case 422:
            throw APIError.invalidInput((try? JSONDecoder().decode(MessageDetail.self, from: data))?.detail ?? "")
        case 502:
            throw APIError.aiFailed((try? JSONDecoder().decode(MessageDetail.self, from: data))?.detail ?? "")
        default:
            throw APIError.server(code)
        }
    }
}
