                , svH + 14),
                BackgroundColor3 = Color3.fromRGB(180,180,180),
                BorderSizePixel  = 0,
                ZIndex           = 51,
                Parent           = picker,
            })
            rnd(alphaBar, 3)
            alphaFill = inst("Frame", {
                Size             = UDim2.new(alpha, 0, 1, 0),
                BackgroundColor3 = color,
                BorderSizePixel  = 0,
                ZIndex           = 52,
                Parent           = alphaBar,
            })
            rnd(alphaFill, 3)

            local aDrag = false
            alphaBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    aDrag = true
                    alpha = math.clamp((i.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                    s.alpha = alpha
                    alphaFill.Size = UDim2.new(alpha, 0, 1, 0)
                    if opts.Callback then opts.Callback(color, alpha) end
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if aDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                    alpha = math.clamp((i.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                    s.alpha = alpha
                    alphaFill.Size = UDim2.new(alpha, 0, 1, 0)
                    if opts.Callback then opts.Callback(color, alpha) end
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then aDrag = false end
            end)
        end

        -- Hex input row
        local hexY = 8 + svH + (hasAlpha and 22 or 8)
        local hexRow = inst("Frame", {
            Size             = UDim2.new(0, 180, 0, 24),
            Position         = UDim2.new(0, 8, 0, hexY),
            BackgroundTransparency = 1,
            ZIndex           = 51,
            Parent           = picker,
        })
        inst("TextLabel", {
            Size             = UDim2.new(0, 12, 1, 0),
            BackgroundTransparency = 1,
            Text             = "#",
            TextColor3       = T.TextFaint,
            Font             = Enum.Font.Code,
            TextSize         = 12,
            ZIndex           = 51,
            Parent           = hexRow,
        })
        local hexBox = inst("TextBox", {
            Size             = UDim2.new(1, -16, 1, -4),
            Position         = UDim2.new(0, 16, 0, 2),
            BackgroundColor3 = T.BgDark,
            Text             = string.format("%02X%02X%02X", color.R*255, color.G*255, color.B*255),
            TextColor3       = T.Text,
            Font             = Enum.Font.Code,
            TextSize         = 11,
            BorderSizePixel  = 0,
            ZIndex           = 51,
            Parent           = hexRow,
        })
        rnd(hexBox, 3)

        local h_, sat_, v_ = Color3.toHSV(color)

        local function applySV()
            svCursor.Position = UDim2.new(sat_, -4, 1 - v_, -4)
        end

        local function applyColor()
            local nc = Color3.fromHSV(h_, sat_, v_)
            color, s.value = nc, nc
            swatch.BackgroundColor3 = nc
            hexL.Text = string.format("#%02X%02X%02X", nc.R*255, nc.G*255, nc.B*255)
            hexBox.Text = string.format("%02X%02X%02X", nc.R*255, nc.G*255, nc.B*255)
            svBase.BackgroundColor3 = Color3.fromHSV(h_, 1, 1)
            if alphaFill then alphaFill.BackgroundColor3 = nc end
            if opts.Callback then opts.Callback(nc, alpha) end
        end

        -- SV drag
        local svDrag = false
        svBase.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                svDrag = true
                sat_ = math.clamp((i.Position.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
                v_   = 1 - math.clamp((i.Position.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
                applySV(); applyColor()
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if svDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                sat_ = math.clamp((i.Position.X - svBase.AbsolutePosition.X) / svBase.AbsoluteSize.X, 0, 1)
                v_   = 1 - math.clamp((i.Position.Y - svBase.AbsolutePosition.Y) / svBase.AbsoluteSize.Y, 0, 1)
                applySV(); applyColor()
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
        end)

        -- Hue drag
        local hueDrag = false
        hueBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDrag = true
                h_ = math.clamp((i.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                hueCursor.Position = UDim2.new(0, -2, h_, -1)
                applyColor()
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if hueDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                h_ = math.clamp((i.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                hueCursor.Position = UDim2.new(0, -2, h_, -1)
                applyColor()
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
        end)

        -- Hex commit
        hexBox.FocusLost:Connect(function()
            local hex = hexBox.Text:gsub("[^%x]", ""):sub(1, 6)
            if #hex == 6 then
                local r = tonumber(hex:sub(1,2), 16) / 255
                local g = tonumber(hex:sub(3,4), 16) / 255
                local b = tonumber(hex:sub(5,6), 16) / 255
                color = Color3.new(r, g, b)
                h_, sat_, v_ = Color3.toHSV(color)
                applySV(); applyColor()
            end
        end)

        -- Toggle picker visibility
        local pOpen = false
        swatch.MouseButton1Click:Connect(function()
            pOpen = not pOpen
            if pOpen then
                local ap = swatch.AbsolutePosition
                local sg = self.sg.AbsoluteSize
                local px = math.clamp(ap.X - 208, 0, sg.X - 208)
                local py = math.clamp(ap.Y - 90,  0, sg.Y - pickerH - 4)
                picker.Position = UDim2.new(0, px, 0, py)
                applySV()
            end
            picker.Visible = pOpen
        end)

        -- Close picker on outside click
        self.sg.InputBegan:Connect(function(i)
            if not pOpen or i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local mx, my = i.Position.X, i.Position.Y
            local pp, ps = picker.AbsolutePosition, picker.AbsoluteSize
            if mx < pp.X or mx > pp.X+ps.X or my < pp.Y or my > pp.Y+ps.Y then
                pOpen = false; picker.Visible = false
            end
        end)

        table.insert(m.settings, s)
        return s
    end

    function m:AddLabel(opts)
        opts = opts or {}
        m.gear.Visible = true
        local lbl = inst("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text             = opts.Text or "",
            TextColor3       = opts.Color or T.TextFaint,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Font             = Enum.Font.Gotham,
            TextSize         = 10,
            TextWrapped      = true,
            LayoutOrder      = #m.settings + 1,
            ZIndex           = 27,
            Parent           = m.sl,
        })
        return lbl
    end

    function m:AddSeparator()
        m.gear.Visible = true
        local sep = inst("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.Border,
            BorderSizePixel  = 0,
            LayoutOrder      = #m.settings + 1,
            ZIndex           = 27,
            Parent           = m.sl,
        })
        return sep
    end

    -- fire initial callback if pre-enabled
    table.insert(tab.modules, m)
    if m.enabled and m.cb then task.spawn(m.cb, true) end

    return m
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Notifications
-- ─────────────────────────────────────────────────────────────────────────────
function ClickLib:Notify(title, body, duration, color)
    duration = duration or 3
    color    = color or self.T.Accent
    local T  = self.T

    -- Nudge existing notifs upward
    for _, n in ipairs(self._notifs) do
        local p = n.Position
        tw(n, { Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset - 72) }, 0.18)
    end

    local notif = inst("Frame", {
        Size             = UDim2.new(0, 240, 0, 62),
        Position         = UDim2.new(1, 12, 1, -16),
        AnchorPoint      = Vector2.new(0, 1),
        BackgroundColor3 = T.NotifBg,
        BorderSizePixel  = 0,
        ZIndex           = 90,
        Parent           = self.sg,
    })
    rnd(notif, 7)
    brd(notif, color)

    -- Left color bar
    local bar = inst("Frame", {
        Size             = UDim2.new(0, 3, 1, -14),
        Position         = UDim2.new(0, 5, 0, 7),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = 91,
        Parent           = notif,
    })
    rnd(bar, 2)

    inst("TextLabel", {
        Size             = UDim2.new(1, -22, 0, 18),
        Position         = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = T.Text,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        ZIndex           = 91,
        Parent           = notif,
    })
    inst("TextLabel", {
        Size             = UDim2.new(1, -22, 0, 26),
        Position         = UDim2.new(0, 16, 0, 26),
        BackgroundTransparency = 1,
        Text             = body,
        TextColor3       = T.TextDim,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        ZIndex           = 91,
        Parent           = notif,
    })

    -- Progress drain
    local prog = inst("Frame", {
        Size             = UDim2.new(1, -8, 0, 2),
        Position         = UDim2.new(0, 4, 1, -4),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = 91,
        Parent           = notif,
    })
    rnd(prog, 1)

    table.insert(self._notifs, notif)

    -- Slide in
    tw(notif, { Position = UDim2.new(1, -252, 1, -16) }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenS:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 0, 2) }):Play()

    task.delay(duration, function()
        tw(notif, { Position = UDim2.new(1, 12, 1, -16) }, 0.22)
        task.wait(0.25)
        local idx = table.find(self._notifs, notif)
        if idx then table.remove(self._notifs, idx) end
        notif:Destroy()
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Config  (executor filesystem or getgenv fallback)
-- ─────────────────────────────────────────────────────────────────────────────
function ClickLib:SaveConfig(name)
    local cfg = {}
    for _, tab in ipairs(self.tabs) do
        cfg[tab.name] = {}
        for _, mod in ipairs(tab.modules) do
            local entry = { enabled = mod.enabled, key = KB:getKey(mod.kbId), settings = {} }
            for i, s in ipairs(mod.settings) do
                if s.type == "colorpicker" then
                    entry.settings[i] = { r = s.value.R, g = s.value.G, b = s.value.B, a = s.alpha }
                elseif s.type == "dropdown" and type(s.value) == "table" then
                    local t = {}
                    for k, v in pairs(s.value) do if v then table.insert(t, k) end end
                    entry.settings[i] = t
                else
                    entry.settings[i] = s.value
                end
            end
            cfg[tab.name][mod.name] = entry
        end
    end

    local ok, json = pcall(function() return HttpS:JSONEncode(cfg) end)
    if not ok then return end

    local fname = "clicklib_" .. (name or "default") .. ".json"
    if writefile then
        writefile(fname, json)
    else
        getgenv()._ClickLibCfg = cfg
    end
end

function ClickLib:LoadConfig(name)
    local cfg
    local fname = "clicklib_" .. (name or "default") .. ".json"

    if readfile then
        local ok, content = pcall(readfile, fname)
        if ok then
            local ok2, decoded = pcall(function() return HttpS:JSONDecode(content) end)
            if ok2 then cfg = decoded end
        end
    end

    if not cfg and getgenv()._ClickLibCfg then
        cfg = getgenv()._ClickLibCfg
    end

    if not cfg then return end

    for _, tab in ipairs(self.tabs) do
        local tc = cfg[tab.name]
        if not tc then continue end
        for _, mod in ipairs(tab.modules) do
            local mc = tc[mod.name]
            if not mc then continue end
            if mc.enabled ~= mod.enabled then mod:setEnabled(mc.enabled) end
            if mc.key then KB:setKey(mod.kbId, mc.key) end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public helpers
-- ─────────────────────────────────────────────────────────────────────────────
function ClickLib:Toggle()
    self.visible = not self.visible
    self.win.Visible = self.visible
end

function ClickLib:ToggleKeybindPanel()
    self.kbPanel.Visible = not self.kbPanel.Visible
end

function ClickLib:SetToggleKey(key)
    self.toggleKey = key
end

function ClickLib:SetTheme(overrides)
    for k, v in pairs(overrides) do self.T[k] = v end
end

function ClickLib:Destroy()
    if self.sg then self.sg:Destroy() end
end

return ClickLib
