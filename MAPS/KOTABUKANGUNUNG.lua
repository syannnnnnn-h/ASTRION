-- ============================================================
-- ASTRIONHUB V2.7 - SMOOTH ROTATION FIXED VERSION
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local hrp = nil

local Packs = {
    lucide = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))(),
    craft  = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua"))(),
    geist  = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua"))(),
}

local function refreshHRP(char)
    if not char then
        char = player.Character or player.CharacterAdded:Wait()
    end
    hrp = char:WaitForChild("HumanoidRootPart")
end
if player.Character then refreshHRP(player.Character) end
player.CharacterAdded:Connect(refreshHRP)

-- ============================================================
-- GLOBAL STATE VARIABLES
-- ============================================================
local mainFolder = "ASTRIONHUB"
if not isfolder(mainFolder) then makefolder(mainFolder) end

local playbackRate = 1.0
local isRunning = false
local routes = {}
local isLooping = false
local heightOffset = 0
local isPaused = false
local isPlaying = false
local isFlipped = false
local FLIP_SMOOTHNESS = 0.03
local currentFlipRotation = CFrame.new()

local floatingUI = nil
local floatingVisible = false

-- Improved Smoothing constants - FIXED FOR ROTATION
local POSITION_SMOOTH = 0.85
local VELOCITY_SMOOTH = 0.80
local MOVE_SMOOTH = 0.88
local ROTATION_SMOOTH = 0.12  -- Lebih smooth untuk rotasi natural
local ROTATION_FLIP_SMOOTH = 0.06  -- Extra smooth untuk flip rotation

-- ============================================================
-- PRESERVE ORIGINAL JUMP POWER - FIXED VERSION
-- ============================================================
local originalJumpPower = nil
local originalJumpHeight = nil
local jumpSettingsSaved = false

local function preserveJumpSettings()
    if jumpSettingsSaved then return end
    
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if humanoid.UseJumpPower then
        originalJumpPower = humanoid.JumpPower
        print(string.format("💾 Original JumpPower Saved: %.2f", originalJumpPower))
    else
        originalJumpHeight = humanoid.JumpHeight
        print(string.format("💾 Original JumpHeight Saved: %.2f", originalJumpHeight))
    end
    
    jumpSettingsSaved = true
end

local function restoreJumpSettings()
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if originalJumpPower and humanoid.UseJumpPower then
        humanoid.JumpPower = originalJumpPower
        print(string.format("✅ JumpPower Restored: %.2f", originalJumpPower))
    elseif originalJumpHeight and not humanoid.UseJumpPower then
        humanoid.JumpHeight = originalJumpHeight
        print(string.format("✅ JumpHeight Restored: %.2f", originalJumpHeight))
    end
end

-- Save jump settings immediately
if player.Character then
    task.wait(0.1)
    preserveJumpSettings()
end

player.CharacterAdded:Connect(function()
    jumpSettingsSaved = false
    task.wait(0.1)
    preserveJumpSettings()
end)

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function vecToTable(v3)
    return {x = v3.X, y = v3.Y, z = v3.Z}
end

local function tableToVec(t)
    return Vector3.new(t.x, t.y, t.z)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpVector(a, b, t)
    return Vector3.new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t), lerp(a.Z, b.Z, t))
end

local function lerpAngle(a, b, t)
    local diff = (b - a)
    while diff > math.pi do diff = diff - 2*math.pi end
    while diff < -math.pi do diff = diff + 2*math.pi end
    return a + diff * t
end

-- ============================================================
-- SMOOTH RUNNING TO POSITION
-- ============================================================
local function smoothRunToPosition(targetPos, timeout)
    local char = player.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return false end
    
    local startTime = tick()
    local maxTime = timeout or 15
    local reached = false
    
    print("🏃 Running to position...")
    
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    local moveConnection
    moveConnection = RunService.Heartbeat:Connect(function(dt)
        if not hrp or not hrp.Parent or not humanoid or not humanoid.Parent then
            if moveConnection then moveConnection:Disconnect() end
            return
        end
        
        local currentPos = hrp.Position
        local direction = (targetPos - currentPos)
        local distance = direction.Magnitude
        
        if distance < 5 then
            reached = true
            humanoid:Move(Vector3.zero, false)
            if moveConnection then moveConnection:Disconnect() end
            print("✅ Reached position!")
            return
        end
        
        if tick() - startTime > maxTime then
            print("⏱️ Timeout reaching position, continuing anyway...")
            reached = true
            humanoid:Move(Vector3.zero, false)
            if moveConnection then moveConnection:Disconnect() end
            return
        end
        
        local flatDirection = Vector3.new(direction.X, 0, direction.Z)
        if flatDirection.Magnitude > 0.1 then
            flatDirection = flatDirection.Unit
            
            local lookPos = Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)
            local targetCFrame = CFrame.lookAt(currentPos, lookPos)
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, 0.3)
            
            humanoid:Move(flatDirection, false)
            
            local forwardVel = flatDirection * 18
            hrp.AssemblyLinearVelocity = Vector3.new(forwardVel.X, hrp.AssemblyLinearVelocity.Y, forwardVel.Z)
        end
    end)
    
    while not reached and (tick() - startTime) < maxTime do
        task.wait(0.1)
    end
    
    if moveConnection then
        moveConnection:Disconnect()
    end
    
    if humanoid and humanoid.Parent then
        humanoid:Move(Vector3.zero, false)
    end
    
    return reached
end

-- ============================================================
-- FINE-TUNED JUMP DETECTOR V2.7
-- ============================================================
local JumpDetector = {}
JumpDetector.__index = JumpDetector

function JumpDetector.new()
    local self = setmetatable({}, JumpDetector)
    self.lastJumpTime = 0
    self.jumpCooldown = 0
    self.lastJumpBool = false
    self.lastYVelocity = 0
    self.consecutiveUpwardFrames = 0
    self.wasGrounded = true
    self.jumpRequested = false
    self.framesSinceJumpRequest = 0
    self.lastState = "Running"
    self.stateTransitionTime = 0
    self.velocityHistory = {}
    return self
end

function JumpDetector:ShouldJump(data, currentIndex, frame0, frame1, interpVel, currentTime, humanoid)
    if self.jumpCooldown > 0 then
        self.jumpCooldown = self.jumpCooldown - 0.016
    end
    
    if self.framesSinceJumpRequest > 0 then
        self.framesSinceJumpRequest = self.framesSinceJumpRequest + 1
        if self.framesSinceJumpRequest > 12 then
            self.jumpRequested = false
            self.framesSinceJumpRequest = 0
        end
    end
    
    local currentState = frame0.state or "Running"
    if currentState == "Climbing" then
        return false
    end
    
    local currentYVel = interpVel.Y
    table.insert(self.velocityHistory, currentYVel)
    if #self.velocityHistory > 3 then
        table.remove(self.velocityHistory, 1)
    end
    
    local stateChanged = (currentState ~= self.lastState)
    local currentRealTime = tick()
    if stateChanged then
        self.stateTransitionTime = currentRealTime
    end
    
    -- METHOD 1: BOOLEAN FLIP DETECTION
    local currentJumpBool = frame0.jumping or false
    local nextJumpBool = frame1.jumping or false
    local booleanFlip = (not self.lastJumpBool) and (currentJumpBool or nextJumpBool)
    
    -- METHOD 2: STATE TRANSITION
    local stateJumpTransition = false
    local nextState = frame1.state or "Running"
    
    if stateChanged then
        if (self.lastState == "Running" or self.lastState == "Landed" or self.lastState == "RunningNoPhysics") then
            if currentState == "Jumping" then
                stateJumpTransition = true
            end
        end
    end
    
    if (currentState == "Running" or currentState == "Landed" or currentState == "RunningNoPhysics") then
        if nextState == "Jumping" then
            stateJumpTransition = true
        end
    end
    
    -- METHOD 3: VELOCITY ANALYSIS
    local velocityJump = false
    local velocityDelta = currentYVel - self.lastYVelocity
    
    if currentYVel > 22 and self.lastYVelocity < 10 then
        velocityJump = true
        self.consecutiveUpwardFrames = self.consecutiveUpwardFrames + 1
    elseif currentYVel > 18 and velocityDelta > 12 then
        if #self.velocityHistory >= 2 then
            local prevVel = self.velocityHistory[#self.velocityHistory - 1] or 0
            local prevPrevVel = self.velocityHistory[#self.velocityHistory - 2] or 0
            
            if prevVel > prevPrevVel and currentYVel > prevVel then
                velocityJump = true
                self.consecutiveUpwardFrames = self.consecutiveUpwardFrames + 1
            end
        end
    elseif currentYVel > 16 and self.lastYVelocity < 3 and velocityDelta > 10 then
        velocityJump = true
        self.consecutiveUpwardFrames = self.consecutiveUpwardFrames + 1
    else
        if currentYVel < 15 then
            self.consecutiveUpwardFrames = 0
        end
    end
    
    local confirmedVelocityJump = velocityJump and self.consecutiveUpwardFrames >= 2
    
    -- METHOD 4: GROUNDED TRANSITION
    local currentlyGrounded = (currentState == "Running" or currentState == "RunningNoPhysics" or currentState == "Landed")
    local groundedToAirTransition = self.wasGrounded and not currentlyGrounded and currentYVel > 16
    
    if groundedToAirTransition then
        local timeSinceTransition = currentRealTime - self.stateTransitionTime
        if timeSinceTransition > 0.25 then
            groundedToAirTransition = false
        end
    end
    
    -- METHOD 5: LOOKAHEAD CHECK
    local lookaheadJump = false
    if nextState == "Jumping" and currentState ~= "Jumping" then
        if currentYVel > 10 or nextJumpBool then
            lookaheadJump = true
        end
    end
    
    -- DECISION LOGIC
    local shouldJump = false
    local reason = ""
    
    if self.jumpCooldown <= 0 then
        if booleanFlip then
            shouldJump = true
            reason = "Boolean Flip"
        elseif stateJumpTransition and not self.jumpRequested then
            shouldJump = true
            reason = "State Transition"
        elseif lookaheadJump and not self.jumpRequested then
            shouldJump = true
            reason = "Lookahead"
        elseif confirmedVelocityJump and not self.jumpRequested then
            shouldJump = true
            reason = "Velocity Spike"
        elseif groundedToAirTransition and not self.jumpRequested then
            shouldJump = true
            reason = "Ground Transition"
        end
    end
    
    self.lastJumpBool = currentJumpBool or nextJumpBool
    self.lastYVelocity = currentYVel
    self.wasGrounded = currentlyGrounded
    self.lastState = currentState
    
    if shouldJump then
        self.jumpCooldown = 0.28
        self.jumpRequested = true
        self.framesSinceJumpRequest = 1
        print(string.format("🎯 Jump detected: %s (Y-Vel: %.1f)", reason, currentYVel))
    end
    
    return shouldJump
end

function JumpDetector:ExecuteJump(humanoid)
    if not humanoid then return false end
    
    local currentState = humanoid:GetState()
    
    if currentState == Enum.HumanoidStateType.Climbing then
        return false
    end
    
    local validStates = {
        [Enum.HumanoidStateType.Running] = true,
        [Enum.HumanoidStateType.RunningNoPhysics] = true,
        [Enum.HumanoidStateType.Landed] = true,
        [Enum.HumanoidStateType.Freefall] = true,
    }
    
    if validStates[currentState] then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        print("✅ Jump executed!")
        return true
    end
    
    return false
end

-- ============================================================
-- LOAD JSON ROUTES
-- ============================================================
local function loadRoute(url, routeName)
    local ok, res = pcall(function() 
        return game:HttpGet(url) 
    end)
    
    if ok and res and #res > 0 then
        local success, result = pcall(function()
            return HttpService:JSONDecode(res)
        end)
        if success then
            print("✅ Route loaded from URL: " .. routeName)
            return result
        end
    end
    
    warn("❌ Failed to load route: " .. routeName)
    return nil
end

-- ============================================================
-- ROUTE CONFIGURATION
-- ============================================================
routes = {
    {
        name = "BASE → CP8",
        url = "https://raw.githubusercontent.com/v0ydxfc6666/json/refs/heads/main/KBG.json",
        data = nil
    },
}

for i, route in ipairs(routes) do
    route.data = loadRoute(route.url, route.name)
end

-- ============================================================
-- FIND NEAREST FUNCTIONS
-- ============================================================
local function findClosestFrameIndex(data, currentPos)
    local closestIndex = 1
    local closestDistance = math.huge
    
    for i, frame in ipairs(data) do
        local framePos = tableToVec(frame.position)
        local distance = (currentPos - framePos).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestIndex = i
        end
    end
    
    return closestIndex, closestDistance
end

-- ============================================================
-- PLAYBACK SYSTEM WITH SMOOTH ROTATION FIX
-- ============================================================
local function findSurroundingFrames(data, t)
    if #data == 0 then return nil, nil, 0 end
    if t <= data[1].time then return 1, 1, 0 end
    if t >= data[#data].time then return #data, #data, 0 end

    local left, right = 1, #data
    while left < right - 1 do
        local mid = math.floor((left + right) / 2)
        if data[mid].time <= t then
            left = mid
        else
            right = mid
        end
    end

    local i0, i1 = left, right
    local span = data[i1].time - data[i0].time
    local alpha = span > 0 and math.clamp((t - data[i0].time) / span, 0, 1) or 0

    return i0, i1, alpha
end

local function playRouteData(data, onComplete)
    if not data or #data == 0 then 
        if onComplete then onComplete() end
        return 
    end
    if not hrp then refreshHRP() end
    
    local char = player.Character
    if not char then 
        if onComplete then onComplete() end
        return 
    end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then 
        if onComplete then onComplete() end
        return 
    end
    
    isRunning = true
    isPlaying = true
    
    -- DON'T MODIFY JUMP SETTINGS DURING PLAYBACK
    preserveJumpSettings()
    
    if data[1] then
        local currentHipHeight = humanoid.HipHeight
        local recordedHipHeight = data[1].hipHeight or 2
        heightOffset = currentHipHeight - recordedHipHeight
        
        print(string.format("🎭 Avatar Detected - Current: %.2f | Recorded: %.2f | Offset: %.2f", 
            currentHipHeight, recordedHipHeight, heightOffset))
    end
    
    local startIndex, distance = findClosestFrameIndex(data, hrp.Position)
    
    print("📍 Distance to nearest point: " .. math.floor(distance) .. " studs")
    
    if distance > 5 then
        print("🏃 Distance > 5 studs, running to nearest point...")
        local startPos = tableToVec(data[startIndex].position)
        local reached = smoothRunToPosition(startPos, 15)
        if reached then
            task.wait(0.3)
        end
    else
        print("✅ Already near track (< 5 studs), starting immediately!")
    end
    
    local accumulatedTime = data[startIndex].time or 0
    local lastPlaybackTime = tick()
    
    local jumpDetector = JumpDetector.new()
    
    local positionBuffer = {}
    local velocityBuffer = {}
    local rotationBuffer = {}
    local moveBuffer = {}
    local bufferSize = 10  -- Increased buffer for smoother rotation
    
    -- SMOOTH ROTATION STATE
    local currentSmoothedYaw = 0
    local lastRawYaw = 0
    local rotationInitialized = false
    
    local playbackConnection
    playbackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not isRunning then
            if playbackConnection then
                playbackConnection:Disconnect()
            end
            if onComplete then onComplete() end
            return
        end
        
        if isPaused then
            if humanoid then
                humanoid:Move(Vector3.zero, false)
            end
            return
        end
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            isRunning = false
            if onComplete then onComplete() end
            return
        end
        
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        
        local currentTime = tick()
        local actualDelta = math.min(currentTime - lastPlaybackTime, 0.1)
        lastPlaybackTime = currentTime
        accumulatedTime = accumulatedTime + (actualDelta * playbackRate)
        
        if accumulatedTime > data[#data].time then
            isRunning = false
            if playbackConnection then
                playbackConnection:Disconnect()
            end
            if onComplete then onComplete() end
            return
        end
        
        local i0, i1, alpha = findSurroundingFrames(data, accumulatedTime)
        local f0, f1 = data[i0], data[i1]
        if not f0 or not f1 then return end
        
        local pos0, pos1 = tableToVec(f0.position), tableToVec(f1.position)
        local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
        local interpPos = lerpVector(pos0, pos1, smoothAlpha)
        
        local vel0 = f0.velocity and tableToVec(f0.velocity) or Vector3.new(0,0,0)
        local vel1 = f1.velocity and tableToVec(f1.velocity) or Vector3.new(0,0,0)
        local interpVel = lerpVector(vel0, vel1, smoothAlpha)
        
        local move0 = f0.moveDirection and tableToVec(f0.moveDirection) or Vector3.new(0,0,0)
        local move1 = f1.moveDirection and tableToVec(f1.moveDirection) or Vector3.new(0,0,0)
        local interpMove = lerpVector(move0, move1, smoothAlpha)
        
        -- SMOOTH ROTATION LOGIC - FIXED
        local yaw0, yaw1 = f0.rotation or 0, f1.rotation or 0
        local rawInterpYaw = lerpAngle(yaw0, yaw1, smoothAlpha)
        
        -- Initialize smooth yaw on first frame
        if not rotationInitialized then
            currentSmoothedYaw = rawInterpYaw
            lastRawYaw = rawInterpYaw
            rotationInitialized = true
        end
        
        -- Detect sudden rotation changes (like flip in JSON)
        local yawDelta = math.abs(lerpAngle(lastRawYaw, rawInterpYaw, 1))
        local isFlipRotation = yawDelta > math.pi * 0.5  -- Deteksi rotasi > 90 derajat
        
        -- Apply different smoothing based on rotation type
        local rotationSmoothFactor = isFlipRotation and ROTATION_FLIP_SMOOTH or ROTATION_SMOOTH
        currentSmoothedYaw = lerpAngle(currentSmoothedYaw, rawInterpYaw, rotationSmoothFactor)
        
        lastRawYaw = rawInterpYaw
        
        table.insert(positionBuffer, interpPos)
        table.insert(velocityBuffer, interpVel)
        table.insert(rotationBuffer, currentSmoothedYaw)  -- Use smoothed yaw
        table.insert(moveBuffer, interpMove)
        
        if #positionBuffer > bufferSize then table.remove(positionBuffer, 1) end
        if #velocityBuffer > bufferSize then table.remove(velocityBuffer, 1) end
        if #rotationBuffer > bufferSize then table.remove(rotationBuffer, 1) end
        if #moveBuffer > bufferSize then table.remove(moveBuffer, 1) end
        
        local avgPos = Vector3.new(0, 0, 0)
        local avgVel = Vector3.new(0, 0, 0)
        local avgYaw = 0
        local avgMove = Vector3.new(0, 0, 0)
        local totalWeight = 0
        
        for i, pos in ipairs(positionBuffer) do
            local weight = i / #positionBuffer
            avgPos = avgPos + (pos * weight)
            totalWeight = totalWeight + weight
        end
        avgPos = avgPos / totalWeight
        
        totalWeight = 0
        for i, vel in ipairs(velocityBuffer) do
            local weight = i / #velocityBuffer
            avgVel = avgVel + (vel * weight)
            totalWeight = totalWeight + weight
        end
        avgVel = avgVel / totalWeight
        
        -- Smooth rotation buffer averaging
        totalWeight = 0
        for i, yaw in ipairs(rotationBuffer) do
            local weight = i / #rotationBuffer
            avgYaw = avgYaw + (yaw * weight)
            totalWeight = totalWeight + weight
        end
        avgYaw = avgYaw / totalWeight
        
        totalWeight = 0
        for i, move in ipairs(moveBuffer) do
            local weight = i / #moveBuffer
            avgMove = avgMove + (move * weight)
            totalWeight = totalWeight + weight
        end
        avgMove = avgMove / totalWeight
        
        local correctedY = avgPos.Y + heightOffset
        local targetCFrame = CFrame.new(avgPos.X, correctedY, avgPos.Z) * CFrame.Angles(0, avgYaw, 0)
        
        -- Apply manual flip rotation if enabled
        if isFlipped then
            local flipRotation = CFrame.Angles(0, math.pi, 0)
            currentFlipRotation = currentFlipRotation:Lerp(flipRotation, FLIP_SMOOTHNESS)
        else
            currentFlipRotation = currentFlipRotation:Lerp(CFrame.new(), FLIP_SMOOTHNESS)
        end
        
        targetCFrame = targetCFrame * currentFlipRotation
        
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, POSITION_SMOOTH)
        
        local targetVelocity = avgVel * 0.98
        local currentVel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = currentVel:Lerp(targetVelocity, VELOCITY_SMOOTH)
        
        if hum then
            local currentMove = hum.MoveDirection
            local smoothMove = currentMove:Lerp(avgMove, MOVE_SMOOTH)
            hum:Move(smoothMove, false)
        end
        
        if jumpDetector:ShouldJump(data, i0, f0, f1, interpVel, accumulatedTime, hum) then
            jumpDetector:ExecuteJump(hum)
        end
    end)
end

-- ============================================================
-- FLOATING BUTTON UI
-- ============================================================
local function createFloatingUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FloatingControlUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "FloatingBG"
    bgFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    bgFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
    bgFrame.Size = UDim2.new(0, 140, 0, 80)
    bgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    bgFrame.BorderSizePixel = 0
    bgFrame.Visible = false
    bgFrame.Parent = screenGui
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 16)
    bgCorner.Parent = bgFrame
    
    local dragIndicator = Instance.new("Frame")
    dragIndicator.BackgroundTransparency = 1
    dragIndicator.Position = UDim2.new(0.5, 0, 0, 8)
    dragIndicator.Size = UDim2.new(0, 40, 0, 6)
    dragIndicator.AnchorPoint = Vector2.new(0.5, 0)
    dragIndicator.Parent = bgFrame
    
    local dotLayout = Instance.new("UIListLayout")
    dotLayout.FillDirection = Enum.FillDirection.Horizontal
    dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    dotLayout.Padding = UDim.new(0, 6)
    dotLayout.Parent = dragIndicator
    
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        dot.BackgroundTransparency = 0.5
        dot.BorderSizePixel = 0
        dot.Size = UDim2.new(0, 5, 0, 5)
        dot.Parent = dragIndicator
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
    end
    
    local buttonFrame = Instance.new("Frame")
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Position = UDim2.new(0.5, 0, 0.5, 8)
    buttonFrame.Size = UDim2.new(1, -20, 0, 50)
    buttonFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    buttonFrame.Parent = bgFrame
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonFrame
    
    local playPauseBtn = Instance.new("TextButton")
    playPauseBtn.Size = UDim2.new(0, 50, 0, 50)
    playPauseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    playPauseBtn.Text = "▶️"
    playPauseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    playPauseBtn.TextSize = 24
    playPauseBtn.Font = Enum.Font.GothamBold
    playPauseBtn.BorderSizePixel = 0
    playPauseBtn.Parent = buttonFrame
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(1, 0)
    playCorner.Parent = playPauseBtn
    
    local rotateBtn = Instance.new("TextButton")
    rotateBtn.Size = UDim2.new(0, 50, 0, 50)
    rotateBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    rotateBtn.Text = "🔄"
    rotateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rotateBtn.TextSize = 24
    rotateBtn.Font = Enum.Font.GothamBold
    rotateBtn.BorderSizePixel = 0
    rotateBtn.Parent = buttonFrame
    
    local rotateCorner = Instance.new("UICorner")
    rotateCorner.CornerRadius = UDim.new(1, 0)
    rotateCorner.Parent = rotateBtn
    
    local function addHoverEffect(btn)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 54, 0, 54),
                BackgroundColor3 = Color3.fromRGB(70, 70, 80)
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 50, 0, 50),
                BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            }):Play()
        end)
    end
    
    addHoverEffect(playPauseBtn)
    addHoverEffect(rotateBtn)
    
    local dragging = false
    local dragInput, dragStart, startPos
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        bgFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    
    bgFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bgFrame.Position
            
            for _, dot in pairs(dragIndicator:GetChildren()) do
                if dot:IsA("Frame") then
                    TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0
                    }):Play()
                end
            end
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    for _, dot in pairs(dragIndicator:GetChildren()) do
                        if dot:IsA("Frame") then
                            TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                                BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                                BackgroundTransparency = 0.5
                            }):Play()
                        end
                    end
                end
            end)
        end
    end)
    
    bgFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end)
    
    playPauseBtn.MouseButton1Click:Connect(function()
        print("🖱️ Play/Pause button clicked!")
        
        if not isPlaying then
            print("▶️ Starting autowalk...")
            
            if #routes == 0 then 
                print("⚠️ No routes loaded!")
                return 
            end
            
            if isLooping then 
                print("⚠️ Already running!")
                return 
            end
            
            isPlaying = true
            isLooping = true
            isPaused = false
            
            playPauseBtn.Text = "⏸️"
            playPauseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            
            print("✅ Autowalk started!")
            
            task.spawn(function()
                while isLooping do
                    if not hrp then 
                        pcall(refreshHRP)
                    end
                    
                    for r = 1, #routes do
                        if not isLooping then break end
                        if not routes[r].data then continue end
                        
                        local finished = false
                        pcall(function()
                            playRouteData(routes[r].data, function()
                                finished = true
                            end)
                        end)
                        
                        while not finished and isLooping do
                            task.wait(0.1)
                        end
                        
                        if not isLooping then break end
                        task.wait(0.5)
                    end
                    
                    if isLooping and routes[1] and routes[1].data then
                        print("🔄 Loop selesai, kembali ke titik awal...")
                        
                        pcall(function()
                            local startPoint = tableToVec(routes[1].data[1].position)
                            local currentPos = hrp.Position
                            local distance = (currentPos - startPoint).Magnitude
                            
                            print(string.format("📍 Jarak dari titik awal: %.0f studs", distance))
                            
                            if distance > 5 then
                                print("🏃‍♂️ RUNNING kembali ke titik awal...")
                                local reached = smoothRunToPosition(startPoint, 20)
                                
                                if reached then
                                    print("✅ Sampai di titik awal!")
                                    task.wait(1)
                                else
                                    print("⚠️ Gagal mencapai titik awal, lanjut loop...")
                                    task.wait(0.5)
                                end
                            else
                                print("✅ Sudah dekat dengan titik awal, lanjut loop!")
                                task.wait(1)
                            end
                        end)
                    end
                end
                
                isLooping = false
                isPlaying = false
                print("🛑 Autowalk loop ended")
            end)
            
            return
        end
        
        isPaused = not isPaused
        
        if isPaused then
            playPauseBtn.Text = "▶️"
            playPauseBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
            print("⏸️ Paused")
        else
            playPauseBtn.Text = "⏸️"
            playPauseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            print("▶️ Resumed")
        end
    end)
    
    rotateBtn.MouseButton1Click:Connect(function()
        print("🖱️ Rotate button clicked!")
        
        isFlipped = not isFlipped
        
        if isFlipped then
            rotateBtn.Text = "🔃"
            rotateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
            print("🔄 Rotate: ON (Backward)")
        else
            rotateBtn.Text = "🔄"
            rotateBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            print("🔄 Rotate: OFF")
        end
    end)
    
    local function show()
        bgFrame.Visible = true
        bgFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(bgFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 140, 0, 80)
        }):Play()
        floatingVisible = true
    end
    
    local function hide()
        TweenService:Create(bgFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.delay(0.3, function()
            bgFrame.Visible = false
            floatingVisible = false
        end)
    end
    
    local function reset()
        isPaused = false
        isFlipped = false
        playPauseBtn.Text = "▶️"
        playPauseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        rotateBtn.Text = "🔄"
        rotateBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end
    
    return {
        show = show,
        hide = hide,
        reset = reset,
        gui = screenGui
    }
end

floatingUI = createFloatingUI()

-- ============================================================
-- MAIN PLAYBACK FUNCTIONS
-- ============================================================
local function runAllRoutes()
    if #routes == 0 then return end
    if isLooping then return end
    
    isLooping = true
    
    task.spawn(function()
        while isLooping do
            if not hrp then refreshHRP() end
            
            for r = 1, #routes do
                if not isLooping then break end
                if not routes[r].data then continue end
                
                local finished = false
                playRouteData(routes[r].data, function()
                    finished = true
                end)
                
                while not finished and isLooping do
                    task.wait(0.1)
                end
                
                if not isLooping then break end
                task.wait(0.5)
            end
            
            if isLooping and routes[1] and routes[1].data then
                print("🔄 Loop selesai, kembali ke titik awal...")
                
                local startPoint = tableToVec(routes[1].data[1].position)
                local currentPos = hrp.Position
                local distance = (currentPos - startPoint).Magnitude
                
                print(string.format("📍 Jarak dari titik awal: %.0f studs", distance))
                
                if distance > 5 then
                    print("🏃‍♂️ RUNNING kembali ke titik awal...")
                    local reached = smoothRunToPosition(startPoint, 20)
                    
                    if reached then
                        print("✅ Sampai di titik awal!")
                        task.wait(1)
                    else
                        print("⚠️ Gagal mencapai titik awal, lanjut loop...")
                        task.wait(0.5)
                    end
                else
                    print("✅ Sudah dekat dengan titik awal, lanjut loop!")
                    task.wait(1)
                end
            end
        end
        
        isLooping = false
        isPlaying = false
    end)
end

local function stopRoute()
    print("🛑 Stopping all routes...")
    isRunning = false
    isLooping = false
    isPlaying = false
    isPaused = false
    isFlipped = false
    
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:Move(Vector3.zero, false)
        end
    end
    
    if floatingUI then
        floatingUI.hide()
        floatingUI.reset()
    end
    
    print("✅ All routes stopped!")
end

-- ===============================
-- Anti Beton Ultra-Smooth
-- ===============================
local antiBetonActive = false
local antiBetonConn

local function enableAntiBeton()
    if antiBetonConn then antiBetonConn:Disconnect() end

    antiBetonConn = RunService.Stepped:Connect(function(_, dt)
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end

        if antiBetonActive and humanoid.FloorMaterial == Enum.Material.Air then
            local targetY = -50
            local currentY = hrp.Velocity.Y
            local newY = currentY + (targetY - currentY) * math.clamp(dt * 2.5, 0, 1)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, newY, hrp.Velocity.Z)
        end
    end)
end

local function disableAntiBeton()
    if antiBetonConn then
        antiBetonConn:Disconnect()
        antiBetonConn = nil
    end
end

-- ===============================
-- Anti Idle
-- ===============================
local antiIdleActive = true
local antiIdleConn

local function enableAntiIdle()
    if antiIdleConn then antiIdleConn:Disconnect() end
    antiIdleConn = player.Idled:Connect(function()
        if antiIdleActive then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

enableAntiIdle()

-- ===============================
-- FINDING SERVER FUNCTION
-- ===============================
local function findLowPlayerServer()
    local PlaceId = game.PlaceId
    
    task.spawn(function()
        local Cursor = ""
        local Servers = {}
        
        local WindUI = getgenv().WindUIInstance
        if WindUI then
            WindUI:Notify({
                Title = "Server Finder",
                Content = "🔍 Scanning servers...",
                Duration = 3,
            })
        end

        repeat
            local URL = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s", PlaceId, Cursor ~= "" and "&cursor="..Cursor or "")
            local success, Response = pcall(function()
                return game:HttpGet(URL)
            end)
            
            if success then
                local Data = HttpService:JSONDecode(Response)
                for _, server in pairs(Data.data) do
                    table.insert(Servers, server)
                end
                Cursor = Data.nextPageCursor
            end
            task.wait(0.5)
        until not Cursor or #Servers >= 50

        if #Servers > 0 then
            table.sort(Servers, function(a, b)
                return a.playing < b.playing
            end)
            
            local message = "Found " .. #Servers .. " servers!\n\nLowest player counts:"
            for i = 1, math.min(5, #Servers) do
                local server = Servers[i]
                message = message .. string.format("\n%d/%d players", server.playing, server.maxPlayers)
            end
            
            if WindUI then
                WindUI:Notify({
                    Title = "✅ Servers Found",
                    Content = message,
                    Duration = 8,
                })
            end
            
            if Servers[1] then
                task.wait(2)
                if WindUI then
                    WindUI:Notify({
                        Title = "Teleporting",
                        Content = "🚀 Joining lowest server...",
                        Duration = 3,
                    })
                end
                TeleportService:TeleportToPlaceInstance(PlaceId, Servers[1].id)
            end
        else
            if WindUI then
                WindUI:Notify({
                    Title = "❌ Error",
                    Content = "No servers found!",
                    Duration = 3,
                })
            end
        end
    end)
end

-- ============================================================
-- UI: WindUI V2.7 - SMOOTH ROTATION EDITION
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
getgenv().WindUIInstance = WindUI

WindUI:Popup({
    Title = "Welcome to ASTRIONHUB!",
    Content = "Version 2.7 - Smooth Rotation Fixed",
    Buttons = {
        {
            Title = "Let's Go!",
            Icon = "rocket",
        }
    }
})

local Window = WindUI:CreateWindow({
    Title = "ASTRIONHUB V2.7",
    Author = "by Jinho x Astrion",
    Folder = "ASTRIONHUB",
    Icon = "mountain-snow",
    NewElements = true,
    
    HideSearchBar = false,
    
    OpenButton = {
        Title = "ASTRIONHUB",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"), 
            Color3.fromHex("#e7ff2f")
        )
    }
})

-- ============================================================
-- TAGS
-- ============================================================
Window:Tag({
    Title = "v2.7",
    Icon = "geist:serverless",
    Color = Color3.fromHex("#30ff6a")
})

-- ============================================================
-- INFO TAB
-- ============================================================
local InfoTab = Window:Tab({
    Title = "About",
    Icon = "info",
    Default = true
})

InfoTab:Section({
    Title = "ASTRIONHUB V2.7",
    TextSize = 24,
    FontWeight = Enum.FontWeight.Bold,
})

InfoTab:Space()

InfoTab:Section({
    Title = [[🚀 ASTRIONHUB V2.7 — SMOOTH ROTATION FIXED

✨ PEMBARUAN TERBARU:
• Rotasi karakter sekarang ULTRA SMOOTH
• Deteksi otomatis perputaran cepat di JSON
• Tidak ada lagi gerakan patah-patah saat flip
• Sistem buffer rotasi yang lebih pintar

Sistem rotasi baru menggunakan dual-smoothing:
→ Rotasi normal: Halus & natural
→ Rotasi flip/cepat: Extra smooth dengan adaptive smoothing

Pengalaman bermain kini terasa lebih cinematik dan profesional.

V2.7 = Stability. Elegance. Smooth Rotation.
Dibangun oleh Jinho × Astrion System]],
    TextSize = 14,
    TextTransparency = 0.25,
})

InfoTab:Space()

-- ============================================================
-- DISCORD INTEGRATION WITH API
-- ============================================================
local DiscordSection = InfoTab:Section({
    Title = "Discord Community",
    TextSize = 20,
})

local InviteCode = "KZHQJBHwG"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

-- Try to fetch Discord server info
local DiscordInfo = nil
pcall(function()
    local Response = game:GetService("HttpService"):JSONDecode(
        game:HttpGet(DiscordAPI)
    )
    DiscordInfo = Response
end)

if DiscordInfo and DiscordInfo.guild then
    -- Show Discord server with rich info
    InfoTab:Paragraph({
        Title = tostring(DiscordInfo.guild.name),
        Desc = tostring(DiscordInfo.guild.description or "Join our community for updates, support, and more!"),
        Image = DiscordInfo.guild.icon and ("https://cdn.discordapp.com/icons/" .. DiscordInfo.guild.id .. "/" .. DiscordInfo.guild.icon .. ".png?size=1024") or nil,
        ImageSize = 48,
    })
    
    InfoTab:Button({
        Title = "Copy Discord Link",
        Icon = "geist:logo-discord",
        Desc = string.format("%d members online", DiscordInfo.approximate_presence_count or 0),
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/" .. InviteCode)
                WindUI:Notify({
                    Title = "Success!",
                    Content = "Discord invite copied to clipboard!",
                    Duration = 3,
                })
            end
        end
    })
else
    -- Fallback if API fails
    InfoTab:Button({
        Title = "Copy Discord Link",
        Icon = "geist:logo-discord",
        Desc = "Join our community!",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/" .. InviteCode)
                WindUI:Notify({
                    Title = "Success!",
                    Content = "Discord invite copied to clipboard!",
                    Duration = 3,
                })
            end
        end
    })
end

-- ============================================================
-- MAIN TAB
-- ============================================================
local MainTab = Window:Tab({
    Title = "Auto Walk",
    Icon = "lucide:bot-message-square",
})

local speeds = {}
for v = 0.25, 3, 0.25 do
    table.insert(speeds, {
        Title = string.format("%.2fx", v),
        Value = v
    })
end

MainTab:Dropdown({
    Title = "Playback Speed",
    Icon = "lucide:chevrons-up",
    Values = speeds,
    Value = speeds[4],
    Callback = function(option)
        playbackRate = option.Value
        print("Speed set to: " .. option.Title)
    end
})

MainTab:Space()

MainTab:Toggle({
    Title = "Anti Beton Ultra-Smooth",
    Icon = "shield",
    Desc = "Prevents stiff falling when floating",
    Value = false,
    Callback = function(state)
        antiBetonActive = state
        if state then
            enableAntiBeton()
            WindUI:Notify({
                Title = "Anti Beton",
                Content = "✅ Enabled",
                Duration = 2,
            })
        else
            disableAntiBeton()
            WindUI:Notify({
                Title = "Anti Beton",
                Content = "❌ Disabled",
                Duration = 2,
            })
        end
    end
})

MainTab:Space()

MainTab:Button({
    Title = "START Auto Loop",
    Icon = "play",
    Desc = "Show floating control & start auto loop",
    Color = Color3.fromHex("#30ff6a"),
    Callback = function()
        if floatingUI then
            floatingUI.show()
            WindUI:Notify({
                Title = "Started!",
                Content = "📱 Floating control displayed!",
                Duration = 3,
            })
        end
    end
})

MainTab:Space()

MainTab:Button({
    Title = "STOP Track",
    Icon = "lucide:octagon-minus",
    Desc = "Stop all routes & loop",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        pcall(stopRoute)
        WindUI:Notify({
            Title = "Stopped!",
            Content = "🛑 All routes stopped!",
            Duration = 3,
        })
    end
})

-- ============================================================
-- TOOLS TAB
-- ============================================================
local ToolsTab = Window:Tab({
    Title = "Tools",
    Icon = "settings",
})

-- God Mode System
local godModeEnabled = false
local godModeConnection = nil
local forceFieldConnection = nil

local function StartGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
    end
    if forceFieldConnection then
        forceFieldConnection:Disconnect()
    end
    
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        if godModeEnabled and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            if hum then
                hum.Health = hum.MaxHealth
                
                for _, effect in pairs(hum:GetChildren()) do
                    if effect:IsA("NumberValue") and effect.Name == "creator" then
                        effect:Destroy()
                    end
                end
            end
        end
    end)
    
    forceFieldConnection = humanoid.HealthChanged:Connect(function(health)
        if godModeEnabled then
            if health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
        end
    end)
    
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
end

local function StopGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    if forceFieldConnection then
        forceFieldConnection:Disconnect()
        forceFieldConnection = nil
    end
    
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            end)
        end
    end
end

ToolsTab:Section({
    Title = "Protection",
})

ToolsTab:Toggle({
    Title = "God Mode (100%)",
    Desc = "Complete invincibility - works everywhere",
    Icon = "shield-check",
    Value = false,
    Callback = function(Value)
        godModeEnabled = Value
        
        if Value then
            StartGodMode()
            WindUI:Notify({
                Title = "God Mode",
                Content = "✅ Ultimate protection activated!",
                Duration = 3,
            })
        else
            StopGodMode()
            WindUI:Notify({
                Title = "God Mode",
                Content = "❌ Deactivated",
                Duration = 2,
            })
        end
    end,
})

ToolsTab:Space()

ToolsTab:Section({
    Title = "Server Tools",
})

ToolsTab:Button({
    Title = "Find Low Player Server",
    Icon = "search",
    Desc = "Search for empty servers & auto join",
    Callback = function()
        findLowPlayerServer()
    end
})

ToolsTab:Space()

ToolsTab:Slider({
    Title = "WalkSpeed",
    Icon = "gauge",
    Desc = "Adjust character walk speed",
    Value = {
        Min = 10,
        Max = 500,
        Default = 16
    },
    Step = 1,
    Suffix = " Speed",
    Callback = function(val)
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end
})

ToolsTab:Space()

ToolsTab:Slider({
    Title = "Jump Power",
    Icon = "arrow-big-up",
    Desc = "Adjust character jump height",
    Value = {
        Min = 10,
        Max = 500,
        Default = 50
    },
    Step = 1,
    Suffix = " Power",
    Callback = function(val)
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            if humanoid.UseJumpPower then
                humanoid.JumpPower = val
                originalJumpPower = val
            else
                humanoid.JumpHeight = val
                originalJumpHeight = val
            end
        end
    end
})

ToolsTab:Space()

ToolsTab:Button({
    Title = "Respawn Character",
    Icon = "refresh-ccw",
    Desc = "Respawn your character",
    Callback = function()
        player.Character:BreakJoints()
        WindUI:Notify({
            Title = "Respawning",
            Content = "⏳ Please wait...",
            Duration = 2,
        })
    end
})

-- ============================================================
-- APPEARANCE TAB
-- ============================================================
local AppearanceTab = Window:Tab({
    Title = "Theme",
    Icon = "palette",
})

AppearanceTab:Section({
    Title = "Customize Interface",
    Desc = "Personalize your experience",
    TextSize = 18,
})

AppearanceTab:Space()

local themes = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(themes, {
        Title = themeName
    })
end
table.sort(themes, function(a, b) return a.Title < b.Title end)

AppearanceTab:Dropdown({
    Title = "Select Theme",
    Icon = "lucide:palette",
    Values = themes,
    SearchBarEnabled = true,
    Value = themes[8],
    Callback = function(theme)
        WindUI:SetTheme(theme.Title)
        WindUI:Notify({
            Title = "Theme Changed",
            Content = "Applied: " .. theme.Title,
            Duration = 2,
        })
    end
})

-- ============================================================
-- SHOW WINDOW
-- ============================================================
pcall(function()
    Window:Show()
    InfoTab:Show()
end)
