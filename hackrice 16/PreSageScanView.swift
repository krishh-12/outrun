//
//  PreSageScanView.swift
//  hackrice 16
//
//  Official SmartSpectra API-key scan (Presage docs QuickStart),
//  wired into outrun's age engine on Save.
//

import AVFoundation
import SmartSpectra
import SwiftUI

struct PreSageScanView: View {
    var state: UserRecoveryState
    var minutesSinceAerobicActivity: Int
    var onFinished: () -> Void

    private enum TraceWindow {
        static let rate = 120
        static let arterialWaveform = 240
        static let breathingWaveform = 180
    }

    @Bindable private var sdk = SmartSpectraSDK.shared

    @Environment(\.dismiss) private var dismiss
    @State private var startError: String?
    @State private var isSaving = false
    @State private var pulseRateBuffer: [MeasurementWithConfidence] = []
    @State private var breathingRateBuffer: [MeasurementWithConfidence] = []
    @State private var arterialPressureBuffer: [MeasurementWithConfidence] = []
    @State private var chestBuffer: [SmartSpectra.Measurement] = []
    @State private var abdomenBuffer: [SmartSpectra.Measurement] = []
    @State private var latestHrv: Hrv?

    init(
        state: UserRecoveryState,
        minutesSinceAerobicActivity: Int,
        onFinished: @escaping () -> Void
    ) {
        self.state = state
        self.minutesSinceAerobicActivity = minutesSinceAerobicActivity
        self.onFinished = onFinished
    }

    private static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SMARTSPECTRA_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private enum WaveformProminence {
        case primary
        case secondary
    }

    private var metrics: Metrics? { sdk.metrics }

    private var metricsUpdateToken: Int64 {
        [
            metrics?.cardio.pulseRate.last?.timestamp,
            metrics?.breathing.rate.last?.timestamp,
            metrics?.cardio.arterialPressureTrace.last?.timestamp,
            metrics?.breathing.upperTrace.last?.timestamp,
            metrics?.breathing.lowerTrace.last?.timestamp,
            metrics?.cardio.hrv.last?.timestamp
        ]
        .compactMap { $0 }
        .max() ?? 0
    }

    private var latestPulse: MeasurementWithConfidence? {
        pulseRateBuffer.last ?? sdk.metrics?.cardio.pulseRate.last
    }

    private var latestBreathing: MeasurementWithConfidence? {
        breathingRateBuffer.last ?? sdk.metrics?.breathing.rate.last
    }

    private var displayedHrv: Hrv? {
        latestHrv ?? sdk.metrics?.cardio.hrv.last
    }

    private var pulseRateText: String {
        formatMetric(latestPulse.map { Double($0.value) }, digits: 0, suffix: " bpm")
    }

    private var breathingRateText: String {
        formatMetric(latestBreathing.map { Double($0.value) }, digits: 0, suffix: " bpm")
    }

    private var hrvText: String {
        guard let value = displayedHrv?.rmssd, value > 0 else { return "--" }
        return formatMetric(value, digits: 1, suffix: " ms")
    }

    private var capturedStressScore: Double {
        guard let value = displayedHrv?.baevsky, value.isFinite, value > 0 else { return 0 }
        return Double(value)
    }

    private var pulseConfidenceColor: Color {
        confidenceColor(latestPulse?.confidence)
    }

    private var breathingConfidenceColor: Color {
        confidenceColor(latestBreathing?.confidence)
    }

    private var arterialPressureSamples: [Double] {
        let buffered = arterialPressureBuffer.map { Double($0.value) }
        if buffered.count > 1 { return buffered }
        return (sdk.metrics?.cardio.arterialPressureTrace ?? []).map { Double($0.value) }
    }

    private var chestSamples: [Double] {
        chestBuffer.map { Double($0.value) }
    }

    private var abdomenSamples: [Double] {
        abdomenBuffer.map { Double($0.value) }
    }

    private var statusText: String {
        switch sdk.processingStatus {
        case .idle: return "Idle"
        case .starting: return "Starting"
        case .running: return "Running"
        case .stopping: return "Stopping"
        case .error: return "Error"
        @unknown default: return "Unknown"
        }
    }

    private var validationTitle: String {
        guard let validationStatus = sdk.validationStatus else { return "Waiting" }
        return validationName(validationStatus.code)
    }

    private var statusColor: Color {
        switch sdk.processingStatus {
        case .running: return .green
        case .starting, .stopping: return .orange
        case .error: return .red
        case .idle: return .gray
        @unknown default: return .gray
        }
    }

    private var validationColor: Color {
        guard let validationStatus = sdk.validationStatus else { return .gray }
        switch validationStatus.code {
        case .ok: return .green
        case .cameraTuning: return .orange
        default: return .yellow
        }
    }

    private var isTransitioning: Bool {
        sdk.processingStatus == .starting || sdk.processingStatus == .stopping
    }

    private var startStopTitle: String {
        switch sdk.processingStatus {
        case .running: return "Stop"
        case .starting: return "Starting"
        case .stopping: return "Stopping"
        default: return "Start"
        }
    }

    private var previewPlaceholderText: String {
        if startError != nil { return startError ?? "Camera unavailable" }
        switch sdk.processingStatus {
        case .starting: return "Starting camera…"
        case .running: return "Waiting for camera frames…"
        default: return "Tap Start to open the camera"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            statusBar(compact: true)

            if let startError {
                Text(startError)
                    .font(Neu.label(12))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            ScrollView {
                VStack(spacing: 12) {
                    previewCard
                        .frame(height: 280)

                    if let health = state.healthContext {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Apple Health Context")
                                .font(Neu.label(12))
                                .foregroundStyle(.white.opacity(0.8))
                            Text(String(
                                format: "Sleep %.1fh · %d steps · HRV %d ms. These lifestyle factors are separated from the camera scan so a rough night or low-step day is not treated as true biological aging.",
                                health.sleepHours,
                                health.stepCount,
                                health.hrvSDNN
                            ))
                            .font(Neu.body(11))
                            .foregroundStyle(.white.opacity(0.72))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        Text("Link Apple Health in Add to separate sleep and steps from this scan.")
                            .font(Neu.body(11))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    HStack(spacing: 12) {
                        metricCard(
                            title: "Pulse Rate",
                            value: pulseRateText,
                            valueColor: pulseConfidenceColor,
                            accent: .red,
                            compact: true
                        )
                        metricCard(
                            title: "Breathing Rate",
                            value: breathingRateText,
                            valueColor: breathingConfidenceColor,
                            accent: .cyan,
                            compact: true
                        )
                    }
                    .frame(height: 86)

                    metricCard(
                        title: "HRV RMSSD",
                        value: hrvText,
                        valueColor: .white,
                        accent: .mint,
                        compact: true
                    )
                    .frame(height: 86)

                    waveformCard(
                        title: "Arterial Pressure",
                        samples: arterialPressureSamples,
                        accent: .purple,
                        compact: true,
                        prominence: .primary
                    )
                    .frame(height: 140)

                    HStack(spacing: 12) {
                        waveformCard(
                            title: "Chest Waveform",
                            samples: chestSamples,
                            accent: .cyan,
                            compact: true,
                            prominence: .secondary
                        )
                        waveformCard(
                            title: "Abdomen Waveform",
                            samples: abdomenSamples,
                            accent: .blue,
                            compact: true,
                            prominence: .secondary
                        )
                    }
                    .frame(height: 120)

                    Text("Keep face and upper chest visible and still. Pulse ~12s, breathing ~30s, HRV ~60s. Tap Stop to save vitals and return to the dashboard. Video is not stored.")
                        .font(Neu.body(11))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .background(backgroundGradient.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            if let vitals = await HealthKitManager.shared.fetchLatestVitals() {
                state.applyLiveHealthKitVitals(vitals, recordHistory: false)
            }
            await startMeasurement()
        }
        .task(id: metricsUpdateToken) {
            mergeCurrentMetrics()
        }
        .onDisappear {
            Task { try? await sdk.stop() }
        }
    }

    private var previewCard: some View {
        ZStack {
            if let image = sdk.imageOutput {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.24, blue: 0.46), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                    Image(systemName: "camera.viewfinder")
                        .font(Neu.number(40))
                    Text(previewPlaceholderText)
                        .font(Neu.heading(17))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .foregroundStyle(.white.opacity(0.92))
            }

            LinearGradient(
                colors: [.black.opacity(0.68), .black.opacity(0.12), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    private func statusBar(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 10) {
            Button("Cancel") {
                Task {
                    try? await sdk.stop()
                    onFinished()
                    dismiss()
                }
            }
            .font(Neu.label(12))
            .foregroundStyle(.white)

            badge(title: "Status", value: statusText, color: statusColor)
            badge(title: "Validation", value: validationTitle, color: validationColor)

            Spacer(minLength: 4)

            Button(action: {
                if sdk.processingStatus == .running {
                    saveAndReturn()
                } else {
                    toggleMeasurement()
                }
            }) {
                Text(isSaving ? "Saving" : startStopTitle)
                    .font(Neu.label(12))
                    .padding(.horizontal, compact ? 12 : 16)
                    .padding(.vertical, 8)
                    .background(sdk.processingStatus == .running ? Neu.accent : .white, in: Capsule())
                    .foregroundStyle(.black)
            }
            .disabled(isTransitioning || isSaving)
        }
    }

    private func metricCard(
        title: String,
        value: String,
        valueColor: Color,
        accent: Color,
        compact: Bool,
        monospacedValue: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(Neu.label(12))
                    .foregroundStyle(.white)
            }

            Text(value)
                .font(
                    monospacedValue
                        ? .system(size: compact ? 21 : 24, weight: .semibold, design: .monospaced)
                        : Neu.number(compact ? 21 : 24)
                )
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .presageDashboardCard()
    }

    private func waveformCard(
        title: String,
        samples: [Double],
        accent: Color,
        compact: Bool,
        prominence: WaveformProminence
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            Text(title)
                .font(Neu.label(12))
                .foregroundStyle(.white)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.12))

                if samples.count > 1 {
                    PresageWaveformView(
                        samples: samples,
                        strokeColor: accent,
                        verticalPaddingFraction: prominence == .primary ? 0.14 : 0.08
                    )
                    .padding(prominence == .primary ? 8 : 10)
                }
            }
            .frame(maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accent.opacity(0.3), lineWidth: 1)
            )
        }
        .presageDashboardCard()
    }

    private func badge(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(title): \(value)")
                .font(Neu.label(12))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.white.opacity(0.12), in: Capsule())
        .foregroundStyle(.white)
    }

    private func mergeCurrentMetrics() {
        guard let metrics else { return }

        if !metrics.cardio.pulseRate.isEmpty {
            pulseRateBuffer.appendProtoArray(contentsOf: metrics.cardio.pulseRate)
            pulseRateBuffer = Array(pulseRateBuffer.suffix(TraceWindow.rate))
        }

        if !metrics.breathing.rate.isEmpty {
            breathingRateBuffer.appendProtoArray(contentsOf: metrics.breathing.rate)
            breathingRateBuffer = Array(breathingRateBuffer.suffix(TraceWindow.rate))
        }

        if !metrics.cardio.arterialPressureTrace.isEmpty {
            arterialPressureBuffer.appendProtoArray(contentsOf: metrics.cardio.arterialPressureTrace)
            arterialPressureBuffer = Array(arterialPressureBuffer.suffix(TraceWindow.arterialWaveform))
        }

        if !metrics.breathing.upperTrace.isEmpty {
            chestBuffer.appendProtoArray(contentsOf: metrics.breathing.upperTrace)
            chestBuffer = Array(chestBuffer.suffix(TraceWindow.breathingWaveform))
        }

        if !metrics.breathing.lowerTrace.isEmpty {
            abdomenBuffer.appendProtoArray(contentsOf: metrics.breathing.lowerTrace)
            abdomenBuffer = Array(abdomenBuffer.suffix(TraceWindow.breathingWaveform))
        }

        if let hrv = metrics.cardio.hrv.last {
            latestHrv = hrv
        }
    }

    private func resetBuffers() {
        pulseRateBuffer.removeAll(keepingCapacity: true)
        breathingRateBuffer.removeAll(keepingCapacity: true)
        arterialPressureBuffer.removeAll(keepingCapacity: true)
        chestBuffer.removeAll(keepingCapacity: true)
        abdomenBuffer.removeAll(keepingCapacity: true)
        latestHrv = nil
    }

    private func configureSDK() {
        sdk.config.apiKey = Self.apiKey
        sdk.config.cameraPosition = .front
        sdk.config.imageOutputEnabled = true
        sdk.config.requestedMetrics =
            SmartSpectraConfig.breathingMetrics + SmartSpectraConfig.cardioMetrics
    }

    private func ensureCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    private func toggleMeasurement() {
        Task {
            switch sdk.processingStatus {
            case .running:
                saveAndReturn()
            case .idle, .error:
                await startMeasurement()
            default:
                break
            }
        }
    }

    private func startMeasurement() async {
        startError = nil
        configureSDK()

        guard !Self.apiKey.isEmpty else {
            startError = "Missing SmartSpectra API key."
            return
        }

        let cameraAllowed = await ensureCameraAccess()
        guard cameraAllowed else {
            startError = "Camera access is required. Enable it in Settings → outrunn → Camera, then tap Start."
            return
        }

        switch sdk.processingStatus {
        case .running, .starting:
            return
        case .stopping:
            try? await sdk.stop()
        default:
            break
        }

        resetBuffers()
        do {
            try await sdk.start()
        } catch {
            startError = error.localizedDescription
        }
    }

    private func stopMeasurement() async {
        do {
            try await sdk.stop()
        } catch {
            startError = error.localizedDescription
        }
    }

    private func saveAndReturn() {
        guard !isSaving else { return }
        isSaving = true
        mergeCurrentMetrics()

        let cameraHR = latestPulse.map { Double($0.value) } ?? Double(max(state.garminData.restingHeartRate, 60))
        let breath = latestBreathing.map { Double($0.value) } ?? 16.5
        let quality = Double(latestPulse?.confidence ?? 70)
        let rmssd = displayedHrv.flatMap { $0.rmssd > 0 ? Double($0.rmssd) : nil }
        let stressScore = capturedStressScore

        Task {
            await stopMeasurement()
            // Persist vitals only — never write camera frames or video to disk.
            if let vitals = await HealthKitManager.shared.fetchLatestVitals() {
                state.applyLiveHealthKitVitals(vitals, recordHistory: false)
            }
            if let rmssd {
                state.garminData.hrvStatus = Int(rmssd.rounded())
            }
            let hrr = UserRecoveryState.heartRateRecovery(
                cameraHR: cameraHR,
                peakHR: Double(state.recentPeakHeartRate),
                restingHR: Double(state.garminData.restingHeartRate),
                minutesSinceAerobicActivity: minutesSinceAerobicActivity
            )
            await MainActor.run {
                state.applyPreSageScan(
                    hrrObserved: hrr,
                    respiratoryRate: breath,
                    vascularScore: min(100, max(8, quality)),
                    minutesSinceAerobicActivity: minutesSinceAerobicActivity,
                    cameraHeartRate: Int(cameraHR.rounded()),
                    signalQuality: min(100, max(0, quality)),
                    stressScore: stressScore
                )
                isSaving = false
                onFinished()
                dismiss()
            }
            await GeminiCoach.refreshPlan(for: state)
        }
    }

    private func confidenceColor(_ confidence: Float?) -> Color {
        guard let confidence, confidence.isFinite else { return .white.opacity(0.65) }
        let percent = min(max(Double(confidence), 0), 100)
        switch percent {
        case 85...:
            return .green
        case 60..<85:
            return .yellow
        default:
            return .red
        }
    }

    private func formatMetric(_ value: Double?, digits: Int = 0, suffix: String = "") -> String {
        guard let value else { return "--" }
        if digits == 0 {
            return "\(Int(value.rounded()))\(suffix)"
        }
        return String(format: "%.\(digits)f", value) + suffix
    }

    private func validationName(_ code: ValidationCode) -> String {
        switch code {
        case .ok: return "OK"
        case .noFaceFound: return "No Face"
        case .multipleFacesFound: return "Multi Face"
        case .faceNotCentered: return "Off Center"
        case .faceSizeOutOfRange: return "Face Size"
        case .tooDark: return "Too Dark"
        case .tooBright: return "Too Bright"
        case .chestNotVisible: return "Chest Missing"
        case .cameraTuning: return "Tuning"
        @unknown default: return "Unknown"
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.05, blue: 0.12),
                Color(red: 0.07, green: 0.09, blue: 0.18),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct PresageWaveformView: View {
    let samples: [Double]
    let strokeColor: Color
    let verticalPaddingFraction: Double

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard samples.count > 1 else { return }

                let minValue = samples.min() ?? 0
                let maxValue = samples.max() ?? 1
                let rawRange = max(maxValue - minValue, 0.0001)
                let padding = rawRange * verticalPaddingFraction
                let lowerBound = minValue - padding
                let upperBound = maxValue + padding
                let range = max(upperBound - lowerBound, 0.0001)

                for (index, sample) in samples.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(samples.count - 1)
                    let normalized = (sample - lowerBound) / range
                    let y = geometry.size.height * (1 - normalized)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        }
    }
}

private extension View {
    func presageDashboardCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

#Preview {
    @Previewable @State var state = UserRecoveryState.mock
    PreSageScanView(state: state, minutesSinceAerobicActivity: 45, onFinished: {})
}
