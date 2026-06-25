-- ── Services ─────────────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local UIS          = game:GetService("UserInputService")

-- ── Themes ────────────────────────────────────────────────────────────────────
local Themes = {
	JWare  = { main = Color3.fromRGB(70,7,100),   outline = Color3.fromRGB(0,0,0), bg  = Color3.fromRGB(27,27,27), bg2 = Color3.fromRGB(16,16,16) },
	JWare2 = { main = Color3.fromRGB(135,0,2),    outline = Color3.fromRGB(0,0,0), bg  = Color3.fromRGB(27,27,27), bg2 = Color3.fromRGB(16,16,16) },
	JWare3 = { main = Color3.fromRGB(45,100,10),    outline = Color3.fromRGB(0,0,0), bg  = Color3.fromRGB(27,27,27), bg2 = Color3.fromRGB(16,16,16) },
}

theme = Themes.JWare3

-- ── Constants ─────────────────────────────────────────────────────────────────
local VIEWPORT   = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local MB1        = Enum.UserInputType.MouseButton1
local MOUSE_MOVE = Enum.UserInputType.MouseMovement

local COLOR_ELEM_BG      = Color3.fromRGB(26, 26, 26)
local COLOR_TEXT_NORMAL  = Color3.fromRGB(200, 200, 200)
local COLOR_TEXT_HOVER   = Color3.fromRGB(255, 255, 255)
local COLOR_TEXT_DIM     = Color3.fromRGB(150, 150, 150)

-- ════════════════════════════════════════════════════════════════════════════
--  Shared Helpers
-- ════════════════════════════════════════════════════════════════════════════

local function tween(obj, goal, callback)
	local t = TweenService:Create(obj, TWEEN_INFO, goal)
	if callback then t.Completed:Connect(callback) end
	t:Play()
	return t
end

local function getGuiParent()
	if RunService:IsStudio() then
		local lp = Players.LocalPlayer
		return lp and lp:FindFirstChildOfClass("PlayerGui") or CoreGui
	end
	local ok = pcall(function() return CoreGui.Parent end)
	return ok and CoreGui or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui)
end

local function toTextAlign(v)
	if typeof(v) == "EnumItem" and v.EnumType == Enum.TextXAlignment then return v end
	if typeof(v) == "string" then
		local s = v:lower()
		if s == "left"  then return Enum.TextXAlignment.Left  end
		if s == "right" then return Enum.TextXAlignment.Right end
	end
	return Enum.TextXAlignment.Center
end

local function applyDefaults(defaults, opts)
	for k, v in pairs(defaults) do
		if opts[k] == nil then opts[k] = v end
	end
end

-- ── Instance factories ────────────────────────────────────────────────────────

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function makeFrame(props, parent)
	props.BorderSizePixel = props.BorderSizePixel ~= nil and props.BorderSizePixel or 0
	return make("Frame", props, parent)
end

local function makeLabel(props, parent)
	props.BackgroundTransparency = props.BackgroundTransparency ~= nil and props.BackgroundTransparency or 1
	props.BorderSizePixel        = 0
	return make("TextLabel", props, parent)
end

local function makeScreenGui(name, parent)
	return make("ScreenGui", {
		Name            = name,
		IgnoreGuiInset  = true,
		ResetOnSpawn    = false,
		ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
	}, parent)
end

local function makeStroke(parent, color, thickness, mode)
	return make("UIStroke", {
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border,
		Color           = color or Color3.new(),
		Thickness       = thickness or 1,
	}, parent)
end

local function makeListLayout(parent, props)
	props = props or {}
	props.SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder
	return make("UIListLayout", props, parent)
end

-- ── Behaviour helpers ─────────────────────────────────────────────────────────

local function makeDraggable(handle, target, speed)
	speed = speed or 0.2
	local dragging, dragStart, startPos = false, Vector2.zero, target.Position
	local goalPos = target.Position

	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= MB1 then return end
		dragging  = true
		dragStart = input.Position
		startPos  = target.Position
		goalPos   = startPos
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == MOUSE_MOVE then
			local delta = input.Position - dragStart
			goalPos = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
		end
	end)

	RunService.RenderStepped:Connect(function()
		target.Position = target.Position:Lerp(goalPos, speed)
	end)
end

local function matchesKey(input, keyName)
	if not keyName or keyName == "None" or keyName == "" then return false end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode.Name == keyName
	elseif input.UserInputType.Name:match("MouseButton") and keyName:match("^MB%d$") then
		return ("MB" .. (input.UserInputType.Value - Enum.UserInputType.MouseButton1.Value + 1)) == keyName
	end
	return false
end

local function inputToKeyName(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return (input.KeyCode == Enum.KeyCode.Escape) and "None" or input.KeyCode.Name
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then return "MB1"
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then return "MB2"
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then return "MB3"
	end
end

local function startListening(label, onBound)
	label.Text = "..."
	task.defer(function()
		local conn
		conn = UIS.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			local name = inputToKeyName(input)
			if name then conn:Disconnect(); label.Text = name; onBound(name) end
		end)
	end)
end

-- ── Color helpers ─────────────────────────────────────────────────────────────

local function colorToHex(c)
	return string.format("%02X%02X%02X",
		math.floor(c.R * 255 + .5),
		math.floor(c.G * 255 + .5),
		math.floor(c.B * 255 + .5))
end

local function hexToColor(hex)
	hex = hex:gsub("#", ""):upper()
	if #hex ~= 6 then return nil end
	local r, g, b = tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
	return (r and g and b) and Color3.fromRGB(r, g, b) or nil
end

-- ════════════════════════════════════════════════════════════════════════════
--  Window Constructor
-- ════════════════════════════════════════════════════════════════════════════

local function CreateWindow(opts)
	opts = opts or {}
	applyDefaults({ Title = "JWare UI", TextAlignment = "Center", Size = Vector2.new(700, 550) }, opts)

	local W, H       = opts.Size.X, opts.Size.Y
	local Window     = { tabs = {}, currentTab = nil, keybindLabels = {} }

	-- ── Popup management ──────────────────────────────────────────────────────
	local activePopup = nil
	local function closePopup()
		if activePopup then activePopup.Visible = false; activePopup = nil end
	end

	-- ── Theme registry (track objects for bulk re-color) ──────────────────────
	local tracked = {
		mainStrokes = {}, outlineStrokes = {}, gradients = {},
		fills = {}, scrollbars = {}, bgFrames = {}, bg2Frames = {},
		tabButtons = {}, activeChecks = {}, activeOptionLabels = {},
	}

	local function track(list, item) table.insert(list, item); return item end

	local function addMainStroke(parent, thickness)
		return track(tracked.mainStrokes, makeStroke(parent, theme.main, thickness or 2))
	end
	local function addOutlineStroke(parent, thickness)
		return track(tracked.outlineStrokes, makeStroke(parent, theme.outline, thickness or 2))
	end

	local function bgFrame(props, parent)
		local f = makeFrame(props, parent)
		track(tracked.bgFrames, f)
		return f
	end
	local function bg2Frame(props, parent)
		local f = makeFrame(props, parent)
		track(tracked.bg2Frames, f)
		return f
	end

	function Window:ApplyTheme(newTheme)
		for _, s in ipairs(tracked.mainStrokes)       do if s and s.Parent then s.Color = newTheme.main    end end
		for _, s in ipairs(tracked.outlineStrokes)    do if s and s.Parent then s.Color = newTheme.outline end end
		for _, g in ipairs(tracked.gradients)         do if g and g.Parent then g.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, newTheme.main), ColorSequenceKeypoint.new(1, newTheme.bg2) } end end
		for _, f in ipairs(tracked.fills)             do if f and f.Parent then f.BackgroundColor3 = newTheme.main end end
		for _, sf in ipairs(tracked.scrollbars)       do if sf and sf.Parent then sf.ScrollBarImageColor3 = newTheme.main end end
		for _, fr in ipairs(tracked.bgFrames)         do if fr and fr.Parent then fr.BackgroundColor3 = newTheme.bg  end end
		for _, fr in ipairs(tracked.bg2Frames)        do if fr and fr.Parent then fr.BackgroundColor3 = newTheme.bg2 end end
		for _, btn in ipairs(tracked.tabButtons)      do if btn and btn.Parent and btn.BackgroundTransparency == 0 then btn.BackgroundColor3 = newTheme.main end end
		for _, c in ipairs(tracked.activeChecks)      do if c and c.Parent then c.BackgroundColor3 = newTheme.main end end
		for _, l in ipairs(tracked.activeOptionLabels)do if l and l.Parent then l.BackgroundColor3 = newTheme.main end end
		theme = newTheme
	end

	-- ── Screen GUIs ───────────────────────────────────────────────────────────
	local guiParent  = getGuiParent()
	local mainGui    = makeScreenGui("JWare UI",            guiParent)
	local overlayGui = makeScreenGui("JWare UI Watermarks", guiParent)
	Window._mainGui    = mainGui
	Window._overlayGui = overlayGui

	-- ── Main frame ────────────────────────────────────────────────────────────
	local mainFrame = bgFrame({
		Name            = "MainFrame",
		BackgroundColor3 = theme.bg,
		Size            = UDim2.new(0, W, 0, H),
		Position        = UDim2.fromOffset(math.floor(VIEWPORT.X/2 - W/2), math.floor(VIEWPORT.Y/2 - H/2)),
	}, mainGui)
	addMainStroke(mainFrame)

	local titleBar = bgFrame({ Name = "TitleBar", BackgroundColor3 = theme.bg, Size = UDim2.new(0, W, 0, 30) }, mainFrame)

	makeLabel({
		Name             = "Title",
		Size             = UDim2.new(0, W - 20, 1, 0),
		Position         = UDim2.new(0, 10, 0, 0),
		Text             = opts.Title,
		TextSize         = 15,
		TextColor3       = Color3.fromRGB(255, 255, 255),
		TextXAlignment   = toTextAlign(opts.TextAlignment),
		FontFace         = Font.new("rbxasset://fonts/families/DenkOne.json"),
	}, titleBar)

	local contentFrame = bg2Frame({
		Name             = "ContentFrame",
		BackgroundColor3 = theme.bg2,
		Size             = UDim2.new(0, W - 10, 0, H - 35),
		Position         = UDim2.new(0, 5, 0, 30),
	}, mainFrame)
	addOutlineStroke(contentFrame)

	local tabsBar = bg2Frame({ Name = "TabsBar", BackgroundColor3 = theme.bg2, Size = UDim2.new(1, 0, 0, 40) }, contentFrame)
	addOutlineStroke(tabsBar)

	local tabButtonHolder = makeFrame({ Name = "TabButtonHolder", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, tabsBar)
	makeListLayout(tabButtonHolder, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2) })
	make("UIPadding", { PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1) }, tabButtonHolder)

	-- ── Popup overlay (shared by dropdowns & color pickers) ───────────────────
	local popupOverlay = makeFrame({
		Name = "PopupOverlay", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 200,
	}, mainGui)

	-- ── Keybind panel ─────────────────────────────────────────────────────────
	local keybindFrame = bgFrame({
		Name             = "KeybindFrame",
		BackgroundColor3 = theme.bg,
		Size             = UDim2.new(0, 150, 0, 100),
		Position         = UDim2.new(0, 5, 0, 600),
		Visible          = false,
	}, overlayGui)
	addMainStroke(keybindFrame)

	local keybindContent = bg2Frame({
		Name             = "Content",
		BackgroundColor3 = theme.bg2,
		Size             = UDim2.new(0, 140, 0, 90),
		Position         = UDim2.new(0, 5, 0, 5),
	}, keybindFrame)
	addOutlineStroke(keybindContent, 1)
	makeListLayout(keybindContent, { HorizontalFlex = Enum.UIFlexAlignment.SpaceAround })
	make("UIPadding", { PaddingBottom = UDim.new(0, 5) }, keybindContent)

	local kbTitleRow = makeFrame({ Name = "TitleRow", BackgroundTransparency = 1, Size = UDim2.new(0, 130, 0, 15) }, keybindContent)
	makeLabel({ Size = UDim2.new(1, 0, 1, 0), Text = "Keybinds", TextSize = 12, TextColor3 = Color3.fromRGB(255,255,255), FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json") }, kbTitleRow)

	local kbVisible = false
	function Window:ToggleKeybinds(state)
		kbVisible = (state == nil) and not kbVisible or state
		keybindFrame.Visible = kbVisible
	end

	function Window:AddKeybind(title, key)
		if self.keybindLabels[title] then
			local e = self.keybindLabels[title]
			e.keyLabel.Text       = key
			e.keyLabel.TextColor3 = (key == "None") and COLOR_TEXT_DIM or Color3.fromRGB(255,255,255)
			return
		end
		local row = makeFrame({ Name = "KB_"..title, BackgroundTransparency = 1, Size = UDim2.new(0, 130, 0, 15) }, keybindContent)
		makeLabel({ Size = UDim2.new(1,0,1,0), Text = title, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,  TextColor3 = Color3.fromRGB(255,255,255), FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json") }, row)
		local keyLabel = makeLabel({ Size = UDim2.new(1,0,1,0), Text = key,   TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = (key=="None") and COLOR_TEXT_DIM or Color3.fromRGB(255,255,255), FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json") }, row)
		self.keybindLabels[title] = { row = row, keyLabel = keyLabel }
	end

	function Window:SetKeybindActive(title, active)
		local e = self.keybindLabels[title]
		if e then tween(e.keyLabel, { TextColor3 = active and theme.main or Color3.fromRGB(255,255,255) }) end
	end

	-- ── Watermark panel ───────────────────────────────────────────────────────
	local watermarkFrame = bgFrame({
		Name             = "WatermarkFrame",
		BackgroundColor3 = theme.bg,
		Size             = UDim2.new(0, 400, 0, 30),
		Position         = UDim2.new(0, 5, 0, 60),
		Visible          = false,
	}, overlayGui)
	addMainStroke(watermarkFrame)

	local watermarkContent = bg2Frame({
		Name             = "Content",
		BackgroundColor3 = theme.bg2,
		Size             = UDim2.new(0, 390, 0, 20),
		Position         = UDim2.new(0, 5, 0, 5),
	}, watermarkFrame)
	addOutlineStroke(watermarkContent, 1)

	function Window:SetWatermark(text, alignment)
		for _, c in ipairs(watermarkContent:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		makeLabel({
			Size           = UDim2.new(1, 0, 1, 0),
			Text           = text,
			TextSize       = 13,
			TextColor3     = Color3.fromRGB(255, 255, 255),
			TextXAlignment = toTextAlign(alignment),
			FontFace       = Font.new("rbxasset://fonts/families/Ubuntu.json"),
		}, watermarkContent)
	end

	local wmVisible = false
	function Window:ToggleWatermark(state)
		wmVisible = (state == nil) and not wmVisible or state
		watermarkFrame.Visible = wmVisible
	end

	local uiVisible = true
	function Window:ToggleUI(state)
		uiVisible = (state == nil) and not uiVisible or state
		mainGui.Enabled = uiVisible
	end

	-- Draggable panels
	makeDraggable(titleBar,       mainFrame)
	makeDraggable(keybindFrame,   keybindFrame)
	makeDraggable(watermarkFrame, watermarkFrame)

	-- ════════════════════════════════════════════════════════════════════════
	--  Tab Constructor
	-- ════════════════════════════════════════════════════════════════════════

	function Window:AddTab(tabOpts)
		tabOpts = tabOpts or {}
		applyDefaults({ Title = "Tab", Icon = "rbxassetid://70562308088944" }, tabOpts)

		local Tab = { active = false, hover = false }

		local tabButton = makeLabel({
			Name                 = tabOpts.Title,
			BackgroundColor3     = theme.main,
			BackgroundTransparency = 1,
			TextSize             = 14,
			TextColor3           = COLOR_TEXT_DIM,
			FontFace             = Font.new("rbxasset://fonts/families/Ubuntu.json"),
			Text                 = tabOpts.Title,
			Size                 = UDim2.new(0, 100, 1, 0),
		}, tabButtonHolder)
		track(tracked.tabButtons, tabButton)
		make("UIPadding", { PaddingLeft = UDim.new(0, 26) }, tabButton)

		local tabIcon = make("ImageLabel", {
			BackgroundTransparency = 1,
			Image                  = tabOpts.Icon,
			ImageColor3            = COLOR_TEXT_DIM,
			Size                   = UDim2.new(0, 20, 0, 20),
			Position               = UDim2.new(0, -10, 0.25, 0),
			BorderSizePixel        = 0,
		}, tabButton)

		local container = bgFrame({
			Name             = tabOpts.Title .. "_Container",
			BackgroundColor3 = theme.bg,
			Size             = UDim2.new(1, -10, 0, H - 90),
			Position         = UDim2.new(0, 5, 0, 50),
			Visible          = false,
		}, contentFrame)
		addOutlineStroke(container)
		Tab.container = container

		function Tab:Activate()
			if self.active then return end
			if Window.currentTab then Window.currentTab:Deactivate() end
			self.active = true
			tween(tabButton, { TextColor3 = COLOR_TEXT_HOVER, BackgroundTransparency = 0, BackgroundColor3 = theme.main })
			tween(tabIcon,   { ImageColor3 = COLOR_TEXT_HOVER })
			container.Visible = true
			Window.currentTab = self
		end

		function Tab:Deactivate()
			if not self.active then return end
			self.active = false; self.hover = false
			tween(tabButton, { TextColor3 = COLOR_TEXT_DIM, BackgroundTransparency = 1 })
			tween(tabIcon,   { ImageColor3 = COLOR_TEXT_DIM })
			container.Visible = false
		end

		tabButton.MouseEnter:Connect(function() Tab.hover = true;  if not Tab.active then tween(tabButton, { TextColor3 = COLOR_TEXT_HOVER }); tween(tabIcon, { ImageColor3 = COLOR_TEXT_HOVER }) end end)
		tabButton.MouseLeave:Connect(function() Tab.hover = false; if not Tab.active then tween(tabButton, { TextColor3 = COLOR_TEXT_DIM  }); tween(tabIcon, { ImageColor3 = COLOR_TEXT_DIM  }) end end)
		UIS.InputBegan:Connect(function(input, gpe) if not gpe and input.UserInputType == MB1 and Tab.hover then Tab:Activate() end end)

		if Window.currentTab == nil then Tab:Activate() end
		table.insert(Window.tabs, Tab)

		-- ══════════════════════════════════════════════════════════════════
		--  Section Constructor
		-- ══════════════════════════════════════════════════════════════════

		function Tab:AddSection(secOpts)
			secOpts = secOpts or {}
			applyDefaults({ Title = "Section", Type = "Left" }, secOpts)

			local colOffsets = { Left = 5, Center = 231, Right = 457 }
			local colKey     = secOpts.Type .. "Col"

			if not self[colKey] then
				local col = makeFrame({
					Name                 = colKey,
					BackgroundTransparency = 1,
					Size                 = UDim2.new(0, 218, 1, -10),
					Position             = UDim2.new(0, colOffsets[secOpts.Type] or 5, 0, 5),
				}, container)
				makeListLayout(col, { Padding = UDim.new(0, 7) })
				self[colKey] = col
			end

			local sectionFrame = bg2Frame({
				Name             = secOpts.Title,
				BackgroundColor3 = theme.bg2,
				Size             = UDim2.new(0, 218, 0, 40),
			}, self[colKey])
			addOutlineStroke(sectionFrame)

			-- Gradient header accent
			local gradFade = makeFrame({ Name = "Fade", BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(1,0,0,20), ZIndex = 1 }, sectionFrame)
			local gradient = make("UIGradient", {
				Rotation     = 90,
				Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,0.5) },
				Color        = ColorSequence.new{ ColorSequenceKeypoint.new(0, theme.main), ColorSequenceKeypoint.new(1, theme.bg2) },
			}, gradFade)
			track(tracked.gradients, gradient)

			makeLabel({
				Name           = "Title",
				Size           = UDim2.new(1, 0, 0, 15),
				Position       = UDim2.new(0, 0, 0, 5),
				Text           = secOpts.Title,
				TextSize       = 14,
				TextColor3     = Color3.fromRGB(255, 255, 255),
				FontFace       = Font.new("rbxasset://fonts/families/Ubuntu.json"),
				ZIndex         = 3,
			}, sectionFrame)

			local elemHolder = makeFrame({
				Name                 = "ElementsHolder",
				BackgroundTransparency = 1,
				Position             = UDim2.new(0, 0, 0, 30),
				Size                 = UDim2.new(0, 218, 0, 0),
			}, sectionFrame)
			local elemLayout = makeListLayout(elemHolder, { Padding = UDim.new(0, 4) })
			make("UIPadding", { PaddingLeft = UDim.new(0, 5) }, elemHolder)

			elemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				sectionFrame.Size = UDim2.new(0, 218, 0, elemLayout.AbsoluteContentSize.Y + 40)
			end)

			local Section = { frame = sectionFrame, elemHolder = elemHolder }

			-- Shared hover helper for text labels inside elements
			local function hoverText(label)
				label.MouseEnter:Connect(function() tween(label, { TextColor3 = COLOR_TEXT_HOVER }) end)
				label.MouseLeave:Connect(function() tween(label, { TextColor3 = COLOR_TEXT_NORMAL }) end)
			end

			-- ── AddButton ────────────────────────────────────────────────────
			function Section:AddButton(cfg)
				cfg = cfg or {}
				applyDefaults({ Title = "Button", Callback = function() end }, cfg)

				local btn = make("TextLabel", {
					Name                 = cfg.Title,
					BackgroundColor3     = COLOR_ELEM_BG,
					BorderSizePixel      = 0,
					Size                 = UDim2.new(0, 208, 0, 20),
					Text                 = cfg.Title,
					TextSize             = 14,
					TextColor3           = COLOR_TEXT_NORMAL,
					Font                 = Enum.Font.Gotham,
					ClipsDescendants     = true,
				}, self.elemHolder)
				addOutlineStroke(btn, 1)
				hoverText(btn)

				btn.InputBegan:Connect(function(input)
					if input.UserInputType ~= MB1 then return end
					tween(btn, { BackgroundColor3 = theme.main }, function()
						tween(btn, { BackgroundColor3 = COLOR_ELEM_BG })
					end)
					cfg.Callback()
				end)

				return btn
			end

			-- ── AddToggle ────────────────────────────────────────────────────
			function Section:AddToggle(cfg)
				cfg = cfg or {}
				applyDefaults({
					Title          = "Toggle",
					Default        = false,
					Callback       = function() end,
					KeybindEnabled = false,
					KeyBind        = "None",
					Mode           = "Toggle",
					Sync           = false,
					KeyCallback    = function() end,
				}, cfg)

				local row   = makeFrame({ Name = cfg.Title, BackgroundTransparency = 1, Size = UDim2.new(0, 208, 0, 20) }, self.elemHolder)
				local check = makeFrame({ Name = "Check", BackgroundColor3 = COLOR_ELEM_BG, Size = UDim2.new(0,15,0,15), Position = UDim2.new(0,0,0,3) }, row)
				Instance.new("UICorner", check).CornerRadius = UDim.new(0, 2)
				addOutlineStroke(check, 1)

				local titleLabel = makeLabel({
					Name           = "Title",
					Size           = UDim2.new(0, 150, 1, 0),
					Position       = UDim2.new(0, 23, 0, 0),
					Text           = cfg.Title,
					TextSize       = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3     = COLOR_TEXT_NORMAL,
					Font           = Enum.Font.Gotham,
				}, row)

				local toggled   = cfg.Default
				local activeKey = cfg.KeyBind
				local keyState  = toggled

				local function refreshCheck(animate)
					-- sync theme tracker
					local idx = table.find(tracked.activeChecks, check)
					if toggled and not idx then
						table.insert(tracked.activeChecks, check)
					elseif not toggled and idx then
						table.remove(tracked.activeChecks, idx)
					end
					local col = toggled and theme.main or COLOR_ELEM_BG
					if animate then tween(check, { BackgroundColor3 = col }) else check.BackgroundColor3 = col end
				end
				refreshCheck(false)

				local keyLabel
				if cfg.KeybindEnabled then
					keyLabel = makeLabel({
						Size           = UDim2.new(0, 30, 0, 15),
						Position       = UDim2.new(0, 177, 0, 0),
						Text           = activeKey,
						TextSize       = 12,
						TextColor3     = toggled and theme.main or COLOR_TEXT_DIM,
						Font           = Enum.Font.GothamBold,
					}, row)
					Window:AddKeybind(cfg.Title, activeKey)
				end

				local function setKeyColor(state)
					if keyLabel then tween(keyLabel, { TextColor3 = state and theme.main or COLOR_TEXT_DIM }) end
					if cfg.KeybindEnabled then Window:SetKeybindActive(cfg.Title, state) end
				end

				local function doToggle()
					toggled = not toggled
					refreshCheck(true)
					cfg.Callback(toggled)
					if cfg.Sync then keyState = toggled; setKeyColor(toggled); cfg.KeyCallback("Sync", { Key = activeKey, Mode = cfg.Mode, State = toggled }) end
				end

				hoverText(titleLabel)
				titleLabel.InputBegan:Connect(function(i) if i.UserInputType == MB1 then doToggle() end end)
				check.InputBegan:Connect(function(i)      if i.UserInputType == MB1 then doToggle() end end)

				if cfg.KeybindEnabled then
					local kbHover, listening = false, false
					keyLabel.MouseEnter:Connect(function() kbHover = true  end)
					keyLabel.MouseLeave:Connect(function() kbHover = false end)

					UIS.InputBegan:Connect(function(input, gpe)
						if gpe then return end
						if kbHover and not listening and input.UserInputType == MB1 then
							listening = true
							startListening(keyLabel, function(name)
								listening = false; activeKey = name
								Window:AddKeybind(cfg.Title, name)
								cfg.KeyCallback("Changed", { Key = name, Mode = cfg.Mode })
							end)
							return
						end
						if not matchesKey(input, activeKey) then return end
						if cfg.Mode == "Toggle" then
							if cfg.Sync then toggled = not toggled; refreshCheck(true); keyState = toggled; setKeyColor(toggled); cfg.Callback(toggled); cfg.KeyCallback("Pressed", { Key=activeKey, Mode=cfg.Mode, State=toggled })
							else keyState = not keyState; setKeyColor(keyState); cfg.KeyCallback("Pressed", { Key=activeKey, Mode=cfg.Mode, State=keyState }) end
						elseif cfg.Mode == "Hold" then
							setKeyColor(true); cfg.KeyCallback("Pressed", { Key=activeKey, Mode=cfg.Mode, State=true })
						end
					end)
					UIS.InputEnded:Connect(function(input, gpe)
						if gpe or cfg.Mode ~= "Hold" then return end
						if matchesKey(input, activeKey) then setKeyColor(false); cfg.KeyCallback("Pressed", { Key=activeKey, Mode=cfg.Mode, State=false }) end
					end)
				end

				return {
					frame    = row,
					check    = check,
					keyLabel = keyLabel,
					GetState = function() return toggled end,
					SetState = function(v)
						if type(v) == "boolean" and toggled ~= v then
							toggled = v; refreshCheck(true); cfg.Callback(toggled)
							if cfg.Sync then keyState = toggled; setKeyColor(toggled) end
						end
					end,
					GetKey   = function() return activeKey end,
					SetKey   = function(v)
						if v ~= activeKey then activeKey = v; if keyLabel then keyLabel.Text = v end; Window:AddKeybind(cfg.Title, v); cfg.KeyCallback("Changed", { Key=v, Mode=cfg.Mode }) end
					end,
				}
			end

			-- ── AddSlider ────────────────────────────────────────────────────
			function Section:AddSlider(cfg)
				cfg = cfg or {}
				applyDefaults({ Title = "Slider", Min = 0, Max = 100, Rounding = 0, Suffix = "", Default = nil, Callback = function() end }, cfg)
				if cfg.Default == nil then cfg.Default = cfg.Min end

				local sliderFrame = makeFrame({ Name = cfg.Title, BackgroundTransparency = 1, Size = UDim2.new(0, 208, 0, 40) }, self.elemHolder)
				local titleLabel  = makeLabel({ Size = UDim2.new(0,155,0,15), Text = cfg.Title, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, sliderFrame)
				local valueLabel  = makeLabel({ Size = UDim2.new(0,50,0,15),  Position = UDim2.new(0,158,0,0), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, sliderFrame)
				local track_      = makeFrame({ Name = "Track", BackgroundColor3 = COLOR_ELEM_BG, Size = UDim2.new(1,0,0,15), Position = UDim2.new(0,0,0,20) }, sliderFrame)
				addOutlineStroke(track_, 1)
				local fill = makeFrame({ BackgroundColor3 = theme.main }, track_)
				track(tracked.fills, fill)

				local currentValue = cfg.Default

				local function round(v) return cfg.Rounding > 0 and math.floor(v / cfg.Rounding + .5) * cfg.Rounding or v end

				local function applyMouseX(mouseX)
					local rel = math.clamp(mouseX - track_.AbsolutePosition.X, 0, track_.AbsoluteSize.X)
					local pct = track_.AbsoluteSize.X > 0 and (rel / track_.AbsoluteSize.X) or 0
					currentValue = round(cfg.Min + (cfg.Max - cfg.Min) * pct)
					fill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.03, true)
					valueLabel.Text = tostring(math.floor(currentValue)) .. cfg.Suffix
					cfg.Callback(currentValue)
				end

				local initPct = (cfg.Max ~= cfg.Min) and ((cfg.Default - cfg.Min) / (cfg.Max - cfg.Min)) or 0
				fill.Size       = UDim2.new(initPct, 0, 1, 0)
				valueLabel.Text = tostring(cfg.Default) .. cfg.Suffix

				local dragging = false
				local function startDrag(input) if input.UserInputType == MB1 then dragging = true; applyMouseX(input.Position.X) end end
				track_.InputBegan:Connect(startDrag); fill.InputBegan:Connect(startDrag)
				UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == MOUSE_MOVE then applyMouseX(i.Position.X) end end)
				UIS.InputEnded:Connect(function(i) if i.UserInputType == MB1 then dragging = false end end)

				sliderFrame.MouseEnter:Connect(function() tween(titleLabel, { TextColor3 = COLOR_TEXT_HOVER }); tween(valueLabel, { TextColor3 = COLOR_TEXT_HOVER }) end)
				sliderFrame.MouseLeave:Connect(function() tween(titleLabel, { TextColor3 = COLOR_TEXT_NORMAL }); tween(valueLabel, { TextColor3 = COLOR_TEXT_NORMAL }) end)

				return {
					frame    = sliderFrame,
					fill     = fill,
					GetValue = function() return currentValue end,
					SetValue = function(v)
						v = math.clamp(tonumber(v) or cfg.Min, cfg.Min, cfg.Max)
						local pct = (cfg.Max ~= cfg.Min) and ((v - cfg.Min) / (cfg.Max - cfg.Min)) or 0
						currentValue = round(v)
						fill.Size    = UDim2.new(pct, 0, 1, 0)
						valueLabel.Text = tostring(math.floor(currentValue)) .. cfg.Suffix
						cfg.Callback(currentValue)
					end,
				}
			end

			-- ── AddDropdown ──────────────────────────────────────────────────
			function Section:AddDropdown(cfg)
				cfg = cfg or {}
				applyDefaults({ Title = "Dropdown", Options = {}, Multi = false, Callback = function() end }, cfg)
				cfg.Placeholder = cfg.Placeholder or cfg.Title
				cfg.Default     = (cfg.Multi and type(cfg.Default) == "table") and cfg.Default or (cfg.Default or {})

				local dropFrame = makeFrame({ Name = cfg.Title, BackgroundColor3 = COLOR_ELEM_BG, Size = UDim2.new(0,208,0,20), ZIndex = 10 }, self.elemHolder)
				addOutlineStroke(dropFrame, 1)

				local dropTitle   = makeLabel({ Size = UDim2.new(0,150,1,0), Position = UDim2.new(0,5,0,0), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, dropFrame)
				local indicator   = makeLabel({ Text = "▼", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0,15,1,0), Position = UDim2.new(1,-20,0,-2), TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, dropFrame)
				dropTitle.Text = cfg.Multi
					and ((#cfg.Default > 0) and table.concat(cfg.Default, ", ") or cfg.Placeholder)
					or  ((#cfg.Default > 0) and cfg.Default[1]               or cfg.Placeholder)

				local listHeight  = math.min(#cfg.Options * 20, 160)
				local listFrame   = makeFrame({ Name = "List_"..cfg.Title, BackgroundColor3 = COLOR_ELEM_BG, Size = UDim2.new(0,208,0,listHeight), Visible = false, ZIndex = 200, ClipsDescendants = true }, popupOverlay)
				addOutlineStroke(listFrame, 1)

				local listScroll  = make("ScrollingFrame", {
					Name                  = "Scroll",
					BackgroundTransparency = 1,
					BorderSizePixel       = 0,
					Size                  = UDim2.new(1,0,1,0),
					CanvasSize            = UDim2.new(0,0,0, #cfg.Options * 20),
					ScrollBarThickness    = (#cfg.Options * 20 > listHeight) and 4 or 0,
					ScrollBarImageColor3  = theme.main,
					ZIndex                = 200,
				}, listFrame)
				track(tracked.scrollbars, listScroll)
				makeListLayout(listScroll, { Padding = UDim.new(0,0) })

				local expanded     = false
				local selected     = cfg.Multi and cfg.Default or (cfg.Default[1] or nil)
				local optButtons   = {}
				local optClickConsumed = false

				local function repositionList()
					local ap = dropFrame.AbsolutePosition; local as = dropFrame.AbsoluteSize; local mp = mainGui.AbsolutePosition
					listFrame.Position = UDim2.new(0, ap.X-mp.X, 0, ap.Y-mp.Y+as.Y+2)
				end

				local function setExpanded(state)
					if state then closePopup(); repositionList(); listFrame.Visible = true; activePopup = listFrame
					else listFrame.Visible = false; if activePopup == listFrame then activePopup = nil end end
					expanded = state; indicator.Text = state and "▲" or "▼"
					tween(dropFrame, { BackgroundColor3 = state and theme.main or COLOR_ELEM_BG })
				end

				dropFrame.MouseEnter:Connect(function() tween(dropTitle, { TextColor3 = COLOR_TEXT_HOVER }); tween(indicator, { TextColor3 = COLOR_TEXT_HOVER }) end)
				dropFrame.MouseLeave:Connect(function() tween(dropTitle, { TextColor3 = COLOR_TEXT_NORMAL}); tween(indicator, { TextColor3 = COLOR_TEXT_NORMAL}) end)
				dropFrame.InputBegan:Connect(function(i) if i.UserInputType == MB1 then setExpanded(not expanded) end end)

				UIS.InputBegan:Connect(function(input)
					if not expanded or input.UserInputType ~= MB1 then return end
					if optClickConsumed then optClickConsumed = false; return end
					local mp = UIS:GetMouseLocation()
					local lp, ls = listFrame.AbsolutePosition, listFrame.AbsoluteSize
					local dp, ds = dropFrame.AbsolutePosition, dropFrame.AbsoluteSize
					local inList = mp.X >= lp.X and mp.X <= lp.X+ls.X and mp.Y >= lp.Y and mp.Y <= lp.Y+ls.Y
					local inDrop = mp.X >= dp.X and mp.X <= dp.X+ds.X and mp.Y >= dp.Y and mp.Y <= dp.Y+ds.Y
					if not inList and not inDrop then setExpanded(false) end
				end)

				local function buildOptions(options)
					for _, child in ipairs(listScroll:GetChildren()) do
						if not child:IsA("UIListLayout") then child:Destroy() end
					end
					for _, ob in ipairs(optButtons) do
						local i = table.find(tracked.activeOptionLabels, ob.label)
						if i then table.remove(tracked.activeOptionLabels, i) end
					end
					optButtons = {}

					local newH = math.min(#options * 20, 160)
					listFrame.Size               = UDim2.new(0, 208, 0, newH)
					listScroll.CanvasSize        = UDim2.new(0, 0, 0, #options * 20)
					listScroll.ScrollBarThickness = (#options * 20 > newH) and 4 or 0

					for _, name in ipairs(options) do
						local wrapper = make("TextButton", {
							Name                 = name,
							BackgroundTransparency = 1,
							AutoButtonColor      = false,
							Size                 = UDim2.new(1, 0, 0, 20),
							ZIndex               = 200,
							Text                 = "",
						}, listScroll)
						local optLabel = makeLabel({
							Name                 = "Label",
							BackgroundColor3     = COLOR_ELEM_BG,
							BackgroundTransparency = 0,
							Size                 = UDim2.new(1, 0, 1, 0),
							Text                 = name,
							TextSize             = 14,
							TextColor3           = COLOR_TEXT_NORMAL,
							TextXAlignment       = Enum.TextXAlignment.Left,
							Font                 = Enum.Font.Gotham,
							ZIndex               = 200,
						}, wrapper)
						addOutlineStroke(optLabel, 1)
						make("UIPadding", { PaddingLeft = UDim.new(0, 5) }, optLabel)

						wrapper.MouseEnter:Connect(function() tween(optLabel, { TextColor3 = COLOR_TEXT_HOVER  }) end)
						wrapper.MouseLeave:Connect(function() tween(optLabel, { TextColor3 = COLOR_TEXT_NORMAL }) end)
						wrapper.InputBegan:Connect(function(i) if i.UserInputType == MB1 then optClickConsumed = true end end)

						wrapper.MouseButton1Click:Connect(function()
							if cfg.Multi then
								local idx = table.find(selected, name)
								if idx then
									table.remove(selected, idx)
									local ti = table.find(tracked.activeOptionLabels, optLabel); if ti then table.remove(tracked.activeOptionLabels, ti) end
									tween(optLabel, { BackgroundColor3 = COLOR_ELEM_BG })
								else
									table.insert(selected, name)
									if not table.find(tracked.activeOptionLabels, optLabel) then table.insert(tracked.activeOptionLabels, optLabel) end
									tween(optLabel, { BackgroundColor3 = theme.main })
								end
								dropTitle.Text = (#selected > 0) and table.concat(selected, ", ") or cfg.Placeholder
								cfg.Callback(selected)
							else
								selected = name; dropTitle.Text = name; cfg.Callback(name)
								tween(optLabel, { BackgroundColor3 = theme.main }, function() tween(optLabel, { BackgroundColor3 = COLOR_ELEM_BG }) end)
								setExpanded(false)
							end
						end)

						table.insert(optButtons, { name = name, label = optLabel })
					end

					if cfg.Multi and type(selected) == "table" then
						for _, ob in ipairs(optButtons) do
							if table.find(selected, ob.name) then
								ob.label.BackgroundColor3 = theme.main
								if not table.find(tracked.activeOptionLabels, ob.label) then table.insert(tracked.activeOptionLabels, ob.label) end
							end
						end
					end
				end

				buildOptions(cfg.Options)

				return {
					frame    = dropFrame,
					GetValue = function() return selected end,
					SetValue = function(val)
						if cfg.Multi then
							for _, ob in ipairs(optButtons) do
								ob.label.BackgroundColor3 = COLOR_ELEM_BG
								local i = table.find(tracked.activeOptionLabels, ob.label); if i then table.remove(tracked.activeOptionLabels, i) end
							end
							selected = {}
							for _, v in ipairs(type(val) == "table" and val or {}) do
								for _, ob in ipairs(optButtons) do
									if ob.name == v then
										table.insert(selected, v); ob.label.BackgroundColor3 = theme.main
										if not table.find(tracked.activeOptionLabels, ob.label) then table.insert(tracked.activeOptionLabels, ob.label) end
										break
									end
								end
							end
							dropTitle.Text = (#selected > 0) and table.concat(selected, ", ") or cfg.Placeholder
							cfg.Callback(selected)
						else
							for _, ob in ipairs(optButtons) do
								if ob.name == val then selected = val; dropTitle.Text = val; cfg.Callback(val); break end
							end
						end
					end,
					Refresh  = function(newOptions, newSelected)
						if expanded then setExpanded(false) end
						selected = cfg.Multi and (type(newSelected) == "table" and newSelected or {}) or (newSelected or nil)
						dropTitle.Text = cfg.Multi
							and ((type(selected) == "table" and #selected > 0) and table.concat(selected, ", ") or cfg.Placeholder)
							or (selected or cfg.Placeholder)
						buildOptions(newOptions)
					end,
				}
			end

			-- ── AddLabel ─────────────────────────────────────────────────────
			function Section:AddLabel(cfg)
				cfg = cfg or {}
				applyDefaults({ Title = "Label", TextAlignment = "Left" }, cfg)
				local labelFrame = makeFrame({ Name = "Label_"..cfg.Title, BackgroundTransparency = 1, Size = UDim2.new(0, 208, 0, 15) }, self.elemHolder)
				local label      = makeLabel({ Size = UDim2.new(1,0,1,0), Text = cfg.Title, TextSize = 14, TextXAlignment = toTextAlign(cfg.TextAlignment), TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, labelFrame)
				return { frame = labelFrame, label = label }
			end

			-- ── AddColorPicker ───────────────────────────────────────────────
			function Section:AddColorPicker(cfg)
				cfg = cfg or {}
				applyDefaults({ Title = "Color", Default = Color3.fromRGB(255,255,255), Callback = function() end }, cfg)

				local PW, PH, SVW, SVH, HW, PAD = 166, 148, 138, 114, 12, 5

				local row       = makeFrame({ Name = "ColorPicker_"..cfg.Title, BackgroundTransparency = 1, ZIndex = 10, Size = UDim2.new(0,208,0,15) }, self.elemHolder)
				local rowTitle  = makeLabel({ Size = UDim2.new(1,0,1,0), Text = cfg.Title..":", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, row)
				local swatch    = makeFrame({ BackgroundColor3 = cfg.Default, Size = UDim2.new(0,30,0,15), Position = UDim2.new(0,177,0,0), ZIndex = 10 }, row)
				addOutlineStroke(swatch, 1)

				local panel = makeFrame({ BackgroundColor3 = Color3.fromRGB(18,18,18), Size = UDim2.new(0,PW,0,PH), Visible = false, ZIndex = 200 }, popupOverlay)
				addMainStroke(panel)

				local svBox       = makeFrame({ BackgroundColor3 = Color3.fromRGB(255,0,0), Size = UDim2.new(0,SVW,0,SVH), Position = UDim2.new(0,PAD,0,PAD), ZIndex = 201, ClipsDescendants = false }, panel)
				addOutlineStroke(svBox, 1)
				local whiteLayer  = makeFrame({ BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), ZIndex = 202 }, svBox)
				make("UIGradient", { Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }, Rotation = 0 }, whiteLayer)
				local blackLayer  = makeFrame({ BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), ZIndex = 203 }, svBox)
				make("UIGradient", { Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }, Rotation = 90 }, blackLayer)

				local svCursor = makeFrame({ BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0,8,0,8), ZIndex = 205 }, panel)
				Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)
				makeStroke(svCursor, Color3.new(0,0,0), 1)

				local hueBar = makeFrame({ BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0,HW,0,SVH), Position = UDim2.new(0,PAD+SVW+PAD,0,PAD), ZIndex = 201 }, panel)
				addOutlineStroke(hueBar, 1)
				make("UIGradient", { Rotation = 90, Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255,0,0)),
					ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255,255,0)),
					ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
					ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0,255,255)),
					ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0,0,255)),
					ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
					ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255,0,0)),
				}}, hueBar)

				local hueCursor = makeFrame({ BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0,HW+4,0,3), ZIndex = 205 }, panel)
				makeStroke(hueCursor, Color3.new(0,0,0), 1)

				local hexRow   = makeFrame({ BackgroundColor3 = COLOR_ELEM_BG, Size = UDim2.new(0,PW-PAD*2,0,20), Position = UDim2.new(0,PAD,0,PAD+SVH+PAD), ZIndex = 201 }, panel)
				addOutlineStroke(hexRow, 1)
				makeLabel({ Size = UDim2.new(0,14,1,0), Position = UDim2.new(0,4,0,0), Text = "#", TextSize = 13, TextColor3 = COLOR_TEXT_DIM, Font = Enum.Font.GothamBold, ZIndex = 202 }, hexRow)
				local hexInput = make("TextBox", {
					BackgroundTransparency = 1, Size = UDim2.new(1,-18,1,0), Position = UDim2.new(0,18,0,0),
					Text = "", PlaceholderText = "RRGGBB", PlaceholderColor3 = COLOR_TEXT_DIM,
					TextSize = 13, TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 202,
				}, hexRow)

				local hue, sat, val_ = 0, 1, 1
				local currentColor = cfg.Default

				local function refreshPicker(skipHex)
					svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
					currentColor           = Color3.fromHSV(hue, sat, val_)
					svCursor.Position      = UDim2.new(0, PAD + sat*SVW - 4, 0, PAD + (1-val_)*SVH - 4)
					hueCursor.Position     = UDim2.new(0, PAD+SVW+PAD-2, 0, PAD + hue*SVH - 1)
					swatch.BackgroundColor3 = currentColor
					if not skipHex then hexInput.Text = colorToHex(currentColor) end
					cfg.Callback(currentColor)
				end

				local function loadColor(c)
					local h, s, v = Color3.toHSV(c); hue = h; sat = s; val_ = v; refreshPicker(false)
				end

				local dragSV, dragHue = false, false

				local function applySV(mp)
					local ap, as = svBox.AbsolutePosition, svBox.AbsoluteSize
					sat  = math.clamp((mp.X-ap.X)/as.X, 0, 1)
					val_ = 1 - math.clamp((mp.Y-ap.Y)/as.Y, 0, 1)
					refreshPicker(false)
				end
				local function applyHue(mp)
					local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
					hue = math.clamp((mp.Y-ap.Y)/as.Y, 0, 1)
					refreshPicker(false)
				end

				local function beginSV(i)  if i.UserInputType == MB1 then dragSV  = true; applySV(i.Position)  end end
				local function endSV(i)    if i.UserInputType == MB1 then dragSV  = false end end
				blackLayer.InputBegan:Connect(beginSV); blackLayer.InputEnded:Connect(endSV)
				svBox.InputBegan:Connect(beginSV);      svBox.InputEnded:Connect(endSV)
				hueBar.InputBegan:Connect(function(i) if i.UserInputType == MB1 then dragHue = true;  applyHue(i.Position) end end)
				hueBar.InputEnded:Connect(function(i)  if i.UserInputType == MB1 then dragHue = false end end)
				UIS.InputChanged:Connect(function(i)
					if i.UserInputType ~= MOUSE_MOVE then return end
					if dragSV  then applySV(i.Position)  end
					if dragHue then applyHue(i.Position) end
				end)
				UIS.InputEnded:Connect(function(i)
					if i.UserInputType == MB1 then dragSV = false; dragHue = false end
				end)

				hexInput.FocusLost:Connect(function()
					local c = hexToColor(hexInput.Text)
					if c then loadColor(c) else hexInput.Text = colorToHex(currentColor) end
				end)

				local function repositionPanel()
					local ap, as = swatch.AbsolutePosition, swatch.AbsoluteSize
					local mp      = mainGui.AbsolutePosition
					local px = ap.X-mp.X-PW+as.X; local py = ap.Y-mp.Y+as.Y+4
					if px < 0 then px = 0 end
					if py + PH > mainGui.AbsoluteSize.Y then py = ap.Y-mp.Y-PH-4 end
					panel.Position = UDim2.new(0, px, 0, py)
				end

				swatch.InputBegan:Connect(function(i)
					if i.UserInputType ~= MB1 then return end
					if panel.Visible then panel.Visible = false; if activePopup == panel then activePopup = nil end
					else closePopup(); repositionPanel(); panel.Visible = true; activePopup = panel end
				end)

				UIS.InputBegan:Connect(function(input)
					if not panel.Visible or input.UserInputType ~= MB1 or hexInput:IsFocused() then return end
					local mp = UIS:GetMouseLocation()
					local pp, ps = panel.AbsolutePosition, panel.AbsoluteSize
					local sp, ss = swatch.AbsolutePosition, swatch.AbsoluteSize
					local inPanel  = mp.X>=pp.X and mp.X<=pp.X+ps.X and mp.Y>=pp.Y and mp.Y<=pp.Y+ps.Y
					local inSwatch = mp.X>=sp.X and mp.X<=sp.X+ss.X and mp.Y>=sp.Y and mp.Y<=sp.Y+ss.Y
					if not inPanel and not inSwatch then panel.Visible = false; if activePopup == panel then activePopup = nil end end
				end)

				row.MouseEnter:Connect(function() tween(rowTitle, { TextColor3 = COLOR_TEXT_HOVER  }) end)
				row.MouseLeave:Connect(function() tween(rowTitle, { TextColor3 = COLOR_TEXT_NORMAL }) end)
				loadColor(cfg.Default)

				return {
					frame    = row,
					swatch   = swatch,
					panel    = panel,
					GetColor = function() return currentColor end,
					SetColor = loadColor,
				}
			end

			-- ── AddKeyPicker ─────────────────────────────────────────────────
			function Section:AddKeyPicker(cfg)
				cfg = cfg or {}
				applyDefaults({ Title = "Keybind", Default = "None", Mode = "Toggle", Callback = function() end }, cfg)

				local holder     = makeFrame({ Name = "KeyPicker_"..cfg.Title, BackgroundTransparency = 1, Size = UDim2.new(0,208,0,20) }, self.elemHolder)
				local titleLabel = makeLabel({ Size = UDim2.new(1,-40,1,0), Text = cfg.Title, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, holder)
				local keyLabel   = makeLabel({ Size = UDim2.new(0,30,0,15), Position = UDim2.new(1,-5,0,0), AnchorPoint = Vector2.new(1,0), Text = cfg.Default, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = COLOR_TEXT_DIM, Font = Enum.Font.GothamBold, AutomaticSize = Enum.AutomaticSize.X }, holder)
				Window:AddKeybind(cfg.Title, cfg.Default)
				hoverText(titleLabel)

				local activeKey = cfg.Default; local toggled = false; local kbHover = false; local listening = false
				keyLabel.MouseEnter:Connect(function() kbHover = true  end)
				keyLabel.MouseLeave:Connect(function() kbHover = false end)

				UIS.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if kbHover and not listening and input.UserInputType == MB1 then
						listening = true
						startListening(keyLabel, function(name)
							listening = false
							if name ~= activeKey then activeKey = name; Window:AddKeybind(cfg.Title, name); cfg.Callback("Changed", { Key=name, Mode=cfg.Mode }) end
						end)
						return
					end
					if not matchesKey(input, activeKey) then return end
					if cfg.Mode == "Toggle" then
						toggled = not toggled
						tween(keyLabel, { TextColor3 = toggled and theme.main or COLOR_TEXT_DIM })
						Window:SetKeybindActive(cfg.Title, toggled)
						cfg.Callback("Pressed", { Key=activeKey, Mode=cfg.Mode, State=toggled })
					elseif cfg.Mode == "Hold" then
						tween(keyLabel, { TextColor3 = theme.main }); Window:SetKeybindActive(cfg.Title, true)
						cfg.Callback("Pressed", { Key=activeKey, Mode=cfg.Mode, State=true })
					end
				end)
				UIS.InputEnded:Connect(function(input, gpe)
					if gpe or cfg.Mode ~= "Hold" then return end
					if matchesKey(input, activeKey) then
						tween(keyLabel, { TextColor3 = COLOR_TEXT_DIM }); Window:SetKeybindActive(cfg.Title, false)
						cfg.Callback("Pressed", { Key=activeKey, Mode=cfg.Mode, State=false })
					end
				end)

				return {
					GetKey  = function() return activeKey end,
					SetKey  = function(v) if v ~= activeKey then activeKey = v; keyLabel.Text = v; Window:AddKeybind(cfg.Title, v); cfg.Callback("Changed", { Key=v, Mode=cfg.Mode }) end end,
					GetMode = function() return cfg.Mode end,
					SetMode = function(v) cfg.Mode = v end,
				}
			end

			-- ── AddTextInput ─────────────────────────────────────────────────
			function Section:AddTextInput(cfg)
				cfg = cfg or {}
				applyDefaults({
					Title        = "Text Input",
					Default      = "",
					Placeholder  = "Enter text...",
					ClearOnFocus = true,
					Numeric      = false,
					MaxLength    = nil,
					Callback     = function() end,
					OnFocus      = function() end,
					OnUnfocus    = function() end,
				}, cfg)

				local inputFrame = makeFrame({ Name = "TextInput_"..cfg.Title, BackgroundTransparency = 1, Size = UDim2.new(0,208,0,40) }, self.elemHolder)
				local titleLabel = makeLabel({ Size = UDim2.new(1,0,0,15), Text = cfg.Title, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = COLOR_TEXT_NORMAL, Font = Enum.Font.Gotham }, inputFrame)
				local boxFrame   = makeFrame({ BackgroundColor3 = COLOR_ELEM_BG, Size = UDim2.new(1,0,0,20), Position = UDim2.new(0,0,0,20) }, inputFrame)
				local boxStroke  = addOutlineStroke(boxFrame, 1)
				local textBox    = make("TextBox", {
					BackgroundTransparency = 1,
					Size                   = UDim2.new(1,-8,1,0),
					Position               = UDim2.new(0,4,0,0),
					Text                   = cfg.Default,
					PlaceholderText        = cfg.Placeholder,
					PlaceholderColor3      = COLOR_TEXT_DIM,
					TextSize               = 13,
					TextColor3             = COLOR_TEXT_NORMAL,
					TextXAlignment         = Enum.TextXAlignment.Left,
					Font                   = Enum.Font.Gotham,
					ClearTextOnFocus       = cfg.ClearOnFocus,
					ClipsDescendants       = true,
				}, boxFrame)

				local currentValue = cfg.Default

				textBox.Focused:Connect(function()
					tween(boxFrame, { BackgroundColor3 = Color3.fromRGB(34,34,34) })
					boxStroke.Color = theme.main
					tween(titleLabel, { TextColor3 = COLOR_TEXT_HOVER })
					cfg.OnFocus(currentValue)
				end)

				textBox.FocusLost:Connect(function(enterPressed)
					local raw = textBox.Text
					if cfg.Numeric then
						raw = raw:gsub("[^%d%.%-]", "")
						local num = tonumber(raw); raw = num and tostring(num) or currentValue
					end
					if cfg.MaxLength and #raw > cfg.MaxLength then raw = raw:sub(1, cfg.MaxLength) end
					textBox.Text = raw ~= "" and raw or ""
					if raw ~= "" then currentValue = raw end
					boxStroke.Color = theme.outline
					tween(boxFrame, { BackgroundColor3 = COLOR_ELEM_BG })
					tween(titleLabel, { TextColor3 = COLOR_TEXT_NORMAL })
					cfg.OnUnfocus(currentValue, enterPressed)
					cfg.Callback(currentValue, enterPressed)
				end)

				textBox:GetPropertyChangedSignal("Text"):Connect(function()
					local t = textBox.Text
					if cfg.Numeric then
						local clean = t:gsub("[^%d%.%-]", "")
						if clean ~= t then textBox.Text = clean; return end
					end
					if cfg.MaxLength and #t > cfg.MaxLength then textBox.Text = t:sub(1, cfg.MaxLength) end
				end)

				inputFrame.MouseEnter:Connect(function() tween(titleLabel, { TextColor3 = COLOR_TEXT_HOVER  }) end)
				inputFrame.MouseLeave:Connect(function() if not textBox:IsFocused() then tween(titleLabel, { TextColor3 = COLOR_TEXT_NORMAL }) end end)

				return {
					frame    = inputFrame,
					textBox  = textBox,
					GetValue = function() return currentValue end,
					SetValue = function(v)
						v = tostring(v)
						if cfg.MaxLength and #v > cfg.MaxLength then v = v:sub(1, cfg.MaxLength) end
						currentValue = v; textBox.Text = v; cfg.Callback(currentValue, false)
					end,
					Clear    = function() currentValue = ""; textBox.Text = "" end,
				}
			end

			return Section
		end -- AddSection
		return Tab
	end -- AddTab

	return Window
end -- CreateWindow

-- ─── Export ───────────────────────────────────────────────────────────────────
if getgenv then
	getgenv().JWareUI = getgenv().JWareUI or InitJWareUI()
	return getgenv().JWareUI
else
	_G.JWareUI = _G.JWareUI or InitJWareUI()
	return _G.JWareUI
end
