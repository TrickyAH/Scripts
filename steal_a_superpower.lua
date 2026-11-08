-- AutoFarm module for Steal a Superpower. Single file until the shared Utility helpers exist.
local AutoFarm = {
	running = false,
	toggles = {
		BossFarm = false,
		ZoneFarm = false,
		AutoTrain = false,
		AutoBank = true,
		AutoOpenPacks = false,
		AutoCards = false,
		AutoUpgrades = false,
		AutoPotions = false,
		AutoAuras = false,
		AutoRebirth = false,
		AutoClaim = false,
		DodgeAttacks = true,
		InstaKillBosses = false,
		ServerHop = false,
		FastRespawn = false,
	},
	settings = {
		theme = "Obsidian",
		look = "Soft",
		key = "RightShift",
		width = 976,
		height = 750,
		openPacks = {},
		openCount = 10,
		upgradeIds = {},
		potionTypes = {},
		potionTiers = {},
		spendLimit = 50,
		floatHeight = 8,
		targetDistance = 30,
		respawnEvery = 45,
	},
}

-- Constants.
local BRAIN_INTERVAL = 0.15
local ECONOMY_INTERVAL = 2
local CARDS_INTERVAL = 3
local INTERFACE_INTERVAL = 1
local ANTI_AFK_INTERVAL = 60
local REPLY_WAIT = 0.6
local RETRY_COOLDOWN = 20
local PROMPT_SETTLE = 0.25
local LIFT_RETRY = 6
local LIFT_REACH = 14
local STOP_LIFT_TIMEOUT = 2
local BOSS_SPAWN_WAIT = 8
local BOSS_NO_SHOW_COOLDOWN = 30
local BOSS_GIVE_UP_TIME = 25
local BOSS_MIN_DAMAGE_SHARE = 0.05
local BOSS_TOO_STRONG_COOLDOWN = 300
local PACK_SETTLE_TIME = 2
local BANK_TIMEOUT = 5
local SPAWN_RADIUS = 340
local MIN_TARGET_DISTANCE = 4
local TARGET_RANGE_SHARE = 0.6
local ARENA_MARGIN = 12
local ARENA_FALLBACK_WIDTH = 220
local ARENA_FALLBACK_HEIGHT = 80
local INSTA_KILL_COOLDOWN = 1
local INSTA_KILL_OVERKILL = 2
local INSTA_KILL_CONFIRM_TIME = 3
local INSTA_KILL_DELAY = 0.75
local HOP_MIN_STAY = 20
local CLAIM_RETRY = 120
local RESPAWN_RANGE = { 5, 90 }
local HOP_MIN_WAIT = 25
local HOP_RETRY = 30
local HOP_STATE_MAX_AGE = 180
local HOP_STATE_FILE = "StealASuperpower/hop.json"
local HOP_LOADER = 'if isfile and isfile("SuperpowerFarm.lua") then loadstring(readfile("SuperpowerFarm.lua"))() '
	.. 'else loadstring(game:HttpGet("https://raw.githubusercontent.com/TrickyAH/Scripts/main/steal_a_superpower.lua"))() end'
local SERVER_LIST_URL = "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100"
local DODGE_MARGIN = 6
local DODGE_PASSES = 3
local DODGE_LOG_COOLDOWN = 1
local PLACE_BEST_COOLDOWN = 45
local MAX_OPEN_PER_CALL = 10
local OPEN_DELAY = 0.4
local MAX_ACTIVITY_LINES = 6
local CHART_BARS = 12
local CONFIG_FOLDER = "StealASuperpower"
local POTION_TIERS = { "I", "II", "III" }
local BENCH_UPGRADE = "Training Bench"
local BOSS_UP_COLOR = Color3.fromRGB(107, 211, 138)
local BOSS_WAIT_COLOR = Color3.fromRGB(167, 174, 184)

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local virtualInputManager = game:GetService("VirtualInputManager")
local httpService = game:GetService("HttpService")
local teleportService = game:GetService("TeleportService")

-- Autoexec can run this before the game exists.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

while not playersService.LocalPlayer do
	task.wait()
end

replicatedStorage:WaitForChild("Shared")
replicatedStorage:WaitForChild("Client")

-- UI library. The build step pastes UI/DeepVein.lua in place of this block for the published copy.
-- DeepVein library, bundled by tools/build.py.
local Library = (function()
-- DeepVein window library. Game-independent: draggable tabs and cards, pop-out cards, themes and configs.
local Library = {
	running = false,
	toggles = {},
	settings = {},
	onUnload = nil,
}

-- Classes.
local Window = {}
Window.__index = Window

local Page = {}
Page.__index = Page

local Row = {}
Row.__index = Row

local Card = {}
Card.__index = Card

local ButtonRow = {}
ButtonRow.__index = ButtonRow

-- Constants. Sizes are the design's CSS pixels.
local DEFAULT_SIZE = Vector2.new(976, 750)
local MIN_WINDOW_SIZE = Vector2.new(820, 560)
local HEADER_HEIGHT = 64
local FOOTER_HEIGHT = 28
local RAIL_WIDTH = 200
local BRAND_WIDTH = 184
local TAB_HEIGHT = 40
local TAB_GAP = 4
local PAGE_PADDING = 16
local PAGE_TITLE_HEIGHT = 61
local DOCK_NOTE_HEIGHT = 196
local DRAG_THRESHOLD = 6
local EDGE_SCROLL_ZONE = 56
local EDGE_SCROLL_SPEED = 560
local LAYOUT_SAVE_DELAY = 0.8
local REVEAL_STAGGER = 0.04
local POP_OFFSET = Vector2.new(28, 24)
local DEFAULT_POP_WIDTH = 368
local HAIR_SPACE = utf8.char(0x200A)

-- Roblox draws each font smaller than CSS does at the same number, so design sizes are scaled by these.
local FONT_FACTORS = {
	body = 1.515,
	medium = 1.515,
	bold = 1.515,
	mono = 1.32,
	monoBold = 1.32,
	display = 1.392,
}

-- The icon sheet: Lucide icons, white on transparent, 64 pixels each, 8 per row.
local ICON_URL = "https://raw.githubusercontent.com/TrickyAH/Scripts/main/assets/deepvein-icons.png"
local ICON_PATH = "DeepVein/icons.png"
local ICON_CELL = 64
local ICON_COLUMNS = 8
local ICONS = {
	["arrow-down-to-line"] = 0,
	["arrow-up"] = 1,
	check = 2,
	["chevron-down"] = 3,
	["circle-dot"] = 4,
	circle = 5,
	["external-link"] = 6,
	["file-text"] = 7,
	gem = 8,
	gift = 9,
	["grip-vertical"] = 10,
	hammer = 11,
	house = 12,
	lock = 13,
	minus = 14,
	pickaxe = 15,
	search = 16,
	settings = 17,
	sparkles = 18,
	star = 19,
	x = 20,
}

-- Each theme is named after an ore. Every other color is mixed from these.
local THEME_ORDER = { "Obsidian", "Amethyst", "Emerald", "Ruby", "Sapphire", "Topaz", "Iron", "Quartz" }
local THEME_SOURCES = {
	Obsidian = { window = "101215", rail = "0B0D10", edge = "262B33", stripe = "262B33", accent = "5BD6E0", text = "ECEEF1" },
	Amethyst = { window = "160F1F", rail = "0F0A16", edge = "2A2236", stripe = "33264A", accent = "B48CFF", text = "E6DDF2" },
	Emerald = { window = "0D1813", rail = "08110D", edge = "1E3329", stripe = "234533", accent = "6BD38A", text = "DDF2E6" },
	Ruby = { window = "1C0E11", rail = "13090B", edge = "36202A", stripe = "4A232B", accent = "FF6B7A", text = "F5DDE1" },
	Sapphire = { window = "0D1220", rail = "080C16", edge = "1F2B44", stripe = "233457", accent = "5B9BFF", text = "DDE6F7" },
	Topaz = { window = "1A140A", rail = "110D06", edge = "3A2E18", stripe = "4A3A1C", accent = "F0B649", text = "F5EBD6" },
	Iron = { window = "14161A", rail = "0E1013", edge = "2C3038", stripe = "3A3F48", accent = "C7CDD6", text = "E4E7EC" },
	Quartz = { window = "F3F4F6", rail = "FFFFFF", edge = "D5D8DE", stripe = "D5D8DE", accent = "2A8F99", text = "1B1E23", light = true },
}

-- The exact Obsidian colors from the design.
local OBSIDIAN = {
	header = "0D0F12",
	line = "1E2229",
	divider = "22262D",
	card = "171A1F",
	inset = "13161A",
	field = "15181D",
	deep = "0F1114",
	chip = "22282F",
	track = "2A2F37",
	buttonEdge = "2E343D",
	edgeStrong = "3A4048",
	lift = "1B2027",
	soft = "B4BAC4",
	muted = "8A929D",
	faint = "5A616C",
	dim = "5E6873",
	accentBg = "12262A",
	accentNav = "14272B",
	accentEdge = "1F4A50",
	accentText = "BFF1F4",
	accentDim = "23383C",
	accentMid = "2E5A60",
	accentAvatar = "1E3438",
	accentInk = "062024",
	dock = "0F1A1C",
	ink = "0B0D10",
}

-- Looks change the corner size and transparency of the window.
local LOOK_ORDER = { "Soft", "Sharp", "Glass" }
local LOOKS = {
	Soft = { radius = 1, glass = 0 },
	Sharp = { radius = 0.35, glass = 0 },
	Glass = { radius = 1.15, glass = 0.14 },
}

-- Properties that accept a theme token.
local COLOR_PROPERTIES = {
	BackgroundColor3 = true,
	Color = true,
	ImageColor3 = true,
	PlaceholderColor3 = true,
	ScrollBarImageColor3 = true,
	TextColor3 = true,
}

-- Services.
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
local playersService = game:GetService("Players")
local coreGui = game:GetService("CoreGui")

---Build a font from a built-in family, falling back to Gotham.
---@param enumFont Enum.Font
---@param weight Enum.FontWeight
---@return Font
local function getFont(enumFont, weight)
	local success, font = pcall(function()
		return Font.new(Font.fromEnum(enumFont).Family, weight)
	end)

	return success and font or Font.fromEnum(Enum.Font.Gotham)
end

local FONTS = {
	body = getFont(Enum.Font.TitilliumWeb, Enum.FontWeight.Regular),
	medium = getFont(Enum.Font.TitilliumWeb, Enum.FontWeight.SemiBold),
	bold = getFont(Enum.Font.TitilliumWeb, Enum.FontWeight.Bold),
	mono = getFont(Enum.Font.RobotoMono, Enum.FontWeight.Medium),
	monoBold = getFont(Enum.Font.RobotoMono, Enum.FontWeight.SemiBold),
	display = getFont(Enum.Font.Sarpanch, Enum.FontWeight.Bold),
}

---Build a full theme from its source colors.
---@param source table
---@param exact table? exact colors that replace the mixed ones
---@return table
local function makeTheme(source, exact)
	local white, black = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
	local window, rail, edge = Color3.fromHex(source.window), Color3.fromHex(source.rail), Color3.fromHex(source.edge)
	local accent, text = Color3.fromHex(source.accent), Color3.fromHex(source.text)
	local theme = { window = window, rail = rail, edge = edge, accent = accent, text = text, shadow = black }

	if source.light then
		theme.header = white
		theme.line = Color3.fromHex("E3E6EA")
		theme.divider = Color3.fromHex("E6E8EC")
		theme.card = white
		theme.inset = Color3.fromHex("F7F8F9")
		theme.field = white
		theme.deep = Color3.fromHex("EEF0F3")
		theme.chip = white
		theme.track = edge
		theme.buttonEdge = Color3.fromHex("CDD1D8")
		theme.edgeStrong = Color3.fromHex("B8BEC7")
		theme.lift = white
		theme.soft = Color3.fromHex("4A515B")
		theme.muted = Color3.fromHex("6B737E")
		theme.faint = Color3.fromHex("A2A9B3")
		theme.dim = Color3.fromHex("9AA1AB")
		theme.accentBg = white:Lerp(accent, 0.1)
		theme.accentNav = white:Lerp(accent, 0.12)
		theme.accentEdge = white:Lerp(accent, 0.35)
		theme.accentText = accent:Lerp(black, 0.35)
		theme.accentDim = white:Lerp(accent, 0.2)
		theme.accentMid = white:Lerp(accent, 0.45)
		theme.accentAvatar = white:Lerp(accent, 0.15)
		theme.accentInk = white
		theme.dock = white:Lerp(accent, 0.05)
		theme.ink = white
		theme.gold = Color3.fromHex("B07A10")
		theme.good = Color3.fromHex("2E9E5B")
		theme.red = Color3.fromHex("D8404F")
		theme.dangerBg = Color3.fromHex("FDECEE")
		theme.dangerCard = Color3.fromHex("FFF5F6")
		theme.dangerEdge = Color3.fromHex("F0BEC4")
		theme.dangerText = Color3.fromHex("B02838")
		theme.dangerTitle = Color3.fromHex("8A1E2B")
		theme.dangerSub = Color3.fromHex("B0606A")
	else
		theme.header = rail:Lerp(window, 0.4)
		theme.line = window:Lerp(edge, 0.64)
		theme.divider = window:Lerp(edge, 0.82)
		theme.card = window:Lerp(edge, 0.32)
		theme.inset = window:Lerp(edge, 0.14)
		theme.field = window:Lerp(edge, 0.23)
		theme.deep = rail:Lerp(window, 0.8)
		theme.chip = window:Lerp(edge, 0.8):Lerp(text, 0.02)
		theme.track = edge:Lerp(text, 0.02)
		theme.buttonEdge = edge:Lerp(text, 0.045)
		theme.edgeStrong = edge:Lerp(text, 0.1)
		theme.lift = window:Lerp(edge, 0.32):Lerp(edge, 0.35)
		theme.soft = text:Lerp(window, 0.25)
		theme.muted = text:Lerp(window, 0.45)
		theme.faint = text:Lerp(window, 0.66)
		theme.dim = text:Lerp(window, 0.62)
		theme.accentBg = window:Lerp(accent, 0.1)
		theme.accentNav = window:Lerp(accent, 0.115)
		theme.accentEdge = window:Lerp(accent, 0.27)
		theme.accentText = accent:Lerp(white, 0.6)
		theme.accentDim = window:Lerp(accent, 0.17)
		theme.accentMid = window:Lerp(accent, 0.37)
		theme.accentAvatar = window:Lerp(accent, 0.15)
		theme.accentInk = accent:Lerp(black, 0.86)
		theme.dock = window:Lerp(accent, 0.05)
		theme.ink = rail
		theme.gold = Color3.fromHex("F0B649")
		theme.good = Color3.fromHex("8FE3A6")
		theme.red = Color3.fromHex("FF6B7A")
		theme.dangerBg = Color3.fromHex("1E1416")
		theme.dangerCard = Color3.fromHex("1A1214")
		theme.dangerEdge = Color3.fromHex("4A2A2E")
		theme.dangerText = Color3.fromHex("FFB3BA")
		theme.dangerTitle = Color3.fromHex("FFD6DA")
		theme.dangerSub = Color3.fromHex("C99BA0")
	end

	theme.dangerSolid = Color3.fromHex("E2525F")
	theme.dangerInk = Color3.fromHex("1A0B0D")

	for token, value in pairs(exact or {}) do
		theme[token] = Color3.fromHex(value)
	end

	return theme
end

local THEMES = {}

for name, source in pairs(THEME_SOURCES) do
	THEMES[name] = makeTheme(source, name == "Obsidian" and OBSIDIAN or nil)
end

-- Color tokens. The active theme turns these into real colors.
local THEME = {}

for token in pairs(THEMES.Obsidian) do
	THEME[token] = token
end

-- Interface root.
local screenGui = nil

-- Built instances and window state.
local ui = {}

-- Connections cut on unload.
local connections = {}

-- Everything the appearance settings need to update.
local themed = setmetatable({}, { __mode = "k" })
local corners = setmetatable({}, { __mode = "k" })
local glassy = setmetatable({}, { __mode = "k" })

-- Functions that redraw a control from its value.
local paints = {}

-- Redraw functions for every row bound to a toggle key.
local keyPaints = {}

-- Functions called when a toggle changes.
local toggleWatchers = {}

-- Validation rules for saved settings, by key.
local rules = {}

-- The page each toggle key lives on.
local toggleKeys = {}

-- Rows the search box can filter.
local searchRows = {}

-- Pages by name, and in the order they were added.
local pages = {}
local pageList = {}

-- Rail sections by name, in order.
local sections = {}
local sectionList = {}

-- Cards by id.
local cards = {}

-- The card that owns each slot frame.
local slotCards = setmetatable({}, { __mode = "k" })

-- The press waiting to become a drag, and the drag in progress.
local pointer = { pending = nil, drag = nil, position = Vector2.zero }

-- File paths for configs and the saved layout.
local paths = {
	folder = "DeepVein",
	configs = "DeepVein/configs",
	autoload = "DeepVein/autoload.txt",
	layout = "DeepVein/layout.json",
}

-- The open page.
local currentPage = nil

-- The layout before any saved one was applied.
local defaultLayout = nil

-- Defined further down.
local showPage, saveLayoutSoon, captureLayout, applyLayout, popOut, dock, updateBadges, refreshSettings
local refreshConfigList, refreshFooter

---Connect a signal and cut it on unload.
---@param signal RBXScriptSignal
---@param callback function
---@return RBXScriptConnection
local function connect(signal, callback)
	local connection = signal:Connect(callback)

	connections[#connections + 1] = connection

	return connection
end

---Get the active theme.
---@return table
local function getPalette()
	return THEMES[Library.settings.theme] or THEMES.Obsidian
end

---Get the active look.
---@return table
local function getLook()
	return LOOKS[Library.settings.look] or LOOKS.Soft
end

---Get a theme color as hex, for rich text.
---@param token string
---@return string
local function hexOf(token)
	return "#" .. getPalette()[token]:ToHex()
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

---Set a fixed color that no theme changes.
---@param instance Instance
---@param property string
---@param color Color3
local function setRawColor(instance, property, color)
	if themed[instance] then
		themed[instance][property] = nil
	end

	instance[property] = color
end

---Play a tween and return it.
---@param instance Instance
---@param properties table
---@param duration number?
---@param easing Enum.EasingStyle?
---@param delay number?
---@return Tween
local function tween(instance, properties, duration, easing, delay)
	local info = TweenInfo.new(
		duration or 0.18,
		easing or Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out,
		0,
		false,
		delay or 0
	)
	local created = tweenService:Create(instance, info, properties)

	created:Play()

	return created
end

---Fade a property to a theme token.
---@param instance Instance
---@param property string
---@param token string
---@param duration number?
---@return Tween
local function fadeColor(instance, property, token, duration)
	themed[instance] = themed[instance] or {}
	themed[instance][property] = token

	return tween(instance, { [property] = getPalette()[token] }, duration or 0.18)
end

---Apply the active theme and look to everything.
local function applyAppearance()
	local palette = getPalette()
	local look = getLook()

	-- Set directly: a tween per object dropped the game to 29 FPS on every theme change.
	for instance, properties in pairs(themed) do
		for property, token in pairs(properties) do
			instance[property] = palette[token]
		end
	end

	for corner, radius in pairs(corners) do
		corner.CornerRadius = UDim.new(0, math.floor(radius * look.radius + 0.5))
	end

	for element, transparency in pairs(glassy) do
		element.BackgroundTransparency = math.min(transparency + look.glass, 1)
	end
end

---Create an instance. String colors are theme tokens.
---@param className string
---@param properties table
---@return Instance
local function create(className, properties)
	local instance = Instance.new(className)

	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
	end

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

---Round an element and optionally give it an edge.
---@param element GuiObject
---@param radius number
---@param edge string?
---@param thickness number?
---@return UIStroke?
local function style(element, radius, edge, thickness)
	local corner = create("UICorner", {
		CornerRadius = UDim.new(0, math.floor(radius * getLook().radius + 0.5)),
		Parent = element,
	})

	corners[corner] = radius

	if edge then
		return create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = edge,
			Thickness = thickness or 1,
			Parent = element,
		})
	end

	return nil
end

---Make an element fully round.
---@param element GuiObject
local function pill(element)
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = element })
end

---Add padding to an element.
---@param element GuiObject
---@param top number
---@param right number?
---@param bottom number?
---@param left number?
---@return UIPadding
local function pad(element, top, right, bottom, left)
	right = right or top
	bottom = bottom or top
	left = left or right

	return create("UIPadding", {
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right),
		PaddingTop = UDim.new(0, top),
		Parent = element,
	})
end

---Add a list layout to an element.
---@param element GuiObject
---@param gap number
---@param horizontal boolean?
---@return UIListLayout
local function list(element, gap, horizontal)
	return create("UIListLayout", {
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
		Parent = element,
	})
end

---Turn a design size into a Roblox text size.
---@param kind string
---@param size number
---@return number
local function textSize(kind, size)
	return math.floor(size * FONT_FACTORS[kind] + 0.5)
end

---Spell text in capitals with a hair space between letters, like the design's letter spacing.
---@param value string
---@return string
local function caps(value)
	local characters = {}

	for _, code in utf8.codes(string.upper(value)) do
		characters[#characters + 1] = utf8.char(code)
	end

	return table.concat(characters, HAIR_SPACE)
end

---Create a text label from a design size.
---@param parent Instance
---@param value string
---@param size number design font size
---@param kind string? body, medium, bold, mono, monoBold or display
---@param color string? a theme token
---@param properties table?
---@return TextLabel
local function text(parent, value, size, kind, color, properties)
	kind = kind or "body"

	local robloxSize = textSize(kind, size)
	local instance = create("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = FONTS[kind],
		Size = UDim2.new(1, 0, 0, robloxSize),
		Text = value,
		TextColor3 = color or THEME.text,
		TextSize = robloxSize,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})

	for property, propertyValue in pairs(properties or {}) do
		if COLOR_PROPERTIES[property] and type(propertyValue) == "string" then
			setColor(instance, property, propertyValue)
		else
			instance[property] = propertyValue
		end
	end

	return instance
end

---Load the icon sheet once.
---@return string?
local function loadIcons()
	local success, asset = pcall(function()
		if not isfolder("DeepVein") then
			makefolder("DeepVein")
		end

		if not isfile(ICON_PATH) then
			local data = game:HttpGet(ICON_URL)

			if string.sub(data, 2, 4) ~= "PNG" then
				return nil
			end

			writefile(ICON_PATH, data)
		end

		return getcustomasset(ICON_PATH)
	end)

	return success and asset or nil
end

---Point an icon image at a different icon.
---@param image ImageLabel
---@param name string
local function setIcon(image, name)
	local index = ICONS[name] or 0

	image.ImageRectOffset = Vector2.new(index % ICON_COLUMNS * ICON_CELL, index // ICON_COLUMNS * ICON_CELL)
end

---Create an icon.
---@param parent Instance
---@param name string
---@param size number
---@param color string? a theme token
---@param properties table?
---@return ImageLabel
local function icon(parent, name, size, color, properties)
	local image = create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = ui.iconAsset or "",
		ImageColor3 = color or THEME.soft,
		ImageRectSize = Vector2.new(ICON_CELL, ICON_CELL),
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})

	setIcon(image, name)

	for property, value in pairs(properties or {}) do
		if COLOR_PROPERTIES[property] and type(value) == "string" then
			setColor(image, property, value)
		else
			image[property] = value
		end
	end

	return image
end

---Draw six grip dots, 10 by 16.
---@param parent Instance
---@param properties table?
---@return Frame
local function drawGrip(parent, properties)
	local grip = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(10, 16),
		Parent = parent,
	})

	for _, offset in ipairs({ { 2, 3 }, { 6, 3 }, { 2, 7 }, { 6, 7 }, { 2, 11 }, { 6, 11 } }) do
		local dot = create("Frame", {
			BackgroundColor3 = THEME.faint,
			Position = UDim2.fromOffset(offset[1] - 0.3, offset[2] - 0.3),
			Size = UDim2.fromOffset(2.6, 2.6),
			Parent = grip,
		})

		pill(dot)
	end

	for property, value in pairs(properties or {}) do
		grip[property] = value
	end

	return grip
end

---Fade grip dots in or out.
---@param grip Frame
---@param shown boolean
local function setGripShown(grip, shown)
	for _, dot in ipairs(grip:GetChildren()) do
		if dot:IsA("Frame") then
			tween(dot, { BackgroundTransparency = shown and 0 or 1 }, 0.16)
		end
	end
end

---Fade a background between two tokens while the pointer is over it.
---@param button GuiObject
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

---Shrink a button while pressed and spring it back.
---@param button GuiButton
---@param amount number?
local function addPress(button, amount)
	local scale = create("UIScale", { Parent = button })
	local pressed = false

	button.MouseButton1Down:Connect(function()
		pressed = true
		tween(scale, { Scale = amount or 0.96 }, 0.08)
	end)

	-- Only spring back after a real press, so moving the mouse around creates no tweens.
	for _, signal in ipairs({ button.MouseButton1Up, button.MouseLeave }) do
		signal:Connect(function()
			if pressed then
				pressed = false
				tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
			end
		end)
	end
end

---Set label text only when it changed.
---@param target TextLabel
---@param value string
local function setText(target, value)
	if target.Text ~= value then
		target.Text = value
	end
end

-- Last value shown by each bar.
local barValues = setmetatable({}, { __mode = "k" })

---Glide a progress bar only when its value changed.
---@param fill Frame
---@param alpha number
local function setBar(fill, alpha)
	alpha = math.clamp(alpha, 0, 1)

	if math.abs(alpha - (barValues[fill] or -1)) > 0.001 then
		barValues[fill] = alpha
		tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.5)
	end
end

---Check for a click or touch.
---@param input InputObject
---@return boolean
local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

---Check for pointer movement.
---@param input InputObject
---@return boolean
local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

---Get an input's position as a Vector2.
---@param input InputObject
---@return Vector2
local function inputPosition(input)
	return Vector2.new(input.Position.X, input.Position.Y)
end

---Check whether a point is inside a GUI object.
---@param object GuiObject
---@param position Vector2
---@return boolean
local function isInside(object, position)
	local topLeft = object.AbsolutePosition
	local bottomRight = topLeft + object.AbsoluteSize

	return position.X >= topLeft.X and position.Y >= topLeft.Y and position.X <= bottomRight.X and position.Y <= bottomRight.Y
end

---Wait for a press to move far enough, then start a drag. A press that never moves is a click.
---@param input InputObject
---@param handlers table begin(position, start) returns a drag, click() runs on a plain click
local function trackPress(input, handlers)
	if pointer.drag or pointer.pending or ui.busy then
		return
	end

	pointer.pending = { start = inputPosition(input), handlers = handlers }
end

---Run a callback without letting its error break the window.
---@param labelText string
---@param callback function?
---@vararg any
local function safeCall(labelText, callback, ...)
	if not callback then
		return
	end

	local success, message = pcall(callback, ...)

	if not success then
		warn(string.format("[DeepVein] %s: %s", labelText, tostring(message)))
	end
end

---Ease a value from 0 to 1, fast then slow.
---@param alpha number
---@return number
local function easeOut(alpha)
	return 1 - (1 - alpha) ^ 4
end

---Check that the executor can save files.
---@return boolean
local function canSave()
	return writefile ~= nil and readfile ~= nil and isfile ~= nil and isfolder ~= nil and makefolder ~= nil
end

---Create the save folders.
local function ensureFolders()
	if not isfolder(paths.folder) then
		makefolder(paths.folder)
	end

	if not isfolder(paths.configs) then
		makefolder(paths.configs)
	end
end

---Read and decode a JSON file.
---@param path string
---@return table?
local function readJson(path)
	if not canSave() or not isfile(path) then
		return nil
	end

	local success, value = pcall(function()
		return httpService:JSONDecode(readfile(path))
	end)

	return success and type(value) == "table" and value or nil
end

-- Bumped on every layout change, so only the last one writes.
local layoutSaveToken = 0

---Save the layout shortly after the last change.
function saveLayoutSoon()
	if not canSave() or not defaultLayout then
		return
	end

	layoutSaveToken += 1

	local token = layoutSaveToken

	refreshFooter()

	task.delay(LAYOUT_SAVE_DELAY, function()
		if token ~= layoutSaveToken or not Library.running then
			return
		end

		pcall(function()
			ensureFolders()
			writefile(paths.layout, httpService:JSONEncode(captureLayout()))
		end)
	end)
end

---List the slot frames in a container, in order.
---@param container Instance
---@param except Instance?
---@return Frame[]
local function listSlots(container, except)
	local slots = {}

	for _, child in ipairs(container:GetChildren()) do
		if child ~= except and child:GetAttribute("DeepVeinSlot") then
			slots[#slots + 1] = child
		end
	end

	table.sort(slots, function(left, right)
		return left.LayoutOrder < right.LayoutOrder
	end)

	return slots
end

---Number slots 2, 4, 6..., leaving odd numbers free for markers.
---@param container Instance
---@param except Instance?
local function renumber(container, except)
	for index, slot in ipairs(listSlots(container, except)) do
		slot.LayoutOrder = index * 2
	end
end

---Find where a pointer height would insert into a container.
---@param container Instance
---@param except Instance?
---@param y number
---@return number
local function insertIndex(container, except, y)
	local slots = listSlots(container, except)

	for index, slot in ipairs(slots) do
		if y < slot.AbsolutePosition.Y + slot.AbsoluteSize.Y / 2 then
			return index
		end
	end

	return #slots + 1
end

---Create the outline left where a dragged item started.
---@param container Instance
---@param insertAt number
---@param session table
---@return Frame
local function makeGhost(container, insertAt, session)
	local outer = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = insertAt * 2 - 1,
		Size = UDim2.new(1, 0, 0, session.height),
		Parent = container,
	})

	local inner = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, session.height - session.gap),
		Parent = outer,
	})

	local stroke = style(inner, session.radius, THEME.edgeStrong)

	stroke.Transparency = 0.35

	if session.ghostText then
		text(inner, session.ghostText, 12, "body", THEME.dim, {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end

	return outer
end

---Create the glowing line that shows where a dragged item will land.
---@param container Instance
---@param insertAt number
---@param session table
---@return Frame
local function makeMarker(container, insertAt, session)
	local outer = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = insertAt * 2 - 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = container,
	})

	local line = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = THEME.accent,
		Position = UDim2.new(0.5, 0, 0, session.markerTop),
		Size = UDim2.new(1, -session.markerInset * 2, 0, 3),
		Parent = outer,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = line })

	local glow = create("UIStroke", { Color = THEME.accent, Thickness = 3, Transparency = 0.7, Parent = line })

	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	return outer
end

---Move the landing line. Siblings slide apart where it opens and close where it left.
---@param session table
---@param container Instance
---@param insertAt number
local function moveMarker(session, container, insertAt)
	if session.container == container and session.insertAt == insertAt then
		return
	end

	local leaving = session.marker

	if leaving then
		tween(leaving, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)

		task.delay(0.19, function()
			leaving:Destroy()
		end)
	end

	session.container, session.insertAt, session.marker = container, insertAt, nil

	-- Dropping right where the item started needs no line.
	if container == session.ghostContainer and insertAt == session.ghostIndex then
		return
	end

	renumber(container, session.slot)
	session.marker = makeMarker(container, insertAt, session)
	tween(session.marker, { Size = UDim2.new(1, 0, 0, session.markerHeight) }, 0.18)
end

---Glide a dragged item into its landing place, then call done with the frame that held the place.
---@param session table
---@param toPosition function turns a screen position into the item's Position
---@param done function
local function settle(session, toPosition, done)
	local landing = session.marker or session.ghost

	ui.busy = true

	-- The line opens to full size while the start outline closes, so everything slides into place.
	if session.marker then
		for _, child in ipairs(landing:GetChildren()) do
			child:Destroy()
		end

		tween(landing, { Size = UDim2.new(1, 0, 0, session.height) }, 0.26)
		tween(session.ghost, { Size = UDim2.new(1, 0, 0, 0) }, 0.26)
	end

	local start = session.slot.Position
	local startedAt = os.clock()
	local gliding

	gliding = connect(runService.RenderStepped, function()
		local alpha = math.clamp((os.clock() - startedAt) / 0.3, 0, 1)
		local target = toPosition(landing.AbsolutePosition)

		session.slot.Position = start:Lerp(target, easeOut(alpha))

		if alpha >= 1 then
			gliding:Disconnect()

			if Library.running then
				done(landing)

				if session.marker then
					session.ghost:Destroy()
				end

				landing:Destroy()
			end

			ui.busy = false
		end
	end)
end

---Check whether a card can be seen right now.
---@param card table
---@return boolean
local function isCardVisible(card)
	if card.pop then
		return ui.popLayer.Visible and not card.pop.collapsed
	end

	return ui.windowShown and not ui.minimized and currentPage == card.page
end

---Paint a tab as selected or not.
---@param page table
local function paintTab(page)
	local selected = page == currentPage
	local tab = page.tab

	fadeColor(tab.button, "BackgroundColor3", selected and THEME.accentNav or THEME.inset)
	tween(tab.button, { BackgroundTransparency = selected and 0 or 1 }, 0.18)
	tween(tab.stroke, { Transparency = selected and 0 or 1 }, 0.18)
	fadeColor(tab.name, "TextColor3", selected and THEME.accentText or THEME.soft)
	fadeColor(tab.icon, "ImageColor3", selected and THEME.accent or THEME.soft)
	tab.name.FontFace = selected and FONTS.medium or FONTS.body
end

---Count toggles that are on, per page, for the tab badges and page subtitles.
function updateBadges()
	for _, page in ipairs(pageList) do
		local total, on = #page.toggleKeys, 0

		for _, key in ipairs(page.toggleKeys) do
			on += Library.toggles[key] and 1 or 0
		end

		setText(page.tab.badge, on > 0 and string.format("%d on", on) or "")

		if page.subtitle and total > 0 then
			local prefix = page.description ~= "" and page.description .. " " or ""

			setText(page.subtitle, string.format("%s%d of %d running.", prefix, on, total))
		end
	end

	for _, card in pairs(cards) do
		if card.pop and card.pop.badge then
			local on = 0

			for _, key in ipairs(card.toggleKeys) do
				on += Library.toggles[key] and 1 or 0
			end

			setText(card.pop.badge, on > 0 and string.format("%d on", on) or "")
		end
	end
end

---Show the hide key, config and theme in the footer.
function refreshFooter()
	if not ui.footerKey then
		return
	end

	local settings = Library.settings
	local key = settings.key == "RightShift" and "RShift" or settings.key == "LeftShift" and "LShift" or settings.key

	setText(ui.footerKey, key)

	local config = ui.activeConfig
	local autoload = ui.autoloadName

	ui.footerConfig.Text = config
			and string.format(
				'Config: <font color="%s">%s</font>%s',
				hexOf(THEME.soft),
				config,
				config == autoload and " (autoload)" or ""
			)
		or "Config: none"

	local floating = 0

	for _, card in pairs(cards) do
		floating += card.pop and 1 or 0
	end

	setText(
		ui.footerRight,
		floating > 0 and string.format("%d card%s popped out", floating, floating == 1 and "" or "s")
			or "Theme: " .. settings.theme
	)
end

---Get the height a card needs for its own content, ignoring any stretch.
---@param card table
---@return number
local function naturalHeight(card)
	local scale = ui.scale
	local height = card.paddingValues[1] * 2 + card.body.AbsoluteSize.Y / scale

	if card.header.Visible then
		height += card.header.AbsoluteSize.Y / scale + card.gap
	end

	if card.note then
		height = card.note.AbsoluteSize.Y / scale
	end

	return math.max(height, card.pop and 0 or card.minHeight or 0)
end

---Get the smallest size a card's constraint may take: its own minimum height, minus padding.
---@param card table
---@return Vector2
local function baseMinimum(card)
	return Vector2.new(0, card.minHeight and card.minHeight - card.paddingValues[1] * 2 or 0)
end

---Stretch the last card in each column of the page's bottom row down to the page's bottom edge, like the design.
---@param page table
local function stretchPage(page)
	local lastRow = page.rows[#page.rows]

	if not page.stretch or not lastRow or not page.frame.Visible or ui.busy then
		return
	end

	local scale = ui.scale
	local above = 0

	for index = 1, #page.rows - 1 do
		above += page.rows[index].frame.AbsoluteSize.Y / scale
	end

	local available = page.scroller.AbsoluteWindowSize.Y / scale - page.bottomPadding - above

	for _, column in ipairs(lastRow.columns) do
		local slots = listSlots(column)
		local used = 0

		for index, slot in ipairs(slots) do
			local card = slotCards[slot]

			if index < #slots then
				card.stretch.MinSize = baseMinimum(card)
				used += naturalHeight(card) + page.gap
			elseif not card.pop then
				local fill = math.max(naturalHeight(card), available - used)

				card.stretch.MinSize = Vector2.new(0, math.max(fill - card.paddingValues[1] * 2, 0))
			end
		end
	end
end

-- Pages waiting for a stretch on the next frame.
local stretchQueue = {}

---Stretch a page's columns once the layout has settled.
---@param page table
local function stretchSoon(page)
	if not page or not page.stretch or stretchQueue[page] then
		return
	end

	stretchQueue[page] = true

	task.defer(function()
		task.wait()
		stretchQueue[page] = nil

		if Library.running then
			stretchPage(page)
		end
	end)
end

---Fade a page's cards in one after another.
---@param page table
local function reveal(page)
	local scale = ui.scale
	local targets = {}

	stretchPage(page)
	page.scroller.CanvasPosition = Vector2.zero
	page.scroller.Position = UDim2.new(0, 0, 0, page.contentTop + 10)
	tween(page.scroller, { Position = UDim2.new(0, 0, 0, page.contentTop) }, 0.34)

	if page.title then
		page.title.TextTransparency = 1
		page.subtitle.TextTransparency = 1
		tween(page.title, { TextTransparency = 0 }, 0.3)
		tween(page.subtitle, { TextTransparency = 0 }, 0.3, nil, 0.05)
	end

	for _, card in ipairs(page.cards) do
		if card.slot.Parent and card.slot.Parent ~= ui.dragLayer then
			targets[#targets + 1] = card
		end
	end

	table.sort(targets, function(left, right)
		local leftY, rightY = left.slot.AbsolutePosition.Y, right.slot.AbsolutePosition.Y

		if math.abs(leftY - rightY) > 4 then
			return leftY < rightY
		end

		return left.slot.AbsolutePosition.X < right.slot.AbsolutePosition.X
	end)

	for index, card in ipairs(targets) do
		local size = card.frame.AbsoluteSize / scale

		if size.X < 1 or size.Y < 1 then
			continue
		end

		-- A veil in the window color fades away, so the card seems to fade in.
		local veil = create("Frame", {
			BackgroundColor3 = THEME.window,
			Size = UDim2.fromOffset(size.X, size.Y),
			ZIndex = 5,
			Parent = card.slot,
		})

		style(veil, 12)
		tween(veil, { BackgroundTransparency = 1 }, 0.34, Enum.EasingStyle.Quad, (index - 1) * REVEAL_STAGGER)

		task.delay((index - 1) * REVEAL_STAGGER + 0.36, function()
			veil:Destroy()
		end)
	end
end

---Show one page.
---@param name string
function showPage(name)
	local page = pages[name]

	if not page or page == currentPage then
		return
	end

	currentPage = page

	for _, other in ipairs(pageList) do
		other.frame.Visible = other == page
		paintTab(other)
	end

	reveal(page)
end

---Create a small square icon button.
---@param parent Instance
---@param iconName string
---@param properties table?
---@return TextButton, ImageLabel
local function iconButton(parent, iconName, properties)
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = THEME.chip,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 28),
		Text = "",
		Parent = parent,
	})

	style(button, 7)
	addPress(button, 0.9)

	local image = icon(button, iconName, 14, THEME.muted, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	button.MouseEnter:Connect(function()
		tween(button, { BackgroundTransparency = 0.2 }, 0.15)
		fadeColor(image, "ImageColor3", button:GetAttribute("HoverToken") or THEME.text, 0.15)
	end)

	button.MouseLeave:Connect(function()
		tween(button, { BackgroundTransparency = button:GetAttribute("RestTransparency") or 1 }, 0.15)
		fadeColor(image, "ImageColor3", button:GetAttribute("RestToken") or THEME.muted, 0.15)
	end)

	for property, value in pairs(properties or {}) do
		button[property] = value
	end

	return button, image
end

---Build a button in one of the design's styles.
---@param parent Instance
---@param label string
---@param kind string? "ghost" (default), "text", "primary", "danger", "dangerSolid" or "dangerSoft"
---@param callback function
---@param height number?
---@return TextButton
local function makeButton(parent, label, kind, callback, height)
	kind = kind or "ghost"

	local styles = {
		ghost = { bg = THEME.card, bgAlpha = 1, edge = THEME.buttonEdge, text = THEME.soft, font = "body" },
		text = { bg = THEME.card, bgAlpha = 1, edge = THEME.buttonEdge, text = THEME.text, font = "body" },
		primary = { bg = THEME.accent, bgAlpha = 0, text = THEME.accentInk, font = "bold" },
		danger = { bg = THEME.card, bgAlpha = 1, edge = THEME.dangerEdge, text = THEME.dangerText, font = "body" },
		dangerSolid = { bg = THEME.dangerSolid, bgAlpha = 0, text = THEME.dangerInk, font = "bold" },
		dangerSoft = { bg = THEME.dangerBg, bgAlpha = 0, edge = THEME.dangerEdge, text = THEME.dangerText, font = "medium" },
	}
	local look = styles[kind] or styles.ghost
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = look.bg,
		BackgroundTransparency = look.bgAlpha,
		FontFace = FONTS[look.font],
		Size = UDim2.new(1, 0, 0, height or 34),
		Text = label,
		TextColor3 = look.text,
		TextSize = textSize(look.font, 13),
		Parent = parent,
	})

	style(button, 9, look.edge)
	addPress(button)

	button.MouseEnter:Connect(function()
		if look.bgAlpha == 1 then
			fadeColor(button, "BackgroundColor3", THEME.chip)
			tween(button, { BackgroundTransparency = 0.4 }, 0.15)
		else
			tween(button, { BackgroundTransparency = 0.12 }, 0.15)
		end
	end)

	button.MouseLeave:Connect(function()
		tween(button, { BackgroundTransparency = look.bgAlpha }, 0.15)
	end)

	button.MouseButton1Click:Connect(function()
		safeCall(label, callback)
	end)

	return button
end

---Build the panel that takes a card's place while it floats.
---@param card table
---@param height number
---@return Frame
local function buildDockNote(card, height)
	local note = create("Frame", {
		BackgroundColor3 = THEME.dock,
		ClipsDescendants = true,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, height),
		Parent = card.frame,
	})

	card.noteStroke = style(note, 12, THEME.accentEdge)

	local holder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -40, 0, 0),
		Parent = note,
	})

	local layout = list(holder, 12)

	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	icon(holder, "external-link", 32, THEME.accent, { LayoutOrder = 1 })
	card.noteTitle = text(holder, card.title .. " is popped out", 15, "medium", THEME.accentText, {
		LayoutOrder = 2,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	text(holder, "It's floating over the game. Its settings still save with your config.", 12, "body", THEME.muted, {
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Size = UDim2.new(0, 240, 0, 0),
		TextTruncate = Enum.TextTruncate.None,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local button = makeButton(holder, "Dock it back here", "ghost", function()
		dock(card)
	end)

	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 34)
	button.LayoutOrder = 4
	button.FontFace = FONTS.medium
	setColor(button, "BackgroundColor3", THEME.accentBg)
	button.BackgroundTransparency = 0
	setColor(button, "TextColor3", THEME.accentText)
	setColor(button:FindFirstChildOfClass("UIStroke"), "Color", THEME.accentEdge)
	pad(button, 0, 16)

	return note
end

---Show the dock target while a floating card hovers over the window.
---@param card table
---@param hovering boolean
local function setDockHover(card, hovering)
	if card.dockHover == hovering or not card.note then
		return
	end

	card.dockHover = hovering
	fadeColor(card.noteStroke, "Color", hovering and THEME.accent or THEME.accentEdge)
	fadeColor(card.note, "BackgroundColor3", hovering and THEME.accentBg or THEME.dock)
	card.noteTitle.Text = hovering and "Release to dock it here" or card.title .. " is popped out"
	fadeColor(card.pop.stroke, "Color", hovering and THEME.accent or THEME.edge)
end

---Fold a floating card down to its header, or open it again.
---@param card table
---@param collapsed boolean
---@param instant boolean?
local function setCollapsed(card, collapsed, instant)
	local pop = card.pop

	if not pop or pop.collapsed == collapsed then
		return
	end

	pop.collapsed = collapsed
	pop.token += 1

	local token = pop.token
	local content = pop.content
	local full = pop.wrap.AbsoluteSize.Y / ui.scale
	local duration = instant and 0 or 0.28

	setIcon(pop.collapseIcon, collapsed and "chevron-down" or "minus")
	pop.line.Visible = not collapsed
	pop.filler.Visible = not collapsed
	pop.dot.Visible = collapsed
	pop.badge.Visible = collapsed
	content.AutomaticSize = Enum.AutomaticSize.None

	if collapsed then
		content.Size = UDim2.new(1, 0, 0, full)
		tween(content, { Size = UDim2.new(1, 0, 0, 0) }, duration)
		tween(pop.frame, { Size = UDim2.fromOffset(260, 0) }, duration)
	else
		content.Size = UDim2.new(1, 0, 0, 0)
		tween(content, { Size = UDim2.new(1, 0, 0, full) }, duration)
		tween(pop.frame, { Size = UDim2.fromOffset(pop.width, 0) }, duration)

		task.delay(duration + 0.02, function()
			if pop.token == token and not pop.collapsed then
				content.AutomaticSize = Enum.AutomaticSize.Y
				content.Size = UDim2.new(1, 0, 0, 0)
			end
		end)
	end

	updateBadges()
	saveLayoutSoon()
end

---Keep a floating window on screen.
---@param position Vector2
---@param size Vector2
---@return Vector2
local function clampToScreen(position, size)
	local viewport = ui.viewport

	return Vector2.new(
		math.clamp(position.X, 0, math.max(viewport.X - size.X, 0)),
		math.clamp(position.Y, 0, math.max(viewport.Y - 44, 0))
	)
end

---Build the floating window for a card.
---@param card table
---@param width number
---@return table
local function buildPopout(card, width)
	local pop = { collapsed = false, token = 0, width = width }
	local frame = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.window,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(width, 0),
		Parent = ui.popLayer,
	})

	glassy[frame] = 0
	frame.BackgroundTransparency = getLook().glass
	pop.frame = frame
	pop.stroke = style(frame, 12, THEME.edge)
	pop.scale = create("UIScale", { Scale = ui.scale, Parent = frame })
	list(frame, 0)

	local header = create("Frame", {
		Active = true,
		BackgroundColor3 = THEME.header,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = frame,
	})

	glassy[header] = 0
	style(header, 12)
	pop.filler = create("Frame", {
		BackgroundColor3 = THEME.header,
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
		Parent = header,
	})
	pop.line = create("Frame", {
		BackgroundColor3 = THEME.line,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = header,
	})

	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = header,
	})

	pad(row, 0, 6, 0, 12)
	list(row, 8, true)
	drawGrip(row, { LayoutOrder = 1 })
	icon(row, "gem", 14, THEME.accent, { LayoutOrder = 2 })

	pop.dot = create("Frame", {
		BackgroundColor3 = THEME.accent,
		LayoutOrder = 3,
		Size = UDim2.fromOffset(8, 8),
		Visible = false,
		Parent = row,
	})

	pill(pop.dot)

	local title = text(row, card.title, 13, "medium", THEME.text, { LayoutOrder = 4, Size = UDim2.new(0, 10, 1, 0) })

	create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = title })

	pop.badge = text(row, "", 11, "mono", THEME.accent, {
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 5,
		Size = UDim2.new(0, 0, 1, 0),
		TextTruncate = Enum.TextTruncate.None,
		Visible = false,
	})

	local collapseButton, collapseIcon = iconButton(row, "minus", { LayoutOrder = 6 })

	pop.collapseIcon = collapseIcon

	local dockButton, dockIcon = iconButton(row, "arrow-down-to-line", { LayoutOrder = 7 })

	dockButton:SetAttribute("RestTransparency", 0)
	dockButton:SetAttribute("RestToken", THEME.accent)
	dockButton:SetAttribute("HoverToken", THEME.accentText)
	setColor(dockButton, "BackgroundColor3", THEME.accentBg)
	dockButton.BackgroundTransparency = 0
	setColor(dockIcon, "ImageColor3", THEME.accent)

	collapseButton.MouseButton1Click:Connect(function()
		setCollapsed(card, not pop.collapsed)
	end)

	dockButton.MouseButton1Click:Connect(function()
		dock(card)
	end)

	pop.content = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = frame,
	})
	pop.wrap = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = pop.content,
	})

	pad(pop.wrap, 12)

	-- Drag the header to move it. Drop it over the window to dock it.
	header.InputBegan:Connect(function(input)
		if not isPress(input) or pointer.drag or ui.busy then
			return
		end

		local start = inputPosition(input)
		local origin = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
		local overWindow = false

		tween(pop.scale, { Scale = ui.scale * 1.02 }, 0.2, Enum.EasingStyle.Back)

		pointer.drag = {
			move = function(position)
				local target = clampToScreen(origin + position - start, frame.AbsoluteSize)

				frame.Position = UDim2.fromOffset(target.X, target.Y)
				overWindow = ui.windowShown and not ui.minimized and isInside(ui.main, position)

				if overWindow and currentPage ~= card.page then
					showPage(card.page.name)
				end

				setDockHover(card, overWindow)
			end,
			finish = function()
				tween(pop.scale, { Scale = ui.scale }, 0.24, Enum.EasingStyle.Back)
				setDockHover(card, false)

				if overWindow then
					dock(card)
				else
					saveLayoutSoon()
				end
			end,
		}
	end)

	return pop
end

---Hide or show a card's own frame while it floats.
---@param card table
---@param floating boolean
local function setCardFloating(card, floating)
	card.header.Visible = not floating and card.headerShown
	card.padding.PaddingTop = UDim.new(0, floating and 0 or card.paddingValues[1])
	card.padding.PaddingBottom = UDim.new(0, floating and 0 or card.paddingValues[1])
	card.padding.PaddingLeft = UDim.new(0, floating and 0 or card.paddingValues[2])
	card.padding.PaddingRight = UDim.new(0, floating and 0 or card.paddingValues[2])
	glassy[card.frame] = (not floating) and 0 or nil
	card.frame.BackgroundTransparency = floating and 1 or getLook().glass
	card.stroke.Transparency = floating and 1 or 0

	card.stretch.MinSize = floating and Vector2.zero or baseMinimum(card)
	stretchSoon(card.page)

	for _, overlay in ipairs(card.overlays) do
		overlay.Visible = false
	end
end

---Float a card over the game.
---@param card table
---@param restore Vector2? a saved position, placed without animation
function popOut(card, restore)
	if card.pop then
		return
	end

	local scale = ui.scale
	local start = card.frame.AbsolutePosition
	local width = card.frame.AbsoluteSize.X / scale
	local height = card.frame.AbsoluteSize.Y / scale

	if width < 50 then
		width = DEFAULT_POP_WIDTH
	end

	local pop = buildPopout(card, width)

	card.pop = pop
	setCardFloating(card, true)
	card.note = buildDockNote(card, restore and DOCK_NOTE_HEIGHT or math.max(height, 60))
	card.body.Parent = pop.wrap

	if restore then
		pop.frame.Position = UDim2.fromOffset(restore.X, restore.Y)
	else
		local target = clampToScreen(start + POP_OFFSET, Vector2.new(width * scale, 100))

		pop.frame.Position = UDim2.fromOffset(start.X, start.Y)
		pop.scale.Scale = scale * 0.94
		tween(pop.frame, { Position = UDim2.fromOffset(target.X, target.Y) }, 0.36)
		tween(pop.scale, { Scale = scale }, 0.4, Enum.EasingStyle.Back)
		tween(card.note, { Size = UDim2.new(1, 0, 0, DOCK_NOTE_HEIGHT) }, 0.32)
	end

	updateBadges()
	saveLayoutSoon()
end

---Put a floating card back in its place in the window.
---@param card table
---@param instant boolean?
function dock(card, instant)
	local pop = card.pop

	if not pop or pop.docking then
		return
	end

	pop.docking = true

	local function finish()
		card.body.Parent = card.frame

		if card.note then
			card.note:Destroy()
			card.note = nil
		end

		pop.frame:Destroy()
		card.pop = nil
		card.dockHover = false
		setCardFloating(card, false)
		saveLayoutSoon()
	end

	local visible = not instant and ui.windowShown and not ui.minimized and currentPage == card.page

	if not visible then
		finish()

		return
	end

	if pop.collapsed then
		pop.content.AutomaticSize = Enum.AutomaticSize.Y
	end

	local paddingValues = card.paddingValues
	local cardHeight = card.body.AbsoluteSize.Y / ui.scale
		+ paddingValues[1] * 2
		+ (card.headerShown and card.header.AbsoluteSize.Y / ui.scale + card.gap or 0)
	local target = card.frame.AbsolutePosition

	tween(pop.frame, { Position = UDim2.fromOffset(target.X, target.Y) }, 0.28)
	tween(pop.scale, { Scale = ui.scale * 0.97 }, 0.28)
	tween(card.note, { Size = UDim2.new(1, 0, 0, math.max(cardHeight, card.minHeight or 0)) }, 0.28)
	task.delay(0.28, function()
		if Library.running then
			finish()
		end
	end)
end

---Lift a dragged item: tilt it, light its edge and drop a shadow.
---@param target GuiObject the visible box
---@param stroke UIStroke
---@param shadow Frame
---@param tilt number
---@param slot Frame
local function lift(target, stroke, shadow, tilt, slot)
	fadeColor(target, "BackgroundColor3", THEME.lift, 0.2)
	tween(target, { BackgroundTransparency = 0 }, 0.2)
	fadeColor(stroke, "Color", THEME.accent, 0.2)
	tween(stroke, { Transparency = 0 }, 0.2)
	tween(slot, { Rotation = tilt }, 0.28, Enum.EasingStyle.Back)
	tween(shadow, { BackgroundTransparency = 0.45 }, 0.26)
end

---Put a lifted item down again.
---@param target GuiObject
---@param stroke UIStroke
---@param shadow Frame
---@param slot Frame
---@param rest table background, backgroundAlpha, stroke, strokeAlpha
local function putDown(target, stroke, shadow, slot, rest)
	fadeColor(target, "BackgroundColor3", rest.background, 0.26)
	tween(target, { BackgroundTransparency = rest.backgroundAlpha }, 0.26)
	fadeColor(stroke, "Color", rest.stroke, 0.26)
	tween(stroke, { Transparency = rest.strokeAlpha }, 0.26)
	tween(slot, { Rotation = 0 }, 0.3, Enum.EasingStyle.Back)
	tween(shadow, { BackgroundTransparency = 1 }, 0.24)
end

---Find the column and position a pointer is over.
---@param page table
---@param position Vector2
---@param except Instance
---@return Frame, number
local function findCardTarget(page, position, except)
	local bestColumn, bestDistance = nil, math.huge

	for _, column in ipairs(page:GetColumns()) do
		local topLeft = column.AbsolutePosition
		local bottomRight = topLeft + Vector2.new(column.AbsoluteSize.X, math.max(column.AbsoluteSize.Y, 40))
		local dx = position.X < topLeft.X and topLeft.X - position.X
			or position.X > bottomRight.X and position.X - bottomRight.X
			or 0
		local dy = position.Y < topLeft.Y and topLeft.Y - position.Y
			or position.Y > bottomRight.Y and position.Y - bottomRight.Y
			or 0
		local distance = dx * dx + dy * dy

		if distance < bestDistance then
			bestColumn, bestDistance = column, distance
		end
	end

	return bestColumn, insertIndex(bestColumn, except, position.Y)
end

---Create a drop shadow in the drag layer.
---@param width number
---@param height number
---@param radius number
---@return Frame
local function makeShadow(width, height, radius)
	local shadow = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = THEME.shadow,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(width + 8, height + 8),
		Parent = ui.dragLayer,
	})

	style(shadow, radius + 4)

	return shadow
end

---Start dragging a card around its page.
---@param card table
---@param position Vector2
---@param start Vector2
---@return table?
local function beginCardDrag(card, position, start)
	local page = card.page

	if card.pop or page ~= currentPage then
		return nil
	end

	local scale = ui.scale
	local slot = card.slot
	local layer = ui.dragLayer
	local column = slot.Parent
	local absolute = slot.AbsolutePosition
	local width = slot.AbsoluteSize.X / scale
	local session = {
		slot = slot,
		height = slot.AbsoluteSize.Y / scale,
		gap = page.gap,
		radius = 12,
		markerHeight = page.gap + 6,
		markerTop = math.floor((page.gap + 6) / 2) - 1,
		markerInset = 0,
		ghostText = card.title .. " was here",
	}

	local before = 0

	for _, other in ipairs(listSlots(column, slot)) do
		before += other.LayoutOrder < slot.LayoutOrder and 1 or 0
	end

	renumber(column, slot)
	session.ghostIndex = before + 1
	session.ghostContainer = column
	session.container, session.insertAt = column, session.ghostIndex
	session.ghost = makeGhost(column, session.ghostIndex, session)

	local shadow = makeShadow(width, session.height - page.gap, 12)

	slot.Parent = layer
	slot.AnchorPoint = Vector2.new(0.5, 0)
	slot.Size = UDim2.fromOffset(width, 0)

	local grab = start - absolute

	---Place the card under the pointer.
	---@param at Vector2
	local function place(at)
		local origin = layer.AbsolutePosition
		local x = (at.X - grab.X - origin.X) / scale + width / 2
		local y = (at.Y - grab.Y - origin.Y) / scale

		slot.Position = UDim2.fromOffset(x, y)
	end

	---Move the line to where the card would land.
	local function retarget()
		local target, insertAt = findCardTarget(page, pointer.position, slot)

		moveMarker(session, target, insertAt)
	end

	place(position)
	lift(card.frame, card.stroke, shadow, 1.5, slot)

	-- Keep the shadow under the card, and scroll the page while the card is held near its top or bottom.
	local following = connect(runService.RenderStepped, function(deltaTime)
		local scroller = page.scroller
		local top = scroller.AbsolutePosition.Y
		local bottom = top + scroller.AbsoluteSize.Y
		local y = pointer.position.Y
		local speed = 0

		shadow.Position = UDim2.new(slot.Position.X, slot.Position.Y + UDim.new(0, 12))

		if session.settling then
			return
		end

		if y < top + EDGE_SCROLL_ZONE then
			speed = -EDGE_SCROLL_SPEED * math.clamp(1 - (y - top) / EDGE_SCROLL_ZONE, 0, 1)
		elseif y > bottom - EDGE_SCROLL_ZONE then
			speed = EDGE_SCROLL_SPEED * math.clamp(1 - (bottom - y) / EDGE_SCROLL_ZONE, 0, 1)
		end

		if speed ~= 0 then
			local limit = math.max(scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y, 0)

			scroller.CanvasPosition = Vector2.new(0, math.clamp(scroller.CanvasPosition.Y + speed * deltaTime, 0, limit))
			retarget()
		end
	end)

	session.move = function(at)
		place(at)
		retarget()
	end

	session.finish = function()
		session.settling = true
		putDown(card.frame, card.stroke, shadow, slot, {
			background = card.restBackground,
			backgroundAlpha = getLook().glass,
			stroke = card.restStroke,
			strokeAlpha = 0,
		})

		settle(session, function(target)
			local origin = layer.AbsolutePosition

			return UDim2.fromOffset((target.X - origin.X) / scale + width / 2, (target.Y - origin.Y) / scale)
		end, function(landing)
			following:Disconnect()
			slot.Parent = landing.Parent
			slot.AnchorPoint = Vector2.zero
			slot.Position = UDim2.new()
			slot.Size = UDim2.new(1, 0, 0, 0)
			slot.Rotation = 0
			slot.LayoutOrder = landing.LayoutOrder
			shadow:Destroy()

			task.defer(function()
				renumber(slot.Parent)
				stretchSoon(page)
				saveLayoutSoon()
			end)
		end)
	end

	return session
end

---Start dragging a tab up or down its rail section.
---@param page table
---@param position Vector2
---@param start Vector2
---@return table?
local function beginTabDrag(page, position, start)
	if page.pinned then
		return nil
	end

	local scale = ui.scale
	local slot = page.tab.slot
	local container = slot.Parent
	local layer = ui.dragLayer
	local absolute = slot.AbsolutePosition
	local width = slot.AbsoluteSize.X / scale
	local session = {
		slot = slot,
		height = TAB_HEIGHT + TAB_GAP,
		gap = TAB_GAP,
		radius = 9,
		markerHeight = 7,
		markerTop = 2,
		markerInset = 6,
	}

	local before = 0

	for _, other in ipairs(listSlots(container, slot)) do
		before += other.LayoutOrder < slot.LayoutOrder and 1 or 0
	end

	renumber(container, slot)
	session.ghostIndex = before + 1
	session.ghostContainer = container
	session.container, session.insertAt = container, session.ghostIndex
	session.ghost = makeGhost(container, session.ghostIndex, session)

	local shadow = makeShadow(width, TAB_HEIGHT, 9)

	slot.Parent = layer
	slot.AnchorPoint = Vector2.new(0.5, 0)
	slot.Size = UDim2.fromOffset(width, TAB_HEIGHT + TAB_GAP)

	local grab = start - absolute
	local x = (absolute.X - layer.AbsolutePosition.X) / scale + width / 2

	---Place the tab under the pointer, inside its section.
	---@param at Vector2
	local function place(at)
		local origin = layer.AbsolutePosition
		local top = (container.AbsolutePosition.Y - origin.Y) / scale
		local bottom = top + container.AbsoluteSize.Y / scale - TAB_HEIGHT
		local y = math.clamp((at.Y - grab.Y - origin.Y) / scale, top - 8, math.max(bottom, top) + 8)

		slot.Position = UDim2.fromOffset(x, y)
		shadow.Position = UDim2.fromOffset(x, y + 10)
	end

	place(position)
	page.tab.button.BackgroundTransparency = 0
	page.tab.stroke.Transparency = 0
	lift(page.tab.button, page.tab.stroke, shadow, -2, slot)

	session.move = function(at)
		place(at)
		moveMarker(session, container, insertIndex(container, slot, at.Y))
	end

	session.finish = function()
		local selected = page == currentPage

		putDown(page.tab.button, page.tab.stroke, shadow, slot, {
			background = selected and THEME.accentNav or THEME.inset,
			backgroundAlpha = selected and 0 or 1,
			stroke = THEME.accentEdge,
			strokeAlpha = selected and 0 or 1,
		})

		settle(session, function(target)
			local origin = layer.AbsolutePosition

			return UDim2.fromOffset(x, (target.Y - origin.Y) / scale)
		end, function(landing)
			slot.Parent = container
			slot.AnchorPoint = Vector2.zero
			slot.Position = UDim2.new()
			slot.Size = UDim2.new(1, 0, 0, TAB_HEIGHT + TAB_GAP)
			slot.Rotation = 0
			slot.LayoutOrder = landing.LayoutOrder
			shadow:Destroy()

			task.defer(function()
				renumber(container)
				paintTab(page)
				saveLayoutSoon()
			end)
		end)
	end

	return session
end

---Set a toggle and redraw everything bound to it.
---@param key string
---@param enabled boolean
local function setToggle(key, enabled)
	if Library.toggles[key] == enabled then
		return
	end

	Library.toggles[key] = enabled

	for _, paint in ipairs(keyPaints[key] or {}) do
		paint()
	end

	for _, watcher in ipairs(toggleWatchers[key] or {}) do
		safeCall(key, watcher, enabled)
	end

	updateBadges()
end

---Register a function to run when a toggle changes.
---@param key string
---@param callback function
local function watchToggle(key, callback)
	toggleWatchers[key] = toggleWatchers[key] or {}
	table.insert(toggleWatchers[key], callback)
end

---Redraw every control from its value, and tell watchers about toggles that changed.
local function repaintAll()
	for key, keyList in pairs(keyPaints) do
		local changed = false

		for _, paint in ipairs(keyList) do
			changed = paint() or changed
		end

		if changed then
			for _, watcher in ipairs(toggleWatchers[key] or {}) do
				safeCall(key, watcher, Library.toggles[key] == true)
			end
		end
	end

	for _, paint in ipairs(paints) do
		paint()
	end

	updateBadges()
end

---Build a switch: a 40 by 22 track with a sliding knob.
---@param parent Instance
---@param properties table?
---@return Frame, function
local function makeSwitch(parent, properties)
	local track = create("Frame", {
		BackgroundColor3 = THEME.track,
		Size = UDim2.fromOffset(40, 22),
		Parent = parent,
	})

	pill(track)

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = THEME.muted,
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Parent = track,
	})

	pill(knob)

	local knobScale = create("UIScale", { Parent = knob })

	for property, value in pairs(properties or {}) do
		track[property] = value
	end

	---Show on or off.
	---@param enabled boolean
	---@param animate boolean
	local function show(enabled, animate)
		local duration = animate and 0.22 or 0

		fadeColor(track, "BackgroundColor3", enabled and THEME.accent or THEME.track, duration)
		fadeColor(knob, "BackgroundColor3", enabled and THEME.ink or THEME.muted, duration)
		tween(knob, { Position = UDim2.new(0, enabled and 21 or 3, 0.5, 0) }, animate and 0.34 or 0, Enum.EasingStyle.Back)

		if animate then
			-- The knob squashes as it travels.
			knobScale.Scale = 0.8
			tween(knobScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
		end
	end

	return track, show
end

---Get the next layout position in a card's body.
---@param card table
---@return number
local function nextOrder(card)
	card.order += 1

	return card.order
end

---Create a block in a card's body. With showWhen, it folds away while that toggle is off.
---@param card table
---@param options table? showWhen, gap, top
---@return Frame
local function addBlock(card, options)
	options = options or {}

	local outer = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(card),
		Size = UDim2.new(1, 0, 0, 0),
		Parent = card.body,
	})

	local inner = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = outer,
	})

	if options.top then
		pad(inner, options.top, 0, 0, 0)
	end

	list(inner, options.gap or 8)
	card.lastRow = nil

	local key = options.showWhen

	if key then
		local token = 0

		outer.ClipsDescendants = true

		---Unfold or fold the block.
		---@param open boolean
		local function setOpen(open)
			token += 1

			local current = token

			if open then
				outer.AutomaticSize = Enum.AutomaticSize.None
				outer.Size = UDim2.new(1, 0, 0, 0)
				outer.Visible = true

				task.spawn(function()
					-- Measure after a frame, once the hidden content has a size.
					task.wait()

					if token ~= current then
						return
					end

					tween(outer, { Size = UDim2.new(1, 0, 0, inner.AbsoluteSize.Y / ui.scale) }, 0.34, Enum.EasingStyle.Back)
					task.wait(0.36)

					if token == current then
						outer.AutomaticSize = Enum.AutomaticSize.Y
						outer.Size = UDim2.new(1, 0, 0, 0)
					end
				end)
			else
				outer.AutomaticSize = Enum.AutomaticSize.None
				outer.Size = UDim2.new(1, 0, 0, inner.AbsoluteSize.Y / ui.scale)
				tween(outer, { Size = UDim2.new(1, 0, 0, 0) }, 0.22)

				task.delay(0.22, function()
					if token == current then
						outer.Visible = false
					end
				end)
			end
		end

		watchToggle(key, setOpen)

		if not Library.toggles[key] then
			outer.AutomaticSize = Enum.AutomaticSize.None
			outer.Visible = false
		end
	end

	return inner
end

---Build a segmented control: the design's tab strip.
---@param parent Instance
---@param count number
---@param isSelected function
---@param onSelect function
---@param labelFor function returns the rich text for a segment
---@return table
local function makeSegmented(parent, count, isSelected, onSelect, labelFor)
	local frame = create("Frame", {
		BackgroundColor3 = THEME.deep,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = parent,
	})

	style(frame, 10, THEME.divider)
	pad(frame, 3)

	local highlight = create("Frame", {
		BackgroundColor3 = THEME.chip,
		Size = UDim2.fromScale(1 / count, 1),
		Parent = frame,
	})

	style(highlight, 8)

	local segmented = { frame = frame, buttons = {} }

	for index = 1, count do
		local button = create("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			FontFace = FONTS.body,
			Position = UDim2.fromScale((index - 1) / count, 0),
			RichText = true,
			Size = UDim2.fromScale(1 / count, 1),
			Text = "",
			TextColor3 = THEME.muted,
			TextSize = textSize("body", 13),
			ZIndex = 2,
			Parent = frame,
		})

		segmented.buttons[index] = button
		button.MouseButton1Click:Connect(function()
			onSelect(index)
			segmented.paint()
		end)
	end

	local shown = nil

	---Slide the highlight to the selected segment and refresh the labels.
	function segmented.paint()
		for index, button in ipairs(segmented.buttons) do
			local selected = isSelected(index)

			button.FontFace = selected and FONTS.medium or FONTS.body
			setColor(button, "TextColor3", selected and THEME.text or THEME.muted)
			button.Text = labelFor(index, selected)

			if selected and shown ~= index then
				tween(highlight, { Position = UDim2.fromScale((index - 1) / count, 0) }, shown and 0.3 or 0)
				shown = index
			end
		end
	end

	segmented.paint()

	return segmented
end

---Add a switch row with a title and description. Read it from Library.toggles[key].
---@param key string
---@param title string
---@param description string?
---@param default boolean?
---@param callback function? called with the new state
---@return TextButton
function Card:AddToggle(key, title, description, default, callback)
	if Library.toggles[key] == nil then
		Library.toggles[key] = default == true
	end

	toggleKeys[key] = self.page
	table.insert(self.page.toggleKeys, key)
	table.insert(self.toggleKeys, key)

	local tall = description ~= nil and description ~= ""
	local height = tall and 52 or 44
	local row = create("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, height),
		Text = "",
		Parent = self.body,
	})

	-- A divider sits under every row that has another row after it.
	if self.lastRow then
		create("Frame", {
			BackgroundColor3 = THEME.divider,
			Position = UDim2.new(0, 0, 1, 1),
			Size = UDim2.new(1, 0, 0, 1),
			Parent = self.lastRow,
		})
	end

	self.lastRow = row

	local titleSize = textSize("medium", 15)
	local descriptionSize = textSize("body", 12)
	local top = math.floor((height - titleSize - (tall and descriptionSize or 0)) / 2) + 1

	text(row, title, 15, "medium", THEME.text, {
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, -56, 0, titleSize),
	})

	if tall then
		text(row, description, 12, "body", THEME.muted, {
			Position = UDim2.fromOffset(0, top + titleSize - 3),
			Size = UDim2.new(1, -56, 0, descriptionSize),
		})
	end

	local _, show = makeSwitch(row, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
	})

	local shown = nil

	---Show the current state. Returns true when it changed.
	---@return boolean
	local function paint()
		local enabled = Library.toggles[key] == true

		if enabled == shown then
			return false
		end

		show(enabled, shown ~= nil)
		shown = enabled

		return true
	end

	if callback then
		watchToggle(key, callback)
	end

	addPress(row, 0.99)
	row.MouseButton1Click:Connect(function()
		setToggle(key, not Library.toggles[key])
	end)

	keyPaints[key] = keyPaints[key] or {}
	table.insert(keyPaints[key], paint)
	paint()
	searchRows[#searchRows + 1] = {
		page = self.page,
		text = string.lower(title .. " " .. (description or "")),
		frame = row,
	}

	return row
end

---Add a compact switch row, like the design's quick switches. It shares its value with any other row for the key.
---@param key string
---@param title string
---@return TextButton
function Card:AddSwitch(key, title)
	if Library.toggles[key] == nil then
		Library.toggles[key] = false
	end

	local row = create("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		Parent = self.body,
	})

	local label = text(row, title, 14, "body", THEME.text, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, -56, 0, textSize("body", 14)),
	})

	local _, show = makeSwitch(row, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
	})

	local shown = nil

	---Show the current state. Returns true when it changed.
	---@return boolean
	local function paint()
		local enabled = Library.toggles[key] == true

		if enabled == shown then
			return false
		end

		show(enabled, shown ~= nil)
		fadeColor(label, "TextColor3", enabled and THEME.text or THEME.soft, shown ~= nil and 0.2 or 0)
		shown = enabled

		return true
	end

	addPress(row, 0.99)
	row.MouseButton1Click:Connect(function()
		setToggle(key, not Library.toggles[key])
	end)

	keyPaints[key] = keyPaints[key] or {}
	table.insert(keyPaints[key], paint)
	paint()

	return row
end

---Add a whole-number slider in an inset box. Read it from Library.settings[key].
---@param key string
---@param title string
---@param range number[]
---@param suffix string?
---@param default number?
---@param callback function?
---@param options table? showWhen = a toggle key, ticks = labels spread under the track
---@return Frame
function Card:AddSlider(key, title, range, suffix, default, callback, options)
	options = options or {}

	if type(Library.settings[key]) ~= "number" then
		Library.settings[key] = default or range[1]
	end

	rules[key] = { kind = "slider", range = range }

	local inner = addBlock(self, { showWhen = options.showWhen, top = 2 })
	local ticks = options.ticks
	local labelSize = textSize("body", 13)
	local tickSize = textSize("mono", 11)
	local trackTop = 12 + labelSize + 6
	local height = trackTop + 18 + (ticks and 6 + tickSize or 0) + 12
	local box = create("Frame", {
		BackgroundColor3 = THEME.inset,
		Size = UDim2.new(1, 0, 0, height),
		Parent = inner,
	})

	style(box, 10, THEME.divider)
	text(box, title, 13, "body", THEME.soft, {
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.new(1, -150, 0, labelSize),
	})

	local value = text(box, "", 14, "monoBold", THEME.text, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 12),
		Size = UDim2.new(0, 140, 0, labelSize),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local area = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, trackTop),
		Size = UDim2.new(1, -28, 0, 18),
		Parent = box,
	})

	local track = create("Frame", {
		BackgroundColor3 = THEME.track,
		Position = UDim2.fromOffset(0, 7),
		Size = UDim2.new(1, 0, 0, 4),
		Parent = area,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = track })

	local fill = create("Frame", {
		BackgroundColor3 = THEME.accent,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = fill })

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.text,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		Parent = track,
	})

	pill(knob)
	create("UIStroke", { Color = THEME.accent, Thickness = 3, Parent = knob })

	if ticks then
		local count = #ticks

		for index, tick in ipairs(ticks) do
			local alpha = (index - 1) / math.max(count - 1, 1)

			text(box, tick, 11, "mono", THEME.muted, {
				AnchorPoint = Vector2.new(alpha, 0),
				Position = UDim2.new(alpha, 14 - alpha * 28, 0, trackTop + 18 + 6),
				Size = UDim2.new(0, 40, 0, tickSize),
				TextXAlignment = index == 1 and Enum.TextXAlignment.Left
					or index == count and Enum.TextXAlignment.Right
					or Enum.TextXAlignment.Center,
			})
		end
	end

	local shown = nil

	---Show the current value.
	local function paint()
		local current = Library.settings[key]

		if current == shown then
			return
		end

		local alpha = (current - range[1]) / math.max(range[2] - range[1], 1)

		shown = current
		value.Text = suffix and string.format("%d %s", current, suffix) or tostring(current)
		tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.12)
		tween(knob, { Position = UDim2.fromScale(alpha, 0.5) }, 0.12)
	end

	---Set the value from a pointer position.
	---@param x number
	local function setFromPointer(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local new = math.floor(range[1] + (range[2] - range[1]) * alpha + 0.5)

		if new ~= Library.settings[key] then
			Library.settings[key] = new
			paint()
			safeCall(key, callback, new)
		end
	end

	local hit = create("TextButton", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -6, 0, -6),
		Size = UDim2.new(1, 12, 1, 12),
		Text = "",
		Parent = area,
	})

	hit.InputBegan:Connect(function(input)
		if not isPress(input) or pointer.drag then
			return
		end

		tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.22, Enum.EasingStyle.Back)
		setFromPointer(input.Position.X)

		pointer.drag = {
			move = function(position)
				setFromPointer(position.X)
			end,
			finish = function()
				tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.22, Enum.EasingStyle.Back)
			end,
		}
	end)

	paint()
	paints[#paints + 1] = paint
	searchRows[#searchRows + 1] = { page = self.page, text = string.lower(title), frame = box }

	return box
end

---Add option chips, optionally split into tabs. Read each tab from Library.settings[tab.key].
---@param tabs table[] each { name, key, choices, defaults, colors, single, callback }
---@param options table? actions = Select all and Clear buttons, columns, showWhen
function Card:AddChips(tabs, options)
	options = options or {}

	for _, tab in ipairs(tabs) do
		if tab.single then
			if not table.find(tab.choices, Library.settings[tab.key]) then
				Library.settings[tab.key] = tab.defaults or tab.choices[1]
			end

			rules[tab.key] = { kind = "single", options = tab.choices }
		else
			if type(Library.settings[tab.key]) ~= "table" then
				Library.settings[tab.key] = tab.defaults or {}
			end

			rules[tab.key] = { kind = "multi", options = tab.choices }
		end
	end

	local inner = addBlock(self, { gap = options.gap or 12, showWhen = options.showWhen })
	local active = math.clamp(options.startTab or 1, 1, #tabs)
	local segmented = nil
	local tabPaints = {}
	local paintSummary = nil

	-- With a label, the chips fold away behind a dropdown button that shows a summary.
	if options.label then
		local header = create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = THEME.inset,
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, 44),
			Text = "",
			Parent = inner,
		})

		local headerStroke = style(header, 9, THEME.edge)

		text(header, options.label, 14, "body", THEME.text, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.new(0.55, -14, 0, textSize("body", 14)),
		})

		local summary = text(header, "", 13, "body", THEME.muted, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -40, 0.5, 0),
			Size = UDim2.new(0.45, -40, 0, textSize("body", 13)),
			TextXAlignment = Enum.TextXAlignment.Right,
		})

		local chevron = icon(header, "chevron-down", 16, THEME.muted, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
		})

		local body = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = options.open == true,
			Parent = inner,
		})

		list(body, options.gap or 12)
		addPress(header, 0.99)

		---Show or hide the chips.
		---@param open boolean
		local function setOpen(open)
			body.Visible = open
			tween(chevron, { Rotation = open and 180 or 0 }, 0.18)
			fadeColor(headerStroke, "Color", open and THEME.edgeStrong or THEME.edge, 0.18)
		end

		header.MouseButton1Click:Connect(function()
			setOpen(not body.Visible)
		end)

		paintSummary = function()
			local value

			if options.summary then
				value = options.summary()
			else
				local picked = 0

				for _, tab in ipairs(tabs) do
					if tab.single then
						value = tostring(Library.settings[tab.key])
					else
						for _, option in ipairs(tab.choices) do
							picked += Library.settings[tab.key][option] and 1 or 0
						end
					end
				end

				value = value or (picked == 0 and "None picked" or string.format("%d picked", picked))
			end

			setText(summary, value or "")
		end

		inner = body
	end

	---Count picked options in a tab.
	---@param tab table
	---@return number
	local function countPicked(tab)
		if tab.single then
			return 1
		end

		local picked = 0

		for _, option in ipairs(tab.choices) do
			picked += Library.settings[tab.key][option] and 1 or 0
		end

		return picked
	end

	if #tabs > 1 then
		segmented = makeSegmented(inner, #tabs, function(index)
			return index == active
		end, function(index)
			active = index

			for other, tab in ipairs(tabs) do
				tab.grid.Visible = other == index
			end
		end, function(index, selected)
			local tab = tabs[index]

			return string.format(
				'%s <font family="rbxasset://fonts/families/RobotoMono.json"%s>%d</font>',
				tab.name,
				selected and string.format(' color="%s"', hexOf(THEME.accent)) or "",
				countPicked(tab)
			)
		end)

		segmented.frame.LayoutOrder = 1
	end

	local columns = options.columns or 2

	for index, tab in ipairs(tabs) do
		local grid = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = index + 1,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = index == active,
			Parent = inner,
		})

		create("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.new(1 / columns, -8 * (columns - 1) / columns, 0, 40),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = grid,
		})

		tab.grid = grid
		tabPaints[index] = {}

		for order, option in ipairs(tab.choices) do
			local chip = create("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = THEME.inset,
				BackgroundTransparency = 1,
				LayoutOrder = order,
				Text = "",
				Parent = grid,
			})

			local stroke = style(chip, 9, THEME.edge)
			local color = tab.colors and tab.colors[option]
			local dot = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = color or THEME.muted,
				Position = UDim2.new(0, 12, 0.5, 0),
				Size = UDim2.fromOffset(10, 10),
				Parent = chip,
			})

			pill(dot)

			local name = text(chip, option, 13, "body", THEME.muted, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 31, 0.5, 0),
				Size = UDim2.new(1, -60, 0, textSize("body", 13)),
			})

			local check = icon(chip, "check", 14, THEME.accent, {
				AnchorPoint = Vector2.new(1, 0.5),
				ImageTransparency = 1,
				Position = UDim2.new(1, -12, 0.5, 0),
			})

			local checkScale = create("UIScale", { Scale = 0.6, Parent = check })
			local shown = nil

			addPress(chip, 0.97)

			---Show whether the option is picked.
			local function paint()
				local selected

				if tab.single then
					selected = Library.settings[tab.key] == option
				else
					selected = Library.settings[tab.key][option] == true
				end

				if selected == shown then
					return
				end

				local animate = shown ~= nil

				shown = selected
				tween(chip, { BackgroundTransparency = selected and 0 or 1 }, animate and 0.18 or 0)
				fadeColor(stroke, "Color", selected and THEME.edgeStrong or THEME.edge, animate and 0.18 or 0)
				fadeColor(name, "TextColor3", selected and THEME.text or THEME.muted, animate and 0.18 or 0)
				tween(check, { ImageTransparency = selected and 0 or 1 }, animate and 0.16 or 0)
				tween(checkScale, { Scale = selected and 1 or 0.6 }, animate and 0.3 or 0, Enum.EasingStyle.Back)
			end

			table.insert(tabPaints[index], paint)

			chip.MouseButton1Click:Connect(function()
				if tab.single then
					Library.settings[tab.key] = option
				else
					local selection = Library.settings[tab.key]

					selection[option] = not selection[option] or nil
				end

				for _, repaint in ipairs(tabPaints[index]) do
					repaint()
				end

				if segmented then
					segmented.paint()
				end

				if paintSummary then
					paintSummary()
				end

				safeCall(tab.key, tab.callback, Library.settings[tab.key])
			end)
		end
	end

	if options.actions then
		local actions = create("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = #tabs + 2,
			Size = UDim2.new(1, 0, 0, 34),
			Parent = inner,
		})

		list(actions, 8, true).HorizontalFlex = Enum.UIFlexAlignment.Fill

		---Pick or clear every option in the open tab.
		---@param picked boolean
		local function setAll(picked)
			local tab = tabs[active]

			if tab.single then
				return
			end

			local selection = {}

			for _, option in ipairs(tab.choices) do
				selection[option] = picked or nil
			end

			Library.settings[tab.key] = selection

			for _, repaint in ipairs(tabPaints[active]) do
				repaint()
			end

			if segmented then
				segmented.paint()
			end

			if paintSummary then
				paintSummary()
			end

			safeCall(tab.key, tab.callback, selection)
		end

		makeButton(actions, "Select all", "ghost", function()
			setAll(true)
		end).LayoutOrder = 1
		makeButton(actions, "Clear", "ghost", function()
			setAll(false)
		end).LayoutOrder = 2
	end

	paints[#paints + 1] = function()
		for _, group in ipairs(tabPaints) do
			for _, paint in ipairs(group) do
				paint()
			end
		end

		if segmented then
			segmented.paint()
		end

		if paintSummary then
			paintSummary()
		end
	end

	paints[#paints]()
end

---Add a list of options as chips. Kept for scripts written for the dropdown API.
---@param key string
---@param title string
---@param choices string[]
---@param defaults any a table of picked options, or one option when single
---@param callback function?
---@param options table? single, colors, showWhen, actions
function Card:AddDropdown(key, title, choices, defaults, callback, options)
	options = options or {}
	self:AddChips({
		{
			name = title,
			key = key,
			choices = choices,
			defaults = defaults,
			colors = options.colors,
			single = options.single,
			callback = callback,
		},
	}, { showWhen = options.showWhen, actions = not options.single and options.actions })
end

---Add a segmented pick-one control. Read it from Library.settings[key].
---@param key string
---@param title string?
---@param choices string[]
---@param default string?
---@param callback function?
---@return table
function Card:AddSegmented(key, title, choices, default, callback)
	if not table.find(choices, Library.settings[key]) then
		Library.settings[key] = default or choices[1]
	end

	rules[key] = { kind = "single", options = choices }

	local inner = addBlock(self)

	if title then
		text(inner, title, 13, "body", THEME.soft)
	end

	local segmented = makeSegmented(inner, #choices, function(index)
		return Library.settings[key] == choices[index]
	end, function(index)
		Library.settings[key] = choices[index]
		safeCall(key, callback, choices[index])
	end, function(index)
		return choices[index]
	end)

	segmented.frame.LayoutOrder = 2
	paints[#paints + 1] = segmented.paint

	return segmented
end

---Add a full-width button. Kind can be "ghost", "text", "primary", "danger", "dangerSolid" or "dangerSoft".
---@param label string
---@param callback function
---@param kind string?
---@return TextButton
function Card:AddButton(label, callback, kind)
	return makeButton(addBlock(self), label, kind, callback)
end

---Add a row of buttons that share the width.
---@return table
function Card:AddButtonRow()
	local frame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = addBlock(self),
	})

	list(frame, 8, true).HorizontalFlex = Enum.UIFlexAlignment.Fill

	return setmetatable({ frame = frame, count = 0 }, ButtonRow)
end

---Add a button to the row.
---@param label string
---@param callback function
---@param kind string?
---@return TextButton
function ButtonRow:AddButton(label, callback, kind)
	self.count += 1

	local button = makeButton(self.frame, label, kind, callback)

	button.LayoutOrder = self.count

	return button
end

---Add a text input.
---@param placeholder string
---@return TextBox
function Card:AddInput(placeholder)
	local input = create("TextBox", {
		BackgroundColor3 = THEME.deep,
		ClearTextOnFocus = false,
		FontFace = FONTS.body,
		PlaceholderColor3 = THEME.muted,
		PlaceholderText = placeholder,
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		TextColor3 = THEME.text,
		TextSize = textSize("body", 13),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = addBlock(self),
	})

	local stroke = style(input, 9, THEME.buttonEdge)

	pad(input, 0, 12)

	input.Focused:Connect(function()
		fadeColor(stroke, "Color", THEME.accentEdge)
	end)

	input.FocusLost:Connect(function()
		fadeColor(stroke, "Color", THEME.buttonEdge)
	end)

	return input
end

---Add wrapped text. Update it with Library.setText.
---@param value string
---@return TextLabel
function Card:AddLabel(value)
	return text(addBlock(self), value, 13, "body", THEME.soft, {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		TextTruncate = Enum.TextTruncate.None,
		TextWrapped = true,
	})
end

---Add a line of text. Options: size, color (a token), kind, align, rich, top.
---@param value string
---@param options table?
---@return TextLabel
function Card:AddText(value, options)
	options = options or {}

	return text(
		addBlock(self, { top = options.top }),
		value,
		options.size or 13,
		options.kind or "body",
		options.color or THEME.soft,
		{
			RichText = options.rich == true,
			TextXAlignment = options.align == "center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		}
	)
end

---Add a tinted note with an icon, such as a warning about what is never sold.
---@param value string
---@param iconName string?
---@return TextLabel
function Card:AddNote(value, iconName)
	local note = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.accentBg,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = addBlock(self),
	})

	style(note, 9, THEME.accentEdge)
	pad(note, 8, 10)
	list(note, 8, true)
	icon(note, iconName or "lock", 14, THEME.accent, { LayoutOrder = 1 })

	return text(note, value, 12, "body", THEME.accentText, {
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Size = UDim2.new(1, -22, 0, 0),
		TextTruncate = Enum.TextTruncate.None,
		TextWrapped = true,
	})
end

---Add a large display title, like a zone name.
---@param value string
---@param size number? design size, 24 by default
---@param color string? a theme token
---@return TextLabel
function Card:AddValue(value, size, color)
	return text(addBlock(self, { gap = 0 }), value, size or 24, "display", color or THEME.text)
end

---Add a name and value row. Returns the value label.
---@param name string
---@param color string? value color token
---@param mono boolean? false for plain text values
---@return TextLabel
function Card:AddStat(name, color, mono)
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, textSize("body", 13)),
		Parent = addBlock(self, { gap = 0 }),
	})

	text(row, name, 13, "body", THEME.soft, { Size = UDim2.new(0.5, 0, 1, 0) })

	return text(row, "—", 13, mono == false and "body" or "mono", color or THEME.text, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		RichText = true,
		Size = UDim2.new(0.5, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
end

---Add a progress row: a name and value with a bar under it. Returns the value label and the bar fill.
---@param name string
---@return TextLabel, Frame
function Card:AddProgress(name)
	local inner = addBlock(self, { gap = 6 })
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, textSize("body", 13)),
		Parent = inner,
	})

	text(row, name, 13, "body", THEME.soft, { Size = UDim2.new(0.5, 0, 1, 0) })

	local value = text(row, "—", 13, "mono", THEME.text, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local track = create("Frame", {
		BackgroundColor3 = THEME.edge,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 6),
		Parent = inner,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = track })

	local fill = create("Frame", {
		BackgroundColor3 = THEME.accent,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })

	return value, fill
end

---Add a thin progress bar. Returns the fill for Library.setBar.
---@return Frame
function Card:AddBar()
	local track = create("Frame", {
		BackgroundColor3 = THEME.edge,
		Size = UDim2.new(1, 0, 0, 6),
		Parent = addBlock(self),
	})

	create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = track })

	local fill = create("Frame", {
		BackgroundColor3 = THEME.accent,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })

	return fill
end

---Add the headline block: a title, a big number, a rate line, a bar chart, and stats down the right side.
---Use it on a card made with header = false. Returns value, rate (rich text), stats and SetBars.
---@param stats string[] names for the right-side stats
---@param barCount number?
---@return table
function Card:AddHero(stats, barCount)
	barCount = barCount or 12

	local height = (self.minHeight or 188) - self.paddingValues[1] * 2 - 2
	local hero = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, height),
		Parent = self.body,
	})

	local left = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -168, 1, 0),
		Parent = hero,
	})

	local titleSize = textSize("medium", 10)
	local title = text(left, caps(self.title), 10, "medium", THEME.muted, { Size = UDim2.new(1, 0, 0, titleSize) })
	local valueTop = titleSize + 4
	local value = text(left, "—", 34, "monoBold", THEME.text, {
		Position = UDim2.fromOffset(0, valueTop),
		Size = UDim2.new(1, 0, 0, 38),
	})

	local rateSize = textSize("body", 13)
	local rateTop = valueTop + 38
	local rate = text(left, "", 13, "body", THEME.accentText, {
		Position = UDim2.fromOffset(0, rateTop),
		RichText = true,
		Size = UDim2.new(1, 0, 0, rateSize),
	})

	local chartTop = rateTop + rateSize + 10
	local chart = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, chartTop),
		Size = UDim2.new(1, 0, 1, -chartTop),
		Parent = left,
	})

	local layout = list(chart, 5, true)

	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalFlex = Enum.UIFlexAlignment.Fill

	local bars = {}

	for index = 1, barCount do
		local bar = create("Frame", {
			BackgroundColor3 = index == barCount and THEME.accent
				or index == barCount - 1 and THEME.accentMid
				or THEME.accentDim,
			LayoutOrder = index,
			Size = UDim2.new(0, 4, 0.1, 0),
			Parent = chart,
		})

		create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = bar })
		bars[index] = bar
	end

	local right = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 150, 1, 0),
		Parent = hero,
	})

	create("Frame", {
		BackgroundColor3 = THEME.edge,
		Size = UDim2.new(0, 1, 1, 0),
		Parent = right,
	})

	local statLabels = {}
	local labelSize, valueSize = textSize("body", 12), textSize("mono", 16)
	local blockHeight = labelSize + valueSize - 2

	for index, name in ipairs(stats) do
		local alpha = (index - 1) / math.max(#stats - 1, 1)
		local block = create("Frame", {
			AnchorPoint = Vector2.new(0, alpha),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 17, alpha, 0),
			Size = UDim2.new(1, -17, 0, blockHeight),
			Parent = right,
		})

		text(block, name, 12, "body", THEME.muted, { Size = UDim2.new(1, 0, 0, labelSize) })
		statLabels[index] = text(block, "—", 16, "mono", THEME.text, {
			Position = UDim2.fromOffset(0, labelSize - 2),
			Size = UDim2.new(1, 0, 0, valueSize),
		})
	end

	self:AddHandle(title)

	local shownBars = {}
	local heroObject = { value = value, rate = rate, stats = statLabels }

	---Show the latest amounts as bars, scaled to the largest.
	---@param values number[]
	function heroObject:SetBars(values)
		local highest = 0

		for _, amount in ipairs(values) do
			highest = math.max(highest, amount)
		end

		for index, bar in ipairs(bars) do
			local amount = values[#values - barCount + index] or 0
			local alpha = highest > 0 and math.max(amount / highest, 0.06) or 0.06

			if math.abs(alpha - (shownBars[index] or -1)) > 0.005 then
				shownBars[index] = alpha
				tween(bar, { Size = UDim2.new(0, 4, alpha, 0) }, 0.5)
			end
		end
	end

	return heroObject
end

---Add a grid of tiles, like the crew pads. Each tile has :Set({ id, badge, badgeColor, badgeInk, name, sub, strong }).
---@param count number
---@param columns number?
---@return table[]
function Card:AddTiles(count, columns)
	columns = columns or 4

	local grid = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = addBlock(self),
	})

	local idSize, nameSize, subSize = textSize("bold", 11), textSize("medium", 14), textSize("body", 12)
	local tileHeight = 8 + idSize + nameSize + subSize + 2

	create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8),
		CellSize = UDim2.new(1 / columns, -8 * (columns - 1) / columns, 0, tileHeight),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	local tiles = {}

	for index = 1, count do
		local frame = create("Frame", {
			BackgroundColor3 = THEME.inset,
			LayoutOrder = index,
			Parent = grid,
		})

		local stroke = style(frame, 9, THEME.edge)
		local id = text(frame, "", 11, "mono", THEME.muted, {
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(0, 40, 0, idSize),
		})

		local badge = create("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -10, 0, 8),
			Size = UDim2.fromOffset(0, idSize - 2),
			Parent = frame,
		})

		create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = badge })

		local badgeStroke = create("UIStroke", { Color = THEME.buttonEdge, Parent = badge })

		badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local badgeText = text(badge, "", 11, "bold", THEME.muted, {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			TextTruncate = Enum.TextTruncate.None,
		})

		pad(badge, 0, 6)

		local name = text(frame, "", 14, "medium", THEME.text, {
			Position = UDim2.fromOffset(10, 6 + idSize),
			Size = UDim2.new(1, -20, 0, nameSize),
		})

		local sub = text(frame, "", 12, "body", THEME.muted, {
			Position = UDim2.fromOffset(10, 4 + idSize + nameSize),
			Size = UDim2.new(1, -20, 0, subSize),
		})

		local tile = { frame = frame }

		---Fill the tile. badgeColor fills the badge; without it the badge is an outline.
		---@param data table
		function tile:Set(data)
			setText(id, data.id or "")
			setText(name, data.name or "")
			setText(sub, data.sub or "")
			setText(badgeText, data.badge or "")
			badge.Visible = data.badge ~= nil and data.badge ~= ""
			setColor(stroke, "Color", data.strong and THEME.edgeStrong or THEME.edge)

			if data.badgeColor then
				badge.BackgroundTransparency = 0
				setRawColor(badge, "BackgroundColor3", data.badgeColor)
				badgeStroke.Transparency = 1
				badgeText.FontFace = FONTS.bold
				setRawColor(badgeText, "TextColor3", data.badgeInk or Color3.fromHex("1A1D22"))
			else
				badge.BackgroundTransparency = 1
				badgeStroke.Transparency = 0
				badgeText.FontFace = FONTS.body
				setColor(badgeText, "TextColor3", THEME.muted)
			end
		end

		tiles[index] = tile
	end

	return tiles
end

---Add a feed of timed lines, newest first. Set it with feed:Set({ { text, time, dot, dim } }).
---@param count number
---@return table
function Card:AddFeed(count)
	local inner = addBlock(self, { gap = 8 })
	local lineSize = textSize("body", 13)
	local rows = {}

	for index = 1, count do
		local row = create("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, lineSize - 2),
			Visible = false,
			Parent = inner,
		})

		local dot = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = THEME.muted,
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(6, 6),
			Parent = row,
		})

		pill(dot)

		local label = text(row, "", 13, "body", THEME.text, {
			Position = UDim2.fromOffset(16, -1),
			Size = UDim2.new(1, -96, 0, lineSize),
		})

		local time = text(row, "", 12, "mono", THEME.muted, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0, 80, 0, textSize("mono", 12)),
			TextXAlignment = Enum.TextXAlignment.Right,
		})

		rows[index] = { frame = row, dot = dot, label = label, time = time }
	end

	local feed = {}

	---Show entries. dot is a theme token, dim greys the text.
	---@param entries table[]
	function feed:Set(entries)
		for index, row in ipairs(rows) do
			local entry = entries[index]

			row.frame.Visible = entry ~= nil

			if entry then
				setText(row.label, entry.text or "")
				setText(row.time, entry.time or "")
				setColor(row.dot, "BackgroundColor3", entry.dot or THEME.muted)
				setColor(row.label, "TextColor3", entry.dim and THEME.soft or THEME.text)
			end
		end
	end

	return feed
end

---Add empty space.
---@param height number
function Card:AddSpace(height)
	create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(self),
		Size = UDim2.new(1, 0, 0, height),
		Parent = self.body,
	})
end

---Add a frame for custom content.
---@param height number
---@return Frame
function Card:AddFrame(height)
	return create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = addBlock(self),
	})
end

---Show a small outlined badge at the right of the card's header, like "Z5".
---@param value string
function Card:SetBadge(value)
	if not self.badge then
		self.badge = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(0, 21),
			Parent = self.header,
		})

		create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self.badge })
		create("UIStroke", { Color = THEME.accentEdge, Parent = self.badge }).ApplyStrokeMode =
			Enum.ApplyStrokeMode.Border
		pad(self.badge, 0, 7)
		self.badgeText = text(self.badge, "", 12, "display", THEME.accent, {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			TextTruncate = Enum.TextTruncate.None,
		})
		self.header.Size = UDim2.new(1, 0, 0, 21)
	end

	setText(self.badgeText, value)
end

---Show a note at the right of the card's header. Rich text works; Library.hex gives theme colors.
---@param value string
function Card:SetNote(value)
	if not self.noteLabel then
		self.noteLabel = text(self.header, "", 12, "body", THEME.muted, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			RichText = true,
			Size = UDim2.new(0.6, 0, 0, textSize("body", 12)),
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end

	setText(self.noteLabel, value)
end

---Change the card's title.
---@param value string
function Card:SetTitle(value)
	self.title = value
	setText(self.titleLabel, caps(value))
end

---Make an element start a drag of this card, like its header does.
---@param element GuiObject
function Card:AddHandle(element)
	element.Active = true
	element.InputBegan:Connect(function(input)
		if isPress(input) and not self.overButton then
			trackPress(input, {
				begin = function(position, start)
					return beginCardDrag(self, position, start)
				end,
			})
		end
	end)
end

---Check whether this card can be seen right now, so updates can be skipped when it can't.
---@return boolean
function Card:IsVisible()
	return isCardVisible(self)
end

---Float this card over the game.
function Card:PopOut()
	popOut(self)
end

---Put this card back in the window.
function Card:Dock()
	dock(self)
end

---Create a band of columns on a page. Weights set the column widths, such as { 7, 5 }.
---@param weights number[]?
---@return table
function Page:AddRow(weights)
	weights = weights or { 1, 1 }

	local total = 0

	for _, weight in ipairs(weights) do
		total += weight
	end

	local frame = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = #self.rows + 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.holder,
	})

	list(frame, self.gap, true).VerticalAlignment = Enum.VerticalAlignment.Top

	local row = setmetatable({ page = self, columns = {}, frame = frame }, Row)
	local gapShare = self.gap * (#weights - 1)

	for index, weight in ipairs(weights) do
		local column = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Size = UDim2.new(weight / total, -gapShare * weight / total, 0, 0),
			Parent = frame,
		})

		list(column, 0)
		row.columns[index] = column
	end

	self.rows[#self.rows + 1] = row

	return row
end

---List every column on the page, row by row.
---@return Frame[]
function Page:GetColumns()
	local columns = {}

	for _, row in ipairs(self.rows) do
		for _, column in ipairs(row.columns) do
			columns[#columns + 1] = column
		end
	end

	return columns
end

---Add a card to the page's first row. Column 1 is the left.
---@param title string
---@param column number?
---@param options table?
---@return table
function Page:AddCard(title, column, options)
	self.defaultRow = self.defaultRow or self.rows[1] or self:AddRow({ 1, 1 })

	return self.defaultRow:AddCard(title, column, options)
end

---Add a card to a column of this row. Drag its header to move it, or pop it out over the game.
---@param title string
---@param column number?
---@param options table? id, header ("chrome", "quiet" or false), padding { vertical, horizontal }, gap, minHeight, tone
---@return table
function Row:AddCard(title, column, options)
	options = options or {}

	local page = self.page
	local columnIndex = math.clamp(column or 1, 1, #self.columns)
	local container = self.columns[columnIndex]
	local headerMode = options.header

	if headerMode == nil then
		headerMode = page.title and "chrome" or "quiet"
	end

	local chrome = headerMode == "chrome"
	local paddingValues = options.padding or { 14, 16 }
	local gap = options.gap or (chrome and 4 or 10)
	local danger = options.tone == "danger"
	local slot = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = (#listSlots(container) + 1) * 2,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = container,
	})

	slot:SetAttribute("DeepVeinSlot", true)
	pad(slot, 0, 0, page.gap, 0)

	local frame = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = danger and THEME.dangerCard or THEME.card,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = slot,
	})

	glassy[frame] = 0
	frame.BackgroundTransparency = getLook().glass

	local stroke = style(frame, 12, danger and THEME.dangerEdge or THEME.edge)
	local padding = pad(frame, paddingValues[1], paddingValues[2])

	list(frame, gap)

	local minSize = nil

	if options.minHeight then
		-- The minimum applies inside the padding, so the padding comes off first.
		minSize = create("UISizeConstraint", {
			MinSize = Vector2.new(0, options.minHeight - paddingValues[1] * 2),
			Parent = frame,
		})
	end

	-- A second minimum, set when the card stretches to the bottom of the page.
	local stretch = minSize or create("UISizeConstraint", { Parent = frame })

	local header = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, chrome and 28 or textSize("medium", 10)),
		Visible = headerMode ~= false,
		Parent = frame,
	})

	local titleLabel = text(header, caps(title), 10, "medium", THEME.muted, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, chrome and 18 or 0, 0.5, 0),
		Size = UDim2.new(1, chrome and -50 or -40, 0, textSize("medium", 10)),
	})

	local body = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = frame,
	})

	list(body, gap)

	local card = setmetatable({
		id = options.id or (page.name .. "/" .. title),
		title = title,
		page = page,
		defaultRow = self,
		defaultColumn = columnIndex,
		slot = slot,
		frame = frame,
		stroke = stroke,
		padding = padding,
		paddingValues = paddingValues,
		gap = gap,
		header = header,
		headerShown = headerMode ~= false,
		titleLabel = titleLabel,
		body = body,
		minSize = minSize,
		stretch = stretch,
		minHeight = options.minHeight,
		restBackground = danger and THEME.dangerCard or THEME.card,
		restStroke = danger and THEME.dangerEdge or THEME.edge,
		overlays = {},
		toggleKeys = {},
		order = 0,
	}, Card)

	cards[card.id] = card
	slotCards[slot] = card
	page.cards[#page.cards + 1] = card

	-- The pop-out button and grip. Chrome cards show them in the header; quiet cards show them on hover.
	local grip
	local popButton

	if chrome then
		grip = drawGrip(header, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) })
		popButton = iconButton(header, "external-link", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 6, 0.5, 0),
		})
	else
		grip = drawGrip(slot, {
			Position = UDim2.fromOffset(paddingValues[2] - 14, paddingValues[1] - 3),
			ZIndex = 3,
		})

		for _, dot in ipairs(grip:GetChildren()) do
			dot.BackgroundTransparency = 1
		end

		popButton = iconButton(slot, "external-link", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 6),
			Visible = false,
			ZIndex = 3,
		})
		card.overlays = { popButton }
		card:AddHandle(grip)

		local function showChrome(shown)
			if card.pop then
				return
			end

			setGripShown(grip, shown)
			popButton.Visible = shown
		end

		frame.MouseEnter:Connect(function()
			showChrome(true)
		end)

		frame.MouseLeave:Connect(function()
			task.delay(0.05, function()
				if not card.overButton then
					showChrome(false)
				end
			end)
		end)

		popButton.MouseLeave:Connect(function()
			task.delay(0.05, function()
				if not card.overButton then
					showChrome(false)
				end
			end)
		end)
	end

	popButton.MouseEnter:Connect(function()
		card.overButton = true
	end)

	popButton.MouseLeave:Connect(function()
		card.overButton = false
	end)

	popButton.MouseButton1Click:Connect(function()
		card.overButton = false

		if card.pop then
			dock(card)
		else
			popOut(card)
		end
	end)

	card:AddHandle(header)
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		stretchSoon(page)
	end)

	return card
end

---Add a button to the top right of the page, beside the title.
---@param label string
---@param kind string?
---@param callback function
---@return TextButton
function Page:AddAction(label, kind, callback)
	local button = makeButton(self.actions, label, kind or "dangerSoft", callback)

	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 34)
	pad(button, 0, 14)

	return button
end

---Change the line under the page title.
---@param value string
function Page:SetDescription(value)
	self.description = value

	if self.subtitle then
		self.subtitle.Text = value
	end

	updateBadges()
end

---Get or create a rail section.
---@param name string
---@return Frame
local function getSection(name)
	if sections[name] then
		return sections[name]
	end

	local first = #sectionList == 0
	local section = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = #sectionList + 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = ui.sectionHolder,
	})

	list(section, 0)

	local labelTop = first and 6 or 10
	local labelSize = textSize("medium", 10)
	local labelFrame = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, labelTop + labelSize + 4),
		Parent = section,
	})

	text(labelFrame, caps(name), 10, "medium", THEME.muted, {
		Position = UDim2.fromOffset(10, labelTop),
		Size = UDim2.new(1, -20, 0, labelSize),
	})

	sections[name] = section
	sectionList[#sectionList + 1] = section

	return section
end

---Build a tab in the rail.
---@param page table
---@param parent Instance
---@return table
local function buildTab(page, parent)
	local slot = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = (#listSlots(parent) + 1) * 2,
		Size = UDim2.new(1, 0, 0, TAB_HEIGHT + (page.pinned and 0 or TAB_GAP)),
		Parent = parent,
	})

	if not page.pinned then
		slot:SetAttribute("DeepVeinSlot", true)
	end

	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = THEME.inset,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
		Text = "",
		Parent = slot,
	})

	style(button, 9)

	local stroke = create("UIStroke", { Color = THEME.accentEdge, Transparency = 1, Parent = button })

	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local tabIcon = icon(button, page.icon or "star", 16, THEME.soft, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
	})

	local grip = nil

	if not page.pinned then
		grip = drawGrip(button, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
		})

		for _, dot in ipairs(grip:GetChildren()) do
			dot.BackgroundTransparency = 1
		end
	end

	local name = text(button, page.name, 14, "body", THEME.soft, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 38, 0.5, 0),
		Size = UDim2.new(1, -96, 0, textSize("body", 14)),
	})

	local badge = text(button, "", 11, "mono", THEME.accent, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 48, 0, textSize("mono", 11)),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local tab = {
		slot = slot,
		button = button,
		stroke = stroke,
		icon = tabIcon,
		name = name,
		badge = badge,
	}

	button.MouseEnter:Connect(function()
		if page ~= currentPage then
			tween(button, { BackgroundTransparency = 0.3 }, 0.15)
		end

		if grip then
			setGripShown(grip, true)
			tween(badge, { TextTransparency = 1 }, 0.12)
		end
	end)

	button.MouseLeave:Connect(function()
		if page ~= currentPage and not (pointer.drag and pointer.drag.slot == slot) then
			tween(button, { BackgroundTransparency = 1 }, 0.2)
		end

		if grip then
			setGripShown(grip, false)
			tween(badge, { TextTransparency = 0 }, 0.16)
		end
	end)

	addPress(button, 0.97)

	button.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end

		trackPress(input, {
			begin = function(position, start)
				return beginTabDrag(page, position, start)
			end,
			click = function()
				ui.search.Text = ""
				showPage(page.name)
			end,
		})
	end)

	return tab
end

---Add a page with a tab in the rail. Drag the tab to reorder it inside its section.
---@param name string
---@param options table? icon, section, title (false hides the page title), description, gap, padding
---@return table
function Window:AddPage(name, options)
	options = options or {}

	local showTitle = options.title ~= false
	local paddingValue = options.padding or PAGE_PADDING
	local frame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = ui.main,
	})

	local title, subtitle = nil, nil

	if showTitle then
		title = text(frame, name, 26, "display", THEME.text, {
			Position = UDim2.fromOffset(paddingValue, paddingValue),
			Size = UDim2.new(1, -320, 0, 29),
		})
		subtitle = text(frame, options.description or "", 13, "body", THEME.muted, {
			Position = UDim2.fromOffset(paddingValue, paddingValue + 28),
			Size = UDim2.new(1, -320, 0, textSize("body", 13)),
		})
	end

	local actions = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -paddingValue, 0, paddingValue + 14),
		Size = UDim2.fromOffset(300, 34),
		Parent = frame,
	})

	list(actions, 8, true).HorizontalAlignment = Enum.HorizontalAlignment.Right

	local contentTop = showTitle and paddingValue + PAGE_TITLE_HEIGHT or paddingValue
	local scroller = create("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, contentTop),
		ScrollBarImageColor3 = THEME.faint,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = UDim2.new(1, 0, 1, -contentTop),
		Parent = frame,
	})

	-- Side padding inside a scrolling frame moves content without shrinking it, so the holder is inset by hand.
	local holder = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(paddingValue, 0),
		Size = UDim2.new(1, -paddingValue * 2, 0, 0),
		Parent = scroller,
	})

	list(holder, 0)

	local page

	scroller:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
		stretchSoon(page)
	end)

	page = setmetatable({
		name = name,
		icon = options.icon,
		description = options.description or "",
		pinned = options.pinned == true,
		gap = options.gap or 12,
		stretch = options.stretch ~= false,
		bottomPadding = paddingValue,
		frame = frame,
		title = title,
		subtitle = subtitle,
		actions = actions,
		scroller = scroller,
		holder = holder,
		contentTop = contentTop,
		rows = {},
		cards = {},
		toggleKeys = {},
	}, Page)

	page.tab = buildTab(page, page.pinned and ui.pinnedTabs or getSection(options.section or "Automation"))
	pages[name] = page
	pageList[#pageList + 1] = page

	return page
end

---Record the current tab order, card places, floating cards and window size.
---@return table
function captureLayout()
	local layout = { tabs = {}, pages = {}, popped = {} }

	for _, section in ipairs(sectionList) do
		for _, slot in ipairs(listSlots(section)) do
			for _, page in ipairs(pageList) do
				if page.tab.slot == slot then
					table.insert(layout.tabs, page.name)
				end
			end
		end
	end

	for _, page in ipairs(pageList) do
		local rows = {}

		for rowIndex, row in ipairs(page.rows) do
			rows[rowIndex] = {}

			for columnIndex, column in ipairs(row.columns) do
				rows[rowIndex][columnIndex] = {}

				for _, slot in ipairs(listSlots(column)) do
					table.insert(rows[rowIndex][columnIndex], slotCards[slot].id)
				end
			end
		end

		layout.pages[page.name] = rows
	end

	for id, card in pairs(cards) do
		if card.pop then
			local position = card.pop.frame.Position

			layout.popped[id] = { x = position.X.Offset, y = position.Y.Offset, collapsed = card.pop.collapsed }
		end
	end

	layout.width, layout.height = Library.settings.width, Library.settings.height

	return layout
end

---Apply a saved layout. Unknown names are skipped and new cards keep their default place.
---@param layout table
function applyLayout(layout)
	if type(layout) ~= "table" then
		return
	end

	if type(layout.tabs) == "table" then
		local orders, placed = {}, {}

		for _, name in ipairs(layout.tabs) do
			local page = pages[name]

			if page and not page.pinned and not placed[page] then
				local section = page.tab.slot.Parent

				orders[section] = (orders[section] or 0) + 1
				placed[page] = true
				page.tab.slot.LayoutOrder = orders[section] * 2
			end
		end

		for _, page in ipairs(pageList) do
			if not page.pinned and not placed[page] then
				local section = page.tab.slot.Parent

				orders[section] = (orders[section] or 0) + 1
				page.tab.slot.LayoutOrder = orders[section] * 2
			end
		end
	end

	if type(layout.pages) == "table" then
		for _, page in ipairs(pageList) do
			local saved = layout.pages[page.name]

			if type(saved) ~= "table" then
				continue
			end

			local placed, counts = {}, {}

			for rowIndex, savedRow in ipairs(saved) do
				local row = page.rows[rowIndex]

				if not row or type(savedRow) ~= "table" then
					continue
				end

				for columnIndex, ids in ipairs(savedRow) do
					local column = row.columns[columnIndex]

					if not column or type(ids) ~= "table" then
						continue
					end

					for _, id in ipairs(ids) do
						local card = cards[id]

						if card and card.page == page and not placed[card] then
							placed[card] = true
							counts[column] = (counts[column] or 0) + 1
							card.slot.Parent = column
							card.slot.LayoutOrder = counts[column] * 2
						end
					end
				end
			end

			for _, card in ipairs(page.cards) do
				if not placed[card] then
					local column = card.defaultRow.columns[card.defaultColumn]

					counts[column] = (counts[column] or 0) + 1
					card.slot.Parent = column
					card.slot.LayoutOrder = counts[column] * 2
				end
			end
		end
	end

	local popped = type(layout.popped) == "table" and layout.popped or {}

	for id, card in pairs(cards) do
		local entry = popped[id]

		if type(entry) == "table" and type(entry.x) == "number" and type(entry.y) == "number" then
			local position = clampToScreen(Vector2.new(entry.x, entry.y), Vector2.new(DEFAULT_POP_WIDTH, 44))

			if card.pop then
				card.pop.frame.Position = UDim2.fromOffset(position.X, position.Y)
			else
				popOut(card, position)
			end

			if entry.collapsed == true then
				task.defer(setCollapsed, card, true, true)
			end
		elseif card.pop then
			dock(card, true)
		end
	end

	if type(layout.width) == "number" and type(layout.height) == "number" then
		ui.setWindowSize(layout.width, layout.height)
	end
end

---Put every tab and card back where the script placed them.
local function resetLayout()
	local anyFloating = false

	for _, card in pairs(cards) do
		if card.pop then
			anyFloating = true
			dock(card)
		end
	end

	task.delay(anyFloating and 0.32 or 0, function()
		if not Library.running then
			return
		end

		local width, height = Library.settings.width, Library.settings.height

		applyLayout(defaultLayout)
		ui.setWindowSize(width, height)

		if currentPage then
			reveal(currentPage)
		end

		saveLayoutSoon()
	end)
end

---Get the file path of a config.
---@param name string
---@return string
local function configFile(name)
	return string.format("%s/%s.json", paths.configs, name)
end

---Turn a typed name into a safe file name.
---@param name string
---@return string
local function cleanConfigName(name)
	return (string.gsub(string.gsub(name, "[^%w%s_-]", ""), "^%s*(.-)%s*$", "%1"))
end

---List saved configs with how many toggles they turn on and when they were saved.
---@return table[]
local function listConfigs()
	local entries = {}

	if not canSave() or not listfiles then
		return entries
	end

	ensureFolders()

	for _, path in ipairs(listfiles(paths.configs)) do
		local name = string.match(string.gsub(path, "\\", "/"), "([^/]+)%.json$")

		if name then
			local saved = readJson(configFile(name)) or {}
			local on = 0

			for _, value in pairs(type(saved.toggles) == "table" and saved.toggles or {}) do
				on += value == true and 1 or 0
			end

			entries[#entries + 1] = { name = name, on = on, savedAt = tonumber(saved.savedAt) }
		end
	end

	table.sort(entries, function(left, right)
		return left.name < right.name
	end)

	return entries
end

---Describe when a config was saved, like the design: a time today, "yesterday", or a date.
---@param savedAt number?
---@return string
local function describeSaved(savedAt)
	if not savedAt then
		return "saved"
	end

	local today = os.date("*t")
	local saved = os.date("*t", savedAt)

	if saved.year == today.year and saved.yday == today.yday then
		return "saved " .. os.date("%H:%M", savedAt)
	elseif saved.year == today.year and saved.yday == today.yday - 1 then
		return "saved yesterday"
	end

	return "saved " .. string.gsub(os.date("%b %d", savedAt), " 0", " ")
end

---Save the toggles and settings.
---@param name string
---@return boolean
local function saveConfig(name)
	if not canSave() or name == "" then
		return false
	end

	local settings = {}

	-- Window size lives in the layout file, so loading a config never resizes the window.
	for key, value in pairs(Library.settings) do
		if key ~= "width" and key ~= "height" then
			settings[key] = value
		end
	end

	ensureFolders()
	writefile(
		configFile(name),
		httpService:JSONEncode({ toggles = Library.toggles, settings = settings, savedAt = os.time() })
	)
	ui.activeConfig = name
	refreshFooter()

	return true
end

---Copy only known and valid values from a saved config.
---@param saved table
local function applyConfig(saved)
	local settings = Library.settings
	local savedSettings = type(saved.settings) == "table" and saved.settings or {}

	for key, value in pairs(type(saved.toggles) == "table" and saved.toggles or {}) do
		if (toggleKeys[key] or Library.toggles[key] ~= nil) and type(value) == "boolean" then
			Library.toggles[key] = value
		end
	end

	for key, rule in pairs(rules) do
		local value = savedSettings[key]

		if rule.kind == "slider" and type(value) == "number" then
			-- Edited files can hold decimals, which would break the number display.
			settings[key] = math.clamp(math.floor(value), rule.range[1], rule.range[2])
		elseif rule.kind == "single" and table.find(rule.options, value) then
			settings[key] = value
		elseif rule.kind == "multi" and type(value) == "table" then
			local selection = {}

			for _, option in ipairs(rule.options) do
				selection[option] = value[option] == true or nil
			end

			settings[key] = selection
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

	applyAppearance()
	refreshSettings()
end

---Load a saved config.
---@param name string
---@return boolean
local function loadConfig(name)
	local saved = readJson(configFile(name))

	if not saved then
		return false
	end

	applyConfig(saved)
	ui.activeConfig = name
	refreshFooter()

	return true
end

---Get the name of the autoload config.
---@return string?
local function getAutoload()
	if not canSave() or not isfile(paths.autoload) then
		return nil
	end

	local name = readfile(paths.autoload)

	return name ~= "" and name or nil
end

---Show the selected theme, look, key and window size on the Settings page, and redraw every control.
function refreshSettings()
	local settings = Library.settings

	for name, entry in pairs(ui.themeSwatches or {}) do
		local selected = name == settings.theme

		if selected then
			setColor(entry.stroke, "Color", THEME.accent)
		else
			setRawColor(entry.stroke, "Color", Color3.fromHex(THEME_SOURCES[name].edge))
		end

		entry.stroke.Thickness = selected and 2 or 1
	end

	if ui.lookControl then
		ui.lookControl.paint()
	end

	if ui.keyChip then
		ui.keyChip.Text = settings.key == "RightShift" and "RShift" or settings.key
	end

	if ui.sizeLabel then
		ui.sizeLabel.Text = string.format("%d × %d", settings.width, settings.height)
	end

	refreshFooter()
	repaintAll()
end

---Show a short message under the config list.
---@param value string
local function setConfigNote(value)
	ui.configNote.Text = value
	ui.configNote.Parent.Parent.Visible = value ~= ""
end

---Rebuild the saved config list.
function refreshConfigList()
	for _, child in ipairs(ui.configList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local entries = listConfigs()
	local autoload = getAutoload()
	local names = {}

	ui.autoloadName = autoload

	for _, entry in ipairs(entries) do
		names[#names + 1] = entry.name
	end

	if not table.find(names, ui.selectedConfig) then
		ui.selectedConfig = nil
	end

	for order, entry in ipairs(entries) do
		local selected = entry.name == ui.selectedConfig
		local row = create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = selected and THEME.accentBg or THEME.inset,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 46),
			Text = "",
			Parent = ui.configList,
		})

		style(row, 10, selected and THEME.accentEdge or THEME.edge)
		addPress(row, 0.98)
		icon(row, selected and "circle-dot" or "circle", 14, selected and THEME.accent or THEME.muted, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
		})

		local nameSize, subSize = textSize("medium", 14), textSize("body", 11)
		local top = math.floor((46 - nameSize - subSize) / 2) + 2

		text(row, entry.name, 14, "medium", THEME.text, {
			Position = UDim2.fromOffset(36, top),
			Size = UDim2.new(1, -130, 0, nameSize),
		})
		text(row, string.format("%d toggles · %s", entry.on, describeSaved(entry.savedAt)), 11, "body", THEME.muted, {
			Position = UDim2.fromOffset(36, top + nameSize - 4),
			Size = UDim2.new(1, -130, 0, subSize),
		})

		if entry.name == autoload then
			local badge = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = THEME.accent,
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(0, textSize("bold", 10)),
				Parent = row,
			})

			create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = badge })
			pad(badge, 0, 6)
			text(badge, caps("Autoload"), 10, "bold", THEME.accentInk, {
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				TextTruncate = Enum.TextTruncate.None,
			})
		end

		row.MouseButton1Click:Connect(function()
			ui.selectedConfig = entry.name
			ui.configName.Text = entry.name
			refreshConfigList()
		end)
	end

	ui.configEmpty.Parent.Parent.Visible = #entries == 0

	if ui.autoloadButton then
		local isAutoload = ui.selectedConfig ~= nil and ui.selectedConfig == autoload

		ui.autoloadButton.Text = isAutoload and "Clear autoload" or "Set autoload"
	end

	refreshFooter()
end

---Build one settings row: a label on the left, controls on the right. Returns the right side.
---@param card table
---@param title string
---@param sub string?
---@return Frame
local function settingsRow(card, title, sub)
	local titleSize = textSize("body", 14)
	local subSize = sub and textSize("body", 12) or 0
	local height = math.max(30, titleSize + subSize - 4)
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = addBlock(card, { gap = 0 }),
	})

	local top = math.floor((height - titleSize - (sub and subSize - 4 or 0)) / 2)

	text(row, title, 14, "body", THEME.text, {
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(0.5, 0, 0, titleSize),
	})

	if sub then
		text(row, sub, 12, "body", THEME.muted, {
			Position = UDim2.fromOffset(0, top + titleSize - 4),
			Size = UDim2.new(0.75, 0, 0, subSize),
		})
	end

	local right = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 30),
		Parent = row,
	})

	list(right, 8, true).HorizontalAlignment = Enum.HorizontalAlignment.Right

	return right
end

---Build a small outlined button for settings rows.
---@param parent Instance
---@param label string
---@param order number
---@param callback function
---@return TextButton
local function smallButton(parent, label, order, callback)
	local button = makeButton(parent, label, "ghost", callback, 30)

	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.fromOffset(0, 30)
	button.LayoutOrder = order
	button:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 8)
	pad(button, 0, 12)

	return button
end

---Build the Settings page, matching the design.
---@param window table
local function buildSettings(window)
	local settingsPage = window:AddPage("Settings", { icon = "settings", pinned = true, title = false })
	local row = settingsPage:AddRow({ 1, 1 })

	-- Theme swatches show each theme's own rail, edge and accent.
	local theme = row:AddCard("Theme", 1, { id = "DeepVein/Theme" })

	theme:SetNote("Named after ores")

	local grid = theme:AddFrame(4 * 46 + 3 * 8)

	create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8),
		CellSize = UDim2.new(0.5, -4, 0, 46),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	ui.themeSwatches = {}

	for order, name in ipairs(THEME_ORDER) do
		local source = THEME_SOURCES[name]
		local swatch = create("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromHex(source.window),
			LayoutOrder = order,
			Text = "",
			Parent = grid,
		})

		style(swatch, 10)

		local stroke = create("UIStroke", { Color = Color3.fromHex(source.edge), Parent = swatch })

		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local stripes = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(27, 22),
			Parent = swatch,
		})

		for index, color in ipairs({ source.rail, source.stripe, source.accent }) do
			local stripe = create("Frame", {
				BackgroundColor3 = Color3.fromHex(color),
				Position = UDim2.fromOffset((index - 1) * 9, 0),
				Size = UDim2.fromOffset(9, 22),
				Parent = stripes,
			})

			if index ~= 2 then
				create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = stripe })
				create("Frame", {
					BackgroundColor3 = Color3.fromHex(color),
					Position = UDim2.fromOffset(index == 1 and 4 or 0, 0),
					Size = UDim2.fromOffset(5, 22),
					Parent = stripe,
				})
			end
		end

		local label = text(swatch, name, 13, "medium", THEME.text, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 47, 0.5, 0),
			Size = UDim2.new(1, -52, 0, textSize("medium", 13)),
		})

		setRawColor(label, "TextColor3", Color3.fromHex(source.text))
		ui.themeSwatches[name] = { stroke = stroke }
		addPress(swatch)
		swatch.MouseButton1Click:Connect(function()
			Library.settings.theme = name
			applyAppearance()
			refreshSettings()
		end)
	end

	local look = row:AddCard("Look", 1, { id = "DeepVein/Look" })

	ui.lookControl = look:AddSegmented("look", nil, LOOK_ORDER, Library.settings.look, function()
		applyAppearance()
	end)

	local windowCard = row:AddCard("Window", 1, { id = "DeepVein/Window" })
	local keyRow = settingsRow(windowCard, "Hide key")
	local chip = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = THEME.deep,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 26),
		Parent = keyRow,
	})

	style(chip, 7, THEME.buttonEdge)
	pad(chip, 0, 10)

	-- The thicker bottom edge makes it look like a key.
	local keyEdge = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = THEME.buttonEdge,
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.new(1, 18, 0, 3),
		ZIndex = 0,
		Parent = chip,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = keyEdge })

	ui.keyChip = text(chip, "RShift", 13, "mono", THEME.text, {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		TextTruncate = Enum.TextTruncate.None,
	})

	smallButton(keyRow, "Change", 2, function()
		ui.capturingKey = true
		ui.keyChip.Text = "Press a key"
	end)

	local sizeRow = settingsRow(windowCard, "Window size")

	ui.sizeLabel = text(sizeRow, "", 13, "mono", THEME.soft, {
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
		Size = UDim2.new(0, 0, 1, 0),
		TextTruncate = Enum.TextTruncate.None,
	})

	smallButton(sizeRow, "Reset", 2, function()
		ui.setWindowSize(DEFAULT_SIZE.X, DEFAULT_SIZE.Y)
		refreshSettings()
		saveLayoutSoon()
	end)

	local layoutRow = settingsRow(windowCard, "Layout", "Tab order, card order, popped-out cards")

	smallButton(layoutRow, "Reset", 1, resetLayout)

	local configs = row:AddCard("Configs", 2, { id = "DeepVein/Configs" })
	local inputRow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = addBlock(configs),
	})

	list(inputRow, 8, true)

	ui.configName = create("TextBox", {
		BackgroundColor3 = THEME.deep,
		ClearTextOnFocus = false,
		FontFace = FONTS.body,
		LayoutOrder = 1,
		PlaceholderColor3 = THEME.muted,
		PlaceholderText = "Name a new config",
		Size = UDim2.new(1, -70, 0, 36),
		Text = "",
		TextColor3 = THEME.text,
		TextSize = textSize("body", 13),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = inputRow,
	})

	style(ui.configName, 9, THEME.buttonEdge)
	pad(ui.configName, 0, 12)

	local saveButton = makeButton(inputRow, "Save", "primary", function()
		local name = cleanConfigName(ui.configName.Text)

		if saveConfig(name) then
			ui.selectedConfig = name
			setConfigNote("")
			refreshConfigList()
		else
			setConfigNote("Type a config name first.")
		end
	end, 36)

	saveButton.LayoutOrder = 2
	saveButton.Size = UDim2.fromOffset(62, 36)

	local listHolder = configs:AddFrame(0)

	listHolder.AutomaticSize = Enum.AutomaticSize.Y
	ui.configList = listHolder
	list(listHolder, 6)

	ui.configEmpty = configs:AddText("No saved configs yet.", { color = THEME.muted, size = 12 })
	ui.configNote = configs:AddText("", { color = THEME.muted, size = 12 })
	ui.configNote.Parent.Parent.Visible = false

	local firstRow = configs:AddButtonRow()

	firstRow:AddButton("Load", function()
		local name = ui.selectedConfig

		if not name then
			setConfigNote("Pick a config first.")
		elseif loadConfig(name) then
			setConfigNote("")
		else
			setConfigNote("Could not read " .. name)
		end
	end, "text")

	firstRow:AddButton("Overwrite", function()
		local name = ui.selectedConfig

		if name and saveConfig(name) then
			setConfigNote("")
			refreshConfigList()
		else
			setConfigNote("Pick a config first.")
		end
	end, "text")

	local secondRow = configs:AddButtonRow()

	ui.autoloadButton = secondRow:AddButton("Set autoload", function()
		local name = ui.selectedConfig

		if not name then
			setConfigNote("Pick a config first.")

			return
		end

		ensureFolders()
		writefile(paths.autoload, getAutoload() == name and "" or name)
		setConfigNote("")
		refreshConfigList()
	end, "text")

	secondRow:AddButton("Delete", function()
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
			writefile(paths.autoload, "")
		end

		if ui.activeConfig == name then
			ui.activeConfig = nil
		end

		ui.selectedConfig = nil
		ui.configName.Text = ""
		setConfigNote("")
		refreshConfigList()
	end, "danger")

	if not canSave() then
		setConfigNote("This executor cannot save files.")
	end

	local unload = row:AddCard("Unload", 2, { id = "DeepVein/Unload", header = false, tone = "danger" })
	local unloadRow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		Parent = addBlock(unload, { gap = 0 }),
	})

	local titleSize, subSize = textSize("medium", 14), textSize("body", 12)
	local titleTop = math.floor((38 - titleSize - subSize + 4) / 2)
	local unloadTitle = text(unloadRow, "Unload script", 14, "medium", THEME.dangerTitle, {
		Position = UDim2.fromOffset(0, titleTop),
		Size = UDim2.new(1, -110, 0, titleSize),
	})

	text(unloadRow, "Stops every loop and closes this window.", 12, "body", THEME.dangerSub, {
		Position = UDim2.fromOffset(0, titleTop + titleSize - 4),
		Size = UDim2.new(1, -110, 0, subSize),
	})

	local unloadButton = makeButton(unloadRow, "Unload", "dangerSolid", function()
		window:Destroy()
	end, 36)

	unloadButton.AnchorPoint = Vector2.new(1, 0.5)
	unloadButton.Position = UDim2.new(1, 0, 0.5, 0)
	unloadButton.Size = UDim2.fromOffset(72, 36)
	unload:AddHandle(unloadTitle)
end

---Get the screen area below the Roblox top bar, where the window lives.
---@return Vector2
local function getScreenArea()
	local inset = game:GetService("GuiService"):GetGuiInset()

	return workspace.CurrentCamera.ViewportSize - inset
end

---Work out how far to shrink the window to fit the screen.
---@return number
local function computeScale()
	local settings = Library.settings

	return math.min(1, ui.viewport.X * 0.94 / settings.width, ui.viewport.Y * 0.94 / settings.height)
end

---Build the window frame: header, rail, page area, footer and the layers above them.
---@param options table
local function buildWindow(options)
	local settings = Library.settings
	local title = options.title or "Script"

	screenGui = create("ScreenGui", {
		Name = "DeepVein",
		DisplayOrder = 20,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = gethui and gethui() or coreGui,
	})

	ui.iconAsset = loadIcons()
	ui.viewport = getScreenArea()
	ui.scale = computeScale()
	ui.windowShown = true
	ui.minimized = false

	local window = create("Frame", {
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.window,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(settings.width, settings.height),
		Parent = screenGui,
	})

	glassy[window] = 0
	style(window, 14, THEME.edge)
	ui.window = window
	ui.windowScale = create("UIScale", { Scale = ui.scale * 0.94, Parent = window })

	-- Header.
	local header = create("Frame", {
		Active = true,
		BackgroundColor3 = THEME.header,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		ZIndex = 2,
		Parent = window,
	})

	glassy[header] = 0
	style(header, 14)
	create("Frame", {
		BackgroundColor3 = THEME.header,
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = header,
	})
	create("Frame", {
		BackgroundColor3 = THEME.line,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = header,
	})

	icon(header, "gem", 26, THEME.accent, { Position = UDim2.fromOffset(20, 19) })
	text(header, caps(title), 17, "display", THEME.text, {
		Position = UDim2.fromOffset(56, 16),
		Size = UDim2.fromOffset(BRAND_WIDTH - 36, 17),
	})
	text(header, options.subtitle or "", 11, "body", THEME.muted, {
		Position = UDim2.fromOffset(56, 35),
		Size = UDim2.fromOffset(BRAND_WIDTH - 36, 14),
	})

	local searchFrame = create("Frame", {
		BackgroundColor3 = THEME.field,
		Position = UDim2.fromOffset(20 + BRAND_WIDTH + 16, 13),
		Size = UDim2.new(1, -560, 0, 38),
		Parent = header,
	})

	local searchStroke = style(searchFrame, 10, THEME.edge)

	icon(searchFrame, "search", 15, THEME.muted, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
	})

	local search = create("TextBox", {
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		FontFace = FONTS.body,
		PlaceholderColor3 = THEME.muted,
		PlaceholderText = "Search toggles and settings",
		Position = UDim2.fromOffset(39, 0),
		Size = UDim2.new(1, -78, 1, 0),
		Text = "",
		TextColor3 = THEME.text,
		TextSize = textSize("body", 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = searchFrame,
	})

	local slash = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(20, 18),
		Parent = searchFrame,
	})

	style(slash, 5, THEME.buttonEdge)
	text(slash, "/", 11, "mono", THEME.muted, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	ui.search = search

	search.Focused:Connect(function()
		fadeColor(searchStroke, "Color", THEME.accentEdge)
	end)

	search.FocusLost:Connect(function()
		fadeColor(searchStroke, "Color", THEME.edge)
	end)

	local right = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(0, 34),
		Parent = header,
	})

	list(right, 16, true).HorizontalAlignment = Enum.HorizontalAlignment.Right

	---Give the search box whatever width the right side leaves.
	local function fitSearch()
		local used = right.AbsoluteSize.X / math.max(ui.windowScale.Scale, 0.01)

		searchFrame.Size = UDim2.new(1, -(20 + BRAND_WIDTH + 16 + used + 16 + 16), 0, 38)
	end

	right:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSearch)

	local stat = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 34),
		Visible = false,
		Parent = right,
	})

	pad(stat, 0, 4)

	local statLayout = list(stat, 0)

	statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	statLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	ui.stat = stat
	ui.statName = text(stat, "", 10, "medium", THEME.muted, {
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 12),
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	ui.statValue = text(stat, "", 17, "monoBold", THEME.gold, {
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 20),
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local status = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = THEME.field,
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 30),
		Parent = right,
	})

	pill(status)
	pad(status, 0, 12)
	list(status, 7, true)
	ui.status = status
	ui.statusStroke = create("UIStroke", { Color = THEME.edge, Parent = status })
	ui.statusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ui.statusDot = create("Frame", {
		BackgroundColor3 = THEME.faint,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(8, 8),
		Parent = status,
	})

	pill(ui.statusDot)
	ui.statusGlow = create("UIStroke", { Color = THEME.accent, Thickness = 3, Transparency = 1, Parent = ui.statusDot })
	ui.statusText = text(status, "Idle", 13, "medium", THEME.soft, {
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 30),
		TextTruncate = Enum.TextTruncate.None,
	})

	local controls = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.fromOffset(68, 32),
		Parent = right,
	})

	list(controls, 4, true)

	local minimizeButton = iconButton(controls, "minus", { LayoutOrder = 1, Size = UDim2.fromOffset(32, 32) })
	local closeButton = iconButton(controls, "x", { LayoutOrder = 2, Size = UDim2.fromOffset(32, 32) })

	minimizeButton:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 8)
	closeButton:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 8)

	minimizeButton.MouseButton1Click:Connect(function()
		ui.setMinimized(not ui.minimized)
	end)

	closeButton.MouseButton1Click:Connect(function()
		ui.setWindowVisible(false)
	end)

	-- Rail.
	local rail = create("Frame", {
		BackgroundColor3 = THEME.rail,
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Size = UDim2.new(0, RAIL_WIDTH, 1, -HEADER_HEIGHT - FOOTER_HEIGHT),
		Parent = window,
	})

	glassy[rail] = 0
	create("Frame", {
		BackgroundColor3 = THEME.line,
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		Parent = rail,
	})

	ui.sectionHolder = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 14),
		Size = UDim2.new(1, -24, 0, 0),
		Parent = rail,
	})

	list(ui.sectionHolder, 0)

	ui.pinnedTabs = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 1, -(14 + 54 + 6 + TAB_HEIGHT)),
		Size = UDim2.new(1, -24, 0, TAB_HEIGHT),
		Parent = rail,
	})

	list(ui.pinnedTabs, 0)

	local profile = create("Frame", {
		BackgroundColor3 = THEME.inset,
		Position = UDim2.new(0, 12, 1, -(14 + 54)),
		Size = UDim2.new(1, -24, 0, 54),
		Parent = rail,
	})

	style(profile, 10, THEME.line)

	local localPlayer = playersService.LocalPlayer
	local playerName = localPlayer and localPlayer.Name or "Player"
	local avatar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = THEME.accentAvatar,
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		Parent = profile,
	})

	pill(avatar)

	-- The design's initials, like "CS" for ChillSato37: the capitals in the name, or its first two letters.
	local initials = string.gsub(playerName, "[^%u]", "")

	initials = #initials >= 2 and string.sub(initials, 1, 2) or string.upper(string.sub(playerName, 1, 2))

	text(avatar, initials, 13, "display", THEME.accent, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local nameSize, lineSize = textSize("medium", 13), textSize("body", 11)
	local nameTop = math.floor((54 - nameSize - lineSize + 4) / 2)

	text(profile, playerName, 13, "medium", THEME.text, {
		Position = UDim2.fromOffset(52, nameTop),
		Size = UDim2.new(1, -58, 0, nameSize),
	})
	ui.profileLine = text(profile, "", 11, "body", THEME.muted, {
		Position = UDim2.fromOffset(52, nameTop + nameSize - 4),
		Size = UDim2.new(1, -58, 0, lineSize),
	})

	-- Page area.
	ui.main = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(RAIL_WIDTH, HEADER_HEIGHT),
		Size = UDim2.new(1, -RAIL_WIDTH, 1, -HEADER_HEIGHT - FOOTER_HEIGHT),
		Parent = window,
	})

	-- Footer.
	local footer = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = THEME.header,
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, FOOTER_HEIGHT),
		Parent = window,
	})

	glassy[footer] = 0
	create("Frame", {
		BackgroundColor3 = THEME.line,
		Size = UDim2.new(1, 0, 0, 1),
		Parent = footer,
	})

	local footerRow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = footer,
	})

	pad(footerRow, 0, 16)
	list(footerRow, 14, true)

	local keyGroup = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 18),
		Parent = footerRow,
	})

	list(keyGroup, 4, true)

	local keyChip = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 16),
		Parent = keyGroup,
	})

	style(keyChip, 4, THEME.buttonEdge)
	pad(keyChip, 0, 5)
	ui.footerKey = text(keyChip, "RShift", 11, "mono", THEME.soft, {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		TextTruncate = Enum.TextTruncate.None,
	})
	text(keyGroup, "hide", 11, "body", THEME.muted, {
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Size = UDim2.new(0, 0, 1, 0),
		TextTruncate = Enum.TextTruncate.None,
	})
	ui.footerConfig = text(footerRow, "Config: none", 11, "body", THEME.muted, {
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		RichText = true,
		Size = UDim2.fromOffset(0, 18),
		TextTruncate = Enum.TextTruncate.None,
	})
	ui.footerRight = text(footer, "", 11, "body", THEME.muted, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(240, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- Resize grip in the bottom right corner.
	local grip = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(14, 14),
		Text = "",
		ZIndex = 5,
		Parent = window,
	})

	for _, offset in ipairs({ { 10, 10 }, { 10, 6 }, { 6, 10 }, { 10, 2 }, { 6, 6 }, { 2, 10 } }) do
		create("Frame", {
			BackgroundColor3 = THEME.faint,
			Position = UDim2.fromOffset(offset[1], offset[2]),
			Size = UDim2.fromOffset(2, 2),
			Parent = grip,
		})
	end

	-- Dragged tabs and cards ride above everything else in the window.
	ui.dragLayer = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = window,
	})

	-- Floating cards live outside the window so they stay up while it is hidden.
	ui.popLayer = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = screenGui,
	})

	local reopen = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = THEME.window,
		Position = UDim2.fromOffset(-200, 20),
		Size = UDim2.fromOffset(170, 40),
		Text = "",
		Visible = false,
		ZIndex = 6,
		Parent = screenGui,
	})

	style(reopen, 10, THEME.edge)
	hover(reopen, THEME.window, THEME.card)
	addPress(reopen)
	icon(reopen, "gem", 18, THEME.accent, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
	})
	text(reopen, caps(title), 13, "display", THEME.text, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 38, 0.5, 0),
		Size = UDim2.new(1, -46, 0, 18),
	})

	reopen.MouseButton1Click:Connect(function()
		ui.setWindowVisible(true)
	end)

	---Show or hide the window. Floating cards stay where they are.
	---@param visible boolean
	function ui.setWindowVisible(visible)
		if ui.windowShown == visible then
			return
		end

		ui.windowShown = visible

		if visible then
			window.Visible = true
			ui.windowScale.Scale = ui.scale * 0.94
			tween(ui.windowScale, { Scale = ui.scale }, 0.34, Enum.EasingStyle.Back)
			tween(reopen, { Position = UDim2.fromOffset(-200, 20) }, 0.2)

			task.delay(0.2, function()
				if ui.windowShown then
					reopen.Visible = false
				end
			end)
		else
			tween(ui.windowScale, { Scale = ui.scale * 0.92 }, 0.14)
			reopen.Visible = true
			tween(reopen, { Position = UDim2.fromOffset(20, 20) }, 0.36, Enum.EasingStyle.Back)

			task.delay(0.14, function()
				if not ui.windowShown then
					window.Visible = false
				end
			end)
		end
	end

	---Hide or show everything, including floating cards.
	local function toggleEverything()
		local shown = ui.windowShown or ui.popLayer.Visible

		ui.popLayer.Visible = not shown
		ui.setWindowVisible(not shown)

		if shown then
			reopen.Visible = false
		end
	end

	---Resize the window within the allowed limits.
	---@param width number
	---@param height number
	function ui.setWindowSize(width, height)
		local maxWidth = math.max(MIN_WINDOW_SIZE.X, ui.viewport.X / ui.scale)
		local maxHeight = math.max(MIN_WINDOW_SIZE.Y, ui.viewport.Y / ui.scale)

		settings.width = math.clamp(math.floor(width), MIN_WINDOW_SIZE.X, maxWidth)
		settings.height = math.clamp(math.floor(height), MIN_WINDOW_SIZE.Y, maxHeight)

		if not ui.minimized then
			window.Size = UDim2.fromOffset(settings.width, settings.height)
		end

		if ui.sizeLabel then
			ui.sizeLabel.Text = string.format("%d × %d", settings.width, settings.height)
		end
	end

	---Fold the window down to its header, or open it again.
	---@param minimized boolean
	function ui.setMinimized(minimized)
		ui.minimized = minimized
		grip.Visible = not minimized
		tween(window, { Size = UDim2.fromOffset(settings.width, minimized and HEADER_HEIGHT or settings.height) }, 0.32)
	end

	header.InputBegan:Connect(function(input)
		if not isPress(input) or pointer.drag or search:IsFocused() then
			return
		end

		local start = inputPosition(input)
		local origin = window.Position

		pointer.drag = {
			move = function(position)
				local delta = position - start
				local viewport = ui.viewport
				local halfHeight = window.AbsoluteSize.Y / 2
				local x = math.clamp(origin.X.Offset + delta.X, -viewport.X / 2, viewport.X / 2)
				local topLimit = math.min(halfHeight - viewport.Y / 2, 0)
				local y = math.clamp(origin.Y.Offset + delta.Y, topLimit, math.max(topLimit, viewport.Y / 2))

				window.Position = UDim2.new(0.5, x, 0.5, y)
			end,
			finish = function() end,
		}
	end)

	grip.InputBegan:Connect(function(input)
		if not isPress(input) or pointer.drag then
			return
		end

		local start = inputPosition(input)
		local startWidth, startHeight = settings.width, settings.height
		local startPosition = window.Position

		pointer.drag = {
			move = function(position)
				local delta = position - start

				ui.setWindowSize(startWidth + delta.X / ui.scale, startHeight + delta.Y / ui.scale)

				-- The window is centered on its position, so move it to keep the top-left corner still.
				window.Position = startPosition
					+ UDim2.fromOffset(
						(settings.width - startWidth) * ui.scale / 2,
						(settings.height - startHeight) * ui.scale / 2
					)
			end,
			finish = function()
				saveLayoutSoon()
			end,
		}
	end)

	search:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(search.Text)
		local firstMatch = nil

		for _, row in ipairs(searchRows) do
			local matches = query == "" or string.find(row.text, query, 1, true) ~= nil

			row.frame.Visible = matches
			firstMatch = firstMatch or (matches and query ~= "" and row.page)
		end

		if firstMatch then
			showPage(firstMatch.name)
		end
	end)

	connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
		ui.viewport = getScreenArea()
		ui.scale = computeScale()
		ui.windowScale.Scale = ui.scale
		ui.setWindowSize(settings.width, settings.height)
		stretchSoon(currentPage)

		for _, card in pairs(cards) do
			if card.pop then
				card.pop.scale.Scale = ui.scale
			end
		end
	end)

	connect(userInputService.InputChanged, function(input)
		if not isMove(input) then
			return
		end

		local position = inputPosition(input)
		local pending = pointer.pending

		pointer.position = position

		if pending and (position - pending.start).Magnitude >= DRAG_THRESHOLD then
			pointer.pending = nil
			pointer.drag = pending.handlers.begin and pending.handlers.begin(position, pending.start) or nil
		end

		if pointer.drag then
			pointer.drag.move(position)
		end
	end)

	connect(userInputService.InputEnded, function(input)
		if not isPress(input) then
			return
		end

		local pending, drag = pointer.pending, pointer.drag

		pointer.pending, pointer.drag = nil, nil

		if pending and pending.handlers.click then
			safeCall("Click", pending.handlers.click)
		end

		if drag then
			safeCall("Drop", drag.finish, inputPosition(input))
		end
	end)

	connect(userInputService.InputBegan, function(input, processed)
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
			toggleEverything()
		elseif not processed and input.KeyCode == Enum.KeyCode.Slash and ui.windowShown then
			task.defer(function()
				search:CaptureFocus()
			end)
		end
	end)

	task.defer(fitSearch)
end

---Show a status in the header pill. Active lights it up and makes the dot glow.
---@param value string
---@param active boolean
function Window:SetStatus(value, active)
	setText(ui.statusText, value)

	if ui.statusActive == active then
		return
	end

	ui.statusActive = active
	fadeColor(ui.status, "BackgroundColor3", active and THEME.accentBg or THEME.field, 0.3)
	fadeColor(ui.statusStroke, "Color", active and THEME.accentEdge or THEME.edge, 0.3)
	fadeColor(ui.statusText, "TextColor3", active and THEME.accentText or THEME.soft, 0.3)
	fadeColor(ui.statusDot, "BackgroundColor3", active and THEME.accent or THEME.faint, 0.3)

	if ui.pulse then
		ui.pulse:Cancel()
		ui.pulse = nil
	end

	ui.statusGlow.Transparency = 1

	if active then
		local info = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

		ui.statusGlow.Transparency = 0.55
		ui.pulse = tweenService:Create(ui.statusGlow, info, { Transparency = 0.9 })
		ui.pulse:Play()
	end
end

---Show a named number in the header, such as cash.
---@param name string
---@param value string
function Window:SetStat(name, value)
	ui.stat.Visible = true
	setText(ui.statName, caps(name))
	setText(ui.statValue, value)
end

---Set the second line of the profile card in the rail.
---@param value string
function Window:SetProfile(value)
	setText(ui.profileLine, value)
end

---Check whether a page is on screen.
---@param name string
---@return boolean
function Window:IsPageVisible(name)
	return ui.windowShown and not ui.minimized and currentPage ~= nil and currentPage.name == name
end

---Turn every toggle off.
function Window:DisableAll()
	for key in pairs(toggleKeys) do
		setToggle(key, false)
	end
end

---Set a toggle from the script, updating every row bound to it.
---@param key string
---@param enabled boolean
function Window:SetToggle(key, enabled)
	setToggle(key, enabled)
end

---Open a page by name.
---@param name string
function Window:ShowPage(name)
	showPage(name)
end

---Finish building: add Settings, restore the saved layout, open the first tab and load the autoload config.
---Call this last. Returns the name of the config it loaded, if any.
---@return string?
function Window:Ready()
	buildSettings(self)
	defaultLayout = captureLayout()

	local saved = readJson(paths.layout)

	if saved then
		applyLayout(saved)
	end

	refreshSettings()
	refreshConfigList()

	for _, section in ipairs(sectionList) do
		local first = listSlots(section)[1]

		for _, page in ipairs(pageList) do
			if page.tab.slot == first and not currentPage then
				showPage(page.name)
			end
		end
	end

	updateBadges()
	tween(ui.windowScale, { Scale = ui.scale }, 0.38, Enum.EasingStyle.Back)

	local autoload = getAutoload()

	if autoload and loadConfig(autoload) then
		refreshConfigList()

		return autoload
	end

	refreshFooter()

	return nil
end

---Remove the window and stop everything. Calls Library.onUnload once.
function Window:Destroy()
	if not Library.running then
		return
	end

	Library.running = false
	pointer.pending, pointer.drag = nil, nil

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	table.clear(connections)

	if ui.pulse then
		ui.pulse:Cancel()
	end

	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end

	safeCall("onUnload", Library.onUnload)
end

---Create the window. Only one window per loaded copy of the library.
---@param options table? title, subtitle, configFolder, toggles, settings, theme, look, key
---@return table
function Library.new(options)
	options = options or {}

	local folder = options.configFolder or "DeepVein"

	paths.folder = folder
	paths.configs = folder .. "/configs"
	paths.autoload = folder .. "/autoload.txt"
	paths.layout = folder .. "/layout.json"

	-- Scripts can pass their own tables, so their loops read values without going through the library.
	Library.toggles = options.toggles or Library.toggles
	Library.settings = options.settings or Library.settings

	local settings = Library.settings

	settings.theme = THEMES[settings.theme] and settings.theme
		or (THEMES[options.theme] and options.theme or "Obsidian")
	settings.look = LOOKS[settings.look] and settings.look or (LOOKS[options.look] and options.look or "Soft")
	settings.key = type(settings.key) == "string" and settings.key or options.key or "RightShift"
	settings.width = DEFAULT_SIZE.X
	settings.height = DEFAULT_SIZE.Y
	Library.running = true

	buildWindow(options)

	return setmetatable({}, Window)
end

-- Shared helpers for scripts.
Library.setText = setText
Library.setBar = setBar
Library.setColor = setColor
Library.fadeColor = fadeColor
Library.caps = caps
Library.theme = THEME
Library.fonts = FONTS

---Get a theme color as a hex string, for rich text.
---@param token string
---@return string
function Library.hex(token)
	return hexOf(token)
end

Library.helpers = {
	create = create,
	text = text,
	icon = icon,
	style = style,
	tween = tween,
	hover = hover,
	addPress = addPress,
	textSize = textSize,
}

-- Return Library module.
return Library
end)()

-- Game modules.
local Shared = replicatedStorage.Shared
local Client = replicatedStorage.Client
local Remotes = replicatedStorage:WaitForChild("Remotes")
local PlayerState = require(Client.Core.PlayerState)
local BossTimer = require(Client.UI.World.BossTimer)
local LocalEnemyRegistry = require(Client.Core.LocalEnemyRegistry)
local BaseConfig = require(Shared.Config.BaseConfig)
local CardStats = require(Shared.Rules.CardStats)
local CosmeticConfig = require(Shared.Config.CosmeticConfig)
local EnemyConfig = require(Shared.Config.EnemyConfig)
local PackConfig = require(Shared.Config.PackConfig)
local PlaceConfig = require(Shared.Config.PlaceConfig)
local PowerConfig = require(Shared.Config.PowerConfig)
local Progression = require(Shared.Rules.Progression)
local AbilityConfig = require(Shared.Config.AbilityConfig)
local AbilityScaling = require(Shared.Rules.AbilityScaling)
local ZoneConfig = require(Shared.Config.ZoneConfig)
local Big = require(Shared.Util.Big)
local Daily = require(Shared.Rules.Daily)
local ForeverPack = require(Shared.Rules.ForeverPack)
local CardIndex = require(Shared.Rules.CardIndex)
local Format = require(Shared.Util.Format)

-- Local player.
local localPlayer = playersService.LocalPlayer

-- The window.
local window = nil

-- Labels the refresh loop updates.
local ui = {}

-- Connections cut on unload.
local connections = {}

-- Original BossTimer functions, restored on unload.
local oldBossTimerShow, oldBossTimerHide = nil, nil

-- Original local enemy damage function, restored on unload.
local oldEnemyDamage = nil

-- Last time our own attack landed on each enemy model.
local ourHits = setmetatable({}, { __mode = "k" })

-- Last time the server paid out a kill.
local lastRewardAt = 0

-- Server time each boss pad respawns, by pad id.
local bossRespawnAt = {}

-- Map catalog for the current world.
local catalog = { zones = {}, zoneOrder = {}, bossPads = {}, pads = {} }

-- Display name to id lookups for the menu chips.
local bossIdByName, zoneGateByName = {}, {}

-- What the brain is doing, shown on the Home page.
local session = { startedAt = os.clock(), mode = "Idle", target = "—", bossKills = 0, mobKills = 0, packsOpened = 0, dodges = 0 }

-- Brain state.
local brain = {
	bossPad = nil,
	bossArrivedAt = 0,
	bossEngagedAt = 0,
	bossStartHealth = 0,
	bossModel = nil,
	bankAfter = nil,
	bankStartedAt = nil,
	lastLiftTry = 0,
	lastPlaceBest = 0,
	holdCFrame = nil,
	lastDodge = 0,
	lastInstaKill = 0,
	holdArena = nil,
}

-- Next allowed time for each action key.
local cooldowns = {}

-- Newest activity lines first.
local activity = {}

---Add a line to the activity feed.
---@param text string
---@param dot string?
local function logActivity(text, dot)
	table.insert(activity, 1, { text = text, time = os.date("%H:%M:%S"), dot = dot or "muted", dim = dot == nil })
	activity[MAX_ACTIVITY_LINES + 1] = nil
end

---Get the player's data.
---@return table?
local function getData()
	return PlayerState.Data
end

---Get the character parts used for movement.
---@return Humanoid?, BasePart?
local function getBody()
	local character = localPlayer.Character
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return nil, nil
	end

	return humanoid, rootPart
end

---Check an action cooldown.
---@param key string
---@return boolean
local function isReady(key)
	return os.clock() >= (cooldowns[key] or 0)
end

---Block an action for a while.
---@param key string
---@param seconds number
local function backOff(key, seconds)
	cooldowns[key] = os.clock() + seconds
end

---Call a RemoteFunction, unless this copy of the script has been unloaded.
---@param name string
---@vararg any
---@return boolean, any
local function invoke(name, ...)
	if not AutoFarm.running then
		return false, nil
	end

	local remote = Remotes:FindFirstChild(name)
	if not remote then
		logActivity("Missing remote " .. name, "dangerText")
		return false, nil
	end

	local arguments = table.pack(...)
	local success, result, message = pcall(function()
		return remote:InvokeServer(table.unpack(arguments, 1, arguments.n))
	end)

	if not success then
		warn(string.format("[SuperpowerFarm] %s failed: %s", name, tostring(result)))
		return false, nil
	end

	return result ~= nil and result ~= false, result, message
end

---Fire a RemoteEvent, unless this copy of the script has been unloaded.
---@param name string
---@vararg any
local function fire(name, ...)
	if not AutoFarm.running then
		return
	end

	local remote = Remotes:FindFirstChild(name)
	if remote then
		remote:FireServer(...)
	end
end

---Format a big number the way the game does.
---@param value any
---@return string
local function short(value)
	local success, text = pcall(Format.Short, value)
	return success and text or tostring(value)
end

---Check that spending an amount stays inside the spend limit.
---@param data table
---@param price any
---@return boolean
local function canSpend(data, price)
	local cash = Big.toNumber(data.Cash)
	local limit = cash * math.clamp(AutoFarm.settings.spendLimit or 50, 1, 100) / 100

	return Big.ge(data.Cash, price) and Big.toNumber(price) <= limit
end

---Get the player's base plot.
---@return Model?
local function getPlot()
	local bases = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Bases")
	if not bases then
		return nil
	end

	for _, plot in ipairs(bases:GetChildren()) do
		if plot:GetAttribute("Owner") == localPlayer.UserId then
			return plot
		end
	end

	return nil
end

---Get the zone display name for a gate.
---@param gate string
---@return string
local function zoneName(gate)
	local zone = ZoneConfig[gate] or ZoneConfig["Stage" .. gate]
	return zone and zone.Name or gate
end

---Get the display name for an enemy type.
---@param enemyId string
---@return string
local function enemyName(enemyId)
	local enemyType = EnemyConfig.Types[enemyId]
	local name = enemyType and enemyType.Name or enemyId

	-- World 2 names all end the same way, which cut them off in the chips.
	return (string.gsub(name, " of the Federation$", ""))
end

---Build the zone and boss catalog from the current world's enemy pads.
local function buildCatalog()
	local pads = {}
	local folder = replicatedStorage:FindFirstChild("EnemyPads")

	for _, pad in ipairs(folder and folder:GetChildren() or {}) do
		local id = tonumber(pad.Name)
		local enemyId = pad:GetAttribute("Enemy")
		local enemyType = EnemyConfig.Types[enemyId]
		local padCFrame = pad:GetAttribute("PadCFrame")

		if id and enemyType and typeof(padCFrame) == "CFrame" then
			pads[#pads + 1] = {
				id = id,
				enemy = enemyId,
				boss = enemyType.Boss == true,
				gate = pad:GetAttribute("Gate"),
				level = pad:GetAttribute("Level") or 1,
				respawn = pad:GetAttribute("RespawnTime") or enemyType.RespawnTime or 8,
				cframe = padCFrame,
				arenaCFrame = pad:GetAttribute("ArenaCFrame"),
				arenaSize = pad:GetAttribute("ArenaSize"),
				zoneMinZ = pad:GetAttribute("ZoneMinZ"),
				zoneMaxZ = pad:GetAttribute("ZoneMaxZ"),
			}
		end
	end

	table.sort(pads, function(left, right)
		return left.id < right.id
	end)

	-- Pads that share a ZoneMinZ/ZoneMaxZ range belong to one zone, guarded by its boss.
	local groups, groupOrder = {}, {}

	for _, pad in ipairs(pads) do
		local key = pad.zoneMinZ and pad.zoneMaxZ and (pad.zoneMinZ .. "|" .. pad.zoneMaxZ) or "none"
		local group = groups[key]

		if not group then
			group = { key = key, maxZ = pad.zoneMaxZ or 0, minZ = pad.zoneMinZ, mobs = {}, boss = nil }
			groups[key] = group
			groupOrder[#groupOrder + 1] = group
		end

		if pad.boss and pad.gate then
			group.boss = pad
		else
			table.insert(group.mobs, pad)
		end
	end

	-- Zones run away from spawn, so the nearest range comes first.
	table.sort(groupOrder, function(left, right)
		return left.maxZ > right.maxZ
	end)

	local zones, order, bossPads = {}, {}, {}

	for _, group in ipairs(groupOrder) do
		local boss = group.boss

		if boss then
			-- A zone without an arena box gets one built from its range.
			if typeof(boss.arenaCFrame) ~= "CFrame" and group.minZ then
				boss.arenaCFrame = CFrame.new(0, boss.cframe.Y + ARENA_FALLBACK_HEIGHT / 2, (group.minZ + group.maxZ) / 2)
				boss.arenaSize = Vector3.new(ARENA_FALLBACK_WIDTH, ARENA_FALLBACK_HEIGHT, group.maxZ - group.minZ)
			end

			for _, mob in ipairs(group.mobs) do
				if typeof(mob.arenaCFrame) ~= "CFrame" then
					mob.arenaCFrame, mob.arenaSize = boss.arenaCFrame, boss.arenaSize
				end
			end

			zones[boss.gate] = { gate = boss.gate, name = zoneName(boss.gate), mobs = group.mobs, boss = boss }
			order[#order + 1] = boss.gate
			bossPads[boss.enemy] = boss
		end
	end

	local byId = {}

	for _, pad in ipairs(pads) do
		byId[pad.id] = pad
	end

	catalog = { zones = zones, zoneOrder = order, bossPads = bossPads, pads = byId }
end

---Check whether a boss pad has its boss up, as far as this client knows.
---@param pad table
---@return boolean
local function bossReady(pad)
	local respawnAt = bossRespawnAt[pad.id]
	return not respawnAt or workspace:GetServerTimeNow() >= respawnAt
end

---Get seconds until a boss respawns.
---@param pad table
---@return number
local function bossWait(pad)
	local respawnAt = bossRespawnAt[pad.id]
	return respawnAt and math.max(0, respawnAt - workspace:GetServerTimeNow()) or 0
end

---Get the living enemy models on a set of pads.
---@param padIds table<number, boolean>
---@return Model[]
local function livingEnemies(padIds)
	local folder = workspace:FindFirstChild("Enemies")
	local found = {}

	for _, model in ipairs(folder and folder:GetChildren() or {}) do
		local root = model:FindFirstChild("HumanoidRootPart")
		local humanoid = model:FindFirstChildOfClass("Humanoid")

		if root and humanoid and humanoid.Health > 0 and padIds[model:GetAttribute("PadId")]
			and not model:GetAttribute("Dead") and not model:GetAttribute("DeadLocal") then
			found[#found + 1] = model
		end
	end

	return found
end

---Get the range of the equipped card's primary attack.
---@return number
local function attackRange()
	local data = getData()
	local card = data and data.Equipped and data.Equipped[1]
	local abilityId = card and AbilityConfig.PrimaryFor(card)
	local ability = abilityId and AbilityConfig.Get(abilityId)

	if not ability then
		return 10
	end

	local success, scaling = pcall(AbilityScaling.FromData, data, card, abilityId)
	return (ability.Range or 10) * (success and scaling and scaling.Size or 1)
end

---Get the arena box for an enemy model's pad.
---@param model Model
---@return CFrame?, Vector3?
local function arenaOf(model)
	local pad = catalog.pads[model:GetAttribute("PadId")]

	if pad and typeof(pad.arenaCFrame) == "CFrame" and typeof(pad.arenaSize) == "Vector3" then
		return pad.arenaCFrame, pad.arenaSize
	end

	return nil, nil
end

---Keep a position inside an arena box, away from its walls.
---@param position Vector3
---@param arena table?
---@return Vector3
local function clampToArena(position, arena)
	if not arena then
		return position
	end

	local half = arena.size / 2 - Vector3.new(ARENA_MARGIN, 0, ARENA_MARGIN)
	local relative = arena.cframe:PointToObjectSpace(position)
	local clamped = Vector3.new(
		math.clamp(relative.X, -math.max(half.X, 0), math.max(half.X, 0)),
		relative.Y,
		math.clamp(relative.Z, -math.max(half.Z, 0), math.max(half.Z, 0))
	)

	return arena.cframe:PointToWorldSpace(clamped)
end

---Pick a spot a little above the ground beside the enemy, on the arena side, inside our attack range.
---@param model Model
---@return CFrame?, table?
local function hoverFor(model)
	local enemyRoot = model:FindFirstChild("HumanoidRootPart")
	if not enemyRoot then
		return nil, nil
	end

	local reach = math.max(MIN_TARGET_DISTANCE, attackRange() * TARGET_RANGE_SHARE)
	local distance = math.clamp(AutoFarm.settings.targetDistance or 30, MIN_TARGET_DISTANCE, reach)
	local height = AutoFarm.settings.floatHeight or 8
	local arenaCFrame, arenaSize = arenaOf(model)
	local arena = arenaCFrame and { cframe = arenaCFrame, size = arenaSize }

	-- Standing toward the arena's middle keeps walls from coming between us and the target.
	local center = arenaCFrame and arenaCFrame.Position or enemyRoot.Position + Vector3.new(1, 0, 0)
	local flat = (center - enemyRoot.Position) * Vector3.new(1, 0, 1)
	local direction = flat.Magnitude > 1 and flat.Unit or Vector3.new(1, 0, 0)
	local position = clampToArena(enemyRoot.Position + direction * distance + Vector3.new(0, height, 0), arena)

	return CFrame.new(position), arena
end

---Hold the character at a spot every frame. Pass nil to let go.
---@param cframe CFrame?
---@param arena table? the box the character must stay inside
local function holdAt(cframe, arena)
	brain.holdCFrame = cframe
	brain.holdArena = arena
end

---Push a position out of every enemy attack telegraph on the ground.
---@param position Vector3
---@return Vector3, boolean
local function escapeTelegraphs(position)
	local folder = workspace:FindFirstChild("_EnemyTelegraphs")
	if not folder then
		return position, false
	end

	local moved = false

	for _ = 1, DODGE_PASSES do
		local pushed = false

		for _, part in ipairs(folder:GetDescendants()) do
			if part:IsA("BasePart") and part.Transparency < 1 then
				-- Telegraphs are flat, so the two largest sides give the footprint.
				local size = part.Size
				local sides = { size.X, size.Y, size.Z }

				table.sort(sides)

				local radius = sides[3] / 2 + DODGE_MARGIN
				local flat = (position - part.Position) * Vector3.new(1, 0, 1)

				if flat.Magnitude < radius then
					local direction = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(1, 0, 0)
					local ground = Vector3.new(part.Position.X, position.Y, part.Position.Z)

					position = ground + direction * radius
					pushed, moved = true, true
				end
			end
		end

		if not pushed then
			break
		end
	end

	return position, moved
end

---Keep the character on its held spot, keeping the facing the game sets when it aims.
local function holdStep()
	local cframe = brain.holdCFrame
	if not cframe then
		return
	end

	local _, rootPart = getBody()
	if not rootPart or rootPart.Anchored then
		return
	end

	local position = cframe.Position

	if AutoFarm.toggles.DodgeAttacks then
		local dodged

		position, dodged = escapeTelegraphs(position)

		if dodged and os.clock() - brain.lastDodge > DODGE_LOG_COOLDOWN then
			session.dodges += 1
		end

		brain.lastDodge = dodged and os.clock() or brain.lastDodge
	end

	position = clampToArena(position, brain.holdArena)

	local facing = rootPart.CFrame - rootPart.CFrame.Position
	rootPart.CFrame = CFrame.new(position) * facing
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

---Teleport the character.
---@param cframe CFrame
local function teleport(cframe)
	local humanoid, rootPart = getBody()
	if not rootPart then
		return
	end

	if humanoid.Sit then
		humanoid.Sit = false
	end

	rootPart.CFrame = cframe
	rootPart.AssemblyLinearVelocity = Vector3.zero
end

---Check whether the server has us on the bench.
---@return boolean
local function isLifting()
	return localPlayer:GetAttribute("Lifting") == true or localPlayer:GetAttribute("LiftingLocal") == true
end

---Get off the bench the way the game's jump does.
local function stopLift()
	if not isLifting() then
		return
	end

	fire("BenchStop")
	localPlayer:SetAttribute("LiftingLocal", nil)

	-- The game pins the character to the bench until the server clears Lifting, which undoes teleports.
	local startedAt = os.clock()

	while localPlayer:GetAttribute("Lifting") == true and os.clock() - startedAt < STOP_LIFT_TIMEOUT do
		task.wait(0.05)
	end

	local _, rootPart = getBody()
	if rootPart then
		rootPart.Anchored = false
	end
end

---Press a proximity prompt from beside it.
---@param prompt ProximityPrompt
---@return boolean
local function pressPrompt(prompt)
	local _, rootPart = getBody()
	local part = prompt and prompt.Parent

	if not rootPart or not part or not part:IsA("BasePart") or not prompt.Enabled then
		return false
	end

	holdAt(nil)

	for _ = 1, 3 do
		teleport(CFrame.new(part.Position + Vector3.new(0, 3, 0)))
		task.wait(PROMPT_SETTLE)

		if (rootPart.Position - part.Position).Magnitude <= prompt.MaxActivationDistance then
			break
		end
	end

	if (rootPart.Position - part.Position).Magnitude > prompt.MaxActivationDistance then
		logActivity("Could not reach " .. prompt.Name, "dangerText")
		return false
	end

	prompt:InputHoldBegin()
	task.wait(prompt.HoldDuration + 0.05)
	prompt:InputHoldEnd()

	return true
end

---Lie on the bench so the server starts giving training power.
local function startLift()
	if isLifting() or os.clock() - brain.lastLiftTry < LIFT_RETRY then
		return
	end

	local plot = getPlot()
	local liePoint = plot and plot:FindFirstChild("LiePoint", true)
	local prompt = plot and plot:FindFirstChild("LiftPrompt", true)

	if not liePoint or not prompt then
		return
	end

	brain.lastLiftTry = os.clock()
	holdAt(nil)
	teleport(liePoint.CFrame)
	task.wait(PROMPT_SETTLE)

	local _, rootPart = getBody()
	if rootPart and (rootPart.Position - liePoint.Position).Magnitude <= LIFT_REACH then
		prompt:InputHoldBegin()
		task.wait(0.05)
		prompt:InputHoldEnd()
	end
end

---Count the packs on our back.
---@return number
local function carriedPacks()
	local carried = localPlayer:GetAttribute("CarriedPacks")
	if type(carried) ~= "string" or carried == "" then
		return 0
	end

	local count = 0

	for _ in string.gmatch(carried, "[^,]+") do
		count += 1
	end

	return count
end

---Teleport home the way the boss portal does.
local function goHome()
	local baseSpawn = localPlayer:GetAttribute("BaseSpawn")
	local character = localPlayer.Character

	if typeof(baseSpawn) ~= "CFrame" or not character then
		return
	end

	stopLift()
	holdAt(nil)
	character:PivotTo(baseSpawn)
	fire("TeleportHome")
end

---Get seconds until the first selected boss in this world respawns.
---@return number?
local function soonestBossWait()
	local picked = AutoFarm.settings["bosses" .. PlaceConfig.World] or {}
	local soonest = nil

	for _, gate in ipairs(catalog.zoneOrder) do
		local pad = catalog.zones[gate].boss

		if picked[enemyName(pad.enemy)] then
			soonest = math.min(soonest or math.huge, bossWait(pad))
		end
	end

	return soonest
end

---Save toggles and settings so the next server picks up where this one stopped.
local function saveHopState()
	if not writefile then
		return
	end

	pcall(function()
		if not isfolder("StealASuperpower") then
			makefolder("StealASuperpower")
		end

		writefile(HOP_STATE_FILE, httpService:JSONEncode({
			at = os.time(),
			toggles = AutoFarm.toggles,
			settings = AutoFarm.settings,
		}))
	end)
end

---Load the state saved before a server hop, if it is recent.
local function loadHopState()
	if not isfile or not isfile(HOP_STATE_FILE) then
		return
	end

	local success, state = pcall(function()
		return httpService:JSONDecode(readfile(HOP_STATE_FILE))
	end)

	pcall(delfile, HOP_STATE_FILE)

	if not success or type(state) ~= "table" or os.time() - (state.at or 0) > HOP_STATE_MAX_AGE then
		return
	end

	for key, value in pairs(state.toggles or {}) do
		if AutoFarm.toggles[key] ~= nil then
			AutoFarm.toggles[key] = value
		end
	end

	for key, value in pairs(state.settings or {}) do
		AutoFarm.settings[key] = value
	end

	session.hopped = true
end

---Join a different public server of this place and run the script again there.
local function hopServer()
	local queue = queue_on_teleport or (syn and syn.queue_on_teleport)

	if not queue then
		logActivity("Server hop needs queue_on_teleport", "dangerText")
		backOff("hop", HOP_RETRY)
		return
	end

	local success, body = pcall(game.HttpGet, game, string.format(SERVER_LIST_URL, game.PlaceId))
	local list = success and select(2, pcall(httpService.JSONDecode, httpService, body))
	local servers = {}

	for _, server in ipairs(type(list) == "table" and list.data or {}) do
		if server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 0) then
			servers[#servers + 1] = server.id
		end
	end

	if #servers == 0 then
		logActivity("No other server to hop to", "dangerText")
		backOff("hop", HOP_RETRY)
		return
	end

	saveHopState()
	queue(HOP_LOADER)
	logActivity("Hopping servers for fresh bosses", "accent")
	backOff("hop", HOP_RETRY)
	teleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], localPlayer)
end

---Check whether a card change on the base is waiting.
---@return boolean
local function placeBestPending()
	local data = getData()
	if not data then
		return false
	end

	local success, _, changed, count = pcall(BaseConfig.BestHolders, data)
	return success and changed == true and (count or 0) > 0
end

---Press the base's Place Best button.
local function placeBest()
	local plot = getPlot()
	local prompt = plot and plot:FindFirstChild("BestPrompt", true)

	brain.lastPlaceBest = os.clock()

	if not prompt then
		return
	end

	stopLift()

	if pressPrompt(prompt) then
		task.wait(REPLY_WAIT)

		if placeBestPending() then
			logActivity("Place Best did not change the base")
		else
			logActivity("Placed best cards on the base", "accent")
		end
	end
end

---Fight a boss pad: wait for the boss, stand off, and let the game's auto attack hit it.
---@param pad table
---@param rootPart BasePart
local function fightBoss(pad, rootPart)
	if brain.bossPad ~= pad then
		brain.bossPad = pad
		brain.bossArrivedAt = os.clock()
		brain.bossModel = nil
		session.target = enemyName(pad.enemy)
	end

	local model = brain.bossModel

	if model and not model.Parent and not model:GetAttribute("Dead") then
		-- The boss despawned without dying, usually because we left its area.
		model = nil
		brain.bossModel = nil
	end

	if not model or model:GetAttribute("Dead") or model:GetAttribute("DeadLocal") then
		if model then
			-- The boss we were fighting died.
			session.bossKills += 1
			logActivity("Killed " .. enemyName(pad.enemy), "gold")
			brain.bossModel = nil
			brain.bossPad = nil

			if AutoFarm.toggles.AutoBank then
				brain.bankAfter = os.clock() + PACK_SETTLE_TIME
			end

			return
		end

		model = livingEnemies({ [pad.id] = true })[1]
		brain.bossModel = model

		if model then
			brain.bossEngagedAt = os.clock()
			brain.bossStartHealth = model:FindFirstChildOfClass("Humanoid").Health
		end
	end

	local humanoid = model and model:FindFirstChildOfClass("Humanoid")

	-- Once our own hit has landed, the server accepts the kill, so finish the boss through the game's damage path.
	---@note: On bosses with huge health a weak hit is below number precision, so Health never visibly drops; ourHits sees the hit instead.
	local firstHit = ourHits[model]
	local serverSaw = firstHit and os.clock() - firstHit >= INSTA_KILL_DELAY + localPlayer:GetNetworkPing() * 2

	if AutoFarm.toggles.InstaKillBosses and humanoid and serverSaw and LocalEnemyRegistry.Damage
		and os.clock() - brain.lastInstaKill > INSTA_KILL_COOLDOWN then
		local killedAt = os.clock()
		local name = enemyName(pad.enemy)

		brain.lastInstaKill = killedAt
		LocalEnemyRegistry.Damage(model, humanoid.Health * EnemyConfig.HealthUnit(model) * INSTA_KILL_OVERKILL)

		task.delay(INSTA_KILL_CONFIRM_TIME, function()
			if AutoFarm.running and lastRewardAt < killedAt then
				logActivity("No reward for insta-killing " .. name, "dangerText")
			end
		end)
	end

	-- Skip bosses we can't dent, and train instead.

	if humanoid and os.clock() - brain.bossEngagedAt > BOSS_GIVE_UP_TIME then
		local lost = (brain.bossStartHealth - humanoid.Health) / math.max(humanoid.MaxHealth, 1)

		if lost < BOSS_MIN_DAMAGE_SHARE then
			logActivity(enemyName(pad.enemy) .. " is too strong, skipping for 5 min", "dangerText")
			bossRespawnAt[pad.id] = workspace:GetServerTimeNow() + BOSS_TOO_STRONG_COOLDOWN
			brain.bossPad = nil
			brain.bossModel = nil

			return
		end

		brain.bossEngagedAt = os.clock()
		brain.bossStartHealth = humanoid.Health
	end

	if not model then
		-- Bosses only spawn while we are near the pad.
		holdAt(pad.cframe + Vector3.new(0, 3, 40))

		if os.clock() - brain.bossArrivedAt > BOSS_SPAWN_WAIT then
			bossRespawnAt[pad.id] = workspace:GetServerTimeNow() + BOSS_NO_SHOW_COOLDOWN
			brain.bossPad = nil
		end

		return
	end

	local spot, arena = hoverFor(model)

	if spot then
		holdAt(spot, arena)
	else
		brain.bossModel = nil
	end
end

---Farm the mobs of a zone.
---@param zone table
---@param rootPart BasePart
local function farmZone(zone, rootPart)
	local padIds = {}

	for _, pad in ipairs(zone.mobs) do
		padIds[pad.id] = true
	end

	local enemies = livingEnemies(padIds)
	local nearest, best = nil, math.huge

	for _, model in ipairs(enemies) do
		local enemyRoot = model:FindFirstChild("HumanoidRootPart")
		local distance = enemyRoot and (enemyRoot.Position - rootPart.Position).Magnitude or math.huge

		if distance < best then
			nearest, best = model, distance
		end
	end

	session.target = zone.name

	local spot, arena = nearest and hoverFor(nearest)

	if spot then
		holdAt(spot, arena)
		return
	end

	-- Nothing alive yet: wait in the middle of the zone so every pad can spawn.
	local middle = Vector3.zero

	for _, pad in ipairs(zone.mobs) do
		middle += pad.cframe.Position
	end

	middle /= math.max(#zone.mobs, 1)
	holdAt(CFrame.new(middle + Vector3.new(0, AutoFarm.settings.floatHeight or 8, 0)))
end

---Pick the first selected boss that is up.
---@return table?
local function readyBoss()
	if not AutoFarm.toggles.BossFarm then
		return nil
	end

	local picked = AutoFarm.settings["bosses" .. PlaceConfig.World] or {}

	for _, gate in ipairs(catalog.zoneOrder) do
		local pad = catalog.zones[gate].boss

		if picked[enemyName(pad.enemy)] and bossReady(pad) then
			return pad
		end
	end

	return nil
end

---Get the selected zone in this world.
---@return table?
local function selectedZone()
	local name = AutoFarm.settings["zone" .. PlaceConfig.World]
	local gate = name and zoneGateByName[name]
	return gate and catalog.zones[gate]
end

---Set the mode shown on Home.
---@param mode string
---@param target string?
local function setMode(mode, target)
	session.mode = mode
	session.target = target or session.target
end

---Decide what the character does this tick.
local function brainStep()
	local _, rootPart = getBody()
	if not rootPart then
		holdAt(nil)
		setMode("Waiting for character", "—")
		return
	end

	-- Bank packs after a boss kill or when full.
	local carrying = carriedPacks()
	local capacity = tonumber(localPlayer:GetAttribute("CarryCapacity")) or 5

	if brain.bankAfter and os.clock() >= brain.bankAfter
		or AutoFarm.toggles.AutoBank and carrying >= capacity and not brain.bankStartedAt then
		brain.bankAfter = nil
		brain.bankStartedAt = os.clock()
		setMode("Banking packs", carrying .. " packs")
		goHome()
		return
	end

	-- Dropped packs are still flying to us, so stay put until they land.
	if brain.bankAfter then
		setMode("Collecting packs", carrying .. " packs")
		return
	end

	if brain.bankStartedAt then
		if carriedPacks() == 0 or os.clock() - brain.bankStartedAt > BANK_TIMEOUT then
			brain.bankStartedAt = nil

			if carrying > 0 then
				logActivity("Banked packs at home", "gold")
			end
		else
			return
		end
	end

	-- Base errands run between fights.
	if AutoFarm.toggles.AutoCards and os.clock() - brain.lastPlaceBest > PLACE_BEST_COOLDOWN and placeBestPending() then
		setMode("Placing best cards", "Base")
		placeBest()
		return
	end

	local boss = brain.bossPad or readyBoss()

	if boss and AutoFarm.toggles.BossFarm then
		stopLift()
		setMode("Boss farm", enemyName(boss.enemy))
		fightBoss(boss, rootPart)
		return
	end

	brain.bossPad = nil

	-- Every picked boss is respawning here, so a fresh server is faster than waiting.
	if AutoFarm.toggles.ServerHop and AutoFarm.toggles.BossFarm and carrying == 0 and isReady("hop")
		and os.clock() - session.startedAt > HOP_MIN_STAY then
		local wait = soonestBossWait()

		if wait and wait > HOP_MIN_WAIT then
			setMode("Server hop", "New server")
			stopLift()
			hopServer()
			return
		end
	end

	local zone = AutoFarm.toggles.ZoneFarm and selectedZone()

	if zone then
		stopLift()
		setMode("Zone farm", zone.name)
		farmZone(zone, rootPart)
		return
	end

	holdAt(nil)

	if AutoFarm.toggles.AutoTrain then
		setMode(isLifting() and "Training" or "Going to bench", "Bench")
		startLift()
		return
	end

	setMode("Idle", "—")
end

---Buy the selected stat upgrades.
---@param data table
local function buyUpgrades(data)
	local picked = AutoFarm.settings.upgradeIds or {}

	for _, upgrade in ipairs(Progression.Upgrades) do
		local level = Progression.UpgradeLevel(data, upgrade.Id)
		local key = "upgrade" .. upgrade.Id

		if picked[upgrade.Name] and level < upgrade.MaxLevel and isReady(key) then
			local price = Progression.UpgradePrice(data, upgrade.Id, level)

			if canSpend(data, price) then
				invoke("BuyUpgrade", upgrade.Id)
				task.wait(REPLY_WAIT)

				local after = getData()

				if after and Progression.UpgradeLevel(after, upgrade.Id) > level then
					logActivity(string.format("%s to level %d", upgrade.Name, level + 1), "accent")
				else
					backOff(key, RETRY_COOLDOWN)
				end
			end
		end
	end
end

---Upgrade the bench while it is affordable.
---@param data table
local function upgradeBench(data)
	local level = data.Base and data.Base.Bench or 1

	if level >= BaseConfig.BenchMaxLevel or not isReady("bench") then
		return
	end

	if not canSpend(data, BaseConfig.BenchCost(level)) then
		return
	end

	fire("BenchUpgrade")
	task.wait(REPLY_WAIT)

	local after = getData()

	if after and after.Base.Bench > level then
		logActivity("Bench to level " .. after.Base.Bench, "accent")
	else
		backOff("bench", RETRY_COOLDOWN)
	end
end

---Rebirth once the power level reaches the requirement.
---@param data table
local function tryRebirth(data)
	local rebirths = data.Rebirths or 0
	local needed = Progression.RebirthLevelRequirement(rebirths)

	if PowerConfig.Level(data.Power or 0) < needed or not isReady("rebirth") then
		return
	end

	invoke("Rebirth")
	task.wait(REPLY_WAIT * 2)

	local after = getData()

	if after and (after.Rebirths or 0) > rebirths then
		logActivity("Rebirthed to " .. after.Rebirths, "gold")
	else
		backOff("rebirth", RETRY_COOLDOWN)
	end
end

---Buy selected potions from the rotating shelf.
---@param data table
local function buyPotions(data)
	local types = AutoFarm.settings.potionTypes or {}
	local tiers = AutoFarm.settings.potionTiers or {}
	local slot = CosmeticConfig.PotionShelf(data, workspace:GetServerTimeNow())
	local shelf = CosmeticConfig.PotionStock(localPlayer.UserId, slot)

	for _, item in ipairs(shelf) do
		local key = "potion" .. slot .. item.Type.Id .. item.Tier.Tier

		if types[item.Type.Name] and tiers[item.Tier.Numeral] and isReady(key)
			and CosmeticConfig.PotionLeft(data, item, slot) > 0 and canSpend(data, item.Tier.Price) then
			local before = CosmeticConfig.PotionLeft(data, item, slot)

			invoke("BuyCosmetic", "Potion", item.Type.Id, item.Tier.Tier)
			task.wait(REPLY_WAIT)

			local after = getData()

			if after and CosmeticConfig.PotionLeft(after, item, slot) < before then
				logActivity(string.format("Bought %s %s", item.Type.Name, item.Tier.Numeral), "accent")
			else
				backOff(key, RETRY_COOLDOWN)
			end
		end
	end
end

---Get how strong a cosmetic is: auras multiply, trails add speed.
---@param item table
---@return number
local function cosmeticStrength(item)
	return item.Multiplier or item.Speed or 0
end

---Buy or equip the strongest aura or trail this world sells.
---@param data table
---@param kindName string "Aura" or "Trail"
local function buyCosmetic(data, kindName)
	local kind = CosmeticConfig.Kinds[kindName]
	local owned = data[kind.Owned] or {}
	local equipped = kind.ById[data[kind.Equipped] or ""]
	local bestOwned, bestBuy = equipped, nil

	for _, item in ipairs(kind.Items) do
		local strength = cosmeticStrength(item)

		if owned[item.Id] then
			if not bestOwned or strength > cosmeticStrength(bestOwned) then
				bestOwned = item
			end
		elseif (item.World or 1) == PlaceConfig.World and not item.RobuxOnly and (item.Price or 0) > 0 then
			if (not bestBuy or strength > cosmeticStrength(bestBuy)) and canSpend(data, CosmeticConfig.PriceFor(data, kindName, item)) then
				bestBuy = item
			end
		end
	end

	local buyKey = kindName .. (bestBuy and bestBuy.Id or "")

	if bestBuy and (not bestOwned or cosmeticStrength(bestBuy) > cosmeticStrength(bestOwned)) and isReady(buyKey) then
		invoke("BuyCosmetic", kindName, bestBuy.Id)
		task.wait(REPLY_WAIT)

		local after = getData()

		if after and (after[kind.Owned] or {})[bestBuy.Id] then
			logActivity("Bought " .. bestBuy.Name, "gold")
		else
			backOff(buyKey, RETRY_COOLDOWN)
		end

		return
	end

	if bestOwned and bestOwned ~= equipped and isReady(kindName .. "Equip") then
		invoke("EquipCosmetic", kindName, bestOwned.Id)
		backOff(kindName .. "Equip", RETRY_COOLDOWN)
		logActivity("Equipped " .. bestOwned.Name, "accent")
	end
end

---Claim one free reward and confirm it with a field that changes when it lands.
---@param key string
---@param label string
---@param remote string
---@param changed function returns true once the claim shows in the data
---@vararg any
local function claimReward(key, label, remote, changed, ...)
	if not isReady(key) then
		return
	end

	invoke(remote, ...)
	task.wait(REPLY_WAIT * 2)

	local after = getData()

	if after and changed(after) then
		logActivity("Claimed " .. label, "gold")
	else
		backOff(key, CLAIM_RETRY)
	end
end

---Claim the daily reward, free Forever Pack steps, index rewards and offline cash.
---@param data table
local function claimRewards(data)
	local now = workspace:GetServerTimeNow()

	if Daily.Ready(data, now) then
		local days = data.Daily and data.Daily.Last

		claimReward("daily", "daily reward", "DailyClaim", function(after)
			return (after.Daily and after.Daily.Last) ~= days
		end)
	end

	local step = ForeverPack.Step(data)
	local success, reward = pcall(ForeverPack.Get, step, data, localPlayer.UserId)

	if success and reward and reward.Free then
		claimReward("forever" .. step, "Forever Pack step " .. step, "ForeverClaim", function(after)
			return ForeverPack.Step(after) > step
		end, step)
	end

	for _, section in ipairs(CardIndex.Sections) do
		if section.Reward and CardIndex.CanClaim(data, section.Rarity) then
			claimReward("index" .. section.Rarity, section.Rarity .. " index reward", "ClaimIndex", function(after)
				return after.IndexClaims and after.IndexClaims[section.Rarity] ~= nil
			end, section.Rarity)
		end
	end

	if data.Offline and Big.gt(data.Offline.Pending or 0, 0) then
		claimReward("offline", "offline cash", "OfflineCollect", function(after)
			return not (after.Offline and Big.gt(after.Offline.Pending or 0, 0))
		end)
	end
end

---Run the spending jobs.
local function economyStep()
	local toggles = AutoFarm.toggles

	if toggles.AutoUpgrades and getData() then
		buyUpgrades(getData())
	end

	if toggles.AutoUpgrades and (AutoFarm.settings.upgradeIds or {})[BENCH_UPGRADE] and getData() then
		upgradeBench(getData())
	end

	if toggles.AutoPotions and getData() then
		buyPotions(getData())
	end

	if toggles.AutoAuras and getData() then
		buyCosmetic(getData(), "Aura")
		buyCosmetic(getData(), "Trail")
	end

	if toggles.AutoClaim and getData() then
		claimRewards(getData())
	end

	if toggles.AutoRebirth and getData() then
		tryRebirth(getData())
	end
end

---Open the selected packs without the opening animation.
---@param data table
local function openPacks(data)
	local picked = AutoFarm.settings.openPacks or {}
	local perCall = math.clamp(math.floor(AutoFarm.settings.openCount or MAX_OPEN_PER_CALL), 1, math.min(MAX_OPEN_PER_CALL, PackConfig.MaxOpenAtOnce))

	for packId, count in pairs(data.Packs or {}) do
		local key = "open" .. packId

		if picked[packId] and count > 0 and isReady(key) then
			local amount = math.min(count, perCall)
			-- The game's own open button calls this same remote; the animation is only client side.
			local opened, result = invoke("OpenPack", packId, amount)

			if opened and type(result) == "table" then
				session.packsOpened += amount
				logActivity(string.format("Opened %d %s pack%s", amount, packId, amount == 1 and "" or "s"), "gold")
				fire("PackRevealDone")
			else
				backOff(key, RETRY_COOLDOWN)
			end

			task.wait(OPEN_DELAY)
			return
		end
	end
end

---Merge every card stack that can be merged.
---@param data table
local function mergeCards(data)
	local success, _, count = pcall(CardStats.FuseAll, data.Cards)

	if not success or (count or 0) == 0 or not isReady("merge") then
		return
	end

	local merged = invoke("FuseAll")

	if merged then
		logActivity(string.format("Merged %d card%s", count, count == 1 and "" or "s"), "accent")
	else
		backOff("merge", RETRY_COOLDOWN)
	end
end

---Equip the strongest card if it is not equipped.
---@param data table
local function equipBest(data)
	local success, best = pcall(CardStats.Best, data.Cards, function(cardId)
		return BaseConfig.SlotOf(data, cardId) ~= nil
	end)

	if not success or type(best) ~= "table" or not best[1] or not isReady("equip") then
		return
	end

	if table.find(data.Equipped or {}, best[1]) then
		return
	end

	local equipped = invoke("EquipBest")

	if equipped then
		logActivity("Equipped " .. tostring(best[1]), "accent")
	else
		backOff("equip", RETRY_COOLDOWN)
	end
end

---Run the card jobs.
local function cardsStep()
	local toggles = AutoFarm.toggles

	if toggles.AutoOpenPacks and getData() then
		openPacks(getData())
	end

	if toggles.AutoCards and getData() then
		mergeCards(getData())
	end

	if toggles.AutoCards and getData() then
		equipBest(getData())
	end
end

---Press a key nobody uses, so the game's idle rejoin never fires.
local function antiAfkStep()
	virtualInputManager:SendKeyEvent(true, Enum.KeyCode.F14, false, game)
	task.wait(0.05)
	virtualInputManager:SendKeyEvent(false, Enum.KeyCode.F14, false, game)
end

---Respawn this client's bosses now, through the game's own LocalEnemies command handler.
local function respawnBossesLocally()
	if not getconnections then
		return false
	end

	for _, connection in ipairs(getconnections(Remotes.LocalEnemies.OnClientEvent)) do
		if connection.Function then
			pcall(connection.Function, "RespawnBosses")
			return true
		end
	end

	return false
end

---Respawn bosses on a timer when Fast Respawn is on.
local function respawnStep()
	if not AutoFarm.toggles.FastRespawn or not AutoFarm.toggles.BossFarm then
		return
	end

	if os.clock() - (session.lastRespawn or 0) < (AutoFarm.settings.respawnEvery or 45) then
		return
	end

	session.lastRespawn = os.clock()

	if not respawnBossesLocally() then
		logActivity("Fast Respawn needs getconnections", "dangerText")
		window:SetToggle("FastRespawn", false)
	end
end

---Record boss respawn times from the game's own boss timer.
local function hookBossTimer()
	oldBossTimerShow, oldBossTimerHide = BossTimer.Show, BossTimer.Hide

	BossTimer.Show = function(padId, position, seconds, ...)
		---@note: The game's Show calls Hide first, so the time is recorded after it returns.
		local results = table.pack(oldBossTimerShow(padId, position, seconds, ...))

		if type(padId) == "number" and type(seconds) == "number" then
			bossRespawnAt[padId] = workspace:GetServerTimeNow() + seconds
		end

		return table.unpack(results, 1, results.n)
	end

	BossTimer.Hide = function(padId, ...)
		bossRespawnAt[padId] = nil
		return oldBossTimerHide(padId, ...)
	end
end

---Put the game's boss timer back.
local function unhookBossTimer()
	if oldBossTimerShow then
		BossTimer.Show, BossTimer.Hide = oldBossTimerShow, oldBossTimerHide
		oldBossTimerShow, oldBossTimerHide = nil, nil
	end
end

---Record when our own attacks land, through the game's local enemy damage function.
local function hookEnemyDamage()
	oldEnemyDamage = LocalEnemyRegistry.Damage

	if not oldEnemyDamage then
		return
	end

	LocalEnemyRegistry.Damage = function(model, amount, ...)
		if typeof(model) == "Instance" and type(amount) == "number" and amount > 0 then
			-- Keep the first hit, so the insta-kill can wait for the server to see it.
			ourHits[model] = ourHits[model] or os.clock()
		end

		return oldEnemyDamage(model, amount, ...)
	end
end

---Put the game's damage function back.
local function unhookEnemyDamage()
	if oldEnemyDamage then
		LocalEnemyRegistry.Damage = oldEnemyDamage
		oldEnemyDamage = nil
	end
end

---Run a loop until unload, logging errors with a label.
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
				warn(string.format("[SuperpowerFarm] %s: %s", label, tostring(message)))
			end

			task.wait(interval)
		end
	end)
end

---Turn every automation toggle off.
local function disableAll()
	window:DisableAll()
	holdAt(nil)
	logActivity("Turned everything off")
end

---Build the Home page.
---@param page table
local function buildHome(page)
	local theme = Library.theme
	local top = page:AddRow({ 7, 5 })
	local powerCard = top:AddCard("Power", 1, { header = false, padding = { 16, 18 }, minHeight = 188 })

	ui.hero = powerCard:AddHero({ "Session", "Boss kills", "Packs opened" }, CHART_BARS)

	local nowCard = top:AddCard("Now", 2, { padding = { 16, 18 }, minHeight = 188, gap = 0 })

	ui.nowCard = nowCard
	ui.mode = nowCard:AddValue("Idle")
	nowCard:AddSpace(10)
	ui.target = nowCard:AddStat("Target", theme.gold)
	nowCard:AddSpace(6)
	ui.level = nowCard:AddStat("Level", theme.good)
	nowCard:AddSpace(6)
	ui.rebirth = nowCard:AddStat("Rebirth at", theme.soft)
	nowCard:AddSpace(6)
	ui.carry = nowCard:AddStat("Carrying", theme.soft)

	local bossCard = page:AddRow({ 1 }):AddCard("Bosses", 1)

	ui.bossCard = bossCard
	ui.bossTiles = bossCard:AddTiles(12, 4)

	local bottom = page:AddRow({ 7, 5 })
	local activityCard = bottom:AddCard("Activity", 1, { gap = 8, minHeight = 212 })

	ui.feed = activityCard:AddFeed(MAX_ACTIVITY_LINES)

	local quick = bottom:AddCard("Quick switches", 2, { gap = 6, minHeight = 212 })

	quick:AddSwitch("BossFarm", "Boss Farm")
	quick:AddSwitch("ZoneFarm", "Zone Farm")
	quick:AddSwitch("AutoTrain", "Auto Train")
	quick:AddSwitch("AutoOpenPacks", "Open Packs")

	ui.homeCards = { powerCard, nowCard, bossCard, activityCard, quick }
end

---Refresh the header and the live values on the home cards.
local function refreshInterface()
	local data = getData()
	if not data then
		return
	end

	local active = false

	for key, enabled in pairs(AutoFarm.toggles) do
		if key ~= "AutoBank" and key ~= "DodgeAttacks" then
			active = active or enabled
		end
	end

	session.startPower = session.startPower or data.Power
	window:SetStat("Cash", "$" .. short(data.Cash))
	window:SetStatus(active and session.mode or "Idle", active)
	window:SetProfile(string.format("World %d · Rebirth %d", PlaceConfig.World, data.Rebirths or 0))
	ui.feed:Set(activity)

	local shown = false

	for _, card in ipairs(ui.homeCards) do
		shown = shown or card:IsVisible()
	end

	if not shown then
		return
	end

	local setText = Library.setText
	local elapsed = math.max(os.clock() - session.startedAt, 1)
	local hours, minutes = elapsed // 3600, elapsed // 60 % 60
	local level = PowerConfig.Level(data.Power or 0)
	local needed = Progression.RebirthLevelRequirement(data.Rebirths or 0)

	setText(ui.hero.value, short(data.Power))
	setText(ui.hero.rate, string.format("Cash <font family=\"rbxasset://fonts/families/RobotoMono.json\">$%s</font>", short(data.Cash)))
	setText(ui.hero.stats[1], hours > 0 and string.format("%dh %dm", hours, minutes) or string.format("%dm %02ds", minutes, elapsed // 1 % 60))
	setText(ui.hero.stats[2], tostring(session.bossKills))
	setText(ui.hero.stats[3], tostring(session.packsOpened))
	setText(ui.mode, session.mode)
	setText(ui.target, tostring(session.target))
	setText(ui.level, tostring(level))
	setText(ui.rebirth, level >= needed and "Ready" or ("Level " .. needed))
	setText(ui.carry, string.format("%d / %d packs", carriedPacks(), tonumber(localPlayer:GetAttribute("CarryCapacity")) or 5))

	local picked = AutoFarm.settings["bosses" .. PlaceConfig.World] or {}

	for index, tile in ipairs(ui.bossTiles) do
		local gate = catalog.zoneOrder[index]
		local pad = gate and catalog.zones[gate].boss

		tile.frame.Visible = pad ~= nil

		if pad then
			local wait = bossWait(pad)
			local name = enemyName(pad.enemy)

			tile:Set({
				id = tostring(pad.id),
				badge = wait > 0 and string.format("%d:%02d", wait // 60, wait % 60) or "UP",
				badgeColor = wait > 0 and BOSS_WAIT_COLOR or BOSS_UP_COLOR,
				name = name,
				sub = string.format("Lv %d · %s", pad.level, picked[name] and "selected" or zoneName(gate)),
				strong = picked[name] == true,
			})
		end
	end
end

---Build the boss and zone chips for every world.
---@return table, table
local function worldChoices()
	local bossTabs, zoneTabs = {}, {}

	for worldNumber, world in ipairs(PlaceConfig.Worlds) do
		local bossNames, zoneNames = {}, {}

		for _, boss in ipairs(world.Bosses) do
			local name, zone = enemyName(boss.Id), zoneName(boss.Gate)

			bossNames[#bossNames + 1] = name
			zoneNames[#zoneNames + 1] = zone
			bossIdByName[name] = boss.Id
			zoneGateByName[zone] = boss.Gate
		end

		local label = "World " .. worldNumber

		bossTabs[#bossTabs + 1] = { name = label, key = "bosses" .. worldNumber, choices = bossNames }
		zoneTabs[#zoneTabs + 1] = { name = label, key = "zone" .. worldNumber, choices = zoneNames, single = true }
	end

	return bossTabs, zoneTabs
end

---Create the window and every page.
local function createInterface()
	Library.onUnload = AutoFarm.detach
	window = Library.new({
		title = "Superpower",
		subtitle = "Steal a Superpower",
		configFolder = CONFIG_FOLDER,
		toggles = AutoFarm.toggles,
		settings = AutoFarm.settings,
	})

	buildHome(window:AddPage("Home", { icon = "house", section = "Overview", title = false, padding = 14, gap = 10 }))

	local bossTabs, zoneTabs = worldChoices()
	local farm = window:AddPage("Farm", { icon = "pickaxe", section = "Automation", description = "Bosses, zones and the training bench." })

	farm:AddAction("Turn all off", "dangerSoft", disableAll)

	local bosses = farm:AddCard("Boss farm", 1)

	bosses:AddToggle("BossFarm", "Boss Farm", "Fights each picked boss that is up, in map order.")
	bosses:AddToggle("InstaKillBosses", "Insta-Kill", "After your first hit lands, finishes the boss at once. Works on bosses you can't beat.")
	bosses:AddToggle("ServerHop", "Server Hop", "When every picked boss is respawning, joins another server and keeps farming there.")
	bosses:AddToggle("FastRespawn", "Fast Respawn", "Respawns your bosses on a timer instead of waiting for the game.")
	bosses:AddSlider("respawnEvery", "Respawn every", RESPAWN_RANGE, "sec", nil, nil, { showWhen = "FastRespawn", ticks = { "5s", "90s" } })
	bosses:AddChips(bossTabs, { actions = true, label = "Select bosses", startTab = PlaceConfig.World })
	bosses:AddNote("Only bosses in the world you are in can be farmed.", "lock")

	local zones = farm:AddCard("Zone farm", 2)

	zones:AddToggle("ZoneFarm", "Zone Farm", "Kills the mobs in the picked zone. Bosses come first when Boss Farm is on.")
	zones:AddChips(zoneTabs, {
		label = "Select zone",
		startTab = PlaceConfig.World,
		summary = function()
			return tostring(AutoFarm.settings["zone" .. PlaceConfig.World] or "None")
		end,
	})
	zones:AddNote("Uses the game's Auto Attack setting and your equipped card.", "lock")

	local general = farm:AddCard("Between fights", 2)

	general:AddToggle("AutoTrain", "Auto Train", "Lies on your bench whenever nothing else is running, like while bosses respawn.")
	general:AddToggle("AutoBank", "Auto Bank Packs", "Goes home after a boss kill, and when you carry the max, so packs bank.")
	general:AddButton("Teleport home", goHome, "ghost")

	local movement = farm:AddCard("Movement", 1)

	movement:AddToggle("DodgeAttacks", "Dodge Attacks", "Slides out of glowing enemy attack zones while farming.")
	movement:AddSlider("targetDistance", "Distance from target", { MIN_TARGET_DISTANCE, 120 }, "studs", nil, nil, { ticks = { "4", "120" } })
	movement:AddSlider("floatHeight", "Float height", { 0, 40 }, "studs", nil, nil, { ticks = { "0", "40" } })

	local packChoices = {}

	for _, packId in ipairs(PackConfig.Order) do
		packChoices[#packChoices + 1] = packId
	end

	for _, packId in ipairs(PackConfig.Limited) do
		if PackConfig.Packs[packId] then
			packChoices[#packChoices + 1] = packId
		end
	end

	local cards = window:AddPage("Cards", { icon = "star", description = "Packs, merging and card placement." })
	local packs = cards:AddCard("Packs", 1)

	packs:AddToggle("AutoOpenPacks", "Auto Open Packs", "Opens the picked packs with no animation on screen.")
	packs:AddSlider("openCount", "Open at once", { 1, MAX_OPEN_PER_CALL }, "packs", nil, nil, { ticks = { "1", "10" } })
	packs:AddChips({ { name = "Packs", key = "openPacks", choices = packChoices } }, { actions = true, label = "Select packs" })
	packs:AddNote("The game caps one open at 10 packs.", "lock")

	local deck = cards:AddCard("Cards", 2)

	deck:AddToggle("AutoCards", "Auto Manage Cards", "Merges 5-copy stacks, equips your strongest card, and places the best cards on your base.")
	deck:AddButton("Place best now", function()
		task.spawn(placeBest)
	end, "ghost")

	local upgradeNames = { BENCH_UPGRADE }

	for _, upgrade in ipairs(Progression.Upgrades) do
		upgradeNames[#upgradeNames + 1] = upgrade.Name
	end

	local potionNames = {}

	for _, potion in ipairs(CosmeticConfig.Potions.Types) do
		potionNames[#potionNames + 1] = potion.Name
	end

	local shop = window:AddPage("Shop", { icon = "arrow-up", description = "Upgrades, bench, potions, auras and rebirth." })
	local upgrades = shop:AddCard("Upgrades", 1)

	upgrades:AddToggle("AutoUpgrades", "Auto Upgrades", "Buys the picked upgrades from the Upgrades menu.")
	upgrades:AddChips({ { name = "Upgrades", key = "upgradeIds", choices = upgradeNames } }, { actions = true, label = "Select upgrades" })
	upgrades:AddSlider("spendLimit", "Spend limit", { 1, 100 }, "% of cash", nil, nil, { ticks = { "1%", "100%" } })

	local store = shop:AddCard("Store", 2)

	store:AddToggle("AutoPotions", "Auto Buy Potions", "Buys picked potions from the shelf when they restock.")
	store:AddChips({
		{ name = "Potions", key = "potionTypes", choices = potionNames },
		{ name = "Tiers", key = "potionTiers", choices = POTION_TIERS },
	}, { actions = true, label = "Select potions" })
	store:AddToggle("AutoAuras", "Auto Best Aura & Trail", "Buys the strongest aura and trail you can afford, and equips your best ones.")
	store:AddToggle("AutoClaim", "Auto Claim Rewards", "Claims the daily reward, free Forever Pack steps, index rewards and offline cash.")

	upgrades:AddToggle("AutoRebirth", "Auto Rebirth", "Rebirths as soon as your level is high enough. Resets power.")

	AutoFarm.window = window
	window:Ready()
end

---Initialize AutoFarm module.
function AutoFarm.init()
	AutoFarm.running = true
	AutoFarm.session, AutoFarm.activity = session, activity
	loadHopState()
	buildCatalog()
	hookBossTimer()
	hookEnemyDamage()
	createInterface()

	connections[#connections + 1] = runService.Heartbeat:Connect(holdStep)
	connections[#connections + 1] = Remotes.EnemyReward.OnClientEvent:Connect(function()
		lastRewardAt = os.clock()
	end)
	connections[#connections + 1] = replicatedStorage.EnemyPads.ChildAdded:Connect(function()
		task.defer(buildCatalog)
	end)

	spawnLoop("Interface", INTERFACE_INTERVAL, refreshInterface)
	spawnLoop("Brain", BRAIN_INTERVAL, brainStep)
	spawnLoop("Economy", ECONOMY_INTERVAL, economyStep)
	spawnLoop("Cards", CARDS_INTERVAL, cardsStep)
	spawnLoop("AntiAfk", ANTI_AFK_INTERVAL, antiAfkStep)
	spawnLoop("Respawn", 1, respawnStep)
	logActivity(session.hopped and "Loaded after a server hop" or "Loaded")
end

---Detach AutoFarm module.
function AutoFarm.detach()
	if not AutoFarm.running then
		return
	end

	-- Get off the bench first, or the game keeps the character pinned there after unload.
	if isLifting() then
		task.spawn(stopLift)
		task.wait(0.1)
	end

	AutoFarm.running = false
	brain.holdCFrame = nil
	unhookEnemyDamage()
	unhookBossTimer()

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	table.clear(connections)

	if window then
		local current = window

		window = nil
		current:Destroy()
	end
end

-- Replace any previous instance.
if shared.SuperpowerAutoFarm then
	shared.SuperpowerAutoFarm.detach()
end

shared.SuperpowerAutoFarm = AutoFarm
AutoFarm.init()

-- Return AutoFarm module.
return AutoFarm
