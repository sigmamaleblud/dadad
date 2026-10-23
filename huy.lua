-- UILib.lua | dx9ware 1:1 (complete rewrite)
-- Fixes: sidebar layout, dropdown clipping, section visibility,
-- color picker, multi dropdown, notify, watermark, config save/load.

local UILib = {}
UILib.__index = UILib

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- ============================================================
-- PALETTE
-- ============================================================
local T = {
    SB = Color3.fromRGB(13,13,13),
    BG = Color3.fromRGB(17,17,17),
    ROW = Color3.fromRGB(21,21,21),
    ROWH = Color3.fromRGB(26,26,26),
    LINE = Color3.fromRGB(28,28,28),
    LINEP = Color3.fromRGB(32,32,32),
    ACC = Color3.fromRGB(102,42,194),
    ACC2 = Color3.fromRGB(130,60,220),
    ACCA = Color3.fromRGB(90,36,175),
    ACCH = Color3.fromRGB(45,18,90),
    TXT = Color3.fromRGB(208,208,208),
    TXT2 = Color3.fromRGB(105,105,105),
    TXTH = Color3.fromRGB(185,185,185),
    INP = Color3.fromRGB(22,22,22),
    INPB = Color3.fromRGB(44,44,44),
    TOFF = Color3.fromRGB(30,30,30),
    TOFFB = Color3.fromRGB(52,52,52),
    SLB = Color3.fromRGB(30,30,30),
    DROP = Color3.fromRGB(15,15,15),
    WHITE = Color3.fromRGB(255,255,255),
}

local SW, PW, RH, SH = 152, 240, 26, 26

-- ============================================================
-- HELPERS
-- ============================================================
local function tw(o,p,t) TS:Create(o, TweenInfo.new(t or 0.1, Enum.EasingStyle.Quad), p):Play() end
local function N(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function C(r,p) return N("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function ST(c,t,p)
    local s = Instance.new("UIStroke")
    s.Color = c; s.Thickness = t or 1; s.Parent = p
    return s
end

local function drag(frame, handle)
    handle = handle or frame
    local d, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            d = true; ds = i.Position; sp = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and i.UserInputType == Enum.UserInputType.MouseMovement then
            local v = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + v.X,
                                       sp.Y.Scale, sp.Y.Offset + v.Y)
        end
    end)
end

local function guiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return CoreGui
end

local function toKeyCode(v)
    if not v then return nil end
    if typeof(v) == "EnumItem" then return v end
    if type(v) == "string" then
        return Enum.KeyCode[v] or Enum.UserInputType[v]
    end
    return nil
end

local function keyName(k)
    if not k then return "None" end
    if typeof(k) == "EnumItem" then return k.Name end
    return tostring(k)
end

-- ============================================================
-- WINDOW
-- ============================================================
function UILib.new(cfg)
    cfg = cfg or {}
    local self = setmetatable({
        _tabs = {},
        _active = nil,
        _widgets = {},
        _configName = cfg.ConfigName or "default",
        _autoSave = cfg.AutoSave ~= false,
        _unload = {},
        _overlays = {},
    }, UILib)

    self._gui = Instance.new("ScreenGui")
    self._gui.Name = cfg.Name or "UILib"
    self._gui.ResetOnSpawn = false
    self._gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._gui.DisplayOrder = 999
    self._gui.IgnoreGuiInset = true
    self._gui.Parent = guiParent()

    -- Toggle keybind
    local toggleKey = toKeyCode(cfg.ToggleKey) or Enum.KeyCode.RightShift
    UserInputServiceToggle = UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode == toggleKey then
            self._gui.Enabled = not self._gui.Enabled
        end
    end)
    table.insert(self._unload, UserInputServiceToggle)

    -- Sidebar
    local sb = N("Frame", {
        Size = UDim2.new(0, SW, 0, 0),
        Position = cfg.Position or UDim2.new(0.15, 0, 0.15, 0),
        BackgroundColor3 = T.SB,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
    }, self._gui)
    C(5, sb); ST(T.LINE, 1, sb)
    drag(sb)
    self._sb = sb

    -- Eye header
    local eyeF = N("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
    }, sb)
    N("ImageLabel", {
        Size = UDim2.new(0, 34, 0, 34),
        Position = UDim2.new(0.5, -17, 0.5, -17),
        BackgroundTransparency = 1,
        Image = "rbxassetid://" .. (cfg.EyeIcon or "12556702945"),
        ScaleType = Enum.ScaleType.Fit,
    }, eyeF)
    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.LINE,
        BorderSizePixel = 0,
    }, eyeF)

    -- Tab list
    local tabC = N("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, sb)
    N("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0)}, tabC)
    self._tabC = tabC

    -- Rescan footer
    local rescanW = N("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
    }, sb)
    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T.LINE,
        BorderSizePixel = 0,
    }, rescanW)
    local rescan = N("TextButton", {
        Size = UDim2.new(1, -18, 0, 24),
        Position = UDim2.new(0, 9, 0, 9),
        BackgroundColor3 = T.INP,
        BorderSizePixel = 0,
        Text = "Rescan",
        TextColor3 = T.TXT,
        TextSize = 11,
        Font = Enum.Font.Gotham,
    }, rescanW)
    C(4, rescan); ST(T.INPB, 1, rescan)
    self._rescan = rescan

    -- Panel (child of sidebar so it moves when dragged)
    local panel = N("Frame", {
        Size = UDim2.new(0, PW, 0, 0),
        Position = UDim2.new(0, SW + 6, 0, 0),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
        Visible = false,
    }, sb)
    C(5, panel); ST(T.LINE, 1, panel)
    self._panel = panel

    -- Panel header
    local phdr = N("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
    }, panel)
    C(5, phdr)
    N("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
    }, phdr)

    self._panelTitle = N("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.TXTH,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
    }, phdr)

    -- Accent dot (closes panel)
    local dot = N("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -16, 0.5, -5),
        BackgroundColor3 = T.ACC,
        BorderSizePixel = 0,
    }, phdr)
    C(100, dot)

    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.ACC,
        BorderSizePixel = 0,
    }, phdr)

    dot.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            if self._active then
                self._active._btn:Fire() -- sim click
            end
        end
    end)

    -- Panel content holder
    local holder = N("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 29),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
    }, panel)
    N("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, holder)
    self._contentHolder = holder

    -- Watermark
    self:SetWatermark(cfg.Watermark or "UILib | dx9ware")

    return self
end

-- ============================================================
-- NOTIFY
-- ============================================================
function UILib:Notify(text, duration)
    duration = duration or 3
    if not self._notifyHolder then
        local holder = N("Frame", {
            Size = UDim2.new(0, 260, 0, 0),
            Position = UDim2.new(1, -280, 1, -50),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
        }, self._gui)
        local layout = N("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }, holder)
        self._notifyHolder = holder
        self._notifyLayout = layout
    end
    local notif = N("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
    }, self._notifyHolder)
    C(5, notif); ST(T.ACC, 1, notif)
    N("Frame", {
        Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 0, 0.2, 0),
        BackgroundColor3 = T.ACC,
        BorderSizePixel = 0,
    }, notif)
    N("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(text),
        TextColor3 = T.TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 11,
        Font = Enum.Font.Gotham,
    }, notif)
    task.delay(duration, function()
        if notif and notif.Parent then
            tw(notif, {BackgroundTransparency = 1}, 0.25)
            task.wait(0.3)
            if notif and notif.Parent then notif:Destroy() end
        end
    end)
end

-- ============================================================
-- WATERMARK
-- ============================================================
function UILib:SetWatermark(text)
    if not self._wm then
        self._wm = N("TextLabel", {
            Size = UDim2.new(0, 220, 0, 22),
            Position = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = T.BG,
            BorderSizePixel = 0,
            Text = text or "UILib",
            TextColor3 = T.TXT,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 500,
        }, self._gui)
        C(3, self._wm); ST(T.ACC, 1, self._wm)
    else
        self._wm.Text = text
        self._wm.Visible = true
    end
end

function UILib:HideWatermark()
    if self._wm then self._wm.Visible = false end
end

-- ============================================================
-- TAB
-- ============================================================
local Tab = {}; Tab.__index = Tab
local Sec = {}; Sec.__index = Sec

function UILib:AddTab(name, icon)
    local tab = setmetatable({
        _secs = {}, _lib = self, _name = name, _open = false, _icon = icon
    }, Tab)

    local btn = N("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = T.SB,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, self._tabC)

    if icon then
        N("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = icon,
            TextColor3 = T.TXT2,
            TextSize = 13,
            Font = Enum.Font.Gotham,
        }, btn)
    end

    local lbl = N("TextLabel", {
        Size = UDim2.new(1, -44, 1, 0),
        Position = UDim2.new(0, icon and 30 or 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = T.TXT2,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12,
        Font = Enum.Font.Gotham,
    }, btn)

    local chev = N("TextLabel", {
        Size = UDim2.new(0, 16, 1, 0),
        Position = UDim2.new(1, -18, 0, 0),
        BackgroundTransparency = 1,
        Text = "›",
        TextColor3 = T.TXT2,
        TextSize = 17,
        Font = Enum.Font.GothamBold,
    }, btn)

    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.LINE,
        BorderSizePixel = 0,
    }, btn)

    btn.MouseEnter:Connect(function()
        if not tab._open then tw(btn, {BackgroundColor3 = T.ACCH}) end
    end)
    btn.MouseLeave:Connect(function()
        if not tab._open then tw(btn, {BackgroundColor3 = T.SB}) end
    end)

    -- Content container for this tab (inside shared panel holder)
    local content = N("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ClipsDescendants = false,
    }, self._contentHolder)
    N("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0)}, content)

    local function activate()
        if tab._open then
            tab._open = false
            self._panel.Visible = false
            content.Visible = false
            tw(btn, {BackgroundColor3 = T.SB})
            lbl.TextColor3 = T.TXT2
            chev.TextColor3 = T.TXT2
            self._active = nil
            return
        end
        if self._active then
            self._active._open = false
            self._active._content.Visible = false
            tw(self._active._btn, {BackgroundColor3 = T.SB})
            self._active._lbl.TextColor3 = T.TXT2
            self._active._chev.TextColor3 = T.TXT2
        end
        tab._open = true
        self._active = tab
        tw(btn, {BackgroundColor3 = T.ACCA})
        lbl.TextColor3 = T.WHITE
        chev.TextColor3 = T.WHITE
        self._panelTitle.Text = name
        self._panel.Visible = true
        content.Visible = true
    end

    local click = btn.MouseButton1Click:Connect(activate)
    tab._btn = btn
    tab._lbl = lbl
    tab._chev = chev
    tab._content = content
    tab._activate = activate

    table.insert(self._tabs, tab)
    return tab
end

-- ============================================================
-- SECTION
-- ============================================================
function Tab:AddSection(name)
    local sec = setmetatable({
        _collapsed = false,
        _tab = self,
        _lib = self._lib,
        _path = self._name .. "." .. name,
    }, Sec)

    local wrap = N("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self._content)

    local hdr = N("TextButton", {
        Size = UDim2.new(1, 0, 0, SH),
        BackgroundColor3 = T.BG,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, wrap)

    local arrow = N("TextLabel", {
        Size = UDim2.new(0, 14, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = T.ACC2,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
    }, hdr)

    N("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = T.TXTH,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
    }, hdr)

    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.LINEP,
        BorderSizePixel = 0,
    }, hdr)

    local body = N("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, SH),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, wrap)
    N("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0)}, body)

    hdr.MouseButton1Click:Connect(function()
        sec._collapsed = not sec._collapsed
        body.Visible = not sec._collapsed
        arrow.Text = sec._collapsed and "▶" or "▼"
    end)

    sec._body = body
    sec._wrapper = wrap
    return sec
end

-- ============================================================
-- ROW HELPERS
-- ============================================================
local function mkRow(parent, h)
    local f = N("Frame", {
        Size = UDim2.new(1, 0, 0, h or RH),
        BackgroundColor3 = T.ROW,
        BorderSizePixel = 0,
    }, parent)
    f.MouseEnter:Connect(function() tw(f, {BackgroundColor3 = T.ROWH}) end)
    f.MouseLeave:Connect(function() tw(f, {BackgroundColor3 = T.ROW}) end)
    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.LINE,
        BorderSizePixel = 0,
    }, f)
    return f
end

local function rowLabel(f, text)
    N("TextLabel", {
        Size = UDim2.new(0.65, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T.TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 11,
        Font = Enum.Font.Gotham,
    }, f)
end

-- Register widget for config save/load
local function register(sec, name, getter, setter)
    local key = sec._path .. "." .. name
    sec._lib._widgets[key] = {Get = getter, Set = setter}
    sec._lib:_autoSaveDebounced()
end

-- ============================================================
-- TOGGLE
-- ============================================================
function Sec:AddToggle(name, default, cb)
    local val = default or false
    local f = mkRow(self._body)
    rowLabel(f, name)

    local track = N("Frame", {
        Size = UDim2.new(0, 32, 0, 16),
        Position = UDim2.new(1, -38, 0.5, -8),
        BackgroundColor3 = val and T.ACC or T.TOFF,
        BorderSizePixel = 0,
    }, f)
    C(100, track); ST(T.TOFFB, 1, track)

    local knob = N("Frame", {
        Size = UDim2.new(0, 11, 0, 11),
        Position = val and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,2,0.5,-5),
        BackgroundColor3 = T.WHITE,
        BorderSizePixel = 0,
    }, track)
    C(100, knob)

    local function apply(v, fire)
        val = v
        tw(track, {BackgroundColor3 = v and T.ACC or T.TOFF})
        tw(knob, {Position = v and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,2,0.5,-5)})
        if fire and cb then task.spawn(cb, v) end
    end

    N("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, f).MouseButton1Click:Connect(function()
        apply(not val, true)
        self._lib:_autoSaveDebounced()
    end)

    local t = {}
    function t:Get() return val end
    function t:Set(v) apply(v, true) end
    register(self, name, function() return val end, function(v) apply(v, true) end)
    return t
end

-- ============================================================
-- KEYBIND
-- ============================================================
function Sec:AddKeybind(name, default, cb)
    local key = toKeyCode(default)
    local listening = false
    local f = mkRow(self._body)
    rowLabel(f, name)

    local kbtn = N("TextButton", {
        Size = UDim2.new(0, 62, 0, 16),
        Position = UDim2.new(1, -66, 0.5, -8),
        BackgroundColor3 = T.INP,
        BorderSizePixel = 0,
        Text = "[" .. keyName(key) .. "]",
        TextColor3 = T.TXT2,
        TextSize = 10,
        Font = Enum.Font.Gotham,
    }, f)
    C(3, kbtn); ST(T.INPB, 1, kbtn)

    kbtn.MouseButton1Click:Connect(function()
        listening = true
        kbtn.Text = "[...]"
        kbtn.TextColor3 = T.ACC2
    end)

    local conn = UIS.InputBegan:Connect(function(i)
        if not listening then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            key = i.KeyCode
            kbtn.Text = "[" .. keyName(key) .. "]"
            kbtn.TextColor3 = T.TXT2
            if cb then task.spawn(cb, key) end
            self._lib:_autoSaveDebounced()
        elseif i.UserInputType == Enum.UserInputType.MouseButton3 then
            listening = false
            key = Enum.UserInputType.MouseButton3
            kbtn.Text = "[MMB]"
            kbtn.TextColor3 = T.TXT2
            if cb then task.spawn(cb, key) end
            self._lib:_autoSaveDebounced()
        end
    end)

    local kb = {}
    function kb:Get() return key end
    function kb:Set(v)
        key = toKeyCode(v)
        kbtn.Text = "[" .. keyName(key) .. "]"
        if cb then task.spawn(cb, key) end
    end
    function kb:Clear()
        key = nil
        kbtn.Text = "[None]"
        kbtn.TextColor3 = T.TXT2
        if cb then task.spawn(cb, nil) end
    end
    register(self, name, function() return key and keyName(key) end, function(v) kb:Set(v) end)
    return kb
end

-- ============================================================
-- SLIDER
-- ============================================================
function Sec:AddSlider(name, min, max, default, cb, rounding)
    local val = math.clamp(default or min, min, max)
    local drag_ = false

    -- Auto-detect rounding
    if rounding == nil then
        local hasFrac = (default and default % 1 ~= 0) or (min % 1 ~= 0) or (max % 1 ~= 0)
        rounding = hasFrac and 2 or 0
    end
    local mult = 10 ^ rounding
    local function round(x) return math.floor(x * mult + 0.5) / mult end
    local function fmt(v)
        if rounding == 0 then return tostring(math.floor(v + 0.5)) end
        return string.format("%." .. rounding .. "f", v)
    end

    local f = mkRow(self._body, 36)

    N("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 18),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = T.TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 11,
        Font = Enum.Font.Gotham,
    }, f)

    local vlbl = N("TextLabel", {
        Size = UDim2.new(0.3, -8, 0, 18),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = fmt(val),
        TextColor3 = T.TXT2,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 10,
        Font = Enum.Font.Gotham,
    }, f)

    local track = N("Frame", {
        Size = UDim2.new(1, -16, 0, 3),
        Position = UDim2.new(0, 8, 0, 25),
        BackgroundColor3 = T.SLB,
        BorderSizePixel = 0,
    }, f)
    C(100, track)

    local r0 = (val - min) / (max - min)
    local fill = N("Frame", {
        Size = UDim2.new(r0, 0, 1, 0),
        BackgroundColor3 = T.ACC,
        BorderSizePixel = 0,
    }, track)
    C(100, fill)

    local knob = N("Frame", {
        Size = UDim2.new(0, 7, 0, 7),
        Position = UDim2.new(r0, -3, 0.5, -3),
        BackgroundColor3 = T.WHITE,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, track)
    C(100, knob)

    local function apply(x, fire)
        local rr = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = round(min + rr * (max - min))
        fill.Size = UDim2.new(rr, 0, 1, 0)
        knob.Position = UDim2.new(rr, -3, 0.5, -3)
        vlbl.Text = fmt(val)
        if fire and cb then task.spawn(cb, val) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag_ = true; apply(i.Position.X, true)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag_ and i.UserInputType == Enum.UserInputType.MouseMovement then
            apply(i.Position.X, true)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            if drag_ then self._lib:_autoSaveDebounced() end
            drag_ = false
        end
    end)

    local s = {}
    function s:Get() return val end
    function s:Set(v)
        val = math.clamp(round(v), min, max)
        local rr = (val - min) / (max - min)
        fill.Size = UDim2.new(rr, 0, 1, 0)
        knob.Position = UDim2.new(rr, -3, 0.5, -3)
        vlbl.Text = fmt(val)
        if cb then task.spawn(cb, val) end
    end
    register(self, name, function() return val end, function(v) s:Set(v) end)
    return s
end

-- ============================================================
-- DROPDOWN (single-select)
-- ============================================================
function Sec:AddDropdown(name, opts, default, cb)
    local val = default or opts[1]
    local f = mkRow(self._body)
    rowLabel(f, name)

    local dbtn = N("TextButton", {
        Size = UDim2.new(0, 70, 0, 16),
        Position = UDim2.new(1, -74, 0.5, -8),
        BackgroundColor3 = T.INP,
        BorderSizePixel = 0,
        Text = tostring(val or ""),
        TextColor3 = T.TXT,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        ClipsDescendants = true,
    }, f)
    C(3, dbtn); ST(T.INPB, 1, dbtn)

    local open = false
    local overlay, clickAway

    local function closeOverlay()
        if overlay then overlay:Destroy(); overlay = nil end
        if clickAway then clickAway:Destroy(); clickAway = nil end
        open = false
    end

    local function openOverlay()
        if open then closeOverlay(); return end
        open = true
        -- Click-away
        clickAway = N("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 998,
        }, self._lib._gui)
        clickAway.MouseButton1Click:Connect(closeOverlay)

        local listH = math.min(#opts, 7) * 20
        local ax = dbtn.AbsolutePosition
        local ay = dbtn.AbsolutePosition.Y + dbtn.AbsoluteSize.Y + 2

        -- Check bottom overflow
        local vpH = workspace.CurrentCamera.ViewportSize.Y
        if ay + listH > vpH - 10 then
            ay = dbtn.AbsolutePosition.Y - listH - 2
        end

        overlay = N("Frame", {
            Size = UDim2.new(0, math.max(90, dbtn.AbsoluteSize.X), 0, listH),
            Position = UDim2.new(0, ax.X, 0, ay),
            BackgroundColor3 = T.DROP,
            BorderSizePixel = 0,
            ZIndex = 999,
        }, self._lib._gui)
        C(3, overlay); ST(T.INPB, 1, overlay)

        local scroll = N("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.ACC,
            CanvasSize = UDim2.new(0, 0, 0, #opts * 20),
            ZIndex = 999,
        }, overlay)
        N("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

        for _, opt in ipairs(opts) do
            local ob = N("TextButton", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = opt,
                TextColor3 = T.TXT2,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                ZIndex = 999,
            }, scroll)
            N("UIPadding", {PaddingLeft = UDim.new(0, 7)}, ob)
            ob.MouseEnter:Connect(function()
                ob.TextColor3 = T.TXT
                tw(ob, {BackgroundColor3 = T.ROWH, BackgroundTransparency = 0})
            end)
            ob.MouseLeave:Connect(function()
                ob.TextColor3 = T.TXT2
                tw(ob, {BackgroundTransparency = 1})
            end)
            ob.MouseButton1Click:Connect(function()
                val = opt
                dbtn.Text = opt
                closeOverlay()
                if cb then task.spawn(cb, val) end
                self._lib:_autoSaveDebounced()
            end)
        end
    end

    dbtn.MouseButton1Click:Connect(openOverlay)

    local dd = {}
    function dd:Get() return val end
    function dd:Set(v)
        val = v
        dbtn.Text = tostring(v or "")
        if cb then task.spawn(cb, val) end
    end
    function dd:SetOptions(newOpts, defaultIdx)
        -- simple re-creation not supported; update list values
        opts = newOpts
    end
    register(self, name, function() return val end, function(v) dd:Set(v) end)
    return dd
end

-- ============================================================
-- MULTI DROPDOWN
-- ============================================================
function Sec:AddMultiDropdown(name, opts, default, cb)
    local selected = {}
    if type(default) == "table" then
        for _, v in ipairs(default) do selected[v] = true end
    end

    local f = mkRow(self._body)
    rowLabel(f, name)

    local function countSel()
        local c = 0
        for _ in pairs(selected) do c = c + 1 end
        return c
    end

    local dbtn = N("TextButton", {
        Size = UDim2.new(0, 70, 0, 16),
        Position = UDim2.new(1, -74, 0.5, -8),
        BackgroundColor3 = T.INP,
        BorderSizePixel = 0,
        Text = countSel() .. " selected",
        TextColor3 = T.TXT,
        TextSize = 10,
        Font = Enum.Font.Gotham,
    }, f)
    C(3, dbtn); ST(T.INPB, 1, dbtn)

    local open = false
    local overlay, clickAway

    local function closeOverlay()
        if overlay then overlay:Destroy(); overlay = nil end
        if clickAway then clickAway:Destroy(); clickAway = nil end
        open = false
    end

    local function getList()
        local t = {}
        for _, v in ipairs(opts) do if selected[v] then table.insert(t, v) end end
        return t
    end

    local function openOverlay()
        if open then closeOverlay(); return end
        open = true
        clickAway = N("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 998,
        }, self._lib._gui)
        clickAway.MouseButton1Click:Connect(closeOverlay)

        local listH = math.min(#opts, 7) * 20
        local ax = dbtn.AbsolutePosition
        local ay = dbtn.AbsolutePosition.Y + dbtn.AbsoluteSize.Y + 2
        local vpH = workspace.CurrentCamera.ViewportSize.Y
        if ay + listH > vpH - 10 then ay = dbtn.AbsolutePosition.Y - listH - 2 end

        overlay = N("Frame", {
            Size = UDim2.new(0, math.max(110, dbtn.AbsoluteSize.X), 0, listH),
            Position = UDim2.new(0, ax.X - 40, 0, ay),
            BackgroundColor3 = T.DROP,
            BorderSizePixel = 0,
            ZIndex = 999,
        }, self._lib._gui)
        C(3, overlay); ST(T.INPB, 1, overlay)

        local scroll = N("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.ACC,
            CanvasSize = UDim2.new(0, 0, 0, #opts * 20),
            ZIndex = 999,
        }, overlay)
        N("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

        for _, opt in ipairs(opts) do
            local isSel = selected[opt]
            local ob = N("TextButton", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = (isSel and "✓ " or "   ") .. opt,
                TextColor3 = isSel and T.ACC2 or T.TXT2,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                ZIndex = 999,
            }, scroll)
            N("UIPadding", {PaddingLeft = UDim.new(0, 7)}, ob)
            ob.MouseEnter:Connect(function()
                ob.TextColor3 = T.TXT
                tw(ob, {BackgroundColor3 = T.ROWH, BackgroundTransparency = 0})
            end)
            ob.MouseLeave:Connect(function()
                ob.TextColor3 = selected[opt] and T.ACC2 or T.TXT2
                tw(ob, {BackgroundTransparency = 1})
            end)
            ob.MouseButton1Click:Connect(function()
                selected[opt] = not selected[opt]
                if not selected[opt] then selected[opt] = nil end
                ob.Text = (selected[opt] and "✓ " or "   ") .. opt
                ob.TextColor3 = selected[opt] and T.ACC2 or T.TXT2
                dbtn.Text = countSel() .. " selected"
                if cb then task.spawn(cb, getList()) end
                self._lib:_autoSaveDebounced()
            end)
        end
    end

    dbtn.MouseButton1Click:Connect(openOverlay)

    local dd = {}
    function dd:Get() return getList() end
    function dd:Set(t)
        selected = {}
        for _, v in ipairs(t or {}) do selected[v] = true end
        dbtn.Text = countSel() .. " selected"
        if cb then task.spawn(cb, getList()) end
    end
    register(self, name, function() return getList() end, function(v) dd:Set(v) end)
    return dd
end

-- ============================================================
-- BUTTON
-- ============================================================
function Sec:AddButton(name, cb)
    local f = mkRow(self._body, 28)
    local btn = N("TextButton", {
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 8, 0.5, -9),
        BackgroundColor3 = T.INP,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = T.TXT,
        TextSize = 11,
        Font = Enum.Font.Gotham,
    }, f)
    C(3, btn); ST(T.INPB, 1, btn)
    btn.MouseButton1Click:Connect(function()
        tw(btn, {BackgroundColor3 = T.ACC}, 0.07)
        task.delay(0.15, function()
            if btn and btn.Parent then tw(btn, {BackgroundColor3 = T.INP}, 0.1) end
        end)
        if cb then task.spawn(cb) end
    end)
end

-- ============================================================
-- LABEL (returns handle)
-- ============================================================
function Sec:AddLabel(text)
    local f = N("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundColor3 = T.ROW,
        BorderSizePixel = 0,
    }, self._body)
    local lbl = N("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T.TXT2,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 10,
        Font = Enum.Font.Gotham,
    }, f)
    return {
        SetText = function(_, t) lbl.Text = t end,
        GetText = function() return lbl.Text end,
        _label = lbl,
    }
end

-- ============================================================
-- COLOR PICKER
-- ============================================================
function Sec:AddColorPicker(name, defaultColor, defaultTransp, cb)
    local color = defaultColor or Color3.new(1,1,1)
    local transp = defaultTransp or 0
    local f = mkRow(self._body)
    rowLabel(f, name)

    local preview = N("Frame", {
        Size = UDim2.new(0, 32, 0, 14),
        Position = UDim2.new(1, -40, 0.5, -7),
        BackgroundColor3 = color,
        BackgroundTransparency = transp,
        BorderSizePixel = 0,
    }, f)
    C(3, preview); ST(T.INPB, 1, preview)

    local overlay, clickAway, open = nil, nil, false

    local function closePicker()
        if overlay then overlay:Destroy(); overlay = nil end
        if clickAway then clickAway:Destroy(); clickAway = nil end
        open = false
    end

    local function apply(c, t, fire)
        color = c
        if t ~= nil then transp = t end
        preview.BackgroundColor3 = color
        preview.BackgroundTransparency = transp
        if fire and cb then task.spawn(cb, color, transp) end
    end

    local function openPicker()
        if open then closePicker(); return end
        open = true

        clickAway = N("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 998,
        }, self._lib._gui)
        clickAway.MouseButton1Click:Connect(closePicker)

        local ax = preview.AbsolutePosition
        local ay = preview.AbsolutePosition.Y + preview.AbsoluteSize.Y + 2
        local vpH = workspace.CurrentCamera.ViewportSize.Y
        local panelH = 190
        if ay + panelH > vpH - 10 then ay = preview.AbsolutePosition.Y - panelH - 2 end

        overlay = N("Frame", {
            Size = UDim2.new(0, 190, 0, panelH),
            Position = UDim2.new(0, math.min(ax.X - 100, workspace.CurrentCamera.ViewportSize.X - 200), 0, ay),
            BackgroundColor3 = T.BG,
            BorderSizePixel = 0,
            ZIndex = 999,
        }, self._lib._gui)
        C(5, overlay); ST(T.LINE, 1, overlay)

        -- Live preview
        local livePreview = N("Frame", {
            Size = UDim2.new(1, -16, 0, 24),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = color,
            BackgroundTransparency = transp,
            BorderSizePixel = 0,
            ZIndex = 999,
        }, overlay)
        C(3, livePreview); ST(T.INPB, 1, livePreview)

        local rC = math.floor(color.R * 255)
        local gC = math.floor(color.G * 255)
        local bC = math.floor(color.B * 255)
        local tC = math.floor(transp * 100)

        local function applyAll()
            local c = Color3.fromRGB(rC, gC, bC)
            apply(c, tC / 100, true)
            livePreview.BackgroundColor3 = c
            livePreview.BackgroundTransparency = tC / 100
        end

        local function mkSlider(label, y, mn, mx, init, onCh)
            N("TextLabel", {
                Size = UDim2.new(0.22, 0, 0, 20),
                Position = UDim2.new(0, 8, 0, y),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = T.TXT,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.Gotham,
                ZIndex = 999,
            }, overlay)
            local trk = N("Frame", {
                Size = UDim2.new(0.72, -14, 0, 4),
                Position = UDim2.new(0.26, 0, 0, y + 8),
                BackgroundColor3 = T.SLB,
                BorderSizePixel = 0,
                ZIndex = 999,
            }, overlay)
            C(100, trk)
            local r0 = (init - mn) / (mx - mn)
            local fill = N("Frame", {
                Size = UDim2.new(r0, 0, 1, 0),
                BackgroundColor3 = T.ACC,
                BorderSizePixel = 0,
                ZIndex = 999,
            }, trk)
            C(100, fill)
            local knob = N("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(r0, -4, 0.5, -4),
                BackgroundColor3 = T.WHITE,
                BorderSizePixel = 0,
                ZIndex = 1000,
            }, trk)
            C(100, knob)
            local dragging = false
            local function upd(x)
                local rr = math.clamp((x - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
                local v = math.floor(mn + rr * (mx - mn) + 0.5)
                fill.Size = UDim2.new(rr, 0, 1, 0)
                knob.Position = UDim2.new(rr, -4, 0.5, -4)
                onCh(v)
            end
            trk.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true; upd(i.Position.X)
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    upd(i.Position.X)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    if dragging then self._lib:_autoSaveDebounced() end
                    dragging = false
                end
            end)
        end

        mkSlider("R", 38, 0, 255, rC, function(v) rC = v; applyAll() end)
        mkSlider("G", 60, 0, 255, gC, function(v) gC = v; applyAll() end)
        mkSlider("B", 82, 0, 255, bC, function(v) bC = v; applyAll() end)
        mkSlider("A", 104, 0, 100, tC, function(v) tC = v; applyAll() end)

        -- Hex input
        local hexBox = N("TextBox", {
            Size = UDim2.new(1, -60, 0, 22),
            Position = UDim2.new(0, 8, 1, -32),
            BackgroundColor3 = T.INP,
            BorderSizePixel = 0,
            Text = string.format("#%02X%02X%02X", rC, gC, bC),
            TextColor3 = T.TXT,
            TextSize = 10,
            Font = Enum.Font.Code,
            PlaceholderText = "#RRGGBB",
            PlaceholderColor3 = T.TXT2,
            ClearTextOnFocus = false,
            ZIndex = 999,
        }, overlay)
        C(3, hexBox); ST(T.INPB, 1, hexBox)

        local applyBtn = N("TextButton", {
            Size = UDim2.new(0, 46, 0, 22),
            Position = UDim2.new(1, -52, 1, -32),
            BackgroundColor3 = T.ACC,
            BorderSizePixel = 0,
            Text = "Apply",
            TextColor3 = T.WHITE,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            ZIndex = 999,
        }, overlay)
        C(3, applyBtn)

        applyBtn.MouseButton1Click:Connect(function()
            local hex = hexBox.Text:gsub("#", ""):gsub("%s", "")
            if #hex == 6 then
                local ok, r, g, b = pcall(function()
                    return tonumber(hex:sub(1,2), 16),
                           tonumber(hex:sub(3,4), 16),
                           tonumber(hex:sub(5,6), 16)
                end)
                if ok and r and g and b then
                    rC, gC, bC = r, g, b
                    applyAll()
                end
            end
        end)
    end

    preview.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then openPicker() end
    end)

    local p = {}
    function p:Get() return color, transp end
    function p:Set(c, t) apply(c, t, true) end
    register(self, name, function() return {c = color, t = transp} end, function(v)
        if type(v) == "table" then p:Set(Color3.new(v.c.R or v.c[1] or 0, v.c.G or v.c[2] or 0, v.c.B or v.c[3] or 0), v.t) end
    end)
    return p
end

-- ============================================================
-- INPUT
-- ============================================================
function Sec:AddInput(name, placeholder, default, cb)
    local f = mkRow(self._body)
    rowLabel(f, name)
    local box = N("TextBox", {
        Size = UDim2.new(0, 90, 0, 16),
        Position = UDim2.new(1, -94, 0.5, -8),
        BackgroundColor3 = T.INP,
        BorderSizePixel = 0,
        Text = default or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = T.TXT2,
        TextColor3 = T.TXT,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
    }, f)
    C(3, box); ST(T.INPB, 1, box)
    box.FocusLost:Connect(function()
        if cb then task.spawn(cb, box.Text) end
        self._lib:_autoSaveDebounced()
    end)
    local i = {}
    function i:Get() return box.Text end
    function i:Set(v)
        box.Text = tostring(v or "")
        if cb then task.spawn(cb, box.Text) end
    end
    register(self, name, function() return box.Text end, function(v) i:Set(v) end)
    return i
end

-- ============================================================
-- RESCAN
-- ============================================================
function UILib:OnRescan(cb)
    self._rescan.MouseButton1Click:Connect(cb)
end

-- ============================================================
-- CONFIG SAVE / LOAD
-- ============================================================
local function configDir()
    local dir = "UILibConfigs"
    if isfolder and not isfolder(dir) then pcall(makefolder, dir) end
    return dir
end

function UILib:_autoSaveDebounced()
    if not self._autoSave then return end
    if self._saveTask then task.cancel(self._saveTask) end
    self._saveTask = task.delay(1.5, function() self:SaveConfig(self._configName) end)
end

function UILib:SaveConfig(name)
    name = name or self._configName
    self._configName = name
    local data = {}
    for key, w in pairs(self._widgets) do
        local ok, v = pcall(w.Get)
        if ok and v ~= nil then
            -- Serialize Color3
            if typeof(v) == "Color3" then
                v = {__c3 = {v.R, v.G, v.B}}
            elseif typeof(v) == "EnumItem" then
                v = {__enum = v.Name}
            elseif type(v) == "table" then
                local copy = {}
                for k2, v2 in pairs(v) do
                    if typeof(v2) == "Color3" then
                        copy[k2] = {__c3 = {v2.R, v2.G, v2.B}}
                    elseif typeof(v2) == "EnumItem" then
                        copy[k2] = {__enum = v2.Name}
                    else
                        copy[k2] = v2
                    end
                end
                v = copy
            end
            data[key] = v
        end
    end
    local json = HS:JSONEncode(data)
    pcall(function()
        writefile(configDir() .. "/" .. name .. ".json", json)
    end)
    return true
end

function UILib:LoadConfig(name)
    name = name or self._configName
    self._configName = name
    local path = configDir() .. "/" .. name .. ".json"
    if isfile and not isfile(path) then return false end
    local ok, contents = pcall(function() return readfile(path) end)
    if not ok or not contents then return false end
    local ok2, data = pcall(function() return HS:JSONDecode(contents) end)
    if not ok2 or type(data) ~= "table" then return false end
    -- Restore serialized types
    for key, v in pairs(data) do
        if type(v) == "table" then
            if v.__c3 then
                v = Color3.new(v.__c3[1], v.__c3[2], v.__c3[3])
            elseif v.__enum then
                v = Enum.KeyCode[v.__enum] or Enum.UserInputType[v.__enum] or v
            else
                for k2, v2 in pairs(v) do
                    if type(v2) == "table" and v2.__c3 then
                        v[k2] = Color3.new(v2.__c3[1], v2.__c3[2], v2.__c3[3])
                    elseif type(v2) == "table" and v2.__enum then
                        v[k2] = Enum.KeyCode[v2.__enum] or Enum.UserInputType[v2.__enum] or v2
                    end
                end
            end
        end
        data[key] = v
    end
    for key, v in pairs(data) do
        local w = self._widgets[key]
        if w then pcall(w.Set, v) end
    end
    return true
end

function UILib:DeleteConfig(name)
    local path = configDir() .. "/" .. name .. ".json"
    pcall(function()
        if isfile and isfile(path) then delfile(path) end
    end)
end

function UILib:ListConfigs()
    local list = {}
    pcall(function()
        if listfiles then
            for _, f in ipairs(listfiles(configDir())) do
                local n = f:match("([^/\\]+)%.json$")
                if n then table.insert(list, n) end
            end
        end
    end)
    return list
end

-- ============================================================
-- UNLOAD
-- ============================================================
function UILib:OnUnload(cb)
    table.insert(self._unload, cb)
end

function UILib:Destroy()
    for _, c in ipairs(self._unload) do pcall(c) end
    if self._saveTask then pcall(task.cancel, self._saveTask) end
    pcall(function() self:SaveConfig(self._configName) end)
    pcall(function() self._gui:Destroy() end)
end

-- ============================================================
-- RETURN
-- ============================================================
return UILib
