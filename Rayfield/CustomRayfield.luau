

if debugX then
end



local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

local function safeFont(fontName)
	if type(fontName) ~= "string" then return nil end
	local success, font = pcall(function()
		return Enum.Font[fontName]
	end)
	return success and font or nil
end

local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url)
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response"
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	while not requestCompleted do
		task.wait()
	end
	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end
	if not success then
	end
	return if success then result else nil
end

local requestsDisabled = false
local customAssetId = nil
local secureMode = false
if getgenv then
	local ok, result = pcall(function() return getgenv().DISABLE_RAYFIELD_REQUESTS end)
	if ok and result then requestsDisabled = true end
	local ok2, result2 = pcall(function() return getgenv().RAYFIELD_ASSET_ID end)
	if ok2 and type(result2) == "number" then customAssetId = result2 end
	local ok3, result3 = pcall(function() return getgenv().RAYFIELD_SECURE end)
	if ok3 and result3 then secureMode = true end
end

if secureMode then
	local _error = error
	local _assert = assert
	warn = function(...) end
	print = function(...) end
	error = function(_, level) _error("", level) end
	assert = function(v, ...) return _assert(v) end
end

local secureWarnings = {}
local customAssets = {}

local function secureNotify(wType, title, content)
	if secureWarnings[wType] then return end
	secureWarnings[wType] = true
	task.spawn(function()
		while not RayfieldLibrary or not RayfieldLibrary.Notify do task.wait(0.5) end
		RayfieldLibrary:Notify({
			Title = title,
			Content = content,
			Duration = 8,
		})
	end)
end
local InterfaceBuild = 'UU2NX'
local Release = "Build 1.749"
local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
	General = {
		rayfieldOpen = {Type = 'bind', Value = 'K', Name = 'Rayfield Keybind'},

	},
	System = {
		usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
	}
}

local overriddenSettings: { [string]: any } = {}
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[category .. "." .. name] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[category .. "." .. name] ~= nil then
		return overriddenSettings[category .. "." .. name]
	elseif settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

if not prompt and not useStudio then
	prompt = {
		create = function() end
	}
end


local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			return false
		else
			return result
		end
	end
end

local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

local function loadSettings()
	local file = nil

	local success, result =	pcall(function()
		if callSafely(isfolder, RayfieldFolder) then
			if callSafely(isfile, RayfieldFolder..'/settings'..ConfigurationExtension) then
				file = callSafely(readfile, RayfieldFolder..'/settings'..ConfigurationExtension)
			end
		end

		if useStudio then
			file = [[
	{"General":{"rayfieldOpen":{"Value":"K","Type":"bind","Name":"Rayfield Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Rayfield Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
]]
		end

		if file then
			local decodeSuccess, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
			if decodeSuccess then
				file = decodedFile
			else
				file = {}
			end
		else
			file = {}
		end


		if not settingsCreated then
			return
		end

		if next(file) ~= nil then
			for categoryName, categoryTable in file do
				for settingName, setting in categoryTable do
					local default = settingsTable[categoryName] and settingsTable[categoryName][settingName]
					if not default then continue end
					local settingType = typeof(default.Value)
					if not (settingType == typeof(setting.Value)) then
						continue
					end
					default.Value = setting.Value
				end
			end
		end
		for categoryName, categoryTable in settingsTable do
			for settingName, setting in categoryTable do
				if setting.Element then
					setting.Element:Set(getSetting(categoryName, settingName))
				end
			end
		end
		settingsInitialized = true
	end)

	if not success then 
		if writefile then
		end
	end
end

if debugX then
end

loadSettings()

if debugX then
end

local ANALYTICS_TOKEN = "05de7f9fd320d3b8428cd1c77014a337b85b6c8efee2c5914f5ab5700c354b9a"

local reporter = nil
if not requestsDisabled and not useStudio then
	local fetchSuccess, fetchResult = pcall((game :: any).HttpGet, game, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/reporter.lua")
	if fetchSuccess and #fetchResult > 0 then
		local execSuccess, Analytics = pcall(function()
			return (loadstring(fetchResult) :: any)()
		end)
		if execSuccess and Analytics then
			pcall(function()
				reporter = Analytics.new({
					url          = "https://rayfield-collect.sirius-software-ltd.workers.dev",
					token        = ANALYTICS_TOKEN,
					product_name = "Rayfield",
					category     = "UILibrary",
				})
			end)
		end
	end
end

if not useStudio and math.random(10) == 1 then
	task.spawn(function()
		pcall((game :: any).HttpGet, game, "https://www.sentivel.com/api/heartbeat/81074364b461f8da81bad6fdc363c3b927f884d6fc28d806a15ee50ca1e68c78")
	end)
end

local promptUser = 2

if promptUser == 1 and prompt and type(prompt.create) == "function" then
	prompt.create(
		'Be cautious when running scripts',
	    [[Please be careful when running scripts from unknown developers. This script has already been ran.

<font transparency='0.3'>Some scripts may steal your items or in-game goods.</font>]],
		'Okay',
		'',
		function()

		end
	)
end

if debugX then
end

local RayfieldLibrary = {
	Flags = {},
	Theme = {
		Default = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(25, 25, 25),
			Topbar = Color3.fromRGB(34, 34, 34),
			Shadow = Color3.fromRGB(20, 20, 20),

			NotificationBackground = Color3.fromRGB(20, 20, 20),
			NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

			TabBackground = Color3.fromRGB(80, 80, 80),
			TabStroke = Color3.fromRGB(85, 85, 85),
			TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
			TabTextColor = Color3.fromRGB(240, 240, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

			ElementBackground = Color3.fromRGB(35, 35, 35),
			ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
			SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
			ElementStroke = Color3.fromRGB(50, 50, 50),
			SecondaryElementStroke = Color3.fromRGB(40, 40, 40),

			SliderBackground = Color3.fromRGB(50, 138, 220),
			SliderProgress = Color3.fromRGB(50, 138, 220),
			SliderStroke = Color3.fromRGB(58, 163, 255),

			ToggleBackground = Color3.fromRGB(30, 30, 30),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(100, 100, 100),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

			DropdownSelected = Color3.fromRGB(40, 40, 40),
			DropdownUnselected = Color3.fromRGB(30, 30, 30),

			InputBackground = Color3.fromRGB(30, 30, 30),
			InputStroke = Color3.fromRGB(65, 65, 65),
			PlaceholderColor = Color3.fromRGB(178, 178, 178)
		},

		Ocean = {
			TextColor = Color3.fromRGB(230, 240, 240),

			Background = Color3.fromRGB(20, 30, 30),
			Topbar = Color3.fromRGB(25, 40, 40),
			Shadow = Color3.fromRGB(15, 20, 20),

			NotificationBackground = Color3.fromRGB(25, 35, 35),
			NotificationActionsBackground = Color3.fromRGB(230, 240, 240),

			TabBackground = Color3.fromRGB(40, 60, 60),
			TabStroke = Color3.fromRGB(50, 70, 70),
			TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
			TabTextColor = Color3.fromRGB(210, 230, 230),
			SelectedTabTextColor = Color3.fromRGB(20, 50, 50),

			ElementBackground = Color3.fromRGB(30, 50, 50),
			ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
			SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
			ElementStroke = Color3.fromRGB(45, 70, 70),
			SecondaryElementStroke = Color3.fromRGB(40, 65, 65),

			SliderBackground = Color3.fromRGB(0, 110, 110),
			SliderProgress = Color3.fromRGB(0, 140, 140),
			SliderStroke = Color3.fromRGB(0, 160, 160),

			ToggleBackground = Color3.fromRGB(30, 50, 50),
			ToggleEnabled = Color3.fromRGB(0, 130, 130),
			ToggleDisabled = Color3.fromRGB(70, 90, 90),
			ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
			ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
			ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),

			DropdownSelected = Color3.fromRGB(30, 60, 60),
			DropdownUnselected = Color3.fromRGB(25, 40, 40),

			InputBackground = Color3.fromRGB(30, 50, 50),
			InputStroke = Color3.fromRGB(50, 70, 70),
			PlaceholderColor = Color3.fromRGB(140, 160, 160)
		},

		AmberGlow = {
			TextColor = Color3.fromRGB(255, 245, 230),

			Background = Color3.fromRGB(45, 30, 20),
			Topbar = Color3.fromRGB(55, 40, 25),
			Shadow = Color3.fromRGB(35, 25, 15),

			NotificationBackground = Color3.fromRGB(50, 35, 25),
			NotificationActionsBackground = Color3.fromRGB(245, 230, 215),

			TabBackground = Color3.fromRGB(75, 50, 35),
			TabStroke = Color3.fromRGB(90, 60, 45),
			TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
			TabTextColor = Color3.fromRGB(250, 220, 200),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 10),

			ElementBackground = Color3.fromRGB(60, 45, 35),
			ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
			SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
			ElementStroke = Color3.fromRGB(85, 60, 45),
			SecondaryElementStroke = Color3.fromRGB(75, 50, 35),

			SliderBackground = Color3.fromRGB(220, 130, 60),
			SliderProgress = Color3.fromRGB(250, 150, 75),
			SliderStroke = Color3.fromRGB(255, 170, 85),

			ToggleBackground = Color3.fromRGB(55, 40, 30),
			ToggleEnabled = Color3.fromRGB(240, 130, 30),
			ToggleDisabled = Color3.fromRGB(90, 70, 60),
			ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
			ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
			ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
			ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),

			DropdownSelected = Color3.fromRGB(70, 50, 40),
			DropdownUnselected = Color3.fromRGB(55, 40, 30),

			InputBackground = Color3.fromRGB(60, 45, 35),
			InputStroke = Color3.fromRGB(90, 65, 50),
			PlaceholderColor = Color3.fromRGB(190, 150, 130)
		},

		Light = {
			TextColor = Color3.fromRGB(40, 40, 40),

			Background = Color3.fromRGB(245, 245, 245),
			Topbar = Color3.fromRGB(230, 230, 230),
			Shadow = Color3.fromRGB(200, 200, 200),

			NotificationBackground = Color3.fromRGB(250, 250, 250),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),

			TabBackground = Color3.fromRGB(235, 235, 235),
			TabStroke = Color3.fromRGB(215, 215, 215),
			TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
			TabTextColor = Color3.fromRGB(80, 80, 80),
			SelectedTabTextColor = Color3.fromRGB(0, 0, 0),

			ElementBackground = Color3.fromRGB(240, 240, 240),
			ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
			SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
			ElementStroke = Color3.fromRGB(210, 210, 210),
			SecondaryElementStroke = Color3.fromRGB(210, 210, 210),

			SliderBackground = Color3.fromRGB(150, 180, 220),
			SliderProgress = Color3.fromRGB(100, 150, 200), 
			SliderStroke = Color3.fromRGB(120, 170, 220),

			ToggleBackground = Color3.fromRGB(220, 220, 220),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(150, 150, 150),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),

			DropdownSelected = Color3.fromRGB(230, 230, 230),
			DropdownUnselected = Color3.fromRGB(220, 220, 220),

			InputBackground = Color3.fromRGB(240, 240, 240),
			InputStroke = Color3.fromRGB(180, 180, 180),
			PlaceholderColor = Color3.fromRGB(140, 140, 140)
		},

		Amethyst = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(30, 20, 40),
			Topbar = Color3.fromRGB(40, 25, 50),
			Shadow = Color3.fromRGB(20, 15, 30),

			NotificationBackground = Color3.fromRGB(35, 20, 40),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 250),

			TabBackground = Color3.fromRGB(60, 40, 80),
			TabStroke = Color3.fromRGB(70, 45, 90),
			TabBackgroundSelected = Color3.fromRGB(180, 140, 200),
			TabTextColor = Color3.fromRGB(230, 230, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 20, 50),

			ElementBackground = Color3.fromRGB(45, 30, 60),
			ElementBackgroundHover = Color3.fromRGB(50, 35, 70),
			SecondaryElementBackground = Color3.fromRGB(40, 30, 55),
			ElementStroke = Color3.fromRGB(70, 50, 85),
			SecondaryElementStroke = Color3.fromRGB(65, 45, 80),

			SliderBackground = Color3.fromRGB(100, 60, 150),
			SliderProgress = Color3.fromRGB(130, 80, 180),
			SliderStroke = Color3.fromRGB(150, 100, 200),

			ToggleBackground = Color3.fromRGB(45, 30, 55),
			ToggleEnabled = Color3.fromRGB(120, 60, 150),
			ToggleDisabled = Color3.fromRGB(94, 47, 117),
			ToggleEnabledStroke = Color3.fromRGB(140, 80, 170),
			ToggleDisabledStroke = Color3.fromRGB(124, 71, 150),
			ToggleEnabledOuterStroke = Color3.fromRGB(90, 40, 120),
			ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 110),

			DropdownSelected = Color3.fromRGB(50, 35, 70),
			DropdownUnselected = Color3.fromRGB(35, 25, 50),

			InputBackground = Color3.fromRGB(45, 30, 60),
			InputStroke = Color3.fromRGB(80, 50, 110),
			PlaceholderColor = Color3.fromRGB(178, 150, 200)
		},

		Green = {
			TextColor = Color3.fromRGB(30, 60, 30),

			Background = Color3.fromRGB(235, 245, 235),
			Topbar = Color3.fromRGB(210, 230, 210),
			Shadow = Color3.fromRGB(200, 220, 200),

			NotificationBackground = Color3.fromRGB(240, 250, 240),
			NotificationActionsBackground = Color3.fromRGB(220, 235, 220),

			TabBackground = Color3.fromRGB(215, 235, 215),
			TabStroke = Color3.fromRGB(190, 210, 190),
			TabBackgroundSelected = Color3.fromRGB(245, 255, 245),
			TabTextColor = Color3.fromRGB(50, 80, 50),
			SelectedTabTextColor = Color3.fromRGB(20, 60, 20),

			ElementBackground = Color3.fromRGB(225, 240, 225),
			ElementBackgroundHover = Color3.fromRGB(210, 225, 210),
			SecondaryElementBackground = Color3.fromRGB(235, 245, 235), 
			ElementStroke = Color3.fromRGB(180, 200, 180),
			SecondaryElementStroke = Color3.fromRGB(180, 200, 180),

			SliderBackground = Color3.fromRGB(90, 160, 90),
			SliderProgress = Color3.fromRGB(70, 130, 70),
			SliderStroke = Color3.fromRGB(100, 180, 100),

			ToggleBackground = Color3.fromRGB(215, 235, 215),
			ToggleEnabled = Color3.fromRGB(60, 130, 60),
			ToggleDisabled = Color3.fromRGB(150, 175, 150),
			ToggleEnabledStroke = Color3.fromRGB(80, 150, 80),
			ToggleDisabledStroke = Color3.fromRGB(130, 150, 130),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 160, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(160, 180, 160),

			DropdownSelected = Color3.fromRGB(225, 240, 225),
			DropdownUnselected = Color3.fromRGB(210, 225, 210),

			InputBackground = Color3.fromRGB(235, 245, 235),
			InputStroke = Color3.fromRGB(180, 200, 180),
			PlaceholderColor = Color3.fromRGB(120, 140, 120)
		},

		Bloom = {
			TextColor = Color3.fromRGB(60, 40, 50),

			Background = Color3.fromRGB(255, 240, 245),
			Topbar = Color3.fromRGB(250, 220, 225),
			Shadow = Color3.fromRGB(230, 190, 195),

			NotificationBackground = Color3.fromRGB(255, 235, 240),
			NotificationActionsBackground = Color3.fromRGB(245, 215, 225),

			TabBackground = Color3.fromRGB(240, 210, 220),
			TabStroke = Color3.fromRGB(230, 200, 210),
			TabBackgroundSelected = Color3.fromRGB(255, 225, 235),
			TabTextColor = Color3.fromRGB(80, 40, 60),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 50),

			ElementBackground = Color3.fromRGB(255, 235, 240),
			ElementBackgroundHover = Color3.fromRGB(245, 220, 230),
			SecondaryElementBackground = Color3.fromRGB(255, 235, 240), 
			ElementStroke = Color3.fromRGB(230, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(230, 200, 210),

			SliderBackground = Color3.fromRGB(240, 130, 160),
			SliderProgress = Color3.fromRGB(250, 160, 180),
			SliderStroke = Color3.fromRGB(255, 180, 200),

			ToggleBackground = Color3.fromRGB(240, 210, 220),
			ToggleEnabled = Color3.fromRGB(255, 140, 170),
			ToggleDisabled = Color3.fromRGB(200, 180, 185),
			ToggleEnabledStroke = Color3.fromRGB(250, 160, 190),
			ToggleDisabledStroke = Color3.fromRGB(210, 180, 190),
			ToggleEnabledOuterStroke = Color3.fromRGB(220, 160, 180),
			ToggleDisabledOuterStroke = Color3.fromRGB(190, 170, 180),

			DropdownSelected = Color3.fromRGB(250, 220, 225),
			DropdownUnselected = Color3.fromRGB(240, 210, 220),

			InputBackground = Color3.fromRGB(255, 235, 240),
			InputStroke = Color3.fromRGB(220, 190, 200),
			PlaceholderColor = Color3.fromRGB(170, 130, 140)
		},

		DarkBlue = {
			TextColor = Color3.fromRGB(230, 230, 230),

			Background = Color3.fromRGB(20, 25, 30),
			Topbar = Color3.fromRGB(30, 35, 40),
			Shadow = Color3.fromRGB(15, 20, 25),

			NotificationBackground = Color3.fromRGB(25, 30, 35),
			NotificationActionsBackground = Color3.fromRGB(45, 50, 55),

			TabBackground = Color3.fromRGB(35, 40, 45),
			TabStroke = Color3.fromRGB(45, 50, 60),
			TabBackgroundSelected = Color3.fromRGB(40, 70, 100),
			TabTextColor = Color3.fromRGB(200, 200, 200),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),

			ElementBackground = Color3.fromRGB(30, 35, 40),
			ElementBackgroundHover = Color3.fromRGB(40, 45, 50),
			SecondaryElementBackground = Color3.fromRGB(35, 40, 45), 
			ElementStroke = Color3.fromRGB(45, 50, 60),
			SecondaryElementStroke = Color3.fromRGB(40, 45, 55),

			SliderBackground = Color3.fromRGB(0, 90, 180),
			SliderProgress = Color3.fromRGB(0, 120, 210),
			SliderStroke = Color3.fromRGB(0, 150, 240),

			ToggleBackground = Color3.fromRGB(35, 40, 45),
			ToggleEnabled = Color3.fromRGB(0, 120, 210),
			ToggleDisabled = Color3.fromRGB(70, 70, 80),
			ToggleEnabledStroke = Color3.fromRGB(0, 150, 240),
			ToggleDisabledStroke = Color3.fromRGB(75, 75, 85),
			ToggleEnabledOuterStroke = Color3.fromRGB(20, 100, 180), 
			ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),

			DropdownSelected = Color3.fromRGB(30, 70, 90),
			DropdownUnselected = Color3.fromRGB(25, 30, 35),

			InputBackground = Color3.fromRGB(25, 30, 35),
			InputStroke = Color3.fromRGB(45, 50, 60), 
			PlaceholderColor = Color3.fromRGB(150, 150, 160)
		},

		Serenity = {
			TextColor = Color3.fromRGB(50, 55, 60),
			Background = Color3.fromRGB(240, 245, 250),
			Topbar = Color3.fromRGB(215, 225, 235),
			Shadow = Color3.fromRGB(200, 210, 220),

			NotificationBackground = Color3.fromRGB(210, 220, 230),
			NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

			TabBackground = Color3.fromRGB(200, 210, 220),
			TabStroke = Color3.fromRGB(180, 190, 200),
			TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
			TabTextColor = Color3.fromRGB(50, 55, 60),
			SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

			ElementBackground = Color3.fromRGB(210, 220, 230),
			ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
			SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
			ElementStroke = Color3.fromRGB(190, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

			SliderBackground = Color3.fromRGB(200, 220, 235),
			SliderProgress = Color3.fromRGB(70, 130, 180),
			SliderStroke = Color3.fromRGB(150, 180, 220),

			ToggleBackground = Color3.fromRGB(210, 220, 230),
			ToggleEnabled = Color3.fromRGB(70, 160, 210),
			ToggleDisabled = Color3.fromRGB(180, 180, 180),
			ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
			ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
			ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

			DropdownSelected = Color3.fromRGB(220, 230, 240),
			DropdownUnselected = Color3.fromRGB(200, 210, 220),

			InputBackground = Color3.fromRGB(220, 230, 240),
			InputStroke = Color3.fromRGB(180, 190, 200),
			PlaceholderColor = Color3.fromRGB(150, 150, 150)
		},

		Cyberpunk = {
			TextColor = Color3.fromRGB(255, 255, 255),
			Background = Color3.fromRGB(15, 12, 28),
			Topbar = Color3.fromRGB(25, 18, 45),
			Shadow = Color3.fromRGB(10, 8, 20),
			NotificationBackground = Color3.fromRGB(20, 15, 35),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),
			TabBackground = Color3.fromRGB(35, 25, 60),
			TabStroke = Color3.fromRGB(255, 0, 110),
			TabBackgroundSelected = Color3.fromRGB(255, 0, 110),
			TabTextColor = Color3.fromRGB(240, 240, 255),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
			ElementBackground = Color3.fromRGB(25, 20, 48),
			ElementBackgroundHover = Color3.fromRGB(35, 28, 65),
			SecondaryElementBackground = Color3.fromRGB(20, 15, 38),
			ElementStroke = Color3.fromRGB(255, 0, 110),
			SecondaryElementStroke = Color3.fromRGB(0, 240, 255),
			SliderBackground = Color3.fromRGB(40, 30, 75),
			SliderProgress = Color3.fromRGB(0, 240, 255),
			SliderStroke = Color3.fromRGB(0, 240, 255),
			ToggleBackground = Color3.fromRGB(30, 22, 55),
			ToggleEnabled = Color3.fromRGB(255, 0, 110),
			ToggleDisabled = Color3.fromRGB(60, 45, 90),
			ToggleEnabledStroke = Color3.fromRGB(255, 50, 140),
			ToggleDisabledStroke = Color3.fromRGB(80, 60, 115),
			ToggleEnabledOuterStroke = Color3.fromRGB(150, 0, 70),
			ToggleDisabledOuterStroke = Color3.fromRGB(50, 38, 75),
			DropdownSelected = Color3.fromRGB(35, 28, 65),
			DropdownUnselected = Color3.fromRGB(25, 20, 48),
			InputBackground = Color3.fromRGB(30, 24, 55),
			InputStroke = Color3.fromRGB(0, 240, 255),
			PlaceholderColor = Color3.fromRGB(160, 150, 200)
		},

		BloodNight = {
			TextColor = Color3.fromRGB(250, 240, 240),
			Background = Color3.fromRGB(20, 10, 10),
			Topbar = Color3.fromRGB(32, 14, 14),
			Shadow = Color3.fromRGB(12, 6, 6),
			NotificationBackground = Color3.fromRGB(28, 12, 12),
			NotificationActionsBackground = Color3.fromRGB(240, 230, 230),
			TabBackground = Color3.fromRGB(45, 20, 20),
			TabStroke = Color3.fromRGB(180, 30, 30),
			TabBackgroundSelected = Color3.fromRGB(190, 25, 25),
			TabTextColor = Color3.fromRGB(245, 220, 220),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
			ElementBackground = Color3.fromRGB(30, 15, 15),
			ElementBackgroundHover = Color3.fromRGB(42, 20, 20),
			SecondaryElementBackground = Color3.fromRGB(24, 12, 12),
			ElementStroke = Color3.fromRGB(90, 30, 30),
			SecondaryElementStroke = Color3.fromRGB(75, 25, 25),
			SliderBackground = Color3.fromRGB(60, 20, 20),
			SliderProgress = Color3.fromRGB(220, 35, 35),
			SliderStroke = Color3.fromRGB(255, 50, 50),
			ToggleBackground = Color3.fromRGB(35, 16, 16),
			ToggleEnabled = Color3.fromRGB(220, 35, 35),
			ToggleDisabled = Color3.fromRGB(70, 35, 35),
			ToggleEnabledStroke = Color3.fromRGB(255, 60, 60),
			ToggleDisabledStroke = Color3.fromRGB(90, 45, 45),
			ToggleEnabledOuterStroke = Color3.fromRGB(140, 20, 20),
			ToggleDisabledOuterStroke = Color3.fromRGB(50, 25, 25),
			DropdownSelected = Color3.fromRGB(45, 22, 22),
			DropdownUnselected = Color3.fromRGB(32, 16, 16),
			InputBackground = Color3.fromRGB(35, 18, 18),
			InputStroke = Color3.fromRGB(140, 35, 35),
			PlaceholderColor = Color3.fromRGB(170, 120, 120)
		},

		MidnightEmerald = {
			TextColor = Color3.fromRGB(235, 250, 240),
			Background = Color3.fromRGB(12, 22, 18),
			Topbar = Color3.fromRGB(16, 32, 25),
			Shadow = Color3.fromRGB(8, 15, 12),
			NotificationBackground = Color3.fromRGB(14, 28, 22),
			NotificationActionsBackground = Color3.fromRGB(230, 245, 235),
			TabBackground = Color3.fromRGB(22, 45, 35),
			TabStroke = Color3.fromRGB(35, 75, 58),
			TabBackgroundSelected = Color3.fromRGB(16, 185, 129),
			TabTextColor = Color3.fromRGB(210, 240, 225),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
			ElementBackground = Color3.fromRGB(18, 35, 28),
			ElementBackgroundHover = Color3.fromRGB(24, 46, 37),
			SecondaryElementBackground = Color3.fromRGB(14, 28, 22),
			ElementStroke = Color3.fromRGB(30, 65, 50),
			SecondaryElementStroke = Color3.fromRGB(25, 55, 42),
			SliderBackground = Color3.fromRGB(25, 52, 42),
			SliderProgress = Color3.fromRGB(16, 185, 129),
			SliderStroke = Color3.fromRGB(52, 211, 153),
			ToggleBackground = Color3.fromRGB(20, 40, 32),
			ToggleEnabled = Color3.fromRGB(16, 185, 129),
			ToggleDisabled = Color3.fromRGB(50, 75, 65),
			ToggleEnabledStroke = Color3.fromRGB(52, 211, 153),
			ToggleDisabledStroke = Color3.fromRGB(70, 95, 85),
			ToggleEnabledOuterStroke = Color3.fromRGB(10, 110, 75),
			ToggleDisabledOuterStroke = Color3.fromRGB(35, 55, 45),
			DropdownSelected = Color3.fromRGB(24, 48, 38),
			DropdownUnselected = Color3.fromRGB(18, 36, 28),
			InputBackground = Color3.fromRGB(20, 40, 32),
			InputStroke = Color3.fromRGB(35, 85, 65),
			PlaceholderColor = Color3.fromRGB(130, 175, 155)
		},

		NordicFrost = {
			TextColor = Color3.fromRGB(236, 239, 244),
			Background = Color3.fromRGB(46, 52, 64),
			Topbar = Color3.fromRGB(59, 66, 82),
			Shadow = Color3.fromRGB(36, 41, 51),
			NotificationBackground = Color3.fromRGB(59, 66, 82),
			NotificationActionsBackground = Color3.fromRGB(229, 233, 240),
			TabBackground = Color3.fromRGB(67, 76, 94),
			TabStroke = Color3.fromRGB(76, 86, 106),
			TabBackgroundSelected = Color3.fromRGB(136, 192, 208),
			TabTextColor = Color3.fromRGB(229, 233, 240),
			SelectedTabTextColor = Color3.fromRGB(46, 52, 64),
			ElementBackground = Color3.fromRGB(59, 66, 82),
			ElementBackgroundHover = Color3.fromRGB(67, 76, 94),
			SecondaryElementBackground = Color3.fromRGB(53, 59, 74),
			ElementStroke = Color3.fromRGB(76, 86, 106),
			SecondaryElementStroke = Color3.fromRGB(70, 79, 98),
			SliderBackground = Color3.fromRGB(67, 76, 94),
			SliderProgress = Color3.fromRGB(136, 192, 208),
			SliderStroke = Color3.fromRGB(129, 161, 193),
			ToggleBackground = Color3.fromRGB(53, 59, 74),
			ToggleEnabled = Color3.fromRGB(136, 192, 208),
			ToggleDisabled = Color3.fromRGB(76, 86, 106),
			ToggleEnabledStroke = Color3.fromRGB(143, 188, 187),
			ToggleDisabledStroke = Color3.fromRGB(90, 100, 120),
			ToggleEnabledOuterStroke = Color3.fromRGB(94, 129, 172),
			ToggleDisabledOuterStroke = Color3.fromRGB(60, 68, 85),
			DropdownSelected = Color3.fromRGB(67, 76, 94),
			DropdownUnselected = Color3.fromRGB(59, 66, 82),
			InputBackground = Color3.fromRGB(53, 59, 74),
			InputStroke = Color3.fromRGB(76, 86, 106),
			PlaceholderColor = Color3.fromRGB(143, 188, 187)
		},

		Dracula = {
			TextColor = Color3.fromRGB(248, 248, 242),
			Background = Color3.fromRGB(40, 42, 54),
			Topbar = Color3.fromRGB(52, 55, 70),
			Shadow = Color3.fromRGB(30, 31, 41),
			NotificationBackground = Color3.fromRGB(52, 55, 70),
			NotificationActionsBackground = Color3.fromRGB(248, 248, 242),
			TabBackground = Color3.fromRGB(68, 71, 90),
			TabStroke = Color3.fromRGB(98, 114, 164),
			TabBackgroundSelected = Color3.fromRGB(189, 147, 249),
			TabTextColor = Color3.fromRGB(248, 248, 242),
			SelectedTabTextColor = Color3.fromRGB(40, 42, 54),
			ElementBackground = Color3.fromRGB(50, 52, 66),
			ElementBackgroundHover = Color3.fromRGB(62, 65, 82),
			SecondaryElementBackground = Color3.fromRGB(44, 46, 58),
			ElementStroke = Color3.fromRGB(98, 114, 164),
			SecondaryElementStroke = Color3.fromRGB(80, 95, 140),
			SliderBackground = Color3.fromRGB(68, 71, 90),
			SliderProgress = Color3.fromRGB(255, 121, 198),
			SliderStroke = Color3.fromRGB(255, 140, 210),
			ToggleBackground = Color3.fromRGB(50, 52, 66),
			ToggleEnabled = Color3.fromRGB(80, 250, 123),
			ToggleDisabled = Color3.fromRGB(98, 114, 164),
			ToggleEnabledStroke = Color3.fromRGB(100, 255, 140),
			ToggleDisabledStroke = Color3.fromRGB(120, 135, 180),
			ToggleEnabledOuterStroke = Color3.fromRGB(40, 160, 75),
			ToggleDisabledOuterStroke = Color3.fromRGB(70, 80, 115),
			DropdownSelected = Color3.fromRGB(62, 65, 82),
			DropdownUnselected = Color3.fromRGB(50, 52, 66),
			InputBackground = Color3.fromRGB(46, 48, 62),
			InputStroke = Color3.fromRGB(139, 233, 253),
			PlaceholderColor = Color3.fromRGB(139, 233, 253)
		},

		SolarFlare = {
			TextColor = Color3.fromRGB(255, 250, 240),
			Background = Color3.fromRGB(28, 18, 12),
			Topbar = Color3.fromRGB(42, 26, 18),
			Shadow = Color3.fromRGB(18, 10, 6),
			NotificationBackground = Color3.fromRGB(38, 22, 15),
			NotificationActionsBackground = Color3.fromRGB(255, 240, 225),
			TabBackground = Color3.fromRGB(58, 35, 22),
			TabStroke = Color3.fromRGB(95, 55, 35),
			TabBackgroundSelected = Color3.fromRGB(245, 158, 11),
			TabTextColor = Color3.fromRGB(250, 230, 210),
			SelectedTabTextColor = Color3.fromRGB(25, 15, 8),
			ElementBackground = Color3.fromRGB(40, 24, 16),
			ElementBackgroundHover = Color3.fromRGB(52, 32, 22),
			SecondaryElementBackground = Color3.fromRGB(34, 20, 14),
			ElementStroke = Color3.fromRGB(85, 48, 30),
			SecondaryElementStroke = Color3.fromRGB(70, 38, 24),
			SliderBackground = Color3.fromRGB(60, 36, 24),
			SliderProgress = Color3.fromRGB(245, 158, 11),
			SliderStroke = Color3.fromRGB(251, 191, 36),
			ToggleBackground = Color3.fromRGB(38, 22, 15),
			ToggleEnabled = Color3.fromRGB(234, 88, 12),
			ToggleDisabled = Color3.fromRGB(75, 50, 38),
			ToggleEnabledStroke = Color3.fromRGB(249, 115, 22),
			ToggleDisabledStroke = Color3.fromRGB(95, 65, 50),
			ToggleEnabledOuterStroke = Color3.fromRGB(160, 50, 10),
			ToggleDisabledOuterStroke = Color3.fromRGB(55, 35, 25),
			DropdownSelected = Color3.fromRGB(52, 32, 22),
			DropdownUnselected = Color3.fromRGB(40, 24, 16),
			InputBackground = Color3.fromRGB(36, 22, 14),
			InputStroke = Color3.fromRGB(100, 58, 35),
			PlaceholderColor = Color3.fromRGB(195, 145, 115)
		},

		ToxicHazard = {
			TextColor = Color3.fromRGB(230, 255, 230),
			Background = Color3.fromRGB(14, 18, 12),
			Topbar = Color3.fromRGB(22, 30, 18),
			Shadow = Color3.fromRGB(8, 12, 8),
			NotificationBackground = Color3.fromRGB(20, 28, 16),
			NotificationActionsBackground = Color3.fromRGB(225, 250, 225),
			TabBackground = Color3.fromRGB(30, 45, 24),
			TabStroke = Color3.fromRGB(55, 80, 40),
			TabBackgroundSelected = Color3.fromRGB(132, 204, 22),
			TabTextColor = Color3.fromRGB(215, 245, 215),
			SelectedTabTextColor = Color3.fromRGB(10, 20, 8),
			ElementBackground = Color3.fromRGB(22, 32, 18),
			ElementBackgroundHover = Color3.fromRGB(30, 42, 24),
			SecondaryElementBackground = Color3.fromRGB(18, 26, 15),
			ElementStroke = Color3.fromRGB(50, 75, 38),
			SecondaryElementStroke = Color3.fromRGB(40, 60, 30),
			SliderBackground = Color3.fromRGB(32, 50, 26),
			SliderProgress = Color3.fromRGB(132, 204, 22),
			SliderStroke = Color3.fromRGB(163, 230, 53),
			ToggleBackground = Color3.fromRGB(22, 32, 18),
			ToggleEnabled = Color3.fromRGB(132, 204, 22),
			ToggleDisabled = Color3.fromRGB(50, 70, 45),
			ToggleEnabledStroke = Color3.fromRGB(163, 230, 53),
			ToggleDisabledStroke = Color3.fromRGB(70, 95, 65),
			ToggleEnabledOuterStroke = Color3.fromRGB(80, 130, 15),
			ToggleDisabledOuterStroke = Color3.fromRGB(35, 50, 30),
			DropdownSelected = Color3.fromRGB(30, 44, 25),
			DropdownUnselected = Color3.fromRGB(22, 32, 18),
			InputBackground = Color3.fromRGB(20, 28, 16),
			InputStroke = Color3.fromRGB(60, 90, 45),
			PlaceholderColor = Color3.fromRGB(140, 185, 130)
		},

		RoseGold = {
			TextColor = Color3.fromRGB(255, 245, 245),
			Background = Color3.fromRGB(28, 16, 20),
			Topbar = Color3.fromRGB(40, 22, 28),
			Shadow = Color3.fromRGB(18, 10, 14),
			NotificationBackground = Color3.fromRGB(36, 20, 26),
			NotificationActionsBackground = Color3.fromRGB(255, 235, 240),
			TabBackground = Color3.fromRGB(55, 30, 38),
			TabStroke = Color3.fromRGB(90, 48, 60),
			TabBackgroundSelected = Color3.fromRGB(244, 114, 182),
			TabTextColor = Color3.fromRGB(248, 215, 225),
			SelectedTabTextColor = Color3.fromRGB(45, 15, 25),
			ElementBackground = Color3.fromRGB(38, 20, 26),
			ElementBackgroundHover = Color3.fromRGB(50, 28, 36),
			SecondaryElementBackground = Color3.fromRGB(32, 16, 22),
			ElementStroke = Color3.fromRGB(80, 42, 54),
			SecondaryElementStroke = Color3.fromRGB(68, 35, 45),
			SliderBackground = Color3.fromRGB(56, 30, 40),
			SliderProgress = Color3.fromRGB(244, 114, 182),
			SliderStroke = Color3.fromRGB(249, 168, 212),
			ToggleBackground = Color3.fromRGB(38, 20, 26),
			ToggleEnabled = Color3.fromRGB(236, 72, 153),
			ToggleDisabled = Color3.fromRGB(75, 45, 55),
			ToggleEnabledStroke = Color3.fromRGB(244, 114, 182),
			ToggleDisabledStroke = Color3.fromRGB(95, 60, 72),
			ToggleEnabledOuterStroke = Color3.fromRGB(160, 30, 95),
			ToggleDisabledOuterStroke = Color3.fromRGB(50, 30, 38),
			DropdownSelected = Color3.fromRGB(50, 28, 36),
			DropdownUnselected = Color3.fromRGB(38, 20, 26),
			InputBackground = Color3.fromRGB(34, 18, 24),
			InputStroke = Color3.fromRGB(95, 50, 65),
			PlaceholderColor = Color3.fromRGB(195, 140, 160)
		},

		DeepAbyss = {
			TextColor = Color3.fromRGB(230, 240, 255),
			Background = Color3.fromRGB(10, 14, 24),
			Topbar = Color3.fromRGB(14, 20, 36),
			Shadow = Color3.fromRGB(6, 8, 16),
			NotificationBackground = Color3.fromRGB(12, 18, 32),
			NotificationActionsBackground = Color3.fromRGB(225, 235, 250),
			TabBackground = Color3.fromRGB(20, 30, 52),
			TabStroke = Color3.fromRGB(32, 50, 85),
			TabBackgroundSelected = Color3.fromRGB(59, 130, 246),
			TabTextColor = Color3.fromRGB(210, 225, 250),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
			ElementBackground = Color3.fromRGB(16, 24, 42),
			ElementBackgroundHover = Color3.fromRGB(22, 34, 58),
			SecondaryElementBackground = Color3.fromRGB(12, 18, 32),
			ElementStroke = Color3.fromRGB(30, 48, 80),
			SecondaryElementStroke = Color3.fromRGB(24, 38, 65),
			SliderBackground = Color3.fromRGB(24, 38, 68),
			SliderProgress = Color3.fromRGB(59, 130, 246),
			SliderStroke = Color3.fromRGB(96, 165, 250),
			ToggleBackground = Color3.fromRGB(16, 24, 42),
			ToggleEnabled = Color3.fromRGB(59, 130, 246),
			ToggleDisabled = Color3.fromRGB(45, 60, 90),
			ToggleEnabledStroke = Color3.fromRGB(96, 165, 250),
			ToggleDisabledStroke = Color3.fromRGB(60, 80, 115),
			ToggleEnabledOuterStroke = Color3.fromRGB(30, 75, 160),
			ToggleDisabledOuterStroke = Color3.fromRGB(30, 40, 65),
			DropdownSelected = Color3.fromRGB(22, 34, 58),
			DropdownUnselected = Color3.fromRGB(16, 24, 42),
			InputBackground = Color3.fromRGB(14, 22, 38),
			InputStroke = Color3.fromRGB(40, 65, 110),
			PlaceholderColor = Color3.fromRGB(130, 160, 210)
		},

		Monochrome = {
			TextColor = Color3.fromRGB(250, 250, 250),
			Background = Color3.fromRGB(12, 12, 12),
			Topbar = Color3.fromRGB(20, 20, 20),
			Shadow = Color3.fromRGB(0, 0, 0),
			NotificationBackground = Color3.fromRGB(18, 18, 18),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),
			TabBackground = Color3.fromRGB(30, 30, 30),
			TabStroke = Color3.fromRGB(55, 55, 55),
			TabBackgroundSelected = Color3.fromRGB(240, 240, 240),
			TabTextColor = Color3.fromRGB(200, 200, 200),
			SelectedTabTextColor = Color3.fromRGB(15, 15, 15),
			ElementBackground = Color3.fromRGB(22, 22, 22),
			ElementBackgroundHover = Color3.fromRGB(32, 32, 32),
			SecondaryElementBackground = Color3.fromRGB(16, 16, 16),
			ElementStroke = Color3.fromRGB(48, 48, 48),
			SecondaryElementStroke = Color3.fromRGB(38, 38, 38),
			SliderBackground = Color3.fromRGB(40, 40, 40),
			SliderProgress = Color3.fromRGB(230, 230, 230),
			SliderStroke = Color3.fromRGB(255, 255, 255),
			ToggleBackground = Color3.fromRGB(24, 24, 24),
			ToggleEnabled = Color3.fromRGB(230, 230, 230),
			ToggleDisabled = Color3.fromRGB(60, 60, 60),
			ToggleEnabledStroke = Color3.fromRGB(255, 255, 255),
			ToggleDisabledStroke = Color3.fromRGB(80, 80, 80),
			ToggleEnabledOuterStroke = Color3.fromRGB(140, 140, 140),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 45, 45),
			DropdownSelected = Color3.fromRGB(32, 32, 32),
			DropdownUnselected = Color3.fromRGB(22, 22, 22),
			InputBackground = Color3.fromRGB(20, 20, 20),
			InputStroke = Color3.fromRGB(65, 65, 65),
			PlaceholderColor = Color3.fromRGB(160, 160, 160)
		}
	}
}





local RayfieldAssetId = customAssetId or 10804731440
local Rayfield = useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://"..RayfieldAssetId)[1]
local buildAttempts = 0
local correctBuild = false
local warned
local globalLoaded
local rayfieldDestroyed = false

repeat
	if Rayfield:FindFirstChild('Build') and Rayfield.Build.Value == InterfaceBuild then
		correctBuild = true
		break
	end

	correctBuild = false

	if not warned then
		warned = true
	end

	local toDestroy
	toDestroy, Rayfield = Rayfield, useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://"..RayfieldAssetId)[1]
	if toDestroy and not useStudio then toDestroy:Destroy() end

	buildAttempts = buildAttempts + 1
until buildAttempts >= 2

Rayfield.Enabled = false

if gethui then
	Rayfield.Parent = gethui()
elseif syn and syn.protect_gui then 
	syn.protect_gui(Rayfield)
	Rayfield.Parent = CoreGui
elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
	Rayfield.Parent = CoreGui:FindFirstChild("RobloxGui")
elseif not useStudio then
	Rayfield.Parent = CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
elseif not useStudio then
	for _, Interface in ipairs(CoreGui:GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
end

if secureMode and not customAssetId then
	secureNotify("default_asset", "Secure Mode", "You are using the default Rayfield asset ID. Set RAYFIELD_ASSET_ID to a custom upload to avoid detection.")
end

do
	local AssetPath = RayfieldFolder.."/Assets"
	local AssetBaseURL = "https://raw.githubusercontent.com/UnknownDeveloper-sqd/UnknownSquad-RayField-Lib/main/Assets/"

	local assetFiles = {
		["1"] = AssetBaseURL.."1.png",
		["2"] = AssetBaseURL.."2.png",
		["3"] = AssetBaseURL.."3.png",
		["4"] = AssetBaseURL.."4.png",
		["5"] = AssetBaseURL.."5.png",
		["6"] = AssetBaseURL.."6.png",
		["7"] = AssetBaseURL.."7.png",
		["8"] = AssetBaseURL.."8.png",
		["9"] = AssetBaseURL.."9.png",
		["10"] = AssetBaseURL.."10.png",
		["11"] = AssetBaseURL.."11.png",
		["12"] = AssetBaseURL.."12.png",
		["13"] = AssetBaseURL.."13.png",
		["14"] = AssetBaseURL.."14.png",
		["15"] = AssetBaseURL.."15.png",
		["16"] = AssetBaseURL.."16.png",
		["17"] = AssetBaseURL.."17.png",
		["18"] = AssetBaseURL.."18.png",
	}

	for id, _ in assetFiles do
		customAssets[tostring(id)] = ""
	end

	local hasCustomAsset = type(getcustomasset) == "function"
	local hasFilesystem = type(writefile) == "function" and type(makefolder) == "function" and type(isfile) == "function" and type(isfolder) == "function"

	if hasCustomAsset and hasFilesystem then
		local ok, err = pcall(function()
			ensureFolder(RayfieldFolder)
			ensureFolder(AssetPath)

			local attempted = {}
			local function nextToFetch()
				for id, _ in assetFiles do
					if not attempted[id] and not isfile(AssetPath.."/"..tostring(id)..".png") then
						return id
					end
				end
				return nil
			end

			if nextToFetch() then
				task.spawn(function()
					while true do
						local id = nextToFetch()
						if not id then break end
						local ok, res = pcall(requestFunc, {Url = assetFiles[id], Method = "GET"})
						if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
							pcall(writefile, AssetPath.."/"..tostring(id)..".png", res.Body)
						end
						attempted[id] = true
						task.wait()
					end
				end)

				while nextToFetch() do
					task.wait(0.1)
				end
			end

			for id, _ in assetFiles do
				local success, asset = pcall(getcustomasset, AssetPath.."/"..tostring(id)..".png")
				if success then
					customAssets[tostring(id)] = asset
				else
				end
			end
		end)

		if not ok then
			secureNotify("asset_load_fail", "Rayfield", "Failed to load custom assets. UI images may not display correctly.")
		end
	else
		secureNotify("no_getcustomasset", "Rayfield", "Your executor does not support getcustomasset. Some UI images may not render correctly.")
	end


	Rayfield.Main.Shadow.Image.Image = customAssets["2"]
	Rayfield.Main.Topbar.Hide.Image = customAssets["3"]
	Rayfield.Main.Topbar.ChangeSize.Image = customAssets["4"]
	Rayfield.Main.Topbar.Settings.Image = customAssets["5"]
	Rayfield.Main.Topbar.Icon.Image = customAssets["6"]
	Rayfield.Main.Topbar.Search.Image = customAssets["7"]
	Rayfield.Main.Topbar.Search.ImageRectOffset = Vector2.new(0, 0)
	Rayfield.Main.Topbar.Search.ImageRectSize = Vector2.new(0, 0)
	Rayfield.Main.Elements.Template.Toggle.Switch.Shadow.Image = customAssets["8"]
	Rayfield.Main.Elements.Template.Slider.Main.Shadow.Image = customAssets["8"]
	Rayfield.Main.Elements.Template.Dropdown.Toggle.Image = customAssets["9"]
	Rayfield.Main.Elements.Template.Dropdown.Toggle.ImageRectOffset = Vector2.new(0, 0)
	Rayfield.Main.Elements.Template.Dropdown.Toggle.ImageRectSize = Vector2.new(0, 0)
	Rayfield.Main.Elements.Template.Label.Icon.Image = customAssets["10"]
	Rayfield.Main.Elements.Template.ColorPicker.CPBackground.MainCP.Image = customAssets["11"]
	Rayfield.Main.Elements.Template.ColorPicker.CPBackground.MainCP.MainPoint.Image = customAssets["12"]
	Rayfield.Main.Elements.Template.ColorPicker.ColorSlider.SliderPoint.Image = customAssets["12"]
	Rayfield.Main.TabList.Template.Image.Image = customAssets["13"]
	Rayfield.Main.Search.Search.Image = customAssets["14"]
	Rayfield.Main.Search.Shadow.Image = customAssets["2"]
	Rayfield.Notifications.Template.Icon.Image = customAssets["15"]
	Rayfield.Notifications.Template.Shadow.Image = customAssets["16"]
		if type(writefile) == "function" and type(isfile) == "function" then
			pcall(function()
				ensureFolder(RayfieldFolder)
				ensureFolder(AssetPath)
				ensureFolder(ConfigurationFolder)
				if not isfile("1.png") then
					local b64String = "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44nGiq06CI4VW15pdnQP6qOq7Uxa/+IXv/K2s8466z/RsPKH8+q6Li/Plmm2iAwzrRl6EsLWPwAoLJJIs6vbTqcybP4GOUKiIkA5FqGdcm1sNz4yua7zjieeeOJjOWe9BKGpCDvP6omnn/oE/G1ejLDsMC1TUQkzZotKWlkcTKx3cHDwx97642/91tNPP/27x02Y0I+oXvbI4wxFYix52nZIF04OWlTRgS034Vhqv2zptvHmm2+e8fnPfv41jz766NlPP/H0uU8/+fTrGBuXPv7445c9+eQzy+jTS5977rlLtm3edskXN3/xoq1bt16wcePG127ZsuXczZt3nLNjx45zvvSl5ed8+ctfPveLX/zieatXr76Q8BLCy9asWXN5oefWXP7FG794+Zdv+vKyL3zhC5feeOONlyBz0bPPPnvhM8/cfMHNN3+lQzdf8Oyzqy9c89xzF1Huoueff/51q1atulg2fP7zn7/ss5/9/GWbN2y+5HOf+9xFjz321HmPPfbYeU888fT569ffcPHGdRuXyd6V2Hr99V+46IYbbjj/qaeeOk/hjU/deOHa59e+7smpM85/YsqUV92yceNccJj8yCOP6MCfiZvmauemXXNC+4HGt7JGiI4tY0fhCDMi+42AcBPtd4EQDARGCYF23CnUXH/w/gd/5OLXv/6rM2fP+Wlz7xefdZHr9ORufLR0szI4ISlz5wmZm7m7yM3M9VHZsolmClhxjjPyTE5x/Ze90sVe2uyhRDgQbCbfoW7vy5YtG164cOH/09fXPxcdCcI3YiM1lBIJLdr9a3brZPpUVbIqVea0xOC4uekSwHCUxRRP8+bNey9r+JWwlIZNLPyYRkBjDAP9G9/4xuSHH3r4s+yJn376qac+/czKZz/FPnode/TfPf/88x8foeee+1vxVj236lr24uve8573XLd61err1q5ee+3atWuv/cAHPvD373v/+65933ve9/ern1v195KF/vb5Z6Vj1cco85crVz77m3adJeotvmNDiY/W41Do3N22w1FHW+ejjz76YfD93K//+ge+xBdjX4WWb9iw4asbNrzwFeJfIf4lEfEvI/eV3/iN3/jKr//6+5d/4APvX752zdqvrV+7/mv0zdd+/f2/fuvrr3j9N+iz2973vvfd/v73v//2VatX3Ua/fAO65a477nhbW+c4DseM6SODfMxY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"
					local b64decode = (crypt and (crypt.base64decode or crypt.base64_decode))
						or (syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode)
						or base64_decode
					if b64decode then
						local ok, decoded = pcall(b64decode, b64String)
						if ok and decoded and #decoded > 0 then
							pcall(writefile, "1.png", decoded)
							pcall(writefile, AssetPath .. "/1.png", decoded)
						end
					end
				end
			end)
		end

		if type(getcustomasset) == "function" and isfile and (isfile("1.png") or isfile(AssetPath .. "/1.png")) then
			local logoFile = isfile("1.png") and "1.png" or (AssetPath .. "/1.png")
			Rayfield.Loading.Banner.Image = getcustomasset(logoFile)
		elseif customAssets["1"] and #customAssets["1"] > 0 then
			Rayfield.Loading.Banner.Image = customAssets["1"]
		end
	Rayfield.Loading.BackgroundTransparency = 1
	Rayfield.Loading.Banner.BackgroundTransparency = 1
	Rayfield.Loading.Banner.ScaleType = Enum.ScaleType.Fit
	Rayfield.Loading.Banner.Size = UDim2.new(0, 420, 0, 132)

end

local minSize = Vector2.new(1024, 768)
local useMobileSizing

if Rayfield.AbsoluteSize.X < minSize.X and Rayfield.AbsoluteSize.Y < minSize.Y then
	useMobileSizing = true
end

local useMobilePrompt = false
if UserInputService.TouchEnabled then
	useMobilePrompt = true
end



local Main = Rayfield.Main
local MPrompt = Rayfield:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
TabList.ZIndex = 10
Elements.ZIndex = 2
local dragBar = Rayfield:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil

local dragOffset = 255
local dragOffsetMobile = 150
local currentSavedWidth = 500
local currentSavedHeight = 475

local function updateDragBarPosition(instant)
	if not dragBar or not Main then return end
	local mainHeight = Main.Size.Y.Offset
	if mainHeight <= 0 then mainHeight = 475 end
	local mainWidth = Main.Size.X.Offset
	if mainWidth <= 0 then mainWidth = 500 end
	
	local targetYOffset = (mainHeight / 2) + 18
	local targetPos = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, Main.Position.Y.Scale, Main.Position.Y.Offset + targetYOffset)
	
	if instant then
		dragBar.Position = targetPos
	else
		TweenService:Create(dragBar, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
	end
end

Rayfield.DisplayOrder = 100
LoadingFrame.Version.Text = Release

local Icons = useStudio and require(script.Parent.icons) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua')

local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = Rayfield.Notifications
local keybindConnections = {}

local SelectedTheme = RayfieldLibrary.Theme.Default

local function ChangeTheme(Theme)
	if typeof(Theme) == 'string' then
		SelectedTheme = RayfieldLibrary.Theme[Theme]
	elseif typeof(Theme) == 'table' then
		SelectedTheme = Theme
	end

	local anim = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	TweenService:Create(Rayfield.Main, anim, {BackgroundColor3 = SelectedTheme.Background}):Play()
	TweenService:Create(Rayfield.Main.Topbar, anim, {BackgroundColor3 = SelectedTheme.Topbar}):Play()
	TweenService:Create(Rayfield.Main.Topbar.CornerRepair, anim, {BackgroundColor3 = SelectedTheme.Topbar}):Play()
	TweenService:Create(Rayfield.Main.Shadow.Image, anim, {ImageColor3 = SelectedTheme.Shadow}):Play()

	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
	if Topbar:FindFirstChild('Settings') then
		Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
		Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	end

	Main.Search.BackgroundColor3 = SelectedTheme.TextColor
	Main.Search.Shadow.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Input.PlaceholderColor3 = SelectedTheme.TextColor
	Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke

	if Main:FindFirstChild('Notice') then
		Main.Notice.BackgroundColor3 = SelectedTheme.Background
	end

	for _, text in ipairs(Rayfield:GetDescendants()) do
		if text.Parent and text.Parent.Parent ~= Notifications then
			if text:IsA('TextLabel') or text:IsA('TextBox') then
				text.TextColor3 = SelectedTheme.TextColor
				if SelectedTheme.Font then
					pcall(function() text.Font = SelectedTheme.Font end)
				end
			end
		end
	end

	for _, TabPage in ipairs(Elements:GetChildren()) do
		for _, Element in ipairs(TabPage:GetChildren()) do
			if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
				TweenService:Create(Element, anim, {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
				if Element:FindFirstChild('UIStroke') then
					TweenService:Create(Element.UIStroke, anim, {Color = SelectedTheme.ElementStroke}):Play()
				end

				local list = Element:FindFirstChild('List')
				if list then
					local selectedText = Element:FindFirstChild('Selected') and Element.Selected.Text or ""
					for _, opt in ipairs(list:GetChildren()) do
						if opt.ClassName == "Frame" and opt.Name ~= "Placeholder" then
							if opt.Name == selectedText then
								TweenService:Create(opt, anim, {BackgroundColor3 = SelectedTheme.DropdownSelected}):Play()
							else
								TweenService:Create(opt, anim, {BackgroundColor3 = SelectedTheme.DropdownUnselected}):Play()
							end
							if opt:FindFirstChild('UIStroke') then
								TweenService:Create(opt.UIStroke, anim, {Color = SelectedTheme.ElementStroke}):Play()
							end
						end
					end
				end

				local switch = Element:FindFirstChild('Switch')
				if switch then
					local isEnabled = switch.Position.X.Scale > 0.4
					if isEnabled then
						TweenService:Create(Element, anim, {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
					else
						TweenService:Create(Element, anim, {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
					end
				end

				local sliderMain = Element:FindFirstChild('Main')
				if sliderMain and sliderMain:FindFirstChild('Progress') then
					TweenService:Create(sliderMain, anim, {BackgroundColor3 = SelectedTheme.SliderBackground}):Play()
					TweenService:Create(sliderMain.Progress, anim, {BackgroundColor3 = SelectedTheme.SliderProgress}):Play()
				end
			end
		end
	end

	for _, TabButton in ipairs(TabList:GetChildren()) do
		if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" and TabButton.Name ~= "Template" then
			if TabButton:FindFirstChild('UIStroke') then
				TabButton.UIStroke.Color = SelectedTheme.TabStroke
			end
			if Elements.UIPageLayout and Elements.UIPageLayout.CurrentPage and Elements.UIPageLayout.CurrentPage.Name == TabButton.Name then
				TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
				if TabButton:FindFirstChild('Title') then TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor end
				if TabButton:FindFirstChild('Image') then TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor end
			else
				TabButton.BackgroundColor3 = SelectedTheme.TabBackground
				if TabButton:FindFirstChild('Title') then TabButton.Title.TextColor3 = SelectedTheme.TabTextColor end
				if TabButton:FindFirstChild('Image') then TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor end
			end
		end
	end
end

local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}
	if not Icons then
		return
	end
	name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
	local sizedicons = Icons['48px']
	local r = sizedicons[name]
	if not r then
		return nil
	end

	local rirs = r[2]
	local riro = r[3]

	if type(r[1]) ~= "number" or type(rirs) ~= "table" or type(riro) ~= "table" then
		return nil
	end

	local irs = Vector2.new(rirs[1], rirs[2])
	local iro = Vector2.new(riro[1], riro[2])

	local asset = {
		id = r[1],
		imageRectSize = irs,
		imageRectOffset = iro,
	}

	return asset
end
local function getAssetUri(id: any): string
	local assetUri = ""
	if type(id) == "number" then
		assetUri = "rbxassetid://" .. id
	elseif type(id) == "string" and not Icons then
	else
	end
	return assetUri
end

local function isCustomAsset(value)
	return type(value) == "string" and (string.find(value, "rbxasset://") == 1 or string.find(value, "rbxthumb://") == 1)
end

local function resolveIcon(icon)
	if not icon or icon == 0 then
		return "", nil, nil
	end

	if isCustomAsset(icon) then
		return icon, nil, nil
	end

	if secureMode then
		secureNotify("icon_blocked", "Secure Mode", "Element icons using asset IDs or Lucide names are blocked. Use getcustomasset() for icons to stay undetected.")
		return "", nil, nil
	end

	if typeof(icon) == "string" and Icons then
		local asset = getIcon(icon)
		return "rbxassetid://" .. asset.id, asset.imageRectOffset, asset.imageRectSize
	else
		return getAssetUri(icon), nil, nil
	end
end

local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
	local dragging = false
	local relative = nil

	local offset = Vector2.zero
	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		offset += getService('GuiService'):GetGuiInset()
	end

	local function connectFunctions()
		if dragBar and enableTaptic then
			dragBar.MouseEnter:Connect(function()
				if not dragging and not Hidden then
					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 120, 0, 4)}):Play()
				end
			end)

			dragBar.MouseLeave:Connect(function()
				if not dragging and not Hidden then
					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 100, 0, 4)}):Play()
				end
			end)
		end
	end

	connectFunctions()

	dragObject.InputBegan:Connect(function(input, processed)
		if processed then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = true

			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}):Play()
			end
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = false

			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}):Play()
			end
		end
	end)

	local renderStepped = RunService.RenderStepped:Connect(function()
		if dragging and not Hidden then
			local position = UserInputService:GetMouseLocation() + relative + offset
			local mainH = object.Size.Y.Offset
			if mainH <= 0 then mainH = 475 end
			local targetDragY = position.Y + (mainH / 2) + 18

			if enableTaptic and tapticOffset then
				TweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y)}):Play()
				if dragBar then
					TweenService:Create(dragBar, TweenInfo.new(0.05, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, targetDragY)}):Play()
				end
			else
				object.Position = UDim2.fromOffset(position.X, position.Y)
				if dragBar then
					dragBar.Position = UDim2.fromOffset(position.X, targetDragY)
				end
			end
		end
	end)

	object.Destroying:Connect(function()
		if inputEnded then inputEnded:Disconnect() end
		if renderStepped then renderStepped:Disconnect() end
	end)
end


local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadConfiguration(Configuration)
	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
	local changed

	if not success then return end

	for FlagName, Flag in pairs(RayfieldLibrary.Flags) do
		local FlagValue = Data[FlagName]

		if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
			task.spawn(function()
				if Flag.Type == "ColorPicker" then
					changed = true
					Flag:Set(UnpackColor(FlagValue))
				else
					if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
						changed = true
						Flag:Set(FlagValue) 	
					end
				end
			end)
		else
		end
	end

	return changed
end

local function SaveConfiguration()
	if not CEnabled or not globalLoaded then return end

	if debugX then
	end

	local Data = {}
	for i, v in pairs(RayfieldLibrary.Flags) do
		if v.Type == "ColorPicker" then
			Data[i] = PackColor(v.Color)
		else
			if typeof(v.CurrentValue) == 'boolean' then
				if v.CurrentValue == false then
					Data[i] = false
				else
					Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
				end
			else
				Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
			end
		end
	end

	if useStudio then
		if script.Parent:FindFirstChild('configuration') then script.Parent.configuration:Destroy() end

		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Parent = script.Parent
		ScreenGui.Name = 'configuration'

		local TextBox = Instance.new("TextBox")
		TextBox.Parent = ScreenGui
		TextBox.Size = UDim2.new(0, 800, 0, 50)
		TextBox.AnchorPoint = Vector2.new(0.5, 0)
		TextBox.Position = UDim2.new(0.5, 0, 0, 30)
		TextBox.Text = HttpService:JSONEncode(Data)
		TextBox.ClearTextOnFocus = false
	end

	if debugX then
	end


	callSafely(writefile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, tostring(HttpService:JSONEncode(Data)))
end

function RayfieldLibrary:Notify(data)
	task.spawn(function()

		local newNotification = Notifications.Template:Clone()
		newNotification.Name = data.Title or 'No Title Provided'
		newNotification.Parent = Notifications
		newNotification.LayoutOrder = #Notifications:GetChildren()
		newNotification.Visible = false

		newNotification.Title.Text = data.Title or "Unknown Title"
		newNotification.Description.Text = data.Content or "Unknown Content"

		if data.Image then
			local img, rectOffset, rectSize = resolveIcon(data.Image)
			newNotification.Icon.Image = img
			if rectOffset then newNotification.Icon.ImageRectOffset = rectOffset end
			if rectSize then newNotification.Icon.ImageRectSize = rectSize end
		else
			newNotification.Icon.Image = ""
		end


		newNotification.Title.TextColor3 = SelectedTheme.TextColor
		newNotification.Description.TextColor3 = SelectedTheme.TextColor
		newNotification.BackgroundColor3 = SelectedTheme.Background
		newNotification.UIStroke.Color = SelectedTheme.TextColor
		newNotification.Icon.ImageColor3 = SelectedTheme.TextColor

		newNotification.BackgroundTransparency = 1
		newNotification.Title.TextTransparency = 1
		newNotification.Description.TextTransparency = 1
		newNotification.UIStroke.Transparency = 1
		newNotification.Shadow.ImageTransparency = 1
		newNotification.Size = UDim2.new(1, 0, 0, 800)
		newNotification.Icon.ImageTransparency = 1
		newNotification.Icon.BackgroundTransparency = 1

		task.wait()

		newNotification.Visible = true

		if data.Actions then
		end

		local bounds = {newNotification.Title.TextBounds.Y, newNotification.Description.TextBounds.Y}
		newNotification.Size = UDim2.new(1, -60, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)

		newNotification.Icon.Size = UDim2.new(0, 32, 0, 32)
		newNotification.Icon.Position = UDim2.new(0, 20, 0.5, 0)

		TweenService:Create(newNotification, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, math.max(bounds[1] + bounds[2] + 31, 60))}):Play()

		task.wait(0.15)
		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.45}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

		task.wait(0.05)

		TweenService:Create(newNotification.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()

		task.wait(0.05)
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.35}):Play()
		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.95}):Play()
		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.82}):Play()

		local waitDuration = math.min(math.max((#newNotification.Description.Text * 0.1) + 2.5, 3), 10)
		task.wait(data.Duration or waitDuration)

		newNotification.Icon.Visible = false
		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, 0)}):Play()

		task.wait(1)

		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)}):Play()

		newNotification.Visible = false
		newNotification:Destroy()
	end)
end

local function openSearch()
	searchOpen = true

	Main.Search.BackgroundTransparency = 1
	Main.Search.Shadow.ImageTransparency = 1
	Main.Search.Input.TextTransparency = 1
	Main.Search.Search.ImageTransparency = 1
	Main.Search.UIStroke.Transparency = 1
	Main.Search.Size = UDim2.new(1, 0, 0, 80)
	Main.Search.Position = UDim2.new(0.5, 0, 0, 70)

	Main.Search.Input.Interactable = true

	Main.Search.Visible = true

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			tabbtn.Interact.Visible = false
			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
			TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
			TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		end
	end

	Main.Search.Input:CaptureFocus()
	TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.05, Enum.EasingStyle.Quint), {ImageTransparency = 0.95}):Play()
	TweenService:Create(Main.Search, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0, 57), BackgroundTransparency = 0.9}):Play()
	TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.8}):Play()
	TweenService:Create(Main.Search.Input, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
	TweenService:Create(Main.Search.Search, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
	TweenService:Create(Main.Search, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -35, 0, 35)}):Play()
end

local function closeSearch()
	searchOpen = false

	TweenService:Create(Main.Search, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, Size = UDim2.new(1, -55, 0, 30)}):Play()
	TweenService:Create(Main.Search.Search, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
	TweenService:Create(Main.Search.Input, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			tabbtn.Interact.Visible = true
			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			else
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
			end
		end
	end

	Main.Search.Input.Text = ''
	Main.Search.Input.Interactable = false
end

local function setElementsVisible(show)
	for _, tab in ipairs(Elements:GetChildren()) do
		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
			for _, element in ipairs(tab:GetChildren()) do
				if element.ClassName == "Frame" then
					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = show and 0.4 or 1}):Play()
						elseif element.Name == 'Divider' then
							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = show and 0.85 or 1}):Play()
						else
							local bgTarget = element:GetAttribute("BackgroundTransparencyTarget") or 0
							local strokeTarget = element:GetAttribute("UIStrokeTransparencyTarget") or 0
							local titleTarget = element:GetAttribute("TitleTextTransparencyTarget") or 0
							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = show and bgTarget or 1}):Play()
							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = show and strokeTarget or 1}):Play()
							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = show and titleTarget or 1}):Play()
						end
						for _, child in ipairs(element:GetChildren()) do
							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
								child.Visible = show
							end
						end
					end
				end
			end
		end
	end
end

local function setTabButtonsVisible(show)
	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			if show then
				if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
					TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
					TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
					TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
				else
					TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
					TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
					TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
					TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			else
				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			end
		end
	end
end

local function Hide(notify: boolean?)
	if MPrompt then
		MPrompt.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		MPrompt.Position = UDim2.new(0.5, 0, 0, -50)
		MPrompt.Size = UDim2.new(0, 40, 0, 10)
		MPrompt.BackgroundTransparency = 1
		MPrompt.Title.TextTransparency = 1
		MPrompt.Visible = true
	end

	task.spawn(closeSearch)

	Debounce = true
	if notify then
		if useMobilePrompt then 
			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = "The interface has been hidden, you can unhide the interface by tapping 'Show'.", Duration = 7, Image = 4400697855})
		else
			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = "The interface has been hidden, you can unhide the interface by tapping " .. tostring(getSetting("General", "rayfieldOpen")) .. ".", Duration = 7, Image = 4400697855})
		end
	end

	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 0)}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 45)}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar.CornerRepair, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main.Topbar.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
	if dragBarCosmetic then
		TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	end

	if useMobilePrompt and MPrompt then
		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(0.5, 0, 0, 20), BackgroundTransparency = 0.3}):Play()
		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.3}):Play()
	end

	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
		if TopbarButton.ClassName == "ImageButton" then
			TweenService:Create(TopbarButton, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
		end
	end

	setTabButtonsVisible(false)

	if dragInteract then dragInteract.Visible = false end

	setElementsVisible(false)

	task.wait(0.5)
	Main.Visible = false
	Debounce = false
end

local function Maximise()
	Debounce = true
	Topbar.ChangeSize.Image = customAssets["4"]

	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, currentSavedWidth, 0, 275) or UDim2.new(0, currentSavedWidth, 0, currentSavedHeight)}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, currentSavedWidth, 0, 45)}):Play(); updateDragBarPosition()
	TabList.Visible = true
	task.wait(0.2)

	Elements.Visible = true

	setElementsVisible(true)

	task.wait(0.1)

	setTabButtonsVisible(true)

	task.wait(0.5)
	Debounce = false
end


local function Unhide()
	Debounce = true
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Visible = true
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, currentSavedWidth, 0, 275) or UDim2.new(0, currentSavedWidth, 0, currentSavedHeight)}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, currentSavedWidth, 0, 45)}):Play(); updateDragBarPosition()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Topbar.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

	if MPrompt then
		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 40, 0, 10), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 1}):Play()
		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		task.spawn(function()
			task.wait(0.5)
			MPrompt.Visible = false
		end)
	end

	if Minimised then
		task.spawn(Maximise)
	end

	dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset)

	dragInteract.Visible = true

	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
		if TopbarButton.ClassName == "ImageButton" then
			if TopbarButton.Name == 'Icon' then
				TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			else
				TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
			end

		end
	end

	setTabButtonsVisible(true)

	setElementsVisible(true)

	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5}):Play()

	task.wait(0.5)
	Minimised = false
	Debounce = false
end

local function Minimise()
	Debounce = true
	Topbar.ChangeSize.Image = customAssets["17"]

	Topbar.UIStroke.Color = SelectedTheme.ElementStroke

	task.spawn(closeSearch)

	setTabButtonsVisible(false)

	setElementsVisible(false)

	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, currentSavedWidth, 0, 45)}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, currentSavedWidth, 0, 45)}):Play()

	task.wait(0.3)

	Elements.Visible = false
	TabList.Visible = false

	task.wait(0.2)
	Debounce = false
end

local function saveSettings()
	local encoded
	local success, err = pcall(function()
		encoded = HttpService:JSONEncode(settingsTable)
	end)

	if success then
		if useStudio then
			if script.Parent['get.val'] then
				script.Parent['get.val'].Value = encoded
			end
		end
		callSafely(writefile, RayfieldFolder..'/settings'..ConfigurationExtension, encoded)
	end
end

local function updateSetting(category: string, setting: string, value: any)
	if not settingsInitialized then
		return
	end
	settingsTable[category][setting].Value = value
	overriddenSettings[category .. "." .. setting] = nil
	saveSettings()
end

local function createSettings(window)
	local newTab = window:CreateTab("Settings", 0, true)

	if TabList["Settings"] then
		TabList["Settings"].LayoutOrder = 1000
	elseif TabList["Rayfield Settings"] then
		TabList["Rayfield Settings"].LayoutOrder = 1000
	end

	if Elements["Settings"] then
		Elements["Settings"].LayoutOrder = 1000
	elseif Elements["Rayfield Settings"] then
		Elements["Rayfield Settings"].LayoutOrder = 1000
	end

	local pickerSetters = {}

	newTab:CreateSection("Interface Scale & Dimensions")

	local widthSlider
	local heightSlider

	local function applySize(newW, newH, smooth)
		currentSavedWidth = newW
		currentSavedHeight = newH
		local tweenInfo = TweenInfo.new(smooth and 0.4 or 0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(Main, tweenInfo, {Size = UDim2.new(0, newW, 0, newH)}):Play()
		TweenService:Create(Topbar, tweenInfo, {Size = UDim2.new(0, newW, 0, 45)}):Play()
		updateDragBarPosition(not smooth)
	end

	widthSlider = newTab:CreateSlider({
		Name = "UI Width",
		Range = {380, 850},
		Increment = 5,
		Suffix = " px",
		CurrentValue = currentSavedWidth,
		Ext = true,
		Callback = function(Value)
			applySize(Value, currentSavedHeight, false)
		end
	})

	heightSlider = newTab:CreateSlider({
		Name = "UI Height",
		Range = {250, 750},
		Increment = 5,
		Suffix = " px",
		CurrentValue = currentSavedHeight,
		Ext = true,
		Callback = function(Value)
			applySize(currentSavedWidth, Value, false)
		end
	})

	newTab:CreateButton({
		Name = "Reset to Default Size",
		Ext = true,
		Callback = function()
			widthSlider:Set(500)
			heightSlider:Set(475)
			applySize(500, 475, true)
		end
	})

	newTab:CreateSection("Typography & Font")

	local fontList = {
		"AmaticSC",
		"Antique",
		"Arcade",
		"Arial",
		"ArialBold",
		"Arimo",
		"ArimoBold",
		"Bangers",
		"Bodoni",
		"BuilderSans",
		"BuilderSansBold",
		"BuilderSansExtraBold",
		"BuilderSansMedium",
		"Cartoon",
		"Code",
		"Creepster",
		"DenkOne",
		"Fantasy",
		"Fondamento",
		"FredokaOne",
		"Garamond",
		"Gotham",
		"GothamBlack",
		"GothamBold",
		"GothamMedium",
		"GrenzeGotisch",
		"Highway",
		"IndieFlower",
		"JosefinSans",
		"Jura",
		"Kalam",
		"Legacy",
		"LuckiestGuy",
		"Merriweather",
		"Michroma",
		"Montserrat",
		"Nunito",
		"Oswald",
		"PatrickHand",
		"PermanentMarker",
		"Roboto",
		"RobotoCondensed",
		"RobotoMono",
		"Sarpanch",
		"SciFi",
		"SourceSans",
		"SourceSansBold",
		"SourceSansItalic",
		"SourceSansLight",
		"SourceSansSemibold",
		"SpecialElite",
		"TitilliumWeb",
		"Ubuntu"
	}

	local fontDropdown = newTab:CreateDropdown({
		Name = "UI Font Family",
		Options = fontList,
		CurrentOption = {"Gotham"},
		MultipleOptions = false,
		Ext = true,
		Callback = function(Option)
			local chosen = typeof(Option) == "table" and Option[1] or Option
			local targetFont = safeFont(chosen) or Enum.Font.Gotham
			SelectedTheme.Font = targetFont
			for _, desc in ipairs(Rayfield:GetDescendants()) do
				if desc:IsA("TextLabel") or desc:IsA("TextBox") or desc:IsA("TextButton") then
					pcall(function() desc.Font = targetFont end)
				end
			end
		end
	})

	newTab:CreateSection("Theme Preset")

	local themeNames = {}
	for tName, _ in pairs(RayfieldLibrary.Theme) do
		table.insert(themeNames, tName)
	end
	table.sort(themeNames)

	local themeDropdown = newTab:CreateDropdown({
		Name = "Preset Themes",
		Options = themeNames,
		CurrentOption = {"Default"},
		MultipleOptions = false,
		Ext = true,
		Callback = function(Option)
			local chosen = typeof(Option) == "table" and Option[1] or Option
			if RayfieldLibrary.Theme[chosen] then
				ChangeTheme(chosen)
				for pName, setter in pairs(pickerSetters) do
					pcall(setter)
				end
			end
		end
	})

	newTab:CreateSection("Colors Customizer")

	local cpBg = newTab:CreateColorPicker({
		Name = "Window Background Color",
		Color = SelectedTheme.Background,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.Background = Color
			TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundColor3 = Color}):Play()
			if Main:FindFirstChild("Notice") then Main.Notice.BackgroundColor3 = Color end
		end
	})
	pickerSetters["Background"] = function() cpBg:Set(SelectedTheme.Background) end

	local cpTopbar = newTab:CreateColorPicker({
		Name = "Topbar Color",
		Color = SelectedTheme.Topbar,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.Topbar = Color
			TweenService:Create(Topbar, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundColor3 = Color}):Play()
			if Topbar:FindFirstChild("CornerRepair") then Topbar.CornerRepair.BackgroundColor3 = Color end
		end
	})
	pickerSetters["Topbar"] = function() cpTopbar:Set(SelectedTheme.Topbar) end

	local cpText = newTab:CreateColorPicker({
		Name = "Text Color",
		Color = SelectedTheme.TextColor,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.TextColor = Color
			for _, text in ipairs(Rayfield:GetDescendants()) do
				if text.Parent and text.Parent.Parent ~= Notifications then
					if text:IsA("TextLabel") or text:IsA("TextBox") then
						text.TextColor3 = Color
					end
				end
			end
			Topbar.ChangeSize.ImageColor3 = Color
			Topbar.Hide.ImageColor3 = Color
			Topbar.Search.ImageColor3 = Color
			if Topbar:FindFirstChild("Settings") then Topbar.Settings.ImageColor3 = Color end
		end
	})
	pickerSetters["TextColor"] = function() cpText:Set(SelectedTheme.TextColor) end

	local cpElementBg = newTab:CreateColorPicker({
		Name = "Element Background Color",
		Color = SelectedTheme.ElementBackground,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.ElementBackground = Color
			for _, TabPage in ipairs(Elements:GetChildren()) do
				for _, Element in ipairs(TabPage:GetChildren()) do
					if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
						TweenService:Create(Element, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundColor3 = Color}):Play()
					end
				end
			end
		end
	})
	pickerSetters["ElementBackground"] = function() cpElementBg:Set(SelectedTheme.ElementBackground) end

	local cpStroke = newTab:CreateColorPicker({
		Name = "Element Stroke / Border Color",
		Color = SelectedTheme.ElementStroke,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.ElementStroke = Color
			for _, TabPage in ipairs(Elements:GetChildren()) do
				for _, Element in ipairs(TabPage:GetChildren()) do
					if Element.ClassName == "Frame" and Element:FindFirstChild("UIStroke") then
						Element.UIStroke.Color = Color
					end
				end
			end
			if Topbar:FindFirstChild("Divider") then Topbar.Divider.BackgroundColor3 = Color end
		end
	})
	pickerSetters["ElementStroke"] = function() cpStroke:Set(SelectedTheme.ElementStroke) end

	local cpTabBg = newTab:CreateColorPicker({
		Name = "Tab Background Color",
		Color = SelectedTheme.TabBackground,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.TabBackground = Color
			for _, TabButton in ipairs(TabList:GetChildren()) do
				if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" and TabButton.Name ~= "Template" then
					if not (Elements.UIPageLayout and Elements.UIPageLayout.CurrentPage and Elements.UIPageLayout.CurrentPage.Name == TabButton.Name) then
						TabButton.BackgroundColor3 = Color
					end
				end
			end
		end
	})
	pickerSetters["TabBackground"] = function() cpTabBg:Set(SelectedTheme.TabBackground) end

	local cpTabSelected = newTab:CreateColorPicker({
		Name = "Tab Selected Color",
		Color = SelectedTheme.TabBackgroundSelected,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.TabBackgroundSelected = Color
			for _, TabButton in ipairs(TabList:GetChildren()) do
				if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" and TabButton.Name ~= "Template" then
					if Elements.UIPageLayout and Elements.UIPageLayout.CurrentPage and Elements.UIPageLayout.CurrentPage.Name == TabButton.Name then
						TabButton.BackgroundColor3 = Color
					end
				end
			end
		end
	})
	pickerSetters["TabBackgroundSelected"] = function() cpTabSelected:Set(SelectedTheme.TabBackgroundSelected) end

	local cpAccent = newTab:CreateColorPicker({
		Name = "Accent / Toggle Enabled Color",
		Color = SelectedTheme.ToggleEnabled,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.ToggleEnabled = Color
			SelectedTheme.SliderProgress = Color
			SelectedTheme.SliderBackground = Color
		end
	})
	pickerSetters["ToggleEnabled"] = function() cpAccent:Set(SelectedTheme.ToggleEnabled) end

	local cpShadow = newTab:CreateColorPicker({
		Name = "Shadow / Glow Color",
		Color = SelectedTheme.Shadow,
		Ext = true,
		Callback = function(Color)
			SelectedTheme.Shadow = Color
			Main.Shadow.Image.ImageColor3 = Color
		end
	})
	pickerSetters["Shadow"] = function() cpShadow:Set(SelectedTheme.Shadow) end

	newTab:CreateSection("GUI Configuration")

	local configFilePath = RayfieldFolder .. "/GUI_Customizer_Config.json"

	newTab:CreateButton({
		Name = "Save GUI Config",
		Ext = true,
		Callback = function()
			local configData = {
				Width = currentSavedWidth,
				Height = currentSavedHeight,
				Font = SelectedTheme.Font and SelectedTheme.Font.Name or "Gotham",
				ThemeColors = {
					Background = {SelectedTheme.Background.R, SelectedTheme.Background.G, SelectedTheme.Background.B},
					Topbar = {SelectedTheme.Topbar.R, SelectedTheme.Topbar.G, SelectedTheme.Topbar.B},
					TextColor = {SelectedTheme.TextColor.R, SelectedTheme.TextColor.G, SelectedTheme.TextColor.B},
					ElementBackground = {SelectedTheme.ElementBackground.R, SelectedTheme.ElementBackground.G, SelectedTheme.ElementBackground.B},
					ElementStroke = {SelectedTheme.ElementStroke.R, SelectedTheme.ElementStroke.G, SelectedTheme.ElementStroke.B},
					TabBackground = {SelectedTheme.TabBackground.R, SelectedTheme.TabBackground.G, SelectedTheme.TabBackground.B},
					TabBackgroundSelected = {SelectedTheme.TabBackgroundSelected.R, SelectedTheme.TabBackgroundSelected.G, SelectedTheme.TabBackgroundSelected.B},
					ToggleEnabled = {SelectedTheme.ToggleEnabled.R, SelectedTheme.ToggleEnabled.G, SelectedTheme.ToggleEnabled.B},
					Shadow = {SelectedTheme.Shadow.R, SelectedTheme.Shadow.G, SelectedTheme.Shadow.B}
				}
			}

			local ok, encoded = pcall(function() return HttpService:JSONEncode(configData) end)
			if ok and writefile then
				ensureFolder(RayfieldFolder)
				callSafely(writefile, configFilePath, encoded)
				RayfieldLibrary:Notify({
					Title = "GUI Config",
					Content = "GUI customization profile saved successfully!",
					Duration = 4,
					Image = 4483362458
				})
			end
		end
	})

	newTab:CreateButton({
		Name = "Load GUI Config",
		Ext = true,
		Callback = function()
			if isfile and isfile(configFilePath) then
				local content = callSafely(readfile, configFilePath)
				if content then
					local ok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
					if ok and decoded then
						if decoded.Width and decoded.Height then
							widthSlider:Set(decoded.Width)
							heightSlider:Set(decoded.Height)
							applySize(decoded.Width, decoded.Height, true)
						end
						if decoded.Font and safeFont(decoded.Font) then
							fontDropdown:Set(decoded.Font)
						end
						if decoded.ThemeColors then
							for cKey, cVal in pairs(decoded.ThemeColors) do
								if SelectedTheme[cKey] and type(cVal) == "table" then
									local colorObj = Color3.new(cVal[1], cVal[2], cVal[3])
									SelectedTheme[cKey] = colorObj
								end
							end
							ChangeTheme(SelectedTheme)
							for pName, setter in pairs(pickerSetters) do
								pcall(setter)
							end
						end
						RayfieldLibrary:Notify({
							Title = "GUI Config",
							Content = "GUI customization loaded successfully!",
							Duration = 4,
							Image = 4483362458
						})
						return
					end
				end
			end
			RayfieldLibrary:Notify({
				Title = "GUI Config",
				Content = "No saved configuration file found.",
				Duration = 3,
				Image = 4335487866
			})
		end
	})

	newTab:CreateSection("Keybind & System")

	for categoryName, settingCategory in pairs(settingsTable) do
		for settingName, setting in pairs(settingCategory) do
			if setting.Type == "input" then
				setting.Element = newTab:CreateInput({
					Name = setting.Name,
					CurrentValue = setting.Value,
					PlaceholderText = setting.Placeholder,
					Ext = true,
					RemoveTextAfterFocusLost = setting.ClearOnFocus,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			elseif setting.Type == "toggle" then
				setting.Element = newTab:CreateToggle({
					Name = setting.Name,
					CurrentValue = setting.Value,
					Ext = true,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			elseif setting.Type == "bind" then
				setting.Element = newTab:CreateKeybind({
					Name = setting.Name,
					CurrentKeybind = setting.Value,
					HoldToInteract = false,
					Ext = true,
					CallOnChange = true,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			end
		end
	end

	settingsCreated = true
	loadSettings()
	saveSettings()
end

local function fadeOutKeyUI(KeyMain)
	TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
	TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
	TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
	TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
	TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
end

function RayfieldLibrary:CreateWindow(Settings)
	if Rayfield:FindFirstChild('Loading') then
		if getgenv and not getgenv().rayfieldCached then
			Rayfield.Enabled = true
			Rayfield.Loading.BackgroundTransparency = 1
			Rayfield.Loading.Visible = true

			local banner = Rayfield.Loading:FindFirstChild('Banner')
			if banner then
				banner.BackgroundTransparency = 1
				banner.ScaleType = Enum.ScaleType.Fit
				banner.Size = UDim2.new(0, 390, 0, 122)
				banner.ImageTransparency = 1
				TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					ImageTransparency = 0,
					Size = UDim2.new(0, 420, 0, 132)
				}):Play()
			end

			task.wait(1.8)

			if banner then
				local fadeOut = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					ImageTransparency = 1,
					Size = UDim2.new(0, 440, 0, 138)
				})
				fadeOut:Play()
				fadeOut.Completed:Wait()
			end

			Rayfield.Loading.Visible = false
		end
	end

	if getgenv then getgenv().rayfieldCached = true end

	if not correctBuild and not Settings.DisableBuildWarnings then
		task.delay(3, 
			function() 
				RayfieldLibrary:Notify({Title = 'Build Mismatch', Content = 'Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.\n\nTry rejoining and then run the script twice.', Image = 4335487866, Duration = 15})		
			end)
	end

	if Settings.ToggleUIKeybind then
		local keybind = Settings.ToggleUIKeybind
		if type(keybind) == "string" then
			keybind = string.upper(keybind)
			assert(pcall(function()
				return Enum.KeyCode[keybind]
			end), "ToggleUIKeybind must be a valid KeyCode")
			overrideSetting("General", "rayfieldOpen", keybind)
		elseif typeof(keybind) == "EnumItem" then
			assert(keybind.EnumType == Enum.KeyCode, "ToggleUIKeybind must be a KeyCode enum")
			overrideSetting("General", "rayfieldOpen", keybind.Name)
		else
			overrideSetting("General", "rayfieldOpen", "K")
		end
	end

	ensureFolder(RayfieldFolder)

	local Passthrough = false
	Topbar.Title.Text = Settings.Name

	Main.Size = UDim2.new(0, 420, 0, 100)
	Main.Visible = true
	Main.BackgroundTransparency = 1
	if Main:FindFirstChild('Notice') then Main.Notice.Visible = false end
	Main.Shadow.Image.ImageTransparency = 1

	LoadingFrame.Title.TextTransparency = 1
	LoadingFrame.Subtitle.TextTransparency = 1

	if Settings.ShowText then
		MPrompt.Title.Text = 'Show '..Settings.ShowText
	end

	LoadingFrame.Version.TextTransparency = 1
	LoadingFrame.Title.Text = Settings.LoadingTitle or "Rayfield"
	LoadingFrame.Subtitle.Text = Settings.LoadingSubtitle or "Interface Suite"

	if Settings.LoadingTitle ~= "Rayfield Interface Suite" then
		LoadingFrame.Version.Text = "Rayfield UI"
	end

	if Settings.Icon and Settings.Icon ~= 0 and Topbar:FindFirstChild('Icon') then
		Topbar.Icon.Visible = true
		Topbar.Title.Position = UDim2.new(0, 47, 0.5, 0)

		if Settings.Icon then
			local img, rectOffset, rectSize = resolveIcon(Settings.Icon)
			Topbar.Icon.Image = img
			if rectOffset then Topbar.Icon.ImageRectOffset = rectOffset end
			if rectSize then Topbar.Icon.ImageRectSize = rectSize end
		else
			Topbar.Icon.Image = ""
		end
	end

	if dragBar then
		dragBar.Visible = false
		dragBarCosmetic.BackgroundTransparency = 1
		dragBar.Visible = true
	end

	if Settings.Theme then
		local success, result = pcall(ChangeTheme, Settings.Theme)
		if not success then
			local success, result2 = pcall(ChangeTheme, 'Default')
			if not success then
			end
		end
	end

	Topbar.Visible = false
	Elements.Visible = false
	LoadingFrame.Visible = true

	if not Settings.DisableRayfieldPrompts then
		task.spawn(function()
			while not rayfieldDestroyed do
				task.wait(math.random(180, 600))
				if rayfieldDestroyed then break end
				RayfieldLibrary:Notify({
					Title = "Rayfield Interface",
					Content = "Enjoying this UI library? Find it at sirius.menu/discord",
					Duration = 7,
					Image = 4370033185,
				})
			end
		end)
	end

	pcall(function()
		if not Settings.ConfigurationSaving.FileName then
			Settings.ConfigurationSaving.FileName = tostring(game.PlaceId)
		end

		if Settings.ConfigurationSaving.Enabled == nil then
			Settings.ConfigurationSaving.Enabled = false
		end

		CFileName = Settings.ConfigurationSaving.FileName
		ConfigurationFolder = Settings.ConfigurationSaving.FolderName or ConfigurationFolder
		CEnabled = Settings.ConfigurationSaving.Enabled

		if Settings.ConfigurationSaving.Enabled then
			ensureFolder(ConfigurationFolder)
		end
	end)


	makeDraggable(Main, Topbar, false, {dragOffset, dragOffsetMobile})
	if dragBar then dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset) makeDraggable(Main, dragInteract, true, {dragOffset, dragOffsetMobile}) end

	for _, TabButton in ipairs(TabList:GetChildren()) do
		if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" then
			TabButton.BackgroundTransparency = 1
			TabButton.Title.TextTransparency = 1
			TabButton.Image.ImageTransparency = 1
			TabButton.UIStroke.Transparency = 1
		end
	end

	if Settings.Discord and Settings.Discord.Enabled and not useStudio and not secureMode then
		ensureFolder(RayfieldFolder.."/Discord Invites")

		if not callSafely(isfile, RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension) then
			if requestFunc then
				pcall(function()
					requestFunc({
						Url = 'http://127.0.0.1:6463/rpc?v=1',
						Method = 'POST',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = 'https://discord.com'
						},
						Body = HttpService:JSONEncode({
							cmd = 'INVITE_BROWSER',
							nonce = HttpService:GenerateGUID(false),
							args = {code = Settings.Discord.Invite}
						})
					})
				end)
			end

			if Settings.Discord.RememberJoins then
				callSafely(writefile, RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension,"Rayfield RememberJoins is true for this invite, this invite will not ask you to join again")
			end
		end
	end

	if (Settings.KeySystem) then
		if not Settings.KeySettings then
			Passthrough = true
			return
		end

		ensureFolder(RayfieldFolder.."/Key System")

		if typeof(Settings.KeySettings.Key) == "string" then Settings.KeySettings.Key = {Settings.KeySettings.Key} end

		if Settings.KeySettings.GrabKeyFromSite then
			for i, Key in ipairs(Settings.KeySettings.Key) do
				local Success, Response = pcall(function()
					Settings.KeySettings.Key[i] = tostring(game:HttpGet(Key):gsub("[\n\r]", " "))
					Settings.KeySettings.Key[i] = string.gsub(Settings.KeySettings.Key[i], " ", "")
				end)
				if not Success then
				end
			end
		end

		if not Settings.KeySettings.FileName then
			Settings.KeySettings.FileName = "No file name specified"
		end

		if callSafely(isfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension) then
			for _, MKey in ipairs(Settings.KeySettings.Key) do
				local savedKeys = callSafely(readfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension)
				if savedKeys and string.find(savedKeys, MKey) then
					Passthrough = true
				end
			end
		end

		if not Passthrough and secureMode then
			Rayfield.Enabled = false
			return RayfieldLibrary
		end

		if not Passthrough then
			local AttemptsRemaining = Settings.KeySettings.MaxAttempts or 5
			Rayfield.Enabled = false
			local KeyUI = useStudio and script.Parent:FindFirstChild('Key') or game:GetObjects("rbxassetid://11380036235")[1]

			KeyUI.Enabled = true

			if gethui then
				KeyUI.Parent = gethui()
			elseif syn and syn.protect_gui then 
				syn.protect_gui(KeyUI)
				KeyUI.Parent = CoreGui
			elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
				KeyUI.Parent = CoreGui:FindFirstChild("RobloxGui")
			elseif not useStudio then
				KeyUI.Parent = CoreGui
			end

			if gethui then
				for _, Interface in ipairs(gethui():GetChildren()) do
					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
						Interface.Enabled = false
						Interface.Name = "KeyUI-Old"
					end
				end
			elseif not useStudio then
				for _, Interface in ipairs(CoreGui:GetChildren()) do
					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
						Interface.Enabled = false
						Interface.Name = "KeyUI-Old"
					end
				end
			end

			local KeyMain = KeyUI.Main
			KeyMain.Title.Text = Settings.KeySettings.Title or Settings.Name
			KeyMain.Subtitle.Text = Settings.KeySettings.Subtitle or "Key System"
			KeyMain.NoteMessage.Text = Settings.KeySettings.Note or "No instructions"

			KeyMain.Size = UDim2.new(0, 467, 0, 175)
			KeyMain.BackgroundTransparency = 1
			KeyMain.Shadow.Image.ImageTransparency = 1
			KeyMain.Title.TextTransparency = 1
			KeyMain.Subtitle.TextTransparency = 1
			KeyMain.KeyNote.TextTransparency = 1
			KeyMain.Input.BackgroundTransparency = 1
			KeyMain.Input.UIStroke.Transparency = 1
			KeyMain.Input.InputBox.TextTransparency = 1
			KeyMain.NoteTitle.TextTransparency = 1
			KeyMain.NoteMessage.TextTransparency = 1
			KeyMain.Hide.ImageTransparency = 1

			TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
			TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
			task.wait(0.05)
			TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			task.wait(0.05)
			TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			task.wait(0.05)
			TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			task.wait(0.15)
			TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.3}):Play()


			KeyUI.Main.Input.InputBox.FocusLost:Connect(function()
				if #KeyUI.Main.Input.InputBox.Text == 0 then return end
				local KeyFound = false
				local FoundKey = ''
				for _, MKey in ipairs(Settings.KeySettings.Key) do


					if KeyMain.Input.InputBox.Text == MKey then
						KeyFound = true
						FoundKey = MKey
					end
				end
				if KeyFound then
					fadeOutKeyUI(KeyMain)
					task.wait(0.51)
					Passthrough = true
					KeyMain.Visible = false
					if Settings.KeySettings.SaveKey then
						callSafely(writefile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension, FoundKey)
						RayfieldLibrary:Notify({Title = "Key System", Content = "The key for this script has been saved successfully.", Image = 3605522284})
					end
				else
					if AttemptsRemaining == 0 then
						fadeOutKeyUI(KeyMain)
						task.wait(0.45)
						Players.LocalPlayer:Kick("No Attempts Remaining")
						game:Shutdown()
					end
					KeyMain.Input.InputBox.Text = ""
					AttemptsRemaining = AttemptsRemaining - 1
					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.495,0,0.5,0)}):Play()
					task.wait(0.1)
					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.505,0,0.5,0)}):Play()
					task.wait(0.1)
					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5,0,0.5,0)}):Play()
					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
				end
			end)

			KeyMain.Hide.MouseButton1Click:Connect(function()
				fadeOutKeyUI(KeyMain)
				task.wait(0.51)
				Passthrough = true
				RayfieldLibrary:Destroy()
				KeyUI:Destroy()
			end)
		else
			Passthrough = true
		end
	end
	if Settings.KeySystem then
		repeat task.wait() until Passthrough
		if rayfieldDestroyed then return end
	end

	Notifications.Template.Visible = false
	Notifications.Visible = true
	Rayfield.Enabled = true

	task.wait(0.5)
	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
	task.wait(0.1)
	TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	task.wait(0.05)
	TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	task.wait(0.05)
	TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()


	Elements.Template.LayoutOrder = 100000
	Elements.Template.Visible = false

	Elements.UIPageLayout.FillDirection = Enum.FillDirection.Horizontal
	Elements.UIPageLayout.ScrollWheelInputEnabled = false
	Elements.UIPageLayout.GamepadInputEnabled = false
	Elements.UIPageLayout.TouchInputEnabled = false
	TabList.Template.Visible = false

	local FirstTab = false
	local Window = {}
	function Window:CreateTab(Name, Image, Ext)
		local SDone = false
		local TabButton = TabList.Template:Clone()
		TabButton.Name = Name
		TabButton.Title.Text = Name
		TabButton.Parent = TabList
		TabButton.Title.TextWrapped = false
		TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 30, 0, 30)

		if Image and Image ~= 0 then
			local img, rectOffset, rectSize = resolveIcon(Image)
			TabButton.Image.Image = img
			if rectOffset then TabButton.Image.ImageRectOffset = rectOffset end
			if rectSize then TabButton.Image.ImageRectSize = rectSize end

			TabButton.Title.AnchorPoint = Vector2.new(0, 0.5)
			TabButton.Title.Position = UDim2.new(0, 37, 0.5, 0)
			TabButton.Image.Visible = true
			TabButton.Title.TextXAlignment = Enum.TextXAlignment.Left
			TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 52, 0, 30)
		end



		TabButton.BackgroundTransparency = 1
		TabButton.Title.TextTransparency = 1
		TabButton.Image.ImageTransparency = 1
		TabButton.UIStroke.Transparency = 1

		TabButton.Visible = not Ext or false

		local TabPage = Elements.Template:Clone()
		TabPage.Name = Name
		TabPage.Visible = true

		local TabPadding = TabPage:FindFirstChildOfClass("UIPadding")
		if not TabPadding then
			TabPadding = Instance.new("UIPadding")
			TabPadding.PaddingTop = UDim.new(0, 6)
			TabPadding.PaddingBottom = UDim.new(0, 8)
			TabPadding.PaddingLeft = UDim.new(0, 0)
			TabPadding.PaddingRight = UDim.new(0, 0)
			TabPadding.Parent = TabPage
		end

		TabPage.LayoutOrder = Ext and 10000 or #Elements:GetChildren()

		for _, TemplateElement in ipairs(TabPage:GetChildren()) do
			if TemplateElement.ClassName == "Frame" and TemplateElement.Name ~= "Placeholder" then
				TemplateElement:Destroy()
			end
		end

		TabPage.Parent = Elements
		if not FirstTab and not Ext then
			Elements.UIPageLayout.Animated = false
			Elements.UIPageLayout:JumpTo(TabPage)
			Elements.UIPageLayout.Animated = true
		end

		TabButton.UIStroke.Color = SelectedTheme.TabStroke

		if Elements.UIPageLayout.CurrentPage == TabPage then
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
		else
			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
		end


		task.wait(0.1)
		if FirstTab or Ext then
			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
		elseif not Ext then
			FirstTab = Name
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		end


		TabButton.Interact.MouseButton1Click:Connect(function()
			if Minimised then return end
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackgroundSelected}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.SelectedTabTextColor}):Play()
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.SelectedTabTextColor}):Play()

			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton and OtherTabButton.Name ~= "Placeholder" then
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackground}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end

			if Elements.UIPageLayout.CurrentPage ~= TabPage then
				Elements.UIPageLayout:JumpTo(TabPage)
			end
		end)

		local Tab = {}

		function Tab:CreateButton(ButtonSettings)
			local ButtonValue = {}

			local Button = Elements.Template.Button:Clone()
			Button.Name = ButtonSettings.Name
			Button.Title.Text = ButtonSettings.Name
			Button.Visible = true
			Button.Parent = TabPage

			Button.BackgroundTransparency = 1
			Button.UIStroke.Transparency = 1
			Button.Title.TextTransparency = 1

			TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Button.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	


			Button.Interact.MouseButton1Click:Connect(function()
				local Success, Response = pcall(ButtonSettings.Callback)
				if rayfieldDestroyed then
					return
				end
				if not Success then
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Button.Title.Text = "Callback Error"
					task.wait(0.5)
					Button.Title.Text = ButtonSettings.Name
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				else
					if not ButtonSettings.Ext then
						SaveConfiguration(ButtonSettings.Name..'\n')
					end
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					task.wait(0.2)
					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end
			end)

			Button.MouseEnter:Connect(function()
				TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
				TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.7}):Play()
			end)

			Button.MouseLeave:Connect(function()
				TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
				TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
			end)

			function ButtonValue:Set(NewButton)
				Button.Title.Text = NewButton
				Button.Name = NewButton
			end

			return ButtonValue
		end

		function Tab:CreateColorPicker(ColorPickerSettings)
			ColorPickerSettings.Type = "ColorPicker"
			local ColorPicker = Elements.Template.ColorPicker:Clone()
			local Background = ColorPicker.CPBackground
			local Display = Background.Display
			local Main = Background.MainCP
			local Slider = ColorPicker.ColorSlider
			ColorPicker.ClipsDescendants = true
			ColorPicker.Name = ColorPickerSettings.Name
			ColorPicker.Title.Text = ColorPickerSettings.Name
			ColorPicker.Visible = true
			ColorPicker.Parent = TabPage
			ColorPicker.Size = UDim2.new(1, -10, 0, 45)
			Background.Size = UDim2.new(0, 39, 0, 22)
			Display.BackgroundTransparency = 0
			Main.MainPoint.ImageTransparency = 1
			ColorPicker.Interact.Size = UDim2.new(1, 0, 1, 0)
			ColorPicker.Interact.Position = UDim2.new(0.5, 0, 0.5, 0)
			ColorPicker.RGB.Position = UDim2.new(0, 17, 0, 70)
			ColorPicker.HexInput.Position = UDim2.new(0, 17, 0, 90)
			Main.ImageTransparency = 1
			Background.BackgroundTransparency = 1

			for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
				if rgbinput:IsA("Frame") then
					rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
					rgbinput.UIStroke.Color = SelectedTheme.InputStroke
				end
			end

			ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
			ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke

			local opened = false 
			local mouse = Players.LocalPlayer:GetMouse()
			local mainDragging = false 
			local sliderDragging = false 
			ColorPicker.Interact.MouseButton1Down:Connect(function()
				task.spawn(function()
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					task.wait(0.2)
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end)

				if not opened then
					opened = true 
					TweenService:Create(Background, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 18, 0, 15)}):Play()
					task.wait(0.1)
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 120)}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 173, 0, 86)}):Play()
					TweenService:Create(Display, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.289, 0, 0.5, 0)}):Play()
					TweenService:Create(ColorPicker.RGB, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 40)}):Play()
					TweenService:Create(ColorPicker.HexInput, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 73)}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0.574, 0, 1, 0)}):Play()
					TweenService:Create(Main.MainPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
					TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = SelectedTheme ~= RayfieldLibrary.Theme.Default and 0.25 or 0.1}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				else
					opened = false
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 39, 0, 22)}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 1, 0)}):Play()
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					TweenService:Create(ColorPicker.RGB, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 70)}):Play()
					TweenService:Create(ColorPicker.HexInput, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 90)}):Play()
					TweenService:Create(Display, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
					TweenService:Create(Main.MainPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
					TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
				end

			end)

			local colorPickerInputConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					mainDragging = false
					sliderDragging = false
				end end)
			Main.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true 
				end
			end)
			Main.MainPoint.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true 
				end
			end)
			Slider.MouseButton1Down:Connect(function()
				sliderDragging = true 
			end)
			Slider.SliderPoint.MouseButton1Down:Connect(function()
				sliderDragging = true 
			end)
			local h,s,v = ColorPickerSettings.Color:ToHSV()
			local color = Color3.fromHSV(h,s,v) 
			local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
			ColorPicker.HexInput.InputBox.Text = hex
			local function setDisplay()
				Main.MainPoint.Position = UDim2.new(s,-Main.MainPoint.AbsoluteSize.X/2,1-v,-Main.MainPoint.AbsoluteSize.Y/2)
				Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
				Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
				Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
				local x = h * Slider.AbsoluteSize.X
				Slider.SliderPoint.Position = UDim2.new(0,x-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
				Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
				local color = Color3.fromHSV(h,s,v) 
				local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
				ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
				ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
				hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
				ColorPicker.HexInput.InputBox.Text = hex
			end
			setDisplay()
			ColorPicker.HexInput.InputBox.FocusLost:Connect(function()
				if not pcall(function()
						local r, g, b = string.match(ColorPicker.HexInput.InputBox.Text, "^#?(%w%w)(%w%w)(%w%w)$")
						local rgbColor = Color3.fromRGB(tonumber(r, 16),tonumber(g, 16), tonumber(b, 16))
						h,s,v = rgbColor:ToHSV()
						hex = ColorPicker.HexInput.InputBox.Text
						setDisplay()
						ColorPickerSettings.Color = rgbColor
					end) 
				then 
					ColorPicker.HexInput.InputBox.Text = hex 
				end
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				if not ColorPickerSettings.Ext then
					SaveConfiguration()
				end
			end)
			local function rgbBoxes(box,toChange)
				local value = tonumber(box.Text) 
				local color = Color3.fromHSV(h,s,v) 
				local oldR,oldG,oldB = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				local save 
				if toChange == "R" then save = oldR;oldR = value elseif toChange == "G" then save = oldG;oldG = value else save = oldB;oldB = value end
				if value then 
					value = math.clamp(value,0,255)
					h,s,v = Color3.fromRGB(oldR,oldG,oldB):ToHSV()

					setDisplay()
				else 
					box.Text = tostring(save)
				end
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				if not ColorPickerSettings.Ext then
					SaveConfiguration(ColorPickerSettings.Flag..'\n'..tostring(ColorPickerSettings.Color))
				end
			end
			ColorPicker.RGB.RInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.RInput.InputBox,"R")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)
			ColorPicker.RGB.GInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.GInput.InputBox,"G")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)
			ColorPicker.RGB.BInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.BInput.InputBox,"B")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)

			local colorPickerRenderConnection = RunService.RenderStepped:connect(function()
				if mainDragging then
					local localX = math.clamp(mouse.X-Main.AbsolutePosition.X,0,Main.AbsoluteSize.X)
					local localY = math.clamp(mouse.Y-Main.AbsolutePosition.Y,0,Main.AbsoluteSize.Y)
					Main.MainPoint.Position = UDim2.new(0,localX-Main.MainPoint.AbsoluteSize.X/2,0,localY-Main.MainPoint.AbsoluteSize.Y/2)
					s = localX / Main.AbsoluteSize.X
					v = 1 - (localY / Main.AbsoluteSize.Y)
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					local color = Color3.fromHSV(h,s,v) 
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					if not ColorPickerSettings.Ext then
						SaveConfiguration()
					end
				end
				if sliderDragging then 
					local localX = math.clamp(mouse.X-Slider.AbsolutePosition.X,0,Slider.AbsoluteSize.X)
					h = localX / Slider.AbsoluteSize.X
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Slider.SliderPoint.Position = UDim2.new(0,localX-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
					Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					local color = Color3.fromHSV(h,s,v) 
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					if not ColorPickerSettings.Ext then
						SaveConfiguration()
					end
				end
			end)

			ColorPicker.Destroying:Connect(function()
				if colorPickerRenderConnection then
					colorPickerRenderConnection:Disconnect()
				end
				if colorPickerInputConnection then
					colorPickerInputConnection:Disconnect()
				end
			end)

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and ColorPickerSettings.Flag then
					RayfieldLibrary.Flags[ColorPickerSettings.Flag] = ColorPickerSettings
				end
			end

			function ColorPickerSettings:Set(RGBColor)
				ColorPickerSettings.Color = RGBColor
				h,s,v = ColorPickerSettings.Color:ToHSV()
				color = Color3.fromHSV(h,s,v)
				setDisplay()
			end

			ColorPicker.MouseEnter:Connect(function()
				TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			ColorPicker.MouseLeave:Connect(function()
				TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
					if rgbinput:IsA("Frame") then
						rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
						rgbinput.UIStroke.Color = SelectedTheme.InputStroke
					end
				end

				ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
				ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return ColorPickerSettings
		end

		function Tab:CreateSection(SectionName)

			local SectionValue = {}

			if SDone then
				local SectionSpace = Elements.Template.SectionSpacing:Clone()
				SectionSpace.Visible = true
				SectionSpace.Parent = TabPage
			end

			local Section = Elements.Template.SectionTitle:Clone()
			Section.Title.Text = SectionName
			Section.Visible = true
			Section.Parent = TabPage

			Section.Title.TextTransparency = 1
			TweenService:Create(Section.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()

			function SectionValue:Set(NewSection)
				Section.Title.Text = NewSection
			end

			SDone = true

			return SectionValue
		end

		function Tab:CreateDivider()
			local DividerValue = {}

			local Divider = Elements.Template.Divider:Clone()
			Divider.Visible = true
			Divider.Parent = TabPage

			Divider.Divider.BackgroundTransparency = 1
			TweenService:Create(Divider.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85}):Play()

			function DividerValue:Set(Value)
				Divider.Visible = Value
			end

			return DividerValue
		end

		function Tab:CreateLabel(LabelText : string, Icon: number, Color : Color3, IgnoreTheme : boolean)
			local LabelValue = {}

			local Label = Elements.Template.Label:Clone()
			Label.Title.Text = LabelText
			Label.Visible = true
			Label.Parent = TabPage

			Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
			Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke

			if Icon then
				local img, rectOffset, rectSize = resolveIcon(Icon)
				Label.Icon.Image = img
				if rectOffset then Label.Icon.ImageRectOffset = rectOffset end
				if rectSize then Label.Icon.ImageRectSize = rectSize end
			else
				Label.Icon.Image = ""
			end

			if Icon and Label:FindFirstChild('Icon') then
				Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
				Label.Title.Size = UDim2.new(1, -100, 0, 14)
				Label.Icon.Visible = true
			end

			Label.Icon.ImageTransparency = 1
			Label.BackgroundTransparency = 1
			Label.UIStroke.Transparency = 1
			Label.Title.TextTransparency = 1

			Label:SetAttribute("BackgroundTransparencyTarget", Color and 0.8 or 0)
			Label:SetAttribute("UIStrokeTransparencyTarget", Color and 0.7 or 0)
			Label:SetAttribute("TitleTextTransparencyTarget", Color and 0.2 or 0)

			TweenService:Create(Label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = Color and 0.8 or 0}):Play()
			TweenService:Create(Label.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = Color and 0.7 or 0}):Play()
			TweenService:Create(Label.Icon, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
			TweenService:Create(Label.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = Color and 0.2 or 0}):Play()

			function LabelValue:Set(NewLabel, Icon, Color)
				Label.Title.Text = NewLabel

				if Color then
					Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
					Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke
				end

				if Icon and Label:FindFirstChild('Icon') then
					Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
					Label.Title.Size = UDim2.new(1, -100, 0, 14)

					local img, rectOffset, rectSize = resolveIcon(Icon)
					Label.Icon.Image = img
					if rectOffset then Label.Icon.ImageRectOffset = rectOffset end
					if rectSize then Label.Icon.ImageRectSize = rectSize end

					Label.Icon.Visible = true
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Label.BackgroundColor3 = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementBackground
				Label.UIStroke.Color = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementStroke
			end)

			return LabelValue
		end

		function Tab:CreateParagraph(ParagraphSettings)
			local ParagraphValue = {}

			local Paragraph = Elements.Template.Paragraph:Clone()
			Paragraph.Title.Text = ParagraphSettings.Title
			Paragraph.Content.Text = ParagraphSettings.Content
			Paragraph.Visible = true
			Paragraph.Parent = TabPage

			Paragraph.BackgroundTransparency = 1
			Paragraph.UIStroke.Transparency = 1
			Paragraph.Title.TextTransparency = 1
			Paragraph.Content.TextTransparency = 1

			Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
			Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke

			TweenService:Create(Paragraph, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Paragraph.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Paragraph.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	
			TweenService:Create(Paragraph.Content, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			function ParagraphValue:Set(NewParagraphSettings)
				Paragraph.Title.Text = NewParagraphSettings.Title
				Paragraph.Content.Text = NewParagraphSettings.Content
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
				Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke
			end)

			return ParagraphValue
		end

		function Tab:CreateInput(InputSettings)
			local Input = Elements.Template.Input:Clone()
			Input.Name = InputSettings.Name
			Input.Title.Text = InputSettings.Name
			Input.Visible = true
			Input.Parent = TabPage

			Input.BackgroundTransparency = 1
			Input.UIStroke.Transparency = 1
			Input.Title.TextTransparency = 1

			Input.InputFrame.InputBox.Text = InputSettings.CurrentValue or ''

			Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
			Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke

			TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Input.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			Input.InputFrame.InputBox.PlaceholderText = InputSettings.PlaceholderText
			Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30)

			Input.InputFrame.InputBox.FocusLost:Connect(function()
				local Success, Response = pcall(function()
					InputSettings.Callback(Input.InputFrame.InputBox.Text)
					InputSettings.CurrentValue = Input.InputFrame.InputBox.Text
				end)

				if not Success then
					TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Input.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Input.Title.Text = "Callback Error"
					task.wait(0.5)
					Input.Title.Text = InputSettings.Name
					TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Input.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				if InputSettings.RemoveTextAfterFocusLost then
					Input.InputFrame.InputBox.Text = ""
				end

				if not InputSettings.Ext then
					SaveConfiguration()
				end
			end)

			Input.MouseEnter:Connect(function()
				TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Input.MouseLeave:Connect(function()
				TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
				TweenService:Create(Input.InputFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30)}):Play()
			end)

			function InputSettings:Set(text)
				Input.InputFrame.InputBox.Text = text
				InputSettings.CurrentValue = text

				local Success, Response = pcall(function()
					InputSettings.Callback(text)
				end)

				if not InputSettings.Ext then
					SaveConfiguration()
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and InputSettings.Flag then
					RayfieldLibrary.Flags[InputSettings.Flag] = InputSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
				Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return InputSettings
		end

		function Tab:CreateDropdown(DropdownSettings)
			local Dropdown = Elements.Template.Dropdown:Clone()
			if string.find(DropdownSettings.Name,"closed") then
				Dropdown.Name = "Dropdown"
			else
				Dropdown.Name = DropdownSettings.Name
			end
			Dropdown.Title.Text = DropdownSettings.Name
			Dropdown.Visible = true
			Dropdown.Parent = TabPage

			Dropdown.List.Visible = false
			if DropdownSettings.CurrentOption then
				if type(DropdownSettings.CurrentOption) == "string" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
				end
				if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
				end
			else
				DropdownSettings.CurrentOption = {}
			end

			if DropdownSettings.MultipleOptions then
				if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
					if #DropdownSettings.CurrentOption == 1 then
						Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
					elseif #DropdownSettings.CurrentOption == 0 then
						Dropdown.Selected.Text = "None"
					else
						Dropdown.Selected.Text = "Various"
					end
				else
					DropdownSettings.CurrentOption = {}
					Dropdown.Selected.Text = "None"
				end
			else
				Dropdown.Selected.Text = DropdownSettings.CurrentOption[1] or "None"
			end
			if DropdownSettings.CurrentOption and DropdownSettings.CurrentOption[1] and safeFont(DropdownSettings.CurrentOption[1]) then
				Dropdown.Selected.Font = safeFont(DropdownSettings.CurrentOption[1])
			end

			Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
			TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()

			Dropdown.BackgroundTransparency = 1
			Dropdown.UIStroke.Transparency = 1
			Dropdown.Title.TextTransparency = 1

			Dropdown.Size = UDim2.new(1, -10, 0, 45)

			TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Dropdown.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			for _, ununusedoption in ipairs(Dropdown.List:GetChildren()) do
				if ununusedoption.ClassName == "Frame" and ununusedoption.Name ~= "Placeholder" then
					ununusedoption:Destroy()
				end
			end

			Dropdown.Toggle.Rotation = 180

			Dropdown.Interact.MouseButton1Click:Connect(function()
				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
				TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
				task.wait(0.1)
				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
				TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				if Debounce then return end
				if Dropdown.List.Visible then
					Debounce = true
					TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
							TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
							TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
						end
					end
					TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 1}):Play()
					TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 180}):Play()	
					task.wait(0.35)
					Dropdown.List.Visible = false
					Debounce = false
				else
					TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 180)}):Play()
					Dropdown.List.Visible = true
					TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 0.7}):Play()
					TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 0}):Play()	
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
							if DropdownOpt.Name ~= Dropdown.Selected.Text then
								TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
							end
							TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
						end
					end
				end
			end)

			Dropdown.MouseEnter:Connect(function()
				if not Dropdown.List.Visible then
					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
				end
			end)

			Dropdown.MouseLeave:Connect(function()
				TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			local function SetDropdownOptions()
				for _, Option in ipairs(DropdownSettings.Options) do
					local DropdownOption = Elements.Template.Dropdown.List.Template:Clone()
					DropdownOption.Name = Option
					DropdownOption.Title.Text = Option
					local fontVal = safeFont(Option)
					if fontVal then
						DropdownOption.Title.Font = fontVal
					end
					DropdownOption.Parent = Dropdown.List
					DropdownOption.Visible = true

					DropdownOption.BackgroundTransparency = 1
					DropdownOption.UIStroke.Transparency = 1
					DropdownOption.Title.TextTransparency = 1




					DropdownOption.Interact.ZIndex = 50
					DropdownOption.Interact.MouseButton1Click:Connect(function()
						if not DropdownSettings.MultipleOptions and table.find(DropdownSettings.CurrentOption, Option) then 
							return
						end

						if table.find(DropdownSettings.CurrentOption, Option) then
							table.remove(DropdownSettings.CurrentOption, table.find(DropdownSettings.CurrentOption, Option))
							if DropdownSettings.MultipleOptions then
								if #DropdownSettings.CurrentOption == 1 then
									Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
								elseif #DropdownSettings.CurrentOption == 0 then
									Dropdown.Selected.Text = "None"
								else
									Dropdown.Selected.Text = "Various"
								end
							else
								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
								local curFont = safeFont(DropdownSettings.CurrentOption[1])
								if curFont then
									Dropdown.Selected.Font = curFont
								end
							end
						else
							if not DropdownSettings.MultipleOptions then
								table.clear(DropdownSettings.CurrentOption)
							end
							table.insert(DropdownSettings.CurrentOption, Option)
							if DropdownSettings.MultipleOptions then
								if #DropdownSettings.CurrentOption == 1 then
									Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
								elseif #DropdownSettings.CurrentOption == 0 then
									Dropdown.Selected.Text = "None"
								else
									Dropdown.Selected.Text = "Various"
								end
							else
								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
							end
							TweenService:Create(DropdownOption.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							TweenService:Create(DropdownOption, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.DropdownSelected}):Play()
							Debounce = true
						end


						local Success, Response = pcall(function()
							DropdownSettings.Callback(DropdownSettings.CurrentOption)
						end)

						if not Success then
							TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Dropdown.Title.Text = "Callback Error"
							task.wait(0.5)
							Dropdown.Title.Text = DropdownSettings.Name
							TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
							TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
						end

						for _, droption in ipairs(Dropdown.List:GetChildren()) do
							if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" and not table.find(DropdownSettings.CurrentOption, droption.Name) then
								TweenService:Create(droption, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.DropdownUnselected}):Play()
							end
						end
						if not DropdownSettings.MultipleOptions then
							task.wait(0.1)
							TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
							for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
								if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
									TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
									TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
									TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
								end
							end
							TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 1}):Play()
							TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 180}):Play()	
							task.wait(0.35)
							Dropdown.List.Visible = false
						end
						Debounce = false
						if not DropdownSettings.Ext then
							SaveConfiguration()
						end
					end)

					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
						DropdownOption.UIStroke.Color = SelectedTheme.ElementStroke
					end)
				end
			end
			SetDropdownOptions()

			for _, droption in ipairs(Dropdown.List:GetChildren()) do
				if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" then
					if not table.find(DropdownSettings.CurrentOption, droption.Name) then
						droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
					else
						droption.BackgroundColor3 = SelectedTheme.DropdownSelected
					end

					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end)
				end
			end

			function DropdownSettings:Set(NewOption)
				DropdownSettings.CurrentOption = NewOption

				if typeof(DropdownSettings.CurrentOption) == "string" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
				end

				if not DropdownSettings.MultipleOptions then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
				end

				if DropdownSettings.MultipleOptions then
					if #DropdownSettings.CurrentOption == 1 then
						Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
					elseif #DropdownSettings.CurrentOption == 0 then
						Dropdown.Selected.Text = "None"
					else
						Dropdown.Selected.Text = "Various"
					end
				else
					Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
					local curFont = safeFont(DropdownSettings.CurrentOption[1])
					if curFont then
						Dropdown.Selected.Font = curFont
					end
				end


				local Success, Response = pcall(function()
					DropdownSettings.Callback(NewOption)
				end)
				if not Success then
					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Dropdown.Title.Text = "Callback Error"
					task.wait(0.5)
					Dropdown.Title.Text = DropdownSettings.Name
					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				for _, droption in ipairs(Dropdown.List:GetChildren()) do
					if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" then
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end
				end
			end

			function DropdownSettings:Refresh(optionsTable: table)
				DropdownSettings.Options = optionsTable
				for _, option in Dropdown.List:GetChildren() do
					if option.ClassName == "Frame" and option.Name ~= "Placeholder" then
						option:Destroy()
					end
				end
				SetDropdownOptions()

				for _, droption in ipairs(Dropdown.List:GetChildren()) do
					if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" then
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end
				end

				if Dropdown.List.Visible then
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
							DropdownOpt.BackgroundTransparency = 0
							DropdownOpt.Title.TextTransparency = 0
							if not table.find(DropdownSettings.CurrentOption, DropdownOpt.Name) then
								DropdownOpt.UIStroke.Transparency = 0
							end
						end
					end
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and DropdownSettings.Flag then
					RayfieldLibrary.Flags[DropdownSettings.Flag] = DropdownSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			return DropdownSettings
		end

		function Tab:CreateKeybind(KeybindSettings)
			local CheckingForKey = false
			local Keybind = Elements.Template.Keybind:Clone()
			Keybind.Name = KeybindSettings.Name
			Keybind.Title.Text = KeybindSettings.Name
			Keybind.Visible = true
			Keybind.Parent = TabPage

			Keybind.BackgroundTransparency = 1
			Keybind.UIStroke.Transparency = 1
			Keybind.Title.TextTransparency = 1

			Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
			Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke

			TweenService:Create(Keybind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Keybind.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
			Keybind.KeybindFrame.Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30)

			Keybind.KeybindFrame.KeybindBox.Focused:Connect(function()
				CheckingForKey = true
				Keybind.KeybindFrame.KeybindBox.Text = ""
			end)
			Keybind.KeybindFrame.KeybindBox.FocusLost:Connect(function()
				CheckingForKey = false
				if Keybind.KeybindFrame.KeybindBox.Text == nil or Keybind.KeybindFrame.KeybindBox.Text == "" then
					Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
					if not KeybindSettings.Ext then
						SaveConfiguration()
					end
				end
			end)

			Keybind.MouseEnter:Connect(function()
				TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Keybind.MouseLeave:Connect(function()
				TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			local connection = UserInputService.InputBegan:Connect(function(input, processed)
				if CheckingForKey then
					if input.KeyCode ~= Enum.KeyCode.Unknown then
						local SplitMessage = string.split(tostring(input.KeyCode), ".")
						local NewKeyNoEnum = SplitMessage[3]
						Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeyNoEnum)
						KeybindSettings.CurrentKeybind = tostring(NewKeyNoEnum)
						Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
						if not KeybindSettings.Ext then
							SaveConfiguration()
						end

						if KeybindSettings.CallOnChange then
							KeybindSettings.Callback(tostring(NewKeyNoEnum))
						end
					end
				elseif not KeybindSettings.CallOnChange and KeybindSettings.CurrentKeybind ~= nil and (input.KeyCode == Enum.KeyCode[KeybindSettings.CurrentKeybind] and not processed) then
					local Held = true
					local Connection
					Connection = input.Changed:Connect(function(prop)
						if prop == "UserInputState" then
							Connection:Disconnect()
							Held = false
						end
					end)

					if not KeybindSettings.HoldToInteract then
						local Success, Response = pcall(KeybindSettings.Callback)
						if not Success then
							TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
							TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
							Keybind.Title.Text = "Callback Error"
							task.wait(0.5)
							Keybind.Title.Text = KeybindSettings.Name
							TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
							TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
						end
					else
						task.wait(0.25)
						if Held then
							local Loop; Loop = RunService.Stepped:Connect(function()
								if not Held then
									KeybindSettings.Callback(false)
									Loop:Disconnect()
								else
									KeybindSettings.Callback(true)
								end
							end)
						end
					end
				end
			end)
			table.insert(keybindConnections, connection)

			Keybind.KeybindFrame.KeybindBox:GetPropertyChangedSignal("Text"):Connect(function()
				TweenService:Create(Keybind.KeybindFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30)}):Play()
			end)

			function KeybindSettings:Set(NewKeybind)
				Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeybind)
				KeybindSettings.CurrentKeybind = tostring(NewKeybind)
				Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
				if not KeybindSettings.Ext then
					SaveConfiguration()
				end

				if KeybindSettings.CallOnChange then
					KeybindSettings.Callback(tostring(NewKeybind))
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and KeybindSettings.Flag then
					RayfieldLibrary.Flags[KeybindSettings.Flag] = KeybindSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
				Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return KeybindSettings
		end

		function Tab:CreateToggle(ToggleSettings)
			local ToggleValue = {}

			local Toggle = Elements.Template.Toggle:Clone()
			Toggle.Name = ToggleSettings.Name
			Toggle.Title.Text = ToggleSettings.Name
			Toggle.Visible = true
			Toggle.Parent = TabPage

			Toggle.BackgroundTransparency = 1
			Toggle.UIStroke.Transparency = 1
			Toggle.Title.TextTransparency = 1
			Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
				Toggle.Switch.Shadow.Visible = false
			end

			TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Toggle.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			if ToggleSettings.CurrentValue == true then
				Toggle.Switch.Indicator.Position = UDim2.new(1, -20, 0.5, 0)
				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
			else
				Toggle.Switch.Indicator.Position = UDim2.new(1, -40, 0.5, 0)
				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
			end

			Toggle.MouseEnter:Connect(function()
				TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Toggle.MouseLeave:Connect(function()
				TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Toggle.Interact.MouseButton1Click:Connect(function()
				if ToggleSettings.CurrentValue == true then
					ToggleSettings.CurrentValue = false
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -40, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
				else
					ToggleSettings.CurrentValue = true
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()		
				end

				local Success, Response = pcall(function()

					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)

				if not Success then
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Toggle.Title.Text = "Callback Error"
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				if not ToggleSettings.Ext then
					SaveConfiguration()
				end
			end)

			function ToggleSettings:Set(NewToggleValue)
				if NewToggleValue == true then
					ToggleSettings.CurrentValue = true
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()	
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
				else
					ToggleSettings.CurrentValue = false
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -40, 0.5, 0)}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
				end

				local Success, Response = pcall(function()

					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)

				if not Success then
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Toggle.Title.Text = "Callback Error"
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				if not ToggleSettings.Ext then
					SaveConfiguration()
				end
			end

			if not ToggleSettings.Ext then
				if Settings.ConfigurationSaving then
					if Settings.ConfigurationSaving.Enabled and ToggleSettings.Flag then
						RayfieldLibrary.Flags[ToggleSettings.Flag] = ToggleSettings
					end
				end
			end


			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
					Toggle.Switch.Shadow.Visible = false
				end

				task.wait()

				if not ToggleSettings.CurrentValue then
					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
				else
					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
				end
			end)

			return ToggleSettings
		end

		function Tab:CreateSlider(SliderSettings)
			local SLDragging = false
			local Slider = Elements.Template.Slider:Clone()
			Slider.ClipsDescendants = true
			Slider.Name = SliderSettings.Name
			Slider.Title.Text = SliderSettings.Name
			Slider.Size = UDim2.new(1, -10, 0, 45)
			Slider.Position = UDim2.new(0, 0, 0, 0)
			Slider.Visible = true
			Slider.Parent = TabPage

			Slider.BackgroundTransparency = 1
			Slider.UIStroke.Transparency = 1
			Slider.Title.TextTransparency = 1

			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
				Slider.Main.Shadow.Visible = false
			end

			Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
			Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
			Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
			Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress

			TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Slider.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

			Slider.Main.Progress.Size =	UDim2.new(0, Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)

			if not SliderSettings.Suffix then
				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue)
			else
				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue) .. " " .. SliderSettings.Suffix
			end

			Slider.MouseEnter:Connect(function()
				TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
			end)

			Slider.MouseLeave:Connect(function()
				TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			end)

			Slider.Main.Interact.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					TweenService:Create(Slider.Main.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					TweenService:Create(Slider.Main.Progress.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					SLDragging = true 
				end 
			end)

			Slider.Main.Interact.InputEnded:Connect(function(Input) 
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					TweenService:Create(Slider.Main.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
					TweenService:Create(Slider.Main.Progress.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
					SLDragging = false 
				end 
			end)

			Slider.Main.Interact.MouseButton1Down:Connect(function(X)
				local Current = Slider.Main.Progress.AbsolutePosition.X + Slider.Main.Progress.AbsoluteSize.X
				local Start = Current
				local Location = X
				local Loop; Loop = RunService.Stepped:Connect(function()
					if SLDragging then
						Location = UserInputService:GetMouseLocation().X
						Current = Current + 0.025 * (Location - Start)

						if Location < Slider.Main.AbsolutePosition.X then
							Location = Slider.Main.AbsolutePosition.X
						elseif Location > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Location = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current < Slider.Main.AbsolutePosition.X + 5 then
							Current = Slider.Main.AbsolutePosition.X + 5
						elseif Current > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Current = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current <= Location and (Location - Start) < 0 then
							Start = Location
						elseif Current >= Location and (Location - Start) > 0 then
							Start = Location
						end
						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Current - Slider.Main.AbsolutePosition.X, 1, 0)}):Play()
						local NewValue = SliderSettings.Range[1] + (Location - Slider.Main.AbsolutePosition.X) / Slider.Main.AbsoluteSize.X * (SliderSettings.Range[2] - SliderSettings.Range[1])

						NewValue = math.floor(NewValue / SliderSettings.Increment + 0.5) * (SliderSettings.Increment * 10000000) / 10000000
						NewValue = math.clamp(NewValue, SliderSettings.Range[1], SliderSettings.Range[2])

						if not SliderSettings.Suffix then
							Slider.Main.Information.Text = tostring(NewValue)
						else
							Slider.Main.Information.Text = tostring(NewValue) .. " " .. SliderSettings.Suffix
						end

						if SliderSettings.CurrentValue ~= NewValue then
							local Success, Response = pcall(function()
								SliderSettings.Callback(NewValue)
							end)
							if not Success then
								TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
								Slider.Title.Text = "Callback Error"
								task.wait(0.5)
								Slider.Title.Text = SliderSettings.Name
								TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
							end

							SliderSettings.CurrentValue = NewValue
							if not SliderSettings.Ext then
								SaveConfiguration()
							end
						end
					else
						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X > 5 and Location - Slider.Main.AbsolutePosition.X or 5, 1, 0)}):Play()
						Loop:Disconnect()
					end
				end)
			end)

			function SliderSettings:Set(NewVal)
				local NewVal = math.clamp(NewVal, SliderSettings.Range[1], SliderSettings.Range[2])

				TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Slider.Main.AbsoluteSize.X * ((NewVal - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * ((NewVal - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)}):Play()
				Slider.Main.Information.Text = tostring(NewVal) .. " " .. (SliderSettings.Suffix or "")

				local Success, Response = pcall(function()
					SliderSettings.Callback(NewVal)
				end)

				if not Success then
					TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					Slider.Title.Text = "Callback Error"
					task.wait(0.5)
					Slider.Title.Text = SliderSettings.Name
					TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
				end

				SliderSettings.CurrentValue = NewVal
				if not SliderSettings.Ext then
					SaveConfiguration()
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and SliderSettings.Flag then
					RayfieldLibrary.Flags[SliderSettings.Flag] = SliderSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
					Slider.Main.Shadow.Visible = false
				end

				Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
				Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
				Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
				Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress
			end)

			return SliderSettings
		end

		Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
			TabButton.UIStroke.Color = SelectedTheme.TabStroke

			if Elements.UIPageLayout.CurrentPage == TabPage then
				TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
				TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
				TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			else
				TabButton.BackgroundColor3 = SelectedTheme.TabBackground
				TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
				TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
			end
		end)

		return Tab
	end

	Elements.Visible = true


	task.wait(1.1)
	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 390, 0, 90)}):Play()
	task.wait(0.3)
	TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
	task.wait(0.2)
	LoadingFrame.Visible = false
	task.wait(0.1)
	TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()

	Topbar.BackgroundTransparency = 1
	Topbar.Divider.Size = UDim2.new(0, 0, 0, 1)
	Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	Topbar.CornerRepair.BackgroundTransparency = 1
	Topbar.Title.TextTransparency = 1
	Topbar.Search.ImageTransparency = 1
	if Topbar:FindFirstChild('Settings') then
		Topbar.Settings.ImageTransparency = 1
	end
	Topbar.ChangeSize.ImageTransparency = 1
	Topbar.Hide.ImageTransparency = 1


	task.wait(0.5)
	Topbar.Visible = true
	TweenService:Create(Topbar, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	task.wait(0.1)
	TweenService:Create(Topbar.Divider, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, 1)}):Play()
	TweenService:Create(Topbar.Title, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	task.wait(0.05)
	TweenService:Create(Topbar.Search, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
	task.wait(0.05)
	if Topbar:FindFirstChild('Settings') then
		TweenService:Create(Topbar.Settings, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
		task.wait(0.05)
	end
	TweenService:Create(Topbar.ChangeSize, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
	task.wait(0.05)
	TweenService:Create(Topbar.Hide, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
	task.wait(0.3)

	if dragBar then
		TweenService:Create(dragBarCosmetic, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
	end

	function Window.ModifyTheme(NewTheme)
		local success = pcall(ChangeTheme, NewTheme)
		if not success then
			RayfieldLibrary:Notify({Title = 'Unable to Change Theme', Content = 'We are unable find a theme on file.', Image = 4400704299})
		else
			RayfieldLibrary:Notify({Title = 'Theme Changed', Content = 'Successfully changed theme to '..(typeof(NewTheme) == 'string' and NewTheme or 'Custom Theme')..'.', Image = 4483362748})
		end
	end

	local success, result = pcall(function()
		createSettings(Window)
	end)

	if not success then end

	if reporter and getSetting("System", "usageAnalytics") then
		local themeName = "Default"
		if Settings.Theme then
			if type(Settings.Theme) == "string" then
				themeName = Settings.Theme
			elseif type(Settings.Theme) == "table" then
				themeName = "Custom"
			end
		end

		local discordInvite = nil
		if Settings.Discord and Settings.Discord.Enabled and Settings.Discord.Invite and Settings.Discord.Invite ~= "" then
			local raw = tostring(Settings.Discord.Invite)
			discordInvite = (raw:match("discord%.gg/([%w%-]+)") or raw:match("discord%.com/invite/([%w%-]+)") or raw):sub(1, 32)
		end

		local sampleSend = false

		if not Settings.ScriptID and math.random() > 0.4 then
			sampleSend = true
		end

			reporter:windowCreated({
				script_name        = Settings.Name or "Unknown",
				script_version     = Release,
				interface_version  = InterfaceBuild,
				theme              = themeName,
				is_mobile          = useMobileSizing and true or false,
				has_key_system     = Settings.KeySystem and true or false,
				discord_invite     = discordInvite,
				config_saving      = (Settings.ConfigurationSaving and Settings.ConfigurationSaving.Enabled) and true or false,
				script_id          = Settings.ScriptID or sampleSend and 'sid_tzfyxawonjx9' or nil,
				verification_token = Settings.VerificationToken,
			})
	end

	return Window
end

local function setVisibility(visibility: boolean, notify: boolean?)
	if Debounce then return end
	if visibility then
		Hidden = false
		Unhide()
	else
		Hidden = true
		Hide(notify)
	end
end

function RayfieldLibrary:SetVisibility(visibility: boolean)
	setVisibility(visibility, false)
end

function RayfieldLibrary:IsVisible(): boolean
	return not Hidden
end

local hideHotkeyConnection
function RayfieldLibrary:Destroy()
	rayfieldDestroyed = true
	if hideHotkeyConnection then
		hideHotkeyConnection:Disconnect()
	end
	for _, connection in keybindConnections do
		connection:Disconnect()
	end
	Rayfield:Destroy()
end

Topbar.ChangeSize.MouseButton1Click:Connect(function()
	if Debounce then return end
	if Minimised then
		Minimised = false
		Maximise()
	else
		Minimised = true
		Minimise()
	end
end)

Main.Search.Input:GetPropertyChangedSignal('Text'):Connect(function()
	if #Main.Search.Input.Text > 0 then
		if not Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks') then 
			local searchTitle = Elements.Template.SectionTitle:Clone()
			searchTitle.Parent = Elements.UIPageLayout.CurrentPage
			searchTitle.Name = 'SearchTitle-fsefsefesfsefesfesfThanks'
			searchTitle.LayoutOrder = -100
			searchTitle.Title.Text = "Results from '"..Elements.UIPageLayout.CurrentPage.Name.."'"
			searchTitle.Visible = true
		end
	else
		local searchTitle = Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks')

		if searchTitle then
			searchTitle:Destroy()
		end
	end

	for _, element in ipairs(Elements.UIPageLayout.CurrentPage:GetChildren()) do
		if element.ClassName ~= 'UIListLayout' and element.Name ~= 'Placeholder' and element.Name ~= 'SearchTitle-fsefsefesfsefesfesfThanks' then
			if element.Name == 'SectionTitle' then
				if #Main.Search.Input.Text == 0 then
					element.Visible = true
				else
					element.Visible = false
				end
			else
				if string.lower(element.Name):find(string.lower(Main.Search.Input.Text), 1, true) then
					element.Visible = true
				else
					element.Visible = false
				end
			end
		end
	end
end)

Main.Search.Input.FocusLost:Connect(function(enterPressed)
	if #Main.Search.Input.Text == 0 and searchOpen then
		task.wait(0.12)
		closeSearch()
	end
end)

Topbar.Search.MouseButton1Click:Connect(function()
	task.spawn(function()
		if searchOpen then
			closeSearch()
		else
			openSearch()
		end
	end)
end)

if Topbar:FindFirstChild('Settings') then
	local previousActiveTab = nil
	Topbar.Settings.MouseButton1Click:Connect(function()
		task.spawn(function()
			local settingsPage = Elements:FindFirstChild('Settings') or Elements['Rayfield Settings']
			if settingsPage and Elements.UIPageLayout.CurrentPage == settingsPage then
				if previousActiveTab and previousActiveTab.Parent == Elements then
					Elements.UIPageLayout:JumpTo(previousActiveTab)
					for _, OtherTabButton in ipairs(TabList:GetChildren()) do
						if OtherTabButton.Name == previousActiveTab.Name then
							TweenService:Create(OtherTabButton, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
							TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
							TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
						end
					end
					return
				end
			elseif settingsPage and Elements.UIPageLayout.CurrentPage ~= settingsPage then
				previousActiveTab = Elements.UIPageLayout.CurrentPage
			end

			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton.Name ~= "Placeholder" then
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackground}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.TabTextColor}):Play()
					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
					TweenService:Create(OtherTabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
				end
			end

			if settingsPage then
				settingsPage.CanvasPosition = Vector2.new(0, 0)
				Elements.UIPageLayout:JumpTo(settingsPage)
			end
		end)
	end)

end


Topbar.Hide.MouseButton1Click:Connect(function()
	setVisibility(Hidden, not useMobileSizing)
end)

hideHotkeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
	if (input.KeyCode == Enum.KeyCode[getSetting("General", "rayfieldOpen")]) and not processed then
		if Debounce then return end
		if Hidden then
			Hidden = false
			Unhide()
		else
			Hidden = true
			Hide()
		end
	end
end)

if MPrompt then
	MPrompt.Interact.MouseButton1Click:Connect(function()
		if Debounce then return end
		if Hidden then
			Hidden = false
			Unhide()
		end
	end)
end

for _, TopbarButton in ipairs(Topbar:GetChildren()) do
	if TopbarButton.ClassName == "ImageButton" and TopbarButton.Name ~= 'Icon' then
		TopbarButton.MouseEnter:Connect(function()
			TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
		end)

		TopbarButton.MouseLeave:Connect(function()
			TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
		end)
	end
end


function RayfieldLibrary:LoadConfiguration()
	local config

	if debugX then
	end

	if useStudio then
		config = [[{"Toggle1adwawd":true,"ColorPicker1awd":{"B":255,"G":255,"R":255},"Slider1dawd":100,"ColorPicfsefker1":{"B":255,"G":255,"R":255},"Slidefefsr1":80,"dawdawd":"","Input1":"hh","Keybind1":"B","Dropdown1":["Ocean"]}]]
	end

	if CEnabled then
		local notified
		local loaded

		local success, result = pcall(function()
			if useStudio and config then
				loaded = LoadConfiguration(config)
				return
			end

			if isfile then 
				if callSafely(isfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension) then
					loaded = LoadConfiguration(callSafely(readfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension))
				end
			else
				notified = true
				RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We couldn't enable Configuration Saving as you are not using software with filesystem support.", Image = 4384402990})
			end
		end)

		if success and loaded and not notified then
			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "The configuration file for this script has been loaded from a previous session.", Image = 4384403532})
		elseif not success and not notified then
			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We've encountered an issue loading your configuration correctly.\n\nCheck the Developer Console for more information.", Image = 4384402990})
		end
	end

	globalLoaded = true
end



if useStudio then































end

if CEnabled and Main:FindFirstChild('Notice') then
	Main.Notice.BackgroundTransparency = 1
	Main.Notice.Title.TextTransparency = 1
	Main.Notice.Size = UDim2.new(0, 0, 0, 0)
	Main.Notice.Position = UDim2.new(0.5, 0, 0, -100)
	Main.Notice.Visible = true


	TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 280, 0, 35), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 0.5}):Play()
	TweenService:Create(Main.Notice.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.1}):Play()
end

task.delay(4, function()
	RayfieldLibrary.LoadConfiguration()
	if Main:FindFirstChild('Notice') and Main.Notice.Visible then
		TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 100, 0, 25), Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}):Play()
		TweenService:Create(Main.Notice.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		task.wait(0.5)
		Main.Notice.Visible = false
	end
end)

return RayfieldLibrary

