-- UILib.lua | dx9ware 1:1

local UILib = {}
UILib.__index = UILib

local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local T = {
    SB      = Color3.fromRGB(13,13,13),
    BG      = Color3.fromRGB(17,17,17),
    BG2     = Color3.fromRGB(21,21,21),
    LINE    = Color3.fromRGB(28,28,28),
    LINEP   = Color3.fromRGB(32,32,32),
    ACC     = Color3.fromRGB(102,42,194),
    ACC2    = Color3.fromRGB(130,60,220),
    TACT    = Color3.fromRGB(90,36,175),
    THOV    = Color3.fromRGB(45,18,90),
    TXT     = Color3.fromRGB(208,208,208),
    TXT2    = Color3.fromRGB(105,105,105),
    TXTH    = Color3.fromRGB(185,185,185),
    KB      = Color3.fromRGB(22,22,22),
    KBB     = Color3.fromRGB(44,44,44),
    TON     = Color3.fromRGB(102,42,194),
    TOFF    = Color3.fromRGB(30,30,30),
    TOFFB   = Color3.fromRGB(52,52,52),
    SLF     = Color3.fromRGB(102,42,194),
    SLB     = Color3.fromRGB(30,30,30),
    DROP    = Color3.fromRGB(15,15,15),
}

local SW = 152
local PW = 210
local RH = 24
local SH = 26

local function tw(o,p,t) TS:Create(o,TweenInfo.new(t or .1,Enum.EasingStyle.Quad),p):Play() end
local function N(c,p,par)
    local o=Instance.new(c)
    for k,v in pairs(p) do o[k]=v end
    if par then o.Parent=par end
    return o
end
local function C(r,p) return N("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function St(c,t,p)
    local s=Instance.new("UIStroke"); s.Color=c; s.Thickness=t or 1; s.Parent=p; return s
end

local function drag(frame, handle)
    local d,ds,sp
    ;(handle or frame).InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            d=true; ds=i.Position; sp=frame.Position
        end
    end)
    ;(handle or frame).InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and i.UserInputType==Enum.UserInputType.MouseMovement then
            local v=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+v.X,sp.Y.Scale,sp.Y.Offset+v.Y)
        end
    end)
end

------------------------------------------------------------------------
function UILib.new(cfg)
    cfg=cfg or {}
    local self=setmetatable({_tabs={},_n=0},UILib)

    local gui=Instance.new("ScreenGui")
    gui.Name=cfg.Name or "UILib"; gui.ResetOnSpawn=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=999
    gui.Parent=(gethui and gethui()) or game:GetService("CoreGui")

    UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode==(cfg.ToggleKey or Enum.KeyCode.RShift) then
            gui.Enabled=not gui.Enabled
        end
    end)

    -- SIDEBAR
    local sb=N("Frame",{
        Size=UDim2.new(0,SW,0,0),
        Position=UDim2.new(0.15,0,0.15,0),
        BackgroundColor3=T.SB,
        BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=false,
    },gui)
    C(5,sb); St(T.LINE,1,sb)
    drag(sb)

    -- eye icon
    local eyeF=N("Frame",{Size=UDim2.new(1,0,0,58),BackgroundTransparency=1},sb)
    N("ImageLabel",{
        Size=UDim2.new(0,34,0,34),
        Position=UDim2.new(.5,-17,.5,-17),
        BackgroundTransparency=1,
        Image="rbxassetid://"..(cfg.EyeIcon or "12556702945"),
        ScaleType=Enum.ScaleType.Fit,
    },eyeF)

    N("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.LINE,
        BorderSizePixel=0,
    },eyeF)

    -- tab container
    local tabC=N("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1,
        AutomaticSize=Enum.AutomaticSize.Y,
    },sb)
    N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},tabC)

    -- rescan
    local rescanW=N("Frame",{
        Size=UDim2.new(1,0,0,42),
        BackgroundTransparency=1,
    },sb)
    N("Frame",{
        Size=UDim2.new(1,0,0,1),
        BackgroundColor3=T.LINE,
        BorderSizePixel=0,
    },rescanW)
    local rsBtn=N("TextButton",{
        Size=UDim2.new(1,-18,0,24),
        Position=UDim2.new(0,9,0,9),
        BackgroundColor3=T.KB,
        BorderSizePixel=0,
        Text="Rescan",
        TextColor3=T.TXT,
        TextSize=11,
        Font=Enum.Font.Gotham,
    },rescanW)
    C(4,rsBtn); St(T.KBB,1,rsBtn)

    self._gui=gui; self._sb=sb; self._tabC=tabC; self._rescan=rsBtn
    return self
end

function UILib:OnRescan(cb) self._rescan.MouseButton1Click:Connect(cb) end

------------------------------------------------------------------------
-- Tab
------------------------------------------------------------------------
local Tab={}; Tab.__index=Tab
local Sec={}; Sec.__index=Sec

function UILib:AddTab(name, icon)
    local tab=setmetatable({_secs={},_lib=self,_open=false},Tab)
    self._n=self._n+1

    -- sidebar button
    local btn=N("TextButton",{
        Size=UDim2.new(1,0,0,34),
        BackgroundColor3=T.SB,
        BorderSizePixel=0,
        Text="",
        AutoButtonColor=false,
    },self._tabC)

    if icon then
        N("TextLabel",{
            Size=UDim2.new(0,20,1,0),
            Position=UDim2.new(0,8,0,0),
            BackgroundTransparency=1,
            Text=icon,
            TextColor3=T.TXT2,
            TextSize=13,
            Font=Enum.Font.Gotham,
        },btn)
    end

    local lbl=N("TextLabel",{
        Size=UDim2.new(1,-44,1,0),
        Position=UDim2.new(0,icon and 30 or 10,0,0),
        BackgroundTransparency=1,
        Text=name,
        TextColor3=T.TXT2,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=12,
        Font=Enum.Font.Gotham,
    },btn)

    local chev=N("TextLabel",{
        Size=UDim2.new(0,16,1,0),
        Position=UDim2.new(1,-18,0,0),
        BackgroundTransparency=1,
        Text="›",
        TextColor3=T.TXT2,
        TextSize=17,
        Font=Enum.Font.GothamBold,
    },btn)

    N("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.LINE,
        BorderSizePixel=0,
    },btn)

    btn.MouseEnter:Connect(function()
        if not tab._open then tw(btn,{BackgroundColor3=T.THOV}) end
    end)
    btn.MouseLeave:Connect(function()
        if not tab._open then tw(btn,{BackgroundColor3=T.SB}) end
    end)

    -- PANEL — independent floating frame
    local sbPos=self._sb.Position
    local px=sbPos.X.Offset + SW + 6 + (self._n-1)*(PW+6)
    local py=sbPos.Y.Offset

    local panel=N("Frame",{
        Size=UDim2.new(0,PW,0,0),
        Position=UDim2.new(0,150+(self._n-1)*(PW+6),0.15,0),
        BackgroundColor3=T.BG,
        BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        Visible=false,
        ClipsDescendants=false,
    },self._gui)
    C(5,panel); St(T.LINE,1,panel)

    -- panel header
    local phdr=N("Frame",{
        Size=UDim2.new(1,0,0,28),
        BackgroundColor3=T.BG,
        BorderSizePixel=0,
    },panel)
    C(5,phdr)
    -- bottom square filler
    N("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,1,-6),BackgroundColor3=T.BG,BorderSizePixel=0},phdr)

    -- icon label in header
    if icon then
        N("TextLabel",{
            Size=UDim2.new(0,18,1,0),
            Position=UDim2.new(0,7,0,0),
            BackgroundTransparency=1,
            Text=icon,
            TextColor3=T.TXT2,
            TextSize=12,
            Font=Enum.Font.Gotham,
        },phdr)
    end

    N("TextLabel",{
        Size=UDim2.new(1,-42,1,0),
        Position=UDim2.new(0,icon and 26 or 8,0,0),
        BackgroundTransparency=1,
        Text=name,
        TextColor3=T.TXTH,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=12,
        Font=Enum.Font.GothamBold,
    },phdr)

    -- purple dot = collapse body
    local dot=N("Frame",{
        Size=UDim2.new(0,10,0,10),
        Position=UDim2.new(1,-16,0.5,-5),
        BackgroundColor3=T.ACC,
        BorderSizePixel=0,
    },phdr)
    C(100,dot)

    -- purple line under header
    N("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.ACC,
        BorderSizePixel=0,
    },phdr)

    drag(panel, phdr)

    -- body scroll
    local bodyScroll=N("ScrollingFrame",{
        Size=UDim2.new(1,0,0,0),
        Position=UDim2.new(0,0,0,29),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=2,
        ScrollBarImageColor3=T.ACC,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=false,
    },panel)
    local bL=N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},bodyScroll)
    N("UIPadding",{PaddingBottom=UDim.new(0,5)},bodyScroll)
    bL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        bodyScroll.CanvasSize=UDim2.new(0,0,0,bL.AbsoluteContentSize.Y+8)
    end)

    local bodyVisible=true
    dot.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            bodyVisible=not bodyVisible
            bodyScroll.Visible=bodyVisible
            tw(dot,{BackgroundColor3=bodyVisible and T.ACC or T.KBB})
        end
    end)

    btn.MouseButton1Click:Connect(function()
        tab._open=not tab._open
        panel.Visible=tab._open
        if tab._open then
            tw(btn,{BackgroundColor3=T.TACT})
            lbl.TextColor3=Color3.new(1,1,1)
            chev.TextColor3=Color3.new(1,1,1)
        else
            tw(btn,{BackgroundColor3=T.SB})
            lbl.TextColor3=T.TXT2
            chev.TextColor3=T.TXT2
        end
    end)

    tab._btn=btn; tab._panel=panel; tab._bodyScroll=bodyScroll
    table.insert(self._tabs,tab)
    return tab
end

------------------------------------------------------------------------
-- Section
------------------------------------------------------------------------

function Tab:AddSection(name)
    local sec=setmetatable({_collapsed=false},Sec)

    local wrap=N("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1,
        AutomaticSize=Enum.AutomaticSize.Y,
    },self._bodyScroll)

    local shdr=N("TextButton",{
        Size=UDim2.new(1,0,0,SH),
        BackgroundColor3=T.BG,
        BorderSizePixel=0,
        Text="",
        AutoButtonColor=false,
    },wrap)

    local arrow=N("TextLabel",{
        Size=UDim2.new(0,14,1,0),
        Position=UDim2.new(0,5,0,0),
        BackgroundTransparency=1,
        Text="▼",
        TextColor3=T.ACC2,
        TextSize=8,
        Font=Enum.Font.GothamBold,
    },shdr)

    N("TextLabel",{
        Size=UDim2.new(1,-20,1,0),
        Position=UDim2.new(0,18,0,0),
        BackgroundTransparency=1,
        Text=name,
        TextColor3=T.TXTH,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=11,
        Font=Enum.Font.GothamBold,
    },shdr)

    N("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.LINEP,
        BorderSizePixel=0,
    },shdr)

    local body=N("Frame",{
        Size=UDim2.new(1,0,0,0),
        Position=UDim2.new(0,0,0,SH),
        BackgroundTransparency=1,
        AutomaticSize=Enum.AutomaticSize.Y,
    },wrap)
    N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},body)

    shdr.MouseButton1Click:Connect(function()
        sec._collapsed=not sec._collapsed
        body.Visible=not sec._collapsed
        arrow.Text=sec._collapsed and "▶" or "▼"
    end)

    sec._body=body
    return sec
end

------------------------------------------------------------------------
-- Row helper
------------------------------------------------------------------------

local function mkRow(parent, h)
    local f=N("Frame",{
        Size=UDim2.new(1,0,0,h or RH),
        BackgroundColor3=T.BG2,
        BorderSizePixel=0,
    },parent)
    f.MouseEnter:Connect(function() tw(f,{BackgroundColor3=Color3.fromRGB(26,26,26)}) end)
    f.MouseLeave:Connect(function() tw(f,{BackgroundColor3=T.BG2}) end)
    N("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.LINE,
        BorderSizePixel=0,
    },f)
    return f
end

local function rowLbl(f,text)
    N("TextLabel",{
        Size=UDim2.new(0.65,0,1,0),
        Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text=text,
        TextColor3=T.TXT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=11,
        Font=Enum.Font.Gotham,
    },f)
end

------------------------------------------------------------------------
-- Toggle (pill)
------------------------------------------------------------------------

function Sec:AddToggle(name, default, cb)
    local val=default or false
    local f=mkRow(self._body)
    rowLbl(f,name)

    local track=N("Frame",{
        Size=UDim2.new(0,32,0,16),
        Position=UDim2.new(1,-38,0.5,-8),
        BackgroundColor3=val and T.TON or T.TOFF,
        BorderSizePixel=0,
    },f)
    C(100,track); St(T.TOFFB,1,track)

    local knob=N("Frame",{
        Size=UDim2.new(0,11,0,11),
        Position=val and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,2,0.5,-5),
        BackgroundColor3=Color3.new(1,1,1),
        BorderSizePixel=0,
    },track)
    C(100,knob)

    N("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",
    },f).MouseButton1Click:Connect(function()
        val=not val
        tw(track,{BackgroundColor3=val and T.TON or T.TOFF})
        tw(knob,{Position=val and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,2,0.5,-5)})
        if cb then cb(val) end
    end)

    local t={Value=val}
    function t:Set(v)
        val=v
        track.BackgroundColor3=v and T.TON or T.TOFF
        knob.Position=v and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,2,0.5,-5)
        if cb then cb(v) end
    end
    return t
end

------------------------------------------------------------------------
-- Keybind
------------------------------------------------------------------------

function Sec:AddKeybind(name, default, cb)
    local key=default
    local listening=false
    local f=mkRow(self._body)
    rowLbl(f,name)

    local kbtn=N("TextButton",{
        Size=UDim2.new(0,62,0,16),
        Position=UDim2.new(1,-66,0.5,-8),
        BackgroundColor3=T.KB,
        BorderSizePixel=0,
        Text=key and ("["..key.Name.."]") or "[None]",
        TextColor3=T.TXT2,
        TextSize=10,
        Font=Enum.Font.Gotham,
    },f)
    C(3,kbtn); St(T.KBB,1,kbtn)

    kbtn.MouseButton1Click:Connect(function()
        listening=true; kbtn.Text="[...]"; kbtn.TextColor3=T.ACC2
    end)

    -- MMB binding
    UIS.InputBegan:Connect(function(i)
        if not listening then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            listening=false; key=i.KeyCode
            kbtn.Text="["..key.Name.."]"; kbtn.TextColor3=T.TXT2
            if cb then cb(key) end
        elseif i.UserInputType==Enum.UserInputType.MouseButton3 then
            -- middle mouse
            listening=false; key="MMB"
            kbtn.Text="[MMB]"; kbtn.TextColor3=T.TXT2
            if cb then cb("MMB") end
        end
    end)

    local kb={}
    function kb:Get() return key end
    function kb:Clear() key=nil; kbtn.Text="[None]"; kbtn.TextColor3=T.TXT2 end
    return kb
end

------------------------------------------------------------------------
-- Slider
------------------------------------------------------------------------

function Sec:AddSlider(name, min, max, default, cb)
    local val=math.clamp(default or min,min,max)
    local drag_=false
    local f=mkRow(self._body,36)
    -- cancel hover interference with drag
    f.MouseEnter:Connect(function() end)

    N("TextLabel",{
        Size=UDim2.new(0.7,0,0,18),
        Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text=name,
        TextColor3=T.TXT,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=11,
        Font=Enum.Font.Gotham,
    },f)

    local vlbl=N("TextLabel",{
        Size=UDim2.new(0.3,-8,0,18),
        Position=UDim2.new(0.7,0,0,0),
        BackgroundTransparency=1,
        Text=tostring(val),
        TextColor3=T.TXT2,
        TextXAlignment=Enum.TextXAlignment.Right,
        TextSize=10,
        Font=Enum.Font.Gotham,
    },f)

    local track=N("Frame",{
        Size=UDim2.new(1,-16,0,3),
        Position=UDim2.new(0,8,0,25),
        BackgroundColor3=T.SLB,
        BorderSizePixel=0,
    },f)
    C(100,track)

    local r0=(val-min)/(max-min)
    local fill=N("Frame",{Size=UDim2.new(r0,0,1,0),BackgroundColor3=T.SLF,BorderSizePixel=0},track)
    C(100,fill)
    local knob=N("Frame",{
        Size=UDim2.new(0,7,0,7),
        Position=UDim2.new(r0,-3,0.5,-3),
        BackgroundColor3=Color3.new(1,1,1),
        BorderSizePixel=0,
        ZIndex=2,
    },track)
    C(100,knob)

    local function upd(x)
        local r=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        val=math.floor(min+r*(max-min)+.5)
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,-3,0.5,-3)
        vlbl.Text=tostring(val)
        if cb then cb(val) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag_=true; upd(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag_ and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag_=false end
    end)

    local s={Value=val}
    function s:Set(v)
        val=math.clamp(v,min,max)
        local r=(val-min)/(max-min)
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,-3,0.5,-3); vlbl.Text=tostring(val)
    end
    return s
end

------------------------------------------------------------------------
-- Dropdown
------------------------------------------------------------------------

function Sec:AddDropdown(name, opts, default, cb)
    local val=default or opts[1]
    local open=false
    local f=mkRow(self._body)
    f.ClipsDescendants=false; f.ZIndex=6
    rowLbl(f,name)

    N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.LINE,BorderSizePixel=0,ZIndex=6},f)

    local dbtn=N("TextButton",{
        Size=UDim2.new(0,70,0,16),
        Position=UDim2.new(1,-74,0.5,-8),
        BackgroundColor3=T.KB,
        BorderSizePixel=0,
        Text=val,
        TextColor3=T.TXT,
        TextSize=10,
        Font=Enum.Font.Gotham,
        ClipsDescendants=false,
        ZIndex=6,
    },f)
    C(3,dbtn); St(T.KBB,1,dbtn)

    local lh=math.min(#opts,7)*20
    local list=N("Frame",{
        Size=UDim2.new(1,2,0,lh),
        Position=UDim2.new(0,-1,1,2),
        BackgroundColor3=T.DROP,
        BorderSizePixel=0,
        Visible=false,
        ZIndex=20,
    },dbtn)
    C(3,list); St(T.KBB,1,list)

    local ls=N("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=2,
        ScrollBarImageColor3=T.ACC,
        CanvasSize=UDim2.new(0,0,0,#opts*20),
        ZIndex=20,
    },list)
    N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},ls)

    for _,opt in ipairs(opts) do
        local ob=N("TextButton",{
            Size=UDim2.new(1,0,0,20),
            BackgroundTransparency=1,
            Text=opt,
            TextColor3=T.TXT2,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextSize=10,
            Font=Enum.Font.Gotham,
            ZIndex=20,
        },ls)
        N("UIPadding",{PaddingLeft=UDim.new(0,7)},ob)
        ob.MouseEnter:Connect(function() ob.TextColor3=T.TXT; tw(ob,{BackgroundColor3=Color3.fromRGB(26,26,26),BackgroundTransparency=0}) end)
        ob.MouseLeave:Connect(function() ob.TextColor3=T.TXT2; tw(ob,{BackgroundTransparency=1}) end)
        ob.MouseButton1Click:Connect(function()
            val=opt; dbtn.Text=opt; list.Visible=false; open=false
            if cb then cb(val) end
        end)
    end

    dbtn.MouseButton1Click:Connect(function() open=not open; list.Visible=open end)

    local dd={Value=val}
    function dd:Set(v) val=v; dbtn.Text=v end
    return dd
end

------------------------------------------------------------------------
-- Button
------------------------------------------------------------------------

function Sec:AddButton(name, cb)
    local f=mkRow(self._body,28)
    local btn=N("TextButton",{
        Size=UDim2.new(1,-16,0,18),
        Position=UDim2.new(0,8,0.5,-9),
        BackgroundColor3=T.KB,
        BorderSizePixel=0,
        Text=name,
        TextColor3=T.TXT,
        TextSize=11,
        Font=Enum.Font.Gotham,
    },f)
    C(3,btn); St(T.KBB,1,btn)
    btn.MouseButton1Click:Connect(function()
        tw(btn,{BackgroundColor3=T.ACC},0.07)
        task.delay(0.15,function() tw(btn,{BackgroundColor3=T.KB},0.1) end)
        if cb then cb() end
    end)
end

------------------------------------------------------------------------
-- Label
------------------------------------------------------------------------

function Sec:AddLabel(text)
    local f=N("Frame",{Size=UDim2.new(1,0,0,18),BackgroundColor3=T.BG2,BorderSizePixel=0},self._body)
    N("TextLabel",{
        Size=UDim2.new(1,-16,1,0),
        Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text=text,
        TextColor3=T.TXT2,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=10,
        Font=Enum.Font.Gotham,
    },f)
end

------------------------------------------------------------------------
return UILib
