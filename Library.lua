-- ─── Themes ───────────────────────────────────────────────────────────────────
Themes = {
	JWare  = { MainColor = Color3.fromRGB(70,7,100),   OutlineColor = Color3.fromRGB(0,0,0), BackgroundColor = Color3.fromRGB(27,27,27), BackgroundColor2 = Color3.fromRGB(16,16,16) },
	JWare2 = { MainColor = Color3.fromRGB(135,0,2),    OutlineColor = Color3.fromRGB(0,0,0), BackgroundColor = Color3.fromRGB(27,27,27), BackgroundColor2 = Color3.fromRGB(16,16,16) },
}

local function InitJWareUI()
	-- ─── Services ──────────────────────────────────────────────────────────────
	local Players          = game:GetService("Players")
	local TweenService     = game:GetService("TweenService")
	local RunService       = game:GetService("RunService")
	local CoreGui          = game:GetService("CoreGui")
	local UIS              = game:GetService("UserInputService")

	-- ─── Constants ─────────────────────────────────────────────────────────────
	local VIEWPORT   = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
	local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local MB1        = Enum.UserInputType.MouseButton1
	local MOUSE_MOVE = Enum.UserInputType.MouseMovement

	local C_ELEM_BG     = Color3.fromRGB(26,26,26)
	local C_TEXT_NORMAL = Color3.fromRGB(200,200,200)
	local C_TEXT_HOVER  = Color3.fromRGB(255,255,255)
	local C_TEXT_DIM    = Color3.fromRGB(150,150,150)

	Theme = Themes.JWare2

	-- ─── Helpers ───────────────────────────────────────────────────────────────
	local function tween(obj, goal, cb)
		local t = TweenService:Create(obj, TWEEN_INFO, goal)
		if cb then t.Completed:Connect(cb) end
		t:Play(); return t
	end

	local function resolveParent()
		if RunService:IsStudio() then
			local lp = Players.LocalPlayer
			return lp and lp:FindFirstChildOfClass("PlayerGui") or CoreGui
		end
		local ok = pcall(function() return CoreGui.Parent end)
		return (ok and CoreGui) or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui)
	end

	local function normalizeAlign(v)
		if typeof(v)=="EnumItem" and v.EnumType==Enum.TextXAlignment then return v end
		if typeof(v)=="string" then
			local s=v:lower()
			if s=="left"  then return Enum.TextXAlignment.Left  end
			if s=="right" then return Enum.TextXAlignment.Right end
		end
		return Enum.TextXAlignment.Center
	end

	local function validate(defs, opts)
		for k,v in pairs(defs) do if opts[k]==nil then opts[k]=v end end
	end

	local function addStroke(parent, color, thickness, mode)
		local s       = Instance.new("UIStroke")
		s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
		s.Color       = color     or Color3.new()
		s.Thickness   = thickness or 1
		s.Parent      = parent
		return s
	end

	local function makeInstance(cls, props, parent)
		local i = Instance.new(cls)
		for k,v in pairs(props) do i[k]=v end
		if parent then i.Parent=parent end
		return i
	end

	local function makeLabel(props, parent)
		props.BackgroundTransparency = props.BackgroundTransparency ~= nil and props.BackgroundTransparency or 1
		props.BorderSizePixel        = props.BorderSizePixel        ~= nil and props.BorderSizePixel        or 0
		return makeInstance("TextLabel", props, parent)
	end

	local function makeFrame(props, parent)
		props.BorderSizePixel = props.BorderSizePixel ~= nil and props.BorderSizePixel or 0
		return makeInstance("Frame", props, parent)
	end

	local function makeScreenGui(name, parent)
		return makeInstance("ScreenGui", { Name=name, IgnoreGuiInset=true, ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling }, parent)
	end

	local function makeDraggable(handle, target, speed)
		speed = speed or 0.2
		local dragging, dragStart, frameStart = false, Vector2.zero, target.Position
		local targetPos = target.Position
		handle.InputBegan:Connect(function(i)
			if i.UserInputType~=MB1 then return end
			dragging=true; dragStart=i.Position; frameStart=target.Position; targetPos=frameStart
			i.Changed:Connect(function()
				if i.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end)
		UIS.InputChanged:Connect(function(i)
			if dragging and i.UserInputType==MOUSE_MOVE then
				local d=i.Position-dragStart
				targetPos=UDim2.new(0,frameStart.X.Offset+d.X,0,frameStart.Y.Offset+d.Y)
			end
		end)
		RunService.RenderStepped:Connect(function()
			target.Position=target.Position:Lerp(targetPos,speed)
		end)
	end

	local function toggleState(cur, state)
		if state==nil then return not cur end
		return state and true or false
	end

	local function keyMatchesInput(input, keyName)
		if not keyName or keyName=="None" or keyName=="" then return false end
		if input.UserInputType==Enum.UserInputType.Keyboard then
			return input.KeyCode.Name==keyName
		elseif input.UserInputType.Name:match("MouseButton") and keyName:match("^MB%d$") then
			return ("MB"..(input.UserInputType.Value-Enum.UserInputType.MouseButton1.Value+1))==keyName
		end
		return false
	end

	local function inputToKeyName(input)
		if input.UserInputType==Enum.UserInputType.Keyboard then
			return (input.KeyCode==Enum.KeyCode.Escape) and "None" or input.KeyCode.Name
		elseif input.UserInputType==Enum.UserInputType.MouseButton1 then return "MB1"
		elseif input.UserInputType==Enum.UserInputType.MouseButton2 then return "MB2"
		elseif input.UserInputType==Enum.UserInputType.MouseButton3 then return "MB3"
		end
	end

	local function startListening(keyLabel, onBound)
		keyLabel.Text="..."
		task.defer(function()
			local conn
			conn=UIS.InputBegan:Connect(function(input,gp)
				if gp then return end
				local name=inputToKeyName(input)
				if name then conn:Disconnect(); keyLabel.Text=name; onBound(name) end
			end)
		end)
	end

	-- ─── Color Picker Helpers ──────────────────────────────────────────────────
	local function colorToHex(c)
		return string.format("%02X%02X%02X", math.floor(c.R*255+.5), math.floor(c.G*255+.5), math.floor(c.B*255+.5))
	end

	local function hexToColor(hex)
		hex=hex:gsub("#",""):upper()
		if #hex~=6 then return nil end
		local r,g,b=tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16)
		return (r and g and b) and Color3.fromRGB(r,g,b) or nil
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- Window Constructor
	-- ═══════════════════════════════════════════════════════════════════════════
	local function CreateWindow(opts)
		opts=opts or {}
		validate({ Title="JWare UI [v1.0]", TextAlignment="Center", Size=Vector2.new(700,550) }, opts)

		local WIN_W, WIN_H = opts.Size.X, opts.Size.Y
		local guiParent    = resolveParent()
		local Window       = { CurrentTab=nil, Tabs={}, KeybindLabels={} }

		-- ═════════════════════════════════════════════════════════════════════
		-- Config / Save System
		-- ═════════════════════════════════════════════════════════════════════
		local CONFIG_FOLDER = "JWareUI_Configs"
		local CONFIG_EXT    = ".json"

		local saveableElements = {}

		local function ensureFolder()
			if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
		end

		local function configPath(name)
			return CONFIG_FOLDER .. "/" .. name .. CONFIG_EXT
		end

		local function listConfigs()
			ensureFolder()
			local files = listfiles(CONFIG_FOLDER)
			local names = {}
			for _, path in ipairs(files) do
				local name = path:match("[/\\]?([^/\\]+)$") or path
				if name ~= "_autoload.txt" and name:sub(-#CONFIG_EXT) == CONFIG_EXT then
					table.insert(names, name:sub(1, -#CONFIG_EXT-1))
				end
			end
			return names
		end

		local function serialise(v)
			local t = typeof(v)
			if t == "boolean" or t == "number" or t == "string" then return v end
			if t == "Color3" then return { __type="Color3", r=v.R, g=v.G, b=v.B } end
			if t == "table"  then
				local out = {}
				for i,x in ipairs(v) do out[i] = serialise(x) end
				return out
			end
			return tostring(v)
		end

		local function deserialise(v)
			if type(v) == "table" then
				if v.__type == "Color3" then return Color3.new(v.r, v.g, v.b) end
				local out = {}
				for i,x in ipairs(v) do out[i] = deserialise(x) end
				return out
			end
			return v
		end

		function Window:SaveConfig(name)
			ensureFolder()
			local data = {}
			for _, entry in ipairs(saveableElements) do
				local ok, val = pcall(entry.getVal)
				if ok then data[entry.key] = serialise(val) end
			end
			local ok, encoded = pcall(game:GetService("HttpService").JSONEncode, game:GetService("HttpService"), data)
			if ok then writefile(configPath(name), encoded) end
		end

		function Window:LoadConfig(name)
			local path = configPath(name)
			if not isfile(path) then return false end
			local ok, decoded = pcall(function()
				return game:GetService("HttpService"):JSONDecode(readfile(path))
			end)
			if not ok or type(decoded) ~= "table" then return false end
			for _, entry in ipairs(saveableElements) do
				local raw = decoded[entry.key]
				if raw ~= nil then
					pcall(entry.setVal, deserialise(raw))
				end
			end
			return true
		end

		local function registerSaveable(key, getVal, setVal)
			table.insert(saveableElements, { key=key, getVal=getVal, setVal=setVal })
		end

		-- ── ScreenGuis ────────────────────────────────────────────────────────
		local mainGui    = makeScreenGui("JWare UI",            guiParent)
		local overlayGui = makeScreenGui("JWare UI Watermarks", guiParent)
		Window._mainGui    = mainGui
		Window._overlayGui = overlayGui

		local PopupOverlay = makeFrame({ Name="PopupOverlay", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0), ZIndex=200 }, mainGui)
		local activePopup  = nil
		local function closeActivePopup()
			if activePopup then activePopup.Visible=false; activePopup=nil end
		end

		-- ── Theme Registry ────────────────────────────────────────────────────
		local T = {
			strokes={}, outlineStrokes={}, gradients={}, fills={}, scrolls={},
			mainFrames={}, bg2Frames={}, tabButtons={}, activeChecks={}, activeOptLabels={}
		}
		local function track(list, item) table.insert(list,item); return item end

		local function addTrackedStroke(parent, color, thickness, mode)
			local s=addStroke(parent,color,thickness,mode)
			if color==Theme.MainColor then track(T.strokes,s) end
			return s
		end
		local function addOutlineStroke(parent, thickness, mode)
			return track(T.outlineStrokes, addStroke(parent,Theme.OutlineColor,thickness,mode))
		end

		function Window:ApplyTheme(nt)
			for _,s in ipairs(T.strokes)         do if s and s.Parent then s.Color=nt.MainColor end end
			for _,s in ipairs(T.outlineStrokes)  do if s and s.Parent then s.Color=nt.OutlineColor end end
			for _,g in ipairs(T.gradients)        do if g and g.Parent then g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,nt.MainColor),ColorSequenceKeypoint.new(1,nt.BackgroundColor2)} end end
			for _,f in ipairs(T.fills)            do if f and f.Parent then f.BackgroundColor3=nt.MainColor end end
			for _,sf in ipairs(T.scrolls)         do if sf and sf.Parent then sf.ScrollBarImageColor3=nt.MainColor end end
			for _,fr in ipairs(T.mainFrames)      do if fr and fr.Parent then fr.BackgroundColor3=nt.BackgroundColor end end
			for _,fr in ipairs(T.bg2Frames)       do if fr and fr.Parent then fr.BackgroundColor3=nt.BackgroundColor2 end end
			for _,btn in ipairs(T.tabButtons)     do if btn and btn.Parent and btn.BackgroundTransparency==0 then btn.BackgroundColor3=nt.MainColor end end
			for _,c in ipairs(T.activeChecks)     do if c and c.Parent then c.BackgroundColor3=nt.MainColor end end
			for _,l in ipairs(T.activeOptLabels)  do if l and l.Parent then l.BackgroundColor3=nt.MainColor end end
			Theme=nt
		end

		local uiVisible=true
		function Window:UIToggle(state) uiVisible=toggleState(uiVisible,state); mainGui.Enabled=uiVisible end

		local function mainFrame(props, parent)
			local f=makeFrame(props,parent); track(T.mainFrames,f); return f
		end
		local function bg2Frame(props, parent)
			local f=makeFrame(props,parent); track(T.bg2Frames,f); return f
		end

		-- ── Main Frame ────────────────────────────────────────────────────────
		local MainFrame = mainFrame({
			Name="MainFrame", BackgroundColor3=Theme.BackgroundColor,
			Size=UDim2.new(0,WIN_W,0,WIN_H),
			Position=UDim2.fromOffset(math.floor(VIEWPORT.X/2-WIN_W/2), math.floor(VIEWPORT.Y/2-WIN_H/2)),
		}, mainGui)
		addTrackedStroke(MainFrame, Theme.MainColor, 2)

		local TitleBar = mainFrame({ Name="TitleBar", BackgroundColor3=Theme.BackgroundColor, Size=UDim2.new(0,WIN_W,0,30) }, MainFrame)

		local TitleLabel = makeLabel({
			Name="Title", Size=UDim2.new(0,WIN_W-20,1,0), Position=UDim2.new(0,10,0,0),
			Text=opts.Title, TextSize=15, TextColor3=Color3.fromRGB(255,255,255),
			TextXAlignment=normalizeAlign(opts.TextAlignment),
			FontFace=Font.new("rbxasset://fonts/families/DenkOne.json"),
		}, TitleBar)

		local ContentFrame = bg2Frame({
			Name="ContentFrame", BackgroundColor3=Theme.BackgroundColor2,
			Size=UDim2.new(0,WIN_W-10,0,WIN_H-35), Position=UDim2.new(0,5,0,30),
		}, MainFrame)
		addOutlineStroke(ContentFrame,2)

		local TabsBar = bg2Frame({ Name="TabsBar", BackgroundColor3=Theme.BackgroundColor2, Size=UDim2.new(1,0,0,40) }, ContentFrame)
		addOutlineStroke(TabsBar,2)

		local TabButtonHolder = makeFrame({ Name="TabButtonHolder", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0) }, TabsBar)
		makeInstance("UIListLayout", { FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2) }, TabButtonHolder)
		makeInstance("UIPadding",    { PaddingLeft=UDim.new(0,1), PaddingRight=UDim.new(0,1) }, TabButtonHolder)

		-- ── Keybind Overlay ───────────────────────────────────────────────────
		local KeybindFrame = mainFrame({
			Name="KeybindFrame", BackgroundColor3=Theme.BackgroundColor,
			Size=UDim2.new(0,150,0,100), Position=UDim2.new(0,5,0,600), Visible=false,
		}, overlayGui)
		addTrackedStroke(KeybindFrame, Theme.MainColor, 2)

		local KeybindContent = bg2Frame({
			Name="Content", BackgroundColor3=Theme.BackgroundColor2,
			Size=UDim2.new(0,140,0,90), Position=UDim2.new(0,5,0,5),
		}, KeybindFrame)
		addOutlineStroke(KeybindContent)
		makeInstance("UIListLayout", { HorizontalFlex=Enum.UIFlexAlignment.SpaceAround, SortOrder=Enum.SortOrder.LayoutOrder }, KeybindContent)
		makeInstance("UIPadding",    { PaddingBottom=UDim.new(0,5) }, KeybindContent)

		local KBTitleFrame = makeFrame({ Name="TitleRow", BackgroundTransparency=1, Size=UDim2.new(0,130,0,15) }, KeybindContent)
		makeLabel({ BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text="Keybinds", TextSize=12, TextColor3=Color3.fromRGB(255,255,255), FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json") }, KBTitleFrame)

		local kbVisible=false
		function Window:KeybindToggle(state) kbVisible=toggleState(kbVisible,state); KeybindFrame.Visible=kbVisible end

		function Window:AddKeybind(title, key)
			if self.KeybindLabels[title] then
				local e=self.KeybindLabels[title]
				e.KeyLabel.Text=key; e.KeyLabel.TextColor3=(key=="None") and C_TEXT_DIM or Color3.fromRGB(255,255,255)
				return
			end
			local row=makeFrame({ Name="KB_"..title, BackgroundTransparency=1, Size=UDim2.new(0,130,0,15) }, KeybindContent)
			makeLabel({ BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text=title, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Color3.fromRGB(255,255,255), FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json") }, row)
			local rk=makeLabel({ BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text=key, TextSize=12, TextXAlignment=Enum.TextXAlignment.Right, TextColor3=(key=="None") and C_TEXT_DIM or Color3.fromRGB(255,255,255), FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json") }, row)
			self.KeybindLabels[title]={ Frame=row, KeyLabel=rk }
		end

		function Window:SetKeybindActive(title, active)
			local e=self.KeybindLabels[title]
			if not e then return end
			tween(e.KeyLabel,{ TextColor3=active and Theme.MainColor or Color3.fromRGB(255,255,255) })
		end

		-- ── Watermark Overlay ─────────────────────────────────────────────────
		local WatermarkFrame = mainFrame({
			Name="WatermarkFrame", BackgroundColor3=Theme.BackgroundColor,
			Size=UDim2.new(0,400,0,30), Position=UDim2.new(0,5,0,60), Visible=false,
		}, overlayGui)
		addTrackedStroke(WatermarkFrame, Theme.MainColor, 2)

		local WatermarkContent = bg2Frame({
			Name="Content", BackgroundColor3=Theme.BackgroundColor2,
			Size=UDim2.new(0,390,0,20), Position=UDim2.new(0,5,0,5),
		}, WatermarkFrame)
		addOutlineStroke(WatermarkContent)

		function Window:AddWatermark(text, alignment)
			for _,c in ipairs(WatermarkContent:GetChildren()) do
				if c:IsA("TextLabel") then c:Destroy() end
			end
			makeLabel({ BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text=text, TextSize=13, TextColor3=Color3.fromRGB(255,255,255), TextXAlignment=normalizeAlign(alignment), FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json") }, WatermarkContent)
		end

		local wmVisible=false
		function Window:Watermark(state) wmVisible=toggleState(wmVisible,state); WatermarkFrame.Visible=wmVisible end

		makeDraggable(TitleLabel,     MainFrame)
		makeDraggable(KeybindFrame,   KeybindFrame)
		makeDraggable(WatermarkFrame, WatermarkFrame)

		-- ═════════════════════════════════════════════════════════════════════
		-- Tab Constructor
		-- ═════════════════════════════════════════════════════════════════════
		function Window:AddTab(tabOpts)
			tabOpts=tabOpts or {}
			validate({ Title="Tab", Icon="rbxassetid://70562308088944" }, tabOpts)

			local Tab={ Hover=false, Active=false }

			local TabButton=makeLabel({
				Name=tabOpts.Title, BackgroundColor3=Theme.MainColor, BackgroundTransparency=1,
				TextSize=14, TextColor3=C_TEXT_DIM, FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json"),
				Text=tabOpts.Title, Size=UDim2.new(0,100,1,0),
			}, TabButtonHolder)
			track(T.tabButtons, TabButton)
			makeInstance("UIPadding",{ PaddingLeft=UDim.new(0,26) }, TabButton)

			local TabIcon=makeInstance("ImageLabel",{
				BackgroundTransparency=1, Image=tabOpts.Icon, ImageColor3=C_TEXT_DIM,
				Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,-10,0.25,0), BorderSizePixel=0,
			}, TabButton)

			local ElementsContainer=mainFrame({
				Name=tabOpts.Title.."_Container", BackgroundColor3=Theme.BackgroundColor,
				Size=UDim2.new(1,-10,0,WIN_H-90), Position=UDim2.new(0,5,0,50), Visible=false,
			}, ContentFrame)
			addOutlineStroke(ElementsContainer,2)
			Tab.ElementsContainer=ElementsContainer

			function Tab:Activate()
				if self.Active then return end
				if Window.CurrentTab then Window.CurrentTab:Deactivate() end
				self.Active=true
				tween(TabButton,{ TextColor3=C_TEXT_HOVER, BackgroundTransparency=0, BackgroundColor3=Theme.MainColor })
				tween(TabIcon,  { ImageColor3=C_TEXT_HOVER })
				ElementsContainer.Visible=true; Window.CurrentTab=self
			end

			function Tab:Deactivate()
				if not self.Active then return end
				self.Active=false; self.Hover=false
				tween(TabButton,{ TextColor3=C_TEXT_DIM, BackgroundTransparency=1 })
				tween(TabIcon,  { ImageColor3=C_TEXT_DIM })
				ElementsContainer.Visible=false
			end

			TabButton.MouseEnter:Connect(function() Tab.Hover=true;  if not Tab.Active then tween(TabButton,{TextColor3=C_TEXT_HOVER}); tween(TabIcon,{ImageColor3=C_TEXT_HOVER}) end end)
			TabButton.MouseLeave:Connect(function() Tab.Hover=false; if not Tab.Active then tween(TabButton,{TextColor3=C_TEXT_DIM });  tween(TabIcon,{ImageColor3=C_TEXT_DIM }) end end)

			UIS.InputBegan:Connect(function(input,gpe)
				if gpe then return end
				if input.UserInputType==MB1 and Tab.Hover then Tab:Activate() end
			end)

			if Window.CurrentTab==nil then Tab:Activate() end
			table.insert(Window.Tabs, Tab)

			-- ═══════════════════════════════════════════════════════════════════
			-- Section Constructor
			-- ═══════════════════════════════════════════════════════════════════
			function Tab:AddSection(secOpts)
				secOpts=secOpts or {}
				secOpts.Type  = secOpts.Type  or "Left"
				secOpts.Title = secOpts.Title or (secOpts.Type.." Section")

				local colXMap = { Left=5, Center=231, Right=457 }
				local colKey  = secOpts.Type.."Column"

				if not Tab[colKey] then
					local col=makeFrame({ Name=colKey, BackgroundTransparency=1, Size=UDim2.new(0,218,1,-10), Position=UDim2.new(0,colXMap[secOpts.Type] or 5,0,5) }, ElementsContainer)
					makeInstance("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,7) }, col)
					Tab[colKey]=col
				end

				local SectionFrame=bg2Frame({ Name=secOpts.Title, BackgroundColor3=Theme.BackgroundColor2, Size=UDim2.new(0,218,0,40) }, Tab[colKey])
				addOutlineStroke(SectionFrame,2)

				local GradFade=makeFrame({ Name="Fade", BackgroundColor3=Color3.fromRGB(255,255,255), Size=UDim2.new(1,0,0,20), ZIndex=1 }, SectionFrame)
				local GradGrad=makeInstance("UIGradient",{
					Rotation=90,
					Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,0.5)},
					Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Theme.MainColor),ColorSequenceKeypoint.new(1,Theme.BackgroundColor2)},
				}, GradFade)
				track(T.gradients, GradGrad)

				makeLabel({ Name="Title", BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.new(1,0,0,15), Position=UDim2.new(0,0,0,5), Text=secOpts.Title, TextSize=14, TextColor3=Color3.fromRGB(255,255,255), FontFace=Font.new("rbxasset://fonts/families/Ubuntu.json"), ZIndex=3 }, SectionFrame)

				local ElemHolder=makeFrame({ Name="ElementsHolder", BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.new(0,0,0,30), Size=UDim2.new(0,218,0,0) }, SectionFrame)
				local ElemLayout=makeInstance("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4) }, ElemHolder)
				makeInstance("UIPadding",{ PaddingLeft=UDim.new(0,5) }, ElemHolder)

				ElemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					SectionFrame.Size=UDim2.new(0,218,0,ElemLayout.AbsoluteContentSize.Y+40)
				end)

				local Section={ Frame=SectionFrame, ElementsHolder=ElemHolder }

				local function hoverText(lbl)
					lbl.MouseEnter:Connect(function() tween(lbl,{TextColor3=C_TEXT_HOVER}) end)
					lbl.MouseLeave:Connect(function() tween(lbl,{TextColor3=C_TEXT_NORMAL}) end)
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddButton
				-- ─────────────────────────────────────────────────────────────
				function Section:AddButton(cfg)
					cfg=cfg or {}; cfg.Title=cfg.Title or "Button"; cfg.Callback=cfg.Callback or function() end
					local btn=makeInstance("TextLabel",{
						Name=cfg.Title, BackgroundColor3=C_ELEM_BG, BorderSizePixel=0,
						Size=UDim2.new(0,208,0,20), Text=cfg.Title, TextSize=14, TextColor3=C_TEXT_NORMAL,
						Font=Enum.Font.Gotham, BackgroundTransparency=0, ClipsDescendants=true,
					}, self.ElementsHolder)
					addOutlineStroke(btn)
					hoverText(btn)
					btn.InputBegan:Connect(function(i)
						if i.UserInputType~=MB1 then return end
						tween(btn,{BackgroundColor3=Theme.MainColor},function() tween(btn,{BackgroundColor3=C_ELEM_BG}) end)
						cfg.Callback()
					end)
					return btn
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddToggle
				-- ─────────────────────────────────────────────────────────────
				function Section:AddToggle(cfg)
					cfg=cfg or {}
					validate({ Title="Toggle", Default=false, Callback=function()end, KeybindEnabled=false, KeyBind="None", Mode="Toggle", Sync=false, KeyCallback=function()end, Save=false }, cfg)

					local ToggleFrame=makeFrame({ Name=cfg.Title, BackgroundTransparency=1, Size=UDim2.new(0,208,0,20) }, self.ElementsHolder)
					local Check=makeFrame({ Name="Check", BackgroundColor3=C_ELEM_BG, Size=UDim2.new(0,15,0,15), Position=UDim2.new(0,0,0,3) }, ToggleFrame)
					Instance.new("UICorner",Check).CornerRadius=UDim.new(0,2)
					addOutlineStroke(Check)

					local TitleLbl=makeLabel({ Name="Title", BackgroundTransparency=1, Size=UDim2.new(0,150,1,0), Position=UDim2.new(0,23,0,0), Text=cfg.Title, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, ToggleFrame)

					local toggled=cfg.Default; local currentKey=cfg.KeyBind; local keyState=toggled

					local function syncCheck(animated)
						if toggled then
							if not table.find(T.activeChecks,Check) then table.insert(T.activeChecks,Check) end
						else
							local i=table.find(T.activeChecks,Check); if i then table.remove(T.activeChecks,i) end
						end
						local col=toggled and Theme.MainColor or C_ELEM_BG
						if animated then tween(Check,{BackgroundColor3=col}) else Check.BackgroundColor3=col end
					end
					syncCheck(false)

					local KeyLabel
					if cfg.KeybindEnabled then
						KeyLabel=makeLabel({ BackgroundTransparency=1, Size=UDim2.new(0,30,0,15), Position=UDim2.new(0,177,0,0), Text=currentKey, TextSize=12, TextXAlignment=Enum.TextXAlignment.Center, TextColor3=toggled and Theme.MainColor or C_TEXT_DIM, Font=Enum.Font.GothamBold }, ToggleFrame)
						Window:AddKeybind(cfg.Title, currentKey)
					end

					local function setKeyColor(state)
						if KeyLabel then tween(KeyLabel,{TextColor3=state and Theme.MainColor or C_TEXT_DIM}) end
						if cfg.KeybindEnabled then Window:SetKeybindActive(cfg.Title,state) end
					end

					local function doToggle()
						toggled=not toggled; syncCheck(true); cfg.Callback(toggled)
						if cfg.Sync then keyState=toggled; setKeyColor(toggled); cfg.KeyCallback("Sync",{Key=currentKey,Mode=cfg.Mode,State=toggled}) end
					end

					hoverText(TitleLbl)
					TitleLbl.InputBegan:Connect(function(i) if i.UserInputType==MB1 then doToggle() end end)
					Check.InputBegan:Connect(function(i) if i.UserInputType==MB1 then doToggle() end end)

					if cfg.KeybindEnabled then
						local kbHover=false; local listening=false
						KeyLabel.MouseEnter:Connect(function() kbHover=true  end)
						KeyLabel.MouseLeave:Connect(function() kbHover=false end)

						UIS.InputBegan:Connect(function(input,gp)
							if gp then return end
							if kbHover and not listening and input.UserInputType==MB1 then
								listening=true
								startListening(KeyLabel,function(name)
									listening=false; currentKey=name; Window:AddKeybind(cfg.Title,name)
									cfg.KeyCallback("Changed",{Key=name,Mode=cfg.Mode})
								end)
								return
							end
							if not keyMatchesInput(input,currentKey) then return end
							if cfg.Mode=="Toggle" then
								if cfg.Sync then toggled=not toggled; syncCheck(true); keyState=toggled; setKeyColor(toggled); cfg.Callback(toggled); cfg.KeyCallback("Pressed",{Key=currentKey,Mode=cfg.Mode,State=toggled})
								else keyState=not keyState; setKeyColor(keyState); cfg.KeyCallback("Pressed",{Key=currentKey,Mode=cfg.Mode,State=keyState}) end
							elseif cfg.Mode=="Hold" then
								setKeyColor(true); cfg.KeyCallback("Pressed",{Key=currentKey,Mode=cfg.Mode,State=true})
							end
						end)
						UIS.InputEnded:Connect(function(input,gp)
							if gp or cfg.Mode~="Hold" then return end
							if keyMatchesInput(input,currentKey) then setKeyColor(false); cfg.KeyCallback("Pressed",{Key=currentKey,Mode=cfg.Mode,State=false}) end
						end)
					end

					local api = {
						Frame=ToggleFrame, Check=Check, KeyLabel=KeyLabel,
						GetState=function() return toggled end,
						SetState=function(v) if toggled~=v then doToggle() end end,
						GetKey  =function() return currentKey end,
						SetKey  =function(v)
							if v~=currentKey then currentKey=v; if KeyLabel then KeyLabel.Text=v end; Window:AddKeybind(cfg.Title,v); cfg.KeyCallback("Changed",{Key=v,Mode=cfg.Mode}) end
						end,
					}
					if cfg.Save then
						registerSaveable("toggle_"..cfg.Title, function() return toggled end, function(v) if toggled~=v then doToggle() end end)
					end
					return api
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddDropdown
				-- ─────────────────────────────────────────────────────────────
				function Section:AddDropdown(cfg)
					cfg=cfg or {}
					validate({ Title="Dropdown", Options={}, Multi=false, Callback=function()end, Save=false }, cfg)
					cfg.Placeholder=cfg.Placeholder or cfg.Title
					cfg.Default=(cfg.Multi and type(cfg.Default)=="table") and cfg.Default or (cfg.Default or {})

					local DropFrame=makeFrame({ Name=cfg.Title, BackgroundColor3=C_ELEM_BG, Size=UDim2.new(0,208,0,20), ZIndex=10 }, self.ElementsHolder)
					addOutlineStroke(DropFrame)

					local DropTitle=makeLabel({ Name="Title", BackgroundTransparency=1, Size=UDim2.new(0,150,1,0), Position=UDim2.new(0,5,0,0), TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, DropFrame)
					DropTitle.Text=cfg.Multi and ((#cfg.Default>0) and table.concat(cfg.Default,", ") or cfg.Placeholder) or ((#cfg.Default>0) and cfg.Default[1] or cfg.Placeholder)

					local Indicator=makeLabel({ Name="Indicator", BackgroundTransparency=1, Text="▼", TextSize=14, TextXAlignment=Enum.TextXAlignment.Right, Size=UDim2.new(0,15,1,0), Position=UDim2.new(1,-20,0,-2), TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, DropFrame)

					local listHeight=math.min(#cfg.Options*20,160)
					local ListFrame=makeFrame({ Name="List_"..cfg.Title, BackgroundColor3=C_ELEM_BG, Size=UDim2.new(0,208,0,listHeight), Visible=false, ZIndex=200, ClipsDescendants=true }, PopupOverlay)
					addOutlineStroke(ListFrame)

					local ListScroll=makeInstance("ScrollingFrame",{
						Name="Scroll", BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.new(1,0,1,0),
						CanvasSize=UDim2.new(0,0,0,#cfg.Options*20),
						ScrollBarThickness=(#cfg.Options*20>listHeight) and 4 or 0,
						ScrollBarImageColor3=Theme.MainColor, ZIndex=200,
					}, ListFrame)
					track(T.scrolls, ListScroll)
					makeInstance("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0) }, ListScroll)

					local expanded=false
					local selected=cfg.Multi and cfg.Default or (cfg.Default[1] or nil)
					local optButtons={}
					local optClickConsumed=false

					local function repositionList()
						local ap=DropFrame.AbsolutePosition; local as=DropFrame.AbsoluteSize; local mp=mainGui.AbsolutePosition
						ListFrame.Position=UDim2.new(0,ap.X-mp.X,0,ap.Y-mp.Y+as.Y+2)
					end

					local function setExpanded(state)
						if state then closeActivePopup(); repositionList(); ListFrame.Visible=true; activePopup=ListFrame
						else ListFrame.Visible=false; if activePopup==ListFrame then activePopup=nil end end
						expanded=state; Indicator.Text=state and "▲" or "▼"
						tween(DropFrame,{BackgroundColor3=state and Theme.MainColor or C_ELEM_BG})
					end

					DropFrame.MouseEnter:Connect(function() tween(DropTitle,{TextColor3=C_TEXT_HOVER}); tween(Indicator,{TextColor3=C_TEXT_HOVER}) end)
					DropFrame.MouseLeave:Connect(function() tween(DropTitle,{TextColor3=C_TEXT_NORMAL}); tween(Indicator,{TextColor3=C_TEXT_NORMAL}) end)
					DropFrame.InputBegan:Connect(function(i) if i.UserInputType==MB1 then setExpanded(not expanded) end end)

					UIS.InputBegan:Connect(function(input)
						if not expanded then return end
						if input.UserInputType~=MB1 then return end
						if optClickConsumed then optClickConsumed=false; return end
						local mp=UIS:GetMouseLocation()
						local lp,ls=ListFrame.AbsolutePosition,ListFrame.AbsoluteSize
						local dp,ds=DropFrame.AbsolutePosition,DropFrame.AbsoluteSize
						local inList=mp.X>=lp.X and mp.X<=lp.X+ls.X and mp.Y>=lp.Y and mp.Y<=lp.Y+ls.Y
						local inDrop=mp.X>=dp.X and mp.X<=dp.X+ds.X and mp.Y>=dp.Y and mp.Y<=dp.Y+ds.Y
						if not inList and not inDrop then setExpanded(false) end
					end)

					local function buildOptions(options)
						-- Remember whether the list was open so we can reopen it after rebuild
						local wasExpanded = expanded
					
						-- Close silently: hide the frame but do NOT touch activePopup or expanded,
						-- because setExpanded(false) would clear activePopup and the next MB1
						-- outside-click handler would permanently seal the list shut.
						ListFrame.Visible = false
					
						-- Destroy old option rows
						for _, child in ipairs(ListScroll:GetChildren()) do
							if not child:IsA("UIListLayout") then child:Destroy() end
						end
						for _, ob in ipairs(optButtons) do
							local ti = table.find(T.activeOptLabels, ob.Label)
							if ti then table.remove(T.activeOptLabels, ti) end
						end
						optButtons = {}
					
						-- Resize to new option count
						local newH = math.min(#options * 20, 160)
						ListFrame.Size               = UDim2.new(0, 208, 0, newH)
						ListScroll.CanvasSize        = UDim2.new(0, 0, 0, #options * 20)
						ListScroll.ScrollBarThickness = (#options * 20 > newH) and 4 or 0
					
						for _, optName in ipairs(options) do
							local wrapper = makeInstance("TextButton", {
								Name                = optName,
								BackgroundTransparency = 1,
								AutoButtonColor     = false,
								Size                = UDim2.new(1, 0, 0, 20),
								ZIndex              = 200,
								Text                = "",
							}, ListScroll)
							local optLbl = makeLabel({
								Name               = "Label",
								BackgroundColor3   = C_ELEM_BG,
								BackgroundTransparency = 0,
								Size               = UDim2.new(1, 0, 1, 0),
								Text               = optName,
								TextSize           = 14,
								TextColor3         = C_TEXT_NORMAL,
								TextXAlignment     = Enum.TextXAlignment.Left,
								Font               = Enum.Font.Gotham,
								ZIndex             = 200,
							}, wrapper)
							addOutlineStroke(optLbl)
							makeInstance("UIPadding", { PaddingLeft = UDim.new(0, 5) }, optLbl)
					
							wrapper.MouseEnter:Connect(function() tween(optLbl, { TextColor3 = C_TEXT_HOVER  }) end)
							wrapper.MouseLeave:Connect(function() tween(optLbl, { TextColor3 = C_TEXT_NORMAL }) end)
							wrapper.InputBegan:Connect(function(i)
								if i.UserInputType == MB1 then optClickConsumed = true end
							end)
					
							wrapper.MouseButton1Click:Connect(function()
								if cfg.Multi then
									local idx = table.find(selected, optName)
									if idx then
										table.remove(selected, idx)
										local ti = table.find(T.activeOptLabels, optLbl)
										if ti then table.remove(T.activeOptLabels, ti) end
										tween(optLbl, { BackgroundColor3 = C_ELEM_BG })
									else
										table.insert(selected, optName)
										if not table.find(T.activeOptLabels, optLbl) then
											table.insert(T.activeOptLabels, optLbl)
										end
										tween(optLbl, { BackgroundColor3 = Theme.MainColor })
									end
									DropTitle.Text = (#selected > 0) and table.concat(selected, ", ") or cfg.Placeholder
									cfg.Callback(selected)
								else
									selected      = optName
									DropTitle.Text = optName
									cfg.Callback(optName)
									tween(optLbl, { BackgroundColor3 = Theme.MainColor }, function()
										tween(optLbl, { BackgroundColor3 = C_ELEM_BG })
									end)
									setExpanded(false)
								end
							end)
					
							table.insert(optButtons, { Name = optName, Label = optLbl })
						end
					
						-- Restore multi-select highlights
						if cfg.Multi then
							for _, ob in ipairs(optButtons) do
								if table.find(selected, ob.Name) then
									ob.Label.BackgroundColor3 = Theme.MainColor
									if not table.find(T.activeOptLabels, ob.Label) then
										table.insert(T.activeOptLabels, ob.Label)
									end
								end
							end
						end
					
						-- If the list was open before the rebuild (e.g. Refresh called while
						-- user had it open), reopen it properly so it stays visible.
						if wasExpanded then
							expanded = false          -- setExpanded checks this to avoid no-op
							setExpanded(true)
						else
							expanded = false          -- make sure state is consistent
						end
					end

					buildOptions(cfg.Options)

					local dropApi = {
						Frame=DropFrame,
						GetValue=function() return selected end,
						SetValue=function(val)
							if cfg.Multi then
								for _,ob in ipairs(optButtons) do
									ob.Label.BackgroundColor3=C_ELEM_BG
									local ti=table.find(T.activeOptLabels,ob.Label); if ti then table.remove(T.activeOptLabels,ti) end
								end
								selected={}
								for _,v in ipairs(val) do
									for _,ob in ipairs(optButtons) do
										if ob.Name==v then
											table.insert(selected,v); ob.Label.BackgroundColor3=Theme.MainColor
											if not table.find(T.activeOptLabels,ob.Label) then table.insert(T.activeOptLabels,ob.Label) end
											break
										end
									end
								end
								DropTitle.Text=(#selected>0) and table.concat(selected,", ") or cfg.Placeholder
								cfg.Callback(selected)
							else
								for _,ob in ipairs(optButtons) do
									if ob.Name==val then selected=val; DropTitle.Text=val; cfg.Callback(val); break end
								end
							end
						end,
						Refresh=function(newOptions, newSelected)
							selected = cfg.Multi and (newSelected or {}) or (newSelected or nil)
							DropTitle.Text = cfg.Multi
								and ((selected and #selected>0) and table.concat(selected,", ") or cfg.Placeholder)
								or  (selected or cfg.Placeholder)
							buildOptions(newOptions)
						end,
					}
					if cfg.Save then
						registerSaveable("dropdown_"..cfg.Title, function() return selected end, function(v) dropApi.SetValue(v) end)
					end
					return dropApi
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddSlider
				-- ─────────────────────────────────────────────────────────────
				function Section:AddSlider(cfg)
					cfg=cfg or {}
					validate({ Title="Slider", Min=0, Max=100, Rounding=0, Suffix="", Callback=function()end, Save=false }, cfg)
					cfg.Default=cfg.Default~=nil and cfg.Default or cfg.Min

					local SliderFrame=makeFrame({ Name=cfg.Title, BackgroundTransparency=1, Size=UDim2.new(0,208,0,40) }, self.ElementsHolder)
					local TitleLbl=makeLabel({ Name="Title", BackgroundTransparency=1, Size=UDim2.new(0,155,0,15), Text=cfg.Title, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, SliderFrame)
					local ValueLbl=makeLabel({ Name="Value", BackgroundTransparency=1, Size=UDim2.new(0,50,0,15), Position=UDim2.new(0,158,0,0), TextSize=14, TextXAlignment=Enum.TextXAlignment.Right, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, SliderFrame)
					local Track=makeFrame({ Name="Track", BackgroundColor3=C_ELEM_BG, Size=UDim2.new(1,0,0,15), Position=UDim2.new(0,0,0,20) }, SliderFrame)
					addOutlineStroke(Track)
					local Fill=makeFrame({ Name="Fill", BackgroundColor3=Theme.MainColor }, Track)
					track(T.fills, Fill)

					local function roundVal(v) return cfg.Rounding>0 and math.floor(v/cfg.Rounding+.5)*cfg.Rounding or v end
					local currentValue=cfg.Default

					local function applyValue(mouseX)
						local rel=math.clamp(mouseX-Track.AbsolutePosition.X,0,Track.AbsoluteSize.X)
						local pct=(Track.AbsoluteSize.X>0) and (rel/Track.AbsoluteSize.X) or 0
						currentValue=roundVal(cfg.Min+(cfg.Max-cfg.Min)*pct)
						Fill:TweenSize(UDim2.new(pct,0,1,0),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,0.03,true)
						ValueLbl.Text=tostring(math.floor(currentValue))..cfg.Suffix
						cfg.Callback(currentValue)
					end

					local initPct=(cfg.Max~=cfg.Min) and ((cfg.Default-cfg.Min)/(cfg.Max-cfg.Min)) or 0
					Fill.Size=UDim2.new(initPct,0,1,0); ValueLbl.Text=tostring(cfg.Default)..cfg.Suffix

					local dragging=false
					local function startDrag(i) if i.UserInputType==MB1 then dragging=true; applyValue(i.Position.X) end end
					Track.InputBegan:Connect(startDrag); Fill.InputBegan:Connect(startDrag)
					UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==MOUSE_MOVE then applyValue(i.Position.X) end end)
					UIS.InputEnded:Connect(function(i) if i.UserInputType==MB1 then dragging=false end end)

					SliderFrame.MouseEnter:Connect(function() tween(TitleLbl,{TextColor3=C_TEXT_HOVER}); tween(ValueLbl,{TextColor3=C_TEXT_HOVER}) end)
					SliderFrame.MouseLeave:Connect(function() tween(TitleLbl,{TextColor3=C_TEXT_NORMAL}); tween(ValueLbl,{TextColor3=C_TEXT_NORMAL}) end)

					local sliderApi = {
						Frame=SliderFrame, Fill=Fill,
						GetValue=function() return currentValue end,
						SetValue=function(v)
							v=math.clamp(v,cfg.Min,cfg.Max)
							local pct=(cfg.Max~=cfg.Min) and ((v-cfg.Min)/(cfg.Max-cfg.Min)) or 0
							currentValue=roundVal(v); Fill.Size=UDim2.new(pct,0,1,0)
							ValueLbl.Text=tostring(math.floor(currentValue))..cfg.Suffix; cfg.Callback(currentValue)
						end,
					}
					if cfg.Save then
						registerSaveable("slider_"..cfg.Title, function() return currentValue end, function(v) sliderApi.SetValue(v) end)
					end
					return sliderApi
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddLabel
				-- ─────────────────────────────────────────────────────────────
				function Section:AddLabel(cfg)
					cfg=cfg or {}; cfg.Title=cfg.Title or "Label"; cfg.TextAlignment=cfg.TextAlignment or "Left"
					local LabelFrame=makeFrame({ Name="Label_"..cfg.Title, BackgroundTransparency=1, Size=UDim2.new(0,208,0,15) }, self.ElementsHolder)
					local Lbl=makeLabel({ Name="Title", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text=cfg.Title, TextSize=14, TextXAlignment=normalizeAlign(cfg.TextAlignment), TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, LabelFrame)
					return { Frame=LabelFrame, Label=Lbl }
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddColorPicker
				-- ─────────────────────────────────────────────────────────────
				function Section:AddColorPicker(cfg)
					cfg=cfg or {}
					validate({ Title="Color", Default=Color3.fromRGB(255,255,255), Callback=function()end, Save=false }, cfg)

					local RowFrame=makeFrame({ Name="ColorPicker_"..cfg.Title, BackgroundTransparency=1, ZIndex=10, Size=UDim2.new(0,208,0,15) }, self.ElementsHolder)
					local RowTitle=makeLabel({ Name="Title", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Text=cfg.Title..":", TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, RowFrame)
					local Swatch=makeFrame({ Name="Swatch", BackgroundColor3=cfg.Default, Size=UDim2.new(0,30,0,15), Position=UDim2.new(0,177,0,0), ZIndex=10 }, RowFrame)
					addOutlineStroke(Swatch)

					local PW,PH,SVW,SVH,HW,PAD=166,148,138,114,12,5

					local PickerPanel=makeFrame({ Name="PickerPanel_"..cfg.Title, BackgroundColor3=Color3.fromRGB(18,18,18), Size=UDim2.new(0,PW,0,PH), Visible=false, ZIndex=200 }, PopupOverlay)
					addTrackedStroke(PickerPanel, Theme.MainColor, 1)

					local SVBox=makeFrame({ Name="SVBox", BackgroundColor3=Color3.fromRGB(255,0,0), Size=UDim2.new(0,SVW,0,SVH), Position=UDim2.new(0,PAD,0,PAD), ZIndex=201, ClipsDescendants=false }, PickerPanel)
					addOutlineStroke(SVBox)

					local WhiteOverlay=makeFrame({ Name="WhiteOverlay", BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(1,0,1,0), ZIndex=202 }, SVBox)
					makeInstance("UIGradient",{ Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1)), Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}, Rotation=0 }, WhiteOverlay)

					local BlackOverlay=makeFrame({ Name="BlackOverlay", BackgroundColor3=Color3.new(0,0,0), Size=UDim2.new(1,0,1,0), ZIndex=203 }, SVBox)
					makeInstance("UIGradient",{ Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(0,0,0)), Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}, Rotation=90 }, BlackOverlay)

					local SVCursor=makeFrame({ Name="SVCursor", BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(0,8,0,8), ZIndex=205 }, PickerPanel)
					Instance.new("UICorner",SVCursor).CornerRadius=UDim.new(1,0)
					addStroke(SVCursor,Color3.new(0,0,0),1)

					local HueBar=makeFrame({ Name="HueBar", BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(0,HW,0,SVH), Position=UDim2.new(0,PAD+SVW+PAD,0,PAD), ZIndex=201 }, PickerPanel)
					addOutlineStroke(HueBar)
					makeInstance("UIGradient",{ Rotation=90, Color=ColorSequence.new{
						ColorSequenceKeypoint.new(0.000,Color3.fromRGB(255,0,0)),
						ColorSequenceKeypoint.new(0.166,Color3.fromRGB(255,255,0)),
						ColorSequenceKeypoint.new(0.333,Color3.fromRGB(0,255,0)),
						ColorSequenceKeypoint.new(0.500,Color3.fromRGB(0,255,255)),
						ColorSequenceKeypoint.new(0.666,Color3.fromRGB(0,0,255)),
						ColorSequenceKeypoint.new(0.833,Color3.fromRGB(255,0,255)),
						ColorSequenceKeypoint.new(1.000,Color3.fromRGB(255,0,0)),
					}}, HueBar)

					local HueCursor=makeFrame({ Name="HueCursor", BackgroundColor3=Color3.new(1,1,1), Size=UDim2.new(0,HW+4,0,3), ZIndex=205 }, PickerPanel)
					addStroke(HueCursor,Color3.new(0,0,0),1)

					local HexRow=makeFrame({ Name="HexRow", BackgroundColor3=C_ELEM_BG, Size=UDim2.new(0,PW-PAD*2,0,20), Position=UDim2.new(0,PAD,0,PAD+SVH+PAD), ZIndex=201 }, PickerPanel)
					addOutlineStroke(HexRow)
					makeLabel({ BackgroundTransparency=1, Size=UDim2.new(0,14,1,0), Position=UDim2.new(0,4,0,0), Text="#", TextSize=13, TextColor3=C_TEXT_DIM, Font=Enum.Font.GothamBold, ZIndex=202 }, HexRow)
					local HexInput=makeInstance("TextBox",{ Name="HexInput", BackgroundTransparency=1, Size=UDim2.new(1,-18,1,0), Position=UDim2.new(0,18,0,0), Text="", PlaceholderText="RRGGBB", PlaceholderColor3=C_TEXT_DIM, TextSize=13, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, ZIndex=202 }, HexRow)

					local hue,sat,val_=0,1,1; local selColor=cfg.Default

					local function updateUI(skipHex)
						SVBox.BackgroundColor3=Color3.fromHSV(hue,1,1)
						selColor=Color3.fromHSV(hue,sat,val_)
						SVCursor.Position=UDim2.new(0,PAD+sat*SVW-4,0,PAD+(1-val_)*SVH-4)
						HueCursor.Position=UDim2.new(0,PAD+SVW+PAD-2,0,PAD+hue*SVH-1)
						Swatch.BackgroundColor3=selColor
						if not skipHex then HexInput.Text=colorToHex(selColor) end
						cfg.Callback(selColor)
					end

					local function initFromColor(c)
						local h,s,v=Color3.toHSV(c); hue=h; sat=s; val_=v; updateUI(false)
					end

					local dragSV,dragHue=false,false

					local function applySV(mp)
						local ap,as=SVBox.AbsolutePosition,SVBox.AbsoluteSize
						sat=math.clamp((mp.X-ap.X)/as.X,0,1); val_=1-math.clamp((mp.Y-ap.Y)/as.Y,0,1); updateUI(false)
					end
					local function applyHue(mp)
						local ap,as=HueBar.AbsolutePosition,HueBar.AbsoluteSize
						hue=math.clamp((mp.Y-ap.Y)/as.Y,0,1); updateUI(false)
					end

					local function svBegin(i) if i.UserInputType==MB1 then dragSV=true; applySV(i.Position) end end
					local function svEnd(i)   if i.UserInputType==MB1 then dragSV=false end end
					BlackOverlay.InputBegan:Connect(svBegin); BlackOverlay.InputEnded:Connect(svEnd)
					SVBox.InputBegan:Connect(svBegin); SVBox.InputEnded:Connect(svEnd)
					HueBar.InputBegan:Connect(function(i) if i.UserInputType==MB1 then dragHue=true; applyHue(i.Position) end end)
					HueBar.InputEnded:Connect(function(i) if i.UserInputType==MB1 then dragHue=false end end)

					UIS.InputChanged:Connect(function(i)
						if i.UserInputType~=MOUSE_MOVE then return end
						if dragSV then applySV(i.Position) end
						if dragHue then applyHue(i.Position) end
					end)
					UIS.InputEnded:Connect(function(i)
						if i.UserInputType==MB1 then dragSV=false; dragHue=false end
					end)

					HexInput.FocusLost:Connect(function()
						local c=hexToColor(HexInput.Text)
						if c then initFromColor(c) else HexInput.Text=colorToHex(selColor) end
					end)

					local function repositionPanel()
						local ap,as=Swatch.AbsolutePosition,Swatch.AbsoluteSize; local mp=mainGui.AbsolutePosition
						local px=ap.X-mp.X-PW+as.X; local py=ap.Y-mp.Y+as.Y+4
						if px<0 then px=0 end
						if py+PH>mainGui.AbsoluteSize.Y then py=ap.Y-mp.Y-PH-4 end
						PickerPanel.Position=UDim2.new(0,px,0,py)
					end

					Swatch.InputBegan:Connect(function(i)
						if i.UserInputType~=MB1 then return end
						if PickerPanel.Visible then PickerPanel.Visible=false; if activePopup==PickerPanel then activePopup=nil end
						else closeActivePopup(); repositionPanel(); PickerPanel.Visible=true; activePopup=PickerPanel end
					end)

					UIS.InputBegan:Connect(function(input)
						if not PickerPanel.Visible then return end
						if input.UserInputType~=MB1 then return end
						if HexInput:IsFocused() then return end
						local mp=UIS:GetMouseLocation()
						local pp,ps=PickerPanel.AbsolutePosition,PickerPanel.AbsoluteSize
						local sp,ss=Swatch.AbsolutePosition,Swatch.AbsoluteSize
						local inPanel=mp.X>=pp.X and mp.X<=pp.X+ps.X and mp.Y>=pp.Y and mp.Y<=pp.Y+ps.Y
						local inSwatch=mp.X>=sp.X and mp.X<=sp.X+ss.X and mp.Y>=sp.Y and mp.Y<=sp.Y+ss.Y
						if not inPanel and not inSwatch then PickerPanel.Visible=false; if activePopup==PickerPanel then activePopup=nil end end
					end)

					RowFrame.MouseEnter:Connect(function() tween(RowTitle,{TextColor3=C_TEXT_HOVER}) end)
					RowFrame.MouseLeave:Connect(function() tween(RowTitle,{TextColor3=C_TEXT_NORMAL}) end)
					initFromColor(cfg.Default)

					local cpApi = { Frame=RowFrame, Swatch=Swatch, Panel=PickerPanel, GetColor=function() return selColor end, SetColor=initFromColor }
					if cfg.Save then
						registerSaveable("color_"..cfg.Title, function() return selColor end, function(v) initFromColor(v) end)
					end
					return cpApi
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddKeyPicker
				-- ─────────────────────────────────────────────────────────────
				function Section:AddKeyPicker(cfg)
					cfg=cfg or {}
					validate({ Title="Keybind", Default="None", Mode="Toggle", Callback=function()end }, cfg)

					local Holder=makeFrame({ Name="KeyPicker_"..cfg.Title, BackgroundTransparency=1, Size=UDim2.new(0,208,0,20) }, self.ElementsHolder)
					local TitleLbl=makeLabel({ Name="Title", BackgroundTransparency=1, Size=UDim2.new(1,-40,1,0), Text=cfg.Title, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, Holder)
					local KeyLbl=makeLabel({ Name="Key", BackgroundTransparency=1, Size=UDim2.new(0,30,0,15), Position=UDim2.new(1,-5,0,0), AnchorPoint=Vector2.new(1,0), Text=cfg.Default, TextSize=12, TextXAlignment=Enum.TextXAlignment.Right, TextColor3=C_TEXT_DIM, Font=Enum.Font.GothamBold, AutomaticSize=Enum.AutomaticSize.X }, Holder)
					Window:AddKeybind(cfg.Title, cfg.Default)

					hoverText(TitleLbl)

					local currentKey=cfg.Default; local toggled=false; local kbHover=false; local listening=false
					KeyLbl.MouseEnter:Connect(function() kbHover=true  end)
					KeyLbl.MouseLeave:Connect(function() kbHover=false end)

					UIS.InputBegan:Connect(function(input,gp)
						if gp then return end
						if kbHover and not listening and input.UserInputType==MB1 then
							listening=true
							startListening(KeyLbl,function(name)
								listening=false
								if name~=currentKey then currentKey=name; Window:AddKeybind(cfg.Title,name); cfg.Callback("Changed",{Key=name,Mode=cfg.Mode}) end
							end)
							return
						end
						if not keyMatchesInput(input,currentKey) then return end
						if cfg.Mode=="Toggle" then
							toggled=not toggled
							tween(KeyLbl,{TextColor3=toggled and Theme.MainColor or C_TEXT_DIM})
							Window:SetKeybindActive(cfg.Title,toggled)
							cfg.Callback("Pressed",{Key=currentKey,Mode=cfg.Mode,State=toggled})
						elseif cfg.Mode=="Hold" then
							tween(KeyLbl,{TextColor3=Theme.MainColor}); Window:SetKeybindActive(cfg.Title,true)
							cfg.Callback("Pressed",{Key=currentKey,Mode=cfg.Mode,State=true})
						end
					end)
					UIS.InputEnded:Connect(function(input,gp)
						if gp or cfg.Mode~="Hold" then return end
						if keyMatchesInput(input,currentKey) then
							tween(KeyLbl,{TextColor3=C_TEXT_DIM}); Window:SetKeybindActive(cfg.Title,false)
							cfg.Callback("Pressed",{Key=currentKey,Mode=cfg.Mode,State=false})
						end
					end)

					return {
						GetKey =function() return currentKey end,
						SetKey =function(v) if v~=currentKey then currentKey=v; KeyLbl.Text=v; Window:AddKeybind(cfg.Title,v); cfg.Callback("Changed",{Key=v,Mode=cfg.Mode}) end end,
						GetMode=function() return cfg.Mode end,
						SetMode=function(v) cfg.Mode=v end,
					}
				end

				-- ─────────────────────────────────────────────────────────────
				-- AddTextInput
				-- ─────────────────────────────────────────────────────────────
				function Section:AddTextInput(cfg)
					cfg=cfg or {}
					validate({
						Title       = "Text Input",
						Default     = "",
						Placeholder = "Enter text...",
						ClearOnFocus= true,
						Numeric     = false,
						MaxLength   = nil,
						Callback    = function()end,
						OnFocus     = function()end,
						OnUnfocus   = function()end,
						Save        = false,
					}, cfg)

					local InputFrame=makeFrame({ Name="TextInput_"..cfg.Title, BackgroundTransparency=1, Size=UDim2.new(0,208,0,40) }, self.ElementsHolder)
					local TitleLbl=makeLabel({ Name="Title", BackgroundTransparency=1, Size=UDim2.new(1,0,0,15), Text=cfg.Title, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=C_TEXT_NORMAL, Font=Enum.Font.Gotham }, InputFrame)

					local BoxFrame=makeFrame({ Name="Box", BackgroundColor3=C_ELEM_BG, Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0,20) }, InputFrame)
					local BoxStroke=addOutlineStroke(BoxFrame)

					local TextBox=makeInstance("TextBox",{
						Name                = "Input",
						BackgroundTransparency = 1,
						Size                = UDim2.new(1,-8,1,0),
						Position            = UDim2.new(0,4,0,0),
						Text                = cfg.Default,
						PlaceholderText     = cfg.Placeholder,
						PlaceholderColor3   = C_TEXT_DIM,
						TextSize            = 13,
						TextColor3          = C_TEXT_NORMAL,
						TextXAlignment      = Enum.TextXAlignment.Left,
						Font                = Enum.Font.Gotham,
						ClearTextOnFocus    = cfg.ClearOnFocus,
						ClipsDescendants    = true,
					}, BoxFrame)

					local currentValue = cfg.Default

					TextBox.Focused:Connect(function()
						tween(BoxFrame, { BackgroundColor3=Color3.fromRGB(34,34,34) })
						BoxStroke.Color = Theme.MainColor
						tween(TitleLbl, { TextColor3=C_TEXT_HOVER })
						cfg.OnFocus(currentValue)
					end)

					TextBox.FocusLost:Connect(function(enterPressed)
						local raw = TextBox.Text
						if cfg.Numeric then
							raw = raw:gsub("[^%d%.%-]","")
							local num = tonumber(raw)
							raw = num and tostring(num) or currentValue
						end
						if cfg.MaxLength and #raw > cfg.MaxLength then
							raw = raw:sub(1, cfg.MaxLength)
						end
						if raw=="" then
							TextBox.Text = ""
						else
							TextBox.Text = raw
							currentValue = raw
						end
						BoxStroke.Color = Theme.OutlineColor
						tween(BoxFrame, { BackgroundColor3=C_ELEM_BG })
						tween(TitleLbl, { TextColor3=C_TEXT_NORMAL })
						cfg.OnUnfocus(currentValue, enterPressed)
						cfg.Callback(currentValue, enterPressed)
					end)

					TextBox:GetPropertyChangedSignal("Text"):Connect(function()
						local t = TextBox.Text
						if cfg.Numeric then
							local clean = t:gsub("[^%d%.%-]","")
							if clean~=t then TextBox.Text=clean; return end
						end
						if cfg.MaxLength and #t > cfg.MaxLength then
							TextBox.Text = t:sub(1, cfg.MaxLength); return
						end
					end)

					InputFrame.MouseEnter:Connect(function() tween(TitleLbl,{TextColor3=C_TEXT_HOVER}) end)
					InputFrame.MouseLeave:Connect(function()
						if not TextBox:IsFocused() then tween(TitleLbl,{TextColor3=C_TEXT_NORMAL}) end
					end)

					local tiApi = {
						Frame    = InputFrame,
						TextBox  = TextBox,
						GetValue = function() return currentValue end,
						SetValue = function(v)
							v = tostring(v)
							if cfg.MaxLength and #v > cfg.MaxLength then v=v:sub(1,cfg.MaxLength) end
							currentValue   = v
							TextBox.Text   = v
							cfg.Callback(currentValue, false)
						end,
						Clear    = function()
							currentValue = ""
							TextBox.Text = ""
						end,
					}
					if cfg.Save then
						registerSaveable("textinput_"..cfg.Title, function() return currentValue end, function(v) tiApi.SetValue(v) end)
					end
					return tiApi
				end

				return Section
			end -- AddSection
			return Tab
		end -- AddTab

		-- ═══════════════════════════════════════════════════════════════════════════
		-- DROP-IN REPLACEMENT  –  paste this over the existing Window:AddConfigSection
		-- inside InitJWareUI(), right before  "return Window"
		-- ═══════════════════════════════════════════════════════════════════════════
		function Window:AddConfigSection(section)

			-- ── constants ─────────────────────────────────────────────────────────
			local META_FILE   = CONFIG_FOLDER .. "/_autoload.txt"
			local ITEM_H      = 20        -- height of each config row in the list
			local MAX_VISIBLE = 5         -- rows visible before scrolling
			local LIST_W      = 208

			-- ── state ─────────────────────────────────────────────────────────────
			local selectedName  = nil     -- currently selected config name (string | nil)
			local listExpanded  = false
			local nameInputApi  = nil     -- set after we create the TextInput element

			-- ── helpers ───────────────────────────────────────────────────────────
			local function ensureCfgFolder()
				if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
			end

			local function cfgPath(name)
				return CONFIG_FOLDER .. "/" .. name .. CONFIG_EXT
			end

			local function listCfgNames()
				ensureCfgFolder()
				local out = {}
				for _, path in ipairs(listfiles(CONFIG_FOLDER)) do
					local n = path:match("[/\\]?([^/\\]+)$") or path
					if n ~= "_autoload.txt" and n:sub(-#CONFIG_EXT) == CONFIG_EXT then
						table.insert(out, n:sub(1, -#CONFIG_EXT - 1))
					end
				end
				table.sort(out)
				return out
			end

			-- ── Build the dropdown row frame ──────────────────────────────────────
			-- We build it manually so we fully control open/close without touching
			-- the shared activePopup / PopupOverlay system that AddDropdown uses.

			local DropOuter = makeFrame({
				Name                = "CfgDropOuter",
				BackgroundTransparency = 1,
				Size                = UDim2.new(0, LIST_W, 0, ITEM_H),
			}, section.ElementsHolder)

			local DropBtn = makeFrame({
				Name             = "CfgDropBtn",
				BackgroundColor3 = C_ELEM_BG,
				Size             = UDim2.new(0, LIST_W, 0, ITEM_H),
				ZIndex           = 10,
			}, DropOuter)
			addOutlineStroke(DropBtn)

			local DropLabel = makeLabel({
				Name               = "Label",
				BackgroundTransparency = 1,
				Size               = UDim2.new(0, LIST_W - 20, 1, 0),
				Position           = UDim2.new(0, 5, 0, 0),
				TextSize           = 14,
				TextXAlignment     = Enum.TextXAlignment.Left,
				TextColor3         = C_TEXT_DIM,
				Font               = Enum.Font.Gotham,
				Text               = "Saved configs",
				ZIndex             = 11,
			}, DropBtn)

			local DropArrow = makeLabel({
				Name               = "Arrow",
				BackgroundTransparency = 1,
				Size               = UDim2.new(0, 15, 1, 0),
				Position           = UDim2.new(1, -20, 0, -2),
				TextSize           = 14,
				TextXAlignment     = Enum.TextXAlignment.Right,
				TextColor3         = C_TEXT_NORMAL,
				Font               = Enum.Font.Gotham,
				Text               = "▼",
				ZIndex             = 11,
			}, DropBtn)

			-- ── The inline list (NOT in PopupOverlay – lives inside ElementsHolder) ─
			-- It sits immediately below DropOuter and is toggled visible/invisible.
			-- Because it is inside the section's own column it never conflicts with
			-- the shared activePopup logic.

			local listNames     = {}   -- current names shown
			local listRowFrames = {}   -- {frame, label} per row

			local ListOuter = makeFrame({
				Name = "CfgList",
				BackgroundColor3 = C_ELEM_BG,
				Size = UDim2.new(0, LIST_W, 0, 0),
				Visible = false,
				ClipsDescendants = true,
				ZIndex = 1000,
			}, PopupOverlay) -- or ScreenGui/MainGui

			ListOuter.AnchorPoint = Vector2.new(0, 0)
			ListOuter.Position = UDim2.new(0, 0, 0, 100)

			addOutlineStroke(ListOuter)

			local ListScroll = makeInstance("ScrollingFrame", {
				Name                  = "Scroll",
				BackgroundTransparency= 1,
				BorderSizePixel        = 0,
				Size                  = UDim2.new(1, 0, 1, 0),
				CanvasSize             = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness     = 4,
				ScrollBarImageColor3   = Theme.MainColor,
				ZIndex                 = 12,
			}, ListOuter)
			track(T.scrolls, ListScroll)
			makeInstance("UIListLayout", {
				SortOrder    = Enum.SortOrder.LayoutOrder,
				Padding      = UDim.new(0, 0),
			}, ListScroll)

			-- ── rebuild list rows ─────────────────────────────────────────────────
			local function rebuildRows(names)
				listNames = names
				-- destroy old rows
				for _, child in ipairs(ListScroll:GetChildren()) do
					if not child:IsA("UIListLayout") then child:Destroy() end
				end
				listRowFrames = {}

				local totalH = #names * ITEM_H
				local visH   = math.min(#names, MAX_VISIBLE) * ITEM_H
				ListOuter.Size               = UDim2.new(0, LIST_W, 0, visH)
				ListScroll.CanvasSize        = UDim2.new(0, 0, 0, totalH)
				ListScroll.ScrollBarThickness = (totalH > visH) and 4 or 0

				for _, name in ipairs(names) do
					local row = makeInstance("TextButton", {
						Name               = name,
						BackgroundTransparency = 1,
						AutoButtonColor    = false,
						Size               = UDim2.new(1, 0, 0, ITEM_H),
						Text               = "",
						ZIndex             = 13,
					}, ListScroll)

					local rowLbl = makeLabel({
						Name               = "Lbl",
						BackgroundColor3   = C_ELEM_BG,
						BackgroundTransparency = 0,
						Size               = UDim2.new(1, 0, 1, 0),
						Text               = name,
						TextSize           = 14,
						TextXAlignment     = Enum.TextXAlignment.Left,
						TextColor3         = C_TEXT_NORMAL,
						Font               = Enum.Font.Gotham,
						ZIndex             = 13,
					}, row)
					addOutlineStroke(rowLbl)
					makeInstance("UIPadding", { PaddingLeft = UDim.new(0, 5) }, rowLbl)

					-- highlight if selected
					if name == selectedName then
						rowLbl.BackgroundColor3 = Theme.MainColor
						if not table.find(T.activeOptLabels, rowLbl) then
							table.insert(T.activeOptLabels, rowLbl)
						end
					end

					row.MouseEnter:Connect(function() tween(rowLbl, { TextColor3 = C_TEXT_HOVER }) end)
					row.MouseLeave:Connect(function() tween(rowLbl, { TextColor3 = C_TEXT_NORMAL }) end)

					row.MouseButton1Click:Connect(function()
						-- deselect old highlight
						for _, rf in ipairs(listRowFrames) do
							local ti = table.find(T.activeOptLabels, rf.label)
							if ti then table.remove(T.activeOptLabels, ti) end
							tween(rf.label, { BackgroundColor3 = C_ELEM_BG })
						end
						-- select new
						selectedName = name
						tween(rowLbl, { BackgroundColor3 = Theme.MainColor })
						if not table.find(T.activeOptLabels, rowLbl) then
							table.insert(T.activeOptLabels, rowLbl)
						end
						DropLabel.Text     = name
						DropLabel.TextColor3 = C_TEXT_NORMAL
						-- sync name input
						if nameInputApi then nameInputApi.SetValue(name) end
						-- collapse
						listExpanded          = false
						ListOuter.Visible     = false
						DropArrow.Text        = "▼"
						tween(DropBtn, { BackgroundColor3 = C_ELEM_BG })
					end)

					table.insert(listRowFrames, { frame = row, label = rowLbl })
				end
			end

			-- ── open / close helpers ──────────────────────────────────────────────
			local function openList()
				local names = listCfgNames()
				if #names == 0 then return end

				rebuildRows(names)

				local absPos = DropBtn.AbsolutePosition
				local absSize = DropBtn.AbsoluteSize
				local overlayPos = PopupOverlay.AbsolutePosition

				ListOuter.Position = UDim2.fromOffset(
					absPos.X - overlayPos.X,
					absPos.Y - overlayPos.Y + absSize.Y + 2
				)

				listExpanded = true
				ListOuter.Visible = true
				DropArrow.Text = "▲"

				tween(DropBtn, {
					BackgroundColor3 = Theme.MainColor
				})
			end

			local function closeList()
				listExpanded      = false
				ListOuter.Visible = false
				DropArrow.Text    = "▼"
				tween(DropBtn, { BackgroundColor3 = C_ELEM_BG })
			end

			local function toggleList()
				if listExpanded then closeList() else openList() end
			end

			-- hover / click on the dropdown button
			DropBtn.MouseEnter:Connect(function()
				tween(DropLabel, { TextColor3 = C_TEXT_HOVER })
				tween(DropArrow, { TextColor3 = C_TEXT_HOVER })
			end)
			DropBtn.MouseLeave:Connect(function()
				tween(DropLabel, { TextColor3 = selectedName and C_TEXT_NORMAL or C_TEXT_DIM })
				tween(DropArrow, { TextColor3 = C_TEXT_NORMAL })
			end)
			DropBtn.InputBegan:Connect(function(i)
				if i.UserInputType == MB1 then toggleList() end
			end)

			-- ── Config Name text input ────────────────────────────────────────────
			nameInputApi = section:AddTextInput({
				Title        = "Name",
				Default      = "",
				Placeholder  = "New config..",
				ClearOnFocus = false,
				Callback     = function() end,
			})

			-- ── Save ──────────────────────────────────────────────────────────────
			section:AddButton({
				Title    = "Save",
				Callback = function()
					local name = nameInputApi.GetValue():match("^%s*(.-)%s*$")  -- trim
					if name == "" then return end
					self:SaveConfig(name)
					selectedName   = name
					DropLabel.Text      = name
					DropLabel.TextColor3 = C_TEXT_NORMAL
					if listExpanded then closeList() end
					-- persist autoload file if it already points somewhere
					ensureCfgFolder()
					if isfile(META_FILE) then writefile(META_FILE, name) end
				end,
			})

			-- ── Load ──────────────────────────────────────────────────────────────
			section:AddButton({
				Title    = "Load",
				Callback = function()
					if not selectedName or selectedName == "" then return end
					self:LoadConfig(selectedName)
					nameInputApi.SetValue(selectedName)
				end,
			})

			-- ── Delete ────────────────────────────────────────────────────────────
			section:AddButton({
				Title    = "Delete",
				Callback = function()
					if not selectedName or selectedName == "" then return end
					local path = cfgPath(selectedName)
					if isfile(path) then delfile(path) end
					if isfile(META_FILE) and readfile(META_FILE) == selectedName then
						delfile(META_FILE)
					end
					selectedName = nil
					DropLabel.Text      = "Select config..."
					DropLabel.TextColor3 = C_TEXT_DIM
					nameInputApi.SetValue("")
					-- close list cleanly (no Refresh, no popup system touched)
					closeList()
				end,
			})

			-- ── Load on Start toggle ──────────────────────────────────────────────
			local autoName   = isfile(META_FILE) and readfile(META_FILE) or ""
			local autoActive = autoName ~= ""

			if autoActive then
				selectedName         = autoName
				DropLabel.Text       = autoName
				DropLabel.TextColor3 = C_TEXT_NORMAL
			end

			section:AddToggle({
				Title    = "Load on Start",
				Default  = autoActive,
				Callback = function(state)
					ensureCfgFolder()
					if state then
						local name = nameInputApi.GetValue():match("^%s*(.-)%s*$")
						if name == "" then name = selectedName end
						if name and name ~= "" then writefile(META_FILE, name) end
					else
						if isfile(META_FILE) then delfile(META_FILE) end
					end
				end,
			})

			-- ── Auto-load on script start ─────────────────────────────────────────
			if autoActive and autoName ~= "" then
				task.defer(function() self:LoadConfig(autoName) end)
			end
		end

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
