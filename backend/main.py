from multiprocessing.reduction import duplicate
from fastapi import FastAPI, UploadFile, File, Header
from pydantic import BaseModel
from database import patients_collection, doctors_collection, appointments_collection, reports_collection
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
    message: str
    conversation: list = []

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

@app.post("/ai-chat")
def ai_chat(data: ChatMessage):
    system_prompt = """You are a medical assistant helping collect patient symptoms before a doctor's appointment.
    Ask about: main complaint, duration, severity (1-10), other symptoms, current medications, allergies.
    After collecting all info, generate a structured summary for the doctor.
    Be conversational and empathetic."""
    
    conversation = data.conversation
    conversation.append(f"Patient: {data.message}")
    
    response = ask_gemini(conversation + [system_prompt])
    conversation.append(f"AI: {response}")
    
    return {
        "response": response,
        "conversation": conversation
    }

@app.post("/report/upload")
async def upload_patient_report(patient_email: str, file: UploadFile = File(...)):
    contents = await file.read()
    url = upload_report(contents)
    reports_collection.insert_one({
        "patient_email": patient_email,
        "file_url": url,
        "file_name": file.filename,
        "type": file.content_type
    })
    return {"message": "Report uploaded successfully", "url": url}

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


