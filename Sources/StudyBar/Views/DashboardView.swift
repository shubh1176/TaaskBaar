import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var timerService: TimerService
    @State private var stats = TimerService.DailyStats()
    @State private var weeklyData: [(String, Double, Color)] = []
    @State private var streakScale: CGFloat = 1
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                streakBanner
                statsGrid
                weeklyChart
                todayBreakdown
                quickOverview
                hint
            }
        }
        .onAppear { refresh() }
        .onReceive(timer) { _ in refresh() }
    }

    private var streakBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .scaleEffect(streakScale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5).repeatCount(3, autoreverses: true)) {
                        streakScale = 1.15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        streakScale = 1
                    }
                }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(stats.streak) Day Streak")
                    .font(.system(size: 16, weight: .bold))
                Text(stats.streak > 0 ? "Keep the momentum!" : "Start a session to begin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if stats.streak > 0 {
                Text("🔥")
                    .font(.title3)
            }
        }
        .cardStyle(padding: 14)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatCard(icon: "timer", color: .orange, label: "Focus Today", value: "\(stats.focusSeconds.formattedHours)h",
                     detail: stats.focusSeconds > 0 ? "\(stats.focusSeconds / 60)m total" : nil)
            StatCard(icon: "checkmark.circle", color: .green, label: "Tasks Done", value: "\(stats.tasksCompleted)",
                     detail: stats.tasksCompleted == 1 ? "1 task" : "\(stats.tasksCompleted) tasks")
            StatCard(icon: "rectangle.stack", color: .purple, label: "Flashcards", value: "\(stats.flashcardsReviewed)",
                     detail: "reviewed today")
            StatCard(icon: "flame", color: .orange, label: "Streak", value: "\(stats.streak) days",
                     detail: stats.streak > 0 ? "best run yet" : "start today")
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Weekly Focus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.leading, 4)

            BarChart(data: weeklyData, maxValue: weeklyData.map(\.1).max().map { max($0, 1) })
                .frame(height: 110)
        }
        .cardStyle(padding: 14)
    }

    private var todayBreakdown: some View {
        let focusVal = Double(stats.focusSeconds)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Today's Breakdown")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.leading, 4)

            HStack(spacing: 20) {
                DonutChart(segments: [
                    (value: max(focusVal, 1), color: .orange, label: "Focus"),
                    (value: max(Double(stats.tasksCompleted * 300), 1), color: .green, label: "Tasks"),
                    (value: max(Double(stats.flashcardsReviewed * 60), 1), color: .purple, label: "Cards")
                ], innerRadiusRatio: 0.55)
                .frame(width: 70, height: 70)

                VStack(alignment: .leading, spacing: 6) {
                    legendRow(color: .orange, label: "Focus", value: focusVal.formattedHours + "h")
                    legendRow(color: .green, label: "Tasks", value: "\(stats.tasksCompleted) done")
                    legendRow(color: .purple, label: "Cards", value: "\(stats.flashcardsReviewed) reviewed")
                }
                Spacer()
            }
        }
        .cardStyle(padding: 14)
    }

    private func legendRow(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .medium))
        }
    }

    private var quickOverview: some View {
        let tasks = StorageService.shared.readTasks()
        let incomplete = tasks.filter { !$0.isCompleted }.sorted { $0.createdAt > $1.createdAt }.prefix(3)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Open Tasks")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if !incomplete.isEmpty {
                    Text("\(incomplete.count) remaining")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.leading, 4)

            if !incomplete.isEmpty {
                ForEach(incomplete) { task in
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Text(task.text)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Spacer()
                        Text(task.createdAt, style: .time)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.quaternary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("All caught up!")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
            }
        }
        .cardStyle(padding: 14)
    }

    private var hint: some View {
        HStack {
            Image(systemName: "command")
                .font(.system(size: 8))
            Text("⇧ Space")
                .font(.system(size: 8, weight: .medium))
            Text("quick capture")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
    }

    private func refresh() {
        stats = timerService.getDailyStats()
        weeklyData = computeWeeklyData()
    }

    private func computeWeeklyData() -> [(String, Double, Color)] {
        let sessions = StorageService.shared.readSessions()
        let cal = Calendar.current
        let today = Date()
        var result: [(String, Double, Color)] = []

        for i in (0..<7).reversed() {
            guard let day = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let daySessions = sessions.filter { cal.isDate($0.startedAt, inSameDayAs: day) }
            let hours = daySessions.reduce(0.0) { $0 + Double($1.durationSeconds) } / 3600.0
            let label = i == 0 ? "Today" : day.weekdaySymbol
            let color: Color = i == 0 ? .orange : .blue.opacity(0.6)
            result.append((label, hours, color))
        }
        return result
    }
}

struct StatCard: View {
    var icon: String
    var color: Color
    var label: String
    var value: String
    var detail: String?

    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(hovered ? Color.gray.opacity(0.12) : Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .scaleEffect(hovered ? 1.02 : 1)
        .onHover { h in withAnimation(.spring) { hovered = h } }
    }
}
