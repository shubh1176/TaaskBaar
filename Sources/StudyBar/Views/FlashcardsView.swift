import SwiftUI

struct FlashcardsView: View {
    @StateObject private var viewModel = FlashcardsViewModel()
    @State private var showAddSheet = false
    @State private var question = ""
    @State private var answer = ""
    @State private var deck = "General"
    @State private var reviewMode = false
    @State private var flipped = false
    @State private var reviewProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            header
            if viewModel.flashcards.isEmpty {
                emptyState
            } else if reviewMode, let card = viewModel.currentCard {
                reviewCard(card)
            } else {
                cardList
            }
        }
        .sheet(isPresented: $showAddSheet) { addCardSheet }
        .onAppear { viewModel.refresh() }
    }

    private var header: some View {
        HStack {
            let due = viewModel.dueCards.count
            if due > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 8))
                    Text("\(due) due")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Text("\(viewModel.flashcards.count) cards")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: { showAddSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.stack")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No flashcards yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Add your first card to get started")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var cardList: some View {
        VStack(spacing: 8) {
            if !viewModel.dueCards.isEmpty {
                Button(action: {
                    viewModel.currentIndex = 0
                    flipped = false
                    reviewProgress = 0
                    reviewMode = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text("Review \(viewModel.dueCards.count) due cards")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .sbButton(.orange)
            }

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.flashcards) { card in
                        cardRow(card)
                    }
                }
            }
        }
    }

    private func cardRow(_ card: Flashcard) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(card.question)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(card.answer)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7))
                        .foregroundStyle(.green)
                    Text("\(card.correctCount)")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                Text("d\(card.interval)")
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func reviewCard(_ card: Flashcard) -> some View {
        VStack(spacing: 14) {
            let total = viewModel.dueCards.count
            let remaining = total - viewModel.currentIndex
            HStack {
                Text("\(remaining) remaining")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                ProgressView(value: Double(viewModel.currentIndex), total: Double(total))
                    .tint(.orange)
                    .frame(width: 80)
                Spacer()
                Button("End") {
                    flipped = false
                    reviewMode = false
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }

            ZStack {
                cardFace(card.question, label: "Question", color: .blue.opacity(0.1))
                    .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (0, 1, 0))
                    .opacity(flipped ? 0 : 1)
                cardFace(card.answer, label: "Answer", color: .green.opacity(0.1))
                    .rotation3DEffect(.degrees(flipped ? 0 : 180), axis: (0, 1, 0))
                    .opacity(flipped ? 1 : 0)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: flipped)
            .onTapGesture {
                withAnimation { flipped.toggle() }
            }

            if flipped {
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            viewModel.rateCard(card.id, correct: false)
                            flipped = false
                            reviewProgress = CGFloat(viewModel.currentIndex)
                            if viewModel.currentCard == nil { reviewMode = false }
                        }
                    }) {
                        Label("Again", systemImage: "xmark.circle")
                            .font(.system(size: 11))
                    }
                    .sbButton(.red)

                    Button(action: {
                        withAnimation {
                            viewModel.rateCard(card.id, correct: true)
                            flipped = false
                            reviewProgress = CGFloat(viewModel.currentIndex)
                            if viewModel.currentCard == nil { reviewMode = false }
                        }
                    }) {
                        Label("Good", systemImage: "checkmark.circle")
                            .font(.system(size: 11))
                    }
                    .sbButton(.green)
                }
            } else {
                Text("Tap to reveal answer")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func cardFace(_ text: String, label: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .cardStyle(padding: 20)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var addCardSheet: some View {
        VStack(spacing: 16) {
            Text("New Flashcard")
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 3) {
                Text("Question").font(.caption2).foregroundStyle(.secondary)
                TextEditor(text: $question)
                    .font(.system(size: 12))
                    .frame(height: 55)
                    .padding(6)
                    .background(.quaternary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Answer").font(.caption2).foregroundStyle(.secondary)
                TextEditor(text: $answer)
                    .font(.system(size: 12))
                    .frame(height: 55)
                    .padding(6)
                    .background(.quaternary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            HStack {
                Button("Cancel") { showAddSheet = false }
                    .sbButton(.secondary)
                Spacer()
                Button("Save") {
                    viewModel.addCard(question: question, answer: answer, deck: deck)
                    question = ""; answer = ""
                    showAddSheet = false
                }
                .sbButton(.blue)
                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320, height: 300)
    }
}
