import GlassCard from "../components/GlassCard";

const METRICS = [
  { label: "Daily Active Users", value: "2,480", delta: "+8.6%" },
  { label: "7-Day Retention", value: "62%", delta: "+3.4%" },
  { label: "Pose Sessions / Day", value: "1,120", delta: "+15.1%" },
  { label: "Safety Interventions", value: "14", delta: "-11.0%" },
];

const NICHES = [
  {
    title: "Desk Ergonomics Coach",
    pitch: "Real-time posture checks and behavior nudges for remote teams.",
  },
  {
    title: "Perimenopause Wellness",
    pitch: "Lifestyle guidance with symptom journaling and community circles.",
  },
  {
    title: "Teen Athlete Recovery",
    pitch: "Pose analysis, hydration habits, and stress-aware coaching.",
  },
  {
    title: "Shift Worker Sleep",
    pitch: "Circadian-friendly plans and fatigue behavior monitoring.",
  },
];

const IOS_CHECKLIST = [
  "App privacy manifest and nutrition labels configured.",
  "Sign in with Apple support included for account creation.",
  "In-app reporting for unsafe content and community abuse.",
  "Human-readable disclaimer: wellness support, not medical diagnosis.",
  "Data deletion flow accessible from profile settings.",
];

export default function AdminView() {
  return (
    <div className="px-1 pt-4 pb-36 space-y-4">
      <div>
        <h2 className="text-[22px] font-bold text-slate-900">Admin Control Panel</h2>
        <p className="text-[13px] text-slate-500 mt-1">
          Production dashboard for growth, safety, and Apple App Store readiness.
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {METRICS.map((metric) => (
          <GlassCard key={metric.label}>
            <p className="text-[11px] text-slate-500">{metric.label}</p>
            <p className="text-[22px] font-bold text-slate-900 mt-1">{metric.value}</p>
            <p className="text-[12px] font-semibold text-emerald-600">{metric.delta}</p>
          </GlassCard>
        ))}
      </div>

      <GlassCard>
        <h3 className="text-[16px] font-bold text-slate-900">Growth Niches</h3>
        <div className="mt-3 space-y-2.5">
          {NICHES.map((niche) => (
            <div key={niche.title} className="rounded-2xl bg-white/60 border border-white/70 p-3">
              <p className="text-[13px] font-semibold text-slate-900">{niche.title}</p>
              <p className="text-[12px] text-slate-600 mt-1">{niche.pitch}</p>
            </div>
          ))}
        </div>
      </GlassCard>

      <GlassCard>
        <h3 className="text-[16px] font-bold text-slate-900">iOS Submission Readiness</h3>
        <ul className="mt-2 space-y-2">
          {IOS_CHECKLIST.map((item) => (
            <li key={item} className="text-[12px] text-slate-700 flex gap-2">
              <span className="text-emerald-600">✓</span>
              <span>{item}</span>
            </li>
          ))}
        </ul>
      </GlassCard>
    </div>
  );
}
