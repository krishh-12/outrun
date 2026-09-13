//
//  OutrunSplashView.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

struct OutrunSplashView: View {
    var onContinue: () -> Void

    private let letters = BrandWordmark.Kind.outrun.glyphCount

    @State private var revealed = Array(repeating: false, count: BrandWordmark.Kind.outrun.glyphCount)
    @State private var underline: CGFloat = 0
    @State private var hintOpacity: Double = 0
    @State private var markScale: CGFloat = 0.96

    var body: some View {
        ZStack {
            Neu.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    BrandWordmark(kind: .outrun, size: 58, revealed: revealed)
                        .scaleEffect(markScale)

                    Capsule()
                        .fill(Neu.accent.opacity(0.85))
                        .frame(width: 88 * underline, height: 1.5)
                }

                Text("Tap to Begin")
                    .font(Neu.serif(13))
                    .italic()
                    .tracking(1.4)
                    .foregroundStyle(Neu.muted)
                    .opacity(hintOpacity)
                    .padding(.top, 36)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            onContinue()
        }
        .onAppear {
            animateWordmark()
        }
    }

    private func animateWordmark() {
        for index in 0..<letters {
            withAnimation(
                .spring(response: 0.62, dampingFraction: 0.78)
                .delay(Double(index) * 0.07)
            ) {
                revealed[index] = true
            }
        }

        withAnimation(.easeOut(duration: 0.7).delay(0.48)) {
            underline = 1
            markScale = 1
        }

        withAnimation(.easeInOut(duration: 0.8).delay(0.85)) {
            hintOpacity = 1
        }
    }
}

#Preview {
    OutrunSplashView(onContinue: {})
}
