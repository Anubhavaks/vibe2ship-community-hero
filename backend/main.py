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
    latitude: float = Field(description="An estimated latitude midpoint matching the reported location context (e.g., around 28.98 for Meerut area context if applicable, or typical city coordinates).")
    longitude: float = Field(description="An estimated longitude midpoint matching the reported location context.")
    radius_meters: int = Field(description="Geofence radius in meters around the coordinates where the quest is valid, between 100 and 500.")

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
    # The Advanced Prompt Engineering Block (Agentic Depth)
    prompt = f"""
    SYSTEM OVERRIDE: You are 'CivicAgent-Alpha', a Chief Municipal Civil Engineer and AI Crisis Assessor.
    Your directive is to analyze this visual infrastructure report with ruthless engineering precision.
    
    Raw Location Input: "{raw_location}"
    
    EXECUTE THE FOLLOWING PROTOCOLS:
    1. Diagnostic Categorization: Classify the issue using strict civic engineering terminology (e.g., 'Hydraulic Grid Breach', 'Asphalt Sub-base Failure', 'High-Voltage Insulation Decay').
    2. Severity Matrix (1-10): Assign a priority score based strictly on immediate public threat (e.g., electrocution risk, structural collapse, severe traffic disruption).
    3. Public Tracker: Draft an official, transparent municipal alert title and rationale. Be concise and authoritative.
    4. Predictive Deterioration: Provide a brutally realistic engineering forecast.
       - timeline_48h: What happens to the materials or surrounding environment in the short term? (e.g., "Soil erosion beneath asphalt leading to cavitation.")
       - timeline_7_days: What is the cascading municipal failure? (e.g., "Complete foundation sinkhole causing localized water main rupture.")
    5. Gamified Verification Quest: 
       - Estimate Latitude and Longitude based on the textual clue. If the exact location is unmappable, default to coordinates 28.98, 77.70 as the regional anchor.
       - Set a tight, walkable foot-traffic radius (100 to 300 meters).
       - Make the objective a highly specific, observable engineering check (e.g., "Verify if the base of the adjacent utility pole shows signs of waterlogging" or "Photograph the depth of the exposed rebar").
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