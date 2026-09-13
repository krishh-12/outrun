//
//  RootView.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

enum AppRoute: Equatable {
    case splash
    case signUp
    case connectDevice
    case dashboard
}

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.scenePhase) private var scenePhase

    @State private var route: AppRoute = .splash
    @State private var recoveryState = UserRecoveryState.freshStart

    private let deviceSetupKey = "didCompleteDeviceSetup"

    var body: some View {
        ZStack {
            Neu.canvas.ignoresSafeArea()

            switch route {
            case .splash:
                OutrunSplashView {
                    go(to: nextRouteAfterSplash)
                }
                .transition(pushTransition)

            case .signUp:
                SignUpView { user in
                    attachAccount(user)
                    go(to: needsDeviceSetup ? .connectDevice : .dashboard)
                }
                .transition(pushTransition)

            case .connectDevice:
                DeviceConnectView { source in
                    recoveryState.dataSource = source
                    if let integration = DataIntegration.allCases.first(where: { $0.wearableSource == source }) {
                        recoveryState.connect(integration)
                    } else {
                        recoveryState.persistSoon()
                    }
                    UserDefaults.standard.set(true, forKey: deviceSetupKey)
                    go(to: .dashboard)
                }
                .transition(pushTransition)

            case .dashboard:
                MainShellView(state: recoveryState, onLogOut: logOut)
                    .transition(pushTransition)
            }
        }
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.52, dampingFraction: 0.88), value: route)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                recoveryState.persistSoon()
            }
        }
    }

    private var hasCompletedDeviceSetup: Bool {
        UserDefaults.standard.bool(forKey: deviceSetupKey) || !recoveryState.connectedIntegrations.isEmpty
    }

    private var needsDeviceSetup: Bool {
        !hasCompletedDeviceSetup
    }

    private var nextRouteAfterSplash: AppRoute {
        guard let user = auth.currentUser else {
            return .signUp
        }
        attachAccount(user)
        return needsDeviceSetup ? .connectDevice : .dashboard
    }

    private func attachAccount(_ user: AuthUser) {
        recoveryState.persistenceKey = user.id
        if let snapshot = RecoveryPersistence.load(userId: user.id) {
            recoveryState.restore(from: snapshot)
            recoveryState.persistenceKey = user.id
            if recoveryState.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                recoveryState.userName = user.name
            }
            if recoveryState.profileEmail == nil {
                recoveryState.profileEmail = user.email
            }
            recoveryState.authProvider = user.provider
        } else {
            recoveryState.resetForNewAccount(name: user.name, provider: user.provider, email: user.email)
            recoveryState.persistenceKey = user.id
            recoveryState.persistSoon()
        }
    }

    private var pushTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private func go(to next: AppRoute) {
        route = next
    }

    private func logOut() {
        recoveryState.persistSoon()
        auth.signOut()
        recoveryState = UserRecoveryState.freshStart
        go(to: .splash)
    }
}

#Preview {
    RootView()
        .environment(AuthService())
}
