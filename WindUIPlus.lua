--[[

    TakoGlass UI (Refined Single-File Version)

    API (same as you requested):

        local TakoGlass = loadstring(game:HttpGet("..."))()

        local window = TakoGlass:CreateWindow({
            Title        = "Nexus Hub",
            SubTitle     = "by 16Takoo (fixed & fully restored)",
            ConfigName   = "MySuperHub",
            Theme        = "Dark",           -- "Dark" | "Light"
            Size         = UDim2.fromOffset(580, 460),
            SidebarWidth = 200,
            Transparent  = true,
            UseBlur      = false,
            BlurSize     = 18,
        })

        window:SetToggleKey(Enum.KeyCode.H)        -- to hide/show UI
        window:SetBlur(true, 18)                   -- enable / change blur at runtime
        window:SetTheme("Light")                   -- or "Dark"

        local tab = window:CreateTab("Main")
        local section = tab:CreateSection("Speed para 70","Da 70 de speed walkspeed")

        section:AddToggle({
            Name     = "Enable",
            Flag     = "SpeedEnable",
            Default  = false,
            Callback = function(value) end
        })

        section:AddSlider({
            Name     = "Speed",
            Min      = 0,
            Max      = 100,
            Default  = 70,
            Step     = 1,       -- optional (float allowed)
            Flag     = "SpeedValue",
            Callback = function(value) end
        })

        section:AddDropdown({
            Name     = "Mode",
            Options  = {"A","B","C"},
            Default  = "A",
            Flag     = "ModeFlag",
            Callback = function(value) end
        })

        section:AddInput({
            Name        = "Custom",
            Default     = "",
            Placeholder = "Type here",
            Flag        = "CustomInput",
            Callback    = function(text, enterPressed) end
        })

        section:AddButton({
            Name     = "Do Something",
            Callback = function() end
        })

        TakoGlass.Notify("Title","Message",4)

]]

-------------------------------------------------
-- Services
-------------------------------------------------

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer      = Players.LocalPlayer or Players.PlayerAdded:Wait()

-------------------------------------------------
-- Root table
-------------------------------------------------

local TakoGlass = {}
TakoGlass.__index = TakoGlass

-------------------------------------------------
-- Config
-------------------------------------------------

local CONFIG_FOLDER   = "TakoGlassConfigs"
local DEFAULT_THEME   = "Dark"
local NOTIFY_ZINDEX   = 100

local Themes = {
    Dark = {
        Name        = "Dark",
        WindowBg    = Color3.fromRGB(14, 14, 22),
        WindowAlpha = 0.12,
        CardBg      = Color3.fromRGB(24, 24, 36),
        ElementBg   = Color3.fromRGB(32, 32, 46),
        SidebarBg   = Color3.fromRGB(16, 16, 26),

        Accent      = Color3.fromRGB(102, 140, 255),
        AccentSoft  = Color3.fromRGB(72, 110, 220),

        Text        = Color3.fromRGB(240, 240, 250),
        SubText     = Color3.fromRGB(155, 160, 185),

        StrokeSoft  = Color3.fromRGB(70, 70, 95),
    },

    Light = {
        Name        = "Light",
        WindowBg    = Color3.fromRGB(245, 247, 255),
        WindowAlpha = 0.06,
        CardBg      = Color3.fromRGB(252, 252, 255),
        ElementBg   = Color3.fromRGB(238, 241, 255),
        SidebarBg   = Color3.fromRGB(234, 238, 255),

        Accent      = Color3.fromRGB(80, 130, 255),
        AccentSoft  = Color3.fromRGB(60, 105, 230),

        Text        = Color3.fromRGB(24, 26, 40),
        SubText     = Color3.fromRGB(105, 110, 140),

        StrokeSoft  = Color3.fromRGB(200, 205, 230),
    }
}

-------------------------------------------------
-- Helpers
-------------------------------------------------

local function Create(instanceType, properties)
    local obj = Instance.new(instanceType)
    for k, v in pairs(properties or {}) do
        obj[k] = v
    end
    return obj
end

local function Ease(instance, goalProps, duration)
    if not instance then return end
    local tweenInfo = TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(instance, tweenInfo, goalProps):Play()
end

local function EnsureConfigFolder()
    if not isfolder or not makefolder then return end
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function SaveConfig(configName, data)
    if not writefile then return end
    EnsureConfigFolder()
    local path = ("%s/%s.json"):format(CONFIG_FOLDER, configName)
    writefile(path, HttpService:JSONEncode(data))
end

local function LoadConfig(configName)
    if not readfile or not isfile then return {} end
    local path = ("%s/%s.json"):format(CONFIG_FOLDER, configName)
    if not isfile(path) then return {} end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(decoded) ~= "table" then
        return {}
    end
    return decoded
end

local function GetOrCreateBlur()
    local blur = Lighting:FindFirstChild("TakoGlassBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "TakoGlassBlur"
        blur.Enabled = false
        blur.Parent = Lighting
    end
    return blur
end

-------------------------------------------------
-- Notification system (instance-agnostic)
-------------------------------------------------

local function GetNotifyGui()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end

    local gui = playerGui:FindFirstChild("TakoGlass_Notify")
    if gui then return gui end

    gui = Create("ScreenGui", {
        Name = "TakoGlass_Notify",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    gui.Parent = playerGui

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
    local gui = GetNotifyGui()
    if not gui then return end

    local holder = gui:FindFirstChild("Holder")
    if not holder then return end

    local theme = Themes[DEFAULT_THEME]

    local card = Create("Frame", {
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = NOTIFY_ZINDEX,
    })
    card.Parent = holder

    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
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
        ZIndex = NOTIFY_ZINDEX + 1,
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
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = NOTIFY_ZINDEX + 1,
    })
    body.Parent = card

    -- Auto-height based on text bounds
    task.delay(0.03, function()
        local bounds = body.TextBounds
        local totalHeight = 18 + bounds.Y + 8
        Ease(card, { Size = UDim2.new(1, 0, 0, totalHeight) }, 0.18)
        body.Size = UDim2.new(1, 0, 0, bounds.Y)
    end)

    local alive = true
    local function close()
        if not alive then return end
        alive = false
        Ease(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.15)
        task.delay(0.18, function()
            if card then card:Destroy() end
        end)
    end

    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            close()
        end
    end)

    task.delay(duration or 4, close)
end

-------------------------------------------------
-- Window creation
-------------------------------------------------

function TakoGlass:CreateWindow(options)
    options = options or {}

    local self = setmetatable({}, TakoGlass)

    self.Title        = options.Title or "UI Title"
    self.SubTitle     = options.SubTitle or ""
    self.ConfigName   = options.ConfigName or self.Title
    self.ThemeName    = options.Theme or DEFAULT_THEME
    self.Size         = options.Size or UDim2.fromOffset(580, 460)
    self.SidebarWidth = options.SidebarWidth or 200
    self.Transparent  = (options.Transparent ~= nil) and options.Transparent or true

    self.UseBlur      = (options.UseBlur ~= nil) and options.UseBlur or false
    self.BlurSize     = options.BlurSize or 18

    self.Flags        = {}
    self.Config       = LoadConfig(self.ConfigName)
    if self.Config.__Theme and Themes[self.Config.__Theme] then
        self.ThemeName = self.Config.__Theme
    end

    self.Tabs         = {}
    self.Elements     = {}    -- flat list of elements for theme re‑apply
    self.ToggleKey    = Enum.KeyCode.RightShift
    self.IsOpen       = true
    self.IsMinimized  = false

    local theme = Themes[self.ThemeName]
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    assert(playerGui, "PlayerGui not found")

    -- Blur
    self.BlurObject = GetOrCreateBlur()
    self.BlurObject.Size = self.BlurSize
    self.BlurObject.Enabled = self.UseBlur

    -- ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "TakoGlass_" .. self.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    screenGui.Parent = playerGui
    self.Gui = screenGui

    -- Main window
    local main = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = self.Size,
        BackgroundColor3 = theme.WindowBg,
        BackgroundTransparency = self.Transparent and theme.WindowAlpha or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    main.Parent = screenGui
    Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = main })
    Create("UIStroke", {
        Color = theme.StrokeSoft,
        Thickness = 1,
        Transparency = 0.3,
        Parent = main,
    })
    self.Main = main

    -- Top bar
    local topBar = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
    })
    topBar.Parent = main

    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
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
    })
    titleLabel.Parent = topBar

    local subtitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = self.SubTitle,
        TextColor3 = theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.7, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 24),
    })
    subtitleLabel.Parent = topBar

    self.TitleLabel   = titleLabel
    self.SubTitleLabel= subtitleLabel

    -- Minimize + close
    local minimizeButton = Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "–",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = theme.SubText,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -64, 0, 0),
    })
    minimizeButton.Parent = topBar

    local closeButton = Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = theme.SubText,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -32, 0, 0),
    })
    closeButton.Parent = topBar

    closeButton.MouseButton1Click:Connect(function()
        self.BlurObject.Enabled = false
        screenGui:Destroy()
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        self.IsMinimized = not self.IsMinimized
        if self.IsMinimized then
            Ease(main, { Size = UDim2.new(0, self.Size.X.Offset, 0, 44) }, 0.16)
        else
            Ease(main, { Size = self.Size }, 0.16)
        end
    end)

    -- Dragging with simple bounds
    do
        local dragging = false
        local dragStart
        local startPos

        local function clampToScreen(pos)
            local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local x = math.clamp(pos.X.Offset, -viewport.X / 2, viewport.X / 2)
            local y = math.clamp(pos.Y.Offset, -viewport.Y / 2, viewport.Y / 2)
            return UDim2.new(0.5, x, 0.5, y)
        end

        topBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)

        topBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        topBar.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                local newPos = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
                main.Position = clampToScreen(newPos)
            end
        end)
    end

    -- Sidebar
    local sidebar = Create("Frame", {
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, self.SidebarWidth, 1, -44),
    })
    sidebar.Parent = main
    Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = sidebar })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebar,
    })
    local tabLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
    })
    tabLayout.Parent = sidebar

    -- Content area
    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, self.SidebarWidth, 0, 44),
        Size = UDim2.new(1, -self.SidebarWidth, 1, -44),
    })
    content.Parent = main

    self.Sidebar = sidebar
    self.TabHolder = sidebar
    self.Content = content

    -- Toggle key (global, but bound to this window)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.ToggleKey then
            self:SetVisible(not self.IsOpen)
        end
    end)

    self:SetTheme(self.ThemeName)

    return self
end

-------------------------------------------------
-- Window methods
-------------------------------------------------

function TakoGlass:SetVisible(visible)
    self.IsOpen = visible
    if self.Gui then
        self.Gui.Enabled = visible
    end
    if self.BlurObject then
        self.BlurObject.Enabled = visible and self.UseBlur or false
    end
end

function TakoGlass:SetToggleKey(keyCode)
    self.ToggleKey = keyCode
end

function TakoGlass:SetBlur(enabled, size)
    self.UseBlur = enabled and true or false
    if size then
        self.BlurSize = size
    end
    local blur = self.BlurObject or GetOrCreateBlur()
    self.BlurObject = blur
    blur.Size = self.BlurSize
    blur.Enabled = self.UseBlur and self.IsOpen
end

function TakoGlass:SetTheme(themeName)
    if not Themes[themeName] then return end
    self.ThemeName = themeName
    local theme = Themes[themeName]

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
    if self.Sidebar then self.Sidebar.BackgroundColor3 = theme.SidebarBg end

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

    self.Config.__Theme = themeName
    SaveConfig(self.ConfigName, self.Config)
end

-------------------------------------------------
-- Tabs / Sections / Elements
-------------------------------------------------

function TakoGlass:CreateTab(name)
    local theme = Themes[self.ThemeName]

    local button = Create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.SubText,
        Size = UDim2.new(1, -4, 0, 28),
    })
    button.Parent = self.TabHolder

    local buttonBg = Create("Frame", {
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    })
    buttonBg.Parent = button
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = buttonBg })

    local page = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        Visible = false,
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
        Window = self,
        Button = button,
        ButtonBg = buttonBg,
        Page = page,
        Sections = {}
    }

    function tab:SetActive()
        for _, other in ipairs(self.Window.Tabs) do
            other.Page.Visible = false
            Ease(other.ButtonBg, { BackgroundTransparency = 1 }, 0.15)
            Ease(other.Button, { TextColor3 = Themes[self.Window.ThemeName].SubText }, 0.15)
        end
        self.Page.Visible = true
        Ease(self.ButtonBg, { BackgroundTransparency = 0, BackgroundColor3 = Themes[self.Window.ThemeName].ElementBg }, 0.15)
        Ease(self.Button, { TextColor3 = Themes[self.Window.ThemeName].Text }, 0.15)
    end

    function tab:ApplyTheme(theme)
        self.Button.TextColor3 = theme.SubText
        self.ButtonBg.BackgroundColor3 = theme.SidebarBg
        for _, section in ipairs(self.Sections) do
            if section.ApplyTheme then
                section:ApplyTheme(theme)
            end
        end
    end

    -- Sections
    function tab:CreateSection(title, description)
        local theme = Themes[self.Window.ThemeName]

        local card = Create("Frame", {
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 90),
        })
        card.Parent = self.Page

        Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = card })
        local stroke = Create("UIStroke", {
            Color = theme.StrokeSoft,
            Thickness = 1,
            Transparency = 0.4,
        })
        stroke.Parent = card

        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            Parent = card,
        })

        local titleLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Text = title or "Section",
            TextColor3 = theme.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -80, 0, 20),
        })
        titleLabel.Parent = card

        local descLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = description or "",
            TextColor3 = theme.SubText,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, -80, 0, 18),
        })
        descLabel.Parent = card

        local content = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 44),
            Size = UDim2.new(1, 0, 0, 0),
        })
        content.Parent = card

        local cLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),
        })
        cLayout.Parent = content

        cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.Size = UDim2.new(1, 0, 0, cLayout.AbsoluteContentSize.Y)
            card.Size = UDim2.new(1, 0, 0, 50 + cLayout.AbsoluteContentSize.Y)
        end)

        local section = {
            Window  = self.Window,
            Tab     = self,
            Card    = card,
            Content = content,
        }

        function section:ApplyTheme(theme)
            card.BackgroundColor3 = theme.CardBg
            stroke.Color = theme.StrokeSoft
            titleLabel.TextColor3 = theme.Text
            descLabel.TextColor3 = theme.SubText
        end

        -------------------------------------------------
        -- Toggle
        -------------------------------------------------

        function section:AddToggle(opts)
            opts = opts or {}
            local name = opts.Name or "Toggle"
            local flag = opts.Flag or ("TG_Toggle_" .. name)
            local default = opts.Default or false
            local callback = opts.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -60, 1, 0),
            })
            label.Parent = row

            local pill = Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 42, 0, 20),
                BackgroundColor3 = self.Window.Flags[flag] and theme.Accent or theme.ElementBg,
                BorderSizePixel = 0,
            })
            pill.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })

            local knob = Create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = self.Window.Flags[flag] and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            knob.Parent = pill
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local function applyTheme(theme)
                pill.BackgroundColor3 = self.Window.Flags[flag] and theme.Accent or theme.ElementBg
                label.TextColor3 = theme.Text
            end

            local function setValue(value)
                self.Window.Flags[flag] = value
                self.Window.Config[flag] = value
                SaveConfig(self.Window.ConfigName, self.Window.Config)

                Ease(pill, {
                    BackgroundColor3 = value and theme.Accent or theme.ElementBg
                }, 0.16)
                Ease(knob, {
                    Position = value and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)
                }, 0.16)

                callback(value)
            end

            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setValue(not self.Window.Flags[flag])
                end
            end)

            local element = {
                ApplyTheme = applyTheme
            }
            table.insert(self.Window.Elements, element)

            return {
                Set = setValue,
                Get = function() return self.Window.Flags[flag] end
            }
        end

        -------------------------------------------------
        -- Slider
        -------------------------------------------------

        function section:AddSlider(opts)
            opts = opts or {}
            local name    = opts.Name or "Slider"
            local min     = opts.Min or 0
            local max     = opts.Max or 100
            local default = (opts.Default ~= nil) and opts.Default or min
            local step    = opts.Step or 1
            local flag    = opts.Flag or ("TG_Slider_" .. name)
            local callback = opts.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local frame = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
            })
            frame.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(0.6, 0, 0, 18),
            })
            label.Parent = frame

            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = tostring(self.Window.Flags[flag]),
                TextColor3 = theme.SubText,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0.4, 0, 0, 18),
            })
            valueLabel.Parent = frame

            local bar = Create("Frame", {
                BackgroundColor3 = theme.ElementBg,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 4),
                Position = UDim2.new(0, 0, 0, 22),
            })
            bar.Parent = frame
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = bar })

            local function valueToAlpha(v)
                return (v - min) / (max - min)
            end

            local fill = Create("Frame", {
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(valueToAlpha(self.Window.Flags[flag]), 0, 1, 0),
            })
            fill.Parent = bar
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })

            local dragging = false

            local function setValueFromAlpha(alpha)
                alpha = math.clamp(alpha, 0, 1)
                local raw = min + (max - min) * alpha
                local stepped = math.floor(raw / step + 0.5) * step
                stepped = math.clamp(stepped, min, max)

                self.Window.Flags[flag] = stepped
                self.Window.Config[flag] = stepped
                SaveConfig(self.Window.ConfigName, self.Window.Config)

                fill.Size = UDim2.new(valueToAlpha(stepped), 0, 1, 0)
                valueLabel.Text = tostring(stepped)
                callback(stepped)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setValueFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
                end
            end)
            bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setValueFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
                end
            end)

            local function applyTheme(theme)
                label.TextColor3 = theme.Text
                valueLabel.TextColor3 = theme.SubText
                bar.BackgroundColor3 = theme.ElementBg
                fill.BackgroundColor3 = theme.Accent
            end

            local element = { ApplyTheme = applyTheme }
            table.insert(self.Window.Elements, element)

            return {
                Set = function(v)
                    setValueFromAlpha(valueToAlpha(v))
                end
            }
        end

        -------------------------------------------------
        -- Dropdown
        -------------------------------------------------

        function section:AddDropdown(opts)
            opts = opts or {}
            local name     = opts.Name or "Dropdown"
            local list     = opts.Options or {}
            local default  = opts.Default or list[1]
            local flag     = opts.Flag or ("TG_Drop_" .. name)
            local callback = opts.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(0.4, 0, 1, 0),
            })
            label.Parent = row

            local button = Create("TextButton", {
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = tostring(self.Window.Flags[flag]),
                Font = Enum.Font.Gotham,
                TextColor3 = theme.Text,
                TextSize = 13,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.6, 0, 0, 24),
            })
            button.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })

            local listFrame = Create("Frame", {
                BackgroundColor3 = theme.CardBg,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 180, 0, 0),
                Visible = false,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 1, 2),
            })
            listFrame.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = listFrame })
            Create("UIStroke", {
                Color = theme.StrokeSoft,
                Thickness = 1,
                Transparency = 0.4,
                Parent = listFrame,
            })

            local scroll = Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
            })
            scroll.Parent = listFrame

            local lLayout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 2),
            })
            lLayout.Parent = scroll

            local function rebuild()
                for _, child in ipairs(scroll:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for _, option in ipairs(list) do
                    local optButton = Create("TextButton", {
                        BackgroundTransparency = 1,
                        Text = tostring(option),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        Size = UDim2.new(1, -6, 0, 22),
                    })
                    optButton.Parent = scroll

                    optButton.MouseButton1Click:Connect(function()
                        self.Window.Flags[flag] = option
                        self.Window.Config[flag] = option
                        SaveConfig(self.Window.ConfigName, self.Window.Config)
                        button.Text = tostring(option)
                        listFrame.Visible = false
                        callback(option)
                    end)
                end

                scroll.CanvasSize = UDim2.new(0, 0, 0, lLayout.AbsoluteContentSize.Y + 4)
                listFrame.Size = UDim2.new(0, 180, 0, math.min(lLayout.AbsoluteContentSize.Y + 4, 120))
            end

            lLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                scroll.CanvasSize = UDim2.new(0, 0, 0, lLayout.AbsoluteContentSize.Y + 4)
            end)

            rebuild()

            button.MouseButton1Click:Connect(function()
                listFrame.Visible = not listFrame.Visible
            end)

            -- close when clicking outside
            UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if listFrame.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local pos = input.Position
                    local absPos = listFrame.AbsolutePosition
                    local absSize = listFrame.AbsoluteSize
                    local inside = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
                        and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y

                    if not inside then
                        listFrame.Visible = false
                    end
                end
            end)

            local function applyTheme(theme)
                label.TextColor3 = theme.Text
                button.BackgroundColor3 = theme.ElementBg
                button.TextColor3 = theme.Text
                listFrame.BackgroundColor3 = theme.CardBg
            end

            local element = { ApplyTheme = applyTheme }
            table.insert(self.Window.Elements, element)

            return {
                Set = function(value)
                    self.Window.Flags[flag] = value
                    self.Window.Config[flag] = value
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    button.Text = tostring(value)
                    callback(value)
                end,
                Refresh = function(newOptions)
                    list = newOptions or {}
                    rebuild()
                end
            }
        end

        -------------------------------------------------
        -- Input
        -------------------------------------------------

        function section:AddInput(opts)
            opts = opts or {}
            local name        = opts.Name or "Input"
            local flag        = opts.Flag or ("TG_Input_" .. name)
            local default     = opts.Default or ""
            local placeholder = opts.Placeholder or ""
            local callback    = opts.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
            })
            row.Parent = self.Content

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(0.35, 0, 1, 0),
            })
            label.Parent = row

            local box = Create("TextBox", {
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = tostring(self.Window.Flags[flag]),
                PlaceholderText = placeholder,
                Font = Enum.Font.Gotham,
                TextColor3 = theme.Text,
                TextSize = 13,
                ClearTextOnFocus = false,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.65, 0, 0, 24),
            })
            box.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })

            box.FocusLost:Connect(function(enterPressed)
                self.Window.Flags[flag] = box.Text
                self.Window.Config[flag] = box.Text
                SaveConfig(self.Window.ConfigName, self.Window.Config)
                callback(box.Text, enterPressed)
            end)

            local function applyTheme(theme)
                label.TextColor3 = theme.Text
                box.BackgroundColor3 = theme.ElementBg
                box.TextColor3 = theme.Text
            end

            local element = { ApplyTheme = applyTheme }
            table.insert(self.Window.Elements, element)

            return {
                Set = function(value)
                    value = tostring(value)
                    self.Window.Flags[flag] = value
                    self.Window.Config[flag] = value
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    box.Text = value
                    callback(value, false)
                end
            }
        end

        -------------------------------------------------
        -- Button
        -------------------------------------------------

        function section:AddButton(opts)
            opts = opts or {}
            local text     = opts.Name or "Button"
            local callback = opts.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            local btn = Create("TextButton", {
                BackgroundColor3 = theme.ElementBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                Size = UDim2.new(1, 0, 0, 24),
            })
            btn.Parent = self.Content
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

            btn.MouseEnter:Connect(function()
                Ease(btn, { BackgroundColor3 = theme.AccentSoft }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                Ease(btn, { BackgroundColor3 = theme.ElementBg }, 0.12)
            end)
            btn.MouseButton1Click:Connect(function()
                callback()
            end)

            local function applyTheme(theme)
                btn.BackgroundColor3 = theme.ElementBg
                btn.TextColor3 = theme.Text
            end

            local element = { ApplyTheme = applyTheme }
            table.insert(self.Window.Elements, element)

            return btn
        end

        table.insert(self.Sections, section)
        return section
    end

    button.MouseButton1Click:Connect(function()
        tab:SetActive()
    end)

    if #self.Tabs == 0 then
        tab:SetActive()
    end

    table.insert(self.Tabs, tab)
    return tab
end

return TakoGlass
