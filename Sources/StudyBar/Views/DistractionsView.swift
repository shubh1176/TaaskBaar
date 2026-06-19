import SwiftUI

struct DistractionsView: View {
    @StateObject private var viewModel = DistractionsViewModel()

    var body: some View {
        VStack(spacing: 12) {
            focusChart
            statsRow
            activityList
        }
        .onAppear { viewModel.refresh() }
    }

    private var focusChart: some View {
        let focus = Double(viewModel.todayFocusSeconds)
        let distract = Double(viewModel.todayDistractionSeconds)
        let total = max(focus + distract, 1)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Today's Focus Ratio")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.leading, 4)

            HStack(spacing: 24) {
                DonutChart(segments: [
                    (value: focus, color: .green, label: "Focused"),
                    (value: distract, color: .red, label: "Distracted")
                ], innerRadiusRatio: 0.5)
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("Focused").font(.system(size: 10)).foregroundStyle(.secondary)
                        Text(focus.formattedHours + "h")
                            .font(.system(size: 11, weight: .bold))
                    }
                    HStack(spacing: 6) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text("Distracted").font(.system(size: 10)).foregroundStyle(.secondary)
                        Text(distract.formattedHours + "h")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Divider()
                    Text("\(Int(focus / total * 100))% productive")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(focus / total > 0.7 ? .green : .orange)
                }
                Spacer()
            }
        }
        .cardStyle(padding: 14)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            MiniStatCard(icon: "target", color: .green, value: viewModel.todayFocusSeconds.formattedHours + "h", label: "Focus")
            MiniStatCard(icon: "eye.slash", color: .red, value: viewModel.todayDistractionSeconds.formattedHours + "h", label: "Distracted")
            MiniStatCard(icon: "divide.circle", color: .blue, value: focusRatio, label: "Ratio")
        }
    }

    private var focusRatio: String {
        let f = Double(viewModel.todayFocusSeconds)
        let d = Double(viewModel.todayDistractionSeconds)
        guard d > 0 else { return "—" }
        return String(format: "%.1fx", f / d)
    }

    private var activityList: some View {
        Group {
            if !viewModel.entries.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                        Text("Recent")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .padding(.leading, 4)

                    ForEach(viewModel.entries.prefix(6)) { entry in
                        HStack(spacing: 8) {
                            Image(systemName: entry.isDistracting ? "hand.raised.slash" : "checkmark.seal")
                                .font(.system(size: 9))
                                .foregroundStyle(entry.isDistracting ? .red : .green)
                            Text(entry.appName)
                                .font(.system(size: 10))
                            Spacer()
                            Text("\(entry.durationSeconds / 60)m")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .cardStyle(padding: 12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "eye.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No data tracked yet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }
}

struct MiniStatCard: View {
    var icon: String
    var color: Color
    var value: String
    var label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(10)
        .background(.quaternary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
