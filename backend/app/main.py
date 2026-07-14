from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_tables, SessionLocal, User
from app.routers import predict, assessments, auth, dashboard
from app.routers.auth import hash_password

app = FastAPI(
    title="MamaSafe API",
    description="AI-powered maternal risk assessment for community health workers in Cameroon",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def seed_admin():
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.username == "admin").first()
        if not existing:
            admin = User(
                username="admin",
                hashed_password=hash_password("ChangeMe@2025"),
                role="admin",
                full_name="System Administrator",
                must_change_password=True,
            )
            db.add(admin)
            db.commit()
            print("Admin account seeded: admin / ChangeMe@2025")
    finally:
        db.close()


@app.on_event("startup")
def startup():
    create_tables()
    seed_admin()


app.include_router(auth.router)
app.include_router(predict.router)
app.include_router(assessments.router)
app.include_router(dashboard.router)


@app.get("/health")
def health():
    return {"status": "ok", "model": "XGBoost", "version": "1.0.0"}
