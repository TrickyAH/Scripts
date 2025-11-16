--// Load Fluent and Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

--// Create Window
local Window = Fluent:CreateWindow({
    Title = "TP Farm",
    SubTitle = "Compact UI",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 420), -- slightly taller for new toggle
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Tabs
local Tabs = {
    Main = Window:AddTab({Title = "Main", Icon = ""}),
    AutoStats = Window:AddTab({Title = "Auto Stats", Icon = ""}),
    AutoSkill = Window:AddTab({Title = "Auto Skill", Icon = ""}),
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}

-- Folders and Remotes
local EnemyFolder = workspace:FindFirstChild("Enemies")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Knit")
local CollectRemote, StatRemote

if Knit then
    local EnemyService = Knit:FindFirstChild("Services") and Knit.Services:FindFirstChild("EnemyService")
    CollectRemote = EnemyService and EnemyService:FindFirstChild("RF") and EnemyService.RF:FindFirstChild("CollectPickUp")
    
    local PlayerHandler = Knit.Services:FindFirstChild("PlayerHandler")
    StatRemote = PlayerHandler and PlayerHandler:FindFirstChild("RF") and PlayerHandler.RF:FindFirstChild("UseStatPoint")
end

local Distance = 4
local currentTarget = nil

-- Variables for toggles
local AutoFarm = false
local AutoShard = false
local AutoStamina = false
local AutoAgility = false
local AutoVitality = false
local AutoStrength = false
local AutoSkill1 = false
local AutoSkill2 = false
local AutoSkill3 = false
local AutoSkill4 = false
local WeaponHitboxExpander = false

--------------------------------------------------------------------
-- GUI Toggles
--------------------------------------------------------------------
-- Main Tab
local TpToggle = Tabs.Main:AddToggle("TPFarm", {Title = "Auto TP Farm", Default = AutoFarm})
local ShardToggle = Tabs.Main:AddToggle("ShardPickup", {Title = "Auto Shard Pickup", Default = AutoShard})
local HitboxToggle = Tabs.Main:AddToggle("WeaponHitbox", {Title = "Weapon Hitbox Expander", Default = WeaponHitboxExpander})

TpToggle:OnChanged(function(v) AutoFarm=v end)
ShardToggle:OnChanged(function(v) AutoShard=v end)
HitboxToggle:OnChanged(function(v) WeaponHitboxExpander=v end)

-- Auto Stats Tab
local StaminaToggle = Tabs.AutoStats:AddToggle("Stamina", {Title = "Auto Stamina", Default = AutoStamina})
local AgilityToggle = Tabs.AutoStats:AddToggle("Agility", {Title = "Auto Agility", Default = AutoAgility})
local VitalityToggle = Tabs.AutoStats:AddToggle("Vitality", {Title = "Auto Vitality", Default = AutoVitality})
local StrengthToggle = Tabs.AutoStats:AddToggle("Strength", {Title = "Auto Strength", Default = AutoStrength})

StaminaToggle:OnChanged(function(v) AutoStamina=v end)
AgilityToggle:OnChanged(function(v) AutoAgility=v end)
VitalityToggle:OnChanged(function(v) AutoVitality=v end)
StrengthToggle:OnChanged(function(v) AutoStrength=v end)

-- Auto Skill Tab
local Skill1Toggle = Tabs.AutoSkill:AddToggle("Skill1", {Title = "Auto Skill 1", Default = AutoSkill1})
local Skill2Toggle = Tabs.AutoSkill:AddToggle("Skill2", {Title = "Auto Skill 2", Default = AutoSkill2})
local Skill3Toggle = Tabs.AutoSkill:AddToggle("Skill3", {Title = "Auto Skill 3", Default = AutoSkill3})
local Skill4Toggle = Tabs.AutoSkill:AddToggle("Skill4", {Title = "Auto Skill 4", Default = AutoSkill4})

Skill1Toggle:OnChanged(function(v) AutoSkill1=v end)
Skill2Toggle:OnChanged(function(v) AutoSkill2=v end)
Skill3Toggle:OnChanged(function(v) AutoSkill3=v end)
Skill4Toggle:OnChanged(function(v) AutoSkill4=v end)

--------------------------------------------------------------------
-- FUNCTIONS
--------------------------------------------------------------------
local function getClosest()
    if not EnemyFolder then return nil end
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest, shortest = nil, math.huge
    for _, mob in ipairs(EnemyFolder:GetChildren()) do
        local mHRP = mob:FindFirstChild("HumanoidRootPart")
        if mHRP then
            local dist = (hrp.Position - mHRP.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = mob
            end
        end
    end
    return closest
end

local function useStat(stat)
    if StatRemote then pcall(function() StatRemote:InvokeServer(stat,1) end) end
end

local function collectShard()
    if CollectRemote then pcall(function() CollectRemote:InvokeServer("Shard") end) end
end

local function pressKey(key)
    if not key then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

--------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")
            if hrp and humanoid and humanoid.Health > 0 then

                -- Weapon Hitbox Expander
                if WeaponHitboxExpander then
                    for _, tool in pairs(char:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("WeaponHitbox") then
                            tool.WeaponHitbox.Size = Vector3.new(20,20,20)
                        end
                    end
                end

                -- Auto Shard
                if AutoShard then collectShard() end

                -- Auto Farm
                if AutoFarm then
                    local target = getClosest()
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        if target ~= currentTarget or (hrp.Position - target.HumanoidRootPart.Position).Magnitude > Distance+2 then
                            pcall(function()
                                hrp.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0,0,Distance)
                                currentTarget = target
                            end)
                        end
                    else
                        currentTarget = nil
                    end
                end

                -- Auto Stats
                if AutoStamina then useStat("Stamina") end
                if AutoAgility then useStat("Agility") end
                if AutoVitality then useStat("Vitality") end
                if AutoStrength then useStat("Strength") end

                -- Auto Skills
                if AutoSkill1 then pressKey("One") end
                if AutoSkill2 then pressKey("Two") end
                if AutoSkill3 then pressKey("Three") end
                if AutoSkill4 then pressKey("Four") end
            end
        end
    end
end)

--------------------------------------------------------------------
-- SAVE / LOAD CONFIG
--------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("TPFarmUI")
SaveManager:SetFolder("TPFarmUI/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({Title="TP Farm",Content="Compact UI Loaded!",Duration=5})
SaveManager:LoadAutoloadConfig()
