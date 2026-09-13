//
//  AuthService.swift
//  outrunn
//
//  Created by Krish Hariharan on 9/12/26.
//

import AuthenticationServices
import CryptoKit
import Foundation
import GoogleSignIn
import UIKit

@Observable
@MainActor
final class AuthService {
    private static let accountsKey = "auth.accounts.v1"
    private static let sessionKey = "auth.session.v1"

    private(set) var currentUser: AuthUser?
    var isBusy = false
    var errorMessage: String?

    @ObservationIgnored
    private let appleCoordinator = AppleSignInCoordinator()

    init() {
        configureGoogleIfNeeded()
        restoreSession()
    }

    func handleOpenURL(_ url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }

    func signInWithApple() async throws -> AuthUser {
        beginWork()
        defer { isBusy = false }

        do {
            let credential = try await appleCoordinator.start()
            let appleUserID = credential.user

            if let existing = accounts().first(where: { $0.appleUserID == appleUserID }) {
                return try persistSession(from: existing)
            }

            let email = credential.email?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = PersonNameComponentsFormatter.localizedString(
                from: credential.fullName ?? PersonNameComponents(),
                style: .default
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

            let account = StoredAccount(
                id: appleUserID,
                name: name.isEmpty ? (email?.split(separator: "@").first.map(String.init) ?? "runner") : name,
                email: email?.lowercased(),
                provider: .apple,
                appleUserID: appleUserID
            )
            return try persistNewAccount(account)
        } catch {
            throw mapAndStore(error)
        }
    }

    func signInWithGoogle() async throws -> AuthUser {
        beginWork()
        defer { isBusy = false }

        guard AuthConfig.isGoogleConfigured else {
            throw mapAndStore(AuthError.googleNotConfigured)
        }

        guard let presenter = UIApplication.shared.outrunTopViewController else {
            throw mapAndStore(AuthError.missingPresenter)
        }

        do {
            configureGoogleIfNeeded()
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            let googleUser = result.user
            let googleID = googleUser.userID ?? UUID().uuidString
            let email = googleUser.profile?.email.lowercased()
            let name = googleUser.profile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? "runner"

            if let existing = accounts().first(where: {
                $0.googleUserID == googleID || (email != nil && $0.email == email)
            }) {
                return try persistSession(from: existing)
            }

            let account = StoredAccount(
                id: googleID,
                name: name.isEmpty ? "runner" : name,
                email: email,
                provider: .google,
                googleUserID: googleID
            )
            return try persistNewAccount(account)
        } catch {
            throw mapAndStore(error)
        }
    }

    func signUpWithEmail(name: String, email: String, password: String) async throws -> AuthUser {
        beginWork()
        defer { isBusy = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let displayName = trimmedName.isEmpty
            ? (normalizedEmail.split(separator: "@").first.map(String.init) ?? "runner")
            : trimmedName

        guard normalizedEmail.contains("@"), normalizedEmail.contains("."), password.count >= 6 else {
            throw mapAndStore(AuthError.missingEmail)
        }

        var stored = accounts()
        if stored.contains(where: { $0.email == normalizedEmail }) {
            throw mapAndStore(AuthError.emailTaken)
        }

        do {
            let salt = PasswordHasher.randomSalt()
            let account = StoredAccount(
                id: UUID().uuidString,
                name: displayName,
                email: normalizedEmail,
                provider: .email,
                passwordSalt: salt,
                passwordHash: PasswordHasher.hash(password, salt: salt)
            )
            stored.append(account)
            try saveAccounts(stored)
            return try persistSession(from: account)
        } catch {
            throw mapAndStore(error)
        }
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthUser {
        beginWork()
        defer { isBusy = false }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let account = accounts().first(where: { $0.email == normalizedEmail && $0.provider == .email }) else {
            throw mapAndStore(AuthError.accountNotFound)
        }
        guard let salt = account.passwordSalt,
              let hash = account.passwordHash,
              PasswordHasher.verify(password, salt: salt, hash: hash) else {
            throw mapAndStore(AuthError.invalidPassword)
        }

        do {
            return try persistSession(from: account)
        } catch {
            throw mapAndStore(error)
        }
    }

    func signOut() {
        currentUser = nil
        errorMessage = nil
        KeychainStore.delete(for: Self.sessionKey)
        GIDSignIn.sharedInstance.signOut()
    }

    func clearError() {
        errorMessage = nil
    }

    private func configureGoogleIfNeeded() {
        guard AuthConfig.isGoogleConfigured else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AuthConfig.googleClientID)
    }

    private func restoreSession() {
        guard let data = KeychainStore.load(for: Self.sessionKey),
              let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            currentUser = nil
            return
        }
        currentUser = user
    }

    private func accounts() -> [StoredAccount] {
        guard let data = KeychainStore.load(for: Self.accountsKey) else { return [] }
        return (try? JSONDecoder().decode([StoredAccount].self, from: data)) ?? []
    }

    private func saveAccounts(_ accounts: [StoredAccount]) throws {
        let data = try JSONEncoder().encode(accounts)
        try KeychainStore.save(data, for: Self.accountsKey)
    }

    private func persistNewAccount(_ account: StoredAccount) throws -> AuthUser {
        var stored = accounts()
        stored.append(account)
        try saveAccounts(stored)
        return try persistSession(from: account)
    }

    private func persistSession(from account: StoredAccount) throws -> AuthUser {
        let user = account.asUser
        let data = try JSONEncoder().encode(user)
        try KeychainStore.save(data, for: Self.sessionKey)
        currentUser = user
        errorMessage = nil
        return user
    }

    private func beginWork() {
        isBusy = true
        errorMessage = nil
    }

    private func mapAndStore(_ error: Error) -> AuthError {
        let mapped = AuthError.wrap(error)
        if mapped != .cancelled {
            errorMessage = mapped.errorDescription
        }
        return mapped
    }
}

private struct StoredAccount: Codable {
    var id: String
    var name: String
    var email: String?
    var provider: AuthProvider
    var passwordSalt: Data?
    var passwordHash: Data?
    var appleUserID: String?
    var googleUserID: String?

    var asUser: AuthUser {
        AuthUser(id: id, name: name, email: email, provider: provider)
    }
}

private enum PasswordHasher {
    static func randomSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    static func hash(_ password: String, salt: Data) -> Data {
        let key = SymmetricKey(data: salt)
        let mac = HMAC<SHA256>.authenticationCode(for: Data(password.utf8), using: key)
        return Data(mac)
    }

    static func verify(_ password: String, salt: Data, hash: Data) -> Bool {
        self.hash(password, salt: salt) == hash
    }
}

private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    private var currentNonce: String?

    func start() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let nonce = Self.randomNonce()
            currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.outrunKeyWindow ?? ASPresentationAnchor()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            resume(.failure(AuthError.invalidCredential))
            return
        }
        resume(.success(credential))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        resume(.failure(error))
    }

    private func resume(_ result: Result<ASAuthorizationAppleIDCredential, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        currentNonce = nil
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status == errSecSuccess {
                result.append(charset[Int(random) % charset.count])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

private extension AuthError {
    static func wrap(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }

        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            return .cancelled
        }

        if nsError.domain == "com.google.GIDSignIn", nsError.code == GIDSignInError.canceled.rawValue {
            return .cancelled
        }

        return .unknown(error.localizedDescription.isEmpty ? "Sign in failed. Try again." : error.localizedDescription)
    }
}

extension UIApplication {
    var outrunKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first
    }

    var outrunTopViewController: UIViewController? {
        var controller = outrunKeyWindow?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
