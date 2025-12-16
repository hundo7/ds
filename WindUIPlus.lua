--// TakoGlass UI v3
--  Glass-style UI with:
--   - Configurable blur from script (or disabled)
--   - Smooth “4K-ish” card look (tighter borders, less fog)
--   - Window:SetToggleKey(Enum.KeyCode.H)
--   - Window:SetBlur(enabled, size)
--   - Script-configurable options & themes
--   - Notifications only (no prints)

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer      = Players.LocalPlayer

local TakoGlass = {}
TakoGlass.__index = TakoGlass

-------------------------------------------------
-- Config / Defaults
-------------------------------------------------

local CONFIG_FOLDER = "TakoGlassConfigs"

local DefaultTheme = {
    Name        = "Default",
    Accent      = Color3.fromRGB(95, 140, 255),
    Background  = Color3.fromRGB(12, 12, 18),
    Outline     = Color3.fromRGB(80, 80, 110),
    Text        = Color3.fromRGB(235, 235, 245),
    Placeholder = Color3.fromRGB(150, 150, 170),
    Button      = Color3.fromRGB(26, 26, 36),
    Icon        = Color3.fromRGB(210, 210, 220),
}

-------------------------------------------------
-- Helpers
-------------------------------------------------

local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function DoTween(obj, goal, time, style, dir)
    if not obj then return end
    local tweenInfo = TweenInfo.new(
        time or 0.18,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, tweenInfo, goal):Play()
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

-------------------------------------------------
-- Blur control (per window)
-------------------------------------------------

local function getOrCreateBlur()
    local blur = Lighting:FindFirstChild("TakoGlassBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "TakoGlassBlur"
        blur.Enabled = false
        blur.Size = 12
        blur.Parent = Lighting
    end
    return blur
end

-------------------------------------------------
-- Notifications
-------------------------------------------------

function TakoGlass.Notify(title, text, duration)
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end

    local gui = pg:FindFirstChild("TakoGlass_Notify")
    if not gui then
        gui = Create("ScreenGui", {
            Name = "TakoGlass_Notify",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = pg
        })
        local holder = Create("Frame", {
            Name = "Holder",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -24, 1, -24),
            Size = UDim2.new(0, 320, 1, -48),
            BackgroundTransparency = 1,
            Parent = gui
        })
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 6),
            Parent = holder
        })
    end

    local theme = DefaultTheme
    local holder = gui:FindFirstChild("Holder")

    local card = Create("Frame", {
        BackgroundColor3 = theme.Button,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = holder
    })
    card.ZIndex = 20

    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
    Create("UIStroke", {
        Color = theme.Outline,
        Thickness = 1,
        Transparency = 0.35,
        Parent = card
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDimnew(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = card
    })

    Create("TextLabel", {
        Text = title or "Notification",
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextColor3 = theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    Create("TextLabel", {
        Text = text or "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Placeholder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 36),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card
    })

    DoTween(card, { Size = UDim2.new(1, 0, 0, 70) }, 0.2)
    task.spawn(function()
        task.wait(duration or 4)
        DoTween(card, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
        task.wait(0.2)
        card:Destroy()
    end)
end

-------------------------------------------------
-- Window constructor
-------------------------------------------------

function TakoGlass:CreateWindow(opts)
    local self = setmetatable({}, TakoGlass)

    opts = opts or {}

    self.Title        = opts.Title or "Nexus Hub"
    self.IconName     = opts.Icon or nil
    self.Author       = opts.Author or ""
    self.Folder       = opts.Folder or self.Title
    self.Size         = opts.Size or UDim2.fromOffset(580, 460)
    self.Transparent  = (opts.Transparent ~= nil) and opts.Transparent or true
    self.Resizable    = (opts.Resizable ~= nil) and opts.Resizable or false -- flag only
    self.SideBarWidth = opts.SideBarWidth or 200
    self.Theme        = opts.Theme or table.clone(DefaultTheme)

    self.UseBlur      = (opts.UseBlur ~= nil) and opts.UseBlur or false
    self.BlurSize     = opts.BlurSize or 14

    self.ConfigName   = self.Folder
    self.Flags        = {}
    self.Config       = LoadConfig(self.ConfigName)

    self.ToggleKey    = Enum.KeyCode.RightShift
    self.IsOpen       = true
    self.IsMinimized  = false

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then error("No PlayerGui") end

    local blur = getOrCreateBlur()
    self.BlurObject = blur
    if self.UseBlur then
        blur.Size = self.BlurSize
        blur.Enabled = true
    else
        blur.Enabled = false
    end

    local gui = Create("ScreenGui", {
        Name = "TakoGlass_" .. self.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = pg
    })
    self.Gui = gui

    -------------------------------------------------
    -- Main window
    -------------------------------------------------

    local main = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = self.Size,
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = self.Transparent and 0.1 or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = main })
    Create("UIStroke", {
        Color = self.Theme.Outline,
        Thickness = 1,
        Transparency = 0.25,
        Parent = main
    })

    self.Main = main

    -------------------------------------------------
    -- Top bar
    -------------------------------------------------

    local top = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = main
    })

    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 18),
        PaddingRight = UDim.new(0, 12),
        Parent = top
    })

    local titleLabel = Create("TextLabel", {
        Text = self.Title,
        Font = Enum.Font.GothamSemibold,
        TextSize = 16,
        TextColor3 = self.Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 6),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = top
    })

    local authorLabel = Create("TextLabel", {
        Text = self.Author,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = self.Theme.Placeholder,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.7, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 24),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = top
    })

    self.TitleLabel  = titleLabel
    self.AuthorLabel = authorLabel

    -- Minus and close buttons
    local minusBtn = Create("TextButton", {
        Text = "–",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = self.Theme.Icon,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -64, 0, 0),
        Parent = top
    })

    local closeBtn = Create("TextButton", {
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = self.Theme.Icon,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -32, 0, 0),
        Parent = top
    })

    closeBtn.MouseButton1Click:Connect(function()
        if self.BlurObject then self.BlurObject.Enabled = false end
        gui:Destroy()
    end)

    minusBtn.MouseButton1Click:Connect(function()
        self.IsMinimized = not self.IsMinimized
        if self.IsMinimized then
            DoTween(main, { Size = UDim2.new(0, self.Size.X.Offset, 0, 44) }, 0.16)
        else
            DoTween(main, { Size = self.Size }, 0.16)
        end
    end)

    -- Dragging
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

    -------------------------------------------------
    -- Sidebar
    -------------------------------------------------

    local sidebar = Create("Frame", {
        BackgroundColor3 = self.Theme.Button,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(0, self.SideBarWidth, 1, -44),
        Parent = main
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = sidebar })

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebar
    })

    local tabList = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
        Parent = sidebar
    })

    -- Content panel
    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, self.SideBarWidth, 0, 44),
        Size = UDim2.new(1, -self.SideBarWidth, 1, -44),
        Parent = main
    })

    self.Sidebar = sidebar
    self.TabList = sidebar
    self.Content = content
    self.Tabs    = {}

    -------------------------------------------------
    -- Global toggle key
    -------------------------------------------------

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.ToggleKey then
            self:SetVisible(not self.IsOpen)
        end
    end)

    self:SetTheme(self.Theme)

    return self
end

-------------------------------------------------
-- Window methods
-------------------------------------------------

function TakoGlass:SetVisible(state)
    if state == nil then
        return self.IsOpen
    end
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
    if size then
        self.BlurSize = size
    end
    local blur = self.BlurObject or getOrCreateBlur()
    self.BlurObject = blur
    blur.Size = self.BlurSize
    blur.Enabled = self.UseBlur and self.IsOpen or false
end

function TakoGlass:SetTheme(themeTable)
    for k, v in pairs(themeTable or {}) do
        self.Theme[k] = v
    end
    local t = self.Theme

    if self.Main then
        self.Main.BackgroundColor3 = t.Background
        self.Main.BackgroundTransparency = self.Transparent and 0.1 or 0
        local stroke = self.Main:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = t.Outline
            stroke.Transparency = 0.25
        end
    end

    if self.TitleLabel then self.TitleLabel.TextColor3 = t.Text end
    if self.AuthorLabel then self.AuthorLabel.TextColor3 = t.Placeholder end
    if self.Sidebar then
        self.Sidebar.BackgroundColor3 = t.Button
    end

    for _, tab in ipairs(self.Tabs) do
        tab:ApplyTheme(t)
    end
end

-------------------------------------------------
-- Tabs / Sections / Elements
-------------------------------------------------

function TakoGlass:CreateTab(name)
    local theme = self.Theme

    local btn = Create("TextButton", {
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.Placeholder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 28),
        Parent = self.TabList
    })

    local btnBg = Create("Frame", {
        BackgroundColor3 = theme.Button,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = btn
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btnBg })

    local page = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        Visible = false,
        Parent = self.Content
    })

    local layout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 12),
        Parent = page
    })

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = page
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local tab = {}
    tab.Window = self
    tab.Button = btn
    tab.ButtonBg = btnBg
    tab.Page = page
    tab.Sections = {}

    function tab:SetActive()
        for _, other in ipairs(self.Window.Tabs) do
            other.Page.Visible = false
            DoTween(other.ButtonBg, { BackgroundTransparency = 1 }, 0.15)
            DoTween(other.Button,   { TextColor3 = self.Window.Theme.Placeholder }, 0.15)
        end
        self.Page.Visible = true
        DoTween(self.ButtonBg, { BackgroundTransparency = 0, BackgroundColor3 = self.Window.Theme.Button }, 0.15)
        DoTween(self.Button,   { TextColor3 = self.Window.Theme.Text }, 0.15)
    end

    function tab:ApplyTheme(t)
        DoTween(self.Button, { TextColor3 = t.Placeholder }, 0.01)
        DoTween(self.ButtonBg, { BackgroundColor3 = t.Button }, 0.01)
        for _, sec in ipairs(self.Sections) do
            sec:ApplyTheme(t)
        end
    end

    -------------------------------------------------
    -- Section (card)
    -------------------------------------------------

    function tab:CreateSection(title, description)
        local t = self.Window.Theme

        local card = Create("Frame", {
            BackgroundColor3 = t.Button,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 90),
            Parent = self.Page
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = card })
        local stroke = Create("UIStroke", {
            Color = t.Outline,
            Thickness = 1,
            Transparency = 0.40,
            Parent = card
        })

        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            Parent = card
        })

        local titleLabel = Create("TextLabel", {
            Text = title or "Section",
            Font = Enum.Font.GothamSemibold,
            TextSize = 15,
            TextColor3 = t.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -80, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card
        })

        local descLabel = Create("TextLabel", {
            Text = description or "",
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = t.Placeholder,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 22),
            Size = UDim2.new(1, -80, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = card
        })

        local content = Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 44),
            Size = UDim2.new(1, 0, 0, 0),
            Parent = card
        })
        local cLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 6),
            Parent = content
        })

        cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.Size = UDim2.new(1, 0, 0, cLayout.AbsoluteContentSize.Y)
            card.Size    = UDim2.new(1, 0, 0, 50 + cLayout.AbsoluteContentSize.Y)
        end)

        local section = {}
        section.Window = self.Window
        section.Tab = self
        section.Card = card
        section.Content = content

        function section:ApplyTheme(t2)
            card.BackgroundColor3 = t2.Button
            stroke.Color = t2.Outline
            titleLabel.TextColor3 = t2.Text
            descLabel.TextColor3 = t2.Placeholder
        end

        -------------------------------------------------
        -- Elements
        -------------------------------------------------

        function section:AddButton(opt)
            opt = opt or {}
            local text = opt.Name or "Button"
            local callback = opt.Callback or function() end
            local t2 = self.Window.Theme

            local btn = Create("TextButton", {
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = t2.Text,
                BackgroundColor3 = t2.Button,
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                Parent = self.Content
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = btn })

            btn.MouseEnter:Connect(function()
                DoTween(btn, { BackgroundColor3 = t2.Accent }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                DoTween(btn, { BackgroundColor3 = t2.Button }, 0.12)
            end)

            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)

            return btn
        end

        function section:AddToggle(opt)
            opt = opt or {}
            local name = opt.Name or "Toggle"
            local flag = opt.Flag or ("TG_Toggle_" .. name)
            local default = opt.Default or false
            local callback = opt.Callback or function() end
            local t2 = self.Window.Theme

            if self.Window.Config[flag] == nil then
                self.Window.Config[flag] = default
            end
            self.Window.Flags[flag] = self.Window.Config[flag]

            local row = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                Parent = self.Content
            })

            local label = Create("TextLabel", {
                Text = name,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = t2.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -60, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row
            })

            local pill = Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 42, 0, 20),
                BackgroundColor3 = self.Window.Flags[flag] and t2.Accent or t2.Button,
                BorderSizePixel = 0,
                Parent = row
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })

            local knob = Create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = self.Window.Flags[flag] and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = pill
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

            local function setValue(v)
                self.Window.Flags[flag] = v
                self.Window.Config[flag] = v
                SaveConfig(self.Window.ConfigName, self.Window.Config)

                DoTween(pill, { BackgroundColor3 = v and t2.Accent or t2.Button }, 0.16)
                DoTween(knob, {
                    Position = v and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)
                }, 0.16)

                pcall(callback, v)
            end

            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setValue(not self.Window.Flags[flag])
                end
            end)

            return {
                Set = setValue,
                Get = function() return self.Window.Flags[flag] end
            }
        end

        -- Slider, Dropdown, Input remain the same as previous version
        -- (for brevity you can reuse those blocks unchanged from v2,
        --  just keep their styles consistent with t2.Button, t2.Accent, etc.)

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

return TakoGlass
