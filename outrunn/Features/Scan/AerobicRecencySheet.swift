//
//  AerobicRecencySheet.swift
//  outrunn
//

import SwiftUI

struct AerobicRecencySheet: View {
    var onContinue: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Double = 30

    var body: some View {
        NavigationStack {
            ZStack {
                Neu.canvas.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    Text("Time After Workout")
                        .font(Neu.heading(26))
                        .foregroundStyle(Neu.ink)

                    Text(label(for: Int(selectedMinutes.rounded())))
                        .font(Neu.number(28))
                        .foregroundStyle(Neu.accent)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Slider(value: $selectedMinutes, in: 0...240, step: 5)
                        .tint(Neu.accent)

                    HStack {
                        Text("Just now")
                            .font(Neu.body(13))
                            .foregroundStyle(Neu.muted)
                        Spacer()
                        Text("4 hours")
                            .font(Neu.body(13))
                            .foregroundStyle(Neu.muted)
                    }

                    Text("Gemini uses this to tell incomplete recovery apart from true biological age.")
                        .font(Neu.body())
                        .foregroundStyle(Neu.muted)

                    Spacer()

                    Button {
                        onContinue(Int(selectedMinutes.rounded()))
                    } label: {
                        Text("Continue to Scan")
                            .font(Neu.button(17))
                            .foregroundStyle(Neu.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(NeuButtonStyle())
                }
                .padding(22)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func label(for minutes: Int) -> String {
        if minutes == 0 { return "Just now" }
        if minutes < 60 { return "\(minutes) minutes ago" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        return "\(hours) hr \(remainder) min ago"
    }
}
