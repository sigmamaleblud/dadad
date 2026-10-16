-- ============================================================
-- PRIV9.NET | PRISON LIFE EDITION
-- ============================================================
-- Сделано на базе priv9 UI + Silent Aim + Chams
-- ============================================================

if getgenv().priv9_loaded then
    getgenv().priv9_library:unload_menu()
end
getgenv().priv9_loaded = true

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- UI LIBRARY (priv9 style)
-- ============================================================
getgenv().priv9_library = {
    directory = "priv9",
    folders = {"/fonts", "/configs"},
    flags = {},
    config_flags = {},
    connections = {},
    notifications = {},
    gui = nil
}

local library = getgenv().priv9_library
library.__index = library

-- Флаги и колбэки
local flags = library.flags
local config_flags = library.config_flags

-- Функции-хелперы
local function connection(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(library.connections, conn)
    return conn
end

function library:create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in pairs(options) do
        ins[prop] = value
    end
    return ins
end

function library:connection(signal, callback)
    return connection(signal, callback)
end

function library:unload_menu()
    if library.gui then library.gui:Destroy() end
    for _, conn in pairs(library.connections) do
        pcall(function() conn:Disconnect() end)
    end
    library.connections = {}
    if library.sgui then library.sgui:Destroy() end
end

-- ============================================================
-- FONTS
-- ============================================================
local fonts = {}
do
    local function Register_Font(Name, Weight, Style, Asset)
        if not isfile(Asset.Id) then writefile(Asset.Id, Asset.Font) end
        if isfile(Name .. ".font") then delfile(Name .. ".font") end
        local Data = {
            name = Name,
            faces = {{name = "Regular", weight = Weight, style = Style, assetId = getcustomasset(Asset.Id)}},
        }
        writefile(Name .. ".font", HttpService:JSONEncode(Data))
        return getcustomasset(Name .. ".font")
    end

    pcall(function()
        local ProggyClean = Register_Font("ProggyClean", 400, "Normal", {
            Id = "ProggyClean.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf")
        })
        fonts["ProggyClean"] = Font.new(ProggyClean, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)

    pcall(function()
        local TahomaBold = Register_Font("TahomaBold", 700, "Normal", {
            Id = "tahoma_bold.ttf",
            Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/tahoma_bold.ttf")
        })
        fonts["TahomaBold"] = Font.new(TahomaBold, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    end)

    -- Fallback
    if not fonts["ProggyClean"] then
        fonts["ProggyClean"] = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end
    if not fonts["TahomaBold"] then
        fonts["TahomaBold"] = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    end
end

-- ============================================================
-- THEME
-- ============================================================
local themes = {
    preset = {
        outline = Color3.fromRGB(10, 10, 10),
        inline = Color3.fromRGB(35, 35, 35),
        text = Color3.fromRGB(180, 180, 180),
        text_outline = Color3.fromRGB(0, 0, 0),
        ["1"] = Color3.fromHex("#245771"),
        ["2"] = Color3.fromHex("#215D63"),
        ["3"] = Color3.fromHex("#1E6453"),
    },
    utility = {
        ["1"] = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, ScrollBarImageColor3 = {}},
        ["2"] = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, ScrollBarImageColor3 = {}},
        ["3"] = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, ScrollBarImageColor3 = {}},
        inline = {BackgroundColor3 = {}},
        text = {TextColor3 = {}},
        text_outline = {Color = {}},
    }
}

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local notifications = {notifs = {}}

function notifications:create_notification(options)
    if not library.sgui then return end
    local cfg = {name = options.name or "..."}
    local outline = library:create("Frame", {
        Parent = library.sgui;
        Position = UDim2.fromOffset(-50, 50 + (#notifications.notifs * 30));
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(0, 0, 0, 24);
        BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.X;
        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local dark = library:create("Frame", {
        Parent = outline; BackgroundTransparency = 1;
        Position = UDim2.new(0, 2, 0, 2); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -4, 1, -4); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    });
    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = dark;
        Size = UDim2.new(0, 0, 1, 0); Position = UDim2.new(0, 1, 0, -1);
        BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.X;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library:create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, themes.preset["1"]),
            ColorSequenceKeypoint.new(0.5, themes.preset["2"]),
            ColorSequenceKeypoint.new(1, themes.preset["3"])
        };
        Parent = outline
    });
    local index = #notifications.notifs + 1
    notifications.notifs[index] = outline
    TweenService:Create(outline, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {AnchorPoint = Vector2.new(0, 0)}):Play()
    task.spawn(function()
        task.wait(3)
        notifications.notifs[index] = nil
        TweenService:Create(outline, TweenInfo.new(1), {Position = UDim2.fromOffset(-200, outline.Position.Y.Offset)}):Play()
        task.wait(1)
        outline:Destroy()
    end)
end

-- ============================================================
-- GAME DATA (Prison Life)
-- ============================================================
local PrisonLife = {
    Teams = {
        ["Inmate"] = true,
        ["Prisoner"] = true,
        ["Guard"] = true,
        ["Police"] = true,
        ["Criminal"] = true,
        ["Mafia"] = true,
        ["Rebel"] = true,
    }
}

-- Проверка тиммейта
local function IsTeammate(plr)
    if not plr or plr == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    if not myTeam then return false end
    return plr.Team == myTeam
end

-- ============================================================
-- TARGETS CACHE
-- ============================================================
local CachedTargets = {}

local function RebuildTargets()
    local list = {}
    local myChar = LocalPlayer.Character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
                if root then
                    table.insert(list, {
                        Model = char,
                        Humanoid = hum,
                        Root = root,
                        Player = plr,
                        RigType = (hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
                    })
                end
            end
        end
    end
    CachedTargets = list
end

task.spawn(function()
    while task.wait(1) do
        pcall(RebuildTargets)
    end
end)
RebuildTargets()

-- ============================================================
-- UI: WINDOW + TABS
-- ============================================================
do
    library.gui = library:create("ScreenGui", {
        Parent = CoreGui, Name = "\0", Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
    })

    library.sgui = library:create("ScreenGui", {Name = "priv9_notifs", Parent = gethui() or CoreGui})

    local window_outline = library:create("Frame", {
        Parent = library.gui;
        Position = UDim2.new(0.5, -320, 0.5, -250);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(0, 640, 0, 500);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });

    -- Title
    local title_holder = library:create("Frame", {
        Parent = window_outline; BackgroundTransparency = 0.8;
        Position = UDim2.new(0, 2, 0, 2); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -4, 0, 20); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    });
    library:create("TextLabel", {
        FontFace = fonts["TahomaBold"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = "priv9.net | prison life";
        Parent = title_holder;
        BackgroundTransparency = 1; Size = UDim2.new(1, 0, 1, 0); BorderSizePixel = 0;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library.gradient = library:create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, themes.preset["1"]),
            ColorSequenceKeypoint.new(0.5, themes.preset["2"]),
            ColorSequenceKeypoint.new(1, themes.preset["3"])
        };
        Parent = window_outline
    });

    -- Tab holder
    local tab_button_holder = library:create("Frame", {
        AnchorPoint = Vector2.new(0, 1); Parent = window_outline; BackgroundTransparency = 0.8;
        Position = UDim2.new(0, 2, 1, -2); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -4, 0, 20); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    });
    library:create("UIListLayout", {
        VerticalAlignment = Enum.VerticalAlignment.Center;
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        HorizontalFlex = Enum.UIFlexAlignment.Fill;
        Parent = tab_button_holder; SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalFlex = Enum.UIFlexAlignment.Fill
    });

    library.window_outline = window_outline
    library.tab_button_holder = tab_button_holder
    library.selected_tab = nil
end

function library:tab(properties)
    local cfg = {name = properties.name or "tab", count = 0}
    local tab_button = library:create("TextButton", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(170, 170, 170);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = library.tab_button_holder;
        BackgroundTransparency = 1; BorderSizePixel = 0;
        AutomaticSize = Enum.AutomaticSize.XY; TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local Page = library:create("Frame", {
        Parent = library.window_outline; BackgroundTransparency = 0.6;
        Position = UDim2.new(0, 2, 0, 24); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -4, 1, -48); BorderSizePixel = 0;
        BackgroundColor3 = Color3.fromRGB(0, 0, 0), Visible = false,
    });
    cfg.page = Page
    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalFlex = Enum.UIFlexAlignment.Fill; Parent = Page;
        Padding = UDim.new(0, 2); SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalFlex = Enum.UIFlexAlignment.Fill
    });
    library:create("UIPadding", {
        PaddingTop = UDim.new(0, 2); PaddingBottom = UDim.new(0, 2); Parent = Page;
        PaddingRight = UDim.new(0, 2); PaddingLeft = UDim.new(0, 2)
    });

    function cfg.open_tab()
        if library.selected_tab then
            library.selected_tab[1].Visible = false
            library.selected_tab[2].TextColor3 = Color3.fromRGB(170, 170, 170)
        end
        Page.Visible = true
        tab_button.TextColor3 = Color3.fromRGB(255, 255, 255)
        library.selected_tab = {Page, tab_button}
    end

    tab_button.MouseButton1Down:Connect(function() cfg.open_tab() end)
    if not library.selected_tab then cfg.open_tab() end
    return setmetatable(cfg, library)
end

function library:column()
    local self_tab = self
    local cfg = {count = 0}
    local scrolling_frame = library:create("ScrollingFrame", {
        ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0); Active = true;
        AutomaticCanvasSize = Enum.AutomaticSize.Y; ScrollBarThickness = 0;
        Parent = self_tab.page; LayoutOrder = -1; BackgroundTransparency = 1;
        ScrollBarImageTransparency = 1; BorderColor3 = Color3.fromRGB(0, 0, 0);
        BackgroundColor3 = Color3.fromRGB(0, 0, 0); BorderSizePixel = 0;
        CanvasSize = UDim2.new(0, 0, 0, 0)
    });
    cfg.column = scrolling_frame
    library:create("UIListLayout", {
        Parent = scrolling_frame; Padding = UDim.new(0, 5); SortOrder = Enum.SortOrder.LayoutOrder
    });
    return setmetatable(cfg, library)
end

function library:section(properties)
    local self_col = self
    local cfg = {
        name = properties.name or "section",
        count = self_col.count or 1,
    }
    local accent = library:create("Frame", {
        Parent = self_col.column; ClipsDescendants = true;
        BorderColor3 = Color3.fromRGB(0, 0, 0); BorderSizePixel = 0;
        BackgroundColor3 = themes.preset[tostring(cfg.count)] or themes.preset["1"]
    });
    local dark = library:create("Frame", {
        Parent = accent; BackgroundTransparency = 0.6;
        Position = UDim2.new(0, 2, 0, 16); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -4, 1, -18); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    });
    local elements = library:create("Frame", {
        Parent = dark; Position = UDim2.new(0, 4, 0, 5);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -8, 0, 0);
        BackgroundTransparency = 1; BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    cfg.elements = elements
    elements.AutomaticSize = Enum.AutomaticSize.Y
    accent.AutomaticSize = Enum.AutomaticSize.Y
    accent.Size = UDim2.new(1, 0, 0, 0)
    library:create("UIPadding", {Parent = elements, Name = "", PaddingBottom = UDim.new(0, 7)})
    library:create("UIListLayout", {
        Parent = elements; Padding = UDim.new(0, 6); SortOrder = Enum.SortOrder.LayoutOrder
    });
    library:create("TextLabel", {
        FontFace = fonts["TahomaBold"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = accent;
        Size = UDim2.new(1, 0, 0, 0); Position = UDim2.new(0, 4, 0, 2);
        BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.Y;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    return setmetatable(cfg, library)
end

function library:toggle(options)
    local self_sec = self
    local cfg = {
        name = options.name or "Toggle",
        flag = options.flag or tostring(math.random(1,9999999)),
        default = options.default or false,
        callback = options.callback or function() end,
        color = themes.preset["1"],
        count = self_sec.count or 1
    }
    local toggle = library:create("TextButton", {
        Parent = self_sec.elements; BackgroundTransparency = 1; Text = "";
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, 0, 0, 12);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = toggle;
        Size = UDim2.new(1, 0, 1, 0); Position = UDim2.new(0, 1, 0, -1);
        BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.X;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local accent = library:create("Frame", {
        AnchorPoint = Vector2.new(1, 0); Parent = toggle; Position = UDim2.new(1, 0, 0, 0);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(0, 12, 0, 12);
        BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local fill = library:create("Frame", {
        Parent = accent; Position = UDim2.new(0, 1, 0, 1);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -2, 1, -2);
        BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    function cfg.set(bool)
        fill.BackgroundColor3 = bool and themes.preset["1"] or themes.preset.inline
        flags[cfg.flag] = bool
        cfg.callback(bool)
    end
    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set
    toggle.MouseButton1Click:Connect(function()
        cfg.enabled = not cfg.enabled
        cfg.set(cfg.enabled)
    end)
    return setmetatable(cfg, library)
end

function library:slider(options)
    local self_sec = self
    local cfg = {
        name = options.name or nil, suffix = options.suffix or "",
        flag = options.flag or tostring(2^789),
        callback = options.callback or function() end,
        min = options.min or 0,
        max = options.max or 100,
        intervals = options.interval or 1,
        default = options.default or 10,
        value = options.default or 10,
        dragging = false,
    }
    local slider = library:create("Frame", {
        Parent = self_sec.elements; BackgroundTransparency = 1;
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, 0, 0, 25);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local label = library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        RichText = true; BorderColor3 = Color3.fromRGB(0, 0, 0); Text = "";
        Parent = slider; Size = UDim2.new(1, 0, 0, 0); Position = UDim2.new(0, 1, 0, -2);
        BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.XY;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local outline = library:create("TextButton", {
        Parent = slider; Text = ""; AutoButtonColor = false;
        Position = UDim2.new(0, 0, 0, 13); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, 0, 0, 12); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local inline = library:create("Frame", {
        Parent = outline; Position = UDim2.new(0, 1, 0, 1);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -2, 1, -2);
        BorderSizePixel = 0; BackgroundColor3 = themes.preset.inline
    });
    local accent = library:create("Frame", {
        Parent = inline; BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(0.5, 0, 1, 0); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    function cfg.set(value)
        local valuee = tonumber(value)
        if valuee == nil then return end
        cfg.value = math.clamp(math.floor(valuee / cfg.intervals + 0.5) * cfg.intervals, cfg.min, cfg.max)
        accent.Size = UDim2.new((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)
        label.Text = cfg.name .. "<font color='#AAAAAA'>" .. ' - ' .. tostring(cfg.value) .. cfg.suffix .. "</font>"
        flags[cfg.flag] = cfg.value
        cfg.callback(flags[cfg.flag])
    end
    cfg.set(cfg.default)
    outline.MouseButton1Down:Connect(function() cfg.dragging = true end)
    library:connection(UserInputService.InputChanged, function(input)
        if cfg.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local size_x = (input.Position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X
            local value = ((cfg.max - cfg.min) * size_x) + cfg.min
            cfg.set(value)
        end
    end)
    library:connection(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then cfg.dragging = false end
    end)
    config_flags[cfg.flag] = cfg.set
    return setmetatable(cfg, library)
end

function library:dropdown(options)
    local self_sec = self
    local cfg = {
        name = options.name or nil,
        flag = options.flag or tostring(math.random(1,9999999)),
        items = options.items or {""},
        callback = options.callback or function() end,
        multi = options.multi or false,
        open = false,
        option_instances = {},
        multi_items = {},
    }
    cfg.default = options.default or (cfg.multi and {cfg.items[1]}) or cfg.items[1] or "None"
    flags[cfg.flag] = {}
    local dropdown = library:create("Frame", {
        Parent = self_sec.elements; BackgroundTransparency = 1;
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, 0, 0, 16);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local dropdown_holder = library:create("TextButton", {
        AnchorPoint = Vector2.new(1, 0); AutoButtonColor = false; Text = "";
        Parent = dropdown; Position = UDim2.new(1, 0, 0, 0);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(0.5, 0, 0, 16);
        BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local inline = library:create("Frame", {
        Parent = dropdown_holder; Position = UDim2.new(0, 1, 0, 1);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -2, 1, -2);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    });
    local text = library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = inline;
        Size = UDim2.new(1, 0, 1, 0); BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 1); BorderSizePixel = 0;
        AutomaticSize = Enum.AutomaticSize.X; TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local accent = library:create("Frame", {
        Parent = library.gui; Size = UDim2.new(0.09, 0, 0.006, 20);
        Position = UDim2.new(0, 500, 0, 100); BorderColor3 = Color3.fromRGB(0, 0, 0);
        BorderSizePixel = 0; Visible = false;
        AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset["1"]
    });
    local inline2 = library:create("Frame", {
        Parent = accent; Size = UDim2.new(1, -2, 1, -2); Position = UDim2.new(0, 1, 0, 1);
        BorderColor3 = Color3.fromRGB(0, 0, 0); BorderSizePixel = 0;
        AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset.inline
    });
    library:create("UIListLayout", {
        Parent = inline2; Padding = UDim.new(0, 6); SortOrder = Enum.SortOrder.LayoutOrder
    });
    library:create("UIPadding", {
        PaddingTop = UDim.new(0, 5); PaddingBottom = UDim.new(0, 2); Parent = inline2;
        PaddingRight = UDim.new(0, 6); PaddingLeft = UDim.new(0, 6)
    });
    library:create("UIPadding", {PaddingBottom = UDim.new(0, 2); Parent = accent});

    function cfg.set_visible(bool) accent.Visible = bool end

    function cfg.set(value)
        local selected = {}
        local isTable = type(value) == "table"
        if value == nil then return end
        local lookup = nil
        if isTable then
            lookup = {}
            for k, v in pairs(value) do
                if type(k) == "number" and type(v) == "string" then lookup[v] = true
                elseif type(k) == "string" then lookup[k] = true end
            end
        end
        for _, option in pairs(cfg.option_instances) do
            local isSelected = false
            if isTable then isSelected = lookup[option.Text] == true
            else isSelected = option.Text == value end
            if isSelected then
                table.insert(selected, option.Text)
                cfg.multi_items = selected
                option.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                option.TextColor3 = Color3.fromRGB(170, 170, 170)
            end
        end
        if cfg.multi then
            text.Text = #selected > 0 and table.concat(selected, ", ") or cfg.name
            flags[cfg.flag] = selected
            cfg.callback(selected)
        else
            text.Text = selected[1] or cfg.name
            flags[cfg.flag] = selected[1]
            cfg.callback(selected[1])
        end
    end

    function cfg.refresh_options(list)
        for _, option in pairs(cfg.option_instances) do option:Destroy() end
        cfg.option_instances = {}
        for _, option in pairs(list) do
            local button = library:create("TextButton", {
                FontFace = fonts["ProggyClean"]; AutoButtonColor = false;
                TextColor3 = Color3.fromRGB(170, 170, 170); BorderColor3 = Color3.fromRGB(0, 0, 0);
                Text = option; Parent = inline2; Size = UDim2.new(1, 0, 0, 0);
                Position = UDim2.new(0, 0, 0, 1); BackgroundTransparency = 1;
                TextXAlignment = Enum.TextXAlignment.Left; BorderSizePixel = 0;
                AutomaticSize = Enum.AutomaticSize.Y; TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            });
            table.insert(cfg.option_instances, button)
            button.MouseButton1Down:Connect(function()
                if cfg.multi then
                    local selected_index = table.find(cfg.multi_items, button.Text)
                    if selected_index then table.remove(cfg.multi_items, selected_index)
                    else table.insert(cfg.multi_items, button.Text) end
                    cfg.set(cfg.multi_items)
                else
                    cfg.set_visible(false)
                    cfg.open = false
                    cfg.set(button.Text)
                end
            end)
        end
    end

    cfg.refresh_options(cfg.items)
    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set
    dropdown_holder.MouseButton1Click:Connect(function()
        cfg.open = not cfg.open
        accent.Size = UDim2.new(0, dropdown_holder.AbsoluteSize.X, 0, accent.Size.Y.Offset)
        accent.Position = UDim2.new(0, dropdown_holder.AbsolutePosition.X, 0, dropdown_holder.AbsolutePosition.Y + 77)
        cfg.set_visible(cfg.open)
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not (library:mouse_in_frame(accent) or library:mouse_in_frame(dropdown)) then
                cfg.open = false
                cfg.set_visible(false)
            end
        end
    end)
    return setmetatable(cfg, library)
end

function library:colorpicker(options)
    local self_sec = self
    local cfg = {
        name = options.name or "Color",
        flag = options.flag or tostring(2^789),
        color = options.color or Color3.new(1, 1, 1),
        alpha = options.alpha and 1 - options.alpha or 0,
        open = false,
        callback = options.callback or function() end,
    }
    local colorpicker_element = library:create("TextButton", {
        Parent = self_sec.elements; BackgroundTransparency = 1; Text = "";
        AutoButtonColor = false; BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, 0, 0, 12); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local accent = library:create("Frame", {
        AnchorPoint = Vector2.new(1, 0); Parent = colorpicker_element;
        Position = UDim2.new(1, 0, 0, 0); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(0, 30, 0, 12); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local colorpicker_element_color = library:create("Frame", {
        Parent = accent; Position = UDim2.new(0, 1, 0, 1);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -2, 1, -2);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = colorpicker_element;
        Size = UDim2.new(1, 0, 1, 0); Position = UDim2.new(0, 1, 0, 0);
        BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.X;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local colorpicker = library:create("Frame", {
        Parent = library.gui; Position = UDim2.new(0.688, 0, 0.247, 0);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Visible = false;
        Size = UDim2.new(0, 150, 0, 150); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local a = library:create("Frame", {
        Parent = colorpicker; BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local e = library:create("Frame", {
        Parent = a; Position = UDim2.new(0, 1, 0, 1); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -2, 1, -2); BorderSizePixel = 0;
        BackgroundColor3 = Color3.fromRGB(0, 0, 0); BackgroundTransparency = 0.6; ZIndex = -1
    });
    library:create("UIPadding", {
        PaddingTop = UDim.new(0, 7); PaddingBottom = UDim.new(0, -13); Parent = e;
        PaddingRight = UDim.new(0, 6); PaddingLeft = UDim.new(0, 7)
    });
    local textbox_holder = library:create("Frame", {
        Parent = e; Position = UDim2.new(0, 0, 1, -36); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -1, 0, 16); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local textbox = library:create("TextBox", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = ""; Parent = textbox_holder;
        BackgroundTransparency = 0; ClearTextOnFocus = false;
        PlaceholderColor3 = Color3.fromRGB(255, 255, 255); Size = UDim2.new(1, -2, 1, -2);
        Position = UDim2.new(0, 1, 0, 1); BorderSizePixel = 0; TextSize = 12;
        TextXAlignment = Enum.TextXAlignment.Center; BackgroundColor3 = themes.preset.inline
    });
    local hue_button = library:create("TextButton", {
        AnchorPoint = Vector2.new(1, 0); Text = ""; AutoButtonColor = false;
        Parent = e; Position = UDim2.new(1, -1, 0, 0); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(0, 14, 1, -60); BorderSizePixel = 0; BackgroundColor3 = themes.preset.inline
    });
    local hue_drag = library:create("Frame", {
        Parent = hue_button; Position = UDim2.new(0, 1, 0, 1); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -2, 1, -2); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library:create("UIGradient", {
        Rotation = 90; Parent = hue_drag;
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        }
    });
    local hue_picker = library:create("Frame", {
        Parent = hue_drag; BorderMode = Enum.BorderMode.Inset;
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, 2, 0, 3);
        Position = UDim2.new(0, -1, 0, -1); BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local alpha_button = library:create("TextButton", {
        AnchorPoint = Vector2.new(0, 0.5); Text = ""; AutoButtonColor = false;
        Parent = e; Position = UDim2.new(0, 0, 1, -48); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -1, 0, 14); BorderSizePixel = 0; BackgroundColor3 = themes.preset.inline
    });
    local alpha_color = library:create("Frame", {
        Parent = alpha_button; Position = UDim2.new(0, 1, 0, 1); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -2, 1, -2); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 221, 255)
    });
    local alphaind = library:create("ImageLabel", {
        ScaleType = Enum.ScaleType.Tile; BorderColor3 = Color3.fromRGB(0, 0, 0);
        Parent = alpha_color; Image = "rbxassetid://18274452449";
        BackgroundTransparency = 1; Size = UDim2.new(1, 0, 1, 0);
        TileSize = UDim2.new(0, 4, 0, 4); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library:create("UIGradient", {Parent = alphaind; Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}});
    local alpha_picker = library:create("Frame", {
        Parent = alpha_color; BorderMode = Enum.BorderMode.Inset;
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(0, 3, 1, 2);
        Position = UDim2.new(0, -1, 0, -1); BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local saturation_value_button = library:create("TextButton", {
        Parent = e; BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -20, 1, -60);
        Text = ""; AutoButtonColor = false; BorderSizePixel = 0; BackgroundColor3 = themes.preset.inline
    });
    local colorpicker_color = library:create("Frame", {
        Parent = saturation_value_button; Position = UDim2.new(0, 1, 0, 1);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -2, 1, -2);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 221, 255)
    });
    local val = library:create("TextButton", {
        Parent = colorpicker_color; Text = ""; AutoButtonColor = false;
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, 0, 1, 0);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library:create("UIGradient", {Parent = val; Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}});
    local saturation_value_picker = library:create("Frame", {
        Parent = colorpicker_color; BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(0, 3, 0, 3); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    });
    library:create("Frame", {
        Parent = saturation_value_picker; Position = UDim2.new(0, 1, 0, 1);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, -2, 1, -2);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local saturation_button = library:create("TextButton", {
        Parent = colorpicker_color; Text = ""; AutoButtonColor = false;
        Size = UDim2.new(1, 0, 1, 0); BorderColor3 = Color3.fromRGB(0, 0, 0);
        ZIndex = 2; BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library:create("UIGradient", {
        Rotation = 270; Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)};
        Parent = saturation_button; Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))}
    });
    local dragging_sat = false
    local dragging_hue = false
    local dragging_alpha = false
    local h, s, v = cfg.color:ToHSV()
    local a = cfg.alpha
    flags[cfg.flag] = {}
    function cfg.set_visible(bool)
        colorpicker.Visible = bool
        colorpicker.Position = UDim2.fromOffset(colorpicker_element_color.AbsolutePosition.X - 1, colorpicker_element_color.AbsolutePosition.Y + colorpicker_element_color.AbsoluteSize.Y + 65)
    end
    function cfg.set(color_, alpha_)
        if color_ then h, s, v = color_:ToHSV() end
        if alpha_ then a = alpha_ end
        local Color = Color3.fromHSV(h, s, v)
        hue_picker.Position = UDim2.new(0, -1, 1 - h, -1)
        alpha_picker.Position = UDim2.new(1 - a, -1, 0, -1)
        saturation_value_picker.Position = UDim2.new(s, -1, 1 - v, -1)
        alpha_color.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        colorpicker_element_color.BackgroundColor3 = Color
        colorpicker_color.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        flags[cfg.flag] = {Color = Color; Transparency = a}
        cfg.callback(Color, a)
    end
    function cfg.update_color()
        local m = UserInputService:GetMouseLocation()
        local offset = Vector2.new(m.X, m.Y - 36)
        if dragging_sat then
            s = math.clamp((offset - saturation_value_button.AbsolutePosition).X / saturation_value_button.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp((offset - saturation_value_button.AbsolutePosition).Y / saturation_value_button.AbsoluteSize.Y, 0, 1)
        elseif dragging_hue then
            h = 1 - math.clamp((offset - hue_button.AbsolutePosition).Y / hue_button.AbsoluteSize.Y, 0, 1)
        elseif dragging_alpha then
            a = 1 - math.clamp((offset - alpha_button.AbsolutePosition).X / alpha_button.AbsoluteSize.X, 0, 1)
        end
        cfg.set(nil, nil)
    end
    cfg.set(cfg.color, cfg.alpha)
    config_flags[cfg.flag] = cfg.set
    colorpicker_element.MouseButton1Click:Connect(function()
        cfg.open = not cfg.open
        cfg.set_visible(cfg.open)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if (dragging_sat or dragging_hue or dragging_alpha) and input.UserInputType == Enum.UserInputType.MouseMovement then
            cfg.update_color()
        end
    end)
    library:connection(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging_sat = false; dragging_hue = false; dragging_alpha = false
            if not (library:mouse_in_frame(colorpicker_element) or library:mouse_in_frame(colorpicker)) then
                cfg.open = false; cfg.set_visible(false)
            end
        end
    end)
    alpha_button.MouseButton1Down:Connect(function() dragging_alpha = true end)
    hue_button.MouseButton1Down:Connect(function() dragging_hue = true end)
    saturation_button.MouseButton1Down:Connect(function() dragging_sat = true end)
    return setmetatable(cfg, library)
end

function library:keybind(options)
    local self_sec = self
    local cfg = {
        flag = options.flag or tostring(math.random(1,9999999)),
        callback = options.callback or function() end,
        name = options.name or nil,
        key = options.key or nil,
        mode = options.mode or "Hold",
        active = false,
    }
    flags[cfg.flag] = {mode = cfg.mode, key = cfg.key, active = cfg.active}
    local keybind = library:create("Frame", {
        Parent = self_sec.elements; BackgroundTransparency = 1;
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(1, 0, 0, 16);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local text = library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = keybind;
        Size = UDim2.new(1, 0, 1, 0); Position = UDim2.new(0, 1, 0, 0);
        BackgroundTransparency = 1; TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0; AutomaticSize = Enum.AutomaticSize.X;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local keybind_holder = library:create("TextButton", {
        AnchorPoint = Vector2.new(1, 0); AutoButtonColor = false; Text = "";
        Parent = keybind; Position = UDim2.new(1, 0, 0, 0); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(0.5, 0, 0, 16); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    local key_text = library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = "[-]"; Parent = keybind_holder;
        Size = UDim2.new(1, 0, 1, 0); BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, -1); BorderSizePixel = 0;
        AutomaticSize = Enum.AutomaticSize.X; TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    function cfg.set(input)
        if typeof(input) == "EnumItem" then
            input = input.Name == "Escape" and "..." or input
            cfg.key = input or "..."
            flags[cfg.flag].key = cfg.key
        elseif type(input) == "boolean" then
            cfg.active = input
            flags[cfg.flag].active = input
            cfg.callback(input)
        end
        local keyName = tostring(cfg.key):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
        key_text.Text = " ".. (keyName ~= "..." and keyName or "...") .." "
    end
    keybind_holder.MouseButton1Down:Connect(function()
        key_text.Text = "..."
        local conn
        conn = library:connection(UserInputService.InputBegan, function(keycode, game_event)
            if game_event then return end
            cfg.set(keycode.KeyCode)
            conn:Disconnect()
        end)
    end)
    library:connection(UserInputService.InputBegan, function(input, game_event)
        if not game_event and input.KeyCode == cfg.key then
            if cfg.mode == "Hold" then cfg.set(true)
            elseif cfg.mode == "Toggle" then
                cfg.active = not cfg.active
                cfg.set(cfg.active)
            end
        end
    end)
    library:connection(UserInputService.InputEnded, function(input, game_event)
        if game_event then return end
        if input.KeyCode == cfg.key then
            if cfg.mode == "Hold" then cfg.set(false) end
        end
    end)
    cfg.set(cfg.key)
    return setmetatable(cfg, library)
end

function library:button(options)
    local self_sec = self
    local cfg = {name = options.name or "button", callback = options.callback or function() end}
    local frame = library:create("TextButton", {
        AnchorPoint = Vector2.new(1, 0); Text = ""; AutoButtonColor = false;
        Parent = self_sec.elements; Position = UDim2.new(1, 0, 0, 0); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, 0, 0, 16); BorderSizePixel = 0; BackgroundColor3 = themes.preset["1"]
    });
    library:create("Frame", {
        Parent = frame; Position = UDim2.new(0, 1, 0, 1); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -2, 1, -2); BorderSizePixel = 0; BackgroundColor3 = themes.preset.inline
    });
    library:create("TextLabel", {
        FontFace = fonts["ProggyClean"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = cfg.name; Parent = frame;
        Size = UDim2.new(1, 0, 1, 0); BackgroundTransparency = 1;
        Position = UDim2.new(0, 1, 0, 1); BorderSizePixel = 0;
        AutomaticSize = Enum.AutomaticSize.X; TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    frame.MouseButton1Click:Connect(function() cfg.callback() end)
    return setmetatable(cfg, library)
end

function library:mouse_in_frame(uiobject)
    if not uiobject then return false end
    local mouse = LocalPlayer:GetMouse()
    local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
    local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X
    return (y_cond and x_cond)
end

-- ============================================================
-- UI: BUILD MENU
-- ============================================================
local window = library:tab({name = "main"})
-- Переопределим window под правильный API (tab -> column -> section)
-- Но у нас таб создаётся внутри window, поэтому используем window как таб
-- А точнее создадим окно вручную

-- Пересоздаём окно правильно
do
    -- Удаляем всё, что создали до этого
    if library.gui then library.gui:Destroy() end

    library.gui = library:create("ScreenGui", {
        Parent = CoreGui, Name = "\0", Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
    })
    library.sgui = library:create("ScreenGui", {Name = "priv9_notifs", Parent = gethui() or CoreGui})

    -- Window
    local window_outline = library:create("Frame", {
        Parent = library.gui;
        Position = UDim2.new(0.5, -320, 0.5, -250);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Size = UDim2.new(0, 640, 0, 500);
        BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    local title_holder = library:create("Frame", {
        Parent = window_outline; BackgroundTransparency = 0.8;
        Position = UDim2.new(0, 2, 0, 2); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -4, 0, 20); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    });
    library:create("TextLabel", {
        FontFace = fonts["TahomaBold"]; TextColor3 = Color3.fromRGB(255, 255, 255);
        BorderColor3 = Color3.fromRGB(0, 0, 0); Text = "priv9.net | prison life";
        Parent = title_holder;
        BackgroundTransparency = 1; Size = UDim2.new(1, 0, 1, 0); BorderSizePixel = 0;
        TextSize = 12; BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    });
    library.gradient = library:create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, themes.preset["1"]),
            ColorSequenceKeypoint.new(0.5, themes.preset["2"]),
            ColorSequenceKeypoint.new(1, themes.preset["3"])
        };
        Parent = window_outline
    });
    local tab_button_holder = library:create("Frame", {
        AnchorPoint = Vector2.new(0, 1); Parent = window_outline; BackgroundTransparency = 0.8;
        Position = UDim2.new(0, 2, 1, -2); BorderColor3 = Color3.fromRGB(0, 0, 0);
        Size = UDim2.new(1, -4, 0, 20); BorderSizePixel = 0; BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    });
    library:create("UIListLayout", {
        VerticalAlignment = Enum.VerticalAlignment.Center;
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        HorizontalFlex = Enum.UIFlexAlignment.Fill;
        Parent = tab_button_holder; SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalFlex = Enum.UIFlexAlignment.Fill
    });
    library.window_outline = window_outline
    library.tab_button_holder = tab_button_holder
end

local combat_tab = library:tab({name = "combat"})
local combat_l = combat_tab:column()
local combat_r = combat_tab:column()

-- Aim Assist
local aim = combat_l:section({name = "aim assist (legit)"})
aim:toggle({name = "enabled", flag = "AimAssistEnabled", default = false})
aim:keybind({name = "aim key", flag = "AimAssistKey", key = Enum.KeyCode.T, mode = "Hold"})
aim:slider({name = "fov", flag = "AimAssistFOV", min = 1, max = 180, default = 30, interval = 1, suffix = "°"})
aim:slider({name = "speed", flag = "AimAssistSpeed", min = 1, max = 100, default = 50, interval = 1, suffix = "%"})
aim:slider({name = "prediction", flag = "AimAssistPrediction", min = 0, max = 100, default = 50, interval = 1, suffix = "%"})
aim:dropdown({name = "smoothing", flag = "AimAssistSmoothing", items = {"Linear","Exponential"}, default = "Linear"})
aim:toggle({name = "team check", flag = "AimAssistTeamCheck", default = true})
aim:toggle({name = "wall check", flag = "AimAssistWallCheck", default = true})

-- Silent Aim
local silent = combat_r:section({name = "silent aim"})
silent:toggle({name = "enabled", flag = "SilentAimEnabled", default = false})
silent:keybind({name = "silent key", flag = "SilentAimKey", key = Enum.KeyCode.C, mode = "Hold"})
silent:slider({name = "fov", flag = "SilentAimFOV", min = 1, max = 180, default = 60, interval = 1, suffix = "°"})
silent:slider({name = "hit chance", flag = "SilentAimHitChance", min = 1, max = 100, default = 100, interval = 1, suffix = "%"})
silent:toggle({name = "team check", flag = "SilentAimTeamCheck", default = true})
silent:toggle({name = "wall check", flag = "SilentAimWallCheck", default = false})

-- Triggerbot
local trig = combat_l:section({name = "triggerbot"})
trig:toggle({name = "enabled", flag = "TriggerEnabled", default = false})
trig:keybind({name = "trigger key", flag = "TriggerKey", key = Enum.KeyCode.V, mode = "Hold"})
trig:slider({name = "delay", flag = "TriggerDelay", min = 0, max = 500, default = 16, interval = 1, suffix = "ms"})

-- Visuals Tab
local visuals_tab = library:tab({name = "visuals"})
local vis_l = visuals_tab:column()
local vis_r = visuals_tab:column()

-- ESP
local esp = vis_l:section({name = "esp"})
esp:toggle({name = "enabled", flag = "EspEnabled", default = true})
esp:slider({name = "max distance", flag = "EspMaxDistance", min = 50, max = 5000, default = 2500, interval = 1, suffix = " studs"})
esp:toggle({name = "box", flag = "EspBox", default = true})
esp:colorpicker({name = "box color", flag = "BoxColor", color = Color3.fromRGB(120, 240, 220)})
esp:toggle({name = "name", flag = "EspName", default = true})
esp:colorpicker({name = "name color", flag = "NameColor", color = Color3.fromRGB(255, 255, 255)})
esp:toggle({name = "health", flag = "EspHealth", default = true})
esp:toggle({name = "distance", flag = "EspDistance", default = true})
esp:colorpicker({name = "distance color", flag = "DistanceColor", color = Color3.fromRGB(200, 200, 200)})
esp:toggle({name = "skeleton", flag = "EspSkeleton", default = false})
esp:colorpicker({name = "skeleton color", flag = "SkeletonColor", color = Color3.fromRGB(255, 255, 255)})
esp:toggle({name = "team check", flag = "EspTeamCheck", default = true})

-- Chams
local chams = vis_l:section({name = "chams"})
chams:toggle({name = "enabled", flag = "ChamsEnabled", default = true})
chams:toggle({name = "glow (neon)", flag = "ChamsGlow", default = true})
chams:colorpicker({name = "visible color", flag = "VisibleColor", color = Color3.fromRGB(183, 190, 255), alpha = 0.4})
chams:colorpicker({name = "invisible color", flag = "InvisibleColor", color = Color3.fromRGB(0, 0, 0), alpha = 0.6})

-- Lighting
local light = vis_r:section({name = "lighting"})
light:toggle({name = "enable", flag = "LightingEnabled", default = false})
light:dropdown({name = "preset", flag = "LightingPreset", items = {"Midnight", "Dawn", "Golden Hour", "Overcast", "Foggy Morning"}, default = "Midnight"})
light:slider({name = "clock time", flag = "TimeSlider", min = 0, max = 24, default = 0, interval = 0.1})
light:toggle({name = "bloom", flag = "BloomEnabled", default = true})
light:slider({name = "bloom intensity", flag = "BloomIntensity", min = 0, max = 3, default = 1.5, interval = 0.01})
light:slider({name = "bloom size", flag = "BloomSize", min = 4, max = 56, default = 32, interval = 1})

-- ============================================================
-- LOGIC: AIM ASSIST
-- ============================================================
local AimAssist = {CurrentTarget = nil}
local AimRayParams = RaycastParams.new()
AimRayParams.FilterDescendantsInstances = {workspace}
AimRayParams.FilterType = Enum.RaycastFilterType.Include

local function AimRaycast(O, G)
    local D = G - O
    local DU = D.Unit
    local CO = O
    local RD = D.Magnitude
    while RD > 0 do
        local R = workspace:Raycast(CO, DU * RD, AimRayParams)
        if not R then return false end
        local HP = R.Instance
        if HP and HP.CanCollide and HP.Transparency < 1 then return true, R end
        RD = RD - (R.Position - CO).Magnitude
        CO = R.Position + DU / 20
    end
    return false
end

local function GetClosestTarget(fov, wallCheck, teamCheck)
    local CF = Camera.CFrame
    local CP = CF.Position
    local CLV = CF.LookVector
    local RF = math.rad(fov)
    local bestTarget = nil
    local bestAngle = math.huge

    for _, tgt in ipairs(CachedTargets) do
        if teamCheck and IsTeammate(tgt.Player) then continue end
        local root = tgt.Root
        if root then
            local angle = math.acos(CLV:Dot((root.Position - CP).Unit)) * 2
            if angle <= RF then
                if wallCheck then
                    local hit = AimRaycast(CP, root.Position)
                    if hit then continue end
                end
                if angle < bestAngle then
                    bestAngle = angle
                    bestTarget = tgt
                end
            end
        end
    end
    return bestTarget
end

local function ProcessAimAssist(dt)
    if not flags.AimAssistEnabled then
        AimAssist.CurrentTarget = nil
        return
    end
    local kp = flags.AimAssistKey
    if type(kp) == "table" and kp.key and kp.key ~= "..." then
        if kp.active ~= true then AimAssist.CurrentTarget = nil return end
    end

    local CF = Camera.CFrame
    local CP = CF.Position

    if AimAssist.CurrentTarget then
        local cur = AimAssist.CurrentTarget
        local part = cur.Root
        local valid = part and part.Parent and cur.Humanoid and cur.Humanoid.Health > 0
        if valid then
            local aimPos = part.Position
            if flags.AimAssistWallCheck then
                local h = AimRaycast(CP, aimPos)
                if h then AimAssist.CurrentTarget = nil return end
            end
            -- Prediction
            if flags.AimAssistPrediction > 0 and part.Velocity then
                local predAmount = flags.AimAssistPrediction / 100
                aimPos = aimPos + part.Velocity * (predAmount * 0.15)
            end
            local speed = flags.AimAssistSpeed or 50
            local smoothing
            if flags.AimAssistSmoothing == "Linear" then
                smoothing = speed / 10 * dt
            else
                smoothing = 1 - math.exp(-speed / 2 * dt)
            end
            Camera.CFrame = CF:Lerp(CFrame.lookAt(CP, aimPos), smoothing)
            return
        else
            AimAssist.CurrentTarget = nil
        end
    end

    local target = GetClosestTarget(flags.AimAssistFOV or 30, flags.AimAssistWallCheck, flags.AimAssistTeamCheck)
    if target then AimAssist.CurrentTarget = target end
end

-- ============================================================
-- LOGIC: SILENT AIM (namecall hook)
-- ============================================================
if getrawmetatable and newcclosure and setreadonly and getnamecallmethod and checkcaller then
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Raycast" and flags.SilentAimEnabled and checkcaller() == false then
            local args = {...}
            local origin = args[1]
            local direction = args[2]
            if origin and direction then
                local kp = flags.SilentAimKey
                if type(kp) == "table" and kp.key and kp.key ~= "..." then
                    if kp.active ~= true then return oldNamecall(self, ...) end
                end
                local camPos = Camera.CFrame.Position
                local camLook = Camera.CFrame.LookVector
                local cosFov = math.cos(math.rad(flags.SilentAimFOV or 60))
                local bestDot, bestPos = -1, nil
                for _, tgt in ipairs(CachedTargets) do
                    if flags.SilentAimTeamCheck and IsTeammate(tgt.Player) then continue end
                    local root = tgt.Root
                    if root then
                        local d = root.Position - camPos
                        local dot = camLook:Dot(d.Unit)
                        if dot >= cosFov and dot > bestDot then
                            -- Wall check
                            if flags.SilentAimWallCheck then
                                local hit = AimRaycast(camPos, root.Position)
                                if hit then continue end
                            end
                            bestDot = dot
                            bestPos = root.Position
                        end
                    end
                end
                if bestPos then
                    args[2] = (bestPos - origin).Unit * direction.Magnitude
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

-- ============================================================
-- LOGIC: LIGHTING
-- ============================================================
local LightingPresets = {
    ["Midnight"] = {
        Ambient = Color3.fromRGB(10, 13, 22), OutdoorAmbient = Color3.fromRGB(7, 11, 28),
        Brightness = 0.38, ClockTime = 0, FogColor = Color3.fromRGB(7, 9, 20),
        FogStart = 45, FogEnd = 1700, BloomIntensity = 1.65, BloomSize = 34,
    },
    ["Dawn"] = {
        Ambient = Color3.fromRGB(80, 70, 90), OutdoorAmbient = Color3.fromRGB(120, 100, 80),
        Brightness = 2.2, ClockTime = 6.5, FogColor = Color3.fromRGB(195, 175, 155),
        FogStart = 250, FogEnd = 7000, BloomIntensity = 1.2, BloomSize = 28,
    },
    ["Golden Hour"] = {
        Ambient = Color3.fromRGB(92, 60, 38), OutdoorAmbient = Color3.fromRGB(185, 118, 55),
        Brightness = 2.9, ClockTime = 18.5, FogColor = Color3.fromRGB(222, 148, 75),
        FogStart = 120, FogEnd = 3800, BloomIntensity = 1.9, BloomSize = 38,
    },
    ["Overcast"] = {
        Ambient = Color3.fromRGB(112, 115, 122), OutdoorAmbient = Color3.fromRGB(148, 152, 160),
        Brightness = 1.5, ClockTime = 12, FogColor = Color3.fromRGB(178, 182, 192),
        FogStart = 180, FogEnd = 4500, BloomIntensity = 0.55, BloomSize = 20,
    },
    ["Foggy Morning"] = {
        Ambient = Color3.fromRGB(118, 118, 112), OutdoorAmbient = Color3.fromRGB(158, 158, 148),
        Brightness = 1.75, ClockTime = 7.2, FogColor = Color3.fromRGB(198, 198, 192),
        FogStart = 40, FogEnd = 1000, BloomIntensity = 0.75, BloomSize = 22,
    },
}

local CrimBloom = Instance.new("BloomEffect")
CrimBloom.Name = "CrimBloom"
CrimBloom.Intensity = 2.4; CrimBloom.Size = 56; CrimBloom.Threshold = 0.55; CrimBloom.Enabled = false
CrimBloom.Parent = Lighting

local function ApplyPreset(name)
    local preset = LightingPresets[name]
    if not preset then return end
    for prop, value in pairs(preset) do
        pcall(function() Lighting[prop] = value end)
    end
    if preset.BloomIntensity then CrimBloom.Intensity = preset.BloomIntensity end
    if preset.BloomSize then CrimBloom.Size = preset.BloomSize end
end

-- ============================================================
-- LOGIC: CHAMS (Neon + Adornments)
-- ============================================================
local ShadingModes = {
    ["Default"] = Enum.AdornShading.Default,
    ["Shaded"] = Enum.AdornShading.Shaded,
    ["XRayShaded"] = Enum.AdornShading.XRayShaded,
    ["AlwaysOnTop"] = Enum.AdornShading.AlwaysOnTop
}

local Storage = {}
local OriginalParts = {}

local function CreateChamsForPart(part)
    local Inline, Outline
    Inline = Instance.new("BoxHandleAdornment")
    Inline.Size = part.Size + Vector3.new(-0.1, -0.1, -0.1)
    Inline.ZIndex = 2; Inline.AlwaysOnTop = true; Inline.Parent = CoreGui
    Outline = Instance.new("BoxHandleAdornment")
    Outline.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
    Outline.ZIndex = 1; Outline.AlwaysOnTop = false; Outline.Parent = CoreGui
    Inline.Adornee = part; Outline.Adornee = part
    return { Inline, Outline }
end

local function ApplyGlowBody(Model, color)
    if Model == LocalPlayer.Character then return end
    if not OriginalParts[Model] then OriginalParts[Model] = {} end
    local parts = {}
    for _, name in ipairs({"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
        local p = Model:FindFirstChild(name)
        if p and p:IsA("BasePart") then table.insert(parts, p) end
    end
    for _, p in ipairs(parts) do
        if p.Parent then
            local saved = OriginalParts[Model][p]
            if not saved then
                saved = {Material = p.Material, Color = p.Color}
                OriginalParts[Model][p] = saved
            end
            pcall(function() p.Material = Enum.Material.Neon end)
            local bright = Color3.new(
                math.min(1, color.R * 0.15 + 0.9),
                math.min(1, color.G * 0.15 + 0.9),
                math.min(1, color.B * 0.15 + 0.9)
            )
            pcall(function() p.Color = bright end)
        end
    end
end

local function RestoreGlowBody(Model)
    if not OriginalParts[Model] then return end
    for p, data in pairs(OriginalParts[Model]) do
        if p and p.Parent then
            pcall(function() p.Material = data.Material end)
            pcall(function() p.Color = data.Color end)
        end
    end
    OriginalParts[Model] = nil
end

-- ============================================================
-- LOGIC: ESP
-- ============================================================
local ESPOverlay = Instance.new("ScreenGui")
ESPOverlay.Name = "priv9_esp"
ESPOverlay.ResetOnSpawn = false
ESPOverlay.IgnoreGuiInset = true
ESPOverlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPOverlay.DisplayOrder = 999
ESPOverlay.Parent = gethui() or CoreGui

local BoxEntries = {}

local function NewBoxEntry()
    local container = Instance.new("Frame")
    container.Name = "priv9_box"; container.BackgroundTransparency = 1
    container.BorderSizePixel = 0; container.Visible = false; container.ZIndex = 1
    container.Parent = ESPOverlay
    local box = Instance.new("Frame")
    box.Position = UDim2.new(0, -1, 0, -1); box.Size = UDim2.new(1, 2, 1, 2)
    box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.ZIndex = 1
    box.Parent = container
    local inline = Instance.new("UIStroke")
    inline.Color = Color3.fromRGB(120, 240, 220); inline.Thickness = 1
    inline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; inline.Parent = box
    local outline = Instance.new("UIStroke")
    outline.Color = Color3.fromRGB(0, 0, 0); outline.Thickness = 3
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; outline.Parent = container
    return {Container = container, Box = box, Inline = inline, Outline = outline}
end

local function GetBoxEntry(p)
    if not BoxEntries[p] then BoxEntries[p] = NewBoxEntry() end
    return BoxEntries[p]
end

-- ============================================================
--RENDER LOOP
-- ============================================================
local FrameCounter = 0
RunService.RenderStepped:Connect(function(dt)
    FrameCounter = FrameCounter + 1
    if FrameCounter % 4 == 0 then RebuildTargets() end

   
    pcall(ProcessAimAssist, dt)

    local EspActive = flags.EspEnabled == true
    local ChamsActive = flags.ChamsEnabled == true
    local ChamsGlow = flags.ChamsGlow == true
    local EspMaxDistance = flags.EspMaxDistance or 2500
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position

    local activeKeys = {}

    for _, tgt in ipairs(CachedTargets) do
        pcall(function()
            local Model = tgt.Model
            local Humanoid = tgt.Humanoid
            local Player = tgt.Player
            local HRP = tgt.Root

            activeKeys[Model] = true

            local distance = 0
            if myPos and HRP then distance = (HRP.Position - myPos).Magnitude end

        
            local wantGlow = ChamsGlow and ChamsActive and Humanoid.Health > 0 and distance <= EspMaxDistance
            local hasGlow = OriginalParts[Model] ~= nil
            if wantGlow and not hasGlow then
                ApplyGlowBody(Model, flags.VisibleColor and flags.VisibleColor.Color or Color3.fromRGB(140, 180, 255))
            elseif not wantGlow and hasGlow then
                RestoreGlowBody(Model)
            end

            
            if ChamsActive and Humanoid.Health > 0 then
                local Data = Storage[Model]
                if not Data then Data = { Chams = {} }; Storage[Model] = Data end
                for _, PartName in ipairs({"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do
                    local BodyPart = Model:FindFirstChild(PartName)
                    if BodyPart and BodyPart:IsA("BasePart") then
                        if not Data.Chams[PartName] then Data.Chams[PartName] = CreateChamsForPart(BodyPart) end
                        local Pair = Data.Chams[PartName]
                        local Inline, Outline = Pair[1], Pair[2]
                        Inline.Adornee = BodyPart; Inline.Visible = true
                        Inline.Transparency = 0.65
                        Inline.Color3 = flags.InvisibleColor and flags.InvisibleColor.Color or Color3.new(0, 0, 0)
                        Inline.AlwaysOnTop = not ChamsGlow
                        Outline.Adornee = BodyPart; Outline.Visible = true
                        Outline.Transparency = 0.35
                        Outline.Color3 = flags.VisibleColor and flags.VisibleColor.Color or Color3.fromRGB(140, 180, 255)
                        Outline.AlwaysOnTop = true
                    end
                end
            else
                local Data = Storage[Model]
                if Data then
                    for _, Pair in pairs(Data.Chams) do
                        Pair[1].Adornee = nil; Pair[2].Adornee = nil
                        Pair[1].Visible = false; Pair[2].Visible = false
                    end
                end
            end

            -- ESP
            if EspActive and Humanoid.Health > 0 and distance <= EspMaxDistance and HRP then
                local cam = workspace.CurrentCamera
                if cam then
                    local sp = cam:WorldToViewportPoint(HRP.Position)
                    if sp.Z > 0 then
                        local tanFov = math.tan(math.rad(cam.FieldOfView) * 0.5)
                        if tanFov > 0 then
                            local scale = (cam.ViewportSize.Y * 1.5) / (sp.Z * 2 * tanFov)
                            local width = 2.0833 * scale
                            local height = 3.6364 * scale
                            local bx = math.floor(sp.X - width * 0.5)
                            local by = math.floor(sp.Y - height * 0.4)
                            local bw = math.floor(width)
                            local bh = math.floor(height)

                            local BoxE = GetBoxEntry(Model)
                            if BoxE then
                                BoxE.Container.Visible = true
                                BoxE.Container.Position = UDim2.new(0, bx, 0, by)
                                BoxE.Container.Size = UDim2.new(0, math.max(1, bw), 0, math.max(1, bh))
                                BoxE.Inline.Color = flags.BoxColor and flags.BoxColor.Color or Color3.fromRGB(120, 240, 220)
                            end
                        end
                    end
                end
            else
                local BoxE = BoxEntries[Model]
                if BoxE then BoxE.Container.Visible = false end
            end
        end)
    end

    -- Cleanup
    for Model, _ in pairs(Storage) do
        if not activeKeys[Model] or not Model.Parent then
            local Data = Storage[Model]
            if Data then
                for _, Pair in pairs(Data.Chams) do
                    pcall(function() Pair[1]:Destroy() end)
                    pcall(function() Pair[2]:Destroy() end)
                end
            end
            Storage[Model] = nil
        end
    end
    for Model, _ in pairs(BoxEntries) do
        if not activeKeys[Model] or not Model.Parent then
            pcall(function() BoxEntries[Model].Container:Destroy() end)
            BoxEntries[Model] = nil
        end
    end
    for Model, _ in pairs(OriginalParts) do
        if not Model.Parent then RestoreGlowBody(Model) end
    end
end)


config_flags["LightingEnabled"] = function(v)
    if v then
        ApplyPreset(flags.LightingPreset or "Midnight")
        if flags.BloomEnabled then CrimBloom.Enabled = true end
    else
        CrimBloom.Enabled = false
    end
end
config_flags["LightingPreset"] = function(v)
    if flags.LightingEnabled then ApplyPreset(v) end
end
config_flags["BloomEnabled"] = function(v)
    if CrimBloom then CrimBloom.Enabled = v and flags.LightingEnabled end
end


function CleanUp()
    pcall(function() library:unload_menu() end)
    pcall(function() ESPOverlay:Destroy() end)
    pcall(function() CrimBloom:Destroy() end)
end


notifications:create_notification({name = "priv9.net | prison life loaded"})
