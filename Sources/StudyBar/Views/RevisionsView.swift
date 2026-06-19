import SwiftUI

struct RevisionsView: View {
    @StateObject private var viewModel = RevisionsViewModel()
    @State private var newTopic: String = ""

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("New topic...", text: $newTopic)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit {
                        viewModel.addTopic(newTopic)
                        newTopic = ""
                    }
                Button(action: {
                    viewModel.addTopic(newTopic)
                    newTopic = ""
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .sbButton(.blue)
                .disabled(newTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if viewModel.topics.isEmpty {
                emptyState
            } else {
                if viewModel.pendingReviews > 0 {
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("\(viewModel.pendingReviews) pending reviews")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                ForEach(viewModel.topics) { topic in
                    topicCard(topic)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No revision topics")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Add a topic and revise at\n1, 3, 7, 14, 30 day intervals")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func topicCard(_ topic: RevisionTopic) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(topic.topic)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Button {
                    viewModel.deleteTopic(topic.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            let cal = Calendar.current
            HStack(spacing: 6) {
                ForEach(Array(topic.stages.enumerated()), id: \.offset) { index, stage in
                    let daysSinceStart = cal.dateComponents([.day], from: topic.createdAt.startOfDay, to: Date().startOfDay).day ?? 0
                    let isAvailable = daysSinceStart >= stage.day
                    let isDue = isAvailable && !stage.reviewed

                    VStack(spacing: 2) {
                        Circle()
                            .fill(stage.reviewed ? Color.green : (isDue ? Color.orange : Color.gray.opacity(0.3)))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Text("d\(stage.day)")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(stage.reviewed || isDue ? .white : .gray)
                            )
                        Text(stage.reviewed ? "Done" : (isDue ? "Due" : "Soon"))
                            .font(.system(size: 7))
                            .foregroundStyle(stage.reviewed ? Color.green : (isDue ? Color.orange : Color.gray.opacity(0.5)))
                    }
                    .onTapGesture {
                        if isDue {
                            viewModel.markStage(topic.id, index: index)
                        }
                    }
                    .opacity(isAvailable ? 1 : 0.5)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
