import SwiftUI

struct SessionNotesView: View {
    @StateObject private var viewModel = SessionsViewModel()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                TextField("Search sessions...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if viewModel.filteredSessions.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.filteredSessions) { session in
                    sessionCard(session)
                }
            }
        }
        .onAppear { viewModel.refresh() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(viewModel.searchText.isEmpty ? "No sessions yet" : "No matching sessions")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Complete a study session to see it here")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func sessionCard(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(typeColor(session.type))
                    .frame(width: 8, height: 8)
                Text(session.subject)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(session.type.rawValue)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            HStack(spacing: 12) {
                Label("\(session.durationSeconds / 60)m", systemImage: "clock")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(session.startedAt, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                if session.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
            }

            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func typeColor(_ type: SessionType) -> Color {
        switch type {
        case .pomodoro: return .sbOrange
        case .deepWork: return .sbPurple
        case .custom: return .sbBlue
        }
    }
}
