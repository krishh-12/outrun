//
//  ContextLoggingView.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

struct ContextLoggingView: View {
    var state: UserRecoveryState
    var healthKit: HealthKitManager = .shared

    @Environment(\.dismiss) private var dismiss
    @State private var isSyncing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Neu.canvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Data Source & Telemetry Control")
                            .font(Neu.display(26))
                            .italic()
                            .foregroundStyle(Neu.ink)

                        Picker("Data Source", selection: sourceBinding) {
                            ForEach(DataSourceMode.allCases) { mode in
                                Text(mode == .appleHealth ? "Apple HealthKit (Live)" : "Demo Scenario Generator")
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let status = state.healthKitStatus ?? healthKit.statusMessage {
                            Text(status)
                                .font(Neu.serif(13))
                                .italic()
                                .foregroundStyle(Neu.muted)
                        }

                        if state.dataSourceMode == .appleHealth {
                            liveHealthKitSection
                        } else {
                            scenarioSection
                        }

                        habitGrid
                    }
                    .padding(22)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var sourceBinding: Binding<DataSourceMode> {
        Binding(
            get: { state.dataSourceMode },
            set: { mode in
                if mode == .appleHealth {
                    selectHealthKit()
                } else {
                    state.isUsingLiveHealthKit = false
                    state.dataSourceMode = .demoInjector
                    state.healthKitStatus = "Demo Scenario Generator is ready."
                }
            }
        )
    }

    private var liveHealthKitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                syncHealthKit()
            } label: {
                HStack {
                    if isSyncing {
                        ProgressView()
                            .tint(Neu.ink)
                    }
                    Text(isSyncing ? "Syncing…" : "Sync Apple Health Now")
                        .font(Neu.serif(17))
                        .italic()
                }
                .foregroundStyle(Neu.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(NeuButtonStyle())
            .disabled(isSyncing)

            VStack(alignment: .leading, spacing: 10) {
                Text("Resting HR: \(state.garminData.restingHeartRate) BPM")
                Text("HRV: \(state.garminData.hrvStatus) ms")
                Text("Sleep: \(state.garminData.sleepScore)%")
            }
            .font(Neu.number(17).monospacedDigit())
            .foregroundStyle(Neu.ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 22, style: .continuous)))
        }
    }

    private var scenarioSection: some View {
        VStack(spacing: 12) {
            ForEach(DemoScenario.allCases) { scenario in
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(duration: 0.45, bounce: 0.18)) {
                        state.loadScenario(scenario)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(state.selectedScenario == scenario ? Neu.accent : Neu.muted.opacity(0.45))
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenario.title)
                                .font(Neu.serif(18))
                                .italic()
                                .foregroundStyle(Neu.ink)
                            Text(scenario.summary)
                                .font(Neu.body(12))
                                .foregroundStyle(Neu.muted)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        ConvexShape(
                            shape: RoundedRectangle(cornerRadius: 22, style: .continuous),
                            isPressed: state.selectedScenario == scenario
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var habitGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit context")
                .font(Neu.serif(16))
                .italic()
                .foregroundStyle(Neu.ink)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(RecoveryHabit.allCases) { habit in
                    let on = state.activeHabits.contains(habit)
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation(.spring(duration: 0.35, bounce: 0.12)) {
                            state.toggleHabit(habit)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(habit.title)
                                .font(Neu.serif(13))
                                .italic()
                                .foregroundStyle(Neu.ink)
                                .multilineTextAlignment(.center)
                            Text(habit.penaltyReadout)
                                .font(Neu.body(11))
                                .foregroundStyle(on ? Neu.older : Neu.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            ConvexShape(shape: Capsule(), isPressed: on)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func selectHealthKit() {
        if !healthKit.isHealthDataAvailable {
            state.fallbackToDemoMode(
                reason: "HealthKit is unavailable (simulator or this device). Demo Scenario Mode is on."
            )
            return
        }

        state.dataSourceMode = .appleHealth
        healthKit.requestAuthorization { granted in
            if granted {
                syncHealthKit()
            } else {
                state.fallbackToDemoMode(
                    reason: healthKit.statusMessage ?? "Health authorization failed. Demo Scenario Mode is on."
                )
            }
        }
    }

    private func syncHealthKit() {
        if !healthKit.isHealthDataAvailable {
            state.fallbackToDemoMode(
                reason: "HealthKit is unavailable. Demo Scenario Mode is on."
            )
            return
        }

        isSyncing = true
        healthKit.requestAuthorization { granted in
            Task {
                defer { isSyncing = false }
                guard granted else {
                    state.fallbackToDemoMode(
                        reason: healthKit.statusMessage ?? "Health authorization failed. Demo Scenario Mode is on."
                    )
                    return
                }
                let ok = await healthKit.fetchLatestVitals(into: state)
                if !ok {
                    state.fallbackToDemoMode(
                        reason: healthKit.statusMessage ?? "No HealthKit samples. Demo Scenario Mode is on."
                    )
                }
            }
        }
    }
}

#Preview("HealthKit mock reading") {
    @Previewable @State var state = UserRecoveryState.mock
    ContextLoggingView(state: state)
        .onAppear {
            state.applyLiveHealthKitVitals(HealthKitManager.mockVitals())
        }
}

#Preview("Scenario injection") {
    @Previewable @State var state = UserRecoveryState.mock
    ContextLoggingView(state: state)
        .onAppear {
            state.loadScenario(.overtrainedAlcohol)
        }
}
