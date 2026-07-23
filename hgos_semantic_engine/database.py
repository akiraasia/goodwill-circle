import os
import uuid
from sqlalchemy import create_engine, Column, String, Text, DateTime, JSON
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from pgvector.sqlalchemy import Vector

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/postgres")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class WishSemantic(Base):
    __tablename__ = "wish_semantics"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    wish_id = Column(UUID(as_uuid=True), nullable=True) # Optional FK
    wish_text = Column(Text, nullable=False)
    embedding = Column(Vector(768))
    analysis_json = Column(JSONB, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
