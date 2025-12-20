-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

-- Configuration Variables
local Config = {
    HeightAbove = 8,
    SpinSpeed = 2,
    Radius = 5,
    CheckInterval = 0.5,
    SpellCooldown = 0.5
}

-- Toggle States
local Toggles = {
    AutoFarm = false,
    SpellSpam = false,
    AutoRepeat = false,
    AutoSummon = false,
    AutoStart = false,
    AutoReset = false
}

-- State
local currentTween = nil
local currentTarget = nil
local spinning = false
local angle = 0
local scriptRunning = true
local lastWarning = false

-- Setup remote events safely
local function getRemote(name)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if not remote then
        warn("Remote not found: " .. name)
    end
    return remote
end

local SpawnCompanion = getRemote("SpawnCompanion")
local StartDungeon = getRemote("StartDungeon")
local useSpell = getRemote("useSpell")
local voteRemote = getRemote("voteRemote")

-- Function to safely fire remote
local function safeFireServer(remote, arg1, arg2, arg3)
    if remote then
        local success, err = pcall(function()
            if arg1 ~= nil then
                remote:FireServer(arg1, arg2, arg3)
            else
                remote:FireServer()
            end
        end)
        if not success then
            warn("Failed to fire remote:", err)
        end
        return success
    end
    return false
end

-- Function to summon companion
local function summonCompanion()
    Rayfield:Notify({
        Title = "Companion",
        Content = "Summoning companion...",
        Duration = 3,
        Image = "user"
    })
    safeFireServer(SpawnCompanion)
end

-- Function to start dungeon
local function startDungeon()
    Rayfield:Notify({
        Title = "Dungeon",
        Content = "Starting dungeon...",
        Duration = 3,
        Image = "sword"
    })
    safeFireServer(StartDungeon, true)
end

-- Function to vote repeat
local function voteRepeat()
    safeFireServer(voteRemote, "repeat")
end

-- Spell spam loop
local spellLoop = nil
local function spellSpamLoop()
    if spellLoop then spellLoop:Disconnect() end
    
    spellLoop = RunService.Heartbeat:Connect(function()
        if not Toggles.SpellSpam then return end
        
        task.spawn(function()
            safeFireServer(useSpell, "Q")
            task.wait(Config.SpellCooldown)
            
            if not Toggles.SpellSpam then return end
            safeFireServer(useSpell, "E")
            task.wait(Config.SpellCooldown)
            
            if not Toggles.SpellSpam then return end
            safeFireServer(useSpell, "R")
            task.wait(Config.SpellCooldown)
        end)
        
        task.wait(Config.SpellCooldown * 3)
    end)
end

-- Auto-repeat dungeon loop
local repeatLoop = nil
local function autoRepeatLoop()
    repeatLoop = task.spawn(function()
        while scriptRunning do
            if Toggles.AutoRepeat then
                voteRepeat()
            end
            task.wait(5)
        end
    end)
end

-- Function to check if in Room 5 with no enemies
local function checkRoom5AndReset()
    if not Toggles.AutoReset then return end
    
    -- Check if Room5 exists
    local roomInfo = workspace:FindFirstChild("roomInformation")
    if not roomInfo then return end
    
    local room5 = roomInfo:FindFirstChild("Room5")
    if not room5 then return end
    
    local enemiesFolder = room5:FindFirstChild("Enemies")
    if not enemiesFolder then return end
    
    -- Count alive enemies in Room5 ONLY
    local aliveCount = 0
    for _, mob in pairs(enemiesFolder:GetChildren()) do
        if mob:IsA("Model") then
            local mobHum = mob:FindFirstChild("Humanoid")
            if mobHum and mobHum.Health > 0 and mobHum:GetState() ~= Enum.HumanoidStateType.Dead then
                if mobHum.Health > mobHum.MaxHealth * 0.01 then
                    aliveCount = aliveCount + 1
                end
            end
        end
    end
    
    -- ONLY reset if we're checking Room5 folder AND it has zero alive enemies
    -- This ensures we only reset when specifically at Room 5
    if aliveCount == 0 and #enemiesFolder:GetChildren() > 0 then
        -- Extra check: make sure no enemies exist in workspace.Enemies either
        local workspaceEnemies = workspace:FindFirstChild("Enemies")
        local hasOtherEnemies = false
        
        if workspaceEnemies then
            for _, mob in pairs(workspaceEnemies:GetChildren()) do
                if mob:IsA("Model") then
                    local mobHum = mob:FindFirstChild("Humanoid")
                    if mobHum and mobHum.Health > 0 then
                        hasOtherEnemies = true
                        break
                    end
                end
            end
        end
        
        -- Only reset if Room5 is clear AND no other enemies exist
        if not hasOtherEnemies then
            Rayfield:Notify({
                Title = "Auto-Reset",
                Content = "Room 5 cleared! Resetting character...",
                Duration = 3,
                Image = "refresh-cw"
            })
            
            print("Room 5 cleared - Resetting character")
            
            -- Reset character
            if char and char.Parent then
                char:BreakJoints()
            end
        end
    end
end

-- Function to find nearest alive enemy
local function findNearestEnemy()
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end
    
    local nearest = nil
    local minDist = math.huge
    
    for _, mob in pairs(enemiesFolder:GetChildren()) do
        if mob:IsA("Model") then
            local mobHum = mob:FindFirstChild("Humanoid")
            local mobHrp = mob:FindFirstChild("HumanoidRootPart")
            
            -- More thorough alive check
            if mobHum and mobHrp and mobHum.Health > 0 and mobHum:GetState() ~= Enum.HumanoidStateType.Dead then
                -- Skip if health is too low (likely dead but not detected)
                if mobHum.Health > mobHum.MaxHealth * 0.01 then
                    local dist = (hrp.Position - mobHrp.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = mob
                    end
                end
            end
        end
    end
    
    return nearest
end

-- Function to check if target is still valid
local function isTargetValid(target)
    if not target or not target.Parent then return false end
    
    local mobHum = target:FindFirstChild("Humanoid")
    local mobHrp = target:FindFirstChild("HumanoidRootPart")
    
    if not mobHum or not mobHrp then return false end
    
    -- Check both health and humanoid state
    if mobHum.Health <= 0 or mobHum:GetState() == Enum.HumanoidStateType.Dead then 
        return false 
    end
    
    -- Extra check: if HRP is anchored and health hasn't changed, might be dead
    if mobHrp.Anchored and mobHum.Health <= mobHum.MaxHealth * 0.01 then
        return false
    end
    
    return true
end

-- Function to stop current movement
local function stopMovement()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    spinning = false
end

-- Function to spin around target
local spinConnection = nil
local function spinAroundTarget(target)
    local mobHrp = target:FindFirstChild("HumanoidRootPart")
    if not mobHrp then return end
    
    if spinConnection then spinConnection:Disconnect() end
    spinning = true
    
    spinConnection = RunService.RenderStepped:Connect(function(dt)
        if not Toggles.AutoFarm or not scriptRunning or not isTargetValid(target) or not spinning then
            if spinConnection then spinConnection:Disconnect() end
            return
        end
        
        -- Check if character and HRP still exist
        if not char or not char.Parent then
            if spinConnection then spinConnection:Disconnect() end
            return
        end
        
        local currentHrp = char:FindFirstChild("HumanoidRootPart")
        if not currentHrp then
            if spinConnection then spinConnection:Disconnect() end
            return
        end
        
        angle = angle + (dt * (360 / Config.SpinSpeed))
        if angle >= 360 then angle = angle - 360 end
        
        local radians = math.rad(angle)
        local offsetX = math.cos(radians) * Config.Radius
        local offsetZ = math.sin(radians) * Config.Radius
        
        local targetPos = mobHrp.Position + Vector3.new(offsetX, Config.HeightAbove, offsetZ)
        
        currentHrp.CFrame = CFrame.new(targetPos, mobHrp.Position)
        currentHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        currentHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
end

-- Main farming loop
local farmLoop = nil
local function mainLoop()
    farmLoop = task.spawn(function()
        while scriptRunning do
            if Toggles.AutoFarm then
                char = player.Character
                if char then
                    hrp = char:FindFirstChild("HumanoidRootPart")
                    hum = char:FindFirstChild("Humanoid")
                    
                    if hrp and hum and hum.Health > 0 then
                        if currentTarget and isTargetValid(currentTarget) then
                            if not spinning then
                                spinAroundTarget(currentTarget)
                            end
                        else
                            stopMovement()
                            currentTarget = findNearestEnemy()
                            
                            if currentTarget then
                                print("New target found:", currentTarget.Name)
                                lastWarning = false
                                spinAroundTarget(currentTarget)
                            else
                                if not lastWarning then
                                    print("No enemies found, waiting...")
                                    lastWarning = true
                                end
                            end
                        end
                    end
                end
            else
                stopMovement()
            end
            
            task.wait(Config.CheckInterval)
        end
    end)
end

-- Anti-fling protection
hrp.Anchored = false
local bodyVel = Instance.new("BodyVelocity")
bodyVel.MaxForce = Vector3.new(0, 0, 0)
bodyVel.Parent = hrp

-- Handle character respawn
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
    hum = newChar:WaitForChild("Humanoid")
    stopMovement()
    currentTarget = nil
    
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(0, 0, 0)
    bodyVel.Parent = hrp
end)

-- Create Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = "Dungeon Auto-Farm (TP)",
    LoadingTitle = "Auto-Farm Script",
    LoadingSubtitle = "by Script Hub",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil, -- Auto-detects AppData location for any executor
        FileName = "DungeonAutoFarm"
    }
})

-- Create Tabs
local MainTab = Window:CreateTab("Main", "zap")
local ConfigTab = Window:CreateTab("Configuration", "settings")

-- Main Tab Elements
local StartSection = MainTab:CreateSection("Dungeon Controls")

local StartButton = MainTab:CreateButton({
    Name = "Summon Companion & Start Dungeon",
    Callback = function()
        task.spawn(function()
            summonCompanion()
            task.wait(2)
            startDungeon()
        end)
    end
})

MainTab:CreateToggle({
    Name = "Auto-Summon Companion",
    CurrentValue = false,
    Flag = "AutoSummon",
    Callback = function(Value)
        Toggles.AutoSummon = Value
        if Value then
            summonCompanion()
            Rayfield:Notify({
                Title = "Auto-Summon",
                Content = "Companion summoned! Toggle off to stop auto-summon.",
                Duration = 3,
                Image = "user"
            })
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto-Start Dungeon",
    CurrentValue = false,
    Flag = "AutoStart",
    Callback = function(Value)
        Toggles.AutoStart = Value
        if Value then
            startDungeon()
            Rayfield:Notify({
                Title = "Auto-Start",
                Content = "Dungeon started! Toggle off to stop auto-start.",
                Duration = 3,
                Image = "play"
            })
        end
    end
})

local FarmSection = MainTab:CreateSection("Farming")

MainTab:CreateToggle({
    Name = "Auto-Farm Enemies (TP)",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        Toggles.AutoFarm = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto-Farm",
                Content = "Auto-farming enabled!",
                Duration = 3,
                Image = "target"
            })
            mainLoop()
        else
            stopMovement()
            Rayfield:Notify({
                Title = "Auto-Farm",
                Content = "Auto-farming disabled!",
                Duration = 3,
                Image = "x"
            })
        end
    end
})

MainTab:CreateToggle({
    Name = "Spell Spam (Q, E, R)",
    CurrentValue = false,
    Flag = "SpellSpam",
    Callback = function(Value)
        Toggles.SpellSpam = Value
        if Value then
            Rayfield:Notify({
                Title = "Spell Spam",
                Content = "Spell spam enabled!",
                Duration = 3,
                Image = "sparkles"
            })
            spellSpamLoop()
        else
            if spellLoop then spellLoop:Disconnect() end
            Rayfield:Notify({
                Title = "Spell Spam",
                Content = "Spell spam disabled!",
                Duration = 3,
                Image = "x"
            })
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto-Repeat Dungeon",
    CurrentValue = false,
    Flag = "AutoRepeat",
    Callback = function(Value)
        Toggles.AutoRepeat = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto-Repeat",
                Content = "Auto-repeat enabled!",
                Duration = 3,
                Image = "repeat"
            })
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto-Reset at Room 5",
    CurrentValue = false,
    Flag = "AutoReset",
    Callback = function(Value)
        Toggles.AutoReset = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto-Reset",
                Content = "Will reset ONLY when Room 5 is completely cleared!",
                Duration = 3,
                Image = "refresh-cw"
            })
        end
    end
})

-- Configuration Tab Elements
local MovementSection = ConfigTab:CreateSection("Movement Settings")

ConfigTab:CreateSlider({
    Name = "Height Above Enemy",
    Range = {1, 20},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 8,
    Flag = "HeightAbove",
    Callback = function(Value)
        Config.HeightAbove = Value
    end
})

ConfigTab:CreateSlider({
    Name = "Spin Speed",
    Range = {0.5, 5},
    Increment = 0.5,
    Suffix = " sec/rotation",
    CurrentValue = 2,
    Flag = "SpinSpeed",
    Callback = function(Value)
        Config.SpinSpeed = Value
    end
})

ConfigTab:CreateSlider({
    Name = "Circle Radius",
    Range = {1, 15},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 5,
    Flag = "Radius",
    Callback = function(Value)
        Config.Radius = Value
    end
})

local PerformanceSection = ConfigTab:CreateSection("Performance")

ConfigTab:CreateSlider({
    Name = "Target Check Interval",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = " seconds",
    CurrentValue = 0.5,
    Flag = "CheckInterval",
    Callback = function(Value)
        Config.CheckInterval = Value
    end
})

ConfigTab:CreateSlider({
    Name = "Spell Cooldown",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = " seconds",
    CurrentValue = 0.5,
    Flag = "SpellCooldown",
    Callback = function(Value)
        Config.SpellCooldown = Value
    end
})

-- Start auto-repeat loop
autoRepeatLoop()

-- Welcome notification
Rayfield:Notify({
    Title = "Script Loaded!",
    Content = "Dungeon Auto-Farm ready. Toggle features in Main tab.",
    Duration = 5,
    Image = "check-circle"
})

-- Load saved configuration
Rayfield:LoadConfiguration()
