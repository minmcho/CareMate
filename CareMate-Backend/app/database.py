from motor.motor_asyncio import AsyncIOMotorClient
from app.config import settings

client: AsyncIOMotorClient = None
db = None


async def connect_db():
    global client, db
    client = AsyncIOMotorClient(settings.MONGODB_URL)
    db = client[settings.MONGODB_DB_NAME]
    # Create indexes
    await db.schedules.create_index("user_id")
    await db.medications.create_index("user_id")
    await db.conversations.create_index([("user_id", 1), ("created_at", -1)])
    print(f"Connected to MongoDB: {settings.MONGODB_DB_NAME}")


async def close_db():
    global client
    if client:
        client.close()


def get_db():
    return db
