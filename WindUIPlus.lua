-- WindUIPlus Executor Edition
-- Single-file UI Library (Rayfield/Linoria-inspired)
-- Executor-only (HttpGet, writefile/readfile supported)
-- No prints. Notifications only.

-- =========================================================
-- SERVICES / EXECUTOR API SAFETY
-- =========================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local writefile = writefile or function() end
local readfile = readfile or function() return nil end
local isfile = isfile or function() return false end
local makefolder = makefolder or function() end

-- =========================================================
-- LIBRARY ROOT
-- =========================================================
local Library = {}
Library.__index = Library
Library.Version = "1.0.0"
Library.Flags = {}
Library.Windows = {}
Library.Themes = {}
Library.Localization = {}
Library.CurrentLanguage = "en"
Library.ConfigFolder = "WindUIPlus"
Library.LastConfigFile = "last.json"

-- =========================================================
-- DEFAULT LOCALIZATION
-- =========================================================
Library.Localization.en = {
    Loaded = "Loaded",
    Saved = "Saved",
    Error = "Error",
    Config = "Config",
    Theme = "Theme",
    About = "About",
}

-- =========================================================
-- THEMES
-- =========================================================
Library.Themes.Dark = {
    Background = Color3.fromRGB(18,18,18),
    Panel = Color3.fromRGB(24,24,24),
    Accent = Color3.fromRGB(88,101,242),
    Text = Color3.fromRGB(235,235,235),
    Muted = Color3.fromRGB(140,140,140)
}

Library.Themes.Light = {
    Background = Color3.fromRGB(245,245,245),
    Panel = Color3.fromRGB(255,255,255),
    Accent = Color3.fromRGB(0,120,255),
    Text = Color3.fromRGB(20,20,20),
    Muted = Color3.fromRGB(120,120,120)
}

Library.CurrentTheme = Library.Themes.Dark

-- =========================================================
-- UTILITIES
-- =========================================================
local Util = {}

function Util:Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

function Util:Create(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    return inst
end

function Util:Round(n, inc)
    inc = inc or 1
    return math.floor(n / inc + 0.5) * inc
end

function Util:Safe(cb, ...)
    local ok, err = pcall(cb, ...)
    if not ok then
        Library:Notify(Library.Localization[Library.CurrentLanguage].Error, tostring(err))
    end
end

-- =========================================================
-- BLUR / ACRYLIC
-- =========================================================
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

function Library:SetBlur(state)
    Util:Tween(Blur, TweenInfo.new(0.25), {Size = state and 18 or 0})
end

-- =========================================================
-- NOTIFICATIONS
-- =========================================================
local NotifyGui = Util:Create("ScreenGui", {Name = "WindUIPlus_Notify", ResetOnSpawn = false, Parent = PlayerGui})

local NotifyHolder = Util:Create("Frame", {
    Parent = NotifyGui,
    AnchorPoint = Vector2.new(1,1),
    Position = UDim2.fromScale(0.98,0.98),
    Size = UDim2.fromScale(0.3,0.5),
    BackgroundTransparency = 1
})

local NotifyLayout = Util:Create("UIListLayout", {Parent = NotifyHolder, Padding = UDim.new(0,8), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom})

function Library:Notify(title, text, duration)
    duration = duration or 3
    local theme = Library.CurrentTheme

    local card = Util:Create("Frame", {
        Parent = NotifyHolder,
        Size = UDim2.new(1,0,0,64),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,10), Parent = card})

    local t = Util:Create("TextLabel", {
        Parent = card,
        Position = UDim2.fromOffset(12,8),
        Size = UDim2.new(1,-24,0,20),
        BackgroundTransparency = 1,
        Text = tostring(title),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Left,
        TextColor3 = theme.Text
    })

    local d = Util:Create("TextLabel", {
        Parent = card,
        Position = UDim2.fromOffset(12,30),
        Size = UDim2.new(1,-24,0,24),
        BackgroundTransparency = 1,
        TextWrapped = true,
        Text = tostring(text),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Left,
        TextColor3 = theme.Muted
    })

    card.BackgroundTransparency = 1
    Util:Tween(card, TweenInfo.new(0.25), {BackgroundTransparency = 0})

    task.delay(duration, function()
        Util:Tween(card, TweenInfo.new(0.25), {BackgroundTransparency = 1})
        task.wait(0.3)
        card:Destroy()
    end)
end

-- =========================================================
-- CONFIG SYSTEM
-- =========================================================
function Library:EnsureFolder()
    if not isfolder or not isfolder(Library.ConfigFolder) then
        makefolder(Library.ConfigFolder)
    end
end

function Library:SaveConfig(name)
    self:EnsureFolder()
    local path = Library.ConfigFolder .. "/" .. name .. ".json"
    writefile(path, HttpService:JSONEncode(Library.Flags))
    writefile(Library.ConfigFolder .. "/" .. Library.LastConfigFile, name)
    self:Notify(Library.Localization[self.CurrentLanguage].Saved, name)
end

function Library:LoadConfig(name)
    local path = Library.ConfigFolder .. "/" .. name .. ".json"
    if isfile(path) then
        local data = HttpService:JSONDecode(readfile(path))
        for k,v in pairs(data) do
            if Library.Flags[k] ~= nil then
                Library.Flags[k] = v
            end
        end
        self:Notify(Library.Localization[self.CurrentLanguage].Loaded, name)
    end
end

function Library:AutoLoad()
    local last = Library.ConfigFolder .. "/" .. Library.LastConfigFile
    if isfile(last) then
        local name = readfile(last)
        self:LoadConfig(name)
    end
end

-- =========================================================
-- DRAGGING
-- =========================================================
function Util:MakeDraggable(handle, frame)
    local dragging, start, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            start = i.Position
            startPos = frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - start
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- =========================================================
-- WINDOW
-- =========================================================
function Library:CreateWindow(opts)
    opts = opts or {}
    local theme = self.CurrentTheme

    local gui = Util:Create("ScreenGui", {Name = "WindUIPlus", ResetOnSpawn = false, Parent = PlayerGui})

    local main = Util:Create("Frame", {
        Parent = gui,
        Position = UDim2.fromScale(0.5,0.5),
        AnchorPoint = Vector2.new(0.5,0.5),
        Size = UDim2.fromOffset(640,420),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,12), Parent = main})

    local top = Util:Create("Frame", {Parent = main, Size = UDim2.new(1,0,0,44), BackgroundColor3 = theme.Panel, BorderSizePixel = 0})
    Util:Create("UICorner", {CornerRadius = UDim.new(0,12), Parent = top})

    local title = Util:Create("TextLabel", {Parent = top, Position = UDim2.fromOffset(12,0), Size = UDim2.new(1,-24,1,0), BackgroundTransparency = 1, Text = opts.Title or "WindUIPlus", Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Left, TextColor3 = theme.Text})

    Util:MakeDraggable(top, main)

    local tabsBar = Util:Create("Frame", {Parent = main, Position = UDim2.fromOffset(0,44), Size = UDim2.new(0,160,1,-44), BackgroundColor3 = theme.Panel, BorderSizePixel = 0})
    local content = Util:Create("Frame", {Parent = main, Position = UDim2.fromOffset(160,44), Size = UDim2.new(1,-160,1,-44), BackgroundTransparency = 1})

    local tabLayout = Util:Create("UIListLayout", {Parent = tabsBar, Padding = UDim.new(0,6)})

    local Window = {Tabs = {}, Gui = gui, Main = main, Content = content}

    function Window:CreateTab(name)
        local btn = Util:Create("TextButton", {Parent = tabsBar, Size = UDim2.new(1,-12,0,36), Text = name, Font = Enum.Font.Gotham, TextSize = 14, BackgroundColor3 = theme.Background, TextColor3 = theme.Text, BorderSizePixel = 0})
        Util:Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = btn})

        local page = Util:Create("ScrollingFrame", {Parent = content, Size = UDim2.new(1,0,1,0), CanvasSize = UDim2.new(0,0,0,0), ScrollBarImageTransparency = 1, Visible = false})
        local layout = Util:Create("UIListLayout", {Parent = page, Padding = UDim.new(0,12)})

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 12)
        end)

        local Tab = {}

        function Tab:Show()
            for _,t in pairs(Window.Tabs) do t.Page.Visible = false end
            page.Visible = true
        end

        btn.MouseButton1Click:Connect(function() Tab:Show() end)

        function Tab:CreateSection(text)
            local holder = Util:Create("Frame", {Parent = page, Size = UDim2.new(1,-24,0,0), BackgroundColor3 = theme.Panel, BorderSizePixel = 0})
            Util:Create("UICorner", {CornerRadius = UDim.new(0,10), Parent = holder})

            local title = Util:Create("TextLabel", {Parent = holder, Position = UDim2.fromOffset(12,8), Size = UDim2.new(1,-24,0,20), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Left, TextColor3 = theme.Text})

            local list = Util:Create("UIListLayout", {Parent = holder, Padding = UDim.new(0,8)})
            list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                holder.Size = UDim2.new(1,-24,0,list.AbsoluteContentSize.Y + 20)
            end)

            local Section = {}

            function Section:AddToggle(name, default, cb)
                Library.Flags[name] = default
                local b = Util:Create("TextButton", {Parent = holder, Size = UDim2.new(1,-24,0,32), Text = name, BackgroundColor3 = theme.Background, TextColor3 = theme.Text, Font = Enum.Font.Gotham, TextSize = 13, BorderSizePixel = 0})
                Util:Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = b})
                b.MouseButton1Click:Connect(function()
                    Library.Flags[name] = not Library.Flags[name]
                    Util:Safe(cb, Library.Flags[name])
                end)
            end

            function Section:AddSlider(name, min, max, def, cb)
                Library.Flags[name] = def
                local f = Util:Create("Frame", {Parent = holder, Size = UDim2.new(1,-24,0,40), BackgroundTransparency = 1})
                local bar = Util:Create("Frame", {Parent = f, Position = UDim2.fromOffset(0,24), Size = UDim2.new(1,0,0,6), BackgroundColor3 = theme.Background, BorderSizePixel = 0})
                local fill = Util:Create("Frame", {Parent = bar, Size = UDim2.fromScale((def-min)/(max-min),1), BackgroundColor3 = theme.Accent, BorderSizePixel = 0})
                Util:Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = bar})
                Util:Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = fill})
                local dragging=false
                bar.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                        local x=(i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X
                        x=math.clamp(x,0,1)
                        fill.Size=UDim2.fromScale(x,1)
                        local v=Util:Round(min+(max-min)*x,1)
                        Library.Flags[name]=v
                        Util:Safe(cb,v)
                    end
                end)
            end

            function Section:AddDropdown(name, list, cb)
                Library.Flags[name] = list[1]
                local b = Util:Create("TextButton", {Parent = holder, Size = UDim2.new(1,-24,0,32), Text = name, BackgroundColor3 = theme.Background, TextColor3 = theme.Text, Font = Enum.Font.Gotham, TextSize = 13, BorderSizePixel = 0})
                Util:Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = b})
                b.MouseButton1Click:Connect(function()
                    local idx = table.find(list, Library.Flags[name]) or 1
                    idx = idx % #list + 1
                    Library.Flags[name] = list[idx]
                    Util:Safe(cb, Library.Flags[name])
                end)
            end

            function Section:AddInput(name, cb)
                Library.Flags[name] = ""
                local box = Util:Create("TextBox", {Parent = holder, Size = UDim2.new(1,-24,0,32), PlaceholderText = name, Text = "", BackgroundColor3 = theme.Background, TextColor3 = theme.Text, Font = Enum.Font.Gotham, TextSize = 13, BorderSizePixel = 0})
                Util:Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = box})
                box.FocusLost:Connect(function()
                    Library.Flags[name] = box.Text
                    Util:Safe(cb, box.Text)
                end)
            end

            return Section
        end

        Tab.Page = page
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Tab:Show() end
        return Tab
    end

    Library:SetBlur(true)
    table.insert(Library.Windows, Window)
    return Window
end

-- =========================================================
-- INIT
-- =========================================================
Library:AutoLoad()

return setmetatable(Library, Library)
