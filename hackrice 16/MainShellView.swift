//
//  MainShellView.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

enum ShellTab: Hashable {
    case dashboard
    case data
    case insights
    case history
    case add
}

struct MainShellView: View {
    var state: UserRecoveryState
    var onLogOut: () -> Void

    @State private var tab: ShellTab = .dashboard
    @State private var showSettings = false
    @State private var insightsOpenCount = 0
    @State private var scanRequestCount = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                DashboardView(
                    state: state,
                    onOpenSettings: { showSettings = true },
                    onSeeInsights: { openInsights() },
                    scanRequestCount: scanRequestCount
                )
                    .opacity(tab == .dashboard ? 1 : 0)
                    .allowsHitTesting(tab == .dashboard)

                DataView(state: state, onOpenSettings: { showSettings = true })
                    .opacity(tab == .data ? 1 : 0)
                    .allowsHitTesting(tab == .data)

                PersonalizedInsightsView(
                    state: state,
                    onOpenSettings: { showSettings = true },
                    onOpenRoute: openRoute,
                    isVisible: tab == .insights,
                    openCount: insightsOpenCount
                )
                    .opacity(tab == .insights ? 1 : 0)
                    .allowsHitTesting(tab == .insights)

                HistoryView(state: state, onOpenSettings: { showSettings = true })
                    .opacity(tab == .history ? 1 : 0)
                    .allowsHitTesting(tab == .history)

                AddSourcesView(state: state, onOpenSettings: { showSettings = true })
                    .opacity(tab == .add ? 1 : 0)
                    .allowsHitTesting(tab == .add)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .background(Neu.canvas.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.18), value: tab)
        .sheet(isPresented: $showSettings) {
            SettingsView(state: state, onLogOut: onLogOut)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.dashboard, icon: "house.fill", title: "Dash")
            tabButton(.data, icon: "chart.xyaxis.line", title: "Data")
            tabButton(.insights, icon: "sparkles", title: "Insights")
            tabButton(.history, icon: "clock", title: "History")
            tabButton(.add, icon: "plus", title: "Add")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(height: 72)
        .background(
            ConvexShape(shape: Capsule())
        )
    }

    private func tabButton(_ value: ShellTab, icon: String, title: String) -> some View {
        let selected = tab == value
        let isInsights = value == .insights
        return Button {
            if value == .insights {
                openInsights()
            } else {
                tab = value
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isInsights {
                        Circle()
                            .fill(selected ? Neu.accent.opacity(0.32) : Neu.accent.opacity(0.18))
                            .frame(width: 38, height: 38)
                    }
                    Image(systemName: icon)
                        .font(.system(size: isInsights ? 17 : 18, weight: .semibold))
                        .foregroundStyle(isInsights || selected ? Neu.accent : Neu.muted)
                        .symbolEffect(.pulse, options: .repeating.speed(0.35), isActive: isInsights && !selected)
                }
                Text(isInsights ? "AI" : title)
                    .font(Neu.tab(prominent: isInsights))
                    .foregroundStyle(isInsights || selected ? Neu.accent : Neu.muted.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isInsights ? "Insights AI" : title)
    }

    private func openInsights() {
        insightsOpenCount += 1
        tab = .insights
    }

    private func openRoute(_ route: RoadrunnerRoute) {
        switch route {
        case .dash:
            tab = .dashboard
        case .data:
            tab = .data
        case .insights:
            openInsights()
        case .history:
            tab = .history
        case .add:
            tab = .add
        case .settings:
            showSettings = true
        case .scan:
            tab = .dashboard
            scanRequestCount += 1
        }
    }
}

struct AddSourcesView: View {
    var state: UserRecoveryState
    var onOpenSettings: () -> Void = {}

    @State private var selected: DataIntegration?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ShellHeader(title: "Add") {
                SettingsGearButton(action: onOpenSettings)
            }

            VStack(spacing: 12) {
                ForEach(DataIntegration.allCases) { integration in
                    integrationRow(integration)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ShellLayout.horizontalPadding)
        .padding(.top, ShellLayout.topPadding)
        .sheet(item: $selected) { integration in
            DeviceLinkView(state: state, integration: integration)
        }
    }

    private func integrationRow(_ integration: DataIntegration) -> some View {
        let connected = state.isConnected(integration)

        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            selected = integration
        } label: {
                HStack(spacing: 14) {
                    Image(systemName: integration.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(connected ? Neu.accent : Neu.ink)
                        .frame(width: 28)

                    Text(integration.title)
                        .font(Neu.heading(16))
                        .italic()
                        .foregroundStyle(Neu.ink)

                    Spacer()

                    Text(connected ? "Manage" : integration.actionTitle)
                        .font(Neu.body(13))
                        .foregroundStyle(connected ? Neu.accent : Neu.muted)
                }
            .padding(16)
            .background(
                ConvexShape(
                    shape: RoundedRectangle(cornerRadius: 20, style: .continuous),
                    isPressed: connected
                )
            )
        }
        .buttonStyle(.plain)
    }
}

struct AerobicRecencySheet: View {
    var onContinue: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Double = 30

    var body: some View {
        NavigationStack {
            ZStack {
                Neu.canvas.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    Text("Time After Workout")
                        .font(Neu.heading(26))
                        .foregroundStyle(Neu.ink)

                    Text(label(for: Int(selectedMinutes.rounded())))
                        .font(Neu.number(28))
                        .foregroundStyle(Neu.accent)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Slider(value: $selectedMinutes, in: 0...240, step: 5)
                        .tint(Neu.accent)

                    HStack {
                        Text("Just now")
                            .font(Neu.body(13))
                            .foregroundStyle(Neu.muted)
                        Spacer()
                        Text("4 hours")
                            .font(Neu.body(13))
                            .foregroundStyle(Neu.muted)
                    }

                    Text("Gemini uses this to tell incomplete recovery apart from true biological age.")
                        .font(Neu.body())
                        .foregroundStyle(Neu.muted)

                    Spacer()

                    Button {
                        onContinue(Int(selectedMinutes.rounded()))
                    } label: {
                        Text("Continue to Scan")
                            .font(Neu.heading(18))
                            .foregroundStyle(Neu.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(NeuButtonStyle())
                }
                .padding(22)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func label(for minutes: Int) -> String {
        if minutes == 0 { return "Just now" }
        if minutes < 60 { return "\(minutes) minutes ago" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        return "\(hours) hr \(remainder) min ago"
    }
}

struct PersonalizedInsightsView: View {
    var state: UserRecoveryState
    var onOpenSettings: () -> Void = {}
    var onOpenRoute: (RoadrunnerRoute) -> Void = { _ in }
    var isVisible: Bool = true
    var openCount: Int = 0

    @State private var roadrunnerDraft = ""
    @FocusState private var roadrunnerFocused: Bool
    @State private var planJumpCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShellHeader(title: "Insights") {
                SettingsGearButton(action: onOpenSettings)
            }
            .padding(.horizontal, ShellLayout.horizontalPadding)
            .padding(.top, ShellLayout.topPadding)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Color.clear
                            .frame(height: 1)
                            .id("insightsTop")

                        refreshCard
                        roadrunnerCard

                        if state.isRefreshingCoach {
                            HStack(spacing: 12) {
                                ProgressView()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Writing a new plan")
                                        .font(Neu.button(16))
                                        .foregroundStyle(Neu.ink)
                                    Text(state.coachStatus ?? "Gemini is reading your latest scan…")
                                        .font(Neu.body(14))
                                        .foregroundStyle(Neu.muted)
                                }
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
                        }

                        if let plan = state.latestCoachPlan {
                            hero(plan)
                                .id("insightsPlan")
                            agesRow(plan)
                            readableBlock(
                                kicker: "Scan vs wearables",
                                title: "What the camera saw, vs Apple Health / Garmin",
                                body: plan.scanVsLifestyle,
                                tint: Neu.accent
                            )
                            if !plan.studyNotes.isEmpty {
                                readableBlock(
                                    kicker: "Studies & your age group",
                                    title: plan.ageGroup.isEmpty ? "Recovery baseline" : "Age group \(plan.ageGroup)",
                                    body: [plan.recoveryWindow, plan.studyNotes].filter { !$0.isEmpty }.joined(separator: "\n\n"),
                                    tint: Color(red: 0.55, green: 0.45, blue: 0.28)
                                )
                            }
                            if !plan.drivers.isEmpty {
                                Text("What’s moving the number")
                                    .font(Neu.label(13))
                                    .foregroundStyle(Neu.muted)
                                    .textCase(.uppercase)
                                    .tracking(0.6)
                                ForEach(Array(plan.drivers.enumerated()), id: \.offset) { _, driver in
                                    driverRow(driver)
                                }
                            }
                            planSection(title: "Do this today", symbol: "sun.max.fill", tint: Color.orange, items: plan.today)
                            planSection(title: "This week", symbol: "calendar", tint: Neu.accent, items: plan.thisWeek)
                            planSection(title: "Training", symbol: "figure.run", tint: Color(red: 0.86, green: 0.38, blue: 0.40), items: plan.training)
                            planSection(title: "Recovery", symbol: "moon.zzz.fill", tint: Color(red: 0.35, green: 0.55, blue: 0.86), items: plan.recovery)
                            planSection(title: "Long-term improvement", symbol: "chart.line.uptrend.xyaxis", tint: Neu.younger, items: plan.longTerm)
                            planSection(title: "Recommended supplements", symbol: "pills.fill", tint: Color(red: 0.55, green: 0.45, blue: 0.28), items: plan.supplements)
                            if let caution = plan.caution, !caution.isEmpty {
                                readableBlock(kicker: "Keep in mind", title: "Not a diagnosis", body: caution, tint: Neu.older)
                            }
                        } else if !state.isRefreshingCoach {
                            readableBlock(
                                kicker: "Plan",
                                title: state.hasCompletedBaseline ? "No Gemini plan yet" : "Scan first",
                                body: state.hasCompletedBaseline
                                    ? "Tap Repopulate Insights to generate a plan from your latest scan. Opening this page will not spend tokens on its own."
                                    : "Complete a scan to unlock a personalized recovery plan.",
                                tint: Neu.accent
                            )
                            .id("insightsPlan")
                            if let status = state.coachStatus {
                                readableBlock(kicker: "Gemini", title: "Couldn’t finish the plan", body: status, tint: Neu.older)
                            }
                        }
                    }
                    .padding(.horizontal, ShellLayout.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isVisible) { _, visible in
                    if visible {
                        scrollToTop(proxy)
                    } else {
                        resetRoadrunnerSession()
                    }
                }
                .onChange(of: openCount) { _, _ in
                    guard isVisible else { return }
                    scrollToTop(proxy)
                }
                .onChange(of: planJumpCount) { _, _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("insightsPlan", anchor: .top)
                    }
                }
            }
        }
    }

    private var refreshCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last updated")
                .font(Neu.label(12))
                .foregroundStyle(Neu.accent)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(lastUpdatedText)
                .font(Neu.heading(22))
                .italic()
                .foregroundStyle(Neu.ink)
            Text(accuracyNote)
                .font(Neu.body())
                .foregroundStyle(Neu.ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            if state.hasCompletedBaseline {
                Button {
                    Task { await GeminiCoach.refreshPlan(for: state) }
                } label: {
                    Text(state.isRefreshingCoach ? "Generating…" : "Repopulate Insights")
                        .font(Neu.button(17))
                        .foregroundStyle(Neu.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(NeuButtonStyle())
                .disabled(state.isRefreshingCoach)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
    }

    private var roadrunnerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                RoadrunnerMark(size: 30)
                Text("ask")
                    .font(Neu.display(20))
                    .italic()
                    .foregroundStyle(Neu.ink)
                BrandWordmark(kind: .roadrunner, size: 20)
            }
            Text("Ask where something lives, or why a number moved. Finding a screen is free. Gemini answers are limited to \(UserRecoveryState.roadrunnerDailyLimit) a day.")
                .font(Neu.body(14))
                .foregroundStyle(Neu.muted)
                .fixedSize(horizontal: false, vertical: true)

            if state.roadrunnerMessages.isEmpty {
                Text("Try “Where are my ages?” or “What should I do tonight?”")
                    .font(Neu.body(13))
                    .foregroundStyle(Neu.muted.opacity(0.9))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(state.roadrunnerMessages.suffix(8))) { message in
                        roadrunnerBubble(message)
                    }
                }
            }

            if state.isAskingRoadrunner {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("roadrunner is checking your scan…")
                        .font(Neu.body(13))
                        .foregroundStyle(Neu.muted)
                }
            }

            if let status = state.roadrunnerStatus, !state.isAskingRoadrunner {
                Text(status)
                    .font(Neu.body(13))
                    .foregroundStyle(Neu.older)
            } else if state.hasCompletedBaseline {
                Text(quotaCopy)
                    .font(Neu.body(12))
                    .foregroundStyle(Neu.muted.opacity(0.9))
            }

            HStack(spacing: 10) {
                TextField("ask roadruner", text: $roadrunnerDraft, axis: .vertical)
                    .font(Neu.body(16))
                    .foregroundStyle(Neu.ink)
                    .lineLimit(1...3)
                    .focused($roadrunnerFocused)
                    .submitLabel(.send)
                    .onSubmit { sendRoadrunner() }
                    .disabled(state.isAskingRoadrunner)

                Button {
                    sendRoadrunner()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(Neu.number(28))
                        .foregroundStyle(canSendRoadrunner ? Neu.accent : Neu.muted.opacity(0.45))
                }
                .buttonStyle(.plain)
                .disabled(!canSendRoadrunner)
                .accessibilityLabel("Send")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ConvexShape(
                    shape: RoundedRectangle(cornerRadius: 18, style: .continuous),
                    isPressed: true
                )
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
    }

    private var quotaCopy: String {
        let left = state.roadrunnerAsksRemaining
        if left == 0 {
            return "Gemini questions are used up for today. You can still ask where something is."
        }
        if left == 1 {
            return "1 Gemini question left today"
        }
        return "\(left) Gemini questions left today"
    }

    private func resetRoadrunnerSession() {
        roadrunnerDraft = ""
        roadrunnerFocused = false
        planJumpCount = 0
        state.roadrunnerGeneration += 1
        state.roadrunnerMessages = []
        state.roadrunnerStatus = nil
        state.isAskingRoadrunner = false
    }

    private var canSendRoadrunner: Bool {
        !state.isAskingRoadrunner
            && !roadrunnerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendRoadrunner() {
        let question = roadrunnerDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSendRoadrunner else { return }
        roadrunnerDraft = ""
        roadrunnerFocused = false
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        Task { await GeminiCoach.askRoadrunner(question, for: state) }
    }

    @ViewBuilder
    private func roadrunnerBubble(_ message: RoadrunnerMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 28) }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                roadrunnerText(message)
                    .font(Neu.body())
                    .foregroundStyle(Neu.ink)
                    .multilineTextAlignment(message.isUser ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
                    .background(
                        ConvexShape(
                            shape: RoundedRectangle(cornerRadius: 16, style: .continuous),
                            isPressed: message.isUser
                        )
                    )
                if let route = message.route, !message.isUser {
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        if route == .insights {
                            planJumpCount += 1
                        } else {
                            onOpenRoute(route)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(route.buttonTitle)
                            Image(systemName: "arrow.up.right")
                        }
                        .font(Neu.label(14))
                        .foregroundStyle(Neu.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            if !message.isUser { Spacer(minLength: 28) }
        }
    }

    private func roadrunnerText(_ message: RoadrunnerMessage) -> Text {
        guard !message.isUser else { return Text(message.text) }
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let attributed = try? AttributedString(markdown: message.text, options: options) {
            return Text(attributed)
        }
        return Text(message.text)
    }

    private var lastUpdatedText: String {
        guard let plan = state.latestCoachPlan else {
            return "Not generated yet"
        }
        return plan.generatedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var accuracyNote: String {
        if !state.hasCompletedBaseline {
            return "Insights stay empty until you complete a scan."
        }
        if state.latestCoachPlan == nil {
            return "Repopulate Insights to generate a plan. This page will not call Gemini until you do."
        }
        if let scan = state.latestScan,
           let plan = state.latestCoachPlan,
           scan.capturedAt > plan.generatedAt.addingTimeInterval(2) {
            return "A newer scan is in. Repopulate Insights so this plan matches it."
        }
        return "Repopulate Insights after a scan or Health changes. Opening this page will not refresh the plan on its own."
    }

    private func scrollToTop(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo("insightsTop", anchor: .top)
        }
    }

    private func hero(_ plan: CoachPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your read")
                .font(Neu.label(12))
                .foregroundStyle(Neu.accent)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(plan.headline)
                .font(Neu.display(26))
                .italic()
                .foregroundStyle(Neu.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(plan.summary)
                .font(Neu.body(16))
                .foregroundStyle(Neu.ink.opacity(0.82))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 24, style: .continuous)))
    }

    private func agesRow(_ plan: CoachPlan) -> some View {
        HStack(spacing: 10) {
            ageChip("Calendar", value: state.chronologicalAge)
            ageChip("Scan", value: plan.scanImpliedAge ?? state.cardiacAge)
            ageChip("Health", value: plan.lifestyleImpliedAge ?? Double(state.garminData.restingHeartRate > 0 ? state.chronologicalAge : state.biologicalAge))
            ageChip("Combined", value: plan.adjustedBiologicalAge ?? state.biologicalAge)
        }
    }

    private func ageChip(_ label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Neu.emphasis(11))
                .foregroundStyle(Neu.muted)
            Text(String(format: "%.1f", value))
                .font(Neu.number(18))
                .foregroundStyle(Neu.ink)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 16, style: .continuous)))
    }

    private func readableBlock(kicker: String, title: String, body: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kicker)
                .font(Neu.label(11))
                .foregroundStyle(tint)
                .textCase(.uppercase)
                .tracking(0.7)
            Text(title)
                .font(Neu.heading(20))
                .italic()
                .foregroundStyle(Neu.ink)
            Text(body)
                .font(Neu.body())
                .foregroundStyle(Neu.ink.opacity(0.8))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
    }

    private func driverRow(_ driver: CoachDriver) -> some View {
        let color: Color = {
            switch driver.impact.lowercased() {
            case "helping": return Neu.younger
            case "hurting": return Neu.older
            default: return Neu.muted
            }
        }()
        return HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.factor)
                    .font(Neu.button(16))
                    .foregroundStyle(Neu.ink)
                Text(driver.note)
                    .font(Neu.body(14))
                    .foregroundStyle(Neu.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 18, style: .continuous)))
    }

    private func planSection(title: String, symbol: String, tint: Color, items: [String]) -> some View {
        guard !items.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                    Text(title)
                        .font(Neu.heading(20))
                        .italic()
                        .foregroundStyle(Neu.ink)
                }
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(Neu.label(13))
                            .foregroundStyle(tint)
                            .frame(width: 22, height: 22)
                            .background(tint.opacity(0.15), in: Circle())
                        Text(item)
                            .font(Neu.body())
                            .foregroundStyle(Neu.ink.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
        )
    }
}

struct HistoryView: View {
    var state: UserRecoveryState
    var onOpenSettings: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: ShellLayout.pageSpacing) {
            ShellHeader(title: "History") {
                SettingsGearButton(action: onOpenSettings)
            }

            if state.ageHistory.isEmpty && state.scanHistory.isEmpty {
                Spacer(minLength: 0)
                Text("Scans you complete will land here and stay stored.")
                    .font(Neu.serif(16))
                    .italic()
                    .foregroundStyle(Neu.muted)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(state.ageHistory.reversed()) { reading in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(reading.date, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                                    .font(Neu.serif(15))
                                    .italic()
                                    .foregroundStyle(Neu.muted)
                                Text("Real \(fmt(reading.chronologicalAge))  ·  Bio \(fmt(reading.biologicalAge))  ·  Cardiac \(fmt(reading.cardiacAge))  ·  Resp \(fmt(reading.respiratoryAge))")
                                    .font(Neu.body())
                                    .foregroundStyle(Neu.ink)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.horizontal, ShellLayout.horizontalPadding)
        .padding(.top, ShellLayout.topPadding)
    }

    private func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

#Preview {
    @Previewable @State var state = UserRecoveryState.mock
    MainShellView(state: state, onLogOut: {})
}
