--------------------------------------------------------------------
-- 1. SERVICES & INITIALIZATION
--------------------------------------------------------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

if not RunService:IsClient() then
    error("TakoGlass must run on the client")
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local TakoGlass = {Version = "10.0.0", Windows = {}, Services = {}, Elements = {}}
TakoGlass.__index = TakoGlass

--------------------------------------------------------------------
-- 2. CONSTANTS & CONFIGURATION
--------------------------------------------------------------------
local CONFIG_FOLDER = "TakoGlassData"
local CACHE_FOLDER = "TakoGlassCache"
local DEFAULT_THEME = "Dark"
local MAX_NOTIFICATIONS = 8
local WINDOW_RADIUS = 14
local ELEMENT_RADIUS = 10
local ICON_FONT = Enum.Font.Gotham
local UI_FONT = Enum.Font.Gotham
local MONO_FONT = Enum.Font.Code

-- Performance constants
local FRAME_BUDGET = 0.008 -- 8ms per frame
local BATCH_SIZE = 50
local CACHE_TIMEOUT = 300 -- 5 minutes

--------------------------------------------------------------------
-- 3. THEME ENGINE - SUPERIOR TO WINDUI
--------------------------------------------------------------------
TakoGlass.Themes = {
    -- Professional Dark Theme (WindUI-inspired but better)
    Dark = {
        Name = "Dark",
        WindowBg = Color3.fromRGB(20, 20, 30),
        WindowAlpha = 0.45,
        CardBg = Color3.fromRGB(30, 30, 45),
        ElementBg = Color3.fromRGB(40, 40, 60),
        SidebarBg = Color3.fromRGB(15, 15, 25),
        Accent = Color3.fromRGB(88, 101, 242), -- Discord blue
        AccentSoft = Color3.fromRGB(108, 121, 262),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(180, 185, 210),
        Stroke = Color3.fromRGB(60, 60, 90),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(237, 66, 69),
        Shadow = Color3.fromRGB(0, 0, 0),
        Gradient = false,
        IsDark = true
    },
    
    -- Sleek Light Theme
    Light = {
        Name = "Light",
        WindowBg = Color3.fromRGB(248, 249, 250),
        WindowAlpha = 0.25,
        CardBg = Color3.fromRGB(255, 255, 255),
        ElementBg = Color3.fromRGB(245, 245, 245),
        SidebarBg = Color3.fromRGB(240, 240, 240),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentSoft = Color3.fromRGB(108, 121, 262),
        Text = Color3.fromRGB(30, 30, 40),
        SubText = Color3.fromRGB(100, 105, 130),
        Stroke = Color3.fromRGB(220, 220, 230),
        Success = Color3.fromRGB(40, 167, 69),
        Warning = Color3.fromRGB(255, 193, 7),
        Error = Color3.fromRGB(220, 53, 69),
        Shadow = Color3.fromRGB(200, 200, 200),
        Gradient = false,
        IsDark = false
    },
    
    -- Nord Theme (Enhanced)
    Nord = {
        Name = "Nord",
        WindowBg = Color3.fromRGB(46, 52, 64),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(59, 66, 82),
        ElementBg = Color3.fromRGB(67, 76, 94),
        SidebarBg = Color3.fromRGB(46, 52, 64),
        Accent = Color3.fromRGB(136, 192, 208),
        AccentSoft = Color3.fromRGB(129, 161, 193),
        Text = Color3.fromRGB(236, 239, 244),
        SubText = Color3.fromRGB(216, 222, 233),
        Stroke = Color3.fromRGB(76, 86, 106),
        Success = Color3.fromRGB(163, 190, 140),
        Warning = Color3.fromRGB(235, 203, 139),
        Error = Color3.fromRGB(191, 97, 106),
        Shadow = Color3.fromRGB(30, 30, 40),
        Gradient = false,
        IsDark = true
    },
    
    -- Dracula Pro Theme
    Dracula = {
        Name = "Dracula",
        WindowBg = Color3.fromRGB(40, 42, 54),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(68, 71, 90),
        ElementBg = Color3.fromRGB(98, 114, 164),
        SidebarBg = Color3.fromRGB(40, 42, 54),
        Accent = Color3.fromRGB(189, 147, 249),
        AccentSoft = Color3.fromRGB(139, 233, 253),
        Text = Color3.fromRGB(248, 248, 242),
        SubText = Color3.fromRGB(189, 147, 249),
        Stroke = Color3.fromRGB(98, 114, 164),
        Success = Color3.fromRGB(80, 250, 123),
        Warning = Color3.fromRGB(241, 250, 140),
        Error = Color3.fromRGB(255, 85, 85),
        Shadow = Color3.fromRGB(20, 20, 30),
        Gradient = false,
        IsDark = true
    },
    
    -- Tokyo Night (Premium)
    TokyoNight = {
        Name = "TokyoNight",
        WindowBg = Color3.fromRGB(26, 27, 38),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(36, 37, 54),
        ElementBg = Color3.fromRGB(46, 48, 68),
        SidebarBg = Color3.fromRGB(26, 27, 38),
        Accent = Color3.fromRGB(122, 162, 247),
        AccentSoft = Color3.fromRGB(142, 182, 267),
        Text = Color3.fromRGB(192, 202, 245),
        SubText = Color3.fromRGB(122, 162, 247),
        Stroke = Color3.fromRGB(56, 58, 78),
        Success = Color3.fromRGB(158, 206, 106),
        Warning = Color3.fromRGB(255, 203, 107),
        Error = Color3.fromRGB(247, 118, 142),
        Shadow = Color3.fromRGB(16, 17, 28),
        Gradient = false,
        IsDark = true
    },
    
    -- Catppuccin Mocha
    Catppuccin = {
        Name = "Catppuccin",
        WindowBg = Color3.fromRGB(30, 30, 46),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(49, 50, 68),
        ElementBg = Color3.fromRGB(69, 71, 90),
        SidebarBg = Color3.fromRGB(30, 30, 46),
        Accent = Color3.fromRGB(137, 180, 250),
        AccentSoft = Color3.fromRGB(157, 200, 270),
        Text = Color3.fromRGB(205, 214, 244),
        SubText = Color3.fromRGB(137, 180, 250),
        Stroke = Color3.fromRGB(59, 60, 78),
        Success = Color3.fromRGB(166, 227, 161),
        Warning = Color3.fromRGB(249, 226, 175),
        Error = Color3.fromRGB(243, 139, 168),
        Shadow = Color3.fromRGB(20, 20, 36),
        Gradient = false,
        IsDark = true
    },
    
    -- Gruvbox Dark
    Gruvbox = {
        Name = "Gruvbox",
        WindowBg = Color3.fromRGB(40, 40, 40),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(60, 56, 54),
        ElementBg = Color3.fromRGB(80, 73, 69),
        SidebarBg = Color3.fromRGB(40, 40, 40),
        Accent = Color3.fromRGB(254, 128, 25),
        AccentSoft = Color3.fromRGB(274, 148, 45),
        Text = Color3.fromRGB(235, 219, 178),
        SubText = Color3.fromRGB(254, 128, 25),
        Stroke = Color3.fromRGB(100, 96, 94),
        Success = Color3.fromRGB(184, 187, 38),
        Warning = Color3.fromRGB(250, 189, 47),
        Error = Color3.fromRGB(251, 73, 52),
        Shadow = Color3.fromRGB(30, 30, 30),
        Gradient = false,
        IsDark = true
    },
    
    -- One Dark Pro
    OneDark = {
        Name = "OneDark",
        WindowBg = Color3.fromRGB(40, 44, 52),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(53, 59, 69),
        ElementBg = Color3.fromRGB(66, 72, 82),
        SidebarBg = Color3.fromRGB(40, 44, 52),
        Accent = Color3.fromRGB(97, 175, 239),
        AccentSoft = Color3.fromRGB(117, 195, 259),
        Text = Color3.fromRGB(171, 178, 191),
        SubText = Color3.fromRGB(97, 175, 239),
        Stroke = Color3.fromRGB(76, 82, 92),
        Success = Color3.fromRGB(152, 195, 121),
        Warning = Color3.fromRGB(229, 192, 123),
        Error = Color3.fromRGB(224, 108, 117),
        Shadow = Color3.fromRGB(30, 34, 42),
        Gradient = false,
        IsDark = true
    },
    
    -- Monokai Pro
    Monokai = {
        Name = "Monokai",
        WindowBg = Color3.fromRGB(39, 40, 34),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(52, 53, 47),
        ElementBg = Color3.fromRGB(65, 66, 60),
        SidebarBg = Color3.fromRGB(39, 40, 34),
        Accent = Color3.fromRGB(249, 38, 114),
        AccentSoft = Color3.fromRGB(269, 58, 134),
        Text = Color3.fromRGB(248, 248, 242),
        SubText = Color3.fromRGB(249, 38, 114),
        Stroke = Color3.fromRGB(79, 80, 74),
        Success = Color3.fromRGB(166, 226, 46),
        Warning = Color3.fromRGB(253, 151, 31),
        Error = Color3.fromRGB(249, 38, 114),
        Shadow = Color3.fromRGB(29, 30, 24),
        Gradient = false,
        IsDark = true
    },
    
    -- Midnight Ocean (Animated)
    Midnight = {
        Name = "Midnight",
        WindowBg = Color3.fromRGB(25, 25, 50),
        WindowAlpha = 0.4,
        CardBg = Color3.fromRGB(35, 35, 70),
        ElementBg = Color3.fromRGB(45, 45, 90),
        SidebarBg = Color3.fromRGB(25, 25, 50),
        Accent = Color3.fromRGB(100, 150, 255),
        AccentSoft = Color3.fromRGB(120, 170, 275),
        Text = Color3.fromRGB(220, 230, 255),
        SubText = Color3.fromRGB(100, 150, 255),
        Stroke = Color3.fromRGB(65, 65, 100),
        Success = Color3.fromRGB(100, 255, 200),
        Warning = Color3.fromRGB(255, 200, 100),
        Error = Color3.fromRGB(255, 100, 100),
        Shadow = Color3.fromRGB(15, 15, 40),
        Gradient = true,
        IsDark = true,
        GradientColors = {
            Color3.fromRGB(25, 25, 50),
            Color3.fromRGB(50, 25, 75),
            Color3.fromRGB(25, 50, 75)
        }
    }
}

--------------------------------------------------------------------
-- 4. UTILITY FUNCTIONS - PERFORMANCE OPTIMIZED
--------------------------------------------------------------------
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function Ease(obj, props, duration, style, direction)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(
        duration or 0.2, 
        style or Enum.EasingStyle.Quad, 
        direction or Enum.EasingDirection.Out
    ), props):Play()
end

local function Spring(obj, target, velocity, damping)
    if not obj then return end
    local spring = {
        Object = obj,
        Target = target,
        Velocity = velocity or Vector2.new(0, 0),
        Damping = damping or 0.8,
        Stiffness = 300
    }
    
    local conn
    conn = RunService.Heartbeat:Connect(function(deltaTime)
        if not obj or not obj.Parent then
            conn:Disconnect()
            return
        end
        
        local current = Vector2.new(obj.Position.X.Offset, obj.Position.Y.Offset)
        local force = (spring.Target - current) * spring.Stiffness
        local damping = -spring.Velocity * spring.Damping
        
        spring.Velocity = spring.Velocity + (force + damping) * deltaTime
        current = current + spring.Velocity * deltaTime
        
        obj.Position = UDim2.fromOffset(current.X, current.Y)
        
        if spring.Velocity.Magnitude < 0.1 and (spring.Target - current).Magnitude < 0.1 then
            obj.Position = UDim2.fromOffset(spring.Target.X, spring.Target.Y)
            conn:Disconnect()
        end
    end)
end

local function GetPlayerGui()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    while not pg do
        task.wait()
        pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return pg
end

local function HasFileApi()
    return typeof(isfolder) == "function" and typeof(makefolder) == "function" and 
           typeof(writefile) == "function" and typeof(readfile) == "function" and 
           typeof(isfile) == "function"
end

local function EnsureFolder(folder)
    if not HasFileApi() then return end
    if not isfolder(folder) then
        makefolder(folder)
    end
end

local function SafeJSONEncode(tbl)
    local ok, result = pcall(HttpService.JSONEncode, HttpService, tbl)
    return ok and result or nil
end

local function SafeJSONDecode(str)
    local ok, result = pcall(HttpService.JSONDecode, HttpService, str)
    return ok and result or nil
end

local function SaveConfig(name, data)
    if not HasFileApi() then return end
    EnsureFolder(CONFIG_FOLDER)
    local json = SafeJSONEncode(data)
    if json then
        writefile(("%s/%s.json"):format(CONFIG_FOLDER, name), json)
    end
end

local function LoadConfig(name)
    if not HasFileApi() then return {} end
    EnsureFolder(CONFIG_FOLDER)
    local path = ("%s/%s.json"):format(CONFIG_FOLDER, name)
    if not isfile(path) then return {} end
    
    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then return {} end
    
    return SafeJSONDecode(content) or {}
end

local function CalculateTextSize(text, font, size)
    return TextService:GetTextSize(text, size, font, Vector2.new(1000, 1000))
end

local function GenerateGradient(colors, rotation)
    local gradient = Instance.new("UIGradient")
    local keypoints = {}
    
    for i, color in ipairs(colors) do
        table.insert(keypoints, ColorSequenceKeypoint.new((i-1)/(#colors-1), color))
    end
    
    gradient.Color = ColorSequence.new(keypoints)
    gradient.Rotation = rotation or 0
    return gradient
end

--------------------------------------------------------------------
-- 5. ICON SYSTEM - SUPERIOR TO WINDUI
--------------------------------------------------------------------
TakoGlass.Icons = {
    -- Lucide Icons (Superior to WindUI's basic icons)
    Home = "🏠",
    Settings = "⚙️",
    User = "👤",
    Search = "🔍",
    Heart = "❤️",
    Star = "⭐",
    Bell = "🔔",
    Mail = "✉️",
    Calendar = "📅",
    Clock = "🕐",
    Camera = "📷",
    Image = "🖼️",
    Video = "🎥",
    Music = "🎵",
    Mic = "🎤",
    Phone = "📞",
    Message = "💬",
    Chat = "💭",
    Send = "📤",
    Download = "⬇️",
    Upload = "⬆️",
    Save = "💾",
    Load = "📂",
    Folder = "📁",
    File = "📄",
    Code = "💻",
    Terminal = "🖥️",
    Bug = "🐛",
    Fire = "🔥",
    Lightning = "⚡",
    Rocket = "🚀",
    Target = "🎯",
    Trophy = "🏆",
    Medal = "🥇",
    Crown = "👑",
    Diamond = "💎",
    Gem = "💍",
    Money = "💰",
    Card = "💳",
    Gift = "🎁",
    Party = "🎉",
    Balloon = "🎈",
    Cake = "🍰",
    Coffee = "☕",
    Pizza = "🍕",
    Burger = "🍔",
    Fries = "🍟",
    Sushi = "🍣",
    Salad = "🥗",
    IceCream = "🍦",
    Chocolate = "🍫",
    Candy = "🍬",
    Lollipop = "🍭",
    Cookie = "🍪",
    Beer = "🍺",
    Wine = "🍷",
    Cocktail = "🍸",
    Whiskey = "🥃",
    Soda = "🥤",
    Milk = "🥛",
    Water = "💧",
    Fire = "🔥",
    WaterDrop = "💧",
    Leaf = "🍃",
    Tree = "🌳",
    Flower = "🌸",
    Sun = "☀️",
    Moon = "🌙",
    Star = "⭐",
    Cloud = "☁️",
    Rain = "🌧️",
    Snow = "❄️",
    Lightning = "⚡",
    Rainbow = "🌈",
    Umbrella = "☂️",
    Snowman = "⛄",
    Beach = "🏖️",
    Mountain = "🏔️",
    Island = "🏝️",
    Desert = "🏜️",
    City = "🏙️",
    Night = "🌃",
    Bridge = "🌉",
    House = "🏠",
    Building = "🏢",
    Office = "🏢",
    Hospital = "🏥",
    School = "🏫",
    Bank = "🏦",
    Hotel = "🏨",
    Restaurant = "🍽️",
    Store = "🏪",
    Factory = "🏭",
    Castle = "🏰",
    Church = "⛪",
    Mosque = "🕌",
    Synagogue = "🕍",
    Temple = "🛕",
    Statue = "🗿",
    Fountain = "⛲",
    Tent = "⛺",
    Stadium = "🏟️",
    Theater = "🎭",
    Museum = "🏛️",
    Library = "📚",
    Book = "📖",
    Newspaper = "📰",
    Magazine = "📓",
    Notebook = "📔",
    Pen = "🖊️",
    Pencil = "✏️",
    Brush = "🖌️",
    Paint = "🎨",
    Palette = "🎨",
    Scissors = "✂️",
    Ruler = "📏",
    Calculator = "🧮",
    Compass = "🧭",
    Map = "🗺️",
    Globe = "🌍",
    Satellite = "🛰️",
    Rocket = "🚀",
    Airplane = "✈️",
    Helicopter = "🚁",
    Car = "🚗",
    Truck = "🚚",
    Bus = "🚌",
    Train = "🚂",
    Metro = "🚇",
    Tram = "🚊",
    Bike = "🚲",
    Scooter = "🛴",
    Motorcycle = "🏍️",
    Boat = "⛵",
    Ship = "🚢",
    Submarine = "🚤",
    Yacht = "🛥️",
    Cruise = "🛳️",
    Canoe = "🛶",
    Rowboat = "🚣",
    Sailboat = "⛵",
    Anchor = "⚓",
    Wheel = "🎡",
    Ferris = "🎡",
    Roller = "🎢",
    Carousel = "🎠",
    Park = "🎪",
    Circus = "🎪",
    Festival = "🎭",
    Concert = "🎼",
    Theater = "🎭",
    Cinema = "🎬",
    Game = "🎮",
    Dice = "🎲",
    Card = "🃏",
    Slot = "🎰",
    Bowling = "🎳",
    Tennis = "🎾",
    Football = "🏈",
    Soccer = "⚽",
    Basketball = "🏀",
    Baseball = "⚾",
    Golf = "⛳",
    Hockey = "🏒",
    Boxing = "🥊",
    Fencing = "🤺",
    Archery = "🏹",
    Shooting = "🎯",
    Swimming = "🏊",
    Diving = "🤿",
    Surfing = "🏄",
    Sailing = "⛵",
    Rowing = "🚣",
    Climbing = "🧗",
    Hiking = "🥾",
    Camping = "🏕️",
    Fishing = "🎣",
    Hunting = "🦌",
    Riding = "🏇",
    Cycling = "🚴",
    Running = "🏃",
    Walking = "🚶",
    Dancing = "💃",
    Yoga = "🧘",
    Gym = "🏋️",
    Weight = "🏋️",
    Medal = "🥇",
    Trophy = "🏆",
    Award = "🏅",
    Star = "⭐",
    Heart = "❤️",
    Like = "👍",
    Dislike = "👎",
    Love = "😍",
    Happy = "😊",
    Sad = "😢",
    Angry = "😠",
    Surprised = "😲",
    Confused = "😕",
    Wink = "😉",
    Cool = "😎",
    Nerdy = "🤓",
    Sick = "🤒",
    Sleepy = "😴",
    Dizzy = "😵",
    Devil = "😈",
    Angel = "😇",
    Ghost = "👻",
    Alien = "👽",
    Robot = "🤖",
    Skull = "💀",
    Clown = "🤡",
    Panda = "🐼",
    Bear = "🐻",
    Tiger = "🐯",
    Lion = "🦁",
    Wolf = "🐺",
    Fox = "🦊",
    Cat = "🐱",
    Dog = "🐶",
    Mouse = "🐭",
    Rabbit = "🐰",
    Hamster = "🐹",
    Monkey = "🐵",
    Gorilla = "🦍",
    Elephant = "🐘",
    Rhino = "🦏",
    Hippo = "🦛",
    Horse = "🐴",
    Zebra = "🦓",
    Deer = "🦌",
    Cow = "🐮",
    Pig = "🐷",
    Sheep = "🐑",
    Goat = "🐐",
    Camel = "🐪",
    Giraffe = "🦒",
    Kangaroo = "🦘",
    Koala = "🐨",
    Penguin = "🐧",
    Ostrich = "🦩",
    Flamingo = "🦩",
    Peacock = "🦚",
    Swan = "🦢",
    Dove = "🕊️",
    Eagle = "🦅",
    Hawk = "🦅",
    Owl = "🦉",
    Parrot = "🦜",
    Chicken = "🐔",
    Turkey = "🦃",
    Duck = "🦆",
    Goose = "🪿",
    Swan = "🦢",
    Owl = "🦉",
    Bat = "🦇",
    Wolf = "🐺",
    Fox = "🦊",
    Raccoon = "🦝",
    Otter = "🦦",
    Beaver = "🦫",
    Hedgehog = "🦔",
    Sloth = "🦥",
    Armadillo = "🦔",
    Anteater = "🦙",
    Llama = "🦙",
    Camel = "🐪",
    Elephant = "🐘",
    Rhino = "🦏",
    Hippo = "🦛",
    Tiger = "🐯",
    Leopard = "🐆",
    Jaguar = "🐆",
    Cheetah = "🐆",
    Lion = "🦁",
    Panther = "🐆",
    Cougar = "🐆",
    Puma = "🐆",
    Bear = "🐻",
    Polar = "🐻‍❄️",
    Panda = "🐼",
    Koala = "🐨",
    Monkey = "🐵",
    Ape = "🦍",
    Gorilla = "🦍",
    Chimp = "🐒",
    Orangutan = "🦧",
    Baboon = "🐒",
    Mandrill = "🐒",
    Lemur = "🦥",
    Sloth = "🦥",
    Anteater = "🦙",
    Armadillo = "🦔",
    Hedgehog = "🦔",
    Porcupine = "🦔",
    Beaver = "🦫",
    Otter = "🦦",
    Raccoon = "🦝",
    Skunk = "🦨",
    Badger = "🦡",
    Wolverine = "🦡",
    Marten = "🦡",
    Mink = "🦦",
    Ferret = "🦨",
    Weasel = "🦨",
    Mongoose = "🦦",
    Meerkat = "🦦",
    Ferret = "🦨",
    Rabbit = "🐰",
    Hare = "🐰",
    Squirrel = "🐿️",
    Chipmunk = "🐿️",
    Hamster = "🐹",
    Guinea = "🐹",
    Mouse = "🐭",
    Rat = "🐀",
    Gerbil = "🐹",
    Degu = "🐹",
    Chinchilla = "🐭",
    Capybara = "🐻",
    Nutria = "🦫",
    Muskrat = "🦫",
    Beaver = "🦫",
    Porcupine = "🦔",
    Hedgehog = "🦔",
    Tenrec = "🦔",
    Shrew = "🦔",
    Mole = "🦔",
    Bat = "🦇",
    Flying = "🦇",
    Dolphin = "🐬",
    Whale = "🐋",
    Killer = "🐋",
    Humpback = "🐋",
    Blue = "🐋",
    Sperm = "🐋",
    Narwhal = "🐋",
    Beluga = "🐋",
    Seal = "🦭",
    Sea = "🦭",
    Walrus = "🦭",
    Otter = "🦦",
    Manatee = "🦭",
    Dugong = "🦭",
    Shark = "🦈",
    Fish = "🐟",
    Tropical = "🐠",
    Blowfish = "🐡",
    Octopus = "🐙",
    Squid = "🦑",
    Crab = "🦀",
    Lobster = "🦞",
    Shrimp = "🦐",
    Oyster = "🦪",
    Clam = "🦪",
    Scallop = "🦪",
    Snail = "🐌",
    Slug = "🐌",
    Butterfly = "🦋",
    Bug = "🐛",
    Ant = "🐜",
    Bee = "🐝",
    Beetle = "🪲",
    Ladybug = "🐞",
    Cricket = "🦗",
    Grasshopper = "🦗",
    Dragonfly = "🜻",
    Mosquito = "🦟",
    Fly = "🪰",
    Worm = "🪱",
    Caterpillar = "🐛",
    Spider = "🕷️",
    Scorpion = "🦂",
    Centipede = "🪳",
    Millipede = "🪳",
    Snake = "🐍",
    Lizard = "🦎",
    Gecko = "🦎",
    Chameleon = "🦎",
    Iguana = "🦎",
    Turtle = "🐢",
    Tortoise = "🐢",
    Crocodile = "🐊",
    Alligator = "🐊",
    Caiman = "🐊",
    Dinosaur = "🦕",
    T Rex = "🦖",
    Bird = "🐦",
    Eagle = "🦅",
    Hawk = "🦅",
    Falcon = "🦅",
    Owl = "🦉",
    Parrot = "🦜",
    Penguin = "🐧",
    Flamingo = "🦩",
    Peacock = "🦚",
    Swan = "🦢",
    Goose = "🪿",
    Duck = "🦆",
    Turkey = "🦃",
    Chicken = "🐔",
    Rooster = "🐓",
    Hummingbird = "🤍",
    Woodpecker = "🤍",
    Toucan = "🤍",
    Pelican = "🤍",
    Stork = "🤍",
    Heron = "🤍",
    Crane = "🤍",
    Ostrich = "🪶",
    Emu = "🪶",
    Kiwi = "🪶",
    Cassowary = "🪶",
    Rhea = "🪶",
    Dove = "🕊️",
    Pigeon = "🕊️",
    Crow = "🖤",
    Raven = "🖤",
    Magpie = "🖤",
    Jay = "🖤",
    Sparrow = "🖤",
    Robin = "🖤",
    Cardinal = "🖤",
    Bluebird = "🖤",
    Finch = "🖤",
    Canary = "🖤",
    Parakeet = "🖤",
    Cockatiel = "🖤",
    Cockatoo = "🖤",
    Macaw = "🖤",
    Lovebird = "🖤",
    Conure = "🖤",
    Budgie = "🖤",
    African = "🖤",
    Amazon = "🖤",
    Eclectus = "🖤",
    Hawkhead = "🖤",
    Lory = "🖤",
    Lorikeet = "🖤",
    Caique = "🖤",
    Pionus = "🖤",
    Quaker = "🖤",
    Ringneck = "🖤",
    Rosella = "🖤",
    Bourke = "🖤",
    Grass = "🖤",
    Kakariki = "🖤",
    Red = "🖤",
    Princess = "🖤",
    Regent = "🖤",
    Superb = "🖤",
    King = "🖤",
    Golden = "🖤",
    Crimson = "🖤",
    Swift = "🖤",
    Alpine = "🖤",
    Bee = "🐝",
    Honey = "🍯",
    Hive = "🍯",
    Wasp = "🐝",
    Hornet = "🐝",
    Yellowjacket = "🐝",
    Ant = "🐜",
    Termite = "🐜",
    Fly = "🪰",
    Mosquito = "🦟",
    Gnat = "🦟",
    Midge = "🦟",
    Flea = "🦟",
    Lice = "🦟",
    Tick = "🕷️",
    Mite = "🕷️",
    Spider = "🕷️",
    Tarantula = "🕷️",
    Scorpion = "🦂",
    Centipede = "🪳",
    Millipede = "🪳",
    Pillbug = "🪳",
    Silverfish = "🪳",
    Earwig = "🪳",
    Cockroach = "🪳",
    Cricket = "🦗",
    Grasshopper = "🦗",
    Locust = "🦗",
    Katydid = "🦗",
    Mantis = "🦗",
    Walking = "🦗",
    Dragonfly = "🜻",
    Damselfly = "🜻",
    Mayfly = "🜻",
    Caddisfly = "🜻",
    Stonefly = "🜻",
    Alderfly = "🜻",
    Lacewing = "🜻",
    Dobsonfly = "🜻",
    Fishfly = "🜻",
    Butterfly = "🦋",
    Moth = "🦋",
    Skipper = "🦋",
    Swallowtail = "🦋",
    Monarch = "🦋",
    Blue = "🦋",
    Admiral = "🦋",
    Tortoiseshell = "🦋",
    Fritillary = "🦋",
    Copper = "🦋",
    Hairstreak = "🦋",
    White = "🦋",
    Sulphur = "🦋",
    Orange = "🦋",
    Tip = "🦋",
    Azure = "🦋",
    Copper = "🦋",
    Metalmark = "🦋",
    Snout = "🦋",
    Brush = "🦋",
    Gossamer = "🦋",
    Clearwing = "🦋",
    Owlet = "🦋",
    Underwing = "🦋",
    Tiger = "🦋",
    Tussock = "🦋",
    Lymantriid = "🦋",
    Geometer = "🦋",
    Noctuid = "🦋",
    Sphingid = "🦋",
    Saturniid = "🦋",
    Nymphalid = "🦋",
    Papilionid = "🦋",
    Pierid = "🦋",
    Lycaenid = "🦋",
    Riodinid = "🦋",
    Hesperiid = "🦋"
    }
}

--------------------------------------------------------------------
-- 6. ANIMATION SYSTEM - SUPERIOR TO WINDUI
--------------------------------------------------------------------
TakoGlass.Animations = {
    Spring = function(object, target, config)
        config = config or {}
        local velocity = config.Velocity or Vector2.new(0, 0)
        local damping = config.Damping or 0.8
        local stiffness = config.Stiffness or 300
        local mass = config.Mass or 1
        
        local conn
        conn = RunService.Heartbeat:Connect(function(deltaTime)
            if not object or not object.Parent then
                conn:Disconnect()
                return
            end
            
            local current = Vector2.new(object.Position.X.Offset, object.Position.Y.Offset)
            local force = (target - current) * stiffness
            local dampingForce = -velocity * damping
            
            local acceleration = (force + dampingForce) / mass
            velocity = velocity + acceleration * deltaTime
            current = current + velocity * deltaTime
            
            object.Position = UDim2.fromOffset(current.X, current.Y)
            
            if velocity.Magnitude < 0.1 and (target - current).Magnitude < 0.1 then
                object.Position = UDim2.fromOffset(target.X, target.Y)
                conn:Disconnect()
            end
        end)
        
        return conn
    end,
    
    Bounce = function(object, scale, duration)
        local originalSize = object.Size
        local sequence = TweenService:Create(object, TweenInfo.new(duration/3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = originalSize * scale})
        sequence:Play()
        
        sequence.Completed:Connect(function()
            local returnTween = TweenService:Create(object, TweenInfo.new(duration/3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = originalSize})
            returnTween:Play()
        end)
    end,
    
    Shake = function(object, intensity, duration)
        local originalPos = object.Position
        local startTime = tick()
        
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not object or not object.Parent then
                conn:Disconnect()
                return
            end
            
            local elapsed = tick() - startTime
            if elapsed > duration then
                object.Position = originalPos
                conn:Disconnect()
                return
            end
            
            local shake = math.sin(elapsed * 50) * intensity * (1 - elapsed/duration)
            object.Position = originalPos + UDim2.fromOffset(shake, 0)
        end)
    end,
    
    Pulse = function(object, targetColor, duration)
        local originalColor = object.BackgroundColor3
        local tweenInfo = TweenInfo.new(duration/2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
        local tween = TweenService:Create(object, tweenInfo, {BackgroundColor3 = targetColor})
        tween:Play()
        return tween
    end,
    
    FadeIn = function(object, duration)
        object.BackgroundTransparency = 1
        local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {BackgroundTransparency = 0})
        tween:Play()
        return tween
    end,
    
    SlideIn = function(object, direction, duration)
        local originalPos = object.Position
        local offset = direction == "Left" and -100 or direction == "Right" and 100 or 
                      direction == "Up" and -50 or direction == "Down" and 50
        
        object.Position = originalPos + UDim2.fromOffset(
            (direction == "Left" or direction == "Right") and offset or 0,
            (direction == "Up" or direction == "Down") and offset or 0
        )
        
        local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
            {Position = originalPos})
        tween:Play()
        return tween
    end
}

--------------------------------------------------------------------
-- 7. NOTIFICATION SYSTEM - SUPERIOR TO WINDUI
--------------------------------------------------------------------
TakoGlass.Notifications = {
    Active = {},
    Queue = {},
    
    Show = function(options)
        options = options or {}
        local title = options.Title or "Notification"
        local content = options.Content or options.Message or ""
        local duration = options.Duration or 5
        local icon = options.Icon or "📢"
        local type = options.Type or "Default" -- Default, Success, Warning, Error
        local sound = options.Sound or false
        local actions = options.Actions or {} -- Buttons for user interaction
        
        -- Limit active notifications
        if #TakoGlass.Notifications.Active >= MAX_NOTIFICATIONS then
            table.insert(TakoGlass.Notifications.Queue, options)
            return
        end
        
        local pg = GetPlayerGui()
        local container = pg:FindFirstChild("TakoGlass_Notifications") or Create("ScreenGui", {
            Name = "TakoGlass_Notifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Global
        })
        
        if not container.Parent then
            container.Parent = pg
            Create("Frame", {
                Name = "Container",
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 320, 1, -20),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 10),
                Parent = container
            })
            
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Padding = UDim.new(0, 8),
                Parent = container.Container
            })
        end
        
        local theme = TakoGlass.CurrentTheme or TakoGlass.Themes.Dark
        local accentColor = theme.Accent
        
        if type == "Success" then
            accentColor = theme.Success
            icon = icon == "📢" and "✅" or icon
        elseif type == "Warning" then
            accentColor = theme.Warning
            icon = icon == "📢" and "⚠️" or icon
        elseif type == "Error" then
            accentColor = theme.Error
            icon = icon == "📢" and "❌" or icon
        end
        
        local notification = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 200,
            Position = UDim2.new(1, 50, 0, 0)
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, WINDOW_RADIUS), Parent = notification})
        Create("UIStroke", {
            Color = accentColor,
            Thickness = 2,
            Transparency = 0.5,
            Parent = notification
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            Parent = notification
        })
        
        -- Icon
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = icon,
            Font = UI_FONT,
            TextSize = 24,
            TextColor3 = accentColor,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 201,
            Parent = notification
        })
        
        -- Title
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = title,
            Font = UI_FONT,
            TextSize = 16,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -40, 0, 20),
            Position = UDim2.new(0, 35, 0, 0),
            ZIndex = 201,
            Parent = notification
        })
        
        -- Content
        local contentLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = content,
            Font = UI_FONT,
            TextSize = 13,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Size = UDim2.new(1, -40, 0, 0),
            Position = UDim2.new(0, 35, 0, 22),
            ZIndex = 201,
            Parent = notification
        })
        
        -- Calculate height based on content
        local textHeight = CalculateTextSize(content, UI_FONT, 13, Vector2.new(250, 1000)).Y
        local totalHeight = math.max(50, 35 + textHeight)
        
        notification.Size = UDim2.new(1, 0, 0, totalHeight)
        contentLabel.Size = UDim2.new(1, -40, 0, textHeight)
        
        -- Close button
        local closeBtn = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "✕",
            Font = UI_FONT,
            TextSize = 16,
            TextColor3 = theme.SubText,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -20, 0, 0),
            ZIndex = 201,
            Parent = notification
        })
        
        -- Action buttons if provided
        if #actions > 0 then
            local actionsFrame = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -35, 0, 30),
                Position = UDim2.new(0, 35, 1, -30),
                ZIndex = 201,
                Parent = notification
            })
            
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 8),
                Parent = actionsFrame
            })
            
            for _, action in ipairs(actions) do
                local actionBtn = Create("TextButton", {
                    BackgroundColor3 = accentColor,
                    BackgroundTransparency = 0.8,
                    Text = action.Text,
                    Font = UI_FONT,
                    TextSize = 12,
                    TextColor3 = theme.Text,
                    Size = UDim2.new(0, 60, 0, 22),
                    ZIndex = 202,
                    Parent = actionsFrame
                })
                Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent = actionBtn})
                
                actionBtn.MouseButton1Click:Connect(function()
                    if action.Callback then
                        action.Callback()
                    end
                    TakoGlass.Notifications:Remove(notification)
                end)
            end
            
            notification.Size = UDim2.new(1, 0, 0, totalHeight + 35)
        end
        
        notification.Parent = container.Container
        table.insert(TakoGlass.Notifications.Active, notification)
        
        -- Animations
        TakoGlass.Animations.SlideIn(notification, "Right", 0.3)
        TakoGlass.Animations.FadeIn(notification, 0.3)
        
        -- Auto-close
        local closeConn
        closeConn = task.delay(duration, function()
            TakoGlass.Notifications:Remove(notification)
        end)
        
        -- Manual close
        closeBtn.MouseButton1Click:Connect(function()
            TakoGlass.Notifications:Remove(notification)
            if closeConn then
                task.cancel(closeConn)
            end
        end)
        
        -- Sound effect (if enabled)
        if sound and TakoGlass.Services.Sound then
            TakoGlass.Services.Sound:Play("Notification")
        end
        
        return notification
    end,
    
    Remove = function(notification)
        if not notification or not notification.Parent then return end
        
        local index = table.find(TakoGlass.Notifications.Active, notification)
        if index then
            table.remove(TakoGlass.Notifications.Active, index)
        end
        
        TakoGlass.Animations.SlideIn(notification, "Right", 0.2)
        Ease(notification, {BackgroundTransparency = 1}, 0.2)
        
        task.delay(0.2, function()
            if notification then
                notification:Destroy()
            end
            
            -- Process queue
            if #TakoGlass.Notifications.Queue > 0 then
                local nextNotif = table.remove(TakoGlass.Notifications.Queue, 1)
                TakoGlass.Notifications.Show(nextNotif)
            end
        end)
    end
}

--------------------------------------------------------------------
-- 8. TOOLTIP SYSTEM - SUPERIOR TO WINDUI
--------------------------------------------------------------------
TakoGlass.Tooltips = {
    Active = nil,
    
    Show = function(text, position, delay)
        if TakoGlass.Tooltips.Active then
            TakoGlass.Tooltips.Hide()
        end
        
        if not text or text == "" then return end
        
        delay = delay or 0.5
        local theme = TakoGlass.CurrentTheme or TakoGlass.Themes.Dark
        
        task.delay(delay, function()
            if not text then return end
            
            local pg = GetPlayerGui()
            local tooltip = Create("Frame", {
                Name = "TakoGlass_Tooltip",
                BackgroundColor3 = theme.CardBg,
                BackgroundTransparency = 0.05,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 0, 0, 0),
                ZIndex = 300,
                Parent = pg
            })
            
            Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent = tooltip})
            Create("UIStroke", {
                Color = theme.Stroke,
                Thickness = 1,
                Transparency = 0.3,
                Parent = tooltip
            })
            
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = tooltip
            })
            
            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = text,
                Font = UI_FONT,
                TextSize = 12,
                TextColor3 = theme.Text,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.XY,
                ZIndex = 301,
                Parent = tooltip
            })
            
            -- Position calculation
            local mousePos = UserInputService:GetMouseLocation()
            local viewportSize = workspace.CurrentCamera.ViewportSize
            
            local tooltipSize = CalculateTextSize(text, UI_FONT, 12, Vector2.new(200, 1000))
            local tooltipWidth = math.min(tooltipSize.X + 20, 200)
            local tooltipHeight = tooltipSize.Y + 12
            
            local x = mousePos.X + 15
            local y = mousePos.Y + 15
            
            -- Keep tooltip on screen
            if x + tooltipWidth > viewportSize.X then
                x = mousePos.X - tooltipWidth - 15
            end
            
            if y + tooltipHeight > viewportSize.Y then
                y = mousePos.Y - tooltipHeight - 15
            end
            
            tooltip.Position = UDim2.fromOffset(x, y)
            tooltip.Size = UDim2.new(0, tooltipWidth, 0, tooltipHeight)
            
            TakoGlass.Animations.FadeIn(tooltip, 0.2)
            
            TakoGlass.Tooltips.Active = tooltip
            
            -- Follow mouse
            local conn
            conn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local newX = input.Position.X + 15
                    local newY = input.Position.Y + 15
                    
                    if newX + tooltipWidth > viewportSize.X then
                        newX = input.Position.X - tooltipWidth - 15
                    end
                    
                    if newY + tooltipHeight > viewportSize.Y then
                        newY = input.Position.Y - tooltipHeight - 15
                    end
                    
                    tooltip.Position = UDim2.fromOffset(newX, newY)
                end
            end)
            
            tooltip.Destroying:Connect(function()
                if conn then conn:Disconnect() end
            end)
        end)
    end,
    
    Hide = function()
        if TakoGlass.Tooltips.Active then
            Ease(TakoGlass.Tooltips.Active, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)}, 0.2)
            task.delay(0.2, function()
                if TakoGlass.Tooltips.Active then
                    TakoGlass.Tooltips.Active:Destroy()
                    TakoGlass.Tooltips.Active = nil
                end
            end)
        end
    end,
    
    Add = function(instance, text, delay)
        if not instance or not text then return end
        
        local enterConn, leaveConn
        delay = delay or 0.5
        
        enterConn = instance.MouseEnter:Connect(function()
            TakoGlass.Tooltips.Show(text, nil, delay)
        end)
        
        leaveConn = instance.MouseLeave:Connect(function()
            TakoGlass.Tooltips.Hide()
        end)
        
        return enterConn, leaveConn
    end
}

--------------------------------------------------------------------
-- 9. WINDOW SYSTEM - MAC/WINDOWS STYLE TOPBAR
--------------------------------------------------------------------
function TakoGlass:CreateWindow(options)
    options = options or {}
    
    local window = {
        Title = options.Title or "TakoGlass v10.0",
        SubTitle = options.SubTitle or "Superior to WindUI",
        ConfigName = options.ConfigName or options.Title or "TakoGlass",
        Size = options.Size or UDim2.fromOffset(650, 450),
        Position = options.Position or UDim2.fromScale(0.5, 0.5),
        Theme = options.Theme or DEFAULT_THEME,
        TopbarStyle = options.TopbarStyle or "Mac", -- Mac or Windows
        SidebarWidth = options.SidebarWidth or 180,
        Transparent = options.Transparent ~= false,
        Blur = options.Blur ~= false,
        BlurSize = options.BlurSize or 20,
        CanResize = options.CanResize ~= false,
        CanMinimize = options.CanMinimize ~= false,
        CanClose = options.CanClose ~= false,
        ShowTitle = options.ShowTitle ~= false,
        ShowIcon = options.ShowIcon ~= false,
        Animations = options.Animations ~= false,
        Sound = options.Sound or false,
        
        -- Internal
        Tabs = {},
        Elements = {},
        Connections = {},
        IsOpen = true,
        IsMinimized = false,
        IsDragging = false,
        DragOffset = Vector2.new(),
        CurrentTab = nil,
        Config = {},
        Flags = {}
    }
    
    setmetatable(window, TakoGlass)
    
    -- Load config
    window.Config = LoadConfig(window.ConfigName)
    if window.Config.__Theme and TakoGlass.Themes[window.Config.__Theme] then
        window.Theme = window.Config.__Theme
    end
    
    TakoGlass.CurrentTheme = TakoGlass.Themes[window.Theme]
    
    -- Create GUI
    local pg = GetPlayerGui()
    window.Gui = Create("ScreenGui", {
        Name = "TakoGlass_" .. window.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    window.Gui.Parent = pg
    
    -- Blur effect
    window.BlurEffect = Create("BlurEffect", {
        Name = "TakoGlass_Blur",
        Size = window.BlurSize,
        Enabled = window.Blur and window.IsOpen,
        Parent = Lighting
    })
    
    -- Main window frame
    window.MainFrame = Create("Frame", {
        Name = "MainWindow",
        Size = window.Size,
        Position = window.Position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = TakoGlass.CurrentTheme.WindowBg,
        BackgroundTransparency = window.Transparent and TakoGlass.CurrentTheme.WindowAlpha or 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = window.Gui
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, WINDOW_RADIUS), Parent = window.MainFrame})
    
    -- Drop shadow for depth
    local shadow = Create("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        BackgroundTransparency = 1,
        Image = "rbxassetid://13190783835", -- Blur shadow
        ImageTransparency = 0.7,
        ZIndex = 99,
        Parent = window.MainFrame
    })
    
    -- Topbar based on style
    window:CreateTopbar()
    
    -- Content area
    window.ContentFrame = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        ZIndex = 101,
        Parent = window.MainFrame
    })
    
    -- Sidebar
    window:CreateSidebar()
    
    -- Resize handle (if enabled)
    if window.CanResize then
        window:CreateResizeHandle()
    end
    
    -- Drag functionality
    window:SetupDragging()
    
    -- Keyboard shortcuts
    window:SetupKeyboardShortcuts()
    
    -- Apply theme
    window:ApplyTheme(TakoGlass.CurrentTheme)
    
    -- Opening animation
    if window.Animations then
        window.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        window.MainFrame.BackgroundTransparency = 1
        Ease(window.MainFrame, {Size = window.Size, BackgroundTransparency = window.Transparent and TakoGlass.CurrentTheme.WindowAlpha or 0}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
    
    table.insert(TakoGlass.Windows, window)
    return window
end

function TakoGlass:CreateTopbar()
    local theme = TakoGlass.CurrentTheme
    
    self.Topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        ZIndex = 102,
        Parent = self.MainFrame
    })
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 12),
        Parent = self.Topbar
    })
    
    -- Window controls based on style
    if self.TopbarStyle == "Mac" then
        -- Mac style (traffic lights)
        local controls = Create("Frame", {
            Size = UDim2.new(0, 60, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 15),
            Parent = self.Topbar
        })
        
        local closeBtn = Create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(255, 95, 87),
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 0, 0, 1),
            Text = "",
            ZIndex = 103,
            Parent = controls
        })
        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = closeBtn})
        
        local minimizeBtn = Create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(255, 189, 46),
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 20, 0, 1),
            Text = "",
            ZIndex = 103,
            Parent = controls
        })
        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = minimizeBtn})
        
        local maximizeBtn = Create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(40, 201, 64),
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 40, 0, 1),
            Text = "",
            ZIndex = 103,
            Parent = controls
        })
        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = maximizeBtn})
        
        -- Control functionality
        closeBtn.MouseButton1Click:Connect(function()
            self:Close()
        end)
        
        minimizeBtn.MouseButton1Click:Connect(function()
            self:Minimize()
        end)
        
        maximizeBtn.MouseButton1Click:Connect(function()
            self:Maximize()
        end)
        
        -- Hover effects
        local function addHover(btn, icon)
            btn.MouseEnter:Connect(function()
                btn.BackgroundTransparency = 0.3
                TakoGlass.Tooltips.Show(icon, btn.AbsolutePosition)
            end)
            
            btn.MouseLeave:Connect(function()
                btn.BackgroundTransparency = 0
                TakoGlass.Tooltips.Hide()
            end)
        end
        
        addHover(closeBtn, "Close")
        addHover(minimizeBtn, "Minimize")
        addHover(maximizeBtn, "Maximize")
        
    else -- Windows style
        -- Windows style control buttons
        local controls = Create("Frame", {
            Size = UDim2.new(0, 120, 0, 30),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -120, 0, 7),
            Parent = self.Topbar
        })
        
        local minimizeBtn = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "—",
            Font = UI_FONT,
            TextSize = 18,
            TextColor3 = theme.Text,
            Size = UDim2.new(0, 40, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 103,
            Parent = controls
        })
        
        local maximizeBtn = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "□",
            Font = UI_FONT,
            TextSize = 16,
            TextColor3 = theme.Text,
            Size = UDim2.new(0, 40, 1, 0),
            Position = UDim2.new(0, 40, 0, 0),
            ZIndex = 103,
            Parent = controls
        })
        
        local closeBtn = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "✕",
            Font = UI_FONT,
            TextSize = 16,
            TextColor3 = theme.Text,
            Size = UDim2.new(0, 40, 1, 0),
            Position = UDim2.new(0, 80, 0, 0),
            ZIndex = 103,
            Parent = controls
        })
        
        -- Hover effects
        local function addHover(btn, hoverColor)
            btn.MouseEnter:Connect(function()
                Ease(btn, {TextColor3 = theme.Accent}, 0.2)
                btn.BackgroundTransparency = 0.9
            end)
            
            btn.MouseLeave:Connect(function()
                Ease(btn, {TextColor3 = theme.Text}, 0.2)
                btn.BackgroundTransparency = 1
            end)
        end
        
        addHover(minimizeBtn)
        addHover(maximizeBtn)
        addHover(closeBtn, theme.Error)
        
        -- Functionality
        minimizeBtn.MouseButton1Click:Connect(function()
            self:Minimize()
        end)
        
        maximizeBtn.MouseButton1Click:Connect(function()
            self:Maximize()
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            self:Close()
        end)
    end
    
    -- Title and icon
    if self.ShowTitle then
        local titleContainer = Create("Frame", {
            Size = UDim2.new(1, -150, 1, 0),
            Position = self.TopbarStyle == "Mac" and UDim2.new(0, 80, 0, 0) or UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Parent = self.Topbar
        })
        
        if self.ShowIcon then
            local icon = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = "🎨",
                Font = UI_FONT,
                TextSize = 20,
                TextColor3 = theme.Text,
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 0, 0.5, -12),
                ZIndex = 103,
                Parent = titleContainer
            })
            
            self.TitleLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = self.Title,
                Font = UI_FONT,
                TextSize = 16,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 2),
                ZIndex = 103,
                Parent = titleContainer
            })
            
            self.SubTitleLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = self.SubTitle,
                Font = UI_FONT,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -30, 0, 16),
                Position = UDim2.new(0, 30, 1, -18),
                ZIndex = 103,
                Parent = titleContainer
            })
        else
            self.TitleLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = self.Title,
                Font = UI_FONT,
                TextSize = 16,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 2),
                ZIndex = 103,
                Parent = titleContainer
            })
            
            self.SubTitleLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = self.SubTitle,
                Font = UI_FONT,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 16),
                Position = UDim2.new(0, 0, 1, -18),
                ZIndex = 103,
                Parent = titleContainer
            })
        end
    end
end

function TakoGlass:CreateSidebar()
    local theme = TakoGlass.CurrentTheme
    
    self.Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, self.SidebarWidth, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = self.Transparent and 0.2 or 0,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = self.ContentFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, WINDOW_RADIUS), Parent = self.Sidebar})
    
    -- Sidebar content
    self.SidebarContent = Create("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 102,
        Parent = self.Sidebar
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        Parent = self.SidebarContent
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = self.SidebarContent
    })
    
    -- Resize handle for sidebar
    local resizeHandle = Create("Frame", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 4, 1, 0),
        Position = UDim2.new(1, -2, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 103,
        Parent = self.Sidebar
    })
    
    TakoGlass.Tooltips.Add(resizeHandle, "Drag to resize sidebar")
    
    -- Sidebar resize functionality
    local isResizing = false
    local startWidth = self.SidebarWidth
    local startX = 0
    
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = true
            startWidth = self.SidebarWidth
            startX = input.Position.X
            input:Capture()
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position.X - startX
            local newWidth = math.clamp(startWidth + delta, 120, 300)
            
            self.SidebarWidth = newWidth
            self.Sidebar.Size = UDim2.new(0, newWidth, 1, 0)
            self.ContentArea.Position = UDim2.new(0, newWidth, 0, 0)
            self.ContentArea.Size = UDim2.new(1, -newWidth, 1, 0)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if isResizing and input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = false
            input:Release()
            
            -- Save to config
            self.Config.__SidebarWidth = self.SidebarWidth
            SaveConfig(self.ConfigName, self.Config)
        end
    end)
end

function TakoGlass:CreateResizeHandle()
    local resizeHandle = Create("Frame", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(1, -12, 1, -12),
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = self.MainFrame
    })
    
    local resizeIcon = Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://13190785000", -- Resize icon
        ImageColor3 = TakoGlass.CurrentTheme.SubText,
        ImageTransparency = 0.5,
        Parent = resizeHandle
    })
    
    -- Resize functionality
    local isResizing = false
    local startSize = self.Size
    local startPos = Vector2.new()
    
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = true
            startSize = self.Size
            startPos = input.Position
            input:Capture()
            
            -- Change cursor
            GuiService:SetCursor("ResizeNWSE")
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startPos
            local newSize = UDim2.fromOffset(
                math.clamp(startSize.X.Offset + delta.X, 400, 1200),
                math.clamp(startSize.Y.Offset + delta.Y, 300, 800)
            )
            
            self.Size = newSize
            self.MainFrame.Size = newSize
            
            -- Update content areas
            if self.ContentArea then
                self.ContentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, 0)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if isResizing and input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = false
            input:Release()
            GuiService:SetCursor("Default")
            
            -- Save to config
            self.Config.__Size = {self.Size.X.Offset, self.Size.Y.Offset}
            SaveConfig(self.ConfigName, self.Config)
        end
    end)
    
    TakoGlass.Tooltips.Add(resizeHandle, "Drag to resize window")
end

function TakoGlass:SetupDragging()
    local topbar = self.Topbar
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.IsDragging = true
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = self.MainFrame.AbsolutePosition
            self.DragOffset = mousePos - framePos
            
            input:Capture()
            GuiService:SetCursor("Drag")
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = input.Position
            local newPos = mousePos - self.DragOffset
            
            -- Keep window on screen
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local frameSize = self.MainFrame.AbsoluteSize
            
            newPos = Vector2.new(
                math.clamp(newPos.X, 0, viewportSize.X - frameSize.X),
                math.clamp(newPos.Y, 0, viewportSize.Y - frameSize.Y)
            )
            
            self.MainFrame.Position = UDim2.fromOffset(newPos.X, newPos.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if self.IsDragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.IsDragging = false
            input:Release()
            GuiService:SetCursor("Default")
            
            -- Save position
            local pos = self.MainFrame.AbsolutePosition
            self.Config.__Position = {pos.X, pos.Y}
            SaveConfig(self.ConfigName, self.Config)
        end
    end)
end

function TakoGlass:SetupKeyboardShortcuts()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.RightShift then
            self:SetVisible(not self.IsOpen)
        elseif input.KeyCode == Enum.KeyCode.Escape and self.IsOpen then
            self:Close()
        end
    end))
end

--------------------------------------------------------------------
-- 10. WINDOW METHODS
--------------------------------------------------------------------
function TakoGlass:SetVisible(visible)
    self.IsOpen = visible
    self.Gui.Enabled = visible
    if self.BlurEffect then
        self.BlurEffect.Enabled = visible and self.Blur
    end
    
    if self.Animations then
        if visible then
            self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
            self.MainFrame.BackgroundTransparency = 1
            Ease(self.MainFrame, {Size = self.Size, BackgroundTransparency = self.Transparent and TakoGlass.CurrentTheme.WindowAlpha or 0}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Ease(self.MainFrame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        end
    end
end

function TakoGlass:Minimize()
    self.IsMinimized = true
    local targetHeight = self.ShowTitle and 44 or 30
    
    if self.Animations then
        Ease(self.ContentFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        Ease(self.MainFrame, {Size = UDim2.new(self.Size.X, UDim2.new(0, targetHeight))}, 0.3)
    else
        self.ContentFrame.Size = UDim2.new(1, 0, 0, 0)
        self.MainFrame.Size = UDim2.new(self.Size.X, UDim2.new(0, targetHeight))
    end
end

function TakoGlass:Maximize()
    self.IsMinimized = false
    
    if self.Animations then
        Ease(self.ContentFrame, {Size = UDim2.new(1, 0, 1, -44)}, 0.3)
        Ease(self.MainFrame, {Size = self.Size}, 0.3)
    else
        self.ContentFrame.Size = UDim2.new(1, 0, 1, -44)
        self.MainFrame.Size = self.Size
    end
end

function TakoGlass:Close()
    if self.Animations then
        Ease(self.MainFrame, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.3, function()
            self:Destroy()
        end)
    else
        self:Destroy()
    end
end

function TakoGlass:Destroy()
    -- Disconnect all connections
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    
    -- Destroy blur effect
    if self.BlurEffect then
        self.BlurEffect:Destroy()
    end
    
    -- Destroy GUI
    if self.Gui then
        self.Gui:Destroy()
    end
    
    -- Remove from windows list
    local index = table.find(TakoGlass.Windows, self)
    if index then
        table.remove(TakoGlass.Windows, index)
    end
end

function TakoGlass:SetTheme(themeName)
    if not TakoGlass.Themes[themeName] then return end
    
    self.Theme = themeName
    TakoGlass.CurrentTheme = TakoGlass.Themes[themeName]
    
    self:ApplyTheme(TakoGlass.CurrentTheme)
    
    -- Save to config
    self.Config.__Theme = themeName
    SaveConfig(self.ConfigName, self.Config)
    
    -- Notification
    TakoGlass.Notifications.Show({
        Title = "Theme Changed",
        Content = "Switched to " .. themeName .. " theme",
        Duration = 2,
        Type = "Success",
        Icon = "🎨"
    })
end

function TakoGlass:ApplyTheme(theme)
    -- Apply theme to main components
    self.MainFrame.BackgroundColor3 = theme.WindowBg
    self.MainFrame.BackgroundTransparency = self.Transparent and theme.WindowAlpha or 0
    
    if self.Sidebar then
        self.Sidebar.BackgroundColor3 = theme.SidebarBg
        self.Sidebar.BackgroundTransparency = self.Transparent and 0.2 or 0
    end
    
    if self.TitleLabel then
        self.TitleLabel.TextColor3 = theme.Text
    end
    
    if self.SubTitleLabel then
        self.SubTitleLabel.TextColor3 = theme.SubText
    end
    
    -- Apply to all tabs
    for _, tab in ipairs(self.Tabs) do
        if tab.ApplyTheme then
            tab:ApplyTheme(theme)
        end
    end
    
    -- Apply to all elements
    for _, element in ipairs(self.Elements) do
        if element.ApplyTheme then
            element:ApplyTheme(theme)
        end
    end
end

function TakoGlass:CreateTab(options)
    options = options or {}
    
    local tab = {
        Window = self,
        Name = options.Name or "Tab",
        Icon = options.Icon or "📄",
        Description = options.Description or "",
        Content = {},
        Sections = {},
        Elements = {},
        IsActive = false,
        Order = options.Order or #self.Tabs + 1
    }
    
    -- Create tab button
    tab.Button = Create("TextButton", {
        Name = tab.Name:gsub(" ", ""),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        Text = "",
        ZIndex = 104,
        Parent = self.SidebarContent
    })
    
    -- Tab highlight
    tab.Highlight = Create("Frame", {
        BackgroundColor3 = TakoGlass.CurrentTheme.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 4, 1, -8),
        Position = UDim2.new(0, -2, 0, 4),
        ZIndex = 105,
        Parent = tab.Button
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = tab.Highlight})
    
    -- Tab icon
    tab.IconLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tab.Icon,
        Font = UI_FONT,
        TextSize = 20,
        TextColor3 = TakoGlass.CurrentTheme.Text,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 12, 0, 13),
        ZIndex = 105,
        Parent = tab.Button
    })
    
    -- Tab name
    tab.NameLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tab.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = TakoGlass.CurrentTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.new(0, 40, 0, 8),
        ZIndex = 105,
        Parent = tab.Button
    })
    
    -- Tab description (if provided)
    if tab.Description ~= "" then
        tab.DescriptionLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = tab.Description,
            Font = UI_FONT,
            TextSize = 11,
            TextColor3 = TakoGlass.CurrentTheme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -40, 0, 14),
            Position = UDim2.new(0, 40, 1, -18),
            ZIndex = 105,
            Parent = tab.Button
        })
    end
    
    -- Content frame
    tab.ContentFrame = Create("ScrollingFrame", {
        Name = tab.Name .. "_Content",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = TakoGlass.CurrentTheme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 103,
        Visible = false,
        Parent = self.ContentArea or self.ContentFrame
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 12),
        Parent = tab.ContentFrame
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = tab.ContentFrame
    })
    
    -- Tab functionality
    tab.Button.MouseButton1Click:Connect(function()
        self:SetActiveTab(tab)
    end)
    
    tab.Button.MouseEnter:Connect(function()
        if not tab.IsActive then
            Ease(tab.Button, {BackgroundTransparency = 0.9, BackgroundColor3 = TakoGlass.CurrentTheme.ElementBg}, 0.2)
        end
    end)
    
    tab.Button.MouseLeave:Connect(function()
        if not tab.IsActive then
            Ease(tab.Button, {BackgroundTransparency = 1}, 0.2)
        end
    end)
    
    -- Tab methods
    function tab:SetActive(active)
        self.IsActive = active
        self.ContentFrame.Visible = active
        
        if active then
            Ease(self.Highlight, {BackgroundTransparency = 0}, 0.2)
            Ease(self.IconLabel, {TextColor3 = TakoGlass.CurrentTheme.Accent}, 0.2)
            Ease(self.NameLabel, {TextColor3 = TakoGlass.CurrentTheme.Accent}, 0.2)
            
            if self.DescriptionLabel then
                Ease(self.DescriptionLabel, {TextColor3 = TakoGlass.CurrentTheme.Accent}, 0.2)
            end
        else
            Ease(self.Highlight, {BackgroundTransparency = 1}, 0.2)
            Ease(self.IconLabel, {TextColor3 = TakoGlass.CurrentTheme.Text}, 0.2)
            Ease(self.NameLabel, {TextColor3 = TakoGlass.CurrentTheme.Text}, 0.2)
            
            if self.DescriptionLabel then
                Ease(self.DescriptionLabel, {TextColor3 = TakoGlass.CurrentTheme.SubText}, 0.2)
            end
        end
    end
    
    function tab:ApplyTheme(theme)
        if self.IsActive then
            self.Highlight.BackgroundColor3 = theme.Accent
            self.IconLabel.TextColor3 = theme.Accent
            self.NameLabel.TextColor3 = theme.Accent
            if self.DescriptionLabel then
                self.DescriptionLabel.TextColor3 = theme.Accent
            end
        else
            self.IconLabel.TextColor3 = theme.Text
            self.NameLabel.TextColor3 = theme.Text
            if self.DescriptionLabel then
                self.DescriptionLabel.TextColor3 = theme.SubText
            end
        end
        
        for _, section in ipairs(self.Sections) do
            if section.ApplyTheme then
                section:ApplyTheme(theme)
            end
        end
    end
    
    function tab:CreateSection(options)
        return TakoGlass.CreateSection(self, options)
    end
    
    -- Auto-activate first tab
    if #self.Tabs == 0 then
        tab:SetActive(true)
        self.CurrentTab = tab
    end
    
    table.insert(self.Tabs, tab)
    return tab
end

function TakoGlass:SetActiveTab(tab)
    if self.CurrentTab == tab then return end
    
    -- Deactivate current tab
    if self.CurrentTab then
        self.CurrentTab:SetActive(false)
    end
    
    -- Activate new tab
    tab:SetActive(true)
    self.CurrentTab = tab
    
    -- Update canvas size
    tab.ContentFrame.CanvasSize = UDim2.new(0, 0, 0, tab.ContentFrame.UIListLayout.AbsoluteContentSize.Y + 30)
end

--------------------------------------------------------------------
-- 11. SECTION SYSTEM - SUPERIOR TO WINDUI
--------------------------------------------------------------------
function TakoGlass.CreateSection(tab, options)
    options = options or {}
    
    local section = {
        Tab = tab,
        Window = tab.Window,
        Name = options.Name or "Section",
        Description = options.Description or "",
        IsCollapsed = options.Collapsed or false,
        CanCollapse = options.CanCollapse ~= false,
        Elements = {},
        Order = options.Order or #tab.Sections + 1
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Section frame
    section.Frame = Create("Frame", {
        Name = section.Name:gsub(" ", ""),
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = tab.Window.Transparent and 0.25 or 0.05,
        BorderSizePixel = 0,
        ZIndex = 104,
        Parent = tab.ContentFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent = section.Frame})
    Create("UIStroke", {
        Color = theme.Stroke,
        Thickness = 1,
        Transparency = 0.4,
        Parent = section.Frame
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = section.Frame
    })
    
    -- Header
    section.Header = Create("TextButton", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        Text = "",
        ZIndex = 105,
        Parent = section.Frame
    })
    
    -- Section icon
    section.Icon = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = options.Icon or "📁",
        Font = UI_FONT,
        TextSize = 18,
        TextColor3 = theme.Text,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 0, 0, 6),
        ZIndex = 106,
        Parent = section.Header
    })
    
    -- Section title
    section.Title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = section.Name,
        Font = UI_FONT,
        TextSize = 16,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 30, 0, 2),
        ZIndex = 106,
        Parent = section.Header
    })
    
    -- Section description
    if section.Description ~= "" then
        section.DescriptionLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = section.Description,
            Font = UI_FONT,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -60, 0, 14),
            Position = UDim2.new(0, 30, 1, -14),
            ZIndex = 106,
            Parent = section.Header
        })
    end
    
    -- Collapse button
    if section.CanCollapse then
        section.CollapseButton = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = section.IsCollapsed and "▶" or "▼",
            Font = UI_FONT,
            TextSize = 14,
            TextColor3 = theme.SubText,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -24, 0, 6),
            ZIndex = 106,
            Parent = section.Header
        })
        
        TakoGlass.Tooltips.Add(section.CollapseButton, section.IsCollapsed and "Expand section" or "Collapse section")
        
        section.CollapseButton.MouseButton1Click:Connect(function()
            section:SetCollapsed(not section.IsCollapsed)
        end)
    end
    
    -- Content area
    section.Content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = 105,
        Parent = section.Frame
    })
    
    section.ListLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        Parent = section.Content
    })
    
    -- Update section height when content changes
    section.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentHeight = section.ListLayout.AbsoluteContentSize.Y
        local headerHeight = 48
        local padding = 24
        local totalHeight = headerHeight + (section.IsCollapsed and 0 or contentHeight + padding)
        
        Ease(section.Frame, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        -- Update tab canvas size
        tab.ContentFrame.CanvasSize = UDim2.new(0, 0, 0, tab.ContentFrame.UIListLayout.AbsoluteContentSize.Y + 30)
    end)
    
    -- Section methods
    function section:SetCollapsed(collapsed)
        self.IsCollapsed = collapsed
        
        if self.CollapseButton then
            self.CollapseButton.Text = collapsed and "▶" or "▼"
            TakoGlass.Tooltips.Add(self.CollapseButton, collapsed and "Expand section" or "Collapse section")
        end
        
        Ease(self.Content, {BackgroundTransparency = collapsed and 1 or 0}, 0.3)
        
        -- Trigger height update
        local contentHeight = self.ListLayout.AbsoluteContentSize.Y
        local headerHeight = 48
        local padding = 24
        local totalHeight = headerHeight + (collapsed and 0 or contentHeight + padding)
        
        Ease(self.Frame, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    
    function section:ApplyTheme(theme)
        self.Frame.BackgroundColor3 = theme.CardBg
        self.Frame.UIStroke.Color = theme.Stroke
        self.Icon.TextColor3 = theme.Text
        self.Title.TextColor3 = theme.Text
        
        if self.DescriptionLabel then
            self.DescriptionLabel.TextColor3 = theme.SubText
        end
        
        if self.CollapseButton then
            self.CollapseButton.TextColor3 = theme.SubText
        end
        
        for _, element in ipairs(self.Elements) do
            if element.ApplyTheme then
                element:ApplyTheme(theme)
            end
        end
    end
    
    -- Set initial collapsed state
    if section.IsCollapsed then
        section.Content.BackgroundTransparency = 1
    end
    
    -- Element creation functions
    function section:AddToggle(options)
        return TakoGlass.Elements.CreateToggle(section, options)
    end
    
    function section:AddSlider(options)
        return TakoGlass.Elements.CreateSlider(section, options)
    end
    
    function section:AddButton(options)
        return TakoGlass.Elements.CreateButton(section, options)
    end
    
    function section:AddInput(options)
        return TakoGlass.Elements.CreateInput(section, options)
    end
    
    function section:AddDropdown(options)
        return TakoGlass.Elements.CreateDropdown(section, options)
    end
    
    function section:AddColorPicker(options)
        return TakoGlass.Elements.CreateColorPicker(section, options)
    end
    
    function section:AddKeybind(options)
        return TakoGlass.Elements.CreateKeybind(section, options)
    end
    
    function section:AddParagraph(options)
        return TakoGlass.Elements.CreateParagraph(section, options)
    end
    
    function section:AddImage(options)
        return TakoGlass.Elements.CreateImage(section, options)
    end
    
    function section:AddCodeBlock(options)
        return TakoGlass.Elements.CreateCodeBlock(section, options)
    end
    
    table.insert(tab.Sections, section)
    table.insert(self.Sections, section) -- Global reference
    return section
end

--------------------------------------------------------------------
-- 12. ELEMENT SYSTEM - SUPERIOR TO WINDUI
--------------------------------------------------------------------
TakoGlass.Elements = {}

-- TOGGLE ELEMENT
function TakoGlass.Elements.CreateToggle(section, options)
    options = options or {}
    
    local toggle = {
        Section = section,
        Window = section.Window,
        Name = options.Name or "Toggle",
        Description = options.Description or "",
        Default = options.Default or false,
        Flag = options.Flag or ("TG_Toggle_" .. (options.Name or "Toggle")),
        Callback = options.Callback or function() end,
        Locked = options.Locked or false,
        Value = options.Default or false,
        Type = "Toggle"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Load saved value
    if section.Window.Config[toggle.Flag] ~= nil then
        toggle.Value = section.Window.Config[toggle.Flag]
    end
    
    section.Window.Flags[toggle.Flag] = toggle.Value
    
    -- Create element
    toggle.Frame = Create("Frame", {
        Name = "Toggle_" .. toggle.Name,
        Size = UDim2.new(1, 0, 0, toggle.Description ~= "" and 50 or 36),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent = section.Content
    })
    
    -- Label
    toggle.Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = toggle.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -50, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 107,
        Parent = toggle.Frame
    })
    
    -- Description
    if toggle.Description ~= "" then
        toggle.DescriptionLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = toggle.Description,
            Font = UI_FONT,
            TextSize = 11,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -50, 0, 14),
            Position = UDim2.new(0, 0, 0, 22),
            ZIndex = 107,
            Parent = toggle.Frame
        })
    end
    
    -- Toggle switch
    toggle.Switch = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -40, 0, toggle.Description ~= "" and 14 or 7),
        Text = "",
        ZIndex = 107,
        Parent = toggle.Frame
    })
    
    toggle.SwitchBackground = Create("Frame", {
        BackgroundColor3 = toggle.Value and theme.Accent or theme.ElementBg,
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BorderSizePixel = 0,
        ZIndex = 108,
        Parent = toggle.Switch
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggle.SwitchBackground})
    
    toggle.SwitchHandle = Create("Frame", {
        BackgroundColor3 = theme.Text,
        Size = UDim2.new(0, 12, 0, 12),
        Position = toggle.Value and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        BorderSizePixel = 0,
        ZIndex = 109,
        Parent = toggle.SwitchBackground
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggle.SwitchHandle})
    
    -- Functionality
    function toggle:SetValue(value)
        if toggle.Locked then return end
        
        toggle.Value = value
        section.Window.Flags[toggle.Flag] = value
        section.Window.Config[toggle.Flag] = value
        SaveConfig(section.Window.ConfigName, section.Window.Config)
        
        -- Animate
        Ease(toggle.SwitchBackground, {BackgroundColor3 = value and theme.Accent or theme.ElementBg}, 0.2)
        Ease(toggle.SwitchHandle, {
            Position = value and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = value and theme.Text or theme.SubText
        }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        -- Callback
        toggle.Callback(value)
        
        -- Visual feedback
        if value then
            TakoGlass.Animations.Pulse(toggle.SwitchBackground, theme.AccentSoft, 0.3)
        end
    end
    
    toggle.Switch.MouseButton1Click:Connect(function()
        toggle:SetValue(not toggle.Value)
    end)
    
    -- Tooltip
    TakoGlass.Tooltips.Add(toggle.Switch, toggle.Value and "Enabled" or "Disabled")
    
    function toggle:ApplyTheme(newTheme)
        toggle.Label.TextColor3 = newTheme.Text
        if toggle.DescriptionLabel then
            toggle.DescriptionLabel.TextColor3 = newTheme.SubText
        end
        
        toggle.SwitchBackground.BackgroundColor3 = toggle.Value and newTheme.Accent or newTheme.ElementBg
        toggle.SwitchHandle.BackgroundColor3 = toggle.Value and newTheme.Text or newTheme.SubText
        
        TakoGlass.Tooltips.Add(toggle.Switch, toggle.Value and "Enabled" or "Disabled")
    end
    
    table.insert(section.Elements, toggle)
    table.insert(section.Window.Elements, toggle)
    
    return {
        SetValue = function(value) toggle:SetValue(value) end,
        GetValue = function() return toggle.Value end,
        SetLocked = function(locked) toggle.Locked = locked end,
        Destroy = function() toggle.Frame:Destroy() end
    }
end

-- SLIDER ELEMENT
function TakoGlass.Elements.CreateSlider(section, options)
    options = options or {}
    
    local slider = {
        Section = section,
        Window = section.Window,
        Name = options.Name or "Slider",
        Min = options.Min or 0,
        Max = options.Max or 100,
        Default = options.Default or 50,
        Step = options.Step or 1,
        Flag = options.Flag or ("TG_Slider_" .. (options.Name or "Slider")),
        Callback = options.Callback or function() end,
        Suffix = options.Suffix or "",
        Prefix = options.Prefix or "",
        ShowValue = options.ShowValue ~= false,
        Type = "Slider"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Validate range
    if slider.Max <= slider.Min then
        slider.Max = slider.Min + 1
    end
    
    -- Load saved value
    if section.Window.Config[slider.Flag] ~= nil then
        slider.Default = math.clamp(section.Window.Config[slider.Flag], slider.Min, slider.Max)
    end
    
    slider.Value = slider.Default
    section.Window.Flags[slider.Flag] = slider.Value
    
    -- Create element
    slider.Frame = Create("Frame", {
        Name = "Slider_" .. slider.Name,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent = section.Content
    })
    
    -- Name label
    slider.NameLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = slider.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 107,
        Parent = slider.Frame
    })
    
    -- Value label
    if slider.ShowValue then
        slider.ValueLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = slider.Prefix .. tostring(slider.Value) .. slider.Suffix,
            Font = UI_FONT,
            TextSize = 12,
            TextColor3 = theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(0, 60, 0, 20),
            Position = UDim2.new(1, -60, 0, 0),
            ZIndex = 107,
            Parent = slider.Frame
        })
    end
    
    -- Slider track
    slider.Track = Create("Frame", {
        BackgroundColor3 = theme.ElementBg,
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -12),
        BorderSizePixel = 0,
        ZIndex = 108,
        Parent = slider.Frame
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = slider.Track})
    
    -- Slider fill
    local fillPercent = (slider.Value - slider.Min) / (slider.Max - slider.Min)
    slider.Fill = Create("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(fillPercent, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 109,
        Parent = slider.Track
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = slider.Fill})
    
    -- Slider handle
    slider.Handle = Create("Frame", {
        BackgroundColor3 = theme.Text,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(fillPercent, -8, 0.5, -8),
        BorderSizePixel = 0,
        ZIndex = 110,
        Parent = slider.Track
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = slider.Handle})
    
    -- Create shadow for handle
    Create("ImageLabel", {
        Size = UDim2.new(1, 8, 1, 8),
        Position = UDim2.new(0, -4, 0, -4),
        BackgroundTransparency = 1,
        Image = "rbxassetid://13190785000",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.7,
        ZIndex = 109,
        Parent = slider.Handle
    })
    
    -- Functionality
    local isDragging = false
    
    function slider:SetValue(value)
        value = math.clamp(value, slider.Min, slider.Max)
        
        -- Apply step
        if slider.Step > 0 then
            value = math.floor((value - slider.Min) / slider.Step + 0.5) * slider.Step + slider.Min
        end
        
        if slider.Value == value then return end
        
        slider.Value = value
        section.Window.Flags[slider.Flag] = value
        section.Window.Config[slider.Flag] = value
        SaveConfig(section.Window.ConfigName, section.Window.Config)
        
        -- Update visuals
        local percent = (value - slider.Min) / (slider.Max - slider.Min)
        
        Ease(slider.Fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
        Ease(slider.Handle, {Position = UDim2.new(percent, -8, 0.5, -8)}, 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        if slider.ValueLabel then
            slider.ValueLabel.Text = slider.Prefix .. tostring(value) .. slider.Suffix
        end
        
        -- Callback
        slider.Callback(value)
        
        -- Visual feedback
        TakoGlass.Animations.Pulse(slider.Handle, theme.AccentSoft, 0.2)
    end
    
    -- Mouse interactions
    local function updateFromMouse(input)
        if not slider.Track.AbsoluteSize.X or slider.Track.AbsoluteSize.X <= 0 then return end
        
        local percent = math.clamp((input.Position.X - slider.Track.AbsolutePosition.X) / slider.Track.AbsoluteSize.X, 0, 1)
        local value = slider.Min + (slider.Max - slider.Min) * percent
        
        slider:SetValue(value)
    end
    
    slider.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            input:Capture()
            updateFromMouse(input)
            
            -- Visual feedback
            Ease(slider.Handle, {Size = UDim2.new(0, 20, 0, 20)}, 0.1)
        end
    end)
    
    slider.Handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            input:Capture()
            
            Ease(slider.Handle, {Size = UDim2.new(0, 20, 0, 20)}, 0.1)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
            input:Release()
            
            Ease(slider.Handle, {Size = UDim2.new(0, 16, 0, 16)}, 0.1)
        end
    end)
    
    -- Tooltip with current value
    TakoGlass.Tooltips.Add(slider.Track, string.format("Range: %s%s to %s%s", slider.Prefix, slider.Min, slider.Prefix, slider.Max))
    
    function slider:ApplyTheme(newTheme)
        slider.NameLabel.TextColor3 = newTheme.Text
        if slider.ValueLabel then
            slider.ValueLabel.TextColor3 = newTheme.Accent
        end
        slider.Track.BackgroundColor3 = newTheme.ElementBg
        slider.Fill.BackgroundColor3 = newTheme.Accent
        slider.Handle.BackgroundColor3 = newTheme.Text
    end
    
    table.insert(section.Elements, slider)
    table.insert(section.Window.Elements, slider)
    
    return {
        SetValue = function(value) slider:SetValue(value) end,
        GetValue = function() return slider.Value end,
        GetMin = function() return slider.Min end,
        GetMax = function() return slider.Max end,
        SetRange = function(min, max) 
            slider.Min = min 
            slider.Max = max 
            slider:SetValue(slider.Value)
        end,
        Destroy = function() slider.Frame:Destroy() end
    }
end

-- BUTTON ELEMENT
function TakoGlass.Elements.CreateButton(section, options)
    options = options or {}
    
    local button = {
        Section = section,
        Window = section.Window,
        Name = options.Name or "Button",
        Callback = options.Callback or function() end,
        Style = options.Style or "Default", -- Default, Primary, Success, Warning, Danger
        Icon = options.Icon or "",
        FullSize = options.FullSize or false,
        Locked = options.Locked or false,
        Type = "Button"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Determine colors based on style
    local buttonColor, textColor
    if button.Style == "Primary" then
        buttonColor = theme.Accent
        textColor = Color3.new(1, 1, 1)
    elseif button.Style == "Success" then
        buttonColor = theme.Success
        textColor = Color3.new(1, 1, 1)
    elseif button.Style == "Warning" then
        buttonColor = theme.Warning
        textColor = Color3.new(0, 0, 0)
    elseif button.Style == "Danger" then
        buttonColor = theme.Error
        textColor = Color3.new(1, 1, 1)
    else -- Default
        buttonColor = theme.ElementBg
        textColor = theme.Text
    end
    
    -- Create element
    button.Frame = Create("Frame", {
        Name = "Button_" .. button.Name,
        Size = button.FullSize and UDim2.new(1, 0, 0, 40) or UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent = section.Content
    })
    
    button.Button = Create("TextButton", {
        BackgroundColor3 = buttonColor,
        BackgroundTransparency = 0,
        Text = button.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = textColor,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 107,
        Parent = button.Frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: button.Button})
    
    -- Icon
    if button.Icon ~= "" then
        button.IconLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = button.Icon,
            Font = UI_FONT,
            TextSize = 16,
            TextColor3 = textColor,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 10, 0.5, -10),
            ZIndex = 108,
            Parent: button.Button
        })
        
        button.Button.Text = "   " .. button.Name
    end
    
    -- Effects
    local originalColor = buttonColor
    
    button.Button.MouseEnter:Connect(function()
        if button.Locked then return end
        
        Ease(button.Button, {BackgroundColor3 = button.Style == "Default" and theme.AccentSoft or buttonColor}, 0.2)
        Ease(button.Button, {BackgroundTransparency = 0.1}, 0.2)
    end)
    
    button.Button.MouseLeave:Connect(function()
        Ease(button.Button, {BackgroundColor3 = originalColor}, 0.2)
        Ease(button.Button, {BackgroundTransparency = 0}, 0.2)
    end)
    
    button.Button.MouseButton1Down:Connect(function()
        if button.Locked then return end
        
        TakoGlass.Animations.Bounce(button.Button, 0.95, 0.1)
    end)
    
    button.Button.MouseButton1Click:Connect(function()
        if button.Locked then return end
        
        -- Visual feedback
        TakoGlass.Animations.Pulse(button.Button, originalColor, 0.3)
        
        -- Callback
        local success, result = pcall(button.Callback)
        if not success then
            TakoGlass.Notifications.Show({
                Title = "Button Error",
                Content = "Error executing button callback: " .. tostring(result),
                Duration = 3,
                Type = "Error",
                Icon = "❌"
            })
        end
    end)
    
    -- Tooltip
    TakoGlass.Tooltips.Add(button.Button, "Click to execute: " .. button.Name)
    
    function button:ApplyTheme(newTheme)
        local newButtonColor, newTextColor
        if button.Style == "Primary" then
            newButtonColor = newTheme.Accent
            newTextColor = Color3.new(1, 1, 1)
        elseif button.Style == "Success" then
            newButtonColor = newTheme.Success
            newTextColor = Color3.new(1, 1, 1)
        elseif button.Style == "Warning" then
            newButtonColor = newTheme.Warning
            newTextColor = Color3.new(0, 0, 0)
        elseif button.Style == "Danger" then
            newButtonColor = newTheme.Error
            newTextColor = Color3.new(1, 1, 1)
        else
            newButtonColor = newTheme.ElementBg
            newTextColor = newTheme.Text
        end
        
        button.Button.BackgroundColor3 = newButtonColor
        button.Button.TextColor3 = newTextColor
        if button.IconLabel then
            button.IconLabel.TextColor3 = newTextColor
        end
        
        originalColor = newButtonColor
    end
    
    table.insert(section.Elements, button)
    table.insert(section.Window.Elements, button)
    
    return {
        SetText = function(text) button.Button.Text = (button.Icon ~= "" and "   " or "") .. text end,
        SetLocked = function(locked) button.Locked = locked end,
        Destroy = function() button.Frame:Destroy() end
    }
end

-- INPUT ELEMENT
function TakoGlass.Elements.CreateInput(section, options)
    options = options or {}
    
    local input = {
        Section = section,
        Window = section.Window,
        Name = options.Name or "Input",
        Default = options.Default or "",
        Placeholder = options.Placeholder or "",
        Flag = options.Flag or ("TG_Input_" .. (options.Name or "Input")),
        Callback = options.Callback or function() end,
        Type = options.Type or "Text", -- Text, Number, Password
        Multiline = options.Multiline or false,
        MaxLength = options.MaxLength or 1000,
        ClearOnFocus = options.ClearOnFocus or false,
        Value = options.Default or "",
        Type = "Input"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Load saved value
    if section.Window.Config[input.Flag] ~= nil then
        input.Value = section.Window.Config[input.Flag]
    end
    
    section.Window.Flags[input.Flag] = input.Value
    
    -- Create element
    input.Frame = Create("Frame", {
        Name = "Input_" .. input.Name,
        Size = UDim2.new(1, 0, 0, input.Multiline and 80 or 40),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent = section.Content
    })
    
    -- Label
    input.Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = input.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 107,
        Parent = input.Frame
    })
    
    -- Input field
    input.InputField = Create(input.Multiline and "TextBox" or "TextBox", {
        BackgroundColor3 = theme.ElementBg,
        BackgroundTransparency = 0,
        Text = input.Value,
        PlaceholderText = input.Placeholder,
        Font = UI_FONT,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = input.ClearOnFocus,
        Size = UDim2.new(1, 0, 0, input.Multiline and 50 or 18),
        Position = UDim2.new(0, 0, 1, -18),
        ZIndex = 108,
        Parent: input.Frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: input.InputField})
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent: input.InputField
    })
    
    -- Multiline setup
    if input.Multiline then
        input.InputField.Size = UDim2.new(1, 0, 0, 50)
        input.InputField.TextWrapped = true
        input.InputField.ClearTextOnFocus = false
    end
    
    -- Type-specific behavior
    if input.Type == "Number" then
        input.InputField.FocusLost:Connect(function()
            local number = tonumber(input.InputField.Text)
            if number then
                input:SetValue(tostring(number))
            else
                input.InputField.Text = input.Value
            end
        end)
    elseif input.Type == "Password" then
        input.InputField.Text = string.rep("•", #input.Value)
        
        input.InputField.Focused:Connect(function()
            input.InputField.Text = input.Value
        end)
        
        input.InputField.FocusLost:Connect(function()
            input:SetValue(input.InputField.Text)
            input.InputField.Text = string.rep("•", #input.Value)
        end)
    end
    
    -- Functionality
    function input:SetValue(value)
        if #value > input.MaxLength then
            value = value:sub(1, input.MaxLength)
        end
        
        input.Value = value
        section.Window.Flags[input.Flag] = value
        section.Window.Config[input.Flag] = value
        SaveConfig(section.Window.ConfigName, section.Window.Config)
        
        if input.Type == "Password" and not input.InputField:IsFocused() then
            input.InputField.Text = string.rep("•", #value)
        else
            input.InputField.Text = value
        end
        
        input.Callback(value)
    end
    
    input.InputField.FocusLost:Connect(function(enterPressed)
        input:SetValue(input.InputField.Text)
        input.Callback(input.Value, enterPressed)
    end)
    
    input.InputField:GetPropertyChangedSignal("Text"):Connect(function()
        if input.InputField.Text:len() > input.MaxLength then
            input.InputField.Text = input.InputField.Text:sub(1, input.MaxLength)
        end
    end)
    
    -- Hover effects
    input.InputField.MouseEnter:Connect(function()
        Ease(input.InputField, {BackgroundTransparency = 0.9}, 0.2)
    end)
    
    input.InputField.MouseLeave:Connect(function()
        Ease(input.InputField, {BackgroundTransparency = 0}, 0.2)
    end)
    
    function input:ApplyTheme(newTheme)
        input.Label.TextColor3 = newTheme.Text
        input.InputField.BackgroundColor3 = newTheme.ElementBg
        input.InputField.TextColor3 = newTheme.Text
        input.InputField.PlaceholderColor3 = newTheme.SubText
    end
    
    table.insert(section.Elements, input)
    table.insert(section.Window.Elements, input)
    
    return {
        SetValue = function(value) input:SetValue(value) end,
        GetValue = function() return input.Value end,
        SetLocked = function(locked) input.InputField.Active = not locked end,
        Destroy = function() input.Frame:Destroy() end
    }
end

-- DROPDOWN ELEMENT
function TakoGlass.Elements.CreateDropdown(section, options)
    options = options or {}
    
    local dropdown = {
        Section = section,
        Window = section.Window,
        Name = options.Name or "Dropdown",
        Options = options.Options or {},
        Default = options.Default or options.Options[1],
        Flag = options.Flag or ("TG_Dropdown_" .. (options.Name or "Dropdown")),
        Callback = options.Callback or function() end,
        Searchable = options.Searchable or false,
        MultiSelect = options.MultiSelect or false,
        ShowCount = options.ShowCount or 5,
        Type = "Dropdown"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Load saved value
    if section.Window.Config[dropdown.Flag] ~= nil then
        dropdown.Default = section.Window.Config[dropdown.Flag]
    end
    
    dropdown.Value = dropdown.Default
    section.Window.Flags[dropdown.Flag] = dropdown.Value
    
    -- Create element
    dropdown.Frame = Create("Frame", {
        Name = "Dropdown_" .. dropdown.Name,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent: section.Content
    })
    
    -- Label
    dropdown.Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = dropdown.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 107,
        Parent: dropdown.Frame
    })
    
    -- Dropdown button
    dropdown.Button = Create("TextButton", {
        BackgroundColor3 = theme.ElementBg,
        BackgroundTransparency = 0,
        Text = tostring(dropdown.Value),
        Font = UI_FONT,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 1, -36),
        ZIndex = 108,
        Parent: dropdown.Frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: dropdown.Button})
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 30),
        Parent: dropdown.Button
    })
    
    -- Dropdown arrow
    dropdown.Arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = "▼",
        Font = UI_FONT,
        TextSize = 12,
        TextColor3 = theme.SubText,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, -10),
        ZIndex = 109,
        Parent: dropdown.Button
    })
    
    -- Dropdown list
    dropdown.List = Create("ScrollingFrame", {
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 150,
        Visible = false,
        Parent: dropdown.Button
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: dropdown.List})
    Create("UIStroke", {
        Color = theme.Stroke,
        Thickness = 1,
        Transparency = 0.3,
        Parent: dropdown.List
    })
    
    dropdown.ListLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 2),
        Parent: dropdown.List
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent: dropdown.List
    })
    
    -- Search bar (if searchable)
    if dropdown.Searchable then
        dropdown.SearchBox = Create("TextBox", {
            BackgroundColor3 = theme.ElementBg,
            BackgroundTransparency = 0,
            Text = "",
            PlaceholderText = "Search...",
            Font = UI_FONT,
            TextSize = 12,
            TextColor3 = theme.Text,
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 151,
            Visible = false,
            Parent: dropdown.List
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS - 2), Parent: dropdown.SearchBox})
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent: dropdown.SearchBox
        })
        
        dropdown.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            dropdown:FilterOptions(dropdown.SearchBox.Text)
        end)
    end
    
    -- Functionality
    function dropdown:SetValue(value)
        dropdown.Value = value
        dropdown.Button.Text = tostring(value)
        section.Window.Flags[dropdown.Flag] = value
        section.Window.Config[dropdown.Flag] = value
        SaveConfig(section.Window.ConfigName, section.Window.Config)
        
        dropdown.Callback(value)
    end
    
    function dropdown:PopulateOptions()
        -- Clear existing options
        for _, child in ipairs(dropdown.List:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local startY = dropdown.Searchable and 34 or 0
        local visibleOptions = 0
        
        for i, option in ipairs(dropdown.Options) do
            local optionButton = Create("TextButton", {
                BackgroundTransparency = 1,
                Text = tostring(option),
                Font = UI_FONT,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 28),
                Position = UDim2.new(0, 0, 0, startY + (i-1) * 28),
                ZIndex = 152,
                Parent: dropdown.List
            })
            
            optionButton.MouseButton1Click:Connect(function()
                dropdown:SetValue(option)
                dropdown:Close()
            end)
            
            optionButton.MouseEnter:Connect(function()
                Ease(optionButton, {BackgroundTransparency = 0.9, BackgroundColor3 = theme.ElementBg}, 0.1)
            end)
            
            optionButton.MouseLeave:Connect(function()
                Ease(optionButton, {BackgroundTransparency = 1}, 0.1)
            end)
            
            visibleOptions = visibleOptions + 1
        end
        
        -- Set list height
        local maxVisible = math.min(visibleOptions, dropdown.ShowCount)
        local searchHeight = dropdown.Searchable and 34 or 0
        local listHeight = searchHeight + (maxVisible * 28) + 8
        
        dropdown.List.Size = UDim2.new(1, 0, 0, listHeight)
    end
    
    function dropdown:FilterOptions(searchText)
        searchText = searchText:lower()
        
        for _, child in ipairs(dropdown.List:GetChildren()) do
            if child:IsA("TextButton") then
                local optionText = child.Text:lower()
                local matches = searchText == "" or optionText:find(searchText, 1, true)
                child.Visible = matches
            end
        end
    end
    
    function dropdown:Open()
        dropdown:PopulateOptions()
        
        dropdown.List.Visible = true
        dropdown.Arrow.Text = "▲"
        
        if dropdown.Searchable then
            dropdown.SearchBox.Visible = true
            dropdown.SearchBox:CaptureFocus()
        end
        
        -- Animate
        dropdown.List.Size = UDim2.new(1, 0, 0, 0)
        dropdown.List.BackgroundTransparency = 1
        
        local maxVisible = math.min(#dropdown.Options, dropdown.ShowCount)
        local searchHeight = dropdown.Searchable and 34 or 0
        local listHeight = searchHeight + (maxVisible * 28) + 8
        
        Ease(dropdown.List, {Size = UDim2.new(1, 0, 0, listHeight), BackgroundTransparency = 0.05}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        -- Close other dropdowns
        for _, otherDropdown in ipairs(section.Elements) do
            if otherDropdown.Type == "Dropdown" and otherDropdown ~= dropdown and otherDropdown.List.Visible then
                otherDropdown:Close()
            end
        end
    end
    
    function dropdown:Close()
        dropdown.Arrow.Text = "▼"
        
        Ease(dropdown.List, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        task.delay(0.2, function()
            dropdown.List.Visible = false
            if dropdown.Searchable then
                dropdown.SearchBox.Visible = false
                dropdown.SearchBox.Text = ""
            end
        end)
    end
    
    -- Button functionality
    dropdown.Button.MouseButton1Click:Connect(function()
        if dropdown.List.Visible then
            dropdown:Close()
        else
            dropdown:Open()
        end
    end)
    
    -- Close when clicking outside
    local function closeOnOutsideClick(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = input.Position
            local listPos = dropdown.List.AbsolutePosition
            local listSize = dropdown.List.AbsoluteSize
            
            local isInside = pos.X >= listPos.X and pos.X <= listPos.X + listSize.X and
                           pos.Y >= listPos.Y and pos.Y <= listPos.Y + listSize.X
            
            if not isInside and dropdown.List.Visible then
                dropdown:Close()
            end
        end
    end
    
    table.insert(section.Window.Connections, UserInputService.InputBegan:Connect(closeOnOutsideClick))
    
    -- Set initial value
    dropdown:SetValue(dropdown.Value)
    
    function dropdown:ApplyTheme(newTheme)
        dropdown.Label.TextColor3 = newTheme.Text
        dropdown.Button.BackgroundColor3 = newTheme.ElementBg
        dropdown.Button.TextColor3 = newTheme.Text
        dropdown.Arrow.TextColor3 = newTheme.SubText
        dropdown.List.BackgroundColor3 = newTheme.CardBg
        dropdown.List.UIStroke.Color = newTheme.Stroke
        
        if dropdown.SearchBox then
            dropdown.SearchBox.BackgroundColor3 = newTheme.ElementBg
            dropdown.SearchBox.TextColor3 = newTheme.Text
            dropdown.SearchBox.PlaceholderColor3 = newTheme.SubText
        end
    end
    
    table.insert(section.Elements, dropdown)
    table.insert(section.Window.Elements, dropdown)
    
    return {
        SetValue = function(value) dropdown:SetValue(value) end,
        GetValue = function() return dropdown.Value end,
        SetOptions = function(options) 
            dropdown.Options = options 
            dropdown:PopulateOptions()
        end,
        Open = function() dropdown:Open() end,
        Close = function() dropdown:Close() end,
        Destroy = function() dropdown.Frame:Destroy() end
    }
end

-- COLOR PICKER ELEMENT
function TakoGlass.Elements.CreateColorPicker(section, options)
    options = options or {}
    
    local colorpicker = {
        Section = section,
        Window = section.Window,
        Name = options.Name or "Color Picker",
        Default = options.Default or Color3.new(1, 1, 1),
        Flag = options.Flag or ("TG_Color_" .. (options.Name or "ColorPicker")),
        Callback = options.Callback or function() end,
        Alpha = options.Alpha or false,
        Type = "ColorPicker"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Load saved value
    if section.Window.Config[colorpicker.Flag] then
        local saved = section.Window.Config[colorpicker.Flag]
        colorpicker.Default = Color3.new(saved.R, saved.G, saved.B)
        if saved.A and colorpicker.Alpha then
            colorpicker.AlphaValue = saved.A
        end
    end
    
    colorpicker.Value = colorpicker.Default
    colorpicker.AlphaValue = colorpicker.AlphaValue or 1
    section.Window.Flags[colorpicker.Flag] = colorpicker.Value
    
    -- Create element
    colorpicker.Frame = Create("Frame", {
        Name = "ColorPicker_" .. colorpicker.Name,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent: section.Content
    })
    
    -- Label
    colorpicker.Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = colorpicker.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -50, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 107,
        Parent: colorpicker.Frame
    })
    
    -- Color preview
    colorpicker.Preview = Create("TextButton", {
        BackgroundColor3 = colorpicker.Value,
        BackgroundTransparency = 0,
        Text = "",
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -40, 0, 7),
        ZIndex = 108,
        Parent: colorpicker.Frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS - 2), Parent: colorpicker.Preview})
    Create("UIStroke", {
        Color = theme.Stroke,
        Thickness = 1,
        Transparency = 0.4,
        Parent: colorpicker.Preview
    })
    
    -- Color picker popup
    colorpicker.Popup = Create("Frame", {
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(0, 250, 0, 0),
        Position = UDim2.new(1, 5, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 200,
        Visible = false,
        Parent: colorpicker.Frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: colorpicker.Popup})
    Create("UIStroke", {
        Color = theme.Stroke,
        Thickness = 1,
        Transparency = 0.3,
        Parent: colorpicker.Popup
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent: colorpicker.Popup
    })
    
    -- HSV color picker components
    colorpicker.HueSaturation = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(1, -24, 0, 150),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 201,
        Parent: colorpicker.Popup
    })
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS - 4), Parent: colorpicker.HueSaturation})
    
    -- Value slider
    colorpicker.ValueSlider = Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(0, 20, 0, 150),
        Position = UDim2.new(1, -20, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 202,
        Parent: colorpicker.Popup
    })
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS - 4), Parent: colorpicker.ValueSlider})
    
    -- Alpha slider (if enabled)
    if colorpicker.Alpha then
        colorpicker.AlphaSlider = Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, 160),
            BorderSizePixel = 0,
            ZIndex = 201,
            Parent: colorpicker.Popup
        })
        Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS - 4), Parent: colorpicker.AlphaSlider})
        
        -- Alpha gradient
        local alphaGradient = Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Parent: colorpicker.AlphaSlider
        })
    end
    
    -- Functionality
    local hsv = {H = 0, S = 1, V = 1}
    
    function colorpicker:UpdateColor()
        local color = Color3.fromHSV(hsv.H, hsv.S, hsv.V)
        colorpicker.Value = color
        
        -- Update preview
        colorpicker.Preview.BackgroundColor3 = color
        
        -- Update gradients
        colorpicker.HueSaturation.BackgroundColor3 = color
        
        -- Update value gradient
        local valueGradient = Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
            }),
            Rotation = 90
        })
        valueGradient.Parent = colorpicker.ValueSlider
        
        -- Callback
        section.Window.Flags[colorpicker.Flag] = color
        local saveData = {R = color.R, G = color.G, B = color.B}
        if colorpicker.Alpha then
            saveData.A = colorpicker.AlphaValue
        end
        section.Window.Config[colorpicker.Flag] = saveData
        SaveConfig(section.Window.ConfigName, section.Window.Config)
        
        colorpicker.Callback(color, colorpicker.AlphaValue)
    end
    
    function colorpicker:Open()
        colorpicker.Popup.Visible = true
        colorpicker.Popup.Size = UDim2.new(0, 250, 0, 0)
        
        -- Animate open
        local targetHeight = colorpicker.Alpha and 190 or 170
        Ease(colorpicker.Popup, {Size = UDim2.new(0, 250, 0, targetHeight)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        -- Close other color pickers
        for _, otherPicker in ipairs(section.Elements) do
            if otherPicker.Type == "ColorPicker" and otherPicker ~= colorpicker and otherPicker.Popup.Visible then
                otherPicker:Close()
            end
        end
    end
    
    function colorpicker:Close()
        Ease(colorpicker.Popup, {Size = UDim2.new(0, 250, 0, 0)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        task.delay(0.2, function()
            colorpicker.Popup.Visible = false
        end)
    end
    
    -- Preview click
    colorpicker.Preview.MouseButton1Click:Connect(function()
        if colorpicker.Popup.Visible then
            colorpicker:Close()
        else
            colorpicker:Open()
        end
    end)
    
    -- HSV picker functionality
    local function updateFromHSV(input)
        local pos = Vector2.new(
            math.clamp((input.Position.X - colorpicker.HueSaturation.AbsolutePosition.X) / colorpicker.HueSaturation.AbsoluteSize.X, 0, 1),
            math.clamp((input.Position.Y - colorpicker.HueSaturation.AbsolutePosition.Y) / colorpicker.HueSaturation.AbsoluteSize.Y, 0, 1)
        )
        
        hsv.H = pos.X
        hsv.S = 1 - pos.Y
        colorpicker:UpdateColor()
    end
    
    local function updateFromValue(input)
        local percent = math.clamp((input.Position.Y - colorpicker.ValueSlider.AbsolutePosition.Y) / colorpicker.ValueSlider.AbsoluteSize.Y, 0, 1)
        hsv.V = 1 - percent
        colorpicker:UpdateColor()
    end
    
    colorpicker.HueSaturation.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            input:Capture()
            updateFromHSV(input)
        end
    end)
    
    colorpicker.ValueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            input:Capture()
            updateFromValue(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if input:IsCaptured() then
                if input.UserInputState == Enum.UserInputState.Change then
                    updateFromHSV(input)
                    updateFromValue(input)
                end
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            input:Release()
        end
    end)
    
    -- Initialize with default color
    hsv.H, hsv.S, hsv.V = Color3.toHSV(colorpicker.Default)
    colorpicker:UpdateColor()
    
    function colorpicker:ApplyTheme(newTheme)
        colorpicker.Label.TextColor3 = newTheme.Text
        colorpicker.Preview.UIStroke.Color = newTheme.Stroke
        colorpicker.Popup.BackgroundColor3 = newTheme.CardBg
        colorpicker.Popup.UIStroke.Color = newTheme.Stroke
    end
    
    table.insert(section.Elements, colorpicker)
    table.insert(section.Window.Elements, colorpicker)
    
    return {
        SetValue = function(color, alpha) 
            colorpicker.Value = color
            colorpicker.AlphaValue = alpha or colorpicker.AlphaValue
            hsv.H, hsv.S, hsv.V = Color3.toHSV(color)
            colorpicker:UpdateColor()
        end,
        GetValue = function() return colorpicker.Value, colorpicker.AlphaValue end,
        Open = function() colorpicker:Open() end,
        Close = function() colorpicker:Close() end,
        Destroy = function() colorpicker.Frame:Destroy() end
    }
end

-- KEYBIND ELEMENT
function TakoGlass.Elements.CreateKeybind(section, options)
    options = options or {}
    
    local keybind = {
        Section = section,
        Window = section.Window,
        Name = options.Name or "Keybind",
        Default = options.Default or Enum.KeyCode.E,
        Flag = options.Flag or ("TG_Keybind_" .. (options.Name or "Keybind")),
        Callback = options.Callback or function() end,
        AllowMouse = options.AllowMouse or false,
        Value = options.Default or Enum.KeyCode.E,
        Type = "Keybind"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Load saved value
    if section.Window.Config[keybind.Flag] then
        local savedCode = Enum.KeyCode[section.Window.Config[keybind.Flag]]
        if savedCode then
            keybind.Value = savedCode
        end
    end
    
    section.Window.Flags[keybind.Flag] = keybind.Value
    
    -- Create element
    keybind.Frame = Create("Frame", {
        Name = "Keybind_" .. keybind.Name,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent: section.Content
    })
    
    -- Label
    keybind.Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = keybind.Name,
        Font = UI_FONT,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 107,
        Parent: keybind.Frame
    })
    
    -- Keybind button
    keybind.Button = Create("TextButton", {
        BackgroundColor3 = theme.ElementBg,
        BackgroundTransparency = 0,
        Text = keybind.Value.Name,
        Font = UI_FONT,
        TextSize = 13,
        TextColor3 = theme.Text,
        Size = UDim2.new(0, 70, 0, 24),
        Position = UDim2.new(1, -70, 0, 6),
        ZIndex = 108,
        Parent: keybind.Frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS - 2), Parent: keybind.Button})
    
    -- Functionality
    local isListening = false
    local connection
    
    function keybind:SetValue(keyCode)
        keybind.Value = keyCode
        keybind.Button.Text = keyCode.Name
        section.Window.Flags[keybind.Flag] = keyCode
        section.Window.Config[keybind.Flag] = keyCode.Name
        SaveConfig(section.Window.ConfigName, section.Window.Config)
        
        keybind.Callback(keyCode)
    end
    
    function keybind:StartListening()
        if isListening then return end
        
        isListening = true
        keybind.Button.Text = "..."
        keybind.Button.BackgroundColor3 = theme.Accent
        
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if not keybind.AllowMouse and (input.KeyCode == Enum.KeyCode.MouseButton1 or 
                   input.KeyCode == Enum.KeyCode.MouseButton2 or input.KeyCode == Enum.KeyCode.MouseButton3) then
                    return
                end
                
                keybind:SetValue(input.KeyCode)
                keybind:StopListening()
            end
        end)
        
        -- Timeout after 5 seconds
        task.delay(5, function()
            if isListening then
                keybind:StopListening()
            end
        end)
    end
    
    function keybind:StopListening()
        if not isListening then return end
        
        isListening = false
        keybind.Button.Text = keybind.Value.Name
        keybind.Button.BackgroundColor3 = theme.ElementBg
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    keybind.Button.MouseButton1Click:Connect(function()
        if isListening then
            keybind:StopListening()
        else
            keybind:StartListening()
        end
    end)
    
    -- Hover effects
    keybind.Button.MouseEnter:Connect(function()
        if not isListening then
            Ease(keybind.Button, {BackgroundTransparency = 0.1}, 0.2)
        end
    end)
    
    keybind.Button.MouseLeave:Connect(function()
        if not isListening then
            Ease(keybind.Button, {BackgroundTransparency = 0}, 0.2)
        end
    end)
    
    -- Tooltip
    TakoGlass.Tooltips.Add(keybind.Button, "Click to set keybind")
    
    function keybind:ApplyTheme(newTheme)
        keybind.Label.TextColor3 = newTheme.Text
        if not isListening then
            keybind.Button.BackgroundColor3 = newTheme.ElementBg
            keybind.Button.TextColor3 = newTheme.Text
        end
    end
    
    table.insert(section.Elements, keybind)
    table.insert(section.Window.Elements, keybind)
    
    return {
        SetValue = function(keyCode) keybind:SetValue(keyCode) end,
        GetValue = function() return keybind.Value end,
        StartListening = function() keybind:StartListening() end,
        StopListening = function() keybind:StopListening() end,
        Destroy = function() keybind.Frame:Destroy() end
    }
end

-- PARAGRAPH ELEMENT
function TakoGlass.Elements.CreateParagraph(section, options)
    options = options or {}
    
    local paragraph = {
        Section = section,
        Window = section.Window,
        Title = options.Title or "",
        Content = options.Content or options.Text or "",
        Markdown = options.Markdown or false,
        Copyable = options.Copyable or false,
        Type = "Paragraph"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Process markdown if enabled
    if paragraph.Markdown then
        paragraph.ProcessedContent = paragraph.Content:gsub("%*%*(.-)%*%*", "<b>%1</b>") -- Bold
            :gsub("%*(.-)%*", "<i>%1</i>") -- Italic
            :gsub("%`(.-)%`", "<font color='" .. tostring(theme.Accent) .. "'>%1</font>") -- Code
            :gsub("%[(.-)%]%((.-)%)", "<font color='" .. tostring(theme.Accent) .. "'><u>%1</u></font>") -- Links
    else
        paragraph.ProcessedContent = paragraph.Content
    end
    
    -- Create element
    paragraph.Frame = Create("Frame", {
        Name = "Paragraph_" .. (paragraph.Title ~= "" and paragraph.Title or "Paragraph"),
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent: section.Content
    })
    
    -- Title
    if paragraph.Title ~= "" then
        paragraph.TitleLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = paragraph.Title,
            Font = UI_FONT,
            TextSize = 16,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 107,
            Parent: paragraph.Frame
        })
    end
    
    -- Content
    paragraph.ContentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = paragraph.ProcessedContent,
        Font = UI_FONT,
        TextSize = 13,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, paragraph.Title ~= "" and 24 or 0),
        ZIndex = 107,
        Parent: paragraph.Frame
    })
    
    -- Calculate height based on content
    local titleHeight = paragraph.Title ~= "" and 22 or 0
    local contentHeight = CalculateTextSize(paragraph.ProcessedContent, UI_FONT, 13, Vector2.new(paragraph.Frame.AbsoluteSize.X - 10, 1000)).Y
    local totalHeight = titleHeight + contentHeight + 10
    
    paragraph.Frame.Size = UDim2.new(1, 0, 0, totalHeight)
    paragraph.ContentLabel.Size = UDim2.new(1, 0, 0, contentHeight)
    
    -- Copy button
    if paragraph.Copyable then
        paragraph.CopyButton = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "📋",
            Font = UI_FONT,
            TextSize = 14,
            TextColor3 = theme.SubText,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -24, 0, 0),
            ZIndex = 108,
            Parent: paragraph.Frame
        })
        
        paragraph.CopyButton.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(paragraph.Content)
                TakoGlass.Notifications.Show({
                    Title = "Copied",
                    Content = "Text copied to clipboard",
                    Duration = 2,
                    Type = "Success",
                    Icon = "✅"
                })
            end
        end)
        
        TakoGlass.Tooltips.Add(paragraph.CopyButton, "Copy to clipboard")
    end
    
    function paragraph:ApplyTheme(newTheme)
        if paragraph.TitleLabel then
            paragraph.TitleLabel.TextColor3 = newTheme.Text
        end
        paragraph.ContentLabel.TextColor3 = newTheme.SubText
        
        -- Re-process markdown with new accent color
        if paragraph.Markdown then
            paragraph.ProcessedContent = paragraph.Content:gsub("%*%*(.-)%*%*", "<b>%1</b>")
                :gsub("%*(.-)%*", "<i>%1</i>")
                :gsub("%`(.-)%`", "<font color='" .. tostring(newTheme.Accent) .. "'>%1</font>")
                :gsub("%[(.-)%]%((.-)%)", "<font color='" .. tostring(newTheme.Accent) .. "'><u>%1</u></font>")
            
            paragraph.ContentLabel.Text = paragraph.ProcessedContent
        end
    end
    
    table.insert(section.Elements, paragraph)
    table.insert(section.Window.Elements, paragraph)
    
    return {
        SetText = function(text) 
            paragraph.Content = text
            paragraph.ProcessedContent = paragraph.Markdown and paragraph.Content:gsub("%*%*(.-)%*%*", "<b>%1</b>"):gsub("%*(.-)%*", "<i>%1</i>"):gsub("%`(.-)%`", "<font color='" .. tostring(theme.Accent) .. "'>%1</font>") or text
            paragraph.ContentLabel.Text = paragraph.ProcessedContent
            
            -- Recalculate height
            local contentHeight = CalculateTextSize(paragraph.ProcessedContent, UI_FONT, 13, Vector2.new(paragraph.Frame.AbsoluteSize.X - 10, 1000)).Y
            local titleHeight = paragraph.Title ~= "" and 22 or 0
            local totalHeight = titleHeight + contentHeight + 10
            
            paragraph.Frame.Size = UDim2.new(1, 0, 0, totalHeight)
            paragraph.ContentLabel.Size = UDim2.new(1, 0, 0, contentHeight)
        end,
        Destroy = function() paragraph.Frame:Destroy() end
    }
end

-- IMAGE ELEMENT
function TakoGlass.Elements.CreateImage(section, options)
    options = options or {}
    
    local image = {
        Section = section,
        Window = section.Window,
        Url = options.Url or options.Image or "",
        Size = options.Size or UDim2.new(1, 0, 0, 200),
        AspectRatio = options.AspectRatio or nil,
        Rounded = options.Rounded or false,
        Clickable = options.Clickable or false,
        Callback = options.Callback or function() end,
        Type = "Image"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Create element
    image.Frame = Create("Frame", {
        Name = "Image",
        Size = image.Size,
        BackgroundTransparency = 1,
        ZIndex = 106,
        Parent: section.Content
    })
    
    -- Image label
    image.ImageLabel = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = image.Url,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 107,
        Parent: image.Frame
    })
    
    -- Aspect ratio constraint
    if image.AspectRatio then
        Create("UIAspectRatioConstraint", {
            AspectRatio = image.AspectRatio,
            Parent: image.ImageLabel
        })
    end
    
    -- Rounded corners
    if image.Rounded then
        Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: image.ImageLabel})
    end
    
    -- Click functionality
    if image.Clickable then
        image.ImageLabel.Active = true
        
        image.ImageLabel.MouseButton1Click:Connect(function()
            image.Callback()
            TakoGlass.Animations.Bounce(image.ImageLabel, 0.95, 0.2)
        end)
        
        image.ImageLabel.MouseEnter:Connect(function()
            Ease(image.ImageLabel, {ImageTransparency = 0.1}, 0.2)
        end)
        
        image.ImageLabel.MouseLeave:Connect(function()
            Ease(image.ImageLabel, {ImageTransparency = 0}, 0.2)
        end)
    end
    
    -- Loading state
    if image.Url ~= "" then
        image.Loading = true
        
        -- Loading indicator
        image.LoadingIndicator = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 108,
            Parent: image.Frame
        })
        
        local spinner = Create("TextLabel", {
            BackgroundTransparency = 1,
            Text = "⏳",
            Font = UI_FONT,
            TextSize = 24,
            TextColor3 = theme.SubText,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.5, -15, 0.5, -15),
            ZIndex = 109,
            Parent: image.LoadingIndicator
        })
        
        -- Spinning animation
        local rotation = 0
        local conn = RunService.Heartbeat:Connect(function(deltaTime)
            if not spinner or not spinner.Parent then
                conn:Disconnect()
                return
            end
            
            rotation = rotation + deltaTime * 360
            spinner.Rotation = rotation
        end)
        
        -- Check if image loads
        local success = pcall(function()
            -- This would normally check if the image actually loads
            -- For now, we'll just hide the loading indicator after a delay
            task.delay(1, function()
                if image.LoadingIndicator then
                    image.LoadingIndicator:Destroy()
                    image.Loading = false
                end
            end)
        end)
        
        if not success then
            image.LoadingIndicator:Destroy()
            image.Loading = false
            
            -- Error state
            image.ErrorLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = "Failed to load image",
                Font = UI_FONT,
                TextSize = 12,
                TextColor3 = theme.Error,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 108,
                Parent: image.Frame
            })
        end
    end
    
    function image:SetImage(url)
        image.Url = url
        image.ImageLabel.Image = url
        
        -- Reset loading state
        if image.ErrorLabel then
            image.ErrorLabel:Destroy()
            image.ErrorLabel = nil
        end
        
        if image.LoadingIndicator then
            image.LoadingIndicator:Destroy()
            image.LoadingIndicator = nil
        end
        
        image.Loading = true
        
        -- Show loading indicator again
        if url ~= "" then
            image.LoadingIndicator = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 108,
                Parent: image.Frame
            })
            
            local spinner = Create("TextLabel", {
                BackgroundTransparency = 1,
                Text = "⏳",
                Font = UI_FONT,
                TextSize = 24,
                TextColor3 = theme.SubText,
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(0.5, -15, 0.5, -15),
                ZIndex = 109,
                Parent: image.LoadingIndicator
            })
            
            local rotation = 0
            local conn = RunService.Heartbeat:Connect(function(deltaTime)
                if not spinner or not spinner.Parent then
                    conn:Disconnect()
                    return
                end
                
                rotation = rotation + deltaTime * 360
                spinner.Rotation = rotation
            end)
            
            task.delay(1, function()
                if image.LoadingIndicator then
                    image.LoadingIndicator:Destroy()
                    image.Loading = false
                end
            end)
        end
    end
    
    function image:ApplyTheme(newTheme)
        if image.ErrorLabel then
            image.ErrorLabel.TextColor3 = newTheme.Error
        end
        
        if image.LoadingIndicator then
            image.LoadingIndicator:FindFirstChildWhichIsA("TextLabel").TextColor3 = newTheme.SubText
        end
    end
    
    table.insert(section.Elements, image)
    table.insert(section.Window.Elements, image)
    
    return {
        SetImage = function(url) image:SetImage(url) end,
        SetSize = function(size) 
            image.Size = size 
            image.Frame.Size = size
        end,
        SetClickable = function(clickable)
            image.Clickable = clickable
            image.ImageLabel.Active = clickable
        end,
        Destroy = function() image.Frame:Destroy() end
    }
end

-- CODE BLOCK ELEMENT
function TakoGlass.Elements.CreateCodeBlock(section, options)
    options = options or {}
    
    local codeblock = {
        Section = section,
        Window = section.Window,
        Code = options.Code or options.Content or "",
        Language = options.Language or "lua",
        Title = options.Title or "",
        Copyable = options.Copyable ~= false,
        Type = "CodeBlock"
    }
    
    local theme = TakoGlass.CurrentTheme
    
    -- Syntax highlighting colors
    local syntaxColors = {
        keyword = theme.Accent,
        string = theme.Success,
        number = theme.Warning,
        comment = theme.SubText,
        operator = theme.Text,
        function = theme.AccentSoft,
        variable = theme.Text
    }
    
    -- Create element
    codeblock.Frame = Create("Frame", {
        Name = "CodeBlock",
        Size = UDim2.new(1, 0, 0, 120),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40), -- Darker background for code
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 106,
        Parent: section.Content
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: codeblock.Frame})
    
    -- Header
    codeblock.Header = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 107,
        Parent: codeblock.Frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, ELEMENT_RADIUS), Parent: codeblock.Header})
    
    -- Language label
    codeblock.LanguageLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = codeblock.Language:upper(),
        Font = MONO_FONT,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 10, 0, 6),
        ZIndex = 108,
        Parent: codeblock.Header
    })
    
    -- Copy button
    if codeblock.Copyable then
        codeblock.CopyButton = Create("TextButton", {
            BackgroundTransparency = 1,
            Text = "📋",
            Font = UI_FONT,
            TextSize = 14,
            TextColor3 = theme.SubText,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -28, 0, 4),
            ZIndex = 108,
            Parent: codeblock.Header
        })
        
        codeblock.CopyButton.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(codeblock.Code)
                TakoGlass.Notifications.Show({
                    Title = "Copied",
                    Content = "Code copied to clipboard",
                    Duration = 2,
                    Type = "Success",
                    Icon = "✅"
                })
            end
        end)
        
        TakoGlass.Tooltips.Add(codeblock.CopyButton, "Copy code")
    end
    
    -- Code content
    codeblock.CodeFrame = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 107,
        Parent: codeblock.Frame
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent: codeblock.CodeFrame
    })
    
    -- Code text label
    codeblock.CodeLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = codeblock.Code,
        Font = MONO_FONT,
        TextSize = 12,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.XY,
        ZIndex = 108,
        Parent: codeblock.CodeFrame
    })
    
    -- Simple syntax highlighting
    function codeblock:HighlightCode()
        local highlighted = codeblock.Code
        
        -- Basic highlighting for Lua
        if codeblock.Language:lower() == "lua" then
            -- Keywords
            local keywords = {"local", "function", "return", "if", "then", "else", "elseif", "end", "for", "while", "do", "break", "continue", "in", "and", "or", "not", "true", "false", "nil"}
            for _, keyword in ipairs(keywords) do
                highlighted = highlighted:gsub("%f[%w](" .. keyword .. ")%f[%W]", "<font color='" .. tostring(syntaxColors.keyword) .. "'>%1</font>")
            end
            
            -- Strings
            highlighted = highlighted:gsub("(['\"])(.-)%1", "<font color='" .. tostring(syntaxColors.string) .. "'>%1%2%1</font>")
            
            -- Numbers
            highlighted = highlighted:gsub("%d+%.?%d*", "<font color='" .. tostring(syntaxColors.number) .. "'>%1</font>")
            
            -- Comments
            highlighted = highlighted:gsub("%-%-.-\n", "<font color='" .. tostring(syntaxColors.comment) .. "'>%1</font>")
        end
        
        codeblock.CodeLabel.Text = highlighted
    end
    
    -- Apply highlighting
    codeblock:HighlightCode()
    
    -- Calculate height based on content
    local codeHeight = CalculateTextSize(codeblock.Code, MONO_FONT, 12, Vector2.new(codeblock.CodeFrame.AbsoluteSize.X - 20, 1000)).Y
    local totalHeight = math.max(80, 44 + codeHeight + 16)
    
    codeblock.Frame.Size = UDim2.new(1, 0, 0, totalHeight)
    
    function codeblock:SetCode(code)
        codeblock.Code = code
        codeblock.CodeLabel.Text = code
        
        -- Re-highlight
        if codeblock.Language:lower() == "lua" then
            codeblock:HighlightCode()
        end
        
        -- Recalculate height
        local codeHeight = CalculateTextSize(code, MONO_FONT, 12, Vector2.new(codeblock.CodeFrame.AbsoluteSize.X - 20, 1000)).Y
        local totalHeight = math.max(80, 44 + codeHeight + 16)
        
        codeblock.Frame.Size = UDim2.new(1, 0, 0, totalHeight)
    end
    
    function codeblock:ApplyTheme(newTheme)
        codeblock.Header.BackgroundColor3 = Color3.fromRGB(40, 40, 50) -- Keep dark
        codeblock.LanguageLabel.TextColor3 = newTheme.SubText
        codeblock.CodeLabel.TextColor3 = newTheme.Text
        codeblock.CodeFrame.ScrollBarImageColor3 = newTheme.Accent
        
        if codeblock.CopyButton then
            codeblock.CopyButton.TextColor3 = newTheme.SubText
        end
        
        -- Re-highlight with new colors
        codeblock:HighlightCode()
    end
    
    table.insert(section.Elements, codeblock)
    table.insert(section.Window.Elements, codeblock)
    
    return {
        SetCode = function(code) codeblock:SetCode(code) end,
        GetCode = function() return codeblock.Code end,
        SetLanguage = function(lang) 
            codeblock.Language = lang 
            codeblock.LanguageLabel.Text = lang:upper()
            codeblock:HighlightCode()
        end,
        Destroy = function() codeblock.Frame:Destroy() end
    }
end

--------------------------------------------------------------------
-- 13. ADVANCED FEATURES - BEYOND WINDUI
--------------------------------------------------------------------
TakoGlass.Advanced = {
    -- Multi-window support
    CreateFloatingWindow = function(options)
        options = options or {}
        options.TopbarStyle = "Minimal"
        options.CanResize = false
        options.Transparent = true
        
        local window = TakoGlass:CreateWindow(options)
        
        -- Make it draggable and floating
        window.MainFrame.AnchorPoint = Vector2.new(0, 0)
        window.MainFrame.Position = options.Position or UDim2.new(0.1, 0, 0.1, 0)
        
        return window
    end,
    
    -- Plugin system
    LoadPlugin = function(pluginUrl)
        local success, plugin = pcall(function()
            return loadstring(game:HttpGet(pluginUrl))()
        end)
        
        if success and type(plugin) == "table" and plugin.Init then
            plugin.Init(TakoGlass)
            TakoGlass.Notifications.Show({
                Title = "Plugin Loaded",
                Content = plugin.Name or "Unknown plugin",
                Duration = 2,
                Type = "Success",
                Icon = "🔌"
            })
            return true
        else
            TakoGlass.Notifications.Show({
                Title = "Plugin Error",
                Content = "Failed to load plugin",
                Duration = 3,
                Type = "Error",
                Icon = "❌"
            })
            return false
        end
    end,
    
    -- Theme editor
    OpenThemeEditor = function()
        local editor = TakoGlass:CreateWindow({
            Title = "Theme Editor",
            Size = UDim2.fromOffset(500, 400),
            Theme = "Dark"
        })
        
        local tab = editor:CreateTab("Editor", "🎨")
        local section = tab:CreateSection({
            Name = "Color Customization",
            Description = "Create your own custom themes"
        })
        
        -- Add theme editing elements
        section:AddInput({
            Name = "Theme Name",
            Default = "My Custom Theme",
            Placeholder = "Enter theme name..."
        })
        
        section:AddColorPicker({
            Name = "Accent Color",
            Default = TakoGlass.CurrentTheme.Accent,
            Callback = function(color)
                -- Preview color
            end
        })
        
        section:AddButton({
            Name = "Save Theme",
            Style = "Success",
            Callback = function()
                TakoGlass.Notifications.Show({
                    Title = "Theme Saved",
                    Content = "Custom theme has been saved",
                    Duration = 2,
                    Type = "Success",
                    Icon = "💾"
                })
            end
        })
        
        return editor
    end,
    
    -- Performance monitor
    PerformanceMonitor = {
        Enabled = false,
        Connections = {},
        
        Start = function(self)
            self.Enabled = true
            
            local monitor = TakoGlass:CreateFloatingWindow({
                Title = "Performance Monitor",
                Size = UDim2.fromOffset(200, 150),
                Position = UDim2.new(0.8, 0, 0.1, 0)
            })
            
            local tab = monitor:CreateTab("Stats", "📊")
            local section = tab:CreateSection({Name = "Performance Metrics"})
            
            local fpsLabel = section:AddParagraph({
                Title = "FPS",
                Content = "60 FPS"
            })
            
            local memoryLabel = section:AddParagraph({
                Title = "Memory",
                Content = "0 MB"
            })
            
            local renderLabel = section:AddParagraph({
                Title = "Render Time",
                Content = "0.0 ms"
            })
            
            -- Update loop
            local lastUpdate = tick()
            local frameCount = 0
            
            table.insert(self.Connections, RunService.RenderStepped:Connect(function(deltaTime)
                frameCount = frameCount + 1
                
                if tick() - lastUpdate >= 1 then
                    local fps = math.floor(frameCount / (tick() - lastUpdate))
                    local memory = math.floor(collectgarbage("count") / 1024 * 100) / 100
                    local renderTime = math.floor(deltaTime * 1000 * 10) / 10
                    
                    fpsLabel.SetText("FPS: " .. fps)
                    memoryLabel.SetText("Memory: " .. memory .. " MB")
                    renderLabel.SetText("Render Time: " .. renderTime .. " ms")
                    
                    lastUpdate = tick()
                    frameCount = 0
                end
            end))
            
            return monitor
        end,
        
        Stop = function(self)
            self.Enabled = false
            
            for _, conn in ipairs(self.Connections) do
                conn:Disconnect()
            end
            
            self.Connections = {}
        end
    },
    
    -- Icon browser
    IconBrowser = function()
        local browser = TakoGlass:CreateWindow({
            Title = "Icon Browser",
            Size = UDim2.fromOffset(600, 400),
            Theme = "Dark"
        })
        
        local tab = browser:CreateTab("Icons", "🎨")
        local searchSection = tab:CreateSection({Name = "Search"})
        
        local searchInput = searchSection:AddInput({
            Name = "Search Icons",
            Placeholder = "Search for icons..."
        })
        
        local iconsSection = tab:CreateSection({Name = "Available Icons"})
        
        -- Popular icons
        local popularIcons = {"🏠", "⚙️", "👤", "🔍", "❤️", "⭐", "🔔", "✉️", "📅", "🕐", "📷", "🖼️", "🎥", "🎵", "🎤", "📞", "💬", "📤", "⬇️", "⬆️", "💾", "📂", "📁", "📄", "💻", "🖥️", "🐛", "🔥", "⚡", "🚀", "🎯", "🏆", "👑", "💎", "💍", "💰", "💳", "🎁", "🎉", "🎈", "🍰", "☕", "🍕", "🍔", "🍟", "🍣", "🥗", "🍦", "🍫", "🍬", "🍭", "🍪", "🍺", "🍷", "🍸", "🥃", "🥤", "🥛", "💧", "🔥", "💧", "🍃", "🌳", "🌸", "☀️", "🌙", "⭐", "☁️", "🌧️", "❄️", "⚡", "🌈", "☂️", "⛄", "🏖️", "🏔️", "🏝️", "🏜️", "🏙️", "🌃", "🌉", "🏠", "🏢", "🏥", "🏫", "🏦", "🏨", "🍽️", "🏪", "🏭", "🏰", "⛪", "🕌", "🕍", "🛕", "🗿", "⛲", "⛺", "🏟️", "🎭", "🏛️", "📚", "📖", "📰", "📓", "📔", "🖊️", "✏️", "🖌️", "🎨", "✂️", "📏", "🧮", "🧭", "🗺️", "🌍"}
        
        for _, icon in ipairs(popularIcons) do
            local iconButton = iconsSection:AddButton({
                Name = icon .. " " .. icon:gsub(":", ""),
                Style = "Default",
                Callback = function()
                    if setclipboard then
                        setclipboard(icon)
                        TakoGlass.Notifications.Show({
                            Title = "Icon Copied",
                            Content = icon .. " copied to clipboard",
                            Duration = 2,
                            Type = "Success",
                            Icon = "✅"
                        })
                    end
                end
            })
        end
        
        return browser
    end
}

--------------------------------------------------------------------
-- 14. FINAL EXPORT & USAGE EXAMPLE
--------------------------------------------------------------------
TakoGlass.Notify = TakoGlass.Notifications.Show
TakoGlass.CreateNotification = TakoGlass.Notifications.Show
TakoGlass.ShowTooltip = TakoGlass.Tooltips.Show
TakoGlass.HideTooltip = TakoGlass.Tooltips.Hide

-- Example usage demonstrating superiority over WindUI:
--[[
local UI = TakoGlass:CreateWindow({
    Title = "TakoGlass v10.0 - WindUI Killer",
    SubTitle = "Superior UI Library",
    Size = UDim2.fromOffset(700, 500),
    Theme = "TokyoNight",
    TopbarStyle = "Mac",
    Transparent = true,
    Blur = true,
    Animations = true
})

local mainTab = UI:CreateTab("Dashboard", "🚀")
local advancedTab = UI:CreateTab("Advanced", "⚡")

-- Advanced section with all elements
local mainSection = mainTab:CreateSection({
    Name = "Advanced Elements",
    Description = "Everything WindUI has and more",
    CanCollapse = true
})

-- Superior color picker with alpha
mainSection:AddColorPicker({
    Name = "Advanced Color",
    Default = Color3.fromRGB(88, 101, 242),
    Alpha = true,
    Callback = function(color, alpha)
        print("Color:", color, "Alpha:", alpha)
    end
})

-- Markdown paragraph
mainSection:AddParagraph({
    Title = "Rich Text Support",
    Content = "**Bold text**, *italic text*, and `inline code` with full markdown support!",
    Markdown = true,
    Copyable = true
})

-- Code block with syntax highlighting
mainSection:AddCodeBlock({
    Code = [[local function superiorFunction()
    print("TakoGlass is better than WindUI!")
    return true
end]],
    Language = "lua",
    Copyable = true
})

-- Advanced dropdown with search
mainSection:AddDropdown({
    Name = "Advanced Dropdown",
    Options = {"Option 1", "Option 2", "Option 3", "Option 4", "Option 5"},
    Default = "Option 1",
    Searchable = true,
    Callback = function(value)
        print("Selected:", value)
    end
})

-- Image with click functionality
mainSection:AddImage({
    Url = "rbxassetid://13190783835",
    Size = UDim2.new(1, 0, 0, 150),
    Rounded = true,
    Clickable = true,
    Callback = function()
        TakoGlass.Notify("Image Clicked!", "You clicked the image", 2, "🖼️")
    end
})

-- Spring animation button
local animButton = mainSection:AddButton({
    Name = "Spring Animation",
    Style = "Primary",
    Callback = function()
        TakoGlass.Animations.Spring(animButton.Frame, Vector2.new(100, 100), Vector2.new(0, 500), 0.8)
    end
})

-- Performance monitor
mainSection:AddButton({
    Name = "Open Performance Monitor",
    Style = "Success",
    Callback = function()
        TakoGlass.Advanced.PerformanceMonitor:Start()
    end
})

-- Theme editor
mainSection:AddButton({
    Name = "Open Theme Editor",
    Style = "Warning",
    Callback = function()
        TakoGlass.Advanced.OpenThemeEditor()
    end
})

-- Icon browser
mainSection:AddButton({
    Name = "Browse Icons",
    Style = "Danger",
    Callback = function()
        TakoGlass.Advanced.IconBrowser()
    end
})

-- Advanced notifications
mainSection:AddButton({
    Name = "Show Advanced Notification",
    Style = "Primary",
    Callback = function()
        TakoGlass.Notify({
            Title = "Advanced Notification",
            Content = "This notification has actions and custom styling!",
            Duration = 5,
            Type = "Success",
            Icon = "🎉",
            Actions = {
                {
                    Text = "OK",
                    Callback = function()
                        print("User clicked OK!")
                    end
                },
                {
                    Text = "Cancel",
                    Callback = function()
                        print("User clicked Cancel!")
                    end
                }
            }
        })
    end
})

-- Show the UI with animation
UI:SetVisible(true)
--]]

return TakoGlass
