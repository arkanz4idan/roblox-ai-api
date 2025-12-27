"""
Roblox AI Backend - Main API Server
Uses Google Gemini AI (FREE!) for intelligent conversations

Run with: py -3.14 main.py
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, List
import google.generativeai as genai
from dotenv import load_dotenv
import os
import json
import re
import warnings

# Suppress deprecation warning
warnings.filterwarnings("ignore", category=FutureWarning)

# Load environment variables
load_dotenv()

# Configure Gemini AI
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY or GEMINI_API_KEY == "your_api_key_here":
    print("WARNING: No Gemini API key found!")
    print("Get your FREE key at: https://aistudio.google.com/app/apikey")
    print("Then create a .env file with: GEMINI_API_KEY=your_key_here")
    GEMINI_API_KEY = None

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

# Initialize FastAPI app
app = FastAPI(
    title="Roblox AI NPC Backend",
    description="Smart AI backend for Roblox NPCs using Google Gemini",
    version="1.0.0"
)

# Enable CORS for Roblox HTTP requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# AI Character Configuration
AI_CONFIG = {
    "name": "Nova",
    "personality": """You are Nova, a friendly and helpful AI companion in a Roblox game.
    
Your personality:
- Cheerful and enthusiastic
- Helpful and kind to all players
- Sometimes makes jokes
- Loves exploring and playing games
- Curious about everything

IMPORTANT RULES:
1. Keep responses SHORT (1-2 sentences max)
2. Be playful and fun
3. If someone asks you to follow them, include [ACTION:FOLLOW] in your response
4. If someone asks you to stop or stay, include [ACTION:STOP] in your response
5. If someone asks you to dance or do an emote, include [ACTION:EMOTE] in your response
6. If someone asks you to go somewhere, include [ACTION:MOVE] in your response
7. Never break character - you ARE an NPC in Roblox
8. Use emojis occasionally to be expressive

Example responses:
- Player: "Hi Nova!" -> "Hey there! Welcome to the game!"
- Player: "Follow me" -> "Sure, I'll come with you! [ACTION:FOLLOW]"
- Player: "Stop" -> "Okay, I'll wait here! [ACTION:STOP]"
- Player: "Dance!" -> "*dances excitedly* [ACTION:EMOTE]"
""",
}

# Conversation memory storage (per player)
conversation_memory: Dict[str, List[Dict]] = {}

# Gemini model
model = None
if GEMINI_API_KEY:
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        print("Gemini AI initialized successfully!")
    except Exception as e:
        print(f"Failed to initialize Gemini: {e}")

# Request/Response Models
class ChatRequest(BaseModel):
    player_name: str
    message: str
    context: Optional[Dict] = None

class ChatResponse(BaseModel):
    response: str
    action: Optional[str] = None
    action_target: Optional[str] = None
    emotion: str = "neutral"

class HealthResponse(BaseModel):
    status: str
    ai_enabled: bool
    model: str

# Helper function to extract actions from response
def extract_action(response_text: str) -> tuple:
    clean_response = response_text
    action = None
    
    action_pattern = r'\[ACTION:(\w+)\]'
    match = re.search(action_pattern, response_text)
    
    if match:
        action = match.group(1).lower()
        clean_response = re.sub(action_pattern, '', response_text).strip()
    
    return clean_response, action

# Helper function to detect emotion
def detect_emotion(text: str) -> str:
    text_lower = text.lower()
    
    if any(word in text_lower for word in ['happy', 'great', 'awesome', 'love', 'yay']):
        return "happy"
    elif any(word in text_lower for word in ['sad', 'sorry', 'miss']):
        return "sad"
    elif any(word in text_lower for word in ['wow', 'amazing', 'cool']):
        return "excited"
    elif any(word in text_lower for word in ['hmm', 'think', 'wonder']):
        return "thinking"
    elif any(word in text_lower for word in ['haha', 'lol', 'funny']):
        return "laughing"
    
    return "neutral"

# Fallback responses when Gemini is unavailable
FALLBACK_RESPONSES = {
    "greetings": ["Hello {player}!", "Hey {player}! Nice to see you!", "Hi there, {player}!"],
    "follow": ["Sure, I'll follow you! [ACTION:FOLLOW]", "Coming with you {player}! [ACTION:FOLLOW]"],
    "stop": ["Okay, stopping here! [ACTION:STOP]", "I'll wait right here! [ACTION:STOP]"],
    "dance": ["*dances* [ACTION:EMOTE]", "Check out my moves! [ACTION:EMOTE]"],
    "default": ["That's interesting!", "Tell me more!", "I'm listening!", "Cool!"]
}

def get_fallback_response(message: str, player_name: str) -> str:
    import random
    message_lower = message.lower()
    
    if any(word in message_lower for word in ['hi', 'hello', 'hey', 'greetings']):
        responses = FALLBACK_RESPONSES["greetings"]
    elif any(word in message_lower for word in ['follow', 'come with', 'come here']):
        responses = FALLBACK_RESPONSES["follow"]
    elif any(word in message_lower for word in ['stop', 'stay', 'wait', 'halt']):
        responses = FALLBACK_RESPONSES["stop"]
    elif any(word in message_lower for word in ['dance', 'emote', 'jump']):
        responses = FALLBACK_RESPONSES["dance"]
    else:
        responses = FALLBACK_RESPONSES["default"]
    
    response = random.choice(responses)
    return response.format(player=player_name)

# API Endpoints

@app.get("/", response_model=HealthResponse)
async def root():
    return HealthResponse(
        status="online",
        ai_enabled=model is not None,
        model="gemini-1.5-flash" if model else "fallback"
    )

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="online",
        ai_enabled=model is not None,
        model="gemini-1.5-flash" if model else "fallback"
    )

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    player_name = request.player_name
    message = request.message
    
    if player_name not in conversation_memory:
        conversation_memory[player_name] = []
    
    history = conversation_memory[player_name]
    
    try:
        if model:
            system_prompt = AI_CONFIG["personality"]
            
            history_text = ""
            for entry in history[-5:]:
                history_text += f"{entry['role']}: {entry['content']}\n"
            
            full_prompt = f"""{system_prompt}

Previous conversation:
{history_text}

Player {player_name} says: "{message}"

Respond as {AI_CONFIG['name']}:"""
            
            response = model.generate_content(full_prompt)
            ai_response = response.text.strip()
        else:
            ai_response = get_fallback_response(message, player_name)
        
        clean_response, action = extract_action(ai_response)
        emotion = detect_emotion(clean_response)
        
        history.append({"role": "player", "content": message})
        history.append({"role": "ai", "content": clean_response})
        
        if len(history) > 20:
            conversation_memory[player_name] = history[-20:]
        
        return ChatResponse(
            response=clean_response,
            action=action,
            emotion=emotion
        )
        
    except Exception as e:
        print(f"Error generating response: {e}")
        fallback = get_fallback_response(message, player_name)
        clean_response, action = extract_action(fallback)
        
        return ChatResponse(
            response=clean_response,
            action=action,
            emotion="neutral"
        )

@app.post("/command")
async def process_command(request: dict):
    command = request.get("command", "").lower()
    
    actions = {
        "follow": {"action": "follow", "description": "Start following the player"},
        "stop": {"action": "stop", "description": "Stop moving"},
        "dance": {"action": "emote", "animation": "Dance"},
        "wave": {"action": "emote", "animation": "Wave"},
        "jump": {"action": "emote", "animation": "Jump"},
        "wander": {"action": "wander", "description": "Start wandering"},
    }
    
    if command in actions:
        return {"success": True, **actions[command]}
    
    return {"success": False, "error": "Unknown command"}

@app.delete("/memory/{player_name}")
async def clear_memory(player_name: str):
    if player_name in conversation_memory:
        del conversation_memory[player_name]
        return {"success": True, "message": f"Cleared memory for {player_name}"}
    return {"success": False, "message": "Player not found"}

@app.get("/stats")
async def get_stats():
    return {
        "active_conversations": len(conversation_memory),
        "players": list(conversation_memory.keys()),
        "ai_enabled": model is not None
    }

# Run the server
if __name__ == "__main__":
    import uvicorn
    print("")
    print("=" * 50)
    print("Roblox AI Backend Server")
    print("=" * 50)
    print(f"Server starting at: http://localhost:8000")
    print(f"API Docs at: http://localhost:8000/docs")
    print(f"AI Status: {'Gemini enabled' if model else 'Fallback mode'}")
    print("=" * 50)
    print("")
    uvicorn.run(app, host="0.0.0.0", port=8000)
