//
//  DeviceConnectView.swift
//  outrunn
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

struct DeviceConnectView: View {
    var onContinue: (WearableSource) -> Void

    @State private var selected: WearableSource?

    var body: some View {
        ZStack {
            Neu.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Data")
                        .font(Neu.display(28))
                        .italic()
                        .foregroundStyle(Neu.ink)

                    Text("Connect a wearable, or enter recovery data yourself.")
                        .font(Neu.body(16))
                        .foregroundStyle(Neu.muted)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(WearableSource.allCases) { source in
                        sourceRow(source)
                    }
                }

                Spacer()

                Button {
                    guard let selected else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onContinue(selected)
                } label: {
                    Text("Continue")
                        .font(Neu.button(17))
                        .foregroundStyle(selected == nil ? Neu.muted : Neu.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(NeuButtonStyle())
                .disabled(selected == nil)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)
        }
        .preferredColorScheme(.light)
    }

    private func sourceRow(_ source: WearableSource) -> some View {
        let isSelected = selected == source

        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.easeOut(duration: 0.18)) {
                selected = source
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: source.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? Neu.accent : Neu.ink)
                    .frame(width: 28)

                Text(source.title)
                    .font(Neu.heading(16))
                    .foregroundStyle(Neu.ink)

                Spacer()

                Circle()
                    .stroke(isSelected ? Neu.accent : Neu.muted.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(Neu.accent)
                                .frame(width: 10, height: 10)
                        }
                    }
            }
            .padding(16)
            .background(
                ConvexShape(
                    shape: RoundedRectangle(cornerRadius: 20, style: .continuous),
                    isPressed: isSelected
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DeviceConnectView { _ in }
}
