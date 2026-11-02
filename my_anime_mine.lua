-- AutoFarm module for My Anime Mine. Single file until the shared Utility helpers exist.
local AutoFarm = {
	running = false,
	toggles = {
		AutoMine = false,
		AutoTake = false,
		AutoEquipBest = false,
		AutoSell = false,
		AutoBuyPickaxes = false,
		AutoCore = false,
		AutoSkills = false,
		AutoCrew = false,
		AutoZones = false,
		AutoIndexClaim = false,
		AutoIndexHunt = false,
		AutoSpin = false,
		AutoMail = false,
		AutoBuff = false,
		AutoTrialClaim = false,
		AutoFocus = false,
		AutoBigNode = false,
	},
	settings = {
		theme = "Graphite",
		look = "Soft",
		key = "RightShift",
		width = 976,
		height = 750,
		sellInterval = 30,
		indexLimit = 30,
		sellRarities = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true },
		sellTypes = { Ores = true, Miners = true },
	},
}

-- Constants.
local CYCLE_INTERVAL = 3
local MINE_INTERVAL = 0.35
local ACTION_DELAY = 0.5
local RETRY_COOLDOWN = 45
local MAX_ACTIONS_PER_GROUP = 3
local TAKE_INTERVAL = 15
local EXTRAS_INTERVAL = 15
local REVEAL_STAGGER = 0.025
local CLAIM_DELAY = 0.7
local MAIL_COOLDOWN = 300
local BUFF_STATUS_COOLDOWN = 60
local ZONE_MOVE_COOLDOWN = 10
local ZONE_SAVE_SHARE = 0.25
local CHEST_FULL_SHARE = 0.9
local SELL_INTERVAL_RANGE = { 5, 300 }
local INDEX_LIMIT_RANGE = { 1, 120 }
local RARITIES = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythical",
	"Exotic",
	"Limited",
	"Exclusive",
	"Scaled",
}
local SELL_TYPES = { "Ores", "Miners", "Pickaxes" }
local STAND_OFFSET = Vector3.new(0, 3, 6)
local HOP_SETTLES = { 0.12, 0.2, 0.35 }
local SALE_CONFIRM_TIME = 0.8
local MIN_SELL_WORTH = 1000
local CREW_STATS = { false, "Speed", "MineSpeed" }

local SIDEBAR_WIDTH = 242
local MAX_ACTIVITY_LINES = 6

local MIN_WINDOW_SIZE = Vector2.new(760, 520)
local CONFIG_FOLDER = "AnimeMine"
local CONFIG_PATH = CONFIG_FOLDER .. "/configs"
local AUTOLOAD_PATH = CONFIG_FOLDER .. "/autoload.txt"

-- Color tokens. The active theme turns these into real colors.
local THEME = {}

for _, token in ipairs({
	"window",
	"windowEdge",
	"card",
	"cardDeep",
	"cardEdge",
	"field",
	"text",
	"soft",
	"muted",
	"track",
	"bar",
	"green",
	"purple",
	"red",
}) do
	THEME[token] = token
end

---Build a full theme from its main colors.
---@param colors table
---@return table
local function makeTheme(colors)
	local function rgb(values)
		return Color3.fromRGB(values[1], values[2], values[3])
	end

	return {
		window = rgb(colors.window),
		windowEdge = rgb(colors.edge),
		card = rgb(colors.card),
		cardDeep = rgb(colors.deep),
		cardEdge = rgb(colors.edge),
		field = rgb(colors.field),
		text = rgb(colors.text),
		soft = rgb(colors.soft),
		muted = rgb(colors.muted),
		track = rgb(colors.track),
		bar = rgb(colors.bar),
		green = rgb(colors.good),
		purple = rgb(colors.accent),
		red = Color3.fromRGB(226, 84, 84),
	}
end

local THEME_ORDER = { "Graphite", "Midnight", "Amethyst", "Crimson", "Emerald", "Ocean", "Sunset", "Paper" }

local function darkTheme(window, card, deep, edge, field, track, accent, good)
	return makeTheme({
		window = window,
		card = card,
		deep = deep,
		edge = edge,
		field = field,
		track = track,
		accent = accent,
		good = good,
		bar = { 226, 227, 230 },
		text = { 240, 241, 243 },
		soft = { 205, 207, 212 },
		muted = { 142, 145, 152 },
	})
end

local THEMES = {
	Graphite = darkTheme(
		{ 27, 28, 32 },
		{ 26, 27, 31 },
		{ 15, 16, 19 },
		{ 60, 62, 68 },
		{ 20, 21, 24 },
		{ 52, 53, 58 },
		{ 168, 118, 255 },
		{ 92, 214, 132 }
	),
	Midnight = darkTheme(
		{ 15, 18, 30 },
		{ 19, 23, 38 },
		{ 10, 12, 21 },
		{ 46, 54, 84 },
		{ 13, 16, 27 },
		{ 42, 49, 76 },
		{ 104, 148, 255 },
		{ 104, 148, 255 }
	),
	Amethyst = darkTheme(
		{ 26, 18, 38 },
		{ 32, 22, 46 },
		{ 18, 12, 28 },
		{ 72, 52, 102 },
		{ 22, 15, 33 },
		{ 66, 47, 94 },
		{ 196, 132, 255 },
		{ 196, 132, 255 }
	),
	Crimson = darkTheme(
		{ 30, 16, 19 },
		{ 36, 19, 23 },
		{ 20, 10, 12 },
		{ 92, 44, 52 },
		{ 25, 13, 16 },
		{ 84, 41, 48 },
		{ 255, 96, 112 },
		{ 255, 96, 112 }
	),
	Emerald = darkTheme(
		{ 14, 27, 22 },
		{ 17, 33, 27 },
		{ 9, 18, 15 },
		{ 44, 84, 68 },
		{ 12, 23, 19 },
		{ 40, 76, 62 },
		{ 72, 224, 156 },
		{ 72, 224, 156 }
	),
	Ocean = darkTheme(
		{ 13, 26, 34 },
		{ 16, 32, 42 },
		{ 9, 18, 24 },
		{ 42, 82, 100 },
		{ 11, 22, 29 },
		{ 38, 74, 90 },
		{ 72, 200, 232 },
		{ 72, 200, 232 }
	),
	Sunset = darkTheme(
		{ 32, 22, 16 },
		{ 39, 27, 19 },
		{ 21, 14, 10 },
		{ 98, 66, 44 },
		{ 27, 18, 13 },
		{ 88, 60, 40 },
		{ 255, 164, 84 },
		{ 255, 164, 84 }
	),
	Paper = makeTheme({
		window = { 236, 237, 240 },
		card = { 250, 250, 252 },
		deep = { 228, 229, 233 },
		edge = { 206, 208, 214 },
		field = { 244, 245, 247 },
		track = { 212, 214, 220 },
		accent = { 104, 76, 216 },
		good = { 38, 158, 92 },
		bar = { 58, 60, 68 },
		text = { 28, 29, 34 },
		soft = { 62, 64, 72 },
		muted = { 112, 115, 124 },
	}),
}

-- Looks change the shape and transparency of the window.
local LOOK_ORDER = { "Soft", "Sharp", "Glass" }

local LOOKS = {
	Soft = { radius = 1, glass = 0 },
	Sharp = { radius = 0.25, glass = 0 },
	Glass = { radius = 1.2, glass = 0.24 },
}

local PAGES = {
	{
		name = "Farm",
		groups = {
			{
				title = "Mining",
				column = 1,
				rows = { { "AutoMine", "Auto Mine", "Clicks the healthiest rock on your plot." } },
			},
			{
				title = "Chest and selling",
				column = 2,
				custom = "sellTimer",
				rows = {
					{ "AutoTake", "Auto Take Chest", "Takes everything from your chest." },
					{ "AutoEquipBest", "Auto Equip Best", "Arranges your crew after each take." },
					{ "AutoSell", "Auto Sell", "Hops to the buyer and sells your bag." },
				},
			},
			{
				title = "Sell settings",
				column = 1,
				custom = "sell",
				rows = {},
			},
		},
	},
	{
		name = "Upgrades",
		groups = {
			{
				title = "Shop",
				column = 1,
				rows = { { "AutoBuyPickaxes", "Auto Buy Pickaxes", "Buys the strongest pickaxe in stock." } },
			},
			{
				title = "Crew",
				column = 1,
				rows = { { "AutoCrew", "Auto Crew Upgrades", "Levels damage and both speeds." } },
			},
			{
				title = "Progress",
				column = 2,
				rows = {
					{ "AutoCore", "Auto Core Upgrades", "Buys tap damage and miner slots." },
					{ "AutoSkills", "Auto Area Upgrades", "Buys research in unlocked zones." },
					{ "AutoZones", "Auto Unlock Zones", "Saves for and unlocks the next zone." },
				},
			},
		},
	},
	{
		name = "Index",
		groups = {
			{
				title = "Rewards",
				column = 1,
				rows = { { "AutoIndexClaim", "Auto Claim Rewards", "Claims every finished index reward." } },
			},
			{
				title = "Completion",
				column = 2,
				custom = "index",
				rows = {
					{ "AutoIndexHunt", "Auto Complete Areas", "Mines each unfinished area in order." },
				},
			},
		},
	},
	{
		name = "Misc",
		groups = {
			{
				title = "Free rewards",
				column = 1,
				rows = {
					{ "AutoSpin", "Auto Daily Spin", "Spins when ready. Unlocks at Zone 5." },
					{ "AutoMail", "Auto Claim Mail", "Claims rewards from your mailbox." },
					{ "AutoBuff", "Auto Buff Mode", "Claims 2x damage. Needs the game's group." },
					{ "AutoTrialClaim", "Auto Trial Claims", "Claims finished Infinity Trial tiers." },
				},
			},
			{
				title = "Crew",
				column = 2,
				rows = {
					{ "AutoFocus", "Aim Crew At Missing Ore", "During index hunts, targets the needed rock." },
					{ "AutoBigNode", "Auto Big Nodes", "Turns on your best Big Node level." },
				},
			},
		},
	},
}

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")
local coreGui = game:GetService("CoreGui")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local httpService = game:GetService("HttpService")

-- Autoexec can run this before the game exists.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

while not playersService.LocalPlayer do
	task.wait()
end

replicatedStorage:WaitForChild("Modules")

-- Game modules.
local GameState = require(replicatedStorage.Modules.GameState)
local MineConfig = require(replicatedStorage.Modules.MineConfig)
local MineInventory = require(replicatedStorage.Modules.MineInventory)
local MineStock = require(replicatedStorage.Modules.MineStock)
local MineIndex = require(replicatedStorage.Modules.MineIndexRewardsConfig)
local MineDailySpin = require(replicatedStorage.Modules.MineDailySpinConfig)
local MineTrial = require(replicatedStorage.Modules.MineTrialConfig)
local String = require(replicatedStorage.Modules.String)

-- Local player.
local localPlayer = playersService.LocalPlayer

-- Interface root.
local screenGui = nil

-- Interface labels updated by the refresh loop.
local ui = {}

-- Interface connections.
local uiConnections = {}

-- Session numbers shown on the home page.
local session = { startedAt = os.clock(), startMoney = nil, sells = 0, status = "Idle", lastTake = 0 }

-- Area completion state.
local hunt = { key = nil, startedAt = 0, skipped = {}, missing = {} }

-- Whether the server says this account can claim Buff Mode.
local buffMember = false

-- Newest activity lines first.
local activity = {}

---Add a line to the activity card.
---@param text string
local function logActivity(text)
	table.insert(activity, 1, string.format("%s   %s", os.date("%H:%M:%S"), text))
	activity[MAX_ACTIVITY_LINES + 1] = nil
end

-- Next allowed time for each action key.
local cooldowns = {}

---Get the player's data.
---@return table?, table?
local function getData()
	local data = GameState.GetData2()
	return data, data and data.MineGame
end

---Send an event, unless this copy of the script has been unloaded.
---@param eventName string
---@vararg any
local function send(eventName, ...)
	if AutoFarm.running then
		GameState.SendEvent(eventName, ...)
	end
end

---Check that the server will accept actions right now.
---@return boolean
local function canAct()
	local _, mineGame = getData()

	return mineGame ~= nil
		and localPlayer:GetAttribute("ReloadingPlayerData") ~= true
		and localPlayer:GetAttribute("MineTradeSettling") ~= true
		and localPlayer:GetAttribute("MineTradeBusy") ~= true
end

---Get the player's plot.
---@return Model?
local function getPlot()
	local world = workspace:FindFirstChild("MineWorld")
	local plots = world and world:FindFirstChild("Plots")

	return plots and plots:FindFirstChild("MinePlot" .. tostring(localPlayer:GetAttribute("MinePlotIndex")))
end

---Get how full the chest is.
---@param mineGame table
---@return number, number
local function getChestFill(mineGame)
	local plot = getPlot()
	local count = 0

	for _, amount in pairs(mineGame.Chest or {}) do
		count += tonumber(amount) or 0
	end

	return count, math.max(plot and plot:GetAttribute("ChestCapacity") or 1, 1)
end

---Get the next locked zone.
---@param mineGame table
---@return string?, table?, number
local function getNextZone(mineGame)
	local deepest = 0

	for index, zoneKey in ipairs(MineConfig.ZoneKeys) do
		if (mineGame.UnlockedZones or {})[zoneKey] then
			deepest = index
		end
	end

	local nextKey = MineConfig.ZoneKeys[deepest + 1]

	return nextKey, nextKey and MineConfig.Zones[nextKey], deepest + 1
end

---Get the character parts used for movement.
---@return Humanoid?, BasePart?
local function getBody()
	local character = localPlayer.Character
	if not character then
		return nil, nil
	end

	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
end

---Check an action cooldown.
---@param key string
---@return boolean
local function isReady(key)
	return os.clock() >= (cooldowns[key] or 0)
end

---Send a purchase and back off when the money does not change.
---@param key string
---@param eventName string
---@vararg any
---@return boolean
local function purchase(key, eventName, ...)
	if not AutoFarm.running or not canAct() then
		return false
	end

	local data = getData()
	local moneyBefore = data and data.Money

	send(eventName, ...)
	task.wait(ACTION_DELAY)

	local dataAfter = getData()
	local bought = dataAfter ~= nil and dataAfter.Money ~= moneyBefore

	if not bought then
		cooldowns[key] = os.clock() + RETRY_COOLDOWN
	end

	return bought
end

---Hop beside a stand, run an action, and return to the starting spot.
---@param stand Model
---@param action function
---@param settle number
---@return boolean
local function hopToStand(stand, action, settle)
	local humanoid, rootPart = getBody()
	local prompt = stand and stand:FindFirstChildWhichIsA("ProximityPrompt", true)

	if not humanoid or not rootPart or not prompt or humanoid.Health <= 0 or humanoid.Sit then
		return false
	end

	local target = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or stand:GetPivot().Position
	local home = rootPart.CFrame
	local camera = workspace.CurrentCamera
	local cameraType = camera.CameraType

	-- Hold the camera still so the player's screen doesn't jump during the hop.
	camera.CameraType = Enum.CameraType.Scriptable

	rootPart.CFrame = CFrame.new(target + STAND_OFFSET)
	task.wait(settle)

	local success, message = pcall(action)

	task.wait(settle)

	-- Always go home, even when the action failed.
	if rootPart.Parent then
		rootPart.CFrame = home
	end

	camera.CameraType = cameraType

	if not success then
		warn(string.format("[AutoFarm] Hop: %s", tostring(message)))
	end

	return success
end

---Get the sell category of a bag entry. Anything else, like potions and keys, is never sold.
---@param entry table
---@return string?
local function getSellType(entry)
	if MineInventory.Matches(entry, "Ores") then
		return "Ores"
	elseif MineInventory.Matches(entry, "Miners") then
		return "Miners"
	elseif entry.Kind == "Pickaxe" then
		return "Pickaxes"
	end

	return nil
end

---Collect keys allowed by the sell dropdowns. Equipped pickaxes have a sell count of zero.
---@param mineGame table
---@return string[], number
local function getSellPlan(mineGame)
	local settings = AutoFarm.settings
	local keys = {}
	local worth = 0

	for _, entry in ipairs(MineInventory.Collect(mineGame)) do
		local sellType = getSellType(entry)
		local count = tonumber(entry.SellCount or entry.Count) or 0

		if sellType and count > 0 and settings.sellTypes[sellType] and settings.sellRarities[entry.Rarity] then
			keys[#keys + 1] = entry.Key
			worth += tonumber(entry.Worth) or 0
		end
	end

	return keys, worth
end

---Take everything from the chest.
---@return boolean
local function takeChest()
	local _, mineGame = getData()
	if not mineGame or next(mineGame.Chest or {}) == nil then
		return false
	end

	session.status = "Taking the chest."
	send("MineTakeChest")
	task.wait(1)

	return true
end

---Arrange the crew.
local function equipBest()
	send("MineEquipBest")
	task.wait(1)
end

---Sell the bag at the item buyer.
local function sellInventory()
	local _, mineGame = getData()
	if not mineGame then
		return
	end

	local keys, worth = getSellPlan(mineGame)
	if #keys == 0 or worth < MIN_SELL_WORTH then
		return
	end

	session.status = "Selling your bag."

	local moneyBefore = getData().Money

	-- The server's distance check needs a moment to see the hop, so start short and retry longer.
	for _, settle in ipairs(HOP_SETTLES) do
		local hopped = hopToStand(workspace:FindFirstChild("SellStand"), function()
			send("MineSellItems", keys)
		end, settle)

		if not hopped then
			return
		end

		local waitedSince = os.clock()

		-- Only count sales the server really paid for.
		while os.clock() - waitedSince < SALE_CONFIRM_TIME do
			if getData().Money ~= moneyBefore then
				session.sells += 1
				logActivity(string.format("Sold %d stacks", #keys))

				return
			end

			task.wait(0.1)
		end
	end

	logActivity("Sale refused by the server")
end

---Count owned copies of a pickaxe. The saved count already includes equipped ones.
---@param mineGame table
---@param name string
---@return number
local function countPickaxe(mineGame, name)
	return tonumber((mineGame.Pickaxes or {})[name]) or 0
end

---Find the strongest pickaxe worth buying.
---@param data table
---@return number?, table?
local function findPickaxe(data)
	local mineGame = data.MineGame
	local money = tonumber(data.Money) or 0
	local bestIndex, bestDefinition = nil, nil
	local strongestEquipped = 0
	local filledSlots = 0

	for _, holder in pairs(mineGame.Holders or {}) do
		local pickaxe = holder.Pickaxe and MineConfig.GetPickaxeByName(holder.Pickaxe)

		if pickaxe then
			filledSlots += 1
			strongestEquipped = math.max(strongestEquipped, pickaxe.Multiplier)
		end
	end

	-- Empty pads still need a pickaxe, even a weaker one.
	if filledSlots < (mineGame.MinerSlots or 0) then
		strongestEquipped = 0
	end

	for index, definition in ipairs(MineConfig.Pickaxes) do
		local unlocked = (mineGame.UnlockedZones or {})[definition.ZoneReq] == true
		local affordable = tonumber(definition.Cost) ~= nil and definition.Cost <= money

		-- Stock is nil for free pickaxes, and those are always available.
		local remaining = MineStock.GetRemaining(data, definition.Name)
		local inStock = remaining == nil or remaining > 0

		-- Weaker pickaxes are skipped, so selling spares never causes a rebuy.
		local upgrade = definition.Multiplier > strongestEquipped

		if unlocked and affordable and inStock and upgrade and isReady("Pickaxe" .. index) then
			if not bestDefinition or definition.Multiplier > bestDefinition.Multiplier then
				bestIndex, bestDefinition = index, definition
			end
		end
	end

	-- Never fall back to a weaker pickaxe once the strongest one fills every slot.
	if bestDefinition and countPickaxe(mineGame, bestDefinition.Name) >= (mineGame.MinerSlots or 0) then
		return nil, nil
	end

	return bestIndex, bestDefinition
end

---Buy the best affordable pickaxes. The shop has no distance check.
---@return boolean
local function buyPickaxes()
	local boughtAny = false

	for _ = 1, MAX_ACTIONS_PER_GROUP do
		local data, mineGame = getData()

		local index = data and mineGame and findPickaxe(data)
		if not index then
			break
		end

		if purchase("Pickaxe" .. index, "MineBuyPickaxe", index) then
			boughtAny = true
			logActivity("Bought " .. MineConfig.Pickaxes[index].Name)
		end
	end

	return boughtAny
end

---Buy core upgrades through the game's own open-node rules.
local function buyCore()
	for _ = 1, MAX_ACTIONS_PER_GROUP do
		local _, mineGame = getData()
		local chosen = nil

		for _, node in ipairs(MineConfig.CoreNodes) do
			local key = "Core" .. node.Family
			local available = not MineConfig.IsCoreNodeMaxed(mineGame, node) and MineConfig.IsCoreNodeOpen(mineGame, node)

			if available and isReady(key) then
				chosen = node
				break
			end
		end

		if not chosen then
			return
		end

		purchase("Core" .. chosen.Family, MineConfig.CoreUpgradeById[chosen.Family].Event)
	end
end

---Buy area research in every unlocked zone.
local function buySkills()
	local _, mineGame = getData()

	for zoneKey in pairs(mineGame.UnlockedZones or {}) do
		for _ = 1, MAX_ACTIONS_PER_GROUP do
			local _, current = getData()
			local skills = (current.Skills or {})[zoneKey] or {}
			local chosen = nil

			for _, node in ipairs(MineConfig.GetSkillNodes(zoneKey)) do
				local key = zoneKey .. node.Id
				local available = not MineConfig.IsSkillNodeMaxed(skills, node) and MineConfig.IsSkillNodeOpen(skills, node)

				if available and isReady(key) then
					chosen = node
					break
				end
			end

			if not chosen then
				break
			end

			purchase(zoneKey .. chosen.Id, "MineBuySkill", zoneKey, chosen.Family, chosen.Id)
		end
	end
end

---Level the crew, weakest pads first.
local function buyCrew()
	local _, mineGame = getData()
	local holderKeys = {}

	for key in pairs(mineGame.Holders or {}) do
		holderKeys[#holderKeys + 1] = key
	end

	table.sort(holderKeys, function(left, right)
		local leftLevel = mineGame.Holders[left].CharLevel or 1
		local rightLevel = mineGame.Holders[right].CharLevel or 1

		return leftLevel < rightLevel
	end)

	local actions = 0

	for _, holderKey in ipairs(holderKeys) do
		for _, stat in ipairs(CREW_STATS) do
			local key = holderKey .. tostring(stat)

			if actions < MAX_ACTIONS_PER_GROUP and isReady(key) then
				purchase(key, "MineUpgradeCharacter", holderKey, stat or nil)
				actions += 1
			end
		end
	end
end

---Unlock the next zone when its research, pickaxe and cost requirements are met.
---@return boolean
local function unlockZone()
	local data, mineGame = getData()
	local nextKey, zone = getNextZone(mineGame)

	if not zone or not isReady("Zone" .. nextKey) then
		return false
	end

	local done, needed = MineConfig.GetZoneResearchProgress(mineGame.Skills, MineConfig.ZoneResearchGateFor(nextKey))
	local researched = tonumber(done) ~= nil and tonumber(needed) ~= nil and done >= needed
	local hasPickaxe = not zone.EntryPickaxe or countPickaxe(mineGame, zone.EntryPickaxe) > 0

	if not researched or not hasPickaxe or data.Money < (zone.UnlockCost or 0) then
		return false
	end

	local unlocked = purchase("Zone" .. nextKey, "MineSelectZone", nextKey)

	if unlocked then
		logActivity("Unlocked " .. tostring(zone.DisplayName))
	end

	return unlocked
end

---Check whether the next zone is close enough that crew spending should wait.
---@return boolean
local function isSavingForZone()
	if not AutoFarm.toggles.AutoZones then
		return false
	end

	local data, mineGame = getData()
	local nextKey, zone = getNextZone(mineGame)
	if not zone then
		return false
	end

	local cost = zone.UnlockCost or 0
	local done, needed = MineConfig.GetZoneResearchProgress(mineGame.Skills, MineConfig.ZoneResearchGateFor(nextKey))
	local researched = tonumber(done) ~= nil and tonumber(needed) ~= nil and done >= needed
	local hasPickaxe = not zone.EntryPickaxe or countPickaxe(mineGame, zone.EntryPickaxe) > 0

	-- Saving for a far-off zone would stop every other upgrade, so only save when it is close.
	return researched and hasPickaxe and data.Money < cost and data.Money >= cost * ZONE_SAVE_SHARE
end

---Claim finished index rewards.
local function claimIndexRewards()
	local _, mineGame = getData()
	local claimable = mineGame and MineIndex.ClaimableTiers(mineGame)

	if not claimable or claimable.Total == 0 then
		return
	end

	for key, count in pairs(claimable.ByKey) do
		if count > 0 then
			local sent = false

			for _, tier in ipairs(MineIndex.State(mineGame, key).Track) do
				for rewardIndex, claimed in ipairs(tier.ClaimedRewards) do
					local claimKey = string.format("Index%s_%s_%d", tostring(key), tostring(tier.Key), rewardIndex)

					-- A refused claim would otherwise repeat every cycle.
					if tier.Reached and not claimed and isReady(claimKey) then
						cooldowns[claimKey] = os.clock() + RETRY_COOLDOWN
						sent = true

						send(MineIndex.Events.Claim, key, tier.Key, rewardIndex)
						task.wait(CLAIM_DELAY)
					end
				end
			end

			if sent then
				logActivity("Claimed index rewards in " .. tostring(key))
			end
		end
	end
end

---Find the first unlocked area with missing index entries.
---@param mineGame table
---@return string?, string[]?
local function findUnfinishedArea(mineGame)
	for _, zoneKey in ipairs(MineConfig.ZoneKeys) do
		local unlocked = (mineGame.UnlockedZones or {})[zoneKey]

		if unlocked and not hunt.skipped[zoneKey] then
			local state = MineIndex.State(mineGame, zoneKey)

			if state and state.Count < state.Total then
				local missing = {}

				for _, entry in ipairs(MineIndex.Entries(zoneKey)) do
					if not (mineGame.Found or {})[entry.Name] then
						missing[#missing + 1] = entry.Name
					end
				end

				return zoneKey, missing
			end
		end
	end

	return nil, nil
end

---Get the deepest unlocked zone.
---@param mineGame table
---@return string?
local function getDeepestZone(mineGame)
	local deepest = nil

	for _, zoneKey in ipairs(MineConfig.ZoneKeys) do
		if (mineGame.UnlockedZones or {})[zoneKey] then
			deepest = zoneKey
		end
	end

	return deepest
end

---Switch zones when the game allows it.
---@param mineGame table
---@param zoneKey string
local function moveToZone(mineGame, zoneKey)
	-- These timed fights cost their progress if the player leaves, so never interrupt them.
	if localPlayer:GetAttribute("MeteorCoreActive") ~= nil or localPlayer:GetAttribute("TitanGeodeActive") ~= nil then
		return
	end

	if "Z" .. tostring(mineGame.CurrentZone) ~= zoneKey and isReady("MoveZone") then
		cooldowns.MoveZone = os.clock() + ZONE_MOVE_COOLDOWN

		send("MineSelectZone", zoneKey)
		task.wait(1)
	end
end

---Stay in the first unfinished area, then move on or go back to the deepest zone.
---@return boolean
local function runIndexHunt()
	local _, mineGame = getData()
	if not mineGame then
		return false
	end

	local target, missing = findUnfinishedArea(mineGame)

	if not target then
		if hunt.key then
			hunt.key = nil
			logActivity("Index hunt finished")
			moveToZone(mineGame, getDeepestZone(mineGame))
		end

		return false
	end

	if hunt.key ~= target then
		hunt.key, hunt.startedAt = target, os.clock()
		logActivity("Hunting " .. target)
	end

	if os.clock() - hunt.startedAt > AutoFarm.settings.indexLimit * 60 then
		hunt.skipped[target] = true
		hunt.key = nil
		logActivity("Skipped " .. target .. ": time limit reached")

		return true
	end

	moveToZone(mineGame, target)
	hunt.missing = missing
	session.status = string.format("Hunting %s in %s.", table.concat(missing, ", "), target)

	return true
end

---Run one economy cycle in the required order.
local function runCycle()
	if not canAct() then
		return
	end

	local _, currentGame = getData()
	local toggles = AutoFarm.toggles
	local settings = AutoFarm.settings
	local takeEvery = toggles.AutoSell and settings.sellInterval or TAKE_INTERVAL
	local actionsDue = os.clock() - session.lastTake >= takeEvery
	local chestCount, chestCapacity = getChestFill(currentGame)

	-- A long sell timer must not let the chest overflow.
	if toggles.AutoTake and chestCount >= chestCapacity * CHEST_FULL_SHARE then
		actionsDue = true
	end

	-- Everything in the take, equip and sell chain runs on the same timer to limit server traffic.
	if actionsDue and (toggles.AutoTake or toggles.AutoSell or toggles.AutoEquipBest) then
		session.lastTake = os.clock()

		local tookChest = toggles.AutoTake and takeChest()

		if toggles.AutoEquipBest and (tookChest or not toggles.AutoTake) then
			equipBest()
		end

		if toggles.AutoSell then
			sellInventory()
		end
	end

	if toggles.AutoIndexClaim or toggles.AutoIndexHunt then
		claimIndexRewards()
	end

	local hunting = false

	if toggles.AutoIndexHunt then
		hunting = runIndexHunt()
	elseif hunt.key then
		-- Turning the hunt off should not strand the player in an old zone.
		hunt.key = nil

		local _, mineGame = getData()

		moveToZone(mineGame, getDeepestZone(mineGame))
	end

	if toggles.AutoBuyPickaxes and buyPickaxes() and toggles.AutoEquipBest then
		equipBest()
	end

	if toggles.AutoSkills then
		buySkills()
	end

	if not hunting and toggles.AutoZones and unlockZone() then
		return
	end

	if not hunting and isSavingForZone() then
		return
	end

	if toggles.AutoCore then
		buyCore()
	end

	if toggles.AutoCrew then
		buyCrew()
	end

	if not hunting then
		session.status = "Waiting for the next cycle."
	end
end

---Pick the plot rock with the most health.
---@return Model?
local function findRock()
	local plot = getPlot()
	local bestRock, bestHealth = nil, 0

	if not plot then
		return nil
	end

	for _, rock in ipairs(plot.Nodes:GetChildren()) do
		local health = rock:GetAttribute("NodeHP") or 0

		if health > bestHealth and rock:FindFirstChild("NodeClick") then
			bestRock, bestHealth = rock, health
		end
	end

	return bestRock
end

---Click one rock. Clicks land from outside the click range, so the character stays still.
local function mineRock()
	local rock = findRock()
	local detector = rock and rock:FindFirstChild("NodeClick")

	if detector then
		fireclickdetector(detector)
	end
end

---Spin the daily wheel when the game says it is unlocked and ready.
---@param mineGame table
local function claimDailySpin(mineGame)
	if MineDailySpin.Unlocked(mineGame) and MineDailySpin.Ready(mineGame) and isReady("DailySpin") then
		cooldowns.DailySpin = os.clock() + RETRY_COOLDOWN

		send(MineDailySpin.Events.Open)
		task.wait(1)
		send(MineDailySpin.Events.Spin)
		logActivity("Used the daily spin")
	end
end

---Claim every mailbox reward, trying each one at most once per cooldown.
---@param data table
local function claimMail(data)
	local messages = data.Mailbox and data.Mailbox.Messages

	for _, message in pairs(messages or {}) do
		for rewardIndex in ipairs(message.Rewards or {}) do
			local key = string.format("Mail%s_%d", tostring(message.Id), rewardIndex)

			if isReady(key) then
				cooldowns[key] = os.clock() + MAIL_COOLDOWN

				send("ClaimMailboxReward", tostring(message.Id), rewardIndex)
				task.wait(CLAIM_DELAY)
			end
		end
	end
end

---Ask for Buff Mode access and claim it once the server allows it.
---@param mineGame table
local function claimBuffMode(mineGame)
	if mineGame.BuffModeClaimed then
		return
	end

	if isReady("BuffStatus") then
		cooldowns.BuffStatus = os.clock() + BUFF_STATUS_COOLDOWN
		send("MineBuffModeStatus")
	end

	if buffMember and isReady("BuffMode") then
		cooldowns.BuffMode = os.clock() + RETRY_COOLDOWN

		send("MineBuffModeClaim")
		logActivity("Claimed Buff Mode")
	end
end

---Claim finished Infinity Trial tiers.
---@param mineGame table
local function claimTrial(mineGame)
	for _, claimKey in ipairs(MineTrial.ClaimableTiers(mineGame) or {}) do
		local key = "Trial" .. tostring(claimKey)

		if isReady(key) then
			cooldowns[key] = os.clock() + RETRY_COOLDOWN

			send(MineTrial.Events.Claim, claimKey)
			task.wait(CLAIM_DELAY)
		end
	end
end

---Send the crew to the rock holding a missing index ore.
---@param mineGame table
local function aimCrew(mineGame)
	local plot = getPlot()
	if not plot or not hunt.key then
		return
	end

	local holderKeys = {}

	for key in pairs(mineGame.Holders or {}) do
		holderKeys[#holderKeys + 1] = key
	end

	table.sort(holderKeys)

	for _, rock in ipairs(plot.Nodes:GetChildren()) do
		local number = tonumber(string.match(rock.Name, "^Node(%d+)$"))

		if number and table.find(hunt.missing, rock:GetAttribute("NodeOre")) then
			send("MineFocusMany", holderKeys, number)
			return
		end
	end
end

---Turn on the best owned Big Node level in the current zone.
---@param mineGame table
local function setBigNode(mineGame)
	local zoneKey = "Z" .. tostring(mineGame.CurrentZone or 1)

	if not MineConfig.IsBigNodeUnlocked(mineGame, zoneKey) then
		return
	end

	local owned = MineConfig.GetBigNodeLevel(mineGame, zoneKey)
	local running = mineGame.BigNodeMode == true and MineConfig.GetBigNodeRunLevel(mineGame, zoneKey) or 0

	if owned > 0 and running ~= owned then
		send("MineBigNodeToggle", owned)
		logActivity("Set Big Node level " .. tostring(owned))
	end
end

---Run the slower reward and crew jobs.
local function runExtras()
	if not canAct() then
		return
	end

	local toggles = AutoFarm.toggles
	local data, mineGame = getData()

	if toggles.AutoSpin then
		claimDailySpin(mineGame)
	end

	if toggles.AutoMail then
		claimMail(data)
	end

	if toggles.AutoBuff then
		claimBuffMode(mineGame)
	end

	if toggles.AutoTrialClaim then
		claimTrial(mineGame)
	end

	if toggles.AutoFocus then
		aimCrew(mineGame)
	end

	if toggles.AutoBigNode then
		setBigNode(mineGame)
	end
end

---Run a loop with its errors contained.
---@param label string
---@param interval number
---@param callback function
local function spawnLoop(label, interval, callback)
	task.spawn(function()
		while AutoFarm.running do
			local success, message = xpcall(callback, function(failure)
				return tostring(failure) .. " " .. string.gsub(debug.traceback(), "%s+", " ")
			end)

			if not success then
				warn(string.format("[AutoFarm] %s: %s", label, tostring(message)))
			end

			task.wait(interval)
		end
	end)
end

-- Properties that accept a theme token.
local COLOR_PROPERTIES = {
	BackgroundColor3 = true,
	Color = true,
	ImageColor3 = true,
	PlaceholderColor3 = true,
	ScrollBarImageColor3 = true,
	TextColor3 = true,
}

-- Everything the appearance settings need to update.
local themed = {}
local corners = {}
local glassy = {}

---Get the active theme.
---@return table
local function getPalette()
	return THEMES[AutoFarm.settings.theme]
end

---Bind a property to a theme token.
---@param instance Instance
---@param property string
---@param token string
local function setColor(instance, property, token)
	themed[instance] = themed[instance] or {}
	themed[instance][property] = token
	instance[property] = getPalette()[token]
end

---Play a short tween.
---@param instance Instance
---@param properties table
---@param duration number?
---@param easing Enum.EasingStyle?
local function tween(instance, properties, duration, easing)
	local info = TweenInfo.new(duration or 0.16, easing or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	tweenService:Create(instance, info, properties):Play()
end

---Fade a property to a theme token.
---@param instance Instance
---@param property string
---@param token string
---@param duration number?
local function fadeColor(instance, property, token, duration)
	themed[instance] = themed[instance] or {}
	themed[instance][property] = token
	tween(instance, { [property] = getPalette()[token] }, duration or 0.18)
end

---Apply the active theme and look to the whole window.
local function applyAppearance()
	local palette = getPalette()
	local look = LOOKS[AutoFarm.settings.look]

	-- Set directly: a tween per object dropped the game to 29 FPS on every theme change.
	for instance, properties in pairs(themed) do
		for property, token in pairs(properties) do
			instance[property] = palette[token]
		end
	end

	for corner, radius in pairs(corners) do
		corner.CornerRadius = UDim.new(0, math.floor(radius * look.radius))
	end

	for element, transparency in pairs(glassy) do
		element.BackgroundTransparency = math.min(transparency + look.glass, 1)
	end
end

---Create an instance with properties.
---@param className string
---@param properties table
---@return Instance
local function create(className, properties)
	local instance = Instance.new(className)

	for property, value in pairs(properties) do
		if property == "Parent" then
			continue
		end

		if COLOR_PROPERTIES[property] and type(value) == "string" then
			setColor(instance, property, value)
		else
			instance[property] = value
		end
	end

	instance.Parent = properties.Parent

	return instance
end

---Destroy everything inside a frame and forget its appearance entries.
---@param frame Instance
local function clearChildren(frame)
	for _, descendant in ipairs(frame:GetDescendants()) do
		themed[descendant] = nil
		corners[descendant] = nil
		glassy[descendant] = nil
	end

	for _, child in ipairs(frame:GetChildren()) do
		if not child:IsA("UILayout") then
			child:Destroy()
		end
	end
end

---Round an element and give it an edge.
---@param element GuiObject
---@param radius number
---@param edge string?
---@return UIStroke?
local function style(element, radius, edge)
	local corner = create("UICorner", {
		CornerRadius = UDim.new(0, math.floor(radius * LOOKS[AutoFarm.settings.look].radius)),
		Parent = element,
	})

	corners[corner] = radius

	if edge then
		return create("UIStroke", {
			Color = edge,
			Transparency = 0.15,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = element,
		})
	end

	return nil
end

---Fade a button's color while the pointer is over it.
---@param button GuiButton
---@param normal string
---@param hovered string
local function hover(button, normal, hovered)
	button.MouseEnter:Connect(function()
		fadeColor(button, "BackgroundColor3", hovered)
	end)

	button.MouseLeave:Connect(function()
		fadeColor(button, "BackgroundColor3", normal)
	end)
end

---Make a button shrink when pressed and spring back when released.
---@param button GuiButton
local function addPress(button)
	local scale = create("UIScale", { Parent = button })
	local pressed = false

	button.MouseButton1Down:Connect(function()
		pressed = true
		tween(scale, { Scale = 0.95 }, 0.08)
	end)

	-- Only spring back after a real press, so moving the mouse around creates no tweens.
	for _, signal in ipairs({ button.MouseButton1Up, button.MouseLeave }) do
		signal:Connect(function()
			if pressed then
				pressed = false
				tween(scale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
			end
		end)
	end
end

---Set label text only when it changed.
---@param target TextLabel
---@param text string
local function setText(target, text)
	if target.Text ~= text then
		target.Text = text
	end
end

-- Last value shown by each bar.
local barValues = setmetatable({}, { __mode = "k" })

---Glide a progress bar only when its value changed.
---@param fill Frame
---@param alpha number
local function setBar(fill, alpha)
	if math.abs(alpha - (barValues[fill] or -1)) > 0.001 then
		barValues[fill] = alpha
		tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.5)
	end
end

---Create a text label.
---@param parent Instance
---@param text string
---@param size number
---@param color Color3
---@param font Enum.Font
---@param position UDim2
---@param width UDim
---@param alignment Enum.TextXAlignment?
---@return TextLabel
local function label(parent, text, size, color, font, position, width, alignment)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Font = font,
		Text = text,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = alignment or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = position,
		Size = UDim2.new(width.Scale, width.Offset, 0, size + 6),
		Parent = parent,
	})
end

---Create a content card.
---@param parent Instance
---@param height number
---@param order number
---@return Frame
local function card(parent, height, order)
	local frame = create("Frame", {
		BackgroundColor3 = THEME.card,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Size = UDim2.new(1, -10, 0, height),
		Parent = parent,
	})

	glassy[frame] = 0.04
	style(frame, 14, THEME.cardEdge)

	return frame
end

---Create a thin progress bar.
---@param parent Instance
---@param top number
---@return Frame
local function progressBar(parent, top)
	local track = create("Frame", {
		BackgroundColor3 = THEME.track,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 18, 0, top),
		Size = UDim2.new(1, -36, 0, 6),
		Parent = parent,
	})

	style(track, 3)

	local fill = create("Frame", {
		BackgroundColor3 = THEME.bar,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	})

	style(fill, 3)

	return fill
end

---Create one label and value row on the farm card.
---@param parent Frame
---@param name string
---@param top number
---@param divider boolean
---@return TextLabel
local function statRow(parent, name, top, divider)
	label(parent, name, 13, THEME.muted, Enum.Font.Gotham, UDim2.new(0.55, 0, 0, top), UDim.new(0.2, 0))

	local value = label(
		parent,
		"—",
		13,
		THEME.text,
		Enum.Font.GothamMedium,
		UDim2.new(0.75, 0, 0, top),
		UDim.new(0.25, -18),
		Enum.TextXAlignment.Right
	)

	if divider then
		create("Frame", {
			BackgroundColor3 = THEME.track,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Position = UDim2.new(0.55, 0, 0, top + 26),
			Size = UDim2.new(0.45, -18, 0, 1),
			Parent = parent,
		})
	end

	return value
end

---Create a scrolling page.
---@param parent Instance
---@return ScrollingFrame
local function page(parent)
	local frame = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.fromOffset(SIDEBAR_WIDTH, 74),
		ScrollBarImageColor3 = THEME.muted,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, -SIDEBAR_WIDTH - 12, 1, -78),
		Visible = false,
		Parent = parent,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = frame,
	})

	return frame
end

-- Full row heights, and the rows still animating.
local revealHeights = setmetatable({}, { __mode = "k" })
local revealing = {}
local revealToken = 0

---Put animating rows back to their full size.
local function finishReveal()
	for _, target in ipairs(revealing) do
		tween(target, { Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset, 0, revealHeights[target]) }, 0.01)
		target.ClipsDescendants = false
	end

	table.clear(revealing)
end

---Collect the rows of a page in reading order.
---@param parent Instance
---@param targets GuiObject[]
local function collectRows(parent, targets)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible and not ui.noReveal[child] then
			if child.AutomaticSize == Enum.AutomaticSize.Y then
				collectRows(child, targets)
			else
				targets[#targets + 1] = child
			end
		end
	end
end

---Drop every row of a page in from the top, one after another.
---@param frame ScrollingFrame
local function revealPage(frame)
	finishReveal()

	revealToken += 1

	local token = revealToken
	local targets = {}

	collectRows(frame, targets)

	table.sort(targets, function(left, right)
		if left.AbsolutePosition.Y ~= right.AbsolutePosition.Y then
			return left.AbsolutePosition.Y < right.AbsolutePosition.Y
		end

		return left.AbsolutePosition.X < right.AbsolutePosition.X
	end)

	frame.CanvasPosition = Vector2.zero
	frame.Position = UDim2.fromOffset(SIDEBAR_WIDTH, 62)
	tween(frame, { Position = UDim2.fromOffset(SIDEBAR_WIDTH, 74) }, 0.3)

	for index, target in ipairs(targets) do
		revealHeights[target] = revealHeights[target] or target.Size.Y.Offset
		revealing[index] = target
		target.ClipsDescendants = true
		target.Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset, 0, 0)

		task.delay((index - 1) * REVEAL_STAGGER, function()
			if token == revealToken then
				tween(
					target,
					{ Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset, 0, revealHeights[target]) },
					0.32
				)
			end
		end)
	end

	task.delay(#targets * REVEAL_STAGGER + 0.4, function()
		if token == revealToken then
			for _, target in ipairs(revealing) do
				target.ClipsDescendants = false
			end

			table.clear(revealing)
		end
	end)
end

---Create the left and right columns of a page.
---@param parent ScrollingFrame
---@return Frame[]
local function createColumns(parent)
	local columns = {}
	local holder = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 0, 0),
		Parent = parent,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})

	for index = 1, 2 do
		columns[index] = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Size = UDim2.new(0.5, -3, 0, 0),
			Parent = holder,
		})

		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = columns[index],
		})
	end

	return columns
end

---Create a titled section inside a column.
---@param column Frame
---@param title string
---@return Frame
local function groupbox(column, title)
	local box = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.card,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		LayoutOrder = #column:GetChildren(),
		Size = UDim2.fromScale(1, 0),
		Parent = column,
	})

	glassy[box] = 0.04
	style(box, 14, THEME.cardEdge)

	create("UIPadding", {
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		Parent = box,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = box,
	})

	local heading = label(box, title, 15, THEME.text, Enum.Font.GothamBold, UDim2.new(), UDim.new(1, 0))
	heading.LayoutOrder = 0

	return box
end

---Get the next row position in a section.
---@param box Frame
---@return number
local function nextOrder(box)
	return #box:GetChildren()
end

---Create one switch row. The whole row is clickable.
---@param box Frame
---@param row table
---@return TextButton
local function addSwitch(box, row)
	local key, title, description = row[1], row[2], row[3]
	local frame = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = THEME.track,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(box),
		Size = UDim2.new(1, 0, 0, 56),
		Text = "",
		Parent = box,
	})

	style(frame, 10)

	label(frame, title, 14, THEME.text, Enum.Font.GothamMedium, UDim2.fromOffset(8, 8), UDim.new(1, -72))
	label(frame, description, 12, THEME.muted, Enum.Font.Gotham, UDim2.fromOffset(8, 30), UDim.new(1, -72))

	local track = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = THEME.track,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(44, 24),
		Parent = frame,
	})

	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Parent = track,
	})

	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	---Show the current toggle state.
	local function paint()
		local enabled = AutoFarm.toggles[key]
		local hook = ui.toggleHooks[key]

		fadeColor(track, "BackgroundColor3", enabled and THEME.green or THEME.track, 0.2)
		tween(
			knob,
			{ Position = enabled and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) },
			0.28,
			Enum.EasingStyle.Back
		)

		if hook then
			hook(enabled)
		end
	end

	addPress(frame)

	frame.MouseEnter:Connect(function()
		tween(frame, { BackgroundTransparency = 0.7 })
	end)

	frame.MouseLeave:Connect(function()
		tween(frame, { BackgroundTransparency = 1 })
	end)

	frame.MouseButton1Click:Connect(function()
		AutoFarm.toggles[key] = not AutoFarm.toggles[key]
		paint()
	end)

	paint()
	ui.paints[#ui.paints + 1] = paint

	return frame
end

---Create a button.
---@param parent Instance
---@param text string
---@param kind string?
---@param callback function
---@return TextButton
local function addButton(parent, text, kind, callback)
	local normal = kind == "primary" and THEME.bar or kind == "danger" and THEME.red or THEME.field
	local hovered = kind == "primary" and THEME.soft or kind == "danger" and THEME.purple or THEME.track
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = normal,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		LayoutOrder = nextOrder(parent),
		Size = UDim2.new(1, 0, 0, 36),
		Text = text,
		TextColor3 = kind == "primary" and THEME.cardDeep or kind == "danger" and THEME.window or THEME.text,
		TextSize = 13,
		Parent = parent,
	})

	style(button, 9, kind == nil and THEME.cardEdge or nil)
	hover(button, normal, hovered)
	addPress(button)
	button.MouseButton1Click:Connect(callback)

	return button
end

---Create a row that shares its width between buttons.
---@param parent Instance
---@return Frame
local function addButtonRow(parent)
	local row = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(parent),
		Size = UDim2.new(1, 0, 0, 36),
		Parent = parent,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})

	return row
end

---Create a slider bound to a number in the settings.
---@param box Frame
---@param key string
---@param title string
---@param range number[]
---@param suffix string
---@return Frame
local function addSlider(box, key, title, range, suffix)
	local frame = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(box),
		Size = UDim2.new(1, 0, 0, 48),
		Parent = box,
	})

	label(frame, title, 14, THEME.text, Enum.Font.GothamMedium, UDim2.fromOffset(8, 2), UDim.new(1, -90))

	local value = label(
		frame,
		"",
		13,
		THEME.soft,
		Enum.Font.GothamMedium,
		UDim2.new(1, -88, 0, 2),
		UDim.new(0, 80),
		Enum.TextXAlignment.Right
	)

	local track = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = THEME.track,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 32),
		Size = UDim2.new(1, -16, 0, 6),
		Text = "",
		Parent = frame,
	})

	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = create("Frame", {
		BackgroundColor3 = THEME.purple,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	})

	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.bar,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Parent = track,
	})

	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	---Show the current value.
	local function paint()
		local current = AutoFarm.settings[key]
		local alpha = (current - range[1]) / (range[2] - range[1])

		value.Text = string.format("%d %s", current, suffix)
		tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.1)
		tween(knob, { Position = UDim2.fromScale(alpha, 0.5) }, 0.1)
	end

	---Set the value from a pointer position.
	---@param x number
	local function setFromPointer(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)

		AutoFarm.settings[key] = math.floor(range[1] + (range[2] - range[1]) * alpha + 0.5)
		paint()
	end

	local dragging = false

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			tween(knob, { Size = UDim2.fromOffset(18, 18) }, 0.2, Enum.EasingStyle.Back)
			setFromPointer(input.Position.X)
		end
	end)

	uiConnections[#uiConnections + 1] = userInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			setFromPointer(input.Position.X)
		end
	end)

	uiConnections[#uiConnections + 1] = userInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.2, Enum.EasingStyle.Back)
		end
	end)

	paint()
	ui.paints[#ui.paints + 1] = paint

	return frame
end

---Create a multi-select dropdown. It opens inside the section, so nothing gets cut off.
---@param box Frame
---@param title string
---@param options string[]
---@param settingKey string
local function addDropdown(box, title, options, settingKey)
	local header = addButton(box, title, nil, function() end)
	local list = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = nextOrder(box),
		Size = UDim2.fromScale(1, 0),
		Visible = false,
		Parent = box,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})

	ui.noReveal[list] = true
	header.TextXAlignment = Enum.TextXAlignment.Left
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = header })

	local chevron = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Text = "›",
		TextColor3 = THEME.muted,
		TextSize = 18,
		Parent = header,
	})

	local openHeight = #options * 30 + (#options - 1) * 2
	local isOpen = false
	local dropdownToken = 0

	local paints = {}

	---Show how many options are selected.
	local function paintHeader()
		local selected = 0

		for _, option in ipairs(options) do
			selected += AutoFarm.settings[settingKey][option] and 1 or 0
		end

		header.Text = string.format("%s  (%d of %d)", title, selected, #options)
	end

	for order, option in ipairs(options) do
		local row = create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = THEME.field,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 30),
			Text = option,
			TextColor3 = THEME.text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = list,
		})

		style(row, 7)
		hover(row, THEME.field, THEME.track)
		addPress(row)
		create("UIPadding", { PaddingLeft = UDim.new(0, 34), Parent = row })

		local check = create("Frame", {
			BackgroundColor3 = THEME.track,
			BorderSizePixel = 0,
			Position = UDim2.new(0, -24, 0.5, -7),
			Size = UDim2.fromOffset(14, 14),
			Parent = row,
		})

		style(check, 4)

		paints[order] = function()
			local selected = AutoFarm.settings[settingKey][option]

			fadeColor(check, "BackgroundColor3", selected and THEME.green or THEME.track)
			check.Size = UDim2.fromOffset(10, 10)
			check.Position = UDim2.new(0, -22, 0.5, -5)
			tween(
				check,
				{ Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, -24, 0.5, -7) },
				0.26,
				Enum.EasingStyle.Back
			)
		end

		row.MouseButton1Click:Connect(function()
			local selection = AutoFarm.settings[settingKey]

			selection[option] = not selection[option] or nil
			paints[order]()
			paintHeader()
		end)

		paints[order]()
	end

	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		dropdownToken += 1

		local token = dropdownToken

		tween(chevron, { Rotation = isOpen and 90 or 0 }, 0.24)

		if isOpen then
			list.Visible = true
			tween(list, { Size = UDim2.new(1, 0, 0, openHeight) }, 0.3)
		else
			tween(list, { Size = UDim2.fromScale(1, 0) }, 0.22)

			task.delay(0.22, function()
				if token == dropdownToken then
					list.Visible = false
				end
			end)
		end
	end)

	ui.paints[#ui.paints + 1] = function()
		for _, paint in ipairs(paints) do
			paint()
		end

		paintHeader()
	end

	paintHeader()
end

---Create a text input.
---@param parent Instance
---@param placeholder string
---@return TextBox
local function addInput(parent, placeholder)
	local input = create("TextBox", {
		BackgroundColor3 = THEME.field,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(parent),
		PlaceholderColor3 = THEME.muted,
		PlaceholderText = placeholder,
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		TextColor3 = THEME.text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})

	style(input, 9, THEME.cardEdge)
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = input })

	return input
end

---Build the home page.
---@param parent ScrollingFrame
local function buildHome(parent)
	local hello = card(parent, 92, 1)
	local avatar = create("ImageLabel", {
		BackgroundColor3 = THEME.cardDeep,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(18, 17),
		Size = UDim2.fromOffset(58, 58),
		Parent = hello,
	})

	style(avatar, 29, THEME.cardEdge)

	task.spawn(function()
		local success, image = pcall(function()
			return playersService:GetUserThumbnailAsync(
				localPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)

		if success then
			avatar.Image = image
		end
	end)

	local name = localPlayer.Name
	label(hello, "Hello, " .. name, 18, THEME.text, Enum.Font.GothamBold, UDim2.fromOffset(90, 22), UDim.new(0.55, -90))
	ui.subtitle = label(hello, "", 13, THEME.muted, Enum.Font.Gotham, UDim2.fromOffset(90, 50), UDim.new(0.6, -90))
	label(
		hello,
		"Cash",
		14,
		THEME.muted,
		Enum.Font.GothamMedium,
		UDim2.new(0.55, 0, 0, 22),
		UDim.new(0.2, 0),
		Enum.TextXAlignment.Right
	)
	ui.cash = label(
		hello,
		"—",
		18,
		THEME.text,
		Enum.Font.GothamBold,
		UDim2.new(0.75, 0, 0, 20),
		UDim.new(0.25, -18),
		Enum.TextXAlignment.Right
	)
	ui.gain = label(
		hello,
		"",
		12,
		THEME.green,
		Enum.Font.GothamMedium,
		UDim2.new(0.6, 0, 0, 50),
		UDim.new(0.4, -18),
		Enum.TextXAlignment.Right
	)

	local farm = card(parent, 216, 2)
	label(farm, "Farm", 15, THEME.text, Enum.Font.GothamBold, UDim2.fromOffset(18, 18), UDim.new(0.3, 0))

	local pill = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = THEME.track,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -18, 0, 15),
		Size = UDim2.fromOffset(78, 30),
		Parent = farm,
	})

	style(pill, 15)

	ui.pillDot = create("Frame", {
		BackgroundColor3 = THEME.muted,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(11, 11),
		Size = UDim2.fromOffset(8, 8),
		Parent = pill,
	})

	style(ui.pillDot, 4)

	ui.pillText = label(pill, "Idle", 13, THEME.soft, Enum.Font.GothamMedium, UDim2.fromOffset(25, 5), UDim.new(1, -30))
	ui.gained = label(farm, "$0", 34, THEME.soft, Enum.Font.GothamBold, UDim2.fromOffset(18, 58), UDim.new(0.5, -18))
	ui.rate = label(farm, "$0 per hour", 13, THEME.text, Enum.Font.GothamMedium, UDim2.fromOffset(18, 106), UDim.new(0.5, 0))
	ui.status = label(farm, "Idle", 13, THEME.muted, Enum.Font.Gotham, UDim2.fromOffset(18, 133), UDim.new(0.5, 0))
	ui.chest = label(farm, "— in chest", 13, THEME.soft, Enum.Font.GothamMedium, UDim2.fromOffset(18, 162), UDim.new(0.5, 0))
	ui.session = statRow(farm, "Session", 62, true)
	ui.sells = statRow(farm, "Sells", 94, true)
	ui.restock = statRow(farm, "Pickaxe restock", 126, false)
	ui.chestBar = progressBar(farm, 192)

	local zone = card(parent, 142, 3)
	label(zone, "Next area", 15, THEME.text, Enum.Font.GothamBold, UDim2.fromOffset(18, 18), UDim.new(0.5, 0))

	local badge = create("TextLabel", {
		BackgroundColor3 = THEME.cardDeep,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(18, 52),
		Size = UDim2.fromOffset(52, 52),
		Text = "",
		TextColor3 = THEME.purple,
		TextSize = 20,
		Parent = zone,
	})

	style(badge, 10)
	create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = THEME.purple,
		Thickness = 2,
		Parent = badge,
	})

	ui.zoneBadge = badge
	ui.research = label(zone, "—", 19, THEME.text, Enum.Font.GothamBold, UDim2.fromOffset(84, 52), UDim.new(0.55, -84))
	label(zone, "Next:", 13, THEME.muted, Enum.Font.Gotham, UDim2.fromOffset(84, 82), UDim.new(0, 38))
	ui.zoneName = label(zone, "—", 13, THEME.purple, Enum.Font.GothamMedium, UDim2.fromOffset(122, 82), UDim.new(0.5, -122))
	ui.zoneCost = label(
		zone,
		"—",
		13,
		THEME.text,
		Enum.Font.GothamMedium,
		UDim2.new(0.5, 0, 0, 52),
		UDim.new(0.5, -18),
		Enum.TextXAlignment.Right
	)
	ui.zonePick = label(
		zone,
		"—",
		13,
		THEME.muted,
		Enum.Font.Gotham,
		UDim2.new(0.5, 0, 0, 82),
		UDim.new(0.5, -18),
		Enum.TextXAlignment.Right
	)
	ui.zoneBar = progressBar(zone, 118)

	local crew = card(parent, 145, 4)
	label(crew, "Crew", 15, THEME.text, Enum.Font.GothamBold, UDim2.fromOffset(18, 18), UDim.new(0.5, 0))

	local strip = create("Frame", {
		BackgroundColor3 = THEME.cardDeep,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(18, 52),
		Size = UDim2.new(1, -36, 0, 74),
		Parent = crew,
	})

	style(strip, 10, THEME.track)

	ui.crew = {}

	for index, name2 in ipairs({ "Best pickaxe", "Miners", "Tap level" }) do
		local left = (index - 1) / 3

		label(strip, name2, 12, THEME.muted, Enum.Font.Gotham, UDim2.new(left, 17, 0, 12), UDim.new(1 / 3, -24))
		ui.crew[index] = label(strip, "—", 15, THEME.soft, Enum.Font.GothamMedium, UDim2.new(left, 17, 0, 36), UDim.new(1 / 3, -24))

		if index > 1 then
			create("Frame", {
				BackgroundColor3 = THEME.track,
				BorderSizePixel = 0,
				Position = UDim2.new(left, 0, 0, 12),
				Size = UDim2.new(0, 1, 1, -24),
				Parent = strip,
			})
		end
	end

	local log = card(parent, 58 + MAX_ACTIVITY_LINES * 22, 5)
	label(log, "Activity", 15, THEME.text, Enum.Font.GothamBold, UDim2.fromOffset(18, 18), UDim.new(0.5, 0))

	ui.activity = {}

	for index = 1, MAX_ACTIVITY_LINES do
		ui.activity[index] = label(
			log,
			"",
			13,
			THEME.muted,
			Enum.Font.Gotham,
			UDim2.fromOffset(18, 28 + index * 22),
			UDim.new(1, -36)
		)
	end
end

---Turn off every automation toggle.
local function disableAll()
	for key in pairs(AutoFarm.toggles) do
		AutoFarm.toggles[key] = false
	end

	for _, paint in ipairs(ui.paints) do
		paint()
	end

	logActivity("Turned everything off")
end

---Check that the executor can save files.
---@return boolean
local function canSave()
	return writefile ~= nil and readfile ~= nil and isfile ~= nil and listfiles ~= nil and makefolder ~= nil
end

---Create the config folders.
local function ensureFolders()
	if not isfolder(CONFIG_FOLDER) then
		makefolder(CONFIG_FOLDER)
	end

	if not isfolder(CONFIG_PATH) then
		makefolder(CONFIG_PATH)
	end
end

---Turn a typed name into a safe file name.
---@param name string
---@return string
local function cleanConfigName(name)
	return string.gsub(string.gsub(name, "[^%w%s_-]", ""), "^%s*(.-)%s*$", "%1")
end

---Get the file path of a config.
---@param name string
---@return string
local function configFile(name)
	return string.format("%s/%s.json", CONFIG_PATH, name)
end

---List saved configs.
---@return string[]
local function listConfigs()
	local names = {}

	if not canSave() then
		return names
	end

	ensureFolders()

	for _, path in ipairs(listfiles(CONFIG_PATH)) do
		local name = string.match(string.gsub(path, "\\", "/"), "([^/]+)%.json$")

		if name then
			names[#names + 1] = name
		end
	end

	table.sort(names)

	return names
end

---Save the current toggles and appearance.
---@param name string
---@return boolean
local function saveConfig(name)
	if not canSave() or name == "" then
		return false
	end

	ensureFolders()
	writefile(configFile(name), httpService:JSONEncode({
		toggles = AutoFarm.toggles,
		settings = AutoFarm.settings,
	}))

	return true
end

---Copy only known and valid values from a saved config.
---@param saved table
local function applyConfig(saved)
	local settings = AutoFarm.settings
	local savedSettings = type(saved.settings) == "table" and saved.settings or {}

	for key, value in pairs(type(saved.toggles) == "table" and saved.toggles or {}) do
		if AutoFarm.toggles[key] ~= nil and type(value) == "boolean" then
			AutoFarm.toggles[key] = value
		end
	end

	if THEMES[savedSettings.theme] then
		settings.theme = savedSettings.theme
	end

	if LOOKS[savedSettings.look] then
		settings.look = savedSettings.look
	end

	if type(savedSettings.key) == "string" and pcall(function()
		return Enum.KeyCode[savedSettings.key]
	end) then
		settings.key = savedSettings.key
	end

	-- Edited files can hold decimals, which would break the slider's number display.
	if type(savedSettings.sellInterval) == "number" then
		local interval = math.floor(savedSettings.sellInterval)

		settings.sellInterval = math.clamp(interval, SELL_INTERVAL_RANGE[1], SELL_INTERVAL_RANGE[2])
	end

	if type(savedSettings.indexLimit) == "number" then
		local limit = math.floor(savedSettings.indexLimit)

		settings.indexLimit = math.clamp(limit, INDEX_LIMIT_RANGE[1], INDEX_LIMIT_RANGE[2])
	end

	for settingKey, options in pairs({ sellRarities = RARITIES, sellTypes = SELL_TYPES }) do
		if type(savedSettings[settingKey]) == "table" then
			local selection = {}

			for _, option in ipairs(options) do
				selection[option] = savedSettings[settingKey][option] == true or nil
			end

			settings[settingKey] = selection
		end
	end

	if type(savedSettings.width) == "number" and type(savedSettings.height) == "number" then
		ui.setWindowSize(savedSettings.width, savedSettings.height)
	end

	for _, paint in ipairs(ui.paints) do
		paint()
	end

	applyAppearance()
	ui.refreshSettings()
end

---Load a saved config.
---@param name string
---@return boolean
local function loadConfig(name)
	if not canSave() or not isfile(configFile(name)) then
		return false
	end

	local success, saved = pcall(function()
		return httpService:JSONDecode(readfile(configFile(name)))
	end)

	if not success or type(saved) ~= "table" then
		return false
	end

	applyConfig(saved)

	return true
end

---Get the name of the autoload config.
---@return string?
local function getAutoload()
	if not canSave() or not isfile(AUTOLOAD_PATH) then
		return nil
	end

	local name = readfile(AUTOLOAD_PATH)

	return name ~= "" and name or nil
end

---Refresh the live values on the home page.
local function refreshInterface()
	local data, mineGame = getData()
	if not data or not mineGame then
		return
	end

	local money = tonumber(data.Money) or 0
	session.startMoney = session.startMoney or money

	-- Nothing on the home page can be seen, so skip the work.
	if not ui.homeShown then
		return
	end

	local elapsed = math.max(os.clock() - session.startedAt, 1)
	local gained = money - session.startMoney
	local hours, minutes, seconds = elapsed // 3600, elapsed // 60 % 60, elapsed // 1 % 60
	local active = false

	for _, enabled in pairs(AutoFarm.toggles) do
		active = active or enabled
	end

	local gainSign = gained < 0 and "-" or "+"
	local gainText = String:ToMoney(math.abs(gained))

	setText(ui.subtitle, string.format(
		"@%s · Zone %d · %d miner slots",
		localPlayer.Name,
		tonumber(mineGame.CurrentZone) or 1,
		tonumber(mineGame.MinerSlots) or 0
	))
	setText(ui.cash, String:ToMoney(money))
	setText(ui.gain, gained ~= 0 and (gainSign .. gainText) or "")
	setColor(ui.gain, "TextColor3", gained < 0 and THEME.red or THEME.green)
	setText(ui.gained, (gained < 0 and "-" or "") .. gainText)
	setText(ui.rate, (gained < 0 and "-" or "") .. String:ToMoney(math.abs(gained) / elapsed * 3600) .. " per hour")
	setText(ui.status, active and session.status or "All automation is off.")
	setText(ui.pillText, active and "Active" or "Idle")

	-- The status dot breathes while anything is running.
	if active ~= ui.dotActive then
		ui.dotActive = active
		fadeColor(ui.pillDot, "BackgroundColor3", active and THEME.green or THEME.muted, 0.3)

		if ui.dotPulse then
			ui.dotPulse:Cancel()
			ui.dotPulse = nil
			ui.pillDot.BackgroundTransparency = 0
		end

		if active then
			local info = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

			ui.dotPulse = tweenService:Create(ui.pillDot, info, { BackgroundTransparency = 0.6 })
			ui.dotPulse:Play()
		end
	end
	setText(ui.session, hours > 0 and string.format("%dh %dm", hours, minutes) or string.format("%dm %02ds", minutes, seconds))
	setText(ui.sells, tostring(session.sells))
	setText(ui.restock, session.restock or "—")

	local chestCount, capacity = getChestFill(mineGame)

	setText(ui.chest, MineConfig.FormatCount(chestCount) .. " in chest")
	setBar(ui.chestBar, math.clamp(chestCount / capacity, 0, 1))

	local nextKey, zone, nextNumber = getNextZone(mineGame)

	if zone then
		local gate = MineConfig.ZoneResearchGateFor(nextKey)
		local done, needed = MineConfig.GetZoneResearchProgress(mineGame.Skills, gate)
		done, needed = tonumber(done) or 0, tonumber(needed) or 1

		setText(ui.zoneBadge, "Z" .. tostring(nextNumber))
		setText(ui.research, string.format("Research %d / %d", done, needed))
		setText(ui.zoneName, tostring(zone.DisplayName))
		setText(ui.zoneCost, String:ToMoney(zone.UnlockCost or 0))
		setText(ui.zonePick, zone.EntryPickaxe and ("Needs " .. zone.EntryPickaxe) or "No pickaxe needed")
		setBar(ui.zoneBar, math.clamp(done / math.max(needed, 1), 0, 1))
	else
		setText(ui.research, "All zones unlocked")
		setText(ui.zoneName, "—")
		setText(ui.zoneCost, "—")
		setText(ui.zonePick, "—")
		setBar(ui.zoneBar, 1)
	end

	local bestPickaxe, bestPower, miners = "—", 0, 0

	for _, holder in pairs(mineGame.Holders or {}) do
		local pickaxe = holder.Pickaxe and MineConfig.GetPickaxeByName(holder.Pickaxe)

		miners += holder.CharName and 1 or 0

		if pickaxe and pickaxe.Multiplier > bestPower then
			bestPickaxe, bestPower = pickaxe.Name, pickaxe.Multiplier
		end
	end

	setText(ui.crew[1], bestPickaxe)
	setText(ui.crew[2], string.format("%d / %d", miners, tonumber(mineGame.MinerSlots) or 0))
	setText(ui.crew[3], tostring(mineGame.TapLevel or 1))

	for index, line in ipairs(ui.activity) do
		setText(line, activity[index] or "")
	end
end

---Show a short message on the settings page.
---@param text string
local function setConfigNote(text)
	ui.configNote.Text = text
end

---Rebuild the saved config list.
local function refreshConfigList()
	clearChildren(ui.configList)

	local names = listConfigs()

	if not table.find(names, ui.selectedConfig) then
		ui.selectedConfig = nil
	end

	for _, name in ipairs(names) do
		local selected = name == ui.selectedConfig
		local button = addButton(ui.configList, name, nil, function()
			ui.selectedConfig = name
			ui.configName.Text = name
			refreshConfigList()
		end)

		button.Size = UDim2.new(1, 0, 0, 30)

		if selected then
			setColor(button:FindFirstChildOfClass("UIStroke"), "Color", THEME.purple)
		end
	end

	ui.configEmpty.Visible = #names == 0
	ui.autoloadNote.Text = "Autoload: " .. (getAutoload() or "none")
end

---Show the selected theme, look and key.
local function refreshSettings()
	local settings = AutoFarm.settings

	for name, stroke in pairs(ui.themeStrokes) do
		setColor(stroke, "Color", name == settings.theme and THEME.purple or THEME.cardEdge)
	end

	for name, button in pairs(ui.lookButtons) do
		local selected = name == settings.look
		local stroke = button:FindFirstChildOfClass("UIStroke")

		setColor(stroke, "Color", selected and THEME.purple or THEME.cardEdge)
		setColor(button, "TextColor3", selected and THEME.text or THEME.muted)
	end

	ui.keyButton.Text = "Hide key: " .. settings.key
end

---Create one theme swatch.
---@param parent Frame
---@param name string
local function addThemeSwatch(parent, name)
	local colors = THEMES[name]
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = colors.card,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = "",
		Parent = parent,
	})

	ui.themeStrokes[name] = style(button, 9, THEME.cardEdge)
	addPress(button)

	create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Text = name,
		TextColor3 = colors.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = button,
	})

	local dot = create("Frame", {
		BackgroundColor3 = colors.purple,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0.5, -8),
		Size = UDim2.fromOffset(16, 16),
		Parent = button,
	})

	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

	button.MouseButton1Click:Connect(function()
		AutoFarm.settings.theme = name
		applyAppearance()
		refreshSettings()
	end)
end

---Build the settings page.
---@param parent ScrollingFrame
local function buildSettings(parent)
	local columns = createColumns(parent)
	local appearance = groupbox(columns[1], "Theme")

	ui.themeStrokes = {}
	ui.lookButtons = {}

	local swatches = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(appearance),
		Size = UDim2.fromScale(1, 0),
		Parent = appearance,
	})

	create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(6, 6),
		CellSize = UDim2.new(0.5, -3, 0, 40),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = swatches,
	})

	for _, name in ipairs(THEME_ORDER) do
		addThemeSwatch(swatches, name)
	end

	local looks = groupbox(columns[1], "Look")
	local lookRow = addButtonRow(looks)

	for _, name in ipairs(LOOK_ORDER) do
		ui.lookButtons[name] = addButton(lookRow, name, nil, function()
			AutoFarm.settings.look = name
			applyAppearance()
			refreshSettings()
		end)
	end

	local menu = groupbox(columns[1], "Window")

	ui.keyButton = addButton(menu, "Hide key", nil, function()
		ui.capturingKey = true
		ui.keyButton.Text = "Press any key..."
	end)

	addButton(menu, "Reset window size", nil, function()
		ui.setWindowSize(976, 750)
	end)

	addButton(menu, "Hide window", nil, function()
		ui.setWindowVisible(false)
	end)

	addButton(menu, "Unload script", "danger", AutoFarm.detach)

	local configs = groupbox(columns[2], "Configs")

	ui.configName = addInput(configs, "Config name")

	local firstRow = addButtonRow(configs)

	addButton(firstRow, "Create", "primary", function()
		local name = cleanConfigName(ui.configName.Text)

		if saveConfig(name) then
			ui.selectedConfig = name
			setConfigNote("Saved " .. name)
			refreshConfigList()
		else
			setConfigNote("Type a config name first.")
		end
	end)

	addButton(firstRow, "Load", nil, function()
		local name = ui.selectedConfig

		if not name then
			setConfigNote("Pick a config first.")
		elseif loadConfig(name) then
			setConfigNote("Loaded " .. name)
		else
			setConfigNote("Could not read " .. name)
		end
	end)

	local secondRow = addButtonRow(configs)

	addButton(secondRow, "Overwrite", nil, function()
		local name = ui.selectedConfig

		setConfigNote(name and saveConfig(name) and ("Overwrote " .. name) or "Pick a config first.")
	end)

	addButton(secondRow, "Delete", nil, function()
		local name = ui.selectedConfig

		if not delfile then
			setConfigNote("This executor cannot delete files.")
			return
		elseif not name then
			setConfigNote("Pick a config first.")
			return
		end

		delfile(configFile(name))

		if getAutoload() == name then
			writefile(AUTOLOAD_PATH, "")
		end

		ui.selectedConfig = nil
		ui.configName.Text = ""
		setConfigNote("Deleted " .. name)
		refreshConfigList()
	end)

	local thirdRow = addButtonRow(configs)

	addButton(thirdRow, "Set autoload", nil, function()
		local name = ui.selectedConfig

		if not name then
			setConfigNote("Pick a config first.")
			return
		end

		ensureFolders()
		writefile(AUTOLOAD_PATH, name)
		setConfigNote("Autoload set to " .. name)
		refreshConfigList()
	end)

	addButton(thirdRow, "Clear autoload", nil, function()
		if canSave() then
			ensureFolders()
			writefile(AUTOLOAD_PATH, "")
			setConfigNote("Autoload cleared")
			refreshConfigList()
		end
	end)

	ui.autoloadNote = label(configs, "Autoload: none", 12, THEME.soft, Enum.Font.GothamMedium, UDim2.new(), UDim.new(1, 0))
	ui.autoloadNote.LayoutOrder = nextOrder(configs)
	ui.configNote = label(configs, "", 12, THEME.muted, Enum.Font.Gotham, UDim2.new(), UDim.new(1, 0))
	ui.configNote.LayoutOrder = nextOrder(configs)

	if not canSave() then
		setConfigNote("This executor cannot save files.")
	end

	ui.configEmpty = label(configs, "No saved configs yet.", 12, THEME.muted, Enum.Font.Gotham, UDim2.new(), UDim.new(1, 0))
	ui.configEmpty.LayoutOrder = nextOrder(configs)

	ui.configList = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(configs),
		Size = UDim2.fromScale(1, 0),
		Parent = configs,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = ui.configList,
	})

	ui.refreshSettings = refreshSettings
end

---Draw the magnifying glass inside the search box.
---@param parent Instance
local function drawSearchIcon(parent)
	local ring = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.fromOffset(12, 12),
		Parent = parent,
	})

	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	create("UIStroke", { Color = THEME.muted, Thickness = 1.5, Parent = ring })
	create("Frame", {
		BackgroundColor3 = THEME.muted,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(26, 25),
		Rotation = 45,
		Size = UDim2.fromOffset(6, 2),
		Parent = parent,
	})
end

---Create a titled window control.
---@param parent Instance
---@param text string
---@param right number
---@param callback function
local function addControl(parent, text, right, callback)
	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		AutoButtonColor = false,
		BackgroundColor3 = THEME.window,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Position = UDim2.new(1, right, 0, 15),
		Size = UDim2.fromOffset(30, 30),
		Text = text,
		TextColor3 = THEME.soft,
		TextSize = 18,
		Parent = parent,
	})

	style(button, 8)
	hover(button, THEME.window, THEME.track)
	addPress(button)
	button.MouseButton1Click:Connect(callback)
end

---Create the window.
local function createInterface()
	local settings = AutoFarm.settings

	ui.paints = {}
	ui.rows = {}
	ui.toggleHooks = {}
	ui.noReveal = setmetatable({}, { __mode = "k" })
	ui.windowShown = true

	screenGui = create("ScreenGui", {
		Name = "AutoFarmInterface",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = gethui and gethui() or coreGui,
	})

	local viewport = workspace.CurrentCamera.ViewportSize
	local scale = math.min(1, viewport.X * 0.92 / settings.width, viewport.Y * 0.92 / settings.height)
	local window = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.window,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(settings.width, settings.height),
		Parent = screenGui,
	})

	glassy[window] = 0.03
	style(window, 14, THEME.windowEdge)

	local windowScale = create("UIScale", { Scale = scale * 0.92, Parent = window })

	tween(windowScale, { Scale = scale }, 0.34, Enum.EasingStyle.Back)

	local header = create("Frame", {
		Active = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 62),
		Parent = window,
	})

	create("Frame", {
		BackgroundColor3 = THEME.purple,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(18, 20),
		Rotation = 45,
		Size = UDim2.fromOffset(14, 14),
		Parent = window,
	})

	label(window, "Anime Mine", 21, THEME.soft, Enum.Font.GothamBold, UDim2.fromOffset(46, 13), UDim.new(0, 180))

	local search = create("TextBox", {
		BackgroundColor3 = THEME.field,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderColor3 = THEME.muted,
		PlaceholderText = "Search",
		Position = UDim2.fromOffset(SIDEBAR_WIDTH, 11),
		Size = UDim2.new(1, -SIDEBAR_WIDTH - 104, 0, 39),
		Text = "",
		TextColor3 = THEME.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = window,
	})

	style(search, 10, THEME.cardEdge)
	create("UIPadding", { PaddingLeft = UDim.new(0, 44), Parent = search })
	drawSearchIcon(create("Frame", {
		BackgroundTransparency = 1,
		Position = search.Position,
		Size = UDim2.fromOffset(40, 39),
		ZIndex = 2,
		Parent = window,
	}))

	local pages = {}
	local navigation = {}
	local currentPage = nil

	---Record whether the home page can be seen, and rest the status dot when it can't.
	local function updateHomeShown()
		ui.homeShown = ui.windowShown and currentPage == "Home"

		if ui.dotPulse then
			if ui.homeShown then
				ui.dotPulse:Play()
			else
				ui.dotPulse:Pause()
			end
		end
	end

	local navigationPill = create("Frame", {
		BackgroundColor3 = THEME.field,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(15, 74),
		Size = UDim2.fromOffset(190, 41),
		Parent = window,
	})

	style(navigationPill, 20, THEME.cardEdge)

	---Show one page, slide the sidebar pill to it, and drop its rows in.
	---@param name string
	local function showPage(name)
		if name == currentPage then
			return
		end

		currentPage = name
		updateHomeShown()

		for pageName, frame in pairs(pages) do
			frame.Visible = pageName == name
		end

		for pageName, entry in pairs(navigation) do
			local selected = pageName == name

			entry.selected = selected
			fadeColor(entry.button, "TextColor3", selected and THEME.text or THEME.muted)
			tween(entry.padding, { PaddingLeft = UDim.new(0, 20) }, 0.2)

			if selected then
				tween(navigationPill, { Position = entry.button.Position }, 0.34, Enum.EasingStyle.Back)
			end
		end

		revealPage(pages[name])
	end

	---Create one sidebar button.
	---@param name string
	---@param position UDim2
	local function navigationButton(name, position)
		local button = create("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Position = position,
			Size = UDim2.fromOffset(190, 41),
			Text = name,
			TextColor3 = THEME.muted,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = window,
		})

		local entry = {
			button = button,
			padding = create("UIPadding", { PaddingLeft = UDim.new(0, 20), Parent = button }),
			selected = false,
		}

		navigation[name] = entry
		addPress(button)

		button.MouseEnter:Connect(function()
			if not entry.selected then
				fadeColor(button, "TextColor3", THEME.soft)
				tween(entry.padding, { PaddingLeft = UDim.new(0, 27) }, 0.2)
			end
		end)

		button.MouseLeave:Connect(function()
			if not entry.selected then
				fadeColor(button, "TextColor3", THEME.muted)
				tween(entry.padding, { PaddingLeft = UDim.new(0, 20) }, 0.2)
			end
		end)

		button.MouseButton1Click:Connect(function()
			search.Text = ""
			showPage(name)
		end)
	end

	pages.Home = page(window)
	buildHome(pages.Home)
	navigationButton("Home", UDim2.fromOffset(15, 74))

	for index, definition in ipairs(PAGES) do
		pages[definition.name] = page(window)
		navigationButton(definition.name, UDim2.fromOffset(15, 74 + index * 47))

		local columns = createColumns(pages[definition.name])

		for _, group in ipairs(definition.groups) do
			local box = groupbox(columns[group.column], group.title)

			for _, row in ipairs(group.rows) do
				ui.rows[#ui.rows + 1] = {
					page = definition.name,
					text = string.lower(row[2] .. " " .. row[3]),
					frame = addSwitch(box, row),
				}
			end

			if group.custom == "sellTimer" then
				local slider = addSlider(box, "sellInterval", "Sell every", SELL_INTERVAL_RANGE, "sec")
				local sliderToken = 0

				slider.ClipsDescendants = true
				slider.Size = UDim2.fromScale(1, 0)
				slider.Visible = false
				ui.noReveal[slider] = true

				-- The timer only matters while selling, so it unfolds with Auto Sell.
				ui.toggleHooks.AutoSell = function(enabled)
					sliderToken += 1

					local token = sliderToken

					if enabled then
						slider.Visible = true
						tween(slider, { Size = UDim2.new(1, 0, 0, 48) }, 0.34, Enum.EasingStyle.Back)
					else
						tween(slider, { Size = UDim2.fromScale(1, 0) }, 0.22)

						task.delay(0.22, function()
							if token == sliderToken then
								slider.Visible = false
							end
						end)
					end
				end

				ui.toggleHooks.AutoSell(AutoFarm.toggles.AutoSell)
			elseif group.custom == "sell" then
				addDropdown(box, "Rarities to sell", RARITIES, "sellRarities")
				addDropdown(box, "Items to sell", SELL_TYPES, "sellTypes")
			elseif group.custom == "index" then
				addSlider(box, "indexLimit", "Time limit per area", INDEX_LIMIT_RANGE, "min")
			end
		end

		if definition.name == "Misc" then
			addButton(groupbox(columns[2], "Actions"), "Turn everything off", "danger", disableAll)
		end
	end

	pages.Settings = page(window)
	buildSettings(pages.Settings)
	navigationButton("Settings", UDim2.new(0, 15, 1, -56))

	search:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(search.Text)
		local firstMatch = nil

		for _, row in ipairs(ui.rows) do
			local matches = string.find(row.text, query, 1, true) ~= nil

			row.frame.Visible = matches
			firstMatch = firstMatch or (matches and row.page)
		end

		if query ~= "" and firstMatch then
			showPage(firstMatch)
		end
	end)

	ui.reopen = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = THEME.field,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Position = UDim2.fromOffset(20, 60),
		Size = UDim2.fromOffset(130, 36),
		Text = "Anime Mine",
		TextColor3 = THEME.text,
		TextSize = 13,
		Visible = false,
		Parent = screenGui,
	})

	style(ui.reopen, 10, THEME.cardEdge)
	hover(ui.reopen, THEME.field, THEME.track)

	---Show or hide the window, leaving a small button to bring it back.
	---@param visible boolean
	function ui.setWindowVisible(visible)
		ui.windowShown = visible
		ui.reopen.Visible = not visible
		updateHomeShown()

		if visible then
			window.Visible = true
			windowScale.Scale = scale * 0.92
			tween(windowScale, { Scale = scale }, 0.3, Enum.EasingStyle.Back)
		else
			ui.reopen.Position = UDim2.fromOffset(-150, 60)
			tween(ui.reopen, { Position = UDim2.fromOffset(20, 60) }, 0.34, Enum.EasingStyle.Back)
			tween(windowScale, { Scale = scale * 0.9 }, 0.14)

			task.delay(0.14, function()
				if not ui.windowShown then
					window.Visible = false
				end
			end)
		end
	end

	ui.reopen.MouseButton1Click:Connect(function()
		ui.setWindowVisible(true)
	end)

	local grip = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -3, 1, -3),
		Size = UDim2.fromOffset(22, 22),
		Text = "",
		ZIndex = 5,
		Parent = window,
	})

	for _, offset in ipairs({ { 15, 15 }, { 15, 9 }, { 9, 15 }, { 15, 3 }, { 9, 9 }, { 3, 15 } }) do
		create("Frame", {
			BackgroundColor3 = THEME.muted,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(offset[1], offset[2]),
			Size = UDim2.fromOffset(2, 2),
			ZIndex = 5,
			Parent = grip,
		})
	end

	local minimized = false

	---Resize the window within the allowed limits.
	---@param width number
	---@param height number
	function ui.setWindowSize(width, height)
		local maxWidth = math.max(MIN_WINDOW_SIZE.X, viewport.X / scale)
		local maxHeight = math.max(MIN_WINDOW_SIZE.Y, viewport.Y / scale)

		settings.width = math.clamp(math.floor(width), MIN_WINDOW_SIZE.X, maxWidth)
		settings.height = math.clamp(math.floor(height), MIN_WINDOW_SIZE.Y, maxHeight)

		if not minimized then
			window.Size = UDim2.fromOffset(settings.width, settings.height)
		end
	end

	addControl(window, "–", -52, function()
		minimized = not minimized
		grip.Visible = not minimized
		tween(window, { Size = UDim2.fromOffset(settings.width, minimized and 62 or settings.height) }, 0.3)
	end)

	addControl(window, "×", -16, function()
		ui.setWindowVisible(false)
	end)

	local dragStart, windowStart = nil, nil
	local resizeStart, resizeWidth, resizeHeight, resizePosition = nil, nil, nil, nil

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart, windowStart = input.Position, window.Position
		end
	end)

	grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizeStart, resizeWidth, resizeHeight = input.Position, settings.width, settings.height
			resizePosition = window.Position
		end
	end)

	-- Follow the Roblox window when it is resized, and keep this window reachable.
	uiConnections[#uiConnections + 1] = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		viewport = workspace.CurrentCamera.ViewportSize
		scale = math.min(1, viewport.X * 0.92 / settings.width, viewport.Y * 0.92 / settings.height)
		windowScale.Scale = scale
		ui.setWindowSize(settings.width, settings.height)
	end)

	uiConnections[#uiConnections + 1] = userInputService.InputChanged:Connect(function(input)
		if not dragStart and not resizeStart then
			return
		end

		local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch

		if not isMove then
			return
		end

		if dragStart then
			local delta = input.Position - dragStart
			local halfHeight = window.AbsoluteSize.Y / 2
			local x = math.clamp(windowStart.X.Offset + delta.X, -viewport.X / 2, viewport.X / 2)
			local topLimit = math.min(halfHeight - viewport.Y / 2, 0)
			local y = math.clamp(windowStart.Y.Offset + delta.Y, topLimit, math.max(topLimit, viewport.Y / 2))

			window.Position = UDim2.new(0.5, x, 0.5, y)
		elseif resizeStart then
			local delta = input.Position - resizeStart

			ui.setWindowSize(resizeWidth + delta.X / scale, resizeHeight + delta.Y / scale)

			-- The window is centered on its position, so move it to keep the top-left corner still.
			window.Position = resizePosition
				+ UDim2.fromOffset((settings.width - resizeWidth) * scale / 2, (settings.height - resizeHeight) * scale / 2)
		end
	end)

	uiConnections[#uiConnections + 1] = userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart, resizeStart = nil, nil
		end
	end)

	uiConnections[#uiConnections + 1] = userInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if ui.capturingKey then
			ui.capturingKey = false

			-- Escape cancels, so the hide key can't be set to the game menu key.
			if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then
				settings.key = input.KeyCode.Name
			end

			refreshSettings()
		elseif not processed and input.KeyCode.Name == settings.key then
			ui.setWindowVisible(not ui.windowShown)
		end
	end)

	refreshSettings()
	refreshConfigList()
	showPage("Home")

	local autoload = getAutoload()

	if autoload and loadConfig(autoload) then
		logActivity("Loaded config " .. autoload)
	end

	refreshConfigList()
end

---Initialize AutoFarm module.
function AutoFarm.init()
	AutoFarm.running = true
	createInterface()

	spawnLoop("Interface", 1, refreshInterface)

	-- The stock clock drops thread permissions, so it stays on a thread that never touches the interface.
	spawnLoop("Restock", 1, function()
		if ui.homeShown then
			session.restock = MineStock.FormatTime(MineStock.SecondsLeft())
		end
	end)

	-- The server only answers Buff Mode status through this shared event.
	uiConnections[#uiConnections + 1] = replicatedStorage.Remotes.MineFX.OnClientEvent:Connect(function(message)
		if type(message) == "table" and message.t == "buffmode" then
			buffMember = message.member == true
		end
	end)

	spawnLoop("Extras", EXTRAS_INTERVAL, runExtras)
	spawnLoop("Economy", CYCLE_INTERVAL, runCycle)
	spawnLoop("Mining", MINE_INTERVAL, function()
		if AutoFarm.toggles.AutoMine then
			mineRock()
		end
	end)
end

---Detach AutoFarm module.
function AutoFarm.detach()
	AutoFarm.running = false

	for _, connection in ipairs(uiConnections) do
		connection:Disconnect()
	end

	table.clear(uiConnections)
	table.clear(themed)
	table.clear(corners)
	table.clear(glassy)

	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

-- Replace any previous instance.
if shared.MyAnimeMineAutoFarm then
	shared.MyAnimeMineAutoFarm.detach()
end

shared.MyAnimeMineAutoFarm = AutoFarm
AutoFarm.init()

-- Return AutoFarm module.
return AutoFarm
