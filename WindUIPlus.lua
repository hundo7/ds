--[[

	Rayfield Interface Suite
	by Sirius

	shlex  | Designing + Programming
	iRay   | Programming
	Max    | Programming
	Damian | Programming

]]

if debugX then
	warn('Initialising Rayfield')
end

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
		-- If the request fails the content can be empty, even if fetchSuccess is true
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response" -- Set the error message
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult -- Fetched content
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn(`Request for {url} timed out after {timeout} seconds`)
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	-- Wait for completion or timeout
	while not requestCompleted do
		task.wait()
	end
	-- Cancel timeout thread if still running when request completes
	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end
	if not success then
		warn(`Failed to process {url}: {result}`)
	end
	return if success then result else nil
end

local requestsDisabled = true --getgenv and getgenv().DISABLE_RAYFIELD_REQUESTS
local InterfaceBuild = '3K3W'
local Release = "Build 1.68"
local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
	General = {
		-- if needs be in order just make getSetting(name)
		rayfieldOpen = {Type = 'bind', Value = 'K', Name = 'Rayfield Keybind'},
		-- buildwarnings
		-- rayfieldprompts

	},
	System = {
		usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
	}
}

-- Settings that have been overridden by the developer. These will not be saved to the user's configuration file
-- Overridden settings always take precedence over settings in the configuration file, and are cleared if the user changes the setting in the UI
local overriddenSettings: { [string]: any } = {} -- For example, overriddenSettings["System.rayfieldOpen"] = "J"
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[`{category}.{name}`] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[`{category}.{name}`] ~= nil then
		return overriddenSettings[`{category}.{name}`]
	elseif settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

-- If requests/analytics have been disabled by developer, set the user-facing setting to false as well
if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

-- Environment Check
local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false -- Whether the UI elements in the settings page have been set to the proper values
local cachedSettings
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

-- Validate prompt loaded correctly
if not prompt and not useStudio then
	warn("Failed to load prompt library, using fallback")
	prompt = {
		create = function() end -- No-op fallback
	}
end



local function loadSettings()
	local file = nil

	local success, result =	pcall(function()
		task.spawn(function()
			if isfolder and isfolder(RayfieldFolder) then
				if isfile and isfile(RayfieldFolder..'/settings'..ConfigurationExtension) then
					file = readfile(RayfieldFolder..'/settings'..ConfigurationExtension)
				end
			end

			-- for debug in studio
			if useStudio then
				file = [[
		{"General":{"rayfieldOpen":{"Value":"K","Type":"bind","Name":"Rayfield Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Rayfield Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}}
	]]
			end


			if file then
				local success, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
				if success then
					file = decodedFile
				else
					file = {}
				end
			else
				file = {}
			end


			if not settingsCreated then 
				cachedSettings = file
				return
			end

			if file ~= {} then
				for categoryName, settingCategory in pairs(settingsTable) do
					if file[categoryName] then
						for settingName, setting in pairs(settingCategory) do
							if file[categoryName][settingName] then
								setting.Value = file[categoryName][settingName].Value
								setting.Element:Set(getSetting(categoryName, settingName))
							end
						end
					end
				end
			end
			settingsInitialized = true
		end)
	end)

	if not success then 
		if writefile then
			warn('Rayfield had an issue accessing configuration saving capability.')
		end
	end
end

if debugX then
	warn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
	warn('Settings Loaded')
end

local analyticsLib
local sendReport = function(ev_n, sc_n) warn("Failed to load report function") end
if not requestsDisabled then
	if debugX then
		warn('Querying Settings for Reporter Information')
	end	
	analyticsLib = loadWithTimeout("https://analytics.sirius.menu/script")
	if not analyticsLib then
		warn("Failed to load analytics reporter")
		analyticsLib = nil
	elseif analyticsLib and type(analyticsLib.load) == "function" then
		analyticsLib:load()
	else
		warn("Analytics library loaded but missing load function")
		analyticsLib = nil
	end
	sendReport = function(ev_n, sc_n)
		if not (type(analyticsLib) == "table" and type(analyticsLib.isLoaded) == "function" and analyticsLib:isLoaded()) then
			warn("Analytics library not loaded")
			return
		end
		if useStudio then
			print('Sending Analytics')
		else
			if debugX then warn('Reporting Analytics') end
			analyticsLib:report(
				{
					["name"] = ev_n,
					["script"] = {["name"] = sc_n, ["version"] = Release}
				},
				{
					["version"] = InterfaceBuild
				}
			)
			if debugX then warn('Finished Report') end
		end
	end
	if cachedSettings and (#cachedSettings == 0 or (cachedSettings.System and cachedSettings.System.usageAnalytics and cachedSettings.System.usageAnalytics.Value)) then
		sendReport("execution", "Rayfield")
	elseif not cachedSettings then
		sendReport("execution", "Rayfield")
	end
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
	warn('Moving on to continue initialisation')
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
			ToggleDisabledStroke = Color3.fromRGB(90, 110, 110),
			ToggleEnabledOuterStroke = Color3.fromRGB(80, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(50, 70, 70),

			DropdownSelected = Color3.fromRGB(35, 55, 55),
			DropdownUnselected = Color3.fromRGB(25, 45, 45),

			InputBackground = Color3.fromRGB(25, 40, 40),
			InputStroke = Color3.fromRGB(50, 70, 70),
			PlaceholderColor = Color3.fromRGB(170, 190, 190)
		},

		Light = {
			TextColor = Color3.fromRGB(50, 50, 50),

			Background = Color3.fromRGB(255, 255, 255),
			Topbar = Color3.fromRGB(217, 217, 217),
			Shadow = Color3.fromRGB(223, 223, 223),

			NotificationBackground = Color3.fromRGB(220, 220, 220),
			NotificationActionsBackground = Color3.fromRGB(217, 217, 217),

			TabBackground = Color3.fromRGB(230, 230, 230),
			TabStroke = Color3.fromRGB(223, 223, 223),
			TabBackgroundSelected = Color3.fromRGB(215, 215, 215),
			TabTextColor = Color3.fromRGB(50, 50, 50),
			SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

			ElementBackground = Color3.fromRGB(240, 240, 240),
			ElementBackgroundHover = Color3.fromRGB(235, 235, 235),
			SecondaryElementBackground = Color3.fromRGB(210, 210, 210),
			ElementStroke = Color3.fromRGB(180, 199, 97),
			SecondaryElementStroke = Color3.fromRGB(180, 199, 97),

			SliderBackground = Color3.fromRGB(180, 199, 97),
			SliderProgress = Color3.fromRGB(180, 199, 97),
			SliderStroke = Color3.fromRGB(180, 199, 97),

			ToggleBackground = Color3.fromRGB(255, 255, 255),
			ToggleEnabled = Color3.fromRGB(180, 199, 97),
			ToggleDisabled = Color3.fromRGB(255, 255, 255),
			ToggleEnabledStroke = Color3.fromRGB(180, 199, 97),
			ToggleDisabledStroke = Color3.fromRGB(180, 199, 97),
			ToggleEnabledOuterStroke = Color3.fromRGB(180, 199, 97),
			ToggleDisabledOuterStroke = Color3.fromRGB(180, 199, 97),

			DropdownSelected = Color3.fromRGB(230, 230, 230),
			DropdownUnselected = Color3.fromRGB(220, 220, 220),

			InputBackground = Color3.fromRGB(240, 240, 240),
			InputStroke = Color3.fromRGB(180, 199, 97),
			PlaceholderColor = Color3.fromRGB(100, 100, 100)
		}
	},
	EnableSaving = true,
	EnableKeySystem = false,
	Discord = {
		IsEnabled = false,
		Link = nil,
		RememberJoins = true -- Set this to false to make them join the discord every time they load it up
	},
	IconData = {
		id = 6035047374, -- "rbxassetid://6035047374",
		imageRectOffset = Vector2.new(964, 324),
		imageRectSize = Vector2.new(36, 36),
	}
}

-- Icons
local Icons = loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/icons.lua')
local getAssetUri = function(asset)
	if typeof(asset) == 'number' then
		return 'rbxassetid://'..asset
	elseif typeof(asset) == 'string' then
		return asset
	end
end

local getIcon = function(name)
	if typeof(Icons) == "table" and Icons[name] then
		return Icons[name]
	else
		warn(`Icon '{name}' not found`)
		return {id = 0}
	end
end

-- New Version Notification
task.spawn(function()
	local success, result = pcall(function()
		local latestVersion = loadWithTimeout('https://analytics.sirius.menu/rayfield/latest')
		if latestVersion and latestVersion ~= Release then
			RayfieldLibrary:Notify({
				Title = "Rayfield Interface Suite",
				Content = "A new version of Rayfield is available. Please download it from the Sirius website.",
				Duration = 7,
				Image = 4483362458,
				Actions = { -- Notification Buttons
					Open = {
						Name = "Open Download Page",
						Callback = function()
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
									args = {code = "sirius"}
								})
							})
							RayfieldLibrary:Notify({Title = "Rayfield Interface Suite", Content = "The download page has been opened. You can now update to the latest version.", Duration = 7, Image = 4483362458, })
						end
					},

					Ignore = {
						Name = "Ignore",
						Callback = function()
							RayfieldLibrary:Notify({Title = "Rayfield Interface Suite", Content = "You have ignored the notification.", Duration = 7, Image = 4483362458, })
						end
					},
				},
			})
		end
	end)
end)

local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local HttpService = getService("HttpService")
local TextService = getService("TextService")
local Mouse = game.Players.LocalPlayer:GetMouse()
local Players = getService("Players")
local RS = getService("RunService")
local CoreGui = getService("CoreGui")
local ContentProvider = getService("ContentProvider")
local TP = getService("TeleportService")
local InsertService = getService("InsertService")
local Lighting = getService("Lighting")

local function DeepCopyTable(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = DeepCopyTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function CreateWindow(Settings)
	sendReport("window", Settings.Name)
	local Passthrough = false
	if not Settings.LoadingTitle then
		Settings.LoadingTitle = "Rayfield Interface Suite"
	end
	if not Settings.LoadingSubtitle then
		Settings.LoadingSubtitle = "by Sirius"
	end
	if Settings.SaveConfiguration == nil then
		Settings.SaveConfiguration = true
	end
	if Settings.ConfigurationSaving then
		if Settings.ConfigurationSaving.Enabled and Settings.ConfigurationSaving.FolderName then
			RayfieldFolder = Settings.ConfigurationSaving.FolderName
			ConfigurationFolder = Settings.ConfigurationSaving.FolderName.."/Configurations"
			Settings.ConfigurationSaving.Enabled = true
		else
			Settings.ConfigurationSaving.Enabled = false
		end
	end
	local Rayfield = game:GetObjects("rbxassetid://11702779409")[1]

	if gethui then
		Rayfield.Parent = gethui()
	elseif syn.protect_gui then 
		syn.protect_gui(Rayfield)
		Rayfield.Parent = CoreGui
	else
		Rayfield.Parent = CoreGui
	end

	if gethui then
		for _, Interface in ipairs(gethui():GetChildren()) do
			if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
				Interface.Enabled = false
				Interface.Name = "Rayfield-Old"
			end
		end
	else
		for _, Interface in ipairs(CoreGui:GetChildren()) do
			if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
				Interface.Enabled = false
				Interface.Name = "Rayfield-Old"
			end
		end
	end

	-- Theme Saving
	local themeFile
	if Settings.ConfigurationSaving then
		if not isfolder(RayfieldFolder) then
			makefolder(tostring(RayfieldFolder))
		end
		if not isfolder(RayfieldFolder.."/Themes") then
			makefolder(tostring(RayfieldFolder).."/Themes")
		end
		if not isfile(tostring(RayfieldFolder).."/Themes".."/".."Default.txt") then
			themeFile = HttpService:JSONEncode(RayfieldLibrary.Theme.Default)
			writefile(tostring(RayfieldFolder).."/Themes".."/".."Default.txt", themeFile)
		end
	end

	-- Icon
	local asset = getIcon("rayfield")
	Rayfield.Main.WindowIcon.Image = 'rbxassetid://'..asset.id
	Rayfield.Main.WindowIcon.ImageRectOffset = asset.imageRectOffset
	Rayfield.Main.WindowIcon.ImageRectSize = asset.imageRectSize

	local SelectedTheme = RayfieldLibrary.Theme.Default
	local function LoadTheme(Theme)
		local themeFile = readfile(tostring(RayfieldFolder).."/Themes".."/"..Theme..".txt")
		local themeTable = HttpService:JSONDecode(themeFile)
		SelectedTheme = themeTable
		for _, obj in ipairs(Rayfield:GetDescendants()) do
			pcall(function()
				if obj.ClassName == "TextButton" or obj.ClassName == "TextLabel" or obj.ClassName == "TextBox" or obj.ClassName == "ImageButton" or obj.ClassName == "ImageLabel" then
					if SelectedTheme[obj.Name] then
						obj.BackgroundColor3 = SelectedTheme[obj.Name]
					elseif SelectedTheme[obj.Parent.Name] then
						obj.BackgroundColor3 = SelectedTheme[obj.Parent.Name]
					elseif SelectedTheme[obj.Parent.Parent.Name] then
						obj.BackgroundColor3 = SelectedTheme[obj.Parent.Parent.Name]
					end
				end
			end)
		end
	end

	local function SaveTheme(Theme)
		if not isfile(tostring(RayfieldFolder).."/Themes".."/"..Theme..".txt") then
			local themeTable = {}
			for _, obj in ipairs(Rayfield:GetDescendants()) do
				pcall(function()
					if obj.ClassName == "TextButton" or obj.ClassName == "TextLabel" or obj.ClassName == "TextBox" or obj.ClassName == "ImageButton" or obj.ClassName == "ImageLabel" then
						themeTable[obj.Name] = obj.BackgroundColor3
					end
				end)
			end
			local themeFile = HttpService:JSONEncode(themeTable)
			writefile(tostring(RayfieldFolder).."/Themes".."/"..Theme..".txt", themeFile)
		end
	end

	function RayfieldLibrary:Notify(NotificationSettings
