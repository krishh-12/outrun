//
//  RecoveryPersistence.swift
//  hackrice 16
//

import Foundation

struct RecoverySnapshot: Codable {
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
    var connectedIntegrations: [String]
    var isUsingLiveHealthKit: Bool
    var dataSourceMode: DataSourceMode
    var activeHabits: [RecoveryHabit]
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
    var healthContext: HealthContext?
    var latestCoachPlan: CoachPlan?
}

enum RecoveryPersistence {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func save(_ state: UserRecoveryState) {
        let key = (state.persistenceKey?.isEmpty == false) ? state.persistenceKey! : "local"
        if state.persistenceKey == nil || state.persistenceKey?.isEmpty == true {
            state.persistenceKey = key
        }
        do {
            let data = try encoder.encode(state.snapshot())
            try data.write(to: fileURL(for: key), options: [.atomic])
        } catch {
            print("outrun persistence save failed: \(error)")
        }
    }

    static func load(userId: String) -> RecoverySnapshot? {
        guard !userId.isEmpty else { return nil }
        let url = fileURL(for: userId)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(RecoverySnapshot.self, from: data)
        } catch {
            print("outrun persistence load failed: \(error)")
            return nil
        }
    }

    private static func fileURL(for userId: String) -> URL {
        let safe = userId.replacingOccurrences(of: "/", with: "_")
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = folder.appendingPathComponent("outrun", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("recovery-\(safe).json")
    }
}
