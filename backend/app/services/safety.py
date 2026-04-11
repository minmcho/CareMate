"""Safety validator.

Runs on:
    - every inbound user message (pre-processing)
    - every model output (post-processing)

Design goals:
    - Deterministic regex sweep for known crisis / medical terms.
    - Boundary-safe rewriter that softens prohibited words while preserving
      meaning.
    - Zero PII persistence: the caller only stores hashes, never raw text.
"""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from enum import Enum
from typing import List, Pattern

# ---------------------------------------------------------------------------
# Pattern libraries
# ---------------------------------------------------------------------------

CRISIS_PATTERNS: List[Pattern[str]] = [
    re.compile(r"\b(kill|hurt|harm)\s*(myself|me|my\s*self)\b", re.I),
    re.compile(r"\b(suicide|suicidal)\b", re.I),
    re.compile(r"\b(end\s*(my|it\s*all))\b", re.I),
    re.compile(r"\bi\s*(want|wanna)\s*to\s*(die|disappear)\b", re.I),
    re.compile(r"\boverdose\b", re.I),
    re.compile(r"\bcut(ting)?\s*myself\b", re.I),
    re.compile(r"\bchest\s*pain\b", re.I),
    re.compile(r"\bcan'?t\s*breathe\b", re.I),
    re.compile(r"\bstroke\b", re.I),
    re.compile(r"\bheart\s*attack\b", re.I),
]

MEDICAL_CLAIM_PATTERNS: List[Pattern[str]] = [
    re.compile(r"\b(cure|cures|curing)\b", re.I),
    re.compile(r"\bdiagnos(e|is|ing)\b", re.I),
    re.compile(r"\bprescrib(e|ing|ed)\b", re.I),
    re.compile(r"\btreat(s|ment|ing)?\s+your\b", re.I),
    re.compile(
        r"\byou\s*have\s*(diabetes|cancer|depression|anxiety\s*disorder|bipolar|adhd)\b",
        re.I,
    ),
    re.compile(r"\b(take|use)\s+\d+\s*(mg|mcg|ml)\b", re.I),
    re.compile(r"\bthis\s*will\s*(heal|fix)\b", re.I),
]

PII_PATTERNS: List[Pattern[str]] = [
    re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+"),
    re.compile(r"\b\d{10,}\b"),
]


class SafetyCategory(str, Enum):
    OK = "ok"
    CRISIS = "crisis"
    MEDICAL_CLAIM = "medical_claim"
    PII = "pii"


@dataclass
class SafetyResult:
    passed: bool
    category: SafetyCategory
    matches: List[str]
    sanitized: str


# ---------------------------------------------------------------------------
# Core API
# ---------------------------------------------------------------------------


def scan_user_input(text: str) -> SafetyResult:
    """Run the pre-processing safety sweep."""
    crisis = _match_any(text, CRISIS_PATTERNS)
    if crisis:
        return SafetyResult(
            passed=False,
            category=SafetyCategory.CRISIS,
            matches=crisis,
            sanitized="[redacted]",
        )

    pii = _match_any(text, PII_PATTERNS)
    sanitized = text
    for pat in PII_PATTERNS:
        sanitized = pat.sub("[redacted]", sanitized)

    return SafetyResult(
        passed=True,
        category=SafetyCategory.PII if pii else SafetyCategory.OK,
        matches=pii,
        sanitized=sanitized,
    )


def scan_assistant_output(text: str) -> SafetyResult:
    """Run the post-processing safety sweep."""
    medical = _match_any(text, MEDICAL_CLAIM_PATTERNS)
    if medical:
        return SafetyResult(
            passed=False,
            category=SafetyCategory.MEDICAL_CLAIM,
            matches=medical,
            sanitized=_rewrite_medical(text),
        )
    return SafetyResult(
        passed=True,
        category=SafetyCategory.OK,
        matches=[],
        sanitized=text,
    )


def hash_for_audit(text: str) -> str:
    """Return a SHA-256 digest used for crisis audit records."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


def _match_any(text: str, patterns: List[Pattern[str]]) -> List[str]:
    hits: List[str] = []
    for pat in patterns:
        m = pat.search(text)
        if m:
            hits.append(m.group(0))
    return hits


def _rewrite_medical(text: str) -> str:
    out = text
    replacements = [
        (re.compile(r"\bcure(s|d|ing)?\b", re.I), "support"),
        (re.compile(r"\bdiagnos(e|is|ing)\b", re.I), "notice"),
        (re.compile(r"\bprescrib(e|ing|ed)\b", re.I), "suggest"),
        (re.compile(r"\btreat(ment|s|ing)?\b", re.I), "support"),
        (re.compile(r"\bheal\b", re.I), "support"),
    ]
    for pat, repl in replacements:
        out = pat.sub(repl, out)
    if "wellness, not medicine" not in out.lower():
        out += "\n\n_Reminder: VitalPath offers wellness guidance only._"
    return out
