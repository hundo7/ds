-- WindUIPlus Library
-- Inspired by Rayfield/Linoria style UI for Roblox
-- This is a basic implementation. For full features, consider expanding it.

local WindUIPlus = {}
WindUIPlus.__index = WindUIPlus

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Configuration
local ConfigFolder = "WindUIPlusConfigs"
local DefaultTheme = "Dark"
local Themes = {
    Dark = {
        Background = Color3.fromRGB(30, 30, 30),
        Accent = Color3.fromRGB(100, 100, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(50, 50, 50),
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Accent = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(0, 0, 0),
        Border = Color3.fromRGB(200, 200, 200),
    },
    Custom = {} -- User can set
}

-- Utility Functions
local function CreateInstance(class, props)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    return inst
end

local function Tween(obj, props, info)
    TweenService:Create(obj, TweenInfo.new(unpack(info or {0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out})), props):Play()
end

local function SaveConfig(windowTitle, config)
    if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    writefile(ConfigFolder .. "/" .. windowTitle .. ".json", HttpService:JSONEncode(config))
end

local function LoadConfig(windowTitle)
    if isfile(ConfigFolder .. "/" .. windowTitle .. ".json") then
        return HttpService:JSONDecode(readfile(ConfigFolder .. "/" .. windowTitle .. ".json"))
    end
    return {}
end

-- Notification System
function WindUIPlus:Notify(title, desc, duration)
    local notif = CreateInstance("Frame", {
        Size = UDim2.new(0, 300, 0, 80),
        Position = UDim2.new(1, -310, 1, -90),
        BackgroundColor3 = Themes[DefaultTheme].Background,
        BorderSizePixel = 0,
        Parent = game.Players.LocalPlayer.PlayerGui:FindFirstChild("WindUIPlusGui") or CreateInstance("ScreenGui", {Name = "WindUIPlusGui", Parent = game.Players.LocalPlayer.PlayerGui})
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = notif})
    local titleLabel = CreateInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = Themes[DefaultTheme].Text,
        Parent = notif
    })
    local descLabel = CreateInstance("TextLabel", {
        Text = desc,
        Size = UDim2.new(1, 0, 1, -20),
        BackgroundTransparency = 1,
        TextColor3 = Themes[DefaultTheme].Text,
        Parent = notif
    })
    Tween(notif, {Position = UDim2.new(1, -310, 1, -100)}, {duration or 0.5})
    wait(duration or 5)
    Tween(notif, {Position = UDim2.new(1, 0, 1, -100)}, {0.5})
    wait(0.5)
    notif:Destroy()
end

-- Create Window
function WindUIPlus:CreateWindow(options)
    local self = setmetatable({}, WindUIPlus)
    self.Title = options.Title or "WindUIPlus"
    self.Config = LoadConfig(self.Title)
    self.Theme = DefaultTheme
    self.Flags = {}

    -- Main Gui
    self.Gui = CreateInstance("ScreenGui", {
        Name = "WindUIPlus_" .. self.Title,
        Parent = game.Players.LocalPlayer.PlayerGui
    })

    -- Window Frame
    self.Window = CreateInstance("Frame", {
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundColor3 = Themes[self.Theme].Background,
        BorderSizePixel = 0,
        Parent = self.Gui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Window})
    CreateInstance("UIStroke", {Color = Themes[self.Theme].Border, Parent = self.Window})

    -- Title Bar
    self.TitleBar = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Themes[self.Theme].Accent,
        Parent = self.Window
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.TitleBar, CornerRadius = UDim.new(0, 8)}) -- Top only if needed

    self.TitleLabel = CreateInstance("TextLabel", {
        Text = self.Title,
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Themes[self.Theme].Text,
        Parent = self.TitleBar
    })

    -- Close Button
    local closeBtn = CreateInstance("TextButton", {
        Text = "X",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Themes[self.Theme].Text,
        Parent = self.TitleBar
    })
    closeBtn.MouseButton1Click:Connect(function()
        self.Gui:Destroy()
    end)

    -- Theme Button
    local themeBtn = CreateInstance("TextButton", {
        Text = "Theme",
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Themes[self.Theme].Text,
        Parent = self.TitleBar
    })
    themeBtn.MouseButton1Click:Connect(function()
        self:SetTheme(self.Theme == "Dark" and "Light" or "Dark")
    end)

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    self.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            self.Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Tab Holder
    self.TabHolder = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(0, 120, 1, -30),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        Parent = self.Window
    })
    CreateInstance("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.TabHolder})

    self.TabContainer = CreateInstance("Frame", {
        Size = UDim2.new(1, -120, 1, -30),
        Position = UDim2.new(0, 120, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Window
    })

    self.Tabs = {}
    return self
end

-- Set Theme
function WindUIPlus:SetTheme(theme)
    self.Theme = theme
    local t = Themes[theme]
    self.Window.BackgroundColor3 = t.Background
    self.TitleBar.BackgroundColor3 = t.Accent
    self.TitleLabel.TextColor3 = t.Text
    -- Update all elements recursively
    for _, child in ipairs(self.Window:GetDescendants()) do
        if child:IsA("Frame") and child.Name == "Section" then
            child.BackgroundColor3 = t.Background
        elseif child:IsA("TextLabel") then
            child.TextColor3 = t.Text
        -- Add more as needed
        end
    end
end

-- Create Tab
function WindUIPlus:CreateTab(name)
    local tabBtn = CreateInstance("TextButton", {
        Text = name,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Themes[self.Theme].Border,
        TextColor3 = Themes[self.Theme].Text,
        Parent = self.TabHolder
    })
    CreateInstance("UICorner", {Parent = tabBtn})

    local tabFrame = CreateInstance("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        Visible = false,
        Parent = self.TabContainer
    })
    CreateInstance("UIListLayout", {Padding = UDim.new(0, 5), Parent = tabFrame})

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            t.Frame.Visible = false
        end
        tabFrame.Visible = true
    end)

    table.insert(self.Tabs, {Button = tabBtn, Frame = tabFrame})
    if #self.Tabs == 1 then tabFrame.Visible = true end

    local tab = {}
    tab.Sections = {}

    -- Create Section
    function tab:CreateSection(name)
        local section = CreateInstance("Frame", {
            Name = "Section",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Themes[self.Theme].Background,
            Parent = tabFrame
        })
        CreateInstance("UICorner", {Parent = section})
        CreateInstance("UIStroke", {Color = Themes[self.Theme].Border, Parent = section})

        local sectionTitle = CreateInstance("TextLabel", {
            Text = name,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            TextColor3 = Themes[self.Theme].Text,
            Parent = section
        })

        local sectionLayout = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = section
        })

        sectionLayout.Changed:Connect(function(prop)
            if prop == "AbsoluteContentSize" then
                section.Size = UDim2.new(1, 0, 0, sectionLayout.AbsoluteContentSize.Y + 10)
            end
        end)

        table.insert(tab.Sections, section)

        local elements = {}

        -- Add Button
        function elements:AddButton(options)
            local btn = CreateInstance("TextButton", {
                Text = options.Name or "Button",
                Size = UDim2.new(1, -10, 0, 30),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundColor3 = Themes[self.Theme].Accent,
                TextColor3 = Themes[self.Theme].Text,
                Parent = section
            })
            CreateInstance("UICorner", {Parent = btn})

            btn.MouseButton1Click:Connect(options.Callback or function() end)
        end

        -- Add Toggle
        function elements:AddToggle(options)
            local flag = options.Flag or "Toggle_" .. #self.Flags
            self.Flags[flag] = self.Config[flag] or options.Default or false

            local toggleFrame = CreateInstance("Frame", {
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundTransparency = 1,
                Parent = section
            })

            local toggleLabel = CreateInstance("TextLabel", {
                Text = options.Name or "Toggle",
                Size = UDim2.new(1, -40, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = Themes[self.Theme].Text,
                Parent = toggleFrame
            })

            local toggleBtn = CreateInstance("Frame", {
                Size = UDim2.new(0, 30, 0, 15),
                Position = UDim2.new(1, -30, 0.5, -7.5),
                BackgroundColor3 = self.Flags[flag] and Themes[self.Theme].Accent or Themes[self.Theme].Border,
                Parent = toggleFrame
            })
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = toggleBtn})

            toggleFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    self.Flags[flag] = not self.Flags[flag]
                    Tween(toggleBtn, {BackgroundColor3 = self.Flags[flag] and Themes[self.Theme].Accent or Themes[self.Theme].Border})
                    if options.Callback then options.Callback(self.Flags[flag]) end
                    self.Config[flag] = self.Flags[flag]
                    SaveConfig(self.Title, self.Config)
                end
            end)
        end

        -- Add Slider
        function elements:AddSlider(options)
            local flag = options.Flag or "Slider_" .. #self.Flags
            self.Flags[flag] = self.Config[flag] or options.Default or options.Min or 0

            local sliderFrame = CreateInstance("Frame", {
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundTransparency = 1,
                Parent = section
            })

            local sliderLabel = CreateInstance("TextLabel", {
                Text = options.Name or "Slider",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                TextColor3 = Themes[self.Theme].Text,
                Parent = sliderFrame
            })

            local sliderBar = CreateInstance("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = Themes[self.Theme].Border,
                Parent = sliderFrame
            })
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = sliderBar})

            local sliderFill = CreateInstance("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Themes[self.Theme].Accent,
                Parent = sliderBar
            })
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = sliderFill})

            local sliderValue = CreateInstance("TextLabel", {
                Text = tostring(self.Flags[flag]),
                Size = UDim2.new(0, 50, 0, 20),
                Position = UDim2.new(1, -50, 0, 20),
                BackgroundTransparency = 1,
                TextColor3 = Themes[self.Theme].Text,
                Parent = sliderFrame
            })

            local min, max = options.Min or 0, options.Max or 100
            local function updateValue(pos)
                local perc = math.clamp((pos - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                self.Flags[flag] = math.floor(min + (max - min) * perc)
                sliderFill.Size = UDim2.new(perc, 0, 1, 0)
                sliderValue.Text = tostring(self.Flags[flag])
                if options.Callback then options.Callback(self.Flags[flag]) end
                self.Config[flag] = self.Flags[flag]
                SaveConfig(self.Title, self.Config)
            end

            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    updateValue(input.Position.X)
                    local conn
                    conn = UserInputService.InputChanged:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseMovement then
                            updateValue(inp.Position.X)
                        end
                    end)
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            conn:Disconnect()
                        end
                    end)
                end
            end)

            -- Set initial
            local initialPerc = (self.Flags[flag] - min) / (max - min)
            sliderFill.Size = UDim2.new(initialPerc, 0, 1, 0)
            sliderValue.Text = tostring(self.Flags[flag])
        end

        -- Add Dropdown
        function elements:AddDropdown(options)
            local flag = options.Flag or "Dropdown_" .. #self.Flags
            self.Flags[flag] = self.Config[flag] or options.Default or options.Options[1]

            local dropdownFrame = CreateInstance("Frame", {
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundTransparency = 1,
                Parent = section
            })

            local dropdownBtn = CreateInstance("TextButton", {
                Text = self.Flags[flag],
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Themes[self.Theme].Border,
                TextColor3 = Themes[self.Theme].Text,
                Parent = dropdownFrame
            })
            CreateInstance("UICorner", {Parent = dropdownBtn})

            local dropdownList = CreateInstance("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Themes[self.Theme].Background,
                Visible = false,
                ScrollBarThickness = 0,
                Parent = dropdownBtn
            })
            CreateInstance("UIListLayout", {Parent = dropdownList})

            local function toggleList()
                dropdownList.Visible = not dropdownList.Visible
                dropdownList.Size = dropdownList.Visible and UDim2.new(1, 0, 0, math.min(#options.Options * 25, 100)) or UDim2.new(1, 0, 0, 0)
            end

            dropdownBtn.MouseButton1Click:Connect(toggleList)

            for _, opt in ipairs(options.Options or {}) do
                local optBtn = CreateInstance("TextButton", {
                    Text = opt,
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundTransparency = 1,
                    TextColor3 = Themes[self.Theme].Text,
                    Parent = dropdownList
                })
                optBtn.MouseButton1Click:Connect(function()
                    self.Flags[flag] = opt
                    dropdownBtn.Text = opt
                    toggleList()
                    if options.Callback then options.Callback(opt) end
                    self.Config[flag] = opt
                    SaveConfig(self.Title, self.Config)
                end)
            end
        end

        -- Add Text Input
        function elements:AddInput(options)
            local flag = options.Flag or "Input_" .. #self.Flags
            self.Flags[flag] = self.Config[flag] or options.Default or ""

            local inputFrame = CreateInstance("Frame", {
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundTransparency = 1,
                Parent = section
            })

            local inputBox = CreateInstance("TextBox", {
                Text = self.Flags[flag],
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Themes[self.Theme].Border,
                TextColor3 = Themes[self.Theme].Text,
                Parent = inputFrame
            })
            CreateInstance("UICorner", {Parent = inputBox})

            inputBox.FocusLost:Connect(function()
                self.Flags[flag] = inputBox.Text
                if options.Callback then options.Callback(inputBox.Text) end
                self.Config[flag] = inputBox.Text
                SaveConfig(self.Title, self.Config)
            end)
        end

        -- Add Keybind
        function elements:AddKeybind(options)
            local flag = options.Flag or "Keybind_" .. #self.Flags
            self.Flags[flag] = self.Config[flag] or options.Default or Enum.KeyCode.Unknown

            local keybindFrame = CreateInstance("Frame", {
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundTransparency = 1,
                Parent = section
            })

            local keybindLabel = CreateInstance("TextLabel", {
                Text = options.Name or "Keybind",
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = Themes[self.Theme].Text,
                Parent = keybindFrame
            })

            local keybindBtn = CreateInstance("TextButton", {
                Text = self.Flags[flag].Name or "None",
                Size = UDim2.new(0, 60, 1, 0),
                Position = UDim2.new(1, -60, 0, 0),
                BackgroundColor3 = Themes[self.Theme].Border,
                TextColor3 = Themes[self.Theme].Text,
                Parent = keybindFrame
            })
            CreateInstance("UICorner", {Parent = keybindBtn})

            local binding = false
            keybindBtn.MouseButton1Click:Connect(function()
                binding = true
                keybindBtn.Text = "..."
            end)

            UserInputService.InputBegan:Connect(function(input)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    self.Flags[flag] = input.KeyCode
                    keybindBtn.Text = input.KeyCode.Name
                    binding = false
                    if options.Callback then options.Callback(input.KeyCode) end
                    self.Config[flag] = input.KeyCode.Name -- Save as string
                    SaveConfig(self.Title, self.Config)
                end
            end)
        end

        return elements
    end

    return tab
end

return WindUIPlus
