import Foundation
import Speech
import AVFoundation

class SpeechService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var recordingError: String?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?

    // For audio capture (to send to backend STT)
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    override init() {
        super.init()
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        let micStatus = await AVAudioApplication.requestRecordPermission()
        return speechStatus == .authorized && micStatus
    }

    // MARK: - On-device transcription (English)

    func startOnDeviceTranscription(locale: Locale = Locale(identifier: "en-US")) throws {
        guard !isRecording else { return }
        recognizer = SFSpeechRecognizer(locale: locale)
        let node = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcript = result.bestTranscription.formattedString
                }
            }
            if error != nil || result?.isFinal == true {
                self?.stopRecording()
            }
        }

        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        DispatchQueue.main.async { self.isRecording = true }
    }

    // MARK: - Raw audio recording (for backend STT via Whisper)

    func startAudioRecording() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
        ]
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        DispatchQueue.main.async { self.isRecording = true }
        return url
    }

    func stopAudioRecording() -> Data? {
        audioRecorder?.stop()
        DispatchQueue.main.async { self.isRecording = false }
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }

    // MARK: - Stop

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioRecorder?.stop()
        DispatchQueue.main.async { self.isRecording = false }
    }

    // MARK: - TTS Playback

    private var audioPlayer: AVAudioPlayer?

    func playAudio(base64: String) throws {
        guard let data = Data(base64Encoded: base64) else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")
        try data.write(to: url)
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
}
