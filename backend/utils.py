import bcrypt
from jose import jwt
from datetime import datetime, timedelta
from google import genai
import os
import cloudinary
import cloudinary.uploader

SECRET_KEY = "medisync-kkr"
ALGORITHM = "HS256"


def hash_password(password: str):
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def verify_password(plain_password: str, hashed_password: str):
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))

def create_token(data: dict):
    expiry = datetime.utcnow() + timedelta(days=7)
    data["exp"] = expiry
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET")
)

def upload_report(file):
    result = cloudinary.uploader.upload(file, resource_type="auto")
    return result["secure_url"]

def ask_gemini(conversation: list):
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
    response = client.models.generate_content(
        model="gemini-2.5-flash-lite",
        contents=conversation
    )
    return response.text

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except:
        return None