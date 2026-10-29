import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var app
    @Environment(HistoryStore.self) private var history
    @State private var filter: Verdict?
    @State private var showPaywall = false
    @State private var confirmClear = false
    @State private var path: [CheckRecord] = []

    private var filtered: [CheckRecord] {
        history.records.filter { filter == nil || $0.result.verdict == filter }
    }

    private var visible: [CheckRecord] {
        app.isPro ? filtered : Array(filtered.prefix(HistoryStore.freeVisible))
    }

    private var hiddenCount: Int { filtered.count - visible.count }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if history.records.isEmpty {
                    empty
                } else {
                    list
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(Text("History"))
            .toolbar {
                if !history.records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Clear all history", systemImage: "trash", role: .destructive) { confirmClear = true }
                        } label: {
                            Image(systemName: "ellipsis.circle").font(.title3)
                        }
                        .accessibilityLabel(Text("More"))
                    }
                }
            }
            .alert(Text("Delete all checks on this iPhone?"), isPresented: $confirmClear) {
                Button("Delete all", role: .destructive) { history.clear() }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(for: CheckRecord.self) { record in
                ResultView(record: record, fresh: false)
                    .toolbar(.hidden, for: .navigationBar)
                    .overlay(alignment: .topLeading) {
                        Button { if !path.isEmpty { path.removeLast() } } label: {
                            Label("History", systemImage: "chevron.left")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(Theme.brandDeep)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 44)
                                .background(.white, in: Capsule())
                                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 2)
                        .accessibilityLabel(Text("Back to history"))
                    }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: .feature) }
        .onAppear { if UserDefaults.standard.bool(forKey: "uiConfirmClear") { confirmClear = true } }
        .onAppear {
            if app.launchScreen == .historyDetail, let first = history.records.first {
                app.launchScreen = nil
                path = [first]
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 18) {
            Image(systemName: "tray")
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(Theme.brand.opacity(0.6))
            Text("No checks yet")
                .font(Theme.title(.title2))
                .foregroundStyle(Theme.ink)
            Text("When you check a message, the result is saved here on your iPhone so you can find it again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.subtle)
            Button("Check a message") { app.tab = .check }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 300)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            Section {
                filterBar
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            Section {
                ForEach(visible) { record in
                    NavigationLink(value: record) { HistoryRow(record: record) }
                        .listRowBackground(Theme.card)
                }
                .onDelete { offsets in
                    history.delete(Set(offsets.map { visible[$0].id }))
                }
                if hiddenCount > 0 {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill").foregroundStyle(Theme.gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(hiddenCount) older checks").font(.headline).foregroundStyle(Theme.ink)
                                Text("Pro keeps your full history.").font(.subheadline).foregroundStyle(Theme.subtle)
                            }
                            Spacer()
                            Text("Unlock").font(.headline).foregroundStyle(Theme.brand)
                        }
                        .frame(minHeight: 52)
                    }
                    .listRowBackground(Theme.card)
                }
            } footer: {
                Text("Saved only on this iPhone.")
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { filter = nil } label: {
                    Chip(title: "All", symbol: "line.3.horizontal.decrease", selected: filter == nil)
                }
                ForEach(Verdict.allCases, id: \.self) { v in
                    Button { filter = filter == v ? nil : v } label: {
                        Chip(title: v.label, symbol: v.symbol, selected: filter == v)
                    }
                }
            }
            .buttonStyle(PressableStyle())
        }
        .sensoryFeedback(.selection, trigger: filter)
    }
}

struct HistoryRow: View {
    let record: CheckRecord

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(record.result.verdict.headerFill)
                    .frame(width: 52, height: 52)
                Text(verbatim: "\(record.result.riskScore)")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(record.result.verdict.headerText)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    VerdictChip(verdict: record.result.verdict)
                    if let channel = record.channel {
                        Image(systemName: channel.symbol).font(.caption).foregroundStyle(Theme.subtle)
                    }
                    Spacer(minLength: 0)
                    Text(record.date, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(Theme.subtle)
                }
                if record.result.hasScamType {
                    Text(verbatim: record.result.scamType)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                }
                Text(verbatim: record.preview)
                    .font(.subheadline)
                    .foregroundStyle(Theme.subtle)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
