//
//  RecoveryModels.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import Foundation
import Observation

struct HealthContext: Hashable, Codable {
    var capturedAt: Date
    var sleepScore: Int
    var sleepHours: Double
    var stepCount: Int
    var restingHeartRate: Int
    var hrvSDNN: Int
    var respiratoryRate: Double
    var activeEnergyBurned: Double
    var peakHeartRate: Int

    var lifestyleYears: Double {
        let sleepYears = (75.0 - Double(sleepScore)) * 0.035
        let restYears = sleepHours > 0 ? (7.5 - sleepHours) * 0.35 : 0
        let stepYears = (8_000.0 - Double(stepCount)) / 4_000.0 * 0.55
        return ((sleepYears + restYears + stepYears) * 10).rounded() / 10
    }
}

struct GarminTelemetry: Hashable, Codable {
    var sleepScore: Int
    var hrvStatus: Int
    var restingHeartRate: Int
}

enum ChartTimeRange: String, CaseIterable, Identifiable, Codable {
    case day
    case week
    case month
    case sixMonths
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "1D"
        case .week: "1W"
        case .month: "1M"
        case .sixMonths: "6M"
        case .year: "1Y"
        }
    }

    var requiresWeekOfHistory: Bool {
        self != .day
    }

    var startDate: Date {
        switch self {
        case .day:
            Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        case .week:
            Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        case .month:
            Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        case .sixMonths:
            Calendar.current.date(byAdding: .month, value: -6, to: .now) ?? .now
        case .year:
            Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "day", "hour": self = .day
        case "week": self = .week
        case "month": self = .month
        case "sixMonths": self = .sixMonths
        case "year": self = .year
        default: self = .day
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum DataResetScope: String, CaseIterable, Identifiable {
    case day
    case week
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "Reset Today"
        case .week: "Reset This Week"
        case .all: "Reset All Time"
        }
    }

    var cutoff: Date? {
        switch self {
        case .day: Calendar.current.date(byAdding: .day, value: -1, to: .now)
        case .week: Calendar.current.date(byAdding: .day, value: -7, to: .now)
        case .all: nil
        }
    }
}

enum BiologicalAgeBounds {
    static func clamp(_ estimate: Double, chronological chrono: Double, younger: Double, older: Double) -> Double {
        let floor = max(18, chrono - younger)
        let ceiling = min(90, chrono + older)
        let value = min(ceiling, max(floor, estimate))
        return (value * 10).rounded() / 10
    }
}

struct PreSageScan: Identifiable, Hashable, Codable {
    var id: UUID
    var capturedAt: Date
    var hrrObserved: Int
    var minutesSinceAerobicActivity: Int
    var respiratoryRate: Double
    var vascularScore: Double
    var cameraHeartRate: Int
    var signalQuality: Double

    init(
        id: UUID = UUID(),
        capturedAt: Date = .now,
        hrrObserved: Int,
        minutesSinceAerobicActivity: Int,
        respiratoryRate: Double = 16.5,
        vascularScore: Double = 70,
        cameraHeartRate: Int = 0,
        signalQuality: Double = 0
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.hrrObserved = hrrObserved
        self.minutesSinceAerobicActivity = minutesSinceAerobicActivity
        self.respiratoryRate = respiratoryRate
        self.vascularScore = vascularScore
        self.cameraHeartRate = cameraHeartRate
        self.signalQuality = signalQuality
    }
}

struct AgeReading: Identifiable, Hashable, Codable {
    var id: UUID
    var date: Date
    var chronologicalAge: Double
    var biologicalAge: Double
    var cardiacAge: Double
    var respiratoryAge: Double

    init(
        id: UUID = UUID(),
        date: Date,
        chronologicalAge: Double,
        biologicalAge: Double,
        cardiacAge: Double,
        respiratoryAge: Double
    ) {
        self.id = id
        self.date = date
        self.chronologicalAge = chronologicalAge
        self.biologicalAge = biologicalAge
        self.cardiacAge = cardiacAge
        self.respiratoryAge = respiratoryAge
    }
}

enum DataIntegration: String, CaseIterable, Identifiable, Codable {
    case appleHealth
    case appleWatch
    case fitbit
    case garmin
    case strava

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleHealth: "Apple Health"
        case .appleWatch: "Apple Watch"
        case .fitbit: "Fitbit"
        case .garmin: "Garmin"
        case .strava: "Strava"
        }
    }

    var icon: String {
        switch self {
        case .appleHealth: "heart.text.square.fill"
        case .appleWatch: "applewatch"
        case .fitbit: "heart.circle"
        case .garmin: "location.north.circle"
        case .strava: "figure.run"
        }
    }

    var actionTitle: String {
        switch self {
        case .appleHealth: "Link Health"
        case .strava: "Log In"
        default: "Connect"
        }
    }

    var wearableSource: WearableSource? {
        switch self {
        case .appleHealth, .appleWatch: .appleWatch
        case .fitbit: .fitbit
        case .garmin: .garmin
        case .strava: nil
        }
    }

    var detail: String {
        switch self {
        case .appleHealth:
            "Link Apple Health so sleep, steps, and HRV can be separated from Presage scan age."
        case .appleWatch:
            "Pull heart rate, HRV, and sleep your watch writes to Apple Health."
        case .fitbit:
            "Import Fitbit recovery stats you share with Apple Health, or enter them here."
        case .garmin:
            "Import Garmin HRV, sleep, and resting heart rate."
        case .strava:
            "Link Strava so training load can inform recovery context."
        }
    }
}

enum AuthProvider: String, Hashable, Codable {
    case apple
    case google
    case email
}

enum RecoveryHabit: String, CaseIterable, Identifiable, Hashable, Codable {
    case lateAlcohol
    case highFatMeal
    case poorSleep
    case dehydration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lateAlcohol: "Late Alcohol"
        case .highFatMeal: "High Fat Meal"
        case .poorSleep: "Poor Sleep"
        case .dehydration: "Dehydration"
        }
    }

    var agePenalty: Double {
        switch self {
        case .lateAlcohol: 1.2
        case .highFatMeal: 0.8
        case .poorSleep: 1.0
        case .dehydration: 0.7
        }
    }

    var riskPenalty: Double {
        switch self {
        case .lateAlcohol: 0.12
        case .highFatMeal: 0.08
        case .poorSleep: 0.10
        case .dehydration: 0.07
        }
    }

    var penaltyReadout: String {
        String(format: "+%.1f yrs", agePenalty)
    }
}

enum DemoScenario: String, CaseIterable, Identifiable, Codable {
    case primeAthlete
    case overtrainedAlcohol
    case postWorkoutDehydrated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .primeAthlete: "Peak Athlete"
        case .overtrainedAlcohol: "Overtrained + Alcohol"
        case .postWorkoutDehydrated: "Dehydrated Runner"
        }
    }

    var summary: String {
        switch self {
        case .primeAthlete: "RHR 48 · HRV 78 · Sleep 92% · HRR 36"
        case .overtrainedAlcohol: "RHR 68 · HRV 28 · Sleep 45% · HRR 13"
        case .postWorkoutDehydrated: "RHR 58 · HRV 46 · Sleep 75% · HRR 21"
        }
    }

    var telemetry: GarminTelemetry {
        switch self {
        case .primeAthlete:
            GarminTelemetry(sleepScore: 92, hrvStatus: 78, restingHeartRate: 48)
        case .overtrainedAlcohol:
            GarminTelemetry(sleepScore: 45, hrvStatus: 28, restingHeartRate: 68)
        case .postWorkoutDehydrated:
            GarminTelemetry(sleepScore: 75, hrvStatus: 46, restingHeartRate: 58)
        }
    }

    var hrrDrop: Int {
        switch self {
        case .primeAthlete: 36
        case .overtrainedAlcohol: 13
        case .postWorkoutDehydrated: 21
        }
    }

    var respiratoryRate: Double {
        switch self {
        case .primeAthlete: 11.75
        case .overtrainedAlcohol: 18.4
        case .postWorkoutDehydrated: 16.5
        }
    }

    var vascularScore: Double {
        switch self {
        case .primeAthlete: 88
        case .overtrainedAlcohol: 41
        case .postWorkoutDehydrated: 62
        }
    }

    var defaultHabits: Set<RecoveryHabit> {
        switch self {
        case .primeAthlete: []
        case .overtrainedAlcohol: [.lateAlcohol]
        case .postWorkoutDehydrated: [.dehydration]
        }
    }
}

struct AgeFactor: Identifiable, Hashable, Codable {
    var id: String { title }
    var title: String
    var yearsDelta: Double
    var isNegative: Bool
}

enum DataSourceMode: String, CaseIterable, Identifiable, Codable {
    case appleHealth
    case demoInjector

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleHealth: "Apple HealthKit (Live)"
        case .demoInjector: "Demo Scenario Generator"
        }
    }

    var badgeTitle: String {
        switch self {
        case .appleHealth: "Source: Apple Health"
        case .demoInjector: "Source: Demo Injector"
        }
    }
}

enum ClinicalRiskEngine {
    /// Cole CR et al. N Engl J Med. 1999;341:1351-1357. Abnormal HRR ≤12 bpm, adjusted RR 2.0 for death.
    static func mortalityRRFromHRR(_ hrr: Double) -> Double {
        if hrr <= 12 {
            return min(3.2, 2.0 * exp(0.045 * (12 - hrr)))
        }
        return max(0.78, 2.0 * exp(-0.0693 * (hrr - 12)))
    }

    /// Zhang D et al. CMAJ. 2016;188:E53-E63. ~9% higher all-cause mortality per 10 bpm above 60.
    static func mortalityRRFromRestingHR(_ rhr: Double) -> Double {
        exp(0.0862 * (rhr - 60.0) / 10.0)
    }

    /// Zhang D et al. CMAJ 2016; Fox K et al. JACC 2007. Resting HR and coronary events.
    static func cardiacEventRRFromRestingHR(_ rhr: Double) -> Double {
        exp(0.1133 * (rhr - 60.0) / 10.0)
    }

    /// Tsuji H et al. Circulation. 1996;94:2850-2855 (Framingham). Low SDNN raises mortality.
    static func mortalityRRFromHRV(_ sdnn: Double) -> Double {
        exp(0.077 * max(0, 70 - sdnn) / 10.0)
    }

    /// Cole / Vivekananthan: blunted HRR also tracks coronary events.
    static func cardiacEventRRFromHRR(_ hrr: Double) -> Double {
        if hrr <= 12 { return 1.8 }
        if hrr < 18 { return 1.35 }
        if hrr < 22 { return 1.12 }
        return 1.0
    }

    /// Levine ME et al. Aging. 2018; Liu Z et al. PLoS Med. 2018. ~5% mortality per year of phenotypic age acceleration.
    static func mortalityRRFromAgeAcceleration(_ years: Double) -> Double {
        exp(0.0488 * years)
    }

    static func geometricMean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 1 }
        let logSum = values.map { log(max($0, 0.4)) }.reduce(0, +)
        return exp(logSum / Double(values.count))
    }
}

enum WearableSource: String, CaseIterable, Identifiable, Hashable, Codable {
    case appleWatch
    case fitbit
    case garmin
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleWatch: "Apple Watch"
        case .fitbit: "Fitbit"
        case .garmin: "Garmin"
        case .manual: "Enter Data Manually"
        }
    }

    var subtitle: String {
        switch self {
        case .appleWatch: "Heart rate, HRV, and sleep from watchOS"
        case .fitbit: "Sleep score and recovery from Fitbit"
        case .garmin: "HRV, sleep, and training load from Garmin"
        case .manual: "Log sleep, HRV, and HRR yourself"
        }
    }

    var icon: String {
        switch self {
        case .appleWatch: "applewatch"
        case .fitbit: "heart.circle"
        case .garmin: "location.north.circle"
        case .manual: "square.and.pencil"
        }
    }
}

@Observable
final class UserRecoveryState {
    var userName: String
    var chronologicalAge: Double
    var biologicalAge: Double
    var cardiacAge: Double
    var respiratoryAge: Double
    var garminData: GarminTelemetry
    var latestScan: PreSageScan?
    var scanHistory: [PreSageScan]
    var authProvider: AuthProvider?
    var dataSource: WearableSource?
    var hasCompletedBaseline: Bool
    var ageHistory: [AgeReading]
    var connectedIntegrations: Set<String>
    var isUsingLiveHealthKit: Bool
    var dataSourceMode: DataSourceMode
    var activeHabits: Set<RecoveryHabit>
    var factorBreakdown: [AgeFactor]
    var riskMultiplier: Double
    var riskBand: String
    var mortalityRelativeRisk: Double
    var respiratoryRate: Double
    var activeEnergyBurned: Double
    var selectedScenario: DemoScenario?
    var healthKitStatus: String?
    var recentPeakHeartRate: Int
    var cameraHeartRate: Int
    var cardiacEventRelativeRisk: Double
    var hapticsEnabled: Bool
    var chartRange: ChartTimeRange
    var profileEmail: String?
    var persistenceKey: String?
    var healthContext: HealthContext?
    var latestCoachPlan: CoachPlan?
    var coachStatus: String?
    var isRefreshingCoach: Bool

    init(
        userName: String,
        chronologicalAge: Double,
        biologicalAge: Double,
        cardiacAge: Double,
        respiratoryAge: Double,
        garminData: GarminTelemetry,
        latestScan: PreSageScan? = nil,
        scanHistory: [PreSageScan] = [],
        authProvider: AuthProvider? = nil,
        dataSource: WearableSource? = nil,
        hasCompletedBaseline: Bool = false,
        ageHistory: [AgeReading] = [],
        connectedIntegrations: Set<String> = [],
        isUsingLiveHealthKit: Bool = false,
        dataSourceMode: DataSourceMode = .demoInjector,
        activeHabits: Set<RecoveryHabit> = [],
        factorBreakdown: [AgeFactor] = [],
        riskMultiplier: Double = 1.0,
        riskBand: String = "Baseline",
        mortalityRelativeRisk: Double = 1.0,
        respiratoryRate: Double = 14,
        activeEnergyBurned: Double = 0,
        selectedScenario: DemoScenario? = nil,
        healthKitStatus: String? = nil,
        recentPeakHeartRate: Int = 0,
        cameraHeartRate: Int = 0,
        cardiacEventRelativeRisk: Double = 1.0,
        hapticsEnabled: Bool = true,
        chartRange: ChartTimeRange = .day,
        profileEmail: String? = nil,
        persistenceKey: String? = nil,
        healthContext: HealthContext? = nil,
        latestCoachPlan: CoachPlan? = nil
    ) {
        self.userName = userName
        self.chronologicalAge = chronologicalAge
        self.biologicalAge = biologicalAge
        self.cardiacAge = cardiacAge
        self.respiratoryAge = respiratoryAge
        self.garminData = garminData
        self.latestScan = latestScan
        self.scanHistory = scanHistory
        self.authProvider = authProvider
        self.dataSource = dataSource
        self.hasCompletedBaseline = hasCompletedBaseline
        self.ageHistory = ageHistory
        self.connectedIntegrations = connectedIntegrations
        self.isUsingLiveHealthKit = isUsingLiveHealthKit
        self.dataSourceMode = dataSourceMode
        self.activeHabits = activeHabits
        self.factorBreakdown = factorBreakdown
        self.riskMultiplier = riskMultiplier
        self.riskBand = riskBand
        self.mortalityRelativeRisk = mortalityRelativeRisk
        self.respiratoryRate = respiratoryRate
        self.activeEnergyBurned = activeEnergyBurned
        self.selectedScenario = selectedScenario
        self.healthKitStatus = healthKitStatus
        self.recentPeakHeartRate = recentPeakHeartRate
        self.cameraHeartRate = cameraHeartRate
        self.cardiacEventRelativeRisk = cardiacEventRelativeRisk
        self.hapticsEnabled = hapticsEnabled
        self.chartRange = chartRange
        self.profileEmail = profileEmail
        self.persistenceKey = persistenceKey
        self.healthContext = healthContext
        self.latestCoachPlan = latestCoachPlan
        self.coachStatus = nil
        self.isRefreshingCoach = false
    }

    var ageDelta: Double {
        biologicalAge - chronologicalAge
    }

    var cardiacAgeDelta: Double {
        cardiacAge - chronologicalAge
    }

    var pulmonaryAge: Double {
        get { respiratoryAge }
        set { respiratoryAge = newValue }
    }

    var pulmonaryAgeDelta: Double {
        pulmonaryAge - chronologicalAge
    }

    var lifestylePenalties: Double {
        activeHabits.reduce(0) { $0 + $1.agePenalty }
    }

    func applySignedInUser(name: String, provider: AuthProvider, email: String? = nil) {
        userName = name
        authProvider = provider
        profileEmail = email
        persistSoon()
    }

    func resetForNewAccount(name: String, provider: AuthProvider, email: String? = nil) {
        applySignedInUser(name: name, provider: provider, email: email)
        hasCompletedBaseline = false
        latestScan = nil
        scanHistory = []
        ageHistory = []
        connectedIntegrations = []
        biologicalAge = chronologicalAge
        cardiacAge = chronologicalAge
        respiratoryAge = chronologicalAge
        isUsingLiveHealthKit = false
        dataSourceMode = .demoInjector
        activeHabits = []
        factorBreakdown = []
        riskMultiplier = 1.0
        riskBand = "Baseline"
        mortalityRelativeRisk = 1.0
        selectedScenario = nil
        recentPeakHeartRate = 0
        cameraHeartRate = 0
        cardiacEventRelativeRisk = 1.0
        healthContext = nil
        latestCoachPlan = nil
        coachStatus = nil
        persistSoon()
    }

    func completeScan(minutesSinceAerobicActivity: Int) {
        let stress = min(3.5, max(0, (120.0 - Double(minutesSinceAerobicActivity)) / 40.0))
        applyPreSageScan(
            hrrObserved: Int((28.0 - stress * 3.2).rounded()),
            respiratoryRate: 14.0 + stress * 0.85,
            vascularScore: max(38, 82 - stress * 9),
            minutesSinceAerobicActivity: minutesSinceAerobicActivity
        )
    }

    func connect(_ integration: DataIntegration) {
        connectedIntegrations.insert(integration.rawValue)
        if let wearable = integration.wearableSource {
            dataSource = wearable
        }
        persistSoon()
    }

    func disconnect(_ integration: DataIntegration) {
        connectedIntegrations.remove(integration.rawValue)
        if dataSource == integration.wearableSource {
            dataSource = connectedIntegrations.compactMap { raw in
                DataIntegration(rawValue: raw)?.wearableSource
            }.first
        }
        persistSoon()
    }

    func applyWearableVitals(
        for integration: DataIntegration,
        sleepScore: Int,
        hrvStatus: Int,
        restingHeartRate: Int
    ) {
        connect(integration)
        garminData = GarminTelemetry(
            sleepScore: sleepScore,
            hrvStatus: hrvStatus,
            restingHeartRate: restingHeartRate
        )
        if hasCompletedBaseline {
            recalculateBiologicalAge()
        }
        persistSoon()
    }

    func isConnected(_ integration: DataIntegration) -> Bool {
        connectedIntegrations.contains(integration.rawValue)
    }

    func completeBaselineScan(minutesSinceAerobicActivity: Int) {
        completeScan(minutesSinceAerobicActivity: minutesSinceAerobicActivity)
    }

    var hasWeekOfAgeData: Bool {
        guard let first = ageHistory.map(\.date).min(),
              let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now)
        else { return false }
        return first <= weekAgo
    }

    func applyCoachBiologicalAge(_ age: Double) {
        biologicalAge = BiologicalAgeBounds.clamp(
            age,
            chronological: chronologicalAge,
            younger: 8,
            older: 12
        )
        guard !ageHistory.isEmpty else { return }
        var latest = ageHistory[ageHistory.count - 1]
        latest.biologicalAge = biologicalAge
        ageHistory[ageHistory.count - 1] = latest
    }

    func resetData(_ scope: DataResetScope) {
        if let cutoff = scope.cutoff {
            scanHistory.removeAll { $0.capturedAt >= cutoff }
            ageHistory.removeAll { $0.date >= cutoff }
            if let latest = latestScan, latest.capturedAt >= cutoff {
                latestScan = scanHistory.max(by: { $0.capturedAt < $1.capturedAt })
            }
        } else {
            scanHistory = []
            ageHistory = []
            latestScan = nil
            hasCompletedBaseline = false
            garminData = GarminTelemetry(sleepScore: 0, hrvStatus: 0, restingHeartRate: 0)
            healthContext = nil
            activeHabits = []
            selectedScenario = nil
            recentPeakHeartRate = 0
            cameraHeartRate = 0
            respiratoryRate = 14
            activeEnergyBurned = 0
            chartRange = .day
        }

        latestCoachPlan = nil
        coachStatus = nil

        if scanHistory.isEmpty {
            hasCompletedBaseline = false
            biologicalAge = chronologicalAge
            cardiacAge = chronologicalAge
            respiratoryAge = chronologicalAge
            factorBreakdown = []
            riskMultiplier = 1.0
            riskBand = "Baseline"
            mortalityRelativeRisk = 1.0
            cardiacEventRelativeRisk = 1.0
        } else {
            hasCompletedBaseline = true
            recalculateBiologicalAge()
        }
        persistSoon()
    }

    func applyPreSageScan(
        hrrObserved: Int,
        respiratoryRate: Double,
        vascularScore: Double,
        minutesSinceAerobicActivity: Int,
        cameraHeartRate: Int = 0,
        signalQuality: Double = 0
    ) {
        let scan = PreSageScan(
            hrrObserved: hrrObserved,
            minutesSinceAerobicActivity: minutesSinceAerobicActivity,
            respiratoryRate: respiratoryRate,
            vascularScore: vascularScore,
            cameraHeartRate: cameraHeartRate,
            signalQuality: signalQuality
        )
        scanHistory.append(scan)
        latestScan = scan
        self.cameraHeartRate = cameraHeartRate
        hasCompletedBaseline = true
        recalculateBiologicalAge()
        appendHistory()
        persistSoon()
    }

    static func heartRateRecovery(
        cameraHR: Double,
        peakHR: Double,
        restingHR: Double,
        minutesSinceAerobicActivity: Int
    ) -> Int {
        if peakHR >= cameraHR + 4 {
            return Int(min(35, max(5, peakHR - cameraHR)).rounded())
        }
        // Resting rPPG is not a treadmill HRR test. Do not invent elite ~38 bpm recovery.
        let elevation = max(0, cameraHR - max(restingHR, 40))
        if minutesSinceAerobicActivity < 15 {
            return Int(min(18, max(8, 22 - elevation * 0.35)).rounded())
        }
        return Int(min(24, max(12, 20 - elevation * 0.25)).rounded())
    }

    func loadScenario(_ scenario: DemoScenario) {
        isUsingLiveHealthKit = false
        dataSourceMode = .demoInjector
        selectedScenario = scenario
        hasCompletedBaseline = true
        garminData = scenario.telemetry
        activeHabits = scenario.defaultHabits
        latestScan = PreSageScan(
            hrrObserved: scenario.hrrDrop,
            minutesSinceAerobicActivity: scenario == .postWorkoutDehydrated ? 20 : 75,
            respiratoryRate: scenario.respiratoryRate,
            vascularScore: scenario.vascularScore
        )
        if let latestScan {
            scanHistory.append(latestScan)
        }
        healthKitStatus = "Would-be scenario injected: \(scenario.title)."
        recalculateBiologicalAge()
        appendHistory()
        persistSoon()
    }

    func toggleHabit(_ habit: RecoveryHabit) {
        if activeHabits.contains(habit) {
            activeHabits.remove(habit)
        } else {
            activeHabits.insert(habit)
        }
        recalculateBiologicalAge()
        replaceLatestHistory()
        persistSoon()
    }

    func applyLiveHealthKitVitals(_ vitals: HealthKitVitals, recordHistory: Bool = true) {
        isUsingLiveHealthKit = true
        dataSourceMode = .appleHealth
        selectedScenario = nil
        garminData = GarminTelemetry(
            sleepScore: vitals.sleepScore,
            hrvStatus: vitals.hrvSDNN,
            restingHeartRate: vitals.restingHeartRate
        )
        respiratoryRate = vitals.respiratoryRate
        activeEnergyBurned = vitals.activeEnergyBurned
        recentPeakHeartRate = vitals.peakHeartRate
        healthContext = vitals.asHealthContext()
        healthKitStatus = "Live vitals mapped from Apple Health."
        if hasCompletedBaseline {
            recalculateBiologicalAge()
            if recordHistory {
                appendHistory()
            }
        }
        persistSoon()
    }

    func fallbackToDemoMode(reason: String) {
        isUsingLiveHealthKit = false
        dataSourceMode = .demoInjector
        healthKitStatus = reason
        persistSoon()
    }

    /// Compounds PreSage scans with wearable baselines. Ages never reset to a single reading.
    func recalculateBiologicalAge() {
        let chrono = Double(chronologicalAge)
        let scans = scanHistory.isEmpty ? [latestScan].compactMap { $0 } : scanHistory
        let compoundedHRR = mean(scans.map { Double($0.hrrObserved) }, fallback: 22)
        let compoundedResp = mean(scans.map(\.respiratoryRate), fallback: 16.5)
        let compoundedVascular = mean(scans.map(\.vascularScore), fallback: 70)
        let hrvValue = garminData.hrvStatus > 0 ? Double(garminData.hrvStatus) : 55.0
        let rhrValue = garminData.restingHeartRate > 0 ? Double(garminData.restingHeartRate) : 55.0
        let healthYears = healthContext?.lifestyleYears ?? 0

        let baselineExpectedHRR = 30.0 - ((chrono - 20.0) * 0.2)
        let hrvDelta = (hrvValue - 55.0) * -0.1
        let cardiacRecoveryYears = (baselineExpectedHRR - compoundedHRR) * 0.4
        let cardiacOffset = cardiacRecoveryYears + hrvDelta
        let instantCardiac = roundedAge(chrono + cardiacOffset)
        let pulmonaryOffset = (compoundedResp - 14.0) * 0.8
        let instantPulmonary = roundedAge(chrono + pulmonaryOffset)
        let instantBiological = roundedAge(
            (instantCardiac * 0.50) + (instantPulmonary * 0.30) + (chrono * 0.20) + lifestylePenalties + healthYears
        )

        let samples = max(scans.count, hasCompletedBaseline ? 1 : 0)
        cardiacAge = BiologicalAgeBounds.clamp(
            blend(previous: cardiacAge, instant: instantCardiac, samples: samples),
            chronological: chrono,
            younger: 10,
            older: 12
        )
        pulmonaryAge = BiologicalAgeBounds.clamp(
            blend(previous: pulmonaryAge, instant: instantPulmonary, samples: samples),
            chronological: chrono,
            younger: 10,
            older: 12
        )
        biologicalAge = BiologicalAgeBounds.clamp(
            blend(previous: biologicalAge, instant: instantBiological, samples: samples),
            chronological: chrono,
            younger: 8,
            older: 12
        )

        let restingHRYears = (rhrValue - 55.0) * 0.1
        var breakdown: [AgeFactor] = [
            AgeFactor(
                title: "Compounded cardiac recovery",
                yearsDelta: cardiacRecoveryYears,
                isNegative: cardiacRecoveryYears > 0
            ),
            AgeFactor(
                title: "Compounded respiratory rate",
                yearsDelta: pulmonaryOffset,
                isNegative: pulmonaryOffset > 0
            ),
            AgeFactor(
                title: "Wearable HRV",
                yearsDelta: hrvDelta,
                isNegative: hrvDelta > 0
            ),
            AgeFactor(
                title: "Wearable resting HR",
                yearsDelta: restingHRYears,
                isNegative: restingHRYears > 0
            ),
            AgeFactor(
                title: "Scan vascular quality",
                yearsDelta: (70 - compoundedVascular) * 0.04,
                isNegative: compoundedVascular < 70
            )
        ]
        if let health = healthContext {
            breakdown.append(
                AgeFactor(
                    title: "Apple Health sleep",
                    yearsDelta: (75.0 - Double(health.sleepScore)) * 0.035,
                    isNegative: health.sleepScore < 75
                )
            )
            breakdown.append(
                AgeFactor(
                    title: "Apple Health steps",
                    yearsDelta: (8_000.0 - Double(health.stepCount)) / 4_000.0 * 0.55,
                    isNegative: health.stepCount < 8_000
                )
            )
        }
        for habit in RecoveryHabit.allCases where activeHabits.contains(habit) {
            breakdown.append(
                AgeFactor(title: habit.title, yearsDelta: habit.agePenalty, isNegative: true)
            )
        }
        factorBreakdown = breakdown

        let rhr = garminData.restingHeartRate > 0 ? Double(garminData.restingHeartRate) : 60
        let hrv = garminData.hrvStatus > 0 ? Double(garminData.hrvStatus) : 55
        let ageAccel = biologicalAge - chrono

        let mortality = ClinicalRiskEngine.geometricMean([
            ClinicalRiskEngine.mortalityRRFromHRR(compoundedHRR),
            ClinicalRiskEngine.mortalityRRFromRestingHR(rhr),
            ClinicalRiskEngine.mortalityRRFromHRV(hrv),
            ClinicalRiskEngine.mortalityRRFromAgeAcceleration(ageAccel)
        ])
        let cardiac = ClinicalRiskEngine.geometricMean([
            ClinicalRiskEngine.cardiacEventRRFromHRR(compoundedHRR),
            ClinicalRiskEngine.cardiacEventRRFromRestingHR(rhr),
            ClinicalRiskEngine.mortalityRRFromHRV(hrv)
        ])

        mortalityRelativeRisk = (max(0.7, mortality) * 100).rounded() / 100
        cardiacEventRelativeRisk = (max(0.7, cardiac) * 100).rounded() / 100
        riskMultiplier = cardiacEventRelativeRisk
        riskBand = Self.band(for: mortalityRelativeRisk)
    }

    func recalculateEngines() {
        recalculateBiologicalAge()
    }

    private static func band(for multiplier: Double) -> String {
        if multiplier <= 0.95 { return "Optimal" }
        if multiplier < 1.25 { return "Moderate Risk" }
        return "Elevated Risk"
    }

    private func estimatedHRR(fromResting rhr: Int) -> Int {
        max(8, min(40, 90 - rhr))
    }

    private func appendHistory() {
        ageHistory.append(
            AgeReading(
                date: .now,
                chronologicalAge: chronologicalAge,
                biologicalAge: biologicalAge,
                cardiacAge: cardiacAge,
                respiratoryAge: respiratoryAge
            )
        )
    }

    private func mean(_ values: [Double], fallback: Double) -> Double {
        guard !values.isEmpty else { return fallback }
        return values.reduce(0, +) / Double(values.count)
    }

    private func blend(previous: Double, instant: Double, samples: Int) -> Double {
        if samples <= 1 { return instant }
        return roundedAge(previous * 0.65 + instant * 0.35)
    }

    private func replaceLatestHistory() {
        guard !ageHistory.isEmpty else {
            appendHistory()
            return
        }
        ageHistory[ageHistory.count - 1] = AgeReading(
            date: .now,
            chronologicalAge: chronologicalAge,
            biologicalAge: biologicalAge,
            cardiacAge: cardiacAge,
            respiratoryAge: respiratoryAge
        )
    }

    private func roundedAge(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private static func seededHistory(
        chronologicalAge: Double,
        biologicalAge: Double,
        cardiacAge: Double,
        respiratoryAge: Double
    ) -> [AgeReading] {
        (0..<8).map { offset in
            let daysAgo = 7 - offset
            let progress = Double(offset) / 7.0
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            return AgeReading(
                date: date,
                chronologicalAge: chronologicalAge,
                biologicalAge: interpolate(from: chronologicalAge, to: biologicalAge, progress: progress),
                cardiacAge: interpolate(from: chronologicalAge, to: cardiacAge, progress: progress),
                respiratoryAge: interpolate(from: chronologicalAge, to: respiratoryAge, progress: progress)
            )
        }
    }

    private static func interpolate(from: Double, to: Double, progress: Double) -> Double {
        ((from + (to - from) * progress) * 10).rounded() / 10
    }

    func persistSoon() {
        RecoveryPersistence.save(self)
    }

    func restore(from snapshot: RecoverySnapshot) {
        userName = snapshot.userName
        chronologicalAge = snapshot.chronologicalAge
        biologicalAge = snapshot.biologicalAge
        cardiacAge = snapshot.cardiacAge
        respiratoryAge = snapshot.respiratoryAge
        garminData = snapshot.garminData
        latestScan = snapshot.latestScan
        scanHistory = snapshot.scanHistory
        authProvider = snapshot.authProvider
        dataSource = snapshot.dataSource
        hasCompletedBaseline = snapshot.hasCompletedBaseline
        ageHistory = snapshot.ageHistory
        connectedIntegrations = Set(snapshot.connectedIntegrations)
        isUsingLiveHealthKit = snapshot.isUsingLiveHealthKit
        dataSourceMode = snapshot.dataSourceMode
        activeHabits = Set(snapshot.activeHabits)
        factorBreakdown = snapshot.factorBreakdown
        riskMultiplier = snapshot.riskMultiplier
        riskBand = snapshot.riskBand
        mortalityRelativeRisk = snapshot.mortalityRelativeRisk
        respiratoryRate = snapshot.respiratoryRate
        activeEnergyBurned = snapshot.activeEnergyBurned
        selectedScenario = snapshot.selectedScenario
        healthKitStatus = snapshot.healthKitStatus
        recentPeakHeartRate = snapshot.recentPeakHeartRate
        cameraHeartRate = snapshot.cameraHeartRate
        cardiacEventRelativeRisk = snapshot.cardiacEventRelativeRisk
        hapticsEnabled = snapshot.hapticsEnabled
        chartRange = snapshot.chartRange
        profileEmail = snapshot.profileEmail
        healthContext = snapshot.healthContext
        latestCoachPlan = snapshot.latestCoachPlan
    }

    func snapshot() -> RecoverySnapshot {
        RecoverySnapshot(
            userName: userName,
            chronologicalAge: chronologicalAge,
            biologicalAge: biologicalAge,
            cardiacAge: cardiacAge,
            respiratoryAge: respiratoryAge,
            garminData: garminData,
            latestScan: latestScan,
            scanHistory: scanHistory,
            authProvider: authProvider,
            dataSource: dataSource,
            hasCompletedBaseline: hasCompletedBaseline,
            ageHistory: ageHistory,
            connectedIntegrations: Array(connectedIntegrations),
            isUsingLiveHealthKit: isUsingLiveHealthKit,
            dataSourceMode: dataSourceMode,
            activeHabits: Array(activeHabits),
            factorBreakdown: factorBreakdown,
            riskMultiplier: riskMultiplier,
            riskBand: riskBand,
            mortalityRelativeRisk: mortalityRelativeRisk,
            respiratoryRate: respiratoryRate,
            activeEnergyBurned: activeEnergyBurned,
            selectedScenario: selectedScenario,
            healthKitStatus: healthKitStatus,
            recentPeakHeartRate: recentPeakHeartRate,
            cameraHeartRate: cameraHeartRate,
            cardiacEventRelativeRisk: cardiacEventRelativeRisk,
            hapticsEnabled: hapticsEnabled,
            chartRange: chartRange,
            profileEmail: profileEmail,
            healthContext: healthContext,
            latestCoachPlan: latestCoachPlan
        )
    }

    func updateProfile(name: String, chronologicalAge: Double, email: String?) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chronologicalAge = chronologicalAge
        profileEmail = email
        if hasCompletedBaseline {
            recalculateBiologicalAge()
        }
        persistSoon()
    }

    static var freshStart: UserRecoveryState {
        UserRecoveryState(
            userName: "Alex",
            chronologicalAge: 30.0,
            biologicalAge: 30.0,
            cardiacAge: 30.0,
            respiratoryAge: 30.0,
            garminData: GarminTelemetry(
                sleepScore: 0,
                hrvStatus: 0,
                restingHeartRate: 0
            )
        )
    }

    static var mock: UserRecoveryState {
        let chronological = 30.0
        let biological = 26.2
        let cardiac = 27.4
        let respiratory = 28.1
        let state = UserRecoveryState(
            userName: "Alex",
            chronologicalAge: chronological,
            biologicalAge: biological,
            cardiacAge: cardiac,
            respiratoryAge: respiratory,
            garminData: GarminTelemetry(
                sleepScore: 86,
                hrvStatus: 62,
                restingHeartRate: 52
            ),
            latestScan: PreSageScan(
                hrrObserved: 34,
                minutesSinceAerobicActivity: 45,
                respiratoryRate: 13.2,
                vascularScore: 74
            ),
            scanHistory: [
                PreSageScan(
                    hrrObserved: 34,
                    minutesSinceAerobicActivity: 45,
                    respiratoryRate: 13.2,
                    vascularScore: 74
                )
            ],
            hasCompletedBaseline: true,
            ageHistory: seededHistory(
                chronologicalAge: chronological,
                biologicalAge: biological,
                cardiacAge: cardiac,
                respiratoryAge: respiratory
            )
        )
        state.recalculateBiologicalAge()
        return state
    }

    static var postScanPreview: UserRecoveryState {
        let state = UserRecoveryState(
            userName: "Alex",
            chronologicalAge: 30.0,
            biologicalAge: 30.0,
            cardiacAge: 30.0,
            respiratoryAge: 30.0,
            garminData: GarminTelemetry(
                sleepScore: 92,
                hrvStatus: 78,
                restingHeartRate: 48
            )
        )
        state.applyPreSageScan(
            hrrObserved: 36,
            respiratoryRate: 11.75,
            vascularScore: 88,
            minutesSinceAerobicActivity: 45
        )
        return state
    }
}
