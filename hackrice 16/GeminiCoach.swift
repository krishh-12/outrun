//
//  GeminiCoach.swift
//  hackrice 16
//
//  Sends scan vitals + Apple Health context (never video) to Gemini
//  and stores a structured recovery plan.
//

import Foundation

struct CoachDriver: Hashable, Codable {
    var factor: String
    var impact: String
    var note: String
}

struct CoachPlan: Hashable, Codable {
    var generatedAt: Date
    var headline: String
    var summary: String
    var scanVsLifestyle: String
    var ageGroup: String
    var recoveryWindow: String
    var studyNotes: String
    var scanImpliedAge: Double?
    var lifestyleImpliedAge: Double?
    var adjustedBiologicalAge: Double?
    var drivers: [CoachDriver]
    var today: [String]
    var thisWeek: [String]
    var training: [String]
    var recovery: [String]
    var longTerm: [String]
    var supplements: [String]
    var caution: String?

    init(
        generatedAt: Date = .now,
        headline: String,
        summary: String,
        scanVsLifestyle: String,
        ageGroup: String = "",
        recoveryWindow: String = "",
        studyNotes: String = "",
        scanImpliedAge: Double? = nil,
        lifestyleImpliedAge: Double? = nil,
        adjustedBiologicalAge: Double? = nil,
        drivers: [CoachDriver],
        today: [String],
        thisWeek: [String],
        training: [String],
        recovery: [String],
        longTerm: [String] = [],
        supplements: [String] = [],
        caution: String? = nil
    ) {
        self.generatedAt = generatedAt
        self.headline = headline
        self.summary = summary
        self.scanVsLifestyle = scanVsLifestyle
        self.ageGroup = ageGroup
        self.recoveryWindow = recoveryWindow
        self.studyNotes = studyNotes
        self.scanImpliedAge = scanImpliedAge
        self.lifestyleImpliedAge = lifestyleImpliedAge
        self.adjustedBiologicalAge = adjustedBiologicalAge
        self.drivers = drivers
        self.today = today
        self.thisWeek = thisWeek
        self.training = training
        self.recovery = recovery
        self.longTerm = longTerm
        self.supplements = supplements
        self.caution = caution
    }

    enum CodingKeys: String, CodingKey {
        case generatedAt, headline, summary, scanVsLifestyle, ageGroup, recoveryWindow
        case studyNotes, scanImpliedAge, lifestyleImpliedAge, adjustedBiologicalAge
        case drivers, today, thisWeek, training, recovery, longTerm, supplements, caution
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decodeIfPresent(Date.self, forKey: .generatedAt) ?? .now
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        headline = try container.decodeIfPresent(String.self, forKey: .headline) ?? summary
        scanVsLifestyle = try container.decodeIfPresent(String.self, forKey: .scanVsLifestyle) ?? ""
        ageGroup = try container.decodeIfPresent(String.self, forKey: .ageGroup) ?? ""
        recoveryWindow = try container.decodeIfPresent(String.self, forKey: .recoveryWindow) ?? ""
        studyNotes = try container.decodeIfPresent(String.self, forKey: .studyNotes) ?? ""
        scanImpliedAge = try container.decodeIfPresent(Double.self, forKey: .scanImpliedAge)
        lifestyleImpliedAge = try container.decodeIfPresent(Double.self, forKey: .lifestyleImpliedAge)
        adjustedBiologicalAge = try container.decodeIfPresent(Double.self, forKey: .adjustedBiologicalAge)
        drivers = try container.decodeIfPresent([CoachDriver].self, forKey: .drivers) ?? []
        today = try container.decodeIfPresent([String].self, forKey: .today) ?? []
        thisWeek = try container.decodeIfPresent([String].self, forKey: .thisWeek) ?? []
        training = try container.decodeIfPresent([String].self, forKey: .training) ?? []
        recovery = try container.decodeIfPresent([String].self, forKey: .recovery) ?? []
        longTerm = try container.decodeIfPresent([String].self, forKey: .longTerm) ?? []
        supplements = try container.decodeIfPresent([String].self, forKey: .supplements) ?? []
        caution = try container.decodeIfPresent(String.self, forKey: .caution)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(generatedAt, forKey: .generatedAt)
        try container.encode(headline, forKey: .headline)
        try container.encode(summary, forKey: .summary)
        try container.encode(scanVsLifestyle, forKey: .scanVsLifestyle)
        try container.encode(ageGroup, forKey: .ageGroup)
        try container.encode(recoveryWindow, forKey: .recoveryWindow)
        try container.encode(studyNotes, forKey: .studyNotes)
        try container.encodeIfPresent(scanImpliedAge, forKey: .scanImpliedAge)
        try container.encodeIfPresent(lifestyleImpliedAge, forKey: .lifestyleImpliedAge)
        try container.encodeIfPresent(adjustedBiologicalAge, forKey: .adjustedBiologicalAge)
        try container.encode(drivers, forKey: .drivers)
        try container.encode(today, forKey: .today)
        try container.encode(thisWeek, forKey: .thisWeek)
        try container.encode(training, forKey: .training)
        try container.encode(recovery, forKey: .recovery)
        try container.encode(longTerm, forKey: .longTerm)
        try container.encode(supplements, forKey: .supplements)
        try container.encodeIfPresent(caution, forKey: .caution)
    }
}

private struct GeminiPlanPayload: Codable {
    var headline: String?
    var summary: String
    var scanVsLifestyle: String
    var ageGroup: String?
    var recoveryWindow: String?
    var studyNotes: String?
    var scanImpliedAge: Double?
    var lifestyleImpliedAge: Double?
    var adjustedBiologicalAge: Double?
    var drivers: [CoachDriver]
    var plan: Plan
    var caution: String?

    struct Plan: Codable {
        var today: [String]
        var thisWeek: [String]
        var training: [String]
        var recovery: [String]
        var longTerm: [String]
        var supplements: [String]

        enum CodingKeys: String, CodingKey {
            case today, thisWeek, training, recovery, longTerm, supplements
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            today = try container.decodeIfPresent([String].self, forKey: .today) ?? []
            thisWeek = try container.decodeIfPresent([String].self, forKey: .thisWeek) ?? []
            training = try container.decodeIfPresent([String].self, forKey: .training) ?? []
            recovery = try container.decodeIfPresent([String].self, forKey: .recovery) ?? []
            longTerm = try container.decodeIfPresent([String].self, forKey: .longTerm) ?? []
            supplements = try container.decodeIfPresent([String].self, forKey: .supplements) ?? []
        }
    }
}

enum GeminiCoach {
    private static let models = [
        "gemini-3.6-flash"
    ]

    private static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @MainActor
    static func refreshPlan(for state: UserRecoveryState) async {
        guard !apiKey.isEmpty else {
            state.coachStatus = "Missing Gemini API key."
            return
        }
        state.isRefreshingCoach = true
        state.coachStatus = "Gemini is writing your plan…"
        defer { state.isRefreshingCoach = false }

        do {
            let payload = snapshotJSON(from: state)
            let parsed = try await requestPlan(payloadJSON: payload)
            let clamped = boundedAges(from: parsed, state: state)
            let plan = CoachPlan(
                generatedAt: .now,
                headline: parsed.headline ?? parsed.summary,
                summary: parsed.summary,
                scanVsLifestyle: parsed.scanVsLifestyle,
                ageGroup: parsed.ageGroup ?? "",
                recoveryWindow: parsed.recoveryWindow ?? "",
                studyNotes: parsed.studyNotes ?? "",
                scanImpliedAge: clamped.scan,
                lifestyleImpliedAge: clamped.lifestyle,
                adjustedBiologicalAge: clamped.adjusted,
                drivers: parsed.drivers,
                today: parsed.plan.today,
                thisWeek: parsed.plan.thisWeek,
                training: parsed.plan.training,
                recovery: parsed.plan.recovery,
                longTerm: parsed.plan.longTerm,
                supplements: parsed.plan.supplements,
                caution: parsed.caution
            )
            state.latestCoachPlan = plan
            if let adjusted = clamped.adjusted {
                let engine = state.biologicalAge
                let geminiAge = shouldBlockYouthPull(adjusted: adjusted, engine: engine, state: state)
                    ? engine
                    : adjusted
                let blended = engine * 0.55 + geminiAge * 0.45
                state.applyCoachBiologicalAge(blended)
            }
            state.coachStatus = nil
            state.persistSoon()
        } catch {
            state.coachStatus = error.localizedDescription
        }
    }

    @MainActor
    private static func snapshotJSON(from state: UserRecoveryState) -> String {
        let scan = state.latestScan
        let health = state.healthContext
        let chrono = state.chronologicalAge
        let minutes = scan?.minutesSinceAerobicActivity ?? 0
        let ageGroup: String
        switch chrono {
        case ..<30: ageGroup = "18–29"
        case 30..<40: ageGroup = "30–39"
        case 40..<50: ageGroup = "40–49"
        case 50..<60: ageGroup = "50–59"
        default: ageGroup = "60+"
        }
        let expectedHRR = max(12, 32.0 - ((chrono - 20) * 0.22))
        let expectedRHR = 62.0 + max(0, chrono - 30) * 0.12
        let expectedHRV = max(28, 72.0 - ((chrono - 20) * 0.55))
        let recoveryPhase: String
        switch minutes {
        case ..<15: recoveryPhase = "immediate (HR still elevated; do not treat as resting age)"
        case 15..<60: recoveryPhase = "early recovery (1-hour window; Cole HRR most valid here)"
        case 60..<24 * 60: recoveryPhase = "same-day recovery"
        default: recoveryPhase = "rested / next-day baseline"
        }

        let object: [String: Any] = [
            "profile": [
                "chronologicalAge": chrono,
                "ageGroup": ageGroup,
                "engineBiologicalAge": state.biologicalAge,
                "engineCardiacAge": state.cardiacAge,
                "enginePulmonaryAge": state.pulmonaryAge
            ],
            "workoutContext": [
                "minutesSinceAerobicActivity": minutes,
                "userReportedMinutesAfterWorkout": minutes,
                "recoveryPhase": recoveryPhase
            ],
            "scan": [
                "cameraHeartRate": scan?.cameraHeartRate as Any,
                "respiratoryRate": scan?.respiratoryRate as Any,
                "hrrObserved": scan?.hrrObserved as Any,
                "signalQuality": scan?.signalQuality as Any,
                "scanCount": state.scanHistory.count
            ],
            "wearables": [
                "source": state.dataSource?.title ?? "unknown",
                "garminOrWatchRestingHR": state.garminData.restingHeartRate,
                "garminOrWatchHRV": state.garminData.hrvStatus,
                "garminOrWatchSleepScore": state.garminData.sleepScore
            ],
            "appleHealth": [
                "linked": health != nil,
                "sleepHours": health?.sleepHours as Any,
                "sleepScore": health?.sleepScore as Any,
                "steps": health?.stepCount as Any,
                "hrvSDNN": health?.hrvSDNN as Any,
                "restingHeartRate": health?.restingHeartRate as Any,
                "activeEnergyKcal": health?.activeEnergyBurned as Any
            ],
            "studyBaselines": [
                "notes": "Cole 1999 NEJM: 1-min HRR ≤12 bpm is abnormal. Zhang 2016 CMAJ: resting HR vs mortality. Tsuji 1996 Circulation: low HRV (SDNN) vs Framingham mortality. Adult sleep 7–9h; ~8k steps as a modest activity floor. Resting rPPG is not a treadmill HRR test.",
                "expectedHRR_bpm": expectedHRR,
                "expectedRestingHR_bpm": expectedRHR,
                "expectedHRV_sdnn_ms": expectedHRV,
                "expectedSleepHours": 7.5
            ],
            "ageBounds": [
                "doNotGoYoungerThan": max(18, chrono - 8),
                "doNotGoOlderThan": min(90, chrono + 12),
                "note": "Non-clinical adults stay within ~8 years younger and ~12 years older than chronological age. Never output a teenage biological age for an adult."
            ]
        ]
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func requestPlan(payloadJSON: String) async throws -> GeminiPlanPayload {
        var lastError: Error = URLError(.badServerResponse)
        for model in models {
            do {
                return try await requestPlan(model: model, payloadJSON: payloadJSON)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private static func requestPlan(model: String, payloadJSON: String) async throws -> GeminiPlanPayload {
        var components = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        )
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "systemInstruction": [
                "parts": [
                    ["text": systemPrompt]
                ]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "Analyze this outrun athlete snapshot and return JSON only:\n\(payloadJSON)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "responseMimeType": "application/json"
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(status) else {
            let snippet = String(data: data, encoding: .utf8)?.prefix(280) ?? ""
            throw NSError(
                domain: "GeminiCoach",
                code: status,
                userInfo: [NSLocalizedDescriptionKey: "Gemini request failed (\(status)). \(snippet)"]
            )
        }

        let text = try extractText(from: data)
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = cleaned.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        return try JSONDecoder().decode(GeminiPlanPayload.self, from: jsonData)
    }

    private static func extractText(from data: Data) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = object?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        if let text = parts?.compactMap({ $0["text"] as? String }).joined(), !text.isEmpty {
            return text
        }
        throw URLError(.cannotParseResponse)
    }

    private struct ClampedAges {
        var scan: Double?
        var lifestyle: Double?
        var adjusted: Double?
    }

    private static func boundedAges(from parsed: GeminiPlanPayload, state: UserRecoveryState) -> ClampedAges {
        let chrono = state.chronologicalAge
        let minutes = state.latestScan?.minutesSinceAerobicActivity ?? 0
        let quality = state.latestScan?.signalQuality ?? 0
        let tight = quality > 0 && quality < 70
        let scanYounger = minutes < 15 ? 0.0 : (tight ? 4.0 : 8.0)
        let lifestyleYounger = tight ? 4.0 : 6.0
        let adjustedYounger: Double
        if minutes < 15 {
            adjustedYounger = 0
        } else if tight {
            adjustedYounger = 4
        } else if quality >= 80, minutes >= 60 {
            adjustedYounger = 10
        } else {
            adjustedYounger = 8
        }

        return ClampedAges(
            scan: parsed.scanImpliedAge.map {
                BiologicalAgeBounds.clamp($0, chronological: chrono, younger: scanYounger, older: tight ? 4.0 : 10.0)
            },
            lifestyle: parsed.lifestyleImpliedAge.map {
                BiologicalAgeBounds.clamp($0, chronological: chrono, younger: lifestyleYounger, older: tight ? 4.0 : 12.0)
            },
            adjusted: parsed.adjustedBiologicalAge.map {
                BiologicalAgeBounds.clamp($0, chronological: chrono, younger: adjustedYounger, older: tight ? 4.0 : 12.0)
            }
        )
    }

    private static func shouldBlockYouthPull(adjusted: Double, engine: Double, state: UserRecoveryState) -> Bool {
        guard adjusted < engine else { return false }
        let health = state.healthContext
        let sleepOK = (health?.sleepHours ?? 0) >= 7.0 || state.garminData.sleepScore >= 80
        let hrvValue = max(state.garminData.hrvStatus, health?.hrvSDNN ?? 0)
        let hrvOK = hrvValue >= 55
        let rhr = health?.restingHeartRate ?? state.garminData.restingHeartRate
        let rhrOK = rhr > 0 && rhr <= 60
        return !(sleepOK && hrvOK && rhrOK)
    }

    private static let systemPrompt = """
    You are outrun's recovery scientist. Inputs are numbers only (Presage camera scan + Apple Health / Garmin / watch). Never video.

    Compare THREE layers:
    1) Scan (pulse, breathing, HRR, signal quality) — camera physiology at this moment.
    2) Wearables (Apple Health / Garmin RHR, HRV, sleep, steps) — last-day/week lifestyle.
    3) Age-group study baselines provided (Cole 1999 HRR, Zhang 2016 resting HR, Tsuji 1996 HRV, 7–9h sleep).

    Factor minutesSinceAerobicActivity (user-set Time After Workout slider, 0–240 minutes). Treat it as ground truth for recovery phase:
    - Under 15 min: elevated HR is expected; do NOT call the person biologically older from that alone, and do NOT call them younger than chronological age from this scan.
    - 15–60 min: Cole 1-min HRR is most meaningful; compare observed HRR to expectedHRR_bpm for their age group.
    - Hours later: resting HR / HRV should be near wearable baseline; leftover elevation is recovery debt.
    Always mention this recovery window in recoveryWindow.

    Age realism (required):
    - For non-clinical adults, biological age stays within ~8 years younger and ~12 years older than chronological age.
    - Never output a teenage biological age for someone 18+. Floor is max(18, chrono − 8) unless a high-quality rested scan AND independently young HRV/RHR/sleep all agree, in which case floor is max(18, chrono − 10).
    - A resting rPPG scan is NOT a treadmill 1-min HRR test. If there is no real peak HR, do not treat hrrObserved as elite recovery.
    - If engineBiologicalAge is already more than 8 years younger than chronological age, correct toward chronological age unless HRV, RHR, and sleep independently agree.
    - Prefer conservative (closer to chronological) when signalQuality < 70.

    If sleep or steps are poor, attribute that slice of "older" age to lifestyle, not to the scan.
    If the scan is weak (low signalQuality) say so.

    Estimate:
    - scanImpliedAge: age implied by camera HRR/resp alone (bounded as above)
    - lifestyleImpliedAge: age implied by sleep/steps/RHR/HRV (bounded as above)
    - adjustedBiologicalAge: your best combined estimate after removing incomplete-recovery and lifestyle confounders (bounded as above)

    Voice: warm, specific, not clinical-robotic. Short paragraphs. No diagnosis.

    Return JSON:
    headline (punchy 1 sentence),
    summary (2–4 sentences, readable),
    scanVsLifestyle (how scan vs Apple Health/Garmin disagree or agree),
    ageGroup (echo the band),
    recoveryWindow (plain language about time since workout),
    studyNotes (1–3 sentences citing Cole/Zhang/Tsuji or sleep/steps norms vs THIS person),
    scanImpliedAge (number),
    lifestyleImpliedAge (number),
    adjustedBiologicalAge (number),
    drivers (array of {factor, impact: helping|hurting|neutral, note} — max 4),
    plan {
      today (2–4 bullets),
      thisWeek (2–4 bullets),
      training (2–4 bullets),
      recovery (2–4 bullets),
      longTerm (2–4 bullets about 8–12 week improvement: zone-2 consistency, VO2 work, sleep regularity, strength),
      supplements (2–4 conservative, evidence-tied suggestions such as vitamin D if indoor, omega-3, magnesium glycinate for sleep. No mega-doses, no unproven anti-aging stacks. Say to confirm with a clinician. Not medical advice.)
    },
    caution (string or null).
    """
}
