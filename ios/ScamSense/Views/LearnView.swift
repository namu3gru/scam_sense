import SwiftUI

struct LearnView: View {
    @Environment(AppModel.self) private var app
    @State private var cards: [LearnCard] = ContentLoader.load("learn", as: [LearnCard].self) ?? []
    @State private var path: [LearnCard] = []

    private let tints: [Color] = [Color(hex: 0x2347E0), Color(hex: 0xC8261B), Color(hex: 0x0D7A52),
                                  Color(hex: 0xB06A00), Color(hex: 0x7A3FD1), Color(hex: 0x0E7490)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Learn the tricks")
                            .font(Theme.title())
                            .foregroundStyle(Theme.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("The 12 scams going around right now, how they work, and how to beat them.")
                            .font(.body)
                            .foregroundStyle(Theme.subtle)
                    }
                    .padding(.top, 6)
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        NavigationLink(value: card) {
                            row(card, tint: tints[index % tints.count])
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: LearnCard.self) { card in
                let index = cards.firstIndex(of: card) ?? 0
                LearnDetailView(card: card, tint: tints[index % tints.count])
            }
        }
        .onAppear {
            if app.launchScreen == .learnDetail, let first = cards.first {
                app.launchScreen = nil
                path = [first]
            }
        }
    }

    private func row(_ card: LearnCard, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: card.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: card.title).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                Text(verbatim: card.summary).font(.subheadline).foregroundStyle(Theme.subtle)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Theme.subtle)
        }
        .card(padding: 14)
    }
}

struct LearnDetailView: View {
    let card: LearnCard
    let tint: Color
    @Environment(AppModel.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: card.icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    Text(verbatim: card.title).font(Theme.title(.title)).foregroundStyle(.white)
                    Text(verbatim: card.summary).font(.title3).foregroundStyle(.white.opacity(0.9))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

                section("How it works", symbol: "gearshape.2.fill") {
                    Text(verbatim: card.how).font(.body).foregroundStyle(Theme.ink)
                }
                section("How to spot it", symbol: "eye.fill") {
                    ForEach(card.spot, id: \.self) { line in
                        bullet(line, symbol: "flag.fill", color: Theme.scam)
                    }
                }
                section("What to do", symbol: "checkmark.shield.fill") {
                    ForEach(card.todo, id: \.self) { line in
                        bullet(line, symbol: "checkmark.circle.fill", color: Theme.safe)
                    }
                }
                Button {
                    app.tab = .check
                } label: {
                    Label("Got one like this? Check it", systemImage: "magnifyingglass")
                }
                .buttonStyle(PrimaryButtonStyle())
                ShareLink(item: "\(card.title)\n\n\(card.how)\n\n" + card.spot.map { "• " + $0 }.joined(separator: "\n")) {
                    Label("Share with family", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section<Content: View>(_ title: LocalizedStringResource, symbol: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label { Text(title) } icon: { Image(systemName: symbol).foregroundStyle(tint) }
                .sectionTitle()
            VStack(alignment: .leading, spacing: 12) { content() }
                .card()
        }
    }

    private func bullet(_ text: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(color).accessibilityHidden(true)
            Text(verbatim: text).font(.body).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
        }
    }
}
