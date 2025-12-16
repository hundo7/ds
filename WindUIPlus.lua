-- TakoGlass UI v4
-- Refined single-file UI library with:
--  - WindUI-ish glass cards
--  - Configurable blur and toggle key
--  - Fixed notifications, dropdowns, sliders, and themes
--  - Same high-level API as your original TakoGlass snippet

------------------------------
-- Services & client guard
------------------------------

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")
local Lighting           = game:GetService("Lighting")
local RunService         = game:GetService("RunService")

if not RunService:IsClient() then
    error("TakoGlass must be run on the client.")
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local function getPlayerGui()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    repeat
        task.wait()
        pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    until pg
    return pg
end

------------------------------
-- Root object
------------------------------

local TakoGlass = {}
TakoGlass.__index = TakoGlass

------------------------------
-- Config / Themes
------------------------------

local CONFIG_FOLDER  = "TakoGlassConfigs"
local DEFAULT_THEME  = "Dark"
local MAX_NOTIF      = 5
local CORNER_RADIUS  = 10

local Themes = {
    Dark = {
        Name        = "Dark",
        WindowBg    = Color3.fromRGB(16, 16, 24),
        WindowAlpha = 0.10,
        CardBg      = Color3.fromRGB(24, 24, 36),
        ElementBg   = Color3.fromRGB(32, 32, 48),
        SidebarBg   = Color3.fromRGB(14, 14, 20),

        Accent      = Color3.fromRGB(90, 135, 255),
        AccentSoft  = Color3.fromRGB(72, 110, 220),

        Text        = Color3.fromRGB(240, 240, 250),
        SubText     = Color3.fromRGB(155, 160, 185),

        StrokeSoft  = Color3.fromRGB(80, 80, 110),
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
        SubText     = Color3.fromRGB(100, 105, 140),

        StrokeSoft  = Color3.fromRGB(200, 205, 230),
    }
}

------------------------------
-- Small helpers
------------------------------

local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function Ease(obj, goal, t)
    if not obj then return end
    local info = TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(obj, info, goal):Play()
end

local function hasFileApi()
    return typeof(isfolder) == "function"
        and typeof(makefolder) == "function"
        and typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
end

local function ensureConfigFolder()
    if not hasFileApi() then return end
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function saveConfig(name, data)
    if not hasFileApi() then return end
    ensureConfigFolder()
    local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return end
    local path = ("%s/%s.json"):format(CONFIG_FOLDER, name)
    writefile(path, json)
end

local function loadConfig(name)
    if not hasFileApi() then return {} end
    ensureConfigFolder()
    local path = ("%s/%s.json"):format(CONFIG_FOLDER, name)
    if not isfile(path) then return {} end
    local ok, content = pcall(readfile, path)
    if not ok then return {} end
    local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, content)
    if not ok2 or type(decoded) ~= "table" then
        return {}
    end
    return decoded
end

------------------------------
-- Blur helper (1 per game)
------------------------------

local function getBlur()
    local blur = Lighting:FindFirstChild("TakoGlassBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "TakoGlassBlur"
        blur.Enabled = false
        blur.Size = 16
        blur.Parent = Lighting
    end
    return blur
end

------------------------------
-- Notification system
------------------------------

local function getNotifyGui()
    local pg = getPlayerGui()
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
    local gui = getNotifyGui()
    local holder = gui:FindFirstChild("Holder")
    local theme = Themes[DEFAULT_THEME]

    -- limit stack
    local existing = {}
    for _, child in ipairs(holder:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(existing, child)
        end
    end
    if #existing >= MAX_NOTIF then
        existing[1]:Destroy()
    end

    local card = Create("Frame", {
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = 100,
    })
    card.Parent = holder

    Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = card })
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
        ZIndex = 101,
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
        ZIndex = 101,
    })
    body.Parent = card

    -- compute bounds next frame without arbitrary magic delay
    task.defer(function()
        if not body or not body.Parent then return end
        local bounds = body.TextBounds
        local total = 18 + bounds.Y + 8
        body.Size = UDim2.new(1, 0, 0, bounds.Y)
        Ease(card, { Size = UDim2.new(1, 0, 0, total) }, 0.16)
    end)

    local alive = true
    local function close()
        if not alive or not card or not card.Parent then return end
        alive = false
        Ease(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.15)
        task.delay(0.17, function()
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

------------------------------
-- Window creation
------------------------------

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
    self.Config       = loadConfig(self.ConfigName)
    if self.Config.__Theme and Themes[self.Config.__Theme] then
        self.ThemeName = self.Config.__Theme
    end

    self.Tabs         = {}
    self.Elements     = {}
    self.ToggleKey    = Enum.KeyCode.RightShift
    self.IsOpen       = true
    self.IsMinimized  = false
    self._connections = {}

    local theme = Themes[self.ThemeName]
    local playerGui = getPlayerGui()

    -- Blur
    self.BlurObject = getBlur()
    self.BlurObject.Size = self.BlurSize
    self.BlurObject.Enabled = self.UseBlur

    -- ScreenGui
    local gui = Create("ScreenGui", {
        Name = "TakoGlass_" .. self.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    gui.Parent = playerGui
    self.Gui = gui

    -- Root window
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
    main.Parent = gui
    Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS + 4), Parent = main })
    Create("UIStroke", {
        Color = theme.StrokeSoft,
        Thickness = 1,
        Transparency = 0.3,
        Parent = main,
    })
    self.Main = main

    --------------------------
    -- Top bar + drag
    --------------------------

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

    local subLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = self.SubTitle,
        TextColor3 = theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.7, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 24),
    })
    subLabel.Parent = topBar

    self.TitleLabel   = titleLabel
    self.SubTitleLabel= subLabel

    -- minimize & close
    local minimizeButton = Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "-",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = theme.SubText,
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(1, -64, 0, 0),
    })
    minimizeButton.Parent = topBar

    local closeButton = Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = theme.SubText,
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(1, -32, 0, 0),
    })
    closeButton.Parent = topBar

    closeButton.MouseButton1Click:Connect(function()
        self.BlurObject.Enabled = false
        for _, conn in ipairs(self._connections) do
            conn:Disconnect()
        end
        gui:Destroy()
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        self.IsMinimized = not self.IsMinimized
        if self.IsMinimized then
            Ease(main, { Size = UDim2.new(0, self.Size.X.Offset, 0, 44) }, 0.16)
        else
            Ease(main, { Size = self.Size }, 0.16)
        end
    end)

    -- drag with clamp
    do
        local dragging = false
        local dragStart
        local startPos

        local function clampToViewport(pos)
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
            local halfX = self.Size.X.Offset / 2
            local halfY = self.Size.Y.Offset / 2
            local minX = -vp.X / 2 + halfX
            local maxX =  vp.X / 2 - halfX
            local minY = -vp.Y / 2 + halfY
            local maxY =  vp.Y / 2 - halfY

            local x = math.clamp(pos.X.Offset, minX, maxX)
            local y = math.clamp(pos.Y.Offset, minY, maxY)
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
                main.Position = clampToViewport(newPos)
            end
        end)
    end

    --------------------------
    -- Sidebar & content
    --------------------------

    local sidebar = Create("Frame", {
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, self.SidebarWidth, 1, -44),
    })
    sidebar.Parent = main
    Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = sidebar })
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

    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, self.SidebarWidth, 0, 44),
        Size = UDim2.new(1, -self.SidebarWidth, 1, -44),
    })
    content.Parent = main

    self.Sidebar = sidebar
    self.TabHolder = sidebar
    self.Content = content

    --------------------------
    -- Toggle key (debounced)
    --------------------------

    local lastToggle = 0
    local connToggle = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == self.ToggleKey then

            local now = tick()
            if now - lastToggle < 0.15 then return end
            lastToggle = now
            self:SetVisible(not self.IsOpen)
        end
    end)
    table.insert(self._connections, connToggle)

    self:SetTheme(self.ThemeName)

    return self
end

------------------------------
-- Window methods
------------------------------

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
    local blur = self.BlurObject or getBlur()
    self.BlurObject = blur
    blur.Size = self.BlurSize
    blur.Enabled = self.UseBlur and self.IsOpen
end

function TakoGlass:SetTheme(name)
    if not Themes[name] then return end
    self.ThemeName = name
    local theme = Themes[name]

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

    self.Config.__Theme = name
    saveConfig(self.ConfigName, self.Config)
end

------------------------------
-- Tabs / Sections / Elements
------------------------------

function TakoGlass:CreateTab(name)
    local theme = Themes[self.ThemeName]

    local button = Create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Text,
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
    Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = buttonBg })

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
        Sections = {},
    }

    function tab:SetActive()
        for _, other in ipairs(self.Window.Tabs) do
            other.Page.Visible = false
            Ease(other.ButtonBg, { BackgroundTransparency = 1 }, 0.12)
            Ease(other.Button, { TextColor3 = Themes[self.Window.ThemeName].Text }, 0.12)
        end
        self.Page.Visible = true
        Ease(self.ButtonBg, { BackgroundTransparency = 0, BackgroundColor3 = Themes[self.Window.ThemeName].ElementBg }, 0.12)
        Ease(self.Button, { TextColor3 = Themes[self.Window.ThemeName].Text }, 0.12)
    end

    function tab:ApplyTheme(theme)
        self.Button.TextColor3 = theme.Text
        self.ButtonBg.BackgroundColor3 = theme.SidebarBg
        for _, section in ipairs(self.Sections) do
            if section.ApplyTheme then
                section:ApplyTheme(theme)
            end
        end
    end

    button.MouseEnter:Connect(function()
        Ease(buttonBg, { BackgroundTransparency = 0.15 }, 0.1)
    end)
    button.MouseLeave:Connect(function()
        if not self.Page.Visible then
            Ease(buttonBg, { BackgroundTransparency = 1 }, 0.1)
        end
    end)
    button.MouseButton1Click:Connect(function()
        tab:SetActive()
    end)

    -- first tab is active by default
    if #self.Tabs == 0 then
        tab:SetActive()
    end

    table.insert(self.Tabs, tab)

    --------------------------
    -- Sections
    --------------------------

    function tab:CreateSection(title, description)
        local theme = Themes[self.Window.ThemeName]

        local card = Create("Frame", {
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 90),
        })
        card.Parent = self.Page
        Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = card })
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
            card.Size = UDim2.new(1, 0, 0, math.max(60, 50 + cLayout.AbsoluteContentSize.Y))
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

        ----------------------
        -- Toggle
        ----------------------

        function section:AddToggle(opt)
            opt = opt or {}
            local name = opt.Name or "Toggle"
            local flag = opt.Flag or ("TG_Toggle_" .. name)
            local default = opt.Default == nil and false or opt.Default
            local callback = opt.Callback or function() end

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
                Size = UDim2.new(0, 46, 0, 22),
                BackgroundColor3 = self.Window.Flags[flag] and theme.Accent or theme.ElementBg,
                BorderSizePixel = 0,
            })
            pill.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })

            local knob = Create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = self.Window.Flags[flag]
                    and UDim2.new(1, -20, 0.5, -9)
                    or  UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            knob.Parent = pill
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local function applyTheme(theme)
                label.TextColor3 = theme.Text
                pill.BackgroundColor3 = self.Window.Flags[flag] and theme.Accent or theme.ElementBg
            end

            local function setValue(v)
                if self.Window.Flags[flag] == v then return end
                self.Window.Flags[flag] = v
                self.Window.Config[flag] = v
                saveConfig(self.Window.ConfigName, self.Window.Config)

                Ease(pill, {
                    BackgroundColor3 = v and theme.Accent or theme.ElementBg
                }, 0.14)
                Ease(knob, {
                    Position = v
                        and UDim2.new(1, -20, 0.5, -9)
                        or  UDim2.new(0, 2, 0.5, -9)
                }, 0.14)

                callback(v)
            end

            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setValue(not self.Window.Flags[flag])
                end
            end)

            table.insert(self.Window.Elements, { ApplyTheme = applyTheme })

            return {
                Set = setValue,
                Get = function() return self.Window.Flags[flag] end,
            }
        end

        ----------------------
        -- Slider
        ----------------------

        function section:AddSlider(opt)
            opt = opt or {}
            local name    = opt.Name or "Slider"
            local min     = opt.Min or 0
            local max     = opt.Max or 100
            local default = opt.Default
            if default == nil then default = min end
            local step    = opt.Step or 1
            local flag    = opt.Flag or ("TG_Slider_" .. name)
            local callback= opt.Callback or function() end

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

            local function toAlpha(v)
                return (v - min) / (max - min)
            end

            local fill = Create("Frame", {
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new(toAlpha(self.Window.Flags[flag]), 0, 1, 0),
            })
            fill.Parent = bar
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })

            local dragging = false

            local function applyTheme(theme)
                label.TextColor3 = theme.Text
                valueLabel.TextColor3 = theme.SubText
                bar.BackgroundColor3 = theme.ElementBg
                fill.BackgroundColor3 = theme.Accent
            end

            local function setFromAlpha(alpha)
                alpha = math.clamp(alpha, 0, 1)
                local raw = min + (max - min) * alpha
                local stepped = math.floor((raw / step) + 0.5) * step
                stepped = math.clamp(stepped, min, max)

                if self.Window.Flags[flag] == stepped then return end

                self.Window.Flags[flag] = stepped
                self.Window.Config[flag] = stepped
                saveConfig(self.Window.ConfigName, self.Window.Config)

                fill.Size = UDim2.new(toAlpha(stepped), 0, 1, 0)
                valueLabel.Text = tostring(stepped)
                callback(stepped)
            end

            local connDrag = UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                    setFromAlpha(rel)
                end
            end)
            table.insert(self.Window._connections, connDrag)

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                    setFromAlpha(rel)
                end
            end)
            bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            table.insert(self.Window.Elements, { ApplyTheme = applyTheme })

            return {
                Set = function(v)
                    setFromAlpha(toAlpha(v))
                end
            }
        end

        ----------------------
        -- Dropdown
        ----------------------

        function section:AddDropdown(opt)
            opt = opt or {}
            local name     = opt.Name or "Dropdown"
            local list     = opt.Options or {}
            local default  = opt.Default or list[1]
            local flag     = opt.Flag or ("TG_Drop_" .. name)
            local callback = opt.Callback or function() end

            local theme = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil and default ~= nil then
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
                Text = tostring(self.Window.Flags[flag] or "None"),
                Font = Enum.Font.Gotham,
                TextColor3 = theme.Text,
                TextSize = 13,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.6, 0, 0, 24),
            })
            button.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = button })

            local listFrame = Create("Frame", {
                BackgroundColor3 = theme.CardBg,
                BorderSizePixel = 0,
                Visible = false,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 1, 2),
                Size = UDim2.new(0, 180, 0, 0),
            })
            listFrame.Parent = row
            Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = listFrame })
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
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, option in ipairs(list) do
                    local btn = Create("TextButton", {
                        BackgroundTransparency = 1,
                        Text = tostring(option),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        Size = UDim2.new(1, -6, 0, 22),
                    })
                    btn.Parent = scroll
                    btn.MouseButton1Click:Connect(function()
                        self.Window.Flags[flag] = option
                        self.Window.Config[flag] = option
                        saveConfig(self.Window.ConfigName, self.Window.Config)
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

            -- single outside-click closer per window
            if not self.Window._dropdownCloser then
                self.Window._dropdownCloser = UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    for _, t in ipairs(self.Window.Tabs) do
                        for _, sec in ipairs(t.Sections) do
                            local cf = sec.Content
                            for _, r in ipairs(cf:GetDescendants()) do
                                if r:IsA("Frame") and r.Name == "DropdownListFrame" then
                                    if not r.Visible then continue end
                                    local pos, size = r.AbsolutePosition, r.AbsoluteSize
                                    local p = input.Position
                                    local inside = p.X >= pos.X and p.X <= pos.X + size.X
                                        and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
                                    if not inside then
                                        r.Visible = false
                                    end
                                end
                            end
                        end
                    end
                end)
                table.insert(self.Window._connections, self.Window._dropdownCloser)
            end
            listFrame.Name = "DropdownListFrame"

            local function applyTheme(theme)
                label.TextColor3 = theme.Text
                button.BackgroundColor3 = theme.ElementBg
                button.TextColor3 = theme.Text
                listFrame.BackgroundColor3 = theme.CardBg
            end
            table.insert(self.Window.Elements, { ApplyTheme = applyTheme })

            return {
                Set = function(v)
                    self.Window.Flags[flag] = v
                    self.Window.Config[flag] = v
                    saveConfig(self.Window.ConfigName, self.Window.Config)
                    button.Text = tostring(v)
                    callback(v)
                end,
                Refresh = function(newList)
                    list = newList or {}
                    rebuild()
                end
            }
        end

        ----------------------
        -- Input
        ----------------------

        function section:AddInput(opt)
            opt = opt or {}
            local name        = opt.Name or "Input"
            local flag        = opt.Flag or ("TG_Input_" .. name)
            local default     = opt.Default or ""
            local placeholder = opt.Placeholder or ""
            local callback    = opt.Callback or function() end

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
            Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = box })

            local function applyTheme(theme)
                label.TextColor3 = theme.Text
                box.BackgroundColor3 = theme.ElementBg
                box.TextColor3 = theme.Text
            end
            table.insert(self.Window.Elements, { ApplyTheme = applyTheme })

            box.FocusLost:Connect(function(enter)
                local newText = box.Text
                if self.Window.Flags[flag] == newText then
                    callback(newText, enter)
                    return
                end
                self.Window.Flags[flag] = newText
                self.Window.Config[flag] = newText
                saveConfig(self.Window.ConfigName, self.Window.Config)
                callback(newText, enter)
            end)

            return {
                Set = function(v)
                    v = tostring(v)
                    self.Window.Flags[flag] = v
                    self.Window.Config[flag] = v
                    saveConfig(self.Window.ConfigName, self.Window.Config)
                    box.Text = v
                    callback(v, false)
                end
            }
        end

        ----------------------
        -- Button
        ----------------------

        function section:AddButton(opt)
            opt = opt or {}
            local text     = opt.Name or "Button"
            local callback = opt.Callback or function() end

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
            Create("UICorner", { CornerRadius = UDim.new(0, CORNER_RADIUS), Parent = btn })

            btn.MouseEnter:Connect(function()
                Ease(btn, { BackgroundColor3 = theme.AccentSoft }, 0.1)
            end)
            btn.MouseLeave:Connect(function()
                Ease(btn, { BackgroundColor3 = theme.ElementBg }, 0.1)
            end)
            btn.MouseButton1Click:Connect(function()
                callback()
            end)

            local function applyTheme(theme)
                btn.BackgroundColor3 = theme.ElementBg
                btn.TextColor3 = theme.Text
            end
            table.insert(self.Window.Elements, { ApplyTheme = applyTheme })

            return btn
        end

        table.insert(self.Sections, section)
        return section
    end

    return tab
end

return TakoGlass
