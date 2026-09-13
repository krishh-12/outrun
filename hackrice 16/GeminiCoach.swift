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

struct RoadrunnerMessage: Identifiable, Hashable, Codable {
    var id: UUID
    var isUser: Bool
    var text: String
    var createdAt: Date
    var route: RoadrunnerRoute?

    init(
        id: UUID = UUID(),
        isUser: Bool,
        text: String,
        createdAt: Date = .now,
        route: RoadrunnerRoute? = nil
    ) {
        self.id = id
        self.isUser = isUser
        self.text = text
        self.createdAt = createdAt
        self.route = route
    }
}

enum RoadrunnerRoute: String, Codable, Hashable {
    case dash
    case data
    case insights
    case history
    case add
    case settings
    case scan

    var buttonTitle: String {
        switch self {
        case .dash: "Open Dash"
        case .data: "Open Data"
        case .insights: "See plan below"
        case .history: "Open History"
        case .add: "Open Add"
        case .settings: "Open Profile"
        case .scan: "Take a scan"
        }
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
    private static let maxQuestionCharacters = 240

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
    static func askRoadrunner(_ question: String, for state: UserRecoveryState) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let asked = String(trimmed.prefix(maxQuestionCharacters))
        let generation = state.roadrunnerGeneration
        state.roadrunnerMessages.append(RoadrunnerMessage(isUser: true, text: asked))
        state.roadrunnerStatus = nil

        if let local = RoadrunnerGuide.resolve(asked, state: state) {
            guard generation == state.roadrunnerGeneration else { return }
            state.roadrunnerMessages.append(
                RoadrunnerMessage(isUser: false, text: local.text, route: local.route)
            )
            return
        }

        if !RoadrunnerGuide.isOnTopic(asked) {
            guard generation == state.roadrunnerGeneration else { return }
            state.roadrunnerMessages.append(
                RoadrunnerMessage(
                    isUser: false,
                    text: "I only talk about your outrunn scan, ages, wearables, and Insights plan."
                )
            )
            return
        }

        if !state.hasCompletedBaseline {
            guard generation == state.roadrunnerGeneration else { return }
            state.roadrunnerMessages.append(
                RoadrunnerMessage(
                    isUser: false,
                    text: "Scan first from Dash. That’s how outrunn gets your ages and plan.",
                    route: .scan
                )
            )
            return
        }

        guard state.roadrunnerAsksRemaining > 0 else {
            guard generation == state.roadrunnerGeneration else { return }
            state.roadrunnerMessages.append(
                RoadrunnerMessage(
                    isUser: false,
                    text: "That’s today’s Gemini limit. Finding a screen still works — try Data, Insights, or come back tomorrow."
                )
            )
            return
        }

        guard !apiKey.isEmpty else {
            state.roadrunnerStatus = "Missing Gemini API key."
            return
        }
        guard !state.isAskingRoadrunner else { return }
        state.isAskingRoadrunner = true
        defer { state.isAskingRoadrunner = false }

        do {
            let parsed = try await requestRoadrunnerReply(question: asked, state: state)
            guard generation == state.roadrunnerGeneration else { return }
            state.consumeRoadrunnerAsk()
            state.roadrunnerMessages.append(
                RoadrunnerMessage(isUser: false, text: parsed.text, route: parsed.route)
            )
        } catch {
            guard generation == state.roadrunnerGeneration else { return }
            state.roadrunnerStatus = error.localizedDescription
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
                "stressScore": scan?.stressScore as Any,
                "stressScoreSource": "Presage Baevsky Stress Index from HRV",
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

    @MainActor
    private static func requestRoadrunnerReply(question: String, state: UserRecoveryState) async throws -> (text: String, route: RoadrunnerRoute?) {
        var lastError: Error = URLError(.badServerResponse)
        for model in models {
            do {
                return try await requestRoadrunnerReply(model: model, question: question, state: state)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    @MainActor
    private static func requestRoadrunnerReply(model: String, question: String, state: UserRecoveryState) async throws -> (text: String, route: RoadrunnerRoute?) {
        let prompt = """
        Athlete brief:
        \(RoadrunnerGuide.brief(for: state))

        Question:
        \(question)
        """
        let raw = try await generateText(
            model: model,
            systemPrompt: roadrunnerPrompt,
            userText: prompt,
            temperature: 0.5,
            json: false,
            maxOutputTokens: nil
        )
        return parseRoadrunnerPayload(raw)
    }

    private static func parseRoadrunnerPayload(_ raw: String) -> (text: String, route: RoadrunnerRoute?) {
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let object = jsonObject(from: cleaned) {
            let say = jsonString(object, keys: ["say", "text", "reply", "answer", "message", "content"])
                ?? object.values.compactMap { $0 as? String }
                    .filter { RoadrunnerRoute(rawValue: $0.lowercased()) == nil }
                    .max(by: { $0.count < $1.count })
            let open = jsonString(object, keys: ["open", "route", "tab"])?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let route = open.flatMap(RoadrunnerRoute.init(rawValue:))
            if let say, !say.isEmpty {
                return (sanitizeReply(say), route)
            }
        }

        var text = cleaned
        var route: RoadrunnerRoute?
        if let match = text.range(
            of: #"\nopen:\s*([a-z]+)\s*$"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            let line = String(text[match])
            let key = line
                .replacingOccurrences(of: "open:", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            route = RoadrunnerRoute(rawValue: key)
            text.removeSubrange(match)
        }
        return (sanitizeReply(text), route)
    }

    private static func jsonObject(from text: String) -> [String: Any]? {
        let slices: [String]
        if let range = text.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
            slices = [String(text[range]), text]
        } else {
            slices = [text]
        }
        for slice in slices {
            guard let data = slice.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }
            return object
        }
        return nil
    }

    private static func jsonString(_ object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = object[key] as? String, !value.isEmpty {
                return value
            }
            if let values = object[key] as? [String] {
                let joined = values.joined(separator: " ")
                if !joined.isEmpty { return joined }
            }
        }
        return nil
    }

    private static func sanitizeReply(_ text: String) -> String {
        text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "\\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
                        ["text": "Analyze this outrunn athlete snapshot and return JSON only:\n\(payloadJSON)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "responseMimeType": "application/json"
            ]
        ]

        let data = try await postGenerate(model: model, body: body)
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

    private static func generateText(
        model: String,
        systemPrompt: String,
        userText: String,
        temperature: Double,
        json: Bool,
        maxOutputTokens: Int?
    ) async throws -> String {
        var config: [String: Any] = [
            "temperature": temperature
        ]
        if let maxOutputTokens {
            config["maxOutputTokens"] = maxOutputTokens
        }
        if json {
            config["responseMimeType"] = "application/json"
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
                        ["text": userText]
                    ]
                ]
            ],
            "generationConfig": config
        ]
        let data = try await postGenerate(model: model, body: body)
        return try extractText(from: data)
    }

    private static func postGenerate(model: String, body: [String: Any]) async throws -> Data {
        var components = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        )
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

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
        return data
    }

    private static func extractText(from data: Data) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = object?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]] ?? []
        let text = parts.compactMap { part -> String? in
            if part["thought"] as? Bool == true { return nil }
            return part["text"] as? String
        }.joined()
        if !text.isEmpty { return text }
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

    private static let roadrunnerPrompt = """
    You are roadrunner, outrunn's in-app recovery guide.

    Answer only this question. You get a short athlete brief, not chat history and not extra files.

    Stay inside outrunn: this athlete's scan, Real / Biological / Cardiac / Pulmonary Age, Apple Health or Garmin numbers, and the Insights plan. If the question is outside that, say you only talk about their outrunn data.

    If they ask where something is, or what an existing screen means, reply in 1–2 sentences and end with:
    OPEN: dash|data|insights|history|add|settings|scan

    For why a number moved or what to do next: use their actual numbers, explain the likely driver, then give concrete next steps. Do not add an OPEN line unless a screen really helps.

    Voice:
    - Complete, useful answers. Do not truncate your thought. Short paragraphs are fine.
    - Names: Real Age, Biological Age, Cardiac Age, Pulmonary Age.
    - No diagnosis, no drugs, no invented studies, no JSON.
    """

    private static let systemPrompt = """
    You are outrunn's recovery scientist. Inputs are numbers only (Presage camera scan + Apple Health / Garmin / watch). Never video.

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

enum RoadrunnerGuide {
    struct Answer {
        var text: String
        var route: RoadrunnerRoute?
    }

    @MainActor
    static func resolve(_ question: String, state: UserRecoveryState) -> Answer? {
        let q = normalize(question)
        guard !q.isEmpty else { return nil }

        if let fact = factAnswer(q, state: state) {
            return fact
        }

        let interpretive = containsAny(q, [
            "why", "should i", "what should", "how can i", "how do i improve",
            "how do i lower", "how do i reduce", "how do i fix", "tonight",
            "what do i do", "what would you"
        ])
        let wantsPlace = containsAny(q, [
            "where", "find", "take me", "open", "go to", "show me", "which tab",
            "which page", "where can i", "navigate", "bring me", "how do i get",
            "how do i find", "how do i open", "how do i see", "how do i take",
            "how do i start", "how do i scan", "take me to"
        ])
        let wantsExplain = containsAny(q, [
            "what is", "whats", "explain", "what does", "meaning", "methodology",
            "how we got", "how you got", "how did you", "how do you calculate",
            "how is it calculated", "how is this calculated", "tell me about",
            "what are"
        ])

        guard wantsPlace || (wantsExplain && !interpretive) else { return nil }
        guard let route = route(for: q) else { return nil }
        return Answer(text: copy(for: route), route: route)
    }

    static func isOnTopic(_ question: String) -> Bool {
        let q = normalize(question)
        if containsAny(q, [
            "ignore previous", "ignore all", "system prompt", "you are now",
            "jailbreak", "api key", "developer mode", "repeat this prompt",
            "reveal your", "hidden instructions"
        ]) {
            return false
        }
        return containsAny(q, [
            "age", "scan", "pulse", "heart", "cardiac", "pulmonary", "biological",
            "recovery", "sleep", "stress", "breathing", "hrv", "insight", "plan",
            "train", "workout", "dash", "data", "history", "garmin", "health",
            "outrun", "outrunn", "roadrunner", "roadruner", "baseline", "camera", "zone", "steps",
            "tonight", "this week", "should i", "why is", "what should",
            "how can i", "supplement", "real age", "wearable", "apple",
            "presage", "methodology", "older", "younger", "rhr", "vo2",
            "breath", "resting", "hrr"
        ])
    }

    @MainActor
    static func brief(for state: UserRecoveryState) -> String {
        let chrono = state.chronologicalAge
        let scan = state.latestScan
        let health = state.healthContext
        let plan = state.latestCoachPlan
        var lines = [
            "Real Age: \(years(chrono))",
            "Biological Age: \(years(state.biologicalAge)) (\(vsReal(state.biologicalAge, chrono: chrono)))",
            "Cardiac Age: \(years(state.cardiacAge)) (\(vsReal(state.cardiacAge, chrono: chrono)))",
            "Pulmonary Age: \(years(state.pulmonaryAge)) (\(vsReal(state.pulmonaryAge, chrono: chrono)))"
        ]
        if let scan {
            lines.append(
                "Last scan: pulse \(scan.cameraHeartRate) bpm, breathing \(Int(scan.respiratoryRate.rounded()))/min, recovery \(scan.hrrObserved) beats, stress \(Int(scan.stressScore.rounded())), quality \(Int(scan.signalQuality.rounded())), \(scan.minutesSinceAerobicActivity) min after workout"
            )
        }
        if let health {
            lines.append(
                "Wearables: sleep \(String(format: "%.1f", health.sleepHours)) h, RHR \(health.restingHeartRate), HRV \(health.hrvSDNN), steps \(health.stepCount)"
            )
        } else if state.garminData.sleepScore > 0 {
            lines.append(
                "Wearables: sleep \(state.garminData.sleepScore)%, RHR \(state.garminData.restingHeartRate), HRV \(state.garminData.hrvStatus)"
            )
        }
        if let plan {
            lines.append("Plan: \(plan.headline)")
            if let today = plan.today.first {
                lines.append("Today: \(today)")
            }
        }
        return lines.joined(separator: "\n")
    }

    @MainActor
    private static func factAnswer(_ q: String, state: UserRecoveryState) -> Answer? {
        let askingMine = containsAny(q, ["what is my", "whats my", "how old am i", "what are my"])
        guard askingMine, state.hasCompletedBaseline else { return nil }
        let chrono = state.chronologicalAge
        if containsAny(q, ["biological"]) {
            return Answer(
                text: "Biological Age is \(years(state.biologicalAge)) — \(vsReal(state.biologicalAge, chrono: chrono)).",
                route: .data
            )
        }
        if containsAny(q, ["cardiac", "heart age"]) {
            return Answer(
                text: "Cardiac Age is \(years(state.cardiacAge)) — \(vsReal(state.cardiacAge, chrono: chrono)).",
                route: .data
            )
        }
        if containsAny(q, ["pulmonary", "lung"]) {
            return Answer(
                text: "Pulmonary Age is \(years(state.pulmonaryAge)) — \(vsReal(state.pulmonaryAge, chrono: chrono)).",
                route: .data
            )
        }
        if containsAny(q, ["real age", "calendar"]) {
            return Answer(text: "Real Age is \(years(chrono)).", route: .data)
        }
        if containsAny(q, ["pulse", "heart rate", " bpm"]) {
            let pulse = state.latestScan?.cameraHeartRate ?? state.cameraHeartRate
            guard pulse > 0 else { return nil }
            return Answer(text: "Last scan pulse was \(pulse) bpm.", route: .data)
        }
        if containsAny(q, ["breathing", "respiratory"]) {
            guard let rate = state.latestScan?.respiratoryRate, rate > 0 else { return nil }
            return Answer(text: "Last scan breathing was \(Int(rate.rounded())) breaths/min.", route: .data)
        }
        if containsAny(q, ["stress"]) {
            guard let score = state.latestScan?.stressScore, score > 0 else { return nil }
            return Answer(text: "Last scan stress was \(Int(score.rounded())).", route: .data)
        }
        if containsAny(q, ["sleep"]) {
            if state.garminData.sleepScore > 0 {
                return Answer(text: "Sleep is \(state.garminData.sleepScore)%.", route: .data)
            }
            if let hours = state.healthContext?.sleepHours, hours > 0 {
                return Answer(text: "Last night was \(String(format: "%.1f", hours)) hours of sleep.", route: .data)
            }
        }
        return nil
    }

    private static func route(for q: String) -> RoadrunnerRoute? {
        if containsAny(q, ["scan", "camera", "baseline", "presage", "rppg", "face scan"]) {
            return .scan
        }
        if containsAny(q, ["history", "past scan", "previous scan", "old scan", "past result"]) {
            return .history
        }
        if containsAny(q, [
            "apple health", "healthkit", "garmin", "whoop", "oura",
            "connect a", "connect my", "wearable"
        ]) {
            return .add
        }
        if hasWord(q, "add") && containsAny(q, ["tab", "page", "screen", "where", "open", "go to"]) {
            return .add
        }
        if containsAny(q, [
            "settings", "profile", "log out", "logout", "sign out", "reset",
            "haptics", "account", "gear icon", "the gear"
        ]) {
            return .settings
        }
        if containsAny(q, [
            "methodology", "how we got", "how you got", "how did you",
            "how do you calculate", "how is it calculated", "data tab",
            "data page", "data screen", "the numbers", "my numbers", "pulse",
            "breathing", "stress", "cardiac age", "biological age",
            "pulmonary age", "real age"
        ]) || hasWord(q, "data") {
            return .data
        }
        if containsAny(q, ["insights", "my plan", "the plan", "supplement", "repopulate", "do this today"]) {
            return .insights
        }
        if containsAny(q, ["dashboard", "age chart", "age graph", "age trend"])
            || hasWord(q, "dash") || hasWord(q, "chart") || hasWord(q, "graph") || hasWord(q, "trends") {
            return .dash
        }
        return nil
    }

    private static func copy(for route: RoadrunnerRoute) -> String {
        switch route {
        case .scan:
            "Take a scan from Dash. I’ll open it."
        case .data:
            "Those numbers live on Data — ages, pulse, breathing, recovery, and how we got them."
        case .history:
            "Past scans are on History."
        case .add:
            "Connect Apple Health or Garmin from Add."
        case .settings:
            "Profile, reset, and log out are behind the gear icon."
        case .dash:
            "Trends and the age chart are on Dash."
        case .insights:
            "Your plan is on this Insights page, just below the chat."
        }
    }

    private static func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "['’]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsAny(_ q: String, _ phrases: [String]) -> Bool {
        phrases.contains { q.contains($0) }
    }

    private static func hasWord(_ q: String, _ word: String) -> Bool {
        q.range(of: "\\b\(word)\\b", options: .regularExpression) != nil
    }

    private static func years(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func vsReal(_ value: Double, chrono: Double) -> String {
        let delta = value - chrono
        if abs(delta) < 0.3 { return "about the same as Real Age" }
        if delta > 0 {
            return String(format: "%.1f years older than Real Age", delta)
        }
        return String(format: "%.1f years younger than Real Age", abs(delta))
    }
}
