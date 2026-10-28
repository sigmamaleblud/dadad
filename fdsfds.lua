--[[
  LinoriaUI.lua  —  Linoria-inspired UI library for Roblox executors
  
  Usage:
    local UI = loadstring(...)() -- or dofile / require
    local w = UI.Window({ Width=410, Height=468 })
    w.User("name@site.cc", "fallen")
    
    local t = w.Tab("visuals")
    -- t.Left / t.Right are Panel objects
    
    local s = t.Left.Section("players models")
    local chk  = s.Checkbox({ label="visible model", checked=true, color=Color3.fromRGB(58,127,255) })
    local sl   = s.Slider({ label="intensity", min=0, max=20, value=7, step=.5, suffix="x" })
    local dd   = s.Dropdown({ label="material", options={"3d","2d","wireframe"}, value="3d" })
    local cr   = s.ColorRow({ label="fill", color=Color3.fromRGB(96,200,96) })
    s.Separator()
    s.Label("some note", { color=Color3.fromRGB(80,80,80) })
    
    chk.get()         --> bool
    chk.set(true)
    sl.get()          --> number
    dd.get()          --> string
    cr.get()          --> Color3
    
    w.Destroy()
]]

local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local TS        = game:GetService("TextService")

-- ── Theme ─────────────────────────────────────────────────────────────────────
local T = {
  Bg        = Color3.fromRGB(14,  15,  16),
  TabBar    = Color3.fromRGB(12,  13,  14),
  UserBar   = Color3.fromRGB(11,  12,  13),
  Popup     = Color3.fromRGB(20,  21,  22),
  Border    = Color3.fromRGB(33,  33,  34),
  Divider   = Color3.fromRGB(24,  24,  24),
  PopBorder = Color3.fromRGB(39,  39,  39),
  Track     = Color3.fromRGB(28,  28,  28),
  Fill      = Color3.fromRGB(48,  48,  48),
  Text      = Color3.fromRGB(204, 204, 204),
  TextDim   = Color3.fromRGB(153, 153, 153),
  TextSub   = Color3.fromRGB(86,  86,  86),
  Header    = Color3.fromRGB(212, 212, 212),
  Accent    = Color3.fromRGB(90,  106, 232),
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
-- create instance with property table
local function N(class, props, children)
  local i = Instance.new(class)
  for k, v in next, props do i[k] = v end
  for _, c in next, children or {} do c.Parent = i end
  return i
end

local function hsvToRgb(h, s, v)
  if s == 0 then return v, v, v end
  local i = math.floor(h / 60) % 6
  local f = h / 60 - math.floor(h / 60)
  local p, q, t_ = v*(1-s), v*(1-f*s), v*(1-(1-f)*s)
  local lut = {{v,t_,p},{q,v,p},{p,v,t_},{p,q,v},{t_,p,v},{v,p,q}}
  return table.unpack(lut[i+1])
end

local function rgbToHsv(r, g, b)
  local max = math.max(r,g,b)
  local min = math.min(r,g,b)
  local d   = max - min
  local h, s, v = 0, (max == 0) and 0 or d/max, max
  if d > 0 then
    if     max == r then h = 60 * (((g-b)/d) % 6)
    elseif max == g then h = 60 * ((b-r)/d + 2)
    else                 h = 60 * ((r-g)/d + 4) end
    if h < 0 then h += 360 end
  end
  return h, s, v
end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local function mkGui()
  -- destroy previous instance if re-running
  local name = "LinoriaUI"
  pcall(function()
    game:GetService("CoreGui"):FindFirstChild(name):Destroy()
  end)
  local g = N("ScreenGui", { Name=name, ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling })
  if not pcall(function() g.Parent = game:GetService("CoreGui") end) then
    g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
  end
  return g
end

-- ── Tooltip singleton ─────────────────────────────────────────────────────────
local function mkTooltipSystem(gui)
  local frame = N("Frame", {
    BackgroundColor3 = T.Popup,
    BorderSizePixel  = 0,
    Size             = UDim2.new(0, 180, 0, 40),
    Visible          = false,
    ZIndex           = 250,
    Parent           = gui,
  }, {
    N("UICorner",  { CornerRadius = UDim.new(0, 3) }),
    N("UIStroke",  { Color = T.PopBorder, Thickness = 1 }),
    N("UIPadding", { PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,5),
                     PaddingLeft=UDim.new(0,7), PaddingRight=UDim.new(0,7) }),
  })
  local lbl = N("TextLabel", {
    BackgroundTransparency = 1,
    Size                   = UDim2.new(1, 0, 1, 0),
    Font                   = Enum.Font.Gotham,
    TextColor3             = T.TextDim,
    TextSize               = 11,
    TextXAlignment         = Enum.TextXAlignment.Left,
    TextYAlignment         = Enum.TextYAlignment.Top,
    TextWrapped            = true,
    RichText               = true,
    ZIndex                 = 251,
    Parent                 = frame,
  })
  local function show(text, x, y)
    lbl.Text = text
    local sz = TS:GetTextSize(text, 11, Enum.Font.Gotham, Vector2.new(180, 800))
    frame.Size     = UDim2.new(0, sz.X + 14, 0, sz.Y + 10)
    frame.Position = UDim2.new(0, x + 12, 0, y + 4)
    frame.Visible  = true
  end
  local function hide() frame.Visible = false end
  return show, hide
end

-- ── Color picker popup ────────────────────────────────────────────────────────
local function mkColorPicker(gui, showTip, hideTip)
  return function(anchor, initColor, onchange)
    -- close any open picker
    local old = gui:FindFirstChild("__cpop")
    if old then old:Destroy() end

    local h, s, v = rgbToHsv(initColor.R, initColor.G, initColor.B)

    local ap  = anchor.AbsolutePosition
    local av  = workspace.CurrentCamera.ViewportSize
    local px  = ap.X + anchor.AbsoluteSize.X + 6
    local py  = ap.Y
    if px + 184 > av.X then px = ap.X - 184 - 6 end
    if py + 202 > av.Y then py = av.Y - 202 - 6 end

    local pop = N("Frame", {
      Name             = "__cpop",
      BackgroundColor3 = T.Popup,
      BorderSizePixel  = 0,
      Position         = UDim2.new(0, px, 0, py),
      Size             = UDim2.new(0, 184, 0, 202),
      ZIndex           = 200,
      Parent           = gui,
    }, {
      N("UICorner",  { CornerRadius = UDim.new(0, 4) }),
      N("UIStroke",  { Color = T.PopBorder, Thickness = 1 }),
      N("UIPadding", { PaddingTop=UDim.new(0,7), PaddingBottom=UDim.new(0,7),
                       PaddingLeft=UDim.new(0,7), PaddingRight=UDim.new(0,7) }),
    })

    -- SV field (hue-colored bg + white gradient + black gradient overlay)
    local svF = N("Frame", {
      BackgroundColor3 = Color3.fromHSV(h/360, 1, 1),
      BorderSizePixel  = 0,
      Size             = UDim2.new(1, 0, 0, 118),
      ZIndex           = 201,
      Parent           = pop,
    }, { N("UICorner", { CornerRadius=UDim.new(0,2) }) })

    local whiteOvr = N("Frame", {
      BackgroundColor3 = Color3.fromRGB(255,255,255),
      BorderSizePixel  = 0,
      Size             = UDim2.new(1,0,1,0),
      ZIndex           = 202,
      Parent           = svF,
    }, { N("UICorner", { CornerRadius=UDim.new(0,2) }) })
    N("UIGradient", {
      Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }),
      Parent = whiteOvr,
    })

    local blackOvr = N("Frame", {
      BackgroundColor3 = Color3.fromRGB(0,0,0),
      BorderSizePixel  = 0,
      Size             = UDim2.new(1,0,1,0),
      ZIndex           = 203,
      Parent           = svF,
    }, { N("UICorner", { CornerRadius=UDim.new(0,2) }) })
    N("UIGradient", {
      Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }),
      Rotation = 90,
      Parent = blackOvr,
    })

    -- SV cursor dot
    local cur = N("Frame", {
      AnchorPoint      = Vector2.new(0.5, 0.5),
      BackgroundTransparency = 1,
      BorderSizePixel  = 0,
      Size             = UDim2.new(0, 8, 0, 8),
      ZIndex           = 210,
      Parent           = svF,
    }, {
      N("UICorner", { CornerRadius=UDim.new(1,0) }),
      N("UIStroke",  { Color=Color3.fromRGB(255,255,255), Thickness=1.5 }),
    })

    -- Hue bar
    local hueBar = N("Frame", {
      BackgroundColor3 = Color3.fromRGB(255,255,255),
      BorderSizePixel  = 0,
      Position         = UDim2.new(0, 0, 0, 123),
      Size             = UDim2.new(1, 0, 0, 10),
      ZIndex           = 201,
      Parent           = pop,
    }, { N("UICorner", { CornerRadius=UDim.new(0,2) }) })
    N("UIGradient", {
      Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,0,0)),
      }),
      Parent = hueBar,
    })
    local hueThumb = N("Frame", {
      AnchorPoint      = Vector2.new(0.5, 0),
      BackgroundTransparency = 1,
      BorderSizePixel  = 0,
      Size             = UDim2.new(0, 4, 1, 0),
      ZIndex           = 205,
      Parent           = hueBar,
    }, {
      N("UIStroke",  { Color=Color3.fromRGB(255,255,255), Thickness=1.5 }),
      N("UICorner",  { CornerRadius=UDim.new(0,2) }),
    })

    -- Hex input
    local hexBox = N("TextBox", {
      BackgroundColor3 = T.Bg,
      BorderSizePixel  = 0,
      Position         = UDim2.new(0, 0, 0, 140),
      Size             = UDim2.new(1, 0, 0, 20),
      Font             = Enum.Font.Code,
      PlaceholderText  = "#RRGGBB",
      TextColor3       = T.TextDim,
      TextSize         = 11,
      ClearTextOnFocus = false,
      ZIndex           = 201,
      Parent           = pop,
    }, {
      N("UICorner",  { CornerRadius=UDim.new(0,2) }),
      N("UIStroke",  { Color=T.PopBorder, Thickness=1 }),
      N("UIPadding", { PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5) }),
    })

    N("TextLabel", {
      BackgroundTransparency = 1,
      Position               = UDim2.new(0, 0, 0, 167),
      Size                   = UDim2.new(1, 0, 0, 12),
      Font                   = Enum.Font.Gotham,
      Text                   = "save to gallery",
      TextColor3             = Color3.fromRGB(50,50,50),
      TextSize               = 9,
      TextXAlignment         = Enum.TextXAlignment.Left,
      ZIndex                 = 201,
      Parent                 = pop,
    })

    -- Update visuals
    local function upd()
      svF.BackgroundColor3  = Color3.fromHSV(h/360, 1, 1)
      cur.Position           = UDim2.new(s, 0, 1-v, 0)
      hueThumb.Position      = UDim2.new(h/360, 0, 0, 0)
      local r_, g_, b_ = hsvToRgb(h, s, v)
      hexBox.Text = string.format("#%02X%02X%02X",
        math.floor(r_*255+.5), math.floor(g_*255+.5), math.floor(b_*255+.5))
    end
    local function emit()
      local r_, g_, b_ = hsvToRgb(h, s, v)
      onchange(Color3.new(r_, g_, b_))
    end

    -- SV drag
    local svDrag, hueDrag = false, false
    svF.InputBegan:Connect(function(i)
      if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
      svDrag = true
      local rel = i.Position - svF.AbsolutePosition
      s = math.clamp(rel.X / svF.AbsoluteSize.X, 0, 1)
      v = math.clamp(1 - rel.Y / svF.AbsoluteSize.Y, 0, 1)
      upd(); emit()
    end)
    hueBar.InputBegan:Connect(function(i)
      if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
      hueDrag = true
      local rel = i.Position - hueBar.AbsolutePosition
      h = math.clamp((rel.X / hueBar.AbsoluteSize.X) * 360, 0, 359.9)
      upd(); emit()
    end)
    UIS.InputChanged:Connect(function(i)
      if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
      if svDrag then
        local rel = i.Position - Vector2.new(svF.AbsolutePosition.X, svF.AbsolutePosition.Y)
        s = math.clamp(rel.X / svF.AbsoluteSize.X, 0, 1)
        v = math.clamp(1 - rel.Y / svF.AbsoluteSize.Y, 0, 1)
        upd(); emit()
      end
      if hueDrag then
        local rel = i.Position - Vector2.new(hueBar.AbsolutePosition.X, hueBar.AbsolutePosition.Y)
        h = math.clamp((rel.X / hueBar.AbsoluteSize.X) * 360, 0, 359.9)
        upd(); emit()
      end
    end)
    UIS.InputEnded:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseButton1 then
        svDrag = false; hueDrag = false
      end
    end)

    hexBox.FocusLost:Connect(function()
      local hex = hexBox.Text:gsub("#","")
      if #hex == 6 then
        local r_ = tonumber(hex:sub(1,2),16) or 0
        local g_ = tonumber(hex:sub(3,4),16) or 0
        local b_ = tonumber(hex:sub(5,6),16) or 0
        h,s,v = rgbToHsv(r_/255, g_/255, b_/255)
        upd(); emit()
      end
    end)

    -- Close on outside click
    local conn
    conn = UIS.InputBegan:Connect(function(i)
      if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
      local m   = UIS:GetMouseLocation()
      local pos = pop.AbsolutePosition
      local sz  = pop.AbsoluteSize
      if m.X < pos.X or m.X > pos.X + sz.X or m.Y < pos.Y or m.Y > pos.Y + sz.Y then
        pop:Destroy(); conn:Disconnect()
      end
    end)

    upd()
    return pop
  end
end

-- ── Section ───────────────────────────────────────────────────────────────────
local function mkSection(container, gui, openCP, showTip, hideTip)
  local sec = {}

  -- helper: blank layout row
  local lo = 0
  local function row(h_)
    lo += 1
    return N("Frame", {
      BackgroundTransparency = 1,
      Size        = UDim2.new(1, 0, 0, h_ or 17),
      LayoutOrder = lo,
      Parent      = container,
    })
  end

  local function infoBtn(parent, text, xOffset)
    local b = N("TextLabel", {
      AnchorPoint            = Vector2.new(1, 0.5),
      BackgroundTransparency = 1,
      Position               = UDim2.new(1, xOffset or -2, 0.5, 0),
      Size                   = UDim2.new(0, 12, 0, 12),
      Font                   = Enum.Font.Georgia,
      Text                   = "i",
      TextColor3             = Color3.fromRGB(70,70,70),
      TextSize               = 8,
      Parent                 = parent,
    }, {
      N("UICorner", { CornerRadius=UDim.new(1,0) }),
      N("UIStroke", { Color=Color3.fromRGB(50,50,50), Thickness=1 }),
    })
    b.InputBegan:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseMovement then
        local m = UIS:GetMouseLocation(); showTip(text, m.X, m.Y)
      end
    end)
    b.InputEnded:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseMovement then hideTip() end
    end)
    return b
  end

  local function mkSwatch(parent, color, onPick)
    local sw = N("Frame", {
      AnchorPoint      = Vector2.new(1, 0.5),
      BackgroundColor3 = color,
      BorderSizePixel  = 0,
      Position         = UDim2.new(1, -2, 0.5, 0),
      Size             = UDim2.new(0, 13, 0, 13),
      Parent           = parent,
    }, {
      N("UICorner", { CornerRadius=UDim.new(0,2) }),
      N("UIStroke", { Color=Color3.fromRGB(255,255,255), Thickness=0.5, Transparency=0.88 }),
    })
    sw.InputBegan:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseButton1 then
        openCP(sw, sw.BackgroundColor3, function(c)
          sw.BackgroundColor3 = c; onPick(c)
        end)
      end
    end)
    return sw
  end

  function sec.Checkbox(opts)
    opts = opts or {}
    local checked = opts.checked or false
    local color   = opts.color   -- Color3 | nil
    local val     = checked

    local r = row()
    -- small checkbox square
    local chk = N("Frame", {
      AnchorPoint            = Vector2.new(0, 0.5),
      BackgroundColor3       = checked and (color or T.Accent) or Color3.fromRGB(0,0,0),
      BackgroundTransparency = checked and 0 or 1,
      BorderSizePixel        = 0,
      Position               = UDim2.new(0, 0, 0.5, 0),
      Size                   = UDim2.new(0, 9, 0, 9),
      Parent                 = r,
    }, {
      N("UICorner", { CornerRadius=UDim.new(0,1) }),
    })
    local stroke = N("UIStroke", {
      Color     = checked and (color or T.Accent) or Color3.fromRGB(54,54,54),
      Thickness = 1,
      Parent    = chk,
    })
    N("TextLabel", {
      AnchorPoint            = Vector2.new(0, 0.5),
      BackgroundTransparency = 1,
      Position               = UDim2.new(0, 14, 0.5, 0),
      Size                   = UDim2.new(1, -38, 0, 14),
      Font                   = Enum.Font.Gotham,
      Text                   = opts.label or "",
      TextColor3             = T.TextDim,
      TextSize               = 10,
      TextXAlignment         = Enum.TextXAlignment.Left,
      Parent                 = r,
    })

    local swatchRef
    if opts.info then infoBtn(r, opts.info, color and -18 or -2) end
    if color then
      swatchRef = mkSwatch(r, color, function(c) color = c
        if val then chk.BackgroundColor3 = c; stroke.Color = c end
      end)
    end

    local function toggle()
      val = not val
      if val then
        chk.BackgroundTransparency = 0
        chk.BackgroundColor3 = color or T.Accent
        stroke.Color         = color or T.Accent
      else
        chk.BackgroundTransparency = 1
        stroke.Color               = Color3.fromRGB(54,54,54)
      end
      if opts.onChange then opts.onChange(val) end
    end
    r.InputBegan:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
    end)
    return { get=function() return val end, set=function(x) if x~=val then toggle() end end }
  end

  function sec.Slider(opts)
    opts = opts or {}
    local min_, max_ = opts.min or 0, opts.max or 100
    local step_      = opts.step or 1
    local suffix_    = opts.suffix or ""
    local val        = opts.value or opts.default or min_

    -- label row
    if opts.label and opts.label ~= "" then
      local lr = row(13)
      N("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        Font=Enum.Font.Gotham, Text=opts.label,
        TextColor3=T.TextSub, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=lr,
      })
    end

    local cr = row(16)

    local minus = N("TextLabel", {
      AnchorPoint=Vector2.new(0,.5), BackgroundTransparency=1,
      Position=UDim2.new(0,0,.5,0), Size=UDim2.new(0,12,0,14),
      Font=Enum.Font.Code, Text="−",
      TextColor3=Color3.fromRGB(72,72,72), TextSize=15, Parent=cr,
    })
    local plus = N("TextLabel", {
      AnchorPoint=Vector2.new(1,.5), BackgroundTransparency=1,
      Position=UDim2.new(1,0,.5,0), Size=UDim2.new(0,12,0,14),
      Font=Enum.Font.Code, Text="+",
      TextColor3=Color3.fromRGB(72,72,72), TextSize=15, Parent=cr,
    })
    local trk = N("Frame", {
      AnchorPoint=Vector2.new(0,.5), BackgroundColor3=T.Track, BorderSizePixel=0,
      Position=UDim2.new(0,15,.5,0), Size=UDim2.new(1,-30,0,3), Parent=cr,
    }, { N("UICorner",{CornerRadius=UDim.new(0,2)}) })
    local fill = N("Frame", {
      BackgroundColor3=T.Fill, BorderSizePixel=0,
      Size=UDim2.new(0,0,1,0), Parent=trk,
    }, { N("UICorner",{CornerRadius=UDim.new(0,2)}) })
    local vtxt = N("TextLabel", {
      AnchorPoint=Vector2.new(1,.5), BackgroundTransparency=1,
      Position=UDim2.new(1,-2,.5,0), Size=UDim2.new(.7,0,1,0),
      Font=Enum.Font.Gotham, Text="", TextColor3=Color3.fromRGB(100,100,100),
      TextSize=9, TextXAlignment=Enum.TextXAlignment.Right, Parent=trk,
    })
    row(3) -- small spacer

    local function snap(x)
      return math.clamp(math.round(x / step_) * step_, min_, max_)
    end
    local function upd()
      fill.Size = UDim2.new((val-min_)/(max_-min_), 0, 1, 0)
      vtxt.Text = tostring(val) .. suffix_
      if opts.onChange then opts.onChange(val) end
    end

    minus.InputBegan:Connect(function(i)
      if i.UserInputType==Enum.UserInputType.MouseButton1 then val=snap(val-step_); upd() end
    end)
    plus.InputBegan:Connect(function(i)
      if i.UserInputType==Enum.UserInputType.MouseButton1 then val=snap(val+step_); upd() end
    end)

    local trkDrag = false
    local function setFromMouse(mx)
      local pos  = trk.AbsolutePosition.X
      local size = trk.AbsoluteSize.X
      val = snap(min_ + math.clamp((mx-pos)/size, 0, 1) * (max_-min_))
      upd()
    end
    trk.InputBegan:Connect(function(i)
      if i.UserInputType==Enum.UserInputType.MouseButton1 then
        trkDrag=true; setFromMouse(i.Position.X)
      end
    end)
    UIS.InputChanged:Connect(function(i)
      if trkDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
        setFromMouse(i.Position.X)
      end
    end)
    UIS.InputEnded:Connect(function(i)
      if i.UserInputType==Enum.UserInputType.MouseButton1 then trkDrag=false end
    end)

    upd()
    return { get=function() return val end, set=function(x) val=snap(x); upd() end }
  end

  function sec.Dropdown(opts)
    opts = opts or {}
    local options = opts.options or {}
    local cur     = opts.value or options[1] or ""

    if opts.label and opts.label ~= "" then
      local lr = row(13)
      N("TextLabel", {
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        Font=Enum.Font.Gotham, Text=opts.label,
        TextColor3=T.TextSub, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=lr,
      })
    end

    local dr = row(18)
    if opts.info then infoBtn(dr, opts.info, -18) end

    local valLbl = N("TextLabel", {
      BackgroundTransparency=1, Position=UDim2.new(0,0,0,0),
      Size=UDim2.new(1,-16,1,0), Font=Enum.Font.Gotham,
      Text=cur, TextColor3=T.TextDim, TextSize=10,
      TextXAlignment=Enum.TextXAlignment.Left, Parent=dr,
    })
    N("TextLabel", {
      AnchorPoint=Vector2.new(1,.5), BackgroundTransparency=1,
      Position=UDim2.new(1,0,.5,0), Size=UDim2.new(0,14,0,14),
      Font=Enum.Font.Gotham, Text="≡",
      TextColor3=Color3.fromRGB(60,60,60), TextSize=12, Parent=dr,
    })
    row(3)

    local menuOpen, menuF = false, nil
    local function closeMenu() if menuF then menuF:Destroy(); menuF=nil end; menuOpen=false end
    local function openMenu()
      closeMenu(); menuOpen=true
      local ap = dr.AbsolutePosition
      menuF = N("Frame", {
        BackgroundColor3=T.Popup, BorderSizePixel=0,
        Position=UDim2.new(0,ap.X,0,ap.Y+dr.AbsoluteSize.Y+2),
        Size=UDim2.new(0,dr.AbsoluteSize.X,0,#options*20+4),
        ZIndex=180, Parent=gui,
      }, {
        N("UICorner",  { CornerRadius=UDim.new(0,3) }),
        N("UIStroke",  { Color=T.PopBorder, Thickness=1 }),
        N("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0) }),
        N("UIPadding", { PaddingTop=UDim.new(0,2), PaddingBottom=UDim.new(0,2) }),
      })
      for idx, opt in next, options do
        local it = N("TextButton", {
          BackgroundTransparency=1, LayoutOrder=idx,
          Size=UDim2.new(1,0,0,20), Font=Enum.Font.Gotham,
          Text=" "..opt, TextColor3=opt==cur and T.Text or T.TextDim,
          TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
          ZIndex=181, Parent=menuF,
        }, { N("UIPadding",{PaddingLeft=UDim.new(0,6)}) })
        it.MouseEnter:Connect(function() it.BackgroundColor3=Color3.fromRGB(26,27,28); it.BackgroundTransparency=0 end)
        it.MouseLeave:Connect(function() it.BackgroundTransparency=1 end)
        it.Activated:Connect(function()
          cur=opt; valLbl.Text=opt; closeMenu()
          if opts.onChange then opts.onChange(opt) end
        end)
      end
      -- close on outside click
      local conn_; conn_ = UIS.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        local m=UIS:GetMouseLocation(); local p=menuF and menuF.AbsolutePosition; local sz=menuF and menuF.AbsoluteSize
        if menuF and (m.X<p.X or m.X>p.X+sz.X or m.Y<p.Y or m.Y>p.Y+sz.Y) then
          closeMenu(); conn_:Disconnect()
        end
      end)
    end
    dr.InputBegan:Connect(function(i)
      if i.UserInputType==Enum.UserInputType.MouseButton1 then
        if menuOpen then closeMenu() else openMenu() end
      end
    end)
    return { get=function() return cur end, set=function(x) cur=x; valLbl.Text=x end }
  end

  function sec.ColorRow(opts)
    opts = opts or {}
    local color = opts.color or Color3.fromRGB(255,255,255)
    local r = row()
    N("TextLabel", {
      AnchorPoint=Vector2.new(0,.5), BackgroundTransparency=1,
      Position=UDim2.new(0,0,.5,0), Size=UDim2.new(1,-36,0,14),
      Font=Enum.Font.Gotham, Text=opts.label or "",
      TextColor3=T.TextDim, TextSize=10,
      TextXAlignment=Enum.TextXAlignment.Left, Parent=r,
    })
    if opts.info then infoBtn(r, opts.info, -18) end
    local sw = mkSwatch(r, color, function(c) color=c; if opts.onChange then opts.onChange(c) end end)
    return { get=function() return color end, set=function(c) color=c; sw.BackgroundColor3=c end }
  end

  function sec.Label(text, opts_)
    opts_ = opts_ or {}
    local lr = row(opts_.height or 14)
    N("TextLabel", {
      BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
      Font=Enum.Font.Gotham, Text=text or "",
      TextColor3=opts_.color or Color3.fromRGB(78,78,78),
      TextSize=opts_.size or 9,
      TextXAlignment=Enum.TextXAlignment.Left, Parent=lr,
    })
  end

  function sec.Separator()
    lo += 1
    N("Frame", {
      BackgroundColor3=T.Divider, BorderSizePixel=0,
      Size=UDim2.new(1,0,0,1), LayoutOrder=lo, Parent=container,
    })
    lo += 1
    N("Frame", {
      BackgroundTransparency=1, Size=UDim2.new(1,0,0,4),
      LayoutOrder=lo, Parent=container,
    })
  end

  return sec
end

-- ── Panel ─────────────────────────────────────────────────────────────────────
local function mkPanel(scroll, gui, openCP, showTip, hideTip)
  local pan = {}
  local lo  = 0

  function pan.Section(title)
    lo += 1
    local cont = N("Frame", {
      BackgroundTransparency = 1,
      AutomaticSize          = Enum.AutomaticSize.Y,
      Size                   = UDim2.new(1, 0, 0, 0),
      LayoutOrder            = lo,
      Parent                 = scroll,
    }, {
      N("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0) }),
      N("UIPadding", {
        PaddingLeft=UDim.new(0,7), PaddingRight=UDim.new(0,7), PaddingBottom=UDim.new(0,8),
      }),
    })
    if title and title ~= "" then
      N("TextLabel", {
        BackgroundTransparency=1, LayoutOrder=0,
        Size=UDim2.new(1,0,0,20), Font=Enum.Font.GothamBold,
        Text=title, TextColor3=T.Header, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=cont,
      })
    end
    return mkSection(cont, gui, openCP, showTip, hideTip)
  end

  function pan.List(items, onSelect)
    lo += 1
    local cont = N("Frame", {
      BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y,
      Size=UDim2.new(1,0,0,0), LayoutOrder=lo, Parent=scroll,
    }, {
      N("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,1) }),
      N("UIPadding",{ PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5), PaddingTop=UDim.new(0,3) }),
    })
    local rows = {}
    for i, item in next, items do
      local r = N("Frame", {
        BackgroundTransparency=1, BorderSizePixel=0,
        LayoutOrder=i, Size=UDim2.new(1,0,0,20), Parent=cont,
      }, { N("UICorner",{CornerRadius=UDim.new(0,2)}) })
      local leftBar = N("Frame", {
        BackgroundColor3=T.Accent, BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.new(0,0,.1,0), Size=UDim2.new(0,2,.8,0), Parent=r,
      }, { N("UICorner",{CornerRadius=UDim.new(0,1)}) })
      N("Frame", {
        AnchorPoint=Vector2.new(0,.5), BackgroundColor3=item.color or Color3.fromRGB(85,85,85),
        BorderSizePixel=0, Position=UDim2.new(0,5,.5,0),
        Size=UDim2.new(0,7,0,7), Parent=r,
      }, { N("UICorner",{CornerRadius=UDim.new(0,1)}) })
      N("TextLabel", {
        AnchorPoint=Vector2.new(0,.5), BackgroundTransparency=1,
        Position=UDim2.new(0,16,.5,0), Size=UDim2.new(1,-32,0,14),
        Font=Enum.Font.Gotham, Text=item.label or "",
        TextColor3=T.TextDim, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=r,
      })
      if item.color then
        N("Frame", {
          AnchorPoint=Vector2.new(1,.5), BackgroundColor3=item.color,
          BorderSizePixel=0, Position=UDim2.new(1,-4,.5,0),
          Size=UDim2.new(0,12,0,12), Parent=r,
        }, { N("UICorner",{CornerRadius=UDim.new(0,2)}) })
      end
      local selected = false
      r.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        for _, rr in next, rows do
          rr._row.BackgroundTransparency = 1
          rr._bar.BackgroundTransparency = 1
        end
        r.BackgroundColor3 = Color3.fromRGB(18,19,20)
        r.BackgroundTransparency = 0
        leftBar.BackgroundTransparency = 0
        selected = true
        if onSelect then onSelect(item) end
      end)
      r.MouseEnter:Connect(function()
        if r.BackgroundTransparency == 1 then
          r.BackgroundColor3 = Color3.fromRGB(20,21,22)
          r.BackgroundTransparency = 0
        end
      end)
      r.MouseLeave:Connect(function()
        if leftBar.BackgroundTransparency == 1 then
          r.BackgroundTransparency = 1
        end
      end)
      table.insert(rows, { _row=r, _bar=leftBar })
    end
    return rows
  end

  return pan
end

-- ── Window factory ────────────────────────────────────────────────────────────
local function Window(opts)
  opts = opts or {}
  local W    = opts.Width  or 410
  local H    = opts.Height or 468
  local vp   = workspace.CurrentCamera.ViewportSize
  local px   = opts.X or math.floor((vp.X - W) / 2)
  local py   = opts.Y or math.floor((vp.Y - H) / 2)

  local gui  = mkGui()
  local showTip, hideTip = mkTooltipSystem(gui)
  local openCP = mkColorPicker(gui, showTip, hideTip)

  local win = N("Frame", {
    BackgroundColor3 = T.Bg,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    Position         = UDim2.new(0, px, 0, py),
    Size             = UDim2.new(0, W, 0, H),
    Parent           = gui,
  }, {
    N("UICorner", { CornerRadius=UDim.new(0,3) }),
    N("UIStroke", { Color=T.Border, Thickness=1 }),
  })

  -- ── Tab bar / drag handle ─────────────────────────────────────────────────
  local tabBar = N("Frame", {
    BackgroundColor3 = T.TabBar,
    BorderSizePixel  = 0,
    Size             = UDim2.new(1, 0, 0, 26),
    Parent           = win,
  }, {
    N("UIListLayout", {
      FillDirection=Enum.FillDirection.Horizontal,
      SortOrder=Enum.SortOrder.LayoutOrder,
    }),
    N("Frame", {  -- bottom border line
      AnchorPoint=Vector2.new(0,1), BackgroundColor3=T.Divider, BorderSizePixel=0,
      Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,1), ZIndex=2,
    }),
  })

  -- ── Body ──────────────────────────────────────────────────────────────────
  local body = N("Frame", {
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    ClipsDescendants       = true,
    Position               = UDim2.new(0, 0, 0, 27),
    Size                   = UDim2.new(1, 0, 1, -57),  -- 27 top + 30 bottom
    Parent                 = win,
  })

  -- ── User bar ──────────────────────────────────────────────────────────────
  local uBar = N("Frame", {
    AnchorPoint      = Vector2.new(0, 1),
    BackgroundColor3 = T.UserBar,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 0, 1, 0),
    Size             = UDim2.new(1, 0, 0, 30),
    Parent           = win,
  }, {
    N("Frame", { BackgroundColor3=T.Divider, BorderSizePixel=0, Size=UDim2.new(1,0,0,1) }),
    N("UIPadding", { PaddingLeft=UDim.new(0,9), PaddingRight=UDim.new(0,9) }),
    N("UIListLayout", {
      FillDirection=Enum.FillDirection.Horizontal,
      VerticalAlignment=Enum.VerticalAlignment.Center,
      Padding=UDim.new(0,7),
    }),
  })
  local avaF = N("Frame", {
    BackgroundColor3=Color3.fromRGB(28,28,28), BorderSizePixel=0,
    Size=UDim2.new(0,20,0,20), Parent=uBar,
  }, { N("UICorner",{CornerRadius=UDim.new(1,0)}) })
  local uInfo = N("Frame", {
    BackgroundTransparency=1, Size=UDim2.new(1,-30,0,28), Parent=uBar,
  }, {
    N("UIListLayout",{
      FillDirection=Enum.FillDirection.Vertical,
      VerticalAlignment=Enum.VerticalAlignment.Center,
      Padding=UDim.new(0,1),
    }),
  })
  local uName = N("TextLabel", {
    BackgroundTransparency=1, Size=UDim2.new(1,0,0,13),
    Font=Enum.Font.Gotham, Text="", TextColor3=Color3.fromRGB(130,130,130),
    TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, Parent=uInfo,
  })
  local uSub = N("TextLabel", {
    BackgroundTransparency=1, Size=UDim2.new(1,0,0,11),
    Font=Enum.Font.Gotham, Text="", TextColor3=Color3.fromRGB(60,60,60),
    TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, Parent=uInfo,
  })

  -- ── Resize handle ─────────────────────────────────────────────────────────
  local rh = N("TextLabel", {
    AnchorPoint=Vector2.new(1,1), BackgroundTransparency=1,
    Position=UDim2.new(1,-5,1,-4), Size=UDim2.new(0,12,0,12),
    Font=Enum.Font.Code, Text="⠿",
    TextColor3=Color3.fromRGB(38,38,38), TextSize=11, ZIndex=5, Parent=win,
  })

  -- ── Drag ──────────────────────────────────────────────────────────────────
  local drag, dStart, dWinPos = false, nil, nil
  tabBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
      drag=true; dStart=i.Position; dWinPos=win.Position
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
      local d=i.Position-dStart
      win.Position=UDim2.new(dWinPos.X.Scale, dWinPos.X.Offset+d.X,
                              dWinPos.Y.Scale, dWinPos.Y.Offset+d.Y)
    end
  end)
  UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
  end)

  -- ── Resize ────────────────────────────────────────────────────────────────
  local rsz, rStart, rWinSz = false, nil, nil
  rh.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
      rsz=true; rStart=i.Position; rWinSz=win.Size
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if rsz and i.UserInputType==Enum.UserInputType.MouseMovement then
      local d=i.Position-rStart
      local nw=math.max(280, rWinSz.X.Offset+d.X)
      local nh=math.max(200, rWinSz.Y.Offset+d.Y)
      win.Size=UDim2.new(0,nw,0,nh)
      body.Size=UDim2.new(1,0,1,-57)
    end
  end)
  UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then rsz=false end
  end)

  -- ── Tabs ──────────────────────────────────────────────────────────────────
  local tabs   = {}
  local tabBtns = {}

  local function Tab(name)
    local idx = #tabs + 1

    local btn = N("TextButton", {
      BackgroundTransparency = 1,
      LayoutOrder            = idx,
      AutomaticSize          = Enum.AutomaticSize.X,
      Size                   = UDim2.new(0, 0, 1, 0),
      Font                   = Enum.Font.Gotham,
      Text                   = "  "..name.."  ",
      TextColor3             = idx==1 and T.Text or Color3.fromRGB(72,72,72),
      TextSize               = 10,
      Parent                 = tabBar,
    }, {
      -- right divider
      N("Frame",{
        AnchorPoint=Vector2.new(1,0), BackgroundColor3=T.Divider, BorderSizePixel=0,
        Position=UDim2.new(1,0,0,0), Size=UDim2.new(0,1,1,0), ZIndex=2,
      }),
    })
    local indicator = N("Frame", {
      AnchorPoint=Vector2.new(.5,1), BackgroundColor3=Color3.fromRGB(130,130,130),
      BorderSizePixel=0, Position=UDim2.new(.5,0,1,0),
      Size=UDim2.new(.6,0,0,1), Visible=(idx==1), Parent=btn,
    })

    -- content (two-column scroll layout)
    local content = N("Frame", {
      BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
      Visible=(idx==1), Parent=body,
    })

    local function mkScroll(pos, size)
      return N("ScrollingFrame", {
        BackgroundTransparency=1, BorderSizePixel=0,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=2,
        ScrollBarImageColor3=Color3.fromRGB(38,38,38),
        ScrollingDirection=Enum.ScrollingDirection.Y,
        Position=pos, Size=size, Parent=content,
      }, {
        N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)}),
        N("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)}),
      })
    end

    local lScroll = mkScroll(UDim2.new(0,0,0,0), UDim2.new(.5,-1,1,0))
    -- divider
    N("Frame",{
      BackgroundColor3=T.Divider, BorderSizePixel=0,
      Position=UDim2.new(.5,-1,0,0), Size=UDim2.new(0,1,1,0), Parent=content,
    })
    local rScroll = mkScroll(UDim2.new(.5,1,0,0), UDim2.new(.5,-1,1,0))

    local tab = {
      Left  = mkPanel(lScroll, gui, openCP, showTip, hideTip),
      Right = mkPanel(rScroll, gui, openCP, showTip, hideTip),
      _btn  = btn, _el=content, _ind=indicator,
    }

    btn.Activated:Connect(function()
      for _, t in next, tabs do
        t._el.Visible  = false
        t._btn.TextColor3 = Color3.fromRGB(72,72,72)
        t._ind.Visible = false
      end
      content.Visible   = true
      btn.TextColor3    = T.Text
      indicator.Visible = true
    end)

    table.insert(tabs, tab)
    table.insert(tabBtns, btn)
    return tab
  end

  local function User(name, sub, avatarAsset)
    uName.Text = name or ""
    uSub.Text  = sub  or ""
    if avatarAsset then
      N("ImageLabel",{
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        Image=avatarAsset, Parent=avaF,
      })
    end
  end

  return {
    Tab     = Tab,
    User    = User,
    Show    = function() win.Visible = true end,
    Hide    = function() win.Visible = false end,
    Destroy = function() gui:Destroy() end,
    Frame   = win,
    Gui     = gui,
  }
end

-- ── Module return ─────────────────────────────────────────────────────────────
return {
  Window = Window,
  Theme  = T,  -- modify T.Accent etc. before creating window to retheme
}
