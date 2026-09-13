//
//  DataView.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

private enum DataAgeKind: Int, CaseIterable, Identifiable {
    case cardiac
    case biological
    case pulmonary

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .cardiac: "Cardiac Age"
        case .biological: "Biological Age"
        case .pulmonary: "Pulmonary Age"
        }
    }

    var color: Color {
        switch self {
        case .cardiac: Color(red: 0.86, green: 0.38, blue: 0.40)
        case .biological: Neu.accent
        case .pulmonary: Color(red: 0.35, green: 0.55, blue: 0.86)
        }
    }
}

private struct SnapshotStat: Identifiable {
    var id: String
    var title: String
    var value: String
    var unit: String
    var meaning: String
    var meaningColor: Color
}

struct DataView: View {
    var state: UserRecoveryState
    var onOpenSettings: () -> Void = {}

    @State private var selected: DataAgeKind = .biological
    @State private var dragOffset: CGFloat = 0
    @State private var jumpingIDs: Set<Int> = []
    @State private var showTelemetry = false

    private let sideSize: CGFloat = 82
    private let centerSize: CGFloat = 152
    private let spacing: CGFloat = 12

    private var travel: CGFloat {
        (centerSize + sideSize) / 2 + spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShellHeader(title: "Data") {
                SettingsGearButton(action: onOpenSettings)
            }
                .padding(.horizontal, ShellLayout.horizontalPadding)
                .padding(.top, ShellLayout.topPadding)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        carousel
                            .frame(height: centerSize)
                            .padding(.top, 12)

                        pageDots

                        if state.hasCompletedBaseline {
                            selectedDeltaCard
                            compareSection
                            snapshotSection
                            yearsSection
                        }

                        telemetryButton

                        Button {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                proxy.scrollTo("methodology", anchor: .top)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text("See How We Got This Information")
                                    .font(Neu.serif(16))
                                    .italic()
                                    .foregroundStyle(Neu.ink)
                                    .multilineTextAlignment(.center)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Neu.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                        .buttonStyle(.plain)

                        methodologySection
                            .id("methodology")
                            .padding(.top, 24)
                    }
                    .padding(.horizontal, ShellLayout.horizontalPadding)
                    .padding(.bottom, 12)
                }
            }
        }
        .sheet(isPresented: $showTelemetry) {
            ContextLoggingView(state: state)
        }
    }

    private var carousel: some View {
        ZStack {
            ForEach(DataAgeKind.allCases) { kind in
                let slot = slot(for: kind)
                ageCircle(kind, size: slot == 0 ? centerSize : sideSize, isPrimary: slot == 0)
                    .offset(x: xOffset(for: slot) + dragOffset * dragFactor(for: slot))
                    .zIndex(slot == 0 ? 2 : 1)
                    .transaction { transaction in
                        if jumpingIDs.contains(kind.id) {
                            transaction.animation = nil
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .highPriorityGesture(dragGesture)
    }

    private var pageDots: some View {
        HStack(spacing: 10) {
            ForEach(DataAgeKind.allCases) { kind in
                Circle()
                    .fill(kind == selected ? Neu.ink : Neu.muted.opacity(0.35))
                    .frame(width: 8, height: 8)
                    .onTapGesture { select(kind) }
                    .accessibilityLabel(kind.title)
            }
        }
        .frame(height: 16)
        .frame(maxWidth: .infinity)
    }

    private func ageCircle(_ kind: DataAgeKind, size: CGFloat, isPrimary: Bool) -> some View {
        ZStack {
            ConvexShape(shape: Circle())

            Circle()
                .stroke(kind.color.opacity(isPrimary ? 1 : 0.45), lineWidth: isPrimary ? 7 : 5)

            VStack(spacing: isPrimary ? 6 : 4) {
                Text(formattedAge(kind))
                    .font(Neu.number(isPrimary ? 40 : 20))
                    .foregroundStyle(Neu.ink)
                    .monospacedDigit()
                Text(kind.title)
                    .font(Neu.serif(isPrimary ? 13 : 10))
                    .italic()
                    .foregroundStyle(Neu.muted)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: size, height: size)
        .onTapGesture { select(kind) }
    }

    private var selectedDeltaCard: some View {
        let years = yearsVsReal(selected)
        return VStack(alignment: .leading, spacing: 6) {
            Text(deltaHeadline(for: selected, years: years))
                .font(Neu.number(22))
                .foregroundStyle(deltaColor(years))
                .fixedSize(horizontal: false, vertical: true)
            Text("Your Real Age is \(String(format: "%.1f", state.chronologicalAge)).")
                .font(Neu.body())
                .foregroundStyle(Neu.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
    }

    private var compareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vs people your Real Age")
                .font(Neu.serif(18))
                .italic()
                .foregroundStyle(Neu.ink)

            HStack(spacing: 12) {
                compareCard(title: "Heart", relativeRisk: state.cardiacEventRelativeRisk)
                compareCard(title: "Overall", relativeRisk: state.mortalityRelativeRisk)
            }
        }
    }

    private func compareCard(title: String, relativeRisk: Double) -> some View {
        let percent = Int(((relativeRisk - 1) * 100).rounded())
        let even = abs(percent) < 5
        let better = percent <= 0
        let value = even ? "Even" : "\(abs(percent))%"
        let detail = even
            ? "Typical for your age"
            : (better ? "lower risk" : "higher risk")

        return VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Neu.emphasis(14))
                .foregroundStyle(Neu.muted)
            Text(value)
                .font(Neu.number(36))
                .foregroundStyle(even ? Neu.ink : (better ? Neu.younger : Neu.older))
                .monospacedDigit()
            Text(detail)
                .font(Neu.emphasis(14))
                .foregroundStyle(even ? Neu.muted : (better ? Neu.younger : Neu.older))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
    }

    private var snapshotSection: some View {
        let stats = snapshotStats
        return Group {
            if !stats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("From your last scan")
                        .font(Neu.serif(18))
                        .italic()
                        .foregroundStyle(Neu.ink)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(stats) { stat in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(stat.title)
                                    .font(Neu.emphasis(13))
                                    .foregroundStyle(Neu.muted)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(stat.value)
                                        .font(Neu.number(32))
                                        .foregroundStyle(Neu.ink)
                                        .monospacedDigit()
                                    if !stat.unit.isEmpty {
                                        Text(stat.unit)
                                            .font(Neu.body(13))
                                            .foregroundStyle(Neu.muted)
                                    }
                                }
                                Text(stat.meaning)
                                    .font(Neu.label(14))
                                    .foregroundStyle(stat.meaningColor)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
                        }
                    }
                }
            }
        }
    }

    private var yearsSection: some View {
        let factors = visibleFactors
        return Group {
            if !factors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What’s adding years")
                        .font(Neu.serif(18))
                        .italic()
                        .foregroundStyle(Neu.ink)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(factors) { factor in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(friendlyFactor(factor.title))
                                        .font(Neu.emphasis(16))
                                        .foregroundStyle(Neu.ink)
                                    Spacer()
                                    Text(yearDeltaLabel(factor.yearsDelta))
                                        .font(Neu.button(16))
                                        .foregroundStyle(factor.yearsDelta > 0.05 ? Neu.older : Neu.younger)
                                        .monospacedDigit()
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Neu.ink.opacity(0.08))
                                        Capsule()
                                            .fill(factor.yearsDelta > 0.05 ? Neu.older : Neu.younger)
                                            .frame(width: geo.size.width * factorBarWidth(factor.yearsDelta))
                                    }
                                }
                                .frame(height: 7)
                            }
                        }
                    }
                    .padding(16)
                    .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
                }
            }
        }
    }

    private var telemetryButton: some View {
        Button {
            showTelemetry = true
        } label: {
            Text("Log extra context")
                .font(Neu.serif(16))
                .italic()
                .foregroundStyle(Neu.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(NeuButtonStyle())
    }

    private var methodologySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How We Got This")
                .font(Neu.serif(20))
                .italic()
                .foregroundStyle(Neu.ink)

            methodologyCard(
                title: "Biological Age",
                body: "A blend of your heart, lungs, and Real Age, then sleep and movement from Apple Health. Younger than Real Age means your body is tracking ahead of the calendar."
            )
            methodologyCard(
                title: "Cardiac Age",
                body: "How quickly your heart calms down after effort, plus your resting pulse. A faster drop reads as a younger heart."
            )
            methodologyCard(
                title: "Pulmonary Age",
                body: "How fast you were breathing in the scan. Easier, slower breathing under strain reads as younger lungs."
            )
            methodologyCard(
                title: "Heart and overall comparison",
                body: "These percentages compare your recovery and resting pulse with people who share your Real Age. They are estimates, not a diagnosis."
            )
        }
    }

    private func methodologyCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Neu.serif(16))
                .italic()
                .foregroundStyle(Neu.ink)
            Text(body)
                .font(Neu.body())
                .foregroundStyle(Neu.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let predicted = value.predictedEndTranslation.width
                if predicted < -40 {
                    select(offset: 1)
                } else if predicted > 40 {
                    select(offset: -1)
                }
                withAnimation(slideAnimation) {
                    dragOffset = 0
                }
            }
    }

    private var slideAnimation: Animation {
        .spring(response: 0.46, dampingFraction: 0.86)
    }

    private func slot(for kind: DataAgeKind, relativeTo focus: DataAgeKind? = nil) -> Int {
        let selectedKind = focus ?? selected
        let delta = kind.rawValue - selectedKind.rawValue
        if delta == 2 { return -1 }
        if delta == -2 { return 1 }
        return delta
    }

    private func xOffset(for slot: Int) -> CGFloat {
        CGFloat(slot) * travel
    }

    private func dragFactor(for slot: Int) -> CGFloat {
        slot == 0 ? 0.9 : 0.55
    }

    private func select(_ kind: DataAgeKind) {
        guard kind != selected else { return }

        var jumping = Set<Int>()
        for item in DataAgeKind.allCases {
            let before = slot(for: item)
            let after = slot(for: item, relativeTo: kind)
            if abs(after - before) > 1 {
                jumping.insert(item.id)
            }
        }
        jumpingIDs = jumping

        withAnimation(slideAnimation) {
            selected = kind
        }

        if !jumpingIDs.isEmpty {
            DispatchQueue.main.async {
                jumpingIDs = []
            }
        }
    }

    private func select(offset: Int) {
        let kinds = DataAgeKind.allCases
        let next = (selected.rawValue + offset + kinds.count) % kinds.count
        select(kinds[next])
    }

    private func ageValue(_ kind: DataAgeKind) -> Double {
        switch kind {
        case .cardiac: state.cardiacAge
        case .biological: state.biologicalAge
        case .pulmonary: state.respiratoryAge
        }
    }

    private func formattedAge(_ kind: DataAgeKind) -> String {
        String(format: "%.1f", ageValue(kind))
    }

    private func yearsVsReal(_ kind: DataAgeKind) -> Double {
        ageValue(kind) - state.chronologicalAge
    }

    private func deltaColor(_ years: Double) -> Color {
        abs(years) < 0.15 ? Neu.ink : (years < 0 ? Neu.younger : Neu.older)
    }

    private func deltaHeadline(for kind: DataAgeKind, years: Double) -> String {
        if abs(years) < 0.15 {
            return "\(kind.title) matches your Real Age."
        }
        let amount = String(format: "%.1f", abs(years))
        return years < 0
            ? "\(amount) years younger than Real Age."
            : "\(amount) years older than Real Age."
    }

    private var snapshotStats: [SnapshotStat] {
        var stats: [SnapshotStat] = []
        let pulse = state.latestScan.flatMap { $0.cameraHeartRate > 0 ? $0.cameraHeartRate : nil }
            ?? (state.garminData.restingHeartRate > 0 ? state.garminData.restingHeartRate : nil)
        if let pulse {
            stats.append(
                SnapshotStat(
                    id: "pulse",
                    title: "Pulse",
                    value: "\(pulse)",
                    unit: "bpm",
                    meaning: pulseMeaning(pulse),
                    meaningColor: pulse <= 70 ? Neu.younger : Neu.older
                )
            )
        }
        if let scan = state.latestScan, scan.respiratoryRate > 0 {
            let rate = Int(scan.respiratoryRate.rounded())
            stats.append(
                SnapshotStat(
                    id: "breathing",
                    title: "Breathing",
                    value: "\(rate)",
                    unit: "/min",
                    meaning: breathingMeaning(scan.respiratoryRate),
                    meaningColor: scan.respiratoryRate <= 16 ? Neu.younger : Neu.older
                )
            )
        }
        if let scan = state.latestScan, scan.hrrObserved > 0 {
            stats.append(
                SnapshotStat(
                    id: "recovery",
                    title: "Recovery",
                    value: "\(scan.hrrObserved)",
                    unit: "beats",
                    meaning: recoveryMeaning(scan.hrrObserved),
                    meaningColor: scan.hrrObserved >= 18 ? Neu.younger : Neu.older
                )
            )
        }
        if state.latestScan != nil {
            let score = state.latestScan?.stressScore ?? 0
            stats.append(
                SnapshotStat(
                    id: "stress",
                    title: "Stress",
                    value: score > 0 ? String(format: "%.0f", score) : "--",
                    unit: "",
                    meaning: stressMeaning(score),
                    meaningColor: stressColor(score)
                )
            )
        }
        if state.garminData.sleepScore > 0 {
            stats.append(
                SnapshotStat(
                    id: "sleep",
                    title: "Sleep",
                    value: "\(state.garminData.sleepScore)",
                    unit: "%",
                    meaning: sleepMeaning(state.garminData.sleepScore),
                    meaningColor: state.garminData.sleepScore >= 75 ? Neu.younger : Neu.older
                )
            )
        }
        return stats
    }

    private var visibleFactors: [AgeFactor] {
        state.factorBreakdown
            .filter { abs($0.yearsDelta) >= 0.15 }
            .sorted { abs($0.yearsDelta) > abs($1.yearsDelta) }
    }

    private var maxFactorYears: Double {
        max(visibleFactors.map { abs($0.yearsDelta) }.max() ?? 1, 0.8)
    }

    private func factorBarWidth(_ years: Double) -> CGFloat {
        CGFloat(min(1, abs(years) / maxFactorYears))
    }

    private func yearDeltaLabel(_ years: Double) -> String {
        if abs(years) < 0.15 { return "0 yrs" }
        return String(format: "%+.1f yrs", years)
    }

    private func friendlyFactor(_ title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("cardiac") { return "Heart recovery" }
        if lower.contains("respiratory") { return "Breathing" }
        if lower.contains("hrv") { return "Day-to-day recovery" }
        if lower.contains("resting") { return "Resting pulse" }
        if lower.contains("vascular") { return "Circulation" }
        if lower.contains("sleep") { return "Sleep" }
        if lower.contains("step") { return "Daily movement" }
        return title
    }

    private func pulseMeaning(_ bpm: Int) -> String {
        if bpm < 55 { return "Very calm" }
        if bpm <= 70 { return "Steady" }
        if bpm <= 85 { return "A bit high" }
        return "Running high"
    }

    private func breathingMeaning(_ rate: Double) -> String {
        if rate <= 14 { return "Easy pace" }
        if rate <= 18 { return "Typical" }
        return "Working hard"
    }

    private func recoveryMeaning(_ drop: Int) -> String {
        if drop >= 25 { return "Calmed down fast" }
        if drop >= 18 { return "Solid bounce-back" }
        if drop >= 12 { return "Average recovery" }
        return "Slow to settle"
    }

    private func stressMeaning(_ score: Double) -> String {
        if score <= 0 { return "Not captured yet" }
        if score <= 80 { return "Calm" }
        if score <= 150 { return "Typical" }
        if score <= 300 { return "Elevated" }
        return "Running high"
    }

    private func stressColor(_ score: Double) -> Color {
        if score <= 0 { return Neu.muted }
        if score <= 150 { return Neu.younger }
        return Neu.older
    }

    private func sleepMeaning(_ score: Int) -> String {
        if score >= 85 { return "Rested" }
        if score >= 75 { return "Decent night" }
        if score >= 60 { return "Short on rest" }
        return "Worn down"
    }
}

#Preview {
    @Previewable @State var state = UserRecoveryState.mock
    DataView(state: state)
}
