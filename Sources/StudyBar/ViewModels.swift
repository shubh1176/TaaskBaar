import Foundation
import Combine
import SwiftUI

// MARK: - TasksViewModel
@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [StudyTask] = []
    @Published var newTaskText: String = ""

    private let storage = StorageService.shared

    init() {
        refresh()
    }

    func refresh() {
        tasks = storage.readTasks().sorted { $0.createdAt > $1.createdAt }
    }

    func addTask(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = StudyTask(text: trimmed)
        storage.addTask(task)
        Haptics.success()
        refresh()
    }

    func toggleTask(_ id: UUID) {
        storage.toggleTask(id)
        Haptics.tap()
        refresh()
    }

    func deleteTask(_ id: UUID) {
        storage.deleteTask(id)
        Haptics.tap()
        refresh()
    }

    var incompleteTasks: [StudyTask] { tasks.filter { !$0.isCompleted } }
    var completedTasks: [StudyTask] { tasks.filter { $0.isCompleted } }
}

// MARK: - FlashcardsViewModel
@MainActor
class FlashcardsViewModel: ObservableObject {
    @Published var flashcards: [Flashcard] = []
    @Published var newQuestion: String = ""
    @Published var newAnswer: String = ""
    @Published var newDeck: String = "General"
    @Published var showingAnswer = false
    @Published var currentIndex: Int = 0

    private let storage = StorageService.shared

    var currentCard: Flashcard? {
        guard !flashcards.isEmpty, currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }

    var dueCards: [Flashcard] {
        flashcards.filter { $0.nextReview <= Date() }
    }

    init() { refresh() }

    func refresh() {
        flashcards = storage.readFlashcards().sorted { $0.createdAt > $1.createdAt }
    }

    func addCard(question: String, answer: String, deck: String) {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !a.isEmpty else { return }
        let card = Flashcard(question: q, answer: a, deck: deck.isEmpty ? "General" : deck)
        storage.addFlashcard(card)
        Haptics.success()
        refresh()
    }

    func rateCard(_ id: UUID, correct: Bool) {
        storage.updateFlashcard(id) { card in
            if correct {
                card.correctCount += 1
                card.interval = min(card.interval * 2, 60)
            } else {
                card.incorrectCount += 1
                card.interval = max(card.interval / 2, 1)
            }
            card.lastReviewed = Date()
            card.nextReview = Calendar.current.date(byAdding: .day, value: card.interval, to: Date()) ?? Date()
        }
        Haptics.tap()
        refresh()
    }

    func deleteCard(_ id: UUID) {
        storage.deleteFlashcard(id)
        Haptics.tap()
        refresh()
    }

    var decks: [String] {
        Array(Set(flashcards.map(\.deck))).sorted()
    }
}

// MARK: - RevisionsViewModel
@MainActor
class RevisionsViewModel: ObservableObject {
    @Published var topics: [RevisionTopic] = []
    @Published var newTopicName: String = ""

    private let storage = StorageService.shared

    init() { refresh() }

    func refresh() {
        topics = storage.readRevisionTopics().sorted { $0.createdAt > $1.createdAt }
    }

    func addTopic(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let topic = RevisionTopic(topic: trimmed)
        storage.addRevisionTopic(topic)
        Haptics.success()
        refresh()
    }

    func markStage(_ topicId: UUID, index: Int) {
        storage.markStageReviewed(topicId, dayIndex: index)
        Haptics.success()
        refresh()
    }

    func deleteTopic(_ id: UUID) {
        storage.deleteRevisionTopic(id)
        Haptics.tap()
        refresh()
    }

    var pendingReviews: Int {
        var count = 0
        for topic in topics {
            for stage in topic.stages where !stage.reviewed {
                let scheduledDay = Calendar.current.date(byAdding: .day, value: stage.day, to: topic.createdAt) ?? topic.createdAt
                if scheduledDay <= Date() {
                    count += 1
                }
            }
        }
        return count
    }
}

// MARK: - ExamsViewModel
@MainActor
class ExamsViewModel: ObservableObject {
    @Published var exams: [Exam] = []
    @Published var newTitle: String = ""
    @Published var newDate: Date = Date().addingTimeInterval(86400 * 7)

    private let storage = StorageService.shared

    init() { refresh() }

    func refresh() {
        exams = storage.readExams().sorted { $0.date < $1.date }
    }

    func addExam(title: String, date: Date) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let exam = Exam(title: trimmed, date: date)
        storage.addExam(exam)
        Haptics.success()
        refresh()
    }

    func deleteExam(_ id: UUID) {
        storage.deleteExam(id)
        Haptics.tap()
        refresh()
    }

    func daysUntil(_ exam: Exam) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: exam.date).day ?? 0
    }

    func colorForDays(_ days: Int) -> Color {
        if days <= 3 { return .sbRed }
        if days <= 7 { return .sbOrange }
        return .sbGreen
    }
}

// MARK: - DistractionsViewModel
@MainActor
class DistractionsViewModel: ObservableObject {
    @Published var entries: [DistractionEntry] = []

    private let storage = StorageService.shared

    init() { refresh() }

    func refresh() {
        entries = storage.readDistractions().sorted { $0.date > $1.date }
    }

    func logDistraction(app: String, seconds: Int, isDistracting: Bool) {
        let entry = DistractionEntry(appName: app, durationSeconds: seconds, isDistracting: isDistracting)
        storage.addDistraction(entry)
        refresh()
    }

    var todayFocusSeconds: Int {
        let today = Date().startOfDay
        return entries.filter { !$0.isDistracting && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    var todayDistractionSeconds: Int {
        let today = Date().startOfDay
        return entries.filter { $0.isDistracting && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.durationSeconds }
    }
}

// MARK: - SessionsViewModel
@MainActor
class SessionsViewModel: ObservableObject {
    @Published var sessions: [StudySession] = []
    @Published var searchText: String = ""

    private let storage = StorageService.shared

    init() { refresh() }

    func refresh() {
        sessions = storage.readSessions().sorted { $0.startedAt > $1.startedAt }
    }

    func deleteSession(_ id: UUID) {
        storage.deleteSession(id)
        Haptics.tap()
        refresh()
    }

    var filteredSessions: [StudySession] {
        if searchText.isEmpty { return sessions }
        return sessions.filter {
            $0.subject.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
}
