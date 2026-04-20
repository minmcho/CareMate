from fastapi import APIRouter, HTTPException
from typing import List
from datetime import datetime
from bson import ObjectId

from app.database import get_db
from app.models.medication import MedicationCreate, MedicationUpdate, MedicationOut

router = APIRouter()


def _doc_to_out(doc: dict) -> MedicationOut:
    return MedicationOut(
        id=str(doc["_id"]),
        name_en=doc["name_en"],
        name_my=doc["name_my"],
        dosage=doc["dosage"],
        time=doc["time"],
        taken=doc.get("taken", False),
        notes=doc.get("notes"),
        user_id=doc["user_id"],
        created_at=doc["created_at"],
    )


@router.get("/{user_id}", response_model=List[MedicationOut])
async def get_medications(user_id: str):
    db = get_db()
    docs = await db.medications.find({"user_id": user_id}).sort("time", 1).to_list(100)
    return [_doc_to_out(d) for d in docs]


@router.post("/", response_model=MedicationOut, status_code=201)
async def create_medication(med: MedicationCreate):
    db = get_db()
    now = datetime.utcnow()
    doc = {**med.model_dump(), "taken": False, "created_at": now}
    result = await db.medications.insert_one(doc)
    created = await db.medications.find_one({"_id": result.inserted_id})
    return _doc_to_out(created)


@router.patch("/{med_id}", response_model=MedicationOut)
async def update_medication(med_id: str, update: MedicationUpdate):
    db = get_db()
    update_data = {k: v for k, v in update.model_dump().items() if v is not None}
    result = await db.medications.find_one_and_update(
        {"_id": ObjectId(med_id)},
        {"$set": update_data},
        return_document=True,
    )
    if not result:
        raise HTTPException(status_code=404, detail="Medication not found")
    return _doc_to_out(result)


@router.post("/{med_id}/toggle-taken", response_model=MedicationOut)
async def toggle_taken(med_id: str):
    db = get_db()
    doc = await db.medications.find_one({"_id": ObjectId(med_id)})
    if not doc:
        raise HTTPException(status_code=404, detail="Medication not found")
    new_taken = not doc.get("taken", False)
    result = await db.medications.find_one_and_update(
        {"_id": ObjectId(med_id)},
        {"$set": {"taken": new_taken}},
        return_document=True,
    )
    return _doc_to_out(result)


@router.delete("/{med_id}", status_code=204)
async def delete_medication(med_id: str):
    db = get_db()
    result = await db.medications.delete_one({"_id": ObjectId(med_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Medication not found")
