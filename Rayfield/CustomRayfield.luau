
local debugX = false
local _env = (getgenv and getgenv()) or _G
local syn = (type(_env) == "table" and _env.syn) or rawget(_G, "syn")
local fluxus = (type(_env) == "table" and _env.fluxus) or rawget(_G, "fluxus")
local currentWindowSettings = nil
local allLibraryConnections = {}

local function getService(name)
	local service = game:GetService(name)
	if cloneref then
		local ok, ref = pcall(cloneref, service)
		if ok and ref then
			return ref
		end
	end
	return service
end

local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local TextService = getService("TextService")
local CoreGui = nil
pcall(function()
	CoreGui = getService("CoreGui")
end)

local function safeParentGui(gui)
	if gethui then
		local ok, hui = pcall(gethui)
		if ok and hui and typeof(hui) == "Instance" then
			local parentOk = pcall(function() gui.Parent = hui end)
			if parentOk then return hui end
		end
	end
	if syn and syn.protect_gui and CoreGui then
		local ok = pcall(function()
			syn.protect_gui(gui)
			gui.Parent = CoreGui
		end)
		if ok then return CoreGui end
	end
	if CoreGui then
		local ok = pcall(function()
			local robloxGui = CoreGui:FindFirstChild("RobloxGui")
			if robloxGui then
				gui.Parent = robloxGui
			else
				gui.Parent = CoreGui
			end
		end)
		if ok then return CoreGui end
	end
	local player = nil
	pcall(function()
		player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	end)
	if player then
		local playerGui = nil
		pcall(function()
			playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
		end)
		if playerGui then
			local ok = pcall(function() gui.Parent = playerGui end)
			if ok then return playerGui end
		end
	end
	return nil
end

local function safeCleanOldGui(guiName, currentGui)
	pcall(function()
		local containers = {}
		if gethui then
			local ok, hui = pcall(gethui)
			if ok and hui then table.insert(containers, hui) end
		end
		if CoreGui then
			pcall(function()
				local r = CoreGui:GetChildren()
				if r then table.insert(containers, CoreGui) end
			end)
		end
		if Players.LocalPlayer then
			pcall(function()
				local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
				if pg then table.insert(containers, pg) end
			end)
		end
		for _, container in ipairs(containers) do
			pcall(function()
				for _, item in ipairs(container:GetChildren()) do
					if (item.Name == guiName or item.Name == guiName .. "-Old") and item ~= currentGui then
						item.Enabled = false
						pcall(function() item:Destroy() end)
					end
				end
			end)
		end
	end)
end

local function safeFont(fontName)
	if type(fontName) ~= "string" then return Enum.Font.Gotham end
	local success, font = pcall(function()
		return Enum.Font[fontName]
	end)
	return (success and font) or Enum.Font.Gotham
end

local function loadWithTimeout(url: string, timeout: number?): ...any
	if type(url) ~= "string" or #url == 0 then return nil end
	local safeTimeout: number = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url)
		if not fetchSuccess or type(fetchResult) ~= "string" or #fetchResult == 0 then
			success, result = false, "Empty or failed response"
			requestCompleted = true
			return
		end
		local execSuccess, execResult = pcall(function()
			local fn = loadstring(fetchResult)
			if type(fn) == "function" then
				return fn()
			end
			return nil
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(safeTimeout, function()
		if not requestCompleted then
			pcall(task.cancel, requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	local startWait = tick()
	while not requestCompleted and (tick() - startWait) < (safeTimeout + 0.5) do
		task.wait(0.05)
	end
	if coroutine.status(timeoutThread) ~= "dead" then
		pcall(task.cancel, timeoutThread)
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

local warn = if secureMode then function(...) end else warn

local RayfieldLibrary
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
local AssetPath = RayfieldFolder.."/Assets"
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
	elseif settingsTable[category] and settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
	return nil
end

if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false
local rawRequest = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request
local function requestFunc(options)
	if type(rawRequest) == "function" then
		local ok, res = pcall(rawRequest, options)
		if ok and res then
			return res
		end
	end
	if type(options) == "table" and (options.Method == nil or options.Method == "GET") and options.Url then
		local ok, body = pcall(game.HttpGet, game, options.Url)
		if ok and type(body) == "string" then
			return {
				StatusCode = 200,
				StatusMessage = "OK",
				Body = body,
				Success = true
			}
		end
	end
	return nil
end

local prompt = {
	create = function(...) end
}

local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			return false
		else
			return result
		end
	end
	return nil
end

local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

local function loadSettings()
	local file = nil

	local success = pcall(function()
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

-- Telemetry heartbeat removed

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

RayfieldLibrary = {
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
			SelectedTabTextColor = Color3.fromRGB(20, 15, 25),
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
			SelectedTabTextColor = Color3.fromRGB(10, 40, 25),
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
			SelectedTabTextColor = Color3.fromRGB(10, 20, 35),
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
local function loadRayfieldGui()
	if useStudio and script and script.Parent then
		local found = script.Parent:FindFirstChild('Rayfield')
		if found then return found end
	end
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://"..RayfieldAssetId)
	end)
	if ok and type(objects) == "table" then
		return objects[1]
	end
	return nil
end

local Rayfield = loadRayfieldGui()
assert(Rayfield, "Rayfield: failed to load interface asset "..tostring(RayfieldAssetId))
local buildAttempts = 0
local _correctBuild = false
local warned
local globalLoaded
local rayfieldDestroyed = false

repeat
	if Rayfield:FindFirstChild('Build') and Rayfield.Build.Value == InterfaceBuild then
		_correctBuild = true
		break
	end

	_correctBuild = false

	if not warned then
		warned = true
	end

	local toDestroy
	local newGui = loadRayfieldGui()
	toDestroy, Rayfield = Rayfield, newGui or Rayfield
	if toDestroy and toDestroy ~= Rayfield and not useStudio then toDestroy:Destroy() end

	buildAttempts = buildAttempts + 1
until buildAttempts >= 2

Rayfield.Enabled = false

safeParentGui(Rayfield)

if secureMode and not customAssetId then
	secureNotify("default_asset", "Secure Mode", "You are using the default Rayfield asset ID. Set RAYFIELD_ASSET_ID to a custom upload to avoid detection.")
end

do
	AssetPath = RayfieldFolder.."/Assets"
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
		["19"] = AssetBaseURL.."19.png",
		["20"] = AssetBaseURL.."20.png",
		["21"] = AssetBaseURL.."21.png",
		["22"] = AssetBaseURL.."22.png",
		["23"] = AssetBaseURL.."23.png",
	}

	for id, _ in assetFiles do
		customAssets[tostring(id)] = ""
	end

	local hasCustomAsset = type(getcustomasset) == "function"
	local hasFilesystem = type(writefile) == "function" and type(makefolder) == "function" and type(isfile) == "function" and type(isfolder) == "function"

	if hasCustomAsset and hasFilesystem then
		local ok = pcall(function()
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

				local fetchWaitStart = tick()
				while nextToFetch() and (tick() - fetchWaitStart) < 4 do
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

	local function safeApplyImage(obj, assetValue)
		if obj and assetValue and assetValue ~= "" then
			pcall(function()
				obj.Image = assetValue
			end)
		end
	end

	safeApplyImage(Rayfield.Main.Shadow.Image, customAssets["2"])
	safeApplyImage(Rayfield.Main.Topbar.Hide, customAssets["3"])
	safeApplyImage(Rayfield.Main.Topbar.ChangeSize, customAssets["4"])
	safeApplyImage(Rayfield.Main.Topbar.Settings, customAssets["5"])
	safeApplyImage(Rayfield.Main.Topbar.Icon, customAssets["6"])
	safeApplyImage(Rayfield.Main.Topbar.Search, customAssets["7"])

	if customAssets["folder"] == nil or customAssets["folder"] == "" then
		pcall(function()
			if type(getcustomasset) == "function" then
				if isfile and isfile("Rayfield_Assets/19.png") then
					customAssets["folder"] = getcustomasset("Rayfield_Assets/19.png")
				elseif isfile and isfile("19.png") then
					customAssets["folder"] = getcustomasset("19.png")
				elseif customAssets["19"] and customAssets["19"] ~= "" then
					customAssets["folder"] = customAssets["19"]
				end
			end
		end)
	end
	if customAssets["file"] == nil or customAssets["file"] == "" then
		pcall(function()
			if type(getcustomasset) == "function" then
				if isfile and isfile("Rayfield_Assets/20.png") then
					customAssets["file"] = getcustomasset("Rayfield_Assets/20.png")
				elseif isfile and isfile("20.png") then
					customAssets["file"] = getcustomasset("20.png")
				elseif customAssets["20"] and customAssets["20"] ~= "" then
					customAssets["file"] = customAssets["20"]
				end
			end
		end)
	end
	if customAssets["run"] == nil or customAssets["run"] == "" then
		pcall(function()
			if type(getcustomasset) == "function" then
				if isfile and isfile("Rayfield_Assets/21.png") then
					customAssets["run"] = getcustomasset("Rayfield_Assets/21.png")
				elseif isfile and isfile("21.png") then
					customAssets["run"] = getcustomasset("21.png")
				elseif customAssets["21"] and customAssets["21"] ~= "" then
					customAssets["run"] = customAssets["21"]
				end
			end
		end)
	end
	if customAssets["copy"] == nil or customAssets["copy"] == "" then
		pcall(function()
			if type(getcustomasset) == "function" then
				if isfile and isfile("Rayfield_Assets/22.png") then
					customAssets["copy"] = getcustomasset("Rayfield_Assets/22.png")
				elseif isfile and isfile("22.png") then
					customAssets["copy"] = getcustomasset("22.png")
				elseif customAssets["22"] and customAssets["22"] ~= "" then
					customAssets["copy"] = customAssets["22"]
				end
			end
		end)
	end
	if customAssets["mobile"] == nil or customAssets["mobile"] == "" then
		pcall(function()
			if type(getcustomasset) == "function" then
				if isfile and isfile("Rayfield_Assets/23.png") then
					customAssets["mobile"] = getcustomasset("Rayfield_Assets/23.png")
				elseif isfile and isfile("23.png") then
					customAssets["mobile"] = getcustomasset("23.png")
				elseif customAssets["23"] and customAssets["23"] ~= "" then
					customAssets["mobile"] = customAssets["23"]
				end
			end
		end)
	end

	local isMobileEnv = (UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)) or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
	if not isMobileEnv then
		local FilesBtn = Rayfield.Main.Topbar:FindFirstChild("Files")
		if not FilesBtn then
			FilesBtn = Rayfield.Main.Topbar.Settings:Clone()
			FilesBtn.Name = "Files"
			FilesBtn.Parent = Rayfield.Main.Topbar
		end
		FilesBtn.Position = UDim2.new(1, -105, 0.5, 0)
		FilesBtn.Size = UDim2.new(0, 24, 0, 24)
		FilesBtn.AnchorPoint = Vector2.new(1, 0.5)
		if customAssets["folder"] and customAssets["folder"] ~= "" then
			FilesBtn.Image = customAssets["folder"]
		else
			FilesBtn.Image = "rbxassetid://6034287525"
		end
		FilesBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
		FilesBtn.ImageTransparency = 0.8
		FilesBtn.Visible = true
		FilesBtn.Active = true
		FilesBtn.ZIndex = 10
		Rayfield.Main.Topbar.Search.Position = UDim2.new(1, -135, 0.5, 0)
	else
		local existingFiles = Rayfield.Main.Topbar:FindFirstChild("Files")
		if existingFiles then
			existingFiles:Destroy()
		end
		Rayfield.Main.Topbar.Search.Position = UDim2.new(1, -105, 0.5, 0)
	end
	Rayfield.Main.Topbar.Search.ImageRectOffset = Vector2.new(0, 0)
	Rayfield.Main.Topbar.Search.ImageRectSize = Vector2.new(0, 0)
	safeApplyImage(Rayfield.Main.Elements.Template.Toggle.Switch.Shadow, customAssets["8"])
	safeApplyImage(Rayfield.Main.Elements.Template.Slider.Main.Shadow, customAssets["8"])
	safeApplyImage(Rayfield.Main.Elements.Template.Dropdown.Toggle, customAssets["9"])
	Rayfield.Main.Elements.Template.Dropdown.Toggle.ImageRectOffset = Vector2.new(0, 0)
	Rayfield.Main.Elements.Template.Dropdown.Toggle.ImageRectSize = Vector2.new(0, 0)
	safeApplyImage(Rayfield.Main.Elements.Template.Label.Icon, customAssets["10"])
	safeApplyImage(Rayfield.Main.Elements.Template.ColorPicker.CPBackground.MainCP, customAssets["11"])
	safeApplyImage(Rayfield.Main.Elements.Template.ColorPicker.CPBackground.MainCP.MainPoint, customAssets["12"])
	safeApplyImage(Rayfield.Main.Elements.Template.ColorPicker.ColorSlider.SliderPoint, customAssets["12"])
	if Rayfield.Main.Elements.Template.ColorPicker:FindFirstChild("Title") then
		Rayfield.Main.Elements.Template.ColorPicker.Title.RichText = false
	end
	safeApplyImage(Rayfield.Main.TabList.Template.Image, customAssets["13"])
	safeApplyImage(Rayfield.Main.Search.Search, customAssets["14"])
	safeApplyImage(Rayfield.Main.Search.Shadow, customAssets["2"])
	safeApplyImage(Rayfield.Notifications.Template.Icon, customAssets["15"])
	safeApplyImage(Rayfield.Notifications.Template.Shadow, customAssets["16"])

	local secTemplate = Rayfield.Main.Elements.Template:FindFirstChild("SectionTitle")
	if secTemplate then
		secTemplate.Size = UDim2.new(1, -10, 0, 24)
		secTemplate.ClipsDescendants = false
		if secTemplate:FindFirstChild("Title") then
			secTemplate.Title.Size = UDim2.new(1, -15, 1, 0)
			secTemplate.Title.Position = UDim2.new(0, 15, 0, 0)
			secTemplate.Title.TextScaled = false
			secTemplate.Title.TextSize = 14
			secTemplate.Title.TextXAlignment = Enum.TextXAlignment.Left
			secTemplate.Title.TextYAlignment = Enum.TextYAlignment.Center
			secTemplate.Title.ClipsDescendants = false
		end
	end
	local secSpacing = Rayfield.Main.Elements.Template:FindFirstChild("SectionSpacing")
	if secSpacing then
		secSpacing.Size = UDim2.new(1, 0, 0, 8)
	end
	if type(writefile) == "function" and type(isfile) == "function" then
		pcall(function()
			ensureFolder(RayfieldFolder)
			ensureFolder(AssetPath)
			ensureFolder(ConfigurationFolder)
			for i = 1, 23 do
				local fn = tostring(i) .. ".png"
				if isfile("Rayfield_Assets/" .. fn) then
					pcall(writefile, AssetPath .. "/" .. fn, readfile("Rayfield_Assets/" .. fn))
					pcall(writefile, fn, readfile("Rayfield_Assets/" .. fn))
				end
			end
		end)
	end

	if type(getcustomasset) == "function" and isfile and (isfile(AssetPath .. "/1.png") or isfile("Rayfield_Assets/1.png") or isfile("1.png")) then
		local logoFile = isfile(AssetPath .. "/1.png") and (AssetPath .. "/1.png") or (isfile("Rayfield_Assets/1.png") and "Rayfield_Assets/1.png" or "1.png")
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
local isMobileEnv = (UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)) or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) or (Rayfield.AbsoluteSize.Y > 0 and Rayfield.AbsoluteSize.Y < 600 and UserInputService.TouchEnabled)
local useMobileSizing = isMobileEnv or (Rayfield.AbsoluteSize.X > 0 and Rayfield.AbsoluteSize.Y > 0 and Rayfield.AbsoluteSize.X < minSize.X and Rayfield.AbsoluteSize.Y < minSize.Y)

local defaultMobileScale = 0.55
local defaultScale = useMobileSizing and defaultMobileScale or 1.0
local currentSavedScale = defaultScale

local useMobilePrompt = false
if UserInputService.TouchEnabled then
	useMobilePrompt = true
end

local Main = Rayfield.Main
local MainScale = Main:FindFirstChildOfClass("UIScale")
if not MainScale then
	MainScale = Instance.new("UIScale")
	MainScale.Parent = Main
end
MainScale.Scale = currentSavedScale

local MPrompt = Rayfield:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
TabList.ZIndex = 10
TabList.ClipsDescendants = true
TabList.ScrollingEnabled = true
TabList.ScrollingDirection = Enum.ScrollingDirection.X
TabList.ScrollBarThickness = 2
TabList.ScrollBarImageTransparency = 0.5
TabList.ElasticBehavior = Enum.ElasticBehavior.Always
TabList.AutomaticCanvasSize = Enum.AutomaticSize.X

local function updateTabListCanvas()
	local tabListLayout = TabList:FindFirstChildOfClass("UIListLayout")
	if tabListLayout then
		TabList.CanvasSize = UDim2.new(0, tabListLayout.AbsoluteContentSize.X + 30, 0, 0)
	end
end

local tabListLayout = TabList:FindFirstChildOfClass("UIListLayout")
if tabListLayout then
	tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabListCanvas)
end
TabList.ChildAdded:Connect(function()
	task.defer(updateTabListCanvas)
end)
TabList.ChildRemoved:Connect(function()
	task.defer(updateTabListCanvas)
end)

Elements.UIPageLayout:GetPropertyChangedSignal("CurrentPage"):Connect(function()
	local cur = Elements.UIPageLayout.CurrentPage
	if not cur then return end
	for _, btn in ipairs(TabList:GetChildren()) do
		if btn.ClassName == "Frame" and btn.Name ~= "Template" and btn.Name ~= "Placeholder" then
			if btn.Name == cur.Name then
				TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
					BackgroundColor3 = SelectedTheme.TabBackgroundSelected,
					BackgroundTransparency = 0
				}):Play()
				if btn:FindFirstChild("Title") then
					TweenService:Create(btn.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
						TextColor3 = SelectedTheme.SelectedTabTextColor,
						TextTransparency = 0
					}):Play()
				end
				if btn:FindFirstChild("Image") then
					TweenService:Create(btn.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
						ImageColor3 = SelectedTheme.SelectedTabTextColor,
						ImageTransparency = 0
					}):Play()
				end
				if btn:FindFirstChild("UIStroke") then
					TweenService:Create(btn.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
						Transparency = 1
					}):Play()
				end
			else
				TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
					BackgroundColor3 = SelectedTheme.TabBackground,
					BackgroundTransparency = 0.7
				}):Play()
				if btn:FindFirstChild("Title") then
					TweenService:Create(btn.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
						TextColor3 = SelectedTheme.TabTextColor,
						TextTransparency = 0.2
					}):Play()
				end
				if btn:FindFirstChild("Image") then
					TweenService:Create(btn.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
						ImageColor3 = SelectedTheme.TabTextColor,
						ImageTransparency = 0.2
					}):Play()
				end
				if btn:FindFirstChild("UIStroke") then
					TweenService:Create(btn.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
						Transparency = 0.5
					}):Play()
				end
			end
		end
	end
end)

Elements.ZIndex = 2
local dragBar = Rayfield:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil
local dragBarScale = dragBar and (dragBar:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", dragBar))
if dragBarScale then
	dragBarScale.Scale = currentSavedScale
end

local dragOffset = 255
local dragOffsetMobile = 150
local currentSavedWidth = 500
local currentSavedHeight = 475

local function updateDragBarPosition(instant)
	if not dragBar or not Main then return end
	local curScale = MainScale and MainScale.Scale or 1
	local mainHeight = (Main.Size.Y.Offset * curScale)
	if mainHeight <= 0 then mainHeight = 475 * curScale end
	local mainWidth = (Main.Size.X.Offset * curScale)
	if mainWidth <= 0 then mainWidth = 500 * curScale end

	local targetYOffset = (mainHeight / 2) + (18 * curScale)
	local targetPos = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, Main.Position.Y.Scale, Main.Position.Y.Offset + targetYOffset)

	if dragBarScale then
		dragBarScale.Scale = curScale
	end

	if instant then
		dragBar.Position = targetPos
	else
		TweenService:Create(dragBar, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
	end
end

local globalWidthSlider = nil
local globalHeightSlider = nil
local globalScaleSlider = nil
local widthSlider = nil
local heightSlider = nil
local scaleSlider = nil

local function applyScale(newScale, smooth)
	if not Main then return end
	newScale = math.clamp(tonumber(newScale) or 1, 0.25, 1.5)
	currentSavedScale = newScale
	if not MainScale then
		MainScale = Main:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", Main)
	end
	if smooth then
		TweenService:Create(MainScale, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = newScale}):Play()
		if dragBarScale then
			TweenService:Create(dragBarScale, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = newScale}):Play()
		end
	else
		MainScale.Scale = newScale
		if dragBarScale then
			dragBarScale.Scale = newScale
		end
	end
	updateDragBarPosition(not smooth)
end

function RayfieldLibrary:ChangeScale(newScale, smooth)
	if smooth == nil then smooth = true end
	applyScale(newScale, smooth)
	if globalScaleSlider and globalScaleSlider.Set then
		pcall(function() globalScaleSlider:Set(newScale) end)
	end
end

function RayfieldLibrary:SetScale(newScale, smooth)
	RayfieldLibrary:ChangeScale(newScale, smooth)
end

local function applySize(newW, newH, smooth)
	if not Main then return end
	newW = math.clamp(math.round(newW or currentSavedWidth), 350, 1200)
	newH = math.clamp(math.round(newH or currentSavedHeight), 200, 1000)
	currentSavedWidth = newW
	currentSavedHeight = newH

	local tweenTime = smooth and 0.45 or 0.14
	local tweenStyle = smooth and Enum.EasingStyle.Back or Enum.EasingStyle.Quad
	local tweenDirection = Enum.EasingDirection.Out
	local anim = TweenInfo.new(tweenTime, tweenStyle, tweenDirection)

	TweenService:Create(Main, anim, {Size = UDim2.new(0, newW, 0, newH)}):Play()
	if Topbar then
		TweenService:Create(Topbar, anim, {Size = UDim2.new(0, newW, 0, 45)}):Play()
		if Topbar:FindFirstChild("Divider") then
			TweenService:Create(Topbar.Divider, anim, {Size = UDim2.new(1, 0, 0, 1)}):Play()
		end
	end

	if smooth and Main:FindFirstChild("Shadow") and Main.Shadow:FindFirstChild("Image") then
		local shadowAnim = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local shadowReset = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(Main.Shadow.Image, shadowAnim, {ImageTransparency = 0.35}):Play()
		task.delay(0.2, function()
			if Main and Main:FindFirstChild("Shadow") and Main.Shadow:FindFirstChild("Image") then
				TweenService:Create(Main.Shadow.Image, shadowReset, {ImageTransparency = 0.6}):Play()
			end
		end)
	end

	updateDragBarPosition(not smooth)
end

Rayfield.DisplayOrder = 100
LoadingFrame.Version.Text = Release

local Icons = nil
pcall(function()
	if useStudio and script and script.Parent then
		local iconModule = script.Parent:FindFirstChild("icons")
		if iconModule and iconModule:IsA("ModuleScript") then Icons = require(iconModule) end
	else
		Icons = loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua', 3)
	end
end)

local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = Rayfield.Notifications
local keybindConnections = {}

local SelectedTheme = RayfieldLibrary.Theme.Default
local currentUIFont = Enum.Font.Gotham
local refreshFileListGlobal = nil
local updateFileExplorerTheme: (() -> ())? = nil

local currentActiveTabName: string? = nil
local function ChangeTheme(Theme)
	if typeof(Theme) == 'string' then
		if RayfieldLibrary.Theme[Theme] then
			SelectedTheme = RayfieldLibrary.Theme[Theme]
		end
	elseif typeof(Theme) == 'table' then
		local baseTheme = (Theme.Base and RayfieldLibrary.Theme[Theme.Base]) or RayfieldLibrary.Theme.Default
		local merged = {}
		for k, v in pairs(baseTheme) do
			merged[k] = v
		end
		for k, v in pairs(Theme) do
			if k ~= "Base" then
				merged[k] = v
			end
		end
		SelectedTheme = merged
	end

	if not SelectedTheme.Font then
		SelectedTheme.Font = currentUIFont
	else
		currentUIFont = SelectedTheme.Font
	end

	local themeAccent = SelectedTheme.Accent or SelectedTheme.ToggleEnabled or SelectedTheme.SliderProgress or SelectedTheme.TextColor or Color3.fromRGB(255, 255, 255)

	local anim = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	TweenService:Create(Rayfield.Main, anim, {BackgroundColor3 = SelectedTheme.Background}):Play()
	TweenService:Create(Rayfield.Main.Topbar, anim, {BackgroundColor3 = SelectedTheme.Topbar}):Play()
	TweenService:Create(Rayfield.Main.Topbar.CornerRepair, anim, {BackgroundColor3 = SelectedTheme.Topbar}):Play()
	TweenService:Create(Rayfield.Main.Shadow.Image, anim, {ImageColor3 = SelectedTheme.Shadow}):Play()

	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
	if Rayfield.Main.Topbar:FindFirstChild('Icon') then
		Rayfield.Main.Topbar.Icon.ImageColor3 = themeAccent
	end
	if Rayfield.Main.Topbar:FindFirstChild('Files') then
		Rayfield.Main.Topbar.Files.ImageColor3 = SelectedTheme.TextColor
	end
	if Topbar:FindFirstChild('Settings') then
		Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
		Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	end

	local mobileToggle = Rayfield:FindFirstChild("RayfieldMobileToggle")
	if mobileToggle then
		TweenService:Create(mobileToggle, anim, {BackgroundColor3 = SelectedTheme.SecondaryElementBackground}):Play()
		if mobileToggle:FindFirstChild("UIStroke") then
			TweenService:Create(mobileToggle.UIStroke, anim, {Color = SelectedTheme.ElementStroke}):Play()
		end
		local icon = mobileToggle:FindFirstChild("Icon")
		if icon then
			TweenService:Create(icon, anim, {ImageColor3 = themeAccent}):Play()
		end
	end

	Main.Search.BackgroundColor3 = SelectedTheme.InputBackground or SelectedTheme.Background
	Main.Search.Shadow.ImageColor3 = SelectedTheme.Shadow
	Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Input.PlaceholderColor3 = SelectedTheme.PlaceholderColor or Color3.fromRGB(140, 140, 150)
	Main.Search.Input.TextColor3 = SelectedTheme.TextColor
	Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke or SelectedTheme.ElementStroke

	if Main:FindFirstChild('Notice') then
		Main.Notice.BackgroundColor3 = SelectedTheme.Background
	end

	for _, text in ipairs(Rayfield:GetDescendants()) do
		if text.Parent and text.Parent.Parent ~= Notifications then
			if text:IsA('TextLabel') or text:IsA('TextBox') or text:IsA('TextButton') then
				text.TextColor3 = SelectedTheme.TextColor
				if SelectedTheme.Font and not text:GetAttribute("KeepFont") then
					pcall(function() text.Font = SelectedTheme.Font end)
				end
			end
		end
	end

	for _, TabPage in ipairs(Elements:GetChildren()) do
		if TabPage.Name ~= "Workspace" and (TabPage:IsA("ScrollingFrame") or TabPage:IsA("Frame")) then
			if TabPage:IsA("ScrollingFrame") then
				TabPage.ScrollBarImageColor3 = SelectedTheme.ElementStroke
			end
			for _, Element in ipairs(TabPage:GetChildren()) do
				if Element:IsA("Frame") and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
					if Element.Name == "SectionTitle" then
						if Element:FindFirstChild('Title') then
							Element.Title.TextColor3 = SelectedTheme.TextColor
						end
					elseif Element.Name == "Paragraph" or Element:FindFirstChild("Content") or Element.Name == "Label" then
						TweenService:Create(Element, anim, {BackgroundColor3 = SelectedTheme.SecondaryElementBackground}):Play()
						if Element:FindFirstChild('UIStroke') then
							TweenService:Create(Element.UIStroke, anim, {Color = SelectedTheme.SecondaryElementStroke}):Play()
						end
						if Element:FindFirstChild('Title') and Element.Title:IsA("TextLabel") then
							Element.Title.TextColor3 = SelectedTheme.TextColor
						end
						if Element:FindFirstChild('Content') and Element.Content:IsA("TextLabel") then
							Element.Content.TextColor3 = SelectedTheme.TextColor
						end
					else
						TweenService:Create(Element, anim, {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
						if Element:FindFirstChild('UIStroke') then
							TweenService:Create(Element.UIStroke, anim, {Color = SelectedTheme.ElementStroke}):Play()
						end
						if Element:FindFirstChild('Title') and Element.Title:IsA("TextLabel") then
							Element.Title.TextColor3 = SelectedTheme.TextColor
						end
						if Element:FindFirstChild('ElementIndicator') then
							Element.ElementIndicator.TextColor3 = SelectedTheme.TextColor
						end

						local list = Element:FindFirstChild('List')
						if list then
							local selectedText = Element:FindFirstChild('Selected') and Element.Selected.Text or ""
							if Element:FindFirstChild('Selected') then
								Element.Selected.TextColor3 = SelectedTheme.TextColor
							end
							if Element:FindFirstChild('Toggle') then
								Element.Toggle.ImageColor3 = SelectedTheme.TextColor
							end
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
									if opt:FindFirstChild('Title') then
										opt.Title.TextColor3 = SelectedTheme.TextColor
									end
								end
							end
						end

						local switch = Element:FindFirstChild('Switch')
						if switch then
							TweenService:Create(switch, anim, {BackgroundColor3 = SelectedTheme.ToggleBackground}):Play()
							local indicator = switch:FindFirstChild('Indicator')
							if indicator then
								local isEnabled = indicator.Position.X.Offset > -30 or indicator.Position.X.Scale > 0.5
								if isEnabled then
									TweenService:Create(indicator, anim, {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
									if indicator:FindFirstChild('UIStroke') then
										TweenService:Create(indicator.UIStroke, anim, {Color = SelectedTheme.ToggleEnabledStroke}):Play()
									end
									if switch:FindFirstChild('UIStroke') then
										TweenService:Create(switch.UIStroke, anim, {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
									end
								else
									TweenService:Create(indicator, anim, {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
									if indicator:FindFirstChild('UIStroke') then
										TweenService:Create(indicator.UIStroke, anim, {Color = SelectedTheme.ToggleDisabledStroke}):Play()
									end
									if switch:FindFirstChild('UIStroke') then
										TweenService:Create(switch.UIStroke, anim, {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
									end
								end
							end
						end

						local sliderMain = Element:FindFirstChild('Main')
						if sliderMain and sliderMain:FindFirstChild('Progress') then
							TweenService:Create(sliderMain, anim, {BackgroundColor3 = SelectedTheme.SliderBackground}):Play()
							TweenService:Create(sliderMain.Progress, anim, {BackgroundColor3 = SelectedTheme.SliderProgress}):Play()
							if sliderMain:FindFirstChild('UIStroke') then
								TweenService:Create(sliderMain.UIStroke, anim, {Color = SelectedTheme.SliderStroke or SelectedTheme.ElementStroke}):Play()
							end
							if sliderMain.Progress:FindFirstChild('UIStroke') then
								TweenService:Create(sliderMain.Progress.UIStroke, anim, {Color = SelectedTheme.SliderStroke or SelectedTheme.ElementStroke}):Play()
							end
							if sliderMain:FindFirstChild('Information') then
								sliderMain.Information.TextColor3 = SelectedTheme.TextColor
							end
						end

						local keybindFrame = Element:FindFirstChild('KeybindFrame')
						if keybindFrame then
							TweenService:Create(keybindFrame, anim, {BackgroundColor3 = SelectedTheme.InputBackground}):Play()
							if keybindFrame:FindFirstChild('UIStroke') then
								TweenService:Create(keybindFrame.UIStroke, anim, {Color = SelectedTheme.InputStroke}):Play()
							end
							if keybindFrame:FindFirstChild('KeybindBox') then
								keybindFrame.KeybindBox.TextColor3 = SelectedTheme.TextColor
							end
						end

						local inputFrame = Element:FindFirstChild('InputFrame')
						if inputFrame then
							TweenService:Create(inputFrame, anim, {BackgroundColor3 = SelectedTheme.InputBackground}):Play()
							if inputFrame:FindFirstChild('UIStroke') then
								TweenService:Create(inputFrame.UIStroke, anim, {Color = SelectedTheme.InputStroke}):Play()
							end
							local inputBox = inputFrame:FindFirstChild('InputBox')
							if inputBox then
								inputBox.TextColor3 = SelectedTheme.TextColor
								inputBox.PlaceholderColor3 = SelectedTheme.PlaceholderColor or Color3.fromRGB(178, 178, 178)
							end
						end
					end
				end
			end
		end
	end

	if updateFileExplorerTheme then
		pcall(updateFileExplorerTheme)
	end

	for _, TabButton in ipairs(TabList:GetChildren()) do
		if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" and TabButton.Name ~= "Template" then
			if TabButton:FindFirstChild('UIStroke') then
				TabButton.UIStroke.Color = SelectedTheme.TabStroke
			end
			local isTabSelected = (currentActiveTabName and TabButton.Name == currentActiveTabName) or (Elements.UIPageLayout and Elements.UIPageLayout.CurrentPage and Elements.UIPageLayout.CurrentPage.Name == TabButton.Name)
			if isTabSelected then
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

local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}?
	if not Icons or type(Icons) ~= "table" then
		return nil
	end
	name = string.match(string.lower(name), "^%s*(.-)%s*$") :: string
	local sizedicons = nil
	pcall(function()
		sizedicons = Icons['48px']
	end)
	if type(sizedicons) ~= "table" then
		return nil
	end
	local r = sizedicons[name]
	if not r or type(r) ~= "table" then
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
		if asset and asset.id then
			return "rbxassetid://" .. asset.id, asset.imageRectOffset, asset.imageRectSize
		else
			return getAssetUri(icon), nil, nil
		end
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

	local dragBegan = dragObject.InputBegan:Connect(function(input, processed)
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
	table.insert(allLibraryConnections, dragBegan)

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
	table.insert(allLibraryConnections, inputEnded)

	local renderStepped = RunService.RenderStepped:Connect(function()
		if dragging and not Hidden then
			local position = UserInputService:GetMouseLocation() + relative + offset
			local mainH = object.Size.Y.Offset
			if mainH <= 0 then mainH = 475 end
			local curScale = MainScale and MainScale.Scale or 1
			local targetDragY = position.Y + ((mainH * curScale) / 2) + (18 * curScale)

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

	table.insert(allLibraryConnections, renderStepped)
	local destroyConn
	destroyConn = object.Destroying:Connect(function()
		if dragBegan then dragBegan:Disconnect() end
		if inputEnded then inputEnded:Disconnect() end
		if renderStepped then renderStepped:Disconnect() end
		if destroyConn then destroyConn:Disconnect() end
	end)
	table.insert(allLibraryConnections, destroyConn)
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

	if not success or type(Data) ~= "table" then return end

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

	if useStudio and script and script.Parent then
		local oldConfig = script.Parent:FindFirstChild('configuration')
		if oldConfig then oldConfig:Destroy() end

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
		newNotification.BackgroundColor3 = SelectedTheme.NotificationBackground or SelectedTheme.Background
		newNotification.UIStroke.Color = SelectedTheme.ElementStroke
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

local lastClosedPosition = nil

local function Hide(notify: boolean?)
	if Main then
		lastClosedPosition = Main.Position
	end
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
	if lastClosedPosition then
		Main.Position = lastClosedPosition
	end
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

	if dragBar then
		updateDragBarPosition(true)
	end

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
	local success = pcall(function()
		encoded = HttpService:JSONEncode(settingsTable)
	end)

	if success then
		if useStudio and script and script.Parent then
			local getVal = script.Parent:FindFirstChild('get.val')
			if getVal and getVal:IsA("ValueBase") then
				(getVal :: any).Value = encoded
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

local function createSettings(window, winSettings)
	winSettings = winSettings or {}
	local initialThemeName = "Default"
	if winSettings.Theme then
		if type(winSettings.Theme) == "string" and RayfieldLibrary.Theme[winSettings.Theme] then
			initialThemeName = winSettings.Theme
		elseif type(winSettings.Theme) == "table" and winSettings.Theme.Base and RayfieldLibrary.Theme[winSettings.Theme.Base] then
			initialThemeName = winSettings.Theme.Base
		end
	end

	local defaultWidth = winSettings.Width or currentSavedWidth or 500
	local defaultHeight = winSettings.Height or currentSavedHeight or 475

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

	scaleSlider = newTab:CreateSlider({
		Name = "UI Scale",
		Range = {0.3, 1.2},
		Increment = 0.05,
		Suffix = "x",
		CurrentValue = currentSavedScale,
		Ext = true,
		Callback = function(Value)
			applyScale(Value, false)
		end
	})
	globalScaleSlider = scaleSlider

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
	globalWidthSlider = widthSlider

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
	globalHeightSlider = heightSlider

	newTab:CreateButton({
		Name = "Reset to Default Size (" .. tostring(defaultWidth) .. "x" .. tostring(defaultHeight) .. ")",
		Ext = true,
		Callback = function()
			widthSlider:Set(defaultWidth)
			heightSlider:Set(defaultHeight)
			applySize(defaultWidth, defaultHeight, true)
			if scaleSlider then
				scaleSlider:Set(defaultScale)
				applyScale(defaultScale, true)
			end
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

	local initialFontName = currentUIFont and currentUIFont.Name or "Gotham"
	if winSettings.Font then
		if type(winSettings.Font) == "string" and table.find(fontList, winSettings.Font) then
			initialFontName = winSettings.Font
		elseif typeof(winSettings.Font) == "EnumItem" and table.find(fontList, winSettings.Font.Name) then
			initialFontName = winSettings.Font.Name
		end
	elseif SelectedTheme and SelectedTheme.Font and typeof(SelectedTheme.Font) == "EnumItem" then
		initialFontName = SelectedTheme.Font.Name
	end

	local fontDropdown = newTab:CreateDropdown({
		Name = "UI Font Family",
		Options = fontList,
		CurrentOption = {initialFontName},
		MultipleOptions = false,
		Ext = true,
		Callback = function(Option)
			local chosen = typeof(Option) == "table" and Option[1] or Option
			local targetFont = safeFont(chosen) or Enum.Font.Gotham
			currentUIFont = targetFont
			SelectedTheme.Font = targetFont
			for _, desc in ipairs(Rayfield:GetDescendants()) do
				if (desc:IsA("TextLabel") or desc:IsA("TextBox") or desc:IsA("TextButton")) and not desc:GetAttribute("KeepFont") then
					pcall(function() desc.Font = targetFont end)
				end
			end
			pcall(function()
				if refreshFileListGlobal then
					refreshFileListGlobal()
				end
			end)
		end
	})

	newTab:CreateSection("Theme Preset")

	local themeNames = {}
	for tName, _ in pairs(RayfieldLibrary.Theme) do
		table.insert(themeNames, tName)
	end
	table.sort(themeNames)

	newTab:CreateDropdown({
		Name = "Preset Themes",
		Options = themeNames,
		CurrentOption = {initialThemeName},
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
			local h, s, v = Color:ToHSV()
			SelectedTheme.ElementBackgroundHover = Color3.fromHSV(h, s, math.clamp(v + 0.05, 0, 1))
			for _, TabPage in ipairs(Elements:GetChildren()) do
				for _, Element in ipairs(TabPage:GetChildren()) do
					if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
						if Element.Name ~= "Paragraph" and not Element:FindFirstChild("Content") and Element.Name ~= "Label" then
							TweenService:Create(Element, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundColor3 = Color}):Play()
						end
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
			local activeName = if (Elements.UIPageLayout and Elements.UIPageLayout.CurrentPage and Elements.UIPageLayout.CurrentPage.Name ~= "Settings" and Elements.UIPageLayout.CurrentPage.Name ~= "Rayfield Settings") then Elements.UIPageLayout.CurrentPage.Name else currentActiveTabName
			for _, TabButton in ipairs(TabList:GetChildren()) do
				if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" and TabButton.Name ~= "Template" then
					if TabButton.Name ~= activeName then
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
			local activeName = if (Elements.UIPageLayout and Elements.UIPageLayout.CurrentPage and Elements.UIPageLayout.CurrentPage.Name ~= "Settings" and Elements.UIPageLayout.CurrentPage.Name ~= "Rayfield Settings") then Elements.UIPageLayout.CurrentPage.Name else currentActiveTabName
			for _, TabButton in ipairs(TabList:GetChildren()) do
				if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" and TabButton.Name ~= "Template" then
					if TabButton.Name == activeName then
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
			if Rayfield.Main.Topbar:FindFirstChild('Icon') then
				Rayfield.Main.Topbar.Icon.ImageColor3 = Color
			end
			for _, TabPage in ipairs(Elements:GetChildren()) do
				if TabPage:IsA("ScrollingFrame") or TabPage:IsA("Frame") then
					for _, Element in ipairs(TabPage:GetChildren()) do
						if Element:IsA("Frame") then
							local switch = Element:FindFirstChild('Switch')
							if switch and switch:FindFirstChild('Indicator') then
								local isEnabled = switch.Indicator.Position.X.Offset > -30 or switch.Indicator.Position.X.Scale > 0.5
								if isEnabled then
									switch.Indicator.BackgroundColor3 = Color
									if switch.Indicator:FindFirstChild('UIStroke') then
										switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke or Color
									end
									if switch:FindFirstChild('UIStroke') then
										switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke or Color
									end
								end
							end
							local sliderMain = Element:FindFirstChild('Main')
							if sliderMain and sliderMain:FindFirstChild('Progress') then
								sliderMain.Progress.BackgroundColor3 = Color
							end
						end
					end
				end
			end
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
						return
					end
				end
			end
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
	currentWindowSettings = Settings
	if Rayfield:FindFirstChild('Loading') then
		if getgenv and not getgenv().rayfieldCached then
			Rayfield.Enabled = true
			Rayfield.Loading.BackgroundTransparency = 1
			Rayfield.Loading.Visible = true

			local banner = Rayfield.Loading:FindFirstChild('Banner')
			if banner then
				if Settings.LoadingImage and tostring(Settings.LoadingImage) ~= "" then
					banner.Image = tostring(Settings.LoadingImage)
				elseif type(getcustomasset) == "function" and isfile and (isfile(AssetPath .. "/1.png") or isfile("Rayfield_Assets/1.png") or isfile("1.png")) then
					local logoFile = isfile(AssetPath .. "/1.png") and (AssetPath .. "/1.png") or (isfile("Rayfield_Assets/1.png") and "Rayfield_Assets/1.png" or "1.png")
					banner.Image = getcustomasset(logoFile)
				elseif customAssets["1"] and #customAssets["1"] > 0 then
					banner.Image = customAssets["1"]
				end
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
				task.wait(0.45)
			end

			Rayfield.Loading.Visible = false
		end
	end

	if getgenv then getgenv().rayfieldCached = true end



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

	local windowSafeName = "Rayfield_" .. (Settings.Name and string.gsub(Settings.Name, "[^%w_]+", "") or "Window")
	Rayfield.Name = windowSafeName
	if Settings.DisableOld ~= false then
		safeCleanOldGui(windowSafeName, Rayfield)
	end

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

	if Settings.Scale and type(Settings.Scale) == "number" then
		currentSavedScale = math.clamp(Settings.Scale, 0.25, 1.5)
	elseif Settings.WindowScale and type(Settings.WindowScale) == "number" then
		currentSavedScale = math.clamp(Settings.WindowScale, 0.25, 1.5)
	else
		currentSavedScale = useMobileSizing and defaultMobileScale or 1.0
	end
	applyScale(currentSavedScale, false)

	if Settings.Width and type(Settings.Width) == "number" then
		currentSavedWidth = math.clamp(Settings.Width, 350, 1200)
	end
	if Settings.Height and type(Settings.Height) == "number" then
		currentSavedHeight = math.clamp(Settings.Height, 200, 1000)
	end
	if Settings.Size then
		if typeof(Settings.Size) == "UDim2" then
			currentSavedWidth = math.clamp(Settings.Size.X.Offset, 350, 1200)
			currentSavedHeight = math.clamp(Settings.Size.Y.Offset, 200, 1000)
		elseif typeof(Settings.Size) == "Vector2" then
			currentSavedWidth = math.clamp(Settings.Size.X, 350, 1200)
			currentSavedHeight = math.clamp(Settings.Size.Y, 200, 1000)
		elseif type(Settings.Size) == "table" then
			if Settings.Size[1] and Settings.Size[2] then
				currentSavedWidth = math.clamp(Settings.Size[1], 350, 1200)
				currentSavedHeight = math.clamp(Settings.Size[2], 200, 1000)
			elseif Settings.Size.Width and Settings.Size.Height then
				currentSavedWidth = math.clamp(Settings.Size.Width, 350, 1200)
				currentSavedHeight = math.clamp(Settings.Size.Height, 200, 1000)
			end
		end
	end

	if Settings.Theme then
		local success = pcall(ChangeTheme, Settings.Theme)
		if not success then
			pcall(ChangeTheme, 'Default')
		end
	end

	if Settings.Colors and type(Settings.Colors) == "table" then
		for cKey, cVal in pairs(Settings.Colors) do
			if typeof(cVal) == "Color3" then
				SelectedTheme[cKey] = cVal
			end
		end
		pcall(ChangeTheme, SelectedTheme)
	end

	if Settings.Font then
		local customF = safeFont(Settings.Font) or (typeof(Settings.Font) == "EnumItem" and Settings.Font)
		if customF then
			currentUIFont = customF
			SelectedTheme.Font = customF
			for _, desc in ipairs(Rayfield:GetDescendants()) do
				if (desc:IsA("TextLabel") or desc:IsA("TextBox") or desc:IsA("TextButton")) and not desc:GetAttribute("KeepFont") then
					pcall(function() desc.Font = customF end)
				end
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
					Title = "UnknownSquad",
					Content = "Join our Discord: https://discord.gg/Gr4bcaqmrk",
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
	if dragBar then
		dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset)
		makeDraggable(Main, dragInteract, true, {dragOffset, dragOffsetMobile})
	end

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

	local Window = {}
	if (Settings.KeySystem) then
		if not Settings.KeySettings then
			Passthrough = true
			return
		end

		ensureFolder(RayfieldFolder.."/Key System")

		if typeof(Settings.KeySettings.Key) == "string" then Settings.KeySettings.Key = {Settings.KeySettings.Key} end

		if Settings.KeySettings.GrabKeyFromSite then
			for i, Key in ipairs(Settings.KeySettings.Key) do
				pcall(function()
					local rawKey = game:HttpGet(Key)
					local cleanKey = string.gsub(rawKey, "[\n\r]", " ")
					local sanitizedKey = string.gsub(cleanKey, " ", "")
					Settings.KeySettings.Key[i] = sanitizedKey
				end)
			end
		end

		if not Settings.KeySettings.FileName then
			Settings.KeySettings.FileName = "No file name specified"
		end

		if callSafely(isfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension) then
			local savedKeys = callSafely(readfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension)
			if savedKeys then
				for _, MKey in ipairs(Settings.KeySettings.Key) do
					if string.find(savedKeys, MKey, 1, true) then
						Passthrough = true
						break
					end
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
			local KeyUI = nil
			if useStudio and script and script.Parent then
				KeyUI = script.Parent:FindFirstChild("Key")
			else
				local ok, objs = pcall(function() return game:GetObjects("rbxassetid://11380036235") end)
				if ok and type(objs) == "table" and objs[1] then KeyUI = objs[1] end
			end
			if not KeyUI then
				warn("Rayfield: Key UI asset could not be loaded, bypassing key system.")
				Passthrough = true
			else
			local keySafeName = "KeyUI_" .. (Settings.Name and string.gsub(Settings.Name, "[^%w_]+", "") or "Window")
			KeyUI.Name = keySafeName
			safeParentGui(KeyUI)
			safeCleanOldGui(keySafeName, KeyUI)

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
						pcall(function() Players.LocalPlayer:Kick("No Attempts Remaining") end)
						pcall(function() game:Shutdown() end)
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
			end
		else
			Passthrough = true
		end
	end
	if Settings.KeySystem then
		repeat task.wait() until Passthrough
		if rayfieldDestroyed then return Window end
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
	Window = Window or {}
	function Window:CreateTab(Name, Image, Ext)
		local SDone = false
		local TabButton = TabList.Template:Clone()
		TabButton.Name = Name
		TabButton.Title.Text = Name
		TabButton.Parent = TabList
		TabButton.Title.TextWrapped = false

		local function getTabTitleWidth()
			local textWidth = 0
			pcall(function()
				textWidth = TextService:GetTextSize(Name, TabButton.Title.TextSize, TabButton.Title.Font, Vector2.new(1000, 30)).X
			end)
			if textWidth <= 0 then
				textWidth = TabButton.Title.TextBounds.X
			end
			return textWidth
		end

		local tw = getTabTitleWidth()
		if Image and Image ~= 0 then
			local img, rectOffset, rectSize = resolveIcon(Image)
			TabButton.Image.Image = img
			if rectOffset then TabButton.Image.ImageRectOffset = rectOffset end
			if rectSize then TabButton.Image.ImageRectSize = rectSize end

			TabButton.Title.AnchorPoint = Vector2.new(0, 0.5)
			TabButton.Title.Position = UDim2.new(0, 37, 0.5, 0)
			TabButton.Image.Visible = true
			TabButton.Title.TextXAlignment = Enum.TextXAlignment.Left
			TabButton.Size = UDim2.new(0, math.max(tw + 52, 70), 0, 30)
		else
			TabButton.Size = UDim2.new(0, math.max(tw + 30, 50), 0, 30)
		end

		if tw <= 0 then
			local c
			c = TabButton.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				if TabButton.Title.TextBounds.X > 0 then
					c:Disconnect()
					local newTw = TabButton.Title.TextBounds.X
					if Image and Image ~= 0 then
						TabButton.Size = UDim2.new(0, math.max(newTw + 52, 70), 0, 30)
					else
						TabButton.Size = UDim2.new(0, math.max(newTw + 30, 50), 0, 30)
					end
				end
			end)
		end

		TabButton.BackgroundTransparency = 1
		TabButton.Title.TextTransparency = 1
		TabButton.Image.ImageTransparency = 1
		TabButton.UIStroke.Transparency = 1
		TabButton.Visible = not Ext or false

		TabButton.Interact.Size = UDim2.new(1, 0, 1, 0)
		TabButton.Interact.Position = UDim2.new(0, 0, 0, 0)
		TabButton.Interact.ZIndex = 25
		TabButton.Interact.Active = true
		TabButton.Interact.AutoButtonColor = false
		TabButton.Title.Active = false
		TabButton.Image.Active = false
		TabButton.Title.ZIndex = 20
		TabButton.Image.ZIndex = 20

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

		local isFirst = false
		if not FirstTab and not Ext then
			FirstTab = Name
			currentActiveTabName = Name
			isFirst = true
		end

		TabPage.Parent = Elements
		if isFirst then
			Elements.UIPageLayout.Animated = false
			Elements.UIPageLayout:JumpTo(TabPage)
			Elements.UIPageLayout.Animated = true
		end

		TabButton.UIStroke.Color = SelectedTheme.TabStroke

		if isFirst then
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
		else
			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
		end

		local selectDebounce = false
		local function selectThisTab()
			if selectDebounce then return end
			selectDebounce = true
			task.delay(0.12, function() selectDebounce = false end)
			if Minimised then return end
			currentActiveTabName = TabButton.Name
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

			pcall(function()
				local frameW = TabList.AbsoluteSize.X
				if frameW > 0 then
					local btnX = TabButton.AbsolutePosition.X - TabList.AbsolutePosition.X + TabList.CanvasPosition.X
					local btnW = TabButton.AbsoluteSize.X
					local targetX = math.clamp(btnX - (frameW / 2) + (btnW / 2), 0, math.max(0, TabList.AbsoluteCanvasSize.X - frameW))
					TweenService:Create(TabList, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(targetX, 0)}):Play()
				end
			end)
		end

		TabButton.Interact.Activated:Connect(selectThisTab)
		TabButton.Interact.MouseButton1Click:Connect(selectThisTab)

		local touchStartPos = nil
		local function onTouchBegan(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				touchStartPos = input.Position
			end
		end
		local function onTouchEnded(input)
			if input.UserInputType == Enum.UserInputType.Touch and touchStartPos then
				local delta = (input.Position - touchStartPos).Magnitude
				touchStartPos = nil
				if delta < 16 then
					selectThisTab()
				end
			end
		end

		TabButton.Interact.InputBegan:Connect(onTouchBegan)
		TabButton.Interact.InputEnded:Connect(onTouchEnded)
		TabButton.InputBegan:Connect(onTouchBegan)
		TabButton.InputEnded:Connect(onTouchEnded)

		local Tab = {}

		function Tab:CreateButton(ButtonSettings)
			local ButtonValue = {}

			local Button = Elements.Template.Button:Clone()
			Button.Name = ButtonSettings.Name
			Button.Title.Text = ButtonSettings.Name
			Button.Visible = true
			Button.Parent = TabPage

			Button.BackgroundColor3 = SelectedTheme.ElementBackground
			Button.UIStroke.Color = SelectedTheme.ElementStroke
			Button.BackgroundTransparency = 1
			Button.UIStroke.Transparency = 1
			Button.Title.TextTransparency = 1

			TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Button.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			Button.Interact.MouseButton1Click:Connect(function()
				local Success = pcall(ButtonSettings.Callback)
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
						SaveConfiguration()
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
			if ColorPicker:FindFirstChild("Title") then
				ColorPicker.Title.RichText = false
				ColorPicker.Title.Text = ""
				ColorPicker.Title.Text = ColorPickerSettings.Name
				ColorPicker.Title.TextTransparency = 0
				ColorPicker.Title.Visible = true
			end
			ColorPicker.Parent = TabPage
			ColorPicker.Size = UDim2.new(1, -10, 0, 45)

			Background.AnchorPoint = Vector2.new(1, 0.5)
			Background.Position = UDim2.new(1, -20, 0.5, 0)
			Background.Size = UDim2.new(0, 39, 0, 22)
			Background.ClipsDescendants = true
			Display.BackgroundTransparency = 0
			Display.ZIndex = 5

			local displayStroke = Display:FindFirstChildOfClass("UIStroke")
			if not displayStroke then
				displayStroke = Instance.new("UIStroke")
				displayStroke.Name = "Stroke"
				displayStroke.Color = SelectedTheme.ElementStroke or Color3.fromRGB(80, 80, 80)
				displayStroke.Thickness = 1
				displayStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				displayStroke.Parent = Display
			end

			Slider.AnchorPoint = Vector2.new(1, 0)
			Slider.Position = UDim2.new(1, -20, 0, 104)
			Slider.Size = UDim2.new(0, 173, 0, 12)
			Slider.ClipsDescendants = false
			Slider.Active = true
			Slider.ZIndex = 1
			Slider.Visible = false
			if Slider:FindFirstChild("SliderPoint") then
				Slider.SliderPoint.AnchorPoint = Vector2.new(0.5, 0.5)
				Slider.SliderPoint.Active = true
				Slider.SliderPoint.ZIndex = 5
				Slider.SliderPoint.ImageTransparency = 1
			end

			Main.Image = ""
			Main.BackgroundTransparency = 0
			Main.Active = true
			Main.ClipsDescendants = false
			Main.AnchorPoint = Vector2.new(0.5, 0.5)
			Main.Position = UDim2.new(0.5, 0, 0.5, 0)
			Main.Size = UDim2.new(1, 0, 1, 0)
			Main.ZIndex = 1
			Main.Visible = false

			local mainCorner = Main:FindFirstChildOfClass("UICorner")
			if not mainCorner then
				mainCorner = Instance.new("UICorner")
				mainCorner.CornerRadius = Background.UICorner.CornerRadius
				mainCorner.Parent = Main
			end

			local satGradFrame = Instance.new("Frame")
			satGradFrame.Name = "SatGradFrame"
			satGradFrame.Size = UDim2.new(1, 0, 1, 0)
			satGradFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			satGradFrame.BackgroundTransparency = 0
			satGradFrame.BorderSizePixel = 0
			satGradFrame.Active = false
			satGradFrame.ZIndex = 2
			local satCorner = Instance.new("UICorner")
			satCorner.CornerRadius = Background.UICorner.CornerRadius
			satCorner.Parent = satGradFrame
			local satUIGrad = Instance.new("UIGradient")
			satUIGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			satUIGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			})
			satUIGrad.Parent = satGradFrame
			satGradFrame.Parent = Main

			local valGradFrame = Instance.new("Frame")
			valGradFrame.Name = "ValGradFrame"
			valGradFrame.Size = UDim2.new(1, 0, 1, 0)
			valGradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			valGradFrame.BackgroundTransparency = 0
			valGradFrame.BorderSizePixel = 0
			valGradFrame.Active = false
			valGradFrame.ZIndex = 3
			local valCorner = Instance.new("UICorner")
			valCorner.CornerRadius = Background.UICorner.CornerRadius
			valCorner.Parent = valGradFrame
			local valUIGrad = Instance.new("UIGradient")
			valUIGrad.Rotation = 90
			valUIGrad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
			valUIGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0)
			})
			valUIGrad.Parent = valGradFrame
			valGradFrame.Parent = Main

			Main.MainPoint.ZIndex = 5
			Main.MainPoint.AnchorPoint = Vector2.new(0.5, 0.5)
			Main.MainPoint.Active = true
			Main.MainPoint.ImageTransparency = 1
			Main.MainPoint.Visible = false

			satGradFrame.Visible = false
			valGradFrame.Visible = false

			ColorPicker.Interact.Size = UDim2.new(1, 0, 1, 0)
			ColorPicker.Interact.Position = UDim2.new(0.5, 0, 0.5, 0)
			ColorPicker.Interact.AnchorPoint = Vector2.new(0.5, 0.5)
			ColorPicker.RGB.Position = UDim2.new(0, 17, 0, 70)
			ColorPicker.RGB.Visible = false
			ColorPicker.HexInput.Position = UDim2.new(0, 17, 0, 90)
			ColorPicker.HexInput.Visible = false

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
					Background.ClipsDescendants = false
					Main.Visible = true
					satGradFrame.Visible = true
					valGradFrame.Visible = true
					Main.MainPoint.Visible = true
					Slider.Visible = true
					ColorPicker.RGB.Visible = true
					ColorPicker.HexInput.Visible = true
					Background.AnchorPoint = Vector2.new(1, 0)
					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 128)}):Play()
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(1, -20, 0, 10), Size = UDim2.new(0, 173, 0, 86)}):Play()
					TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(1, -20, 0, 104)}):Play()
					TweenService:Create(Display, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
					if displayStroke then
						TweenService:Create(displayStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
					end
					ColorPicker.Interact.AnchorPoint = Vector2.new(0, 0)
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -200, 0, 38)}):Play()
					TweenService:Create(ColorPicker.RGB, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 42)}):Play()
					TweenService:Create(ColorPicker.HexInput, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 78)}):Play()
					TweenService:Create(Main.MainPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
					if Slider:FindFirstChild("SliderPoint") then
						TweenService:Create(Slider.SliderPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
					end
					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
				else
					opened = false
					Main.Visible = false
					satGradFrame.Visible = false
					valGradFrame.Visible = false
					Main.MainPoint.Visible = false
					Slider.Visible = false
					ColorPicker.RGB.Visible = false
					ColorPicker.HexInput.Visible = false
					Background.ClipsDescendants = true
					Display.BackgroundTransparency = 0
					if displayStroke then
						displayStroke.Transparency = 0
					end
					TweenService:Create(ColorPicker, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
					Background.AnchorPoint = Vector2.new(1, 0.5)
					TweenService:Create(Background, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.new(0, 39, 0, 22)}):Play()
					ColorPicker.Interact.AnchorPoint = Vector2.new(0.5, 0.5)
					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					ColorPicker.RGB.Position = UDim2.new(0, 17, 0, 70)
					ColorPicker.HexInput.Position = UDim2.new(0, 17, 0, 90)
					Slider.Position = UDim2.new(1, -20, 0, 104)
				end
			end)

			local h,s,v = ColorPickerSettings.Color:ToHSV()
			local color = Color3.fromHSV(h,s,v)
			local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
			ColorPicker.HexInput.InputBox.Text = hex

			local function setDisplay()
				local hueBaseColor = Color3.fromHSV(h, 1, 1)
				Main.BackgroundColor3 = hueBaseColor

				local curCol = Color3.fromHSV(h, s, v)
				Background.BackgroundColor3 = curCol
				Display.BackgroundColor3 = curCol

				Main.MainPoint.Position = UDim2.new(s, 0, 1 - v, 0)
				Main.MainPoint.ImageColor3 = curCol

				Slider.SliderPoint.Position = UDim2.new(h, 0, 0.5, 0)
				Slider.SliderPoint.ImageColor3 = hueBaseColor

				local r,g,b = math.floor((curCol.R*255)+0.5),math.floor((curCol.G*255)+0.5),math.floor((curCol.B*255)+0.5)
				ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
				ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
				ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
				hex = string.format("#%02X%02X%02X",curCol.R*0xFF,curCol.G*0xFF,curCol.B*0xFF)
				ColorPicker.HexInput.InputBox.Text = hex
			end
			setDisplay()

			local function updateMain(inputX, inputY)
				local mainW = math.max(1, Main.AbsoluteSize.X)
				local mainH = math.max(1, Main.AbsoluteSize.Y)
				local localX = math.clamp(inputX - Main.AbsolutePosition.X, 0, mainW)
				local localY = math.clamp(inputY - Main.AbsolutePosition.Y, 0, mainH)
				s = localX / mainW
				v = 1 - (localY / mainH)
				setDisplay()
				local curCol = Color3.fromHSV(h, s, v)
				ColorPickerSettings.Color = curCol
				pcall(function() ColorPickerSettings.Callback(curCol) end)
				if not ColorPickerSettings.Ext then
					SaveConfiguration()
				end
			end

			local function updateSlider(inputX)
				local sliderW = math.max(1, Slider.AbsoluteSize.X)
				local localX = math.clamp(inputX - Slider.AbsolutePosition.X, 0, sliderW)
				h = localX / sliderW
				setDisplay()
				local curCol = Color3.fromHSV(h, s, v)
				ColorPickerSettings.Color = curCol
				pcall(function() ColorPickerSettings.Callback(curCol) end)
				if not ColorPickerSettings.Ext then
					SaveConfiguration()
				end
			end

			local colorPickerInputConnection = UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					mainDragging = false
					sliderDragging = false
				end
			end)

			Main.InputBegan:Connect(function(input)
				if not opened then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					mainDragging = true
					updateMain(input.Position.X, input.Position.Y)
				end
			end)

			Main.MainPoint.InputBegan:Connect(function(input)
				if not opened then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					mainDragging = true
					updateMain(input.Position.X, input.Position.Y)
				end
			end)

			Slider.InputBegan:Connect(function(input)
				if not opened then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliderDragging = true
					updateSlider(input.Position.X)
				end
			end)

			if Slider:FindFirstChild("SliderPoint") then
				Slider.SliderPoint.InputBegan:Connect(function(input)
					if not opened then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliderDragging = true
						updateSlider(input.Position.X)
				end
				end)
			end

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
				local pickedColor = Color3.fromHSV(h,s,v)
				ColorPickerSettings.Color = pickedColor
				pcall(function()ColorPickerSettings.Callback(pickedColor)end)
				if not ColorPickerSettings.Ext then
					SaveConfiguration()
				end
			end)

			local function rgbBoxes(box,toChange)
				local value = tonumber(box.Text)
				local curCol = Color3.fromHSV(h,s,v)
				local oldR,oldG,oldB = math.floor((curCol.R*255)+0.5),math.floor((curCol.G*255)+0.5),math.floor((curCol.B*255)+0.5)
				local save
				if toChange == "R" then save = oldR;oldR = value elseif toChange == "G" then save = oldG;oldG = value else save = oldB;oldB = value end
				if value then
					value = math.clamp(value,0,255)
					h,s,v = Color3.fromRGB(oldR,oldG,oldB):ToHSV()
					setDisplay()
				else
					box.Text = tostring(save)
				end
				local pickedColor = Color3.fromHSV(h,s,v)
				ColorPickerSettings.Color = pickedColor
				if not ColorPickerSettings.Ext then
					SaveConfiguration()
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
					updateMain(mouse.X, mouse.Y)
				end
				if sliderDragging then
					updateSlider(mouse.X)
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
				if displayStroke then
					displayStroke.Color = SelectedTheme.ElementStroke or Color3.fromRGB(80, 80, 80)
				end
			end)

			return ColorPickerSettings
		end

		function Tab:CreateSection(SectionName)

			local SectionValue = {}

			if SDone then
				local SectionSpace = Elements.Template.SectionSpacing:Clone()
				SectionSpace.Size = UDim2.new(1, 0, 0, 8)
				SectionSpace.Visible = true
				SectionSpace.Parent = TabPage
			end

			local Section = Elements.Template.SectionTitle:Clone()
			Section.Size = UDim2.new(1, -10, 0, 24)
			Section.ClipsDescendants = false
			if Section:FindFirstChild("Title") then
				Section.Title.Size = UDim2.new(1, -15, 1, 0)
				Section.Title.Position = UDim2.new(0, 15, 0, 0)
				Section.Title.Text = SectionName
				Section.Title.TextScaled = false
				Section.Title.TextSize = 14
				Section.Title.TextXAlignment = Enum.TextXAlignment.Left
				Section.Title.TextYAlignment = Enum.TextYAlignment.Center
				Section.Title.ClipsDescendants = false
				Section.Title.TextTransparency = 1
				TweenService:Create(Section.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()
			end
			Section.Visible = true
			Section.Parent = TabPage

			function SectionValue:Set(NewSection)
				if Section:FindFirstChild("Title") then
					Section.Title.Text = NewSection
				end
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
			Paragraph.Name = ParagraphSettings.Title or "Paragraph"
			Paragraph.Title.Text = ParagraphSettings.Title or ""
			Paragraph.Content.Text = ParagraphSettings.Content or ""
			Paragraph.Visible = true
			Paragraph.Parent = TabPage

			Paragraph.BackgroundTransparency = 1
			Paragraph.UIStroke.Transparency = 1
			Paragraph.Title.TextTransparency = 1
			Paragraph.Content.TextTransparency = 1

			Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
			Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke
			Paragraph.Title.TextColor3 = SelectedTheme.TextColor
			Paragraph.Content.TextColor3 = SelectedTheme.TextColor

			Paragraph.AutomaticSize = Enum.AutomaticSize.Y
			Paragraph.Size = UDim2.new(1, -10, 0, 0)
			Paragraph.Title.AutomaticSize = Enum.AutomaticSize.Y
			Paragraph.Title.Size = UDim2.new(1, -24, 0, 0)
			Paragraph.Title.TextWrapped = true
			Paragraph.Content.AutomaticSize = Enum.AutomaticSize.Y
			Paragraph.Content.Size = UDim2.new(1, -24, 0, 0)
			Paragraph.Content.TextWrapped = true

			TweenService:Create(Paragraph, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
			TweenService:Create(Paragraph.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
			TweenService:Create(Paragraph.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
			TweenService:Create(Paragraph.Content, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

			function ParagraphValue:Set(NewParagraphSettings)
				if NewParagraphSettings.Title then
					Paragraph.Title.Text = NewParagraphSettings.Title
				end
				if NewParagraphSettings.Content then
					Paragraph.Content.Text = NewParagraphSettings.Content
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
				Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke
				Paragraph.Title.TextColor3 = SelectedTheme.TextColor
				Paragraph.Content.TextColor3 = SelectedTheme.TextColor
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
				local Success = pcall(function()
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

				pcall(function()
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
			local listLayout = Dropdown.List:FindFirstChildOfClass("UIListLayout")
			if listLayout then
				listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					Dropdown.List.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
				end)
				Dropdown.List.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
			end

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
						DropdownOption.Title:SetAttribute("KeepFont", true)
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

						local Success = pcall(function()
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

				local Success = pcall(function()
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

			function DropdownSettings:Refresh(optionsTable: { any })
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
						local Success = pcall(KeybindSettings.Callback)
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
			local Toggle = Elements.Template.Toggle:Clone()
			Toggle.Name = ToggleSettings.Name
			Toggle.Title.Text = ToggleSettings.Name
			Toggle.Visible = true
			Toggle.Parent = TabPage

			Toggle.BackgroundColor3 = SelectedTheme.ElementBackground
			Toggle.UIStroke.Color = SelectedTheme.ElementStroke
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

				local Success = pcall(function()
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

				local Success = pcall(function()
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
					if SLDragging and not SliderSettings.Ext then SaveConfiguration() end
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
							local Success = pcall(function()
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
						end
					else
						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X > 5 and Location - Slider.Main.AbsolutePosition.X or 5, 1, 0)}):Play()
						Loop:Disconnect()
					end
				end)
			end)

			function SliderSettings:Set(NewVal)
				NewVal = math.clamp(NewVal, SliderSettings.Range[1], SliderSettings.Range[2])

				TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Slider.Main.AbsoluteSize.X * ((NewVal - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * ((NewVal - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)}):Play()
				Slider.Main.Information.Text = tostring(NewVal) .. " " .. (SliderSettings.Suffix or "")

				local Success = pcall(function()
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

			local isTabSelected = (currentActiveTabName and TabButton.Name == currentActiveTabName) or (Elements.UIPageLayout and Elements.UIPageLayout.CurrentPage and Elements.UIPageLayout.CurrentPage.Name == TabButton.Name)
			if isTabSelected then
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
	TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = useMobileSizing and UDim2.new(0, currentSavedWidth, 0, 275) or UDim2.new(0, currentSavedWidth, 0, currentSavedHeight)}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, currentSavedWidth, 0, 45)}):Play()
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
		pcall(ChangeTheme, NewTheme)
	end

	pcall(function()
		createSettings(Window, Settings)
	end)

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

function RayfieldLibrary:ChangeSize(width, height, smooth)
	if smooth == nil then smooth = true end
	applySize(width or currentSavedWidth, height or currentSavedHeight, smooth)
	if globalWidthSlider and globalWidthSlider.Set and width then
		pcall(function() globalWidthSlider:Set(width) end)
	end
	if globalHeightSlider and globalHeightSlider.Set and height then
		pcall(function() globalHeightSlider:Set(height) end)
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
		pcall(function() connection:Disconnect() end)
	end
	for _, connection in ipairs(allLibraryConnections) do
		pcall(function() connection:Disconnect() end)
	end
	if Rayfield then Rayfield:Destroy() end
end

local changeSizeDebounce = false
local function toggleMinimise()
	if Debounce or changeSizeDebounce then return end
	changeSizeDebounce = true
	task.delay(0.2, function() changeSizeDebounce = false end)
	if Minimised then
		Minimised = false
		Maximise()
	else
		Minimised = true
		Minimise()
	end
end
Topbar.ChangeSize.MouseButton1Click:Connect(toggleMinimise)
Topbar.ChangeSize.Activated:Connect(toggleMinimise)

Main.Search.Input:GetPropertyChangedSignal('Text'):Connect(function()
	if #Main.Search.Input.Text > 0 then
		if not Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks') then
			local searchTitle = Elements.Template.SectionTitle:Clone()
			searchTitle.Size = UDim2.new(1, -10, 0, 24)
			searchTitle.ClipsDescendants = false
			if searchTitle:FindFirstChild("Title") then
				searchTitle.Title.Size = UDim2.new(1, -15, 1, 0)
				searchTitle.Title.Position = UDim2.new(0, 15, 0, 0)
				searchTitle.Title.TextScaled = false
				searchTitle.Title.TextSize = 14
				searchTitle.Title.Text = "Results from '"..Elements.UIPageLayout.CurrentPage.Name.."'"
				searchTitle.Title.TextXAlignment = Enum.TextXAlignment.Left
				searchTitle.Title.TextYAlignment = Enum.TextYAlignment.Center
				searchTitle.Title.ClipsDescendants = false
			end
			searchTitle.Parent = Elements.UIPageLayout.CurrentPage
			searchTitle.Name = 'SearchTitle-fsefsefesfsefesfesfThanks'
			searchTitle.LayoutOrder = -100
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

local searchBtnDebounce = false
local function toggleSearch()
	if searchBtnDebounce then return end
	searchBtnDebounce = true
	task.delay(0.2, function() searchBtnDebounce = false end)
	task.spawn(function()
		if searchOpen then
			closeSearch()
		else
			openSearch()
		end
	end)
end
Topbar.Search.MouseButton1Click:Connect(toggleSearch)
Topbar.Search.Activated:Connect(toggleSearch)

if Topbar:FindFirstChild('Settings') then
	local previousActiveTab = nil
	local settingsBtnDebounce = false
	local function toggleSettings()
		if settingsBtnDebounce then return end
		settingsBtnDebounce = true
		task.delay(0.2, function() settingsBtnDebounce = false end)
		task.spawn(function()
			local settingsPage = Elements:FindFirstChild('Settings') or Elements['Rayfield Settings']
			if settingsPage and Elements.UIPageLayout.CurrentPage == settingsPage then
				if previousActiveTab and previousActiveTab.Parent == Elements then
					currentActiveTabName = previousActiveTab.Name
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
	end
	Topbar.Settings.MouseButton1Click:Connect(toggleSettings)
	Topbar.Settings.Activated:Connect(toggleSettings)

end

	local folderAsset = customAssets["folder"] or ""
	local fileAsset = customAssets["file"] or ""
	local runAsset = customAssets["run"] or ""
	local copyAsset = customAssets["copy"] or ""
	local mobileAsset = customAssets["mobile"] or ""
	pcall(function()
		if type(getcustomasset) == "function" then
			if folderAsset == "" then
				if isfile and isfile("Rayfield_Assets/19.png") then
					folderAsset = getcustomasset("Rayfield_Assets/19.png")
				elseif isfile and isfile("19.png") then
					folderAsset = getcustomasset("19.png")
				elseif customAssets["19"] and customAssets["19"] ~= "" then
					folderAsset = customAssets["19"]
				end
			end
			if fileAsset == "" then
				if isfile and isfile("Rayfield_Assets/20.png") then
					fileAsset = getcustomasset("Rayfield_Assets/20.png")
				elseif isfile and isfile("20.png") then
					fileAsset = getcustomasset("20.png")
				elseif customAssets["20"] and customAssets["20"] ~= "" then
					fileAsset = customAssets["20"]
				end
			end
			if runAsset == "" then
				if isfile and isfile("Rayfield_Assets/21.png") then
					runAsset = getcustomasset("Rayfield_Assets/21.png")
				elseif isfile and isfile("21.png") then
					runAsset = getcustomasset("21.png")
				elseif customAssets["21"] and customAssets["21"] ~= "" then
					runAsset = customAssets["21"]
				end
			end
			if copyAsset == "" then
				if isfile and isfile("Rayfield_Assets/22.png") then
					copyAsset = getcustomasset("Rayfield_Assets/22.png")
				elseif isfile and isfile("22.png") then
					copyAsset = getcustomasset("22.png")
				elseif customAssets["22"] and customAssets["22"] ~= "" then
					copyAsset = customAssets["22"]
				end
			end
			if mobileAsset == "" then
				if isfile and isfile("Rayfield_Assets/23.png") then
					mobileAsset = getcustomasset("Rayfield_Assets/23.png")
				elseif isfile and isfile("23.png") then
					mobileAsset = getcustomasset("23.png")
				elseif customAssets["23"] and customAssets["23"] ~= "" then
					mobileAsset = customAssets["23"]
				end
			end
		end
	end)

	local mobileToggle = Rayfield:FindFirstChild("RayfieldMobileToggle")
	if not mobileToggle then
		mobileToggle = Instance.new("ImageButton")
		mobileToggle.Name = "RayfieldMobileToggle"
		mobileToggle.Size = UDim2.new(0, 50, 0, 50)
		mobileToggle.Position = UDim2.new(0, 16, 0.5, -25)
		mobileToggle.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
		mobileToggle.BackgroundTransparency = 0.15
		mobileToggle.AutoButtonColor = false
		mobileToggle.ZIndex = 150
		mobileToggle.Active = true
		mobileToggle.Parent = Rayfield

		local mtCorner = Instance.new("UICorner", mobileToggle)
		mtCorner.CornerRadius = UDim.new(0, 25)

		local mtStroke = Instance.new("UIStroke", mobileToggle)
		mtStroke.Color = SelectedTheme.ElementStroke
		mtStroke.Thickness = 1.2
		mtStroke.Transparency = 0.2

		local mtScale = Instance.new("UIScale", mobileToggle)
		mtScale.Scale = 1

		local finalMobileAsset = ""
		if type(getcustomasset) == "function" then
			if isfile and isfile("Rayfield_Assets/23.png") then
				finalMobileAsset = getcustomasset("Rayfield_Assets/23.png")
			elseif isfile and isfile("23.png") then
				finalMobileAsset = getcustomasset("23.png")
			elseif customAssets["23"] and customAssets["23"] ~= "" then
				finalMobileAsset = customAssets["23"]
			elseif mobileAsset ~= "" then
				finalMobileAsset = mobileAsset
			end
		end

		local mtIcon = Instance.new("ImageLabel", mobileToggle)
		mtIcon.Name = "Icon"
		mtIcon.Size = UDim2.new(0, 38, 0, 38)
		mtIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		mtIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		mtIcon.BackgroundTransparency = 1
		mtIcon.ScaleType = Enum.ScaleType.Fit
		mtIcon.Image = finalMobileAsset
		local themeAccent = SelectedTheme.Accent or SelectedTheme.ToggleEnabled or SelectedTheme.SliderProgress or SelectedTheme.TextColor or Color3.fromRGB(255, 255, 255)
		mtIcon.ImageColor3 = themeAccent
		mtIcon.ImageTransparency = 0
		mtIcon.ZIndex = 151
		task.spawn(function()
			pcall(function()
				(game:GetService("ContentProvider") :: any):PreloadAsync({mtIcon})
			end)
		end)

		local isDragging = false
		local dragStart = nil
		local startPos = nil
		local hasMoved = false

		mobileToggle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				hasMoved = false
				dragStart = input.Position
				startPos = mobileToggle.Position

				TweenService:Create(mtScale, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 0.9}):Play()
				TweenService:Create(mobileToggle, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.05}):Play()
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				isDragging = false
				TweenService:Create(mtScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
				TweenService:Create(mobileToggle, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.15}):Play()
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				if dragStart and startPos then
					local delta = input.Position - dragStart
					if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
						hasMoved = true
					end
					mobileToggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				end
			end
		end)

		mobileToggle.Activated:Connect(function()
			if hasMoved then return end
			local bounce = TweenService:Create(mtScale, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 0.8})
			bounce:Play()
			bounce.Completed:Connect(function()
				TweenService:Create(mtScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
			end)

			if Debounce then return end
			if Hidden then
				Hidden = false
				Unhide()
			else
				Hidden = true
				Hide(false)
			end
		end)

		mobileToggle.MouseEnter:Connect(function()
			local currentAccent = SelectedTheme.Accent or SelectedTheme.ToggleEnabled or SelectedTheme.SliderProgress or SelectedTheme.TextColor or Color3.fromRGB(255, 255, 255)
			TweenService:Create(mobileToggle, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.05}):Play()
			TweenService:Create(mtStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Color = currentAccent, Transparency = 0}):Play()
		end)
		mobileToggle.MouseLeave:Connect(function()
			if not isDragging then
				TweenService:Create(mobileToggle, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.15}):Play()
				TweenService:Create(mtStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Color = SelectedTheme.ElementStroke, Transparency = 0.2}):Play()
			end
		end)

		local curSettings = currentWindowSettings
		local isMobile = (UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)) or (useMobileSizing and UserInputService.TouchEnabled)
		if curSettings and curSettings.MobileToggle ~= nil then
			isMobile = curSettings.MobileToggle
		end

		mobileToggle.Visible = isMobile
	end

	if mobileToggle then
		local curSettings = currentWindowSettings
		local isMobile = (UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)) or (useMobileSizing and UserInputService.TouchEnabled)
		if curSettings and curSettings.MobileToggle ~= nil then
			isMobile = curSettings.MobileToggle
		end
		mobileToggle.Visible = isMobile

		local ltypeConn = UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
			local s = currentWindowSettings
			if lastInputType == Enum.UserInputType.Touch and (s == nil or s.MobileToggle == nil or s.MobileToggle == true) then
				mobileToggle.Visible = true
			end
		end)
		table.insert(allLibraryConnections, ltypeConn)
	end

	local curSettings = currentWindowSettings
	local isPhoneOrMobile = (UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)) or (useMobileSizing and UserInputService.TouchEnabled) or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
	if curSettings and (curSettings.DisableWorkspace == true or curSettings.IsMobile == true or curSettings.Mobile == true) then
		isPhoneOrMobile = true
	end

	if isPhoneOrMobile then
		local existingFiles = Topbar:FindFirstChild("Files")
		if existingFiles then
			existingFiles:Destroy()
		end
		Topbar.Search.Position = UDim2.new(1, -105, 0.5, 0)
	else
	local filesBtn = Topbar:FindFirstChild("Files")
	if not filesBtn then
	    filesBtn = Topbar.Settings:Clone()
	    filesBtn.Name = "Files"
	    filesBtn.Parent = Topbar
	end
	filesBtn.Position = UDim2.new(1, -105, 0.5, 0)
	filesBtn.Size = UDim2.new(0, 24, 0, 24)
	filesBtn.AnchorPoint = Vector2.new(1, 0.5)
	if folderAsset ~= "" then
	    filesBtn.Image = folderAsset
	end
	filesBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
	filesBtn.ImageTransparency = 0.8
	filesBtn.Visible = true
	filesBtn.ZIndex = 10
	filesBtn.Active = true

	filesBtn.MouseEnter:Connect(function()
		TweenService:Create(filesBtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.4}):Play()
	end)
	filesBtn.MouseLeave:Connect(function()
		TweenService:Create(filesBtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
	end)

	Topbar.Search.Position = UDim2.new(1, -135, 0.5, 0)

	local function getUIFont()
		return (SelectedTheme and SelectedTheme.Font) or currentUIFont or Enum.Font.Gotham
	end

	local refreshList

	local workspacePage = Instance.new("Frame")
	workspacePage.Name = "Workspace"
	workspacePage.Size = UDim2.new(1, -20, 1, -10)
	workspacePage.Position = UDim2.new(0.5, 0, 0.5, 0)
	workspacePage.AnchorPoint = Vector2.new(0.5, 0.5)
	workspacePage.BackgroundTransparency = 1
	workspacePage.BorderSizePixel = 0
	workspacePage.ClipsDescendants = true
	workspacePage.Visible = true
	workspacePage.Parent = Elements

	local searchContainer = Instance.new("Frame")
	searchContainer.Name = "SearchContainer"
	searchContainer.Size = UDim2.new(1, -10, 0, 36)
	searchContainer.Position = UDim2.new(0.5, 0, 0, 8)
	searchContainer.AnchorPoint = Vector2.new(0.5, 0)
	searchContainer.BackgroundColor3 = SelectedTheme.ElementBackground
	searchContainer.BorderSizePixel = 0
	searchContainer.Parent = workspacePage
	local scCorner = Instance.new("UICorner", searchContainer); scCorner.CornerRadius = UDim.new(0, 6)
	local scStroke = Instance.new("UIStroke", searchContainer); scStroke.Color = SelectedTheme.ElementStroke; scStroke.Thickness = 1

	local searchInput = Instance.new("TextBox")
	searchInput.Name = "Input"
	searchInput.Size = UDim2.new(1, -24, 1, 0)
	searchInput.Position = UDim2.new(0, 14, 0, 0)
	searchInput.BackgroundTransparency = 1
	searchInput.PlaceholderText = "Search files..."
	searchInput.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
	searchInput.Text = ""
	searchInput.Font = getUIFont()
	searchInput.TextSize = 13
	searchInput.TextColor3 = SelectedTheme.TextColor
	searchInput.TextXAlignment = Enum.TextXAlignment.Left
	searchInput.ClearTextOnFocus = false
	searchInput.Parent = searchContainer

	local backBar = Instance.new("Frame")
	backBar.Name = "BackBar"
	backBar.Size = UDim2.new(1, -10, 0, 28)
	backBar.Position = UDim2.new(0.5, 0, 0, 48)
	backBar.AnchorPoint = Vector2.new(0.5, 0)
	backBar.BackgroundTransparency = 1
	backBar.Visible = false
	backBar.Parent = workspacePage

	local backBtn = Instance.new("TextButton")
	backBtn.Name = "BackBtn"
	backBtn.Size = UDim2.new(0, 76, 0, 28)
	backBtn.Position = UDim2.new(0, 0, 0, 0)
	backBtn.BackgroundColor3 = SelectedTheme.ElementBackground
	backBtn.Text = ""
	backBtn.AutoButtonColor = true
	backBtn.Parent = backBar
	local bbCorner = Instance.new("UICorner", backBtn); bbCorner.CornerRadius = UDim.new(0, 6)
	local bbStroke = Instance.new("UIStroke", backBtn); bbStroke.Color = SelectedTheme.ElementStroke; bbStroke.Thickness = 1; bbStroke.Transparency = 0

	local bbIcon = Instance.new("ImageLabel", backBtn)
	bbIcon.Name = "Icon"
	bbIcon.Size = UDim2.new(0, 14, 0, 14)
	bbIcon.Position = UDim2.new(0, 8, 0.5, 0)
	bbIcon.AnchorPoint = Vector2.new(0, 0.5)
	bbIcon.BackgroundTransparency = 1
	bbIcon.Image = (customAssets["9"] and customAssets["9"] ~= "") and customAssets["9"] or "rbxassetid://6031090990"
	bbIcon.Rotation = 270
	bbIcon.ImageColor3 = SelectedTheme.TextColor
	bbIcon.ImageTransparency = 0.15
	bbIcon.Active = false

	local bbLbl = Instance.new("TextLabel", backBtn)
	bbLbl.Name = "Label"
	bbLbl.Size = UDim2.new(1, -26, 1, 0)
	bbLbl.Position = UDim2.new(0, 24, 0, 0)
	bbLbl.BackgroundTransparency = 1
	bbLbl.Text = "Back"
	bbLbl.Font = getUIFont()
	bbLbl.TextSize = 12
	bbLbl.TextColor3 = SelectedTheme.TextColor
	bbLbl.TextXAlignment = Enum.TextXAlignment.Left
	bbLbl.Active = false

	local function setBackHover(hovered)
		if hovered then
			TweenService:Create(backBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {BackgroundColor3 = SelectedTheme.ElementStroke}):Play()
			TweenService:Create(bbStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Color = SelectedTheme.TextColor, Transparency = 0}):Play()
			TweenService:Create(bbIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {ImageTransparency = 0, ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			TweenService:Create(bbLbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		else
			TweenService:Create(backBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
			TweenService:Create(bbStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Color = SelectedTheme.ElementStroke, Transparency = 0}):Play()
			TweenService:Create(bbIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {ImageTransparency = 0.15, ImageColor3 = SelectedTheme.TextColor}):Play()
			TweenService:Create(bbLbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {TextColor3 = SelectedTheme.TextColor}):Play()
		end
	end

	backBtn.MouseEnter:Connect(function() setBackHover(true) end)
	backBtn.MouseLeave:Connect(function() setBackHover(false) end)
	backBtn.SelectionGained:Connect(function() setBackHover(true) end)
	backBtn.SelectionLost:Connect(function() setBackHover(false) end)

	local curDirLabel = Instance.new("TextLabel")
	curDirLabel.Name = "CurDir"
	curDirLabel.Text = ""
	curDirLabel.Font = getUIFont()
	curDirLabel.TextSize = 12
	curDirLabel.TextColor3 = SelectedTheme.TextColor
	curDirLabel.TextTransparency = 0.15
	curDirLabel.TextXAlignment = Enum.TextXAlignment.Left
	curDirLabel.TextTruncate = Enum.TextTruncate.AtEnd
	curDirLabel.Position = UDim2.new(0, 84, 0, 0)
	curDirLabel.Size = UDim2.new(1, -84, 0, 28)
	curDirLabel.BackgroundColor3 = SelectedTheme.ElementBackground
	curDirLabel.BackgroundTransparency = 0.2
	curDirLabel.Parent = backBar
	local cdCorner = Instance.new("UICorner", curDirLabel); cdCorner.CornerRadius = UDim.new(0, 6)
	local cdStroke = Instance.new("UIStroke", curDirLabel); cdStroke.Color = SelectedTheme.ElementStroke; cdStroke.Thickness = 1; cdStroke.Transparency = 0.2
	local cdPadding = Instance.new("UIPadding", curDirLabel); cdPadding.PaddingLeft = UDim.new(0, 10); cdPadding.PaddingRight = UDim.new(0, 10)

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "FileList"
	listFrame.Size = UDim2.new(1, -10, 1, -54)
	listFrame.Position = UDim2.new(0.5, 0, 0, 50)
	listFrame.AnchorPoint = Vector2.new(0.5, 0)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = SelectedTheme.ElementStroke
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent = workspacePage

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	local currentPath = ""
	local selectedItem = nil

	local function formatSize(bytes)
	    if not bytes or bytes <= 0 then return "-" end
	    if bytes < 1024 then
	        return bytes .. " B"
	    elseif bytes < 1048576 then
	        return string.format("%.1f KB", bytes / 1024)
	    else
	        return string.format("%.1f MB", bytes / 1048576)
	    end
	end

	local function getExtension(name)
	    local ext = string.match(name, "%.([^%.]+)$")
	    return ext and string.upper(ext) or ""
	end

	local function cleanFileName(fullPath)
	    local name = string.gsub(fullPath, "\\", "/")
	    return string.match(name, "([^/]+)$") or fullPath
	end

	local contextOverlay = Instance.new("TextButton")
	contextOverlay.Name = "ContextOverlay"
	contextOverlay.Size = UDim2.new(1, 0, 1, 0)
	contextOverlay.Position = UDim2.new(0, 0, 0, 0)
	contextOverlay.BackgroundTransparency = 1
	contextOverlay.Text = ""
	contextOverlay.Visible = false
	contextOverlay.ZIndex = 80
	contextOverlay.Parent = Main

	local contextMenu = Instance.new("Frame")
	contextMenu.Name = "FileContextMenu"
	contextMenu.Size = UDim2.new(0, 168, 0, 100)
	contextMenu.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
	contextMenu.BackgroundTransparency = 1
	contextMenu.BorderSizePixel = 0
	contextMenu.ClipsDescendants = false
	contextMenu.Visible = false
	contextMenu.ZIndex = 90
	contextMenu.Parent = Main

	local cmScale = Instance.new("UIScale", contextMenu)
	cmScale.Scale = 1

	local cmCorner = Instance.new("UICorner", contextMenu)
	cmCorner.CornerRadius = UDim.new(0, 8)

	local cmStroke = Instance.new("UIStroke", contextMenu)
	cmStroke.Color = SelectedTheme.ElementStroke
	cmStroke.Thickness = 1
	cmStroke.Transparency = 1

	local cmLayout = Instance.new("UIListLayout", contextMenu)
	cmLayout.Padding = UDim.new(0, 3)
	cmLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local cmPadding = Instance.new("UIPadding", contextMenu)
	cmPadding.PaddingTop = UDim.new(0, 5)
	cmPadding.PaddingBottom = UDim.new(0, 5)
	cmPadding.PaddingLeft = UDim.new(0, 5)
	cmPadding.PaddingRight = UDim.new(0, 5)

	local function closeContextMenu()
		if not contextMenu.Visible then return end
		contextOverlay.Visible = false
		local tw = TweenService:Create(contextMenu, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		})
		local twScale = TweenService:Create(cmScale, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Scale = 0.88
		})
		local twStroke = TweenService:Create(cmStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Transparency = 1
		})
		tw:Play()
		twScale:Play()
		twStroke:Play()
		for _, child in ipairs(contextMenu:GetChildren()) do
			if child:IsA("TextButton") then
				local icon = child:FindFirstChildOfClass("ImageLabel")
				local lbl = child:FindFirstChildOfClass("TextLabel")
				local st = child:FindFirstChildOfClass("UIStroke")
				if icon then TweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {ImageTransparency = 1}):Play() end
				if lbl then TweenService:Create(lbl, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {TextTransparency = 1}):Play() end
				if st then TweenService:Create(st, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Transparency = 1}):Play() end
			end
		end
		tw.Completed:Connect(function()
			if not contextOverlay.Visible then
				contextMenu.Visible = false
				cmScale.Scale = 1
				for _, child in ipairs(contextMenu:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
			end
		end)
	end

	contextOverlay.MouseButton1Click:Connect(closeContextMenu)
	contextOverlay.MouseButton2Click:Connect(closeContextMenu)

	local function openContextMenu(item, triggerBtn)
		for _, child in ipairs(contextMenu:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		local options = {}

		if item.IsFolder then
			table.insert(options, {
				Name = "Open Folder",
				Icon = (folderAsset and folderAsset ~= "") and folderAsset or "rbxassetid://6034287525",
				Color = Color3.fromRGB(255, 255, 255),
				Callback = function()
					local targetPath = string.gsub(item.Path or item.Name, "\\", "/")
					targetPath = string.gsub(targetPath, "^[./\\]+", "")
					currentPath = targetPath
					refreshList()
				end
			})
			local function safeSetClipboard(text)
				pcall(function()
					local cb = setclipboard or toclipboard
					if type(cb) == "function" then
						cb(text)
					end
				end)
			end

			table.insert(options, {
				Name = "Copy Path",
				Icon = copyAsset ~= "" and copyAsset or "rbxassetid://6034287527",
				Color = Color3.fromRGB(255, 255, 255),
				Callback = function()
					safeSetClipboard(item.Path)
					RayfieldLibrary:Notify({Title = "Copied", Content = "Folder path copied to clipboard", Duration = 2})
				end
			})
			table.insert(options, {
				Name = "Copy Name",
				Icon = copyAsset ~= "" and copyAsset or "rbxassetid://6034287525",
				Color = Color3.fromRGB(255, 255, 255),
				Callback = function()
					safeSetClipboard(item.Name)
					RayfieldLibrary:Notify({Title = "Copied", Content = "Folder name copied to clipboard", Duration = 2})
				end
			})
		else
			if item.Ext == "LUA" or item.Ext == "LUAU" or item.Ext == "TXT" then
				table.insert(options, {
					Name = "Run Script",
					Icon = runAsset ~= "" and runAsset or "rbxassetid://6034287517",
					Color = Color3.fromRGB(255, 255, 255),
					Callback = function()
						pcall(function()
							local src = readfile(item.Path)
							loadstring(src)()
							RayfieldLibrary:Notify({Title = "Executed", Content = "Running " .. item.Name, Duration = 2})
						end)
					end
				})
			end

			table.insert(options, {
				Name = "Copy File",
				Icon = copyAsset ~= "" and copyAsset or (fileAsset ~= "" and fileAsset or "rbxassetid://6034287525"),
				Color = Color3.fromRGB(255, 255, 255),
				Callback = function()
					pcall(function()
						local cb = setclipboard or toclipboard
						if type(cb) == "function" and type(readfile) == "function" then
							cb(readfile(item.Path))
							RayfieldLibrary:Notify({Title = "Copied", Content = "File content copied to clipboard", Duration = 2})
						end
					end)
				end
			})

			table.insert(options, {
				Name = "Copy Path",
				Icon = copyAsset ~= "" and copyAsset or "rbxassetid://6034287527",
				Color = Color3.fromRGB(255, 255, 255),
				Callback = function()
					pcall(function()
						local cb = setclipboard or toclipboard
						if type(cb) == "function" then
							cb(item.Path)
							RayfieldLibrary:Notify({Title = "Copied", Content = "Path copied to clipboard", Duration = 2})
						end
					end)
				end
			})

			table.insert(options, {
				Name = "Copy Name",
				Icon = copyAsset ~= "" and copyAsset or "rbxassetid://6034287525",
				Color = Color3.fromRGB(255, 255, 255),
				Callback = function()
					pcall(function()
						local cb = setclipboard or toclipboard
						if type(cb) == "function" then
							cb(item.Name)
							RayfieldLibrary:Notify({Title = "Copied", Content = "File name copied to clipboard", Duration = 2})
						end
					end)
				end
			})
		end

		local itemH = 28
		local totalHeight = #options * itemH + (#options - 1) * 3 + 12
		local menuWidth = 168

		for idx, opt in ipairs(options) do
			local btn = Instance.new("TextButton")
			btn.Name = opt.Name
			btn.Size = UDim2.new(1, 0, 0, itemH)
			btn.BackgroundColor3 = SelectedTheme.ElementStroke
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.AutoButtonColor = true
			btn.ZIndex = 95
			btn.Parent = contextMenu

			local bCorner = Instance.new("UICorner", btn)
			bCorner.CornerRadius = UDim.new(0, 6)

			local bStroke = Instance.new("UIStroke", btn)
			bStroke.Color = SelectedTheme.TextColor
			bStroke.Thickness = 1
			bStroke.Transparency = 1

			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.new(0, 16, 0, 16)
			icon.Position = UDim2.new(0, 10, 0.5, 0)
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.BackgroundTransparency = 1
			icon.Image = opt.Icon
			icon.ImageColor3 = SelectedTheme.TextColor
			icon.ImageTransparency = 0.15
			icon.ZIndex = 96
			icon.Active = false
			icon.Parent = btn

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -34, 1, 0)
			lbl.Position = UDim2.new(0, 34, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = opt.Name
			lbl.Font = getUIFont()
			lbl.TextSize = 12
			lbl.TextColor3 = SelectedTheme.TextColor
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.ZIndex = 96
			lbl.Active = false
			lbl.Parent = btn

			local function setHover(hovered)
				if hovered then
					TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0,
						BackgroundColor3 = SelectedTheme.ElementStroke
					}):Play()
					TweenService:Create(bStroke, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Transparency = 0.3,
						Color = SelectedTheme.TextColor
					}):Play()
					TweenService:Create(icon, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						ImageTransparency = 0,
						ImageColor3 = SelectedTheme.SelectedTabTextColor or Color3.fromRGB(255, 255, 255)
					}):Play()
					TweenService:Create(lbl, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						TextColor3 = SelectedTheme.SelectedTabTextColor or Color3.fromRGB(255, 255, 255)
					}):Play()
				else
					TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1
					}):Play()
					TweenService:Create(bStroke, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Transparency = 1
					}):Play()
					TweenService:Create(icon, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						ImageTransparency = 0.15,
						ImageColor3 = SelectedTheme.TextColor
					}):Play()
					TweenService:Create(lbl, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						TextColor3 = SelectedTheme.TextColor
					}):Play()
				end
			end

			btn.MouseEnter:Connect(function() setHover(true) end)
			btn.MouseLeave:Connect(function() setHover(false) end)
			btn.SelectionGained:Connect(function() setHover(true) end)
			btn.SelectionLost:Connect(function() setHover(false) end)
			btn.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
					setHover(true)
				end
			end)
			btn.InputEnded:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
					setHover(false)
				end
			end)

			local function handleAction()
				closeContextMenu()
				task.spawn(opt.Callback)
			end
			btn.Activated:Connect(handleAction)
		end

		local mainPos = Main.AbsolutePosition
		local mainSize = Main.AbsoluteSize
		local mousePos = UserInputService:GetMouseLocation()

		local targetX = mousePos.X - mainPos.X
		local targetY = mousePos.Y - mainPos.Y

		if triggerBtn then
			local btnPos = triggerBtn.AbsolutePosition
			local btnSize = triggerBtn.AbsoluteSize
			if targetX < (btnPos.X - mainPos.X - 50) or targetX > (btnPos.X - mainPos.X + btnSize.X + 50) then
				targetX = btnPos.X - mainPos.X - menuWidth - 4
				targetY = btnPos.Y - mainPos.Y
			end
		end

		local posX = math.clamp(targetX, 10, math.max(10, mainSize.X - menuWidth - 10))
		local posY = math.clamp(targetY, 10, math.max(10, mainSize.Y - totalHeight - 10))

		contextMenu.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
		if cmStroke then
			cmStroke.Color = SelectedTheme.SecondaryElementStroke or SelectedTheme.ElementStroke
		end

		contextMenu.Position = UDim2.new(0, posX, 0, posY)
		contextMenu.Size = UDim2.new(0, menuWidth, 0, totalHeight)
		contextMenu.BackgroundTransparency = 1
		cmStroke.Transparency = 1
		cmScale.Scale = 0.88
		contextMenu.Visible = true
		contextOverlay.Visible = true

		TweenService:Create(contextMenu, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.02
		}):Play()
		TweenService:Create(cmStroke, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Transparency = 0
		}):Play()
		TweenService:Create(cmScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1
		}):Play()
	end

	listFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		closeContextMenu()
	end)

	local wheelConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel and contextMenu.Visible then
			closeContextMenu()
		end
	end)
	table.insert(allLibraryConnections, wheelConn)

	refreshList = function()
		refreshFileListGlobal = refreshList
		closeContextMenu()
	    for _, child in ipairs(listFrame:GetChildren()) do
	        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
	            child:Destroy()
	        end
	    end

	    if currentPath == "" then
	        backBar.Visible = false
	        listFrame.Position = UDim2.new(0.5, 0, 0, 50)
	        listFrame.Size = UDim2.new(1, -10, 1, -54)
	    else
	        backBar.Visible = true
	        curDirLabel.Text = currentPath
	        listFrame.Position = UDim2.new(0.5, 0, 0, 78)
	        listFrame.Size = UDim2.new(1, -10, 1, -82)
	    end

	    local rawList = {}
	    local listErr = nil
	    pcall(function()
	        local listFunc = listfiles or (getgenv and getgenv().listfiles) or (syn and syn.listfiles) or (fluxus and fluxus.listfiles)
	        if type(listFunc) == "function" then
	            local ok, res
	            if currentPath == "" then
	                ok, res = pcall(listFunc, "")
	                if not ok or type(res) ~= "table" then
	                    ok, res = pcall(listFunc)
	                end
	                if not ok or type(res) ~= "table" then
	                    ok, res = pcall(listFunc, ".")
	                end
	            else
	                ok, res = pcall(listFunc, currentPath)
	            end
	            if ok and type(res) == "table" then
	                rawList = res
	            elseif not ok then
	                listErr = tostring(res)
	            end
	        else
	            listErr = "Filesystem not supported by executor"
	        end
	    end)

	    local folders = {}
	    local files = {}

	    for _, p in ipairs(rawList) do
	        local name = cleanFileName(p)
	        local isDir = false
	        local isfolderFunc = isfolder or (getgenv and getgenv().isfolder) or (syn and syn.isfolder)
	        local isfileFunc = isfile or (getgenv and getgenv().isfile) or (syn and syn.isfile)
	        pcall(function()
	            if type(isfolderFunc) == "function" then
	                isDir = isfolderFunc(p) == true
	            end
	        end)
	        if not isDir and type(isfileFunc) == "function" then
	            pcall(function()
	                if isfileFunc(p) == false and getExtension(name) == "" then
	                    isDir = true
	                end
	            end)
	        end

	        local size = 0
	        if not isDir then
	            table.insert(files, {Path = p, Name = name, IsFolder = false, Size = size, Ext = getExtension(name)})
	        else
	            table.insert(folders, {Path = p, Name = name, IsFolder = true, Size = 0, Ext = "DIR"})
	        end
	    end

	    table.sort(folders, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
	    table.sort(files, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)

	    local currentItems = {}
	    for _, f in ipairs(folders) do table.insert(currentItems, f) end
	    for _, f in ipairs(files) do table.insert(currentItems, f) end

	    local filterText = string.lower(searchInput.Text)

	    if #currentItems == 0 then
	        local emptyLabel = Instance.new("TextLabel")
	        emptyLabel.Name = "EmptyStatus"
	        emptyLabel.Size = UDim2.new(1, -20, 0, 40)
	        emptyLabel.Position = UDim2.new(0.5, 0, 0, 15)
	        emptyLabel.AnchorPoint = Vector2.new(0.5, 0)
	        emptyLabel.BackgroundTransparency = 1
	        emptyLabel.Font = getUIFont()
	        emptyLabel.TextSize = 12
	        emptyLabel.TextColor3 = SelectedTheme.TextColor
	        emptyLabel.TextTransparency = 0.4
	        emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
	        if listErr then
	            emptyLabel.Text = "Filesystem: " .. tostring(listErr)
	        else
	            emptyLabel.Text = (filterText ~= "") and "No matching files" or "No files in workspace"
	        end
	        emptyLabel.Parent = listFrame
	    end

	    for i, item in ipairs(currentItems) do
	        local matches = (filterText == "" or string.find(string.lower(item.Name), filterText, 1, true))
	        if matches then
	            local row = Instance.new("Frame")
	            row.Name = item.Name
	            row.Size = UDim2.new(1, -4, 0, 34)
	            row.BackgroundColor3 = (selectedItem and selectedItem.Path == item.Path) and SelectedTheme.DropdownSelected or SelectedTheme.ElementBackground
	            row.BackgroundTransparency = (selectedItem and selectedItem.Path == item.Path) and 0.2 or 0.65
	            row.BorderSizePixel = 0
	            row.LayoutOrder = i
	            row.Parent = listFrame

	            local rCorner = Instance.new("UICorner", row); rCorner.CornerRadius = UDim.new(0, 6)

	            local iconImg = Instance.new("ImageLabel")
	            iconImg.Size = UDim2.new(0, 18, 0, 18)
	            iconImg.Position = UDim2.new(0, 10, 0.5, 0)
	            iconImg.AnchorPoint = Vector2.new(0, 0.5)
	            iconImg.BackgroundTransparency = 1
	            iconImg.ZIndex = 3
	            if item.IsFolder then
	                iconImg.Image = (folderAsset and folderAsset ~= "") and folderAsset or "rbxassetid://6034287525"
	            else
	                iconImg.Image = (fileAsset and fileAsset ~= "") and fileAsset or "rbxassetid://6034287527"
	            end
	            iconImg.ImageColor3 = SelectedTheme.TextColor
	            iconImg.Parent = row

	            local nameLbl = Instance.new("TextLabel")
	            nameLbl.Text = item.Name
	            nameLbl.Font = getUIFont()
	            nameLbl.TextSize = 12
	            nameLbl.TextColor3 = SelectedTheme.TextColor
	            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	            nameLbl.Position = UDim2.new(0, 36, 0, 0)
	            nameLbl.Size = UDim2.new(1, -125, 1, 0)
	            nameLbl.BackgroundTransparency = 1
	            nameLbl.ZIndex = 3
	            nameLbl.Parent = row

	            local sizeLbl = Instance.new("TextLabel")
	            sizeLbl.Text = item.IsFolder and "" or formatSize(item.Size)
	            sizeLbl.Font = getUIFont()
	            sizeLbl.TextSize = 11
	            sizeLbl.TextColor3 = SelectedTheme.TextColor
	            sizeLbl.TextTransparency = 0.5
	            sizeLbl.TextXAlignment = Enum.TextXAlignment.Right
	            sizeLbl.Position = UDim2.new(1, -85, 0, 0)
	            sizeLbl.Size = UDim2.new(0, 50, 1, 0)
	            sizeLbl.BackgroundTransparency = 1
	            sizeLbl.ZIndex = 3
	            sizeLbl.Parent = row

	            local menuBtn = Instance.new("TextButton")
	            menuBtn.Name = "MenuBtn"
	            menuBtn.Size = UDim2.new(0, 26, 0, 26)
	            menuBtn.Position = UDim2.new(1, -18, 0.5, 0)
	            menuBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	            menuBtn.BackgroundColor3 = SelectedTheme.ElementBackgroundHover
	            menuBtn.BackgroundTransparency = 1
	            menuBtn.Text = ""
	            menuBtn.AutoButtonColor = false
	            menuBtn.ZIndex = 5
	            menuBtn.Parent = row
	            local mbCorner = Instance.new("UICorner", menuBtn); mbCorner.CornerRadius = UDim.new(0, 6)
	            local mbStroke = Instance.new("UIStroke", menuBtn); mbStroke.Color = SelectedTheme.ElementStroke; mbStroke.Thickness = 1; mbStroke.Transparency = 1

	            local dotsContainer = Instance.new("Frame", menuBtn)
	            dotsContainer.Name = "Dots"
	            dotsContainer.Size = UDim2.new(0, 14, 0, 4)
	            dotsContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	            dotsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	            dotsContainer.BackgroundTransparency = 1
	            dotsContainer.Active = false

	            local dots = {}
	            for dotIdx = 0, 2 do
	                local dot = Instance.new("Frame", dotsContainer)
	                dot.Name = "Dot" .. (dotIdx + 1)
	                dot.Size = UDim2.new(0, 3, 0, 3)
	                dot.Position = UDim2.new(0, dotIdx * 5, 0.5, 0)
	                dot.AnchorPoint = Vector2.new(0, 0.5)
	                dot.BackgroundColor3 = SelectedTheme.TextColor
	                dot.BackgroundTransparency = 0.3
	                dot.BorderSizePixel = 0
	                local dc = Instance.new("UICorner", dot)
	                dc.CornerRadius = UDim.new(1, 0)
	                table.insert(dots, dot)
	            end

	            menuBtn.MouseEnter:Connect(function()
	                TweenService:Create(menuBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	                    BackgroundTransparency = 0.3
	                }):Play()
	                TweenService:Create(mbStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	                    Transparency = 0.5
	                }):Play()
	                for _, d in ipairs(dots) do
	                    TweenService:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	                        BackgroundTransparency = 0
	                    }):Play()
	                end
	            end)
	            menuBtn.MouseLeave:Connect(function()
	                TweenService:Create(menuBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	                    BackgroundTransparency = 1
	                }):Play()
	                TweenService:Create(mbStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	                    Transparency = 1
	                }):Play()
	                for _, d in ipairs(dots) do
	                    TweenService:Create(d, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	                        BackgroundTransparency = 0.3
	                    }):Play()
	                end
	            end)

	            menuBtn.MouseButton1Click:Connect(function()
	                openContextMenu(item, menuBtn)
	            end)

	            local rowBtn = Instance.new("TextButton")
	            rowBtn.Name = "RowClickArea"
	            rowBtn.Size = UDim2.new(1, -36, 1, 0)
	            rowBtn.Position = UDim2.new(0, 0, 0, 0)
	            rowBtn.BackgroundTransparency = 1
	            rowBtn.Text = ""
	            rowBtn.ZIndex = 2
	            rowBtn.Parent = row

	            row.MouseEnter:Connect(function()
	                if not (selectedItem and selectedItem.Path == item.Path) then
	                    TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.45}):Play()
	                end
	            end)
	            row.MouseLeave:Connect(function()
	                if not (selectedItem and selectedItem.Path == item.Path) then
	                    TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.65}):Play()
	                end
	            end)

	            local function onRowClicked()
	                closeContextMenu()
	                if item.IsFolder then
	                    local targetPath = string.gsub(item.Path or item.Name, "\\", "/")
	                    targetPath = string.gsub(targetPath, "^[./\\]+", "")
	                    currentPath = targetPath
	                    refreshList()
	                else
	                    selectedItem = item
	                    for _, r in ipairs(listFrame:GetChildren()) do
	                        if r:IsA("Frame") then
	                            if r.Name == item.Name then
	                                r.BackgroundColor3 = SelectedTheme.DropdownSelected
	                                r.BackgroundTransparency = 0.2
	                            else
	                                r.BackgroundColor3 = SelectedTheme.ElementBackground
	                                r.BackgroundTransparency = 0.65
	                            end
	                        end
	                    end
	                end
	            end
	            rowBtn.Activated:Connect(onRowClicked)

	            rowBtn.MouseButton2Click:Connect(function()
	                openContextMenu(item, rowBtn)
	            end)
	        end
	    end
	end

	local function goBack()
	    closeContextMenu()
	    currentPath = string.gsub(currentPath, "[/\\]?[^/\\]+$", "")
	    currentPath = string.gsub(currentPath, "^[./\\]+", "")
	    refreshList()
	end
	backBtn.Activated:Connect(goBack)

	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	    closeContextMenu()
	    refreshList()
	end)

	local previousTab = nil

	filesBtn.MouseButton1Click:Connect(function()
	    closeContextMenu()
	    local layout = Elements:FindFirstChildOfClass("UIPageLayout")
	    if not layout then return end

	    if layout.CurrentPage == workspacePage then
	        if previousTab and previousTab.Parent == Elements then
	            layout:JumpTo(previousTab)
	            for _, tb in ipairs(TabList:GetChildren()) do
	                if tb.Name == previousTab.Name then
	                    TweenService:Create(tb, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	                    TweenService:Create(tb.Title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	                    TweenService:Create(tb.Image, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
	                end
	            end
	        end
	    else
	        previousTab = layout.CurrentPage
	        for _, tb in ipairs(TabList:GetChildren()) do
	            if tb.Name ~= "Template" and tb:IsA("Frame") and tb.Name ~= "Placeholder" then
	                TweenService:Create(tb, TweenInfo.new(0.3), {BackgroundTransparency = 0.7}):Play()
	                TweenService:Create(tb.Title, TweenInfo.new(0.3), {TextTransparency = 0.2}):Play()
	                TweenService:Create(tb.Image, TweenInfo.new(0.3), {ImageTransparency = 0.2}):Play()
	            end
	        end
	        layout:JumpTo(workspacePage)
	        refreshList()
	    end
	end)

		updateFileExplorerTheme = function()
			if not workspacePage or not workspacePage.Parent then return end
			local anim = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

			if searchContainer then
				TweenService:Create(searchContainer, anim, {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
				if scStroke then
					TweenService:Create(scStroke, anim, {Color = SelectedTheme.ElementStroke}):Play()
				end
				if searchInput then
					searchInput.TextColor3 = SelectedTheme.TextColor
					searchInput.PlaceholderColor3 = SelectedTheme.PlaceholderColor or Color3.fromRGB(140, 140, 150)
				end
			end

			if backBar then
				if backBtn then
					TweenService:Create(backBtn, anim, {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
					if bbStroke then
						TweenService:Create(bbStroke, anim, {Color = SelectedTheme.ElementStroke}):Play()
					end
					if bbIcon then
						bbIcon.ImageColor3 = SelectedTheme.TextColor
					end
					if bbLbl then
						bbLbl.TextColor3 = SelectedTheme.TextColor
					end
				end
				if curDirLabel then
					TweenService:Create(curDirLabel, anim, {BackgroundColor3 = SelectedTheme.ElementBackground, TextColor3 = SelectedTheme.TextColor}):Play()
					if cdStroke then
						TweenService:Create(cdStroke, anim, {Color = SelectedTheme.ElementStroke}):Play()
					end
				end
			end

			if listFrame then
				listFrame.ScrollBarImageColor3 = SelectedTheme.ElementStroke
				for _, row in ipairs(listFrame:GetChildren()) do
					if row:IsA("Frame") then
						local isSel = (selectedItem and selectedItem.Path == row.Name)
						TweenService:Create(row, anim, {
							BackgroundColor3 = isSel and SelectedTheme.DropdownSelected or SelectedTheme.ElementBackground
						}):Play()
						for _, txt in ipairs(row:GetDescendants()) do
							if txt:IsA("TextLabel") and txt.Name ~= "Size" then
								txt.TextColor3 = SelectedTheme.TextColor
							end
						end
						local dots = row:FindFirstChild("MenuBtn") and row.MenuBtn:FindFirstChild("Dots")
						if dots then
							for _, d in ipairs(dots:GetChildren()) do
								if d:IsA("Frame") then
									d.BackgroundColor3 = SelectedTheme.TextColor
								end
							end
						end
					end
				end
			end

			if contextMenu then
				contextMenu.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
				if cmStroke then
					cmStroke.Color = SelectedTheme.SecondaryElementStroke or SelectedTheme.ElementStroke
				end
				for _, btn in ipairs(contextMenu:GetChildren()) do
					if btn:IsA("TextButton") then
						local lbl = btn:FindFirstChildOfClass("TextLabel")
						if lbl then lbl.TextColor3 = SelectedTheme.TextColor end
						local icon = btn:FindFirstChildOfClass("ImageLabel")
						if icon then icon.ImageColor3 = SelectedTheme.TextColor end
					end
				end
			end

			if filesBtn then
				local layout = Elements:FindFirstChildOfClass("UIPageLayout")
				if layout and layout.CurrentPage == workspacePage then
					filesBtn.ImageColor3 = SelectedTheme.TabBackgroundSelected
				else
					filesBtn.ImageColor3 = SelectedTheme.TextColor
				end
			end
		end

		if updateFileExplorerTheme then
			updateFileExplorerTheme()
		end
	end

	local hideBtnDebounce = false
	local function toggleHide()
		if Debounce or hideBtnDebounce then return end
		hideBtnDebounce = true
		task.delay(0.2, function() hideBtnDebounce = false end)
		setVisibility(Hidden, not useMobileSizing)
	end
	Topbar.Hide.MouseButton1Click:Connect(toggleHide)
	Topbar.Hide.Activated:Connect(toggleHide)

hideHotkeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
	local hotkeyName = getSetting("General", "rayfieldOpen")
	local targetCode = nil
	if type(hotkeyName) == "string" then
		pcall(function() targetCode = Enum.KeyCode[hotkeyName] end)
	end
	targetCode = targetCode or Enum.KeyCode.K
	if (input.KeyCode == targetCode) and not processed then
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
		pcall(function()
			if useStudio and config then
				LoadConfiguration(config)
				return
			end

			if isfile then
				if callSafely(isfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension) then
					LoadConfiguration(callSafely(readfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension))
				end
			end
		end)
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
	RayfieldLibrary:LoadConfiguration()
	if Main:FindFirstChild('Notice') and Main.Notice.Visible then
		TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 100, 0, 25), Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}):Play()
		TweenService:Create(Main.Notice.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

		task.wait(0.5)
		Main.Notice.Visible = false
	end
end)

return RayfieldLibrary
