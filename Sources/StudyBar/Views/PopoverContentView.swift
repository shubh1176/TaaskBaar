import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject var timerService: TimerService
    @State private var selectedSection: Section = .dashboard
    @State private var showSettings = false

    enum Section: String, CaseIterable {
        case dashboard = "Dashboard"
        case tasks = "Tasks"
        case timer = "Timer"
        case flashcards = "Flashcards"
        case revisions = "Revisions"
        case exams = "Exams"
        case distractions = "Focus"
        case sessions = "Notes"

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .tasks: return "checklist"
            case .timer: return "timer"
            case .flashcards: return "rectangle.stack"
            case .revisions: return "arrow.triangle.2.circlepath"
            case .exams: return "calendar.badge.clock"
            case .distractions: return "eye.slash"
            case .sessions: return "book.closed"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 52)
                .background(.ultraThinMaterial)

            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 540)
        .background(Color.sbBackground)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(width: 380, height: 420)
        }
    }

    private var sidebar: some View {
        VStack(spacing: 2) {
            Image(systemName: "timer")
                .font(.title3)
                .foregroundStyle(.orange)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ForEach(Section.allCases, id: \.self) { section in
                sidebarButton(section)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 8)
    }

    private func sidebarButton(_ section: Section) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSection = section
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: section.icon)
                    .font(.system(size: 16))
                Text(section.rawValue)
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(selectedSection == section ? .orange : .secondary)
            .frame(width: 36, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selectedSection == section ? Color.orange.opacity(0.12) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text(selectedSection.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if selectedSection == .tasks {
                    quickCaptureHint
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            ScrollView {
                contentView
                    .padding(16)
            }
        }
    }

    private var quickCaptureHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "command")
                .font(.system(size: 8))
            Text("⇧ Space")
                .font(.system(size: 8, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .dashboard: DashboardView()
        case .tasks: TasksView()
        case .timer: TimerView()
        case .flashcards: FlashcardsView()
        case .revisions: RevisionsView()
        case .exams: ExamsView()
        case .distractions: DistractionsView()
        case .sessions: SessionNotesView()
        }
    }
}
