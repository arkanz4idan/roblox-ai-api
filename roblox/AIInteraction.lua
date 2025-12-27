--[[
	AIInteraction - Handles interactions with players and objects
]]

local AIInteraction = {}
AIInteraction.__index = AIInteraction

local Players = game:GetService("Players")
local Config = require(script.Parent:WaitForChild("AIConfig"))

function AIInteraction.new(rootPart)
	local self = setmetatable({}, AIInteraction)
	
	self.RootPart = rootPart
	self.GreetedPlayers = {}
	
	return self
end

-- Get all players within detection radius
function AIInteraction:GetNearbyPlayers()
	local nearbyPlayers = {}
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local distance = (self.RootPart.Position - hrp.Position).Magnitude
				if distance <= Config.DetectionRadius then
					table.insert(nearbyPlayers, {
						player = player,
						distance = distance,
						character = player.Character
					})
				end
			end
		end
	end
	
	table.sort(nearbyPlayers, function(a, b)
		return a.distance < b.distance
	end)
	
	return nearbyPlayers
end

-- Get players within interaction radius
function AIInteraction:GetPlayersInRange()
	local inRange = {}
	
	for _, data in ipairs(self:GetNearbyPlayers()) do
		if data.distance <= Config.InteractionRadius then
			table.insert(inRange, data)
		end
	end
	
	return inRange
end

-- Check if we should greet a player
function AIInteraction:ShouldGreet(playerName)
	if not self.GreetedPlayers[playerName] then
		return true
	end
	
	return (tick() - self.GreetedPlayers[playerName]) >= Config.GreetCooldown
end

-- Mark player as greeted
function AIInteraction:MarkGreeted(playerName)
	self.GreetedPlayers[playerName] = tick()
end

-- Get the closest player
function AIInteraction:GetClosestPlayer()
	local nearby = self:GetNearbyPlayers()
	if #nearby > 0 then
		return nearby[1]
	end
	return nil
end

-- Cleanup old entries
function AIInteraction:Cleanup()
	local currentTime = tick()
	
	for name, timestamp in pairs(self.GreetedPlayers) do
		if (currentTime - timestamp) > (Config.GreetCooldown * 2) then
			self.GreetedPlayers[name] = nil
		end
	end
end

return AIInteraction
