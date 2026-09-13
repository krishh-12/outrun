//
//  HealthKitManager.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import Foundation
import HealthKit
import Observation

struct HealthKitVitals: Hashable {
    var restingHeartRate: Int
    var hrvSDNN: Int
    var sleepScore: Int
    var sleepHours: Double
    var stepCount: Int
    var respiratoryRate: Double
    var activeEnergyBurned: Double
    var peakHeartRate: Int
    var meanHeartRate: Int

    func asHealthContext() -> HealthContext {
        HealthContext(
            capturedAt: .now,
            sleepScore: sleepScore,
            sleepHours: sleepHours,
            stepCount: stepCount,
            restingHeartRate: restingHeartRate,
            hrvSDNN: hrvSDNN,
            respiratoryRate: respiratoryRate,
            activeEnergyBurned: activeEnergyBurned,
            peakHeartRate: peakHeartRate
        )
    }
}

@Observable
@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()

    let store = HKHealthStore()
    var lastSyncFailedGracefully = false
    var statusMessage: String?

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.respiratoryRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKQuantityType(.stepCount),
            HKCategoryType(.sleepAnalysis)
        ]
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isHealthDataAvailable else {
            lastSyncFailedGracefully = true
            statusMessage = "Health data is unavailable on this device. Demo Scenario Mode is on."
            completion(false)
            return
        }

        store.requestAuthorization(toShare: [], read: readTypes) { success, error in
            Task { @MainActor in
                if let error {
                    self.statusMessage = error.localizedDescription
                    self.lastSyncFailedGracefully = true
                    completion(false)
                    return
                }
                self.lastSyncFailedGracefully = !success
                self.statusMessage = success
                    ? "Apple Health connected."
                    : "Health authorization was not granted. Demo Scenario Mode is available."
                completion(success)
            }
        }
    }

    /// 7-day Apple Health baseline plus recent peak HR for HRR cross-reference.
    func fetchLatestVitals() async -> HealthKitVitals? {
        guard isHealthDataAvailable else {
            lastSyncFailedGracefully = true
            statusMessage = "Simulator or this device has no HealthKit store."
            return nil
        }

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let threeHoursAgo = Calendar.current.date(byAdding: .hour, value: -3, to: .now) ?? .now
        let bpm = HKUnit.count().unitDivided(by: .minute())

        async let hrv = statistic(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), start: weekAgo, options: .discreteAverage)
        async let rhr = statistic(.restingHeartRate, unit: bpm, start: weekAgo, options: .discreteAverage)
        async let resp = statistic(.respiratoryRate, unit: bpm, start: weekAgo, options: .discreteAverage)
        async let energy = statistic(.activeEnergyBurned, unit: .kilocalorie(), start: Calendar.current.startOfDay(for: .now), options: .cumulativeSum)
        async let sleep = latestSleep()
        async let peak = statistic(.heartRate, unit: bpm, start: threeHoursAgo, options: .discreteMax)
        async let meanHR = statistic(.heartRate, unit: bpm, start: threeHoursAgo, options: .discreteAverage)
        async let steps = statistic(
            .stepCount,
            unit: .count(),
            start: Calendar.current.startOfDay(for: .now),
            options: .cumulativeSum
        )

        let hrvValue = await hrv
        let rhrValue = await rhr
        let respValue = await resp
        let energyValue = await energy
        let sleepInfo = await sleep
        let peakValue = await peak
        let meanValue = await meanHR
        let stepValue = await steps

        let hasAnySample = [hrvValue, rhrValue, respValue, energyValue, sleepInfo?.hours, peakValue, stepValue].contains { $0 != nil }
        guard hasAnySample else {
            lastSyncFailedGracefully = true
            statusMessage = "No HealthKit samples yet. Open Apple Health, then tap Link Health again."
            return nil
        }

        lastSyncFailedGracefully = false
        statusMessage = "Apple Health sleep, steps, and vitals loaded."
        let sleepHours = sleepInfo?.hours ?? 0
        let sleepScore = sleepInfo?.score ?? Int(min(100, (sleepHours / 8.0) * 100).rounded())
        return HealthKitVitals(
            restingHeartRate: Int((rhrValue ?? 56).rounded()),
            hrvSDNN: Int((hrvValue ?? 50).rounded()),
            sleepScore: sleepScore,
            sleepHours: sleepHours,
            stepCount: Int((stepValue ?? 0).rounded()),
            respiratoryRate: respValue ?? 14,
            activeEnergyBurned: energyValue ?? 0,
            peakHeartRate: Int((peakValue ?? 0).rounded()),
            meanHeartRate: Int((meanValue ?? 0).rounded())
        )
    }

    /// Maps the most recent HealthKit samples into `UserRecoveryState`.
    func fetchLatestVitals(into state: UserRecoveryState) async -> Bool {
        guard let vitals = await fetchLatestVitals() else {
            state.fallbackToDemoMode(
                reason: statusMessage ?? "HealthKit unavailable. Demo Scenario Mode is on."
            )
            return false
        }
        state.applyLiveHealthKitVitals(vitals)
        return true
    }

    /// Preview / simulator helper that mimics a successful HealthKit read.
    static func mockVitals() -> HealthKitVitals {
        HealthKitVitals(
            restingHeartRate: 54,
            hrvSDNN: 61,
            sleepScore: 84,
            sleepHours: 7.4,
            stepCount: 8420,
            respiratoryRate: 13.2,
            activeEnergyBurned: 640,
            peakHeartRate: 168,
            meanHeartRate: 92
        )
    }

    private func statistic(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        options: HKStatisticsOptions
    ) async -> Double? {
        let type = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, stats, _ in
                let quantity = stats?.averageQuantity() ?? stats?.sumQuantity() ?? stats?.maximumQuantity()
                continuation.resume(returning: quantity?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func latestSleep() async -> (hours: Double, score: Int)? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let asleepSeconds = (samples as? [HKCategorySample] ?? []).reduce(0.0) { total, sample in
                    guard isAsleepCategory(sample.value) else { return total }
                    return total + sample.endDate.timeIntervalSince(sample.startDate)
                }
                guard asleepSeconds > 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                let hours = asleepSeconds / 3600
                let score = Int(min(100, (hours / 8.0) * 100).rounded())
                continuation.resume(returning: (hours, score))
            }
            store.execute(query)
        }
    }

}

private func isAsleepCategory(_ value: Int) -> Bool {
    let asleepValues: Set<Int> = [
        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
        HKCategoryValueSleepAnalysis.asleepREM.rawValue
    ]
    return asleepValues.contains(value)
}
