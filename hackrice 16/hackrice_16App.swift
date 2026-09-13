//
//  hackrice_16App.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

@main
struct hackrice_16App: App {
    @State private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .background(Neu.canvas.ignoresSafeArea())
                .onOpenURL { url in
                    authService.handleOpenURL(url)
                }
        }
    }
}
