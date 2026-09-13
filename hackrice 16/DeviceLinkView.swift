//
//  DeviceLinkView.swift
//  hackrice 16
//

import SwiftUI
import UIKit

struct DeviceLinkView: View {
    var state: UserRecoveryState
    var integration: DataIntegration

    @Environment(\.dismiss) private var dismiss
    @State private var sleepScore = 80
    @State private var hrv = 55
    @State private var restingHR = 58
    @State private var status: String?
    @State private var isWorking = false

    private var connected: Bool {
        state.isConnected(integration)
    }

    private var isAppleHealthLink: Bool {
        integration == .appleHealth || integration == .appleWatch
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Neu.canvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            Image(systemName: integration.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Neu.accent)
                                .frame(width: 48, height: 48)
                                .background(ConvexShape(shape: Circle(), isPressed: connected))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(integration.title)
                                    .font(Neu.serif(24))
                                    .italic()
                                    .foregroundStyle(Neu.ink)
                                Text(connected ? "Connected" : "Not Connected")
                                    .font(Neu.serif(14, weight: .light))
                                    .italic()
                                    .foregroundStyle(connected ? Neu.accent : Neu.muted)
                            }
                        }

                        if let status {
                            Text(status)
                                .font(Neu.serif(14, weight: .light))
                                .italic()
                                .foregroundStyle(Neu.ink)
                        }

                        if isAppleHealthLink {
                            appleHealthPanel
                        } else {
                            metricStepper("Sleep Score", value: $sleepScore, range: 1...100)
                            metricStepper("HRV (ms)", value: $hrv, range: 10...160)
                            metricStepper("Resting HR", value: $restingHR, range: 35...110)
                        }

                        Button {
                            Task { await connectDevice() }
                        } label: {
                            Text(isWorking ? "Connecting…" : (connected ? "Refresh Data" : integration.actionTitle))
                                .font(Neu.serif(17, weight: .light))
                                .italic()
                                .foregroundStyle(Neu.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(NeuButtonStyle())
                        .disabled(isWorking)

                        if isAppleHealthLink {
                            Button {
                                openAppleHealth()
                            } label: {
                                Text("Open Apple Health")
                                    .font(Neu.serif(16, weight: .light))
                                    .italic()
                                    .foregroundStyle(Neu.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(NeuButtonStyle())
                        }

                        if connected {
                            Button(role: .destructive) {
                                state.disconnect(integration)
                                status = "Disconnected."
                            } label: {
                                Text("Disconnect")
                                    .font(Neu.serif(16, weight: .light))
                                    .italic()
                                    .foregroundStyle(Neu.older)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
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
            .onAppear {
                sleepScore = max(1, state.garminData.sleepScore)
                hrv = max(10, state.garminData.hrvStatus)
                restingHR = max(35, state.garminData.restingHeartRate)
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var appleHealthPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let health = state.healthContext {
                contextRow("Sleep", value: String(format: "%.1f h  ·  %d", health.sleepHours, health.sleepScore))
                contextRow("Steps", value: "\(health.stepCount)")
                contextRow("HRV", value: "\(health.hrvSDNN) ms")
                contextRow("Resting HR", value: "\(health.restingHeartRate) bpm")
            } else {
                Text("No Health samples loaded yet. Tap Link Health, then allow Sleep, Steps, Heart Rate, and HRV.")
                    .font(Neu.serif(13, weight: .light))
                    .italic()
                    .foregroundStyle(Neu.muted)
            }
        }
        .padding(14)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 18, style: .continuous)))
    }

    private func contextRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Neu.serif(15, weight: .light))
                .italic()
                .foregroundStyle(Neu.ink)
            Spacer()
            Text(value)
                .font(Neu.serif(15, weight: .light))
                .italic()
                .foregroundStyle(Neu.accent)
        }
    }

    private func metricStepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title)
                .font(Neu.serif(16, weight: .light))
                .italic()
                .foregroundStyle(Neu.ink)
            Spacer()
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue)")
                    .font(Neu.serif(16, weight: .light))
                    .italic()
                    .foregroundStyle(Neu.accent)
                    .frame(minWidth: 36, alignment: .trailing)
            }
        }
        .padding(14)
        .background(ConvexShape(shape: RoundedRectangle(cornerRadius: 18, style: .continuous)))
    }

    private func openAppleHealth() {
        if let url = URL(string: "x-apple-health://"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        if let settings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settings)
        }
    }

    @MainActor
    private func connectDevice() async {
        isWorking = true
        defer { isWorking = false }

        if isAppleHealthLink {
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                HealthKitManager.shared.requestAuthorization { continuation.resume(returning: $0) }
            }
            guard granted else {
                status = HealthKitManager.shared.statusMessage ?? "Allow Apple Health access, then try again."
                return
            }
            guard let vitals = await HealthKitManager.shared.fetchLatestVitals() else {
                status = HealthKitManager.shared.statusMessage ?? "Could not read Apple Health. Open Apple Health, then refresh."
                return
            }
            state.connect(.appleHealth)
            if integration == .appleWatch {
                state.connect(.appleWatch)
            }
            state.applyLiveHealthKitVitals(vitals, recordHistory: false)
            status = "Apple Health linked. Sleep and steps will be used as scan context."
            return
        }

        state.applyWearableVitals(
            for: integration,
            sleepScore: sleepScore,
            hrvStatus: hrv,
            restingHeartRate: restingHR
        )
        status = "\(integration.title) connected. These recovery stats now feed compounded age estimates."
    }
}
