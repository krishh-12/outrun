//
//  Theme.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

enum Neu {
    static let canvas = Color(red: 1.0, green: 249.0 / 255.0, blue: 227.0 / 255.0)
    static let ink = Color(red: 0.23, green: 0.27, blue: 0.32)
    static let muted = Color(red: 0.48, green: 0.46, blue: 0.40)
    static let accent = Color(red: 0.32, green: 0.68, blue: 0.72)
    static let younger = Color(red: 0.30, green: 0.62, blue: 0.50)
    static let older = Color(red: 0.78, green: 0.42, blue: 0.36)
    static let lightShadow = Color.white.opacity(0.95)
    static let darkShadow = Color(red: 0.78, green: 0.72, blue: 0.58).opacity(0.45)
    static let plotFill = Color(red: 1.0, green: 252.0 / 255.0, blue: 240.0 / 255.0)

    static func serif(_ size: CGFloat, weight: Font.Weight = .ultraLight) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

enum ShellLayout {
    static let horizontalPadding: CGFloat = 20
    static let topPadding: CGFloat = 8
    static let headerHeight: CGFloat = 52
    static let tabBarHeight: CGFloat = 64
    static let pageSpacing: CGFloat = 16
}

struct ShellHeader<Trailing: View>: View {
    var title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(Neu.serif(28))
                .italic()
                .foregroundStyle(Neu.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            trailing()
        }
        .frame(height: ShellLayout.headerHeight)
    }
}

extension ShellHeader where Trailing == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

struct SettingsGearButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Neu.ink)
                .frame(width: 44, height: 44)
                .background(ConvexShape(shape: Circle()))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }
}

struct ConvexShape<S: Shape>: View {
    var shape: S
    var isPressed: Bool = false

    var body: some View {
        shape
            .fill(Neu.canvas)
            .shadow(
                color: isPressed ? Neu.darkShadow : Neu.lightShadow,
                radius: isPressed ? 4 : 8,
                x: isPressed ? 4 : -6,
                y: isPressed ? 4 : -6
            )
            .shadow(
                color: isPressed ? Neu.lightShadow : Neu.darkShadow,
                radius: isPressed ? 4 : 8,
                x: isPressed ? -3 : 6,
                y: isPressed ? -3 : 6
            )
    }
}

struct NeuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ConvexShape(
                    shape: RoundedRectangle(cornerRadius: 20, style: .continuous),
                    isPressed: configuration.isPressed
                )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct NeuField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(.body, design: .rounded))
        .foregroundStyle(Neu.ink)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            ConvexShape(
                shape: RoundedRectangle(cornerRadius: 18, style: .continuous),
                isPressed: true
            )
        )
    }
}
