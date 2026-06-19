import Foundation

final class StorageService: @unchecked Sendable {
    static let shared = StorageService()

    private var data = AppData()
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.studybar.storage", qos: .utility)

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("StudyBar")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("data.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    // MARK: - Sync Reads (Main thread safe)

    func readSettings() -> AppSettings { queue.sync { data.settings } }
    func readTasks() -> [StudyTask] { queue.sync { data.tasks } }
    func readSessions() -> [StudySession] { queue.sync { data.sessions } }
    func readFlashcards() -> [Flashcard] { queue.sync { data.flashcards } }
    func readRevisionTopics() -> [RevisionTopic] { queue.sync { data.revisionTopics } }
    func readExams() -> [Exam] { queue.sync { data.exams } }
    func readDistractions() -> [DistractionEntry] { queue.sync { data.distractionEntries } }
    func readAll() -> AppData { queue.sync { data } }

    // MARK: - Mutations

    func updateSettings(_ mutate: @escaping (inout AppSettings) -> Void) {
        queue.async(flags: .barrier) {
            mutate(&self.data.settings)
            self.persist()
        }
    }

    // MARK: - Task Operations

    func addTask(_ task: StudyTask) {
        queue.async(flags: .barrier) {
            self.data.tasks.append(task)
            self.persist()
        }
    }

    func toggleTask(_ id: UUID) {
        queue.async(flags: .barrier) {
            guard let idx = self.data.tasks.firstIndex(where: { $0.id == id }) else { return }
            if self.data.tasks[idx].isCompleted {
                self.data.tasks[idx].completedAt = nil
            } else {
                self.data.tasks[idx].completedAt = Date()
            }
            self.persist()
        }
    }

    func deleteTask(_ id: UUID) {
        queue.async(flags: .barrier) {
            self.data.tasks.removeAll { $0.id == id }
            self.persist()
        }
    }

    // MARK: - Session Operations

    func addSession(_ session: StudySession) {
        queue.async(flags: .barrier) {
            self.data.sessions.append(session)
            self.persist()
        }
    }

    func updateSession(_ id: UUID, _ mutate: @escaping (inout StudySession) -> Void) {
        queue.async(flags: .barrier) {
            guard let idx = self.data.sessions.firstIndex(where: { $0.id == id }) else { return }
            mutate(&self.data.sessions[idx])
            self.persist()
        }
    }

    func deleteSession(_ id: UUID) {
        queue.async(flags: .barrier) {
            self.data.sessions.removeAll { $0.id == id }
            self.persist()
        }
    }

    // MARK: - Flashcard Operations

    func addFlashcard(_ card: Flashcard) {
        queue.async(flags: .barrier) {
            self.data.flashcards.append(card)
            self.persist()
        }
    }

    func updateFlashcard(_ id: UUID, _ mutate: @escaping (inout Flashcard) -> Void) {
        queue.async(flags: .barrier) {
            guard let idx = self.data.flashcards.firstIndex(where: { $0.id == id }) else { return }
            mutate(&self.data.flashcards[idx])
            self.persist()
        }
    }

    func deleteFlashcard(_ id: UUID) {
        queue.async(flags: .barrier) {
            self.data.flashcards.removeAll { $0.id == id }
            self.persist()
        }
    }

    // MARK: - Revision Operations

    func addRevisionTopic(_ topic: RevisionTopic) {
        queue.async(flags: .barrier) {
            self.data.revisionTopics.append(topic)
            self.persist()
        }
    }

    func markStageReviewed(_ topicId: UUID, dayIndex: Int) {
        queue.async(flags: .barrier) {
            guard let idx = self.data.revisionTopics.firstIndex(where: { $0.id == topicId }),
                  dayIndex < self.data.revisionTopics[idx].stages.count else { return }
            self.data.revisionTopics[idx].stages[dayIndex].reviewed = true
            self.data.revisionTopics[idx].stages[dayIndex].reviewedAt = Date()
            self.persist()
        }
    }

    func deleteRevisionTopic(_ id: UUID) {
        queue.async(flags: .barrier) {
            self.data.revisionTopics.removeAll { $0.id == id }
            self.persist()
        }
    }

    // MARK: - Exam Operations

    func addExam(_ exam: Exam) {
        queue.async(flags: .barrier) {
            self.data.exams.append(exam)
            self.persist()
        }
    }

    func deleteExam(_ id: UUID) {
        queue.async(flags: .barrier) {
            self.data.exams.removeAll { $0.id == id }
            self.persist()
        }
    }

    // MARK: - Distraction Operations

    func addDistraction(_ entry: DistractionEntry) {
        queue.async(flags: .barrier) {
            self.data.distractionEntries.append(entry)
            self.persist()
        }
    }

    // MARK: - Persistence

    private func load() {
        queue.sync {
            guard let raw = try? Data(contentsOf: self.fileURL),
                  let decoded = try? self.decoder.decode(AppData.self, from: raw) else {
                self.data = AppData()
                return
            }
            self.data = decoded
        }
    }

    private func persist() {
        guard let raw = try? encoder.encode(data) else { return }
        try? raw.write(to: fileURL, options: .atomic)
    }

    func forceSave() {
        queue.sync(flags: .barrier) {
            self.persist()
        }
    }
}
