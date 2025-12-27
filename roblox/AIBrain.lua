--[[
	AIBrain - Built-in AI logic (used when API is unavailable)
	Now mostly used as fallback since Gemini handles responses
]]

local AIBrain = {}

local Config = require(script.Parent:WaitForChild("AIConfig"))

-- Conversation memory for each player
AIBrain.Memory = {}

-- Initialize memory for a player
function AIBrain:InitializeMemory(playerName)
	if not self.Memory[playerName] then
		self.Memory[playerName] = {
			conversationCount = 0,
			lastInteraction = 0,
		}
	end
end

-- Decide what action to take based on current state
function AIBrain:DecideAction(context)
	local decision = {
		action = "idle",
		target = nil,
		priority = 0,
	}
	
	-- Priority 1: Follow target if set
	if context.followTarget then
		decision.action = "follow"
		decision.target = context.followTarget
		decision.priority = 2
		return decision
	end
	
	-- Priority 2: Greet nearby players
	if Config.CanGreetPlayers and context.nearbyPlayers and #context.nearbyPlayers > 0 then
		for _, player in ipairs(context.nearbyPlayers) do
			if not context.greetedPlayers[player.Name] then
				decision.action = "greet"
				decision.target = player
				decision.priority = 3
				return decision
			end
		end
	end
	
	-- Priority 3: Wander around
	if Config.CanWander and context.canWander then
		decision.action = "wander"
		decision.priority = 5
		return decision
	end
	
	return decision
end

-- Get a random greeting for a player
function AIBrain:GetGreeting(playerName)
	local greetings = {
		"Hey " .. playerName .. "! Welcome! 👋",
		"Oh hi there, " .. playerName .. "!",
		"*waves at " .. playerName .. "*",
		playerName .. "! Nice to see you!",
	}
	return greetings[math.random(1, #greetings)]
end

-- Get an idle action
function AIBrain:GetIdleAction()
	local actions = {
		{type = "say", message = "*looks around curiously*"},
		{type = "say", message = "*hums a little tune*"},
		{type = "none"},
		{type = "none"},
	}
	return actions[math.random(1, #actions)]
end

return AIBrain
