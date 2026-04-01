# 🏥 MediSync — Backend

Hey! This is the backend for MediSync — a project we built for the **CodeCure AI Hackathon at Spirit'26, IIT BHU**.

I'm a first year CS student and this is literally my first ever backend. Built it from scratch in like 3-4 days while learning FastAPI, MongoDB, and APIs for the first time. It was painful but it works 🔥

---

## 💡 What does MediSync do?

Doctors in India see like 50-100 patients a day. There's no time. Patients sit for 2 minutes and leave.

MediSync fixes this by:
- Letting patients **book appointments** with doctors online
- Before the appointment, an **AI assistant chats with the patient** and asks about their symptoms
- The AI generates a **structured summary** for the doctor — so when the patient walks in, the doctor already knows what's going on
- All **previous visits, medications, and reports** (X-ray, MRI, blood tests) are stored and accessible

---

## 🛠️ Tech Stack

| What | Which |
|---|---|
| Backend Framework | FastAPI (Python) |
| Database | MongoDB Atlas (free cloud) |
| Authentication | JWT tokens + bcrypt password hashing |
| AI | Google Gemini 2.5 Flash Lite |
| File Storage | Cloudinary |
| Server | Uvicorn |

---

## 📁 Folder Structure

```
backend/
├── main.py        ← all the API endpoints live here
├── database.py    ← connects to MongoDB
├── utils.py       ← password hashing, JWT tokens, AI chat
├── .env           ← secret keys (NOT pushed to GitHub)
├── .env.example   ← template so others know what keys are needed
└── .gitignore     ← makes sure .env never gets pushed
```

---

## 🚀 How to Run This Locally

### Step 1 — Clone the repo
```bash
git clone https://github.com/HimanshuIITP/MediSync
cd MediSync/backend
```

### Step 2 — Install all packages
```bash
pip install fastapi uvicorn "pymongo[srv]" python-dotenv bcrypt python-jose google-genai cloudinary python-multipart
```

### Step 3 — Create a `.env` file
Make a file called `.env` in the backend folder and add:
```
MONGO_URL=your_mongodb_connection_string_here
GEMINI_API_KEY=your_gemini_api_key_here
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

### Step 4 — Start the server
```bash
uvicorn main:app --reload
```

### Step 5 — Open the docs
Go to `http://localhost:8000/docs` in your browser — you'll see all the APIs ready to test!

---

## 📡 All API Endpoints

### 👤 Patient
| Method | Endpoint | What it does |
|---|---|---|
| POST | `/register` | Create a new patient account |
| POST | `/login` | Login → get JWT token back |

### 🩺 Doctor
| Method | Endpoint | What it does |
|---|---|---|
| POST | `/register/doctor` | Create a new doctor account |
| POST | `/login/doctor` | Doctor login → get JWT token back |

### 📅 Appointments
| Method | Endpoint | What it does |
|---|---|---|
| POST | `/appointments/book` | Book an appointment with a doctor |
| GET | `/appointments/{doctor_email}` | Doctor sees all their appointments |
| GET | `/patient/appointments/{email}` | Patient sees all their appointments |

### 📁 Reports
| Method | Endpoint | What it does |
|---|---|---|
| POST | `/report/upload` | Upload X-ray, MRI, blood test etc. |
| GET | `/patient/reports/{email}` | Patient sees all their uploaded reports |

### 🤖 AI Chat
| Method | Endpoint | What it does |
|---|---|---|
| POST | `/ai-chat` | AI asks patient about symptoms and makes a summary for the doctor |

---

## 🤖 How the AI Chat Works

This is the coolest part of the project honestly.

```
Patient books appointment
        ↓
AI chat starts
        ↓
AI asks questions one by one:
  → What's your main problem?
  → How long has this been happening?
  → Rate your pain/discomfort 1-10
  → Any other symptoms?
  → Current medications?
  → Any allergies?
        ↓
After enough info is collected,
AI generates a structured clinical note
        ↓
Doctor sees this BEFORE the patient walks in ✅
```

Example request:
```json
POST /ai-chat
{
  "patient_email": "patient@gmail.com",
  "message": "I have a fever",
  "conversation": []
}
```

Example response:
```json
{
  "response": "I'm sorry to hear that. How long have you had the fever?",
  "conversation": [
    "Patient: I have a fever",
    "AI: I'm sorry to hear that. How long have you had the fever?"
  ]
}
```

Pass the `conversation` array back with each message so the AI remembers the full chat!

---

## 🔐 Security stuff

- Passwords are **never stored in plain text** — bcrypt hashes them
- JWT tokens expire after **7 days**
- All secret keys are in `.env` which is **never pushed to GitHub**
- CORS is enabled so the frontend can call the API freely

---

## ⚠️ Known Issues / TODO

- [ ] JWT token verification on protected routes (currently any request works without token)
- [ ] Role based access (patient vs doctor separation)
- [ ] Better error messages
- [ ] Deploy to Render for 24/7 availability


## note

I had literally zero backend knowledge before this. Never heard of FastAPI, never used MongoDB, never built an API. Built this entire thing in 3-4 days while learning from scratch.