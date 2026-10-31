import logging
import os
from pathlib import Path
from app.core.config import settings
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

logger = logging.getLogger("fireeye.database")

Base = declarative_base()

def create_resilient_engine():
    db_url = settings.DATABASE_URL
    connect_args = {}

    if db_url.startswith("sqlite"):
        connect_args["check_same_thread"] = False
        return create_engine(db_url, connect_args=connect_args, echo=False)

    # For PostgreSQL (e.g. Supabase)
    if db_url.startswith("postgresql://"):
        db_url = db_url.replace("postgresql://", "postgresql+psycopg2://", 1)

    try:
        engine = create_engine(
            db_url,
            connect_args={"connect_timeout": 5},
            pool_pre_ping=True,
            pool_size=10,
            max_overflow=20,
            echo=False,
        )
        with engine.connect() as conn:
            safe_target = db_url.split("@")[-1] if "@" in db_url else db_url
            print(f"[FIRE-EYE DATABASE] Successfully connected to PostgreSQL: {safe_target}")
        return engine
    except Exception as exc:
        safe_target = db_url.split("@")[-1] if "@" in db_url else db_url
        print(f"[FIRE-EYE DATABASE WARNING] Could not establish live connection to PostgreSQL ({safe_target}): {exc}")
        print("[FIRE-EYE DATABASE INFO] Falling back to local high-performance SQLite engine.")
        local_db_path = Path(__file__).resolve().parent.parent / "sql_app.db"
        sqlite_url = f"sqlite:///{local_db_path}"
        return create_engine(sqlite_url, connect_args={"check_same_thread": False}, echo=False)

engine = create_resilient_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
