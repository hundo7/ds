--[[
WindUIPlus
Single-file base UI library template
Style: Rayfield / Linoria inspired
No prints. Notifications only.
Designed to be extended like an open-source lib.
]]

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")nlocal UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Library Root
local Library = {}
Library.__index = Library

--// State
Library.Flags = {}
Library.Connections = {}
Library.Themes = {}
Library.CurrentTheme = "Dark"

--// ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WindUIPlus"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

--// =====================
--// Utility
--// =====================

local function Create(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

--// =====================
--// Notification System
--// =====================

local NotifyHolder = Create("Frame", {
    Parent = ScreenGui,
    AnchorPoint = Vector2.new(1,1),
    Position = UDim2.fromScale(1,1),
    Size = UDim2.fromScale(0,0),
    BackgroundTransparency = 1
})

Create("UIListLayout", {
    Parent = NotifyHolder,
    Padding = UDim.new(0,8),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom
})

function Library:Notify(title, text, duration)
    duration = duration or 3

    local Frame = Create("Frame", {
        Size = UDim2.fromOffset(280, 70),
        BackgroundColor3 = self.Themes[self.CurrentTheme].Surface,
        Parent = NotifyHolder
    })

    Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0,10)})

    Create("TextLabel", {
        Parent = Frame,
        Size = UDim2.fromScale(1,0.45),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = self.Themes[self.CurrentTheme].Text
    })

    Create("TextLabel", {
        Parent = Frame,
        Position = UDim2.fromScale(0,0.45),
        Size = UDim2.fromScale(1,0.55),
        BackgroundTransparency = 1,
        TextWrapped = true,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = self.Themes[self.CurrentTheme].SubText
    })

    Tween(Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        Position = Frame.Position - UDim2.fromOffset(20,0)
    })

    task.delay(duration, function()
        Tween(Frame, TweenInfo.new(0.25), {BackgroundTransparency = 1})
        task.wait(0.25)
        Frame:Destroy()
    end)
end

--// =====================
--// Themes
--// =====================

Library.Themes.Dark = {
    Background = Color3.fromRGB(18,18,18),
    Surface = Color3.fromRGB(28,28,28),
    Accent = Color3.fromRGB(120,140,255),
    Text = Color3.new(1,1,1),
    SubText = Color3.fromRGB(180,180,180)
}

Library.Themes.Light = {
    Background = Color3.fromRGB(235,235,235),
    Surface = Color3.fromRGB(255,255,255),
    Accent = Color3.fromRGB(80,100,220),
    Text = Color3.fromRGB(20,20,20),
    SubText = Color3.fromRGB(90,90,90)
}

function Library:SetTheme(name)
    if self.Themes[name] then
        self.CurrentTheme = name
        self:Notify("Theme", "Theme set to "..name)
    end
end

--// =====================
--// Window
--// =====================

function Library:CreateWindow(config)
    local Window = {}
    Window.Title = config.Title or "WindUIPlus"
    Window.Tabs = {}

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.fromScale(0.48,0.6),
        Position = UDim2.fromScale(0.26,0.2),
        BackgroundColor3 = self.Themes[self.CurrentTheme].Background
    })

    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0,12)})

    -- Dragging
    do
        local dragging, startPos, startInput
        Main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                startInput = input.Position
                startPos = Main.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startInput
                Main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    Window.Main = Main
    return setmetatable(Window, {__index = self})
end

--// =====================
--// Tabs & Sections
--// =====================

function Library:CreateTab(name)
    local Tab = {}
    Tab.Name = name

    local Holder = Create("Frame", {
        Parent = self.Main,
        Size = UDim2.fromScale(1,0.9),
        Position = UDim2.fromScale(0,0.1),
        BackgroundTransparency = 1
    })

    Create("UIListLayout", {Parent = Holder, Padding = UDim.new(0,10)})

    Tab.Holder = Holder
    return Tab
end

function Tab:CreateSection(title)
    local Section = {}

    local Frame = Create("Frame", {
        Parent = self.Holder,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Surface,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0,10)})

    Create("TextLabel", {
        Parent = Frame,
        Size = UDim2.fromScale(1,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text
    })

    Create("UIListLayout", {Parent = Frame, Padding = UDim.new(0,6)})

    Section.Container = Frame
    return Section
end

--// =====================
--// Components
--// =====================

function Section:AddButton(text, callback)
    local Button = Create("TextButton", {
        Parent = self.Container,
        Size = UDim2.fromScale(1,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = text,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Background,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    Create("UICorner", {Parent = Button, CornerRadius = UDim.new(0,8)})
    Button.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
end

function Section:AddToggle(text, default, callback)
    local state = default
    local Toggle = Create("TextButton", {
        Parent = self.Container,
        Size = UDim2.fromScale(1,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = text..": "..(state and "ON" or "OFF"),
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Background,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    Create("UICorner", {Parent = Toggle, CornerRadius = UDim.new(0,8)})
    Toggle.MouseButton1Click:Connect(function()
        state = not state
        Toggle.Text = text..": "..(state and "ON" or "OFF")
        Library.Flags[text] = state
        pcall(callback, state)
    end)
end

function Section:AddSlider(text, min, max, default, callback)
    local value = default or min
    Library.Flags[text] = value

    local Frame = Create("Frame", {
        Parent = self.Container,
        Size = UDim2.fromScale(1,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    })

    local Label = Create("TextLabel", {
        Parent = Frame,
        Text = text..": "..value,
        BackgroundTransparency = 1,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        Size = UDim2.fromScale(1,0.4)
    })

    local Bar = Create("Frame", {
        Parent = Frame,
        Size = UDim2.fromScale(1,0.25),
        Position = UDim2.fromScale(0,0.6),
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Surface
    })
    Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(0,6)})

    local Fill = Create("Frame", {
        Parent = Bar,
        Size = UDim2.fromScale((value-min)/(max-min),1),
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Accent
    })
    Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(0,6)})

    local dragging = false
    Bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
            value = math.floor(min + (max-min)*pct)
            Fill.Size = UDim2.fromScale(pct,1)
            Label.Text = text..": "..value
            Library.Flags[text] = value
            pcall(callback, value)
        end
    end)
end

function Section:AddDropdown(text, list, callback)
    local open = false
    local Button = Create("TextButton", {
        Parent = self.Container,
        Text = text,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Background,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    Create("UICorner", {Parent = Button, CornerRadius = UDim.new(0,8)})

    local Holder = Create("Frame", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,0),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    Create("UIListLayout", {Parent = Holder, Padding = UDim.new(0,4)})

    Button.MouseButton1Click:Connect(function()
        open = not open
        Holder.Visible = open
    end)

    for _,v in ipairs(list) do
        local Opt = Create("TextButton", {
            Parent = Holder,
            Text = v,
            BackgroundColor3 = Library.Themes[Library.CurrentTheme].Surface,
            TextColor3 = Library.Themes[Library.CurrentTheme].Text,
            Font = Enum.Font.Gotham,
            TextSize = 12
        })
        Create("UICorner", {Parent = Opt, CornerRadius = UDim.new(0,6)})
        Opt.MouseButton1Click:Connect(function()
            Button.Text = text..": "..v
            Library.Flags[text] = v
            pcall(callback, v)
        end)
    end
end

function Section:AddInput(text, callback)
    local Box = Create("TextBox", {
        Parent = self.Container,
        PlaceholderText = text,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Background,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    Create("UICorner", {Parent = Box, CornerRadius = UDim.new(0,8)})
    Box.FocusLost:Connect(function()
        Library.Flags[text] = Box.Text
        pcall(callback, Box.Text)
    end)
end

--// =====================
--// Config Saving
--// =====================

function Library:SaveConfig(name)
    local data = HttpService:JSONEncode(self.Flags)
    writefile(name..".json", data)
    self:Notify("Config", "Saved "..name)
end

function Library:LoadConfig(name)
    if isfile(name..".json") then
        self.Flags = HttpService:JSONDecode(readfile(name..".json"))
        self:Notify("Config", "Loaded "..name)
    end
end

--// =====================
--// Blur / Acrylic
--// =====================

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

function Library:SetBlur(state)
    Tween(Blur, TweenInfo.new(0.3), {Size = state and 20 or 0})
end

--// Return
return Library
