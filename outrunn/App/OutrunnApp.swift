//
//  OutrunnApp.swift
//  outrunn
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

@main
struct OutrunnApp: App {
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
