import SwiftUI

struct ExamsView: View {
    @StateObject private var viewModel = ExamsViewModel()
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if !viewModel.exams.isEmpty {
                    let next = viewModel.exams.first!
                    let days = viewModel.daysUntil(next)
                    Text("Next: \(next.title) — \(days)d")
                        .font(.caption)
                        .foregroundStyle(viewModel.colorForDays(days))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(viewModel.colorForDays(days).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .sbButton(.blue)
            }

            if viewModel.exams.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.exams) { exam in
                    examCard(exam)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addExamSheet
        }
        .onAppear { viewModel.refresh() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No exams yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Add exams to see countdowns")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func examCard(_ exam: Exam) -> some View {
        let days = viewModel.daysUntil(exam)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exam.title)
                    .font(.system(size: 13, weight: .medium))
                Text(exam.date, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(days)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.colorForDays(days))
                Text(days == 1 ? "day left" : "days left")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }

            Button {
                viewModel.deleteExam(exam.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.quaternary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var addExamSheet: some View {
        VStack(spacing: 16) {
            Text("New Exam")
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Title").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. DSA Test", text: $viewModel.newTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(.quaternary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Date").font(.caption).foregroundStyle(.secondary)
                DatePicker("", selection: $viewModel.newDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }

            HStack {
                Button("Cancel") { showAddSheet = false }
                    .sbButton(.secondary)
                Spacer()
                Button("Add Exam") {
                    viewModel.addExam(title: viewModel.newTitle, date: viewModel.newDate)
                    viewModel.newTitle = ""
                    showAddSheet = false
                }
                .sbButton(.blue)
                .disabled(viewModel.newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340, height: 380)
    }
}
