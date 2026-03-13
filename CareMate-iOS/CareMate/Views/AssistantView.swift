import SwiftUI

struct AssistantView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AssistantViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                messageList
                Divider()
                inputBar
            }
            .navigationTitle("AI Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    memoryToggle
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    clearButton
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        welcomeMessage
                    }
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if viewModel.isLoading {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.7))
            Text("CareMate AI Assistant")
                .font(.title2.bold())
            Text("Ask me about schedules, medications, diet, or anything about caregiving.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 40)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask CareMate...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($isInputFocused)

            // Voice button
            Button {
                if viewModel.isRecording {
                    Task {
                        await viewModel.stopRecordingAndSend(
                            userId: appState.userId,
                            language: appState.language.rawValue
                        )
                    }
                } else {
                    viewModel.startRecording()
                }
            } label: {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.isRecording ? .red : .blue)
            }

            // Send button
            Button {
                Task {
                    await viewModel.sendMessage(
                        userId: appState.userId,
                        language: appState.language.rawValue
                    )
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.inputText.isEmpty ? .gray : .blue)
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    // MARK: - Toolbar items

    private var memoryToggle: some View {
        Button {
            viewModel.useMemory.toggle()
        } label: {
            Label(
                viewModel.useMemory ? "Memory On" : "Memory Off",
                systemImage: viewModel.useMemory ? "brain.filled.head.profile" : "brain"
            )
            .font(.caption)
        }
    }

    private var clearButton: some View {
        Button {
            Task { await viewModel.clearHistory(userId: appState.userId) }
        } label: {
            Image(systemName: "trash")
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(18)

                HStack(spacing: 6) {
                    if !isUser, let agent = message.agentUsed {
                        Label(agent, systemImage: "cpu")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if message.isMemoryHit {
                        Label("cached", systemImage: "bolt.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - TypingIndicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.secondary)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
            }
        }
        .padding(10)
        .background(Color(.systemGray5))
        .cornerRadius(16)
        .onAppear { phase = 0 }
    }
}
