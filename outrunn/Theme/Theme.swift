//
//  Theme.swift
//  outrunn
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI
import UIKit
import CoreText

enum Neu {
    static let canvas = Color(red: 251.0 / 255.0, green: 245.0 / 255.0, blue: 227.0 / 255.0)
    static let raised = Color(red: 251.0 / 255.0, green: 242.0 / 255.0, blue: 222.0 / 255.0)
    static let inset = Color(red: 245.0 / 255.0, green: 234.0 / 255.0, blue: 210.0 / 255.0)
    static let ink = Color(red: 0.23, green: 0.27, blue: 0.32)
    static let muted = Color(red: 0.48, green: 0.46, blue: 0.40)
    static let accent = Color(red: 0.32, green: 0.68, blue: 0.72)
    static let younger = Color(red: 0.30, green: 0.62, blue: 0.50)
    static let older = Color(red: 0.78, green: 0.42, blue: 0.36)
    static let lightShadow = Color.white
    static let darkShadow = Color(white: 0.42).opacity(0.40)
    static let highlight = Color.white.opacity(0.78)
    static let plotFill = raised

    static func logo(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Newsreader", size: size).weight(weight)
    }

    static func display(_ size: CGFloat) -> Font {
        serif(size, weight: .regular)
    }

    static func heading(_ size: CGFloat) -> Font {
        serif(size, weight: .medium)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        styrene(size, weight: .regular)
    }

    static func emphasis(_ size: CGFloat) -> Font {
        styrene(size, weight: .medium)
    }

    static func label(_ size: CGFloat = 12) -> Font {
        styrene(size, weight: .semibold)
    }

    static func number(_ size: CGFloat) -> Font {
        styrene(size, weight: .semibold)
    }

    static func button(_ size: CGFloat = 17) -> Font {
        styrene(size, weight: .semibold)
    }

    static func tab(_ size: CGFloat = 9, prominent: Bool = false) -> Font {
        styrene(size, weight: prominent ? .bold : .medium)
    }

    static func registerFonts() {
        let names = ["Newsreader", "Newsreader-Italic", "Outfit"]
        for name in names {
            let url =
                Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Theme/Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf")
            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func styrene(_ size: CGFloat, weight: Font.Weight) -> Font {
        typed(
            names: ["Outfit", "Outfit Thin", "Outfit-Thin"],
            size: size,
            weight: weight
        )
    }

    private static func typed(names: [String], size: CGFloat, weight: Font.Weight) -> Font {
        let axis: [Int: CGFloat] = [2003265654: cgWeight(weight)]
        for name in names {
            guard let base = UIFont(name: name, size: size) else { continue }
            let descriptor = base.fontDescriptor.addingAttributes([
                UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): axis
            ])
            return Font(UIFont(descriptor: descriptor, size: size))
        }
        return .system(size: size, weight: weight)
    }

    private static func cgWeight(_ weight: Font.Weight) -> CGFloat {
        switch weight {
        case .ultraLight, .thin: return 200
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        default: return 400
        }
    }
}

struct BrandWordmark: View {
    enum Kind {
        case outrun
        case roadrunner

        var glyphCount: Int {
            switch self {
            case .outrun: 6
            case .roadrunner: 9
            }
        }

        var accessibilityName: String {
            switch self {
            case .outrun: "outrunn"
            case .roadrunner: "roadrunner"
            }
        }
    }

    var kind: Kind
    var size: CGFloat
    var weight: Font.Weight = .light
    var revealed: [Bool]? = nil
    var letterSpacing: CGFloat = 1

    var body: some View {
        HStack(spacing: letterSpacing) {
            ForEach(glyphs) { glyph in
                reveal(glyph.id) {
                    glyphView(glyph)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.accessibilityName)
    }

    var glyphCount: Int { glyphs.count }

    private struct Glyph: Identifiable {
        var id: Int
        var letter: String
        var role: Role

        enum Role {
            case ink
            case accentO
            case echoN
        }
    }

    private var glyphs: [Glyph] {
        switch kind {
        case .outrun:
            zip(Array("outrun"), [Glyph.Role.accentO, .ink, .ink, .ink, .ink, .echoN]).enumerated().map {
                Glyph(id: $0.offset, letter: String($0.element.0), role: $0.element.1)
            }
        case .roadrunner:
            zip(Array("roadruner"), [
                Glyph.Role.ink, .ink, .ink, .ink, .ink, .ink, .echoN, .ink, .ink
            ]).enumerated().map {
                Glyph(id: $0.offset, letter: String($0.element.0), role: $0.element.1)
            }
        }
    }

    private func isRevealed(_ index: Int) -> Bool {
        guard let revealed, revealed.indices.contains(index) else { return true }
        return revealed[index]
    }

    @ViewBuilder
    private func reveal<Content: View>(_ index: Int, @ViewBuilder content: () -> Content) -> some View {
        if revealed == nil {
            content()
        } else {
            content()
                .offset(
                    x: isRevealed(index) ? 0 : 28,
                    y: isRevealed(index) ? 0 : 18
                )
                .opacity(isRevealed(index) ? 1 : 0)
                .blur(radius: isRevealed(index) ? 0 : 8)
        }
    }

    @ViewBuilder
    private func glyphView(_ glyph: Glyph) -> some View {
        let letter = Text(glyph.letter)
            .font(Neu.logo(size, weight: weight))
            .italic()

        switch glyph.role {
        case .accentO:
            letter.foregroundStyle(Neu.accent)
        case .ink:
            letter.foregroundStyle(Neu.ink)
        case .echoN:
            ZStack(alignment: .leading) {
                letter
                    .foregroundStyle(Neu.accent.opacity(0.32))
                    .blur(radius: max(1.8, size * 0.07))
                    .offset(x: size * 0.28)
                letter
                    .foregroundStyle(Neu.accent.opacity(0.82))
                    .blur(radius: max(0.5, size * 0.028))
                    .offset(x: size * 0.46)
                letter
                    .foregroundStyle(Neu.ink)
            }
            .padding(.trailing, size * 0.46)
        }
    }
}

struct RoadrunnerMark: View {
    var size: CGFloat = 28

    private let beak = Color(red: 0.96, green: 0.55, blue: 0.20)
    private let legs = Color(red: 0.98, green: 0.76, blue: 0.28)

    var body: some View {
        Canvas { context, box in
            let w = box.width
            let h = box.height
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * w, y: y * h)
            }

            for item in [(0.28, 0.22), (0.40, 0.16), (0.52, 0.12)] {
                var line = Path()
                line.move(to: pt(0.02, item.0))
                line.addLine(to: pt(item.1, item.0))
                context.stroke(
                    line,
                    with: .color(Neu.accent.opacity(0.4)),
                    style: StrokeStyle(lineWidth: max(1.4, h * 0.045), lineCap: .round)
                )
            }

            var tail = Path()
            tail.move(to: pt(0.10, 0.16))
            tail.addLine(to: pt(0.34, 0.36))
            tail.addLine(to: pt(0.12, 0.34))
            tail.closeSubpath()
            context.fill(tail, with: .color(Neu.accent))

            var tail2 = Path()
            tail2.move(to: pt(0.08, 0.28))
            tail2.addLine(to: pt(0.32, 0.40))
            tail2.addLine(to: pt(0.10, 0.42))
            tail2.closeSubpath()
            context.fill(tail2, with: .color(Neu.accent.opacity(0.85)))

            let body = CGRect(x: w * 0.30, y: h * 0.30, width: w * 0.38, height: h * 0.26)
            let smear = CGRect(x: w * 0.24, y: h * 0.32, width: w * 0.22, height: h * 0.22)
            context.fill(Path(ellipseIn: smear), with: .color(Neu.accent.opacity(0.28)))
            context.fill(Path(ellipseIn: body), with: .color(Neu.accent))

            var neck = Path()
            neck.move(to: pt(0.62, 0.38))
            neck.addQuadCurve(to: pt(0.76, 0.22), control: pt(0.74, 0.36))
            context.stroke(
                neck,
                with: .color(Neu.accent),
                style: StrokeStyle(lineWidth: h * 0.11, lineCap: .round)
            )

            let head = CGRect(x: w * 0.70, y: h * 0.04, width: w * 0.20, height: h * 0.28)
            context.fill(Path(ellipseIn: head), with: .color(Neu.accent))

            var crest = Path()
            crest.move(to: pt(0.76, 0.10))
            crest.addLine(to: pt(0.73, 0.01))
            crest.move(to: pt(0.80, 0.08))
            crest.addLine(to: pt(0.80, 0.00))
            crest.move(to: pt(0.84, 0.10))
            crest.addLine(to: pt(0.87, 0.02))
            context.stroke(
                crest,
                with: .color(Neu.accent),
                style: StrokeStyle(lineWidth: max(1.2, h * 0.035), lineCap: .round)
            )

            let eyeWhite = CGRect(x: w * 0.80, y: h * 0.10, width: w * 0.09, height: h * 0.13)
            context.fill(Path(ellipseIn: eyeWhite), with: .color(.white))
            let pupil = CGRect(x: w * 0.84, y: h * 0.13, width: w * 0.035, height: h * 0.055)
            context.fill(Path(ellipseIn: pupil), with: .color(Neu.ink))

            var beakPath = Path()
            beakPath.move(to: pt(0.88, 0.18))
            beakPath.addLine(to: pt(1.00, 0.23))
            beakPath.addLine(to: pt(0.88, 0.28))
            beakPath.closeSubpath()
            context.fill(beakPath, with: .color(beak))

            let legStyle = StrokeStyle(lineWidth: max(2.0, h * 0.055), lineCap: .round, lineJoin: .round)

            var backLeg = Path()
            backLeg.move(to: pt(0.42, 0.54))
            backLeg.addLine(to: pt(0.34, 0.74))
            backLeg.addLine(to: pt(0.24, 0.92))
            context.stroke(backLeg, with: .color(legs), style: legStyle)
            var backFoot = Path()
            backFoot.move(to: pt(0.24, 0.92))
            backFoot.addLine(to: pt(0.14, 0.97))
            context.stroke(backFoot, with: .color(legs), style: legStyle)

            var frontLeg = Path()
            frontLeg.move(to: pt(0.56, 0.54))
            frontLeg.addLine(to: pt(0.66, 0.70))
            frontLeg.addLine(to: pt(0.80, 0.92))
            context.stroke(frontLeg, with: .color(legs), style: legStyle)
            var frontFoot = Path()
            frontFoot.move(to: pt(0.80, 0.92))
            frontFoot.addLine(to: pt(0.90, 0.97))
            context.stroke(frontFoot, with: .color(legs), style: legStyle)
        }
        .frame(width: size * 1.7, height: size)
        .accessibilityLabel("roadruner")
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
            Group {
                if title == "outrunn" || title == "outrun" {
                    BrandWordmark(kind: .outrun, size: 28)
                } else {
                    Text(title)
                        .font(Neu.display(28))
                        .italic()
                        .foregroundStyle(Neu.ink)
                }
            }
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
            .fill(isPressed ? Neu.inset : Neu.raised)
            .shadow(
                color: isPressed ? Neu.darkShadow : Neu.lightShadow,
                radius: isPressed ? 5 : 11,
                x: isPressed ? 5 : -8,
                y: isPressed ? 5 : -8
            )
            .shadow(
                color: isPressed ? Neu.lightShadow.opacity(0.7) : Neu.darkShadow,
                radius: isPressed ? 5 : 11,
                x: isPressed ? -3 : 8,
                y: isPressed ? -3 : 8
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
        .font(Neu.body(16))
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
