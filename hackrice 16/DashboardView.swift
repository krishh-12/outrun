//
//  DashboardView.swift
//  hackrice 16
//
//  Created by Krish Hariharan on 9/12/26.
//

import Charts
import SwiftUI

enum AgeMetric: String, CaseIterable, Identifiable {
    case real = "Real Age"
    case biological = "Biological Age"
    case cardiac = "Cardiac Age"
    case respiratory = "Pulmonary Age"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .real: Neu.ink
        case .biological: Neu.accent
        case .cardiac: Color(red: 0.86, green: 0.38, blue: 0.40)
        case .respiratory: Color(red: 0.35, green: 0.55, blue: 0.86)
        }
    }
}

struct AgeChartPoint: Identifiable {
    var id: String
    var date: Date
    var index: Int
    var metric: AgeMetric
    var age: Double
}

struct DashboardView: View {
    var state: UserRecoveryState
    var onOpenSettings: () -> Void = {}
    var onSeeInsights: () -> Void = {}
    var scanRequestCount: Int = 0

    @State private var showActivityPrompt = false
    @State private var showPreSageScan = false
    @State private var pendingMinutes = 30

    var body: some View {
        VStack(alignment: .leading, spacing: ShellLayout.pageSpacing) {
            ShellHeader(title: "outrunn") {
                SettingsGearButton(action: onOpenSettings)
            }

            baselineCard
            ageChart
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            insightsButton
        }
        .padding(.horizontal, ShellLayout.horizontalPadding)
        .padding(.top, ShellLayout.topPadding)
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.35), value: state.biologicalAge)
        .sheet(isPresented: $showActivityPrompt) {
            AerobicRecencySheet { minutes in
                pendingMinutes = minutes
                showActivityPrompt = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showPreSageScan = true
                }
            }
        }
        .fullScreenCover(isPresented: $showPreSageScan) {
            PreSageScanView(
                state: state,
                minutesSinceAerobicActivity: pendingMinutes
            ) {
                showPreSageScan = false
            }
        }
        .onChange(of: scanRequestCount) { _, count in
            guard count > 0 else { return }
            showActivityPrompt = true
        }
    }

    private var baselineCard: some View {
        Button {
            showActivityPrompt = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Neu.accent)
                    .frame(width: 44, height: 44)
                    .background(ConvexShape(shape: Circle(), isPressed: true))

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.hasCompletedBaseline ? "Take a New Scan" : "Take Your Baseline Scan")
                        .font(Neu.heading(18))
                        .italic()
                        .foregroundStyle(Neu.ink)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Neu.muted)
            }
            .padding(16)
            .background(
                ConvexShape(shape: RoundedRectangle(cornerRadius: 24, style: .continuous))
            )
        }
        .buttonStyle(.plain)
    }

    private var ageChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Age Trends")
                .font(Neu.heading(16))
                .italic()
                .foregroundStyle(Neu.ink)

            Picker("Range", selection: chartRangeBinding) {
                ForEach(ChartTimeRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if state.ageHistory.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("Complete your baseline scan to unlock your age graph.")
                        .font(Neu.body(15))
                        .foregroundStyle(Neu.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if state.chartRange.requiresWeekOfHistory && !state.hasWeekOfAgeData {
                VStack(spacing: 8) {
                    Spacer()
                    Text("Not enough data")
                        .font(Neu.heading(18))
                        .foregroundStyle(Neu.ink)
                    Text("Keep scanning for a week to unlock this time range.")
                        .font(Neu.body(15))
                        .foregroundStyle(Neu.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if chartPoints.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No readings in this time range yet.")
                        .font(Neu.body(15))
                        .foregroundStyle(Neu.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AgeTrendChart(points: chartPoints, range: state.chartRange)
                    .frame(maxWidth: .infinity, minHeight: 220, maxHeight: .infinity)

                legend
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            ConvexShape(shape: RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], spacing: 8) {
            ForEach(AgeMetric.allCases) { metric in
                HStack(spacing: 8) {
                    Circle()
                        .fill(metric.color)
                        .frame(width: 8, height: 8)
                    Text(metric.rawValue)
                        .font(Neu.body(12))
                        .foregroundStyle(Neu.ink)
                }
            }
        }
    }

    private var insightsButton: some View {
        Button {
            onSeeInsights()
        } label: {
            Text("See Personalized Insights")
                .font(Neu.heading(17))
                .foregroundStyle(Neu.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(NeuButtonStyle())
        .disabled(!state.hasCompletedBaseline)
        .opacity(state.hasCompletedBaseline ? 1 : 0.55)
    }

    private var chartRangeBinding: Binding<ChartTimeRange> {
        Binding(
            get: { state.chartRange },
            set: {
                state.chartRange = $0
                state.persistSoon()
            }
        )
    }

    private var chartPoints: [AgeChartPoint] {
        let start = state.chartRange.startDate
        let readings = state.ageHistory
            .filter { $0.date >= start }
            .sorted { $0.date < $1.date }
        return readings.enumerated().flatMap { index, reading in
            AgeMetric.allCases.map { metric in
                AgeChartPoint(
                    id: "\(reading.id.uuidString)-\(metric.rawValue)",
                    date: reading.date,
                    index: index,
                    metric: metric,
                    age: value(in: reading, for: metric)
                )
            }
        }
    }

    private func value(in reading: AgeReading, for metric: AgeMetric) -> Double {
        switch metric {
        case .real: reading.chronologicalAge
        case .biological: reading.biologicalAge
        case .cardiac: reading.cardiacAge
        case .respiratory: reading.respiratoryAge
        }
    }
}

private struct AgeMetricSeries: Identifiable {
    var metric: AgeMetric
    var points: [AgeChartPoint]
    var id: String { metric.rawValue }
}

private struct AgeTrendChart: View {
    var points: [AgeChartPoint]
    var range: ChartTimeRange

    private var series: [AgeMetricSeries] {
        AgeMetric.allCases.map { metric in
            AgeMetricSeries(
                metric: metric,
                points: points.filter { $0.metric == metric }.sorted { $0.date < $1.date }
            )
        }
    }

    var body: some View {
        if range == .day {
            evenChart
        } else {
            timeChart
        }
    }

    private var evenChart: some View {
        Chart(points) { point in
            PointMark(
                x: .value("Scan", point.index),
                y: .value("Age", point.age)
            )
            .foregroundStyle(point.metric.color)
            .symbol(.circle)
            .symbolSize(90)
        }
        .chartLegend(.hidden)
        .chartXScale(domain: -0.5 ... Double(evenLastIndex) + 0.5)
        .chartXAxis(.hidden)
        .chartYScale(domain: yDomain)
        .chartYAxis { yAxis }
        .chartPlotStyle { plot in
            plot.background(Neu.plotFill)
        }
    }

    private var timeChart: some View {
        Chart {
            ForEach(connectedSeries) { metricSeries in
                LinePlot(
                    metricSeries.points,
                    x: .value("Time", \.date),
                    y: .value("Age", \.age)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(metricSeries.metric.color)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }

            ForEach(points) { point in
                PointMark(
                    x: .value("Time", point.date),
                    y: .value("Age", point.age)
                )
                .foregroundStyle(point.metric.color)
                .symbol(.circle)
                .symbolSize(48)
            }
        }
        .chartLegend(.hidden)
        .chartXScale(domain: range.startDate...Date.now)
        .chartXAxis {
            AxisMarks(values: xTickDates) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: xAxisFormat)
                            .font(Neu.body(11))
                            .foregroundStyle(Neu.muted)
                    }
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartYAxis { yAxis }
        .chartPlotStyle { plot in
            plot.background(Neu.plotFill)
        }
    }

    private var yAxis: some AxisContent {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
            AxisValueLabel {
                if let age = value.as(Double.self) {
                    Text(String(format: "%.0f", age))
                        .font(Neu.body(11).monospacedDigit())
                        .foregroundStyle(Neu.muted)
                }
            }
        }
    }

    private var connectedSeries: [AgeMetricSeries] {
        series.filter { $0.points.count >= 2 }
    }

    private var evenLastIndex: Int {
        max((series.map(\.points.count).max() ?? 1) - 1, 0)
    }

    private var xTickCount: Int {
        switch range {
        case .day: 0
        case .week: 7
        case .month: 5
        case .sixMonths, .year: 6
        }
    }

    private var xTickDates: [Date] {
        let start = range.startDate
        let end = Date.now
        let span = end.timeIntervalSince(start)
        guard span > 0, xTickCount > 1 else { return [end] }
        return (0..<xTickCount).map { index in
            start.addingTimeInterval(span * Double(index) / Double(xTickCount - 1))
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch range {
        case .day: .dateTime.hour().minute()
        case .week: .dateTime.weekday(.abbreviated)
        case .month: .dateTime.month(.abbreviated).day()
        case .sixMonths, .year: .dateTime.month(.abbreviated)
        }
    }

    private var yDomain: ClosedRange<Double> {
        let values = points.map(\.age)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 20...40
        }
        if minValue == maxValue {
            return (minValue - 2)...(maxValue + 2)
        }
        let pad = max(1.0, (maxValue - minValue) * 0.2)
        return (minValue - pad)...(maxValue + pad)
    }
}

#Preview {
    @Previewable @State var recoveryState = UserRecoveryState.mock
    DashboardView(state: recoveryState)
}

#Preview("Post-PreSage scan") {
    @Previewable @State var recoveryState = UserRecoveryState.postScanPreview
    DashboardView(state: recoveryState)
}