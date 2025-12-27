# Roblox AI NPC Backend

Smart AI backend for Roblox NPCs using **Google Gemini AI** (FREE!)

## Deploy to Render.com (FREE - Runs 24/7!)

### Step 1: Push to GitHub

1. Create a new repository on GitHub
2. Push this folder:
```bash
cd "g:\Coding\Programming Language\PZthon\API"
git init
git add .
git commit -m "Roblox AI Backend"
git remote add origin https://github.com/arkanz4idan/roblox-ai-api.git
git push -u origin main
```

### Step 2: Deploy on Render.com

1. Go to **https://render.com** and sign up (free)
2. Click **New > Web Service**
3. Connect your GitHub repository
4. Settings:
   - **Name**: roblox-ai-api
   - **Runtime**: Python
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### Step 3: Add Your Gemini API Key

1. In Render dashboard, go to **Environment**
2. Add variable: `GEMINI_API_KEY` = your key from https://aistudio.google.com/app/apikey

### Step 4: Get Your URL

Render will give you a URL like: `https://roblox-ai-api.onrender.com`

Use this in your Roblox `AIConfig.lua`:
```lua
AIConfig.ApiUrl = "https://roblox-ai-api.onrender.com"
```

## Files

| File | Purpose |
|------|---------|
| `main.py` | FastAPI server with Gemini AI |
| `requirements.txt` | Python dependencies |
| `Procfile` | Render.com startup config |
| `runtime.txt` | Python version |

## API Endpoints

- `GET /` - Health check
- `POST /chat` - Send message, get AI response
- `GET /docs` - API documentation

---
Get your FREE Gemini key: https://aistudio.google.com/app/apikey
