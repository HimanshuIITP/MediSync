# MediSync

AI-powered health-tech platform for smarter appointments, better doctor preparedness, and improved patient engagement.

Built for CodeCure at SPIRIT 2026, IIT (BHU) Varanasi.

## Problem Statement

High patient load and limited consultation time often reduce care quality. Important context such as symptom progression, medication history, and diagnostic files is frequently scattered across systems or not captured before the consultation.

## Solution Overview

MediSync provides a full-stack web workflow for patients, doctors, and departments:

- Patient onboarding and role-based login
- Doctor discovery and appointment booking
- AI pre-consult conversation to collect symptoms before visit
- Structured pre-consult summaries for doctors
- Medical report upload and retrieval
- Doctor schedule, patient records, and pre-consult review
- Department-level report management and summary views

## Innovation Highlights

- Context-aware AI pre-consult that builds conversation history and generates actionable clinical summaries
- End-to-end continuity: appointment -> pre-consult -> files -> doctor review
- Role-specific experience for Patient, Doctor, and Department users
- Production-ready deployment path with environment-driven API configuration

## Tech Stack and Tools

Frontend
- React 19
- TypeScript
- Vite 7
- Tailwind CSS 4
- React Router
- Lucide icons

Backend
- FastAPI
- MongoDB Atlas
- Google Gemini API
- Cloudinary (medical file storage)
- JWT-based authentication utilities

Developer Tooling
- GitHub for version control and regular commits
- GitHub Actions for frontend deployment workflow

## System Architecture

1. Frontend captures role-specific user actions.
2. Backend validates inputs and processes domain logic.
3. MongoDB stores users, appointments, conversations, summaries, and report metadata.
4. AI endpoint processes patient conversation and returns guided responses plus summary.
5. Cloudinary stores uploaded files and returns accessible URLs.
6. Doctors and departments consume pre-processed information for faster decisions.

## Core Features

- Authentication and account creation
  - Patient registration/login
  - Doctor registration/login

- Appointment lifecycle
  - Book appointment
  - View doctor and patient appointment lists
  - Doctor schedule management

- AI-assisted pre-consult
  - Interactive symptom conversation
  - Conversation memory handling
  - Doctor-facing structured summary

- Medical reports
  - Upload report files
  - Retrieve patient reports
  - Department report upload and analytics endpoints

- Patient-doctor continuity
  - Doctor-specific patient files and pre-consults
  - Patient-facing doctor list and history flows

## API Surface (Key Endpoints)

Authentication
- POST /register
- POST /login
- POST /register/doctor
- POST /login/doctor

Discovery and Appointments
- GET /doctors
- POST /appointments/book
- POST /doctor/appointments/schedule
- GET /appointments/{doctor_email}
- GET /patient/appointments/{patient_email}

AI and Clinical Context
- POST /ai-chat
- GET /patient/preconsults/{patient_email}
- GET /doctor/preconsults/{doctor_email}

Reports and Files
- POST /report/upload
- GET /patient/reports/{patient_email}
- POST /department/reports/upload
- GET /department/reports/{department_id}
- GET /department/reports/{department_id}/summary

Care Network Views
- GET /patient/doctors/{patient_email}
- GET /doctor/patients/{doctor_email}
- GET /doctor/patient-files/{doctor_email}

## Installation and Setup

Prerequisites
- Node.js 18+ and npm
- Python 3.10+
- MongoDB Atlas database
- Gemini API key
- Cloudinary credentials

1) Clone repository
- git clone https://github.com/HimanshuIITP/MediSync
- cd MediSync

2) Backend setup
- cd backend
- pip install -r requirements.txt
- create .env from .env.example and fill all keys
- run: uvicorn main:app --reload --host 0.0.0.0 --port 8000

3) Frontend setup
- cd ../frontend
- npm install
- create .env with:
  - VITE_API_BASE_URL=http://127.0.0.1:8000
- run: npm run dev

4) Open app
- Frontend: http://localhost:5173
- Backend docs: http://localhost:8000/docs

## Technical Workflow

Patient Flow
- Register/login -> browse doctors -> book appointment -> complete AI pre-consult -> upload reports -> attend consultation

Doctor Flow
- Login -> review appointments -> check AI summaries and patient files -> plan consultation

Department Flow
- Upload and view reports -> monitor department-wise report summaries

## Scalability and Real-World Readiness

- Stateless HTTP APIs suitable for containerized deployment
- Environment-based configuration for staging/production
- Cloud object storage integration for scalable file handling
- Role-segregated modules that can be split into microservices later
- Data model extendable for prescriptions, follow-ups, and analytics

## Code Quality Practices

- Modular frontend pages/components and backend route grouping
- Typed interfaces in frontend and Pydantic models in backend
- Error handling and guarded UI flows
- Consistent API contract usage across screens
- Repository-level documentation and verification guides included

## Repository Structure

- backend: FastAPI service, database integration, AI utilities
- frontend: React web app for patient/doctor/department experiences
- Flutter: original mobile app codebase and assets
- API_INTEGRATION.md: endpoint and request reference
- VERIFICATION_CHECKLIST.md: end-to-end validation checklist

## Demo Script (Round 2 Ready)

- Start with problem and impact in 30 seconds
- Show patient booking an appointment
- Run AI pre-consult conversation and generated summary
- Show doctor dashboard reading pre-consult context
- Upload and retrieve a report file
- Conclude with scalability and deployment approach

## Team and Contribution

Team project with collaborative development across frontend, backend, and integration/testing.

## License

Educational hackathon prototype.
