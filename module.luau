--------------------------------------------------------------------------------
-- Services & upvalues
--------------------------------------------------------------------------------

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

--------------------------------------------------------------------------------
-- Stealth: random name generator
--------------------------------------------------------------------------------

local _chars = "abcdefghijklmnopqrstuvwxyz"
local function _rid(len)
    len = len or math.random(8, 14)
    local buf = table.create(len)
    for i = 1, len do
        local idx = math.random(1, #_chars)
        buf[i] = string.sub(_chars, idx, idx)
    end
    return table.concat(buf)
end

--------------------------------------------------------------------------------
-- Palette
--------------------------------------------------------------------------------

local COLORS = {
    -- macOS Sonoma dark-mode acrylic tones
    bg         = Color3.fromRGB(30, 30, 32),     -- window body
    titlebar   = Color3.fromRGB(40, 40, 44),     -- title bar
    tab        = Color3.fromRGB(36, 36, 40),     -- sidebar
    tabActive  = Color3.fromRGB(58, 58, 64),     -- active tab highlight
    section    = Color3.fromRGB(34, 34, 38),     -- section cards
    element    = Color3.fromRGB(44, 44, 50),     -- controls bg
    elementHov = Color3.fromRGB(56, 56, 62),     -- controls hover
    accent     = Color3.fromRGB(0, 122, 255),    -- macOS blue
    accentOff  = Color3.fromRGB(70, 70, 76),     -- toggle off
    success    = Color3.fromRGB(52, 199, 89),    -- macOS green
    danger     = Color3.fromRGB(255, 69, 58),    -- macOS red
    text       = Color3.fromRGB(235, 235, 240),  -- primary text
    subtext    = Color3.fromRGB(152, 152, 160),  -- secondary text
    divider    = Color3.fromRGB(58, 58, 62),     -- separators
    slider     = Color3.fromRGB(58, 58, 64),     -- slider track
    sliderFill = Color3.fromRGB(0, 122, 255),    -- slider fill
}

-- Transparency levels for acrylic glass effect
local TRANSPARENCY = {
    root     = 0.15,   -- main window body
    titlebar = 0.08,   -- title bar (slightly more opaque)
    sidebar  = 0.12,   -- tab sidebar
    content  = 0.18,   -- content area
    section  = 0.10,   -- section cards
    element  = 0.05,   -- controls
}

--------------------------------------------------------------------------------
-- Safe callback invoker
--------------------------------------------------------------------------------

local function _safecall(fn, ...)
    if fn then
        local ok, err = pcall(fn, ...)
        if not ok then
            warn("[UI] callback error: " .. tostring(err))
        end
    end
end

--------------------------------------------------------------------------------
-- Instance helpers (stealth: randomized .Name on every instance)
--------------------------------------------------------------------------------

local function _new(class, props, parent)
    local ok, inst = pcall(Instance.new, class)
    if not ok or not inst then return nil end
    inst.Name = _rid()
    if props then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function tween(obj, props, t)
    if not obj or not obj.Parent then return end
    local info = TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local ok, tw = pcall(TweenService.Create, TweenService, obj, info, props)
    if ok and tw then tw:Play() end
end

local function corner(parent, radius)
    return _new("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function stroke(parent, color, thickness)
    return _new("UIStroke", {
        Color     = color or COLORS.divider,
        Thickness = thickness or 1,
    }, parent)
end

local function label(parent, text, size, color, font, xAlign)
    return _new("TextLabel", {
        BackgroundTransparency = 1,
        Text          = text or "",
        TextSize      = size or 13,
        TextColor3    = color or COLORS.text,
        Font          = font or Enum.Font.Gotham,
        TextXAlignment = xAlign or Enum.TextXAlignment.Left,
    }, parent)
end

local function frame(parent, size, pos, color, clip)
    return _new("Frame", {
        Size              = size,
        Position          = pos or UDim2.new(0, 0, 0, 0),
        BackgroundColor3  = color or COLORS.bg,
        BorderSizePixel   = 0,
        ClipsDescendants  = clip or false,
    }, parent)
end

local function padding(parent, px)
    return _new("UIPadding", {
        PaddingLeft   = UDim.new(0, px),
        PaddingRight  = UDim.new(0, px),
        PaddingTop    = UDim.new(0, px),
        PaddingBottom = UDim.new(0, px),
    }, parent)
end

local function listLayout(parent, dir, pad, halign, valign)
    return _new("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, pad or 6),
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = valign or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    }, parent)
end

--- Lucide / image icon via getcustomasset()
local function icon(parent, filePath, size, pos, color)
    local asset = nil
    if typeof(getcustomasset) == "function" then
        local ok, result = pcall(getcustomasset, filePath)
        if ok then asset = result end
    end
    if not asset then return nil end
    return _new("ImageLabel", {
        Size                  = size or UDim2.new(0, 16, 0, 16),
        Position              = pos or UDim2.new(0, 0, 0.5, -8),
        BackgroundTransparency = 1,
        Image                 = asset,
        ImageColor3           = color or COLORS.text,
        ScaleType             = Enum.ScaleType.Fit,
    }, parent)
end

--------------------------------------------------------------------------------
-- Stealth: safe GUI parenting
--------------------------------------------------------------------------------

local function _getGuiParent()
    -- 1. Executor-provided hidden container
    if typeof(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end

    -- 2. Synapse-style protect + CoreGui
    local coreOk, core = pcall(function() return game:GetService("CoreGui") end)
    if coreOk and core then
        if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
            -- syn.protect_gui is applied to the ScreenGui later
            return core
        end
        -- Try plain CoreGui (works in some executors)
        local testOk, _ = pcall(function()
            local t = Instance.new("Folder")
            t.Parent = core
            t:Destroy()
        end)
        if testOk then return core end
    end

    -- 3. Fallback: PlayerGui
    local lp = Players.LocalPlayer
    if lp then
        local pg = lp:FindFirstChildWhichIsA("PlayerGui")
        if pg then return pg end
    end

    return nil
end

--------------------------------------------------------------------------------
-- Draggable fallback (Roblox removed .Draggable on Frames/GUIs in some builds)
--------------------------------------------------------------------------------

local function _makeDraggable(gui, handle, connections)
    -- Try native first
    local nativeOk = pcall(function() gui.Draggable = true end)
    if nativeOk then return end

    -- Manual drag
    local dragging, dragStart, startPos

    local c1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    local c2 = handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    if connections then
        table.insert(connections, c1)
        table.insert(connections, c2)
    end
end

--------------------------------------------------------------------------------
-- HubUI class
--------------------------------------------------------------------------------

local HubUI = {}
HubUI.__index = HubUI

function HubUI.new(title, width, height)
    local self = setmetatable({}, HubUI)
    self._connections = {}   -- track all connections for cleanup
    self.tabs = {}
    self.activeTab = nil
    self.width  = width  or 480
    self.height = height or 340

    -- ScreenGui (stealth: random name, non-reset, max z-order)
    self.gui = _new("ScreenGui", {
        DisplayOrder   = math.huge,
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = false,
    })

    -- Synapse protection
    if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, self.gui)
    end

    self.gui.Parent = gethui()

    -- Acrylic blur effect (frosted glass behind the window)
    self._blur = _new("BlurEffect", {
        Size = 18,
    }, Lighting)

    -- Root frame (acrylic transparent)
    self.root = frame(self.gui,
        UDim2.new(0, self.width, 0, self.height),
        UDim2.new(0.5, -math.floor(self.width / 2), 0.5, -math.floor(self.height / 2)),
        COLORS.bg, true
    )
    self.root.Active = true
    self.root.BackgroundTransparency = TRANSPARENCY.root
    corner(self.root, 12)
    stroke(self.root, Color3.fromRGB(255, 255, 255), 1)
    -- subtle white border like macOS
    local rootStroke = self.root:FindFirstChildWhichIsA("UIStroke")
    if rootStroke then rootStroke.Transparency = 0.82 end

    -- Title bar (slightly more opaque for contrast)
    self.titleBar = frame(self.root,
        UDim2.new(1, 0, 0, 38),
        UDim2.new(0, 0, 0, 0),
        COLORS.titlebar
    )
    self.titleBar.BackgroundTransparency = TRANSPARENCY.titlebar
    self.titleBar.ClipsDescendants = true
    corner(self.titleBar, 12)
    -- fill bottom half so only top corners are rounded
    local titleFix = frame(self.titleBar,
        UDim2.new(1, 0, 0, 20),
        UDim2.new(0, 0, 1, -20),
        COLORS.titlebar
    )
    titleFix.BackgroundTransparency = TRANSPARENCY.titlebar
    -- bottom separator (subtle macOS-style 1px line)
    local titleSep = frame(self.root,
        UDim2.new(1, 0, 0, 1),
        UDim2.new(0, 0, 0, 38),
        Color3.fromRGB(255, 255, 255)
    )
    titleSep.BackgroundTransparency = 0.88

    -- Drag
    _makeDraggable(self.root, self.titleBar, self._connections)

    -- Window control dots
    local dotBox = frame(self.titleBar,
        UDim2.new(0, 66, 0, 12),
        UDim2.new(0, 12, 0.5, -6),
        Color3.new(0, 0, 0)
    )
    dotBox.BackgroundTransparency = 1
    listLayout(dotBox, Enum.FillDirection.Horizontal, 6,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local function _dot(color, hov)
        local b = _new("TextButton", {
            Size            = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Text            = "",
            AutoButtonColor = false,
        }, dotBox)
        corner(b, 99)
        if b then
            local c1 = b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = hov}) end)
            local c2 = b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = color}) end)
            table.insert(self._connections, c1)
            table.insert(self._connections, c2)
        end
        return b
    end

    local redDot    = _dot(Color3.fromRGB(255, 95, 86),  Color3.fromRGB(200, 60, 55))
    local yellowDot = _dot(Color3.fromRGB(255, 189, 46), Color3.fromRGB(200, 140, 30))
    local _greenDot = _dot(Color3.fromRGB(39, 201, 63),  Color3.fromRGB(25, 160, 45))

    -- Title text
    local titleLbl = label(self.titleBar, title, 13, COLORS.text,
        Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    if titleLbl then titleLbl.Size = UDim2.new(1, 0, 1, 0) end

    -- Close
    if redDot then
        local c = redDot.MouseButton1Click:Connect(function()
            self:destroy()
        end)
        table.insert(self._connections, c)
    end

    -- Minimize
    local minimized = false
    if yellowDot then
        local c = yellowDot.MouseButton1Click:Connect(function()
            minimized = not minimized
            tween(self.root, {
                Size = minimized
                    and UDim2.new(0, self.width, 0, 38)
                    or  UDim2.new(0, self.width, 0, self.height)
            }, 0.25)
        end)
        table.insert(self._connections, c)
    end

    -- Tab bar (left sidebar — acrylic)
    self.tabBar = frame(self.root,
        UDim2.new(0, 110, 1, -38),
        UDim2.new(0, 0, 0, 38),
        COLORS.tab
    )
    self.tabBar.BackgroundTransparency = TRANSPARENCY.sidebar
    listLayout(self.tabBar, Enum.FillDirection.Vertical, 2)
    padding(self.tabBar, 6)

    -- Content area (acrylic)
    self.contentArea = frame(self.root,
        UDim2.new(1, -110, 1, -38),
        UDim2.new(0, 110, 0, 38),
        COLORS.bg, true
    )
    self.contentArea.BackgroundTransparency = TRANSPARENCY.content

    -- Divider between sidebar and content (subtle white line)
    local sideDiv = frame(self.root,
        UDim2.new(0, 1, 1, -38),
        UDim2.new(0, 110, 0, 38),
        Color3.fromRGB(255, 255, 255)
    )
    sideDiv.BackgroundTransparency = 0.88

    return self
end

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

function HubUI:destroy()
    -- Fade out
    tween(self.root, {BackgroundTransparency = 1}, 0.2)
    task.delay(0.25, function()
        -- Remove blur effect
        if self._blur then
            pcall(function() self._blur:Destroy() end)
            self._blur = nil
        end
        -- Disconnect everything
        for _, conn in ipairs(self._connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self._connections)
        -- Destroy gui tree
        if self.gui then
            pcall(function() self.gui:Destroy() end)
        end
    end)
end

--------------------------------------------------------------------------------
-- Toggle visibility (keybind-friendly)
--------------------------------------------------------------------------------

function HubUI:toggle()
    if self.gui then
        self.gui.Enabled = not self.gui.Enabled
    end
end

--------------------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------------------

function HubUI:addTab(name, icon)
    local _pool = self._connections   -- capture HubUI connection pool
    local Tab = {name = name, sections = {}}

    -- Tab button
    local hasIcon = icon and #icon > 0
    Tab.button = _new("TextButton", {
        Size            = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = COLORS.tab,
        BorderSizePixel = 0,
        Text            = hasIcon and name or name,
        TextSize        = 12,
        TextColor3      = COLORS.subtext,
        Font            = Enum.Font.GothamBold,
        TextXAlignment  = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
    }, self.tabBar)
    if Tab.button then
        corner(Tab.button, 6)
        -- Lucide icon from file path via getcustomasset()
        if hasIcon then
            local ico = _new("ImageLabel", {
                Size                  = UDim2.new(0, 14, 0, 14),
                Position              = UDim2.new(0, 8, 0.5, -7),
                BackgroundTransparency = 1,
                ScaleType             = Enum.ScaleType.Fit,
                ImageColor3           = COLORS.subtext,
            }, Tab.button)
            -- try getcustomasset for local icon file
            if ico and typeof(getcustomasset) == "function" then
                local ok, asset = pcall(getcustomasset, icon)
                if ok and asset then ico.Image = asset end
            end
            Tab._icon = ico
            -- offset text to make room for icon
            padding(Tab.button, 28)
        else
            padding(Tab.button, 8)
        end
    end

    -- Tab hover
    if Tab.button then
        local c1 = Tab.button.MouseEnter:Connect(function()
            if self.activeTab ~= Tab then
                tween(Tab.button, {BackgroundColor3 = COLORS.tabActive})
            end
        end)
        local c2 = Tab.button.MouseLeave:Connect(function()
            if self.activeTab ~= Tab then
                tween(Tab.button, {BackgroundColor3 = COLORS.tab})
            end
        end)
        table.insert(self._connections, c1)
        table.insert(self._connections, c2)
    end

    -- Tab page (scrollable)
    Tab.page = _new("ScrollingFrame", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 2,
        ScrollBarImageColor3  = COLORS.accent,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        Visible               = false,
    }, self.contentArea)

    -- Compat: AutomaticCanvasSize may not exist on all builds
    if Tab.page then
        pcall(function() Tab.page.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
        padding(Tab.page, 10)
        listLayout(Tab.page, Enum.FillDirection.Vertical, 8)
    end

    -- Tab click
    if Tab.button then
        local c = Tab.button.MouseButton1Click:Connect(function()
            self:selectTab(Tab)
        end)
        table.insert(self._connections, c)
    end

    table.insert(self.tabs, Tab)
    if #self.tabs == 1 then
        self:selectTab(Tab)
    end

    ----------------------------------------------------------------------------
    -- Section
    ----------------------------------------------------------------------------

    function Tab:addSection(sectionName)
        local Section = {}
        local conns = _pool

        local sectionFrame = frame(Tab.page,
            UDim2.new(1, -4, 0, 0), nil, COLORS.section)
        if sectionFrame then
            pcall(function() sectionFrame.AutomaticSize = Enum.AutomaticSize.Y end)
            corner(sectionFrame, 8)
            stroke(sectionFrame, COLORS.divider, 1)
        end

        local inner = frame(sectionFrame, UDim2.new(1, 0, 0, 0), nil, COLORS.section)
        if inner then
            pcall(function() inner.AutomaticSize = Enum.AutomaticSize.Y end)
            inner.ClipsDescendants = false
            padding(inner, 10)
            listLayout(inner, Enum.FillDirection.Vertical, 8)
        end

        -- Section header
        if sectionName and inner then
            local h = label(inner, sectionName:upper(), 10, COLORS.subtext, Enum.Font.GothamBold)
            if h then h.Size = UDim2.new(1, 0, 0, 14) end
        end

        -- ── Toggle ──────────────────────────────────────────────────────────

        function Section:addToggle(lbl, default, callback)
            local state = default or false

            local row = frame(inner, UDim2.new(1, 0, 0, 30), nil, COLORS.element)
            if row then
                corner(row, 6)
                pcall(function() row.AutomaticSize = Enum.AutomaticSize.None end)
            end

            local txt = label(row, lbl, 12, COLORS.text, Enum.Font.Gotham)
            if txt then
                txt.Size     = UDim2.new(1, -50, 1, 0)
                txt.Position = UDim2.new(0, 10, 0, 0)
            end

            -- Pill toggle
            local pill = frame(row,
                UDim2.new(0, 36, 0, 18),
                UDim2.new(1, -44, 0.5, -9),
                state and COLORS.accent or COLORS.accentOff)
            corner(pill, 99)

            local knob = frame(pill,
                UDim2.new(0, 14, 0, 14),
                UDim2.new(0, state and 20 or 2, 0.5, -7),
                Color3.fromRGB(255, 255, 255))
            corner(knob, 99)

            local function update(val)
                state = val
                tween(pill, {BackgroundColor3 = state and COLORS.accent or COLORS.accentOff})
                tween(knob, {Position = UDim2.new(0, state and 20 or 2, 0.5, -7)})
                _safecall(callback, state)
            end

            local btn = _new("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            }, row)

            if btn then
                local c1 = btn.MouseButton1Click:Connect(function() update(not state) end)
                local c2 = btn.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = COLORS.elementHov}) end)
                local c3 = btn.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = COLORS.element}) end)
                table.insert(conns, c1)
                table.insert(conns, c2)
                table.insert(conns, c3)
            end

            return {
                set = function(_, val) update(val) end,
                get = function() return state end,
            }
        end

        -- ── Slider ──────────────────────────────────────────────────────────

        function Section:addSlider(lbl, min, max, default, callback)
            min     = min     or 0
            max     = max     or 100
            default = default or min
            local value    = default
            local dragging = false

            local container = frame(inner, UDim2.new(1, 0, 0, 52), nil, COLORS.element)
            corner(container, 6)

            local topRow = frame(container, UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 8), Color3.new(0, 0, 0))
            if topRow then topRow.BackgroundTransparency = 1 end

            local lblText = label(topRow, lbl, 12, COLORS.text, Enum.Font.Gotham)
            if lblText then lblText.Size = UDim2.new(0.7, 0, 1, 0) end

            local valText = label(topRow, tostring(value), 12, COLORS.accent,
                Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            if valText then
                valText.Size     = UDim2.new(0.3, 0, 1, 0)
                valText.Position = UDim2.new(0.7, 0, 0, 0)
            end

            local track = frame(container,
                UDim2.new(1, -20, 0, 6), UDim2.new(0, 10, 0, 36), COLORS.slider)
            corner(track, 99)

            local pct  = (value - min) / math.max(max - min, 1)
            local fill = frame(track, UDim2.new(pct, 0, 1, 0), nil, COLORS.sliderFill)
            corner(fill, 99)

            local function setVal(v)
                v     = math.clamp(math.round(v), min, max)
                value = v
                local p = (v - min) / math.max(max - min, 1)
                tween(fill, {Size = UDim2.new(p, 0, 1, 0)})
                if valText then valText.Text = tostring(v) end
                _safecall(callback, v)
            end

            local function onInput(input)
                if not track then return end
                local trackPos  = track.AbsolutePosition.X
                local trackSize = track.AbsoluteSize.X
                if trackSize <= 0 then return end
                local rel = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
                setVal(min + rel * (max - min))
            end

            if track then
                local c1 = track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1
                        or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        onInput(i)
                    end
                end)
                table.insert(conns, c1)
            end

            local c2 = UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then
                    onInput(i)
                end
            end)
            table.insert(conns, c2)

            local c3 = UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            table.insert(conns, c3)

            if container then
                local c4 = container.MouseEnter:Connect(function()
                    tween(container, {BackgroundColor3 = COLORS.elementHov})
                end)
                local c5 = container.MouseLeave:Connect(function()
                    tween(container, {BackgroundColor3 = COLORS.element})
                end)
                table.insert(conns, c4)
                table.insert(conns, c5)
            end

            return {
                set = function(_, v) setVal(v) end,
                get = function() return value end,
            }
        end

        -- ── Button ──────────────────────────────────────────────────────────

        function Section:addButton(lbl, callback)
            local btn = _new("TextButton", {
                Size            = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = COLORS.accent,
                BorderSizePixel = 0,
                Text            = lbl,
                TextSize        = 12,
                TextColor3      = Color3.fromRGB(255, 255, 255),
                Font            = Enum.Font.GothamBold,
                AutoButtonColor = false,
            }, inner)
            if btn then corner(btn, 6) end

            if btn then
                local c1 = btn.MouseEnter:Connect(function()
                    tween(btn, {BackgroundColor3 = Color3.fromRGB(100, 160, 255)})
                end)
                local c2 = btn.MouseLeave:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.accent})
                end)
                local c3 = btn.MouseButton1Down:Connect(function()
                    tween(btn, {BackgroundColor3 = Color3.fromRGB(60, 110, 200)})
                end)
                local c4 = btn.MouseButton1Up:Connect(function()
                    tween(btn, {BackgroundColor3 = Color3.fromRGB(100, 160, 255)})
                    _safecall(callback)
                end)
                table.insert(conns, c1)
                table.insert(conns, c2)
                table.insert(conns, c3)
                table.insert(conns, c4)
            end
        end

        -- ── Dropdown ────────────────────────────────────────────────────────

        function Section:addDropdown(lbl, options, default, callback)
            local selected = default or (options and options[1]) or ""
            local open = false

            local wrapper = frame(inner, UDim2.new(1, 0, 0, 30), nil, Color3.new(0, 0, 0))
            if wrapper then
                wrapper.BackgroundTransparency = 1
                wrapper.ClipsDescendants = false
                wrapper.ZIndex = 10
            end

            local header = frame(wrapper, UDim2.new(1, 0, 0, 30), nil, COLORS.element)
            corner(header, 6)

            local selLabel = label(header, selected, 12, COLORS.text, Enum.Font.Gotham)
            if selLabel then
                selLabel.Size     = UDim2.new(1, -40, 1, 0)
                selLabel.Position = UDim2.new(0, 10, 0, 0)
            end

            local arrow = label(header, "\226\150\190", 13, COLORS.subtext,
                Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            if arrow then
                arrow.Size     = UDim2.new(0, 24, 1, 0)
                arrow.Position = UDim2.new(1, -28, 0, 0)
            end

            -- Dropdown list
            local list = frame(wrapper,
                UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 32), COLORS.element)
            if list then
                list.ClipsDescendants = true
                list.ZIndex  = 20
                list.Visible = false
                corner(list, 6)
                stroke(list, COLORS.accent, 1)
            end

            local listInner = frame(list, UDim2.new(1, 0, 0, 0), nil, COLORS.element)
            if listInner then
                pcall(function() listInner.AutomaticSize = Enum.AutomaticSize.Y end)
                padding(listInner, 4)
                listLayout(listInner, Enum.FillDirection.Vertical, 2)
            end

            local function close()
                open = false
                tween(arrow, {TextColor3 = COLORS.subtext})
                if list then list.Visible = false end
                if wrapper then wrapper.Size = UDim2.new(1, 0, 0, 30) end
            end

            for _, opt in ipairs(options or {}) do
                local optBtn = _new("TextButton", {
                    Size            = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = COLORS.element,
                    BorderSizePixel = 0,
                    Text            = opt,
                    TextSize        = 12,
                    TextColor3      = (opt == selected) and COLORS.accent or COLORS.text,
                    Font            = Enum.Font.Gotham,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    ZIndex          = 21,
                    AutoButtonColor = false,
                }, listInner)
                if optBtn then
                    corner(optBtn, 4)
                    padding(optBtn, 8)

                    local c1 = optBtn.MouseEnter:Connect(function()
                        tween(optBtn, {BackgroundColor3 = COLORS.elementHov})
                    end)
                    local c2 = optBtn.MouseLeave:Connect(function()
                        tween(optBtn, {BackgroundColor3 = COLORS.element})
                    end)
                    local c3 = optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        if selLabel then selLabel.Text = opt end
                        -- reset colors
                        if listInner then
                            for _, child in ipairs(listInner:GetChildren()) do
                                if child:IsA("TextButton") then
                                    child.TextColor3 = COLORS.text
                                end
                            end
                        end
                        optBtn.TextColor3 = COLORS.accent
                        _safecall(callback, opt)
                        close()
                    end)
                    table.insert(conns, c1)
                    table.insert(conns, c2)
                    table.insert(conns, c3)
                end
            end

            local headerBtn = _new("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text   = "",
                ZIndex = 11,
            }, header)

            if headerBtn then
                local c = headerBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        tween(arrow, {TextColor3 = COLORS.accent})
                        local itemCount = options and #options or 0
                        local listH = math.min(itemCount * 30, 120)
                        if list then
                            list.Visible = true
                            list.Size    = UDim2.new(1, 0, 0, listH)
                        end
                        if wrapper then
                            wrapper.Size = UDim2.new(1, 0, 0, 30 + listH + 4)
                        end
                    else
                        close()
                    end
                end)
                table.insert(conns, c)
            end

            if header then
                local c1 = header.MouseEnter:Connect(function()
                    tween(header, {BackgroundColor3 = COLORS.elementHov})
                end)
                local c2 = header.MouseLeave:Connect(function()
                    tween(header, {BackgroundColor3 = COLORS.element})
                end)
                table.insert(conns, c1)
                table.insert(conns, c2)
            end

            return {
                set = function(_, v)
                    selected = v
                    if selLabel then selLabel.Text = v end
                    _safecall(callback, v)
                end,
                get = function() return selected end,
            }
        end

        -- ── TextBox ─────────────────────────────────────────────────────────

        function Section:addTextbox(lbl, placeholder, callback)
            local container = frame(inner, UDim2.new(1, 0, 0, 52), nil, COLORS.element)
            corner(container, 6)

            local txt = label(container, lbl, 11, COLORS.subtext, Enum.Font.GothamBold)
            if txt then
                txt.Size     = UDim2.new(1, -20, 0, 16)
                txt.Position = UDim2.new(0, 10, 0, 6)
            end

            local box = _new("TextBox", {
                Size             = UDim2.new(1, -20, 0, 24),
                Position         = UDim2.new(0, 10, 0, 24),
                BackgroundColor3 = COLORS.bg,
                BorderSizePixel  = 0,
                Text             = "",
                PlaceholderText  = placeholder or "Type here...",
                PlaceholderColor3 = COLORS.subtext,
                TextColor3       = COLORS.text,
                TextSize         = 12,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
            }, container)

            if box then
                corner(box, 4)
                padding(box, 6)
                stroke(box, COLORS.divider, 1)

                local c1 = box.Focused:Connect(function()
                    tween(box, {BackgroundColor3 = COLORS.elementHov})
                end)
                local c2 = box.FocusLost:Connect(function(enter)
                    tween(box, {BackgroundColor3 = COLORS.bg})
                    _safecall(callback, box.Text, enter)
                end)
                table.insert(conns, c1)
                table.insert(conns, c2)
            end
        end

        -- ── Label ───────────────────────────────────────────────────────────

        function Section:addLabel(text, color)
            local lbl = label(inner, text, 12, color or COLORS.subtext, Enum.Font.Gotham)
            if lbl then
                lbl.Size     = UDim2.new(1, 0, 0, 18)
                lbl.RichText = true
            end
            return {
                set = function(_, t) if lbl then lbl.Text = t end end,
            }
        end

        -- ── Keybind ─────────────────────────────────────────────────────────

        function Section:addKeybind(lbl, default, callback)
            local key       = default or Enum.KeyCode.Unknown
            local listening = false

            local row = frame(inner, UDim2.new(1, 0, 0, 30), nil, COLORS.element)
            corner(row, 6)

            local txt = label(row, lbl, 12, COLORS.text, Enum.Font.Gotham)
            if txt then
                txt.Size     = UDim2.new(1, -90, 1, 0)
                txt.Position = UDim2.new(0, 10, 0, 0)
            end

            local keyBtn = _new("TextButton", {
                Size            = UDim2.new(0, 74, 0, 20),
                Position        = UDim2.new(1, -82, 0.5, -10),
                BackgroundColor3 = COLORS.bg,
                BorderSizePixel = 0,
                Text            = key.Name,
                TextSize        = 11,
                TextColor3      = COLORS.accent,
                Font            = Enum.Font.GothamBold,
                AutoButtonColor = false,
            }, row)
            if keyBtn then
                corner(keyBtn, 4)
                stroke(keyBtn, COLORS.divider, 1)
            end

            if keyBtn then
                local c1 = keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text       = "..."
                    keyBtn.TextColor3 = COLORS.subtext
                end)
                table.insert(conns, c1)
            end

            local c2 = UserInputService.InputBegan:Connect(function(input, gp)
                if listening and not gp then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        if keyBtn then
                            keyBtn.Text       = key.Name
                            keyBtn.TextColor3 = COLORS.accent
                        end
                        listening = false
                        _safecall(callback, key)
                    end
                end
            end)
            table.insert(conns, c2)

            if row then
                local c3 = row.MouseEnter:Connect(function()
                    tween(row, {BackgroundColor3 = COLORS.elementHov})
                end)
                local c4 = row.MouseLeave:Connect(function()
                    tween(row, {BackgroundColor3 = COLORS.element})
                end)
                table.insert(conns, c3)
                table.insert(conns, c4)
            end

            return {
                get = function() return key end,
            }
        end

        table.insert(Tab.sections, Section)
        return Section
    end


    return Tab
end

--------------------------------------------------------------------------------
-- selectTab
--------------------------------------------------------------------------------

function HubUI:selectTab(tab)
    for _, t in ipairs(self.tabs) do
        if t.page then t.page.Visible = false end
        tween(t.button, {BackgroundColor3 = COLORS.tab})
        if t.button then t.button.TextColor3 = COLORS.subtext end
        if t._icon then tween(t._icon, {ImageColor3 = COLORS.subtext}) end
    end
    if tab.page then tab.page.Visible = true end
    tween(tab.button, {BackgroundColor3 = COLORS.tabActive})
    if tab.button then tab.button.TextColor3 = COLORS.text end
    if tab._icon then tween(tab._icon, {ImageColor3 = COLORS.text}) end
    self.activeTab = tab
end

--------------------------------------------------------------------------------
-- Notification
--------------------------------------------------------------------------------

function HubUI:notify(title, message, duration)
    duration = duration or 3

    local notif = frame(self.gui,
        UDim2.new(0, 240, 0, 60),
        UDim2.new(1, -250, 1, 10),
        COLORS.titlebar)
    corner(notif, 8)
    stroke(notif, COLORS.accent, 1)

    local t = label(notif, title, 12, COLORS.accent, Enum.Font.GothamBold)
    if t then
        t.Size     = UDim2.new(1, -16, 0, 18)
        t.Position = UDim2.new(0, 8, 0, 8)
    end

    local m = label(notif, message, 11, COLORS.subtext, Enum.Font.Gotham)
    if m then
        m.Size     = UDim2.new(1, -16, 0, 18)
        m.Position = UDim2.new(0, 8, 0, 28)
    end

    tween(notif, {Position = UDim2.new(1, -250, 1, -70)}, 0.3)
    task.delay(duration, function()
        tween(notif, {Position = UDim2.new(1, 10, 1, -70)}, 0.3)
        task.wait(0.35)
        if notif then pcall(function() notif:Destroy() end) end
    end)
end

return HubUI
