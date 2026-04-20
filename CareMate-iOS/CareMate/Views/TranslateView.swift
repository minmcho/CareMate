import SwiftUI

struct TranslateView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var speechService = SpeechService()

    @State private var sourceLanguage = "my"
    @State private var targetLanguage = "en"
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var isRecording = false
    @State private var errorMessage: String?

    let languages = [
        ("en", "English"),
        ("my", "Myanmar"),
        ("th", "Thai"),
        ("ar", "Arabic"),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    languagePicker
                    sourcePanel
                    translateButton
                    if !translatedText.isEmpty {
                        translatedPanel
                    }
                }
                .padding()
            }
            .navigationTitle("Translate")
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    // MARK: - Language picker

    private var languagePicker: some View {
        HStack {
            Picker("From", selection: $sourceLanguage) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Button {
                swap(&sourceLanguage, &targetLanguage)
                swap(&inputText, &translatedText)
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .padding()
            }

            Picker("To", selection: $targetLanguage) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Source panel

    private var sourcePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageName(sourceLanguage))
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $inputText)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)

            HStack {
                Button {
                    isRecording ? stopVoiceInput() : startVoiceInput()
                } label: {
                    Label(
                        isRecording ? "Stop" : "Speak",
                        systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .foregroundColor(isRecording ? .red : .blue)
                }
                Spacer()
                if !inputText.isEmpty {
                    Button("Clear") { inputText = ""; translatedText = "" }
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Translate button

    private var translateButton: some View {
        Button {
            Task { await translateText() }
        } label: {
            if isTranslating {
                ProgressView().tint(.white)
            } else {
                Label("Translate", systemImage: "character.bubble.fill")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(14)
        .disabled(inputText.isEmpty || isTranslating)
    }

    // MARK: - Translated result panel

    private var translatedPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageName(targetLanguage))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(translatedText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)

            HStack {
                Button {
                    Task {
                        if let audio = await synthesizeSpeech(translatedText, lang: targetLanguage) {
                            try? speechService.playAudio(base64: audio)
                        }
                    }
                } label: {
                    Label("Play", systemImage: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = translatedText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Actions

    private func translateText() async {
        isTranslating = true
        defer { isTranslating = false }
        struct Req: Codable { let text: String; let source_lang: String; let target_lang: String }
        struct Res: Codable { let translated_text: String }
        do {
            let res: Res = try await APIService.shared.post(
                "/api/translate/text",
                body: Req(text: inputText, source_lang: sourceLanguage, target_lang: targetLanguage)
            )
            translatedText = res.translated_text
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startVoiceInput() {
        Task {
            let granted = await speechService.requestPermissions()
            guard granted else { errorMessage = "Microphone permission denied"; return }
            do {
                _ = try speechService.startAudioRecording()
                isRecording = true
            } catch { errorMessage = error.localizedDescription }
        }
    }

    private func stopVoiceInput() {
        isRecording = false
        guard let audioData = speechService.stopAudioRecording() else { return }
        let b64 = audioData.base64EncodedString()
        Task { await translateAudio(b64) }
    }

    private func translateAudio(_ b64: String) async {
        isTranslating = true
        defer { isTranslating = false }
        struct Req: Codable { let audio_base64: String; let source_lang: String; let target_lang: String; let return_audio: Bool }
        struct Res: Codable { let original_text: String?; let translated_text: String }
        do {
            let res: Res = try await APIService.shared.post(
                "/api/translate/audio",
                body: Req(audio_base64: b64, source_lang: sourceLanguage, target_lang: targetLanguage, return_audio: false)
            )
            inputText = res.original_text ?? ""
            translatedText = res.translated_text
        } catch { errorMessage = error.localizedDescription }
    }

    private func synthesizeSpeech(_ text: String, lang: String) async -> String? {
        struct Req: Codable { let text: String; let language: String }
        struct Res: Codable { let audio_base64: String }
        let res = try? await APIService.shared.post("/api/translate/tts", body: Req(text: text, language: lang)) as Res
        return res?.audio_base64
    }

    private func languageName(_ code: String) -> String {
        languages.first { $0.0 == code }?.1 ?? code
    }
}
