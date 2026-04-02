from datetime import datetime
import re
from fastapi import FastAPI, UploadFile, File, Header
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId
from database import patients_collection, doctors_collection, appointments_collection, reports_collection, preconsults_collection
from utils import hash_password, verify_password,create_token, ask_gemini, upload_report, verify_token
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Patient(BaseModel):
    name: str
    age: int
    gender: str
    email: str
    password: str

class LoginData(BaseModel):
    email: str
    password: str

class Doctor(BaseModel):
    name: str
    specialization: str
    email: str
    password: str

class Appointments(BaseModel):
    patient_email: str
    doctor_email: str
    date: str
    time: str
    reason: str

class ChatMessage(BaseModel):
    patient_email: str
    doctor_email: str
    appointment_id: str
    message: str
    conversation: list = []

class PreconsultRecord(BaseModel):
    patient_email: str
    conversation: list
    ai_response: str
    summary: str
    status: str = "in_progress"

class MedicationUpdate(BaseModel):
    medications: str
    timing: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None

class AppointmentAction(BaseModel):
    action: str
    date: Optional[str] = None
    time: Optional[str] = None

class DoctorScheduleAppointment(BaseModel):
    patient_email: str
    date: str
    time: str
    reason: str

class DepartmentReportStatusUpdate(BaseModel):
    status: str

def parse_appointment_datetime(date_value: str, time_value: str):
    if not date_value:
        return None
    for fmt in ["%Y-%m-%d %H:%M", "%Y-%m-%d %I:%M %p", "%Y-%m-%d"]:
        try:
            return datetime.strptime(f"{date_value} {time_value}".strip(), fmt)
        except ValueError:
            continue
    return None

def is_accepted_appointment(status_value: str):
    return str(status_value or "").lower() in ["accepted", "confirmed", "approved"]

def clean_ai_text(text: str):
    cleaned_lines = []
    for raw_line in str(text or "").splitlines():
        line = raw_line.strip()
        line = re.sub(r"^(?:AI|Assistant)\s*:\s*", "", line, flags=re.IGNORECASE)
        line = re.sub(r"\*\*(.*?)\*\*", r"\1", line)
        line = re.sub(r"^[-*+]\s+", "", line)
        if line:
            cleaned_lines.append(line)
    return "\n".join(cleaned_lines)

def extract_summary_value(summary_text: str, label: str):
    pattern = rf"(?im)^\s*{re.escape(label)}\s*:\s*(.+)$"
    match = re.search(pattern, str(summary_text or ""))
    return match.group(1).strip() if match else ""

def split_medication_items(medication_value: str):
    normalized = str(medication_value or "").strip()
    if not normalized or normalized.lower() in {"none", "n/a", "na", "not given", "not specified"}:
        return []

    normalized = normalized.replace(" and ", ", ")
    parts = [part.strip() for part in re.split(r"[,;/\n]", normalized) if part.strip()]
    return parts or [normalized]

def medication_status_from_appointment(status_value: str):
    normalized = str(status_value or "").lower()
    if normalized in {"accepted", "confirmed", "approved"}:
        return "active"
    if normalized == "completed":
        return "completed"
    if normalized in {"cancelled_by_patient", "cancelled_by_doctor", "declined", "rejected"}:
        return "stopped"
    if normalized == "rescheduled":
        return "changed"
    return normalized or "active"

def build_medication_timing(summary_text: str, appointment: dict):
    timing_sources = [
        extract_summary_value(summary_text, "Duration"),
        extract_summary_value(summary_text, "Next Recommended Step"),
        extract_summary_value(summary_text, "Medications"),
    ]
    timing_sources = [value for value in timing_sources if value]
    if timing_sources:
                return timing_sources[0]

    appointment_date = appointment.get("date", "")
    appointment_time = appointment.get("time", "")
    if appointment_date and appointment_time:
        return f"Visit on {appointment_date} at {appointment_time}"
    if appointment_date:
        return f"Visit on {appointment_date}"
    return "Follow doctor instructions"

def get_accepted_patient_appointment(patient_email: str, doctor_email: str, appointment_id: str):
    try:
        appointment_object_id = ObjectId(appointment_id)
    except Exception:
        return None, {"error": "Invalid appointment id"}

    appointment = appointments_collection.find_one({
        "_id": appointment_object_id,
        "patient_email": patient_email,
        "doctor_email": doctor_email,
    })
    if not appointment:
        return None, {"error": "Appointment not found"}

    if not is_accepted_appointment(appointment.get("status", "")):
        return None, {"error": "AI pre-consultation is available only after the doctor accepts this appointment."}

    return appointment, None

def parse_medication_list(raw_value: str):
    text_value = str(raw_value or "").strip()
    if not text_value:
        return []
    return [item.strip() for item in re.split(r"[,\n;]", text_value) if item.strip()]

def is_plausible_medication_entry(value: str):
    normalized = str(value or "").strip()
    if not normalized:
        return False

    lowered = normalized.lower().rstrip(":").strip()
    invalid_entries = {
        "allergies",
        "medications",
        "chief complaint",
        "duration",
        "severity",
        "other symptoms",
        "next recommended step",
        "doctor",
        "patient",
        "summary",
        "none",
        "n/a",
        "na",
        "not given",
        "not specified",
        "unknown",
    }
    return lowered not in invalid_entries and not normalized.endswith(":")

def sanitize_medication_items(raw_items):
    return [item for item in raw_items if is_plausible_medication_entry(item)]

def ensure_doctor_access(doctor_email: str, authorization: str):
    if not authorization:
        return None, {"error": "Token missing"}

    payload = verify_token(authorization)
    if not payload:
        return None, {"error": "Invalid token"}

    if payload.get("role") != "doctor":
        return None, {"error": "Access denied — doctors only"}

    if payload.get("email") != doctor_email:
        return None, {"error": "Unauthorized doctor access"}

    return payload, None

@app.get("/")
def home():
    return {"message": "BKL chal rha hai"}

@app.post("/register")
def register(patient: Patient):
    existing = patients_collection.find_one({"email": patient.email})
    if existing:
        return {"error": "Email already registered"}
    patients_collection.insert_one({
        "name": patient.name,
        "email": patient.email,
        "age": patient.age,
        "gender": patient.gender,
        "password": hash_password(patient.password)
    })
    return {"message": "Patient registered successfully"}


@app.post("/login")
def login(data: LoginData):
    patient = patients_collection.find_one({"email": data.email})
    if not patient:
        return {"message": "No Email Registered"}
    if not verify_password(data.password, patient["password"]):
        return {"message": "Incorrect Password"}
    token = create_token({"email": data.email})
    return {"message": "Login successful", "token": token}

@app.post("/register/doctor")
def register_doctor(doctor: Doctor):
    existing = doctors_collection.find_one({"email": doctor.email})
    if existing:
        return {"error": "Email already registered"}
    doctors_collection.insert_one({
        "name": doctor.name,
        "email": doctor.email,
        "specialization": doctor.specialization,
        "password": hash_password(doctor.password)
    })
    return {"message": "Doctor registered successfully"}

@app.post("/login/doctor")
def doctor_login(data: LoginData):
    doctor = doctors_collection.find_one({"email": data.email})
    if not doctor:
        return {"error": "No doctor found with this email"}
    if not verify_password(data.password, doctor["password"]):
        return {"error": "Incorrect password"}
    token = create_token({"email": data.email, "role": "doctor"})
    return {"message": "Login successful", "token": token}

@app.get("/doctors")
def get_doctors():
    doctors = doctors_collection.find({}, {"name": 1, "email": 1, "specialization": 1})
    result = []
    for doctor in doctors:
        result.append({
            "id": str(doctor["_id"]),
            "name": doctor.get("name", ""),
            "email": doctor.get("email", ""),
            "specialization": doctor.get("specialization", "General")
        })
    return {"doctors": result}

@app.post("/appointments/book")
def appointment_booking(appointment: Appointments):
    if not patients_collection.find_one({"email": appointment.patient_email}):
        return {"message": "Patient not found"}
    if not doctors_collection.find_one({"email": appointment.doctor_email}):
        return {"message": "Doctor not found"}
    duplicate = appointments_collection.find_one({
        "doctor_email": appointment.doctor_email,
        "date": appointment.date,
        "time": appointment.time
    })
    if duplicate:
        return {"error": "This slot is already booked"}
    appointments_collection.insert_one({
        "patient_email": appointment.patient_email,
        "doctor_email": appointment.doctor_email,
        "date": appointment.date,
        "time": appointment.time,
        "reason": appointment.reason,
        "status": "pending"
    })
    return {"message": "Appointment booked successfully"}

@app.post("/doctor/appointments/schedule")
def doctor_schedule_appointment(payload: DoctorScheduleAppointment, authorization: str = Header(None)):
    if not authorization:
        return {"error": "Token missing"}

    token_payload = verify_token(authorization)
    if not token_payload:
        return {"error": "Invalid token"}

    if token_payload.get("role") != "doctor":
        return {"error": "Access denied — doctors only"}

    doctor_email = token_payload.get("email")
    if not doctor_email:
        return {"error": "Invalid token payload"}

    if not patients_collection.find_one({"email": payload.patient_email}):
        return {"error": "Patient not found"}

    duplicate = appointments_collection.find_one({
        "doctor_email": doctor_email,
        "date": payload.date,
        "time": payload.time,
    })
    if duplicate:
        return {"error": "This slot is already booked"}

    insert_result = appointments_collection.insert_one({
        "patient_email": payload.patient_email,
        "doctor_email": doctor_email,
        "date": payload.date,
        "time": payload.time,
        "reason": payload.reason,
        "status": "accepted",
        "scheduled_by": "doctor",
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    })

    created = appointments_collection.find_one({"_id": insert_result.inserted_id})
    created["_id"] = str(created["_id"])
    return {"message": "Follow-up appointment scheduled", "appointment": created}

@app.get("/appointments/{doctor_email}")
def get_appointments(doctor_email: str, authorization: str = Header(None)):
    if not authorization:
        return {"error": "Token missing"}
    payload = verify_token(authorization)
    if not payload:
        return {"error": "Invalid token"}
    if payload.get("role") != "doctor":
        return {"error": "Access denied — doctors only"}
    result = []
    appointments = appointments_collection.find({"doctor_email": doctor_email})
    for appointment in appointments:
        appointment["_id"] = str(appointment["_id"])
        result.append(appointment)
    return {"appointments": result}

@app.patch("/appointments/{appointment_id}")
def update_appointment(appointment_id: str, action_data: AppointmentAction, authorization: str = Header(None)):
    if not authorization:
        return {"error": "Token missing"}

    payload = verify_token(authorization)
    if not payload:
        return {"error": "Invalid token"}

    user_email = payload.get("email")
    user_role = payload.get("role", "patient")

    try:
        appointment_object_id = ObjectId(appointment_id)
    except Exception:
        return {"error": "Invalid appointment id"}

    appointment = appointments_collection.find_one({"_id": appointment_object_id})
    if not appointment:
        return {"error": "Appointment not found"}

    if user_role == "doctor":
        if appointment.get("doctor_email") != user_email:
            return {"error": "Unauthorized appointment access"}
    else:
        if appointment.get("patient_email") != user_email:
            return {"error": "Unauthorized appointment access"}

    action = (action_data.action or "").lower()
    updates = {"updated_at": datetime.utcnow().isoformat()}

    if user_role == "doctor":
        if action == "accept":
            updates["status"] = "accepted"
        elif action == "decline":
            updates["status"] = "declined"
        elif action == "cancel":
            updates["status"] = "cancelled_by_doctor"
        elif action == "reschedule":
            if not action_data.date or not action_data.time:
                return {"error": "date and time required for reschedule"}
            updates["date"] = action_data.date
            updates["time"] = action_data.time
            updates["status"] = "accepted"
            updates["rescheduled_by"] = "doctor"
        else:
            return {"error": "Invalid doctor action"}
    else:
        if action == "cancel":
            updates["status"] = "cancelled_by_patient"
        elif action == "reschedule":
            if not action_data.date or not action_data.time:
                return {"error": "date and time required for reschedule"}
            updates["date"] = action_data.date
            updates["time"] = action_data.time
            updates["status"] = "pending"
            updates["rescheduled_by"] = "patient"
        else:
            return {"error": "Invalid patient action"}

    appointments_collection.update_one({"_id": appointment_object_id}, {"$set": updates})
    updated = appointments_collection.find_one({"_id": appointment_object_id})
    updated["_id"] = str(updated["_id"])
    return {"message": "Appointment updated", "appointment": updated}

@app.post("/ai-chat")
def ai_chat(data: ChatMessage):
    appointment, access_error = get_accepted_patient_appointment(data.patient_email, data.doctor_email, data.appointment_id)
    if access_error:
        return access_error

    doctor_doc = doctors_collection.find_one({"email": data.doctor_email}, {"name": 1, "email": 1, "specialization": 1})

    system_prompt = """You are a medical pre-consultation assistant.
Keep the conversation simple, friendly, and easy to understand.
Ask one short follow-up question at a time when needed.
Do not use markdown, bullets, bold text, or labels like AI:.
Do not diagnose. Encourage a doctor visit if symptoms seem severe or urgent.
Keep replies concise and plain text."""

    conversation = list(data.conversation)
    conversation.append(f"Patient: {data.message}")
    
    transcript = "\n".join(conversation)
    response_prompt = f"""{system_prompt}

Doctor context:
{doctor_doc.get('name', data.doctor_email) if doctor_doc else data.doctor_email} ({data.doctor_email})

Conversation so far:
{transcript}

Reply with only the next assistant message.
"""
    response = clean_ai_text(ask_gemini([response_prompt])).strip()
    conversation.append(f"AI: {response}")

    summary_prompt = f"""Create a doctor-facing pre-consult report in plain text only.
Do not use markdown, bullets, bold text, or labels like AI:.
Format exactly as:
Doctor: ...
Patient: ...
Chief Complaint: ...
Duration: ...
Severity: ...
Other Symptoms: ...
Medications: ...
Allergies: ...
Next Recommended Step: ...

Use only the information from the conversation and assistant reply below.
Conversation: {conversation}
Assistant reply: {response}"""
    summary = clean_ai_text(ask_gemini([summary_prompt])).strip()
    
    preconsults_collection.update_one(
        {
            "patient_email": data.patient_email,
            "doctor_email": data.doctor_email,
            "appointment_id": data.appointment_id,
        },
        {
            "$set": {
                "patient_email": data.patient_email,
                "doctor_email": data.doctor_email,
                "appointment_id": data.appointment_id,
                "conversation": conversation,
                "ai_response": response,
                "summary": summary,
                "appointment": {
                    "id": str(appointment.get("_id")),
                    "date": appointment.get("date", ""),
                    "time": appointment.get("time", ""),
                    "reason": appointment.get("reason", ""),
                    "status": appointment.get("status", ""),
                },
                "doctor": {
                    "name": doctor_doc.get("name", data.doctor_email) if doctor_doc else data.doctor_email,
                    "email": data.doctor_email,
                    "specialization": doctor_doc.get("specialization", "General") if doctor_doc else "General",
                },
                "updated_at": datetime.utcnow().isoformat(),
                "status": "ready",
            },
            "$setOnInsert": {"created_at": datetime.utcnow().isoformat()},
        },
        upsert=True,
    )

    return {
        "response": response,
        "conversation": conversation,
        "summary": summary,
        "doctor_email": data.doctor_email,
        "appointment_id": data.appointment_id,
        "doctor": {
            "name": doctor_doc.get("name", data.doctor_email) if doctor_doc else data.doctor_email,
            "email": data.doctor_email,
            "specialization": doctor_doc.get("specialization", "General") if doctor_doc else "General",
        },
        "appointment": {
            "id": str(appointment.get("_id")),
            "date": appointment.get("date", ""),
            "time": appointment.get("time", ""),
            "reason": appointment.get("reason", ""),
            "status": appointment.get("status", ""),
        },
    }

@app.get("/patient/preconsults/{patient_email}")
def get_patient_preconsults(patient_email: str, doctor_email: Optional[str] = None, appointment_id: Optional[str] = None):
    query = {"patient_email": patient_email}
    if doctor_email:
        query["doctor_email"] = doctor_email
    if appointment_id:
        query["appointment_id"] = appointment_id

    records = preconsults_collection.find(query)
    result = []
    for record in records:
        record["_id"] = str(record["_id"])
        result.append(record)
    result.sort(key=lambda item: item.get("updated_at", ""), reverse=True)
    return {"preconsults": result}

@app.patch("/doctor/preconsults/{preconsult_id}/medications")
def update_preconsult_medications(preconsult_id: str, payload: MedicationUpdate, authorization: str = Header(None)):
    if not authorization:
        return {"error": "Token missing"}

    token_payload = verify_token(authorization)
    if not token_payload:
        return {"error": "Invalid token"}

    if token_payload.get("role") != "doctor":
        return {"error": "Access denied — doctors only"}

    try:
        record_object_id = ObjectId(preconsult_id)
    except Exception:
        return {"error": "Invalid preconsult id"}

    record = preconsults_collection.find_one({"_id": record_object_id})
    if not record:
        return {"error": "Preconsult not found"}

    if record.get("doctor_email") != token_payload.get("email"):
        return {"error": "Unauthorized preconsult access"}

    medications = [item.strip() for item in re.split(r"[,;\n]", payload.medications) if item.strip()]
    if not medications:
        return {"error": "Please enter at least one medication"}

    appointment_status = str(payload.status or record.get("status", "ready")).lower()
    if appointment_status not in {"active", "completed", "stopped", "changed"}:
        appointment_status = "active"

    updates = {
        "medications": medications,
        "medication_timing": payload.timing or "Follow doctor instructions",
        "medication_status": appointment_status,
        "medication_notes": payload.notes or "",
        "updated_at": datetime.utcnow().isoformat(),
        "status": "ready",
    }

    preconsults_collection.update_one({"_id": record_object_id}, {"$set": updates})
    updated = preconsults_collection.find_one({"_id": record_object_id})
    updated["_id"] = str(updated["_id"])
    return {"message": "Medication prescription saved", "preconsult": updated}

@app.get("/patient/medications/{patient_email}")
def get_patient_medications(patient_email: str):
    appointments = list(appointments_collection.find({"patient_email": patient_email}))
    preconsults = list(preconsults_collection.find({"patient_email": patient_email}))
    preconsult_map = {
        (record.get("appointment_id", ""), record.get("doctor_email", "")): record
        for record in preconsults
    }
    result = []

    for appointment in appointments:
        if not is_accepted_appointment(appointment.get("status", "")) and str(appointment.get("status", "")).lower() != "completed":
            continue

        doctor_email = appointment.get("doctor_email", "")
        appointment_id = str(appointment.get("_id"))
        related_report = preconsult_map.get((appointment_id, doctor_email))
        summary_text = related_report.get("summary", "") if related_report else ""
        medication_items = related_report.get("medications", []) if related_report else []

        if isinstance(medication_items, str):
            medication_items = split_medication_items(medication_items)

        medication_items = sanitize_medication_items(medication_items)

        if not medication_items:
            medication_line = extract_summary_value(summary_text, "Medications")
            medication_items = sanitize_medication_items(split_medication_items(medication_line))

        if not medication_items:
            continue

        doctor_doc = doctors_collection.find_one({"email": doctor_email}, {"name": 1, "specialization": 1, "email": 1})
        doctor_name = doctor_doc.get("name", doctor_email.split("@")[0]) if doctor_doc else doctor_email.split("@")[0]
        doctor_specialization = doctor_doc.get("specialization", "General") if doctor_doc else "General"
        appointment_context = {
            "id": appointment_id,
            "date": appointment.get("date", ""),
            "time": appointment.get("time", ""),
            "reason": appointment.get("reason", ""),
            "status": appointment.get("status", ""),
        }
        status_label = related_report.get("medication_status") if related_report else ""
        if not status_label:
            status_label = medication_status_from_appointment(appointment_context["status"])
        timing = related_report.get("medication_timing") if related_report else ""
        if not timing:
            timing = build_medication_timing(summary_text, appointment_context)
        notes = related_report.get("medication_notes", "") if related_report else ""

        for item in medication_items:
            result.append({
                "id": f"{appointment_id}-{doctor_email}-{item}",
                "name": item,
                "dose": notes or "As prescribed",
                "timing": timing,
                "status": status_label,
                "doctor": {
                    "name": doctor_name,
                    "email": doctor_email,
                    "specialization": doctor_specialization,
                },
                "appointment": appointment_context,
                "summary": summary_text,
                "notes": notes,
                "report_id": str(related_report.get("_id")) if related_report else "",
                "report_status": related_report.get("status", "") if related_report else "",
            })

    result.sort(key=lambda item: f"{item['appointment'].get('date', '')} {item['appointment'].get('time', '')}", reverse=True)
    return {"medications": result}

@app.post("/report/upload")
async def upload_patient_report(patient_email: str, doctor_email: Optional[str] = None, file: UploadFile = File(...)):
    contents = await file.read()
    url = upload_report(contents)
    resolved_doctor_email = doctor_email.strip() if doctor_email else ""

    if not resolved_doctor_email:
        accepted_appointments = list(
            appointments_collection.find(
                {"patient_email": patient_email, "status": {"$in": ["accepted", "approved", "confirmed"]}},
                {"doctor_email": 1, "date": 1, "time": 1},
            )
        )
        accepted_appointments.sort(
            key=lambda item: f"{item.get('date', '')} {item.get('time', '')}",
            reverse=True,
        )
        if accepted_appointments:
            resolved_doctor_email = accepted_appointments[0].get("doctor_email", "") or ""

    if not resolved_doctor_email:
        return {"error": "Please choose a doctor before uploading the file."}
    
    report_doc = {
        "patient_email": patient_email,
        "file_url": url,
        "file_name": file.filename,
        "type": file.content_type
    }
    
    if resolved_doctor_email:
        report_doc["doctor_email"] = resolved_doctor_email
    
    reports_collection.insert_one(report_doc)
    return {"message": "Report uploaded successfully", "url": url}

@app.post("/department/reports/upload")
async def upload_department_report(
    department_id: str,
    patient_name: str,
    patient_email: str,
    report_type: str,
    uploaded_by: str,
    notes: Optional[str] = None,
    doctor_email: Optional[str] = None,
    file: UploadFile = File(...),
):
    contents = await file.read()
    url = upload_report(contents)

    report_doc = {
        "category": "department",
        "department_id": department_id,
        "patient_name": patient_name,
        "patient_email": patient_email,
        "report_type": report_type,
        "uploaded_by": uploaded_by,
        "notes": notes or "",
        "status": "Pending Review",
        "file_url": url,
        "file_name": file.filename,
        "type": file.content_type,
        "file_size": len(contents),
        "uploaded_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }
    
    if doctor_email:
        report_doc["doctor_email"] = doctor_email

    insert_result = reports_collection.insert_one(report_doc)
    created = reports_collection.find_one({"_id": insert_result.inserted_id})
    created["_id"] = str(created["_id"])
    return {"message": "Department report uploaded successfully", "report": created}

@app.get("/department/reports/{department_id}")
def get_department_reports(department_id: str):
    reports = reports_collection.find({"category": "department", "department_id": department_id})
    result = []
    for report in reports:
        report["_id"] = str(report["_id"])
        result.append(report)

    result.sort(key=lambda item: item.get("uploaded_at", ""), reverse=True)
    return {"reports": result}

@app.get("/department/reports/{department_id}/summary")
def get_department_report_summary(department_id: str):
    reports = list(reports_collection.find({"category": "department", "department_id": department_id}))
    now = datetime.utcnow()

    uploaded_today = 0
    for report in reports:
        uploaded_at = report.get("uploaded_at")
        try:
            uploaded_dt = datetime.fromisoformat(uploaded_at.replace("Z", "")) if uploaded_at else None
        except Exception:
            uploaded_dt = None
        if uploaded_dt and uploaded_dt.date() == now.date():
            uploaded_today += 1

    patient_count = len(set(report.get("patient_email", "") for report in reports if report.get("patient_email")))

    return {
        "summary": {
            "total": len(reports),
            "pending": len([item for item in reports if item.get("status") == "Pending Review"]),
            "delivered": len([item for item in reports if item.get("status") == "Delivered"]),
            "archived": len([item for item in reports if item.get("status") == "Archived"]),
            "uploaded_today": uploaded_today,
            "patient_count": patient_count,
        }
    }

@app.get("/department/patients/{department_id}")
def get_department_patients(department_id: str):
    reports = list(reports_collection.find({"category": "department", "department_id": department_id}))

    grouped = {}
    for report in reports:
        patient_email = report.get("patient_email", "")
        key = patient_email or report.get("patient_name", "Unknown")
        if key not in grouped:
            grouped[key] = {
                "name": report.get("patient_name", "Unknown"),
                "email": patient_email,
                "count": 0,
                "latest": None,
                "latest_dt": None,
            }

        grouped[key]["count"] += 1
        uploaded_at = report.get("uploaded_at", "")
        try:
            uploaded_dt = datetime.fromisoformat(uploaded_at.replace("Z", "")) if uploaded_at else None
        except Exception:
            uploaded_dt = None

        current_latest = grouped[key]["latest_dt"]
        if uploaded_dt and (current_latest is None or uploaded_dt > current_latest):
            grouped[key]["latest_dt"] = uploaded_dt
            grouped[key]["latest"] = {
                "report_type": report.get("report_type", ""),
                "uploaded_at": uploaded_at,
            }

    patients = []
    for key, value in grouped.items():
        value.pop("latest_dt", None)
        patients.append({"key": key, **value})

    patients.sort(key=lambda item: (item.get("latest", {}) or {}).get("uploaded_at", ""), reverse=True)
    return {"patients": patients}

@app.patch("/department/reports/{report_id}/status")
def update_department_report_status(report_id: str, payload: DepartmentReportStatusUpdate):
    allowed_status = {"Pending Review", "Delivered", "Archived"}
    if payload.status not in allowed_status:
        return {"error": "Invalid status"}

    try:
        report_object_id = ObjectId(report_id)
    except Exception:
        return {"error": "Invalid report id"}

    report = reports_collection.find_one({"_id": report_object_id, "category": "department"})
    if not report:
        return {"error": "Report not found"}

    reports_collection.update_one(
        {"_id": report_object_id},
        {"$set": {"status": payload.status, "updated_at": datetime.utcnow().isoformat()}},
    )

    updated = reports_collection.find_one({"_id": report_object_id})
    updated["_id"] = str(updated["_id"])
    return {"message": "Status updated", "report": updated}

@app.get("/patient/appointments/{patient_email}")
def get_patient_appointments(patient_email: str):
    appointments = appointments_collection.find({"patient_email": patient_email})
    result = []
    for appointment in appointments:
        appointment["_id"] = str(appointment["_id"])
        result.append(appointment)
    return {"appointments": result}

@app.get("/patient/reports/{patient_email}")
def get_patient_reports(patient_email: str):
    reports = reports_collection.find({"patient_email": patient_email})
    result = []
    for report in reports:
        report["_id"] = str(report["_id"])
        result.append(report)
    return {"reports": result}

@app.get("/doctor/patient-files/{doctor_email}")
def get_doctor_patient_files(doctor_email: str):
    reports = list(reports_collection.find({"doctor_email": doctor_email}))
    
    # Group by patient
    grouped_reports = {}
    for report in reports:
        patient_email = report.get("patient_email", "")
        if patient_email not in grouped_reports:
            patient_doc = patients_collection.find_one({"email": patient_email}, {"name": 1, "email": 1})
            patient_name = str(patient_doc.get("name", "") if patient_doc else "").strip() or patient_email.split("@")[0] or "Unknown patient"
            grouped_reports[patient_email] = {
                "patient_name": patient_name,
                "patient_email": patient_email,
                "files": []
            }
        
        report["_id"] = str(report["_id"])
        grouped_reports[patient_email]["files"].append(report)
    
    # Sort files by uploaded_at descending within each patient
    result = []
    for patient_email, patient_data in grouped_reports.items():
        patient_data["files"].sort(key=lambda x: x.get("uploaded_at", ""), reverse=True)
        result.append(patient_data)
    
    # Sort patients by latest file upload
    result.sort(key=lambda x: x["files"][0].get("uploaded_at", "") if x["files"] else "", reverse=True)
    
    return {"patient_files": result}

@app.get("/patient/doctors/{patient_email}")
def get_patient_doctor_summaries(patient_email: str, accepted_only: bool = False):
    appointments = appointments_collection.find({"patient_email": patient_email})
    now = datetime.now()
    by_doctor = {}

    for appointment in appointments:
        doctor_email = appointment.get("doctor_email")
        if not doctor_email:
            continue

        appointment_status = str(appointment.get("status", "")).lower()
        if accepted_only and not is_accepted_appointment(appointment_status):
            continue

        if doctor_email not in by_doctor:
            doctor_doc = doctors_collection.find_one(
                {"email": doctor_email},
                {"name": 1, "email": 1, "specialization": 1}
            )
            doctor_name = str(doctor_doc.get("name", "") if doctor_doc else "").strip() or doctor_email.split("@")[0]
            by_doctor[doctor_email] = {
                "doctor": {
                    "id": str(doctor_doc["_id"]) if doctor_doc else doctor_email,
                    "name": doctor_name,
                    "email": doctor_email,
                    "specialization": doctor_doc.get("specialization", "General") if doctor_doc else "General",
                },
                "previous_appointment": None,
                "next_appointment": None,
                "previous_dt": None,
                "next_dt": None,
                "latest_doctor_notes": None,
                "latest_prescription": None,
                "appointments": [],
            }

        normalized_appointment = {
            "id": str(appointment.get("_id")),
            "date": appointment.get("date", ""),
            "time": appointment.get("time", ""),
            "status": appointment.get("status", ""),
            "reason": appointment.get("reason", ""),
            "doctor_notes": appointment.get("doctor_notes"),
            "prescription": appointment.get("prescription"),
            "follow_up": appointment.get("follow_up"),
        }
        by_doctor[doctor_email]["appointments"].append(normalized_appointment)

        appointment_dt = parse_appointment_datetime(normalized_appointment["date"], normalized_appointment["time"])
        if appointment_dt and is_accepted_appointment(normalized_appointment["status"]):
            if appointment_dt <= now:
                prev_dt = by_doctor[doctor_email]["previous_dt"]
                if prev_dt is None or appointment_dt > prev_dt:
                    by_doctor[doctor_email]["previous_dt"] = appointment_dt
                    by_doctor[doctor_email]["previous_appointment"] = normalized_appointment
            else:
                next_dt = by_doctor[doctor_email]["next_dt"]
                if next_dt is None or appointment_dt < next_dt:
                    by_doctor[doctor_email]["next_dt"] = appointment_dt
                    by_doctor[doctor_email]["next_appointment"] = normalized_appointment

    result = []
    for doctor_email, summary in by_doctor.items():
        for appointment in reversed(summary["appointments"]):
            if appointment.get("doctor_notes") and summary["latest_doctor_notes"] is None:
                summary["latest_doctor_notes"] = appointment.get("doctor_notes")
            if appointment.get("prescription") and summary["latest_prescription"] is None:
                summary["latest_prescription"] = appointment.get("prescription")

        result.append({
            "doctor": summary["doctor"],
            "previous_appointment": summary["previous_appointment"],
            "next_appointment": summary["next_appointment"],
            "latest_doctor_notes": summary["latest_doctor_notes"],
            "latest_prescription": summary["latest_prescription"],
            "appointments": summary["appointments"],
        })

    return {"doctors": result}

@app.get("/doctor/patients/{doctor_email}")
def get_doctor_patients(doctor_email: str, authorization: str = Header(None)):
    _, access_error = ensure_doctor_access(doctor_email, authorization)
    if access_error:
        return access_error

    appointments = list(appointments_collection.find({"doctor_email": doctor_email}))
    grouped = {}
    now = datetime.now()

    for appointment in appointments:
        patient_email = appointment.get("patient_email")
        if not patient_email:
            continue

        if patient_email not in grouped:
            patient_doc = patients_collection.find_one(
                {"email": patient_email},
                {"name": 1, "email": 1, "age": 1, "gender": 1}
            )
            grouped[patient_email] = {
                "patient": {
                    "email": patient_email,
                    "name": patient_doc.get("name", patient_email.split("@")[0]) if patient_doc else patient_email.split("@")[0],
                    "age": patient_doc.get("age") if patient_doc else None,
                    "gender": patient_doc.get("gender") if patient_doc else None,
                },
                "appointment_count": 0,
                "latest_status": None,
                "last_visit": None,
                "next_visit": None,
                "last_visit_dt": None,
                "next_visit_dt": None,
            }

        grouped[patient_email]["appointment_count"] += 1
        grouped[patient_email]["latest_status"] = appointment.get("status", "")

        appointment_dt = parse_appointment_datetime(appointment.get("date", ""), appointment.get("time", ""))
        normalized = {
            "id": str(appointment.get("_id")),
            "date": appointment.get("date", ""),
            "time": appointment.get("time", ""),
            "status": appointment.get("status", ""),
            "reason": appointment.get("reason", ""),
        }

        if appointment_dt and is_accepted_appointment(appointment.get("status", "")):
            if appointment_dt <= now:
                previous_dt = grouped[patient_email]["last_visit_dt"]
                if previous_dt is None or appointment_dt > previous_dt:
                    grouped[patient_email]["last_visit_dt"] = appointment_dt
                    grouped[patient_email]["last_visit"] = normalized
            else:
                next_dt = grouped[patient_email]["next_visit_dt"]
                if next_dt is None or appointment_dt < next_dt:
                    grouped[patient_email]["next_visit_dt"] = appointment_dt
                    grouped[patient_email]["next_visit"] = normalized

    result = []
    for _, item in grouped.items():
        item.pop("last_visit_dt", None)
        item.pop("next_visit_dt", None)
        result.append(item)

    return {"patients": result}

@app.get("/doctor/preconsults/{doctor_email}")
def get_doctor_preconsults(doctor_email: str, authorization: str = Header(None)):
    _, access_error = ensure_doctor_access(doctor_email, authorization)
    if access_error:
        return access_error

    records = preconsults_collection.find({"doctor_email": doctor_email})
    result = []

    for record in records:
        patient_email = record.get("patient_email", "")
        patient_doc = patients_collection.find_one({"email": patient_email}, {"name": 1, "email": 1, "age": 1, "gender": 1})
        result.append({
            "id": str(record.get("_id")),
            "status": record.get("status", ""),
            "date": record.get("updated_at", record.get("created_at", "")),
            "time": "",
            "reason": record.get("summary", record.get("ai_response", record.get("conversation", []))),
            "doctor_email": record.get("doctor_email", doctor_email),
            "appointment_id": record.get("appointment_id", ""),
            "appointment": record.get("appointment", {}),
            "doctor": record.get("doctor", {}),
            "summary": record.get("summary", ""),
            "conversation": record.get("conversation", []),
            "patient": {
                "name": patient_doc.get("name", patient_email.split("@")[0]) if patient_doc else patient_email.split("@")[0],
                "email": patient_email,
                "age": patient_doc.get("age") if patient_doc else None,
                "gender": patient_doc.get("gender") if patient_doc else None,
            },
        })

    result.sort(key=lambda item: item.get("date", ""), reverse=True)
    return {"preconsults": result}

@app.delete("/account")
def delete_account(authorization: str = Header(None)):
    if not authorization:
        return {"error": "Token missing"}

    payload = verify_token(authorization)
    if not payload:
        return {"error": "Invalid token"}

    user_email = payload.get("email")
    user_role = payload.get("role", "patient")

    if not user_email:
        return {"error": "Invalid token payload"}

    if user_role == "doctor":
        delete_result = doctors_collection.delete_one({"email": user_email})
        if delete_result.deleted_count == 0:
            return {"error": "Doctor account not found"}

        appointments_collection.delete_many({"doctor_email": user_email})
        return {"message": "Doctor account deleted successfully"}

    delete_result = patients_collection.delete_one({"email": user_email})
    if delete_result.deleted_count == 0:
        return {"error": "Patient account not found"}

    appointments_collection.delete_many({"patient_email": user_email})
    reports_collection.delete_many({"patient_email": user_email})
    return {"message": "Patient account deleted successfully"}


