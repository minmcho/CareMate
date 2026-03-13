import { useState, useEffect } from "react";
import { Plus, Check, Clock, Edit2, Trash2, Bell, BellRing, PlayCircle, Circle } from "lucide-react";
import { Language, useTranslation } from "../lib/i18n";
import { cn } from "../lib/utils";

interface Task {
  id: string;
  titleEn: string;
  titleMy: string;
  time: string;
  status: 'pending' | 'in-progress' | 'completed';
}

function parseTime(timeStr: string): Date {
  const now = new Date();
  let hours = 0;
  let minutes = 0;
  
  if (timeStr.includes('AM') || timeStr.includes('PM')) {
    const [time, modifier] = timeStr.split(' ');
    let [h, m] = time.split(':');
    hours = parseInt(h, 10);
    minutes = parseInt(m, 10);
    if (hours === 12) {
      hours = modifier === 'AM' ? 0 : 12;
    } else if (modifier === 'PM') {
      hours += 12;
    }
  } else {
    const [h, m] = timeStr.split(':');
    hours = parseInt(h, 10);
    minutes = parseInt(m, 10);
  }
  
  const target = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hours, minutes, 0);
  return target;
}

function TimeLeftIndicator({ timeStr, t }: { timeStr: string, t: any }) {
  const [timeLeft, setTimeLeft] = useState("");
  const [isOverdue, setIsOverdue] = useState(false);

  useEffect(() => {
    const calculateTimeLeft = () => {
      const target = parseTime(timeStr);
      const now = new Date();
      const diffMs = target.getTime() - now.getTime();
      
      if (diffMs < 0) {
        setIsOverdue(true);
        setTimeLeft(t('overdue'));
        return;
      }
      
      setIsOverdue(false);
      const diffMins = Math.floor(diffMs / 60000);
      const hours = Math.floor(diffMins / 60);
      const mins = diffMins % 60;
      
      if (hours > 0) {
        setTimeLeft(`${hours} ${t('hr')} ${mins} ${t('min')} ${t('left')}`);
      } else {
        setTimeLeft(`${mins} ${t('min')} ${t('left')}`);
      }
    };

    calculateTimeLeft();
    const interval = setInterval(calculateTimeLeft, 60000);
    return () => clearInterval(interval);
  }, [timeStr, t]);

  return (
    <div className={cn(
      "flex items-center gap-1.5 text-xs font-bold px-2.5 py-1 rounded-lg tracking-wide",
      isOverdue ? "bg-rose-50 text-rose-600" : "bg-indigo-50 text-indigo-600"
    )}>
      <Clock className="w-3.5 h-3.5" />
      {timeLeft}
    </div>
  );
}

const initialTasks: Task[] = [
  {
    id: "1",
    titleEn: "Help with morning shower",
    titleMy: "မနက်ရေချိုးပေးရန်",
    time: "08:00 AM",
    status: "completed",
  },
  {
    id: "2",
    titleEn: "Prepare breakfast",
    titleMy: "နံနက်စာပြင်ဆင်ရန်",
    time: "09:00 AM",
    status: "in-progress",
  },
  {
    id: "3",
    titleEn: "Accompany to park",
    titleMy: "ပန်းခြံသို့လိုက်ပို့ရန်",
    time: "04:00 PM",
    status: "pending",
  },
];

export default function ScheduleView({ lang }: { lang: Language }) {
  const t = useTranslation(lang);
  const [tasks, setTasks] = useState<Task[]>(initialTasks);
  const [isAdding, setIsAdding] = useState(false);
  const [editingTaskId, setEditingTaskId] = useState<string | null>(null);
  const [newTaskTitle, setNewTaskTitle] = useState("");
  const [newTaskTime, setNewTaskTime] = useState("");
  const [toast, setToast] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const cycleStatus = (id: string) => {
    setTasks(
      tasks.map((t) => {
        if (t.id === id) {
          const nextStatus = t.status === 'pending' ? 'in-progress' : t.status === 'in-progress' ? 'completed' : 'pending';
          return { ...t, status: nextStatus };
        }
        return t;
      }),
    );
  };

  const saveTask = () => {
    if (!newTaskTitle || !newTaskTime) return;
    
    if (editingTaskId) {
      setTasks(tasks.map(t => t.id === editingTaskId ? { ...t, titleEn: newTaskTitle, titleMy: newTaskTitle, time: newTaskTime } : t));
    } else {
      const newTask: Task = {
        id: Date.now().toString(),
        titleEn: newTaskTitle,
        titleMy: newTaskTitle, // In a real app, we would translate this via API
        time: newTaskTime,
        status: 'pending',
      };
      setTasks([...tasks, newTask].sort((a, b) => a.time.localeCompare(b.time)));
    }
    
    setIsAdding(false);
    setEditingTaskId(null);
    setNewTaskTitle("");
    setNewTaskTime("");
  };

  const editTask = (task: Task) => {
    setEditingTaskId(task.id);
    setNewTaskTitle(task.titleEn);
    setNewTaskTime(task.time);
    setIsAdding(true);
  };

  const deleteTask = (id: string) => {
    setTasks(tasks.filter(t => t.id !== id));
  };

  const cancelEdit = () => {
    setIsAdding(false);
    setEditingTaskId(null);
    setNewTaskTitle("");
    setNewTaskTime("");
  };

  return (
    <div className="p-4 max-w-md mx-auto relative">
      {toast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 bg-slate-800/90 backdrop-blur-md text-white px-5 py-3 rounded-full shadow-xl z-50 flex items-center gap-3 animate-in fade-in slide-in-from-top-4">
          <Check className="w-5 h-5 text-emerald-400" />
          <span className="text-sm font-semibold">{toast}</span>
        </div>
      )}

      <div className="flex items-center justify-between mb-6">
        <h2 className="text-3xl font-bold tracking-tight text-slate-800">{t("schedule")}</h2>
        <button
          onClick={() => {
            setEditingTaskId(null);
            setNewTaskTitle("");
            setNewTaskTime("");
            setIsAdding(true);
          }}
          className="p-2.5 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-full shadow-lg shadow-indigo-200 hover:shadow-xl hover:scale-105 transition-all active:scale-95"
        >
          <Plus className="w-6 h-6" />
        </button>
      </div>

      <div className="flex gap-3 mb-6">
        <button onClick={() => showToast(t('notificationSent'))} className="flex-1 bg-white/60 backdrop-blur-md border border-white shadow-sm py-2.5 rounded-xl flex items-center justify-center gap-2 text-sm font-semibold text-indigo-700 hover:bg-white transition-all active:scale-95">
          <Bell className="w-4 h-4" />
          {t('notifyFamily')}
        </button>
        <button onClick={() => showToast(t('notificationSent'))} className="flex-1 bg-white/60 backdrop-blur-md border border-white shadow-sm py-2.5 rounded-xl flex items-center justify-center gap-2 text-sm font-semibold text-purple-700 hover:bg-white transition-all active:scale-95">
          <BellRing className="w-4 h-4" />
          {t('remindCaregiver')}
        </button>
      </div>

      {isAdding && (
        <div className="bg-white/80 backdrop-blur-xl p-5 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white mb-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              {t("taskName")}
            </label>
            <input
              type="text"
              value={newTaskTitle}
              onChange={(e) => setNewTaskTitle(e.target.value)}
              className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
              placeholder="e.g. Prepare lunch"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              {t("time")}
            </label>
            <input
              type="time"
              value={newTaskTime}
              onChange={(e) => setNewTaskTime(e.target.value)}
              className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
            />
          </div>
          <div className="flex gap-2 pt-2">
            <button
              onClick={saveTask}
              className="flex-1 bg-gradient-to-r from-indigo-500 to-purple-500 text-white py-3 rounded-xl font-semibold shadow-md shadow-indigo-200 hover:shadow-lg transition-all active:scale-95"
            >
              {t("save")}
            </button>
            <button
              onClick={cancelEdit}
              className="flex-1 bg-slate-100/80 text-slate-700 py-3 rounded-xl font-semibold hover:bg-slate-200 transition-all active:scale-95"
            >
              {t("cancel")}
            </button>
          </div>
        </div>
      )}

      <div className="space-y-3">
        {tasks.length === 0 ? (
          <p className="text-center text-slate-500 py-8">{t("noTasks")}</p>
        ) : (
          tasks.map((task) => (
            <div
              key={task.id}
              className={cn(
                "flex items-start gap-4 p-5 rounded-3xl border transition-all duration-300",
                task.status === 'completed'
                  ? "bg-white/40 border-white/20 opacity-75"
                  : "bg-white/80 backdrop-blur-xl border-white shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)]",
              )}
            >
              <button
                onClick={() => cycleStatus(task.id)}
                className={cn(
                  "mt-1 w-8 h-8 rounded-full border-2 flex items-center justify-center shrink-0 transition-all duration-300 hover:scale-110 active:scale-95",
                  task.status === 'completed'
                    ? "bg-gradient-to-br from-emerald-400 to-teal-500 border-transparent text-white shadow-sm"
                    : task.status === 'in-progress'
                    ? "border-indigo-400 text-indigo-500 bg-indigo-50"
                    : "border-slate-300 text-slate-300 hover:border-indigo-300",
                )}
              >
                {task.status === 'completed' && <Check className="w-4 h-4" strokeWidth={3} />}
                {task.status === 'in-progress' && <PlayCircle className="w-4 h-4" strokeWidth={2.5} />}
                {task.status === 'pending' && <Circle className="w-4 h-4" strokeWidth={2.5} />}
              </button>
              
              <div className="flex-1 min-w-0">
                <p
                  className={cn(
                    "font-semibold text-lg leading-tight mb-1",
                    task.status === 'completed'
                      ? "text-slate-500 line-through"
                      : "text-slate-900",
                  )}
                >
                  {lang === "en" ? task.titleEn : task.titleMy}
                </p>
                {lang === "en" && task.titleMy && (
                  <p className="text-sm text-slate-500 mb-2">{task.titleMy}</p>
                )}
                {lang !== "en" && task.titleEn && (
                  <p className="text-sm text-slate-500 mb-2">{task.titleEn}</p>
                )}
                <div className="flex flex-wrap items-center gap-2">
                  <div className="flex items-center gap-1.5 text-sm text-indigo-600 font-semibold bg-indigo-50/80 backdrop-blur-sm w-fit px-2.5 py-1 rounded-lg">
                    <Clock className="w-3.5 h-3.5" />
                    {task.time}
                  </div>
                  <div className={cn(
                    "flex items-center gap-1.5 text-xs font-bold px-2.5 py-1 rounded-lg uppercase tracking-wider",
                    task.status === 'completed' ? "bg-emerald-50 text-emerald-600" :
                    task.status === 'in-progress' ? "bg-blue-50 text-blue-600" :
                    "bg-amber-50 text-amber-600"
                  )}>
                    {task.status === 'completed' ? t('completed') :
                     task.status === 'in-progress' ? t('inProgress') :
                     t('pending')}
                  </div>
                  {task.status !== 'completed' && (
                    <TimeLeftIndicator timeStr={task.time} t={t} />
                  )}
                </div>
              </div>

              <div className="flex flex-col gap-2 shrink-0">
                <button 
                  onClick={() => editTask(task)} 
                  className="p-2 text-slate-400 hover:text-indigo-600 bg-white/50 rounded-full transition-colors hover:bg-indigo-50"
                >
                  <Edit2 className="w-4 h-4" />
                </button>
                <button 
                  onClick={() => deleteTask(task.id)} 
                  className="p-2 text-slate-400 hover:text-rose-600 bg-white/50 rounded-full transition-colors hover:bg-rose-50"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
