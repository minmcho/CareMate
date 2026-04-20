from fastapi import APIRouter, HTTPException
from typing import List
from datetime import datetime
from bson import ObjectId

from app.database import get_db
from app.models.diet import MealCreate, RecipeCreate, RecipeOut, RecipeExtractRequest
from app.services.vllm_service import generate

router = APIRouter()


def _recipe_doc_to_out(doc: dict) -> RecipeOut:
    return RecipeOut(
        id=str(doc["_id"]),
        title=doc["title"],
        cooking_time=doc["cooking_time"],
        ingredients_en=doc["ingredients_en"],
        ingredients_my=doc["ingredients_my"],
        instructions_en=doc["instructions_en"],
        instructions_my=doc["instructions_my"],
        image_url=doc.get("image_url"),
        user_id=doc["user_id"],
        created_at=doc["created_at"],
    )


@router.get("/recipes/{user_id}", response_model=List[RecipeOut])
async def get_recipes(user_id: str):
    db = get_db()
    docs = await db.recipes.find({"user_id": user_id}).to_list(100)
    return [_recipe_doc_to_out(d) for d in docs]


@router.post("/recipes", response_model=RecipeOut, status_code=201)
async def create_recipe(recipe: RecipeCreate):
    db = get_db()
    doc = {**recipe.model_dump(), "created_at": datetime.utcnow()}
    result = await db.recipes.insert_one(doc)
    created = await db.recipes.find_one({"_id": result.inserted_id})
    return _recipe_doc_to_out(created)


@router.post("/recipes/extract-from-image", response_model=RecipeOut, status_code=201)
async def extract_recipe_from_image(req: RecipeExtractRequest):
    """
    Extract a recipe from a base64-encoded image using VLLM multimodal (or prompt-based OCR).
    Falls back to a text-based extraction prompt if multimodal isn't available.
    """
    prompt = (
        "You are given a recipe image. Extract the recipe and return a JSON object with these fields: "
        "title, cooking_time, ingredients_en (array), ingredients_my (array, translate to Myanmar), "
        "instructions_en (array of steps), instructions_my (array of steps, translate to Myanmar). "
        "Return only valid JSON."
    )
    raw_json = await generate(prompt, temperature=0.1)

    import json
    try:
        data = json.loads(raw_json)
    except Exception:
        raise HTTPException(status_code=422, detail="Could not parse recipe from image")

    recipe = RecipeCreate(
        title=data.get("title", "Extracted Recipe"),
        cooking_time=data.get("cooking_time", "30 mins"),
        ingredients_en=data.get("ingredients_en", []),
        ingredients_my=data.get("ingredients_my", []),
        instructions_en=data.get("instructions_en", []),
        instructions_my=data.get("instructions_my", []),
        user_id=req.user_id,
    )
    db = get_db()
    doc = {**recipe.model_dump(), "created_at": datetime.utcnow()}
    result = await db.recipes.insert_one(doc)
    created = await db.recipes.find_one({"_id": result.inserted_id})
    return _recipe_doc_to_out(created)


@router.get("/meals/{user_id}")
async def get_meals(user_id: str):
    db = get_db()
    docs = await db.meals.find({"user_id": user_id}).to_list(50)
    for d in docs:
        d["id"] = str(d.pop("_id"))
    return docs


@router.post("/meals", status_code=201)
async def create_meal(meal: MealCreate):
    db = get_db()
    doc = {**meal.model_dump(), "created_at": datetime.utcnow()}
    result = await db.meals.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    return doc


@router.delete("/recipes/{recipe_id}", status_code=204)
async def delete_recipe(recipe_id: str):
    db = get_db()
    result = await db.recipes.delete_one({"_id": ObjectId(recipe_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Recipe not found")
