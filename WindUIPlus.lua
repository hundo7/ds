-- TakoLib UI Library (WindUI-like skin)
-- Drop-in replacement for previous TakoLib

local TakoLib = {}
TakoLib.__index = TakoLib

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Config
local CONFIG_FOLDER = "TakoLibConfigs"
local DEFAULT_THEME = "Dark"

local Themes = {
    Dark = {
        WindowBg   = Color3.fromRGB(12, 12, 18),
        TopbarBg   = Color3.fromRGB(18, 18, 28),
        SidebarBg  = Color3.fromRGB(14, 14, 22),
        CardBg     = Color3.fromRGB(20, 20, 30),
        ElementBg  = Color3.fromRGB(26, 26, 40),
        Accent     = Color3.fromRGB(90, 130, 255),
        AccentSoft = Color3.fromRGB(60, 90, 200),
        Text       = Color3.fromRGB(235, 235, 240),
        SubText    = Color3.fromRGB(150, 150, 170),
        Border     = Color3.fromRGB(45, 45, 65),
        Shadow     = Color3.fromRGB(0, 0, 0)
    },
    Light = {
        WindowBg   = Color3.fromRGB(245, 247, 255),
        TopbarBg   = Color3.fromRGB(235, 239, 255),
        SidebarBg  = Color3.fromRGB(235, 239, 255),
        CardBg     = Color3.fromRGB(250, 250, 255),
        ElementBg  = Color3.fromRGB(240, 242, 255),
        Accent     = Color3.fromRGB(60, 120, 255),
        AccentSoft = Color3.fromRGB(40, 90, 220),
        Text       = Color3.fromRGB(20, 22, 35),
        SubText    = Color3.fromRGB(90, 95, 120),
        Border     = Color3.fromRGB(200, 205, 230),
        Shadow     = Color3.fromRGB(0, 0, 0)
    }
}

-- Utility
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function DoTween(obj, goal, info)
    if not obj then return end
    local ti = TweenInfo.new(
        info and info[1] or 0.18,
        info and info[2] or Enum.EasingStyle.Quad,
        info and info[3] or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, ti, goal):Play()
end

local function EnsureFolder()
    if not isfolder or not makefolder then return end
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function SaveConfig(name, data)
    if not writefile then return end
    EnsureFolder()
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    writefile(path, HttpService:JSONEncode(data))
end

local function LoadConfig(name)
    if not readfile or not isfile then return {} end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then return {} end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and decoded or {}
end

--------------------------------------------------------
-- Soft shadow generator (fake)
--------------------------------------------------------
local function AddSoftShadow(parent, theme)
    local shadow = Create("ImageLabel", {
        Name = "SoftShadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 6),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 40, 1, 40),
        Image = "rbxassetid://1316045217", -- generic soft shadow sprite
        ImageTransparency = 0.6,
        ImageColor3 = theme.Shadow,
        ZIndex = parent.ZIndex - 1,
        Parent = parent.Parent
    })
    shadow:SetAttribute("Follow", parent.Name)
    return shadow
end

--------------------------------------------------------
-- Notifications (same API, cleaner look)
--------------------------------------------------------
function TakoLib.Notify(title, text, duration)
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not gui then return end

    local holderGui = gui:FindFirstChild("TakoLib_NotifyGui")
    if not holderGui then
        holderGui = Create("ScreenGui", {
            Name = "TakoLib_NotifyGui",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = gui
        })

        local listFrame = Create("Frame", {
            Name = "Holder",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -24, 1, -24),
            Size = UDim2.new(0, 320, 1, -48),
            BackgroundTransparency = 1,
            Parent = holderGui
        })

        local layout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 6),
            Parent = listFrame
        })

        listFrame:SetAttribute("HasLayout", true)
    end

    local t = Themes[DEFAULT_THEME]
    local listFrame = holderGui:FindFirstChild("Holder")

    local card = Create("Frame", {
        BackgroundColor3 = t.CardBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = listFrame
    })
    card.ZIndex = 20

    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
    Create("UIStroke", {
        Color = t.Border,
        Thickness = 1,
        Transparency = 0.25,
        Parent = card
    })

    local padding = Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = card
    })

    local titleLabel = Create("TextLabel", {
        Text = title or "Notification",
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextColor3 = t.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
        Parent = card
    })

    local bodyLabel = Create("TextLabel", {
        Text = text or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = t.SubText,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 32),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 21,
        Parent = card
    })

    local uiSize = Create("UISizeConstraint", {
        MaxSize = Vector2.new(320, 120),
        Parent = card
    })

    card.Size = UDim2.new(1, 0, 0, 0)
    DoTween(card, { Size = UDim2.new(1, 0, 0, 70) })

    task.spawn(function()
        task.wait(duration or 4)
        DoTween(card, { Size = UDim2.new(1, 0, 0, 0) })
        task.wait(0.2)
        card:Destroy()
    end)
end

--------------------------------------------------------
-- Window
--------------------------------------------------------
function TakoLib:CreateWindow(opts)
    local self = setmetatable({}, TakoLib)

    self.Title = opts.Title or "Tako Hub"
    self.SubTitle = opts.SubTitle or ""
    self.Icon = opts.Icon -- optional ImageId
    self.Key = opts.ConfigName or self.Title
    self.ThemeName = opts.Theme or DEFAULT_THEME
    self.Flags = {}
    self.Config = LoadConfig(self.Key)
    if self.Config.__Theme then
        self.ThemeName = self.Config.__Theme
    end

    local t = Themes[self.ThemeName] or Themes[DEFAULT_THEME]

    local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then error("No PlayerGui") end

    local gui = Create("ScreenGui", {
        Name = "TakoLib_" .. self.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = pg
    })

    -- Main window
    local main = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 620, 0, 420),
        BackgroundColor3 = t.WindowBg,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = gui
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = main })
    Create("UIStroke", {
        Color = t.Border,
        Thickness = 1,
        Transparency = 0.2,
        Parent = main
    })

    AddSoftShadow(main, t)

    -- Topbar
    local top = Create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = t.TopbarBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = main,
        ZIndex = 11
    })
    Create("UICorner", {
        CornerRadius = UDim.new(0, 14),
        Parent = top
    })

    local topPad = Create("UIPadding", {
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 10),
        Parent = top
    })

    -- Icon
    if self.Icon then
        local icon = Create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Image = self.Icon,
            ZIndex = 12,
            Parent = top
        })
        icon.ImageColor3 = t.Accent
    end

    local titleLabel = Create("TextLabel", {
        Text = self.Title,
        Font = Enum.Font.GothamSemibold,
        TextSize = 16,
        TextColor3 = t.Text,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(self.Icon and 0, self.Icon and 26 or 2, 0.5, -7),
        Size = UDim2.new(0.6, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = top
    })

    local subtitleLabel = Create("TextLabel", {
        Text = self.SubTitle,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = t.SubText,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(self.Icon and 0, self.Icon and 26 or 2, 0.5, 10),
        Size = UDim2.new(0.6, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
        Parent = top
    })

    -- Theme & close buttons (top-right)
    local themeBtn = Create("TextButton", {
        Text = "Theme",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = t.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 0, 40),
        Position = UDim2.new(1, -90, 0, 0),
        ZIndex = 12,
        Parent = top
    })

    local closeBtn = Create("TextButton", {
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = t.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -40, 0, 0),
        ZIndex = 12,
        Parent = top
    })

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    themeBtn.MouseButton1Click:Connect(function()
        local newTheme = self.ThemeName == "Dark" and "Light" or "Dark"
        self:SetTheme(newTheme)
    end)

    -- Drag window (topbar)
    do
        local dragging = false
        local dragStart, startPos

        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)

        top.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Sidebar (tabs)
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = t.SidebarBg,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 150, 1, -40),
        ZIndex = 10,
        Parent = main
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = sidebar })

    local sidePad = Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebar
    })

    local tabList = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 6),
        Parent = sidebar
    })

    -- Main content area
    local contentFrame = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 150, 0, 40),
        Size = UDim2.new(1, -150, 1, -40),
        ZIndex = 10,
        Parent = main
    })

    self.Gui = gui
    self.Main = main
    self.Topbar = top
    self.Sidebar = sidebar
    self.TabList = sidebar
    self.Content = contentFrame
    self.TitleLabel = titleLabel
    self.SubTitleLabel = subtitleLabel
    self.Tabs = {}

    -- Apply theme
    self:SetTheme(self.ThemeName)

    return self
end

--------------------------------------------------------
-- Theme switch (updates everything)
--------------------------------------------------------
function TakoLib:SetTheme(name)
    if not Themes[name] then return end
    self.ThemeName = name
    local t = Themes[name]

    self.Main.BackgroundColor3 = t.WindowBg
    local mainStroke = self.Main:FindFirstChildOfClass("UIStroke")
    if mainStroke then
        mainStroke.Color = t.Border
        mainStroke.Transparency = 0.2
    end

    self.Topbar.BackgroundColor3 = t.TopbarBg
    self.TitleLabel.TextColor3 = t.Text
    self.SubTitleLabel.TextColor3 = t.SubText

    self.Sidebar.BackgroundColor3 = t.SidebarBg

    for _, tab in ipairs(self.Tabs) do
        tab:ApplyTheme(t)
    end

    self.Config.__Theme = name
    SaveConfig(self.Key, self.Config)
end

--------------------------------------------------------
-- Tabs / Sections / Elements (WindUI-like)
--------------------------------------------------------
function TakoLib:CreateTab(name)
    local t = Themes[self.ThemeName]

    local btn = Create("TextButton", {
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = t.SubText,
        BackgroundColor3 = t.SidebarBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 28),
        ZIndex = 11,
        Parent = self.TabList
    })
    local btnCorner = Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = btn
    })

    local page = Create("ScrollingFrame", {
        Name = name .. "_Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        Visible = false,
        Parent = self.Content,
        ZIndex = 10
    })

    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })

    local pad = Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = page
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)

    local tab = {}
    tab.Window = self
    tab.Button = btn
    tab.Page = page
    tab.Sections = {}

    function tab:SetActive()
        for _, t2 in ipairs(self.Window.Tabs) do
            t2.Page.Visible = false
            DoTween(t2.Button, {
                BackgroundColor3 = Themes[self.Window.ThemeName].SidebarBg,
                TextColor3 = Themes[self.Window.ThemeName].SubText
            })
        end
        self.Page.Visible = true
        DoTween(self.Button, {
            BackgroundColor3 = Themes[self.Window.ThemeName].ElementBg,
            TextColor3 = Themes[self.Window.ThemeName].Text
        })
    end

    function tab:ApplyTheme(tTheme)
        DoTween(self.Button, {
            BackgroundColor3 = tTheme.SidebarBg,
            TextColor3 = tTheme.SubText
        })
        for _, sec in ipairs(self.Sections) do
            sec:ApplyTheme(tTheme)
        end
    end

    function tab:CreateSection(title)
        local tTheme = Themes[self.Window.ThemeName]

        local card = Create("Frame", {
            BackgroundColor3 = tTheme.CardBg,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 80),
            ZIndex = 10,
            Parent = self.Page
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = card })
        local stroke = Create("UIStroke", {
            Color = tTheme.Border,
            Thickness = 1,
            Transparency = 0.4,
            Parent = card
        })

        local cardPad = Create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = card
        })

        local titleLabel = Create("TextLabel", {
            Text = title,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextColor3 = tTheme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
            Parent = card
        })

        local divider = Create("Frame", {
            BackgroundColor3 = tTheme.Border,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 24),
            BackgroundTransparency = 0.4,
            ZIndex = 11,
            Parent = card
        })

        local container = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 28),
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 11,
            Parent = card
        })

        local cLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),
            Parent = container
        })

        cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.Size = UDim2.new(1, 0, 0, cLayout.AbsoluteContentSize.Y)
            card.Size = UDim2.new(1, 0, 0, 32 + cLayout.AbsoluteContentSize.Y + 6)
        end)

        local section = {}
        section.Window = self.Window
        section.Tab = self
        section.Card = card
        section.Container = container

        function section:ApplyTheme(th)
            card.BackgroundColor3 = th.CardBg
            stroke.Color = th.Border
            titleLabel.TextColor3 = th.Text
            divider.BackgroundColor3 = th.Border
        end

        -- button element
        function section:AddButton(opt)
            opt = opt or {}
            local text = opt.Name or "Button"
            local callback = opt.Callback or function() end
            local th = Themes[self.Window.ThemeName]

            local btn = Create("TextButton", {
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundColor3 = th.ElementBg,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 26),
                ZIndex = 11,
                Parent = self.Container
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

            btn.MouseEnter:Connect(function()
                DoTween(btn, { BackgroundColor3 = th.AccentSoft })
            end)
            btn.MouseLeave:Connect(function()
                DoTween(btn, { BackgroundColor3 = th.ElementBg })
            end)

            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)

            return btn
        end

        -- toggle element
        function section:AddToggle(opt)
            opt = opt or {}
            local name = opt.Name or "Toggle"
            local flag = opt.Flag or ("Tako_Toggle_" .. name)
            local default = opt.Default or false
            local callback = opt.Callback or function() end
            local th = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 11,
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = row
            })

            local box = Create("Frame", {
                Size = UDim2.new(0, 30, 0, 14),
                Position = UDim2.new(1, -30, 0.5, -7),
                BackgroundColor3 = self.Window.Flags[flag] and th.Accent or th.ElementBg,
                BorderSizePixel = 0,
                ZIndex = 11,
                Parent = row
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = box })

            local knob = Create("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = self.Window.Flags[flag] and UDim2.new(1, -14, 0, 0) or UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 12,
                Parent = box
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = knob })

            local function setVal(v)
                self.Window.Flags[flag] = v
                self.Window.Config[flag] = v
                SaveConfig(self.Window.Key, self.Window.Config)

                DoTween(box, {
                    BackgroundColor3 = v and th.Accent or th.ElementBg
                })
                DoTween(knob, {
                    Position = v and UDim2.new(1, -14, 0, 0) or UDim2.new(0, 0, 0, 0)
                })

                pcall(callback, v)
            end

            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setVal(not self.Window.Flags[flag])
                end
            end)

            return {
                Set = setVal,
                Get = function() return self.Window.Flags[flag] end
            }
        end

        -- slider element
        function section:AddSlider(opt)
            opt = opt or {}
            local name = opt.Name or "Slider"
            local min = opt.Min or 0
            local max = opt.Max or 100
            local default = opt.Default or min
            local flag = opt.Flag or ("Tako_Slider_" .. name)
            local callback = opt.Callback or function() end
            local th = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                ZIndex = 11,
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = row
            })

            local valueLabel = Create("TextLabel", {
                Text = tostring(self.Window.Flags[flag]),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = th.SubText,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0.4, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 11,
                Parent = row
            })

            local barBg = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = th.ElementBg,
                BorderSizePixel = 0,
                ZIndex = 11,
                Parent = row
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = barBg })

            local percent = (self.Window.Flags[flag] - min) / (max - min)
            local fill = Create("Frame", {
                Size = UDim2.new(percent, 0, 1, 0),
                BackgroundColor3 = th.Accent,
                BorderSizePixel = 0,
                ZIndex = 11,
                Parent = barBg
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })

            local dragging = false

            local function setFromPos(px)
                local rel = math.clamp((px - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max - min) * rel + 0.5)
                self.Window.Flags[flag] = val
                self.Window.Config[flag] = val
                SaveConfig(self.Window.Key, self.Window.Config)

                fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
                valueLabel.Text = tostring(val)
                pcall(callback, val)
            end

            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setFromPos(input.Position.X)
                end
            end)
            barBg.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromPos(input.Position.X)
                end
            end)

            return {
                Set = function(v)
                    v = math.clamp(v, min, max)
                    self.Window.Flags[flag] = v
                    self.Window.Config[flag] = v
                    SaveConfig(self.Window.Key, self.Window.Config)
                    local p = (v - min) / (max - min)
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    valueLabel.Text = tostring(v)
                    pcall(callback, v)
                end
            }
        end

        -- dropdown
        function section:AddDropdown(opt)
            opt = opt or {}
            local name = opt.Name or "Dropdown"
            local list = opt.Options or {}
            local default = opt.Default or list[1]
            local flag = opt.Flag or ("Tako_Drop_" .. name)
            local callback = opt.Callback or function() end
            local th = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                ZIndex = 11,
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = row
            })

            local button = Create("TextButton", {
                Text = tostring(self.Window.Flags[flag]),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundColor3 = th.ElementBg,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.6, 0, 0, 24),
                ZIndex = 11,
                Parent = row
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })

            local listFrame = Create("Frame", {
                BackgroundColor3 = th.CardBg,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 170, 0, 0),
                Visible = false,
                ZIndex = 20,
                Parent = row
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = listFrame })
            Create("UIStroke", { Color = th.Border, Thickness = 1, Transparency = 0.3, Parent = listFrame })

            local sFrame = Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ZIndex = 21,
                Parent = listFrame
            })

            local lsLayout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 2),
                Parent = sFrame
            })

            local function rebuild()
                for _, child in ipairs(sFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for _, v in ipairs(list) do
                    local optBtn = Create("TextButton", {
                        Text = tostring(v),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = th.Text,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -6, 0, 22),
                        ZIndex = 21,
                        Parent = sFrame
                    })

                    optBtn.MouseButton1Click:Connect(function()
                        self.Window.Flags[flag] = v
                        self.Window.Config[flag] = v
                        SaveConfig(self.Window.Key, self.Window.Config)
                        button.Text = tostring(v)
                        listFrame.Visible = false
                        pcall(callback, v)
                    end)
                end

                sFrame.CanvasSize = UDim2.new(0, 0, 0, lsLayout.AbsoluteContentSize.Y + 4)
                listFrame.Size = UDim2.new(0, 170, 0, math.min(lsLayout.AbsoluteContentSize.Y + 4, 140))
            end

            lsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sFrame.CanvasSize = UDim2.new(0, 0, 0, lsLayout.AbsoluteContentSize.Y + 4)
            end)

            rebuild()

            button.MouseButton1Click:Connect(function()
                listFrame.Visible = not listFrame.Visible
            end)

            return {
                Set = function(v)
                    self.Window.Flags[flag] = v
                    self.Window.Config[flag] = v
                    SaveConfig(self.Window.Key, self.Window.Config)
                    button.Text = tostring(v)
                    pcall(callback, v)
                end,
                Refresh = function(newList)
                    list = newList
                    rebuild()
                end
            }
        end

        -- input
        function section:AddInput(opt)
            opt = opt or {}
            local name = opt.Name or "Input"
            local flag = opt.Flag or ("Tako_Input_" .. name)
            local default = opt.Default or ""
            local placeholder = opt.Placeholder or ""
            local callback = opt.Callback or function() end
            local th = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                ZIndex = 11,
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.35, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = row
            })

            local box = Create("TextBox", {
                Text = tostring(self.Window.Flags[flag]),
                PlaceholderText = placeholder,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundColor3 = th.ElementBg,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.65, 0, 0, 24),
                ClearTextOnFocus = false,
                ZIndex = 11,
                Parent = row
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })

            box.FocusLost:Connect(function(enter)
                self.Window.Flags[flag] = box.Text
                self.Window.Config[flag] = box.Text
                SaveConfig(self.Window.Key, self.Window.Config)
                pcall(callback, box.Text, enter)
            end)

            return {
                Set = function(v)
                    v = tostring(v)
                    self.Window.Flags[flag] = v
                    self.Window.Config[flag] = v
                    SaveConfig(self.Window.Key, self.Window.Config)
                    box.Text = v
                    pcall(callback, v, false)
                end
            }
        end

        -- keybind
        function section:AddKeybind(opt)
            opt = opt or {}
            local name = opt.Name or "Keybind"
            local flag = opt.Flag or ("Tako_Key_" .. name)
            local default = opt.Default or Enum.KeyCode.RightShift
            local mode = opt.Mode or "Toggle"
            local callback = opt.Callback or function() end
            local th = Themes[self.Window.ThemeName]

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default.Name
            end

            local stored = Enum.KeyCode[self.Window.Config[flag]] or default
            self.Window.Flags[flag] = stored

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                ZIndex = 11,
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
                Parent = row
            })

            local btn = Create("TextButton", {
                Text = stored.Name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = th.Text,
                BackgroundColor3 = th.ElementBg,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.5, 0, 0, 24),
                ZIndex = 11,
                Parent = row
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

            local binding = false
            btn.MouseButton1Click:Connect(function()
                btn.Text = "..."
                binding = true
            end)

            local toggled = false

            UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end

                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false
                    self.Window.Flags[flag] = input.KeyCode
                    self.Window.Config[flag] = input.KeyCode.Name
                    SaveConfig(self.Window.Key, self.Window.Config)
                    btn.Text = input.KeyCode.Name
                    return
                end

                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.Window.Flags[flag] then
                    if mode == "Toggle" then
                        toggled = not toggled
                        pcall(callback, toggled)
                    elseif mode == "Hold" then
                        pcall(callback, true)
                    end
                end
            end)

            UserInputService.InputEnded:Connect(function(input, gpe)
                if gpe then return end
                if mode == "Hold" and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.Window.Flags[flag] then
                    pcall(callback, false)
                end
            end)

            return {
                Set = function(keycode)
                    self.Window.Flags[flag] = keycode
                    self.Window.Config[flag] = keycode.Name
                    SaveConfig(self.Window.Key, self.Window.Config)
                    btn.Text = keycode.Name
                end
            }
        end

        table.insert(self.Sections, section)
        return section
    end

    btn.MouseButton1Click:Connect(function()
        tab:SetActive()
    end)

    if #self.Tabs == 0 then
        tab:SetActive()
    end

    table.insert(self.Tabs, tab)
    return tab
end

return TakoLib
