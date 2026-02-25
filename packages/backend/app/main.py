from fastapi import FastAPI, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db import engine, Base, get_db
from app.models import User

app = FastAPI()


@app.on_event("startup")
async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


@app.get("/")
async def root():
    return {"message": "Backend running"}


@app.post("/users")
async def create_user(name: str, db: AsyncSession = Depends(get_db)):
    user = User(name=name)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@app.get("/users")
async def list_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User))
    return result.scalars().all()