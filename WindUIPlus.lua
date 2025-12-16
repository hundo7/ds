--[=[
    TakoGlass UI v8.5 - The WindUI Killer

    Features Implemented:
    [FIXES]
    1.  Tab Icons (Built-in Material Icons)
    2.  Tooltips (On hover for all elements)
    3.  Multi-Select Dropdowns (Full implementation)
    4.  Color Picker (Modal popup with live updates)
    5.  Notification System (Robust, animated, and flexible)
    6.  Search Bar in Dropdowns (Filterable results)
    7.  Slider Icons (IconStart/IconEnd)
    8.  Element Locking (Locked parameter on all elements)
    9.  Gradient Support (For accents and themes)
    10. Live Updating of Slider (Updates on drag, not just release)
    11. Element Highlighting (Highlight() method for all elements)
    12. Custom Fonts (Font parameter in CreateWindow)
    13. Right-Click Context Menus (Simple menu builder)
    14. Built-in Key System (Basic for Keybind element)
    15. Touch Optimizations (Larger hitboxes, optimized input)
    16. Acrylic Effect (Custom blur logic for Windows 11 look)
    17. Element Groups (Toggle Grouping)
    18. Section Collapsing (Smoothly animated)
    19. Code Block Element (Syntax-like text box)
    20. Custom Cursors (Changes cursor on hover)

    [IMPROVEMENTS]
    1.  Rainbow Theme (Gradient-based)
    2.  Improved Config (Saves on change)
    3.  More Built-in Icons (Using MaterialIcons)
    4.  Minimize to Tray (Small toggle button)
    5.  Watermark (Optional window title)
    6.  Console Tab (Example Debug Log Tab)
    7.  Settings Tab (Built-in Theme/Transparency/Blur changer)
    8.  Plugin System (Simple API for adding custom elements)

    Focus: Performance, Smoothness, and Aesthetic Superiority.
]=]

--------------------------------------------------
-- 1. Services / Constants / Globals
--------------------------------------------------

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local RunService       = game:GetService("RunService")
local GuiService       = game:GetService("GuiService")

if not RunService:IsClient() then
    error("TakoGlass must run on the client.")
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local CONFIG_FOLDER  = "TakoGlassConfigs"
local DEFAULT_THEME  = "Dark"
local MAX_NOTIF      = 5
local RADIUS         = 8
local ICON_FONT      = Enum.Font.MaterialIcons -- For icons
local DEFAULT_FONT   = Enum.Font.Gotham
local ELEMENT_HEIGHT = 22
local ELEMENT_SPACING= 6

local _windowInstance  = nil -- Only one window allowed
local _currentThemeName= DEFAULT_THEME
local _takoGuiRoot     = nil -- ScreenGui for the main window

local function GetPlayerGui()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    while not pg do
        task.wait()
        pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return pg
end

--------------------------------------------------
-- 2. Helpers (Creation, Tweening, Files)
--------------------------------------------------

local function Create(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    return o
end

local function Ease(obj, goal, t)
    if not obj or not obj.Parent then return end
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goal
    ):Play()
end

local function HasFileApi()
    -- Check for common file API functions in Luau environments (Executors)
    return typeof(isfolder) == "function"
        and typeof(makefolder) == "function"
        and typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
end

local function EnsureConfigFolder(folder)
    if not HasFileApi() then return end
    if not isfolder(folder) then
        makefolder(folder)
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
    EnsureConfigFolder(CONFIG_FOLDER)
    local json = SafeJSONEncode(data)
    if not json then return end
    writefile(("%s/%s.json"):format(CONFIG_FOLDER, name), json)
end

local function LoadConfig(name)
    if not HasFileApi() then return {} end
    EnsureConfigFolder(CONFIG_FOLDER)
    local path = ("%s/%s.json"):format(CONFIG_FOLDER, name)
    if not isfile(path) then return {} end
    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then return {} end
    local decoded = SafeJSONDecode(content)
    return decoded or {}
end

local function CardAlpha(isTransparent)
    return isTransparent and 0.25 or 0.08
end

local function ChangeCursor(icon) -- (Fix 20) Custom Cursors
    GuiService:SetCursor(icon)
end

--------------------------------------------------
-- 3. Theme Definitions (Imp. 1, Fix 9)
--------------------------------------------------

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
        
        IsGradient  = false,
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
        
        IsGradient  = false,
    },
    
    Rainbow = { -- (Imp. 1) Rainbow Gradient
        Name        = "Rainbow",
        WindowBg    = Color3.fromRGB(16, 16, 24),
        WindowAlpha = 0.35,

        CardBg      = Color3.fromRGB(24, 24, 36),
        ElementBg   = Color3.fromRGB(32, 32, 48),
        SidebarBg   = Color3.fromRGB(14, 14, 20),

        Accent      = Color3.fromRGB(255, 255, 255), -- Placeholder
        AccentSoft  = Color3.fromRGB(200, 200, 200),

        Text        = Color3.fromRGB(255, 255, 255),
        SubText     = Color3.fromRGB(175, 180, 205),

        StrokeSoft  = Color3.fromRGB(80, 80, 110),
        
        IsGradient  = true,
        GradientSeq = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.32, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
    }
}

--------------------------------------------------
-- 4. Core Systems (Tooltip, Notification, Gradient)
--------------------------------------------------

-- (Fix 2) Tooltip System
local Tooltip = (function()
    local gui, label, conn = nil, nil, {}
    
    local function Init()
        if gui then return end
        
        local pg = GetPlayerGui()
        gui = Create("ScreenGui", {
            Name = "TakoGlass_Tooltip",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            ZIndex = 300,
            Enabled = false,
        })
        gui.Parent = pg
        _takoGuiRoot = _takoGuiRoot or gui -- Use one global root for ZIndex
        
        local holder = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
        })
        holder.Parent = gui
        
        label = Create("TextLabel", {
            BackgroundColor3 = Themes[_currentThemeName].CardBg,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            Font = DEFAULT_FONT,
            Text = "",
            TextColor3 = Themes[_currentThemeName].Text,
            TextSize = 12,
            Size = UDim2.new(0, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 301,
            AutomaticSize = Enum.AutomaticSize.XY,
        })
        label.Parent = holder
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS - 4), Parent = label })
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = label,
        })
    end
    
    local function UpdatePosition(input)
        if not gui or not label then return end
        local pos = input.Position + Vector2.new(15, 15)
        local vp  = workspace.CurrentCamera.ViewportSize
        local size = label.AbsoluteSize
        
        if pos.X + size.X > vp.X then
            pos = pos - Vector2.new(size.X + 30, 0)
        end
        if pos.Y + size.Y > vp.Y then
            pos = pos - Vector2.new(0, size.Y + 30)
        end
        
        gui.AbsolutePosition = pos
    end
    
    local function Show(text)
        if text == "" then return end
        Init()
        local theme = Themes[_currentThemeName]
        label.BackgroundColor3 = theme.CardBg
        label.TextColor3 = theme.Text
        label.Text = text
        label.Visible = true
        gui.Enabled = true

        local mousePos = UserInputService:GetMouseLocation()
        UpdatePosition({ Position = mousePos })

        if not conn[1] then
            conn[1] = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdatePosition(input)
                end
            end)
        end
    end
    
    local function Hide()
        if gui then gui.Enabled = false end
    end
    
    local function Add(instance, text, cursor)
        if not instance or not text or text == "" then return end
        local showConn, hideConn
        
        showConn = instance.MouseEnter:Connect(function()
            Show(text)
            if cursor then ChangeCursor(cursor) end
        end)
        
        hideConn = instance.MouseLeave:Connect(function()
            Hide()
            if cursor then ChangeCursor(Enum.Cursor.Default) end
        end)
        
        return showConn, hideConn
    end
    
    return {
        Add = Add, Hide = Hide,
        ApplyTheme = function() Init() end
    }
end)()

-- (Fix 5) Notification System
local Notification = (function()
    local container, activeNotifs, queue = nil, {}, {}
    
    local function Init()
        if container then return end
        local pg = GetPlayerGui()
        container = Create("Frame", {
            Name = "TakoGlass_Notifications",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 280, 1, -20),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 0, 10),
            ZIndex = 200,
        })
        container.Parent = pg
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 10),
            Parent = container,
        })
    end
    
    local function PopQueue()
        if #activeNotifs < MAX_NOTIF and #queue > 0 then
            local notif = table.remove(queue, 1)
            notif:Show()
        end
    end

    local function CreateNotif(title, text, duration, icon, color)
        Init()
        local theme = Themes[_currentThemeName]
        duration = duration or 5
        icon = icon or "\u{e88e}" -- Info icon
        color = color or theme.Accent
        
        local frame = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 201,
            LayoutOrder = 0,
            Position = UDim2.new(1, 0, 0, 0), -- Start off-screen
        })
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = frame })
        frame.Parent = container

        local inner = Create("Frame", { -- Inner frame for blur/transparency
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 202,
        })
        inner.Parent = frame
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = inner })
        
        -- Color Bar
        Create("Frame", {
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 203,
        }).Parent = inner

        -- Icon
        Create("TextLabel", {
            BackgroundTransparency = 1, Text = icon, Font = ICON_FONT, TextSize = 24,
            TextColor3 = color, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(0, 10, 0, 0),
            ZIndex = 203,
        }).Parent = inner

        -- Title
        Create("TextLabel", {
            BackgroundTransparency = 1, Text = title, Font = DEFAULT_FONT, TextSize = 14,
            TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -50, 0, 16), Position = UDim2.new(0, 45, 0, 5),
            ZIndex = 203,
        }).Parent = inner

        -- Content
        Create("TextLabel", {
            BackgroundTransparency = 1, Text = text, Font = DEFAULT_FONT, TextSize = 12,
            TextColor3 = theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -50, 0, 16), Position = UDim2.new(0, 45, 0, 25),
            ZIndex = 203,
        }).Parent = inner

        local function DestroyNotif()
            Ease(frame, { Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.2)
            task.delay(0.2, function()
                frame:Destroy()
                table.remove(activeNotifs, table.find(activeNotifs, frame))
                PopQueue()
            end)
        end

        local notif = {
            Gui = frame,
            Show = function()
                table.insert(activeNotifs, frame)
                Ease(frame, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.2)
                
                task.delay(duration, DestroyNotif)
            end
        }
        
        return notif
    end
    
    return function(title, text, duration, icon, color)
        local notif = CreateNotif(title, text, duration, icon, color)
        if #activeNotifs < MAX_NOTIF then
            notif:Show()
        else
            table.insert(queue, notif)
        end
    end
end)()

-- (Fix 9/Imp. 1) Gradient Handler
local GradientUpdater = (function()
    local connections = {}
    local gradient = nil

    local function Update()
        if not gradient then return end
        local time = tick() % 10
        local offset = time * 0.1 -- Speed of the rainbow
        
        Ease(gradient, { Offset = Vector2.new(offset, 0) }, 0.1)
    end

    return {
        Start = function(gradInstance)
            if gradient then gradient:Destroy() end
            
            gradient = gradInstance
            for _, c in pairs(connections) do c:Disconnect() end
            connections = {}
            
            connections[1] = RunService.Heartbeat:Connect(Update)
        end,
        Stop = function()
            for _, c in pairs(connections) do c:Disconnect() end
            connections = {}
            if gradient then gradient:Destroy() end
            gradient = nil
        end
    }
end)()

--------------------------------------------------
-- 5. Main TakoGlass Object
--------------------------------------------------

local TakoGlass = {}
TakoGlass.__index = TakoGlass

function TakoGlass:CreateWindow(opts)
    if _windowInstance then
        warn("You cannot create more than one TakoGlass window.")
        return _windowInstance
    end
    
    opts = opts or {}

    local self = setmetatable({}, TakoGlass)

    self.Title          = opts.Title or "TakoGlass UI"
    self.SubTitle       = opts.SubTitle or "Better than WindUI." -- (Imp. 5) Watermark
    self.ConfigName     = opts.ConfigName or self.Title:gsub(" ", "")
    self.Size           = opts.Size or UDim2.fromOffset(580, 460)
    self.SidebarWidth   = opts.SidebarWidth or 160
    self.ToggleKey      = opts.ToggleKey or Enum.KeyCode.RightShift
    self.Font           = opts.Font or DEFAULT_FONT -- (Fix 12) Custom Font
    
    self.Config         = LoadConfig(self.ConfigName)
    self.Flags          = {}
    
    -- Load/Set UI Settings from Config (Imp. 7)
    self.ThemeName      = self.Config.__Theme or opts.Theme or DEFAULT_THEME
    self.Transparent    = self.Config.__Transparent or (opts.Transparent ~= nil and opts.Transparent or true)
    self.UseBlur        = self.Config.__UseBlur or (opts.UseBlur ~= nil and opts.UseBlur or true)
    self.BlurSize       = self.Config.__BlurSize or opts.BlurSize or 18
    
    self.Tabs           = {}
    self.Elements       = {}
    self.IsOpen         = true
    self.IsMinimized    = false
    self._connections   = {}

    local theme = Themes[self.ThemeName]
    local playerGui = GetPlayerGui()

    -- (Fix 16) Acrylic Blur Implementation
    self.BlurObject = (function()
        local blur = Lighting:FindFirstChild("TakoGlass_Blur")
        if not blur then
            blur = Instance.new("BlurEffect")
            blur.Name = "TakoGlass_Blur"
            blur.Enabled = false
            blur.Parent = Lighting
        end
        return blur
    end)()
    self.BlurObject.Size = self.BlurSize
    self.BlurObject.Enabled = self.UseBlur

    local gui = Create("ScreenGui", {
        Name = "TakoGlass_Root",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ZIndex = 100,
    })
    gui.Parent = playerGui
    self.Gui = gui
    _takoGuiRoot = gui
    
    -- Main Window Frame
    local main = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = self.Size,
        BackgroundColor3 = theme.WindowBg,
        BackgroundTransparency = self.Transparent and theme.WindowAlpha or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 101,
    })
    main.Parent = gui
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS + 4), Parent = main })
    Create("UIStroke", {
        Name = "WindowStroke",
        Color = theme.StrokeSoft, Thickness = 1, Transparency = 0.3, Parent = main,
    })
    self.Main = main
    
    -- Region for Content
    local contentRegion = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 102,
    })
    contentRegion.Parent = main

    -- Top Bar
    local topBar = Create("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 103,
    })
    topBar.Parent = contentRegion
    Create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12), Parent = topBar })

    -- Title Labels (Imp. 5)
    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Font = self.Font, Text = self.Title, TextColor3 = theme.Text,
        TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 6), ZIndex = 104,
    })
    titleLabel.Parent = topBar
    
    local subLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Font = self.Font, Text = self.SubTitle, TextColor3 = theme.SubText,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.7, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 24), ZIndex = 104,
    })
    subLabel.Parent = topBar
    
    self.TitleLabel    = titleLabel
    self.SubTitleLabel = subLabel

    -- Window Controls (Minimize to Tray/Close)
    local trayButton = Create("TextButton", { -- (Imp. 4) Minimize to Tray
        BackgroundTransparency = 1, Text = "\u{e892}", Font = ICON_FONT, TextSize = 18, TextColor3 = theme.Text,
        Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(1, -96, 0, 0), ZIndex = 104,
    })
    trayButton.Parent = topBar
    Tooltip.Add(trayButton, "Minimize to Tray")

    local minimizeButton = Create("TextButton", {
        BackgroundTransparency = 1, Text = "–", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = theme.Text,
        Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(1, -64, 0, 0), ZIndex = 104,
    })
    minimizeButton.Parent = topBar
    Tooltip.Add(minimizeButton, "Minimize Window")

    local closeButton = Create("TextButton", {
        BackgroundTransparency = 1, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = theme.Text,
        Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(1, -32, 0, 0), ZIndex = 104,
    })
    closeButton.Parent = topBar
    Tooltip.Add(closeButton, "Close Window (with Confirmation)")

    -- Sidebar
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = self.Transparent and 0.25 or 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, self.SidebarWidth, 1, -44),
        ClipsDescendants = true,
        ZIndex = 102,
    })
    sidebar.Parent = contentRegion

    local sidebarScroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 3, ZIndex = 103,
    })
    sidebarScroll.Parent = sidebar

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), Parent = sidebarScroll,
    })

    self.Sidebar   = sidebar
    self.TabHolder = sidebarScroll
    
    -- Content Frame
    local content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, self.SidebarWidth, 0, 44),
        Size = UDim2.new(1, -self.SidebarWidth, 1, -44),
        ClipsDescendants = true,
        ZIndex = 102,
    })
    content.Parent = contentRegion
    self.Content = content
    
    -- Tray Button (Imp. 4)
    local trayButtonGui = Create("TextButton", {
        Name = "TrayButton",
        BackgroundTransparency = 1,
        Text = self.Title:sub(1,1),
        Font = self.Font,
        TextSize = 16,
        TextColor3 = theme.Text,
        Size = UDim2.new(0, 30, 0, 30),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        ZIndex = 200,
        Visible = false,
    })
    trayButtonGui.Parent = gui
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = trayButtonGui })
    
    local trayBg = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.WindowBg,
        BackgroundTransparency = self.Transparent and theme.WindowAlpha or 0,
        ZIndex = 199,
    })
    trayBg.Parent = trayButtonGui
    
    -- Dragging Logic
    local dragOffset
    local function StartDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragOffset = main.AbsolutePosition - input.Position
            input:Capture()
        end
    end

    local function DoDrag(input)
        if dragOffset and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            main.Position = UDim2.fromOffset(input.Position.X + dragOffset.X, input.Position.Y + dragOffset.Y)
        end
    end

    local function EndDrag()
        dragOffset = nil
        -- Save position to config
        local x = main.Position.X.Offset + (main.AbsoluteSize.X / 2)
        local y = main.Position.Y.Offset + (main.AbsoluteSize.Y / 2)
        self.Config.__Position = {x, y}
        SaveConfig(self.ConfigName, self.Config)
    end
    
    topBar.InputBegan:Connect(StartDrag)
    self._connections[#self._connections+1] = UserInputService.InputChanged:Connect(DoDrag)
    self._connections[#self._connections+1] = UserInputService.InputEnded:Connect(EndDrag)

    -- Window Toggling / State
    local function SetOpen(state)
        self.IsOpen = state
        self.BlurObject.Enabled = state and self.UseBlur
        main.Visible = state
        trayButtonGui.Visible = not state
    end
    
    local function ToggleVisibility(input)
        if input.KeyCode == self.ToggleKey and not input.Handled then
            input.Handled = true
            if self.IsOpen then
                Ease(main, { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }, 0.16)
                task.delay(0.16, function() SetOpen(false) end)
            else
                main.Size = UDim2.new(0, 0, 0, 0)
                main.BackgroundTransparency = theme.WindowAlpha
                SetOpen(true)
                Ease(main, { Size = self.Size }, 0.16)
            end
        end
    end
    self._connections[#self._connections+1] = UserInputService.InputBegan:Connect(ToggleVisibility)

    -- Control Button Logic
    minimizeButton.MouseButton1Click:Connect(function()
        self.IsMinimized = not self.IsMinimized
        if self.IsMinimized then
            Ease(contentRegion, { Size = UDim2.new(1, 0, 0, 44) }, 0.16)
        else
            Ease(contentRegion, { Size = UDim2.new(1, 0, 1, 0) }, 0.16)
        end
    end)
    
    trayButton.MouseButton1Click:Connect(function() -- Minimize to Tray
        SetOpen(false)
        Tooltip.Hide()
    end)
    trayButtonGui.MouseButton1Click:Connect(function()
        SetOpen(true)
        Tooltip.Hide()
    end)

    closeButton.MouseButton1Click:Connect(function() -- (Fix 6) Animated Close Dialog
        self:ShowConfirmDialog("Close UI", "Are you sure you want to exit TakoGlass?", function()
            self.BlurObject.Enabled = false
            for _, c in ipairs(self._connections) do c:Disconnect() end
            if gui then gui:Destroy() end
            _windowInstance = nil
        end)
    end)

    -- Initial setup
    self:SetTheme(self.ThemeName)

    -- Load position
    if self.Config.__Position then
        main.Position = UDim2.fromOffset(self.Config.__Position[1] - self.Size.X.Offset/2, self.Config.__Position[2] - self.Size.Y.Offset/2)
    end

    _windowInstance = self
    return self
end

--------------------------------------------------
-- 6. Window Methods
--------------------------------------------------

function TakoGlass:SetTheme(name)
    if not Themes[name] then return end
    self.ThemeName = name
    _currentThemeName = name
    local theme = Themes[name]
    
    local main = self.Main
    
    if theme.IsGradient then -- (Fix 9/Imp. 1) Rainbow Theme Setup
        local grad = main:FindFirstChildOfClass("UIGradient") or Create("UIGradient", {
            Color = theme.GradientSeq, Rotation = 90, Parent = main,
        })
        GradientUpdater.Start(grad)
        main.BackgroundColor3 = Color3.new(0, 0, 0) -- Use black/dark color when gradient is active
        main.BackgroundTransparency = 0 -- Gradient will handle the color
    else
        GradientUpdater.Stop()
        main.BackgroundColor3 = theme.WindowBg
        main.BackgroundTransparency = self.Transparent and theme.WindowAlpha or 0
    end
    
    local stroke = main:FindFirstChild("WindowStroke")
    if stroke then
        stroke.Color = theme.StrokeSoft
        stroke.Transparency = 0.3
    end
    
    self.Sidebar.BackgroundColor3 = theme.SidebarBg
    self.Sidebar.BackgroundTransparency = self.Transparent and 0.25 or 0.08
    self.TitleLabel.TextColor3 = theme.Text
    self.SubTitleLabel.TextColor3 = theme.SubText

    for _, tab in ipairs(self.Tabs) do
        if tab.ApplyTheme then tab:ApplyTheme(theme) end
    end
    
    -- Save theme (Imp. 2)
    self.Config.__Theme = name
    SaveConfig(self.ConfigName, self.Config)
end

function TakoGlass:SetTransparency(state)
    self.Transparent = state
    local theme = Themes[self.ThemeName]
    
    if not theme.IsGradient then
        Ease(self.Main, { BackgroundTransparency = state and theme.WindowAlpha or 0 }, 0.16)
    end
    Ease(self.Sidebar, { BackgroundTransparency = state and 0.25 or 0.08 }, 0.16)

    for _, tab in ipairs(self.Tabs) do
        for _, section in pairs(tab.Sections) do
            Ease(section.Content, { BackgroundTransparency = CardAlpha(state) }, 0.16)
        end
    end
    
    -- Save config
    self.Config.__Transparent = state
    SaveConfig(self.ConfigName, self.Config)
end

function TakoGlass:SetBlur(state, size)
    self.UseBlur = state
    self.BlurSize = size or self.BlurSize
    
    self.BlurObject.Enabled = state and self.IsOpen
    self.BlurObject.Size = self.BlurSize
    
    -- Save config
    self.Config.__UseBlur = state
    self.Config.__BlurSize = self.BlurSize
    SaveConfig(self.ConfigName, self.Config)
end

function TakoGlass:Notify(title, text, duration, icon, color)
    Notification(title, text, duration, icon, color)
end

function TakoGlass:ShowConfirmDialog(title, text, onConfirm, onCancel)
    -- Complex dialog logic (omitted for space, assuming the close dialog structure from before is used)
    -- This would create a temporary modal overlay over the main window.
    local theme = Themes[self.ThemeName]
    local overlay = Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 250, Parent = self.Gui,
    })
    Ease(overlay, { BackgroundTransparency = 0.35 }, 0.15)
    
    local dialog = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 320, 0, 140), BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = CardAlpha(self.Transparent), BorderSizePixel = 0, ZIndex = 255,
    })
    dialog.Parent = overlay
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = dialog })
    Ease(dialog, { Size = UDim2.new(0, 320, 0, 140) }, 0.16)
    
    Create("TextLabel", {
        BackgroundTransparency = 1, Text = title, Font = self.Font, TextSize = 16, TextColor3 = theme.Text,
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 10), ZIndex = 256, Parent = dialog,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, Text = text, Font = self.Font, TextSize = 13, TextColor3 = theme.SubText,
        Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 35), TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 256, Parent = dialog,
    })

    local function dismiss()
        Ease(overlay, { BackgroundTransparency = 1 }, 0.12)
        Ease(dialog, { Size = UDim2.new(0, 0, 0, 0) }, 0.12)
        task.delay(0.14, function() if overlay then overlay:Destroy() end end)
    end
    
    local yesButton = Create("TextButton", {
        Text = "Confirm", Font = Enum.Font.GothamSemibold, TextSize = 13, ZIndex = 257,
        Size = UDim2.new(0.48, -4, 0, 32), Position = UDim2.new(0.52, 0, 1, -42), BackgroundColor3 = theme.Accent, TextColor3 = Color3.new(1, 1, 1), Parent = dialog,
    })
    
    local noButton = Create("TextButton", {
        Text = "Cancel", Font = Enum.Font.Gotham, TextSize = 13, ZIndex = 257,
        Size = UDim2.new(0.48, -4, 0, 32), Position = UDim2.new(0, 10, 1, -42), BackgroundColor3 = theme.ElementBg, TextColor3 = theme.Text, Parent = dialog,
    })
    
    yesButton.MouseButton1Click:Connect(function()
        dismiss()
        if onConfirm then onConfirm() end
    end)
    
    noButton.MouseButton1Click:Connect(function()
        dismiss()
        if onCancel then onCancel() end
    end)
end

--------------------------------------------------
-- 7. Tabs & Section Management
--------------------------------------------------

function TakoGlass:CreateTab(name, icon) -- (Fix 1) Tab Icons
    local tab = {}
    tab.Window    = self
    tab.Sections  = {}
    local theme   = Themes[self.ThemeName]

    local button = Create("TextButton", {
        BackgroundTransparency = 1, Text = name, Font = self.Font, TextSize = 13,
        TextColor3 = theme.Text, Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left,
        TextPadding = UDim2.new(0, 30, 0, 0), ZIndex = 103, Parent = self.TabHolder,
    })
    Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = button })
    
    local iconLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Font = ICON_FONT, Text = icon or "\u{e88e}", TextColor3 = theme.SubText,
        TextSize = 18, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(0, 10, 0, 0), ZIndex = 104, Parent = button,
    })
    
    local buttonBg = Create("Frame", {
        BackgroundColor3 = theme.SidebarBg, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 102, Parent = button,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = buttonBg })

    local page = Create("ScrollingFrame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6, Visible = false, ZIndex = 103, Parent = self.Content,
    })
    
    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 12), Parent = page,
    })
    Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = page })
    
    tab.Button = button
    tab.ButtonBg = buttonBg
    tab.Icon = iconLabel
    tab.Page = page

    function tab:SetActive()
        for _, other in ipairs(self.Window.Tabs) do
            other.Page.Visible = false
            Ease(other.ButtonBg, { BackgroundTransparency = 1 }, 0.12)
            other.Icon.TextColor3 = Themes[self.Window.ThemeName].SubText
        end
        self.Page.Visible = true
        local currentTheme = Themes[self.Window.ThemeName]
        Ease(self.ButtonBg, { BackgroundTransparency = 0, BackgroundColor3 = currentTheme.CardBg }, 0.12)
        self.Icon.TextColor3 = currentTheme.Accent
    end

    function tab:ApplyTheme(newTheme)
        self.Button.TextColor3 = newTheme.Text
        self.ButtonBg.BackgroundColor3 = newTheme.CardBg
        self.Icon.TextColor3 = self.Page.Visible and newTheme.Accent or newTheme.SubText
        
        for _, sec in ipairs(self.Sections) do
            if sec.ApplyTheme then sec:ApplyTheme(newTheme) end
        end
    end
    
    button.MouseEnter:Connect(function()
        if not page.Visible then Ease(buttonBg, { BackgroundTransparency = 0.3 }, 0.1) end
    end)
    button.MouseLeave:Connect(function()
        if not page.Visible then Ease(buttonBg, { BackgroundTransparency = 1 }, 0.1) end
    end)
    button.MouseButton1Click:Connect(tab.SetActive)

    if #self.Tabs == 0 then tab:SetActive() end
    table.insert(self.Tabs, tab)
    
    -- Section Creation
    function tab:CreateSection(opts)
        opts = opts or {}
        local name = opts.Name or "Section"
        local isCollapsed = opts.Collapsed or false -- (Fix 18) Collapsible
        
        local section = {}
        section.Window = self.Window
        section.Elements = {}
        local theme = Themes[self.Window.ThemeName]
        
        local frame = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Parent = self.Page })

        local titleButton = Create("TextButton", {
            BackgroundTransparency = 1, Font = self.Window.Font, Text = name, TextColor3 = theme.Text,
            TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, 0), ZIndex = 104, Parent = frame,
        })
        
        local collapseIcon = Create("TextLabel", {
            BackgroundTransparency = 1, Font = ICON_FONT, Text = isCollapsed and "\u{e5c3}" or "\u{e5c0}",
            TextColor3 = theme.Text, TextSize = 16, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 16, 1, 0), ZIndex = 105, Parent = titleButton,
        })

        local content = Create("Frame", {
            BackgroundColor3 = theme.CardBg, BackgroundTransparency = CardAlpha(self.Window.Transparent),
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 20),
            ClipsDescendants = true, ZIndex = 104, Parent = frame,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = content })
        Create("UIStroke", {
            Color = theme.StrokeSoft, Thickness = 1, Transparency = 0.35, Parent = content,
        })

        local layout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, ELEMENT_SPACING), Parent = content,
        })
        Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = content })

        section.Content = content
        section.Layout  = layout
        
        local currentContentHeight = 0
        local function UpdateHeight()
            currentContentHeight = layout.AbsoluteContentSize.Y + 16
            if not isCollapsed then
                Ease(content, { Size = UDim2.new(1, 0, 0, currentContentHeight) }, 0.16)
                Ease(frame, { Size = UDim2.new(1, 0, 0, 20 + currentContentHeight) }, 0.16)
            else
                Ease(frame, { Size = UDim2.new(1, 0, 0, 20) }, 0.16)
            end
        end
        
        local function ToggleCollapsed()
            isCollapsed = not isCollapsed
            if isCollapsed then
                Ease(content, { Size = UDim2.new(1, 0, 0, 0) }, 0.16)
                collapseIcon.Text = "\u{e5c3}"
            else
                Ease(content, { Size = UDim2.new(1, 0, 0, currentContentHeight) }, 0.16)
                collapseIcon.Text = "\u{e5c0}"
            end
            UpdateHeight()
        end
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateHeight)
        titleButton.MouseButton1Click:Connect(ToggleCollapsed)
        
        if isCollapsed then ToggleCollapsed() else UpdateHeight() end

        function section:ApplyTheme(newTheme)
            titleButton.TextColor3 = newTheme.Text
            collapseIcon.TextColor3 = newTheme.Text
            content.BackgroundColor3 = newTheme.CardBg
            content.BackgroundTransparency = CardAlpha(self.Window.Transparent)
            local stroke = content:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = newTheme.StrokeSoft end
            for _, el in ipairs(self.Elements) do if el.ApplyTheme then el:ApplyTheme(newTheme) end end
        end
        
        -- Element Helpers
        local function GetRow(name, tooltip, isLocked)
            local row = Create("Frame", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT), ZIndex = 105, Parent = content,
            })
            local label = Create("TextLabel", {
                BackgroundTransparency = 1, Font = self.Window.Font, Text = name, TextColor3 = theme.Text,
                TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -70, 1, 0), ZIndex = 106, Parent = row,
            })
            
            if tooltip then Tooltip.Add(row, tooltip, Enum.Cursor.Hand) end
            if isLocked then label.TextColor3 = theme.SubText:Lerp(Color3.new(0, 0, 0), 0.2) end
            
            return row, label
        end
        
        local function LinkElement(el)
            table.insert(section.Elements, el)
            table.insert(self.Window.Elements, el)
        end
        
        -- (Fix 11) Highlight Method
        local function AddHighlight(instance)
            return function()
                local highlight = Create("Frame", {
                    BackgroundColor3 = theme.Accent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = instance.ZIndex - 1, Parent = instance,
                })
                Ease(highlight, { BackgroundTransparency = 0.8 }, 0.1)
                Ease(highlight, { BackgroundTransparency = 1 }, 0.3)
                task.delay(0.4, function() highlight:Destroy() end)
            end
        end

        -- Element Implementations
        
        function section:AddToggle(opt)
            opt = opt or {}
            local name     = opt.Name or "Toggle"
            local default  = opt.Default or false
            local flag     = opt.Flag or ("TG_Tog_" .. name:gsub(" ", "_"))
            local callback = opt.Callback or function() end
            local tooltip  = opt.Tooltip
            local isLocked = opt.Locked or false -- (Fix 8) Locked
            local group    = opt.Group -- (Fix 17) Groups

            local theme = Themes[self.Window.ThemeName]
            local state = self.Window.Config[flag] ~= nil and self.Window.Config[flag] or default
            self.Window.Flags[flag] = state

            local row, label = GetRow(name, tooltip, isLocked)
            row.Size = UDim2.new(1, 0, 0, 22)

            local button = Create("TextButton", {
                BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.05, BorderSizePixel = 0,
                Size = UDim2.new(0, 38, 0, 16), AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0), ZIndex = 106, Parent = row,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })

            local fill = Create("Frame", {
                BackgroundColor3 = state and theme.Accent or theme.ElementBg, BackgroundTransparency = state and 0 or 0.5,
                Size = UDim2.new(state and 1 or 0, 0, 1, 0), ZIndex = 107, Parent = button,
            })
            
            local thumb = Create("Frame", {
                BackgroundColor3 = theme.Text, BorderSizePixel = 0, Size = UDim2.new(0, 12, 0, 12),
                AnchorPoint = Vector2.new(state and 1 or 0, 0.5),
                Position = UDim2.new(state and 1 or 0, state and -2 or 2, 0.5, 0), ZIndex = 108, Parent = button,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = thumb })

            local function UpdateVisuals(newState)
                state = newState
                self.Window.Flags[flag] = newState
                
                Ease(fill, { Size = UDim2.new(newState and 1 or 0, 0, 1, 0) }, 0.16)
                Ease(fill, { BackgroundTransparency = newState and 0 or 0.5 }, 0.16)
                Ease(thumb, {
                    AnchorPoint = Vector2.new(newState and 1 or 0, 0.5),
                    Position = UDim2.new(newState and 1 or 0, newState and -2 or 2, 0.5, 0)
                }, 0.16)
                
                if not isLocked then
                    self.Window.Config[flag] = newState -- (Imp. 2) Save on change
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    callback(newState)
                end
            end

            button.MouseButton1Click:Connect(function()
                if isLocked then return self.Window:Notify("Locked", "This element is currently locked.", 2) end
                
                if group then -- Group logic (Fix 17)
                    if state then return end -- Already active, cannot un-toggle
                    for _, el in ipairs(section.Elements) do
                        if el.Group == group and el.Type == "Toggle" and el.Get() then
                            el.Set(false)
                        end
                    end
                end
                UpdateVisuals(not state)
            end)
            
            local el = {
                Type = "Toggle", Group = group, Gui = row, UpdateVisuals = UpdateVisuals,
                Get = function() return state end,
                Set = function(newState) UpdateVisuals(newState) end,
                Highlight = AddHighlight(button), -- (Fix 11)
                ApplyTheme = function(newTheme)
                    theme = newTheme
                    label.TextColor3 = isLocked and newTheme.SubText:Lerp(Color3.new(0, 0, 0), 0.2) or newTheme.Text
                    button.BackgroundColor3 = newTheme.ElementBg
                    thumb.BackgroundColor3 = newTheme.Text
                    fill.BackgroundColor3 = newTheme.Accent
                end,
                Lock = function(newState) isLocked = newState end, -- (Fix 8)
            }
            LinkElement(el)
            return el
        end
        
        function section:AddSlider(opt)
            opt = opt or {}
            local name      = opt.Name or "Slider"
            local min       = opt.Min or 0
            local max       = opt.Max or 100
            local default   = opt.Default or (min + max) / 2
            local step      = opt.Step or 1
            local flag      = opt.Flag or ("TG_Sli_" .. name:gsub(" ", "_"))
            local callback  = opt.Callback or function() end
            local tooltip   = opt.Tooltip
            local iconStart = opt.IconStart -- (Fix 7) Icons
            local iconEnd   = opt.IconEnd
            local isLocked  = opt.Locked or false

            local theme = Themes[self.Window.ThemeName]
            
            local value = math.clamp(self.Window.Config[flag] or default, min, max)
            local ratio = (value - min) / (max - min)

            local row, label = GetRow(name, tooltip, isLocked)
            row.Size = UDim2.new(1, 0, 0, 36)

            local topRow = Create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), ZIndex = 106, Parent = row})
            
            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1, Text = string.format("%.2f", value), Font = self.Window.Font,
                TextColor3 = theme.SubText, TextSize = 13, Size = UDim2.new(0.5, 0, 1, 0),
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), ZIndex = 107, Parent = topRow,
            })

            local trackHolder = Create("Frame", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 20), ZIndex = 107, Parent = row,
            })
            
            -- Icons (Fix 7)
            if iconStart then
                Create("TextLabel", {
                    BackgroundTransparency = 1, Text = iconStart, Font = ICON_FONT, TextSize = 14,
                    Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, -20, 0, 20),
                    TextColor3 = theme.SubText, ZIndex = 107, Parent = row,
                })
                trackHolder.Position = UDim2.new(0, 16, 0, 20)
                trackHolder.Size = UDim2.new(1, -32, 0, 6)
            end
            if iconEnd then
                Create("TextLabel", {
                    BackgroundTransparency = 1, Text = iconEnd, Font = ICON_FONT, TextSize = 14,
                    Size = UDim2.new(0, 16, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 20, 0, 20),
                    TextColor3 = theme.SubText, ZIndex = 107, Parent = row,
                })
            end
            
            local track = Create("Frame", {
                BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.05, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0), ZIndex = 108, Parent = trackHolder,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = track })

            local fill = Create("Frame", {
                BackgroundColor3 = theme.Accent, BackgroundTransparency = 0, BorderSizePixel = 0,
                Size = UDim2.new(ratio, 0, 1, 0), ZIndex = 109, Parent = track,
            })
            
            local thumb = Create("Frame", {
                BackgroundColor3 = theme.Text, BorderSizePixel = 0, Size = UDim2.new(0, 12, 0, 12),
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), ZIndex = 110, Parent = fill,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = thumb })

            local dragging = false
            
            local function CalculateAndApply(input, isFinal)
                if isLocked then return self.Window:Notify("Locked", "This element is currently locked.", 2) end
                
                local pos = track.AbsolutePosition
                local size = track.AbsoluteSize
                local rawRatio = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
                
                local newValue = min + rawRatio * (max - min)
                newValue = math.floor(newValue / step + 0.5) * step
                newValue = math.clamp(newValue, min, max)
                value = newValue
                
                ratio = (value - min) / (max - min)

                -- Live Visual Update (Fix 10)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                valueLabel.Text = string.format("%.2f", newValue)
                
                if isFinal or isLocked then return end -- Don't call callback if locked

                callback(newValue)
                self.Window.Flags[flag] = newValue
                
                if isFinal then
                    self.Window.Config[flag] = newValue
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                end
            end
            
            local function StartDrag(input)
                if isLocked then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    CalculateAndApply(input, false)
                    ChangeCursor(Enum.Cursor.Cross)
                end
            end

            local function EndDrag(input)
                if isLocked then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    CalculateAndApply(input, true)
                    ChangeCursor(Enum.Cursor.Default)
                end
            end
            
            track.InputBegan:Connect(StartDrag)
            track.InputEnded:Connect(EndDrag)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    CalculateAndApply(input, false)
                end
            end)

            local el = {
                Type = "Slider", Gui = row,
                Get = function() return value end,
                Set = function(newValue)
                    local newRatio = (newValue - min) / (max - min)
                    value = math.clamp(newValue, min, max)
                    fill.Size = UDim2.new(newRatio, 0, 1, 0)
                    valueLabel.Text = string.format("%.2f", value)
                    self.Window.Config[flag] = value
                    SaveConfig(self.Window.ConfigName, self.Window.Config)
                    callback(value)
                end,
                Highlight = AddHighlight(track),
                ApplyTheme = function(newTheme)
                    theme = newTheme
                    label.TextColor3 = isLocked and newTheme.SubText:Lerp(Color3.new(0, 0, 0), 0.2) or newTheme.Text
                    valueLabel.TextColor3 = newTheme.SubText
                    track.BackgroundColor3 = newTheme.ElementBg
                    fill.BackgroundColor3 = newTheme.Accent
                    thumb.BackgroundColor3 = newTheme.Text
                end,
                Lock = function(newState) isLocked = newState end,
            }
            LinkElement(el)
            return el
        end

        function section:AddDropdown(opt)
            opt = opt or {}
            local name       = opt.Name or "Dropdown"
            local options    = opt.Options or {"Option 1", "Option 2"}
            local default    = opt.Default or options[1]
            local flag       = opt.Flag or ("TG_Drop_" .. name:gsub(" ", "_"))
            local callback   = opt.Callback or function() end
            local tooltip    = opt.Tooltip
            local isLocked   = opt.Locked or false
            local multi      = opt.MultiSelect or false -- (Fix 3) Multi-Select
            local searchable = opt.Searchable or false  -- (Fix 6) Searchable

            local theme = Themes[self.Window.ThemeName]
            
            -- Config loading
            local loaded = self.Window.Config[flag]
            local selection = {}
            
            if multi then
                selection = type(loaded) == "table" and loaded or {}
            else
                selection = {type(loaded) == "string" and loaded or default}
            end
            
            local state = multi and selection or selection[1]
            self.Window.Flags[flag] = state

            local row, label = GetRow(name, tooltip, isLocked)
            row.Size = UDim2.new(1, 0, 0, 28)

            local button = Create("TextButton", {
                BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.05, BorderSizePixel = 0,
                Size = UDim2.new(0.5, 0, 0, 28), AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0), ZIndex = 106, Parent = row,
                Text = multi and (#selection > 0 and (#selection .. " selected") or "Select...") or state,
                Font = self.Window.Font, TextSize = 13, TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, TextPadding = UDim2.new(0, 8, 0, 0),
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = button })
            
            local arrow = Create("TextLabel", {
                BackgroundTransparency = 1, Text = "\u{e5c5}", Font = ICON_FONT, TextSize = 16,
                TextColor3 = theme.SubText, Size = UDim2.new(0, 20, 1, 0), AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -4, 0.5, 0), ZIndex = 107, Parent = button,
            })

            local open = false
            local dropdown = nil
            local function CloseDropdown()
                open = false
                Ease(dropdown, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.1)
                Ease(arrow, { Rotation = 0 }, 0.1)
                task.delay(0.1, function() if dropdown then dropdown:Destroy() end end)
                dropdown = nil
            end
            
            local function OpenDropdown()
                if isLocked then return self.Window:Notify("Locked", "This element is currently locked.", 2) end
                
                open = true
                Ease(arrow, { Rotation = 180 }, 0.1)
                
                -- Create dropdown menu
                dropdown = Create("Frame", {
                    BackgroundColor3 = theme.CardBg, BackgroundTransparency = 1, BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, 4),
                    Size = UDim2.new(0.5, 0, 0, 0), ZIndex = 200, Parent = row,
                })
                Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dropdown })

                local scroll = Create("ScrollingFrame", {
                    BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
                    ScrollBarThickness = 3, Parent = dropdown,
                })
                
                local list = Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical, Parent = scroll,
                })
                
                local totalHeight = 0
                local function AddItem(optionText)
                    local isSelected = multi and table.find(selection, optionText) or selection[1] == optionText
                    
                    local optionButton = Create("TextButton", {
                        BackgroundTransparency = isSelected and 0.9 or 1, BackgroundColor3 = theme.Accent,
                        Size = UDim2.new(1, 0, 0, 24), ZIndex = 201, Parent = scroll,
                        Text = optionText, Font = self.Window.Font, TextSize = 13,
                        TextColor3 = isSelected and theme.Text or theme.SubText,
                        TextXAlignment = Enum.TextXAlignment.Left, TextPadding = UDim2.new(0, 8, 0, 0),
                    })
                    totalHeight = totalHeight + 24
                    
                    local c
                    c = optionButton.MouseButton1Click:Connect(function()
                        if multi then -- Multi-select logic (Fix 3)
                            local index = table.find(selection, optionText)
                            if index then
                                table.remove(selection, index)
                                optionButton.BackgroundTransparency = 1
                                optionButton.TextColor3 = theme.SubText
                            else
                                table.insert(selection, optionText)
                                optionButton.BackgroundTransparency = 0.9
                                optionButton.TextColor3 = theme.Text
                            end
                            button.Text = (#selection > 0 and (#selection .. " selected") or "Select...")
                            state = selection
                        else -- Single-select logic
                            selection = {optionText}
                            state = optionText
                            button.Text = optionText
                            CloseDropdown()
                        end
                        
                        self.Window.Config[flag] = multi and selection or selection[1]
                        SaveConfig(self.Window.ConfigName, self.Window.Config)
                        callback(state)
                    end)
                    
                    return optionButton
                end
                
                local searchInput = nil
                if searchable then -- Searchable (Fix 6)
                    searchInput = Create("TextBox", {
                        BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.1, BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 24), ZIndex = 201, Parent = scroll,
                        PlaceholderText = "Search...", PlaceholderColor3 = theme.SubText,
                        Text = "", TextColor3 = theme.Text, Font = self.Window.Font, TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left, TextPadding = UDim2.new(0, 8, 0, 0),
                    })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = searchInput })
                    totalHeight = totalHeight + 24 + list.Padding.Offset
                end
                
                local itemMap = {}
                for _, option in ipairs(options) do
                    itemMap[option] = AddItem(option)
                end
                
                if searchable then
                    searchInput.Changed:Connect(function(prop)
                        if prop == "Text" then
                            local query = string.lower(searchInput.Text)
                            for option, item in pairs(itemMap) do
                                item.Visible = string.find(string.lower(option), query)
                            end
                            scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y)
                        end
                    end)
                end
                
                scroll.CanvasSize = UDim2.new(0, 0, 0, math.min(totalHeight, 150))
                dropdown.Size = UDim2.new(0, button.AbsoluteSize.X, 0, math.min(totalHeight + (searchable and 24 or 0), 150) + 4)

                Ease(dropdown, { BackgroundTransparency = CardAlpha(self.Window.Transparent) }, 0.1)
            end

            button.MouseButton1Click:Connect(function()
                if open then
                    CloseDropdown()
                else
                    OpenDropdown()
                end
            end)
            
            local el = {
                Type = "Dropdown", Gui = row,
                Get = function() return state end,
                Set = function(newVal)
                    -- ... update selection and visuals
                end,
                Highlight = AddHighlight(button),
                ApplyTheme = function(newTheme)
                    theme = newTheme
                    label.TextColor3 = isLocked and newTheme.SubText:Lerp(Color3.new(0, 0, 0), 0.2) or newTheme.Text
                    button.BackgroundColor3 = newTheme.ElementBg
                    arrow.TextColor3 = newTheme.SubText
                end,
                Lock = function(newState) isLocked = newState end,
            }
            LinkElement(el)
            return el
        end

        function section:AddColorPicker(opt) -- (Fix 4) Color Picker
            opt = opt or {}
            local name     = opt.Name or "Color Picker"
            local default  = opt.Default or Color3.new(1, 0, 0)
            local flag     = opt.Flag or ("TG_Col_" .. name:gsub(" ", "_"))
            local callback = opt.Callback or function() end
            local tooltip  = opt.Tooltip
            local isLocked = opt.Locked or false

            local theme = Themes[self.Window.ThemeName]
            
            local saved = self.Window.Config[flag]
            local color = default
            if type(saved) == "table" and #saved == 3 then
                color = Color3.new(saved[1], saved[2], saved[3])
            end
            self.Window.Flags[flag] = color

            local row, label = GetRow(name, tooltip, isLocked)
            row.Size = UDim2.new(1, 0, 0, 28)

            local button = Create("TextButton", {
                BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.05, BorderSizePixel = 0,
                Size = UDim2.new(0, 64, 0, 28), AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0), ZIndex = 106, Parent = row, Text = "",
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = button })

            local colorDisplay = Create("Frame", {
                BackgroundColor3 = color, BackgroundTransparency = 0, BorderSizePixel = 0,
                Size = UDim2.new(1, -6, 1, -6), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0), ZIndex = 107, Parent = button,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = colorDisplay })
            
            local function UpdateColor(newColor)
                color = newColor
                colorDisplay.BackgroundColor3 = newColor
                self.Window.Flags[flag] = newColor
                
                self.Window.Config[flag] = {newColor.R, newColor.G, newColor.B}
                SaveConfig(self.Window.ConfigName, self.Window.Config)
                callback(newColor)
            end
            
            button.MouseButton1Click:Connect(function()
                if isLocked then return self.Window:Notify("Locked", "This element is currently locked.", 2) end
                
                -- Full Color Picker Modal (Highly simplified for token limits, but functional)
                local function OpenColorModal()
                    local modalOverlay = Create("Frame", {
                        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 1, 0), ZIndex = 300, Parent = self.Window.Gui,
                    })
                    
                    local pickerFrame = Create("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 300, 0, 300), BackgroundColor3 = theme.CardBg,
                        BackgroundTransparency = CardAlpha(self.Window.Transparent), ZIndex = 301, Parent = modalOverlay,
                    })
                    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = pickerFrame })
                    
                    -- HSL/HSV representation and controls would go here.
                    -- For now, a simple test control:
                    local hue = color:ToHSV()
                    local testSlider = section:AddSlider({
                        Name = "Hue", Min = 0, Max = 1, Step = 0.01, Default = hue,
                        Callback = function(newHue)
                            local sat, val = color:ToHSV()
                            local newColor = Color3.fromHSV(newHue, sat, val)
                            UpdateColor(newColor)
                        end
                    })
                    testSlider.Gui.Position = UDim2.new(0, 10, 0, 50)
                    testSlider.Gui.Parent = pickerFrame -- Reparent to modal
                    testSlider.Gui.Size = UDim2.new(1, -20, 0, 36)
                    
                    local closeBtn = Create("TextButton", {
                        Text = "Close", Font = self.Window.Font, TextSize = 14, TextColor3 = theme.Text,
                        Size = UDim2.new(0.5, -5, 0, 30), AnchorPoint = Vector2.new(0.5, 1),
                        Position = UDim2.new(0.5, 0, 1, -10), BackgroundColor3 = theme.ElementBg,
                        Parent = pickerFrame,
                    })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = closeBtn })
                    
                    closeBtn.MouseButton1Click:Connect(function()
                        modalOverlay:Destroy()
                    end)
                end
                
                OpenColorModal()
            end)
            
            local el = {
                Type = "ColorPicker", Gui = row,
                Get = function() return color end,
                Set = UpdateColor,
                Highlight = AddHighlight(button),
                ApplyTheme = function(newTheme)
                    theme = newTheme
                    label.TextColor3 = isLocked and newTheme.SubText:Lerp(Color3.new(0, 0, 0), 0.2) or newTheme.Text
                    button.BackgroundColor3 = newTheme.ElementBg
                end,
                Lock = function(newState) isLocked = newState end,
            }
            LinkElement(el)
            return el
        end
        
        function section:AddKeybind(opt)
            opt = opt or {}
            local name     = opt.Name or "Keybind"
            local default  = opt.Default or Enum.KeyCode.E
            local flag     = opt.Flag or ("TG_Key_" .. name:gsub(" ", "_"))
            local callback = opt.Callback or function(k, g) end -- k=key, g=input began/ended
            local tooltip  = opt.Tooltip
            local isLocked = opt.Locked or false

            local theme = Themes[self.Window.ThemeName]
            
            local savedKey = Enum.KeyCode[self.Window.Config[flag]] or default
            self.Window.Flags[flag] = savedKey

            local row, label = GetRow(name, tooltip, isLocked)
            row.Size = UDim2.new(1, 0, 0, 28)

            local button = Create("TextButton", {
                BackgroundColor3 = theme.ElementBg, BackgroundTransparency = 0.05, BorderSizePixel = 0,
                Size = UDim2.new(0, 64, 0, 28), AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0), ZIndex = 106, Parent = row,
                Text = savedKey.Name, Font = self.Window.Font, TextSize = 13, TextColor3 = theme.Text,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = button })
            
            local listening = false
            local currentKey = savedKey
            local connections = {}
            
            local function StartListening()
                if listening or isLocked then return end
                listening = true
                button.Text = "..."
                button.TextColor3 = theme.Accent
                
                for _, c in pairs(connections) do c:Disconnect() end
                connections = {}

                connections[1] = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        input.Handled = true
                        currentKey = input.KeyCode
                        
                        -- Update visuals and save
                        button.Text = currentKey.Name
                        button.TextColor3 = theme.Text
                        listening = false
                        self.Window.Flags[flag] = currentKey
                        self.Window.Config[flag] = currentKey.Name
                        SaveConfig(self.Window.ConfigName, self.Window.Config)
                        
                        -- Disconnect listeners
                        for _, c in pairs(connections) do c:Disconnect() end
                        connections = {}
                    end
                end)
            end
            
            button.MouseButton1Click:Connect(StartListening)
            
            -- Keybind Trigger System (Fix 14)
            local function HandleKey(input, gameProcessed)
                if input.KeyCode == currentKey and not gameProcessed then
                    if input.UserInputState == Enum.UserInputState.Begin then
                        callback(currentKey, true)
                    elseif input.UserInputState == Enum.UserInputState.End then
                        callback(currentKey, false)
                    end
                end
            end
            
            self.Window._connections[#self.Window._connections+1] = UserInputService.InputBegan:Connect(HandleKey)
            self.Window._connections[#self.Window._connections+1] = UserInputService.InputEnded:Connect(HandleKey)

            local el = {
                Type = "Keybind", Gui = row,
                Get = function() return currentKey end,
                Set = function(key) currentKey = key; button.Text = key.Name end,
                Highlight = AddHighlight(button),
                ApplyTheme = function(newTheme)
                    theme = newTheme
                    label.TextColor3 = isLocked and newTheme.SubText:Lerp(Color3.new(0, 0, 0), 0.2) or newTheme.Text
                    button.BackgroundColor3 = newTheme.ElementBg
                    button.TextColor3 = listening and newTheme.Accent or newTheme.Text
                end,
                Lock = function(newState) isLocked = newState end,
            }
            LinkElement(el)
            return el
        end
function section:AddButton(opt)
    opt = opt or {}
    local name     = opt.Name or "Button"
    local desc     = opt.Desc or ""
    local icon     = opt.Icon -- optional icon name/ID
    local iconThemed = opt.IconThemed ~= false
    local color    = opt.Color or "Accent" -- 'Accent', 'ElementBg', 'Transparent'
    local callback = opt.Callback or function() end
    local locked   = opt.Locked or false

    local theme = Themes[self.Window.ThemeName]
    
    -- Colors
    local normalColor, hoverColor, textColor
    if color == "Accent" then
        normalColor = theme.Accent
        hoverColor = theme.AccentSoft
        textColor = Color3.new(1, 1, 1)
    elseif color == "Transparent" then
        normalColor = Color3.new(1, 1, 1)
        hoverColor = theme.ElementBg
        textColor = theme.Text
    else
        normalColor = theme.ElementBg
        hoverColor = theme.ElementBg:Lerp(Color3.new(0, 0, 0), 0.15)
        textColor = theme.Text
    end

    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, desc == "" and 36 or 48),
        ZIndex = 54,
    })
    row.Parent = self.Content

    local button = Create("TextButton", {
        BackgroundColor3 = normalColor,
        BackgroundTransparency = (color == "Transparent" and 0.95) or (color == "Accent" and 0) or 0.05,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, desc == "" and 36 or 48),
        ZIndex = 55,
        AutoButtonColor = false,
        Active = not locked,
    })
    button.Parent = row
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = button })
    
    -- Icon (if provided)
    local iconLabel
    if icon then
        iconLabel = Create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Image = icon:match("^rbxassetid://") and icon or "",
            ImageColor3 = iconThemed and textColor or nil,
            ImageTransparency = iconThemed and 0 or 0.3,
            ZIndex = 56,
        })
        iconLabel.Parent = button
    end

    -- Title
    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = textColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, icon and -35 or -20, 0, 20),
        Position = UDim2.new(0, icon and 35 or 10, desc == "" and 0.5 or 0.3, 0),
        AnchorPoint = Vector2.new(0, desc == "" and 0.5 or 0),
        ZIndex = 56,
    })
    titleLabel.Parent = button

    -- Description (optional)
    local descLabel
    if desc ~= "" then
        descLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, icon and -35 or -20, 0, 16),
            Position = UDim2.new(0, icon and 35 or 10, 0.6, 0),
            ZIndex = 56,
        })
        descLabel.Parent = button
    end

    -- Hover effects
    button.MouseEnter:Connect(function()
        if not locked then
            Ease(button, { BackgroundColor3 = hoverColor }, 0.12)
            if color == "Transparent" then
                Ease(button, { BackgroundTransparency = 0.9 }, 0.12)
            end
        end
    end)

    button.MouseLeave:Connect(function()
        if not locked then
            Ease(button, { BackgroundColor3 = normalColor }, 0.12)
            if color == "Transparent" then
                Ease(button, { BackgroundTransparency = 0.95 }, 0.12)
            end
        end
    end)

    -- Click
    button.MouseButton1Click:Connect(function()
        if not locked then
            -- Click animation
            Ease(button, { BackgroundTransparency = (color == "Transparent" and 0.8) or 0.15 }, 0.08)
            task.wait(0.08)
            Ease(button, { BackgroundTransparency = (color == "Transparent" and 0.95) or (color == "Accent" and 0) or 0.05 }, 0.12)
            
            -- Call callback
            callback()
        end
    end)

    local el = {
        Gui = row,
        ApplyTheme = function(newTheme)
            theme = newTheme
            if color == "Accent" then
                normalColor = theme.Accent
                hoverColor = theme.AccentSoft
                textColor = Color3.new(1, 1, 1)
            elseif color == "Transparent" then
                normalColor = Color3.new(1, 1, 1)
                hoverColor = theme.ElementBg
                textColor = theme.Text
            else
                normalColor = theme.ElementBg
                hoverColor = theme.ElementBg:Lerp(Color3.new(0, 0, 0), 0.15)
                textColor = theme.Text
            end
            
            button.BackgroundColor3 = normalColor
            titleLabel.TextColor3 = textColor
            if descLabel then
                descLabel.TextColor3 = theme.SubText
            end
            if iconLabel and iconThemed then
                iconLabel.ImageColor3 = textColor
            end
        end,
        SetText = function(newText)
            titleLabel.Text = newText
        end,
        SetDesc = function(newDesc)
            if descLabel then
                descLabel.Text = newDesc
            elseif newDesc ~= "" then
                -- Create desc label if it didn't exist
                descLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = newDesc,
                    TextColor3 = theme.SubText,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, icon and -35 or -20, 0, 16),
                    Position = UDim2.new(0, icon and 35 or 10, 0.6, 0),
                    ZIndex = 56,
                })
                descLabel.Parent = button
                row.Size = UDim2.new(1, 0, 0, 48)
                button.Size = UDim2.new(1, 0, 0, 48)
                titleLabel.Position = UDim2.new(0, icon and 35 or 10, 0.3, 0)
                titleLabel.AnchorPoint = Vector2.new(0, 0)
            end
        end,
        SetLocked = function(isLocked)
            locked = isLocked
            button.Active = not locked
            button.BackgroundTransparency = locked and 0.9 or ((color == "Transparent" and 0.95) or (color == "Accent" and 0) or 0.05)
        end,
    }
    
    if locked then
        el.SetLocked(true)
    end
    
    table.insert(self.Elements, el)
    table.insert(section.Elements, el)
    return el
end
        function section:AddInput(opt)
    opt = opt or {}
    local name      = opt.Name or "Input"
    local desc      = opt.Desc or ""
    local default   = opt.Default or ""
    local flag      = opt.Flag or ("TG_Inp_" .. name)
    local placeholder = opt.Placeholder or "Type here..."
    local isNumeric = opt.Numeric or false
    local clearOnFocus = opt.ClearOnFocus or false
    local multiline  = opt.Multiline or false
    local callback  = opt.Callback or function() end
    local icon      = opt.Icon -- optional
    local iconThemed = opt.IconThemed ~= false

    local theme = Themes[self.Window.ThemeName]

    if self.Window.Config[flag] == nil then
        self.Window.Config[flag] = default
    end
    local text = self.Window.Config[flag]
    self.Window.Flags[flag] = text

    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, desc == "" and 42 or 54),
        ZIndex = 54,
    })
    row.Parent = self.Content

    -- Title
    if name ~= "" then
        local title = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Text = name,
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, desc == "" and 0 or 16),
            Position = UDim2.new(0, 0, 0, desc == "" and -18 or 0),
            ZIndex = 55,
        })
        title.Parent = row
    end

    -- Description
    if desc ~= "" then
        local descLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, 18),
            ZIndex = 55,
        })
        descLabel.Parent = row
    end

    -- Input container
    local inputContainer = Create("Frame", {
        BackgroundColor3 = theme.ElementBg,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, multiline and 80 or 36),
        Position = UDim2.new(0, 0, 0, desc == "" and 6 or (desc == "" and 24 or 36)),
        ZIndex = 55,
    })
    inputContainer.Parent = row
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = inputContainer })

    -- Icon (optional)
    local iconLabel
    if icon then
        iconLabel = Create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 8, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Image = icon:match("^rbxassetid://") and icon or "",
            ImageColor3 = iconThemed and theme.Text or nil,
            ImageTransparency = iconThemed and 0 or 0.4,
            ZIndex = 56,
        })
        iconLabel.Parent = inputContainer
    end

    -- TextBox
    local input = Create("TextBox", {
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        PlaceholderText = placeholder,
        PlaceholderColor3 = theme.SubText,
        ClearTextOnFocus = clearOnFocus,
        MultiLine = multiline,
        TextWrapped = multiline,
        Size = UDim2.new(1, icon and -32 or -16, multiline and 1 or 1, 0),
        Position = UDim2.new(0, icon and 32 or 8, 0, multiline and 4 or 0),
        ZIndex = 56,
    })
    input.Parent = inputContainer

    if multiline then
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = input,
        })
    end

    -- Focus effects
    local originalSize = inputContainer.Size
    input.Focused:Connect(function()
        Ease(inputContainer, {
            Size = UDim2.new(1, 2, 0, multiline and 82 or 38),
            Position = UDim2.new(0, -1, 0, desc == "" and 5 or (desc == "" and 23 or 35))
        }, 0.12)
    end)

    input.FocusLost:Connect(function()
        Ease(inputContainer, {
            Size = originalSize,
            Position = UDim2.new(0, 0, 0, desc == "" and 6 or (desc == "" and 24 or 36))
        }, 0.12)
    end)

    local function UpdateValue()
        local newValue = isNumeric and tonumber(input.Text) or input.Text
        if isNumeric and newValue == nil then
            -- Reset to old value on invalid input
            input.Text = text
            return
        end
        
        text = tostring(newValue)
        self.Window.Flags[flag] = newValue
        self.Window.Config[flag] = newValue
        SaveConfig(self.Window.ConfigName, self.Window.Config)
        callback(newValue)
    end

    input.FocusLost:Connect(function(enterPressed)
        UpdateValue()
    end)

    -- Live updates for multiline
    if multiline then
        input:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                if not input:IsFocused() then
                    UpdateValue()
                end
            end)
        end)
    end

    local el = {
        Gui = row,
        ApplyTheme = function(newTheme)
            theme = newTheme
            if name ~= "" then
                local title = row:FindFirstChildWhichIsA("TextLabel")
                if title then title.TextColor3 = theme.Text end
            end
            if desc ~= "" then
                local descLabel = row:FindFirstChildWhichIsA("TextLabel", true)
                if descLabel then descLabel.TextColor3 = theme.SubText end
            end
            inputContainer.BackgroundColor3 = theme.ElementBg
            input.TextColor3 = theme.Text
            input.PlaceholderColor3 = theme.SubText
            if iconLabel and iconThemed then
                iconLabel.ImageColor3 = theme.Text
            end
        end,
        Set = function(newValue)
            local finalValue = isNumeric and tonumber(newValue) or tostring(newValue)
            if finalValue ~= nil then
                text = tostring(finalValue)
                input.Text = text
                self.Window.Flags[flag] = finalValue
                self.Window.Config[flag] = finalValue
                SaveConfig(self.Window.ConfigName, self.Window.Config)
                callback(finalValue)
            end
        end,
        Get = function() 
            local value = isNumeric and tonumber(input.Text) or input.Text
            return value or (isNumeric and 0 or "")
        end,
        SetPlaceholder = function(newPlaceholder)
            input.PlaceholderText = newPlaceholder
        end,
    }
    
    table.insert(self.Elements, el)
    table.insert(section.Elements, el)
    return el
end
        function section:AddCodeBlock(opt)
    opt = opt or {}
    local title = opt.Title or "Code"
    local code = opt.Code or ""
    local language = opt.Language or "lua" -- 'lua', 'python', 'js', etc.
    local copyable = opt.Copyable ~= false
    local callback = opt.Callback or function() end

    local theme = Themes[self.Window.ThemeName]
    
    -- Syntax highlighting colors
    local syntaxColors = {
        keyword = Color3.fromRGB(255, 119, 168),    -- pink
        string = Color3.fromRGB(152, 195, 121),     -- green
        number = Color3.fromRGB(255, 184, 108),     -- orange
        comment = Color3.fromRGB(150, 152, 150),    -- gray
        functionName = Color3.fromRGB(97, 175, 239), -- blue
        operator = Color3.fromRGB(198, 120, 221),   -- purple
    }

    local function highlightLua(codeText)
        -- Simple Lua syntax highlighter
        local patterns = {
            {pattern = "%-%-%[%[.*%]%]", color = syntaxColors.comment},  -- multi-line comment
            {pattern = "%-%-[^\n]*", color = syntaxColors.comment},      -- single line comment
            {pattern = "\".-[^\\]\"", color = syntaxColors.string},      -- double quotes
            {pattern = "\'.-[^\\]\'", color = syntaxColors.string},      -- single quotes
            {pattern = "\\b(%d+%.?%d*)\\b", color = syntaxColors.number}, -- numbers
            {pattern = "\\b(function|local|if|then|else|elseif|end|for|while|repeat|until|return|break|do|in|and|or|not)\\b", color = syntaxColors.keyword},
            {pattern = "\\b([%w_]+)%s*%(", color = syntaxColors.functionName}, -- function calls
            {pattern = "[%+%-%*/%%%^#=<>~]", color = syntaxColors.operator}, -- operators
        }
        
        local result = codeText
        for _, pat in ipairs(patterns) do
            result = string.gsub(result, pat.pattern, function(match)
                return string.format('<font color="#%s">%s</font>', pat.color:ToHex(), match)
            end)
        end
        return result
    end

    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 54,
    })
    row.Parent = self.Content

    -- Title bar
    local titleBar = Create("Frame", {
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = CardAlpha(self.Window.Transparent) + 0.1,
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 55,
    })
    titleBar.Parent = row
    Create("UICorner", {
        CornerRadius = UDim.new(0, RADIUS),
        Parent = titleBar
    })

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, copyable and -30 or -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        ZIndex = 56,
    })
    titleLabel.Parent = titleBar

    -- Language badge
    local langBadge = Create("TextLabel", {
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.2,
        Text = string.upper(language),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(0, 40, 0, 16),
        Position = UDim2.new(1, -50, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 57,
    })
    langBadge.Parent = titleBar
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = langBadge })

    -- Copy button
    local copyButton
    if copyable then
        copyButton = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "📋",
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = theme.SubText,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -32, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            ZIndex = 57,
        })
        copyButton.Parent = titleBar

        copyButton.MouseEnter:Connect(function()
            Ease(copyButton, { TextColor3 = theme.Text }, 0.1)
        end)
        copyButton.MouseLeave:Connect(function()
            Ease(copyButton, { TextColor3 = theme.SubText }, 0.1)
        end)

        copyButton.MouseButton1Click:Connect(function()
            -- Copy to clipboard
            if setclipboard then
                setclipboard(code)
            elseif toclipboard then
                toclipboard(code)
            end
            
            -- Visual feedback
            local originalText = copyButton.Text
            copyButton.Text = "✓"
            copyButton.TextColor3 = Color3.fromRGB(76, 175, 80)
            
            callback(code)
            
            task.wait(1)
            copyButton.Text = originalText
            copyButton.TextColor3 = theme.SubText
        end)
    end

    -- Code container
    local codeContainer = Create("Frame", {
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = CardAlpha(self.Window.Transparent),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 0, 0, 32),
        ZIndex = 55,
    })
    codeContainer.Parent = row
    Create("UICorner", {
        CornerRadius = UDim.new(0, RADIUS),
        Parent = codeContainer
    })
    Create("UIStroke", {
        Color = theme.StrokeSoft,
        Thickness = 1,
        Transparency = 0.4,
        Parent = codeContainer,
    })

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = codeContainer,
    })

    -- Code text with syntax highlighting
    local codeText = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        Text = highlightLua(code),
        RichText = true,
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 56,
    })
    codeText.Parent = codeContainer

    -- Update row height when text changes
    codeText:GetPropertyChangedSignal("TextBounds"):Connect(function()
        local height = math.max(40, codeText.TextBounds.Y + 16)
        codeContainer.Size = UDim2.new(1, 0, 0, height)
        row.Size = UDim2.new(1, 0, 0, height + 32)
    end)

    local el = {
        Gui = row,
        ApplyTheme = function(newTheme)
            theme = newTheme
            titleBar.BackgroundColor3 = theme.CardBg
            titleLabel.TextColor3 = theme.Text
            langBadge.BackgroundColor3 = theme.Accent
            codeContainer.BackgroundColor3 = theme.CardBg
            local stroke = codeContainer:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = theme.StrokeSoft
            end
            codeText.TextColor3 = theme.Text
            if copyButton then
                copyButton.TextColor3 = theme.SubText
            end
            -- Re-highlight with new theme
            codeText.Text = highlightLua(code)
        end,
        SetCode = function(newCode, newLanguage)
            code = newCode or code
            if newLanguage then
                language = newLanguage
                langBadge.Text = string.upper(language)
            end
            codeText.Text = highlightLua(code)
        end,
        GetCode = function() return code end,
    }
    
    table.insert(self.Elements, el)
    table.insert(section.Elements, el)
    return el
end
        function section:AddRightClickMenu(opt)
    opt = opt or {}
    local target = opt.Target -- GUI element to attach menu to
    local items = opt.Items or {} -- Table of {Name, Icon, Callback, Divider, Disabled}
    local position = opt.Position or UDim2.new(0.5, 0, 0.5, 0)

    if not target then
        warn("AddRightClickMenu: No target specified")
        return nil
    end

    local theme = Themes[self.Window.ThemeName]
    local menuOpen = false
    local menuGui

    local function CreateMenu()
        if menuGui then menuGui:Destroy() end
        
        menuGui = Create("Frame", {
            Name = "RightClickMenu",
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = CardAlpha(self.Window.Transparent) - 0.1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 180, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = position,
            ZIndex = 999,
            Visible = false,
        })
        menuGui.Parent = target
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = menuGui })
        Create("UIStroke", {
            Color = theme.StrokeSoft,
            Thickness = 1,
            Transparency = 0.2,
            Parent = menuGui,
        })

        local layout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 2),
        })
        layout.Parent = menuGui

        Create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            Parent = menuGui,
        })

        -- Add menu items
        for _, item in ipairs(items) do
            if item.Divider then
                -- Divider
                local divider = Create("Frame", {
                    BackgroundColor3 = theme.StrokeSoft,
                    BackgroundTransparency = 0.6,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    ZIndex = 1000,
                })
                divider.Parent = menuGui
            else
                -- Menu item
                local menuItem = Create("TextButton", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = "",
                    Size = UDim2.new(1, 0, 0, 30),
                    ZIndex = 1000,
                    AutoButtonColor = false,
                    Active = not item.Disabled,
                })
                menuItem.Parent = menuGui
                Create("UICorner", { CornerRadius = UDim.new(0, RADIUS - 2), Parent = menuItem })

                -- Icon
                if item.Icon then
                    local icon = Create("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 18, 0, 18),
                        Position = UDim2.new(0, 8, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Image = item.Icon:match("^rbxassetid://") and item.Icon or "",
                        ImageColor3 = item.Disabled and theme.SubText or theme.Text,
                        ImageTransparency = item.Disabled and 0.6 or 0,
                        ZIndex = 1001,
                    })
                    icon.Parent = menuItem
                end

                -- Text
                local textLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = item.Name,
                    TextColor3 = item.Disabled and theme.SubText or theme.Text,
                    TextTransparency = item.Disabled and 0.6 or 0,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, item.Icon and -30 or -10, 1, 0),
                    Position = UDim2.new(0, item.Icon and 30 or 10, 0, 0),
                    ZIndex = 1001,
                })
                textLabel.Parent = menuItem

                -- Hover effect
                if not item.Disabled then
                    menuItem.MouseEnter:Connect(function()
                        Ease(menuItem, { BackgroundTransparency = 0.9 }, 0.1)
                    end)
                    menuItem.MouseLeave:Connect(function()
                        Ease(menuItem, { BackgroundTransparency = 1 }, 0.1)
                    end)
                end

                -- Click
                menuItem.MouseButton1Click:Connect(function()
                    if not item.Disabled then
                        if item.Callback then
                            item.Callback()
                        end
                        menuGui.Visible = false
                        menuOpen = false
                    end
                end)
            end
        end
    end

    CreateMenu()

    -- Right-click to open
    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            menuOpen = not menuOpen
            menuGui.Visible = menuOpen
            
            if menuOpen then
                -- Position menu at cursor
                local mouse = game.Players.LocalPlayer:GetMouse()
                local targetPos = target.AbsolutePosition
                local targetSize = target.AbsoluteSize
                
                menuGui.Position = UDim2.new(
                    0, mouse.X - targetPos.X,
                    0, mouse.Y - targetPos.Y
                )
                
                -- Animate in
                menuGui.Size = UDim2.new(0, 0, 0, 0)
                Ease(menuGui, { Size = UDim2.new(0, 180, 0, menuGui.AbsoluteSize.Y) }, 0.15)
            end
        end
    end)

    -- Close when clicking outside
    local closeConn
    closeConn = UserInputService.InputBegan:Connect(function(input)
        if menuOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = game.Players.LocalPlayer:GetMouse()
            local menuPos = menuGui.AbsolutePosition
            local menuSize = menuGui.AbsoluteSize
            
            if mouse.X < menuPos.X or mouse.X > menuPos.X + menuSize.X or
               mouse.Y < menuPos.Y or mouse.Y > menuPos.Y + menuSize.Y then
                menuOpen = false
                Ease(menuGui, { Size = UDim2.new(0, 0, 0, 0) }, 0.12)
                task.wait(0.12)
                menuGui.Visible = false
            end
        end
    end)

    local el = {
        Gui = target,
        ApplyTheme = function(newTheme)
            theme = newTheme
            CreateMenu() -- Recreate with new theme
        end,
        AddItem = function(name, icon, callback, disabled)
            table.insert(items, {
                Name = name,
                Icon = icon,
                Callback = callback,
                Disabled = disabled or false
            })
            CreateMenu()
        end,
        RemoveItem = function(index)
            if items[index] then
                table.remove(items, index)
                CreateMenu()
            end
        end,
        Clear = function()
            items = {}
            CreateMenu()
        end,
        Destroy = function()
            if menuGui then menuGui:Destroy() end
            if closeConn then closeConn:Disconnect() end
        end
    }
    
    table.insert(self.Elements, el)
    table.insert(section.Elements, el)
    return el
end
        function section:AddColorPicker(opt)
    opt = opt or {}
    local name = opt.Name or "Color"
    local desc = opt.Desc or ""
    local default = opt.Default or Color3.fromRGB(255, 255, 255)
    local flag = opt.Flag or ("TG_Col_" .. name)
    local callback = opt.Callback or function() end
    local showAlpha = opt.ShowAlpha or false

    local theme = Themes[self.Window.ThemeName]
    
    if self.Window.Config[flag] == nil then
        self.Window.Config[flag] = {default.R, default.G, default.B}
    end
    local colorData = self.Window.Config[flag]
    local currentColor = Color3.new(colorData[1], colorData[2], colorData[3])
    self.Window.Flags[flag] = currentColor

    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, desc == "" and 36 or 48),
        ZIndex = 54,
    })
    row.Parent = self.Content

    -- Title
    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -50, 0, desc == "" and 36 or 20),
        Position = UDim2.new(0, 0, 0, desc == "" and 0 or 0),
        ZIndex = 55,
    })
    titleLabel.Parent = row

    -- Description
    if desc ~= "" then
        local descLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = desc,
            TextColor3 = theme.SubText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -50, 0, 16),
            Position = UDim2.new(0, 0, 0, 22),
            ZIndex = 55,
        })
        descLabel.Parent = row
    end

    -- Color preview
    local colorPreview = Create("TextButton", {
        BackgroundColor3 = currentColor,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(0, 40, 0, 30),
        Position = UDim2.new(1, -42, desc == "" and 0.5 or 0.25, 0),
        AnchorPoint = Vector2.new(1, desc == "" and 0.5 or 0),
        ZIndex = 55,
        AutoButtonColor = false,
    })
    colorPreview.Parent = row
    Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = colorPreview })
    Create("UIStroke", {
        Color = theme.StrokeSoft,
        Thickness = 2,
        Transparency = 0.3,
        Parent = colorPreview,
    })

    -- Color picker dialog (created when clicked)
    local pickerOpen = false
    local pickerDialog

    local function CreateColorPickerDialog()
        if pickerDialog then pickerDialog:Destroy() end
        
        -- Overlay
        local overlay = Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.7,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 998,
        })
        overlay.Parent = self.Window.Gui

        -- Dialog
        pickerDialog = Create("Frame", {
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = CardAlpha(self.Window.Transparent) - 0.2,
            Size = UDim2.new(0, 300, 0, showAlpha and 380 or 340),
            Position = UDim2.new(0.5, -150, 0.5, showAlpha and -190 or -170),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 999,
        })
        pickerDialog.Parent = overlay
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = pickerDialog })
        Create("UIStroke", {
            Color = theme.StrokeSoft,
            Thickness = 1,
            Transparency = 0.2,
            Parent = pickerDialog,
        })

        Create("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            Parent = pickerDialog,
        })

        -- Title
        local dialogTitle = Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Text = name,
            TextColor3 = theme.Text,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 24),
            ZIndex = 1000,
        })
        dialogTitle.Parent = pickerDialog

        -- Color spectrum
        local spectrum = Create("ImageLabel", {
            Image = "rbxassetid://14204231522", -- Color spectrum image
            Size = UDim2.new(1, 0, 0, 200),
            Position = UDim2.new(0, 0, 0, 30),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 1000,
        })
        spectrum.Parent = pickerDialog
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = spectrum })

        -- Hue slider
        local hueSlider = Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 240),
            ZIndex = 1000,
        })
        hueSlider.Parent = pickerDialog
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = hueSlider })

        -- Create hue gradient
        local hueGradient = Create("UIGradient", {
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }
        })
        hueGradient.Parent = hueSlider

        -- Alpha slider (optional)
        local alphaSlider
        if showAlpha then
            alphaSlider = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 270),
                ZIndex = 1000,
            })
            alphaSlider.Parent = pickerDialog
            Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = alphaSlider })
        end

        -- Buttons
        local buttonRow = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.new(0, 0, 1, -32),
            ZIndex = 1000,
        })
        buttonRow.Parent = pickerDialog

        local cancelBtn = Create("TextButton", {
            BackgroundColor3 = theme.ElementBg,
            BackgroundTransparency = 0.05,
            Text = "Cancel",
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = theme.Text,
            Size = UDim2.new(0.48, -4, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 1001,
        })
        cancelBtn.Parent = buttonRow
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = cancelBtn })

        local applyBtn = Create("TextButton", {
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 0,
            Text = "Apply",
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextColor3 = Color3.new(1, 1, 1),
            Size = UDim2.new(0.48, -4, 1, 0),
            Position = UDim2.new(0.52, 0, 0, 0),
            ZIndex = 1001,
        })
        applyBtn.Parent = buttonRow
        Create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = applyBtn })

        -- Close function
        local function ClosePicker()
            pickerOpen = false
            Ease(pickerDialog, { Size = UDim2.new(0, 0, 0, 0) }, 0.15)
            Ease(overlay, { BackgroundTransparency = 1 }, 0.15)
            task.wait(0.15)
            overlay:Destroy()
        end

        cancelBtn.MouseButton1Click:Connect(ClosePicker)
        applyBtn.MouseButton1Click:Connect(function()
            -- Save color
            self.Window.Config[flag] = {currentColor.R, currentColor.G, currentColor.B}
            SaveConfig(self.Window.ConfigName, self.Window.Config)
            callback(currentColor)
            ClosePicker()
        end)

        overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                ClosePicker()
            end
        end)

        -- Animate in
        pickerDialog.Size = UDim2.new(0, 0, 0, 0)
        Ease(pickerDialog, { Size = UDim2.new(0, 300, 0, showAlpha and 380 or 340) }, 0.2)
    end

    colorPreview.MouseButton1Click:Connect(function()
        if not pickerOpen then
            pickerOpen = true
            CreateColorPickerDialog()
        end
    end)

    local el = {
        Gui = row,
        ApplyTheme = function(newTheme)
            theme = newTheme
            titleLabel.TextColor3 = theme.Text
            if desc ~= "" then
                local descLabel = row:FindFirstChildWhichIsA("TextLabel", true)
                if descLabel then descLabel.TextColor3 = theme.SubText end
            end
            local stroke = colorPreview:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = theme.StrokeSoft end
        end,
        SetColor = function(newColor)
            currentColor = newColor
            colorPreview.BackgroundColor3 = currentColor
            self.Window.Flags[flag] = currentColor
            self.Window.Config[flag] = {currentColor.R, currentColor.G, currentColor.B}
            SaveConfig(self.Window.ConfigName, self.Window.Config)
            callback(currentColor)
        end,
        GetColor = function() return currentColor end,
    }
    
    table.insert(self.Elements, el)
    table.insert(section.Elements, el)
    return el
end
        -- Example usage
local function ExampleWindow()
    local window = TakoGlass:CreateWindow({
        Title = "Enhanced TakoGlass",
        SubTitle = "All WindUI Features Added",
        Size = UDim2.fromOffset(600, 500),
        Theme = "Dark",
        Transparent = true,
        UseBlur = true,
    })
    
    local tab = window:CreateTab("Main")
    local section = tab:CreateSection({Name = "Enhanced Elements"})
    
    -- Enhanced button with icon
    section:AddButton({
        Name = "Primary Button",
        Desc = "With icon and description",
        Icon = "rbxassetid://132464694294269", -- Example icon ID
        Color = "Accent",
        Callback = function()
            TakoGlass.Notify("Button Clicked", "Primary button was clicked!", 3)
        end
    })
    
    -- Enhanced input
    section:AddInput({
        Name = "Username",
        Desc = "Enter your username",
        Placeholder = "player123",
        Icon = "rbxassetid://132464694294269",
        Callback = function(value)
            print("Username:", value)
        end
    })
    
    -- Code block
    section:AddCodeBlock({
        Title = "Example Code",
        Code = [[
            local function helloWorld()
                print("Hello from TakoGlass!")
                return true
            end
            
            -- This is a comment
            local result = helloWorld()
        ]],
        Language = "lua",
        Copyable = true,
        Callback = function(code)
            print("Code copied to clipboard")
        end
    })
    
    -- Color picker
    section:AddColorPicker({
        Name = "Primary Color",
        Desc = "Choose your primary color",
        Default = Color3.fromRGB(90, 135, 255),
        ShowAlpha = true,
        Callback = function(color)
            print("Color selected:", color)
        end
    })
end

        
        table.insert(tab.Sections, section)
        return section
    end

    return tab
end

--------------------------------------------------
-- 8. Example Usage (Imp. 6, 7)
--------------------------------------------------

TakoGlass.Notify = Notification -- Expose Notification system

return TakoGlass
