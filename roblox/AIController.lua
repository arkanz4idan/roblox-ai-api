--[[
	AIController - Main script that brings all AI modules together
	
	SETUP:
	1. Create an NPC with Humanoid and HumanoidRootPart
	2. Place all modules as children of this script
	3. Place this script inside the NPC model
	4. Update APIUrl in AIConfig with your ngrok URL
	5. Run! 🎮
]]

-- Services
local Players = game:GetService("Players")

-- Get the NPC model
local NPC = script.Parent
local Humanoid = NPC:WaitForChild("Humanoid")
local RootPart = NPC:WaitForChild("HumanoidRootPart")
local Head = NPC:WaitForChild("Head")

-- Load modules
local Config = require(script:WaitForChild("AIConfig"))
local Brain = require(script:WaitForChild("AIBrain"))
local AIMovement = require(script:WaitForChild("AIMovement"))
local AIInteraction = require(script:WaitForChild("AIInteraction"))
local AIChat = require(script:WaitForChild("AIChat"))

-- Initialize modules
local Movement = AIMovement.new(Humanoid, RootPart)
local Interaction = AIInteraction.new(RootPart)
local Chat = AIChat.new(NPC, Head)

-- State
local CurrentState = "idle"
local FollowTarget = nil
local LastWanderTime = 0
local LastIdleAction = 0

-- Debug print
local function debugPrint(...)
	if Config.DebugMode then
		print("[" .. Config.Name .. "]", ...)
	end
end

-- Initial greeting
Chat:QuickSay("Hi! I'm " .. Config.Name .. "! Talk to me! 🤖", 3)
debugPrint("AI initialized! API:", Config.UseApi and "Enabled" or "Disabled")

-- Handle player chat
local function onPlayerChat(player, message)
	local character = player.Character
	if not character then return end
	
	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not playerRoot then return end
	
	local distance = (RootPart.Position - playerRoot.Position).Magnitude
	if distance > Config.DetectionRadius then return end
	
	debugPrint("Message from", player.Name, ":", message)
	
	-- Look at the player
	Movement:LookAt(player)
	
	-- Process message and get response
	local response = Chat:ProcessMessage(player.Name, message)
	
	-- Handle actions from response
	if response.action then
		debugPrint("Action:", response.action)
		
		if response.action == "follow" then
			CurrentState = "following"
			FollowTarget = player
			Movement:StartFollowing(player)
			
		elseif response.action == "stop" then
			CurrentState = "idle"
			FollowTarget = nil
			Movement:Stop()
			
		elseif response.action == "emote" then
			Humanoid.Jump = true
		end
	end
end

-- Connect to player chat
for _, player in ipairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		onPlayerChat(player, message)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		onPlayerChat(player, message)
	end)
end)

-- Main AI loop
while true do
	local currentTime = tick()
	local nearbyPlayers = Interaction:GetNearbyPlayers()
	local playersInRange = Interaction:GetPlayersInRange()
	
	-- STATE: Following
	if CurrentState == "following" and FollowTarget then
		if not FollowTarget.Parent or not FollowTarget.Character then
			CurrentState = "idle"
			FollowTarget = nil
			Movement:Stop()
			Chat:QuickSay("Oh, they left...", 2)
		end
		
	-- STATE: Idle
	elseif CurrentState == "idle" then
		
		-- Greet nearby players
		if Config.CanGreetPlayers then
			for _, data in ipairs(playersInRange) do
				if Interaction:ShouldGreet(data.player.Name) then
					Movement:LookAt(data.player)
					Chat:Say(Brain:GetGreeting(data.player.Name))
					Interaction:MarkGreeted(data.player.Name)
					break
				end
			end
		end
		
		-- Random idle actions
		if currentTime - LastIdleAction > 15 then
			LastIdleAction = currentTime
			local idleAction = Brain:GetIdleAction()
			if idleAction.type == "say" then
				Chat:QuickSay(idleAction.message, 2)
			end
		end
		
		-- Wander
		if Config.CanWander and not Movement:GetIsMoving() then
			local interval = math.random(Config.WanderInterval[1], Config.WanderInterval[2])
			if currentTime - LastWanderTime > interval then
				LastWanderTime = currentTime
				Movement:Wander()
			end
		end
	end
	
	-- Cleanup periodically
	if math.floor(currentTime) % 60 == 0 then
		Interaction:Cleanup()
	end
	
	wait(0.5)
end
