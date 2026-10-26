-- dont mind this beauty of vibecoding
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local pixelAsset = (function()
    pcall(writefile, "px.ttf", game:HttpGet("https://raw.githubusercontent.com/britzl/gbrausers/master/assets/font/smallest_pixel-7.ttf"))
    return getcustomasset and getcustomasset("px.ttf")
end)()

local mcAsset = (function()
    pcall(writefile, "mc.ttf", game:HttpGet("https://github.com/exliation1337/Fonts/raw/refs/heads/main/Minecraft.ttf"))
    return getcustomasset and getcustomasset("mc.ttf")
end)()

local function makeFont(asset, fallback)
    if asset then return Font.new(asset, Enum.FontWeight.Regular, Enum.FontStyle.Normal) end
    return Font.fromEnum(fallback)
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Orca = {}
Orca.__index = Orca

Orca.Theme = {
	Background  = Color3.fromRGB(18, 18, 20),
	Panel       = Color3.fromRGB(13, 13, 15),
	Stroke      = Color3.fromRGB(38, 38, 42),
	Text        = Color3.fromRGB(220, 220, 225),
	SubText     = Color3.fromRGB(120, 120, 128),
	Disabled    = Color3.fromRGB(70, 70, 76),
	Risky       = Color3.fromRGB(220, 70, 70),
	TooltipBg   = Color3.fromRGB(10, 10, 12),
	Font        = makeFont(pixelAsset, Enum.Font.GothamSemibold),
	FontBody    = makeFont(mcAsset, Enum.Font.Gotham),

	-- swap to a custom Roblox Font asset (e.g. an uploaded Smallest Pixel-7):
	-- Font     = Font.new("rbxassetid://YOUR_ASSET_ID", Enum.FontWeight.Regular),
	-- FontBody = Font.new("rbxassetid://YOUR_ASSET_ID", Enum.FontWeight.Regular),
	-- then set TextLabel.FontFace = Theme.Font instead of TextLabel.Font in Create() calls.
}

local function Create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do
		if prop ~= "Parent" then inst[prop] = value end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local function Tween(inst, info, props)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function MakeDraggable(handle, target)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- hover tooltip anchored to an info glyph; body text + optional "risky - ..." line
local function AttachTooltip(anchor, text, riskyText)
	local tip
	anchor.MouseEnter:Connect(function()
		tip = Create("Frame", {
			Size = UDim2.fromOffset(190, riskyText and 54 or 36),
			Position = UDim2.new(0, anchor.AbsolutePosition.X - anchor:FindFirstAncestorWhichIsA("ScreenGui").AbsolutePosition.X + 16, 0, anchor.AbsolutePosition.Y - anchor:FindFirstAncestorWhichIsA("ScreenGui").AbsolutePosition.Y),
			BackgroundColor3 = Orca.Theme.TooltipBg,
			BorderSizePixel = 0,
			ZIndex = 50,
			Parent = anchor:FindFirstAncestorWhichIsA("ScreenGui"),
		}, {
			Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
			Create("UIStroke", {Color = Orca.Theme.Stroke}),
			Create("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}),
		})
		Create("TextLabel", {
			Text = text,
			FontFace = Orca.Theme.FontBody,
			TextSize = 12,
			TextColor3 = Orca.Theme.Text,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, riskyText and 32 or 24),
			ZIndex = 50,
			Parent = tip,
		})
		if riskyText then
			Create("TextLabel", {
				Text = riskyText,
				FontFace = Orca.Theme.FontBody,
				TextSize = 12,
				TextColor3 = Orca.Theme.Risky,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 34),
				ZIndex = 50,
				Parent = tip,
			})
		end
	end)
	anchor.MouseLeave:Connect(function()
		if tip then tip:Destroy(); tip = nil end
	end)
end

function Orca.new(title, user, tag)
	local self = setmetatable({}, Orca)

	self.ScreenGui = Create("ScreenGui", {
		Name = "OrcaStyleUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	self.Main = Create("Frame", {
		Size = UDim2.fromOffset(620, 420),
		Position = UDim2.new(0.5, -310, 0.5, -210),
		BackgroundColor3 = Orca.Theme.Background,
		BorderSizePixel = 0,
		Parent = self.ScreenGui,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
		Create("UIStroke", {Color = Orca.Theme.Stroke}),
	})

	self.TabBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = self.Main,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 28),
		}),
	})
	MakeDraggable(self.TabBar, self.Main)

	self.Body = Create("Frame", {
		Size = UDim2.new(1, -16, 1, -60),
		Position = UDim2.fromOffset(8, 36),
		BackgroundTransparency = 1,
		Parent = self.Main,
	})

	self.Footer = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 1, -24),
		BackgroundTransparency = 1,
		Parent = self.Main,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
	})
	Create("Frame", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(8, 3),
		BackgroundColor3 = Orca.Theme.Stroke,
		Parent = self.Footer,
	}, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
	Create("TextLabel", {
		Text = user or "user@domain.cc",
		FontFace = Orca.Theme.Font,
		TextSize = 11,
		TextColor3 = Orca.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(200, 12),
		Position = UDim2.fromOffset(32, -1),
		Parent = self.Footer,
	})
	Create("TextLabel", {
		Text = tag or "",
		FontFace = Orca.Theme.FontBody,
		TextSize = 11,
		TextColor3 = Orca.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(200, 12),
		Position = UDim2.fromOffset(32, 10),
		Parent = self.Footer,
	})
	-- bottom-right resize grip; wire to UserInputService drag on target if resizing is wanted
	Create("ImageLabel", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031094678", -- generic diagonal-lines placeholder; swap for your own asset
		ImageColor3 = Orca.Theme.SubText,
		Parent = self.Main,
	})

	self.Tabs = {}
	self._active = nil
	return self
end

function Orca:CreateTab(name)
	local tab = {Sections = {}}

	local btn = Create("TextButton", {
		Size = UDim2.fromOffset(90, 34),
		BackgroundTransparency = 1,
		Text = name,
		FontFace = Orca.Theme.Font,
		TextSize = 13,
		TextColor3 = Orca.Theme.SubText,
		AutoButtonColor = false,
		Parent = self.TabBar,
	})
	local underline = Create("Frame", {
		Size = UDim2.new(0, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 1, -2),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Orca.Theme.Text,
		Parent = btn,
	})

	local page = Create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Body,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 8),
		}),
	})

	tab.Button, tab.Underline, tab.Page = btn, underline, page
	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

	table.insert(self.Tabs, tab)
	if not self._active then self:SelectTab(tab) end

	return setmetatable(tab, {__index = self})
end

function Orca:SelectTab(tab)
	if self._active == tab then return end
	for _, t in ipairs(self.Tabs) do
		local active = t == tab
		t.Page.Visible = active
		Tween(t.Button, FAST, {TextColor3 = active and Orca.Theme.Text or Orca.Theme.SubText})
		Tween(t.Underline, FAST, {Size = active and UDim2.new(1, 0, 0, 2) or UDim2.new(0, 0, 0, 2)})
	end
	self._active = tab
end

-- two-column flow; column = 1 (left) or 2 (right) just picks which side's layout order it lands in
function Orca.AddColumn(tab)
	local col = Create("Frame", {
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		Parent = tab.Page,
	}, {
		Create("UIListLayout", {Padding = UDim.new(0, 8)}),
	})
	return col
end

function Orca.AddSection(column, title)
	local panel = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Orca.Theme.Panel,
		BorderSizePixel = 0,
		Parent = column,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
		Create("UIStroke", {Color = Orca.Theme.Stroke}),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		}),
		Create("UIListLayout", {Padding = UDim.new(0, 6)}),
	})
	Create("TextLabel", {
		Text = title,
		FontFace = Orca.Theme.Font,
		TextSize = 13,
		TextColor3 = Orca.Theme.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		Parent = panel,
	})
	return panel
end

-- checkbox row with optional info-icon tooltip ("desc", "risky - ...")
function Orca.AddCheckbox(section, text, opts)
	opts = opts or {}
	local state = opts.Default or false
	local order = opts.Order or 1

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = section,
	})

	local box = Create("TextButton", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(0, 2),
		BackgroundColor3 = state and Orca.Theme.Text or Color3.fromRGB(0,0,0),
		BackgroundTransparency = state and 0 or 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, {Create("UIStroke", {Color = Orca.Theme.Stroke})})

	Create("TextLabel", {
		Text = text,
		FontFace = Orca.Theme.FontBody,
		TextSize = 12,
		TextColor3 = opts.Disabled and Orca.Theme.Disabled or Orca.Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.fromOffset(18, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	box.MouseButton1Click:Connect(function()
		if opts.Disabled then return end
		state = not state
		Tween(box, FAST, {BackgroundTransparency = state and 0 or 1})
		if opts.Callback then opts.Callback(state) end
	end)

	if opts.Info then
		local info = Create("TextLabel", {
			Text = "i",
			FontFace = Orca.Theme.FontBody,
			TextSize = 10,
			TextColor3 = Orca.Theme.SubText,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(1, -14, 0, 1),
			Parent = row,
		})
		AttachTooltip(info, opts.Info, opts.Risky)
	end

	return {Set = function(_, v) state = v; box.BackgroundTransparency = v and 0 or 1 end}
end

-- small swatch button that opens a flat color grid; picking fires Callback(Color3)
function Orca.AddColorSwatch(parent, default, callback)
	local swatch = Create("TextButton", {
		Size = UDim2.fromOffset(16, 12),
		BackgroundColor3 = default or Color3.fromRGB(80, 80, 255),
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	}, {Create("UICorner", {CornerRadius = UDim.new(0, 2)})})

	local palette = {Color3.fromRGB(255,60,60), Color3.fromRGB(60,255,120), Color3.fromRGB(60,140,255),
		Color3.fromRGB(255,220,60), Color3.fromRGB(200,80,255), Color3.fromRGB(255,255,255)}

	local grid
	swatch.MouseButton1Click:Connect(function()
		if grid then grid:Destroy(); grid = nil; return end
		grid = Create("Frame", {
			Size = UDim2.fromOffset(#palette * 18, 18),
			Position = UDim2.new(0, 0, 1, 4),
			BackgroundColor3 = Orca.Theme.TooltipBg,
			ZIndex = 50,
			Parent = swatch,
		}, {
			Create("UIStroke", {Color = Orca.Theme.Stroke}),
			Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal}),
		})
		for _, c in ipairs(palette) do
			local cell = Create("TextButton", {
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = c,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 51,
				Parent = grid,
			})
			cell.MouseButton1Click:Connect(function()
				swatch.BackgroundColor3 = c
				if callback then callback(c) end
				grid:Destroy(); grid = nil
			end)
		end
	end)
	return swatch
end

-- labeled stepper slider: "- [=====value=====] +"; value rendered centered in the fill bar
function Orca.AddSlider(section, text, opts)
	opts = opts or {}
	local min, max, step = opts.Min or 0, opts.Max or 100, opts.Step or 1
	local value = opts.Default or min
	local suffix = opts.Suffix or ""
	local order = opts.Order or 1

	local wrap = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = section,
	})
	Create("TextLabel", {
		Text = text,
		FontFace = Orca.Theme.FontBody,
		TextSize = 12,
		TextColor3 = Orca.Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = wrap,
	})

	local minus = Create("TextButton", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(0, 16),
		BackgroundTransparency = 1,
		Text = "-",
		FontFace = Orca.Theme.FontBody,
		TextSize = 14,
		TextColor3 = Orca.Theme.SubText,
		Parent = wrap,
	})
	local plus = Create("TextButton", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -14, 0, 16),
		BackgroundTransparency = 1,
		Text = "+",
		FontFace = Orca.Theme.FontBody,
		TextSize = 14,
		TextColor3 = Orca.Theme.SubText,
		Parent = wrap,
	})
	local track = Create("Frame", {
		Size = UDim2.new(1, -36, 0, 14),
		Position = UDim2.fromOffset(18, 16),
		BackgroundColor3 = Orca.Theme.Stroke,
		Parent = wrap,
	}, {Create("UICorner", {CornerRadius = UDim.new(0, 2)})})
	local fill = Create("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = Orca.Theme.Text,
		BackgroundTransparency = 0.7,
		Parent = track,
	}, {Create("UICorner", {CornerRadius = UDim.new(0, 2)})})
	local valueLabel = Create("TextLabel", {
		Text = tostring(value) .. suffix,
		FontFace = Orca.Theme.Font,
		TextSize = 11,
		TextColor3 = Orca.Theme.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = track,
	})

	local function apply(v)
		value = math.clamp(v, min, max)
		fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
		valueLabel.Text = tostring(value) .. suffix
		if opts.Callback then opts.Callback(value) end
	end

	minus.MouseButton1Click:Connect(function() apply(value - step) end)
	plus.MouseButton1Click:Connect(function() apply(value + step) end)

	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local scale = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			apply(min + (max - min) * scale)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local scale = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			apply(min + (max - min) * scale)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return {Set = apply}
end

-- "mode" style dropdown: button with "=" glyph opens a list that overlays below, matching the extra/mode example
function Orca.AddModeDropdown(section, text, options, opts)
	opts = opts or {}
	local selected = opts.Default or options[1]
	local open = false

	local wrap = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = opts.Order or 1,
		ZIndex = 10,
		Parent = section,
	})
	Create("TextLabel", {
		Text = text,
		FontFace = Orca.Theme.FontBody,
		TextSize = 12,
		TextColor3 = Orca.Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = wrap,
	})
	local head = Create("TextButton", {
		Size = UDim2.fromOffset(16, 14),
		Position = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = Orca.Theme.Stroke,
		Text = "=",
		FontFace = Orca.Theme.FontBody,
		TextSize = 11,
		TextColor3 = Orca.Theme.SubText,
		AutoButtonColor = false,
		ZIndex = 11,
		Parent = wrap,
	}, {Create("UICorner", {CornerRadius = UDim.new(0, 2)})})

	local list = Create("Frame", {
		Size = UDim2.fromOffset(80, #options * 18),
		Position = UDim2.new(1, -80, 1, 2),
		BackgroundColor3 = Orca.Theme.TooltipBg,
		Visible = false,
		ZIndex = 20,
		Parent = wrap,
	}, {
		Create("UIStroke", {Color = Orca.Theme.Stroke}),
		Create("UIListLayout", {}),
	})
	for _, optText in ipairs(options) do
		local optBtn = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = optText,
			FontFace = Orca.Theme.FontBody,
			TextSize = 11,
			TextColor3 = optText == selected and Orca.Theme.Text or Orca.Theme.SubText,
			ZIndex = 21,
			Parent = list,
		})
		optBtn.MouseButton1Click:Connect(function()
			selected = optText
			for _, c in ipairs(list:GetChildren()) do
				if c:IsA("TextButton") then c.TextColor3 = c.Text == selected and Orca.Theme.Text or Orca.Theme.SubText end
			end
			open = false
			list.Visible = false
			if opts.Callback then opts.Callback(selected) end
		end)
	end

	head.MouseButton1Click:Connect(function()
		open = not open
		list.Visible = open
	end)

	return {Set = function(_, v) selected = v end}
end

return Orca
