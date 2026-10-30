import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Home: paste or screenshot anything -> a traffic-light verdict.
struct CheckView: View {
    @Environment(AppModel.self) private var app
    @Environment(QuizStore.self) private var quiz

    @State private var text = ""
    @State private var context = ""
    @State private var channel: Channel?
    @State private var photoItem: PhotosPickerItem?
    @State private var screenshot: UIImage?
    @State private var uploadData: Data?
    @State private var thumbData: Data?
    @State private var showConsent = false
    @State private var run: CheckDraft?
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showContext = false
    @State private var pasteTick = 0
    @FocusState private var focused: Bool

    private var canCheck: Bool { !text.trimmed.isEmpty || uploadData != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    inputCard
                    channelPicker
                    contextField
                    reportingNote
                    if app.showUpgradeBanner { upgradeBanner }
                    quizTeaser
                    privacyNote
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                checkButton
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .background {
                        LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg, Theme.bg],
                                       startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea(edges: .bottom)
                    }
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        LogoMark(size: 30)
                        Text(verbatim: "ScamSense")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                    }
                    // Room inside the iOS 26 glass capsule the toolbar draws around this item.
                    .padding(.leading, 4)
                    .padding(.trailing, 12)
                    .fixedSize()
                    .accessibilityElement(children: .combine)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill").font(.title3)
                    }
                    .accessibilityLabel(Text("Settings"))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: $run) { draft in
            CheckRunView(draft: draft) { record in
                if record != nil { resetInput() }
                run = nil
            }
        }
        .sheet(isPresented: $showConsent) {
            ConsentSheet {
                app.consentGiven = true
                showConsent = false
                startCheck()
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: .banner) }
        .onChange(of: photoItem) { _, item in loadPhoto(item) }
        .onAppear(perform: applyHooks)
        .sensoryFeedback(.selection, trigger: channel)
        .sensoryFeedback(.success, trigger: pasteTick)
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Is this a scam?")
                .font(Theme.title())
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Paste a text, email, link or phone number. Get a plain answer before you tap.")
                .font(.body)
                .foregroundStyle(Theme.subtle)
            QuotaPill()
        }
        .padding(.top, 6)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Paste or type the message, link, or phone number here…")
                        .font(.body)
                        .foregroundStyle(Theme.subtle.opacity(0.8))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .focused($focused)
                    .accessibilityLabel(Text("Suspicious message"))
                    .accessibilityHint(Text("Type or paste the message you want checked"))
            }
            .padding(10)
            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let screenshot {
                HStack(spacing: 12) {
                    Image(uiImage: screenshot)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screenshot added").font(.headline).foregroundStyle(Theme.ink)
                        Text("It will be checked along with any text.").font(.subheadline).foregroundStyle(Theme.subtle)
                    }
                    Spacer()
                    Button {
                        withAnimation { clearScreenshot() }
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(Theme.subtle)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(Text("Remove screenshot"))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                // PasteButton reads the clipboard only when tapped, with no "Allow Paste" prompt.
                PasteButton(supportedContentTypes: [.plainText, .url, .image]) { providers in
                    handlePaste(providers)
                }
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .controlSize(.large)
                .tint(Theme.brand)
                .labelStyle(.titleAndIcon)

                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    Label("Screenshot", systemImage: "photo.on.rectangle.angled")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(Theme.brand)
                        .background(Theme.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityHint(Text("Choose a screenshot from your photos"))

                if !text.isEmpty {
                    Button {
                        withAnimation { text = "" }
                    } label: {
                        Image(systemName: "trash")
                            .font(.headline)
                            .frame(width: 50, height: 50)
                            .foregroundStyle(Theme.subtle)
                            .background(Theme.cardAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .accessibilityLabel(Text("Clear text"))
                }
            }
        }
        .card(padding: 14)
    }

    private var channelPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Where did it come from?")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
            FlowLayout(spacing: 8) {
                ForEach(Channel.allCases) { item in
                    Button {
                        withAnimation(.spring(duration: 0.25)) { channel = channel == item ? nil : item }
                    } label: {
                        Chip(title: item.label, symbol: item.symbol, selected: channel == item)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(channel == item ? .isSelected : [])
                }
            }
        }
    }

    private var contextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showContext || !context.isEmpty {
                Text("Anything else? (optional)")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.ink)
                TextField(String(localized: "e.g. “They said they're from my bank and asked for a code”"),
                          text: $context, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.body)
                    .padding(14)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))
                    .focused($focused)
                    .onChange(of: context) { _, new in if new.count > 500 { context = String(new.prefix(500)) } }
            } else {
                Button {
                    withAnimation { showContext = true }
                } label: {
                    Label("Add details (optional)", systemImage: "plus.circle.fill")
                        .font(.system(.headline, design: .rounded))
                        .frame(minHeight: 44)
                }
            }
        }
    }

    private var checkButton: some View {
        Button(action: tapCheck) {
            Label("Check it", systemImage: "magnifyingglass")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canCheck)
        .shadow(color: Theme.brand.opacity(canCheck ? 0.3 : 0), radius: 12, y: 6)
        .accessibilityHint(Text("Sends the message to ScamSense for a verdict"))
    }

    private var reportingNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse")
            Text("Reporting tips for \(Text(app.country.label))")
        }
        .font(.footnote)
        .foregroundStyle(Theme.subtle)
    }

    private var upgradeBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.title)
                .foregroundStyle(Theme.gold)
            VStack(alignment: .leading, spacing: 6) {
                Text("Protect your whole family")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                Text("5 checks a day, full history and ready-made family warnings with Pro.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Button("See Pro") { showPaywall = true }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 40)
                    .background(.white, in: Capsule())
                    .foregroundStyle(Theme.brandDeep)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            Button {
                withAnimation { app.bannerDismissed = true }
            } label: {
                Image(systemName: "xmark").font(.subheadline.weight(.bold)).foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 36, height: 36)
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(16)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var quizTeaser: some View {
        Button {
            app.tab = .quiz
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.2)).frame(width: 54, height: 54)
                    Image(systemName: quiz.todayDone ? "checkmark.seal.fill" : "flame.fill")
                        .font(.title2)
                        .foregroundStyle(quiz.todayDone ? Theme.safe : Color.orange)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Spot the Scam")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    if quiz.todayDone {
                        Text("Done for today: \(quiz.todayCorrect)/5 · \(quiz.currentStreak)-day streak")
                            .font(.subheadline).foregroundStyle(Theme.subtle)
                    } else {
                        Text("Today's 5 questions are ready. Free, 2 minutes.")
                            .font(.subheadline).foregroundStyle(Theme.subtle)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(Theme.subtle)
            }
            .card(padding: 14)
        }
        .buttonStyle(PressableStyle())
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield")
            Text("ScamSense never opens links from your message. Your history stays on this iPhone.")
        }
        .font(.footnote)
        .foregroundStyle(Theme.subtle)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions

    private func tapCheck() {
        focused = false
        guard canCheck else { return }
        if app.consentGiven { startCheck() } else { showConsent = true }
    }

    private func startCheck() {
        run = CheckDraft(text: text, image: uploadData, thumbnail: thumbData, channel: channel, context: context)
    }

    private func resetInput() {
        text = ""
        context = ""
        channel = nil
        showContext = false
        clearScreenshot()
    }

    private func clearScreenshot() {
        screenshot = nil
        uploadData = nil
        thumbData = nil
        photoItem = nil
    }

    private func handlePaste(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: UIImage.self) {
                _ = provider.loadObject(ofClass: UIImage.self) { object, _ in
                    guard let image = object as? UIImage else { return }
                    Task { @MainActor in setScreenshot(image) }
                }
                return
            }
            if provider.canLoadObject(ofClass: String.self) {
                _ = provider.loadObject(ofClass: String.self) { value, _ in
                    guard let value else { return }
                    Task { @MainActor in
                        text = String(value.prefix(6000))
                        pasteTick += 1
                    }
                }
                return
            }
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { value, _ in
                    guard let value else { return }
                    Task { @MainActor in
                        text = value.absoluteString
                        pasteTick += 1
                    }
                }
                return
            }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            setScreenshot(image)
        }
    }

    private func setScreenshot(_ image: UIImage) {
        withAnimation {
            screenshot = image
            uploadData = ImageTools.uploadJPEG(from: image)
            thumbData = ImageTools.thumbnail(from: image)
        }
        pasteTick += 1
    }

    private func applyHooks() {
        if let prefill = app.prefill {
            text = prefill
            channel = .sms
            app.prefill = nil
        }
        if app.autoCheck, canCheck {
            app.autoCheck = false
            run = CheckDraft(text: text, channel: channel, context: "")
        }
        switch app.launchScreen {
        case .settings: showSettings = true
        case .consent: showConsent = true
        case .paywall: showPaywall = true
        case .waiting, .result:
            if text.isEmpty { text = Self.demoText }
            channel = .sms
            run = CheckDraft(text: text, channel: channel, context: "")
        default: return
        }
        app.launchScreen = nil
    }

    static var demoText: String {
        AppConfig.language == "ko"
            ? "[Web발신] 고객님 택배가 주소지 불명으로 보관중입니다. 주소 확인: http://kr-parcel.top/x8"
            : "Toll Services: Your vehicle has an unpaid toll balance of $6.99. To avoid a $50 late fee, pay by today: https://tollpay-renew.top/us"
    }
}

/// "1 of 2 free checks left this week" / "Pro · 5 checks a day".
struct QuotaPill: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        HStack(spacing: 8) {
            if app.isPro {
                Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                Text("Pro · 5 checks a day")
            } else if let q = app.quota {
                Image(systemName: q.remaining > 0 ? "checkmark.circle.fill" : "hourglass")
                    .foregroundStyle(q.remaining > 0 ? Theme.safe : Theme.warn)
                Text("\(q.remaining) of \(q.limit) free checks left this week")
            } else {
                Image(systemName: "gift.fill").foregroundStyle(Theme.brand)
                Text("2 free checks every week")
            }
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
