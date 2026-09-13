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

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                DashboardView(
                    state: state,
                    onOpenSettings: { showSettings = true },
                    onSeeInsights: { tab = .insights }
                )
                    .opacity(tab == .dashboard ? 1 : 0)
                    .allowsHitTesting(tab == .dashboard)

                DataView(state: state, onOpenSettings: { showSettings = true })
                    .opacity(tab == .data ? 1 : 0)
                    .allowsHitTesting(tab == .data)

                PersonalizedInsightsView(
                    state: state,
                    onOpenSettings: { showSettings = true },
                    isVisible: tab == .insights
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
                .padding(.horizontal, 18)
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
        .padding(.horizontal, 8)
        .frame(height: ShellLayout.tabBarHeight)
        .background(
            ConvexShape(shape: Capsule())
        )
    }

    private func tabButton(_ value: ShellTab, icon: String, title: String) -> some View {
        let selected = tab == value
        return Button {
            tab = value
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(selected ? Neu.accent : Neu.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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
                        .font(Neu.serif(16, weight: .regular))
                        .foregroundStyle(Neu.ink)

                    Spacer()

                    Text(connected ? "Manage" : integration.actionTitle)
                        .font(Neu.serif(13, weight: .regular))
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
                        .font(Neu.serif(26, weight: .regular))
                        .foregroundStyle(Neu.ink)

                    Text(label(for: Int(selectedMinutes.rounded())))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Neu.accent)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Slider(value: $selectedMinutes, in: 0...240, step: 5)
                        .tint(Neu.accent)

                    HStack {
                        Text("Just now")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Neu.muted)
                        Spacer()
                        Text("4 hours")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Neu.muted)
                    }

                    Text("Gemini uses this to tell incomplete recovery apart from true biological age.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Neu.muted)

                    Spacer()

                    Button {
                        onContinue(Int(selectedMinutes.rounded()))
                    } label: {
                        Text("Continue to Scan")
                            .font(Neu.serif(18, weight: .regular))
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
    var isVisible: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShellHeader(title: "Insights") {
                SettingsGearButton(action: onOpenSettings)
            }
            .padding(.horizontal, ShellLayout.horizontalPadding)
            .padding(.top, ShellLayout.topPadding)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if state.isRefreshingCoach {
                        HStack(spacing: 12) {
                            ProgressView()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reading your scan against Health data")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Neu.ink)
                                Text(state.coachStatus ?? "Comparing recovery to your age group…")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(Neu.muted)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
                    } else if let plan = state.latestCoachPlan {
                        hero(plan)
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
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
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
                    } else {
                        readableBlock(
                            kicker: "Ages",
                            title: "Biological \(String(format: "%.1f", state.biologicalAge))",
                            body: state.hasCompletedBaseline
                                ? (
                                    state.biologicalAge < state.chronologicalAge
                                        ? "That’s \(String(format: "%.1f", state.chronologicalAge - state.biologicalAge)) years younger than your real age."
                                        : "A little older than your calendar age right now. Refresh the plan so Gemini can split camera physiology from sleep and steps."
                                )
                                : "Complete a scan to unlock a personalized recovery plan.",
                            tint: Neu.accent
                        )
                        if let status = state.coachStatus {
                            readableBlock(kicker: "Gemini", title: "Couldn’t finish the plan", body: status, tint: Neu.older)
                        }
                    }

                    if state.hasCompletedBaseline {
                        Button {
                            Task { await GeminiCoach.refreshPlan(for: state) }
                        } label: {
                            Text(state.isRefreshingCoach ? "Generating…" : "Refresh Gemini plan")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Neu.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(NeuButtonStyle())
                        .disabled(state.isRefreshingCoach)
                    }
                }
                .padding(.horizontal, ShellLayout.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .task(id: isVisible) {
            guard isVisible else { return }
            if state.hasCompletedBaseline, state.latestCoachPlan == nil, !state.isRefreshingCoach {
                await GeminiCoach.refreshPlan(for: state)
            }
        }
    }

    private func hero(_ plan: CoachPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your read")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Neu.accent)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(plan.headline)
                .font(Neu.serif(26, weight: .regular))
                .foregroundStyle(Neu.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(plan.summary)
                .font(.system(size: 16, weight: .regular, design: .rounded))
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
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Neu.muted)
            Text(String(format: "%.1f", value))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .textCase(.uppercase)
                .tracking(0.7)
            Text(title)
                .font(Neu.serif(20, weight: .regular))
                .foregroundStyle(Neu.ink)
            Text(body)
                .font(.system(size: 15, weight: .regular, design: .rounded))
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Neu.ink)
                Text(driver.note)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
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
                        .font(Neu.serif(20, weight: .regular))
                        .foregroundStyle(Neu.ink)
                }
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(tint)
                            .frame(width: 22, height: 22)
                            .background(tint.opacity(0.15), in: Circle())
                        Text(item)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
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
                    .font(Neu.serif(16, weight: .light))
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
                                    .font(Neu.serif(15, weight: .light))
                                    .italic()
                                    .foregroundStyle(Neu.muted)
                                Text("Real \(fmt(reading.chronologicalAge))  ·  Bio \(fmt(reading.biologicalAge))  ·  Cardiac \(fmt(reading.cardiacAge))  ·  Resp \(fmt(reading.respiratoryAge))")
                                    .font(.body)
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
