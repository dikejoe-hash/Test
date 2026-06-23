--[[
	JWare UI Library — Clean Rewrite
	Same features, same style, same animations.
	Organized, bug-fixed, no dead code.
--]]

-- ─── Themes ───────────────────────────────────────────────────────────────────
Themes = {
	JWare  = {
		MainColor       = Color3.fromRGB(70, 7, 100),
		OutlineColor    = Color3.fromRGB(0, 0, 0),
		BackgroundColor  = Color3.fromRGB(27, 27, 27),
		BackgroundColor2 = Color3.fromRGB(16, 16, 16),
	},
	JWare2 = {
		MainColor       = Color3.fromRGB(135, 0, 2),
		OutlineColor    = Color3.fromRGB(0, 0, 0),
		BackgroundColor  = Color3.fromRGB(27, 27, 27),
		BackgroundColor2 = Color3.fromRGB(16, 16, 16),
	},
}

-- ─── Library Init ─────────────────────────────────────────────────────────────
local function InitJWareUI()

	-- Services
	local Players         = game:GetService("Players")
	local TweenService    = game:GetService("TweenService")
	local RunService      = game:GetService("RunService")
	local CoreGui         = game:GetService("CoreGui")
	local UserInputService = game:GetService("UserInputService")

	-- Constants
	local VIEWPORT      = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local TWEEN_INFO    = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local Theme         = Themes.JWare

	-- Colour palette used by elements
	local COL_ELEM_BG     = Color3.fromRGB(26, 26, 26)
	local COL_TEXT_NORMAL = Color3.fromRGB(200, 200, 200)
	local COL_TEXT_HOVER  = Color3.fromRGB(255, 255, 255)
	local COL_TEXT_DIM    = Color3.fromRGB(150, 150, 150)

	-- ─── Helpers ──────────────────────────────────────────────────────────────

	-- Resolve a parent ScreenGui safely (CoreGui first, PlayerGui fallback)
	local function resolveGuiParent()
		if RunService:IsStudio() then
			local lp = Players.LocalPlayer
			return lp and lp:FindFirstChildOfClass("PlayerGui") or CoreGui
		end
		local ok = pcall(function() return CoreGui.Parent end)
		return ok and CoreGui or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui)
	end

	local function tween(obj, goal, callback)
		local t = TweenService:Create(obj, TWEEN_INFO, goal)
		if callback then t.Completed:Connect(callback) end
		t:Play()
		return t
	end

	local function normalizeAlignment(v)
		if typeof(v) == "EnumItem" and v.EnumType == Enum.TextXAlignment then return v end
		if typeof(v) == "string" then
			local s = v:lower()
			if s == "left"   then return Enum.TextXAlignment.Left   end
			if s == "right"  then return Enum.TextXAlignment.Right  end
		end
		return Enum.TextXAlignment.Center
	end

	local function validate(defaults, opts)
		for k, v in pairs(defaults) do
			if opts[k] == nil then opts[k] = v end
		end
	end

	-- Generic smooth dragging with lerp
	local function makeDraggable(dragHandle, targetFrame, lerpSpeed)
		lerpSpeed = lerpSpeed or 0.2
		local dragging      = false
		local dragStart     = Vector2.zero
		local frameStart    = targetFrame.Position
		local targetPos     = targetFrame.Position

		dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			dragging   = true
			dragStart  = input.Position
			frameStart = targetFrame.Position
			targetPos  = frameStart
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				targetPos = UDim2.new(0, frameStart.X.Offset + delta.X, 0, frameStart.Y.Offset + delta.Y)
			end
		end)

		RunService.RenderStepped:Connect(function()
			targetFrame.Position = targetFrame.Position:Lerp(targetPos, lerpSpeed)
		end)
	end

	-- UIStroke helper
	local function addStroke(parent, color, thickness, mode)
		local s = Instance.new("UIStroke")
		s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
		s.Color     = color or Color3.new()
		s.Thickness = thickness or 1
		s.Parent    = parent
		return s
	end

	-- Create a ScreenGui
	local function makeScreenGui(name, parent)
		local sg = Instance.new("ScreenGui")
		sg.Name           = name
		sg.IgnoreGuiInset = true
		sg.ResetOnSpawn   = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent         = parent
		return sg
	end

	-- Toggle helper (nil = flip, else set)
	local function toggleState(current, state)
		if state == nil then return not current end
		return state and true or false
	end

	-- Key matching helper
	local function keyMatchesInput(input, keyName)
		if not keyName or keyName == "None" or keyName == "" then return false end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			return input.KeyCode.Name == keyName
		elseif input.UserInputType.Name:match("MouseButton") and keyName:match("^MB%d$") then
			local idx = input.UserInputType.Value - Enum.UserInputType.MouseButton1.Value + 1
			return ("MB" .. idx) == keyName
		end
		return false
	end

	-- Resolve mouse-button input to an "MB#" name
	local function inputToKeyName(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			return input.KeyCode.Name
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then return "MB1"
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then return "MB2"
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then return "MB3"
		end
		return nil
	end

	-- Shared keybind listening logic (used by Toggle and KeyPicker)
	local function startListening(keyLabel, onBound)
		keyLabel.Text = "..."
		task.defer(function()
			local conn
			conn = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				local name = inputToKeyName(input)
				if name then
					conn:Disconnect()
					keyLabel.Text = name
					onBound(name)
				end
			end)
		end)
	end

	-- ─── Color-picker gradient data ───────────────────────────────────────────
	local GRADIENT_KEYPOINTS = {
		{ t = 0.000, c = Color3.fromRGB(255, 255, 255) },
		{ t = 0.150, c = Color3.fromRGB(255, 0,   0  ) },
		{ t = 0.333, c = Color3.fromRGB(236, 255, 16 ) },
		{ t = 0.500, c = Color3.fromRGB(0,   255, 9  ) },
		{ t = 0.667, c = Color3.fromRGB(0,   255, 248) },
		{ t = 0.833, c = Color3.fromRGB(0,   0,   255) },
		{ t = 1.000, c = Color3.fromRGB(239, 0,   255) },
	}

	local function lerpColor(a, b, t)
		return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end

	local function sampleGradient(t)
		t = math.clamp(t, 0, 1)
		for i = 1, #GRADIENT_KEYPOINTS - 1 do
			local a, b = GRADIENT_KEYPOINTS[i], GRADIENT_KEYPOINTS[i + 1]
			if t >= a.t and t <= b.t then
				return lerpColor(a.c, b.c, (t - a.t) / (b.t - a.t))
			end
		end
		return GRADIENT_KEYPOINTS[#GRADIENT_KEYPOINTS].c
	end

	-- Find gradient t value closest to a given Color3
	local function colorToGradientT(c)
		local bestT, minDist = 0, math.huge
		for t = 0, 1, 0.001 do
			local col = sampleGradient(t)
			local dr, dg, db = col.R - c.R, col.G - c.G, col.B - c.B
			local dist = dr*dr + dg*dg + db*db
			if dist < minDist then minDist, bestT = dist, t end
		end
		return bestT
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- Window Constructor
	-- ═══════════════════════════════════════════════════════════════════════════
	local function CreateWindow(opts)
		opts = opts or {}
		validate({ Title = "JWare UI [v1.0]", TextAlignment = "Center" }, opts)

		local guiParent = resolveGuiParent()
		local Window = { CurrentTab = nil, Tabs = {}, KeybindLabels = {} }

		-- ── ScreenGuis ────────────────────────────────────────────────────────
		local mainGui      = makeScreenGui("JWare UI",           guiParent)
		local overlayGui   = makeScreenGui("JWare UI Watermarks", guiParent)
		Window._mainGui    = mainGui
		Window._overlayGui = overlayGui

		local uiVisible = true
		function Window:UIToggle(state)
			uiVisible = toggleState(uiVisible, state)
			mainGui.Enabled = uiVisible
		end

		-- ── Main Frame ────────────────────────────────────────────────────────
		local MainFrame = Instance.new("Frame")
		MainFrame.Name             = "MainFrame"
		MainFrame.BackgroundColor3 = Theme.BackgroundColor
		MainFrame.BorderSizePixel  = 0
		MainFrame.Size             = UDim2.new(0, 700, 0, 550)
		MainFrame.Position         = UDim2.fromOffset(
			math.floor(VIEWPORT.X / 2 - 350),
			math.floor(VIEWPORT.Y / 2 - 275)
		)
		MainFrame.Parent = mainGui
		addStroke(MainFrame, Theme.MainColor, 2)

		-- ── Title Bar ─────────────────────────────────────────────────────────
		local TitleBar = Instance.new("Frame")
		TitleBar.Name             = "TitleBar"
		TitleBar.BackgroundColor3 = Theme.BackgroundColor
		TitleBar.BorderSizePixel  = 0
		TitleBar.Size             = UDim2.new(0, 700, 0, 30)
		TitleBar.Parent           = MainFrame

		local TitleLabel = Instance.new("TextLabel")
		TitleLabel.Name               = "Title"
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Size               = UDim2.new(0, 680, 1, 0)
		TitleLabel.Position           = UDim2.new(0, 10, 0, 0)
		TitleLabel.Text               = opts.Title
		TitleLabel.TextSize           = 15
		TitleLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
		TitleLabel.TextXAlignment     = normalizeAlignment(opts.TextAlignment)
		TitleLabel.FontFace           = Font.new("rbxasset://fonts/families/DenkOne.json")
		TitleLabel.BorderSizePixel    = 0
		TitleLabel.Parent             = TitleBar

		-- ── Content Frame ─────────────────────────────────────────────────────
		local ContentFrame = Instance.new("Frame")
		ContentFrame.Name             = "ContentFrame"
		ContentFrame.BackgroundColor3 = Theme.BackgroundColor2
		ContentFrame.BorderSizePixel  = 0
		ContentFrame.Size             = UDim2.new(0, 690, 0, 515)
		ContentFrame.Position         = UDim2.new(0, 5, 0, 30)
		ContentFrame.Parent           = MainFrame
		addStroke(ContentFrame, Theme.OutlineColor, 2)

		-- ── Tabs Bar ──────────────────────────────────────────────────────────
		local TabsBar = Instance.new("Frame")
		TabsBar.Name             = "TabsBar"
		TabsBar.BackgroundColor3 = Theme.BackgroundColor2
		TabsBar.BorderSizePixel  = 0
		TabsBar.Size             = UDim2.new(1, 0, 0, 40)
		TabsBar.Parent           = ContentFrame
		addStroke(TabsBar, Theme.OutlineColor, 2)

		local TabButtonHolder = Instance.new("Frame")
		TabButtonHolder.Name                = "TabButtonHolder"
		TabButtonHolder.BackgroundTransparency = 1
		TabButtonHolder.Size                = UDim2.new(1, 0, 1, 0)
		TabButtonHolder.Parent              = TabsBar

		local TabLayout = Instance.new("UIListLayout")
		TabLayout.FillDirection = Enum.FillDirection.Horizontal
		TabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
		TabLayout.Padding       = UDim.new(0, 2)
		TabLayout.Parent        = TabButtonHolder

		local TabPadding = Instance.new("UIPadding")
		TabPadding.PaddingLeft  = UDim.new(0, 1)
		TabPadding.PaddingRight = UDim.new(0, 1)
		TabPadding.Parent       = TabButtonHolder

		-- ── Keybind Overlay ───────────────────────────────────────────────────
		local KeybindFrame = Instance.new("Frame")
		KeybindFrame.Name             = "KeybindFrame"
		KeybindFrame.BackgroundColor3 = Theme.BackgroundColor
		KeybindFrame.BorderSizePixel  = 0
		KeybindFrame.Size             = UDim2.new(0, 150, 0, 100)
		KeybindFrame.Position         = UDim2.new(0, 5, 0, 600)
		KeybindFrame.Visible          = false
		KeybindFrame.Parent           = overlayGui
		addStroke(KeybindFrame, Theme.MainColor, 2)

		local KeybindContent = Instance.new("Frame")
		KeybindContent.Name             = "Content"
		KeybindContent.BackgroundColor3 = Theme.BackgroundColor2
		KeybindContent.BorderSizePixel  = 0
		KeybindContent.Size             = UDim2.new(0, 140, 0, 90)
		KeybindContent.Position         = UDim2.new(0, 5, 0, 5)
		KeybindContent.Parent           = KeybindFrame
		addStroke(KeybindContent, Theme.OutlineColor)

		local KeybindLayout = Instance.new("UIListLayout")
		KeybindLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceAround
		KeybindLayout.SortOrder      = Enum.SortOrder.LayoutOrder
		KeybindLayout.Parent         = KeybindContent

		local KeybindPadding = Instance.new("UIPadding")
		KeybindPadding.PaddingBottom = UDim.new(0, 5)
		KeybindPadding.Parent        = KeybindContent

		-- Keybind title row
		local KBTitleFrame = Instance.new("Frame")
		KBTitleFrame.Name                 = "TitleRow"
		KBTitleFrame.BackgroundTransparency = 1
		KBTitleFrame.Size                 = UDim2.new(0, 130, 0, 15)
		KBTitleFrame.Parent               = KeybindContent

		local KBTitleLabel = Instance.new("TextLabel")
		KBTitleLabel.BackgroundTransparency = 1
		KBTitleLabel.Size                   = UDim2.new(1, 0, 1, 0)
		KBTitleLabel.Text                   = "Keybinds"
		KBTitleLabel.TextSize               = 12
		KBTitleLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
		KBTitleLabel.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json")
		KBTitleLabel.Parent                 = KBTitleFrame

		local keybindVisible = false
		function Window:KeybindToggle(state)
			keybindVisible = toggleState(keybindVisible, state)
			KeybindFrame.Visible = keybindVisible
		end

		function Window:AddKeybind(title, key)
			if key == "None" then
				if self.KeybindLabels[title] then
					self.KeybindLabels[title].Frame:Destroy()
					self.KeybindLabels[title] = nil
				end
				return
			end
			-- Update existing label
			if self.KeybindLabels[title] then
				self.KeybindLabels[title].KeyLabel.Text = key
				return
			end
			-- Create new row
			local row = Instance.new("Frame")
			row.Name                 = "KB_" .. title
			row.BackgroundTransparency = 1
			row.Size                 = UDim2.new(0, 130, 0, 15)
			row.Parent               = KeybindContent

			local rowTitle = Instance.new("TextLabel")
			rowTitle.BackgroundTransparency = 1
			rowTitle.Size               = UDim2.new(1, 0, 1, 0)
			rowTitle.Text               = title
			rowTitle.TextSize           = 12
			rowTitle.TextXAlignment     = Enum.TextXAlignment.Left
			rowTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
			rowTitle.FontFace           = Font.new("rbxasset://fonts/families/GothamSSm.json")
			rowTitle.Parent             = row

			local rowKey = Instance.new("TextLabel")
			rowKey.BackgroundTransparency = 1
			rowKey.Size               = UDim2.new(1, 0, 1, 0)
			rowKey.Text               = key
			rowKey.TextSize           = 12
			rowKey.TextXAlignment     = Enum.TextXAlignment.Right
			rowKey.TextColor3         = Color3.fromRGB(255, 255, 255)
			rowKey.FontFace           = Font.new("rbxasset://fonts/families/GothamSSm.json")
			rowKey.Parent             = row

			self.KeybindLabels[title] = { Frame = row, KeyLabel = rowKey }
		end

		-- ── Watermark Overlay ─────────────────────────────────────────────────
		local WatermarkFrame = Instance.new("Frame")
		WatermarkFrame.Name             = "WatermarkFrame"
		WatermarkFrame.BackgroundColor3 = Theme.BackgroundColor
		WatermarkFrame.BorderSizePixel  = 0
		WatermarkFrame.Size             = UDim2.new(0, 400, 0, 30)
		WatermarkFrame.Position         = UDim2.new(0, 5, 0, 60)
		WatermarkFrame.Visible          = false
		WatermarkFrame.Parent           = overlayGui
		addStroke(WatermarkFrame, Theme.MainColor, 2)

		local WatermarkContent = Instance.new("Frame")
		WatermarkContent.Name             = "Content"
		WatermarkContent.BackgroundColor3 = Theme.BackgroundColor2
		WatermarkContent.BorderSizePixel  = 0
		WatermarkContent.Size             = UDim2.new(0, 390, 0, 20)
		WatermarkContent.Position         = UDim2.new(0, 5, 0, 5)
		WatermarkContent.Parent           = WatermarkFrame
		addStroke(WatermarkContent, Theme.OutlineColor)

		function Window:AddWatermark(text, alignment)
			-- Remove existing watermark text if present
			for _, c in ipairs(WatermarkContent:GetChildren()) do
				if c:IsA("TextLabel") then c:Destroy() end
			end
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Size                   = UDim2.new(1, 0, 1, 0)
			lbl.Text                   = text
			lbl.TextSize               = 13
			lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
			lbl.TextXAlignment         = normalizeAlignment(alignment)
			lbl.FontFace               = Font.new("rbxasset://fonts/families/Ubuntu.json")
			lbl.Parent                 = WatermarkContent
		end

		local watermarkVisible = false
		function Window:WatermarkToggle(state)
			watermarkVisible = toggleState(watermarkVisible, state)
			WatermarkFrame.Visible = watermarkVisible
		end

		-- ── Dragging Setup ────────────────────────────────────────────────────
		makeDraggable(TitleLabel,     MainFrame)
		makeDraggable(KeybindFrame,   KeybindFrame)
		makeDraggable(WatermarkFrame, WatermarkFrame)

		-- ═════════════════════════════════════════════════════════════════════
		-- Tab Constructor
		-- ═════════════════════════════════════════════════════════════════════
		function Window:AddTab(tabOpts)
			tabOpts = tabOpts or {}
			validate({ Title = "Tab", Icon = "rbxassetid://70562308088944" }, tabOpts)

			local Tab = { Hover = false, Active = false }

			-- ── Tab Button ────────────────────────────────────────────────────
			local TabButton = Instance.new("TextLabel")
			TabButton.Name                = tabOpts.Title
			TabButton.BorderSizePixel     = 0
			TabButton.BackgroundColor3    = Theme.MainColor
			TabButton.BackgroundTransparency = 1
			TabButton.TextSize            = 14
			TabButton.TextColor3          = COL_TEXT_DIM
			TabButton.FontFace            = Font.new("rbxasset://fonts/families/Ubuntu.json")
			TabButton.Text                = tabOpts.Title
			TabButton.Size                = UDim2.new(0, 100, 1, 0)
			TabButton.Parent              = TabButtonHolder

			local TabPad = Instance.new("UIPadding")
			TabPad.PaddingLeft = UDim.new(0, 26)
			TabPad.Parent = TabButton

			local TabIcon = Instance.new("ImageLabel")
			TabIcon.BackgroundTransparency = 1
			TabIcon.Image                  = tabOpts.Icon
			TabIcon.ImageColor3            = COL_TEXT_DIM
			TabIcon.Size                   = UDim2.new(0, 20, 0, 20)
			TabIcon.Position               = UDim2.new(0, -10, 0.25, 0)
			TabIcon.BorderSizePixel        = 0
			TabIcon.Parent                 = TabButton

			-- ── Elements Container ────────────────────────────────────────────
			local ElementsContainer = Instance.new("Frame")
			ElementsContainer.Name             = tabOpts.Title .. "_Container"
			ElementsContainer.BackgroundColor3 = Theme.BackgroundColor
			ElementsContainer.BorderSizePixel  = 0
			ElementsContainer.Size             = UDim2.new(0, 680, 0, 460)
			ElementsContainer.Position         = UDim2.new(0, 5, 0, 50)
			ElementsContainer.Visible          = false
			ElementsContainer.Parent           = ContentFrame
			addStroke(ElementsContainer, Theme.OutlineColor, 2)

			Tab.ElementsContainer = ElementsContainer

			-- ── Activate / Deactivate ─────────────────────────────────────────
			function Tab:Activate()
				if self.Active then return end
				if Window.CurrentTab then Window.CurrentTab:Deactivate() end
				self.Active = true
				tween(TabButton, { TextColor3 = COL_TEXT_HOVER,     BackgroundTransparency = 0 })
				tween(TabIcon,   { ImageColor3 = COL_TEXT_HOVER })
				ElementsContainer.Visible = true
				Window.CurrentTab = self
			end

			function Tab:Deactivate()
				if not self.Active then return end
				self.Active = false
				self.Hover  = false
				tween(TabButton, { TextColor3 = COL_TEXT_DIM,  BackgroundTransparency = 1 })
				tween(TabIcon,   { ImageColor3 = COL_TEXT_DIM })
				ElementsContainer.Visible = false
			end

			-- ── Hover / Click ─────────────────────────────────────────────────
			TabButton.MouseEnter:Connect(function()
				Tab.Hover = true
				if not Tab.Active then
					tween(TabButton, { TextColor3  = COL_TEXT_HOVER })
					tween(TabIcon,   { ImageColor3 = COL_TEXT_HOVER })
				end
			end)

			TabButton.MouseLeave:Connect(function()
				Tab.Hover = false
				if not Tab.Active then
					tween(TabButton, { TextColor3  = COL_TEXT_DIM })
					tween(TabIcon,   { ImageColor3 = COL_TEXT_DIM })
				end
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if gpe then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 and Tab.Hover then
					Tab:Activate()
				end
			end)

			-- Auto-activate first tab
			if Window.CurrentTab == nil then Tab:Activate() end

			table.insert(Window.Tabs, Tab)

			-- ═══════════════════════════════════════════════════════════════════
			-- Section Constructor
			-- ═══════════════════════════════════════════════════════════════════
			function Tab:AddSection(secOpts)
				secOpts = secOpts or {}
				secOpts.Type  = secOpts.Type  or "Left"
				secOpts.Title = secOpts.Title or (secOpts.Type .. " Section")

				-- Column X position
				local colX = ({ Left = 5, Center = 231, Right = 457 })[secOpts.Type] or 5

				-- Retrieve or create column frame
				local colKey = secOpts.Type .. "Column"
				if not Tab[colKey] then
					local col = Instance.new("Frame")
					col.Name                 = colKey
					col.BackgroundTransparency = 1
					col.Size                 = UDim2.new(0, 218, 1, -10)
					col.Position             = UDim2.new(0, colX, 0, 5)
					col.Parent               = ElementsContainer

					local colLayout = Instance.new("UIListLayout")
					colLayout.SortOrder = Enum.SortOrder.LayoutOrder
					colLayout.Padding   = UDim.new(0, 7)
					colLayout.Parent    = col

					Tab[colKey] = col
				end
				local Column = Tab[colKey]

				-- Section frame
				local SectionFrame = Instance.new("Frame")
				SectionFrame.Name             = secOpts.Title
				SectionFrame.BackgroundColor3 = Theme.BackgroundColor2
				SectionFrame.BorderSizePixel  = 0
				SectionFrame.Size             = UDim2.new(0, 218, 0, 40) -- auto-grows
				SectionFrame.Parent           = Column
				addStroke(SectionFrame, Theme.OutlineColor, 2)

				-- Gradient header
				local GradFade = Instance.new("Frame")
				GradFade.Name             = "Fade"
				GradFade.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				GradFade.BorderSizePixel  = 0
				GradFade.Size             = UDim2.new(1, 0, 0, 20)
				GradFade.ZIndex           = 1
				GradFade.Parent           = SectionFrame

				local GradGrad = Instance.new("UIGradient")
				GradGrad.Rotation    = 90
				GradGrad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.5) }
				GradGrad.Color       = ColorSequence.new{ ColorSequenceKeypoint.new(0, Theme.MainColor), ColorSequenceKeypoint.new(1, Theme.BackgroundColor2) }
				GradGrad.Parent      = GradFade

				-- Section title label
				local SectionTitle = Instance.new("TextLabel")
				SectionTitle.Name               = "Title"
				SectionTitle.BackgroundTransparency = 1
				SectionTitle.BorderSizePixel    = 0
				SectionTitle.Size               = UDim2.new(1, 0, 0, 15)
				SectionTitle.Position           = UDim2.new(0, 0, 0, 5)
				SectionTitle.Text               = secOpts.Title
				SectionTitle.TextSize           = 14
				SectionTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
				SectionTitle.FontFace           = Font.new("rbxasset://fonts/families/Ubuntu.json")
				SectionTitle.ZIndex             = 3
				SectionTitle.Parent             = SectionFrame

				-- Elements holder (auto-sizing)
				local ElementsHolder = Instance.new("Frame")
				ElementsHolder.Name               = "ElementsHolder"
				ElementsHolder.BackgroundTransparency = 1
				ElementsHolder.BorderSizePixel    = 0
				ElementsHolder.Position           = UDim2.new(0, 0, 0, 30)
				ElementsHolder.Size               = UDim2.new(0, 218, 0, 0)
				ElementsHolder.Parent             = SectionFrame

				local ElemLayout = Instance.new("UIListLayout")
				ElemLayout.SortOrder = Enum.SortOrder.LayoutOrder
				ElemLayout.Padding   = UDim.new(0, 4)
				ElemLayout.Parent    = ElementsHolder

				local ElemPad = Instance.new("UIPadding")
				ElemPad.PaddingLeft = UDim.new(0, 5)
				ElemPad.Parent      = ElementsHolder

				-- Auto-resize section when content changes
				ElemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					SectionFrame.Size = UDim2.new(0, 218, 0, ElemLayout.AbsoluteContentSize.Y + 40)
				end)

				local Section = {
					Frame         = SectionFrame,
					ElementsHolder = ElementsHolder,
				}

				-- ─────────────────────────────────────────────────────────────
				-- AddButton
				-- ─────────────────────────────────────────────────────────────
				function Section:AddButton(cfg)
					cfg = cfg or {}
					cfg.Title    = cfg.Title    or "Button"
					cfg.Callback = cfg.Callback or function() end

					local btn = Instance.new("TextLabel")
					btn.Name                = cfg.Title
					btn.BackgroundColor3    = COL_ELEM_BG
					btn.BorderSizePixel     = 0
					btn.Size                = UDim2.new(0, 208, 0, 20)
					btn.Text                = cfg.Title
					btn.TextSize            = 14
					btn.TextColor3          = COL_TEXT_NORMAL
					btn.Font                = Enum.Font.Gotham
					btn.BackgroundTransparency = 0
					btn.ClipsDescendants    = true
					btn.Parent              = self.ElementsHolder
					addStroke(btn, Theme.OutlineColor)

					btn.MouseEnter:Connect(function() tween(btn, { TextColor3 = COL_TEXT_HOVER }) end)
					btn.MouseLeave:Connect(function() tween(btn, { TextColor3 = COL_TEXT_NORMAL }) end)

					btn.InputBegan:Connect(function(input)
						if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
						tween(btn, { BackgroundColor3 = Theme.MainColor }, function()
							tween(btn, { BackgroundColor3 = COL_ELEM_BG })
						end)
						cfg.Callback()
					end)

					return btn
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddToggle
				-- ─────────────────────────────────────────────────────────────
				function Section:AddToggle(cfg)
					cfg = cfg or {}
					cfg.Title          = cfg.Title          or "Toggle"
					cfg.Default        = cfg.Default        or false
					cfg.Callback       = cfg.Callback       or function() end
					cfg.KeybindEnabled = cfg.KeybindEnabled or false
					cfg.KeyBind        = cfg.KeyBind        or "None"
					cfg.Mode           = cfg.Mode           or "Toggle"
					cfg.Sync           = cfg.Sync           or false
					cfg.KeyCallback    = cfg.KeyCallback    or function() end

					local ToggleFrame = Instance.new("Frame")
					ToggleFrame.Name                 = cfg.Title
					ToggleFrame.BackgroundTransparency = 1
					ToggleFrame.BorderSizePixel      = 0
					ToggleFrame.Size                 = UDim2.new(0, 208, 0, 20)
					ToggleFrame.Parent               = self.ElementsHolder

					local Check = Instance.new("Frame")
					Check.Name             = "Check"
					Check.BackgroundColor3 = COL_ELEM_BG
					Check.BorderSizePixel  = 0
					Check.Size             = UDim2.new(0, 15, 0, 15)
					Check.Position         = UDim2.new(0, 0, 0, 3)
					Check.Parent           = ToggleFrame
					Instance.new("UICorner", Check).CornerRadius = UDim.new(0, 2)
					addStroke(Check, Theme.OutlineColor)

					local TitleLbl = Instance.new("TextLabel")
					TitleLbl.Name               = "Title"
					TitleLbl.BackgroundTransparency = 1
					TitleLbl.Size               = UDim2.new(0, 150, 1, 0)
					TitleLbl.Position           = UDim2.new(0, 23, 0, 0)
					TitleLbl.Text               = cfg.Title
					TitleLbl.TextSize           = 14
					TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
					TitleLbl.TextColor3         = COL_TEXT_NORMAL
					TitleLbl.Font               = Enum.Font.Gotham
					TitleLbl.Parent             = ToggleFrame

					local toggled    = cfg.Default
					local currentKey = cfg.KeyBind
					local keyState   = toggled

					local function syncCheck(animated)
						local col = toggled and Theme.MainColor or COL_ELEM_BG
						if animated then tween(Check, { BackgroundColor3 = col })
						else Check.BackgroundColor3 = col end
					end
					syncCheck(false)

					-- Optional keybind label
					local KeyLabel
					if cfg.KeybindEnabled then
						KeyLabel = Instance.new("TextLabel")
						KeyLabel.BackgroundTransparency = 1
						KeyLabel.Size               = UDim2.new(0, 30, 0, 15)
						KeyLabel.Position           = UDim2.new(0, 177, 0, 0)
						KeyLabel.Text               = currentKey
						KeyLabel.TextSize           = 12
						KeyLabel.TextXAlignment     = Enum.TextXAlignment.Center
						KeyLabel.TextColor3         = toggled and Theme.MainColor or COL_TEXT_DIM
						KeyLabel.Font               = Enum.Font.GothamBold
						KeyLabel.Parent             = ToggleFrame
					end

					local function setKeyLabelColor(state)
						if KeyLabel then tween(KeyLabel, { TextColor3 = state and Theme.MainColor or COL_TEXT_DIM }) end
					end

					local function doToggle()
						toggled = not toggled
						syncCheck(true)
						cfg.Callback(toggled)
						if cfg.Sync then
							keyState = toggled
							setKeyLabelColor(toggled)
							cfg.KeyCallback("Sync", { Key = currentKey, Mode = cfg.Mode, State = toggled })
						end
					end

					-- Click on title or check box
					TitleLbl.MouseEnter:Connect(function() tween(TitleLbl, { TextColor3 = COL_TEXT_HOVER }) end)
					TitleLbl.MouseLeave:Connect(function() tween(TitleLbl, { TextColor3 = COL_TEXT_NORMAL }) end)
					TitleLbl.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then doToggle() end end)
					Check.InputBegan:Connect(function(i)   if i.UserInputType == Enum.UserInputType.MouseButton1 then doToggle() end end)

					-- Keybind logic
					if cfg.KeybindEnabled then
						local kbHover = false
						local listening = false

						KeyLabel.MouseEnter:Connect(function() kbHover = true  end)
						KeyLabel.MouseLeave:Connect(function() kbHover = false end)

						UserInputService.InputBegan:Connect(function(input, gp)
							if gp then return end

							-- Start listening for a new key
							if kbHover and not listening and input.UserInputType == Enum.UserInputType.MouseButton1 then
								listening = true
								startListening(KeyLabel, function(name)
									listening = false
									if name ~= currentKey then
										currentKey = name
										Window:AddKeybind(cfg.Title, name)
										cfg.KeyCallback("Changed", { Key = name, Mode = cfg.Mode })
									end
								end)
								return
							end

							if not keyMatchesInput(input, currentKey) then return end

							if cfg.Mode == "Toggle" then
								if cfg.Sync then
									toggled = not toggled
									syncCheck(true)
									keyState = toggled
									setKeyLabelColor(toggled)
									cfg.Callback(toggled)
									cfg.KeyCallback("Pressed", { Key = currentKey, Mode = cfg.Mode, State = toggled })
								else
									keyState = not keyState
									setKeyLabelColor(keyState)
									cfg.KeyCallback("Pressed", { Key = currentKey, Mode = cfg.Mode, State = keyState })
								end
							elseif cfg.Mode == "Hold" then
								setKeyLabelColor(true)
								cfg.KeyCallback("Pressed", { Key = currentKey, Mode = cfg.Mode, State = true })
							end
						end)

						UserInputService.InputEnded:Connect(function(input, gp)
							if gp or cfg.Mode ~= "Hold" then return end
							if keyMatchesInput(input, currentKey) then
								setKeyLabelColor(false)
								cfg.KeyCallback("Pressed", { Key = currentKey, Mode = cfg.Mode, State = false })
							end
						end)
					end

					return {
						Frame    = ToggleFrame,
						Check    = Check,
						KeyLabel = KeyLabel,
						GetState = function() return toggled end,
						SetState = function(v)
							if toggled ~= v then doToggle() end
						end,
						GetKey = function() return currentKey end,
						SetKey = function(v)
							if v ~= currentKey then
								currentKey = v
								if KeyLabel then KeyLabel.Text = v end
								cfg.KeyCallback("Changed", { Key = v, Mode = cfg.Mode })
							end
						end,
					}
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddDropdown
				-- ─────────────────────────────────────────────────────────────
				function Section:AddDropdown(cfg)
					cfg = cfg or {}
					cfg.Title       = cfg.Title       or "Dropdown"
					cfg.Options     = cfg.Options     or {}
					cfg.Multi       = cfg.Multi       or false
					cfg.Placeholder = cfg.Placeholder or cfg.Title
					cfg.Callback    = cfg.Callback    or function() end

					if cfg.Multi then
						cfg.Default = (type(cfg.Default) == "table") and cfg.Default or {}
					else
						cfg.Default = cfg.Default or {}
					end

					-- Wrapper (collapsed)
					local DropFrame = Instance.new("Frame")
					DropFrame.Name             = cfg.Title
					DropFrame.BackgroundColor3 = COL_ELEM_BG
					DropFrame.BorderSizePixel  = 0
					DropFrame.Size             = UDim2.new(0, 208, 0, 20)
					DropFrame.ZIndex           = 10
					DropFrame.Parent           = self.ElementsHolder
					addStroke(DropFrame, Theme.OutlineColor)

					local DropTitle = Instance.new("TextLabel")
					DropTitle.Name               = "Title"
					DropTitle.BackgroundTransparency = 1
					DropTitle.Size               = UDim2.new(0, 150, 1, 0)
					DropTitle.Position           = UDim2.new(0, 5, 0, 0)
					DropTitle.TextSize           = 14
					DropTitle.TextXAlignment     = Enum.TextXAlignment.Left
					DropTitle.TextColor3         = COL_TEXT_NORMAL
					DropTitle.Font               = Enum.Font.Gotham
					DropTitle.Parent             = DropFrame

					-- Set initial display text
					if cfg.Multi then
						DropTitle.Text = (#cfg.Default > 0) and table.concat(cfg.Default, ", ") or cfg.Placeholder
					else
						DropTitle.Text = (#cfg.Default > 0) and cfg.Default[1] or cfg.Placeholder
					end

					local Indicator = Instance.new("TextLabel")
					Indicator.Name               = "Indicator"
					Indicator.BackgroundTransparency = 1
					Indicator.Text               = "▼"
					Indicator.TextSize           = 14
					Indicator.TextXAlignment     = Enum.TextXAlignment.Right
					Indicator.Size               = UDim2.new(0, 15, 1, 0)
					Indicator.Position           = UDim2.new(1, -20, 0, -2)
					Indicator.TextColor3         = COL_TEXT_NORMAL
					Indicator.Font               = Enum.Font.Gotham
					Indicator.Parent             = DropFrame

					-- Expanded list
					local ListFrame = Instance.new("Frame")
					ListFrame.Name             = "List"
					ListFrame.BackgroundColor3 = COL_ELEM_BG
					ListFrame.BorderSizePixel  = 0
					ListFrame.Size             = UDim2.new(0, 208, 0, #cfg.Options * 20)
					ListFrame.Position         = UDim2.new(0, 0, 0, 20)
					ListFrame.Visible          = false
					ListFrame.ZIndex           = 11
					ListFrame.ClipsDescendants = true
					ListFrame.Parent           = DropFrame
					addStroke(ListFrame, Theme.OutlineColor)

					local ListLayout = Instance.new("UIListLayout")
					ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
					ListLayout.Padding   = UDim.new(0, 0)
					ListLayout.Parent    = ListFrame

					local expanded    = false
					local selected    = cfg.Multi and cfg.Default or (cfg.Default[1] or nil)
					local optButtons  = {}

					local function setExpanded(state)
						expanded = state
						ListFrame.Visible = state
						Indicator.Text    = state and "▲" or "▼"
						tween(DropFrame, { BackgroundColor3 = state and Theme.MainColor or COL_ELEM_BG })
					end

					DropFrame.MouseEnter:Connect(function()
						tween(DropTitle,  { TextColor3 = COL_TEXT_HOVER })
						tween(Indicator,  { TextColor3 = COL_TEXT_HOVER })
					end)
					DropFrame.MouseLeave:Connect(function()
						tween(DropTitle,  { TextColor3 = COL_TEXT_NORMAL })
						tween(Indicator,  { TextColor3 = COL_TEXT_NORMAL })
					end)

					DropFrame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							setExpanded(not expanded)
						end
					end)

					-- Build options
					for _, optName in ipairs(cfg.Options) do
						local wrapper = Instance.new("TextButton")
						wrapper.Name                = optName
						wrapper.BackgroundTransparency = 1
						wrapper.AutoButtonColor     = false
						wrapper.Size                = UDim2.new(1, 0, 0, 20)
						wrapper.ZIndex              = 11
						wrapper.Text                = ""
						wrapper.Parent              = ListFrame

						local optLbl = Instance.new("TextLabel")
						optLbl.Name                = "Label"
						optLbl.BackgroundColor3    = COL_ELEM_BG
						optLbl.BackgroundTransparency = 0
						optLbl.Size                = UDim2.new(1, 0, 1, 0)
						optLbl.Text                = optName
						optLbl.TextSize            = 14
						optLbl.TextColor3          = COL_TEXT_NORMAL
						optLbl.TextXAlignment      = Enum.TextXAlignment.Left
						optLbl.Font                = Enum.Font.Gotham
						optLbl.Parent              = wrapper
						addStroke(optLbl, Theme.OutlineColor)

						local optPad = Instance.new("UIPadding")
						optPad.PaddingLeft = UDim.new(0, 5)
						optPad.Parent      = optLbl

						wrapper.MouseEnter:Connect(function() tween(optLbl, { TextColor3 = COL_TEXT_HOVER }) end)
						wrapper.MouseLeave:Connect(function() tween(optLbl, { TextColor3 = COL_TEXT_NORMAL }) end)

						wrapper.MouseButton1Click:Connect(function()
							if cfg.Multi then
								local idx = table.find(selected, optName)
								if idx then
									table.remove(selected, idx)
									tween(optLbl, { BackgroundColor3 = COL_ELEM_BG })
								else
									table.insert(selected, optName)
									tween(optLbl, { BackgroundColor3 = Theme.MainColor })
								end
								DropTitle.Text = (#selected > 0) and table.concat(selected, ", ") or cfg.Placeholder
								cfg.Callback(selected)
							else
								selected = optName
								DropTitle.Text = optName
								cfg.Callback(optName)
								-- Flash
								tween(optLbl, { BackgroundColor3 = Theme.MainColor }, function()
									tween(optLbl, { BackgroundColor3 = COL_ELEM_BG })
								end)
								setExpanded(false)
							end
						end)

						table.insert(optButtons, { Name = optName, Label = optLbl })
					end

					return {
						Frame    = DropFrame,
						GetValue = function() return selected end,
						SetValue = function(val)
							if cfg.Multi then
								selected = {}
								-- Reset highlights
								for _, ob in ipairs(optButtons) do ob.Label.BackgroundColor3 = COL_ELEM_BG end
								for _, v in ipairs(val) do
									for _, ob in ipairs(optButtons) do
										if ob.Name == v then
											table.insert(selected, v)
											ob.Label.BackgroundColor3 = Theme.MainColor
											break
										end
									end
								end
								DropTitle.Text = (#selected > 0) and table.concat(selected, ", ") or cfg.Placeholder
								cfg.Callback(selected)
							else
								for _, ob in ipairs(optButtons) do
									if ob.Name == val then
										selected = val
										DropTitle.Text = val
										cfg.Callback(val)
										break
									end
								end
							end
						end,
					}
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddSlider
				-- ─────────────────────────────────────────────────────────────
				function Section:AddSlider(cfg)
					cfg = cfg or {}
					cfg.Title    = cfg.Title    or "Slider"
					cfg.Min      = cfg.Min      or 0
					cfg.Max      = cfg.Max      or 100
					cfg.Default  = cfg.Default  ~= nil and cfg.Default or cfg.Min
					cfg.Rounding = cfg.Rounding or 0
					cfg.Suffix   = cfg.Suffix   or ""
					cfg.Callback = cfg.Callback or function() end

					local SliderFrame = Instance.new("Frame")
					SliderFrame.Name                 = cfg.Title
					SliderFrame.BackgroundTransparency = 1
					SliderFrame.BorderSizePixel      = 0
					SliderFrame.Size                 = UDim2.new(0, 208, 0, 40)
					SliderFrame.Parent               = self.ElementsHolder

					local TitleLbl = Instance.new("TextLabel")
					TitleLbl.Name               = "Title"
					TitleLbl.BackgroundTransparency = 1
					TitleLbl.Size               = UDim2.new(0, 155, 0, 15)
					TitleLbl.Text               = cfg.Title
					TitleLbl.TextSize           = 14
					TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
					TitleLbl.TextColor3         = COL_TEXT_NORMAL
					TitleLbl.Font               = Enum.Font.Gotham
					TitleLbl.Parent             = SliderFrame

					local ValueLbl = Instance.new("TextLabel")
					ValueLbl.Name               = "Value"
					ValueLbl.BackgroundTransparency = 1
					ValueLbl.Size               = UDim2.new(0, 50, 0, 15)
					ValueLbl.Position           = UDim2.new(0, 158, 0, 0)
					ValueLbl.TextSize           = 14
					ValueLbl.TextXAlignment     = Enum.TextXAlignment.Right
					ValueLbl.TextColor3         = COL_TEXT_NORMAL
					ValueLbl.Font               = Enum.Font.Gotham
					ValueLbl.Parent             = SliderFrame

					local Track = Instance.new("Frame")
					Track.Name             = "Track"
					Track.BackgroundColor3 = COL_ELEM_BG
					Track.BorderSizePixel  = 0
					Track.Size             = UDim2.new(1, 0, 0, 15)
					Track.Position         = UDim2.new(0, 0, 0, 20)
					Track.Parent           = SliderFrame
					addStroke(Track, Theme.OutlineColor)

					local Fill = Instance.new("Frame")
					Fill.Name             = "Fill"
					Fill.BackgroundColor3 = Theme.MainColor
					Fill.BorderSizePixel  = 0
					Fill.Size             = UDim2.new(0, 0, 1, 0)
					Fill.Parent           = Track

					-- Rounding helper
					local function roundValue(v)
						if cfg.Rounding > 0 then
							return math.floor(v / cfg.Rounding + 0.5) * cfg.Rounding
						end
						return v
					end

					local currentValue = cfg.Default

					local function applyValue(mouseX)
						local rel     = math.clamp(mouseX - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
						local pct     = (Track.AbsoluteSize.X > 0) and (rel / Track.AbsoluteSize.X) or 0
						currentValue  = roundValue(cfg.Min + (cfg.Max - cfg.Min) * pct)
						Fill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.03, true)
						ValueLbl.Text = tostring(math.floor(currentValue)) .. cfg.Suffix
						cfg.Callback(currentValue)
					end

					-- Set initial state
					local initPct = (cfg.Max ~= cfg.Min) and ((cfg.Default - cfg.Min) / (cfg.Max - cfg.Min)) or 0
					Fill.Size     = UDim2.new(initPct, 0, 1, 0)
					ValueLbl.Text = tostring(cfg.Default) .. cfg.Suffix

					local dragging = false

					Track.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true; applyValue(input.Position.X)
						end
					end)
					Fill.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true; applyValue(input.Position.X)
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							applyValue(input.Position.X)
						end
					end)
					UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
						end
					end)

					SliderFrame.MouseEnter:Connect(function()
						tween(TitleLbl, { TextColor3 = COL_TEXT_HOVER })
						tween(ValueLbl, { TextColor3 = COL_TEXT_HOVER })
					end)
					SliderFrame.MouseLeave:Connect(function()
						tween(TitleLbl, { TextColor3 = COL_TEXT_NORMAL })
						tween(ValueLbl, { TextColor3 = COL_TEXT_NORMAL })
					end)

					return {
						Frame    = SliderFrame,
						Fill     = Fill,
						GetValue = function() return currentValue end,
						SetValue = function(v)
							v = math.clamp(v, cfg.Min, cfg.Max)
							local pct = (cfg.Max ~= cfg.Min) and ((v - cfg.Min) / (cfg.Max - cfg.Min)) or 0
							currentValue  = roundValue(v)
							Fill.Size     = UDim2.new(pct, 0, 1, 0)
							ValueLbl.Text = tostring(math.floor(currentValue)) .. cfg.Suffix
							cfg.Callback(currentValue)
						end,
					}
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddLabel
				-- ─────────────────────────────────────────────────────────────
				function Section:AddLabel(cfg)
					cfg = cfg or {}
					cfg.Title         = cfg.Title         or "Label"
					cfg.TextAlignment = cfg.TextAlignment or "Left"

					local LabelFrame = Instance.new("Frame")
					LabelFrame.Name                 = "Label_" .. cfg.Title
					LabelFrame.BackgroundTransparency = 1
					LabelFrame.BorderSizePixel      = 0
					LabelFrame.Size                 = UDim2.new(0, 208, 0, 15)
					LabelFrame.Parent               = self.ElementsHolder

					local Lbl = Instance.new("TextLabel")
					Lbl.Name               = "Title"
					Lbl.BackgroundTransparency = 1
					Lbl.Size               = UDim2.new(1, 0, 1, 0)
					Lbl.Text               = cfg.Title
					Lbl.TextSize           = 14
					Lbl.TextXAlignment     = normalizeAlignment(cfg.TextAlignment)
					Lbl.TextColor3         = COL_TEXT_NORMAL
					Lbl.Font               = Enum.Font.Gotham
					Lbl.Parent             = LabelFrame

					return { Frame = LabelFrame, Label = Lbl }
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddColorPicker
				-- ─────────────────────────────────────────────────────────────
				function Section:AddColorPicker(cfg)
					cfg = cfg or {}
					cfg.Title    = cfg.Title    or "Color"
					cfg.Default  = cfg.Default  or Color3.fromRGB(255, 255, 255)
					cfg.Callback = cfg.Callback or function() end

					-- Row in ElementsHolder
					local RowFrame = Instance.new("Frame")
					RowFrame.Name                 = "ColorPicker_" .. cfg.Title
					RowFrame.BackgroundTransparency = 1
					RowFrame.BorderSizePixel      = 0
					RowFrame.ZIndex               = 10
					RowFrame.Size                 = UDim2.new(0, 208, 0, 15)
					RowFrame.Parent               = self.ElementsHolder

					local RowTitle = Instance.new("TextLabel")
					RowTitle.Name               = "Title"
					RowTitle.BackgroundTransparency = 1
					RowTitle.Size               = UDim2.new(1, 0, 1, 0)
					RowTitle.Text               = cfg.Title .. ":"
					RowTitle.TextSize           = 14
					RowTitle.TextXAlignment     = Enum.TextXAlignment.Left
					RowTitle.TextColor3         = COL_TEXT_NORMAL
					RowTitle.Font               = Enum.Font.Gotham
					RowTitle.Parent             = RowFrame

					-- Small color swatch
					local Swatch = Instance.new("Frame")
					Swatch.Name             = "Swatch"
					Swatch.BackgroundColor3 = cfg.Default
					Swatch.BorderSizePixel  = 0
					Swatch.Size             = UDim2.new(0, 30, 0, 15)
					Swatch.Position         = UDim2.new(0, 177, 0, 0)
					Swatch.ZIndex           = 10
					Swatch.Parent           = RowFrame
					addStroke(Swatch, Theme.OutlineColor)

					-- Popup picker panel
					local PickerPanel = Instance.new("Frame")
					PickerPanel.Name             = "PickerPanel"
					PickerPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
					PickerPanel.BorderSizePixel  = 0
					PickerPanel.Size             = UDim2.new(0, 150, 0, 150)
					PickerPanel.Position         = UDim2.new(0, -120, 1, 2)
					PickerPanel.Visible          = false
					PickerPanel.ZIndex           = 50
					PickerPanel.Parent           = Swatch

					local PanelStroke = addStroke(PickerPanel, cfg.Default, 2)

					-- Gradient area
					local GradArea = Instance.new("Frame")
					GradArea.Name             = "GradArea"
					GradArea.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					GradArea.BorderSizePixel  = 0
					GradArea.Position         = UDim2.new(0, 5, 0, 5)
					GradArea.Size             = UDim2.new(0, 140, 0, 95)
					GradArea.ZIndex           = 51
					GradArea.Parent           = PickerPanel
					addStroke(GradArea, Theme.OutlineColor)

					local GradGrad = Instance.new("UIGradient")
					GradGrad.Rotation = 0
					GradGrad.Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(0.150, Color3.fromRGB(255, 0,   0  )),
						ColorSequenceKeypoint.new(0.333, Color3.fromRGB(236, 255, 16 )),
						ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0,   255, 9  )),
						ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,   255, 248)),
						ColorSequenceKeypoint.new(0.833, Color3.fromRGB(0,   0,   255)),
						ColorSequenceKeypoint.new(1.000, Color3.fromRGB(239, 0,   255)),
					}
					GradGrad.Parent = GradArea

					-- Picker cursor
					local Cursor = Instance.new("Frame")
					Cursor.Name             = "Cursor"
					Cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					Cursor.BorderSizePixel  = 0
					Cursor.Size             = UDim2.new(0, 5, 0, 5)
					Cursor.ZIndex           = 52
					Cursor.Parent           = PickerPanel
					addStroke(Cursor, Theme.OutlineColor)

					-- Brightness slider
					local BrightTrack = Instance.new("Frame")
					BrightTrack.Name             = "BrightTrack"
					BrightTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					BrightTrack.BorderSizePixel  = 0
					BrightTrack.Position         = UDim2.new(0, 5, 0, 105)
					BrightTrack.Size             = UDim2.new(0, 140, 0, 15)
					BrightTrack.ZIndex           = 51
					BrightTrack.Parent           = PickerPanel
					addStroke(BrightTrack, Theme.OutlineColor)

					local BrightGrad = Instance.new("UIGradient")
					BrightGrad.Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
					}
					BrightGrad.Parent = BrightTrack

					local BrightCursor = Instance.new("Frame")
					BrightCursor.Name             = "BrightCursor"
					BrightCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					BrightCursor.BorderSizePixel  = 0
					BrightCursor.Size             = UDim2.new(0, 6, 1, 0)
					BrightCursor.ZIndex           = 52
					BrightCursor.Parent           = BrightTrack
					addStroke(BrightCursor, Theme.OutlineColor)

					-- Close button
					local CloseBtn = Instance.new("Frame")
					CloseBtn.Name             = "CloseBtn"
					CloseBtn.BackgroundColor3 = COL_ELEM_BG
					CloseBtn.BorderSizePixel  = 0
					CloseBtn.Position         = UDim2.new(0, 5, 0, 125)
					CloseBtn.Size             = UDim2.new(0, 140, 0, 20)
					CloseBtn.ZIndex           = 51
					CloseBtn.Parent           = PickerPanel
					addStroke(CloseBtn, Theme.OutlineColor)

					local CloseLbl = Instance.new("TextLabel")
					CloseLbl.BackgroundTransparency = 1
					CloseLbl.Size               = UDim2.new(1, 0, 1, 0)
					CloseLbl.Text               = "Close"
					CloseLbl.Font               = Enum.Font.Gotham
					CloseLbl.TextSize           = 14
					CloseLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
					CloseLbl.ZIndex             = 52
					CloseLbl.Parent             = CloseBtn

					-- State
					local draggingGrad   = false
					local draggingBright = false
					local baseCol        = cfg.Default
					local selColor       = cfg.Default
					local brightness     = 1

					local function applyBrightness(c)
						local h, s, _ = Color3.toHSV(c)
						return Color3.fromHSV(h, s, brightness)
					end

					local function commitColor()
						Swatch.BackgroundColor3 = selColor
						PanelStroke.Color       = selColor
						cfg.Callback(selColor)
					end

					local function updateFromGrad(mouseX)
						local rel = GradArea.AbsoluteSize.X
						local t   = (rel > 0) and math.clamp((mouseX - GradArea.AbsolutePosition.X) / rel, 0, 1) or 0
						local py  = (GradArea.AbsoluteSize.Y > 0) and GradArea.AbsoluteSize.Y * 0.5 or 47
						Cursor.Position = UDim2.new(0, t * (rel > 0 and rel or 140) - Cursor.AbsoluteSize.X * 0.5, 0, py - Cursor.AbsoluteSize.Y * 0.5)
						baseCol  = sampleGradient(t)
						selColor = applyBrightness(baseCol)
						commitColor()
					end

					local function updateFromBright(mouseX)
						local w  = BrightTrack.AbsoluteSize.X
						local px = math.clamp(mouseX - BrightTrack.AbsolutePosition.X, 0, w)
						BrightCursor.Position = UDim2.new(0, px - BrightCursor.AbsoluteSize.X * 0.5, 0, 0)
						brightness = 1 - ((w > 0) and (px / w) or 0)
						selColor   = applyBrightness(baseCol)
						commitColor()
					end

					GradArea.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingGrad = true; updateFromGrad(i.Position.X)
						end
					end)
					GradArea.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingGrad = false end
					end)

					BrightTrack.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							draggingBright = true; updateFromBright(i.Position.X)
						end
					end)
					BrightTrack.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingBright = false end
					end)

					UserInputService.InputChanged:Connect(function(i)
						if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
						if draggingGrad   then updateFromGrad(i.Position.X)   end
						if draggingBright then updateFromBright(i.Position.X)  end
					end)

					Swatch.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							PickerPanel.Visible = not PickerPanel.Visible
						end
					end)

					CloseBtn.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							PickerPanel.Visible = false
						end
					end)

					RowFrame.MouseEnter:Connect(function() tween(RowTitle, { TextColor3 = COL_TEXT_HOVER }) end)
					RowFrame.MouseLeave:Connect(function() tween(RowTitle, { TextColor3 = COL_TEXT_NORMAL }) end)

					-- Position cursor at default color
					local function applyDefault(c)
						local t  = colorToGradientT(c)
						local gw = 140
						local gh = 95
						Cursor.Position     = UDim2.new(0, t * gw - 2, 0, gh * 0.5 - 2)
						baseCol             = sampleGradient(t)
						brightness          = 1
						BrightCursor.Position = UDim2.new(0, gw - 3, 0, 0)
						selColor            = applyBrightness(baseCol)
						Swatch.BackgroundColor3 = selColor
						PanelStroke.Color   = selColor
					end
					applyDefault(cfg.Default)

					return {
						Frame    = RowFrame,
						Swatch   = Swatch,
						Panel    = PickerPanel,
						GetColor = function() return selColor end,
						SetColor = function(c)
							applyDefault(c)
							cfg.Callback(selColor)
						end,
					}
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddKeyPicker
				-- ─────────────────────────────────────────────────────────────
				function Section:AddKeyPicker(cfg)
					cfg = cfg or {}
					cfg.Title    = cfg.Title    or "Keybind"
					cfg.Default  = cfg.Default  or "None"
					cfg.Mode     = cfg.Mode     or "Toggle"
					cfg.Callback = cfg.Callback or function() end

					local Holder = Instance.new("Frame")
					Holder.Name                 = "KeyPicker_" .. cfg.Title
					Holder.BackgroundTransparency = 1
					Holder.BorderSizePixel      = 0
					Holder.Size                 = UDim2.new(0, 208, 0, 20)
					Holder.Parent               = self.ElementsHolder

					local TitleLbl = Instance.new("TextLabel")
					TitleLbl.Name               = "Title"
					TitleLbl.BackgroundTransparency = 1
					TitleLbl.Size               = UDim2.new(1, -40, 1, 0)
					TitleLbl.Text               = cfg.Title
					TitleLbl.TextSize           = 14
					TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
					TitleLbl.TextColor3         = COL_TEXT_NORMAL
					TitleLbl.Font               = Enum.Font.Gotham
					TitleLbl.Parent             = Holder

					local KeyLbl = Instance.new("TextLabel")
					KeyLbl.Name               = "Key"
					KeyLbl.BackgroundTransparency = 1
					KeyLbl.Size               = UDim2.new(0, 30, 0, 15)
					KeyLbl.Position           = UDim2.new(0, 177, 0, 0)
					KeyLbl.Text               = cfg.Default
					KeyLbl.TextSize           = 12
					KeyLbl.TextXAlignment     = Enum.TextXAlignment.Center
					KeyLbl.TextColor3         = COL_TEXT_DIM
					KeyLbl.Font               = Enum.Font.GothamBold
					KeyLbl.Parent             = Holder

					TitleLbl.MouseEnter:Connect(function() tween(TitleLbl, { TextColor3 = COL_TEXT_HOVER }) end)
					TitleLbl.MouseLeave:Connect(function() tween(TitleLbl, { TextColor3 = COL_TEXT_NORMAL }) end)

					local currentKey  = cfg.Default
					local toggleState = false
					local kbHover     = false
					local listening   = false

					KeyLbl.MouseEnter:Connect(function() kbHover = true  end)
					KeyLbl.MouseLeave:Connect(function() kbHover = false end)

					UserInputService.InputBegan:Connect(function(input, gp)
						if gp then return end

						-- Start listening
						if kbHover and not listening and input.UserInputType == Enum.UserInputType.MouseButton1 then
							listening = true
							startListening(KeyLbl, function(name)
								listening = false
								if name ~= currentKey then
									currentKey = name
									Window:AddKeybind(cfg.Title, name)
									cfg.Callback("Changed", { Key = name, Mode = cfg.Mode })
								end
							end)
							return
						end

						if not keyMatchesInput(input, currentKey) then return end

						if cfg.Mode == "Toggle" then
							toggleState = not toggleState
							tween(KeyLbl, { TextColor3 = toggleState and Theme.MainColor or COL_TEXT_DIM })
							cfg.Callback("Pressed", { Key = currentKey, Mode = cfg.Mode, State = toggleState })
						elseif cfg.Mode == "Hold" then
							tween(KeyLbl, { TextColor3 = Theme.MainColor })
							cfg.Callback("Pressed", { Key = currentKey, Mode = cfg.Mode, State = true })
						end
					end)

					UserInputService.InputEnded:Connect(function(input, gp)
						if gp or cfg.Mode ~= "Hold" then return end
						if keyMatchesInput(input, currentKey) then
							tween(KeyLbl, { TextColor3 = COL_TEXT_DIM })
							cfg.Callback("Pressed", { Key = currentKey, Mode = cfg.Mode, State = false })
						end
					end)

					return {
						GetKey  = function() return currentKey end,
						SetKey  = function(v)
							if v ~= currentKey then
								currentKey = v
								KeyLbl.Text = v
								cfg.Callback("Changed", { Key = v, Mode = cfg.Mode })
							end
						end,
						GetMode = function() return cfg.Mode end,
						SetMode = function(v) cfg.Mode = v end,
					}
				end

				return Section
			end -- AddSection

			return Tab
		end -- AddTab

		return Window
	end -- CreateWindow

	return CreateWindow
end -- InitJWareUI

-- ─── Export ───────────────────────────────────────────────────────────────────
if getgenv then
	getgenv().JWareUI = getgenv().JWareUI or InitJWareUI()
	return getgenv().JWareUI
else
	_G.JWareUI = _G.JWareUI or InitJWareUI()
	return _G.JWareUI
end
