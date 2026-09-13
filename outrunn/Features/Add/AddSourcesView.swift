//
//  AddSourcesView.swift
//  outrunn
//

import SwiftUI

struct AddSourcesView: View {
    var state: UserRecoveryState
    var onOpenSettings: () -> Void = {}

    @State private var selected: DataIntegration?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ShellHeader(title: "Add") {
                SettingsGearButton(action: onOpenSettings)
            }

            VStack(spacing: 12) {
                ForEach(DataIntegration.allCases) { integration in
                    integrationRow(integration)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ShellLayout.horizontalPadding)
        .padding(.top, ShellLayout.topPadding)
        .sheet(item: $selected) { integration in
            DeviceLinkView(state: state, integration: integration)
        }
    }

    private func integrationRow(_ integration: DataIntegration) -> some View {
        let connected = state.isConnected(integration)

        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            selected = integration
        } label: {
                HStack(spacing: 14) {
                    Image(systemName: integration.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(connected ? Neu.accent : Neu.ink)
                        .frame(width: 28)

                    Text(integration.title)
                        .font(Neu.heading(16))
                        .italic()
                        .foregroundStyle(Neu.ink)

                    Spacer()

                    Text(connected ? "Manage" : integration.actionTitle)
                        .font(Neu.body(13))
                        .foregroundStyle(connected ? Neu.accent : Neu.muted)
                }
            .padding(16)
            .background(
                ConvexShape(
                    shape: RoundedRectangle(cornerRadius: 20, style: .continuous),
                    isPressed: connected
                )
            )
        }
        .buttonStyle(.plain)
    }
}
