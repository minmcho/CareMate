import { useState, useRef, useEffect } from "react";
import { Mic, Square, Volume2, RefreshCw, ChevronDown } from "lucide-react";
import { Language, useTranslation } from "../lib/i18n";
import { cn } from "../lib/utils";
import { translateAudio } from "../lib/gemini";

type CaregiverLang = "my" | "th" | "en";
type EmployerLang = "en" | "zh" | "ms" | "ar";

export default function TranslateView({ lang, hideHeader }: { lang: Language; hideHeader?: boolean }) {
  const t = useTranslation(lang);
  const [isRecording, setIsRecording] = useState(false);
  const [isTranslating, setIsTranslating] = useState(false);
  const [speakerRole, setSpeakerRole] = useState<"caregiver" | "employer">(
    "caregiver",
  );
  const [caregiverLang, setCaregiverLang] = useState<CaregiverLang>("my");
  const [employerLang, setEmployerLang] = useState<EmployerLang>("en");
  const [translatedText, setTranslatedText] = useState("");
  const [error, setError] = useState("");

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const audioContextRef = useRef<AudioContext | null>(null);

  useEffect(() => {
    return () => {
      if (
        mediaRecorderRef.current &&
        mediaRecorderRef.current.state === "recording"
      ) {
        mediaRecorderRef.current.stop();
      }
      if (audioContextRef.current) {
        audioContextRef.current.close();
      }
    };
  }, []);

  const startRecording = async () => {
    try {
      setError("");
      setTranslatedText("");
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          audioChunksRef.current.push(e.data);
        }
      };

      mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(audioChunksRef.current, {
          type: "audio/webm",
        });
        await handleTranslation(audioBlob);
        stream.getTracks().forEach((track) => track.stop());
      };

      mediaRecorder.start();
      setIsRecording(true);
    } catch (err) {
      console.error("Error accessing microphone:", err);
      setError("Microphone access denied or unavailable.");
    }
  };

  const stopRecording = () => {
    if (
      mediaRecorderRef.current &&
      mediaRecorderRef.current.state === "recording"
    ) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
    }
  };

  const handleTranslation = async (audioBlob: Blob) => {
    setIsTranslating(true);
    try {
      const reader = new FileReader();
      reader.readAsDataURL(audioBlob);
      reader.onloadend = async () => {
        const base64data = reader.result as string;
        const base64Audio = base64data.split(",")[1];

        const sourceLang = speakerRole === "caregiver" ? caregiverLang : employerLang;
        const targetLang = speakerRole === "caregiver" ? employerLang : caregiverLang;

        const result = await translateAudio(
          base64Audio,
          audioBlob.type,
          sourceLang,
          targetLang,
        );
        setTranslatedText(result.text);

        if (result.audioBase64) {
          playAudio(result.audioBase64);
        }
        setIsTranslating(false);
      };
    } catch (err) {
      console.error("Translation failed:", err);
      setError("Failed to translate audio.");
      setIsTranslating(false);
    }
  };

  const playAudio = async (base64Audio: string) => {
    try {
      if (!audioContextRef.current) {
        audioContextRef.current = new (
          window.AudioContext || (window as any).webkitAudioContext
        )({ sampleRate: 24000 });
      }
      const ctx = audioContextRef.current;

      const binaryString = window.atob(base64Audio);
      const len = binaryString.length;
      const bytes = new Uint8Array(len);
      for (let i = 0; i < len; i++) {
        bytes[i] = binaryString.charCodeAt(i);
      }

      const numChannels = 1;
      const sampleRate = 24000;
      const numSamples = bytes.length / 2;

      const audioBuffer = ctx.createBuffer(numChannels, numSamples, sampleRate);
      const channelData = audioBuffer.getChannelData(0);

      const dataView = new DataView(bytes.buffer);
      for (let i = 0; i < numSamples; i++) {
        const intSample = dataView.getInt16(i * 2, true);
        channelData[i] = intSample / 32768.0;
      }

      const source = ctx.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(ctx.destination);
      source.start(0);
    } catch (err) {
      console.error("Failed to play audio:", err);
    }
  };

  return (
    <div className="p-4 max-w-md mx-auto flex flex-col items-center h-full min-h-[80vh]">
      {!hideHeader && (
        <div className="flex flex-col w-full mb-8 gap-4">
          <h2 className="text-3xl font-bold tracking-tight text-slate-800">{t("translate")}</h2>
        </div>
      )}
      <div className="flex flex-col w-full mb-8 gap-4">
        <div className="flex gap-3 w-full">
          <div className="relative flex-1">
            <select
              value={caregiverLang}
              onChange={(e) => setCaregiverLang(e.target.value as CaregiverLang)}
              className="w-full appearance-none bg-indigo-50/80 backdrop-blur-sm text-indigo-700 font-semibold py-2.5 pl-4 pr-10 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500 border border-indigo-100/50 transition-all"
            >
              <option value="my">မြန်မာ (MM)</option>
              <option value="th">ไทย (TH)</option>
              <option value="en">English</option>
            </select>
            <ChevronDown className="w-4 h-4 text-indigo-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <span className="absolute -top-2.5 left-3 bg-white/90 backdrop-blur-md px-1 text-[10px] font-bold text-indigo-500 uppercase tracking-wider rounded">Caregiver</span>
          </div>
          
          <div className="relative flex-1">
            <select
              value={employerLang}
              onChange={(e) => setEmployerLang(e.target.value as EmployerLang)}
              className="w-full appearance-none bg-purple-50/80 backdrop-blur-sm text-purple-700 font-semibold py-2.5 pl-4 pr-10 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 border border-purple-100/50 transition-all"
            >
              <option value="en">English</option>
              <option value="ar">العربية (AR)</option>
              <option value="zh">中文 (ZH)</option>
              <option value="ms">Melayu (MS)</option>
            </select>
            <ChevronDown className="w-4 h-4 text-purple-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <span className="absolute -top-2.5 left-3 bg-white/90 backdrop-blur-md px-1 text-[10px] font-bold text-purple-500 uppercase tracking-wider rounded">Employer</span>
          </div>
        </div>
      </div>

      {/* Role Switcher */}
      <div className="bg-white p-2 rounded-2xl shadow-sm border border-slate-100 flex w-full mb-8 relative">
        <div
          className={cn(
            "absolute inset-y-2 w-[calc(50%-8px)] bg-indigo-100 rounded-xl transition-all duration-300 ease-in-out",
            speakerRole === "caregiver" ? "left-2" : "left-[calc(50%+4px)]",
          )}
        />
        <button
          onClick={() => setSpeakerRole("caregiver")}
          className={cn(
            "flex-1 py-3 text-sm font-medium rounded-xl z-10 transition-colors",
            speakerRole === "caregiver"
              ? "text-indigo-700"
              : "text-slate-500 hover:text-slate-700",
          )}
        >
          {t("caregiver")}
        </button>
        <button
          onClick={() => setSpeakerRole("employer")}
          className={cn(
            "flex-1 py-3 text-sm font-medium rounded-xl z-10 transition-colors",
            speakerRole === "employer"
              ? "text-indigo-700"
              : "text-slate-500 hover:text-slate-700",
          )}
        >
          {t("employer")}
        </button>
      </div>

      {/* Translation Result Area */}
      <div className="flex-1 w-full flex flex-col items-center justify-center mb-8">
        {isTranslating ? (
          <div className="flex flex-col items-center text-indigo-500 animate-pulse">
            <RefreshCw className="w-8 h-8 animate-spin mb-4" />
            <p className="font-medium">{t("translating")}</p>
          </div>
        ) : translatedText ? (
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 w-full text-center relative">
            <Volume2 className="w-6 h-6 text-indigo-400 absolute top-4 right-4" />
            <p className="text-2xl font-medium text-slate-800 leading-relaxed">
              {translatedText}
            </p>
          </div>
        ) : error ? (
          <p className="text-rose-500 text-center font-medium">{error}</p>
        ) : (
          <p className="text-slate-400 text-center text-lg">{t("speakNow")}</p>
        )}
      </div>

      {/* Record Button */}
      <div className="mb-4">
        <button
          onMouseDown={startRecording}
          onMouseUp={stopRecording}
          onMouseLeave={stopRecording}
          onTouchStart={startRecording}
          onTouchEnd={stopRecording}
          className={cn(
            "w-28 h-28 rounded-full flex items-center justify-center transition-all duration-300 shadow-lg",
            isRecording
              ? "bg-rose-500 scale-110 shadow-rose-500/30"
              : "bg-indigo-600 hover:bg-indigo-700 shadow-indigo-600/30",
          )}
        >
          {isRecording ? (
            <Square className="w-10 h-10 text-white fill-white" />
          ) : (
            <Mic className="w-12 h-12 text-white" />
          )}
        </button>
      </div>

      <p className="text-sm font-medium text-slate-500 mb-8">
        {isRecording ? t("releaseToSend") : t("holdToSpeak")}
      </p>
    </div>
  );
}
