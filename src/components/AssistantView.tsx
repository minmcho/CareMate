import React, { useState, useEffect, useRef } from 'react';
import { Mic, MicOff, Video, VideoOff, PhoneOff, Loader2, Bot, Languages, ChevronDown, MessageSquare, Save, Trash2, X, Calendar, Plus, Edit2, Check, Bell, CircleDashed, Clock, CheckCircle2 } from 'lucide-react';
import { Language, useTranslation } from '../lib/i18n';
import { GoogleGenAI, LiveServerMessage, Modality } from '@google/genai';
import { cn } from '../lib/utils';

type CaregiverLang = "my" | "th" | "en";
type EmployerLang = "en" | "zh" | "ms" | "ar";

type Caption = {
  id: string;
  role: 'user' | 'assistant';
  text: string;
  isFinished: boolean;
};

type SavedConversation = {
  id: string;
  date: string;
  captions: Caption[];
};

type Priority = 'low' | 'medium' | 'high';
type TaskStatus = 'pending' | 'in-progress' | 'completed';

type Task = {
  id: string;
  title: string;
  date: string;
  time: string;
  completed: boolean;
  reminderEnabled: boolean;
  notified?: boolean;
  priority: Priority;
  status: TaskStatus;
};

const priorityConfig = {
  low: { label: 'Low', color: 'bg-slate-100 text-slate-600', weight: 1 },
  medium: { label: 'Medium', color: 'bg-amber-100 text-amber-600', weight: 2 },
  high: { label: 'High', color: 'bg-rose-100 text-rose-600', weight: 3 }
};

const statusConfig = {
  'pending': { 
    label: 'Pending', 
    color: 'bg-slate-100 text-slate-600',
    cardStyle: 'border-slate-200 bg-white shadow-sm',
    icon: CircleDashed,
    iconColor: 'text-slate-400 hover:text-indigo-500'
  },
  'in-progress': { 
    label: 'In Progress', 
    color: 'bg-indigo-100 text-indigo-600',
    cardStyle: 'border-indigo-200 bg-indigo-50/30 shadow-sm',
    icon: Clock,
    iconColor: 'text-indigo-500 hover:text-indigo-600'
  },
  'completed': { 
    label: 'Completed', 
    color: 'bg-emerald-100 text-emerald-600',
    cardStyle: 'border-emerald-200 bg-emerald-50/30',
    icon: CheckCircle2,
    iconColor: 'text-emerald-500 hover:text-emerald-600'
  }
};

export default function AssistantView({ lang }: { lang: Language }) {
  const t = useTranslation(lang);
  const [caregiverLang, setCaregiverLang] = useState<CaregiverLang>("my");
  const [employerLang, setEmployerLang] = useState<EmployerLang>("en");
  
  const [isConnecting, setIsConnecting] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [isMicMuted, setIsMicMuted] = useState(false);
  const [isCameraOff, setIsCameraOff] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [volume, setVolume] = useState(0);
  const [captions, setCaptions] = useState<Caption[]>([]);
  const [savedConversations, setSavedConversations] = useState<SavedConversation[]>([]);
  const [showSaved, setShowSaved] = useState(false);
  const [textInput, setTextInput] = useState('');

  const [tasks, setTasks] = useState<Task[]>([]);
  const [showSchedule, setShowSchedule] = useState(false);
  const [newTask, setNewTask] = useState({ title: '', date: '', time: '', reminderEnabled: false, priority: 'medium' as Priority, status: 'pending' as TaskStatus });
  const [editingTask, setEditingTask] = useState<Task | null>(null);

  useEffect(() => {
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission();
    }
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      const now = new Date();
      const nowStr = now.toISOString().split('T')[0];
      const timeStr = now.toTimeString().slice(0, 5);

      setTasks(prevTasks => {
        let changed = false;
        const updatedTasks = prevTasks.map(task => {
          if (task.reminderEnabled && !task.notified && !task.completed && task.date === nowStr && task.time === timeStr) {
            if ("Notification" in window && Notification.permission === "granted") {
              new Notification("Caregiving Reminder", {
                body: `Time for: ${task.title}`,
                icon: "/favicon.ico"
              });
            } else {
              alert(`Reminder: ${task.title}`);
            }
            changed = true;
            return { ...task, notified: true };
          }
          return task;
        });

        if (changed) {
          localStorage.setItem('caregiving_tasks', JSON.stringify(updatedTasks));
          return updatedTasks;
        }
        return prevTasks;
      });
    }, 30000); // Check every 30 seconds

    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const saved = localStorage.getItem('saved_conversations');
    if (saved) {
      try {
        setSavedConversations(JSON.parse(saved));
      } catch (e) {}
    }
    
    const savedTasks = localStorage.getItem('caregiving_tasks');
    if (savedTasks) {
      try {
        setTasks(JSON.parse(savedTasks));
      } catch (e) {}
    }
  }, []);

  const saveTasks = (newTasks: Task[]) => {
    setTasks(newTasks);
    localStorage.setItem('caregiving_tasks', JSON.stringify(newTasks));
  };

  const addTask = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTask.title || !newTask.date || !newTask.time) return;
    
    const task: Task = {
      id: Date.now().toString(),
      ...newTask,
      completed: newTask.status === 'completed',
      notified: false
    };
    
    saveTasks([...tasks, task]);
    setNewTask({ title: '', date: '', time: '', reminderEnabled: false, priority: 'medium', status: 'pending' });
  };

  const updateTask = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingTask || !editingTask.title || !editingTask.date || !editingTask.time) return;
    
    const updatedTask = { ...editingTask, completed: editingTask.status === 'completed' };
    const updatedTasks = tasks.map(t => t.id === editingTask.id ? updatedTask : t);
    saveTasks(updatedTasks);
    setEditingTask(null);
  };

  const toggleTaskCompletion = (id: string) => {
    const updatedTasks = tasks.map(t => {
      if (t.id === id) {
        const isCompleted = t.status === 'completed';
        const newStatus: TaskStatus = isCompleted ? 'pending' : 'completed';
        return { ...t, status: newStatus, completed: !isCompleted };
      }
      return t;
    });
    saveTasks(updatedTasks);
  };

  const updateTaskStatus = (id: string, status: TaskStatus) => {
    const updatedTasks = tasks.map(t => t.id === id ? { ...t, status, completed: status === 'completed' } : t);
    saveTasks(updatedTasks);
  };

  const deleteTask = (id: string) => {
    const updatedTasks = tasks.filter(t => t.id !== id);
    saveTasks(updatedTasks);
  };

  const saveConversation = () => {
    if (captions.length === 0) return;
    const newConv: SavedConversation = {
      id: Date.now().toString(),
      date: new Date().toLocaleString(),
      captions: [...captions]
    };
    const updated = [newConv, ...savedConversations];
    setSavedConversations(updated);
    localStorage.setItem('saved_conversations', JSON.stringify(updated));
    alert('Conversation saved!');
  };

  const deleteConversation = (id: string) => {
    const updated = savedConversations.filter(c => c.id !== id);
    setSavedConversations(updated);
    localStorage.setItem('saved_conversations', JSON.stringify(updated));
  };

  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  
  const streamRef = useRef<MediaStream | null>(null);
  const audioCtxRef = useRef<AudioContext | null>(null);
  const processorRef = useRef<ScriptProcessorNode | null>(null);
  const sessionRef = useRef<any>(null);
  const animationFrameRef = useRef<number | null>(null);

  // Audio output queue
  const audioQueueRef = useRef<Float32Array[]>([]);
  const isPlayingRef = useRef(false);
  const nextPlayTimeRef = useRef(0);

  const startSession = async () => {
    setIsConnecting(true);
    setError(null);
    setCaptions([]);

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: 16000,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true,
        },
        video: {
          width: { ideal: 640 },
          height: { ideal: 480 },
          frameRate: { ideal: 15 }
        }
      });
      streamRef.current = stream;

      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }

      const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
      
      const caregiverLangName = caregiverLang === 'en' ? 'English' : caregiverLang === 'my' ? 'Myanmar/Burmese' : 'Thai';
      const employerLangName = employerLang === 'en' ? 'English' : employerLang === 'ar' ? 'Arabic' : employerLang === 'zh' ? 'Chinese' : 'Malay';

      const playAudioQueue = () => {
        if (!audioCtxRef.current || audioQueueRef.current.length === 0) {
          isPlayingRef.current = false;
          return;
        }
        isPlayingRef.current = true;
        const audioCtx = audioCtxRef.current;
        const pcmData = audioQueueRef.current.shift()!;
        
        const audioBuffer = audioCtx.createBuffer(1, pcmData.length, 24000);
        audioBuffer.getChannelData(0).set(pcmData);
        
        const sourceNode = audioCtx.createBufferSource();
        sourceNode.buffer = audioBuffer;
        sourceNode.connect(audioCtx.destination);
        
        const currentTime = audioCtx.currentTime;
        const startTime = Math.max(currentTime, nextPlayTimeRef.current);
        sourceNode.start(startTime);
        nextPlayTimeRef.current = startTime + audioBuffer.duration;

        sourceNode.onended = () => {
          playAudioQueue();
        };
      };

      const sessionPromise = ai.live.connect({
        model: "gemini-2.5-flash-native-audio-preview-09-2025",
        config: {
          responseModalities: [Modality.AUDIO],
          inputAudioTranscription: {},
          outputAudioTranscription: {},
          speechConfig: {
            voiceConfig: { prebuiltVoiceConfig: { voiceName: "Zephyr" } },
          },
          systemInstruction: `You are a real-time bilingual translator and helpful AI assistant. You are facilitating communication between a caregiver who speaks ${caregiverLangName} and an employer who speaks ${employerLangName}. 
When you hear ${caregiverLangName}, translate it to ${employerLangName} and speak it out. 
When you hear ${employerLangName}, translate it to ${caregiverLangName} and speak it out. 
You also have access to the camera to see the environment. If asked about what you see, answer in the language of the person asking. Be concise and natural.`,
        },
        callbacks: {
          onopen: () => {
            setIsConnected(true);
            setIsConnecting(false);
          },
          onmessage: async (message: LiveServerMessage) => {
            // Handle input transcription (user)
            if (message.serverContent?.inputTranscription) {
              const text = message.serverContent.inputTranscription.text;
              if (text) {
                setCaptions(prev => {
                  const last = prev[prev.length - 1];
                  if (last && last.role === 'user' && !last.isFinished) {
                    return [...prev.slice(0, -1), { ...last, text: last.text + text }];
                  }
                  return [...prev, { id: Date.now().toString(), role: 'user', text, isFinished: false }];
                });
              }
              if (message.serverContent.inputTranscription.finished) {
                setCaptions(prev => {
                  const last = prev[prev.length - 1];
                  if (last && last.role === 'user') {
                    return [...prev.slice(0, -1), { ...last, isFinished: true }];
                  }
                  return prev;
                });
              }
            }

            // Handle output transcription (assistant)
            if (message.serverContent?.outputTranscription) {
              const text = message.serverContent.outputTranscription.text;
              if (text) {
                setCaptions(prev => {
                  const last = prev[prev.length - 1];
                  if (last && last.role === 'assistant' && !last.isFinished) {
                    return [...prev.slice(0, -1), { ...last, text: last.text + text }];
                  }
                  return [...prev, { id: Date.now().toString(), role: 'assistant', text, isFinished: false }];
                });
              }
              if (message.serverContent.outputTranscription.finished) {
                setCaptions(prev => {
                  const last = prev[prev.length - 1];
                  if (last && last.role === 'assistant') {
                    return [...prev.slice(0, -1), { ...last, isFinished: true }];
                  }
                  return prev;
                });
              }
            }

            // Handle audio output
            const base64Audio = message.serverContent?.modelTurn?.parts[0]?.inlineData?.data;
            if (base64Audio) {
              const binaryString = atob(base64Audio);
              const bytes = new Uint8Array(binaryString.length);
              for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
              }
              const pcm16 = new Int16Array(bytes.buffer);
              const float32 = new Float32Array(pcm16.length);
              for (let i = 0; i < pcm16.length; i++) {
                float32[i] = pcm16[i] / 32768;
              }
              audioQueueRef.current.push(float32);
              if (!isPlayingRef.current) {
                playAudioQueue();
              }
            }

            // Handle interruption
            if (message.serverContent?.interrupted) {
              audioQueueRef.current = [];
              nextPlayTimeRef.current = audioCtxRef.current?.currentTime || 0;
            }
          },
          onclose: () => {
            stopSession();
          },
          onerror: (err: any) => {
            console.error("Live API Error:", err);
            setError("Connection error occurred.");
            stopSession();
          }
        }
      });

      sessionRef.current = sessionPromise;

      // Setup Audio Input
      const audioCtx = new AudioContext({ sampleRate: 16000 });
      audioCtxRef.current = audioCtx;
      const source = audioCtx.createMediaStreamSource(stream);
      const processor = audioCtx.createScriptProcessor(4096, 1, 1);
      processorRef.current = processor;

      source.connect(processor);
      processor.connect(audioCtx.destination);

      processor.onaudioprocess = (e) => {
        if (isMicMuted) {
          setVolume(0);
          return;
        }
        const channelData = e.inputBuffer.getChannelData(0);
        const pcm16 = new Int16Array(channelData.length);
        let sum = 0;
        for (let i = 0; i < channelData.length; i++) {
          sum += channelData[i] * channelData[i];
          pcm16[i] = Math.max(-32768, Math.min(32767, channelData[i] * 32768));
        }
        const rms = Math.sqrt(sum / channelData.length);
        setVolume(rms);

        const base64 = btoa(String.fromCharCode(...new Uint8Array(pcm16.buffer)));
        sessionPromise.then((session) => {
          session.sendRealtimeInput({ media: { mimeType: 'audio/pcm;rate=16000', data: base64 } });
        });
      };

      // Setup Video Input
      const sendVideoFrame = () => {
        if (!isCameraOff && videoRef.current && canvasRef.current) {
          const video = videoRef.current;
          const canvas = canvasRef.current;
          if (video.readyState >= 2) {
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            const ctx = canvas.getContext('2d');
            if (ctx) {
              ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
              const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
              const base64 = dataUrl.split(',')[1];
              sessionPromise.then((session) => {
                session.sendRealtimeInput({ media: { mimeType: 'image/jpeg', data: base64 } });
              });
            }
          }
        }
        animationFrameRef.current = setTimeout(sendVideoFrame, 1000); // 1 fps
      };
      sendVideoFrame();

      // Handle Session Events
      const session = await sessionPromise;
      setIsConnected(true);
      setIsConnecting(false);

    } catch (err) {
      console.error("Failed to start session:", err);
      setError("Failed to access camera/microphone or connect to AI.");
      setIsConnecting(false);
      stopSession();
    }
  };

  const stopSession = () => {
    if (animationFrameRef.current) {
      clearTimeout(animationFrameRef.current);
      animationFrameRef.current = null;
    }
    if (processorRef.current) {
      processorRef.current.disconnect();
      processorRef.current = null;
    }
    if (audioCtxRef.current) {
      audioCtxRef.current.close();
      audioCtxRef.current = null;
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    if (sessionRef.current) {
      sessionRef.current.then((session: any) => session.close()).catch(() => {});
      sessionRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setIsConnected(false);
    setIsConnecting(false);
    audioQueueRef.current = [];
    isPlayingRef.current = false;
    nextPlayTimeRef.current = 0;
  };

  useEffect(() => {
    return () => {
      stopSession();
    };
  }, []);

  const toggleMic = () => {
    const newMuteState = !isMicMuted;
    setIsMicMuted(newMuteState);
    if (streamRef.current) {
      streamRef.current.getAudioTracks().forEach(track => {
        track.enabled = !newMuteState;
      });
    }
  };

  const toggleCamera = () => {
    const newCameraState = !isCameraOff;
    setIsCameraOff(newCameraState);
    if (streamRef.current) {
      streamRef.current.getVideoTracks().forEach(track => {
        track.enabled = !newCameraState;
      });
    }
  };

  const [isListening, setIsListening] = useState(false);
  const recognitionRef = useRef<any>(null);

  const handleSendText = async (e?: React.FormEvent, messageOverride?: string) => {
    if (e) e.preventDefault();
    const message = messageOverride || textInput;
    if (!message.trim()) return;

    if (!messageOverride) setTextInput('');

    // Add to captions immediately
    setCaptions(prev => [...prev, { id: Date.now().toString(), role: 'user', text: message, isFinished: true }]);

    // If not connected, start session first
    if (!isConnected) {
      await startSession();
    }

    // Send to AI
    if (sessionRef.current) {
      sessionRef.current.then((session: any) => {
        session.send({
          clientContent: {
            turns: [{ role: 'user', parts: [{ text: message }] }],
            turnComplete: true
          }
        });
      });
    }
  };

  const handleVoiceInput = () => {
    if (isListening) {
      recognitionRef.current?.stop();
      setIsListening(false);
      return;
    }

    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SpeechRecognition) {
      alert("Speech recognition is not supported in this browser. Please use Chrome or Edge.");
      return;
    }

    const recognition = new SpeechRecognition();
    // Default to caregiver language for voice input
    recognition.lang = caregiverLang === 'my' ? 'my-MM' : caregiverLang === 'th' ? 'th-TH' : 'en-US';
    recognition.continuous = false;
    recognition.interimResults = true;

    recognition.onresult = (event: any) => {
      let finalTranscript = '';
      let interimTranscript = '';
      for (let i = event.resultIndex; i < event.results.length; ++i) {
        if (event.results[i].isFinal) {
          finalTranscript += event.results[i][0].transcript;
        } else {
          interimTranscript += event.results[i][0].transcript;
        }
      }
      if (finalTranscript) {
        setTextInput(prev => prev ? prev + ' ' + finalTranscript : finalTranscript);
        // Optionally auto-send when speech ends
        handleSendText(undefined, finalTranscript);
      } else if (interimTranscript) {
        setTextInput(interimTranscript);
      }
    };

    recognition.onerror = (event: any) => {
      console.error("Speech recognition error", event.error);
      setIsListening(false);
    };

    recognition.onend = () => {
      setIsListening(false);
    };

    recognition.start();
    setIsListening(true);
    recognitionRef.current = recognition;
  };

  return (
    <div className="p-4 max-w-md mx-auto h-full flex flex-col gap-4">
      <div className="flex flex-col shrink-0">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h2 className="text-3xl font-bold tracking-tight text-slate-800">{t('assistant')}</h2>
            <p className="text-slate-500 text-sm mt-1">Real-time Translator & AI Assistant</p>
          </div>
        <div className="flex gap-2">
          <button 
            onClick={() => setShowSchedule(true)}
            className="p-2 bg-slate-100 text-slate-600 rounded-full hover:bg-slate-200 transition-colors"
            title="Schedule"
          >
            <Calendar className="w-5 h-5" />
          </button>
          <button 
            onClick={() => setShowSaved(true)}
            className="p-2 bg-slate-100 text-slate-600 rounded-full hover:bg-slate-200 transition-colors"
            title="Saved Conversations"
          >
            <MessageSquare className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Language Selectors */}
      <div className="flex gap-3 w-full mb-6 shrink-0">
        <div className="relative flex-1">
          <select
            value={caregiverLang}
            onChange={(e) => setCaregiverLang(e.target.value as CaregiverLang)}
            disabled={isConnected || isConnecting}
            className="w-full appearance-none bg-indigo-50/80 backdrop-blur-sm text-indigo-700 font-semibold py-2.5 pl-4 pr-10 rounded-xl outline-none focus:ring-2 focus:ring-indigo-500 border border-indigo-100/50 transition-all disabled:opacity-50"
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
            disabled={isConnected || isConnecting}
            className="w-full appearance-none bg-purple-50/80 backdrop-blur-sm text-purple-700 font-semibold py-2.5 pl-4 pr-10 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 border border-purple-100/50 transition-all disabled:opacity-50"
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

      <div className="flex-1 flex flex-col items-center justify-center relative bg-slate-900 rounded-3xl overflow-hidden shadow-xl border-4 border-slate-800">
        <video 
          ref={videoRef} 
          autoPlay 
          playsInline 
          muted 
          className={`w-full h-full object-cover ${isCameraOff ? 'opacity-0' : 'opacity-100'} transition-opacity`}
        />
          <canvas ref={canvasRef} className="hidden" />

          {!isConnected && !isConnecting && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-slate-900/80 backdrop-blur-sm p-6 text-center">
              <div className="w-20 h-20 bg-indigo-500/20 rounded-full flex items-center justify-center mb-4">
                <Video className="w-10 h-10 text-indigo-400" />
              </div>
              <h3 className="text-white font-bold text-xl mb-2">AI Assistant</h3>
              <p className="text-slate-300 text-sm mb-6">Start a live session to talk with the AI. It can see what you show it and hear what you say.</p>
              <button 
                onClick={startSession}
                className="bg-indigo-600 hover:bg-indigo-500 text-white px-8 py-3 rounded-full font-bold shadow-lg shadow-indigo-500/30 transition-all active:scale-95"
              >
                Start Session
              </button>
              {error && <p className="text-rose-400 text-sm mt-4">{error}</p>}
            </div>
          )}

          {isConnecting && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-slate-900/80 backdrop-blur-sm">
              <Loader2 className="w-10 h-10 text-indigo-400 animate-spin mb-4" />
              <p className="text-white font-medium animate-pulse">Connecting to AI...</p>
            </div>
          )}

        {/* Captions Overlay - Always available if there are captions */}
        <div className="absolute top-4 left-4 right-4 bottom-24 overflow-y-auto flex flex-col gap-2 pointer-events-none" style={{ scrollBehavior: 'smooth' }}>
          <div className="mt-auto flex flex-col gap-2">
            {captions.map((caption, i) => (
              <div key={i} className={`max-w-[85%] p-3 rounded-2xl backdrop-blur-md ${caption.role === 'user' ? 'bg-indigo-500/80 text-white self-end rounded-tr-sm' : 'bg-slate-800/80 text-white self-start rounded-tl-sm'}`}>
                <p className="text-sm leading-relaxed">{caption.text}</p>
              </div>
            ))}
          </div>
        </div>

        {isConnected && (
            <>
              {/* Visualizer Orb */}
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none flex flex-col items-center justify-center">
                <div 
                  className="w-32 h-32 rounded-full bg-indigo-500/30 blur-xl transition-all duration-75"
                  style={{ transform: `scale(${1 + volume * 10})`, opacity: 0.5 + volume * 2 }}
                />
                <div 
                  className="absolute w-24 h-24 rounded-full bg-indigo-400/50 blur-md transition-all duration-75"
                  style={{ transform: `scale(${1 + volume * 5})` }}
                />
                <div className="absolute text-white/80 font-medium text-sm mt-40 bg-black/40 px-4 py-1.5 rounded-full backdrop-blur-md">
                  {isPlayingRef.current ? 'Assistant is speaking...' : 'Listening...'}
                </div>
              </div>

              <div className="absolute bottom-6 left-0 right-0 flex justify-center gap-4 px-4">
              <button 
                onClick={saveConversation}
                className="p-4 rounded-full shadow-lg bg-emerald-500/80 backdrop-blur-md text-white hover:bg-emerald-500 transition-all active:scale-95 pointer-events-auto"
                title="Save Conversation"
              >
                <Save className="w-6 h-6" />
              </button>
              <button 
                onClick={toggleMic}
                className={`p-4 rounded-full shadow-lg transition-all active:scale-95 pointer-events-auto ${isMicMuted ? 'bg-rose-500 text-white' : 'bg-slate-700/80 backdrop-blur-md text-white hover:bg-slate-600'}`}
              >
                {isMicMuted ? <MicOff className="w-6 h-6" /> : <Mic className="w-6 h-6" />}
              </button>
              <button 
                onClick={stopSession}
                className="p-4 rounded-full shadow-lg bg-rose-600 text-white hover:bg-rose-500 transition-all active:scale-95"
              >
                <PhoneOff className="w-6 h-6" />
              </button>
              <button 
                onClick={toggleCamera}
                className={`p-4 rounded-full shadow-lg transition-all active:scale-95 ${isCameraOff ? 'bg-rose-500 text-white' : 'bg-slate-700/80 backdrop-blur-md text-white hover:bg-slate-600'}`}
              >
                {isCameraOff ? <VideoOff className="w-6 h-6" /> : <Video className="w-6 h-6" />}
              </button>
            </div>
          </>
        )}
      </div>

      {/* Separate Chat Panel */}
      <div className="bg-white border border-slate-200 rounded-3xl p-3 shadow-sm shrink-0">
        <form onSubmit={handleSendText} className="flex gap-2">
          <button
            type="button"
            onClick={handleVoiceInput}
            className={cn(
              "p-3 rounded-2xl transition-all flex items-center justify-center",
              isListening 
                ? "bg-rose-500 text-white animate-pulse" 
                : "bg-slate-100 text-slate-500 hover:text-slate-700 hover:bg-slate-200"
            )}
            title={isListening ? "Stop Voice Input" : "Voice Message"}
          >
            <Mic className="w-6 h-6" />
          </button>
          <input
            type="text"
            value={textInput}
            onChange={(e) => setTextInput(e.target.value)}
            placeholder="Type a message..."
            className="flex-1 bg-slate-50 text-slate-800 px-4 py-3 rounded-2xl outline-none focus:ring-2 focus:ring-indigo-500 border border-slate-100"
          />
          <button
            type="submit"
            disabled={!textInput.trim()}
            className="bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 disabled:hover:bg-indigo-600 text-white px-5 py-3 rounded-2xl font-bold transition-all shadow-md shadow-indigo-500/20"
          >
            Send
          </button>
        </form>
      </div>

      {/* Saved Conversations Modal */}
      {showSaved && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl shadow-xl w-full max-w-md max-h-[80vh] flex flex-col overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <h3 className="font-bold text-lg text-slate-800">Saved Conversations</h3>
              <button onClick={() => setShowSaved(false)} className="p-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-slate-200 transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-4">
              {savedConversations.length === 0 ? (
                <p className="text-center text-slate-500 py-8">No saved conversations yet.</p>
              ) : (
                savedConversations.map((conv) => (
                  <div key={conv.id} className="bg-slate-50 border border-slate-100 rounded-2xl p-4">
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-xs font-medium text-slate-400">{conv.date}</span>
                      <button onClick={() => deleteConversation(conv.id)} className="text-rose-400 hover:text-rose-600 p-1">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                    <div className="flex flex-col gap-2 max-h-48 overflow-y-auto pr-2">
                      {conv.captions.map((cap, i) => (
                        <div key={i} className={`text-sm p-2 rounded-xl ${cap.role === 'user' ? 'bg-indigo-100 text-indigo-900 self-end rounded-tr-sm' : 'bg-white border border-slate-200 text-slate-700 self-start rounded-tl-sm'}`}>
                          {cap.text}
                        </div>
                      ))}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* Schedule Modal */}
      {showSchedule && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl shadow-xl w-full max-w-md max-h-[80vh] flex flex-col overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <h3 className="font-bold text-lg text-slate-800">Caregiving Schedule</h3>
              <button onClick={() => setShowSchedule(false)} className="p-2 text-slate-400 hover:text-slate-600 rounded-full hover:bg-slate-200 transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="p-4 border-b border-slate-100 bg-white">
              <form onSubmit={editingTask ? updateTask : addTask} className="flex flex-col gap-3">
                <input
                  type="text"
                  placeholder="Task description..."
                  value={editingTask ? editingTask.title : newTask.title}
                  onChange={(e) => editingTask ? setEditingTask({...editingTask, title: e.target.value}) : setNewTask({...newTask, title: e.target.value})}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
                <div className="flex gap-3">
                  <input
                    type="date"
                    value={editingTask ? editingTask.date : newTask.date}
                    onChange={(e) => editingTask ? setEditingTask({...editingTask, date: e.target.value}) : setNewTask({...newTask, date: e.target.value})}
                    className="flex-1 bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500"
                    required
                  />
                  <input
                    type="time"
                    value={editingTask ? editingTask.time : newTask.time}
                    onChange={(e) => editingTask ? setEditingTask({...editingTask, time: e.target.value}) : setNewTask({...newTask, time: e.target.value})}
                    className="flex-1 bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 outline-none focus:ring-2 focus:ring-indigo-500"
                    required
                  />
                </div>
                <div className="flex items-center justify-between gap-4 px-1">
                  <div className="flex-1 flex flex-col gap-2">
                    <div className="flex gap-2">
                      {(['low', 'medium', 'high'] as Priority[]).map((p) => (
                        <button
                          key={p}
                          type="button"
                          onClick={() => editingTask ? setEditingTask({...editingTask, priority: p}) : setNewTask({...newTask, priority: p})}
                          className={cn(
                            "flex-1 py-1.5 px-2 rounded-lg text-xs font-bold transition-all border",
                            (editingTask ? editingTask.priority === p : newTask.priority === p)
                              ? priorityConfig[p].color + " border-transparent ring-2 ring-offset-1 ring-indigo-500/20"
                              : "bg-white border-slate-200 text-slate-400 hover:bg-slate-50"
                          )}
                        >
                          {priorityConfig[p].label}
                        </button>
                      ))}
                    </div>
                    <div className="flex gap-2">
                      {(['pending', 'in-progress', 'completed'] as TaskStatus[]).map((s) => (
                        <button
                          key={s}
                          type="button"
                          onClick={() => editingTask ? setEditingTask({...editingTask, status: s}) : setNewTask({...newTask, status: s})}
                          className={cn(
                            "flex-1 py-1.5 px-2 rounded-lg text-[10px] font-bold uppercase tracking-wider transition-all border",
                            (editingTask ? editingTask.status === s : newTask.status === s)
                              ? statusConfig[s].color + " border-transparent ring-2 ring-offset-1 ring-indigo-500/20"
                              : "bg-white border-slate-200 text-slate-400 hover:bg-slate-50"
                          )}
                        >
                          {statusConfig[s].label}
                        </button>
                      ))}
                    </div>
                  </div>
                  <label className="flex items-center gap-2 cursor-pointer group shrink-0">
                    <div className="relative">
                      <input
                        type="checkbox"
                        checked={editingTask ? editingTask.reminderEnabled : newTask.reminderEnabled}
                        onChange={(e) => editingTask ? setEditingTask({...editingTask, reminderEnabled: e.target.checked, notified: false}) : setNewTask({...newTask, reminderEnabled: e.target.checked})}
                        className="sr-only peer"
                      />
                      <div className="w-10 h-5 bg-slate-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-indigo-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-indigo-600"></div>
                    </div>
                    <span className="text-sm font-medium text-slate-600 group-hover:text-slate-800 transition-colors flex items-center gap-1.5">
                      <Bell className={cn("w-4 h-4", (editingTask ? editingTask.reminderEnabled : newTask.reminderEnabled) ? "text-indigo-500" : "text-slate-400")} />
                      Set Reminder
                    </span>
                  </label>
                </div>
                <div className="flex gap-2">
                  <button
                    type="submit"
                    className="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2.5 rounded-xl transition-colors flex items-center justify-center gap-2"
                  >
                    {editingTask ? <><Check className="w-4 h-4" /> Update Task</> : <><Plus className="w-4 h-4" /> Add Task</>}
                  </button>
                  {editingTask && (
                    <button
                      type="button"
                      onClick={() => setEditingTask(null)}
                      className="bg-slate-200 hover:bg-slate-300 text-slate-700 font-medium py-2.5 px-4 rounded-xl transition-colors"
                    >
                      Cancel
                    </button>
                  )}
                </div>
              </form>
            </div>

            <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-3 bg-slate-50/50">
              {tasks.length === 0 ? (
                <p className="text-center text-slate-500 py-8">No tasks scheduled yet.</p>
              ) : (
                tasks.sort((a, b) => {
                  // Sort by priority weight first
                  const weightA = priorityConfig[a.priority]?.weight || 0;
                  const weightB = priorityConfig[b.priority]?.weight || 0;
                  if (weightA !== weightB) return weightB - weightA;
                  
                  // Then by date and time
                  return new Date(`${a.date}T${a.time}`).getTime() - new Date(`${b.date}T${b.time}`).getTime();
                }).map((task) => {
                  const StatusIcon = statusConfig[task.status].icon;
                  return (
                  <div key={task.id} className={cn("border rounded-2xl p-4 transition-all", statusConfig[task.status].cardStyle)}>
                    <div className="flex items-start justify-between gap-3">
                      <button 
                        onClick={() => toggleTaskCompletion(task.id)}
                        className={cn("mt-0.5 shrink-0 transition-colors", statusConfig[task.status].iconColor)}
                      >
                        <StatusIcon className="w-5 h-5" />
                      </button>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-0.5">
                          <p className={`font-medium truncate ${task.status === 'completed' ? 'text-slate-400 line-through' : 'text-slate-700'}`}>
                            {task.title}
                          </p>
                          <span className={cn("px-1.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider shrink-0", priorityConfig[task.priority].color)}>
                            {priorityConfig[task.priority].label}
                          </span>
                          <button 
                            onClick={() => {
                              const nextStatus: TaskStatus = task.status === 'pending' ? 'in-progress' : task.status === 'in-progress' ? 'completed' : 'pending';
                              updateTaskStatus(task.id, nextStatus);
                            }}
                            className={cn("px-1.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider shrink-0 transition-all hover:scale-105 flex items-center gap-1", statusConfig[task.status].color)}
                          >
                            <StatusIcon className="w-3 h-3" />
                            {statusConfig[task.status].label}
                          </button>
                        </div>
                        <div className="flex items-center gap-2 mt-1 text-xs text-slate-500 font-medium">
                          <span className="bg-slate-100 px-2 py-0.5 rounded-md">{task.date}</span>
                          <span className="bg-slate-100 px-2 py-0.5 rounded-md">{task.time}</span>
                          {task.reminderEnabled && (
                            <span className={cn("flex items-center gap-1 px-2 py-0.5 rounded-md", task.notified ? "bg-slate-100 text-slate-400" : "bg-indigo-50 text-indigo-600")}>
                              <Bell className="w-3 h-3" />
                              {task.notified ? 'Notified' : 'Reminder Set'}
                            </span>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-1 shrink-0">
                        <button 
                          onClick={() => setEditingTask(task)}
                          className="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => deleteTask(task.id)}
                          className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                  );
                })
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
