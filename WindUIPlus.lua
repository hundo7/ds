-- TakoGlass UI v7.5
-- Glass-style Roblox UI with:
-- - Tabs, sections, toggles, sliders, dropdowns, inputs, buttons
-- - Config saving (if file APIs exist)
-- - Theme + color override
-- - Blur + toggle key
-- - Dropdown hover highlight
-- - Animated close confirmation dialog
-- - Clean, aligned layout & visible tab text / close X

--------------------------------------------------
-- Services / Guard
--------------------------------------------------

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local RunService       = game:GetService("RunService")

if not RunService:IsClient() then
    error("TakoGlass must run on the client.")
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local function GetPlayerGui()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    while not pg do
        task.wait()
        pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return pg
end

--------------------------------------------------
-- Root & Themes
--------------------------------------------------

local TakoGlass = {}
TakoGlass.__index = TakoGlass

local CONFIG_FOLDER  = "TakoGlassConfigs"
local DEFAULT_THEME  = "Dark"
local MAX_NOTIF      = 5
local RADIUS         = 10

local Themes = {
    Dark = {
        Name        = "Dark",
        WindowBg    = Color3.fromRGB(16, 16, 24),
        WindowAlpha = 0.35,

        CardBg      = Color3.fromRGB(24, 24, 36),
        ElementBg   = Color3.fromRGB(32, 32, 48),
        SidebarBg   = Color3.fromRGB(14, 14, 20),

        Accent      = Color3.fromRGB(90, 135, 255),
        AccentSoft  = Color3.fromRGB(72, 110, 220),

        Text        = Color3.fromRGB(255, 255, 255),
        SubText     = Color3.fromRGB(175, 180, 205),

        StrokeSoft  = Color3.fromRGB(80, 80, 110),
    },

    Light = {
        Name        = "Light",
        WindowBg    = Color3.fromRGB(245, 247, 255),
        WindowAlpha = 0.18,

        CardBg      = Color3.fromRGB(252, 252, 255),
        ElementBg   = Color3.fromRGB(238, 241, 255),
        SidebarBg   = Color3.fromRGB(234, 238, 255),

        Accent      = Color3.fromRGB(80, 130, 255),
        AccentSoft  = Color3.fromRGB(60, 105, 230),

        Text        = Color3.fromRGB(24, 26, 40),
        SubText     = Color3.fromRGB(100, 105, 140),

        StrokeSoft  = Color3.fromRGB(200, 205, 230),
    }
}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function Create(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    return o
end

local function Ease(obj, goal, t)
    if not obj then return end
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goal
    ):Play()
end

local function HasFileApi()
    return typeof(isfolder) == "function"
        and typeof(makefolder) == "function"
        and typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
end

local function EnsureConfigFolder()
    if not HasFileApi() then return end
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function SafeJSONEncode(tbl)
    local ok, result = pcall(HttpService.JSONEncode, HttpService, tbl)
    if not ok then return nil end
    return result
end

local function SafeJSONDecode(str)
    local ok, result = pcall(HttpService.JSONDecode, HttpService, str)
    if not ok or type(result) ~= "table" then return nil end
    return result
end

local function SaveConfig(name, data)
    if not HasFileApi() then return end
    EnsureConfigFolder()
    local json = SafeJSONEncode(data)
    if not json then return end
    writefile(("%s/%s.json"):format(CONFIG_FOLDER, name), json)
end

local function LoadConfig(name)
    if not HasFileApi() then return {} end
    EnsureConfigFolder()
    local path = ("%s/%s.json"):format(CONFIG_FOLDER, name)
    if not isfile(path) then return {} end
    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then return {} end
    local decoded = SafeJSONDecode(content)
    return decoded or {}
end

local function CardAlpha(isTransparent)
    return isTransparent and 0.25 or 0.06
end

--------------------------------------------------
-- Blur helper
--------------------------------------------------

local function GetBlur()
    local blur = Lighting:FindFirstChild("TakoGlassBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "TakoGlassBlur"
        blur.Enabled = false
        blur.Parent = Lighting
    end
    return blur
end

--------------------------------------------------
-- Notifications
--------------------------------------------------

local _currentThemeName   = DEFAULT_THEME
local _currentTransparent = true

local function GetNotifyGui()
    local pg  = GetPlayerGui()
    local gui = pg:FindFirstChild("TakoGlass_Notify")
    if gui then return gui end

    gui = Create("ScreenGui", {
        Name = "TakoGlass_Notify",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    gui.Parent = pg

    local holder = Create("Frame", {
        Name = "Holder",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -24, 1, -24),
        Size = UDim2.new(0, 320, 1, -48),
        BackgroundTransparency = 1,
    })
    holder.Parent = gui

    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 6),
    })
    layout.Parent = holder

    return gui
end

function TakoGlass.Notify(title, message, duration)
    local gui    = GetNotifyGui()
    local holder = gui:FindFirstChild("Holder")
    if not holder then return end

    local theme = Themes[_currentThemeName] or Themes[DEFAULT_THEME]

    local stack = {}
    for _, child in ipairs(holder:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(stack, child)
        end
    end
    if #stack >= MAX_NOTIF then
        stack[1]:Destroy()
    end

    local card = Create("Frame", {
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = CardAlpha(_currentTransparent),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = 200,
    })
    card.Parent = holder

    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = card })
    Create("UIStroke", {
        Color = theme.StrokeSoft,
        Thickness = 1,
        Transparency = 0.35,
        Parent = card,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = card,
    })

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = title or "Notification",
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 201,
    })
    titleLabel.Parent = card

    local body = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = message or "",
        TextColor3 = theme.SubText,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 18),
        ZIndex = 201,
    })
    body.Parent = card

    task.defer(function()
        if not body or not body.Parent then return end
        local bounds = body.TextBounds
        local totalHeight = 18 + bounds.Y + 8
        body.Size = UDim2.new(1, 0, 0, bounds.Y)
        Ease(card, { Size = UDim2.new(1, 0, 0, totalHeight) }, 0.16)
    end)

    local alive = true
    local function Close()
        if not alive or not card or not card.Parent then return end
        alive = false
        Ease(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.15)
        task.delay(0.18, function()
            if card then card:Destroy() end
        end)
    end

    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Close()
        end
    end)

    task.delay(duration or 4, Close)
end

--------------------------------------------------
-- Close confirmation dialog
--------------------------------------------------

local function ShowCloseDialog(window)
    local theme = Themes[window.ThemeName]

    local pg = window.Gui.Parent
    local overlay = Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 250,
    })
    overlay.Parent = window.Gui

    Ease(overlay, { BackgroundTransparency = 0.35 }, 0.15)

    local dialog = Create("Frame", {
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(0.5, 0, 0.5, 0),
        Size               = UDim2.new(0, 320, 0, 140),
        BackgroundColor3   = theme.CardBg,
        BackgroundTransparency = CardAlpha(window.Transparent),
        BorderSizePixel    = 0,
        ZIndex             = 255,
    })
    dialog.Parent = overlay
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = dialog })
    Create("UIStroke", {
        Color = theme.StrokeSoft,
        Thickness = 1,
        Transparency = 0.35,
        Parent = dialog,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = dialog,
    })

    dialog.Size = UDim2.new(0, 0, 0, 0)
    Ease(dialog, { Size = UDim2.new(0, 320, 0, 140) }, 0.16)

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = "Close Window",
        TextColor3 = theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 22),
        ZIndex = 256,
    })
    title.Parent = dialog

    local body = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Are you sure you wanna close this window?\nYou wont be able to open it again.",
        TextColor3 = theme.SubText,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 52),
        ZIndex = 256,
    })
    body.Parent = dialog

    local buttonRow = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 1, -32),
        ZIndex = 256,
    })
    buttonRow.Parent = dialog

    local noButton = Create("TextButton", {
        BackgroundColor3 = theme.ElementBg,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Text = "Cancel",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Text,
        Size = UDim2.new(0.48, -4, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 257,
    })
    noButton.Parent = buttonRow
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = noButton })

    local yesButton = Create("TextButton", {
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = "Close",
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(0.48, -4, 1, 0),
        Position = UDim2.new(0.52, 0, 0, 0),
        ZIndex = 257,
    })
    yesButton.Parent = buttonRow
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = yesButton })

    local function dismiss()
        Ease(overlay, { BackgroundTransparency = 1 }, 0.12)
        Ease(dialog, { Size = UDim2.new(0, 0, 0, 0) }, 0.12)
        task.delay(0.14, function()
            if overlay then overlay:Destroy() end
        end)
    end

    noButton.MouseButton1Click:Connect(dismiss)

    yesButton.MouseButton1Click:Connect(function()
        dismiss()
        window.BlurObject.Enabled = false
        for _, c in ipairs(window._connections) do
            c:Disconnect()
        end
        if window.Gui then
            window.Gui:Destroy()
        end
    end)
end

--------------------------------------------------
-- Window creation
--------------------------------------------------

function TakoGlass:CreateWindow(opts)
    opts = opts or {}

    local self = setmetatable({}, TakoGlass)

    self.Title        = opts.Title or "UI Title"
    self.SubTitle     = opts.SubTitle or ""
    self.ConfigName   = opts.ConfigName or self.Title
    self.ThemeName    = opts.Theme or DEFAULT_THEME
    self.Size         = opts.Size or UDim2.fromOffset(580, 460)
    self.SidebarWidth = opts.SidebarWidth or 200
    self.Transparent  = (opts.Transparent ~= nil) and opts.Transparent or true

    self.UseBlur      = (opts.UseBlur ~= nil) and opts.UseBlur or false
    self.BlurSize     = opts.BlurSize or 18

    self.Flags        = {}
    self.Config       = LoadConfig(self.ConfigName)
    if self.Config.__Theme and Themes[self.Config.__Theme] then
        self.ThemeName = self.Config.__Theme
    end

    self.Tabs         = {}
    self.Elements     = {}
    self.ToggleKey    = Enum.KeyCode.RightShift
    self.IsOpen       = true
    self.IsMinimized  = false
    self._connections = {}

    local theme    = Themes[self.ThemeName]
    local playerGui= GetPlayerGui()

    _currentThemeName   = self.ThemeName
    _currentTransparent = self.Transparent

    self.BlurObject = GetBlur()
    self.BlurObject.Size = self.BlurSize
    self.BlurObject.Enabled = self.UseBlur

    local gui = Create("ScreenGui", {
        Name = "TakoGlass_" .. self.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    gui.Parent = playerGui
    self.Gui = gui

    local main = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = self.Size,
        BackgroundColor3 = theme.WindowBg,
        BackgroundTransparency = self.Transparent and theme.WindowAlpha or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 50,
    })
    main.Parent = gui
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS + 4), Parent = main })
    Create("UIStroke", {
        Color = theme.StrokeSoft,
        Thickness = 1,
        Transparency = 0.3,
        Parent = main,
    })
    self.Main = main

    --------------------------------------------------
    -- Top bar
    --------------------------------------------------

    local topBar = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 51,
    })
    topBar.Parent = main

    Create("UIPadding", {
        PaddingLeft  = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 12),
        Parent = topBar,
    })

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = self.Title,
        TextColor3 = theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 6),
        ZIndex = 52,
    })
    titleLabel.Parent = topBar

    local subLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = self.SubTitle,
        TextColor3 = theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.7, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 24),
        ZIndex = 52,
    })
    subLabel.Parent = topBar

    self.TitleLabel    = titleLabel
    self.SubTitleLabel = subLabel

    local minimizeButton = Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "–",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = theme.Text,
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(1, -64, 0, 0),
        ZIndex = 53,
    })
    minimizeButton.Parent = topBar

    local closeButton = Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = theme.Text,
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(1, -32, 0, 0),
        ZIndex = 53,
    })
    closeButton.Parent = topBar

    closeButton.MouseButton1Click:Connect(function()
        Ease(main, { Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
        ShowCloseDialog(self)
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        self.IsMinimized = not self.IsMinimized
        if self.IsMinimized then
            Ease(main, { Size = UDim2.new(0, self.Size.X.Offset, 0, 44) }, 0.16)
        else
            Ease(main, { Size = self.Size }, 0.16)
        end
    end)

    --------------------------------------------------
    -- Dragging
    --------------------------------------------------

    do
        local dragging = false
        local dragStart, startPos

        local function ClampToViewport(pos)
            local cam = workspace.CurrentCamera
            local vp  = cam and cam.ViewportSize or Vector2.new(1920, 1080)
            local halfX = self.Size.X.Offset / 2
            local halfY = self.Size.Y.Offset / 2
            local minX  = -vp.X / 2 + halfX
            local maxX  =  vp.X / 2 - halfX
            local minY  = -vp.Y / 2 + halfY
            local maxY  =  vp.Y / 2 - halfY
            local x = math.clamp(pos.X.Offset, minX, maxX)
            local y = math.clamp(pos.Y.Offset, minY, maxY)
            return UDim2.new(0.5, x, 0.5, y)
        end

        local function beginDrag(input)
            dragging  = true
            dragStart = input.Position
            startPos  = main.Position
        end

        local function updateDrag(input)
            if not dragging then return end
            local delta = input.Position - dragStart
            main.Position = ClampToViewport(
                UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            )
        end

        topBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                beginDrag(input)
            end
        end)

        topBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        topBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                updateDrag(input)
            end
        end)
    end

    --------------------------------------------------
    -- Sidebar & content
    --------------------------------------------------

    local sidebar = Create("Frame", {
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = self.Transparent and 0.25 or 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, self.SidebarWidth, 1, -44),
        ClipsDescendants = true,
        ZIndex = 51,
    })
    sidebar.Parent = main
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = sidebar })

    local sidebarScroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ZIndex = 52,
    })
    sidebarScroll.Parent = sidebar

    local tabLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
    })
    tabLayout.Parent = sidebarScroll

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebarScroll,
    })

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 10)
    end)

    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, self.SidebarWidth, 0, 44),
        Size = UDim2.new(1, -self.SidebarWidth, 1, -44),
        ClipsDescendants = true,
        ZIndex = 51,
    })
    content.Parent = main

    self.Sidebar   = sidebar
    self.TabHolder = sidebarScroll
    self.Content   = content

    --------------------------------------------------
    -- Toggle key
    --------------------------------------------------

    local lastToggle = 0
    local toggleConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard
           and input.KeyCode == self.ToggleKey then
            local now = tick()
            if now - lastToggle < 0.15 then return end
            lastToggle = now
            self:SetVisible(not self.IsOpen)
        end
    end)
    table.insert(self._connections, toggleConn)

    self:SetTheme(self.ThemeName)

    return self
end

--------------------------------------------------
-- Window methods
--------------------------------------------------

function TakoGlass:SetVisible(state)
    self.IsOpen = state
    if self.Gui then
        self.Gui.Enabled = state
    end
    if self.BlurObject then
        self.BlurObject.Enabled = state and self.UseBlur or false
    end
end

function TakoGlass:SetToggleKey(keycode)
    self.ToggleKey = keycode
end

function TakoGlass:SetBlur(enabled, size)
    self.UseBlur = enabled and true or false
    if size then self.BlurSize = size end
    local blur = self.BlurObject or GetBlur()
    self.BlurObject = blur
    blur.Size = self.BlurSize
    blur.Enabled = self.UseBlur and self.IsOpen
end

function TakoGlass:SetTheme(name)
    if not Themes[name] then return end
    self.ThemeName        = name
    _currentThemeName     = name
    _currentTransparent   = self.Transparent
    local theme           = Themes[name]

    if self.Main then
        self.Main.BackgroundColor3 = theme.WindowBg
        self.Main.BackgroundTransparency = self.Transparent and theme.WindowAlpha or 0
        local stroke = self.Main:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.StrokeSoft
            stroke.Transparency = 0.3
        end
    end

    if self.TitleLabel then self.TitleLabel.TextColor3 = theme.Text end
    if self.SubTitleLabel then self.SubTitleLabel.TextColor3 = theme.SubText end
    if self.Sidebar then
        self.Sidebar.BackgroundColor3 = theme.SidebarBg
        self.Sidebar.BackgroundTransparency = self.Transparent and 0.25 or 0.08
    end

    for _, tab in ipairs(self.Tabs) do
        if tab.ApplyTheme then
            tab:ApplyTheme(theme)
        end
    end

    for _, el in ipairs(self.Elements) do
        if el.ApplyTheme then
            el:ApplyTheme(theme)
        end
    end

    self.Config.__Theme = name
    SaveConfig(self.ConfigName, self.Config)
end

function TakoGlass:SetThemeColors(colors)
    colors = colors or {}
    local theme = Themes[self.ThemeName]
    for k, v in pairs(colors) do
        if theme[k] ~= nil then
            theme[k] = v
        end
    end
    self:SetTheme(self.ThemeName)
end

--------------------------------------------------
-- Tabs / Sections / Elements
--------------------------------------------------

function TakoGlass:CreateTab(name)
    local theme = Themes[self.ThemeName]

    local button = Create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Text,
        Size = UDim2.new(1, 0, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
    })
    button.Parent = self.TabHolder

    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        Parent = button,
    })

    local buttonBg = Create("Frame", {
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 51,
    })
    buttonBg.Parent = button
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = buttonBg })

    local page = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6,
        Visible = false,
        ZIndex = 51,
    })
    page.Parent = self.Content

    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 12),
    })
    layout.Parent = page

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = page,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local tab = {
        Window   = self,
        Button   = button,
        ButtonBg = buttonBg,
        Page     = page,
        Sections = {},
    }

    function tab:SetActive()
        for _, other in ipairs(self.Window.Tabs) do
            other.Page.Visible = false
            Ease(other.ButtonBg, { BackgroundTransparency = 1 }, 0.12)
        end
        self.Page.Visible = true
        Ease(self.ButtonBg, {
            BackgroundTransparency = 0,
            BackgroundColor3 = Themes[self.Window.ThemeName].CardBg
        }, 0.12)
    end

    function tab:ApplyTheme(theme)
        self.Button.TextColor3 = theme.Text
        self.ButtonBg.BackgroundColor3 = theme.SidebarBg
        for _, sec in ipairs(self.Sections) do
            if sec.ApplyTheme then
                sec:ApplyTheme(theme)
            end
        end
    end

    button.MouseEnter:Connect(function()
        if not page.Visible then
            Ease(buttonBg, { BackgroundTransparency = 0.3 }, 0.1)
        end
    end)

    button.MouseLeave:Connect(function()
        if not page.Visible then
            Ease(buttonBg, { BackgroundTransparency = 1 }, 0.1)
        end
    end)

    button.MouseButton1Click:Connect(function()
        tab:SetActive()
    end)

    if #self.Tabs == 0 then
        tab:SetActive()
    end
    table.insert(self.Tabs, tab)

    --------------------------------------------------
    -- Section & elements
    --------------------------------------------------

    local function CreateSection(opts)
        opts = opts or {}
        local name = opts.Name or "Section"

        local theme = Themes[tab.Window.ThemeName]

        local frame = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), -- Size is calculated by the layout
        })
        frame.Parent = tab.Page

        local content = Create("Frame", {
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = CardAlpha(tab.Window.Transparent),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 20),
            ClipsDescendants = true,
            ZIndex = 51,
        })
        content.Parent = frame
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = content })
        Create("UIStroke", {
            Color = theme.StrokeSoft,
            Thickness = 1,
            Transparency = 0.35,
            Parent = content,
        })

        local sectionLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 4),
        })
        sectionLayout.Parent = content

        Create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = content,
        })

        local titleLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Text = name,
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 52,
        })
        titleLabel.Parent = frame

        local section = {
            Window   = tab.Window,
            Content  = content,
            Title    = titleLabel,
            Layout   = sectionLayout,
            Elements = {},
        }
        
        local currentHeight = 0
        local function UpdateHeight()
            local contentHeight = sectionLayout.AbsoluteContentSize.Y + 16
            currentHeight = contentHeight
            content.Size = UDim2.new(1, 0, 0, contentHeight)
            frame.Size = UDim2.new(1, 0, 0, 20 + contentHeight)
        end
        sectionLayout.DidUpdate:Connect(UpdateHeight)
        UpdateHeight()

        function section:ApplyTheme(theme)
            self.Title.TextColor3 = theme.Text
            self.Content.BackgroundColor3 = theme.CardBg
            self.Content.BackgroundTransparency = CardAlpha(self.Window.Transparent)
            local stroke = self.Content:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = theme.StrokeSoft
            end
            for _, el in ipairs(self.Elements) do
                if el.ApplyTheme then
                    el:ApplyTheme(theme)
                end
            end
        end

        -- AddToggle
        function section:Toggle(opt)
            opt = opt or {}
            local name     = opt.Name or "Toggle"
            local default  = opt.Default or false
            local flag     = opt.Flag or ("TG_Toggle_" .. name)
            local callback = opt.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            
            local currentValue = self.Window.Config[flag]
            self.Window.Flags[flag] = currentValue

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 54,
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -70, 1, 0),
                ZIndex = 55,
            })
            label.Parent = row

            local toggleFrame = Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 36, 0, 16),
                BackgroundColor3 = currentValue and theme.Accent or theme.ElementBg,
                BackgroundTransparency = currentValue and 0 or 0.05,
                BorderSizePixel = 0,
                ZIndex = 55,
            })
            toggleFrame.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = toggleFrame })

            local handle = Create("Frame", {
                AnchorPoint = Vector2.new(currentValue and 1 or 0, 0.5),
                Position = UDim2.new(currentValue and 1 or 0, currentValue and -2 or 2, 0.5, 0),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ZIndex = 56,
            })
            handle.Parent = toggleFrame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = handle })

            local function UpdateVisuals(state)
                local bg = state and theme.Accent or theme.ElementBg
                local bgT = state and 0 or 0.05
                local handlePos = state and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                
                Ease(toggleFrame, { BackgroundColor3 = bg, BackgroundTransparency = bgT }, 0.1)
                Ease(handle, { Position = handlePos }, 0.1)
            end

            local function MouseClick()
                currentValue = not currentValue
                self.Window.Flags[flag] = currentValue
                self.Window.Config[flag] = currentValue
                SaveConfig(self.Window.ConfigName, self.Window.Config)
                
                UpdateVisuals(currentValue)
                callback(currentValue)
            end

            toggleFrame.MouseButton1Click:Connect(MouseClick)

            local el = {
                ApplyTheme = function(t) 
                    label.TextColor3 = t.Text 
                    if currentValue then
                        toggleFrame.BackgroundColor3 = t.Accent
                    else
                        toggleFrame.BackgroundColor3 = t.ElementBg
                    end
                end,
                Set = function(value)
                    if currentValue == value then return end
                    currentValue = value
                    self.Window.Flags[flag] = currentValue
                    self.Window.Config[flag] = currentValue
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    UpdateVisuals(currentValue)
                end,
                Value = function() return currentValue end
            }
            table.insert(self.Elements, el)
            return el
        end

        -- AddSlider
        function section:Slider(opt)
            opt = opt or {}
            local name     = opt.Name or "Slider"
            local default  = opt.Default or 50
            local minVal   = opt.Min or 0
            local maxVal   = opt.Max or 100
            local step     = opt.Step or 1
            local flag     = opt.Flag or ("TG_Slider_" .. name)
            local callback = opt.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end

            local currentValue = self.Window.Config[flag]
            self.Window.Flags[flag] = currentValue

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 42),
                ZIndex = 54,
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -70, 0, 20),
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 55,
            })
            label.Parent = row

            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = tostring(math.round(currentValue / step) * step),
                TextColor3 = theme.SubText,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                Size = UDim2.new(1, -70, 0, 20),
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 55,
            })
            valueLabel.Parent = row

            local sliderFrame = Create("Frame", {
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 8),
                Position = UDim2.new(0, 0, 0, 22),
                ZIndex = 55,
            })
            sliderFrame.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sliderFrame })

            local fill = Create("Frame", {
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 0, 1, 0),
                ZIndex = 56,
            })
            fill.Parent = sliderFrame

            local handle = Create("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ZIndex = 57,
            })
            handle.Parent = sliderFrame
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = handle })

            local function UpdateVisuals(value)
                local percentage = (value - minVal) / (maxVal - minVal)
                local sliderWidth = sliderFrame.AbsoluteSize.X
                local fillWidth = percentage * sliderWidth
                local handlePos = UDim2.new(0, fillWidth, 0.5, 0)
                
                fill.Size = UDim2.new(0, fillWidth, 1, 0)
                handle.Position = handlePos
                valueLabel.Text = tostring(math.round(value / step) * step)
            end
            
            UpdateVisuals(currentValue)

            local dragging = false
            local dragConn

            local function UpdateValue(pos)
                local x = math.clamp(pos.X - sliderFrame.AbsolutePosition.X, 0, sliderFrame.AbsoluteSize.X)
                local percentage = x / sliderFrame.AbsoluteSize.X
                local rawValue = minVal + percentage * (maxVal - minVal)
                local steppedValue = math.round(rawValue / step) * step
                
                currentValue = math.clamp(steppedValue, minVal, maxVal)
                self.Window.Flags[flag] = currentValue
                self.Window.Config[flag] = currentValue
                SaveConfig(self.Window.ConfigName, self.Window.Config)

                UpdateVisuals(currentValue)
                callback(currentValue)
            end

            local function beginDrag(input)
                dragging = true
                UpdateValue(input.Position)
                
                dragConn = UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateValue(input.Position)
                    end
                end)
            end

            local function endDrag()
                dragging = false
                if dragConn then dragConn:Disconnect() end
            end

            sliderFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    beginDrag(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    endDrag()
                end
            end)

            local el = {
                ApplyTheme = function(t) 
                    label.TextColor3 = t.Text 
                    valueLabel.TextColor3 = t.SubText
                    sliderFrame.BackgroundColor3 = t.ElementBg
                    fill.BackgroundColor3 = t.Accent
                end,
                Set = function(value)
                    if currentValue == value then return end
                    currentValue = math.clamp(math.round(value / step) * step, minVal, maxVal)
                    self.Window.Flags[flag] = currentValue
                    self.Window.Config[flag] = currentValue
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    UpdateVisuals(currentValue)
                end,
                Value = function() return currentValue end
            }
            table.insert(self.Elements, el)
            return el
        end
        
        -- AddDropdown
        function section:Dropdown(opt)
            opt = opt or {}
            local name     = opt.Name or "Dropdown"
            local default  = opt.Default or (opt.Options and opt.Options[1]) or "Option 1"
            local options  = opt.Options or {"Option 1", "Option 2", "Option 3"}
            local flag     = opt.Flag or ("TG_Dropdown_" .. name)
            local callback = opt.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            
            local currentValue = self.Window.Config[flag]
            self.Window.Flags[flag] = currentValue

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 54,
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -90, 1, 0),
                ZIndex = 55,
            })
            label.Parent = row

            local button = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 80, 1, 0),
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = tostring(currentValue),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                ZIndex = 55,
            })
            button.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, RADIUS - 2), Parent = button })

            -- Dropdown menu setup
            local listFrame = Create("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 1, 4),
                Size = UDim2.new(0, 120, 0, 0),
                BackgroundColor3 = theme.CardBg,
                BackgroundTransparency = CardAlpha(self.Window.Transparent),
                BorderSizePixel = 0,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 90,
            })
            listFrame.Parent = button -- Attach to button to manage position
            Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = listFrame })
            Create("UIStroke", {
                Color = theme.StrokeSoft,
                Thickness = 1,
                Transparency = 0.35,
                Parent = listFrame,
            })

            local scroll = Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 6,
                ZIndex = 91,
            })
            scroll.Parent = listFrame

            local listLayout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 2),
            })
            listLayout.Parent = scroll
            
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                Parent = scroll,
            })

            local function ToggleList(state)
                local targetHeight = state and (listLayout.AbsoluteContentSize.Y + 4) or 0
                targetHeight = math.min(targetHeight, 200) -- Cap height to 200 pixels

                if state then
                    listFrame.Visible = true
                    Ease(listFrame, { Size = UDim2.new(0, 120, 0, targetHeight) }, 0.15)
                else
                    Ease(listFrame, { Size = UDim2.new(0, 120, 0, 0) }, 0.15)
                    task.delay(0.16, function() listFrame.Visible = false end)
                end
            end

            button.MouseButton1Click:Connect(function()
                ToggleList(not listFrame.Visible)
            end)

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
            end)

            for _, option in ipairs(options) do
                local row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    ZIndex = 92,
                })
                row.Parent = scroll
                
                local bg = Create("Frame", {
                    BackgroundColor3 = theme.AccentSoft,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -2, 1, 0),
                    Position = UDim2.new(0, 1, 0, 0),
                    ZIndex = 92,
                })
                bg.Parent = row
                Create("UICorner", { CornerRadius = UDim.new(0, RADIUS - 4), Parent = bg })

                local optBtn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Text = tostring(option),
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = theme.Text,
                    Size = UDim2.new(1, -6, 1, 0),
                    Position = UDim2.new(0, 3, 0, 0),
                    ZIndex = 93,
                })
                optBtn.Parent = row

                optBtn.MouseEnter:Connect(function()
                    Ease(bg, { BackgroundTransparency = 0.6 }, 0.12)
                end)

                optBtn.MouseLeave:Connect(function()
                    Ease(bg, { BackgroundTransparency = 1 }, 0.12)
                end)

                optBtn.MouseButton1Click:Connect(function()
                    currentValue = option
                    self.Window.Flags[flag] = option
                    self.Window.Config[flag] = option
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    button.Text = tostring(option)
                    ToggleList(false)
                    callback(option)
                end)
            end
            
            local el = {
                ApplyTheme = function(t) 
                    label.TextColor3 = t.Text 
                    button.BackgroundColor3 = t.ElementBg
                    button.TextColor3 = t.Text
                    listFrame.BackgroundColor3 = t.CardBg
                    local stroke = listFrame:FindFirstChildOfClass("UIStroke")
                    if stroke then stroke.Color = t.StrokeSoft end
                end,
                Set = function(value)
                    if currentValue == value then return end
                    currentValue = value
                    self.Window.Flags[flag] = currentValue
                    self.Window.Config[flag] = currentValue
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    button.Text = tostring(value)
                end,
                Value = function() return currentValue end
            }
            table.insert(self.Elements, el)
            return el
        end

        -- AddInput
        function section:Input(opt)
            opt = opt or {}
            local name     = opt.Name or "Input"
            local default  = opt.Default or "Text"
            local flag     = opt.Flag or ("TG_Input_" .. name)
            local callback = opt.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            
            local currentValue = self.Window.Config[flag]
            self.Window.Flags[flag] = currentValue

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 54,
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -90, 1, 0),
                ZIndex = 55,
            })
            label.Parent = row

            local input = Create("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 80, 1, 0),
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = tostring(currentValue),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                PlaceholderText = "",
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 55,
            })
            input.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, RADIUS - 2), Parent = input })

            local function UpdateValue()
                currentValue = input.Text
                self.Window.Flags[flag] = currentValue
                self.Window.Config[flag] = currentValue
                SaveConfig(self.Window.ConfigName, self.Window.Config)
                callback(currentValue)
            end

            input.FocusLost:Connect(function(enterPressed)
                UpdateValue()
            end)

            local el = {
                ApplyTheme = function(t) 
                    label.TextColor3 = t.Text 
                    input.BackgroundColor3 = t.ElementBg
                    input.TextColor3 = t.Text
                end,
                Set = function(value)
                    if currentValue == value then return end
                    currentValue = value
                    self.Window.Flags[flag] = currentValue
                    self.Window.Config[flag] = currentValue
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    input.Text = tostring(value)
                end,
                Value = function() return currentValue end
            }
            table.insert(self.Elements, el)
            return el
        end

        -- AddButton
        function section:Button(opt)
            opt = opt or {}
            local name     = opt.Name or "Button"
            local flag     = opt.Flag or ("TG_Button_" .. name) -- Not used for saving, just uniqueness
            local callback = opt.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                ZIndex = 54,
            })
            row.Parent = self.Content

            local button = Create("TextButton", {
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Text = name,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 55,
            })
            button.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, RADIUS - 2), Parent = button })

            button.MouseButton1Click:Connect(function()
                callback()
            end)

            local el = {
                ApplyTheme = function(t) 
                    button.BackgroundColor3 = t.Accent
                end
            }
            table.insert(self.Elements, el)
            return el
        end
        
        -- AddKeybind
        local function CreateKeybind(parent, defaultKey, onKeyChanged)
            local theme = Themes[tab.Window.ThemeName]
            local listening = false
            
            local keyFrame = Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 80, 1, 0),
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = defaultKey.Name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                ZIndex = 55,
            })
            keyFrame.Parent = parent
            Create("UICorner", { CornerRadius = UDim.new(0, RADIUS - 2), Parent = keyFrame })

            local conn
            
            local function endListening()
                if not listening then return end
                listening = false
                keyFrame.Text = defaultKey.Name
                keyFrame.TextColor3 = theme.Text
                if conn then conn:Disconnect() end
            end
            
            local function startListening()
                if listening then return end
                listening = true
                keyFrame.Text = "..."
                keyFrame.TextColor3 = theme.Accent
                
                conn = tab.Window.Gui.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= tab.Window.ToggleKey then
                        defaultKey = input.KeyCode
                        onKeyChanged(defaultKey)
                        endListening()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        -- Clicked somewhere else, stop listening
                        if input.Target ~= keyFrame then
                            endListening()
                        end
                    end
                end)
                
                task.delay(5, endListening) -- Timeout
            end

            keyFrame.MouseButton1Click:Connect(function()
                if listening then
                    endListening()
                else
                    startListening()
                end
            end)
            
            return keyFrame
        end
        
        function section:Keybind(opt)
            opt = opt or {}
            local name     = opt.Name or "Keybind"
            local default  = opt.Default or Enum.KeyCode.E
            local flag     = opt.Flag or ("TG_Key_" .. name)
            local callback = opt.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default.Name
            end
            
            local savedKey = Enum.KeyCode[self.Window.Config[flag]] or default
            self.Window.Flags[flag] = savedKey

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                ZIndex = 54,
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -70, 1, 0),
                ZIndex = 55,
            })
            label.Parent = row

            local keybind = CreateKeybind(row, savedKey, function(key)
                self.Window.Flags[flag] = key
                self.Window.Config[flag] = key.Name
                SaveConfig(self.Window.ConfigName, self.Window.Config)
                callback(key)
            end)

            local el = {
                ApplyTheme = function(t) 
                    label.TextColor3 = t.Text 
                    keybind.BackgroundColor3 = t.ElementBg
                    if keybind.Text ~= "..." then
                        keybind.TextColor3 = t.Text
                    else
                        keybind.TextColor3 = t.Accent
                    end
                end,
                Set = function(key)
                    if self.Window.Flags[flag] == key then return end
                    self.Window.Flags[flag] = key
                    self.Window.Config[flag] = key.Name
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    keybind.Text = key.Name
                end,
                Value = function() return self.Window.Flags[flag] end
            }
            table.insert(self.Elements, el)
            return el
        end

        table.insert(tab.Sections, section)
        return section
    end
    tab.Section = CreateSection
    
    -- Expose direct element creation methods on the tab, defaulting to an unnamed section
    local defaultSection = CreateSection({ Name = "Controls" })
    tab.Toggle = function(...) return defaultSection:Toggle(...) end
    tab.Slider = function(...) return defaultSection:Slider(...) end
    tab.Dropdown = function(...) return defaultSection:Dropdown(...) end
    tab.Input = function(...) return defaultSection:Input(...) end
    tab.Button = function(...) return defaultSection:Button(...) end
    tab.Keybind = function(...) return defaultSection:Keybind(...) end
    
    return tab
end
TakoGlass.Tab = TakoGlass.CreateTab


-- Aliases for convenience
function TakoGlass:Show()
    self:SetVisible(true)
end

function TakoGlass:Hide()
    self:SetVisible(false)
end

function TakoGlass.new(opts)
    return TakoGlass:CreateWindow(opts)
end

--------------------------------------------------
-- Return module
--------------------------------------------------
return TakoGlass
