local NexusGT = {}
NexusGT.__index = NexusGT

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NexusGT_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = CoreGui

-- Themes
local Themes = {
    Dark = {
        Bg = Color3.fromRGB(20, 20, 25),
        Sec = Color3.fromRGB(30, 30, 35),
        Acc = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSec = Color3.fromRGB(200, 200, 200),
        Stroke = Color3.fromRGB(50, 50, 55)
    },
    Light = {
        Bg = Color3.fromRGB(240, 240, 245),
        Sec = Color3.fromRGB(255, 255, 255),
        Acc = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(30, 30, 35),
        TextSec = Color3.fromRGB(100, 100, 110),
        Stroke = Color3.fromRGB(200, 200, 210)
    }
}

local WindowCount = 0

-- Utility Functions
local function Tween(obj, info, props)
    TweenService:Create(obj, info or TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function DragFunc(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
end

local function CreateStroke(parent, color, thick)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(0,0,0)
    stroke.Thickness = thick or 1
    stroke.Parent = parent
end

local function Notify(title, content, duration)
    WindowCount = WindowCount + 1
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 300, 0, 80)
    notif.Position = UDim2.new(1, 20, 1, -100 - (WindowCount - 1) * 90)
    notif.BackgroundColor3 = Themes.Dark.Sec
    notif.Parent = ScreenGui
    CreateCorner(notif, 8)
    CreateStroke(notif, Themes.Dark.Stroke, 1)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0.4, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Themes.Dark.Text
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = notif

    local contentLbl = Instance.new("TextLabel")
    contentLbl.Size = UDim2.new(1, -20, 0.6, 0)
    contentLbl.Position = UDim2.new(0, 10, 0.4, 0)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text = content
    contentLbl.TextColor3 = Themes.Dark.TextSec
    contentLbl.Font = Enum.Font.Gotham
    contentLbl.TextSize = 14
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextWrapped = true
    contentLbl.Parent = notif

    Tween(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(1, -320, 1, -100 - (WindowCount - 1) * 90)})

    task.delay(duration or 4, function()
        Tween(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(1, 20, 1, -100 - (WindowCount - 1) * 90)}):Play()
        task.wait(0.4)
        notif:Destroy()
        WindowCount = WindowCount - 1
    end)
end

-- Window Creation
function NexusGT:CreateWindow(options)
    local self = setmetatable({}, NexusGT)
    
    options = options or {}
    local name = options.Name or "NexusGT Hub"
    local theme = options.Theme or "Dark"
    
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 550, 0, 450)
    win.Position = UDim2.new(0.5, -275, 0.5, -225)
    win.BackgroundColor3 = Themes[theme].Bg
    win.BorderSizePixel = 0
    win.Parent = ScreenGui
    CreateCorner(win, 12)
    CreateStroke(win, Themes[theme].Stroke, 1)
    
    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 45)
    topbar.BackgroundColor3 = Themes[theme].Sec
    topbar.Parent = win
    CreateCorner(topbar, 12)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = Themes[theme].Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Parent = topbar
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -40, 0.5, -15)
    close.Text = "X"
    close.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    close.TextColor3 = Color3.new(1,1,1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 18
    close.Parent = topbar
    CreateCorner(close, 6)
    
    close.MouseButton1Click:Connect(function()
        win:Destroy()
    end)
    
    DragFunc(topbar)
    
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 150, 1, -55)
    tabContainer.Position = UDim2.new(0, 0, 0, 45)
    tabContainer.BackgroundColor3 = Themes[theme].Sec
    tabContainer.Parent = win
    
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -160, 1, -55)
    contentArea.Position = UDim2.new(0, 155, 0, 45)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = win
    
    local selfTabs = {}
    local currentTab = nil
    
    function self:NewTab(tabName)
        local tab = {}
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -10, 0, 40)
        tabBtn.BackgroundColor3 = Themes[theme].Bg
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Themes[theme].TextSec
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.TextSize = 14
        tabBtn.Parent = tabContainer
        CreateCorner(tabBtn, 6)
        CreateStroke(tabBtn)
        
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = Themes[theme].Acc
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.Visible = false
        tabContent.Parent = contentArea
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = tabContent
        
        tabContent:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        
        tabBtn.MouseButton1Click:Connect(function()
            if currentTab then currentTab.Visible = false end
            tabContent.Visible = true
            currentTab = tabContent
            for _, t in pairs(selfTabs) do
                t.Button.BackgroundColor3 = Themes[theme].Bg
                t.Button.TextColor3 = Themes[theme].TextSec
            end
            tabBtn.BackgroundColor3 = Themes[theme].Acc
            tabBtn.TextColor3 = Color3.new(1,1,1)
        end)
        
        table.insert(selfTabs, {Button = tabBtn, Content = tabContent})
        
        if #selfTabs == 1 then
            tabBtn.MouseButton1Click:Invoke()
        end
        
        function tab:NewSection(name)
            local section = Instance.new("TextLabel")
            section.Size = UDim2.new(1, -20, 0, 30)
            section.BackgroundTransparency = 1
            section.Text = "  " .. name
            section.TextColor3 = Themes[theme].Text
            section.Font = Enum.Font.GothamBold
            section.TextSize = 16
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.Parent = tabContent
        end
        
        function tab:NewButton(name, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 40)
            btn.BackgroundColor3 = Themes[theme].Sec
            btn.Text = name
            btn.TextColor3 = Themes[theme].Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 15
            btn.Parent = tabContent
            CreateCorner(btn, 8)
            CreateStroke(btn)
            
            btn.MouseButton1Click:Connect(callback)
            btn.MouseEnter:Connect(function() Tween(btn, nil, {BackgroundColor3 = Themes[theme].Acc}) end)
            btn.MouseLeave:Connect(function() Tween(btn, nil, {BackgroundColor3 = Themes[theme].Sec}) end)
        end
        
        function tab:NewToggle(name, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 40)
            frame.BackgroundColor3 = Themes[theme].Sec
            frame.Parent = tabContent
            CreateCorner(frame, 8)
            CreateStroke(frame)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = Themes[theme].Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 15
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Position = UDim2.new(0, 10, 0, 0)
            label.Parent = frame
            
            local toggle = Instance.new("Frame")
            toggle.Size = UDim2.new(0, 40, 0, 20)
            toggle.Position = UDim2.new(1, -50, 0.5, -10)
            toggle.BackgroundColor3 = Color3.fromRGB(80,80,90)
            toggle.Parent = frame
            CreateCorner(toggle, 10)
            
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 16, 0, 16)
            dot.Position = UDim2.new(0, 2, 0.5, -8)
            dot.BackgroundColor3 = Color3.new(1,1,1)
            dot.Parent = toggle
            CreateCorner(dot, 8)
            
            local state = default or false
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    state = not state
                    callback(state)
                    Tween(toggle, TweenInfo.new(0.2), {BackgroundColor3 = state and Themes[theme].Acc or Color3.fromRGB(80,80,90)})
                    Tween(dot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                end
            end)
            
            if state then
                toggle.BackgroundColor3 = Themes[theme].Acc
                dot.Position = UDim2.new(1, -18, 0.5, -8)
            end
        end
        
        function tab:NewSlider(name, min, max, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 60)
            frame.BackgroundColor3 = Themes[theme].Sec
            frame.Parent = tabContent
            CreateCorner(frame, 8)
            CreateStroke(frame)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0.4, 0)
            label.BackgroundTransparency = 1
            label.Text = name .. ": " .. default
            label.TextColor3 = Themes[theme].Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 15
            label.Position = UDim2.new(0, 10, 0, 5)
            label.Parent = frame
            
            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -20, 0.2, 0)
            bar.Position = UDim2.new(0, 10, 0.6, 0)
            bar.BackgroundColor3 = Color3.fromRGB(50,50,60)
            bar.Parent = frame
            CreateCorner(bar, 4)
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            fill.BackgroundColor3 = Themes[theme].Acc
            fill.Parent = bar
            CreateCorner(fill, 4)
            
            local dragging = false
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    local val = math.floor(min + (max - min) * pos)
                    fill.Size = UDim2.new(pos, 0, 1, 0)
                    label.Text = name .. ": " .. val
                    callback(val)
                end
            end)
            
            callback(default)
        end
        
        return tab
    end
    
    -- Auto notify on load
    Notify("NexusGT Loaded", "UI Library ready 🔥", 4)
    
    return self
end

-- Global Notify
function NexusGT:Notify(title, content, duration)
    Notify(title, content, duration)
end

return NexusGT
