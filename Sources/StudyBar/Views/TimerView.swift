import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timerService: TimerService
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var pulseScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 16) {
            modeSelector
            subjectField
            timerDisplay
            controls
            breakReminder
            statsFooter
        }
    }

    private var modeSelector: some View {
        Picker("Mode", selection: $timerService.sessionType) {
            ForEach(SessionType.allCases, id: \.self) { type in
                Label(type.rawValue, systemImage: typeIcon(type))
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .disabled(timerService.state.isActive)
    }

    private func typeIcon(_ type: SessionType) -> String {
        switch type {
        case .pomodoro: return "timer"
        case .deepWork: return "brain.head.profile"
        case .custom: return "slider.horizontal.3"
        }
    }

    private var subjectField: some View {
        HStack(spacing: 8) {
            Image(systemName: "book.pages")
                .foregroundStyle(.tertiary)
                .font(.caption)
            TextField("What are you studying?", text: $timerService.sessionSubject)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .disabled(timerService.state.isActive)
    }

    private var timerDisplay: some View {
        ZStack {
            RingProgress(
                progress: timerService.progress,
                color: ringColor,
                lineWidth: 8,
                glow: timerService.state.isActive
            )
            .frame(width: 150, height: 150)

            VStack(spacing: 4) {
                Text(timerService.displayString)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.2), value: timerService.displayString)

                HStack(spacing: 4) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 5, height: 5)
                    Text(timerService.state.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(stateColor)
                }
            }
        }
        .scaleEffect(pulseScale)
        .onChange(of: timerService.state) { _, newState in
            if case .running = newState {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    pulseScale = 1.02
                }
            } else {
                withAnimation(.spring) { pulseScale = 1 }
            }
        }
        .padding(.vertical, 4)
    }

    private var ringColor: Color {
        switch timerService.state {
        case .running: return .orange
        case .paused: return .yellow
        case .break_: return .green
        case .idle: return .blue
        }
    }

    private var stateColor: Color {
        switch timerService.state {
        case .idle: return .secondary
        case .running: return .orange
        case .paused: return .yellow
        case .break_: return .green
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            if case .idle = timerService.state {
                Button(action: { timerService.start() }) {
                    Label("Start", systemImage: "play.fill")
                }
                .sbButton(.green)
            } else if case .running = timerService.state {
                Button(action: { timerService.pause() }) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .sbButton(.orange)
            } else if case .paused = timerService.state {
                Button(action: { timerService.resume() }) {
                    Label("Resume", systemImage: "play.fill")
                }
                .sbButton(.green)
            }

            if timerService.state != .idle {
                Button(action: { timerService.stop() }) {
                    Label("End", systemImage: "stop.fill")
                }
                .sbButton(.red)
            }
        }
    }

    private var breakReminder: some View {
        Group {
            if timerService.showBreakReminder {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundStyle(.teal)
                        Text("Break time!")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    HStack(spacing: 10) {
                        Button(action: { timerService.startBreak() }) {
                            Label("Take \(timerService.breakSeconds / 60)m", systemImage: "play.fill")
                        }
                        .sbButton(.teal)

                        Button(action: { timerService.skipBreak() }) {
                            Text("Skip")
                        }
                        .sbButton(.secondary)
                    }
                }
                .cardStyle(padding: 14)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring, value: timerService.showBreakReminder)
    }

    private var statsFooter: some View {
        HStack {
            StatBadge(icon: "clock", value: "\(timerService.focusSecondsToday.formattedHours)h today")
            Spacer()
            StatBadge(icon: "flame", value: "\(timerService.calculateStreak()) day streak")
        }
        .padding(.top, 4)
    }
}

struct StatBadge: View {
    var icon: String
    var value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
