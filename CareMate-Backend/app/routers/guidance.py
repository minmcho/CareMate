from fastapi import APIRouter
from typing import List
from pydantic import BaseModel

router = APIRouter()


class GuidanceModule(BaseModel):
    id: str
    category: str  # theory | practical | specific
    title_en: str
    title_my: str
    description_en: str
    description_my: str
    video_url: str
    duration_mins: int
    tags: List[str]


# Static guidance library (could be moved to MongoDB)
GUIDANCE_MODULES: List[dict] = [
    {
        "id": "g1", "category": "theory",
        "title_en": "Understanding Dementia", "title_my": "သိမ်မွေ့ဉာဏ်ရည်ချို့တဲ့မှု နားလည်ခြင်း",
        "description_en": "Learn about dementia stages, symptoms, and communication tips.",
        "description_my": "Dementia အဆင့်များ၊ လက္ခဏာများနှင့် ဆက်ဆံရေးအကြံပြုချက်များကို လေ့လာပါ။",
        "video_url": "https://example.com/videos/dementia-basics",
        "duration_mins": 12, "tags": ["dementia", "cognitive", "communication"],
    },
    {
        "id": "g2", "category": "practical",
        "title_en": "Safe Patient Transfer", "title_my": "လူနာလွှဲပြောင်းခြင်း ဘေးကင်းစွာ",
        "description_en": "Techniques for safely moving patients from bed to wheelchair.",
        "description_my": "လူနာကို အိပ်ရာမှ ထိုင်နင်းလှည်းသို့ ဘေးကင်းစွာ ရွှေ့ပြောင်းသည့် နည်းပညာများ။",
        "video_url": "https://example.com/videos/patient-transfer",
        "duration_mins": 8, "tags": ["mobility", "transfer", "safety"],
    },
    {
        "id": "g3", "category": "practical",
        "title_en": "Personal Hygiene Care", "title_my": "ကိုယ်ရေးသန့်ရှင်းမှု စောင့်ရှောက်ခြင်း",
        "description_en": "Step-by-step guide to bathing, oral hygiene, and skin care.",
        "description_my": "ရေချိုး၊ ခံတွင်းသန့်ရှင်းရေးနှင့် အရေပြားစောင့်ရှောက်ခြင်းအတွက် အဆင့်ဆင့်လမ်းညွှန်မှု။",
        "video_url": "https://example.com/videos/hygiene-care",
        "duration_mins": 15, "tags": ["hygiene", "bathing", "skincare"],
    },
    {
        "id": "g4", "category": "specific",
        "title_en": "Wound Care & Dressing", "title_my": "အနာပြုစုခြင်းနှင့် ပတ်ခြင်း",
        "description_en": "Proper wound cleaning, dressing changes, and infection monitoring.",
        "description_my": "အနာကို မှန်ကန်စွာ သန့်ရှင်းခြင်း၊ ပတ်ပိုးပြောင်းလဲခြင်းနှင့် ရောဂါပိုးတိုးပွားမှုကို စောင့်ကြည့်ခြင်း။",
        "video_url": "https://example.com/videos/wound-care",
        "duration_mins": 10, "tags": ["wound", "dressing", "infection"],
    },
    {
        "id": "g5", "category": "theory",
        "title_en": "Medication Administration", "title_my": "ဆေးဝါးပေးအပ်ခြင်း",
        "description_en": "Understanding prescriptions, dosage, and safe medication administration.",
        "description_my": "ဆေးစာ၊ ဆေးပမာဏနှင့် ဘေးကင်းသော ဆေးဝါးပေးအပ်မှုကို နားလည်ခြင်း။",
        "video_url": "https://example.com/videos/medication-admin",
        "duration_mins": 18, "tags": ["medication", "dosage", "safety"],
    },
]


@router.get("/", response_model=List[dict])
async def get_guidance_modules(category: str = None, tag: str = None):
    modules = GUIDANCE_MODULES
    if category:
        modules = [m for m in modules if m["category"] == category]
    if tag:
        modules = [m for m in modules if tag in m["tags"]]
    return modules


@router.get("/{module_id}")
async def get_guidance_module(module_id: str):
    module = next((m for m in GUIDANCE_MODULES if m["id"] == module_id), None)
    if not module:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Module not found")
    return module


@router.get("/categories/list")
async def get_categories():
    return {"categories": ["theory", "practical", "specific"]}
