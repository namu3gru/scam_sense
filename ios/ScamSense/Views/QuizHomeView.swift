import SwiftUI

struct QuizSession: Identifiable {
    let id = UUID()
    let items: [QuizItem]
    let daily: Bool
}

struct QuizHomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(QuizStore.self) private var quiz
    @State private var session: QuizSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Spot the Scam")
                            .font(Theme.title())
                            .foregroundStyle(Theme.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("Five quick, real-looking messages a day. Train your eye so scammers can't fool you.")
                            .font(.body)
                            .foregroundStyle(Theme.subtle)
                    }
                    .padding(.top, 6)
                    LevelCard()
                    todayCard
                    statsRow
                    howItWorks
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: $session) { s in
            QuizPlayView(session: s) { session = nil }
        }
        .onAppear {
            quiz.ensureToday()
            switch app.launchScreen {
            case .quiz, .quizAnswered, .quizResult, .shareCard:
                session = QuizSession(items: quiz.today, daily: true)
            default: break
            }
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Today's challenge", systemImage: "calendar")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(quiz.todayAnsweredCount)/5")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    let answered = i < quiz.todayAnsweredCount
                    Capsule()
                        .fill(answered ? Theme.gold : .white.opacity(0.25))
                        .frame(height: 8)
                }
            }
            .accessibilityHidden(true)
            if quiz.todayDone {
                Text("Nice work! You got \(quiz.todayCorrect) of 5 today. New messages tomorrow.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                HStack(spacing: 10) {
                    ShareScoreButton(score: quiz.todayCorrect, total: 5)
                    Button {
                        session = QuizSession(items: quiz.practiceSet(), daily: false)
                    } label: {
                        Label("Practice more", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(PrimaryButtonStyle(fill: .white, foreground: Theme.brandDeep))
                }
            } else {
                Text(quiz.todayAnsweredCount == 0
                     ? "Can you tell a scam from the real thing? Takes about 2 minutes."
                     : "You're partway through. Finish to keep your streak!")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                Button {
                    quiz.ensureToday()
                    session = QuizSession(items: quiz.today, daily: true)
                } label: {
                    Label(quiz.todayAnsweredCount == 0 ? "Start today's 5" : "Continue", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle(fill: Theme.gold, foreground: Theme.brandDeep))
            }
        }
        .padding(18)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            stat(value: "\(quiz.currentStreak)", label: "Day streak", symbol: "flame.fill", color: .orange)
            stat(value: "\(quiz.progress.bestStreak)", label: "Best streak", symbol: "trophy.fill", color: Theme.gold)
            stat(value: "\(quiz.accuracy)%", label: "Accuracy", symbol: "scope", color: Theme.safe)
        }
    }

    private func stat(value: String, label: LocalizedStringResource, symbol: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3).foregroundStyle(color)
            Text(verbatim: value)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.7)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Theme.subtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line.opacity(0.7), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How levels work").sectionTitle()
            ForEach(QuizLevel.allCases, id: \.self) { level in
                HStack(spacing: 12) {
                    Image(systemName: level.symbol)
                        .foregroundStyle(level.rawValue <= quiz.level.rawValue ? Theme.brand : Theme.subtle.opacity(0.5))
                        .frame(width: 30)
                    Text(level.title).font(.headline).foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(level.floor) pts").font(.subheadline.monospacedDigit()).foregroundStyle(Theme.subtle)
                }
                .frame(minHeight: 36)
            }
            Text("10 points for each right answer, plus a bonus for a perfect day. Free forever.")
                .font(.footnote)
                .foregroundStyle(Theme.subtle)
        }
        .card()
    }
}

struct LevelCard: View {
    @Environment(QuizStore.self) private var quiz

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Theme.line, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: quiz.levelProgress)
                    .stroke(Theme.brand, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: quiz.level.symbol).font(.title2).foregroundStyle(Theme.brand)
            }
            .frame(width: 66, height: 66)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Your level").font(.caption.weight(.semibold)).foregroundStyle(Theme.subtle).textCase(.uppercase)
                Text(quiz.level.title).font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(Theme.ink)
                if let left = quiz.pointsToNext, let next = quiz.level.next {
                    Text("\(quiz.progress.points) pts · \(left) to \(Text(next.title))")
                        .font(.subheadline).foregroundStyle(Theme.subtle)
                } else {
                    Text("\(quiz.progress.points) pts · Top level reached!")
                        .font(.subheadline).foregroundStyle(Theme.subtle)
                }
            }
            Spacer(minLength: 0)
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}
