--[[
	AIChat - Handles all chat functionality for the AI
	NOW USES GEMINI API for smart AI responses!
	
	Falls back to built-in responses if API is unavailable
]]

local AIChat = {}
AIChat.__index = AIChat

local HttpService = game:GetService("HttpService")
local Chat = game:GetService("Chat")
local Players = game:GetService("Players")

local Config = require(script.Parent:WaitForChild("AIConfig"))

function AIChat.new(character, head)
	local self = setmetatable({}, AIChat)
	
	self.Character = character
	self.Head = head
	self.IsTalking = false
	self.ChatConnections = {}
	self.ApiAvailable = true  -- Will be set to false if API fails
	
	-- Create BillboardGui for chat bubbles
	self:SetupChatBubble()
	
	-- Test API connection
	if Config.UseApi then
		spawn(function()
			self:TestApiConnection()
		end)
	end
	
	return self
end

-- Test if API is available
function AIChat:TestApiConnection()
	local success, result = pcall(function()
		local response = HttpService:GetAsync(Config.ApiUrl .. "/health")
		local data = HttpService:JSONDecode(response)
		return data.status == "online"
	end)
	
	if success and result then
		self.ApiAvailable = true
		if Config.DebugMode then
			print("[AIChat] ✅ API connected! Using Gemini AI for responses")
		end
	else
		self.ApiAvailable = false
		if Config.DebugMode then
			warn("[AIChat] ⚠️ API not available, using fallback responses")
			warn("[AIChat] Make sure your server is running and ngrok is connected")
		end
	end
end

-- Setup custom chat bubble system
function AIChat:SetupChatBubble()
	local existingGui = self.Head:FindFirstChild("AIChatBubble")
	if existingGui then
		self.ChatBubble = existingGui
		self.ChatLabel = existingGui:FindFirstChild("Background"):FindFirstChild("Label")
		return
	end
	
	-- Create new BillboardGui
	local bubbleGui = Instance.new("BillboardGui")
	bubbleGui.Name = "AIChatBubble"
	bubbleGui.Adornee = self.Head
	bubbleGui.Size = UDim2.new(0, 200, 0, 50)
	bubbleGui.StudsOffset = Vector3.new(0, 3, 0)
	bubbleGui.AlwaysOnTop = true
	bubbleGui.MaxDistance = 50
	bubbleGui.Parent = self.Head
	
	-- Background frame with gradient
	local frame = Instance.new("Frame")
	frame.Name = "Background"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = bubbleGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 50))
	})
	gradient.Rotation = 90
	gradient.Parent = frame
	
	-- Text label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -16, 1, -8)
	label.Position = UDim2.new(0, 8, 0, 4)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 14
	label.Font = Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = ""
	label.Parent = frame
	
	-- AI indicator badge
	local aiTag = Instance.new("TextLabel")
	aiTag.Name = "AITag"
	aiTag.Size = UDim2.new(0, 50, 0, 18)
	aiTag.Position = UDim2.new(0.5, -25, 0, -13)
	aiTag.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
	aiTag.TextColor3 = Color3.white
	aiTag.TextSize = 11
	aiTag.Font = Enum.Font.GothamBold
	aiTag.Text = "🤖 " .. Config.Name
	aiTag.Parent = frame
	
	local tagCorner = Instance.new("UICorner")
	tagCorner.CornerRadius = UDim.new(0, 8)
	tagCorner.Parent = aiTag
	
	bubbleGui.Enabled = false
	
	self.ChatBubble = bubbleGui
	self.ChatLabel = label
	self.ChatFrame = frame
end

-- Call the Gemini API for a response
function AIChat:CallApi(playerName, message)
	if not Config.UseApi or not self.ApiAvailable then
		return nil
	end
	
	local success, result = pcall(function()
		local requestBody = HttpService:JSONEncode({
			player_name = playerName,
			message = message
		})
		
		local response = HttpService:PostAsync(
			Config.ApiUrl .. "/chat",
			requestBody,
			Enum.HttpContentType.ApplicationJson
		)
		
		return HttpService:JSONDecode(response)
	end)
	
	if success then
		if Config.DebugMode then
			print("[AIChat] API Response:", result.response, "| Action:", result.action or "none")
		end
		return result
	else
		if Config.DebugMode then
			warn("[AIChat] API call failed:", result)
		end
		self.ApiAvailable = false
		return nil
	end
end

-- Display a chat message with typing effect
function AIChat:Say(message, duration)
	if self.IsTalking then
		while self.IsTalking do
			wait(0.1)
		end
	end
	
	self.IsTalking = true
	duration = duration or Config.ChatBubbleDuration
	
	self.ChatBubble.Enabled = true
	self.ChatLabel.Text = ""
	
	-- Resize bubble based on message length
	local textLength = string.len(message)
	local width = math.clamp(textLength * 8 + 32, 120, 350)
	local height = math.clamp(math.ceil(textLength / 35) * 22 + 35, 55, 160)
	self.ChatBubble.Size = UDim2.new(0, width, 0, height)
	
	-- Typing effect
	for i = 1, #message do
		if not self.IsTalking then break end
		self.ChatLabel.Text = string.sub(message, 1, i)
		wait(Config.TypingDelay)
	end
	
	-- Also use Roblox's built-in chat bubble
	pcall(function()
		Chat:Chat(self.Head, message, Enum.ChatColor.Blue)
	end)
	
	wait(duration)
	self.ChatBubble.Enabled = false
	self.IsTalking = false
end

-- Quick say without typing effect
function AIChat:QuickSay(message, duration)
	duration = duration or Config.ChatBubbleDuration
	
	self.ChatBubble.Enabled = true
	self.ChatLabel.Text = message
	
	local textLength = string.len(message)
	local width = math.clamp(textLength * 8 + 32, 120, 350)
	local height = math.clamp(math.ceil(textLength / 35) * 22 + 35, 55, 160)
	self.ChatBubble.Size = UDim2.new(0, width, 0, height)
	
	pcall(function()
		Chat:Chat(self.Head, message, Enum.ChatColor.Blue)
	end)
	
	spawn(function()
		wait(duration)
		if self.ChatLabel.Text == message then
			self.ChatBubble.Enabled = false
		end
	end)
end

-- Fallback responses when API is unavailable
local FallbackResponses = {
	greetings = {
		keywords = {"hello", "hi", "hey", "greetings", "sup", "yo"},
		responses = {"Hey there, %s! 👋", "Hello %s! Nice to meet you!", "Hi %s! What's up?"}
	},
	follow = {
		keywords = {"follow me", "come with me", "come here"},
		responses = {"Sure, I'll follow you! 🏃", "On my way, %s!"},
		action = "follow"
	},
	stop = {
		keywords = {"stop", "stay", "wait", "halt"},
		responses = {"Okay, I'll wait here! 👍", "Stopping!"},
		action = "stop"
	},
	dance = {
		keywords = {"dance", "emote", "jump"},
		responses = {"*dances* 💃", "Check out my moves! 🕺"},
		action = "emote"
	},
	joke = {
		keywords = {"joke", "funny", "make me laugh"},
		responses = {"Why do programmers hate nature? It has too many bugs! 🐛", "What do you call 8 hobbits? A hobbyte! 😂"}
	}
}

local DefaultFallbacks = {"That's interesting!", "Tell me more!", "Cool! 😊"}

function AIChat:GetFallbackResponse(playerName, message)
	local lowerMessage = string.lower(message)
	
	for _, category in pairs(FallbackResponses) do
		for _, keyword in ipairs(category.keywords) do
			if string.find(lowerMessage, keyword, 1, true) then
				local response = category.responses[math.random(1, #category.responses)]
				response = string.gsub(response, "%%s", playerName)
				return {
					response = response,
					action = category.action
				}
			end
		end
	end
	
	return {
		response = DefaultFallbacks[math.random(1, #DefaultFallbacks)],
		action = nil
	}
end

-- Process a message from a player and generate response
function AIChat:ProcessMessage(playerName, message)
	-- Try API first
	local apiResponse = self:CallApi(playerName, message)
	
	if apiResponse then
		-- Random delay before responding (more natural)
		local minDelay, maxDelay = Config.ResponseDelay[1], Config.ResponseDelay[2]
		local delay = minDelay + math.random() * (maxDelay - minDelay)
		wait(delay)
		
		self:Say(apiResponse.response)
		
		return {
			message = apiResponse.response,
			action = apiResponse.action,
			emotion = apiResponse.emotion
		}
	else
		-- Fallback to local responses
		local fallback = self:GetFallbackResponse(playerName, message)
		
		wait(0.5)
		self:Say(fallback.response)
		
		return {
			message = fallback.response,
			action = fallback.action
		}
	end
end

-- Setup listener for player chat messages
function AIChat:ListenForMessages(onMessageCallback)
	local function connectPlayer(player)
		player.Chatted:Connect(function(message)
			local mentionsAI = string.lower(message):find(string.lower(Config.Name))
			
			if mentionsAI or onMessageCallback then
				if onMessageCallback then
					onMessageCallback(player, message)
				end
			end
		end)
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		connectPlayer(player)
	end
	
	table.insert(self.ChatConnections, 
		Players.PlayerAdded:Connect(connectPlayer)
	)
end

-- Check if API is working
function AIChat:IsApiAvailable()
	return self.ApiAvailable
end

-- Cleanup connections
function AIChat:Cleanup()
	for _, connection in ipairs(self.ChatConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.ChatConnections = {}
end

return AIChat
