--[[
	AIConfig - Configuration module for the Roblox AI
	Place this as a ModuleScript in ServerScriptService or inside the NPC model
	
	🔥 NOW WITH API SUPPORT - Uses Gemini AI for smart responses!
]]

local AIConfig = {}

-- AI Identity
AIConfig.Name = "Nova"  -- AI's name
AIConfig.Personality = "friendly"  -- friendly, sarcastic, helpful, shy

-- 🌐 API SETTINGS (IMPORTANT!)
-- For local testing, use ngrok to expose your server
-- Get ngrok at: https://ngrok.com/download
-- Run: ngrok http 8000
-- Then paste the URL here (e.g., "https://abc123.ngrok.io")
AIConfig.ApiUrl = "http://localhost:8000"  -- Change this to your ngrok URL!
AIConfig.UseApi = true  -- Set to false to use built-in responses only

-- Movement Settings
AIConfig.WalkSpeed = 12
AIConfig.RunSpeed = 20
AIConfig.WanderRadius = 50  -- How far AI can wander from spawn
AIConfig.WanderInterval = {5, 15}  -- Random time between wanders (min, max seconds)
AIConfig.FollowDistance = 5  -- How close to stay when following

-- Interaction Settings
AIConfig.DetectionRadius = 30  -- How far AI can detect players
AIConfig.InteractionRadius = 8  -- How close for interaction
AIConfig.GreetCooldown = 60  -- Seconds before greeting same player again

-- Chat Settings
AIConfig.ChatBubbleDuration = 5  -- How long chat bubbles stay
AIConfig.TypingDelay = 0.03  -- Delay between characters (typing effect)
AIConfig.ResponseDelay = {0.5, 1.5}  -- Random delay before responding

-- Behavior Flags
AIConfig.CanWander = true
AIConfig.CanFollow = true
AIConfig.CanInteractWithObjects = true
AIConfig.CanGreetPlayers = true
AIConfig.CanRespondToChat = true

-- Debug
AIConfig.DebugMode = true  -- Enable to see API responses in output

return AIConfig
