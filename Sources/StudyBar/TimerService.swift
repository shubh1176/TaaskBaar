import Foundation
import Combine
import AppKit

enum TimerState: Equatable {
    case idle
    case running(since: Date)
    case paused(elapsed: Int)
    case break_(since: Date)

    var label: String {
        switch self {
        case .idle: return "Idle"
        case .running: return "Focus"
        case .paused: return "Paused"
        case .break_: return "Break"
        }
    }

    var isActive: Bool {
        if case .running = self { return true }
        return false
    }
}

@MainActor
class TimerService: ObservableObject {
    static let shared = TimerService()

    @Published var state: TimerState = .idle
    @Published var currentSessionId: UUID?
    @Published var sessionSubject: String = ""
    @Published var sessionType: SessionType = .pomodoro
    @Published var showBreakReminder = false
    @Published var focusSecondsToday: Int = 0

    private var timer: Timer?
    private let storage = StorageService.shared

    var workSeconds: Int {
        switch sessionType {
        case .pomodoro: return storage.readSettings().pomodoroWorkMinutes * 60
        case .deepWork: return storage.readSettings().deepWorkMinutes * 60
        case .custom: return storage.readSettings().pomodoroWorkMinutes * 60
        }
    }

    var breakSeconds: Int {
        switch sessionType {
        case .pomodoro: return storage.readSettings().pomodoroBreakMinutes * 60
        case .deepWork: return storage.readSettings().deepWorkBreakMinutes * 60
        case .custom: return 5 * 60
        }
    }

    var totalSeconds: Int {
        switch state {
        case .running(let since):
            return Int(-since.timeIntervalSinceNow)
        case .paused(let elapsed):
            return elapsed
        case .break_(let since):
            return Int(-since.timeIntervalSinceNow)
        case .idle:
            return 0
        }
    }

    var displayString: String {
        let total = totalSeconds
        let isBrk: Bool
        if case .break_ = state { isBrk = true } else { isBrk = false }
        let mx = isBrk ? breakSeconds : workSeconds
        let remaining = Swift.max(mx - total, 0)

        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let secs = remaining % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    var progress: Double {
        let total = totalSeconds
        let mx: Int
        if case .break_ = state { mx = breakSeconds } else { mx = workSeconds }
        guard mx > 0 else { return 0 }
        return Double(total) / Double(mx)
    }

    func start() {
        state = .running(since: Date())
        startTimer()
        let session = StudySession(
            subject: sessionSubject,
            notes: "",
            type: sessionType,
            startedAt: Date()
        )
        storage.addSession(session)
        if let sessions = storage.readSessions().last, sessions.id == session.id {
            currentSessionId = session.id
        }
    }

    func pause() {
        guard case .running(let since) = state else { return }
        state = .paused(elapsed: Int(-since.timeIntervalSinceNow))
        stopTimer()
    }

    func resume() {
        guard case .paused(let elapsed) = state else { return }
        state = .running(since: Date().addingTimeInterval(-Double(elapsed)))
        startTimer()
    }

    func stop() {
        stopTimer()
        let elapsed = totalSeconds
        if let id = currentSessionId {
            storage.updateSession(id) { session in
                session.endedAt = Date()
                session.durationSeconds = elapsed
                session.completed = true
            }
        }
        state = .idle
        currentSessionId = nil
        showBreakReminder = false
        refreshTodayStats()
    }

    func startBreak() {
        state = .break_(since: Date())
        startTimer()
        showBreakReminder = false
    }

    func completeBreak() {
        stopTimer()
        state = .idle
        showBreakReminder = false
    }

    func skipBreak() {
        stopTimer()
        state = .idle
        showBreakReminder = false
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        objectWillChange.send()
        let total = totalSeconds
        if case .break_ = state {
            if total >= breakSeconds {
                if storage.readSettings().soundEnabled { NSSound(named: "Glass")?.play() }
                completeBreak()
            }
        } else if case .running = state {
            if total >= workSeconds {
                if storage.readSettings().soundEnabled { NSSound(named: "Glass")?.play() }
                stopTimer()
                if storage.readSettings().autoStartBreaks {
                    startBreak()
                } else {
                    showBreakReminder = true
                }
            }
        }
    }

    func refreshTodayStats() {
        let today = Date().startOfDay
        let sessions = storage.readSessions().filter {
            Calendar.current.isDate($0.startedAt, inSameDayAs: today)
        }
        focusSecondsToday = sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    func calculateStreak() -> Int {
        let sessions = storage.readSessions()
        let tasks = storage.readTasks()
        let cal = Calendar.current
        var streak = 0
        var day = Date().startOfDay

        while true {
            let hasSession = sessions.contains { cal.isDate($0.startedAt, inSameDayAs: day) }
            let hasTask = tasks.contains { $0.completedAt.map { cal.isDate($0, inSameDayAs: day) } ?? false }
            if hasSession || hasTask {
                streak += 1
                day = cal.date(byAdding: .day, value: -1, to: day)!
            } else {
                break
            }
        }
        return streak
    }

    struct DailyStats {
        var focusSeconds: Int = 0
        var tasksCompleted: Int = 0
        var streak: Int = 0
        var flashcardsReviewed: Int = 0
    }

    func getDailyStats() -> DailyStats {
        let today = Date().startOfDay
        let sessions = storage.readSessions().filter {
            Calendar.current.isDate($0.startedAt, inSameDayAs: today)
        }
        let tasks = storage.readTasks().filter {
            $0.completedAt.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false
        }
        let flashcards = storage.readFlashcards().filter {
            $0.lastReviewed.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false
        }
        return DailyStats(
            focusSeconds: sessions.reduce(0) { $0 + $1.durationSeconds },
            tasksCompleted: tasks.count,
            streak: calculateStreak(),
            flashcardsReviewed: flashcards.count
        )
    }
}
