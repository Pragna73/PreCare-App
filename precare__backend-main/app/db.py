from __future__ import annotations

from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = "sqlite:///./precare.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _ensure_column(conn, table: str, col: str, ddl: str) -> None:
    if conn.dialect.name != "sqlite":
        return
    cols = {row[1] for row in conn.execute(text(f"PRAGMA table_info({table})")).fetchall()}
    if col not in cols:
        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {ddl}"))


def run_startup_migrations() -> None:
    with engine.begin() as conn:
        conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS emergency_contacts (
                    id INTEGER PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    label VARCHAR NOT NULL DEFAULT 'Emergency',
                    phone_number VARCHAR NOT NULL,
                    relationship VARCHAR,
                    is_primary BOOLEAN NOT NULL DEFAULT 0,
                    created_at DATETIME,
                    FOREIGN KEY(user_id) REFERENCES users(id)
                )
                """
            )
        )

        conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS health_metrics (
                    id INTEGER PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    hemoglobin FLOAT NOT NULL,
                    systolic_bp INTEGER NOT NULL,
                    diastolic_bp INTEGER NOT NULL,
                    blood_glucose FLOAT NOT NULL,
                    weight_kg FLOAT NOT NULL,
                    created_at DATETIME,
                    FOREIGN KEY(user_id) REFERENCES users(id)
                )
                """
            )
        )

        conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS maya_messages (
                    id INTEGER PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    role VARCHAR NOT NULL,
                    content TEXT NOT NULL,
                    created_at DATETIME,
                    FOREIGN KEY(user_id) REFERENCES users(id)
                )
                """
            )
        )

        conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS digital_twins (
                    id INTEGER PRIMARY KEY,
                    public_id VARCHAR UNIQUE,
                    user_id INTEGER NOT NULL,
                    model_state TEXT NOT NULL DEFAULT '{}',
                    risk_prediction VARCHAR NOT NULL DEFAULT '',
                    future_alert VARCHAR NOT NULL DEFAULT '',
                    created_at DATETIME,
                    FOREIGN KEY(user_id) REFERENCES users(id)
                )
                """
            )
        )

        _ensure_column(conn, "users", "public_id", "public_id VARCHAR")
        _ensure_column(conn, "users", "mobile", "mobile VARCHAR")
        _ensure_column(conn, "users", "emergency_contact_name", "emergency_contact_name VARCHAR")
        _ensure_column(conn, "users", "emergency_contact_phone", "emergency_contact_phone VARCHAR")

        _ensure_column(conn, "reports", "public_id", "public_id VARCHAR")
        _ensure_column(conn, "reports", "user_id", "user_id INTEGER")
        _ensure_column(conn, "reports", "file_path", "file_path VARCHAR")
        _ensure_column(conn, "reports", "file_url", "file_url VARCHAR")
        _ensure_column(conn, "reports", "structured_data", "structured_data TEXT DEFAULT '{}' NOT NULL")

        _ensure_column(conn, "appointments", "public_id", "public_id VARCHAR")
        _ensure_column(conn, "appointments", "user_id", "user_id INTEGER")

        _ensure_column(conn, "emergencies", "public_id", "public_id VARCHAR")
        _ensure_column(conn, "emergencies", "user_id", "user_id INTEGER")
        _ensure_column(conn, "emergencies", "eta_minutes", "eta_minutes INTEGER")

        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_public_id ON users(public_id)"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS idx_reports_public_id ON reports(public_id)"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS idx_appointments_public_id ON appointments(public_id)"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS idx_emergencies_public_id ON emergencies(public_id)"))
        conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS idx_twins_public_id ON digital_twins(public_id)"))
