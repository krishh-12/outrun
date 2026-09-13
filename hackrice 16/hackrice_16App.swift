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

    init() {
        Neu.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(\.font, Neu.body())
                .background(Neu.canvas.ignoresSafeArea())
                .onOpenURL { url in
                    authService.handleOpenURL(url)
                }
        }
    }
}
