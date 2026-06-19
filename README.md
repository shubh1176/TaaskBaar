# StudyBar — The Student Command Center

A macOS menu bar app for focused studying. Quick capture, Pomodoro timer, flashcards, spaced revision scheduling, exam countdowns, and distraction tracking — all from the menu bar.

## Features

- **Quick Capture** — `⌘⇧Space` to capture tasks from anywhere
- **Smart Timer** — Pomodoro, Deep Work, and custom sessions with break reminders
- **Flashcard Vault** — Spaced repetition with 3D flip review
- **Revision Scheduler** — Topics auto-scheduled at 1, 3, 7, 14, 30 day intervals
- **Exam Countdown** — Color-coded urgency for upcoming exams
- **Focus Dashboard** — Weekly charts, daily breakdowns, streak tracking
- **Distraction Tracker** — Monitor focus vs. distraction time
- **Session Notes** — Searchable study session history

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15+

## Build & Run

```bash
xed Package.swift
```

Press `⌘R` in Xcode. The app runs as a menu bar agent (no dock icon).

## Tech Stack

SwiftUI + AppKit, Swift Package Manager, JSON persistence (no dependencies).
