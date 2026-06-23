--[[
    JWareUI Framework (Modernized & Optimized)
    An object-oriented, highly modular UI library for interface development.
--]]

local JWareUI = {}
JWareUI.__index = JWareUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Constants & Configurations
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local DEFAULT_THEME = {
    MainColor = Color3.fromRGB(70, 7, 100),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    BackgroundColor = Color3.fromRGB(27, 27, 27),
    SecondaryColor = Color3.fromRGB(16, 16, 16),
    TextColor = Color3.fromRGB(255, 255, 255),
    MutedTextColor = Color3.fromRGB(150, 150, 150)
}

-- Utility Functions
local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

local function ApplyDrag(gui, target)
    local dragging, dragInput, dragStart, startPos
    
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- =============================================================================
-- WINDOW IMPLEMENTATION
-- =============================================================================

function JWareUI.new(config)
    config = config or {}
    local self = setmetatable({}, JWareUI)
    
    self.Title = config.Title or "JWare UI Menu"
    self.TextAlignment = config.TextAlignment or "Center"
    self.Theme = config.Theme or DEFAULT_THEME
    self.Tabs = {}
    self.ActiveTab = nil

    self:BuildBaseInterface()
    return self
end

function JWareUI:BuildBaseInterface()
    -- Create ScreenGui target container
    self.ScreenGui = CreateInstance("ScreenGui", {
        Name = "JWareUI_Container",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    local parentTarget = (syn and syn.protect_gui) and syn.protect_gui(self.ScreenGui) or CoreGui
    self.ScreenGui.Parent = parentTarget

    -- Main Window Frame
    self.MainFrame = CreateInstance("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 550, 0, 400),
        Position = UDim2.new(0.5, -275, 0.5, -200),
        BackgroundColor3 = self.Theme.BackgroundColor,
        BorderSizePixel = 1,
        BorderColor3 = self.Theme.OutlineColor,
        Parent = self.ScreenGui
    })
    
    -- Title Bar
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Theme.SecondaryColor,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    local alignmentMap = {
        Left = Enum.TextXAlignment.Left,
        Center = Enum.TextXAlignment.Center,
        Right = Enum.TextXAlignment.Right
    }
    
    self.TitleLabel = CreateInstance("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = self.Theme.TextColor,
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        TextXAlignment = alignmentMap[self.TextAlignment] or Enum.TextXAlignment.Center,
        Parent = self.TitleBar
    })

    -- Container for Tabs Navigation
    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = self.Theme.BackgroundColor,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    self.TabListLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = self.TabBar
    })

    -- Display Area for Content Container
    self.ContentContainer = CreateInstance("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -20, 1, -75),
        Position = UDim2.new(0, 10, 0, 70),
        BackgroundTransparency = 1,
        Parent = self.MainFrame
    })

    ApplyDrag(self.TitleBar, self.MainFrame)
end

function JWareUI:UIToggle(state)
    if state == nil then
        self.MainFrame.Visible = not self.MainFrame.Visible
    else
        self.MainFrame.Visible = state
    end
end

-- =============================================================================
-- TAB METHODS
-- =============================================================================

local TabClass = {}
TabClass.__index = TabClass

function JWareUI:AddTab(tabConfig)
    tabConfig = tabConfig or {}
    local tab = setmetatable({}, TabClass)
    
    tab.Title = tabConfig.Title or "Tab"
    tab.Window = self
    
    -- Setup Layout Panels for Left, Center, Right dynamic column arrangement
    tab.PageFrame = CreateInstance("Frame", {
        Name = tab.Title .. "_Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.ContentContainer
    })
    
    tab.Columns = {
        Left = CreateInstance("ScrollingFrame", {
            Name = "LeftColumn",
            Size = UDim2.new(0.32, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = tab.PageFrame
        }),
        Center = CreateInstance("ScrollingFrame", {
            Name = "CenterColumn",
            Size = UDim2.new(0.32, 0, 1, 0),
            Position = UDim2.new(0.34, 0, 0, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = tab.PageFrame
        }),
        Right = CreateInstance("ScrollingFrame", {
            Name = "RightColumn",
            Size = UDim2.new(0.32, 0, 1, 0),
            Position = UDim2.new(0.68, 0, 0, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = tab.PageFrame
        })
    }
    
    for _, col in pairs(tab.Columns) do
        local layout = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = col
        })
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            col.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
    end

    -- Create navigation button link inside tab header panel
    tab.Button = CreateInstance("TextButton", {
        Name = tab.Title .. "_Btn",
        Size = UDim2.new(0, 100, 1, -5),
        BackgroundColor3 = self.Theme.SecondaryColor,
        Text = tab.Title,
        TextColor3 = self.Theme.MutedTextColor,
        Font = Enum.Font.SourceSansBold,
        TextSize = 14,
        Parent = self.TabBar
    })
    
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    return tab
end

function JWareUI:SelectTab(targetTab)
    if self.ActiveTab then
        self.ActiveTab.PageFrame.Visible = false
        TweenService:Create(self.ActiveTab.Button, TWEEN_INFO, {TextColor3 = self.Theme.MutedTextColor}):Play()
    end
    self.ActiveTab = targetTab
    targetTab.PageFrame.Visible = true
    TweenService:Create(targetTab.Button, TWEEN_INFO, {TextColor3 = self.Theme.TextColor}):Play()
end

-- =============================================================================
-- SECTION METHODS
-- =============================================================================

local SectionClass = {}
SectionClass.__index = SectionClass

function TabClass:AddSection(secConfig)
    secConfig = secConfig or {}
    local section = setmetatable({}, SectionClass)
    
    section.Title = secConfig.Title or "Section"
    section.Type = secConfig.Type or "Left" -- Left, Center, or Right Column
    section.Tab = self
    
    local targetColumn = self.Columns[section.Type] or self.Columns.Left
    
    section.Frame = CreateInstance("Frame", {
        Name = section.Title .. "_Sec",
        Size = UDim2.new(1, -5, 0, 40),
        BackgroundColor3 = self.Window.Theme.SecondaryColor,
        BorderSizePixel = 1,
        BorderColor3 = self.Window.Theme.OutlineColor,
        Parent = targetColumn
    })
    
    section.HeaderLabel = CreateInstance("TextLabel", {
        Name = "HeaderLabel",
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 2),
        BackgroundTransparency = 1,
        Text = section.Title:upper(),
        TextColor3 = self.Window.Theme.MainColor,
        Font = Enum.Font.SourceSansBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section.Frame
    })
    
    section.ElementContainer = CreateInstance("Frame", {
        Name = "Elements",
        Size = UDim2.new(1, -10, 1, -25),
        Position = UDim2.new(0, 5, 0, 22),
        BackgroundTransparency = 1,
        Parent = section.Frame
    })
    
    local layout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = section.ElementContainer
    })
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.Frame.Size = UDim2.new(1, -5, 0, layout.AbsoluteContentSize.Y + 30)
    end)
    
    return section
end

-- =============================================================================
-- INTERACTIVE COMPONENTS ELEMENT BUILDERS
-- =============================================================================

function SectionClass:AddButton(btnConfig)
    btnConfig = btnConfig or {}
    local callback = btnConfig.Callback or function() end
    
    local button = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundColor3 = self.Tab.Window.Theme.BackgroundColor,
        BorderSizePixel = 1,
        BorderColor3 = self.Tab.Window.Theme.OutlineColor,
        Text = btnConfig.Title or "Button",
        TextColor3 = self.Tab.Window.Theme.TextColor,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        Parent = self.ElementContainer
    })
    
    button.MouseButton1Click:Connect(callback)
    return button
end

function SectionClass:AddToggle(toggleConfig)
    toggleConfig = toggleConfig or {}
    local state = toggleConfig.Default or false
    local callback = toggleConfig.Callback or function() end
    local theme = self.Tab.Window.Theme

    local toggleFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Parent = self.ElementContainer
    })

    local indicator = CreateInstance("TextButton", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = state and theme.MainColor or theme.BackgroundColor,
        BorderSizePixel = 1,
        BorderColor3 = theme.OutlineColor,
        Text = "",
        Parent = toggleFrame
    })

    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1,
        Text = toggleConfig.Title or "Toggle Option",
        TextColor3 = theme.TextColor,
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleFrame
    })

    local function updateVisuals()
        TweenService:Create(indicator, TWEEN_INFO, {
            BackgroundColor3 = state and theme.MainColor or theme.BackgroundColor
        }):Play()
    end

    indicator.MouseButton1Click:Connect(function()
        state = not state
        updateVisuals()
        callback(state)
    end)

    return {
        SetState = function(newState)
            state = newState
            updateVisuals()
            callback(state)
        end,
        GetState = function()
            return state
        end
    }
end

function SectionClass:AddSlider(sliderConfig)
    sliderConfig = sliderConfig or {}
    local min = sliderConfig.Min or 0
    local max = sliderConfig.Max or 100
    local current = sliderConfig.Default or min
    local rounding = sliderConfig.Rounding or 1
    local suffix = sliderConfig.Suffix or ""
    local callback = sliderConfig.Callback or function() end
    local theme = self.Tab.Window.Theme

    local sliderFrame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Parent = self.ElementContainer
    })

    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 15),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = sliderConfig.Title or "Slider Option",
        TextColor3 = theme.TextColor,
        Font = Enum.Font.SourceSans,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sliderFrame
    })

    local valueLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0.3, -4, 0, 15),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(current) .. suffix,
        TextColor3 = theme.MutedTextColor,
        Font = Enum.Font.SourceSans,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = sliderFrame
    })

    local track = CreateInstance("TextButton", {
        Size = UDim2.new(1, -8, 0, 8),
        Position = UDim2.new(0, 4, 0, 20),
        BackgroundColor3 = theme.BackgroundColor,
        BorderSizePixel = 1,
        BorderColor3 = theme.OutlineColor,
        Text = "",
        Parent = sliderFrame
    })

    local fill = CreateInstance("Frame", {
        Size = UDim2.new((current - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = theme.MainColor,
        BorderSizePixel = 0,
        Parent = track
    })

    local function updateSlider(inputPosition)
        local relativeX = math.clamp((inputPosition.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * relativeX
        value = math.round(value / rounding) * rounding
        value = math.clamp(value, min, max)
        
        current = value
        valueLabel.Text = tostring(current) .. suffix
        fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
        callback(current)
    end

    local holding = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            holding = true
            updateSlider(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if holding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            holding = false
        end
    end)

    return {
        SetValue = function(val)
            current = math.clamp(math.round(val / rounding) * rounding, min, max)
            valueLabel.Text = tostring(current) .. suffix
            fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
            callback(current)
        end,
        GetValue = function()
            return current
        end
    }
end

function SectionClass:AddLabel(textConfig)
    textConfig = textConfig or {}
    local alignmentMap = {
        Left = Enum.TextXAlignment.Left,
        Center = Enum.TextXAlignment.Center,
        Right = Enum.TextXAlignment.Right
    }
    
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = textConfig.Title or "Static Informative Label",
        TextColor3 = self.Tab.Window.Theme.TextColor,
        Font = Enum.Font.SourceSansItalic,
        TextSize = 13,
        TextXAlignment = alignmentMap[textConfig.TextAlignment] or Enum.TextXAlignment.Left,
        Parent = self.ElementContainer
    })
    
    return label
end

-- Hook global initialization namespace pattern
getgenv().JWareUI = {
    CreateWindow = function(config)
        return JWareUI.new(config)
    end
}

return getgenv().JWareUI
