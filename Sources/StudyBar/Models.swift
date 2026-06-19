import Foundation

// MARK: - Task
struct StudyTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var createdAt = Date()
    var completedAt: Date?
    var sessionId: UUID?

    var isCompleted: Bool { completedAt != nil }
}

// MARK: - Session
enum SessionType: String, Codable, CaseIterable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case custom = "Custom"
}

struct StudySession: Identifiable, Codable, Equatable {
    var id = UUID()
    var subject: String
    var notes: String
    var type: SessionType
    var startedAt = Date()
    var endedAt: Date?
    var durationSeconds: Int = 0
    var completed: Bool = false
}

// MARK: - Flashcard
struct Flashcard: Identifiable, Codable, Equatable {
    var id = UUID()
    var question: String
    var answer: String
    var deck: String = "General"
    var createdAt = Date()
    var lastReviewed: Date?
    var nextReview = Date()
    var interval: Int = 1
    var correctCount: Int = 0
    var incorrectCount: Int = 0
}

// MARK: - Revision
struct RevisionTopic: Identifiable, Codable, Equatable {
    var id = UUID()
    var topic: String
    var createdAt = Date()
    var stages: [RevisionStage] = [
        RevisionStage(day: 1),
        RevisionStage(day: 3),
        RevisionStage(day: 7),
        RevisionStage(day: 14),
        RevisionStage(day: 30)
    ]
}

struct RevisionStage: Codable, Equatable {
    var day: Int
    var reviewed = false
    var reviewedAt: Date?
}

// MARK: - Exam
struct Exam: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var colorName: String = "blue"
}

// MARK: - DistractionEntry
struct DistractionEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var appName: String
    var durationSeconds: Int
    var date = Date()
    var isDistracting: Bool
}

// MARK: - App Settings
struct AppSettings: Codable, Equatable {
    var pomodoroWorkMinutes: Int = 25
    var pomodoroBreakMinutes: Int = 5
    var deepWorkMinutes: Int = 90
    var deepWorkBreakMinutes: Int = 15
    var enableBreakReminders = true
    var soundEnabled = true
    var autoStartBreaks = false
    var focusApps: [String] = []
    var distractingApps: [String] = ["YouTube", "Netflix", "Games", "Twitter", "Instagram", "Reddit"]
    var dailyGoalHours: Double = 4
    var notificationsEnabled = true
}

// MARK: - App Data (root persistence object)
struct AppData: Codable {
    var tasks: [StudyTask] = []
    var sessions: [StudySession] = []
    var flashcards: [Flashcard] = []
    var revisionTopics: [RevisionTopic] = []
    var exams: [Exam] = []
    var distractionEntries: [DistractionEntry] = []
    var settings = AppSettings()
    var streakStartDate: Date?
}
