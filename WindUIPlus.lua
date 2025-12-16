--[[
WindUIPlus
Single-file full UI library
Style: Rayfield / Linoria inspired
No prints. Notifications only.
GitHub-ready.
]]

--// =====================
--// Services
--// =====================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// =====================
--// Library Root
--// =====================

local Library = {}
Library.__index = Library

Library.Flags = {}
Library.Themes = {}
Library.CurrentTheme = "Dark"
Library.Language = "en"
Library.Localization = {
    en = {
        Loaded = "Loaded",
        Theme = "Theme",
        ConfigSaved = "Config saved",
        ConfigLoaded = "Config loaded"
    }
}

local function L(key)
    return Library.Localization[Library.Language][key] or key
end

--// =====================
--// ScreenGui
--// =====================

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
        self:Notify(L("Theme"), name)
    end
end

--// =====================
--// Notifications
--// =====================

local NotifyHolder = Create("Frame", {
    Parent = ScreenGui,
    AnchorPoint = Vector2.new(1,1),
    Position = UDim2.fromScale(1,1),
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(0,0)
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
        Size = UDim2.fromOffset(280,70),
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
--// Blur / Acrylic
--// =====================

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

function Library:SetBlur(state)
    Tween(Blur, TweenInfo.new(0.3), {Size = state and 20 or 0})
end

--// =====================
--// Window
--// =====================

function Library:CreateWindow(config)
    local Window = {}
    setmetatable(Window, {__index = self})

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.fromScale(0.48,0.6),
        Position = UDim2.fromScale(0.26,0.2),
        BackgroundColor3 = self.Themes[self.CurrentTheme].Background
    })
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0,12)})

    local Top = Create("Frame", {
        Parent = Main,
        Size = UDim2.fromScale(1,0.08),
        BackgroundTransparency = 1
    })

    Create("TextLabel", {
        Parent = Top,
        Text = config.Title or "WindUIPlus",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = self.Themes[self.CurrentTheme].Text,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1)
    })

    -- Dragging
    do
        local dragging, startPos, startInput
        Top.InputBegan:Connect(function(input)
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
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    Window.Main = Main
    return Window
end

--// =====================
--// Tabs / Sections
--// =====================

function Library:CreateTab(name)
    local Tab = {}

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
        Text = title,
        BackgroundTransparency = 1,
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
    local B = Create("TextButton", {
        Parent = self.Container,
        Text = text,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Background,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    Create("UICorner", {Parent = B, CornerRadius = UDim.new(0,8)})
    B.MouseButton1Click:Connect(function() pcall(callback) end)
end

function Section:AddToggle(text, default, callback)
    local state = default
    Library.Flags[text] = state
    local T = Create("TextButton", {
        Parent = self.Container,
        Text = text..": "..(state and "ON" or "OFF"),
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Background,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    Create("UICorner", {Parent = T, CornerRadius = UDim.new(0,8)})
    T.MouseButton1Click:Connect(function()
        state = not state
        T.Text = text..": "..(state and "ON" or "OFF")
        Library.Flags[text] = state
        pcall(callback, state)
    end)
end

function Section:AddSlider(text, min, max, default, callback)
    local val = default or min
    Library.Flags[text] = val

    local Frame = Create("Frame", {Parent = self.Container, BackgroundTransparency = 1})
    local Label = Create("TextLabel", {
        Parent = Frame,
        Text = text..": "..val,
        BackgroundTransparency = 1,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })

    local Bar = Create("Frame", {
        Parent = Frame,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Surface,
        Size = UDim2.fromScale(1,0.3)
    })
    Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(0,6)})

    local Fill = Create("Frame", {
        Parent = Bar,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Accent,
        Size = UDim2.fromScale((val-min)/(max-min),1)
    })
    Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(0,6)})

    local dragging = false
    Bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local pct = math.clamp((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
            val = math.floor(min+(max-min)*pct)
            Fill.Size = UDim2.fromScale(pct,1)
            Label.Text = text..": "..val
            Library.Flags[text]=val
            pcall(callback,val)
        end
    end)
end

function Section:AddDropdown(text, list, callback)
    local B = Create("TextButton", {
        Parent = self.Container,
        Text = text,
        BackgroundColor3 = Library.Themes[Library.CurrentTheme].Background,
        TextColor3 = Library.Themes[Library.CurrentTheme].Text,
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    Create("UICorner", {Parent = B, CornerRadius = UDim.new(0,8)})

    local Holder = Create("Frame", {Parent = self.Container, BackgroundTransparency = 1})
    Create("UIListLayout", {Parent = Holder, Padding = UDim.new(0,4)})

    for _,v in ipairs(list) do
        local O = Create("TextButton", {
            Parent = Holder,
            Text = v,
            BackgroundColor3 = Library.Themes[Library.CurrentTheme].Surface,
            TextColor3 = Library.Themes[Library.CurrentTheme].Text,
            Font = Enum.Font.Gotham,
            TextSize = 12
        })
        Create("UICorner", {Parent = O, CornerRadius = UDim.new(0,6)})
        O.MouseButton1Click:Connect(function()
            B.Text = text..": "..v
            Library.Flags[text]=v
            pcall(callback,v)
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
--// Config
--// =====================

function Library:SaveConfig(name)
    writefile(name..".json", HttpService:JSONEncode(self.Flags))
    self:Notify(L("ConfigSaved"), name)
end

function Library:LoadConfig(name)
    if isfile(name..".json") then
        self.Flags = HttpService:JSONDecode(readfile(name..".json"))
        self:Notify(L("ConfigLoaded"), name)
    end
end

--// =====================
--// Return
--// =====================

return Library
