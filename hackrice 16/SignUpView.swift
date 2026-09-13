//
//  SignUpView.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

private enum AuthPalette {
    static let background = Neu.canvas
    static let title = Neu.ink
    static let subtitle = Neu.muted
    static let field = Neu.ink
    static let underline = Neu.muted.opacity(0.35)
    static let green = Neu.accent
    static let apple = Color(red: 0.23, green: 0.27, blue: 0.32)
    static let google = Color(red: 0.32, green: 0.52, blue: 0.72)
}

struct SignUpView: View {
    var onSignedIn: (AuthUser) -> Void

    @Environment(AuthService.self) private var auth

    @State private var isCreatingAccount = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var localError: String?
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {
            AuthPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(isCreatingAccount ? "Create Account" : "Welcome")
                        .font(Neu.display(36))
                        .italic()
                        .foregroundStyle(AuthPalette.title)
                        .padding(.top, 28)

                    Text(isCreatingAccount
                         ? "Enter your email address to create an account.\nStart outrunning your biological age."
                         : "Enter your email address to sign in.\nStart outrunning your biological age.")
                        .font(Neu.body(16))
                        .foregroundStyle(AuthPalette.subtitle)
                        .padding(.top, 10)
                        .padding(.bottom, 28)

                    if let message = localError ?? auth.errorMessage {
                        Text(message)
                            .font(Neu.body(14))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .padding(.bottom, 16)
                    }

                    if isCreatingAccount {
                        underlineField(title: "Name", text: $name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .padding(.bottom, 22)
                    }

                    underlineField(title: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .padding(.bottom, 22)

                    underlineField(title: "Password", text: $password, isSecure: true)
                        .textContentType(isCreatingAccount ? .newPassword : .password)

                    if !isCreatingAccount {
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(Neu.body(14))
                            .foregroundStyle(AuthPalette.subtitle)
                        }
                        .padding(.top, 10)
                    }

                    Button(action: submitEmail) {
                        Text(isCreatingAccount ? "Create Account" : "Sign In")
                            .font(Neu.button(17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AuthPalette.green, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 28)

                    HStack(spacing: 4) {
                        Text(isCreatingAccount ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(AuthPalette.subtitle)
                        Button(isCreatingAccount ? "Sign In" : "Create an Account") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCreatingAccount.toggle()
                                localError = nil
                                auth.clearError()
                            }
                        }
                        .foregroundStyle(AuthPalette.green)
                    }
                    .font(Neu.body(15))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)

                    Text("Or")
                        .font(Neu.body(15))
                        .foregroundStyle(AuthPalette.subtitle)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 18)
                        .padding(.bottom, 18)

                    Button {
                        Task { await complete { try await auth.signInWithApple() } }
                    } label: {
                        socialLabel(title: "Continue with Apple", systemImage: "apple.logo")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AuthPalette.apple, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await complete { try await auth.signInWithGoogle() } }
                    } label: {
                        socialLabel(title: "Continue with Google", badge: "G")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AuthPalette.google, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 28)
            }
            .scrollDismissesKeyboard(.interactively)

            if auth.isBusy {
                Neu.canvas.opacity(0.72).ignoresSafeArea()
                ProgressView()
                    .tint(AuthPalette.green)
            }
        }
        .preferredColorScheme(.light)
        .alert("Forgot Password", isPresented: $showForgotPassword) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Password reset is coming soon. Create a new account if you do not remember it.")
        }
    }

    private func underlineField(title: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Neu.label(13))
                .foregroundStyle(AuthPalette.field)

            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                }
            }
            .font(Neu.body())
            .foregroundStyle(.black)

            Rectangle()
                .fill(AuthPalette.underline)
                .frame(height: 1)
        }
    }

    private func socialLabel(title: String, systemImage: String? = nil, badge: String? = nil) -> some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
            }
            if let badge {
                Text(badge)
                    .font(Neu.label(15))
                    .frame(width: 22, height: 22)
                    .background(.white, in: Circle())
                    .foregroundStyle(AuthPalette.google)
            }
            Text(title)
                .font(Neu.button(16))
        }
    }

    private func submitEmail() {
        localError = nil
        auth.clearError()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            localError = "Enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters."
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            if isCreatingAccount {
                await complete {
                    try await auth.signUpWithEmail(name: name, email: email, password: password)
                }
            } else {
                await complete {
                    try await auth.signInWithEmail(email: email, password: password)
                }
            }
        }
    }

    private func complete(_ work: () async throws -> AuthUser) async {
        do {
            let user = try await work()
            onSignedIn(user)
        } catch let error as AuthError where error == .cancelled {
            return
        } catch {
            return
        }
    }
}

#Preview {
    SignUpView { _ in }
        .environment(AuthService())
}
