--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║  UI_CS  –  Half-Life 1 Style UI Library for Roblox Luau            ║
    ║  Sharp corners · Dark olive · Military green · 3D beveled          ║
    ║  Static window · Custom toggle key · Executor-agnostic             ║
    ╚══════════════════════════════════════════════════════════════════════╝
]]

--------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- Utility: uid generator
--------------------------------------------------------------------------------

local function uid()
    local buf = {}
    for i = 1, 8 do
        buf[i] = string.format("%02x", math.random(0, 255))
    end
    return table.concat(buf)
end

--------------------------------------------------------------------------------
-- Palette  (Half-Life 1 — dark olive, military green, muted and utilitarian)
--------------------------------------------------------------------------------

local COLORS = {
    -- Window  (dark charcoal with olive tint)
    bg           = Color3.fromRGB(20, 22, 18),
    titlebar     = Color3.fromRGB(30, 32, 26),
    border       = Color3.fromRGB(50, 55, 40),

    -- Tabs
    tab          = Color3.fromRGB(25, 28, 20),
    tabActive    = Color3.fromRGB(38, 42, 30),
    tabHover     = Color3.fromRGB(45, 50, 36),

    -- Elements
    element      = Color3.fromRGB(28, 32, 24),
    elementHov   = Color3.fromRGB(40, 45, 32),
    section      = Color3.fromRGB(22, 25, 18),
    sectionBdr   = Color3.fromRGB(50, 55, 38),

    -- Text  (greenish-grey, muted military style)
    text         = Color3.fromRGB(180, 190, 160),
    subtext      = Color3.fromRGB(110, 120, 90),
    dimtext      = Color3.fromRGB(60, 65, 45),

    -- Accent  (HL1 military olive-green)
    accent       = Color3.fromRGB(100, 120, 50),
    accentHov    = Color3.fromRGB(130, 155, 65),
    accentDim    = Color3.fromRGB(70, 85, 35),

    -- Controls
    slider       = Color3.fromRGB(32, 36, 26),
    sliderFill   = Color3.fromRGB(100, 120, 50),
    check        = Color3.fromRGB(100, 120, 50),
    checkOff     = Color3.fromRGB(32, 36, 26),

    -- 3D Bevel  (HL1 raised/sunken edges)
    bevelLight   = Color3.fromRGB(70, 78, 55),      -- top/left highlight
    bevelDark    = Color3.fromRGB(8, 10, 6),         -- bottom/right shadow
    bevelMid     = Color3.fromRGB(40, 45, 30),       -- mid-tone edge

    -- Misc
    danger       = Color3.fromRGB(160, 50, 40),
    success      = Color3.fromRGB(70, 150, 50),
    separator    = Color3.fromRGB(45, 50, 35),
}

--------------------------------------------------------------------------------
-- Safe helpers
--------------------------------------------------------------------------------

local function _safecall(fn, ...)
    if type(fn) == "function" then
        local ok, err = pcall(fn, ...)
        if not ok then warn("[UI_CS] callback error:", err) end
    end
end

local function _new(class, props, parent)
    local ok, inst = pcall(Instance.new, class)
    if not ok or not inst then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() inst[k] = v end)
    end
    if parent then
        pcall(function() inst.Parent = parent end)
    end
    return inst
end

local function tween(obj, goals, dur)
    if not obj then return end
    dur = dur or 0.1
    local ok, tw = pcall(function()
        return TweenService:Create(obj,
            TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            goals)
    end)
    if ok and tw then tw:Play() end
end

--------------------------------------------------------------------------------
-- Primitives (sharp, HL1-style 3D beveled)
--------------------------------------------------------------------------------

local function frame(parent, size, pos, color, clipDesc)
    return _new("Frame", {
        Size                  = size or UDim2.new(1, 0, 1, 0),
        Position              = pos or UDim2.new(0, 0, 0, 0),
        BackgroundColor3      = color or COLORS.bg,
        BorderSizePixel       = 0,
        BackgroundTransparency = 0,
        ClipsDescendants      = clipDesc or false,
    }, parent)
end

local function stroke(parent, color, thickness)
    return _new("UIStroke", {
        Color     = color or COLORS.border,
        Thickness = thickness or 1,
    }, parent)
end

--- HL1 3D bevel: 4 edge frames simulating raised/sunken look.
--- "raised" = light top-left, dark bottom-right (buttons, panels)
--- "sunken" = dark top-left, light bottom-right (inputs, troughs)
local function bevelRaised(parent, thickness)
    local t = thickness or 2
    -- Top highlight
    frame(parent, UDim2.new(1, 0, 0, t), UDim2.new(0, 0, 0, 0), COLORS.bevelLight).ZIndex = 8
    -- Left highlight
    frame(parent, UDim2.new(0, t, 1, 0), UDim2.new(0, 0, 0, 0), COLORS.bevelLight).ZIndex = 8
    -- Bottom shadow
    frame(parent, UDim2.new(1, 0, 0, t), UDim2.new(0, 0, 1, -t), COLORS.bevelDark).ZIndex = 8
    -- Right shadow
    frame(parent, UDim2.new(0, t, 1, 0), UDim2.new(1, -t, 0, 0), COLORS.bevelDark).ZIndex = 8
end

local function bevelSunken(parent, thickness)
    local t = thickness or 2
    -- Top shadow (dark = sunken)
    frame(parent, UDim2.new(1, 0, 0, t), UDim2.new(0, 0, 0, 0), COLORS.bevelDark).ZIndex = 8
    -- Left shadow
    frame(parent, UDim2.new(0, t, 1, 0), UDim2.new(0, 0, 0, 0), COLORS.bevelDark).ZIndex = 8
    -- Bottom highlight
    frame(parent, UDim2.new(1, 0, 0, t), UDim2.new(0, 0, 1, -t), COLORS.bevelLight).ZIndex = 8
    -- Right highlight
    frame(parent, UDim2.new(0, t, 1, 0), UDim2.new(1, -t, 0, 0), COLORS.bevelLight).ZIndex = 8
end

local function padding(parent, left, top, right, bottom)
    return _new("UIPadding", {
        PaddingLeft   = UDim.new(0, left or 0),
        PaddingTop    = UDim.new(0, top or left or 0),
        PaddingRight  = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
    }, parent)
end

local function listLayout(parent, dir, pad, hAlign, vAlign)
    return _new("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, pad or 4),
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = vAlign or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function label(parent, text, size, color, font, xAlign)
    return _new("TextLabel", {
        Size                  = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text                  = text or "",
        TextSize              = size or 11,
        TextColor3            = color or COLORS.text,
        Font                  = font or Enum.Font.Code,
        TextXAlignment        = xAlign or Enum.TextXAlignment.Left,
        TextTruncate          = Enum.TextTruncate.AtEnd,
    }, parent)
end

--------------------------------------------------------------------------------
-- Stealth: safe GUI parenting  (gethui → syn.protect_gui → CoreGui → PlayerGui)
--------------------------------------------------------------------------------

local function _getGuiParent()
    -- Executor hidden UI container
    if typeof(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and container then return container end
    end
    -- CoreGui fallback
    local ok2, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok2 and core then return core end
    -- Final fallback
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        return LocalPlayer.PlayerGui
    end
    return nil
end

-- (Dragging removed — HL1 menus are static, centered panels)

--------------------------------------------------------------------------------
-- ██╗   ██╗██╗     ██████╗███████╗
-- ██║   ██║██║    ██╔════╝██╔════╝
-- ██║   ██║██║    ██║     ███████╗
-- ██║   ██║██║    ██║     ╚════██║
-- ╚██████╔╝██║    ╚██████╗███████║
--  ╚═════╝ ╚═╝     ╚═════╝╚══════╝
--  Main Library
--------------------------------------------------------------------------------

local UILib = {}
UILib.__index = UILib

--- Create a new Half-Life 1 style window.
--- @param title string — Window title
--- @param config table? — { width, height, toggleKey }
--- @return table — Window instance
function UILib.new(title: string, config: any?)
    local self = setmetatable({}, UILib)
    config = config or {}

    self._connections = {}
    self._tabs = {}
    self._activeTab = nil
    self._keybinds = {}
    self._width  = config.width  or 560
    self._height = config.height or 420
    self._visible = true
    self._minimized = false
    self._toggleKey = config.toggleKey or Enum.KeyCode.RightShift

    -- ScreenGui
    self._screenGui = _new("ScreenGui", {
        Name           = "UI_CS_" .. uid(),
        DisplayOrder   = math.huge,
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = false,
    })

    -- Parent to executor-safe container
    self._screenGui.Parent = _getGuiParent()

    -- ═════════════════════════════════════════════════════════════════════
    -- Root frame (sharp, opaque, beveled — the main HL1 window)
    -- ═════════════════════════════════════════════════════════════════════

    self._root = frame(self._screenGui,
        UDim2.new(0, self._width, 0, self._height),
        UDim2.new(0.5, -math.floor(self._width / 2), 0.5, -math.floor(self._height / 2)),
        COLORS.bg, true
    )
    self._root.Active = true
    bevelRaised(self._root, 2)

    -- HL1 top accent bar (thicker, raised)
    local accentBar = frame(self._root,
        UDim2.new(1, -4, 0, 3),
        UDim2.new(0, 2, 0, 2),
        COLORS.accent
    )
    if accentBar then accentBar.ZIndex = 10 end

    -- ─── Title bar ──────────────────────────────────────────────────────

    self._titleBar = frame(self._root,
        UDim2.new(1, 0, 0, 30),
        UDim2.new(0, 0, 0, 2),
        COLORS.titlebar
    )

    -- Static window (no drag in HL1 style)

    -- Title text
    local titleLbl = label(self._titleBar, title, 11, COLORS.subtext,
        Enum.Font.Code, Enum.TextXAlignment.Left)
    if titleLbl then
        titleLbl.Size     = UDim2.new(1, -70, 1, 0)
        titleLbl.Position = UDim2.new(0, 10, 0, 0)
    end

    -- ─── Window controls (close / minimize) ─────────────────────────────

    -- Close [X]
    local closeBtn = _new("TextButton", {
        Size            = UDim2.new(0, 30, 0, 30),
        Position        = UDim2.new(1, -30, 0, 0),
        BackgroundColor3 = COLORS.titlebar,
        BorderSizePixel = 0,
        Text            = "×",
        TextSize        = 16,
        TextColor3      = COLORS.subtext,
        Font            = Enum.Font.Code,
        AutoButtonColor = false,
    }, self._titleBar)
    if closeBtn then
        local c1 = closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, {BackgroundColor3 = COLORS.danger, TextColor3 = COLORS.text})
        end)
        local c2 = closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, {BackgroundColor3 = COLORS.titlebar, TextColor3 = COLORS.subtext})
        end)
        local c3 = closeBtn.MouseButton1Click:Connect(function()
            self:Destroy()
        end)
        table.insert(self._connections, c1)
        table.insert(self._connections, c2)
        table.insert(self._connections, c3)
    end

    -- Minimize [-]
    local minBtn = _new("TextButton", {
        Size            = UDim2.new(0, 30, 0, 30),
        Position        = UDim2.new(1, -60, 0, 0),
        BackgroundColor3 = COLORS.titlebar,
        BorderSizePixel = 0,
        Text            = "—",
        TextSize        = 14,
        TextColor3      = COLORS.subtext,
        Font            = Enum.Font.Code,
        AutoButtonColor = false,
    }, self._titleBar)
    if minBtn then
        local c1 = minBtn.MouseEnter:Connect(function()
            tween(minBtn, {BackgroundColor3 = COLORS.elementHov})
        end)
        local c2 = minBtn.MouseLeave:Connect(function()
            tween(minBtn, {BackgroundColor3 = COLORS.titlebar})
        end)
        local c3 = minBtn.MouseButton1Click:Connect(function()
            self._minimized = not self._minimized
            tween(self._root, {
                Size = self._minimized
                    and UDim2.new(0, self._width, 0, 32)
                    or  UDim2.new(0, self._width, 0, self._height),
            }, 0.15)
        end)
        table.insert(self._connections, c1)
        table.insert(self._connections, c2)
        table.insert(self._connections, c3)
    end

    -- Title bar bottom bevel
    frame(self._root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 32), COLORS.bevelDark)
    frame(self._root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 33), COLORS.bevelLight)

    -- ─── Tab bar (horizontal, top) ──────────────────────────────────────

    local tabBarY = 33
    local tabBarH = 28
    self._tabBar = frame(self._root,
        UDim2.new(1, 0, 0, tabBarH),
        UDim2.new(0, 0, 0, tabBarY),
        COLORS.titlebar
    )
    listLayout(self._tabBar, Enum.FillDirection.Horizontal, 0,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    -- Tab bar bottom bevel
    frame(self._root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, tabBarY + tabBarH), COLORS.bevelDark)
    frame(self._root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, tabBarY + tabBarH + 1), COLORS.bevelLight)

    -- ─── Content area ───────────────────────────────────────────────────

    local contentY = tabBarY + tabBarH + 1
    self._contentArea = frame(self._root,
        UDim2.new(1, 0, 1, -contentY),
        UDim2.new(0, 0, 0, contentY),
        COLORS.bg, true
    )

    -- ─── Toggle key binding ─────────────────────────────────────────────

    local toggleConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self._toggleKey then
            self:Toggle()
        end
    end)
    table.insert(self._connections, toggleConn)

    -- ─── Watermark (bottom-right, barely visible) ───────────────────────

    local watermark = label(self._root, "UI_CS", 9, COLORS.dimtext,
        Enum.Font.Code, Enum.TextXAlignment.Right)
    if watermark then
        watermark.Size     = UDim2.new(0, 50, 0, 14)
        watermark.Position = UDim2.new(1, -56, 1, -16)
    end

    return self
end

--------------------------------------------------------------------------------
-- Window Methods
--------------------------------------------------------------------------------

--- Toggle window visibility
function UILib:Toggle()
    if self._screenGui then
        self._visible = not self._visible
        self._screenGui.Enabled = self._visible
    end
end

--- Set toggle keybind
function UILib:SetToggleKey(keyCode: Enum.KeyCode)
    self._toggleKey = keyCode
end

--- Destroy the window and clean up all connections
function UILib:Destroy()
    tween(self._root, {BackgroundTransparency = 1}, 0.12)
    task.delay(0.15, function()
        for _, conn in ipairs(self._connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self._connections)
        if self._screenGui then
            pcall(function() self._screenGui:Destroy() end)
        end
    end)
end

--- Select a tab
function UILib:_selectTab(tab)
    -- Deactivate previous
    if self._activeTab and self._activeTab ~= tab then
        local prev = self._activeTab
        if prev._button then
            tween(prev._button, {BackgroundColor3 = COLORS.titlebar, TextColor3 = COLORS.subtext})
        end
        if prev._underline then prev._underline.Visible = false end
        if prev._page then prev._page.Visible = false end
    end
    -- Activate new
    self._activeTab = tab
    if tab._button then
        tween(tab._button, {BackgroundColor3 = COLORS.tabActive, TextColor3 = COLORS.text})
    end
    if tab._underline then tab._underline.Visible = true end
    if tab._page then tab._page.Visible = true end
end

--------------------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------------------

--- Add a tab to the window.
--- @param name string — Tab name
--- @return table — Tab instance with :AddSection() method
function UILib:AddTab(name: string)
    local conns = self._connections
    local Tab = { _name = name, _sections = {} }

    -- Tab button
    Tab._button = _new("TextButton", {
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
    }, self._tabBar)
    if Tab._button then
        padding(Tab._button, 16, 0, 16, 0)
    end

    -- Underline accent indicator
    Tab._underline = frame(Tab._button,
        UDim2.new(1, 0, 0, 2),
        UDim2.new(0, 0, 1, -2),
        COLORS.accent
    )
    if Tab._underline then Tab._underline.Visible = false end

    -- Tab hover
    if Tab._button then
        local c1 = Tab._button.MouseEnter:Connect(function()
            if self._activeTab ~= Tab then
                tween(Tab._button, {BackgroundColor3 = COLORS.tabHover})
            end
        end)
        local c2 = Tab._button.MouseLeave:Connect(function()
            if self._activeTab ~= Tab then
                tween(Tab._button, {BackgroundColor3 = COLORS.titlebar})
            end
        end)
        table.insert(conns, c1)
        table.insert(conns, c2)
    end

    -- Tab page (scrollable content)
    Tab._page = _new("ScrollingFrame", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 3,
        ScrollBarImageColor3  = COLORS.border,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        Visible               = false,
    }, self._contentArea)
    if Tab._page then
        pcall(function() Tab._page.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
        padding(Tab._page, 10, 8, 10, 8)
        listLayout(Tab._page, Enum.FillDirection.Vertical, 8)
    end

    -- Tab click
    if Tab._button then
        local c = Tab._button.MouseButton1Click:Connect(function()
            self:_selectTab(Tab)
        end)
        table.insert(conns, c)
    end

    table.insert(self._tabs, Tab)
    if #self._tabs == 1 then
        self:_selectTab(Tab)
    end

    --------------------------------------------------------------------------
    -- Tab:AddSection(name)  — Add a groupbox section
    --------------------------------------------------------------------------

    --- Add a section (groupbox) to this tab.
    --- @param sectionName string — Section header name
    --- @return table — Section with widget methods
    function Tab:AddSection(sectionName: string)
        local Section = {}

        -- Groupbox frame
        local sectionFrame = frame(Tab._page,
            UDim2.new(1, -4, 0, 0), nil, COLORS.section)
        if sectionFrame then
            pcall(function() sectionFrame.AutomaticSize = Enum.AutomaticSize.Y end)
            bevelSunken(sectionFrame, 2)
        end

        -- HL1 accent left bar (raised strip on left edge)
        local leftBar = frame(sectionFrame,
            UDim2.new(0, 3, 1, -4),
            UDim2.new(0, 2, 0, 2),
            COLORS.accent
        )
        if leftBar then leftBar.ZIndex = 9 end

        -- Inner container
        local inner = frame(sectionFrame, UDim2.new(1, 0, 0, 0), nil, COLORS.section)
        if inner then
            pcall(function() inner.AutomaticSize = Enum.AutomaticSize.Y end)
            inner.ClipsDescendants = false
            padding(inner, 12, 8, 12, 8)
            listLayout(inner, Enum.FillDirection.Vertical, 5)
        end

        -- Section header
        if sectionName and inner then
            local h = label(inner, "— " .. sectionName:upper(), 10,
                COLORS.accent, Enum.Font.Code)
            if h then h.Size = UDim2.new(1, 0, 0, 16) end
            -- Header underline
            frame(inner, UDim2.new(1, 0, 0, 1), nil, COLORS.separator)
        end

        ---
        -- ✓  TOGGLE (Checkbox)
        ---

        --- @param lbl string — Label text
        --- @param default boolean? — Default state (false)
        --- @param callback function? — function(state: boolean)
        --- @return table — { set(val), get() }
        function Section:AddToggle(lbl: string, default: boolean?, callback: any?)
            local state = default or false

            local row = frame(inner, UDim2.new(1, 0, 0, 22), nil, COLORS.section)
            if row then
                pcall(function() row.AutomaticSize = Enum.AutomaticSize.None end)
            end

            -- Square checkbox
            local box = frame(row,
                UDim2.new(0, 12, 0, 12),
                UDim2.new(0, 0, 0.5, -6),
                state and COLORS.check or COLORS.checkOff)
            bevelSunken(box, 1)

            -- Checkmark
            local checkmark = label(box, "✓", 9,
                state and COLORS.text or Color3.new(0, 0, 0),
                Enum.Font.Code, Enum.TextXAlignment.Center)
            if checkmark then
                checkmark.Size = UDim2.new(1, 0, 1, 0)
                checkmark.TextYAlignment = Enum.TextYAlignment.Center
            end

            -- Label
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

            -- Click area
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

        ---
        -- ─  SLIDER
        ---

        --- @param lbl string — Label text
        --- @param min number — Minimum value
        --- @param max number — Maximum value
        --- @param default number? — Default value
        --- @param callback function? — function(value: number)
        --- @return table — { set(val), get() }
        function Section:AddSlider(lbl: string, min: number, max: number, default: number?, callback: any?)
            min     = min     or 0
            max     = max     or 100
            default = default or min
            local value    = default
            local dragging = false

            local container = frame(inner, UDim2.new(1, 0, 0, 38), nil, COLORS.section)

            -- Top row: label + value display
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

            -- Track (flat bar)
            local track = frame(container,
                UDim2.new(1, 0, 0, 4), UDim2.new(0, 0, 0, 22), COLORS.slider)

            local pct  = (value - min) / math.max(max - min, 1)
            local fill = frame(track, UDim2.new(pct, 0, 1, 0), nil, COLORS.sliderFill)

            -- Thumb (small square notch)
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

        ---
        -- ▶  BUTTON
        ---

        --- @param lbl string — Button text
        --- @param callback function? — Fired on click
        function Section:AddButton(lbl: string, callback: any?)
            local btn = _new("TextButton", {
                Size            = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = COLORS.element,
                BorderSizePixel = 0,
                Text            = lbl,
                TextSize        = 11,
                TextColor3      = COLORS.text,
                Font            = Enum.Font.Code,
                AutoButtonColor = false,
            }, inner)
            if btn then bevelRaised(btn, 1) end

            if btn then
                local c1 = btn.MouseEnter:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.accent, TextColor3 = Color3.new(1, 1, 1)})
                end)
                local c2 = btn.MouseLeave:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.element, TextColor3 = COLORS.text})
                end)
                local c3 = btn.MouseButton1Down:Connect(function()
                    tween(btn, {BackgroundColor3 = COLORS.accentDim})
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

        ---
        -- ▼  DROPDOWN
        ---

        --- @param lbl string — Label text
        --- @param options {string} — Options list
        --- @param default string? — Default selected option
        --- @param callback function? — function(selected: string)
        --- @return table — { set(val), get() }
        function Section:AddDropdown(lbl: string, options: {string}, default: string?, callback: any?)
            local selected = default or (options and options[1]) or ""
            local open = false

            -- Label above dropdown
            local ddLabel = label(inner, lbl, 10, COLORS.subtext, Enum.Font.Code)
            if ddLabel then ddLabel.Size = UDim2.new(1, 0, 0, 14) end

            local wrapper = frame(inner, UDim2.new(1, 0, 0, 24), nil, Color3.new(0, 0, 0))
            if wrapper then
                wrapper.BackgroundTransparency = 1
                wrapper.ClipsDescendants = false
                wrapper.ZIndex = 10
            end

            local header = frame(wrapper, UDim2.new(1, 0, 0, 24), nil, COLORS.element)
            bevelSunken(header, 1)

            local selLabel = label(header, selected, 11, COLORS.text, Enum.Font.Code)
            if selLabel then
                selLabel.Size     = UDim2.new(1, -24, 1, 0)
                selLabel.Position = UDim2.new(0, 8, 0, 0)
            end

            local arrow = label(header, "▾", 10, COLORS.subtext,
                Enum.Font.Code, Enum.TextXAlignment.Right)
            if arrow then
                arrow.Size     = UDim2.new(0, 20, 1, 0)
                arrow.Position = UDim2.new(1, -22, 0, 0)
            end

            -- Dropdown list
            local list = frame(wrapper,
                UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 26), COLORS.element)
            if list then
                list.ClipsDescendants = true
                list.ZIndex  = 20
                list.Visible = false
                bevelSunken(list, 1)
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

            -- Populate options
            for _, opt in ipairs(options or {}) do
                local optBtn = _new("TextButton", {
                    Size            = UDim2.new(1, 0, 0, 22),
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

            -- Toggle dropdown on header click
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
                        local listH = math.min(itemCount * 24, 120)
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

        ---
        -- ⌨  TEXTBOX
        ---

        --- @param lbl string — Label text
        --- @param placeholder string? — Placeholder text
        --- @param callback function? — function(text: string, enterPressed: boolean)
        function Section:AddTextbox(lbl: string, placeholder: string?, callback: any?)
            local container = frame(inner, UDim2.new(1, 0, 0, 42), nil, COLORS.section)

            local txt = label(container, lbl, 10, COLORS.subtext, Enum.Font.Code)
            if txt then
                txt.Size     = UDim2.new(1, 0, 0, 14)
                txt.Position = UDim2.new(0, 0, 0, 0)
            end

            local box = _new("TextBox", {
                Size             = UDim2.new(1, 0, 0, 24),
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
                bevelSunken(box, 1)
                padding(box, 8)

                local c1 = box.Focused:Connect(function()
                    -- HL1 focus: tint the background slightly brighter
                    tween(box, {BackgroundColor3 = COLORS.elementHov})
                end)
                local c2 = box.FocusLost:Connect(function(enter)
                    tween(box, {BackgroundColor3 = COLORS.element})
                    _safecall(callback, box.Text, enter)
                end)
                table.insert(conns, c1)
                table.insert(conns, c2)
            end

            return {
                set = function(_, v) if box then box.Text = v end end,
                get = function() return box and box.Text or "" end,
            }
        end

        ---
        -- 🔑  KEYBIND
        ---

        --- @param lbl string — Label text
        --- @param default Enum.KeyCode? — Default keybind
        --- @param callback function? — function(keyCode: Enum.KeyCode)
        --- @return table — { set(keyCode), get() }
        function Section:AddKeybind(lbl: string, default: any?, callback: any?)
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
            if keyBtn then bevelRaised(keyBtn, 1) end

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

            return {
                set = function(_, k)
                    key = k
                    if keyBtn then keyBtn.Text = "[" .. k.Name .. "]" end
                end,
                get = function() return key end,
            }
        end

        ---
        -- 🎨  COLOR PICKER (inline mini palette)
        ---

        --- @param lbl string — Label text
        --- @param default Color3? — Default color
        --- @param callback function? — function(color: Color3)
        --- @return table — { set(color), get() }
        function Section:AddColorPicker(lbl: string, default: any?, callback: any?)
            local color = default or Color3.fromRGB(100, 120, 50)

            local row = frame(inner, UDim2.new(1, 0, 0, 22), nil, COLORS.section)

            local txt = label(row, lbl, 11, COLORS.text, Enum.Font.Code)
            if txt then
                txt.Size     = UDim2.new(1, -30, 1, 0)
                txt.Position = UDim2.new(0, 0, 0, 0)
            end

            -- Color preview swatch
            local swatch = frame(row,
                UDim2.new(0, 20, 0, 14),
                UDim2.new(1, -24, 0.5, -7),
                color)
            bevelRaised(swatch, 1)

            local pickerOpen = false

            -- Palette panel (hidden by default)
            local palette = frame(inner, UDim2.new(1, 0, 0, 0), nil, COLORS.element)
            if palette then
                palette.Visible = false
                palette.ClipsDescendants = true
                bevelSunken(palette, 1)
            end

            local paletteInner = frame(palette, UDim2.new(1, 0, 0, 0), nil, COLORS.element)
            if paletteInner then
                pcall(function() paletteInner.AutomaticSize = Enum.AutomaticSize.Y end)
                padding(paletteInner, 6)
                listLayout(paletteInner, Enum.FillDirection.Horizontal, 4)
            end

            -- Preset colors (HL1 military style palette)
            local presets = {
                Color3.fromRGB(100, 120, 50),   -- Military Green
                Color3.fromRGB(130, 155, 65),   -- Light Olive
                Color3.fromRGB(70, 85, 35),     -- Dark Olive
                Color3.fromRGB(80, 100, 60),    -- Forest Green
                Color3.fromRGB(120, 110, 70),   -- Khaki
                Color3.fromRGB(160, 50, 40),    -- Danger Red
                Color3.fromRGB(100, 80, 45),    -- Brown
                Color3.fromRGB(180, 190, 160),  -- Off-White
                Color3.fromRGB(110, 120, 90),   -- Warm Gray
                Color3.fromRGB(22, 25, 18),     -- Near Black
            }

            for _, presetColor in ipairs(presets) do
                local colorBtn = _new("TextButton", {
                    Size            = UDim2.new(0, 18, 0, 18),
                    BackgroundColor3 = presetColor,
                    BorderSizePixel = 0,
                    Text            = "",
                    AutoButtonColor = false,
                }, paletteInner)
                if colorBtn then
                    bevelRaised(colorBtn, 1)
                    local c1 = colorBtn.MouseButton1Click:Connect(function()
                        color = presetColor
                        if swatch then tween(swatch, {BackgroundColor3 = color}) end
                        _safecall(callback, color)
                    end)
                    table.insert(conns, c1)
                end
            end

            -- Toggle palette on swatch click
            local swatchBtn = _new("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
            }, swatch)

            if swatchBtn then
                local c = swatchBtn.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    if palette then
                        palette.Visible = pickerOpen
                        palette.Size    = pickerOpen
                            and UDim2.new(1, 0, 0, 32)
                            or  UDim2.new(1, 0, 0, 0)
                    end
                end)
                table.insert(conns, c)
            end

            return {
                set = function(_, c)
                    color = c
                    if swatch then tween(swatch, {BackgroundColor3 = c}) end
                    _safecall(callback, c)
                end,
                get = function() return color end,
            }
        end

        ---
        -- —  SEPARATOR
        ---

        function Section:AddSeparator()
            frame(inner, UDim2.new(1, 0, 0, 1), nil, COLORS.separator)
        end

        ---
        -- 📝  LABEL (static or dynamic text)
        ---

        --- @param text string — Label text
        --- @param color Color3? — Text color
        --- @return table — { set(text) }
        function Section:AddLabel(text: string, color: any?)
            local lbl = label(inner, text, 11, color or COLORS.subtext, Enum.Font.Code)
            if lbl then
                lbl.Size     = UDim2.new(1, 0, 0, 16)
                lbl.RichText = true
            end
            return {
                set = function(_, t) if lbl then lbl.Text = t end end,
            }
        end

        table.insert(Tab._sections, Section)
        return Section
    end

    return Tab
end

--------------------------------------------------------------------------------
-- Notification system (small toast at bottom-right)
--------------------------------------------------------------------------------

--- Show a toast notification
--- @param text string — Message text
--- @param duration number? — Duration in seconds (default 3)
--- @param color Color3? — Accent color for the notification
function UILib:Notify(text: string, duration: number?, color: any?)
    duration = duration or 3
    color    = color or COLORS.accent

    local notif = _new("Frame", {
        Size                  = UDim2.new(0, 280, 0, 36),
        Position              = UDim2.new(1, 0, 1, -50),
        AnchorPoint           = Vector2.new(1, 1),
        BackgroundColor3      = COLORS.titlebar,
        BorderSizePixel       = 0,
        BackgroundTransparency = 0,
    }, self._screenGui)

    if notif then
        bevelRaised(notif, 1)
        -- Top accent bar
        frame(notif, UDim2.new(1, -2, 0, 2), UDim2.new(0, 1, 0, 1), color)

        local ntxt = label(notif, text, 10, COLORS.text, Enum.Font.Code)
        if ntxt then
            ntxt.Size     = UDim2.new(1, -16, 1, -4)
            ntxt.Position = UDim2.new(0, 8, 0, 4)
            ntxt.TextTruncate = Enum.TextTruncate.AtEnd
        end

        -- Slide in
        tween(notif, {Position = UDim2.new(1, -16, 1, -50)}, 0.2)

        -- Auto dismiss
        task.delay(duration, function()
            tween(notif, {Position = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1}, 0.2)
            task.delay(0.25, function()
                pcall(function() notif:Destroy() end)
            end)
        end)
    end
end

--------------------------------------------------------------------------------
-- Module Return
--------------------------------------------------------------------------------

return UILib
