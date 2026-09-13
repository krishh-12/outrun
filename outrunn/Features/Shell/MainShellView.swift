//
//  MainShellView.swift
//  outrunn
//
//  Created by Krish Hariharan on 9/12/26.
//

import SwiftUI

enum ShellTab: Hashable {
    case dashboard
    case data
    case insights
    case history
    case add
}

struct MainShellView: View {
    var state: UserRecoveryState
    var onLogOut: () -> Void

    @State private var tab: ShellTab = .dashboard
    @State private var showSettings = false
    @State private var insightsOpenCount = 0
    @State private var scanRequestCount = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                DashboardView(
                    state: state,
                    onOpenSettings: { showSettings = true },
                    onSeeInsights: { openInsights() },
                    scanRequestCount: scanRequestCount
                )
                    .opacity(tab == .dashboard ? 1 : 0)
                    .allowsHitTesting(tab == .dashboard)

                DataView(state: state, onOpenSettings: { showSettings = true })
                    .opacity(tab == .data ? 1 : 0)
                    .allowsHitTesting(tab == .data)

                InsightsView(
                    state: state,
                    onOpenSettings: { showSettings = true },
                    onOpenRoute: openRoute,
                    isVisible: tab == .insights,
                    openCount: insightsOpenCount
                )
                    .opacity(tab == .insights ? 1 : 0)
                    .allowsHitTesting(tab == .insights)

                HistoryView(state: state, onOpenSettings: { showSettings = true })
                    .opacity(tab == .history ? 1 : 0)
                    .allowsHitTesting(tab == .history)

                AddSourcesView(state: state, onOpenSettings: { showSettings = true })
                    .opacity(tab == .add ? 1 : 0)
                    .allowsHitTesting(tab == .add)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .background(Neu.canvas.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.18), value: tab)
        .sheet(isPresented: $showSettings) {
            SettingsView(state: state, onLogOut: onLogOut)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.dashboard, icon: "house.fill", title: "Dash")
            tabButton(.data, icon: "chart.xyaxis.line", title: "Data")
            tabButton(.insights, icon: "sparkles", title: "Insights")
            tabButton(.history, icon: "clock", title: "History")
            tabButton(.add, icon: "plus", title: "Add")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(height: 72)
        .background(
            ConvexShape(shape: Capsule())
        )
    }

    private func tabButton(_ value: ShellTab, icon: String, title: String) -> some View {
        let selected = tab == value
        let isInsights = value == .insights
        return Button {
            if value == .insights {
                openInsights()
            } else {
                tab = value
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isInsights {
                        Circle()
                            .fill(selected ? Neu.accent.opacity(0.32) : Neu.accent.opacity(0.18))
                            .frame(width: 38, height: 38)
                    }
                    Image(systemName: icon)
                        .font(.system(size: isInsights ? 17 : 18, weight: .semibold))
                        .foregroundStyle(isInsights || selected ? Neu.accent : Neu.muted)
                        .symbolEffect(.pulse, options: .repeating.speed(0.35), isActive: isInsights && !selected)
                }
                Text(isInsights ? "AI" : title)
                    .font(Neu.tab(prominent: isInsights))
                    .foregroundStyle(isInsights || selected ? Neu.accent : Neu.muted.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isInsights ? "Insights AI" : title)
    }

    private func openInsights() {
        insightsOpenCount += 1
        tab = .insights
    }

    private func openRoute(_ route: RoadrunnerRoute) {
        switch route {
        case .dash:
            tab = .dashboard
        case .data:
            tab = .data
        case .insights:
            openInsights()
        case .history:
            tab = .history
        case .add:
            tab = .add
        case .settings:
            showSettings = true
        case .scan:
            tab = .dashboard
            scanRequestCount += 1
        }
    }
}

#Preview {
    @Previewable @State var state = UserRecoveryState.mock
    MainShellView(state: state, onLogOut: {})
}
