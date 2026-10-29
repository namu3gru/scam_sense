import StoreKit
import SwiftUI

struct QuizPlayView: View {
    let session: QuizSession
    var onClose: () -> Void

    @Environment(QuizStore.self) private var quiz
    @Environment(AppModel.self) private var app
    @Environment(\.requestReview) private var requestReview

    @State private var index = 0
    @State private var saidScam: Bool?
    @State private var lastCorrect = false
    @State private var results: [Bool] = []
    @State private var showSummary = false
    @State private var feedback = 0
    @State private var startedFrom = 0

    private var item: QuizItem? { session.items.indices.contains(index) ? session.items[index] : nil }

    var body: some View {
        NavigationStack {
            Group {
                if showSummary {
                    QuizSummaryView(correct: results.filter { $0 }.count + previousCorrect,
                                    total: session.items.count, daily: session.daily, onDone: finish)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if let item {
                    question(item)
                        .id(item.id)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    ContentUnavailableView("No questions", systemImage: "questionmark.bubble")
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { finish() } label: { Image(systemName: "xmark").font(.headline) }
                        .accessibilityLabel(Text("Close"))
                }
                ToolbarItem(placement: .principal) {
                    if !showSummary {
                        Text(session.daily ? "Today's 5" : "Practice")
                            .font(.system(.headline, design: .rounded))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .modifier(LargeTextModifier(on: app.largeText))
        .animation(.spring(duration: 0.4), value: index)
        .animation(.spring(duration: 0.4), value: showSummary)
        .sensoryFeedback(trigger: feedback) { _, _ in lastCorrect ? .success : .error }
        .onAppear(perform: setUp)
    }

    /// Daily sessions resume where the person left off.
    private var previousCorrect: Int {
        guard session.daily else { return 0 }
        return session.items.prefix(startedFrom).filter { quiz.progress.todayAnswers[$0.id] == true }.count
    }

    private func setUp() {
        if session.daily {
            startedFrom = session.items.firstIndex { quiz.progress.todayAnswers[$0.id] == nil } ?? session.items.count
            index = startedFrom
            if startedFrom >= session.items.count { showSummary = true }
        }
        switch app.launchScreen {
        case .quizAnswered:
            app.launchScreen = nil
            if let item { answer(item, scam: item.answer == .scam) }
        case .quizResult, .shareCard:
            app.launchScreen = nil
            var step = 0
            while let item = self.item {
                let right = step != 1   // a believable 4/5
                _ = quiz.answer(item, saidScam: right == (item.answer == .scam), daily: session.daily)
                index += 1
                step += 1
            }
            results = session.items.map { quiz.progress.todayAnswers[$0.id] ?? true }
            startedFrom = 0
            showSummary = true
        case .quiz:
            app.launchScreen = nil
        default: break
        }
    }

    private func question(_ item: QuizItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                progressDots
                Text("Scam or legit?")
                    .font(Theme.title(.title))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                if let situation = item.situation {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill").foregroundStyle(Theme.brand)
                        Text(verbatim: situation).font(.body.weight(.medium)).foregroundStyle(Theme.ink)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                MessageMockView(item: item)
                if let said = saidScam {
                    feedbackCard(item, said: said)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                } else {
                    answerButtons(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(session.items.indices, id: \.self) { i in
                Capsule()
                    .fill(i < index ? Theme.brand : (i == index ? Theme.gold : Theme.line))
                    .frame(height: 8)
            }
        }
        .padding(.top, 8)
        .accessibilityElement()
        .accessibilityLabel(Text("Question \(index + 1) of \(session.items.count)"))
    }

    private func answerButtons(_ item: QuizItem) -> some View {
        HStack(spacing: 12) {
            Button { answer(item, scam: true) } label: {
                Label("Scam", systemImage: "hand.raised.fill")
            }
            .buttonStyle(PrimaryButtonStyle(fill: Theme.scamFill))
            Button { answer(item, scam: false) } label: {
                Label("Legit", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(PrimaryButtonStyle(fill: Theme.safeFill))
        }
        .padding(.top, 4)
    }

    private func feedbackCard(_ item: QuizItem, said: Bool) -> some View {
        let correct = (item.answer == .scam) == said
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                Text(correct ? "Correct!" : "Not quite")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                Spacer()
                Text(item.answer == .scam ? "It's a scam" : "It's legit")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((item.answer == .scam ? Theme.scam : Theme.safe).opacity(0.15), in: Capsule())
                    .foregroundStyle(item.answer == .scam ? Theme.scam : Theme.safe)
            }
            .foregroundStyle(correct ? Theme.safe : Theme.scam)
            Text(verbatim: item.explanation)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if correct {
                Text("+\(QuizStore.pointsPerCorrect) points")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.brand)
            }
            Button(index + 1 < session.items.count ? "Next" : "See my score") { next() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
        }
        .card()
        .accessibilityElement(children: .contain)
    }

    private func answer(_ item: QuizItem, scam: Bool) {
        let correct = quiz.answer(item, saidScam: scam, daily: session.daily)
        lastCorrect = correct
        results.append(correct)
        withAnimation(.spring(duration: 0.35)) { saidScam = scam }
        feedback += 1
    }

    private func next() {
        saidScam = nil
        if index + 1 < session.items.count {
            index += 1
        } else {
            showSummary = true
        }
    }

    private func finish() {
        if showSummary && session.daily && results.filter({ $0 }).count >= 4 && app.shouldAskForReview() {
            requestReview()
        }
        onClose()
    }
}

struct QuizSummaryView: View {
    let correct: Int
    let total: Int
    let daily: Bool
    var onDone: () -> Void

    @Environment(QuizStore.self) private var quiz
    @Environment(AppModel.self) private var app
    @State private var ring: Double = 0
    @State private var askedReminder = false
    @State private var confetti = 0

    private var title: LocalizedStringResource {
        switch correct {
        case total: "Sharp eye!"
        case 4...: "Great job!"
        case 3: "Good start"
        default: "Keep practicing"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle().stroke(Theme.line, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: ring)
                        .stroke(Theme.brand, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text(verbatim: "\(correct)/\(total)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text("correct").font(.headline).foregroundStyle(Theme.subtle)
                    }
                }
                .frame(width: 170, height: 170)
                .padding(.top, 16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(correct) of \(total) correct"))

                Text(title).font(Theme.title()).foregroundStyle(Theme.ink)

                if daily {
                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text("\(quiz.currentStreak)-day streak")
                    }
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.14), in: Capsule())
                }

                LevelCard()

                ScoreShareCard(score: correct, total: total, streak: quiz.currentStreak, level: quiz.level)
                    .frame(width: 300, height: 375)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
                    .accessibilityHidden(true)

                ShareScoreButton(score: correct, total: total)

                if daily && !app.reminderOn && !askedReminder {
                    reminderCard
                }

                Button("Done", action: onDone)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1).delay(0.2)) { ring = Double(correct) / Double(max(total, 1)) }
            confetti += 1
        }
        .sensoryFeedback(.success, trigger: confetti)
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Keep your streak going", systemImage: "bell.badge.fill")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("Want a friendly reminder each evening when new messages are ready?")
                .font(.body)
                .foregroundStyle(Theme.subtle)
            HStack(spacing: 10) {
                Button("Remind me") {
                    askedReminder = true
                    app.reminderOn = true
                    Task { await app.updateReminder() }
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("No thanks") { withAnimation { askedReminder = true } }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .card()
    }
}
