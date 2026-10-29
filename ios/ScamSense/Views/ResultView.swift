import SwiftUI
import UIKit

/// Traffic-light verdict: header + gauge, red flags, what to do, where to report, warn family.
struct ResultView: View {
    let record: CheckRecord
    var fresh = false

    @State private var showAlreadyActed = false
    @State private var showMessage = false
    @State private var appeared = false

    private var result: ScamResult { record.result }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 0) {
                VerdictHeader(result: result, animate: fresh)
                VStack(alignment: .leading, spacing: 22) {
                    warnFamily
                    if !result.redFlags.isEmpty { redFlags }
                    if !result.safeSigns.isEmpty { safeSigns }
                    if !result.whatToDo.isEmpty { whatToDo.id("todo") }
                    if !result.ifAlreadyActed.isEmpty { alreadyActed }
                    if !result.reportTo.isEmpty { reportTo }
                    yourMessage
                    disclaimer
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .background(Theme.bg)
            }
        }
        .onAppear {
            // Test hook for screenshots of the lower half: -uiResultScroll YES
            guard UserDefaults.standard.bool(forKey: "uiResultScroll") else { return }
            showAlreadyActed = true
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation { proxy.scrollTo("todo", anchor: .top) }
            }
        }
        }
        .background {
            VStack(spacing: 0) {
                result.verdict.headerFill.frame(maxHeight: .infinity)
                Theme.bg.frame(maxHeight: .infinity)
            }
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // Solid verdict color behind the status bar / nav bar so scrolled text never collides with it.
            Color.clear.frame(height: 0)
                .background(result.verdict.headerFill, ignoresSafeAreaEdges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(result.verdict.headerFill, for: .navigationBar)
        .toolbarColorScheme(result.verdict == .suspicious ? .light : .dark, for: .navigationBar)
        .sensoryFeedback(trigger: appeared) { _, _ in
            guard fresh else { return nil }
            return result.verdict == .likelySafe ? .success : .warning
        }
        .onAppear { appeared = true }
    }

    // MARK: Sections

    private var shareText: String {
        var text = result.familyMessage.trimmed
        if text.isEmpty { text = result.headline }
        text += "\n\n" + String(localized: "Checked with ScamSense")
        if let link = AppConfig.appStoreLink { text += " " + link }
        return text
    }

    @ViewBuilder private var warnFamily: some View {
        let urgent = result.verdict != .likelySafe
        VStack(alignment: .leading, spacing: 10) {
            if urgent && !result.familyMessage.isEmpty {
                Text(verbatim: "“\(result.familyMessage)”")
                    .font(.body.italic())
                    .foregroundStyle(Theme.ink)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            ShareLink(item: shareText, subject: Text("Scam warning"),
                      preview: SharePreview(Text("Scam warning from ScamSense"))) {
                Label(urgent ? "Warn my family" : "Share this result",
                      systemImage: urgent ? "exclamationmark.bubble.fill" : "square.and.arrow.up")
            }
            .buttonStyle(PrimaryButtonStyle(fill: urgent ? Theme.scamFill : Theme.brandFill))
            .accessibilityHint(Text("Sends a short warning you can forward to family"))
        }
    }

    private var redFlags: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Red flags", systemImage: "flag.fill").sectionTitle()
            ForEach(Array(result.redFlags.enumerated()), id: \.offset) { _, flag in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: Self.icon(flag: flag.flag, why: flag.why))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.scam)
                        .frame(width: 44, height: 44)
                        .background(Theme.scam.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: flag.flag).font(.headline).foregroundStyle(Theme.ink)
                        Text(verbatim: flag.why).font(.body).foregroundStyle(Theme.subtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .card(padding: 14)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var safeSigns: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Good signs", systemImage: "checkmark.seal.fill").sectionTitle()
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(result.safeSigns.enumerated()), id: \.offset) { _, sign in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(Theme.safe)
                            .accessibilityHidden(true)
                        Text(verbatim: sign).font(.body).foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .card(padding: 16)
        }
    }

    private var whatToDo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What to do", systemImage: "list.number").sectionTitle()
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(result.whatToDo.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text(verbatim: "\(index + 1)")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Theme.brandFill, in: Circle())
                            .accessibilityHidden(true)
                        Text(verbatim: step).font(.body).foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 5)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Step \(index + 1): \(step)"))
                }
            }
            .card(padding: 16)
        }
    }

    private var alreadyActed: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.35)) { showAlreadyActed.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bandage.fill").font(.title3).foregroundStyle(Theme.warn)
                    Text("Already clicked or paid?")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showAlreadyActed ? 180 : 0))
                        .foregroundStyle(Theme.subtle)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(showAlreadyActed ? "Hides the steps" : "Shows what to do now"))
            if showAlreadyActed {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Don't panic. Acting quickly helps. Do these now:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.subtle)
                    ForEach(Array(result.ifAlreadyActed.enumerated()), id: \.offset) { _, step in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill").foregroundStyle(Theme.warn)
                                .accessibilityHidden(true)
                            Text(verbatim: step).font(.body).foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .card(padding: 16, fill: Theme.warn.opacity(0.08))
    }

    private var reportTo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Report it", systemImage: "megaphone.fill").sectionTitle()
            ForEach(Array(result.reportTo.enumerated()), id: \.offset) { _, place in
                ReportCard(place: place)
            }
        }
    }

    @ViewBuilder private var yourMessage: some View {
        if record.text != nil || record.thumbnail != nil {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation { showMessage.toggle() }
                } label: {
                    HStack {
                        Label("What you checked", systemImage: "doc.text.magnifyingglass")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showMessage ? 180 : 0))
                            .foregroundStyle(Theme.subtle)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if showMessage {
                    if let data = record.thumbnail, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    if let text = record.text {
                        // Plain text on purpose: links in the suspicious content are never tappable.
                        Text(verbatim: text)
                            .font(.callout.monospaced())
                            .foregroundStyle(Theme.subtle)
                            .textSelection(.enabled)
                    }
                    Text(record.date, format: .dateTime.month().day().hour().minute())
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
            }
            .card(padding: 14)
        }
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(Theme.subtle)
            Text("AI can be wrong. When in doubt, contact the company directly using its official number or app, not the contact info in the message.")
                .font(.footnote)
                .foregroundStyle(Theme.subtle)
        }
        .padding(.top, 4)
    }

    /// Picks an icon from the flag title first, then from its explanation.
    static func icon(flag: String, why: String) -> String {
        match(flag) ?? match(why) ?? "flag.fill"
    }

    private static func match(_ text: String) -> String? {
        let t = text.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { t.contains($0) } }
        if has(["link", "url", "website", "domain", "site", "링크", "주소", "사이트"]) { return "link" }
        if has(["sender", "number", "unknown", "caller", "address", "발신", "번호", "모르는", "보낸"]) { return "person.crop.circle.badge.questionmark" }
        if has(["urgent", "pressure", "fast", "rush", "deadline", "threat", "hurry", "긴급", "급하", "압박", "기한", "재촉", "협박"]) {
            return "clock.badge.exclamationmark"
        }
        if has(["code", "password", "pin", "login", "log in", "verify", "인증", "비밀번호", "로그인"]) { return "key.fill" }
        if has(["gift card", "crypto", "wire", "zelle", "payment", "pay ", "fee", "money", "bitcoin", "상품권", "송금", "입금", "결제", "코인", "수수료", "돈"]) {
            return "creditcard.trianglebadge.exclamationmark"
        }
        if has(["app", "remote", "download", "install", "앱", "설치", "원격"]) { return "apps.iphone" }
        if has(["secret", "don't tell", "비밀", "알리지"]) { return "eye.slash.fill" }
        if has(["too good", "prize", "won", "당첨", "보장"]) { return "gift.fill" }
        return nil
    }
}

// MARK: - Header

struct VerdictHeader: View {
    let result: ScamResult
    var animate: Bool
    var compact = false

    var body: some View {
        let fg = result.verdict.headerText
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: result.verdict.symbol).font(.system(size: 30, weight: .bold))
                Text(result.verdict.bigLabel)
                    .font(.system(.title, design: .rounded, weight: .black))
                    .tracking(1.5)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            RiskGauge(score: result.riskScore, color: fg, animate: animate)
            Text(verbatim: result.headline)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if result.hasScamType {
                Text(verbatim: result.scamType)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(fg.opacity(0.16), in: Capsule())
                    .accessibilityLabel(Text("Type: \(result.scamType)"))
            }
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 20)
        .padding(.top, compact ? 14 : 52)   // room for the floating Done / History button
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity)
        .background(result.verdict.headerFill)
    }
}

struct RiskGauge: View {
    let score: Int
    let color: Color
    var animate: Bool

    @State private var shown: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Circle()
                    .trim(from: 0.5, to: 1)
                    .stroke(color.opacity(0.22), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                Circle()
                    .trim(from: 0.5, to: 0.5 + 0.5 * shown / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
            }
            .frame(width: 210, height: 210)
            .frame(height: 115, alignment: .top)
            VStack(spacing: 0) {
                Text(verbatim: "\(Int(shown.rounded()))")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("Risk score")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .textCase(.uppercase)
                    .opacity(0.85)
            }
        }
        .foregroundStyle(color)
        .frame(width: 230, height: 125)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Risk score \(score) out of 100"))
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 1.1).delay(0.15)) { shown = Double(score) }
            } else {
                shown = Double(score)
            }
        }
    }
}

// MARK: - Report cards

struct ReportCard: View {
    let place: ReportPlace

    @Environment(\.openURL) private var openURL
    @State private var showActions = false
    @State private var confirmURL: URL?

    enum Action: Hashable {
        case web(URL, trusted: Bool)
        case call(String)
        case text(String)
    }

    private var actions: [Action] { Self.actions(for: place) }

    var body: some View {
        Button {
            if actions.count == 1, case .web(let url, let trusted) = actions[0] {
                if trusted { openURL(url) } else { confirmURL = url }
            } else {
                showActions = true
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 44, height: 44)
                    .background(Theme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: place.name).font(.headline).foregroundStyle(Theme.ink)
                    Text(verbatim: place.how).font(.subheadline).foregroundStyle(Theme.subtle)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: actions.isEmpty ? "doc.on.doc" : "chevron.right").foregroundStyle(Theme.subtle)
            }
            .card(padding: 14)
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint(Text("Shows ways to report"))
        .confirmationDialog(Text(verbatim: place.name), isPresented: $showActions, titleVisibility: .visible) {
            ForEach(actions, id: \.self) { action in
                switch action {
                case .web(let url, let trusted):
                    Button(String(localized: "Open \(url.host() ?? url.absoluteString)")) {
                        if trusted { openURL(url) } else { confirmURL = url }
                    }
                case .call(let number):
                    Button(String(localized: "Call \(number)")) {
                        if let url = URL(string: "tel:\(number.filter { $0.isNumber || $0 == "+" })") { openURL(url) }
                    }
                case .text(let number):
                    Button(String(localized: "Text \(number)")) {
                        if let url = URL(string: "sms:\(number)") { openURL(url) }
                    }
                }
            }
            Button(String(localized: "Copy")) { UIPasteboard.general.string = place.how }
            Button("Cancel", role: .cancel) {}
        } message: {
            if actions.contains(.text("7726")) {
                Text("To forward a scam text: press and hold it, tap More, then the arrow, and send it to 7726.")
            } else {
                Text(verbatim: place.how)
            }
        }
        .alert(Text("Open this website?"), isPresented: Binding(get: { confirmURL != nil }, set: { if !$0 { confirmURL = nil } })) {
            Button("Open in Safari") { if let url = confirmURL { openURL(url) } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(confirmURL?.host() ?? "") isn't on our list of official reporting sites. Make sure it's the real company's website before you sign in.")
        }
    }

    private var symbol: String {
        switch actions.first {
        case .web: "safari.fill"
        case .call: "phone.fill"
        case .text: "message.fill"
        case nil: "megaphone.fill"
        }
    }

    static let trustedHosts = ["ftc.gov", "ic3.gov", "identitytheft.gov", "fcc.gov", "usa.gov", "ssa.gov",
                               "consumer.gov", "aarp.org", "police.go.kr", "kisa.or.kr", "fss.or.kr",
                               "counterscam112.go.kr", "boho.or.kr", "spo.go.kr", "fcsc.kr"]
    static let callNumbers: Set<String> = ["112", "118", "1332", "182", "1301", "1811-0041"]

    static func actions(for place: ReportPlace) -> [Action] {
        let text = place.name + " " + place.how
        var out: [Action] = []
        let urlPattern = #"(?i)\b(?:https?://)?((?:[a-z0-9-]+\.)+(?:gov|com|org|net|us|kr)(?:/[^\s,)]*)?)"#
        if let regex = try? NSRegularExpression(pattern: urlPattern) {
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let range = Range(match.range(at: 1), in: text),
                      let url = URL(string: "https://" + text[range].trimmingCharacters(in: CharacterSet(charactersIn: ".")))
                else { continue }
                let host = url.host()?.lowercased() ?? ""
                let trusted = trustedHosts.contains { host == $0 || host.hasSuffix("." + $0) }
                let action = Action.web(url, trusted: trusted)
                if !out.contains(action) { out.append(action) }
            }
        }
        if text.contains("7726") { out.append(.text("7726")) }
        let numberPattern = #"(?<![\d.])(\d{3,4}(?:-\d{4})?|1-\d{3}-\d{3}-\d{4}|\(?\d{3}\)?[ -]\d{3}-\d{4})(?![\d.])"#
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let range = Range(match.range(at: 1), in: text) else { continue }
                let number = String(text[range])
                if number == "7726" { continue }
                let digits = number.filter(\.isNumber)
                if callNumbers.contains(number) || digits.count >= 10 {
                    let action = Action.call(number)
                    if !out.contains(action) { out.append(action) }
                }
            }
        }
        return out
    }
}
