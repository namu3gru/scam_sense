import SwiftUI

@main
struct ScamSenseApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(app.store)
                .environment(app.quiz)
                .environment(app.history)
                .task { await app.start() }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            if app.onboarded && app.launchScreen != .onboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: app.onboarded)
        .modifier(LargeTextModifier(on: app.largeText))
        .tint(Theme.brand)
    }
}

struct MainTabView: View {
    @Environment(AppModel.self) private var app
    @Environment(QuizStore.self) private var quiz

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.tab) {
            Tab("Check", systemImage: "checkmark.shield.fill", value: AppTab.check) {
                CheckView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView()
            }
            Tab("Quiz", systemImage: "questionmark.bubble.fill", value: AppTab.quiz) {
                QuizHomeView()
            }
            .badge(quiz.todayDone ? 0 : 1)
            Tab("Learn", systemImage: "book.fill", value: AppTab.learn) {
                LearnView()
            }
            Tab("Family", systemImage: "heart.circle.fill", value: AppTab.family) {
                FamilyView()
            }
        }
    }
}
