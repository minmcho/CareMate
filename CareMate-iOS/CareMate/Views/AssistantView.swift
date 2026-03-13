import SwiftUI

struct AssistantView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AssistantViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                inputBar
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                LazyVStack(spacing: 10) {
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
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var welcomeMessage: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
            }
            VStack(spacing: 8) {
                Text("CareMate AI")
                    .font(.title2.bold())
                Text("Ask me about schedules, medications, diet,\nor anything about caregiving.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Quick suggestion pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Today's schedule", "Medication reminder", "Diet advice", "Caregiver tips"], id: \.self) { suggestion in
                        Button {
                            viewModel.inputText = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 0.8))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(24)
        .glassCard(cornerRadius: 28, padding: 0)
        .padding(.horizontal)
        .padding(.top, 20)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            // Text field with glass background
            TextField("Ask CareMate...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.3), lineWidth: 0.8)
                }
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
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? .red.opacity(0.15) : .blue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.isRecording ? .red : .blue)
                        .symbolEffect(.pulse, isActive: viewModel.isRecording)
                }
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
                ZStack {
                    Circle()
                        .fill(viewModel.inputText.isEmpty ? .gray.opacity(0.1) : .blue)
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(viewModel.inputText.isEmpty ? .gray : .white)
                }
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 0.5)
        }
    }

    // MARK: - Toolbar items

    private var memoryToggle: some View {
        Button {
            viewModel.useMemory.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.useMemory ? "brain.filled.head.profile" : "brain")
                    .symbolRenderingMode(.hierarchical)
                Text(viewModel.useMemory ? "Memory" : "Memory")
                    .font(.caption.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(viewModel.useMemory ? .blue.opacity(0.15) : .gray.opacity(0.1), in: Capsule())
            .foregroundStyle(viewModel.useMemory ? .blue : .secondary)
        }
    }

    private var clearButton: some View {
        Button {
            Task { await viewModel.clearHistory(userId: appState.userId) }
        } label: {
            Image(systemName: "trash")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.red)
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                // Assistant avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 5) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        if isUser {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        } else {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(.white.opacity(0.3), lineWidth: 0.8)
                                }
                        }
                    }
                    .foregroundStyle(isUser ? .white : .primary)
                    .shadow(color: isUser ? .blue.opacity(0.25) : .black.opacity(0.06), radius: 6, x: 0, y: 3)

                HStack(spacing: 6) {
                    if !isUser, let agent = message.agentUsed {
                        Label(agent, systemImage: "cpu")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if message.isMemoryHit {
                        Label("cached", systemImage: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
            }

            if isUser { Spacer(minLength: 0).frame(width: 0) }
        }
    }
}

// MARK: - TypingIndicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(.secondary)
                    .scaleEffect(animating ? 1.0 : 0.6)
                    .opacity(animating ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.3), lineWidth: 0.8)
        }
        .onAppear { animating = true }
    }
}
