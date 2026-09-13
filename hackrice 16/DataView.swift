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
                            riskSection
                            vitalsSection
                            factorSection
                        }

                        telemetryButton

                        Button {
                            withAnimation(.easeInOut(duration: 0.45)) {
                                proxy.scrollTo("methodology", anchor: .top)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text("See How We Got This Information")
                                    .font(Neu.serif(16, weight: .light))
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
            Circle()
                .fill(Neu.canvas)
                .shadow(color: Neu.lightShadow, radius: 8, x: -6, y: -6)
                .shadow(color: Neu.darkShadow, radius: 8, x: 6, y: 6)

            Circle()
                .stroke(kind.color.opacity(isPrimary ? 1 : 0.45), lineWidth: isPrimary ? 7 : 5)

            VStack(spacing: isPrimary ? 6 : 4) {
                Text(formattedAge(kind))
                    .font(.system(size: isPrimary ? 40 : 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Neu.ink)
                    .monospacedDigit()
                Text(kind.title)
                    .font(Neu.serif(isPrimary ? 13 : 10, weight: .light))
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

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Risk vs Peers")
                .font(Neu.serif(18, weight: .light))
                .italic()
                .foregroundStyle(Neu.ink)

            HStack(spacing: 12) {
                riskCard(
                    title: "All-Cause Mortality",
                    value: String(format: "%.2fx", state.mortalityRelativeRisk),
                    detail: state.riskBand
                )
                riskCard(
                    title: "Cardiac Events",
                    value: String(format: "%.2fx", state.cardiacEventRelativeRisk),
                    detail: "CHD / recovery"
                )
            }

            Text("Relative risk from Cole et al. NEJM 1999 (HRR), Zhang et al. CMAJ 2016 (resting HR), Tsuji et al. Circulation 1996 (HRV), and Levine / Liu phenotypic age acceleration.")
                .font(.caption)
                .foregroundStyle(Neu.muted)
        }
    }

    private func riskCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Neu.serif(13, weight: .light))
                .italic()
                .foregroundStyle(Neu.muted)
            Text(value)
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundStyle(Neu.ink)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Neu.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 18, style: .continuous)))
    }

    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Scan & Apple Health")
                .font(Neu.serif(18, weight: .light))
                .italic()
                .foregroundStyle(Neu.ink)

            VStack(alignment: .leading, spacing: 8) {
                vitalRow("Source", state.isUsingLiveHealthKit ? "Apple Health + PreSage" : "PreSage / demo")
                if let scan = state.latestScan {
                    vitalRow("Camera HR", "\(scan.cameraHeartRate) BPM")
                    vitalRow("HRR drop", "\(scan.hrrObserved) BPM")
                    vitalRow("Respiratory rate", String(format: "%.1f /min", scan.respiratoryRate))
                    vitalRow("Vascular score", String(format: "%.0f", scan.vascularScore))
                    vitalRow("Signal quality", String(format: "%.0f", scan.signalQuality))
                }
                vitalRow("7-day HRV", "\(state.garminData.hrvStatus) ms")
                vitalRow("Resting HR", "\(state.garminData.restingHeartRate) BPM")
                vitalRow("Sleep", "\(state.garminData.sleepScore)%")
                if state.recentPeakHeartRate > 0 {
                    vitalRow("Recent peak HR", "\(state.recentPeakHeartRate) BPM")
                }
            }
            .padding(16)
            .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
        }
    }

    private func vitalRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(Neu.muted)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(Neu.ink)
        }
    }

    private var factorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Age Factor Breakdown")
                .font(Neu.serif(18, weight: .light))
                .italic()
                .foregroundStyle(Neu.ink)

            ForEach(state.factorBreakdown) { factor in
                HStack {
                    Text(factor.title)
                        .font(.body)
                        .foregroundStyle(Neu.ink)
                    Spacer()
                    Text(String(format: "%+.1f yrs", factor.yearsDelta))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(factor.isNegative ? Neu.older : Neu.younger)
                }
                .padding(14)
                .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 16, style: .continuous)))
            }
        }
    }

    private var telemetryButton: some View {
        Button {
            showTelemetry = true
        } label: {
            Text("Log Context & Telemetry")
                .font(Neu.serif(16, weight: .light))
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
                .font(Neu.serif(20, weight: .light))
                .italic()
                .foregroundStyle(Neu.ink)

            methodologyCard(
                title: "Biological Age",
                body: "Your overall biological age is 50% cardiac, 30% pulmonary, and 20% chronological, then lifestyle penalties. It blends the Presage SmartSpectra camera scan with Apple Health 7-day HRV and resting heart rate."
            )
            methodologyCard(
                title: "Cardiac Age",
                body: "Cardiac age uses PreSage heart-rate recovery against an age-expected HRR, plus Apple Health HRV. A larger post-effort drop usually means a younger cardiac age."
            )
            methodologyCard(
                title: "Pulmonary Age",
                body: "Pulmonary age comes from respiratory rate in the rPPG scan versus a 14 breath/min baseline. Easier breathing under strain points to a younger pulmonary age."
            )
            methodologyCard(
                title: "Mortality and Cardiac Risk",
                body: "Relative risk uses published cohorts: Cole 1999 (HRR and death), Zhang 2016 (resting HR), Tsuji 1996 Framingham (HRV), and phenotypic age acceleration. This is an estimate, not a diagnosis."
            )
        }
    }

    private func methodologyCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Neu.serif(16, weight: .light))
                .italic()
                .foregroundStyle(Neu.ink)
            Text(body)
                .font(.body)
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

    private func formattedAge(_ kind: DataAgeKind) -> String {
        let value: Double
        switch kind {
        case .cardiac: value = state.cardiacAge
        case .biological: value = state.biologicalAge
        case .pulmonary: value = state.respiratoryAge
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    @Previewable @State var state = UserRecoveryState.mock
    DataView(state: state)
}
