import subprocess
import os
import sys
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_tables, SessionLocal, User
from app.routers import predict, assessments, auth, dashboard, anc, facilities, referrals, whatsapp_webhook
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

BAILEYS_DIR = os.path.join(os.path.dirname(__file__), "..", "whatsapp")
BAILEYS_LOG = os.path.join(BAILEYS_DIR, "whatsapp.log")
baileys_process = None


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


def start_baileys():
    """Start the Baileys WhatsApp gateway as a detached background process."""
    global baileys_process
    if not os.path.exists(os.path.join(BAILEYS_DIR, "node_modules")):
        print("WhatsApp gateway not installed. Run: cd backend/whatsapp && npm install")
        return
    has_session = os.path.exists(os.path.join(BAILEYS_DIR, "auth", "creds.json"))
    label = "with saved session" if has_session else "first-time — use POST /api/v1/whatsapp/pair to link"
    print(f"WhatsApp gateway: starting {label}...")

    log_file = open(BAILEYS_LOG, "w")
    baileys_process = subprocess.Popen(
        ["node", "src/index.js"],
        cwd=BAILEYS_DIR,
        stdout=log_file,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    print(f"WhatsApp gateway: PID {baileys_process.pid}, log → {BAILEYS_LOG}")


@app.on_event("startup")
def startup():
    create_tables()
    seed_admin()
    start_baileys()


@app.on_event("shutdown")
def shutdown():
    global baileys_process
    if baileys_process:
        baileys_process.terminate()
        try:
            baileys_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            baileys_process.kill()


app.include_router(auth.router)
app.include_router(predict.router)
app.include_router(assessments.router)
app.include_router(dashboard.router)
app.include_router(anc.router)
app.include_router(facilities.router)
app.include_router(referrals.router)
app.include_router(whatsapp_webhook.router)


@app.get("/health")
def health():
    return {"status": "ok", "model": "XGBoost", "version": "1.0.0"}
