# MamaSafe — ANC Visit Scheduler
## Complete Technical Documentation

**Version:** 1.0  
**Module:** Antenatal Care Visit Scheduler  
**Stack:** FastAPI · PostgreSQL · Baileys WhatsApp · APScheduler · React · Expo  
**Last updated:** July 2025

---

## Table of Contents

1. [Overview and Purpose](#1-overview-and-purpose)
2. [Clinical Context — The 8 WHO ANC Visits](#2-clinical-context--the-8-who-anc-visits)
3. [System Architecture](#3-system-architecture)
4. [How Scheduling Works](#4-how-scheduling-works)
5. [Data Model](#5-data-model)
6. [WhatsApp Notification Strategy](#6-whatsapp-notification-strategy)
7. [API Reference](#7-api-reference)
8. [Backend Implementation](#8-backend-implementation)
9. [APScheduler — Background Job Setup](#9-apscheduler--background-job-setup)
10. [WhatsApp Message Templates](#10-whatsapp-message-templates)
11. [Web Frontend Implementation](#11-web-frontend-implementation)
12. [Mobile Frontend Implementation (Expo)](#12-mobile-frontend-implementation-expo)
13. [Testing Guide](#13-testing-guide)
14. [Report Integration](#14-report-integration)
15. [Future Extensions](#15-future-extensions)

---

## 1. Overview and Purpose

The MamaSafe ANC Visit Scheduler solves a specific and measurable problem: pregnant women in Cameroon miss antenatal care visits not because they do not want to attend, but because they are not reminded, do not know the schedule, and have no one following up between visits. The result is that many women arrive at delivery with incomplete antenatal records, undetected complications, and no continuity of care.

The scheduler does three things:

**1. Auto-generates the complete 8-visit schedule at pregnancy registration** — When a CHW registers a new pregnancy in MamaSafe and enters the Last Menstrual Period (LMP) date, the system automatically calculates all 8 WHO-recommended visit dates based on gestational age milestones. No manual scheduling required.

**2. Sends WhatsApp reminders to the patient** — 48 hours before each scheduled visit, the system sends a WhatsApp message to the patient's phone number with the visit date, time, location, and what to bring. A second reminder fires 2 hours before the visit.

**3. Sends a daily CHW visit list** — Every morning at 7 AM, each CHW receives a WhatsApp message listing all patients due for ANC visits that day, so they can proactively follow up if a patient does not arrive.

**What it replaces:** In the current Cameroon system, visit scheduling is done verbally at the end of each visit — the CHW tells the patient when to come back and writes a date on the paper carnet. The patient may lose the carnet, forget the date, or face transportation barriers without any follow-up mechanism.

---

## 2. Clinical Context — The 8 WHO ANC Visits

The World Health Organisation's 2016 ANC recommendations define 8 contact points between a pregnant woman and the health system, replacing the older 4-visit focused ANC model. Cameroon's Ministry of Public Health adopted this framework in its maternal health guidelines.

### Visit schedule based on gestational age

| Visit | Gestational Age | Key clinical activities |
|-------|----------------|------------------------|
| Visit 1 | 8–12 weeks | Booking visit — full history, blood tests, HIV, syphilis, blood group, USS if available, iron/folic acid |
| Visit 2 | 16 weeks | Blood pressure, urine, foetal HR, weight, review blood results |
| Visit 3 | 20 weeks | Anomaly scan if available, foetal movement discussion, BP, urine |
| Visit 4 | 26 weeks | Glucose screening, anaemia check, BP, fundal height |
| Visit 5 | 30 weeks | BP, foetal presentation, haemoglobin, discuss birth plan |
| Visit 6 | 34 weeks | BP, foetal presentation, group B strep discussion, birth plan |
| Visit 7 | 36 weeks | Foetal presentation confirmed, birth plan finalised, danger signs |
| Visit 8 | 38–40 weeks | Final visit — readiness for labour, emergency contacts, facility location |

### Calculating visit dates from LMP

Given the LMP date, each visit date is calculated by adding the corresponding gestational weeks:

```
Visit 1 date = LMP + 8 weeks
Visit 2 date = LMP + 16 weeks
Visit 3 date = LMP + 20 weeks
Visit 4 date = LMP + 26 weeks
Visit 5 date = LMP + 30 weeks
Visit 6 date = LMP + 34 weeks
Visit 7 date = LMP + 36 weeks
Visit 8 date = LMP + 38 weeks
EDD          = LMP + 40 weeks (Naegele's rule: LMP + 9 months + 7 days)
```

### Why auto-calculation matters

A CHW in a rural health post should not need to calculate dates manually. A calculation error means the patient is reminded to come at the wrong gestational age, potentially missing a critical screening window. Auto-calculation eliminates this error class entirely.

---

## 3. System Architecture

### Component overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          MamaSafe Platform                              │
│                                                                         │
│  ┌──────────────┐    ┌─────────────────────────────────────────────┐   │
│  │  React Web   │───▶│              FastAPI Backend                │   │
│  │  Expo Mobile │    │                                             │   │
│  └──────────────┘    │  /api/v1/schedule/*                         │   │
│                      │  /api/v1/pregnancies (existing)             │   │
│                      │                                             │   │
│                      │  ┌─────────────────────────────────────┐   │   │
│                      │  │        APScheduler                  │   │   │
│                      │  │  (background job runner)            │   │   │
│                      │  │                                     │   │   │
│                      │  │  Job 1: Daily reminder check        │   │   │
│                      │  │         runs at 07:00 every day     │   │   │
│                      │  │                                     │   │   │
│                      │  │  Job 2: 2-hour pre-visit reminder   │   │   │
│                      │  │         runs at 06:00 every day     │   │   │
│                      │  │                                     │   │   │
│                      │  │  Job 3: Missed visit check          │   │   │
│                      │  │         runs at 18:00 every day     │   │   │
│                      │  └──────────────┬──────────────────────┘   │   │
│                      │                 │                           │   │
│                      └─────────────────┼───────────────────────────┘   │
└────────────────────────────────────────┼───────────────────────────────┘
                                         │ HTTP POST
                              ┌──────────▼──────────┐
                              │  Baileys WhatsApp   │
                              │  Microservice       │
                              │  (Node.js :3001)    │
                              └──────────┬──────────┘
                                         │ WhatsApp Web
                              ┌──────────▼──────────┐
                              │  Patient's Phone    │
                              │  (WhatsApp message) │
                              └─────────────────────┘
```

### Data flow when a pregnancy is registered

```
CHW enters LMP date
        ↓
POST /api/v1/pregnancies
        ↓
Backend calculates all 8 visit dates
        ↓
Creates ScheduledVisit records (×8) in PostgreSQL
        ↓
Each record: visit_number, scheduled_date, status=scheduled
        ↓
Returns pregnancy object with visit_count=8 to frontend
        ↓
CHW sees visit schedule immediately on patient profile
```

### Data flow for daily reminders (APScheduler)

```
07:00 every morning
        ↓
APScheduler job fires
        ↓
Query: SELECT all ScheduledVisits WHERE
       scheduled_date = today + 2 days
       AND status = 'scheduled'
       AND reminder_48h_sent = false
        ↓
For each visit found:
  - Load patient record
  - Call Baileys microservice POST /send-message
  - Mark reminder_48h_sent = true
        ↓
Second query: SELECT all ScheduledVisits WHERE
              scheduled_date = today
              AND status = 'scheduled'
        ↓
Build CHW daily list
Send to each CHW's WhatsApp
```

---

## 4. How Scheduling Works

### Step 1 — Registration triggers auto-schedule

When a new pregnancy is registered via `POST /api/v1/pregnancies`, the backend immediately calls `auto_schedule_visits(pregnancy_id, lmp_date)`. This function:

1. Calculates the date for each of the 8 visits by adding the required weeks to the LMP date
2. Creates one `ScheduledVisit` record per visit
3. All records start with `status = "scheduled"`
4. No user action required — the schedule is fully generated automatically

### Step 2 — CHW views and manages the schedule

The CHW can view the complete visit schedule on the patient profile screen. Each visit shows:
- Visit number and what it covers clinically
- Scheduled date
- Status: scheduled / completed / missed / rescheduled
- A button to mark as completed (links to the ANC visit recording form)
- A button to reschedule (opens a date picker)

### Step 3 — Background jobs send reminders

Three APScheduler jobs run daily:

**Job 1 — 48-hour reminder (runs 07:00 daily)**
Finds all visits scheduled for 2 days from now. Sends WhatsApp to the patient's phone.

**Job 2 — Day-of reminder (runs 06:00 daily)**
Finds all visits scheduled for today. Sends a shorter "your visit is today" WhatsApp. Also compiles and sends the CHW's daily patient list.

**Job 3 — Missed visit detection (runs 18:00 daily)**
Finds all visits that were scheduled for today and are not marked completed. Marks them as `missed`. Sends a WhatsApp alert to the CHW listing which patients did not show up.

### Step 4 — CHW marks visits completed

When a patient attends a visit and the CHW records clinical data in the ANC card module, the linked `ScheduledVisit` record is automatically updated to `completed`. The next visit's reminder cycle begins automatically.

### Step 5 — Rescheduling

If a patient cannot attend on the scheduled date, the CHW can reschedule from the app. The system:
1. Updates the `ScheduledVisit.scheduled_date` to the new date
2. Resets `reminder_48h_sent = false` so the reminder fires again for the new date
3. Logs the original date in `original_date` for audit purposes
4. Sends a WhatsApp to the patient confirming the new date

---

## 5. Data Model

### New table: `scheduled_visits`

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer PK | Auto-generated |
| `pregnancy_id` | Integer FK | References `pregnancies.id` |
| `visit_number` | Integer | 1 through 8 |
| `gestational_week` | Integer | Target gestational week (8, 16, 20, 26, 30, 34, 36, 38) |
| `scheduled_date` | String YYYY-MM-DD | Calculated visit date |
| `original_date` | String YYYY-MM-DD | Set if rescheduled, preserves original for audit |
| `status` | String | `scheduled`, `completed`, `missed`, `rescheduled`, `cancelled` |
| `anc_visit_id` | Integer FK | References `anc_visits.id` when completed |
| `reminder_48h_sent` | Boolean | Whether 48-hour reminder was sent |
| `reminder_48h_sent_at` | DateTime | When 48-hour reminder was sent |
| `reminder_day_sent` | Boolean | Whether same-day reminder was sent |
| `reminder_day_sent_at` | DateTime | When same-day reminder was sent |
| `whatsapp_delivered_48h` | Boolean | Whether WhatsApp confirmed delivery for 48h reminder |
| `whatsapp_delivered_day` | Boolean | Whether WhatsApp confirmed delivery for day reminder |
| `notes` | String | CHW notes on this visit slot |
| `created_at` | DateTime | When the scheduled visit was created |

### Entity relationship

```
pregnancies
  │ id
  │ patient_id → patients.id
  │ lmp_date
  │ edd_date
  └── scheduled_visits (8 records per pregnancy, created automatically)
        │ pregnancy_id → pregnancies.id
        │ visit_number (1–8)
        │ gestational_week
        │ scheduled_date (auto-calculated from LMP)
        │ status: scheduled | completed | missed | rescheduled | cancelled
        └── anc_visit_id → anc_visits.id (set when CHW records visit)

patients
  │ id
  │ phone ← WhatsApp number for reminders
  └── (via pregnancies → scheduled_visits)

users (CHW)
  │ id
  │ whatsapp_number ← CHW receives daily patient list here
  └── (via patients.chw_id)
```

### Visit schedule constants

```python
# Gestational weeks for each WHO visit
VISIT_SCHEDULE = [
    {"visit_number": 1, "gestational_week": 8,  "label": "Booking visit"},
    {"visit_number": 2, "gestational_week": 16, "label": "Second trimester check"},
    {"visit_number": 3, "gestational_week": 20, "label": "Anomaly screen"},
    {"visit_number": 4, "gestational_week": 26, "label": "Glucose screening"},
    {"visit_number": 5, "gestational_week": 30, "label": "Birth plan begins"},
    {"visit_number": 6, "gestational_week": 34, "label": "Presentation check"},
    {"visit_number": 7, "gestational_week": 36, "label": "Final preparation"},
    {"visit_number": 8, "gestational_week": 38, "label": "Pre-labour review"},
]
```

---

## 6. WhatsApp Notification Strategy

### Why WhatsApp over SMS

WhatsApp is the dominant messaging platform in Cameroon across all three networks (MTN, Orange, Nexttel). Unlike SMS:

- Messages are free to receive
- Rich formatting: bold text, emoji, structured layout
- Delivery receipts (double tick → blue tick)
- Works on basic Android smartphones which are now near-universal
- Patients are already familiar with the interface

Baileys provides a WhatsApp Web client in Node.js — the same approach used by OpenClaw and Hermes. It connects via WhatsApp Web protocol, authenticates with a QR scan once, and maintains a persistent session.

### Three notification types

**Type 1 — 48-hour patient reminder**

Sent to the patient's phone 48 hours before a scheduled visit.

```
🤱 *MamaSafe — Rappel de visite prénatale*

Bonjour [Nom de la patiente],

Votre prochaine visite prénatale est prévue pour :

📅 *[Date de la visite]*
🏥 *[Nom du centre de santé]*
👩‍⚕️ *Agent de santé : [Nom de l'agent]*

Il s'agit de votre *visite n°[N] — [Label de la visite]*.

📋 *À apporter :*
• Carnet de santé maternelle
• Résultats d'analyses précédents
• Pièce d'identité

En cas d'empêchement, contactez votre agent de santé au :
📞 [Numéro de l'agent]

_MamaSafe vous accompagne tout au long de votre grossesse._
```

**Type 2 — Same-day patient reminder**

Sent at 06:00 on the day of the visit.

```
🔔 *MamaSafe — Visite aujourd'hui*

Bonjour [Nom],

Votre visite prénatale est *aujourd'hui* !

🏥 [Centre de santé]
⏰ Venez dès que possible dans la journée

N'oubliez pas votre carnet de santé 📋

_Bonne santé à vous et votre bébé_ 👶
```

**Type 3 — CHW daily patient list**

Sent to the CHW at 07:00 every morning.

```
📋 *MamaSafe — Patients du jour*
[Jour, Date]

Vous avez *[N] visite(s) prénatale(s)* prévue(s) aujourd'hui :

1. 👤 [Nom patient 1] — Visite n°[X] ([Label])
   📞 [Numéro]
   
2. 👤 [Nom patient 2] — Visite n°[X] ([Label])
   📞 [Numéro]

Bonne journée sur le terrain ! 💪
_MamaSafe_
```

**Type 4 — Missed visit alert (to CHW)**

Sent to the CHW at 18:00 if a patient did not attend.

```
⚠️ *MamaSafe — Visites manquées*

[N] patient(s) n'ont pas effectué leur visite aujourd'hui :

• [Nom patient 1] — Visite n°[X]
  📞 [Numéro] — Veuillez la contacter

• [Nom patient 2] — Visite n°[X]
  📞 [Numéro] — Veuillez la contacter

Ces visites sont marquées comme *manquées* dans MamaSafe.
Vous pouvez les reprogrammer depuis l'application.
```

### Language strategy

Messages are sent in the patient's preferred language. When registering a patient, the CHW selects their language preference: French or English. The WhatsApp message templates exist in both languages. Cameroon's bilingual context makes this essential — a patient in Buea receives English messages, a patient in Bafoussam receives French.

---

## 7. API Reference

### Base URL
```
http://localhost:8000/api/v1
```

All endpoints require JWT authentication.

---

### `GET /schedule/{pregnancy_id}`

Get the full 8-visit schedule for a pregnancy.

**Response:**
```json
[
  {
    "id": 1,
    "pregnancy_id": 1,
    "visit_number": 1,
    "gestational_week": 8,
    "label": "Booking visit",
    "scheduled_date": "2025-03-07",
    "original_date": null,
    "status": "completed",
    "anc_visit_id": 3,
    "reminder_48h_sent": true,
    "reminder_day_sent": true,
    "created_at": "2025-01-10T08:00:00"
  },
  {
    "id": 2,
    "pregnancy_id": 1,
    "visit_number": 2,
    "gestational_week": 16,
    "scheduled_date": "2025-05-02",
    "status": "scheduled",
    "reminder_48h_sent": false,
    "reminder_day_sent": false
  }
]
```

---

### `PATCH /schedule/{scheduled_visit_id}/reschedule`

Reschedule a visit to a new date.

**Request body:**
```json
{
  "new_date": "2025-05-09",
  "reason": "Patient travelling"
}
```

**Response:** Updated `ScheduledVisitOut`

**Side effects:**
- Saves original date in `original_date` field
- Resets `reminder_48h_sent = false`
- Sends WhatsApp to patient confirming new date

---

### `PATCH /schedule/{scheduled_visit_id}/complete`

Mark a scheduled visit as completed when the CHW records the ANC visit.

**Request body:**
```json
{
  "anc_visit_id": 5
}
```

**Response:** Updated `ScheduledVisitOut` with `status: "completed"`

---

### `PATCH /schedule/{scheduled_visit_id}/cancel`

Cancel a specific scheduled visit.

**Request body:**
```json
{
  "reason": "Patient moved out of area"
}
```

---

### `GET /schedule/today`

Get all visits scheduled for today across all of the CHW's patients.

**Response:** Array of visits with embedded patient name and phone.

---

### `GET /schedule/upcoming`

Get the next 7 days of scheduled visits for the CHW's patients.

**Query params:**
- `days` (optional, default 7) — lookahead window

---

### `POST /schedule/send-reminder/{scheduled_visit_id}`

Manually trigger a WhatsApp reminder for a specific visit. Used for testing and for cases where the automated reminder failed.

---

### `GET /schedule/analytics`

Summary statistics for the CHW's visit schedule.

**Response:**
```json
{
  "total_scheduled": 48,
  "completed": 23,
  "missed": 4,
  "upcoming_this_week": 6,
  "completion_rate": 47.9,
  "missed_rate": 8.3
}
```

---

## 8. Backend Implementation

### File structure additions

```
backend/
  app/
    database.py           ← Add ScheduledVisit model
    schemas_schedule.py   ← Pydantic schemas for schedule module
    utils/
      scheduler_jobs.py   ← APScheduler job functions
      whatsapp.py         ← Baileys HTTP client (replaces SMS)
    routers/
      schedule.py         ← All schedule endpoints
    main.py               ← Register scheduler and router
  requirements.txt        ← Add apscheduler, httpx
```

### Step 1 — Add `ScheduledVisit` model to `database.py`

Add this class after the `ANCVisit` model:

```python
class ScheduledVisit(Base):
    __tablename__ = "scheduled_visits"

    id                     = Column(Integer, primary_key=True, index=True)
    pregnancy_id           = Column(Integer, ForeignKey("pregnancies.id"),
                                    nullable=False)
    visit_number           = Column(Integer, nullable=False)
    gestational_week       = Column(Integer, nullable=False)
    label                  = Column(String, nullable=True)
    scheduled_date         = Column(String, nullable=False)   # YYYY-MM-DD
    original_date          = Column(String, nullable=True)    # set if rescheduled
    reschedule_reason      = Column(String, nullable=True)
    status                 = Column(String, default="scheduled")
    # scheduled | completed | missed | rescheduled | cancelled
    anc_visit_id           = Column(Integer, ForeignKey("anc_visits.id"),
                                    nullable=True)
    reminder_48h_sent      = Column(Boolean, default=False)
    reminder_48h_sent_at   = Column(DateTime, nullable=True)
    reminder_day_sent      = Column(Boolean, default=False)
    reminder_day_sent_at   = Column(DateTime, nullable=True)
    whatsapp_delivered_48h = Column(Boolean, default=False)
    whatsapp_delivered_day = Column(Boolean, default=False)
    notes                  = Column(String, nullable=True)
    created_at             = Column(DateTime, default=datetime.utcnow)

    pregnancy              = relationship("Pregnancy",
                                          back_populates="scheduled_visits")
```

Also add the back-reference to the `Pregnancy` model:

```python
# Inside Pregnancy class, after anc_visits relationship:
scheduled_visits = relationship("ScheduledVisit",
                                back_populates="pregnancy",
                                cascade="all, delete-orphan",
                                order_by="ScheduledVisit.visit_number")
```

### Step 2 — Install new dependencies

Add to `requirements.txt`:

```
apscheduler==3.10.4
httpx==0.27.0
```

Install:

```bash
pip install apscheduler==3.10.4 httpx==0.27.0
```

### Step 3 — WhatsApp utility (`utils/whatsapp.py`)

This replaces the Africa's Talking SMS utility. It makes HTTP calls to your Baileys microservice:

```python
import httpx
import os
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

BAILEYS_URL = os.getenv("BAILEYS_URL", "http://localhost:3001")
BAILEYS_TOKEN = os.getenv("BAILEYS_TOKEN", "")


async def send_whatsapp(phone: str, message: str) -> dict:
    """
    Send a WhatsApp message via the Baileys microservice.
    Phone must be in international format: +237XXXXXXXXX
    Returns dict with success bool and message_id.
    """
    # Normalise phone: Baileys expects format like 237XXXXXXXXX@s.whatsapp.net
    clean_phone = phone.replace("+", "").replace(" ", "").replace("-", "")
    jid = f"{clean_phone}@s.whatsapp.net"

    headers = {"Authorization": f"Bearer {BAILEYS_TOKEN}"}
    payload = {"jid": jid, "message": message}

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{BAILEYS_URL}/send-message",
                json=payload,
                headers=headers
            )
            if response.status_code == 200:
                data = response.json()
                return {
                    "success": True,
                    "message_id": data.get("messageId", ""),
                    "status": "sent"
                }
            return {
                "success": False,
                "message_id": "",
                "status": f"HTTP {response.status_code}"
            }
    except httpx.TimeoutException:
        return {"success": False, "message_id": "", "status": "timeout"}
    except Exception as e:
        return {"success": False, "message_id": "", "status": str(e)}


def build_48h_reminder(patient_name: str, visit_number: int,
                        visit_label: str, visit_date: str,
                        facility: str, chw_name: str,
                        chw_phone: str, lang: str = "fr") -> str:
    """Build the 48-hour reminder WhatsApp message."""
    if lang == "en":
        return (
            f"🤱 *MamaSafe — Antenatal Visit Reminder*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your next antenatal visit is scheduled for:\n\n"
            f"📅 *{visit_date}*\n"
            f"🏥 *{facility}*\n"
            f"👩‍⚕️ *CHW: {chw_name}*\n\n"
            f"This is your *Visit {visit_number} — {visit_label}*.\n\n"
            f"📋 *Please bring:*\n"
            f"• Maternal health booklet\n"
            f"• Previous test results\n"
            f"• Identity document\n\n"
            f"If you cannot attend, please contact your CHW:\n"
            f"📞 {chw_phone}\n\n"
            f"_MamaSafe supports you throughout your pregnancy._"
        )
    return (
        f"🤱 *MamaSafe — Rappel de visite prénatale*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre prochaine visite prénatale est prévue pour :\n\n"
        f"📅 *{visit_date}*\n"
        f"🏥 *{facility}*\n"
        f"👩‍⚕️ *Agent de santé : {chw_name}*\n\n"
        f"Il s'agit de votre *visite n°{visit_number} — {visit_label}*.\n\n"
        f"📋 *À apporter :*\n"
        f"• Carnet de santé maternelle\n"
        f"• Résultats d'analyses précédents\n"
        f"• Pièce d'identité\n\n"
        f"En cas d'empêchement, contactez votre agent de santé :\n"
        f"📞 {chw_phone}\n\n"
        f"_MamaSafe vous accompagne tout au long de votre grossesse._"
    )


def build_day_reminder(patient_name: str, visit_number: int,
                       facility: str, lang: str = "fr") -> str:
    """Build the same-day reminder message."""
    if lang == "en":
        return (
            f"🔔 *MamaSafe — Visit Today*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your antenatal visit is *today* — Visit {visit_number}!\n\n"
            f"🏥 {facility}\n"
            f"⏰ Please come as early as possible today.\n\n"
            f"Don't forget your health booklet 📋\n\n"
            f"_Wishing you and your baby good health_ 👶"
        )
    return (
        f"🔔 *MamaSafe — Visite aujourd'hui*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre visite prénatale est *aujourd'hui* — Visite n°{visit_number} !\n\n"
        f"🏥 {facility}\n"
        f"⏰ Venez dès que possible dans la journée.\n\n"
        f"N'oubliez pas votre carnet de santé 📋\n\n"
        f"_Bonne santé à vous et votre bébé_ 👶"
    )


def build_chw_daily_list(chw_name: str,
                          visits: list, date_str: str) -> str:
    """Build the CHW morning patient list message."""
    if not visits:
        return (
            f"📋 *MamaSafe — Patients du jour*\n"
            f"{date_str}\n\n"
            f"Bonjour {chw_name},\n\n"
            f"Aucune visite prénatale prévue aujourd'hui. ✅\n\n"
            f"_Bonne journée !_"
        )
    lines = "\n\n".join([
        f"{i+1}. 👤 *{v['patient_name']}* — Visite n°{v['visit_number']} "
        f"({v['label']})\n   📞 {v['patient_phone'] or 'Pas de numéro'}"
        for i, v in enumerate(visits)
    ])
    return (
        f"📋 *MamaSafe — Patients du jour*\n"
        f"{date_str}\n\n"
        f"Bonjour {chw_name},\n\n"
        f"Vous avez *{len(visits)} visite(s) prénatale(s)* prévue(s) "
        f"aujourd'hui :\n\n"
        f"{lines}\n\n"
        f"Bonne journée sur le terrain ! 💪\n_MamaSafe_"
    )


def build_missed_visit_alert(chw_name: str,
                              missed: list, date_str: str) -> str:
    """Build the missed visit alert for CHW."""
    lines = "\n\n".join([
        f"• *{v['patient_name']}* — Visite n°{v['visit_number']}\n"
        f"  📞 {v['patient_phone'] or 'Pas de numéro'} — Veuillez la contacter"
        for v in missed
    ])
    return (
        f"⚠️ *MamaSafe — Visites manquées*\n"
        f"{date_str}\n\n"
        f"Bonjour {chw_name},\n\n"
        f"*{len(missed)} patient(s)* n'ont pas effectué leur visite "
        f"aujourd'hui :\n\n"
        f"{lines}\n\n"
        f"Ces visites sont marquées comme *manquées* dans MamaSafe.\n"
        f"Vous pouvez les reprogrammer depuis l'application."
    )


def build_reschedule_confirmation(patient_name: str,
                                   visit_number: int,
                                   new_date: str,
                                   facility: str,
                                   lang: str = "fr") -> str:
    """Confirm rescheduled visit to patient."""
    if lang == "en":
        return (
            f"📅 *MamaSafe — Visit Rescheduled*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your Visit {visit_number} has been rescheduled to:\n\n"
            f"📅 *{new_date}*\n"
            f"🏥 {facility}\n\n"
            f"Please save this new date. 📋\n\n"
            f"_MamaSafe_"
        )
    return (
        f"📅 *MamaSafe — Visite reprogrammée*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre visite n°{visit_number} a été reprogrammée au :\n\n"
        f"📅 *{new_date}*\n"
        f"🏥 {facility}\n\n"
        f"Veuillez noter cette nouvelle date. 📋\n\n"
        f"_MamaSafe_"
    )
```

### Step 4 — Scheduler jobs (`utils/scheduler_jobs.py`)

```python
from datetime import date, timedelta
from sqlalchemy.orm import Session
from app.database import SessionLocal, ScheduledVisit, Patient, Pregnancy, User
from app.utils.whatsapp import (
    send_whatsapp, build_48h_reminder, build_day_reminder,
    build_chw_daily_list, build_missed_visit_alert
)
import asyncio
import logging

logger = logging.getLogger("mamasafe.scheduler")

VISIT_LABELS = {
    1: "Booking visit",      2: "Second trimester check",
    3: "Anomaly screen",     4: "Glucose screening",
    5: "Birth plan begins",  6: "Presentation check",
    7: "Final preparation",  8: "Pre-labour review",
}


def get_db_session() -> Session:
    db = SessionLocal()
    try:
        return db
    except Exception:
        db.close()
        raise


def run_async(coro):
    """Run async function from sync APScheduler context."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


def job_send_48h_reminders():
    """
    Runs daily at 07:00.
    Sends 48-hour advance WhatsApp reminders to patients
    whose visit is in 2 days.
    """
    logger.info("Running 48h reminder job...")
    db = get_db_session()
    try:
        target_date = str(date.today() + timedelta(days=2))
        visits = (db.query(ScheduledVisit)
                    .filter(ScheduledVisit.scheduled_date == target_date,
                            ScheduledVisit.status == "scheduled",
                            ScheduledVisit.reminder_48h_sent == False)
                    .all())

        logger.info(f"Found {len(visits)} visits for {target_date}")

        for visit in visits:
            pregnancy = db.query(Pregnancy).filter(
                Pregnancy.id == visit.pregnancy_id).first()
            if not pregnancy:
                continue

            patient = db.query(Patient).filter(
                Patient.id == pregnancy.patient_id).first()
            if not patient or not patient.phone:
                logger.warning(f"Patient {pregnancy.patient_id} has no phone — skipping")
                continue

            chw = db.query(User).filter(
                User.id == patient.chw_id).first()

            message = build_48h_reminder(
                patient_name=patient.full_name,
                visit_number=visit.visit_number,
                visit_label=visit.label or VISIT_LABELS.get(visit.visit_number, ""),
                visit_date=visit.scheduled_date,
                facility=patient.facility or "Your health centre",
                chw_name=chw.full_name if chw else "Your CHW",
                chw_phone=getattr(chw, 'whatsapp_number', '') or "",
                lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
            )

            result = run_async(send_whatsapp(patient.phone, message))

            from datetime import datetime
            visit.reminder_48h_sent    = True
            visit.reminder_48h_sent_at = datetime.utcnow()
            visit.whatsapp_delivered_48h = result.get("success", False)
            db.commit()

            logger.info(
                f"48h reminder for patient {patient.full_name}: "
                f"{'sent' if result['success'] else 'failed'}"
            )

    except Exception as e:
        logger.error(f"48h reminder job failed: {e}")
    finally:
        db.close()


def job_send_day_reminders_and_chw_list():
    """
    Runs daily at 06:00.
    1. Sends same-day WhatsApp reminder to each patient with a visit today.
    2. Sends daily patient list to each CHW with visits today.
    """
    logger.info("Running day-of reminder and CHW list job...")
    db = get_db_session()
    try:
        today = str(date.today())
        visits = (db.query(ScheduledVisit)
                    .filter(ScheduledVisit.scheduled_date == today,
                            ScheduledVisit.status == "scheduled")
                    .all())

        logger.info(f"Found {len(visits)} visits today ({today})")

        # Build per-CHW patient lists
        chw_visit_map = {}

        for visit in visits:
            pregnancy = db.query(Pregnancy).filter(
                Pregnancy.id == visit.pregnancy_id).first()
            if not pregnancy:
                continue

            patient = db.query(Patient).filter(
                Patient.id == pregnancy.patient_id).first()
            if not patient:
                continue

            chw = db.query(User).filter(User.id == patient.chw_id).first()
            if not chw:
                continue

            # Collect visit info for CHW list
            if chw.id not in chw_visit_map:
                chw_visit_map[chw.id] = {"chw": chw, "visits": []}
            chw_visit_map[chw.id]["visits"].append({
                "patient_name":  patient.full_name,
                "patient_phone": patient.phone,
                "visit_number":  visit.visit_number,
                "label":         visit.label or VISIT_LABELS.get(visit.visit_number, ""),
            })

            # Send day-of reminder to patient
            if not visit.reminder_day_sent and patient.phone:
                message = build_day_reminder(
                    patient_name=patient.full_name,
                    visit_number=visit.visit_number,
                    facility=patient.facility or "Your health centre",
                    lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
                )
                result = run_async(send_whatsapp(patient.phone, message))
                from datetime import datetime
                visit.reminder_day_sent    = True
                visit.reminder_day_sent_at = datetime.utcnow()
                visit.whatsapp_delivered_day = result.get("success", False)
                db.commit()

        # Send CHW daily patient lists
        from datetime import datetime
        date_str = datetime.now().strftime("%A %d %B %Y")
        for chw_id, data in chw_visit_map.items():
            chw = data["chw"]
            chw_phone = getattr(chw, 'whatsapp_number', None)
            if not chw_phone:
                continue
            message = build_chw_daily_list(
                chw_name=chw.full_name or chw.username,
                visits=data["visits"],
                date_str=date_str,
            )
            run_async(send_whatsapp(chw_phone, message))
            logger.info(f"Sent daily list to CHW {chw.username}: {len(data['visits'])} visits")

    except Exception as e:
        logger.error(f"Day reminder job failed: {e}")
    finally:
        db.close()


def job_detect_missed_visits():
    """
    Runs daily at 18:00.
    Marks unattended visits as missed and alerts CHWs.
    """
    logger.info("Running missed visit detection job...")
    db = get_db_session()
    try:
        today = str(date.today())
        overdue = (db.query(ScheduledVisit)
                     .filter(ScheduledVisit.scheduled_date == today,
                             ScheduledVisit.status == "scheduled")
                     .all())

        logger.info(f"Found {len(overdue)} unattended visits for {today}")

        chw_missed_map = {}

        for visit in overdue:
            # Mark as missed
            visit.status = "missed"
            db.commit()

            pregnancy = db.query(Pregnancy).filter(
                Pregnancy.id == visit.pregnancy_id).first()
            if not pregnancy:
                continue

            patient = db.query(Patient).filter(
                Patient.id == pregnancy.patient_id).first()
            if not patient:
                continue

            chw = db.query(User).filter(User.id == patient.chw_id).first()
            if not chw:
                continue

            if chw.id not in chw_missed_map:
                chw_missed_map[chw.id] = {"chw": chw, "missed": []}
            chw_missed_map[chw.id]["missed"].append({
                "patient_name":  patient.full_name,
                "patient_phone": patient.phone,
                "visit_number":  visit.visit_number,
            })

        # Alert CHWs about missed visits
        from datetime import datetime
        date_str = datetime.now().strftime("%A %d %B %Y")
        for chw_id, data in chw_missed_map.items():
            chw = data["chw"]
            chw_phone = getattr(chw, 'whatsapp_number', None)
            if not chw_phone:
                continue
            message = build_missed_visit_alert(
                chw_name=chw.full_name or chw.username,
                missed=data["missed"],
                date_str=date_str,
            )
            run_async(send_whatsapp(chw_phone, message))
            logger.info(
                f"Sent missed visit alert to CHW {chw.username}: "
                f"{len(data['missed'])} missed"
            )

    except Exception as e:
        logger.error(f"Missed visit job failed: {e}")
    finally:
        db.close()
```

### Step 5 — Schedule router (`routers/schedule.py`)

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import date, timedelta, datetime

from app.database import (get_db, ScheduledVisit, Pregnancy,
                           Patient, User)
from app.schemas_schedule import (ScheduledVisitOut, RescheduleRequest,
                                   CompleteVisitRequest)
from app.routers.auth import get_current_user
from app.utils.whatsapp import (send_whatsapp,
                                 build_reschedule_confirmation)

router = APIRouter(prefix="/api/v1/schedule", tags=["schedule"])

VISIT_SCHEDULE = [
    {"visit_number": 1, "gestational_week": 8,  "label": "Booking visit"},
    {"visit_number": 2, "gestational_week": 16, "label": "Second trimester check"},
    {"visit_number": 3, "gestational_week": 20, "label": "Anomaly screen"},
    {"visit_number": 4, "gestational_week": 26, "label": "Glucose screening"},
    {"visit_number": 5, "gestational_week": 30, "label": "Birth plan begins"},
    {"visit_number": 6, "gestational_week": 34, "label": "Presentation check"},
    {"visit_number": 7, "gestational_week": 36, "label": "Final preparation"},
    {"visit_number": 8, "gestational_week": 38, "label": "Pre-labour review"},
]


def auto_schedule_visits(db: Session, pregnancy_id: int,
                          lmp_date_str: str):
    """
    Called automatically when a pregnancy is registered.
    Creates 8 ScheduledVisit records based on LMP date.
    """
    lmp = datetime.strptime(lmp_date_str, "%Y-%m-%d").date()
    for v in VISIT_SCHEDULE:
        visit_date = lmp + timedelta(weeks=v["gestational_week"])
        sv = ScheduledVisit(
            pregnancy_id    = pregnancy_id,
            visit_number    = v["visit_number"],
            gestational_week = v["gestational_week"],
            label           = v["label"],
            scheduled_date  = str(visit_date),
            status          = "scheduled",
        )
        db.add(sv)
    db.commit()


@router.get("/{pregnancy_id}", response_model=List[ScheduledVisitOut])
def get_schedule(
    pregnancy_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return (db.query(ScheduledVisit)
              .filter(ScheduledVisit.pregnancy_id == pregnancy_id)
              .order_by(ScheduledVisit.visit_number)
              .all())


@router.get("/today/list")
def get_todays_visits(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    today = str(date.today())
    visits = (db.query(ScheduledVisit)
                .filter(ScheduledVisit.scheduled_date == today,
                        ScheduledVisit.status == "scheduled")
                .all())
    result = []
    for v in visits:
        preg = db.query(Pregnancy).filter(
            Pregnancy.id == v.pregnancy_id).first()
        if not preg:
            continue
        patient = db.query(Patient).filter(
            Patient.id == preg.patient_id,
            Patient.chw_id == current_user.id).first()
        if not patient:
            continue
        result.append({
            "visit_id":      v.id,
            "visit_number":  v.visit_number,
            "label":         v.label,
            "patient_name":  patient.full_name,
            "patient_phone": patient.phone,
            "patient_id":    patient.id,
            "pregnancy_id":  v.pregnancy_id,
        })
    return result


@router.get("/upcoming/list")
def get_upcoming_visits(
    days: int = 7,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    today = date.today()
    end   = today + timedelta(days=days)
    visits = (db.query(ScheduledVisit)
                .filter(ScheduledVisit.scheduled_date >= str(today),
                        ScheduledVisit.scheduled_date <= str(end),
                        ScheduledVisit.status == "scheduled")
                .order_by(ScheduledVisit.scheduled_date)
                .all())
    result = []
    for v in visits:
        preg = db.query(Pregnancy).filter(
            Pregnancy.id == v.pregnancy_id).first()
        if not preg:
            continue
        patient = db.query(Patient).filter(
            Patient.id == preg.patient_id,
            Patient.chw_id == current_user.id).first()
        if not patient:
            continue
        result.append({
            "visit_id":      v.id,
            "visit_number":  v.visit_number,
            "label":         v.label,
            "scheduled_date": v.scheduled_date,
            "patient_name":  patient.full_name,
            "patient_id":    patient.id,
        })
    return result


@router.patch("/{visit_id}/reschedule",
              response_model=ScheduledVisitOut)
async def reschedule_visit(
    visit_id: int,
    data: RescheduleRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    # Save original date for audit
    if not visit.original_date:
        visit.original_date = visit.scheduled_date

    visit.scheduled_date     = data.new_date
    visit.status             = "rescheduled"
    visit.reschedule_reason  = data.reason
    visit.reminder_48h_sent  = False  # reset so reminder fires for new date
    visit.reminder_day_sent  = False
    db.commit()
    db.refresh(visit)

    # Notify patient of new date
    preg = db.query(Pregnancy).filter(
        Pregnancy.id == visit.pregnancy_id).first()
    if preg:
        patient = db.query(Patient).filter(
            Patient.id == preg.patient_id).first()
        if patient and patient.phone:
            message = build_reschedule_confirmation(
                patient_name=patient.full_name,
                visit_number=visit.visit_number,
                new_date=data.new_date,
                facility=patient.facility or "Your health centre",
                lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
            )
            await send_whatsapp(patient.phone, message)

    return visit


@router.patch("/{visit_id}/complete",
              response_model=ScheduledVisitOut)
def complete_visit(
    visit_id: int,
    data: CompleteVisitRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    visit.status      = "completed"
    visit.anc_visit_id = data.anc_visit_id
    db.commit()
    db.refresh(visit)
    return visit


@router.patch("/{visit_id}/cancel",
              response_model=ScheduledVisitOut)
def cancel_visit(
    visit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    visit.status = "cancelled"
    db.commit()
    db.refresh(visit)
    return visit


@router.post("/send-reminder/{visit_id}")
async def manual_reminder(
    visit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Manually trigger a WhatsApp reminder for a specific visit."""
    visit = db.query(ScheduledVisit).filter(
        ScheduledVisit.id == visit_id).first()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    preg = db.query(Pregnancy).filter(
        Pregnancy.id == visit.pregnancy_id).first()
    patient = db.query(Patient).filter(
        Patient.id == preg.patient_id).first() if preg else None
    chw = db.query(User).filter(
        User.id == patient.chw_id).first() if patient else None

    if not patient or not patient.phone:
        raise HTTPException(status_code=400,
                            detail="Patient has no phone number")

    from app.utils.whatsapp import build_48h_reminder
    message = build_48h_reminder(
        patient_name=patient.full_name,
        visit_number=visit.visit_number,
        visit_label=visit.label or "",
        visit_date=visit.scheduled_date,
        facility=patient.facility or "Your health centre",
        chw_name=chw.full_name if chw else "Your CHW",
        chw_phone=getattr(chw, 'whatsapp_number', '') or "",
        lang=getattr(patient, 'preferred_language', 'fr') or 'fr',
    )

    result = await send_whatsapp(patient.phone, message)
    return {"success": result["success"], "status": result["status"]}


@router.get("/analytics/summary")
def schedule_analytics(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Get all scheduled visits for this CHW's patients
    patient_ids = [
        p.id for p in db.query(Patient).filter(
            Patient.chw_id == current_user.id).all()
    ]
    pregnancy_ids = [
        pr.id for pr in db.query(Pregnancy).filter(
            Pregnancy.patient_id.in_(patient_ids)).all()
    ]
    q = db.query(ScheduledVisit).filter(
        ScheduledVisit.pregnancy_id.in_(pregnancy_ids))

    total     = q.count()
    completed = q.filter(ScheduledVisit.status == "completed").count()
    missed    = q.filter(ScheduledVisit.status == "missed").count()
    today     = str(date.today())
    end_week  = str(date.today() + timedelta(days=7))
    upcoming  = q.filter(ScheduledVisit.status == "scheduled",
                          ScheduledVisit.scheduled_date >= today,
                          ScheduledVisit.scheduled_date <= end_week).count()

    return {
        "total_scheduled":     total,
        "completed":           completed,
        "missed":              missed,
        "upcoming_this_week":  upcoming,
        "completion_rate":     round(completed / total * 100, 1) if total else 0,
        "missed_rate":         round(missed / total * 100, 1) if total else 0,
    }
```

### Step 6 — Schemas (`schemas_schedule.py`)

```python
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ScheduledVisitOut(BaseModel):
    id:                     int
    pregnancy_id:           int
    visit_number:           int
    gestational_week:       int
    label:                  Optional[str]
    scheduled_date:         str
    original_date:          Optional[str]
    reschedule_reason:      Optional[str]
    status:                 str
    anc_visit_id:           Optional[int]
    reminder_48h_sent:      bool
    reminder_day_sent:      bool
    whatsapp_delivered_48h: bool
    whatsapp_delivered_day: bool
    notes:                  Optional[str]
    created_at:             datetime

    class Config:
        from_attributes = True


class RescheduleRequest(BaseModel):
    new_date: str   # YYYY-MM-DD
    reason:   Optional[str] = None


class CompleteVisitRequest(BaseModel):
    anc_visit_id: int
```

### Step 7 — Register in `main.py`

```python
from app.routers import (predict, assessments, auth,
                          dashboard, anc, referral, schedule)
from app.utils.scheduler_jobs import (
    job_send_48h_reminders,
    job_send_day_reminders_and_chw_list,
    job_detect_missed_visits,
)
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

# Add router
app.include_router(schedule.router)

# Add APScheduler startup
@app.on_event("startup")
def startup():
    create_tables()

    # Start background scheduler
    scheduler = BackgroundScheduler(timezone="Africa/Douala")

    # 48-hour reminders: 07:00 daily
    scheduler.add_job(
        job_send_48h_reminders,
        CronTrigger(hour=7, minute=0),
        id="48h_reminders",
        replace_existing=True,
    )

    # Day-of reminders + CHW list: 06:00 daily
    scheduler.add_job(
        job_send_day_reminders_and_chw_list,
        CronTrigger(hour=6, minute=0),
        id="day_reminders",
        replace_existing=True,
    )

    # Missed visit detection: 18:00 daily
    scheduler.add_job(
        job_detect_missed_visits,
        CronTrigger(hour=18, minute=0),
        id="missed_visits",
        replace_existing=True,
    )

    scheduler.start()
    print("APScheduler started — 3 daily jobs registered")
```

### Step 8 — Hook auto-scheduling into pregnancy registration

In `routers/anc.py`, update the `register_pregnancy` endpoint to call `auto_schedule_visits`:

```python
from app.routers.schedule import auto_schedule_visits

@router.post("/pregnancies", response_model=PregnancyOut)
def register_pregnancy(
    data: PregnancyCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Deactivate existing active pregnancy
    (db.query(Pregnancy)
       .filter(Pregnancy.patient_id == data.patient_id,
               Pregnancy.is_active == True)
       .update({"is_active": False}))

    edd = calculate_edd(data.lmp_date)
    pregnancy = Pregnancy(**data.dict(), edd_date=edd)
    db.add(pregnancy)
    db.commit()
    db.refresh(pregnancy)

    # Auto-generate 8 scheduled visits — this is the key addition
    auto_schedule_visits(db, pregnancy.id, data.lmp_date)

    return pregnancy
```

### Step 9 — Add fields to User model

Add `whatsapp_number` to your existing `User` model in `database.py`:

```python
# Inside User class:
whatsapp_number = Column(String, nullable=True)
full_name       = Column(String, nullable=True)  # if not already present
```

Add `preferred_language` to your `Patient` model:

```python
# Inside Patient class:
preferred_language = Column(String, default="fr")  # "fr" or "en"
```

Run migration:

```bash
python -c "
from app.database import Base, engine
Base.metadata.create_all(bind=engine)
print('Migration complete')
"
```

---

## 9. APScheduler — Background Job Setup

### Why APScheduler

APScheduler is a pure Python library that runs scheduled jobs inside the same FastAPI process. For MamaSafe's needs — three jobs running once per day — it is the correct choice. It requires no separate Celery worker, no Redis broker, and no additional infrastructure.

### Timezone configuration

All jobs use `Africa/Douala` timezone (UTC+1, same as Cameroon). This ensures reminders fire at the correct local time regardless of where the server is hosted.

### Job summary

| Job ID | Trigger | Function | What it does |
|--------|---------|----------|-------------|
| `48h_reminders` | Daily 07:00 CAT | `job_send_48h_reminders` | Sends WhatsApp to patients with visits in 2 days |
| `day_reminders` | Daily 06:00 CAT | `job_send_day_reminders_and_chw_list` | Same-day patient reminder + CHW daily list |
| `missed_visits` | Daily 18:00 CAT | `job_detect_missed_visits` | Marks unattended visits missed, alerts CHW |

### Testing jobs manually

During development, trigger any job manually without waiting for the schedule:

```python
# In a Python shell inside your venv:
from app.utils.scheduler_jobs import (
    job_send_48h_reminders,
    job_send_day_reminders_and_chw_list,
    job_detect_missed_visits,
)

# Test each job:
job_send_48h_reminders()
job_send_day_reminders_and_chw_list()
job_detect_missed_visits()
```

Or add a test endpoint to your router:

```python
# In routers/schedule.py — dev only, remove before production
@router.post("/test/run-jobs")
def run_jobs_manually(current_user = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    from app.utils.scheduler_jobs import (
        job_send_48h_reminders,
        job_send_day_reminders_and_chw_list,
        job_detect_missed_visits
    )
    job_send_48h_reminders()
    job_send_day_reminders_and_chw_list()
    job_detect_missed_visits()
    return {"message": "All jobs executed"}
```

---

## 10. WhatsApp Message Templates

All message template functions live in `utils/whatsapp.py`. They are pure Python functions that accept parameters and return a formatted string. They support both French and English via the `lang` parameter.

### Design principles

**Use WhatsApp markdown** — `*bold*`, `_italic_` render natively in WhatsApp. Use them for emphasis on critical information like dates and risk levels.

**Emoji as visual anchors** — 📅 for dates, 🏥 for facilities, 📞 for phone numbers, ⚠️ for warnings. Health workers scan messages quickly — emoji make key information findable.

**Short and scannable** — Messages should be readable in under 10 seconds. No paragraphs. Use line breaks generously.

**Always sign with MamaSafe** — Every message ends with `_MamaSafe_` so the recipient knows the source.

### Testing templates

Before connecting to Baileys, test templates directly:

```python
from app.utils.whatsapp import build_48h_reminder

msg = build_48h_reminder(
    patient_name="Marie Ngono",
    visit_number=2,
    visit_label="Second trimester check",
    visit_date="2025-07-16",
    facility="Centre de Santé de Melen",
    chw_name="Pauline Mba",
    chw_phone="+237677123456",
    lang="fr"
)
print(msg)
```

Paste the output into WhatsApp on your own phone (via Baileys) to verify formatting before deploying.

---

## 11. Web Frontend Implementation

### New pages and components

| Component / Page | Description |
|-----------------|-------------|
| `VisitSchedule.jsx` | Component showing the 8-visit timeline on patient profile |
| `ScheduleCalendar.jsx` | Week view showing upcoming visits across all patients |
| `RescheduleModal.jsx` | Date picker modal for rescheduling a visit |
| `ScheduleDashboard.jsx` | CHW analytics: completion rate, upcoming visits this week |

### Visit schedule component (`VisitSchedule.jsx`)

```jsx
import { useEffect, useState } from 'react';
import { getSchedule, rescheduleVisit, completeVisit } from '../api/client';

const STATUS_STYLES = {
  scheduled:   { dot: 'bg-indigo-500', label: 'Scheduled',   text: 'text-indigo-600', bg: 'bg-indigo-50' },
  completed:   { dot: 'bg-green-500',  label: 'Completed',   text: 'text-green-600',  bg: 'bg-green-50'  },
  missed:      { dot: 'bg-red-500',    label: 'Missed',      text: 'text-red-600',    bg: 'bg-red-50'    },
  rescheduled: { dot: 'bg-amber-500',  label: 'Rescheduled', text: 'text-amber-600',  bg: 'bg-amber-50'  },
  cancelled:   { dot: 'bg-gray-400',   label: 'Cancelled',   text: 'text-gray-500',   bg: 'bg-gray-50'   },
};

export default function VisitSchedule({ pregnancyId }) {
  const [visits, setVisits] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getSchedule(pregnancyId).then(setVisits).finally(() => setLoading(false));
  }, [pregnancyId]);

  if (loading) return <div className="text-gray-400 text-sm py-4">Loading schedule...</div>;

  const completed = visits.filter(v => v.status === 'completed').length;
  const pct = visits.length > 0 ? Math.round((completed / visits.length) * 100) : 0;

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-bold text-gray-800">ANC Visit Schedule</h3>
        <span className="text-sm text-gray-500">{completed}/{visits.length} completed</span>
      </div>

      {/* Progress bar */}
      <div className="h-2 bg-gray-100 rounded-full overflow-hidden mb-5">
        <div
          className="h-full bg-indigo-500 rounded-full transition-all"
          style={{ width: `${pct}%` }}
        />
      </div>

      {/* Visit timeline */}
      <div className="space-y-2">
        {visits.map((visit, i) => {
          const sc = STATUS_STYLES[visit.status] || STATUS_STYLES.scheduled;
          const isToday = visit.scheduled_date === new Date().toISOString().split('T')[0];
          return (
            <div
              key={visit.id}
              className={`flex items-center gap-3 p-3 rounded-xl border
                          ${sc.bg} ${isToday ? 'ring-2 ring-indigo-400' : 'border-transparent'}`}
            >
              {/* Visit number bubble */}
              <div className={`w-7 h-7 rounded-full flex items-center
                               justify-content-center text-xs font-bold
                               text-white flex-shrink-0 ${sc.dot.replace('bg-', 'bg-')}
                               flex items-center justify-center`}
                   style={{ background: sc.dot.includes('indigo') ? '#6366F1'
                            : sc.dot.includes('green') ? '#22C55E'
                            : sc.dot.includes('red') ? '#EF4444'
                            : sc.dot.includes('amber') ? '#F59E0B' : '#9CA3AF' }}>
                {visit.visit_number}
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <p className="text-sm font-medium text-gray-800 truncate">
                    {visit.label}
                  </p>
                  {isToday && (
                    <span className="text-xs bg-indigo-600 text-white
                                     px-2 py-0.5 rounded-full">Today</span>
                  )}
                </div>
                <p className="text-xs text-gray-500 mt-0.5">
                  {new Date(visit.scheduled_date).toLocaleDateString('en-GB', {
                    day: 'numeric', month: 'short', year: 'numeric'
                  })}
                  {visit.original_date && (
                    <span className="ml-2 line-through text-gray-300">
                      {new Date(visit.original_date).toLocaleDateString('en-GB', {
                        day: 'numeric', month: 'short'
                      })}
                    </span>
                  )}
                </p>
              </div>

              <span className={`text-xs font-semibold ${sc.text}`}>
                {sc.label}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

### API client additions

Add these to `api/client.js`:

```javascript
// Schedule
export const getSchedule = async (pregnancyId) => {
  const res = await client.get(`/api/v1/schedule/${pregnancyId}`);
  return res.data;
};

export const rescheduleVisit = async (visitId, newDate, reason) => {
  const res = await client.patch(`/api/v1/schedule/${visitId}/reschedule`,
    { new_date: newDate, reason });
  return res.data;
};

export const completeScheduledVisit = async (visitId, ancVisitId) => {
  const res = await client.patch(`/api/v1/schedule/${visitId}/complete`,
    { anc_visit_id: ancVisitId });
  return res.data;
};

export const getTodaysVisits = async () => {
  const res = await client.get('/api/v1/schedule/today/list');
  return res.data;
};

export const getUpcomingVisits = async (days = 7) => {
  const res = await client.get(`/api/v1/schedule/upcoming/list?days=${days}`);
  return res.data;
};

export const getScheduleAnalytics = async () => {
  const res = await client.get('/api/v1/schedule/analytics/summary');
  return res.data;
};

export const manualReminder = async (visitId) => {
  const res = await client.post(`/api/v1/schedule/send-reminder/${visitId}`);
  return res.data;
};
```

---

## 12. Mobile Frontend Implementation (Expo)

### New screens

```
src/screens/
  ScheduleScreen.js        ← Patient visit schedule (opened from patient profile)
  UpcomingVisitsScreen.js  ← CHW view: all upcoming visits this week
```

### Schedule screen (`ScheduleScreen.js`)

```jsx
import React, { useState, useEffect } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  StyleSheet, Alert
} from 'react-native';
import { COLORS, FONT, RADIUS } from '../utils/theme';
import { getSchedule, rescheduleVisit } from '../utils/api';

const STATUS_COLORS = {
  scheduled:   COLORS.primary,
  completed:   COLORS.success,
  missed:      COLORS.danger,
  rescheduled: COLORS.warning,
  cancelled:   COLORS.textDim,
};

export default function ScheduleScreen({ route, navigation }) {
  const { pregnancyId, patientName } = route.params;
  const [visits, setVisits] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getSchedule(pregnancyId)
      .then(setVisits)
      .finally(() => setLoading(false));
  }, [pregnancyId]);

  const completed = visits.filter(v => v.status === 'completed').length;

  return (
    <ScrollView style={s.root} contentContainerStyle={s.scroll}>
      <Text style={s.title}>{patientName}</Text>
      <Text style={s.subtitle}>ANC Visit Schedule</Text>

      {/* Progress */}
      <View style={s.progressCard}>
        <View style={s.progressRow}>
          <Text style={s.progressLabel}>Progress</Text>
          <Text style={s.progressCount}>{completed}/{visits.length}</Text>
        </View>
        <View style={s.progressBar}>
          <View style={[s.progressFill, {
            width: visits.length > 0
              ? `${Math.round(completed/visits.length*100)}%`
              : '0%'
          }]} />
        </View>
      </View>

      {/* Visit list */}
      {visits.map(visit => {
        const color = STATUS_COLORS[visit.status] || COLORS.primary;
        const isToday = visit.scheduled_date ===
          new Date().toISOString().split('T')[0];
        return (
          <View key={visit.id}
                style={[s.visitCard, isToday && s.visitCardToday]}>
            <View style={[s.numBubble, { backgroundColor: color }]}>
              <Text style={s.numText}>{visit.visit_number}</Text>
            </View>
            <View style={s.visitInfo}>
              <Text style={s.visitLabel}>{visit.label}</Text>
              <Text style={s.visitDate}>
                {new Date(visit.scheduled_date).toLocaleDateString('fr-FR', {
                  day: 'numeric', month: 'long', year: 'numeric'
                })}
              </Text>
              <Text style={[s.visitStatus, { color }]}>
                {visit.status.charAt(0).toUpperCase() + visit.status.slice(1)}
              </Text>
            </View>
            {visit.status === 'scheduled' && (
              <TouchableOpacity
                style={s.rescheduleBtn}
                onPress={() => navigation.navigate('RescheduleVisit', {
                  visitId: visit.id,
                  visitNumber: visit.visit_number,
                  patientName,
                })}
              >
                <Text style={s.rescheduleBtnText}>📅</Text>
              </TouchableOpacity>
            )}
          </View>
        );
      })}

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const s = StyleSheet.create({
  root:            { flex: 1, backgroundColor: COLORS.bg },
  scroll:          { padding: 16 },
  title:           { fontSize: FONT.xl, fontWeight: '700', color: COLORS.text },
  subtitle:        { fontSize: FONT.sm, color: COLORS.textMuted, marginBottom: 16 },
  progressCard:    { backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: 14, marginBottom: 16 },
  progressRow:     { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
  progressLabel:   { fontSize: FONT.sm, color: COLORS.textMuted },
  progressCount:   { fontSize: FONT.sm, fontWeight: '700', color: COLORS.text },
  progressBar:     { height: 6, backgroundColor: COLORS.surface2, borderRadius: 3, overflow: 'hidden' },
  progressFill:    { height: '100%', backgroundColor: COLORS.primary, borderRadius: 3 },
  visitCard:       { backgroundColor: COLORS.surface, borderRadius: RADIUS.md, padding: 12, marginBottom: 8, flexDirection: 'row', alignItems: 'center', gap: 12 },
  visitCardToday:  { borderWidth: 2, borderColor: COLORS.primary },
  numBubble:       { width: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center', flexShrink: 0 },
  numText:         { fontSize: FONT.xs, fontWeight: '700', color: '#fff' },
  visitInfo:       { flex: 1 },
  visitLabel:      { fontSize: FONT.sm, fontWeight: '500', color: COLORS.text },
  visitDate:       { fontSize: FONT.xs, color: COLORS.textMuted, marginTop: 2 },
  visitStatus:     { fontSize: FONT.xs, fontWeight: '500', marginTop: 2 },
  rescheduleBtn:   { padding: 8 },
  rescheduleBtnText: { fontSize: 18 },
});
```

---

## 13. Testing Guide

### Postman test sequence

```
1. POST /api/v1/pregnancies    → auto-creates 8 scheduled visits
2. GET  /api/v1/schedule/{pregnancy_id}   → verify 8 visits with correct dates
3. GET  /api/v1/schedule/upcoming/list    → see upcoming visits
4. PATCH /api/v1/schedule/{visit_id}/reschedule  → change visit 1 date
5. GET  /api/v1/schedule/{pregnancy_id}   → verify original_date preserved
6. POST /api/v1/schedule/send-reminder/{visit_id}  → manual WhatsApp trigger
7. PATCH /api/v1/schedule/{visit_id}/complete { "anc_visit_id": 1 }
8. GET  /api/v1/schedule/analytics/summary → verify completion_rate updates
9. POST /api/v1/schedule/test/run-jobs    → trigger all 3 scheduler jobs
```

### Test cases for Appendix A

| ID | Description | Expected result |
|----|-------------|----------------|
| SCH-01 | Register pregnancy — verify auto-scheduling | 8 `ScheduledVisit` records created with correct dates |
| SCH-02 | Visit 1 date = LMP + 8 weeks | Date matches calculation |
| SCH-03 | Visit 8 date = LMP + 38 weeks | Date matches calculation |
| SCH-04 | Reschedule visit 2 | `original_date` preserved, `reminder_48h_sent` reset to false |
| SCH-05 | Reschedule confirmation WhatsApp sent | Baileys microservice called, patient phone receives message |
| SCH-06 | Manual reminder trigger | WhatsApp delivered to patient phone (sandbox) |
| SCH-07 | Mark visit as complete | Status `completed`, `anc_visit_id` linked |
| SCH-08 | Run 48h reminder job | All visits in 2 days get reminder, `reminder_48h_sent` = true |
| SCH-09 | Run missed visit job | Unattended visits marked `missed`, CHW alerted |
| SCH-10 | Analytics summary after 2 completed, 1 missed | Correct rates returned |
| SCH-11 | French message template | Message contains French text |
| SCH-12 | English message template | Message contains English text |

---

## 14. Report Integration

### Section 1.2 — Statement of the Problem (add bullet)

> The absence of a structured antenatal visit reminder system means that women who attend their first visit frequently do not return for subsequent contacts, with no mechanism to follow up between visits. Cameroon's WHO-recommended 8-contact ANC model cannot be effectively implemented without automated scheduling and reminder infrastructure.

### Section 1.4 — Research Objectives (add Specific Objective 8)

> To design and implement an ANC visit scheduling module that automatically generates the complete 8-visit WHO antenatal schedule upon pregnancy registration and delivers bilingual WhatsApp reminders to patients 48 hours and 2 hours before each scheduled visit, with daily patient lists sent to community health workers.

### Section 3.6 — Model Specification

Add `ScheduledVisit` to the data model description and `APScheduler` to the technology stack table. Add all schedule endpoints to Table 3.2.

### Section 4.2.5 — Extended System Discussion

> The ANC visit scheduler addresses Delay 1 of the Three Delays framework by removing the burden of visit tracking from both the patient and the CHW. Automated WhatsApp reminders in the patient's preferred language (French or English) ensure that upcoming visits are not forgotten, while the CHW daily list provides a structured morning briefing that enables proactive follow-up for non-attenders. The missed visit detection job converts a passive record system into an active safety net — unattended visits trigger same-day CHW alerts, enabling same-day follow-up rather than discovery at the next visit.

### Section 5.4 — Limitations (add)

> The ANC visit scheduler relies on patients having access to WhatsApp on a smartphone. While WhatsApp penetration in Cameroon is high among the age group most likely to be pregnant (18–35), women in the most resource-constrained settings — precisely those at highest clinical risk — may lack smartphone access. A USSD-based fallback for the reminder system is recommended as a future extension.

---

## 15. Future Extensions

| Feature | Description | Effort |
|---------|-------------|--------|
| USSD fallback reminders | Send visit reminders via USSD for patients without WhatsApp | Medium |
| Two-way WhatsApp | Patient can reply "CONFIRM" or "RESCHEDULE" and system processes response | Medium |
| Geofenced arrival detection | Detect when patient arrives at facility via phone GPS — auto-mark visit attended | High |
| Missed visit risk scoring | ML model predicting which patients are most likely to miss next visit | High |
| Multi-language support | Add Fulfulde, Ewondo, Bassa for patients who speak neither French nor English | Low |
| Visit preparation checklist | WhatsApp message 1 week before lists specific tests to prepare for that visit | Low |

---

*End of document.*

**MamaSafe ANC Visit Scheduler Documentation v1.0**  
*Prepared for the MamaSafe Final Year Project — YIBS Software Engineering*
