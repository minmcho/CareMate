//
//  ChatView.swift
//  Conversational wellness coach with agent-aware styling.
//

import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: ChatViewModel

    init() {
        let url = URL(string: "https://api.vitalpath.ai/graphql")!
        _vm = State(initialValue: ChatViewModel(
            client: GraphQLClient(endpoint: url),
            tokenProvider: { nil }
        ))
    }

    var body: some View {
        @Bindable var vm = vm
        return NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            if vm.busy {
                                TypingIndicator()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        if let last = vm.messages.last {
                            withAnimation(.spring) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                if let notice = vm.rewriteNotice {
                    Label(notice, systemImage: "shield.lefthalf.filled")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        .transition(.opacity)
                }

                composer
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 8)
            }
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .onChange(of: vm.crisisTriggered) { _, newValue in
                if newValue { appState.crisisVisible = true }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Share what's on your mind…", text: $vm.input, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Button {
                Task { await vm.send() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(colors: [.indigo, .purple],
                                       startPoint: .top, endPoint: .bottom),
                        in: Circle()
                    )
            }
            .disabled(vm.input.trimmingCharacters(in: .whitespaces).isEmpty || vm.busy)
        }
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
    }
}

struct MessageBubble: View {
    let message: ChatViewModel.ChatDTO

    var body: some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                if message.role == "assistant", let agent = message.agent {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text(agent.uppercased())
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.secondary)
                }
                Text(message.content)
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                message.role == "user"
                    ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .foregroundStyle(message.role == "user" ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: message.role == "user" ? 0 : 1)
            )
            if message.role == "assistant" { Spacer(minLength: 40) }
        }
    }
}

struct TypingIndicator: View {
    @State private var t: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.purple)
                    .frame(width: 6, height: 6)
                    .offset(y: sin((t + CGFloat(i) * 0.4)) * 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                t = .pi
            }
        }
    }
}
