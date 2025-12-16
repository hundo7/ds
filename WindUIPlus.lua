-- TakoLib UI Library
-- Simple Rayfield/Linoria-style UI made just for you

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
        Background = Color3.fromRGB(20, 20, 25),
        Accent     = Color3.fromRGB(120, 90, 255),
        Text       = Color3.fromRGB(235, 235, 240),
        SubText    = Color3.fromRGB(170, 170, 180),
        Border     = Color3.fromRGB(40, 40, 50)
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        Accent     = Color3.fromRGB(0, 120, 255),
        Text       = Color3.fromRGB(10, 10, 15),
        SubText    = Color3.fromRGB(90, 90, 100),
        Border     = Color3.fromRGB(210, 210, 220)
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
    local ti = TweenInfo.new(
        info and info[1] or 0.2,
        info and info[2] or Enum.EasingStyle.Quad,
        info and info[3] or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, ti, goal):Play()
end

local function EnsureFolder()
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

----------------------------------------------------------------
-- Notifications
----------------------------------------------------------------
function TakoLib.Notify(title, text, duration)
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not gui then return end

    local holder = gui:FindFirstChild("TakoLib_Notifications")
    if not holder then
        holder = Create("ScreenGui", {
            Name = "TakoLib_Notifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = gui
        })

        local listFrame = Create("Frame", {
            Name = "Holder",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.new(0, 300, 1, -40),
            BackgroundTransparency = 1,
            Parent = holder
        })

        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 6),
            Parent = listFrame
        })
    end

    local theme = Themes[DEFAULT_THEME]

    local listFrame = holder:FindFirstChild("Holder")
    local notif = Create("Frame", {
        Size = UDim2.new(0, 0, 0, 70),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Parent = listFrame,
        ClipsDescendants = true
    })

    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
    Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = notif })

    local padding = Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = notif
    })

    local titleLabel = Create("TextLabel", {
        Text = title or "Notification",
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })

    local bodyLabel = Create("TextLabel", {
        Text = text or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -18),
        Position = UDim2.new(0, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = notif
    })

    notif.Size = UDim2.new(1, 0, 0, 0)
    DoTween(notif, { Size = UDim2.new(1, 0, 0, 70) }, {0.2})

    task.spawn(function()
        task.wait(duration or 4)
        DoTween(notif, { Size = UDim2.new(1, 0, 0, 0) }, {0.2})
        task.wait(0.2)
        notif:Destroy()
    end)
end

----------------------------------------------------------------
-- Window creation
----------------------------------------------------------------
function TakoLib:CreateWindow(options)
    local self = setmetatable({}, TakoLib)

    self.Title = options.Title or "TakoLib"
    self.SubTitle = options.SubTitle or ""
    self.Key = options.ConfigName or self.Title
    self.ThemeName = options.Theme or DEFAULT_THEME
    self.Flags = {}
    self.Connections = {}
    self.Config = LoadConfig(self.Key)

    local theme = Themes[self.ThemeName] or Themes[DEFAULT_THEME]

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then error("No PlayerGui") end

    self.Gui = Create("ScreenGui", {
        Name = "TakoLib_" .. self.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = pg
    })

    local main = Create("Frame", {
        Name = "Window",
        Size = UDim2.new(0, 480, 0, 320),
        Position = UDim2.new(0.5, -240, 0.5, -160),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Parent = self.Gui
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = main })
    Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = main })

    local topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = main
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = topbar })

    local titleLabel = Create("TextLabel", {
        Text = self.Title .. (self.SubTitle ~= "" and ("  |  " .. self.SubTitle) or ""),
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })

    local closeBtn = Create("TextButton", {
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        Parent = topbar
    })

    closeBtn.MouseButton1Click:Connect(function()
        self.Gui:Destroy()
    end)

    local themeBtn = Create("TextButton", {
        Text = "Theme",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
        Parent = topbar
    })

    themeBtn.MouseButton1Click:Connect(function()
        local newTheme = self.ThemeName == "Dark" and "Light" or "Dark"
        self:SetTheme(newTheme)
    end)

    -- Dragging
    do
        local dragging = false
        local dragStart, startPos

        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
            end
        end)

        topbar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        topbar.InputChanged:Connect(function(input)
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

    -- Left tab list
    local tabList = Create("Frame", {
        Name = "TabList",
        Size = UDim2.new(0, 130, 1, -32),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Parent = main
    })

    local tabListLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 4),
        Parent = tabList
    })

    local tabHolder = Create("Frame", {
        Name = "TabHolder",
        Size = UDim2.new(1, -130, 1, -32),
        Position = UDim2.new(0, 130, 0, 32),
        BackgroundTransparency = 1,
        Parent = main
    })

    self.Main = main
    self.Topbar = topbar
    self.TitleLabel = titleLabel
    self.TabList = tabList
    self.TabHolder = tabHolder
    self.Tabs = {}

    return self
end

----------------------------------------------------------------
-- Theme switch
----------------------------------------------------------------
function TakoLib:SetTheme(name)
    if not Themes[name] then return end
    self.ThemeName = name
    local t = Themes[name]

    self.Main.BackgroundColor3 = t.Background
    local stroke = self.Main:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Color = t.Border end

    self.Topbar.BackgroundColor3 = t.Accent
    self.TitleLabel.TextColor3 = t.Text

    for _, tab in ipairs(self.Tabs) do
        tab.Button.BackgroundColor3 = t.Border
        tab.Button.TextColor3 = t.Text
        tab:ApplyTheme(t)
    end

    self.Config.__Theme = name
    SaveConfig(self.Key, self.Config)
end

----------------------------------------------------------------
-- Tabs / Sections / Elements
----------------------------------------------------------------
function TakoLib:CreateTab(name)
    local theme = Themes[self.ThemeName]

    local btn = Create("TextButton", {
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Text,
        BackgroundColor3 = theme.Border,
        Size = UDim2.new(1, -8, 0, 28),
        Parent = self.TabList
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

    local page = Create("ScrollingFrame", {
        Name = name .. "_Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self.TabHolder
    })

    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local tab = {}
    tab.Window = self
    tab.Name = name
    tab.Button = btn
    tab.Page = page
    tab.Sections = {}

    function tab:SetActive()
        for _, t in ipairs(self.Window.Tabs) do
            t.Page.Visible = false
        end
        self.Page.Visible = true
    end

    function tab:ApplyTheme(t)
        for _, section in ipairs(self.Sections) do
            section:ApplyTheme(t)
        end
    end

    function tab:CreateSection(secName)
        local theme = Themes[self.Window.ThemeName]

        local frame = Create("Frame", {
            Size = UDim2.new(1, -10, 0, 40),
            BackgroundColor3 = theme.Background,
            BorderSizePixel = 0,
            Parent = self.Page
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
        Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = frame })

        local secLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 4),
            Parent = frame
        })

        local secTitle = Create("TextLabel", {
            Text = secName,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextColor3 = theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 0, 18),
            Position = UDim2.new(0, 6, 0, 4),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame
        })

        local container = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -12, 0, 0),
            Position = UDim2.new(0, 6, 0, 22),
            Parent = frame
        })

        local containerLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 4),
            Parent = container
        })

        containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.Size = UDim2.new(1, -12, 0, containerLayout.AbsoluteContentSize.Y)
            frame.Size = UDim2.new(1, -10, 0, 26 + containerLayout.AbsoluteContentSize.Y + 6)
        end)

        local section = {}
        section.Window = self.Window
        section.Tab = self
        section.Frame = frame
        section.Container = container

        function section:ApplyTheme(t)
            frame.BackgroundColor3 = t.Background
            local s = frame:FindFirstChildOfClass("UIStroke")
            if s then s.Color = t.Border end
            secTitle.TextColor3 = t.Text
        end

        -- Button
        function section:AddButton(opt)
            opt = opt or {}
            local text = opt.Name or "Button"
            local callback = opt.Callback or function() end

            local b = Create("TextButton", {
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundColor3 = Themes[self.Window.ThemeName].Accent,
                Size = UDim2.new(1, 0, 0, 26),
                Parent = self.Container
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })

            b.MouseButton1Click:Connect(function()
                pcall(callback)
            end)

            return b
        end

        -- Toggle
        function section:AddToggle(opt)
            opt = opt or {}
            local name = opt.Name or "Toggle"
            local flag = opt.Flag or ("Tako_Toggle_" .. name)
            local default = opt.Default or false
            local callback = opt.Callback or function() end

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local holder = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder
            })

            local box = Create("Frame", {
                Size = UDim2.new(0, 28, 0, 14),
                Position = UDim2.new(1, -28, 0.5, -7),
                BackgroundColor3 = self.Window.Flags[flag] and Themes[self.Window.ThemeName].Accent or Themes[self.Window.ThemeName].Border,
                BorderSizePixel = 0,
                Parent = holder
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })

            local knob = Create("Frame", {
                Size = UDim2.new(0, 12, 0, 12),
                Position = self.Window.Flags[flag] and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = box
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = knob })

            local function setValue(v)
                self.Window.Flags[flag] = v
                self.Window.Config[flag] = v
                SaveConfig(self.Window.Key, self.Window.Config)

                DoTween(box, {
                    BackgroundColor3 = v and Themes[self.Window.ThemeName].Accent or Themes[self.Window.ThemeName].Border
                })
                DoTween(knob, {
                    Position = v and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6)
                })

                pcall(callback, v)
            end

            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setValue(not self.Window.Flags[flag])
                end
            end)

            return {
                Set = setValue,
                Get = function() return self.Window.Flags[flag] end
            }
        end

        -- Slider
        function section:AddSlider(opt)
            opt = opt or {}
            local name = opt.Name or "Slider"
            local min = opt.Min or 0
            local max = opt.Max or 100
            local default = opt.Default or min
            local flag = opt.Flag or ("Tako_Slider_" .. name)
            local callback = opt.Callback or function() end

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local frame = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame
            })

            local valueLabel = Create("TextLabel", {
                Text = tostring(self.Window.Flags[flag]),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Themes[self.Window.ThemeName].SubText,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 40, 0, 16),
                Position = UDim2.new(1, -40, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = frame
            })

            local bar = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 0, 22),
                BackgroundColor3 = Themes[self.Window.ThemeName].Border,
                BorderSizePixel = 0,
                Parent = frame
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = bar })

            local fill = Create("Frame", {
                Size = UDim2.new((self.Window.Flags[flag] - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Themes[self.Window.ThemeName].Accent,
                BorderSizePixel = 0,
                Parent = bar
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })

            local dragging = false

            local function setValueFromPos(x)
                local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max - min) * rel + 0.5)
                self.Window.Flags[flag] = val
                self.Window.Config[flag] = val
                SaveConfig(self.Window.Key, self.Window.Config)

                fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
                valueLabel.Text = tostring(val)
                pcall(callback, val)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setValueFromPos(input.Position.X)
                end
            end)

            bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setValueFromPos(input.Position.X)
                end
            end)

            return {
                Set = function(v)
                    v = math.clamp(v, min, max)
                    self.Window.Flags[flag] = v
                    self.Window.Config[flag] = v
                    SaveConfig(self.Window.Key, self.Window.Config)
                    fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
                    valueLabel.Text = tostring(v)
                    pcall(callback, v)
                end
            }
        end

        -- Dropdown
        function section:AddDropdown(opt)
            opt = opt or {}
            local name = opt.Name or "Dropdown"
            local list = opt.Options or {}
            local default = opt.Default or list[1]
            local flag = opt.Flag or ("Tako_Drop_" .. name)
            local callback = opt.Callback or function() end

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local frame = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 32),
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame
            })

            local button = Create("TextButton", {
                Text = tostring(self.Window.Flags[flag]),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundColor3 = Themes[self.Window.ThemeName].Border,
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Parent = frame
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })

            local listFrame = Create("Frame", {
                BackgroundColor3 = Themes[self.Window.ThemeName].Background,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 150, 0, 0),
                Visible = false,
                Parent = frame
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = listFrame })
            Create("UIStroke", { Color = Themes[self.Window.ThemeName].Border, Thickness = 1, Parent = listFrame })

            local sf = Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                Parent = listFrame
            })

            local listLayout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 2),
                Parent = sf
            })

            local function rebuild()
                for _, c in ipairs(sf:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end

                for _, v in ipairs(list) do
                    local optBtn = Create("TextButton", {
                        Text = tostring(v),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = Themes[self.Window.ThemeName].Text,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -4, 0, 20),
                        Parent = sf
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

                sf.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
                listFrame.Size = UDim2.new(0, 150, 0, math.min(listLayout.AbsoluteContentSize.Y + 4, 120))
            end

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sf.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
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

        -- Text Input
        function section:AddInput(opt)
            opt = opt or {}
            local name = opt.Name or "Input"
            local flag = opt.Flag or ("Tako_Input_" .. name)
            local default = opt.Default or ""
            local placeholder = opt.Placeholder or ""
            local callback = opt.Callback or function() end

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local frame = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 32),
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame
            })

            local box = Create("TextBox", {
                Text = tostring(self.Window.Flags[flag]),
                PlaceholderText = placeholder,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundColor3 = Themes[self.Window.ThemeName].Border,
                Size = UDim2.new(0.6, 0, 1, 0),
                Position = UDim2.new(0.4, 0, 0, 0),
                ClearTextOnFocus = false,
                Parent = frame
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })

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

        -- Keybind
        function section:AddKeybind(opt)
            opt = opt or {}
            local name = opt.Name or "Keybind"
            local flag = opt.Flag or ("Tako_Key_" .. name)
            local default = opt.Default or Enum.KeyCode.RightShift
            local mode = opt.Mode or "Toggle" -- "Toggle" | "Hold"
            local callback = opt.Callback or function() end

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default.Name
            end

            local stored = Enum.KeyCode[self.Window.Config[flag]] or default
            self.Window.Flags[flag] = stored

            local frame = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                Parent = self.Container
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame
            })

            local btn = Create("TextButton", {
                Text = stored.Name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Themes[self.Window.ThemeName].Text,
                BackgroundColor3 = Themes[self.Window.ThemeName].Border,
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Parent = frame
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

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
