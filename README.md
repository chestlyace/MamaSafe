# MamaSafe

AI-powered maternal mortality risk prediction for community health workers in Cameroon.

MamaSafe combines machine learning risk assessment with end-to-end clinical workflow management — from first antenatal visit through postnatal care and infant growth monitoring — giving community health workers (CHWs) a complete digital toolkit to reduce maternal deaths.

## Why MamaSafe

Maternal mortality remains critical in sub-Saharan Africa, where most deaths are preventable with early detection and timely referral. The root problem is not a lack of clinical knowledge — it is a lack of tools that work at community level, offline, in the hands of CHWs who carry paper registers and make decisions without decision support.

MamaSafe addresses this by putting an XGBoost risk prediction model, automated visit scheduling, emergency referral tracking, and longitudinal monitoring into a system that runs on basic smartphones and sends clinical alerts via WhatsApp and SMS.

## Core Modules

### Risk Prediction
- XGBoost classifier trained on maternal health indicators (age, blood pressure, blood sugar, temperature, heart rate)
- SHAP-powered explainability — every prediction comes with feature-level contributions so CHWs understand *why* a patient is high risk
- Three-tier classification: low, mid, high risk with confidence scores

### ANC Visit Scheduler
- Auto-generates the full 8-visit WHO antenatal care schedule from the LMP date
- WhatsApp reminders sent 48 hours and 2 hours before each visit
- Daily CHW visit lists delivered via WhatsApp each morning
- APScheduler-driven background jobs

### Emergency Referral System
- Structured clinical handoff packet sent to receiving facilities via SMS (Africa's Talking)
- Five-state referral tracking: sent → received → patient_arrived → completed → cancelled
- Designed around the Three Delays Framework to reduce time to appropriate care
- Works on basic phones — no internet required at the receiving facility

### Longitudinal Risk Tracking
- Plots risk scores across all ANC visits as a trend chart
- Automatic escalation detection when risk level increases between visits
- Feature-level trend analysis (BP, blood sugar, SHAP values changing over time)
- WhatsApp alerts to CHWs on risk escalation

### Postnatal Visit Tracker
- Registers delivery outcomes (mode, condition, live birth/stillbirth)
- Auto-schedules 3 WHO postnatal contacts (24 hours, 1 week, 6 weeks)
- PHQ-2 mental health screening embedded in every postnatal visit
- Structured maternal and newborn status recording

### Infant Growth Tracker
- Weight-for-age plotted against WHO Child Growth Standards percentile curves
- Automatic nutritional status classification (normal, underweight, severely underweight, overweight)
- Growth faltering detection when weight crosses percentile lines
- Feeding and immunisation tracking alongside weight

### Facility Management Dashboard
- District-level overview for supervisors and administrators
- CHW performance monitoring with activity metrics and inactivity alerts
- Cross-CHW high-risk patient panel
- Referral analytics by facility and CHW
- One-tap Ministry of Health monthly report export (CSV)

## Architecture

```
Internet
   | 80/443
+--v-----------------------------------------------+
| Host Nginx (reverse proxy, TLS termination)      |
|  www/root  -> frontend container :8080            |
|  /api/     -> backend container  :8000            |
|  api.*     -> backend container  :8000            |
+--+-----------------------------------------------+
   | 127.0.0.1 only
+--v-----------------------------------------------+
| Docker Compose ("mamasafe")                       |
|  frontend (nginx:alpine SPA)  127.0.0.1:8080     |
|  backend  (FastAPI/uvicorn)   127.0.0.1:8000     |
|  whatsapp (Baileys/Express)   127.0.0.1:3001     |
|  db       (PostgreSQL 16)     internal only       |
+--------------------------------------------------+
```

| Layer | Tech | Purpose |
|-------|------|---------|
| Backend API | FastAPI + SQLAlchemy + PostgreSQL | REST API, risk prediction, scheduling, referrals |
| ML Engine | XGBoost + SHAP | Risk classification with explainability |
| Web Dashboard | React 19 + Vite + Tailwind CSS | Supervisor analytics, CHW workflows, 32 pages |
| Mobile App | Flutter + Riverpod + Drift | CHW field app with offline-first local database |
| WhatsApp Gateway | Node.js + Baileys | Patient reminders, CHW alerts, escalation notifications |
| SMS Gateway | Africa's Talking | Facility referral notifications (no internet required) |
| Scheduler | APScheduler | Background jobs for visit reminders and missed-visit detection |

## Tech Stack

### Backend
- **FastAPI** — async REST API
- **SQLAlchemy 2.0** — ORM with PostgreSQL 16
- **XGBoost** — gradient-boosted risk classifier
- **SHAP** — model explainability
- **APScheduler** — background job scheduling
- **python-jose** — JWT authentication
- **passlib + bcrypt** — password hashing

### Frontend (Web)
- **React 19** with Vite 8
- **Tailwind CSS 4** — utility-first styling
- **Recharts** — clinical data visualisation
- **React Router 7** — client-side routing
- **i18next** — English/French internationalisation
- **Axios** — HTTP client

### Mobile
- **Flutter** (migrated from React Native)
- **Riverpod** — state management
- **Drift** — offline-first SQLite database
- **go_router** — declarative routing
- **fl_chart** — growth charts and risk trend visualisation
- **flutter_secure_storage** — credential storage

### WhatsApp Gateway
- **Baileys** — WhatsApp Web multi-device API
- **Express** — webhook receiver
- **Pino** — structured logging

### Infrastructure
- **Docker Compose** — single-server deployment
- **Nginx** — reverse proxy with TLS termination
- **Let's Encrypt** — automated TLS certificates
- **PostgreSQL 16** — primary datastore
- **UFW** — host firewall

## Project Structure

```
MamaSafe/
  backend/
    app/
      main.py              # FastAPI app, router registration, scheduler startup
      database.py          # SQLAlchemy models (User, Patient, Assessment, Referral, etc.)
      schemas.py           # Pydantic request/response schemas
      schemas_admin.py     # Admin dashboard schemas
      schemas_anc.py       # ANC visit schemas
      schemas_postnatal.py # Postnatal visit schemas
      schemas_referral.py  # Referral schemas
      schemas_schedule.py  # Scheduling schemas
      models.py            # Additional model definitions
      routers/
        auth.py            # JWT authentication
        predict.py         # Risk prediction endpoint
        assessments.py     # Assessment CRUD
        dashboard.py       # CHW dashboard
        anc.py             # Antenatal care endpoints
        referral.py        # Emergency referral endpoints
        schedule.py        # Visit scheduling
        risk_trend.py      # Longitudinal risk tracking
        postnatal.py       # Postnatal visit endpoints
        growth.py          # Infant growth tracking
        admin.py           # Facility management dashboard
        users.py           # User management
        facilities.py      # Facility directory
        whatsapp_webhook.py # WhatsApp inbound message handler
      services/            # Business logic layer
      utils/
        risk_tracking.py   # Escalation detection + WhatsApp alerts
        scheduler_jobs.py  # ANC reminder background jobs
        postnatal_jobs.py  # PNC reminder background jobs
        whatsapp.py        # WhatsApp message sending
    model/                 # Trained XGBoost model files
    tests/                 # Backend test suite
    whatsapp/              # Baileys WhatsApp gateway (Node.js)
  frontend/
    src/
      pages/               # 32 page components
      components/          # Reusable UI components
      i18n/                # English/French translations
    public/
    test/
  mobile/
    lib/
      features/            # 18 feature modules
      core/                # Shared utilities, API client, offline DB
      l10n/                # Localisation files
    assets/
  deploy/
    scripts/               # Deployment, backup, monitoring scripts
    nginx/                 # Nginx configuration templates
    docker-compose.yml     # Production compose stack
    .env.production.example
  ml/                      # Model training notebooks and data
  docs/                    # Design specs and implementation plans
```

## Getting Started

### Prerequisites

- Python 3.11+
- Node.js 18+
- PostgreSQL 16+
- Flutter SDK 3.5+ (for mobile)
- Docker & Docker Compose (for deployment)

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env   # edit DATABASE_URL, SECRET_KEY, etc.

# Create tables and seed admin user
python -c "from app.database import create_tables; create_tables()"

# Start the API server
uvicorn app.main:app --reload --port 8000
```

The admin account is seeded automatically on first startup. Default credentials are read from environment variables (`ADMIN_USERNAME`, `ADMIN_PASSWORD`).

### WhatsApp Gateway

```bash
cd backend/whatsapp
npm install
npm start
```

The gateway starts on port 3001. Scan the QR code with the target WhatsApp phone to pair the session. The session persists in a Docker volume across restarts.

### Web Frontend

```bash
cd frontend
npm install
npm run dev
```

The development server runs on port 5173 with hot reload. Configure the API endpoint in `.env`:

```
VITE_API_URL=http://localhost:8000
```

### Mobile App

```bash
cd mobile
flutter pub get

# Configure environment
cp .env.production.example .env   # edit API URLs

# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

### Docker (Production)

```bash
# Clone and configure
git clone <repo-url> /opt/mamasafe/MamaSafe
cd /opt/mamasafe/MamaSafe/deploy
cp .env.production.example .env.production
nano .env.production   # fill in all CHANGE_ME values

# Deploy
bash scripts/deploy.sh /opt/mamasafe/MamaSafe
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for the full single-server deployment runbook covering DNS, TLS, backups, monitoring, and security hardening.

## API Overview

All endpoints are prefixed with `/api/v1` and require JWT authentication unless noted.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/login` | POST | Authenticate user, return JWT |
| `/predict` | POST | Submit vital signs, get risk prediction with SHAP explanations |
| `/patients` | GET/POST | List and register patients |
| `/patients/{id}/assessments` | GET | Assessment history for a patient |
| `/patients/{id}/risk-trend` | GET | Longitudinal risk trend data |
| `/patients/{id}/risk-summary` | GET | Lightweight risk summary for list cards |
| `/anc/schedule/{patient_id}` | GET | ANC visit schedule for a pregnancy |
| `/anc/visits/{id}/complete` | POST | Mark an ANC visit as completed |
| `/referrals` | POST | Initiate an emergency referral |
| `/referrals/{id}/status` | PATCH | Update referral status |
| `/referrals/webhook/whatsapp` | POST | Inbound WhatsApp message handler |
| `/postnatal/deliveries` | POST | Register a delivery |
| `/postnatal/deliveries/{id}/visits` | GET | Postnatal visit schedule |
| `/growth/newborns/{id}/measurements` | GET/POST | Infant growth measurements |
| `/admin/dashboard` | GET | District-level summary (supervisor+) |
| `/admin/chws` | GET | CHW list with performance stats |
| `/admin/high-risk-patients` | GET | Cross-CHW high-risk panel |
| `/admin/referral-analytics` | GET | Referral performance by facility |
| `/admin/report/monthly` | GET | Ministry of Health monthly report |
| `/admin/users` | GET/POST | User management |

## User Roles

| Role | Access |
|------|--------|
| `chw` | Own patients, own assessments, own referrals |
| `supervisor` | All CHWs and patients in their district, facility dashboard |
| `admin` | All data across all districts, user management, system configuration |

## Deployment

MamaSafe is designed for single-server deployment on a Linux VPS (e.g., EC2 t3.small/medium). The entire stack runs in Docker Compose behind Nginx with TLS.

Key deployment details:
- PostgreSQL is never exposed externally — internal Docker network only
- Container ports bound to `127.0.0.1` only
- Nightly `pg_dump` backups with 14-day retention
- Health check monitoring every 5 minutes
- Automatic TLS renewal via Let's Encrypt

Full runbook: [DEPLOYMENT.md](DEPLOYMENT.md)

## Documentation

Each module has detailed technical documentation:

- [Emergency Referral System](REFERRAL_SYSTEM.md) — clinical packet, SMS integration, status tracking
- [ANC Visit Scheduler](ANC_VISIT_SCHEDULER.md) — 8-visit schedule, WhatsApp reminders, APScheduler
- [Longitudinal Risk Tracking](LONGITUDINAL_RISK_TRACKING.md) — trend charts, escalation detection
- [Postnatal Visit Tracker](POSTNATAL_VISIT_TRACKER.md) — delivery registration, PNC contacts, PHQ-2
- [Infant Growth Tracker](INFANT_GROWTH_TRACKER.md) — WHO growth standards, faltering detection
- [Facility Management Dashboard](FACILITY_MANAGEMENT.md) — supervisor analytics, Ministry reports
- [Deployment Runbook](DEPLOYMENT.md) — production deployment, backups, monitoring

## License

All rights reserved. This is proprietary software.
