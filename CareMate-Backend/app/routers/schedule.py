from fastapi import APIRouter, HTTPException, Depends
from typing import List
from datetime import datetime
from bson import ObjectId

from app.database import get_db
from app.models.schedule import ScheduleTaskCreate, ScheduleTaskUpdate, ScheduleTaskOut

router = APIRouter()


def _doc_to_out(doc: dict) -> ScheduleTaskOut:
    return ScheduleTaskOut(
        id=str(doc["_id"]),
        title_en=doc["title_en"],
        title_my=doc["title_my"],
        time=doc["time"],
        status=doc["status"],
        user_id=doc["user_id"],
        created_at=doc["created_at"],
        updated_at=doc["updated_at"],
    )


@router.get("/{user_id}", response_model=List[ScheduleTaskOut])
async def get_tasks(user_id: str):
    db = get_db()
    docs = await db.schedules.find({"user_id": user_id}).sort("time", 1).to_list(100)
    return [_doc_to_out(d) for d in docs]


@router.post("/", response_model=ScheduleTaskOut, status_code=201)
async def create_task(task: ScheduleTaskCreate):
    db = get_db()
    now = datetime.utcnow()
    doc = {**task.model_dump(), "created_at": now, "updated_at": now}
    result = await db.schedules.insert_one(doc)
    created = await db.schedules.find_one({"_id": result.inserted_id})
    return _doc_to_out(created)


@router.patch("/{task_id}", response_model=ScheduleTaskOut)
async def update_task(task_id: str, update: ScheduleTaskUpdate):
    db = get_db()
    update_data = {k: v for k, v in update.model_dump().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()
    result = await db.schedules.find_one_and_update(
        {"_id": ObjectId(task_id)},
        {"$set": update_data},
        return_document=True,
    )
    if not result:
        raise HTTPException(status_code=404, detail="Task not found")
    return _doc_to_out(result)


@router.delete("/{task_id}", status_code=204)
async def delete_task(task_id: str):
    db = get_db()
    result = await db.schedules.delete_one({"_id": ObjectId(task_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Task not found")
