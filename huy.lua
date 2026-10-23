-- UILib.lua  |  dx9ware 1:1

local UILib = {}
UILib.__index = UILib

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local T = {
    Sidebar     = Color3.fromRGB(16, 16, 16),
    SidebarLine = Color3.fromRGB(30, 30, 30),
    TabNorm     = Color3.fromRGB(16, 16, 16),
    TabAct      = Color3.fromRGB(100, 40, 190),
    TabHov      = Color3.fromRGB(60, 25, 115),
    Panel       = Color3.fromRGB(20, 20, 20),
    PanelHdr    = Color3.fromRGB(20, 20, 20),
    SecHdr      = Color3.fromRGB(20, 20, 20),
    SecHdrLine  = Color3.fromRGB(100, 40, 190),
    RowBg       = Color3.fromRGB(20, 20, 20),
    RowHov      = Color3.fromRGB(28, 28, 28),
    CheckOn     = Color3.fromRGB(100, 40, 190),
    CheckOff    = Color3.fromRGB(35, 35, 35),
    CheckBorder = Color3.fromRGB(70, 70, 70),
    Accent      = Color3.fromRGB(120, 60, 210),
    AccentDot   = Color3.fromRGB(110, 50, 200),
    Text        = Color3.fromRGB(220, 220, 220),
    TextDim     = Color3.fromRGB(130, 130, 130),
    TextHdr     = Color3.fromRGB(200, 200, 200),
    KbBg        = Color3.fromRGB(28, 28, 28),
    KbBorder    = Color3.fromRGB(55, 55, 55),
    Sep         = Color3.fromRGB(32, 32, 32),
    SliderFill  = Color3.fromRGB(100, 40, 190),
    SliderBg    = Color3.fromRGB(35, 35, 35),
    BtnBg       = Color3.fromRGB(28, 28, 28),
    BtnBorder   = Color3.fromRGB(55, 55, 55),
    DropBg      = Color3.fromRGB(22, 22, 22),
}

local SIDEBAR_W = 155
local PANEL_W   = 210
local ROW_H     = 24
local SEC_H     = 26

local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.1, Enum.EasingStyle.Quad), p):Play()
end

local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(r, p)
    return new("UICorner", {CornerRadius = UDim.new(0, r)}, p)
end

local function stroke(c, th, p)
    local s = Instance.new("UIStroke")
    s.Color = c; s.Thickness = th or 1
    s.Parent = p
    return s
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------

function UILib.new(cfg)
    cfg = cfg or {}
    local self = setmetatable({_tabs = {}, _active = nil}, UILib)

    local gui = Instance.new("ScreenGui")
    gui.Name           = cfg.Name or "UILib"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder   = 999
    gui.Enabled        = true
    gui.Parent         = (gethui and gethui()) or game:GetService("CoreGui")

    -- toggle keybind
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RShift
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == toggleKey then
            gui.Enabled = not gui.Enabled
        end
    end)

    -- sidebar only visible initially, panel expands to the right
    local sidebar = new("Frame", {
        Size             = UDim2.new(0, SIDEBAR_W, 0, 0),
        Position         = UDim2.new(0.3, 0, 0.2, 0),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
    }, gui)
    corner(6, sidebar)
    stroke(T.SidebarLine, 1, sidebar)

    -- drag on sidebar
    do
        local drg, ds, sp
        sidebar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                drg = true; ds = i.Position; sp = sidebar.Position
            end
        end)
        sidebar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drg = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drg and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - ds
                sidebar.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                             sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end

    -- eye icon
    local iconFrame = new("Frame", {
        Size                 = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1,
    }, sidebar)
    new("ImageLabel", {
        Size                 = UDim2.new(0, 40, 0, 40),
        Position             = UDim2.new(0.5, -20, 0.5, -20),
        BackgroundTransparency = 1,
        Image                = "rbxassetid://" .. (cfg.EyeIcon or "12556702945"),
        ImageColor3          = Color3.new(1,1,1),
        ScaleType            = Enum.ScaleType.Fit,
    }, iconFrame)

    -- divider under icon
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 64),
        BackgroundColor3 = T.SidebarLine,
        BorderSizePixel  = 0,
    }, sidebar)

    -- tab list
    local tabList = new("Frame", {
        Size          = UDim2.new(1, 0, 0, 0),
        Position      = UDim2.new(0, 0, 0, 65),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, sidebar)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0)}, tabList)

    -- rescan
    local rescanArea = new("Frame", {
        Size                 = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    }, sidebar)
    -- will be repositioned via layout below
    -- actually use a wrapper frame with all in UIListLayout
    -- rebuild: icon + divider + tabs + rescan all in one list
    -- simpler: manual position via AutomaticSize parent

    -- footer divider
    local footerDiv = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T.SidebarLine,
        BorderSizePixel  = 0,
    }, sidebar)

    local rescan = new("TextButton", {
        Size             = UDim2.new(1, -20, 0, 28),
        Position         = UDim2.new(0, 10, 0, 8),
        BackgroundColor3 = T.KbBg,
        BorderSizePixel  = 0,
        Text             = "Rescan",
        TextColor3       = T.Text,
        TextSize         = 12,
        Font             = Enum.Font.Gotham,
    }, new("Frame", {
        Size                 = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    }, sidebar))
    corner(4, rescan)
    stroke(T.KbBorder, 1, rescan)

    -- panel (appears to the right of sidebar)
    local panel = new("Frame", {
        Size             = UDim2.new(0, PANEL_W, 0, 0),
        Position         = UDim2.new(0, SIDEBAR_W + 6, 0, 0),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Visible          = false,
    }, sidebar)
    corner(6, panel)
    stroke(T.SidebarLine, 1, panel)

    -- panel header
    local panelHdr = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.PanelHdr,
        BorderSizePixel  = 0,
    }, panel)
    corner(6, panelHdr)
    -- bottom square corners
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 6),
        Position         = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = T.PanelHdr,
        BorderSizePixel  = 0,
    }, panelHdr)

    local panelTitle = new("TextLabel", {
        Size                 = UDim2.new(1, -36, 1, 0),
        Position             = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text                 = "",
        TextColor3           = T.TextHdr,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextSize             = 13,
        Font                 = Enum.Font.GothamBold,
    }, panelHdr)

    -- purple dot top right
    local dot = new("Frame", {
        Size             = UDim2.new(0, 10, 0, 10),
        Position         = UDim2.new(1, -18, 0.5, -5),
        BackgroundColor3 = T.AccentDot,
        BorderSizePixel  = 0,
    }, panelHdr)
    corner(100, dot)

    -- purple line under panel header
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
    }, panelHdr)

    -- panel scroll content
    local panelScroll = new("ScrollingFrame", {
        Size               = UDim2.new(1, 0, 0, 400),
        Position           = UDim2.new(0, 0, 0, 33),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize         = UDim2.new(0, 0, 0, 0),
        AutomaticSize      = Enum.AutomaticSize.Y,
    }, panel)
    local pLayout = new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 0),
    }, panelScroll)
    new("UIPadding", {
        PaddingTop    = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 6),
    }, panelScroll)
    pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        panelScroll.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 10)
    end)

    self._gui        = gui
    self._sidebar    = sidebar
    self._tabList    = tabList
    self._panel      = panel
    self._panelTitle = panelTitle
    self._panelScroll = panelScroll
    self._rescan     = rescan

    return self
end

function UILib:OnRescan(cb)
    self._rescan.MouseButton1Click:Connect(cb)
end

------------------------------------------------------------------------
-- Tab
------------------------------------------------------------------------

local Tab = {}; Tab.__index = Tab
local Sec = {}; Sec.__index = Sec

function UILib:AddTab(name, icon)
    local tab = setmetatable({_secs = {}, _lib = self, _frames = {}}, Tab)

    local btn = new("TextButton", {
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = T.TabNorm,
        BorderSizePixel  = 0,
        Text             = "",
        AutoButtonColor  = false,
    }, self._tabList)

    -- icon
    if icon then
        new("TextLabel", {
            Size                 = UDim2.new(0, 22, 1, 0),
            Position             = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text                 = icon,
            TextColor3           = T.TextDim,
            TextSize             = 13,
            Font                 = Enum.Font.Gotham,
        }, btn)
    end

    local lbl = new("TextLabel", {
        Size                 = UDim2.new(1, -55, 1, 0),
        Position             = UDim2.new(0, icon and 34 or 12, 0, 0),
        BackgroundTransparency = 1,
        Text                 = name,
        TextColor3           = T.TextDim,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextSize             = 12,
        Font                 = Enum.Font.Gotham,
    }, btn)

    -- ">" chevron
    local chev = new("TextLabel", {
        Size                 = UDim2.new(0, 14, 1, 0),
        Position             = UDim2.new(1, -18, 0, 0),
        BackgroundTransparency = 1,
        Text                 = "›",
        TextColor3           = T.TextDim,
        TextSize             = 16,
        Font                 = Enum.Font.GothamBold,
    }, btn)

    btn.MouseEnter:Connect(function()
        if self._active ~= tab then
            tw(btn, {BackgroundColor3 = T.TabHov})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._active ~= tab then
            tw(btn, {BackgroundColor3 = T.TabNorm})
        end
    end)

    btn.MouseButton1Click:Connect(function()
        self:_activate(tab)
    end)

    tab._btn  = btn
    tab._lbl  = lbl
    tab._chev = chev
    tab._name = name

    table.insert(self._tabs, tab)
    return tab
end

function UILib:_activate(tab)
    if self._active == tab then
        -- toggle close
        self._active = nil
        self._panel.Visible = false
        tw(tab._btn, {BackgroundColor3 = T.TabNorm})
        tab._lbl.TextColor3 = T.TextDim
        tab._chev.TextColor3 = T.TextDim
        return
    end

    if self._active then
        tw(self._active._btn, {BackgroundColor3 = T.TabNorm})
        self._active._lbl.TextColor3  = T.TextDim
        self._active._chev.TextColor3 = T.TextDim
        -- hide old sections
        for _, f in ipairs(self._active._frames) do f.Visible = false end
    end

    self._active = tab
    tw(tab._btn, {BackgroundColor3 = T.TabAct})
    tab._lbl.TextColor3  = Color3.new(1,1,1)
    tab._chev.TextColor3 = Color3.new(1,1,1)

    self._panelTitle.Text = tab._name
    self._panel.Visible   = true

    -- show this tab's sections
    for _, f in ipairs(tab._frames) do f.Visible = true end
end

------------------------------------------------------------------------
-- Section
------------------------------------------------------------------------

function Tab:AddSection(name)
    local sec = setmetatable({_collapsed = false, _tab = self}, Sec)

    local wrapper = new("Frame", {
        Size          = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible       = self._lib._active == self,
    }, self._lib._panelScroll)
    table.insert(self._frames, wrapper)

    -- section header row
    local hdr = new("TextButton", {
        Size             = UDim2.new(1, 0, 0, SEC_H),
        BackgroundColor3 = T.SecHdr,
        BorderSizePixel  = 0,
        Text             = "",
        AutoButtonColor  = false,
    }, wrapper)

    -- left accent bar
    new("Frame", {
        Size             = UDim2.new(0, 2, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.25, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
    }, hdr)

    local arrow = new("TextLabel", {
        Size                 = UDim2.new(0, 16, 1, 0),
        Position             = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text                 = "▼",
        TextColor3           = T.Accent,
        TextSize             = 8,
        Font                 = Enum.Font.GothamBold,
    }, hdr)

    new("TextLabel", {
        Size                 = UDim2.new(1, -22, 1, 0),
        Position             = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text                 = name,
        TextColor3           = T.TextHdr,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextSize             = 11,
        Font                 = Enum.Font.GothamBold,
    }, hdr)

    -- bottom line under header
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Sep,
        BorderSizePixel  = 0,
    }, hdr)

    -- body
    local body = new("Frame", {
        Size          = UDim2.new(1, 0, 0, 0),
        Position      = UDim2.new(0, 0, 0, SEC_H),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, wrapper)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0)}, body)

    hdr.MouseButton1Click:Connect(function()
        sec._collapsed = not sec._collapsed
        body.Visible   = not sec._collapsed
        arrow.Text     = sec._collapsed and "▶" or "▼"
    end)

    sec._body    = body
    sec._wrapper = wrapper
    return sec
end

------------------------------------------------------------------------
-- Row helper
------------------------------------------------------------------------

local function mkRow(parent)
    local f = new("Frame", {
        Size             = UDim2.new(1, 0, 0, ROW_H),
        BackgroundColor3 = T.RowBg,
        BorderSizePixel  = 0,
    }, parent)
    -- hover
    f.MouseEnter:Connect(function() tw(f, {BackgroundColor3 = T.RowHov}) end)
    f.MouseLeave:Connect(function() tw(f, {BackgroundColor3 = T.RowBg}) end)

    -- bottom sep
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Sep,
        BorderSizePixel  = 0,
    }, f)
    return f
end

local function addLabel(f, text)
    new("TextLabel", {
        Size                 = UDim2.new(0.62, 0, 1, 0),
        Position             = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text                 = text,
        TextColor3           = T.Text,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextSize             = 11,
        Font                 = Enum.Font.Gotham,
    }, f)
end

------------------------------------------------------------------------
-- Toggle
------------------------------------------------------------------------

function Sec:AddToggle(name, default, cb)
    local val = default or false
    local f   = mkRow(self._body)
    addLabel(f, name)

    local box = new("Frame", {
        Size             = UDim2.new(0, 14, 0, 14),
        Position         = UDim2.new(1, -20, 0.5, -7),
        BackgroundColor3 = val and T.CheckOn or T.CheckOff,
        BorderSizePixel  = 0,
    }, f)
    corner(2, box)
    local bs = stroke(val and T.Accent or T.CheckBorder, 1, box)

    local tick = new("TextLabel", {
        Size                 = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text                 = val and "✓" or "",
        TextColor3           = Color3.new(1,1,1),
        TextSize             = 8,
        Font                 = Enum.Font.GothamBold,
    }, box)

    new("TextButton", {
        Size                 = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text                 = "",
    }, f).MouseButton1Click:Connect(function()
        val = not val
        tw(box, {BackgroundColor3 = val and T.CheckOn or T.CheckOff})
        bs.Color = val and T.Accent or T.CheckBorder
        tick.Text = val and "✓" or ""
        if cb then cb(val) end
    end)

    local t = {Value = val}
    function t:Set(v)
        val = v
        box.BackgroundColor3 = v and T.CheckOn or T.CheckOff
        bs.Color = v and T.Accent or T.CheckBorder
        tick.Text = v and "✓" or ""
        if cb then cb(v) end
    end
    return t
end

------------------------------------------------------------------------
-- Keybind
------------------------------------------------------------------------

function Sec:AddKeybind(name, default, cb)
    local key       = default
    local listening = false
    local f         = mkRow(self._body)
    addLabel(f, name)

    local kbtn = new("TextButton", {
        Size             = UDim2.new(0, 60, 0, 16),
        Position         = UDim2.new(1, -64, 0.5, -8),
        BackgroundColor3 = T.KbBg,
        BorderSizePixel  = 0,
        Text             = key and ("[" .. key.Name .. "]") or "[None]",
        TextColor3       = T.TextDim,
        TextSize         = 10,
        Font             = Enum.Font.Gotham,
    }, f)
    corner(3, kbtn)
    stroke(T.KbBorder, 1, kbtn)

    kbtn.MouseButton1Click:Connect(function()
        listening = true
        kbtn.Text = "[...]"
        kbtn.TextColor3 = T.Accent
    end)

    UserInputService.InputBegan:Connect(function(i)
        if not listening then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            key = i.KeyCode
            kbtn.Text = "[" .. key.Name .. "]"
            kbtn.TextColor3 = T.TextDim
            if cb then cb(key) end
        end
    end)

    local kb = {}
    function kb:Get()   return key end
    function kb:Clear() key = nil; kbtn.Text = "[None]" end
    return kb
end

------------------------------------------------------------------------
-- Slider
------------------------------------------------------------------------

function Sec:AddSlider(name, min, max, default, cb)
    local val  = math.clamp(default or min, min, max)
    local drag = false

    local f = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = T.RowBg,
        BorderSizePixel  = 0,
    }, self._body)
    f.MouseEnter:Connect(function() tw(f, {BackgroundColor3 = T.RowHov}) end)
    f.MouseLeave:Connect(function() tw(f, {BackgroundColor3 = T.RowBg}) end)

    new("TextLabel", {
        Size                 = UDim2.new(0.65, 0, 0, 20),
        Position             = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text                 = name,
        TextColor3           = T.Text,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextSize             = 11,
        Font                 = Enum.Font.Gotham,
    }, f)

    local valLbl = new("TextLabel", {
        Size                 = UDim2.new(0.35, -8, 0, 20),
        Position             = UDim2.new(0.65, 0, 0, 0),
        BackgroundTransparency = 1,
        Text                 = tostring(val),
        TextColor3           = T.TextDim,
        TextXAlignment       = Enum.TextXAlignment.Right,
        TextSize             = 10,
        Font                 = Enum.Font.Gotham,
    }, f)

    local track = new("Frame", {
        Size             = UDim2.new(1, -16, 0, 3),
        Position         = UDim2.new(0, 8, 0, 27),
        BackgroundColor3 = T.SliderBg,
        BorderSizePixel  = 0,
    }, f)
    corner(100, track)

    local r0 = (val - min) / (max - min)
    local fill = new("Frame", {
        Size             = UDim2.new(r0, 0, 1, 0),
        BackgroundColor3 = T.SliderFill,
        BorderSizePixel  = 0,
    }, track)
    corner(100, fill)

    local knob = new("Frame", {
        Size             = UDim2.new(0, 7, 0, 7),
        Position         = UDim2.new(r0, -3, 0.5, -3),
        BackgroundColor3 = Color3.new(1,1,1),
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, track)
    corner(100, knob)

    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Sep,
        BorderSizePixel  = 0,
    }, f)

    local function update(x)
        local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + r * (max - min) + 0.5)
        fill.Size     = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -3, 0.5, -3)
        valLbl.Text   = tostring(val)
        if cb then cb(val) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; update(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)

    local s = {Value = val}
    function s:Set(v)
        val = math.clamp(v, min, max)
        local r = (val-min)/(max-min)
        fill.Size = UDim2.new(r,0,1,0); knob.Position = UDim2.new(r,-3,0.5,-3)
        valLbl.Text = tostring(val)
    end
    return s
end

------------------------------------------------------------------------
-- Dropdown
------------------------------------------------------------------------

function Sec:AddDropdown(name, opts, default, cb)
    local val  = default or opts[1]
    local open = false

    local wrapper = new("Frame", {
        Size          = UDim2.new(1, 0, 0, ROW_H),
        BackgroundColor3 = T.RowBg,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        ZIndex           = 5,
    }, self._body)
    wrapper.MouseEnter:Connect(function() tw(wrapper, {BackgroundColor3 = T.RowHov}) end)
    wrapper.MouseLeave:Connect(function() tw(wrapper, {BackgroundColor3 = T.RowBg}) end)

    addLabel(wrapper, name)

    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Sep,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, wrapper)

    local dbtn = new("TextButton", {
        Size             = UDim2.new(0, 68, 0, 16),
        Position         = UDim2.new(1, -72, 0.5, -8),
        BackgroundColor3 = T.KbBg,
        BorderSizePixel  = 0,
        Text             = val,
        TextColor3       = T.Text,
        TextSize         = 10,
        Font             = Enum.Font.Gotham,
        ClipsDescendants = false,
        ZIndex           = 5,
    }, wrapper)
    corner(3, dbtn)
    stroke(T.KbBorder, 1, dbtn)

    local listH  = math.min(#opts, 6) * 20
    local list   = new("Frame", {
        Size             = UDim2.new(1, 2, 0, listH),
        Position         = UDim2.new(0, -1, 1, 2),
        BackgroundColor3 = T.DropBg,
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 20,
    }, dbtn)
    corner(3, list)
    stroke(T.KbBorder, 1, list)

    local listScroll = new("ScrollingFrame", {
        Size               = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize         = UDim2.new(0, 0, 0, #opts * 20),
        ZIndex             = 20,
    }, list)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, listScroll)

    for _, opt in ipairs(opts) do
        local ob = new("TextButton", {
            Size                 = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text                 = opt,
            TextColor3           = T.TextDim,
            TextXAlignment       = Enum.TextXAlignment.Left,
            TextSize             = 10,
            Font                 = Enum.Font.Gotham,
            ZIndex               = 20,
        }, listScroll)
        new("UIPadding", {PaddingLeft = UDim.new(0, 6)}, ob)
        ob.MouseEnter:Connect(function()
            ob.TextColor3 = T.Text
            tw(ob, {BackgroundColor3 = T.RowHov, BackgroundTransparency = 0})
        end)
        ob.MouseLeave:Connect(function()
            ob.TextColor3 = T.TextDim
            tw(ob, {BackgroundTransparency = 1})
        end)
        ob.MouseButton1Click:Connect(function()
            val = opt; dbtn.Text = opt
            list.Visible = false; open = false
            if cb then cb(val) end
        end)
    end

    dbtn.MouseButton1Click:Connect(function()
        open = not open; list.Visible = open
    end)

    local dd = {Value = val}
    function dd:Set(v) val = v; dbtn.Text = v end
    return dd
end

------------------------------------------------------------------------
-- Button
------------------------------------------------------------------------

function Sec:AddButton(name, cb)
    local f = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = T.RowBg,
        BorderSizePixel  = 0,
    }, self._body)
    f.MouseEnter:Connect(function() tw(f, {BackgroundColor3 = T.RowHov}) end)
    f.MouseLeave:Connect(function() tw(f, {BackgroundColor3 = T.RowBg}) end)

    local btn = new("TextButton", {
        Size             = UDim2.new(1, -16, 0, 20),
        Position         = UDim2.new(0, 8, 0.5, -10),
        BackgroundColor3 = T.KbBg,
        BorderSizePixel  = 0,
        Text             = name,
        TextColor3       = T.Text,
        TextSize         = 11,
        Font             = Enum.Font.Gotham,
    }, f)
    corner(3, btn)
    stroke(T.KbBorder, 1, btn)

    btn.MouseButton1Click:Connect(function()
        tw(btn, {BackgroundColor3 = T.Accent}, 0.07)
        task.delay(0.15, function() tw(btn, {BackgroundColor3 = T.KbBg}, 0.1) end)
        if cb then cb() end
    end)

    new("Frame", {
        Size             = UDim2.new(1,0,0,1),
        Position         = UDim2.new(0,0,1,-1),
        BackgroundColor3 = T.Sep,
        BorderSizePixel  = 0,
    }, f)
end

------------------------------------------------------------------------
-- Label
------------------------------------------------------------------------

function Sec:AddLabel(text)
    local f = new("Frame", {
        Size             = UDim2.new(1,0,0,20),
        BackgroundColor3 = T.RowBg,
        BorderSizePixel  = 0,
    }, self._body)
    new("TextLabel", {
        Size                 = UDim2.new(1,-16,1,0),
        Position             = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1,
        Text                 = text,
        TextColor3           = T.TextDim,
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextSize             = 10,
        Font                 = Enum.Font.Gotham,
    }, f)
end

------------------------------------------------------------------------
return UILib
