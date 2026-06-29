import os
import json
import math
import uuid
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

app = FastAPI(title="CivicHero AI - Live Core")

# Initialize the official Google Gen AI client
try:
    # Hardcode the key here just for your local testing/demo!
    client = genai.Client(api_key="AQ.Ab8RN6IEsqa3qWzo_xkQLuaG6_E3WWK5Ej4Uf9pbwBo1TsuErA")
except Exception as e:
    raise RuntimeError(f"Failed to initialize Gemini Client. Check your API key. Error: {e}")

# ==========================================
# 🗄️ THE REAL IN-MEMORY DATABASE
# ==========================================
# In a production app, this would be PostgreSQL. 
# For the hackathon, this holds our live state perfectly.
ISSUES_DB = {}

# ==========================================
# 📐 HAVERSINE DISTANCE FORMULA
# ==========================================
def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculates distance in meters between two GPS coordinates."""
    R = 6371000  # Radius of Earth in meters
    phi_1 = math.radians(lat1)
    phi_2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2.0) ** 2 + math.cos(phi_1) * math.cos(phi_2) * math.sin(delta_lambda / 2.0) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# ==========================================
# 🤖 AI SCHEMAS
# ==========================================
class CivicAgentAnalysis(BaseModel):
    category: str = Field(description="Strict civic category (e.g., Pothole, Water Leakage).")
    severity: int = Field(description="Score 1-10.")
    department: str = Field(description="Assigned Department: Public Works, Water Supply, Electrical Maintenance, Waste Management, or Traffic Authority.")
    explanation: str = Field(description="Public-facing explanation of the issue.")
    confidence: int = Field(description="AI confidence percentage (e.g., 94).")
    risk_summary: str = Field(description="Short summary of risks if ignored.")
    quest_title: str = Field(description="Title for community verification.")
    quest_objective: str = Field(description="What nearby citizens need to do to verify.")
    latitude: float = Field(description="Estimated latitude.")
    longitude: float = Field(description="Estimated longitude.")

# ==========================================
# 🚀 REAL API ENDPOINTS
# ==========================================

@app.post("/api/v1/report")
async def process_report(raw_location: str = Form(...), image: UploadFile = File(...)):
    image_bytes = await image.read()

    # 1. We catch the bad mime type from Flutter
    safe_mime_type = image.content_type
    if not safe_mime_type or 'octet-stream' in safe_mime_type:
        safe_mime_type = 'image/jpeg'  # Force to JPEG

    prompt = f"""
    You are CivicHero AI. Analyze this infrastructure report. Location: "{raw_location}"
    1. Categorize the issue and assign severity (1-10).
    2. Determine the most appropriate government department.
    3. Calculate your confidence score (0-100).
    4. Provide a risk summary and explanation.
    5. Generate a localized verification quest with estimated coordinates.
    """

    # 2. We pass safe_mime_type to Gemini
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=[
            # 👇 LOOK HERE: This must say safe_mime_type, NOT image.content_type
            types.Part.from_bytes(data=image_bytes, mime_type=safe_mime_type), 
            prompt
        ],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=CivicAgentAnalysis,
            temperature=0.1, 
        )
    )
    
    ai_data = json.loads(response.text)
    new_lat = ai_data.get("latitude", 28.98)
    new_lng = ai_data.get("longitude", 77.70)
    new_category = ai_data.get("category", "")
    # ----------------------------------------------------
    # 🔥 REAL DUPLICATE DETECTION ENGINE
    # ----------------------------------------------------
    is_duplicate = False
    master_id = None

    for issue_id, issue_data in ISSUES_DB.items():
        if issue_data['analysis']['category'] == new_category:
            dist = calculate_distance(new_lat, new_lng, issue_data['analysis']['latitude'], issue_data['analysis']['longitude'])
            if dist <= 100:
                is_duplicate = True
                master_id = issue_id
                break 

    issue_record_id = master_id if is_duplicate else f"CIVIC-{str(uuid.uuid4())[:8].upper()}"
    
    if not is_duplicate:
        ISSUES_DB[issue_record_id] = {
            "id": issue_record_id,
            "status": "Reported",
            "analysis": ai_data
        }

    return {
        "issue_id": issue_record_id,
        "analysis": ai_data,
        "duplicate_detection": {
            "is_duplicate": is_duplicate,
            "master_issue": master_id
        }
    }
@app.post("/api/v1/verify/{issue_id}")
async def verify_issue(issue_id: str):
    """Real endpoint to update an issue's status when a citizen verifies it."""
    if issue_id in ISSUES_DB:
        ISSUES_DB[issue_id]["status"] = "Resolved"
        return {"status": "success", "message": f"Issue {issue_id} verified successfully."}
    raise HTTPException(status_code=404, detail="Issue not found")
@app.post("/api/v1/assign/{issue_id}")
async def assign_issue(issue_id: str):

    if issue_id not in ISSUES_DB:
        raise HTTPException(404)

    ISSUES_DB[issue_id]["status"] = "Assigned"

    return {"success": True}
@app.post("/api/v1/resolve/{issue_id}")
async def resolve_issue(issue_id: str):

    if issue_id not in ISSUES_DB:
        raise HTTPException(404)

    ISSUES_DB[issue_id]["status"] = "Resolved"

    return {"success": True}

@app.get("/api/v1/dashboard")
async def get_dashboard_stats():

    total = len(ISSUES_DB)

    reported = sum(
        1 for issue in ISSUES_DB.values()
        if issue["status"] == "Reported"
    )

    verified = sum(
        1 for issue in ISSUES_DB.values()
        if issue["status"] == "Verified"
    )

    assigned = sum(
        1 for issue in ISSUES_DB.values()
        if issue["status"] == "Assigned"
    )

    resolved = sum(
        1 for issue in ISSUES_DB.values()
        if issue["status"] == "Resolved"
    )

    critical = sum(
        1
        for issue in ISSUES_DB.values()
        if issue["analysis"]["severity"] >= 8
    )

    return {
        "summary": {
            "total": total,
            "reported": reported,
            "verified": verified,
            "assigned": assigned,
            "resolved": resolved,
            "critical": critical,
        },
        "feed": list(ISSUES_DB.values())
    }