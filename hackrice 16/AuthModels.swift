//
//  AuthModels.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import Foundation

struct AuthUser: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var email: String?
    var provider: AuthProvider
}

enum AuthError: LocalizedError, Equatable {
    case cancelled
    case googleNotConfigured
    case missingPresenter
    case invalidCredential
    case emailTaken
    case accountNotFound
    case invalidPassword
    case missingEmail
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .googleNotConfigured:
            return "Add your iOS Google client ID to Info.plist (GIDClientID) and the matching reversed client ID URL scheme."
        case .missingPresenter:
            return "Could not find a window to present sign in."
        case .invalidCredential:
            return "That sign-in response was invalid. Try again."
        case .emailTaken:
            return "An account with that email already exists. Sign in instead."
        case .accountNotFound:
            return "No account found for that email."
        case .invalidPassword:
            return "Incorrect password."
        case .missingEmail:
            return "Enter a valid email and password."
        case .unknown(let message):
            return message
        }
    }
}

enum AuthConfig {
    static var googleClientID: String {
        let info = string(fromInfo: "GIDClientID")
        if isValidGoogleClientID(info) { return info }

        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let clientID = dict["CLIENT_ID"] as? String,
           isValidGoogleClientID(clientID) {
            return clientID
        }

        return info
    }

    static var isGoogleConfigured: Bool {
        isValidGoogleClientID(googleClientID)
    }

    static var reversedGoogleClientID: String {
        let explicit = string(fromInfo: "REVERSED_CLIENT_ID")
        if explicit.hasPrefix("com.googleusercontent.apps.") { return explicit }

        guard isGoogleConfigured else { return "" }
        let prefix = googleClientID.replacingOccurrences(
            of: ".apps.googleusercontent.com",
            with: ""
        )
        return "com.googleusercontent.apps.\(prefix)"
    }

    private static func string(fromInfo key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func isValidGoogleClientID(_ value: String) -> Bool {
        value.hasSuffix(".apps.googleusercontent.com") && !value.contains("PASTE")
    }
}
