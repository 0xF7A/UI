--------------------------------------------------------------------------------
-- Services & upvalues
--------------------------------------------------------------------------------

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")

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
-- Palette  (CS:GO cheat style — flat, dark, sharp)
--------------------------------------------------------------------------------

local COLORS = {
    bg         = Color3.fromRGB(12, 12, 12),      -- window body
    titlebar   = Color3.fromRGB(18, 18, 18),      -- header
    tab        = Color3.fromRGB(16, 16, 16),      -- sidebar bg
    tabActive  = Color3.fromRGB(28, 28, 28),      -- active tab bg
    section    = Color3.fromRGB(18, 18, 18),      -- groupbox
    element    = Color3.fromRGB(24, 24, 24),      -- controls
    elementHov = Color3.fromRGB(32, 32, 32),      -- controls hover
    accent     = Color3.fromRGB(170, 40, 40),     -- red accent
    accentHov  = Color3.fromRGB(200, 55, 55),     -- accent hover
    accentOff  = Color3.fromRGB(40, 40, 40),      -- toggle off
    success    = Color3.fromRGB(50, 180, 80),     -- green
    danger     = Color3.fromRGB(200, 40, 40),     -- red
    text       = Color3.fromRGB(200, 200, 200),   -- primary
    subtext    = Color3.fromRGB(120, 120, 120),   -- secondary
    border     = Color3.fromRGB(40, 40, 40),      -- borders everywhere
    borderLit  = Color3.fromRGB(55, 55, 55),      -- lighter border
    slider     = Color3.fromRGB(36, 36, 36),      -- slider track
    sliderFill = Color3.fromRGB(170, 40, 40),     -- slider fill
    check      = Color3.fromRGB(170, 40, 40),     -- checkbox filled
    checkOff   = Color3.fromRGB(30, 30, 30),      -- checkbox empty
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
-- Instance helpers (stealth: randomized .Name)
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
    local info = TweenInfo.new(t or 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local ok, tw = pcall(TweenService.Create, TweenService, obj, info, props)
    if ok and tw then tw:Play() end
end

-- CS:GO style: sharp corners (radius 0 by default)
local function corner(parent, radius)
    if (radius or 0) <= 0 then return nil end
    return _new("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color, thickness)
    return _new("UIStroke", {
        Color     = color or COLORS.border,
        Thickness = thickness or 1,
    }, parent)
end

local function label(parent, text, size, color, font, xAlign)
    return _new("TextLabel", {
        BackgroundTransparency = 1,
        Text          = text or "",
        TextSize      = size or 11,
        TextColor3    = color or COLORS.text,
        Font          = font or Enum.Font.Code,
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

local function padding(parent, px, top, right, bottom)
    return _new("UIPadding", {
        PaddingLeft   = UDim.new(0, px),
        PaddingRight  = UDim.new(0, right or px),
        PaddingTop    = UDim.new(0, top or px),
        PaddingBottom = UDim.new(0, bottom or px),
    }, parent)
end

local function listLayout(parent, dir, pad, halign, valign)
    return _new("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, pad or 4),
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = valign or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    }, parent)
end

--- Image icon via getcustomasset()
local function icon(parent, filePath, size, pos, color)
    local asset = nil
    if typeof(getcustomasset) == "function" then
        local ok, result = pcall(getcustomasset, filePath)
        if ok then asset = result end
    end
    if not asset then return nil end
    return _new("ImageLabel", {
        Size                  = size or UDim2.new(0, 14, 0, 14),
        Position              = pos or UDim2.new(0, 0, 0.5, -7),
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
    if typeof(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end
    local coreOk, core = pcall(function() return game:GetService("CoreGui") end)
    if coreOk and core then
        if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
            return core
        end
        local testOk, _ = pcall(function()
            local t = Instance.new("Folder")
            t.Parent = core
            t:Destroy()
        end)
        if testOk then return core end
    end
    local lp = Players.LocalPlayer
    if lp then
        local pg = lp:FindFirstChildWhichIsA("PlayerGui")
        if pg then return pg end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Draggable fallback
--------------------------------------------------------------------------------

local function _makeDraggable(gui, handle, connections)
    local nativeOk = pcall(function() gui.Draggable = true end)
    if nativeOk then return end

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
    self._connections = {}
    self.tabs = {}
    self.activeTab = nil
    self.width  = width  or 520
    self.height = height or 380

    -- ScreenGui
    self.gui = _new("ScreenGui", {
        DisplayOrder   = math.huge,
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = false,
    })
    if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, self.gui)
    end
    self.gui.Parent = gethui()

    -- Root frame (sharp, opaque, bordered)
    self.root = frame(self.gui,
        UDim2.new(0, self.width, 0, self.height),
        UDim2.new(0.5, -math.floor(self.width / 2), 0.5, -math.floor(self.height / 2)),
        COLORS.bg, true
    )
    self.root.Active = true
    stroke(self.root, COLORS.border, 1)

    -- Accent top line (colored bar at very top — CS:GO signature)
    local accentLine = frame(self.root,
        UDim2.new(1, 0, 0, 2),
        UDim2.new(0, 0, 0, 0),
        COLORS.accent
    )
    accentLine.ZIndex = 10

    -- Title bar (flat, dark)
    self.titleBar = frame(self.root,
        UDim2.new(1, 0, 0, 28),
        UDim2.new(0, 0, 0, 2),
        COLORS.titlebar
    )

    -- Drag via title bar
    _makeDraggable(self.root, self.titleBar, self._connections)

    -- Title text (left-aligned, small, monospace)
    local titleLbl = label(self.titleBar, title, 11, COLORS.subtext,
        Enum.Font.Code, Enum.TextXAlignment.Left)
    if titleLbl then
        titleLbl.Size     = UDim2.new(1, -60, 1, 0)
        titleLbl.Position = UDim2.new(0, 8, 0, 0)
    end

    -- Close [X] button (top right)
    local closeBtn = _new("TextButton", {
        Size            = UDim2.new(0, 28, 0, 28),
        Position        = UDim2.new(1, -28, 0, 0),
        BackgroundColor3 = COLORS.titlebar,
        BorderSizePixel = 0,
        Text            = "x",
        TextSize        = 12,
        TextColor3      = COLORS.subtext,
        Font            = Enum.Font.Code,
        AutoButtonColor = false,
    }, self.titleBar)
    if closeBtn then
        local c1 = closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, {BackgroundColor3 = COLORS.danger, TextColor3 = COLORS.text})
        end)
        local c2 = closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, {BackgroundColor3 = COLORS.titlebar, TextColor3 = COLORS.subtext})
        end)
        local c3 = closeBtn.MouseButton1Click:Connect(function()
            self:destroy()
        end)
        table.insert(self._connections, c1)
        table.insert(self._connections, c2)
        table.insert(self._connections, c3)
    end

    -- Minimize [-] button
    local minBtn = _new("TextButton", {
        Size            = UDim2.new(0, 28, 0, 28),
        Position        = UDim2.new(1, -56, 0, 0),
        BackgroundColor3 = COLORS.titlebar,
        BorderSizePixel = 0,
        Text            = "-",
        TextSize        = 14,
        TextColor3      = COLORS.subtext,
        Font            = Enum.Font.Code,
        AutoButtonColor = false,
    }, self.titleBar)
    local minimized = false
    if minBtn then
        local c1 = minBtn.MouseEnter:Connect(function()
            tween(minBtn, {BackgroundColor3 = COLORS.elementHov})
        end)
        local c2 = minBtn.MouseLeave:Connect(function()
            tween(minBtn, {BackgroundColor3 = COLORS.titlebar})
        end)
        local c3 = minBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            tween(self.root, {
                Size = minimized
                    and UDim2.new(0, self.width, 0, 30)
                    or  UDim2.new(0, self.width, 0, self.height)
            }, 0.15)
        end)
        table.insert(self._connections, c1)
        table.insert(self._connections, c2)
        table.insert(self._connections, c3)
    end

    -- Title bar bottom border
    frame(self.root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 30), COLORS.border)

    -- Tab bar (horizontal, top — CS:GO style)
    local tabBarY = 31
    local tabBarH = 26
    self.tabBar = frame(self.root,
        UDim2.new(1, 0, 0, tabBarH),
        UDim2.new(0, 0, 0, tabBarY),
        COLORS.titlebar
    )
    listLayout(self.tabBar, Enum.FillDirection.Horizontal, 0,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    -- Tab bar bottom border
    frame(self.root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, tabBarY + tabBarH), COLORS.border)

    -- Content area
    local contentY = tabBarY + tabBarH + 1
    self.contentArea = frame(self.root,
        UDim2.new(1, 0, 1, -contentY),
        UDim2.new(0, 0, 0, contentY),
        COLORS.bg, true
    )

    return self
end

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

function HubUI:destroy()
    tween(self.root, {BackgroundTransparency = 1}, 0.15)
    task.delay(0.2, function()
        for _, conn in ipairs(self._connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self._connections)
        if self.gui then
            pcall(function() self.gui:Destroy() end)
        end
    end)
end

--------------------------------------------------------------------------------
-- Toggle visibility
--------------------------------------------------------------------------------

function HubUI:toggle()
    if self.gui then
        self.gui.Enabled = not self.gui.Enabled
    end
end

--------------------------------------------------------------------------------
-- Tab (horizontal top tabs)
--------------------------------------------------------------------------------

function HubUI:addTab(name, tabIcon)
    local _pool = self._connections
    local Tab = {name = name, sections = {}}

    -- Tab button (flat, compact, text-only or with icon)
    local hasIcon = tabIcon and #tabIcon > 0
    Tab.button = _new("TextButton", {
        Size            = UDim2.new(0, 0, 1, 0),
        AutomaticSize   = Enum.AutomaticSize.X,
        BackgroundColor3 = COLORS.titlebar,
        BorderSizePixel = 0,
        Text            = name:upper(),
        TextSize        = 10,
        TextColor3      = COLORS.subtext,
        Font            = Enum.Font.Code,
        TextXAlignment  = Enum.TextXAlignment.Center,
        AutoButtonColor = false,
    }, self.tabBar)
    if Tab.button then
        padding(Tab.button, 14, 0, 14, 0)
    end

    -- Active tab underline indicator
    Tab._underline = frame(Tab.button,
        UDim2.new(1, 0, 0, 2),
        UDim2.new(0, 0, 1, -2),
        COLORS.accent
    )
    if Tab._underline then Tab._underline.Visible = false end

    -- Icon (if provided)
    if hasIcon and Tab.button then
        local ico = _new("ImageLabel", {
            Size                  = UDim2.new(0, 12, 0, 12),
            Position              = UDim2.new(0, 2, 0.5, -6),
            BackgroundTransparency = 1,
            ScaleType             = Enum.ScaleType.Fit,
            ImageColor3           = COLORS.subtext,
        }, Tab.button)
        if ico and typeof(getcustomasset) == "function" then
            local ok, asset = pcall(getcustomasset, tabIcon)
            if ok and asset then ico.Image = asset end
        end
        Tab._icon = ico
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
                tween(Tab.button, {BackgroundColor3 = COLORS.titlebar})
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
        ScrollBarThickness    = 3,
        ScrollBarImageColor3  = COLORS.border,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        Visible               = false,
    }, self.contentArea)
    if Tab.page then
        pcall(function() Tab.page.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
        padding(Tab.page, 8)
        listLayout(Tab.page, Enum.FillDirection.Vertical, 6)
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

    --------------------------------------------------------------------------
    -- Section (groupbox with colored left border)
    --------------------------------------------------------------------------

    function Tab:addSection(sectionName)
        local Section = {}
        local conns = _pool

        -- Groupbox frame
        local sectionFrame = frame(Tab.page,
            UDim2.new(1, -4, 0, 0), nil, COLORS.section)
        if sectionFrame then
            pcall(function() sectionFrame.AutomaticSize = Enum.AutomaticSize.Y end)
            stroke(sectionFrame, COLORS.border, 1)
        end

        -- Accent left bar (colored strip on left edge — CS:GO signature)
        local leftBar = frame(sectionFrame,
            UDim2.new(0, 2, 1, 0),
            UDim2.new(0, 0, 0, 0),
            COLORS.accent
        )
        if leftBar then leftBar.ZIndex = 5 end

        local inner = frame(sectionFrame, UDim2.new(1, 0, 0, 0), nil, COLORS.section)
        if inner then
            pcall(function() inner.AutomaticSize = Enum.AutomaticSize.Y end)
            inner.ClipsDescendants = false
            padding(inner, 10, 8, 10, 8)
            listLayout(inner, Enum.FillDirection.Vertical, 4)
        end

        -- Section header
        if sectionName and inner then
            local h = label(inner, "— " .. sectionName:upper(), 10,
                COLORS.accent, Enum.Font.Code)
            if h then h.Size = UDim2.new(1, 0, 0, 16) end
            -- header underline
            local hLine = frame(inner, UDim2.new(1, 0, 0, 1), nil, COLORS.border)
        end

        -- ── Checkbox Toggle ─────────────────────────────────────────────

        function Section:addToggle(lbl, default, callback)
            local state = default or false

            local row = frame(inner, UDim2.new(1, 0, 0, 22), nil, COLORS.section)
            if row then
                pcall(function() row.AutomaticSize = Enum.AutomaticSize.None end)
            end

            -- Checkbox box (square, sharp)
            local box = frame(row,
                UDim2.new(0, 12, 0, 12),
                UDim2.new(0, 0, 0.5, -6),
                state and COLORS.check or COLORS.checkOff)
            stroke(box, COLORS.border, 1)

            -- Checkmark text
            local checkmark = label(box, "✓", 9,
                state and COLORS.text or Color3.new(0, 0, 0),
                Enum.Font.Code, Enum.TextXAlignment.Center)
            if checkmark then
                checkmark.Size = UDim2.new(1, 0, 1, 0)
                checkmark.TextYAlignment = Enum.TextYAlignment.Center
            end

            local txt = label(row, lbl, 11, COLORS.text, Enum.Font.Code)
            if txt then
                txt.Size     = UDim2.new(1, -20, 1, 0)
                txt.Position = UDim2.new(0, 18, 0, 0)
            end

            local function update(val)
                state = val
                if box then
                    tween(box, {BackgroundColor3 = state and COLORS.check or COLORS.checkOff})
                end
                if checkmark then
                    checkmark.TextColor3 = state and COLORS.text or Color3.new(0, 0, 0)
                end
                _safecall(callback, state)
            end

            local btn = _new("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            }, row)

            if btn then
                local c1 = btn.MouseButton1Click:Connect(function() update(not state) end)
                local c2 = btn.MouseEnter:Connect(function()
                    if txt then tween(txt, {TextColor3 = COLORS.accent}) end
                end)
                local c3 = btn.MouseLeave:Connect(function()
                    if txt then tween(txt, {TextColor3 = COLORS.text}) end
                end)
                table.insert(conns, c1)
                table.insert(conns, c2)
                table.insert(conns, c3)
            end

            return {
                set = function(_, val) update(val) end,
                get = function() return state end,
            }
        end

        -- ── Slider ──────────────────────────────────────────────────────

        function Section:addSlider(lbl, min, max, default, callback)
            min     = min     or 0
            max     = max     or 100
            default = default or min
            local value    = default
            local dragging = false

            local container = frame(inner, UDim2.new(1, 0, 0, 38), nil, COLORS.section)

            local topRow = frame(container,
                UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0), COLORS.section)
            if topRow then topRow.BackgroundTransparency = 1 end

            local lblText = label(topRow, lbl, 11, COLORS.text, Enum.Font.Code)
            if lblText then lblText.Size = UDim2.new(0.7, 0, 1, 0) end

            local valText = label(topRow, tostring(value), 11, COLORS.accent,
                Enum.Font.Code, Enum.TextXAlignment.Right)
            if valText then
                valText.Size     = UDim2.new(0.3, 0, 1, 0)
                valText.Position = UDim2.new(0.7, 0, 0, 0)
            end

            -- Track (sharp, flat)
            local track = frame(container,
                UDim2.new(1, 0, 0, 4), UDim2.new(0, 0, 0, 22), COLORS.slider)

            local pct  = (value - min) / math.max(max - min, 1)
            local fill = frame(track, UDim2.new(pct, 0, 1, 0), nil, COLORS.sliderFill)

            -- Thumb indicator (small square)
            local thumb = frame(track,
                UDim2.new(0, 6, 0, 10),
                UDim2.new(pct, -3, 0.5, -5),
                COLORS.text)

            local function setVal(v)
                v     = math.clamp(math.round(v), min, max)
                value = v
                local p = (v - min) / math.max(max - min, 1)
                tween(fill, {Size = UDim2.new(p, 0, 1, 0)})
                if thumb then
                    tween(thumb, {Position = UDim2.new(p, -3, 0.5, -5)})
                end
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

            return {
                set = function(_, v) setVal(v) end,
                get = function() return value end,
            }
        end

        -- ── Button ──────────────────────────────────────────────────────

        function Section:addButton(lbl, callback)
            local btn = _new("TextButton", {
                Size            = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = COLORS.element,
                BorderSizePixel = 0,
                Text            = lbl,
                TextSize        = 11,
                TextColor3      = COLORS.text,
                Font            = Enum.Font.Code,
                AutoButtonColor = false,
            }, inner)
            if btn then stroke(btn, COLORS.border, 1) end

            if btn then
                local c1 = btn.MouseEnter:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.accent, TextColor3 = Color3.new(1, 1, 1)})
                end)
                local c2 = btn.MouseLeave:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.element, TextColor3 = COLORS.text})
                end)
                local c3 = btn.MouseButton1Down:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.accentHov})
                end)
                local c4 = btn.MouseButton1Up:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.accent})
                    _safecall(callback)
                end)
                table.insert(conns, c1)
                table.insert(conns, c2)
                table.insert(conns, c3)
                table.insert(conns, c4)
            end
        end

        -- ── Dropdown ────────────────────────────────────────────────────

        function Section:addDropdown(lbl, options, default, callback)
            local selected = default or (options and options[1]) or ""
            local open = false

            local wrapper = frame(inner, UDim2.new(1, 0, 0, 24), nil, Color3.new(0, 0, 0))
            if wrapper then
                wrapper.BackgroundTransparency = 1
                wrapper.ClipsDescendants = false
                wrapper.ZIndex = 10
            end

            local header = frame(wrapper, UDim2.new(1, 0, 0, 24), nil, COLORS.element)
            stroke(header, COLORS.border, 1)

            local selLabel = label(header, selected, 11, COLORS.text, Enum.Font.Code)
            if selLabel then
                selLabel.Size     = UDim2.new(1, -24, 1, 0)
                selLabel.Position = UDim2.new(0, 6, 0, 0)
            end

            local arrow = label(header, "v", 10, COLORS.subtext,
                Enum.Font.Code, Enum.TextXAlignment.Right)
            if arrow then
                arrow.Size     = UDim2.new(0, 18, 1, 0)
                arrow.Position = UDim2.new(1, -20, 0, 0)
            end

            -- Dropdown list
            local list = frame(wrapper,
                UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 26), COLORS.element)
            if list then
                list.ClipsDescendants = true
                list.ZIndex  = 20
                list.Visible = false
                stroke(list, COLORS.border, 1)
            end

            local listInner = frame(list, UDim2.new(1, 0, 0, 0), nil, COLORS.element)
            if listInner then
                pcall(function() listInner.AutomaticSize = Enum.AutomaticSize.Y end)
                padding(listInner, 2)
                listLayout(listInner, Enum.FillDirection.Vertical, 1)
            end

            local function close()
                open = false
                if arrow then tween(arrow, {TextColor3 = COLORS.subtext}) end
                if list then list.Visible = false end
                if wrapper then wrapper.Size = UDim2.new(1, 0, 0, 24) end
            end

            for _, opt in ipairs(options or {}) do
                local optBtn = _new("TextButton", {
                    Size            = UDim2.new(1, 0, 0, 20),
                    BackgroundColor3 = COLORS.element,
                    BorderSizePixel = 0,
                    Text            = opt,
                    TextSize        = 10,
                    TextColor3      = (opt == selected) and COLORS.accent or COLORS.text,
                    Font            = Enum.Font.Code,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    ZIndex          = 21,
                    AutoButtonColor = false,
                }, listInner)
                if optBtn then
                    padding(optBtn, 6)

                    local c1 = optBtn.MouseEnter:Connect(function()
                        tween(optBtn, {BackgroundColor3 = COLORS.elementHov})
                    end)
                    local c2 = optBtn.MouseLeave:Connect(function()
                        tween(optBtn, {BackgroundColor3 = COLORS.element})
                    end)
                    local c3 = optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        if selLabel then selLabel.Text = opt end
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
                        if arrow then tween(arrow, {TextColor3 = COLORS.accent}) end
                        local itemCount = options and #options or 0
                        local listH = math.min(itemCount * 22, 110)
                        if list then
                            list.Visible = true
                            list.Size    = UDim2.new(1, 0, 0, listH)
                        end
                        if wrapper then
                            wrapper.Size = UDim2.new(1, 0, 0, 24 + listH + 2)
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

        -- ── TextBox ─────────────────────────────────────────────────────

        function Section:addTextbox(lbl, placeholder, callback)
            local container = frame(inner, UDim2.new(1, 0, 0, 40), nil, COLORS.section)

            local txt = label(container, lbl, 10, COLORS.subtext, Enum.Font.Code)
            if txt then
                txt.Size     = UDim2.new(1, 0, 0, 14)
                txt.Position = UDim2.new(0, 0, 0, 0)
            end

            local box = _new("TextBox", {
                Size             = UDim2.new(1, 0, 0, 22),
                Position         = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = COLORS.element,
                BorderSizePixel  = 0,
                Text             = "",
                PlaceholderText  = placeholder or "...",
                PlaceholderColor3 = COLORS.subtext,
                TextColor3       = COLORS.text,
                TextSize         = 11,
                Font             = Enum.Font.Code,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
            }, container)

            if box then
                stroke(box, COLORS.border, 1)
                padding(box, 6)

                local c1 = box.Focused:Connect(function()
                    local s = box:FindFirstChildWhichIsA("UIStroke")
                    if s then tween(s, {Color = COLORS.accent}) end
                end)
                local c2 = box.FocusLost:Connect(function(enter)
                    local s = box:FindFirstChildWhichIsA("UIStroke")
                    if s then tween(s, {Color = COLORS.border}) end
                    _safecall(callback, box.Text, enter)
                end)
                table.insert(conns, c1)
                table.insert(conns, c2)
            end
        end

        -- ── Label ───────────────────────────────────────────────────────

        function Section:addLabel(text, color)
            local lbl = label(inner, text, 11, color or COLORS.subtext, Enum.Font.Code)
            if lbl then
                lbl.Size     = UDim2.new(1, 0, 0, 16)
                lbl.RichText = true
            end
            return {
                set = function(_, t) if lbl then lbl.Text = t end end,
            }
        end

        -- ── Keybind ─────────────────────────────────────────────────────

        function Section:addKeybind(lbl, default, callback)
            local key       = default or Enum.KeyCode.Unknown
            local listening = false

            local row = frame(inner, UDim2.new(1, 0, 0, 22), nil, COLORS.section)

            local txt = label(row, lbl, 11, COLORS.text, Enum.Font.Code)
            if txt then
                txt.Size     = UDim2.new(1, -70, 1, 0)
                txt.Position = UDim2.new(0, 0, 0, 0)
            end

            local keyBtn = _new("TextButton", {
                Size            = UDim2.new(0, 60, 0, 18),
                Position        = UDim2.new(1, -62, 0.5, -9),
                BackgroundColor3 = COLORS.element,
                BorderSizePixel = 0,
                Text            = "[" .. key.Name .. "]",
                TextSize        = 10,
                TextColor3      = COLORS.accent,
                Font            = Enum.Font.Code,
                AutoButtonColor = false,
            }, row)
            if keyBtn then
                stroke(keyBtn, COLORS.border, 1)
            end

            if keyBtn then
                local c1 = keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text       = "[...]"
                    keyBtn.TextColor3 = COLORS.subtext
                end)
                table.insert(conns, c1)
            end

            local c2 = UserInputService.InputBegan:Connect(function(input, gp)
                if listening and not gp then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        if keyBtn then
                            keyBtn.Text       = "[" .. key.Name .. "]"
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
                    if txt then tween(txt, {TextColor3 = COLORS.accent}) end
                end)
                local c4 = row.MouseLeave:Connect(function()
                    if txt then tween(txt, {TextColor3 = COLORS.text}) end
                end)
                table.insert(conns, c3)
                table.insert(conns, c4)
            end

            return {
                get = function() return key end,
            }
        end

        -- ── Color Picker (inline) ───────────────────────────────────────

        function Section:addColorPicker(lbl, default, callback)
            local r, g, b = 255, 0, 0
            if default then
                r = math.floor(default.R * 255)
                g = math.floor(default.G * 255)
                b = math.floor(default.B * 255)
            end

            local row = frame(inner, UDim2.new(1, 0, 0, 22), nil, COLORS.section)

            local txt = label(row, lbl, 11, COLORS.text, Enum.Font.Code)
            if txt then
                txt.Size     = UDim2.new(1, -30, 1, 0)
                txt.Position = UDim2.new(0, 0, 0, 0)
            end

            local preview = frame(row,
                UDim2.new(0, 18, 0, 12),
                UDim2.new(1, -22, 0.5, -6),
                Color3.fromRGB(r, g, b))
            stroke(preview, COLORS.border, 1)

            local function setColor(color)
                r = math.floor(color.R * 255)
                g = math.floor(color.G * 255)
                b = math.floor(color.B * 255)
                if preview then preview.BackgroundColor3 = color end
                _safecall(callback, color)
            end

            return {
                set = function(_, color) setColor(color) end,
                get = function() return Color3.fromRGB(r, g, b) end,
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
        tween(t.button, {BackgroundColor3 = COLORS.titlebar})
        if t.button then t.button.TextColor3 = COLORS.subtext end
        if t._underline then t._underline.Visible = false end
        if t._icon then tween(t._icon, {ImageColor3 = COLORS.subtext}) end
    end
    if tab.page then tab.page.Visible = true end
    tween(tab.button, {BackgroundColor3 = COLORS.tabActive})
    if tab.button then tab.button.TextColor3 = COLORS.text end
    if tab._underline then tab._underline.Visible = true end
    if tab._icon then tween(tab._icon, {ImageColor3 = COLORS.accent}) end
    self.activeTab = tab
end

--------------------------------------------------------------------------------
-- Notification (compact, flat)
--------------------------------------------------------------------------------

function HubUI:notify(title, message, duration)
    duration = duration or 3

    local notif = frame(self.gui,
        UDim2.new(0, 220, 0, 50),
        UDim2.new(1, -230, 1, 10),
        COLORS.titlebar)
    stroke(notif, COLORS.border, 1)

    -- Accent top bar on notification
    frame(notif, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), COLORS.accent)

    local t = label(notif, title, 10, COLORS.accent, Enum.Font.Code)
    if t then
        t.Size     = UDim2.new(1, -12, 0, 16)
        t.Position = UDim2.new(0, 6, 0, 6)
    end

    local m = label(notif, message, 10, COLORS.subtext, Enum.Font.Code)
    if m then
        m.Size     = UDim2.new(1, -12, 0, 16)
        m.Position = UDim2.new(0, 6, 0, 24)
    end

    tween(notif, {Position = UDim2.new(1, -230, 1, -60)}, 0.2)
    task.delay(duration, function()
        tween(notif, {Position = UDim2.new(1, 10, 1, -60)}, 0.2)
        task.wait(0.25)
        if notif then pcall(function() notif:Destroy() end) end
    end)
end

return HubUI
