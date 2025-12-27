--[[
	AIMovement - Handles all AI movement including pathfinding, wandering, and following
]]

local AIMovement = {}
AIMovement.__index = AIMovement

local PathfindingService = game:GetService("PathfindingService")
local Config = require(script.Parent:WaitForChild("AIConfig"))

function AIMovement.new(humanoid, rootPart)
	local self = setmetatable({}, AIMovement)
	
	self.Humanoid = humanoid
	self.RootPart = rootPart
	self.SpawnPosition = rootPart.Position
	self.IsMoving = false
	self.FollowTarget = nil
	
	self.PathParams = {
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
	}
	
	return self
end

-- Compute a path to destination
function AIMovement:ComputePath(destination)
	local path = PathfindingService:CreatePath(self.PathParams)
	
	local success = pcall(function()
		path:ComputeAsync(self.RootPart.Position, destination)
	end)
	
	if success and path.Status == Enum.PathStatus.Success then
		return path
	end
	return nil
end

-- Move to a specific position
function AIMovement:MoveTo(destination)
	if self.IsMoving then
		self:Stop()
	end
	
	local path = self:ComputePath(destination)
	if not path then
		self.Humanoid:MoveTo(destination)
		return false
	end
	
	self.IsMoving = true
	local waypoints = path:GetWaypoints()
	
	spawn(function()
		for i = 2, #waypoints do
			if not self.IsMoving then break end
			
			local waypoint = waypoints[i]
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				self.Humanoid.Jump = true
			end
			
			self.Humanoid:MoveTo(waypoint.Position)
			self.Humanoid.MoveToFinished:Wait()
		end
		self.IsMoving = false
	end)
	
	return true
end

-- Wander to a random nearby location
function AIMovement:Wander()
	local angle = math.random() * math.pi * 2
	local distance = math.random(10, Config.WanderRadius)
	
	local offset = Vector3.new(
		math.cos(angle) * distance,
		0,
		math.sin(angle) * distance
	)
	
	local destination = self.SpawnPosition + offset
	
	-- Raycast down to find ground
	local rayOrigin = destination + Vector3.new(0, 50, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {self.RootPart.Parent}
	
	local result = workspace:Raycast(rayOrigin, Vector3.new(0, -100, 0), rayParams)
	if result then
		destination = result.Position + Vector3.new(0, 3, 0)
	end
	
	return self:MoveTo(destination)
end

-- Start following a player
function AIMovement:StartFollowing(target)
	self.FollowTarget = target
	self.IsMoving = true
	
	spawn(function()
		while self.FollowTarget and self.IsMoving do
			local targetPosition = nil
			
			if target:IsA("Player") and target.Character then
				local hrp = target.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					targetPosition = hrp.Position
				end
			end
			
			if targetPosition then
				local distance = (self.RootPart.Position - targetPosition).Magnitude
				
				if distance > Config.FollowDistance then
					local direction = (targetPosition - self.RootPart.Position).Unit
					local destination = targetPosition - direction * Config.FollowDistance
					self.Humanoid:MoveTo(destination)
				end
			end
			
			wait(0.5)
		end
	end)
end

-- Stop following
function AIMovement:StopFollowing()
	self.FollowTarget = nil
end

-- Stop all movement
function AIMovement:Stop()
	self.IsMoving = false
	self.FollowTarget = nil
	self.Humanoid:MoveTo(self.RootPart.Position)
end

-- Look at a target
function AIMovement:LookAt(target)
	local targetPosition
	
	if typeof(target) == "Vector3" then
		targetPosition = target
	elseif target:IsA("Player") and target.Character then
		local hrp = target.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			targetPosition = hrp.Position
		end
	end
	
	if targetPosition then
		local lookCF = CFrame.lookAt(self.RootPart.Position, Vector3.new(targetPosition.X, self.RootPart.Position.Y, targetPosition.Z))
		self.RootPart.CFrame = lookCF
	end
end

function AIMovement:GetIsMoving()
	return self.IsMoving
end

function AIMovement:GetFollowTarget()
	return self.FollowTarget
end

return AIMovement
