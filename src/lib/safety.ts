/**
 * VitalPath AI — safety validator.
 *
 * This module mirrors the backend `SafetyValidator` service. It runs on every
 * inbound user message (pre-processing) and every model output (post-processing).
 *
 * Design goals:
 *  - Deterministic regex sweep for known crisis / medical terms.
 *  - Lightweight "semantic" heuristics for adjacent phrasing.
 *  - Zero PII persistence — only returns booleans + redacted text.
 */

export interface SafetyResult {
  passed: boolean;
  category: "ok" | "crisis" | "medical_claim" | "pii";
  matches: string[];
  sanitized: string;
}

// Crisis keywords — order matters: most specific first.
const CRISIS_PATTERNS: RegExp[] = [
  /\b(kill|hurt|harm)\s*(myself|me|my\s*self)\b/i,
  /\b(suicide|suicidal)\b/i,
  /\b(end\s*(my|it\s*all))\b/i,
  /\bi\s*(want|wanna)\s*to\s*(die|disappear)\b/i,
  /\boverdose\b/i,
  /\bcut(ting)?\s*myself\b/i,
  /\bchest\s*pain\b/i,
  /\bcan'?t\s*breathe\b/i,
  /\bstroke\b/i,
  /\bheart\s*attack\b/i,
];

// Medical claim patterns — block outputs that read like prescriptions.
const MEDICAL_CLAIM_PATTERNS: RegExp[] = [
  /\b(cure|cures|curing)\b/i,
  /\b(diagnos(e|is|ing))\b/i,
  /\b(prescrib(e|ing|ed))\b/i,
  /\b(treat(s|ment|ing)?\s+your)\b/i,
  /\byou\s*have\s*(diabetes|cancer|depression|anxiety\s*disorder|bipolar|adhd)\b/i,
  /\b(take|use)\s+\d+\s*(mg|mcg|ml)\b/i,
  /\bthis\s*will\s*(heal|fix)\b/i,
];

// Simple PII sweep (email + long digit runs).
const PII_PATTERNS: RegExp[] = [
  /[\w.+-]+@[\w-]+\.[\w.-]+/g,
  /\b\d{10,}\b/g,
];

function matchAny(text: string, patterns: RegExp[]): string[] {
  const hits: string[] = [];
  for (const p of patterns) {
    const m = text.match(p);
    if (m) hits.push(m[0]);
  }
  return hits;
}

export function scanUserInput(text: string): SafetyResult {
  const crisis = matchAny(text, CRISIS_PATTERNS);
  if (crisis.length > 0) {
    return {
      passed: false,
      category: "crisis",
      matches: crisis,
      sanitized: "[redacted]",
    };
  }

  const pii = matchAny(text, PII_PATTERNS);
  let sanitized = text;
  for (const p of PII_PATTERNS) sanitized = sanitized.replace(p, "[redacted]");

  return {
    passed: true,
    category: pii.length ? "pii" : "ok",
    matches: pii,
    sanitized,
  };
}

export function scanAssistantOutput(text: string): SafetyResult {
  const medical = matchAny(text, MEDICAL_CLAIM_PATTERNS);
  if (medical.length > 0) {
    return {
      passed: false,
      category: "medical_claim",
      matches: medical,
      sanitized: rewriteMedicalClaim(text),
    };
  }
  return {
    passed: true,
    category: "ok",
    matches: [],
    sanitized: text,
  };
}

function rewriteMedicalClaim(text: string): string {
  // Replace prohibited words with wellness-safe alternatives.
  let out = text;
  const replacements: [RegExp, string][] = [
    [/\bcure(s|d|ing)?\b/gi, "support"],
    [/\bdiagnos(e|is|ing)\b/gi, "notice"],
    [/\bprescrib(e|ing|ed)\b/gi, "suggest"],
    [/\btreat(ment|s|ing)?\b/gi, "support"],
    [/\bheal\b/gi, "support"],
  ];
  for (const [re, rep] of replacements) out = out.replace(re, rep);
  // Always append the disclaimer footer.
  if (!/wellness, not medicine/i.test(out)) {
    out += "\n\n_Reminder: VitalPath offers wellness guidance only._";
  }
  return out;
}

/**
 * Tiny non-cryptographic hash — used for "crisis event" audit logging
 * without storing the raw text. For production we use SHA-256 on the server.
 */
export function hashForAudit(text: string): string {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return (h >>> 0).toString(16).padStart(8, "0");
}
