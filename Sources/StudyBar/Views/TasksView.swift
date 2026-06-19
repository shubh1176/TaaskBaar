import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var newTask: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            header
            addBar
            progressSection
            taskList
        }
        .onAppear { viewModel.refresh(); isFocused = true }
    }

    private var header: some View {
        let total = viewModel.tasks.count
        let done = viewModel.completedTasks.count
        let pct = total > 0 ? Double(done) / Double(total) : 0

        return HStack(spacing: 12) {
            ZStack {
                RingProgress(progress: pct, color: .green, lineWidth: 4)
                    .frame(width: 32, height: 32)
                if total > 0 {
                    Text("\(Int(pct * 100))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "checklist")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(done)/\(total) tasks")
                    .font(.system(size: 11, weight: .medium))
                if total > 0 {
                    ProgressView(value: pct)
                        .tint(.green)
                        .scaleEffect(x: 1, y: 0.5)
                }
            }

            Spacer()

            Text("⌘⇧Space")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.quaternary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 4)
    }

    private var addBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.orange)
                .font(.caption)
            TextField("Add a task...", text: $newTask)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($isFocused)
                .onSubmit {
                    viewModel.addTask(newTask)
                    newTask = ""
                    isFocused = true
                }
            if !newTask.isEmpty {
                Button(action: {
                    viewModel.addTask(newTask)
                    newTask = ""
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var progressSection: some View {
        Group {
            if !viewModel.incompleteTasks.isEmpty {
                sectionHeader("Active — \(viewModel.incompleteTasks.count)")
                ForEach(viewModel.incompleteTasks) { task in
                    taskRow(task)
                        .transition(.slide.combined(with: .opacity))
                }
            }
            if !viewModel.completedTasks.isEmpty {
                sectionHeader("Completed — \(viewModel.completedTasks.count)")
                    .padding(.top, 4)
                ForEach(viewModel.completedTasks) { task in
                    taskRow(task)
                        .transition(.slide.combined(with: .opacity))
                }
            }
            if viewModel.tasks.isEmpty {
                emptyState
            }
        }
        .animation(.spring, value: viewModel.tasks.count)
    }

    private var taskList: some View {
        Group {}
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No tasks yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Press ⌘⇧Space from anywhere to capture instantly")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func taskRow(_ task: StudyTask) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring) {
                    viewModel.toggleTask(task.id)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? Color.green : Color.gray.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            Text(task.text)
                .font(.system(size: 12))
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .tertiary : .primary)

            Spacer()

            Button {
                withAnimation(.spring) {
                    viewModel.deleteTask(task.id)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary.opacity(0.4))
                    .opacity(0)
            }
            .buttonStyle(.plain)
            .onHover { _ in }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quaternary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
