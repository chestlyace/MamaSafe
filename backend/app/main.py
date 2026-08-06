import subprocess
import os
import sys
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_tables, SessionLocal, User
from app.routers import predict, assessments, auth, dashboard, anc, facilities, referrals, whatsapp_webhook, schedule, risk_trend, postnatal, growth, admin, users
from app.routers.auth import hash_password
from app.utils.scheduler_jobs import (
    job_send_48h_reminders,
    job_send_day_reminders_and_chw_list,
    job_detect_missed_visits,
)
from app.utils.postnatal_jobs import (
    job_send_pnc_48h_reminders,
    job_send_pnc_day_reminders,
    job_detect_missed_pnc_visits,
)
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

app = FastAPI(
    title="MamaSafe API",
    description="AI-powered maternal risk assessment for community health workers in Cameroon",
    version="1.0.0"
)

_raw_origins = os.getenv("ALLOWED_ORIGINS", "*")
allowed_origins = (
    [o.strip() for o in _raw_origins.split(",") if o.strip()]
    if _raw_origins != "*"
    else ["*"]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
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
            admin_user = os.getenv("ADMIN_USERNAME", "admin")
            admin_pass = os.getenv("ADMIN_PASSWORD", "ChangeMe@2025")
            admin = User(
                username=admin_user,
                hashed_password=hash_password(admin_pass),
                role="admin",
                full_name="System Administrator",
                must_change_password=True,
            )
            db.add(admin)
            db.commit()
            print(f"Admin account seeded: {admin_user}")
    finally:
        db.close()


def start_baileys():
    """Start the Baileys WhatsApp gateway as a detached background process.

    In containerized deployments the Baileys gateway runs as its own
    service, so the subprocess launch is disabled via DISABLE_BAILEYS_SPAWN=1.
    """
    global baileys_process
    if os.getenv("DISABLE_BAILEYS_SPAWN") == "1":
        print("WhatsApp gateway: running as separate service — subprocess spawn disabled")
        return
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

    # Start APScheduler for ANC visit reminders
    scheduler = BackgroundScheduler(timezone="Africa/Douala")
    scheduler.add_job(
        job_send_48h_reminders,
        CronTrigger(hour=7, minute=0),
        id="48h_reminders",
        replace_existing=True,
    )
    scheduler.add_job(
        job_send_day_reminders_and_chw_list,
        CronTrigger(hour=6, minute=0),
        id="day_reminders",
        replace_existing=True,
    )
    scheduler.add_job(
        job_detect_missed_visits,
        CronTrigger(hour=18, minute=0),
        id="missed_visits",
        replace_existing=True,
    )
    scheduler.add_job(
        job_send_pnc_48h_reminders,
        CronTrigger(hour=7, minute=0),
        id="pnc_48h_reminders",
        replace_existing=True,
    )
    scheduler.add_job(
        job_send_pnc_day_reminders,
        CronTrigger(hour=6, minute=0),
        id="pnc_day_reminders",
        replace_existing=True,
    )
    scheduler.add_job(
        job_detect_missed_pnc_visits,
        CronTrigger(hour=18, minute=0),
        id="pnc_missed_visits",
        replace_existing=True,
    )
    scheduler.start()
    print("APScheduler started — 3 daily ANC + 3 daily PNC reminder jobs registered")


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
app.include_router(schedule.router)
app.include_router(risk_trend.router)
app.include_router(postnatal.router)
app.include_router(growth.router)
app.include_router(admin.router)
app.include_router(users.router)


@app.get("/health")
def health():
    return {"status": "ok", "model": "XGBoost", "version": "1.0.0"}
