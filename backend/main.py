import os
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

app = FastAPI(title="Community Hero - CivicAgent Core")

# Initialize the official Google Gen AI client
# It automatically reads the GEMINI_API_KEY environment variable you just set
try:
    client = genai.Client()
except Exception as e:
    raise RuntimeError(f"Failed to initialize Gemini Client. Check your API key. Error: {e}")

# --- STRUCTURAL OUTPUT SCHEMAS (For Flutter to read perfectly) ---
class PublicTracker(BaseModel):
    title: str = Field(description="A brief, urgent title describing the civic issue.")
    rationale: str = Field(description="A concise explanation detailing why this is a safety or infrastructure risk.")

class PredictiveInsight(BaseModel):
    timeline_48h: str = Field(description="Deterioration forecast if left unattended for 48 hours.")
    timeline_7_days: str = Field(description="Deterioration forecast if left unattended for 7 days.")

class GamifiedQuest(BaseModel):
    quest_title: str = Field(description="An action-packed title for the citizen verification quest.")
    objective: str = Field(description="Clear instruction on what a nearby citizen needs to check or photograph.")
    reward_points: int = Field(description="Points awarded based on risk severity (between 50 and 200).")

class CivicAgentAnalysis(BaseModel):
    category: str = Field(description="Civic category (e.g., Potholes, Water Leakages, Damaged Streetlights, Waste Management).")
    severity_score: int = Field(description="A strict priority score from 1 (lowest) to 10 (highest hazard).")
    public_tracker: PublicTracker
    predictive_insight: PredictiveInsight
    gamified_quest: GamifiedQuest


# --- SANITY CHECK ENDPOINT ---
@app.get("/")
def read_root():
    return {"status": "FastAPI is running successfully!"}


# --- RE-ENGINEERED MULTIMODAL CORE ENDPOINT ---
@app.post("/api/v1/report")
async def process_report(
    raw_location: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        # Read the uploaded file bytes from Flutter
        image_bytes = await image.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to process image file: {e}")

    # The prompt engineering that scores you "Agentic Depth" points
    prompt = f"""
    You are CivicAgent, the autonomous urban infrastructure coordinator.
    Analyze the uploaded image representing a citizen-reported infrastructure issue.
    
    User Reported Location: {raw_location}
    
    Execute your evaluation pipeline:
    1. Categorize the issue into standard civic domains.
    2. Assess visual public safety hazards to score severity (1-10).
    3. Generate clear public communication texts.
    4. Predict infrastructure decay timelines if ignored.
    5. Formulate a hyper-local citizen task (Quest) to verify this problem.
    """

    try:
        # Request structured JSON output from Gemini 2.5 Flash using the official SDK syntax
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[
                types.Part.from_bytes(data=image_bytes, mime_type=image.content_type),
                prompt
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=CivicAgentAnalysis,
                temperature=0.2, # Low temperature for reliable structured outputs
            )
        )
        
        # FastAPI will transparently pass this perfect JSON schema back to Flutter
        return response.text

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini Engine Error: {e}")