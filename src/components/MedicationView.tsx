import { useState, useEffect } from "react";
import { Plus, Check, Clock, Pill } from "lucide-react";
import { Language, useTranslation } from "../lib/i18n";
import { cn } from "../lib/utils";

interface Medication {
  id: string;
  nameEn: string;
  nameMy: string;
  dosage: string;
  time: string;
  taken: boolean;
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

const initialMeds: Medication[] = [
  {
    id: "1",
    nameEn: "Blood Pressure Pill",
    nameMy: "သွေးတိုးကျဆေး",
    dosage: "1 tablet",
    time: "08:00 AM",
    taken: false,
  },
  {
    id: "2",
    nameEn: "Vitamin C",
    nameMy: "ဗီတာမင်စီ",
    dosage: "1 tablet",
    time: "12:00 PM",
    taken: false,
  },
];

export default function MedicationView({ lang }: { lang: Language }) {
  const t = useTranslation(lang);
  const [meds, setMeds] = useState<Medication[]>(initialMeds);
  const [isAdding, setIsAdding] = useState(false);
  const [newMedName, setNewMedName] = useState("");
  const [newMedDosage, setNewMedDosage] = useState("");
  const [newMedTime, setNewMedTime] = useState("");

  const toggleMed = (id: string) => {
    setMeds(meds.map((m) => (m.id === id ? { ...m, taken: !m.taken } : m)));
  };

  const addMed = () => {
    if (!newMedName || !newMedDosage || !newMedTime) return;
    const newMed: Medication = {
      id: Date.now().toString(),
      nameEn: newMedName,
      nameMy: newMedName, // In a real app, we would translate this
      dosage: newMedDosage,
      time: newMedTime,
      taken: false,
    };
    setMeds([...meds, newMed].sort((a, b) => a.time.localeCompare(b.time)));
    setIsAdding(false);
    setNewMedName("");
    setNewMedDosage("");
    setNewMedTime("");
  };

  return (
    <div className="p-4 max-w-md mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-3xl font-bold tracking-tight text-slate-800">{t("medication")}</h2>
        <button
          onClick={() => setIsAdding(true)}
          className="p-2.5 bg-gradient-to-r from-rose-400 to-orange-400 text-white rounded-full shadow-lg shadow-rose-200 hover:shadow-xl hover:scale-105 transition-all active:scale-95"
        >
          <Plus className="w-6 h-6" />
        </button>
      </div>

      {isAdding && (
        <div className="bg-white/80 backdrop-blur-xl p-5 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white mb-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              {t("medName")}
            </label>
            <input
              type="text"
              value={newMedName}
              onChange={(e) => setNewMedName(e.target.value)}
              className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all"
              placeholder="e.g. Panadol"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              {t("dosage")}
            </label>
            <input
              type="text"
              value={newMedDosage}
              onChange={(e) => setNewMedDosage(e.target.value)}
              className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all"
              placeholder="e.g. 2 tablets"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              {t("time")}
            </label>
            <input
              type="time"
              value={newMedTime}
              onChange={(e) => setNewMedTime(e.target.value)}
              className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-rose-500 focus:border-rose-500 outline-none transition-all"
            />
          </div>
          <div className="flex gap-2 pt-2">
            <button
              onClick={addMed}
              className="flex-1 bg-gradient-to-r from-rose-400 to-orange-400 text-white py-3 rounded-xl font-semibold shadow-md shadow-rose-200 hover:shadow-lg transition-all active:scale-95"
            >
              {t("save")}
            </button>
            <button
              onClick={() => setIsAdding(false)}
              className="flex-1 bg-slate-100/80 text-slate-700 py-3 rounded-xl font-semibold hover:bg-slate-200 transition-all active:scale-95"
            >
              {t("cancel")}
            </button>
          </div>
        </div>
      )}

      <div className="space-y-3">
        {meds.length === 0 ? (
          <p className="text-center text-slate-500 py-8">{t("noMeds")}</p>
        ) : (
          meds.map((med) => (
            <div
              key={med.id}
              onClick={() => toggleMed(med.id)}
              className={cn(
                "flex items-start gap-4 p-5 rounded-3xl border transition-all duration-300 cursor-pointer",
                med.taken
                  ? "bg-white/40 border-white/20 opacity-60"
                  : "bg-white/80 backdrop-blur-xl border-white shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] hover:scale-[1.02]",
              )}
            >
              <div
                className={cn(
                  "mt-1 w-7 h-7 rounded-full border-2 flex items-center justify-center shrink-0 transition-all duration-300",
                  med.taken
                    ? "bg-gradient-to-br from-emerald-400 to-teal-500 border-transparent text-white shadow-sm"
                    : "border-slate-300 text-transparent",
                )}
              >
                <Check className="w-4 h-4" strokeWidth={3} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <Pill
                    className={cn(
                      "w-5 h-5",
                      med.taken ? "text-slate-400" : "text-rose-500",
                    )}
                  />
                  <p
                    className={cn(
                      "font-semibold text-lg leading-tight",
                      med.taken
                        ? "text-slate-500 line-through"
                        : "text-slate-900",
                    )}
                  >
                    {lang === "en" ? med.nameEn : med.nameMy}
                  </p>
                </div>
                {lang === "en" && med.nameMy && (
                  <p className="text-sm text-slate-500 mb-1">{med.nameMy}</p>
                )}
                {lang === "my" && med.nameEn && (
                  <p className="text-sm text-slate-500 mb-1">{med.nameEn}</p>
                )}
                <div className="flex items-center gap-3 mt-3">
                  <span className="text-sm text-slate-700 font-semibold bg-slate-100/80 backdrop-blur-sm px-2.5 py-1 rounded-lg">
                    {med.dosage}
                  </span>
                  <div className="flex items-center gap-1.5 text-sm text-rose-600 font-semibold bg-rose-50/80 backdrop-blur-sm w-fit px-2.5 py-1 rounded-lg">
                    <Clock className="w-3.5 h-3.5" />
                    {med.time}
                  </div>
                  {!med.taken && (
                    <TimeLeftIndicator timeStr={med.time} t={t} />
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
