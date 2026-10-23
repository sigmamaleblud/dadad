local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Colors = {
    bg = Color3.fromRGB(15, 15, 15),
    side = Color3.fromRGB(10, 10, 10),
    panel = Color3.fromRGB(20, 20, 20),
    item = Color3.fromRGB(24, 24, 24),
    input = Color3.fromRGB(30, 30, 30),
    hover = Color3.fromRGB(35, 35, 35),
    accent = Color3.fromRGB(110, 50, 200),
    text = Color3.fromRGB(230, 230, 230),
    textDim = Color3.fromRGB(150, 150, 150),
    white = Color3.fromRGB(255, 255, 255),
    outline = Color3.fromRGB(40, 40, 40),
    toggleOff = Color3.fromRGB(50, 50, 50),
    track = Color3.fromRGB(40, 40, 40),
    font = Enum.Font.Gotham,
    fontBold = Enum.Font.GothamBold,
    fontMono = Enum.Font.Code
}

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function tween(obj, time, props)
    TS:Create(obj, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function corner(obj, rad)
    new("UICorner", { CornerRadius = UDim.new(0, rad or 6) }, obj)
end

local function stroke(obj, col, thick, trans)
    new("UIStroke", {
        Color = col or Colors.outline,
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, obj)
end

local function drag(frame, handle)
    handle = handle or frame
    local dragging, dragInput, mousePos, framePos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

local function formatNum(val, round)
    if round == 0 then return tostring(math.floor(val + 0.5)) end
    return string.format("%." .. round .. "f", val)
end

-- main lib
local Library = {}
Library.__index = Library

function Library.new()
    local self = setmetatable({}, Library)
    
    self.gui = new("ScreenGui", {
        Name = "DXLib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        IgnoreGuiInset = true
    }, (gethui and gethui()) or CoreGui)

    self.notifs = new("Frame", {
        Size = UDim2.new(0, 300, 1, -40),
        Position = UDim2.new(1, -320, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 1000
    }, self.gui)
    
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 8)
    }, self.notifs)

    return self
end

function Library:Notify(text, dur, type)
    dur = dur or 3
    local col = (type == "success" and Color3.fromRGB(80, 255, 120)) or (type == "error" and Color3.fromRGB(255, 80, 80)) or Colors.accent
    
    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Colors.panel,
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, self.notifs)
    corner(frame, 6)
    local str = new("UIStroke", { Color = col, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
    local line = new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = col, BackgroundTransparency = 1 }, frame)
    corner(line, 6)
    
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = Colors.text,
        Font = Colors.font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1
    }, frame)
    
    frame.Position = UDim2.new(0, 300, 0, 0)
    tween(frame, 0.3, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 })
    tween(line, 0.3, { BackgroundTransparency = 0 })
    tween(str, 0.3, { Transparency = 0 })
    tween(lbl, 0.3, { TextTransparency = 0 })
    
    task.delay(dur, function()
        if frame then
            tween(frame, 0.3, { Position = UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1 })
            tween(line, 0.3, { BackgroundTransparency = 1 })
            tween(str, 0.3, { Transparency = 1 })
            tween(lbl, 0.3, { TextTransparency = 1 })
            task.wait(0.35)
            frame:Destroy()
        end
    end)
end

function Library:CreateWindow(cfg)
    local Window = { tabs = {}, open = {}, index = 0, key = cfg.ToggleKey or Enum.KeyCode.RightAlt }

    -- sidebar
    Window.sidebar = new("Frame", {
        Size = UDim2.new(0, 180, 0, 65), Position = UDim2.new(0, 300, 0, 200),
        BackgroundColor3 = Colors.side, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 1
    }, self.gui)
    corner(Window.sidebar, 6)
    stroke(Window.sidebar, Colors.outline, 1, 0)
    
    -- header/eye
    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1 }, Window.sidebar)
    new("ImageLabel", {
        Size = UDim2.new(0, 65, 0, 65), Position = UDim2.new(0.5, -32.5, 0.5, -32.5),
        BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id=12556702945&w=150&h=150",
        ScaleType = Enum.ScaleType.Fit, ImageColor3 = Colors.white
    }, header)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Colors.outline }, header)
    drag(Window.sidebar, header)
    
    -- tab list
    local list = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 65),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y
    }, Window.sidebar)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

    function Window:SetKey(k) self.key = k end
    
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Window.key then
            local vis = not Window.sidebar.Visible
            Window.sidebar.Visible = vis
            for _, t in pairs(Window.open) do t.panel.Visible = vis end
        end
    end)

    function Window:AddTab(name)
        Window.index = Window.index + 1
        local Tab = { name = name, index = Window.index }

        Tab.btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Colors.side,
            Text = "", AutoButtonColor = false
        }, list)
        
        new("TextLabel", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "★", TextColor3 = Colors.textDim, Font = Colors.fontBold, TextSize = 14 }, Tab.btn)
        
        Tab.lbl = new("TextLabel", {
            Size = UDim2.new(1, -45, 1, 0), Position = UDim2.new(0, 38, 0, 0),
            BackgroundTransparency = 1, Text = name, TextColor3 = Colors.textDim,
            Font = Colors.font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
        }, Tab.btn)
        
        new("TextLabel", { Size = UDim2.new(0, 15, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, Text = "›", TextColor3 = Colors.textDim, Font = Colors.fontBold, TextSize = 18 }, Tab.btn)

        -- panel
        Tab.panel = new("Frame", {
            Size = UDim2.new(0, 280, 0, 450), BackgroundColor3 = Colors.panel,
            Visible = false, ClipsDescendants = true, ZIndex = 50
        }, self.gui)
        corner(Tab.panel, 6)
        stroke(Tab.panel, Colors.outline, 1, 0)

        local pHeader = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Colors.panel }, Tab.panel)
        new("TextLabel", { Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Colors.text, Font = Colors.fontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, pHeader)
        
        -- collapse dot
        local dot = new("TextButton", { Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -20, 0.5, -5), BackgroundColor3 = Colors.accent, Text = "", BorderSizePixel = 0 }, pHeader)
        corner(dot, 100)
        new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Colors.accent }, pHeader)
        
        drag(Tab.panel, pHeader)

        Tab.content = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, -30), Position = UDim2.new(0, 0, 0, 30),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            ScrollBarImageColor3 = Colors.accent, CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2
        }, Tab.panel)
        
        local cLayout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, Tab.content)
        new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }, Tab.content)
        
        cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Tab.content.CanvasSize = UDim2.new(0, 0, 0, cLayout.AbsoluteContentSize.Y + 16)
        end)

        dot.MouseButton1Click:Connect(function()
            Tab.collapsed = not Tab.collapsed
            tween(Tab.panel, 0.2, { Size = Tab.collapsed and UDim2.new(0, 280, 0, 30) or UDim2.new(0, 280, 0, 450) })
            Tab.content.Visible = not Tab.collapsed
        end)

        Tab.btn.MouseButton1Click:Connect(function()
            if Tab.panel.Visible then
                Tab.panel.Visible = false
                for i, v in pairs(Window.open) do if v == Tab then table.remove(Window.open, i) break end end
                tween(Tab.btn, 0.15, { BackgroundColor3 = Colors.side })
                tween(Tab.lbl, 0.15, { TextColor3 = Colors.textDim })
            else
                Tab.panel.Visible = true
                -- фикс позиции: всегда на своем месте по индексу
                local p = Window.sidebar.AbsolutePosition
                Tab.panel.Position = UDim2.new(0, p.X + 186 + (Tab.index - 1) * 288, 0, p.Y)
                table.insert(Window.open, Tab)
                tween(Tab.btn, 0.15, { BackgroundColor3 = Colors.accent })
                tween(Tab.lbl, 0.15, { TextColor3 = Colors.white })
            end
        end)

        -- section
        function Tab:AddSection(name)
            local Section = {}
            local box = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, Tab.content)
            
            local head = new("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Colors.panel, Text = "", AutoButtonColor = false }, box)
            local arr = new("TextLabel", { Size = UDim2.new(0, 15, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "▼", TextColor3 = Colors.accent, Font = Colors.fontBold, TextSize = 9 }, head)
            new("TextLabel", { Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 28, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Colors.text, Font = Colors.fontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, head)
            new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Colors.outline }, head)
            
            local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 28), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, box)
            new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, body)
            
            head.MouseButton1Click:Connect(function()
                body.Visible = not body.Visible
                arr.Text = body.Visible and "▼" or "▶"
            end)

            -- toggle
            function Section:AddToggle(flag, cfg)
                local f = new("Frame", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.new(0, 5, 0, 0), BackgroundColor3 = Colors.item }, body)
                corner(f, 4)
                new("TextLabel", { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = cfg.Text, TextColor3 = Colors.text, Font = Colors.font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, f)
                
                local track = new("Frame", { Size = UDim2.new(0, 28, 0, 14), Position = UDim2.new(1, -38, 0.5, -7), BackgroundColor3 = cfg.Default and Colors.accent or Colors.toggleOff, BorderSizePixel = 0 }, f)
                corner(track, 100)
                local knob = new("Frame", { Size = UDim2.new(0, 10, 0, 10), Position = cfg.Default and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = Colors.white, BorderSizePixel = 0 }, track)
                corner(knob, 100)
                
                local obj = { Value = cfg.Default, Default = cfg.Default }
                function obj:Set(v)
                    self.Value = v
                    tween(track, 0.15, { BackgroundColor3 = v and Colors.accent or Colors.toggleOff })
                    tween(knob, 0.15, { Position = v and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5) })
                    if cfg.Callback then cfg.Callback(v) end
                end
                
                new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, f).MouseButton1Click:Connect(function()
                    obj:Set(not obj.Value)
                end)
                return obj
            end

            -- slider
            function Section:AddSlider(flag, cfg)
                local f = new("Frame", { Size = UDim2.new(1, -10, 0, 40), Position = UDim2.new(0, 5, 0, 0), BackgroundColor3 = Colors.item }, body)
                corner(f, 4)
                new("TextLabel", { Size = UDim2.new(0.5, 0, 0, 18), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = cfg.Text, TextColor3 = Colors.text, Font = Colors.font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, f)
                
                local vLabel = new("TextLabel", { Size = UDim2.new(0.5, -10, 0, 18), Position = UDim2.new(0.5, 0, 0, 2), BackgroundTransparency = 1, Text = formatNum(cfg.Default, cfg.Rounding or 0), TextColor3 = Colors.textDim, Font = Colors.fontMono, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right }, f)
                
                local track = new("Frame", { Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 28), BackgroundColor3 = Colors.track, BorderSizePixel = 0 }, f)
                corner(track, 100)
                
                local mult = 10 ^ (cfg.Rounding or 0)
                local r = (cfg.Default - cfg.Min) / (cfg.Max - cfg.Min)
                local fill = new("Frame", { Size = UDim2.new(r, 0, 1, 0), BackgroundColor3 = Colors.accent, BorderSizePixel = 0 }, track)
                corner(fill, 100)
                
                local obj = { Value = cfg.Default, Default = cfg.Default }
                local dragging = false
                
                local function update(x)
                    local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local val = math.floor((cfg.Min + p * (cfg.Max - cfg.Min)) * mult + 0.5) / mult
                    obj.Value = val
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    vLabel.Text = formatNum(val, cfg.Rounding or 0)
                    if cfg.Callback then cfg.Callback(val) end
                end
                
                track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i.Position.X) end end)
                UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end end)
                UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                
                function obj:Set(v)
                    v = math.clamp(v, cfg.Min, cfg.Max)
                    local p = (v - cfg.Min) / (cfg.Max - cfg.Min)
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    vLabel.Text = formatNum(v, cfg.Rounding or 0)
                    self.Value = v
                    if cfg.Callback then cfg.Callback(v) end
                end
                return obj
            end

            -- keybind
            function Section:AddKeybind(flag, cfg)
                local f = new("Frame", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.new(0, 5, 0, 0), BackgroundColor3 = Colors.item }, body)
                corner(f, 4)
                new("TextLabel", { Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = cfg.Text, TextColor3 = Colors.text, Font = Colors.font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, f)
                
                local btn = new("TextButton", { Size = UDim2.new(0, 60, 0, 18), Position = UDim2.new(1, -130, 0.5, -9), BackgroundColor3 = Colors.input, Text = cfg.Default and ("["..cfg.Default.Name.."]") or "[None]", TextColor3 = Colors.textDim, Font = Colors.fontMono, TextSize = 10, BorderSizePixel = 0, AutoButtonColor = false }, f)
                corner(btn, 3)
                stroke(btn, Colors.outline, 1, 0)
                
                local modeBtn = new("TextButton", { Size = UDim2.new(0, 55, 0, 18), Position = UDim2.new(1, -65, 0.5, -9), BackgroundColor3 = Colors.input, Text = "Toggle", TextColor3 = Colors.text, Font = Colors.font, TextSize = 10, BorderSizePixel = 0, AutoButtonColor = false }, f)
                corner(modeBtn, 3)
                stroke(modeBtn, Colors.outline, 1, 0)
                
                local listening, mode = false, "Toggle"
                local obj = { Value = cfg.Default, Default = cfg.Default, Mode = mode }
                
                modeBtn.MouseButton1Click:Connect(function()
                    local ax, ay = modeBtn.AbsolutePosition.X, modeBtn.AbsolutePosition.Y + 20
                    local drop = new("Frame", { Size = UDim2.new(0, 55, 0, 66), Position = UDim2.new(0, ax, 0, ay), BackgroundColor3 = Colors.panel, ZIndex = 500 }, self.gui)
                    corner(drop, 4)
                    stroke(drop, Colors.outline, 1, 0)
                    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, drop)
                    
                    for _, opt in pairs({"Toggle", "Hold", "Always"}) do
                        local ob = new("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = opt, TextColor3 = Colors.textDim, Font = Colors.font, TextSize = 10 }, drop)
                        ob.MouseButton1Click:Connect(function()
                            mode = opt
                            obj.Mode = mode
                            modeBtn.Text = opt
                            drop:Destroy()
                        end)
                    end
                    task.delay(0.1, function()
                        local c
                        c = UIS.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drop:Destroy() c:Disconnect() end end)
                    end)
                end)
                
                btn.MouseButton1Click:Connect(function()
                    listening = true
                    btn.Text = "[...]"
                    btn.TextColor3 = Colors.accent
                end)
                
                UIS.InputBegan:Connect(function(i, gp)
                    if gp then return end
                    if listening and i.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        obj.Value = i.KeyCode
                        cfg.Default = i.KeyCode
                        btn.Text = "["..i.KeyCode.Name.."]"
                        btn.TextColor3 = Colors.textDim
                    end
                end)
                
                UIS.InputBegan:Connect(function(i, gp)
                    if gp or not obj.Value then return end
                    if i.KeyCode == obj.Value then
                        if mode == "Toggle" then
                            obj.Toggled = not obj.Toggled
                            if cfg.Callback then cfg.Callback(obj.Toggled) end
                        elseif mode == "Hold" or mode == "Always" then
                            if cfg.Callback then cfg.Callback(true) end
                        end
                    end
                end)
                
                UIS.InputEnded:Connect(function(i)
                    if not obj.Value then return end
                    if i.KeyCode == obj.Value and mode == "Hold" then
                        if cfg.Callback then cfg.Callback(false) end
                    end
                end)
                
                function obj:Set(k)
                    self.Value = k
                    cfg.Default = k
                    btn.Text = k and ("["..k.Name.."]") or "[None]"
                end
                return obj
            end

            -- dropdown
            function Section:AddDropdown(flag, cfg)
                local f = new("Frame", { Size = UDim2.new(1, -10, 0, 28), Position = UDim2.new(0, 5, 0, 0), BackgroundColor3 = Colors.item }, body)
                corner(f, 4)
                new("TextLabel", { Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = cfg.Text, TextColor3 = Colors.text, Font = Colors.font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, f)
                
                local val = cfg.Default or cfg.Options[1]
                local btn = new("TextButton", { Size = UDim2.new(0, 80, 0, 18), Position = UDim2.new(1, -90, 0.5, -9), BackgroundColor3 = Colors.input, Text = val, TextColor3 = Colors.text, Font = Colors.font, TextSize = 10, BorderSizePixel = 0, AutoButtonColor = false }, f)
                corner(btn, 3)
                stroke(btn, Colors.outline, 1, 0)
                
                local obj = { Value = val, Default = val }
                local opened = false
                local drop
                
                btn.MouseButton1Click:Connect(function()
                    if opened then if drop then drop:Destroy() end opened = false return end
                    opened = true
                    
                    local ax, ay = btn.AbsolutePosition.X, btn.AbsolutePosition.Y + 20
                    drop = new("Frame", { Size = UDim2.new(0, 100, 0, #cfg.Options * 22), Position = UDim2.new(0, ax - 20, 0, ay), BackgroundColor3 = Colors.panel, ZIndex = 500 }, self.gui)
                    corner(drop, 4)
                    stroke(drop, Colors.outline, 1, 0)
                    
                    local scroll = new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, #cfg.Options * 22) }, drop)
                    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
                    
                    for _, opt in pairs(cfg.Options) do
                        local ob = new("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = opt, TextColor3 = Colors.textDim, Font = Colors.font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, scroll)
                        new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, ob)
                        ob.MouseButton1Click:Connect(function()
                            obj.Value = opt
                            btn.Text = opt
                            drop:Destroy()
                            opened = false
                            if cfg.Callback then cfg.Callback(opt) end
                        end)
                    end
                    task.delay(0.1, function()
                        local c
                        c = UIS.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 and drop then drop:Destroy() opened = false c:Disconnect() end end)
                    end)
                end)
                
                function obj:Set(v)
                    self.Value = v
                    btn.Text = v
                end
                return obj
            end

            -- button
            function Section:AddButton(cfg)
                local f = new("Frame", { Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 0, 0), BackgroundColor3 = Colors.item }, body)
                corner(f, 4)
                local btn = new("TextButton", { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 5, 0.5, -10), BackgroundColor3 = Colors.input, Text = cfg.Text, TextColor3 = Colors.text, Font = Colors.font, TextSize = 11, BorderSizePixel = 0, AutoButtonColor = false }, f)
                corner(btn, 4)
                
                btn.MouseButton1Click:Connect(function()
                    tween(btn, 0.1, { BackgroundColor3 = Colors.accent })
                    task.delay(0.15, function() tween(btn, 0.1, { BackgroundColor3 = Colors.input }) end)
                    if cfg.Callback then cfg.Callback() end
                end)
            end

            -- label
            function Section:AddLabel(text)
                local f = new("Frame", { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1 }, body)
                new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Colors.textDim, Font = Colors.font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, f)
            end

            return Section
        end

        table.insert(Window.tabs, Tab)
        return Tab
    end

    return Window
end

return Library.new()
