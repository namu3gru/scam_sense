import SwiftUI

/// Renders a quiz item like the real thing: text bubble, email, DM, voicemail, marketplace chat or web pop-up.
/// Nothing inside is tappable.
struct MessageMockView: View {
    let item: QuizItem

    var body: some View {
        Group {
            switch item.channel {
            case .sms: sms
            case .email: email
            case .dm: dm
            case .call: voicemail
            case .marketplace: marketplace
            case .web: web
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var body_: Text { Self.highlighted(item.body) }

    // MARK: Text message

    private var sms: some View {
        VStack(spacing: 10) {
            VStack(spacing: 4) {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xA3A9B7), Color(hex: 0x7D8494)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "person.fill").font(.title2).foregroundStyle(.white))
                Text(verbatim: item.sender).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                Text("Text Message · Today 9:41 AM").font(.caption2).foregroundStyle(Theme.subtle)
            }
            HStack {
                body_
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.bubbleGray, in: BubbleShape())
                Spacer(minLength: 36)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Email

    private var email: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.brand.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(Text(verbatim: String(item.sender.prefix(1)).uppercased())
                        .font(.headline).foregroundStyle(Theme.brand))
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: item.sender).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    Text("To: me · 9:41 AM").font(.caption).foregroundStyle(Theme.subtle)
                }
                Spacer(minLength: 0)
                Image(systemName: "envelope.fill").foregroundStyle(Theme.subtle)
            }
            if let subject = item.subject {
                Text(verbatim: subject).font(.headline).foregroundStyle(Theme.ink)
            }
            Divider()
            body_.font(.body).foregroundStyle(Theme.ink)
            if let cta = item.cta {
                Text(verbatim: cta)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0x1F6FEB), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Social DM

    private var dm: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xF58529), Color(hex: 0xDD2A7B), Color(hex: 0x8134AF)],
                                         startPoint: .bottomLeading, endPoint: .topTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(Text(verbatim: String(item.sender.trimmingCharacters(in: CharacterSet(charactersIn: "@")).prefix(1)).uppercased())
                        .font(.headline).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: item.sender).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                    Text("Direct message").font(.caption).foregroundStyle(Theme.subtle)
                }
                Spacer()
                Image(systemName: "bubble.left.and.bubble.right.fill").foregroundStyle(Color(hex: 0x8134AF))
            }
            HStack {
                body_
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.bubbleGray, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                Spacer(minLength: 30)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Voicemail / call

    private var voicemail: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: 0x34C759), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: item.sender).font(.headline).foregroundStyle(Theme.ink)
                    Text("Voicemail · 0:38").font(.caption).foregroundStyle(Theme.subtle)
                }
                Spacer()
            }
            HStack(spacing: 3) {
                ForEach(0..<34, id: \.self) { i in
                    Capsule()
                        .fill(Theme.subtle.opacity(0.5))
                        .frame(width: 3, height: CGFloat(6 + (i * 37 % 23)))
                }
            }
            .frame(height: 30)
            .accessibilityHidden(true)
            Text("Transcript").font(.caption.weight(.bold)).foregroundStyle(Theme.subtle).textCase(.uppercase)
            body_.font(.body.italic()).foregroundStyle(Theme.ink)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Marketplace

    private var marketplace: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let listing = item.listing {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.cardAlt)
                        .frame(width: 46, height: 46)
                        .overlay(Image(systemName: "tag.fill").foregroundStyle(Theme.subtle))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Marketplace").font(.caption.weight(.bold)).foregroundStyle(Theme.subtle).textCase(.uppercase)
                        Text(verbatim: listing).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                    }
                }
                Divider()
            }
            Text(verbatim: item.sender).font(.caption.weight(.semibold)).foregroundStyle(Theme.subtle)
            HStack {
                body_
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.bubbleGray, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Spacer(minLength: 30)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    // MARK: Web pop-up

    private var web: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "lock.slash").font(.caption)
                Text(verbatim: item.url ?? item.sender).font(.caption.monospaced()).lineLimit(1)
                Spacer()
            }
            .foregroundStyle(Theme.subtle)
            .padding(10)
            .background(Theme.cardAlt)
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(Color(hex: 0xE5484D))
                Text(verbatim: item.sender).font(.headline).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                body_.font(.body).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                if let cta = item.cta {
                    Text(verbatim: cta)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(hex: 0xE5484D), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    /// Colors link-looking text blue (like a real phone would) without making it tappable.
    static func highlighted(_ text: String) -> Text {
        var attributed = AttributedString(text)
        let pattern = #"(?i)\b(?:https?://)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?:/[^\s]*)?"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let range = Range(match.range, in: text),
                      let lower = AttributedString.Index(range.lowerBound, within: attributed),
                      let upper = AttributedString.Index(range.upperBound, within: attributed) else { continue }
                attributed[lower..<upper].foregroundColor = Color(hex: 0x1F6FEB)
                attributed[lower..<upper].underlineStyle = .single
            }
        }
        return Text(attributed)
    }
}

// MARK: - Share card

struct ScoreShareCard: View {
    let score: Int
    let total: Int
    let streak: Int
    let level: QuizLevel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                LogoMark(size: 34)
                Text(verbatim: "ScamSense").font(.system(size: 20, weight: .heavy, design: .rounded))
                Spacer()
            }
            Spacer(minLength: 0)
            Text("Spot the Scam").font(.system(size: 18, weight: .bold, design: .rounded)).opacity(0.85)
            Text(verbatim: "\(score)/\(total)")
                .font(.system(size: 84, weight: .black, design: .rounded))
            Text("I got \(score) of \(total) right today")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                badge(symbol: "flame.fill", text: Text("\(streak)-day streak"))
                badge(symbol: level.symbol, text: Text(level.title))
            }
            Spacer(minLength: 0)
            Text("Can you beat me?")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.gold, in: Capsule())
                .foregroundStyle(Theme.brandDeep)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(width: 300, height: 375)
        .background {
            ZStack {
                Theme.heroGradient
                Circle().fill(.white.opacity(0.06)).frame(width: 340, height: 340).offset(x: 140, y: -170)
                Circle().fill(.white.opacity(0.05)).frame(width: 260, height: 260).offset(x: -150, y: 190)
            }
            .frame(width: 300, height: 375)
            .clipped()
        }
        .dynamicTypeSize(.large)
    }

    private func badge(symbol: String, text: Text) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
            text
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.white.opacity(0.16), in: Capsule())
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct ShareScoreButton: View {
    let score: Int
    let total: Int

    @Environment(QuizStore.self) private var quiz
    @Environment(\.locale) private var locale
    @State private var image: Image?

    var body: some View {
        Group {
            if let image {
                ShareLink(item: image,
                          message: Text("I got \(score) of \(total) right on ScamSense's Spot the Scam today. Can you beat me?"),
                          preview: SharePreview(Text("My Spot the Scam score"), image: image)) {
                    Label("Share score", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {} label: { Label("Share score", systemImage: "square.and.arrow.up") }.disabled(true)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .task(id: score) { render() }
    }

    @MainActor private func render() {
        let card = ScoreShareCard(score: score, total: total, streak: quiz.currentStreak, level: quiz.level)
            .environment(\.locale, locale)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.6
        guard let ui = renderer.uiImage else { return }
        image = Image(uiImage: ui)
        // Test hook: -uiExportShareCard YES writes the rendered card to Documents for screenshots.
        if UserDefaults.standard.bool(forKey: "uiExportShareCard"),
           let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? ui.pngData()?.write(to: dir.appendingPathComponent("sharecard.png"))
        }
    }
}
