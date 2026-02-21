local HubUI = {}
HubUI.__index = HubUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local COLORS = {
    bg          = Color3.fromRGB(20, 20, 20),
    titlebar    = Color3.fromRGB(30, 30, 30),
    tab         = Color3.fromRGB(30, 30, 30),
    tabActive   = Color3.fromRGB(45, 45, 45),
    section     = Color3.fromRGB(28, 28, 28),
    element     = Color3.fromRGB(38, 38, 38),
    elementHov  = Color3.fromRGB(48, 48, 48),
    accent      = Color3.fromRGB(80, 140, 255),
    accentOff   = Color3.fromRGB(60, 60, 60),
    success     = Color3.fromRGB(80, 220, 120),
    danger      = Color3.fromRGB(220, 70, 70),
    text        = Color3.fromRGB(220, 220, 220),
    subtext     = Color3.fromRGB(140, 140, 140),
    divider     = Color3.fromRGB(45, 45, 45),
    slider      = Color3.fromRGB(55, 55, 55),
    sliderFill  = Color3.fromRGB(80, 140, 255),
}

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.divider
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function label(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = size or 13
    l.TextColor3 = color or COLORS.text
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function frame(parent, size, pos, color, clip)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = color or COLORS.bg
    f.BorderSizePixel = 0
    f.ClipsDescendants = clip or false
    f.Parent = parent
    return f
end

local function padding(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.Parent = parent
end

local function listLayout(parent, dir, pad, halign, valign)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, pad or 6)
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment = valign or Enum.VerticalAlignment.Top
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

function HubUI.new(title, width, height)
    local self = setmetatable({}, HubUI)
    self.tabs = {}
    self.activeTab = nil
    self.width = width or 480
    self.height = height or 340

    -- ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "HubUI"
    self.gui.ResetOnSpawn = false
    self.gui.Parent = gethui and gethui() or game.CoreGui

    -- Root frame
    self.root = frame(self.gui,
        UDim2.new(0, self.width, 0, self.height),
        UDim2.new(0.5, -self.width/2, 0.5, -self.height/2),
        COLORS.bg
    )
    self.root.Active = true
    self.root.Draggable = true
    self.root.ClipsDescendants = true
    corner(self.root, 10)
    stroke(self.root, COLORS.divider, 1)

    -- Title bar
    self.titleBar = frame(self.root,
        UDim2.new(1, 0, 0, 38),
        UDim2.new(0, 0, 0, 0),
        COLORS.titlebar
    )
    corner(self.titleBar, 10)
    -- fix bottom corners
    frame(self.titleBar, UDim2.new(1,0,0.5,0), UDim2.new(0,0,0.5,0), COLORS.titlebar)

    -- Mac dots
    local dotContainer = frame(self.titleBar, UDim2.new(0, 66, 0, 12), UDim2.new(0, 12, 0.5, -6), Color3.new(0,0,0))
    dotContainer.BackgroundTransparency = 1
    listLayout(dotContainer, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local function dot(color, dim)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 12, 0, 12)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Text = ""
        b.Parent = dotContainer
        corner(b, 99)
        b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = dim}) end)
        b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = color}) end)
        return b
    end

    local redDot    = dot(Color3.fromRGB(255,95,86),   Color3.fromRGB(200,60,55))
    local yellowDot = dot(Color3.fromRGB(255,189,46),  Color3.fromRGB(200,140,30))
    local greenDot  = dot(Color3.fromRGB(39,201,63),   Color3.fromRGB(25,160,45))

    -- Title
    local titleLbl = label(self.titleBar, title, 13, COLORS.text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    titleLbl.Size = UDim2.new(1, 0, 1, 0)

    -- Mac actions
    redDot.MouseButton1Click:Connect(function()
        tween(self.root, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        self.gui:Destroy()
    end)

    local minimized = false
    yellowDot.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(self.root, {Size = minimized
            and UDim2.new(0, self.width, 0, 38)
            or  UDim2.new(0, self.width, 0, self.height)
        }, 0.2)
    end)

    -- Tab bar (left sidebar)
    self.tabBar = frame(self.root,
        UDim2.new(0, 110, 1, -38),
        UDim2.new(0, 0, 0, 38),
        COLORS.tab
    )
    listLayout(self.tabBar, Enum.FillDirection.Vertical, 2)
    padding(self.tabBar, 6)

    -- Content area
    self.contentArea = frame(self.root,
        UDim2.new(1, -110, 1, -38),
        UDim2.new(0, 110, 0, 38),
        COLORS.bg, true
    )

    -- divider line between sidebar and content
    local sideDiv = frame(self.root, UDim2.new(0, 1, 1, -38), UDim2.new(0, 110, 0, 38), COLORS.divider)

    return self
end

--------------------------------------------------------------------------------
-- Tab
--------------------------------------------------------------------------------

function HubUI:addTab(name, icon)
    local Tab = {}
    Tab.name = name
    Tab.sections = {}

    -- Tab button
    Tab.button = Instance.new("TextButton")
    Tab.button.Size = UDim2.new(1, 0, 0, 32)
    Tab.button.BackgroundColor3 = COLORS.tab
    Tab.button.BorderSizePixel = 0
    Tab.button.Text = (icon and icon .. "  " or "") .. name
    Tab.button.TextSize = 12
    Tab.button.TextColor3 = COLORS.subtext
    Tab.button.Font = Enum.Font.GothamBold
    Tab.button.TextXAlignment = Enum.TextXAlignment.Left
    Tab.button.Parent = self.tabBar
    corner(Tab.button, 6)
    padding(Tab.button, 8)

    Tab.button.MouseEnter:Connect(function()
        if self.activeTab ~= Tab then
            tween(Tab.button, {BackgroundColor3 = COLORS.tabActive})
        end
    end)
    Tab.button.MouseLeave:Connect(function()
        if self.activeTab ~= Tab then
            tween(Tab.button, {BackgroundColor3 = COLORS.tab})
        end
    end)

    -- Tab page (scrolling frame)
    Tab.page = Instance.new("ScrollingFrame")
    Tab.page.Size = UDim2.new(1, 0, 1, 0)
    Tab.page.BackgroundTransparency = 1
    Tab.page.BorderSizePixel = 0
    Tab.page.ScrollBarThickness = 2
    Tab.page.ScrollBarImageColor3 = COLORS.accent
    Tab.page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Tab.page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Tab.page.Visible = false
    Tab.page.Parent = self.contentArea
    padding(Tab.page, 10)
    listLayout(Tab.page, Enum.FillDirection.Vertical, 8)

    Tab.button.MouseButton1Click:Connect(function()
        self:selectTab(Tab)
    end)

    table.insert(self.tabs, Tab)

    if #self.tabs == 1 then
        self:selectTab(Tab)
    end

    -- Section adder
    function Tab:addSection(sectionName)
        local Section = {}

        local sectionFrame = frame(Tab.page,
            UDim2.new(1, -4, 0, 0),
            nil,
            COLORS.section
        )
        sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
        corner(sectionFrame, 8)
        stroke(sectionFrame, COLORS.divider, 1)

        local inner = frame(sectionFrame, UDim2.new(1,0,0,0), nil, COLORS.section)
        inner.AutomaticSize = Enum.AutomaticSize.Y
        inner.ClipsDescendants = false
        padding(inner, 10)
        listLayout(inner, Enum.FillDirection.Vertical, 8)

        -- Section header
        if sectionName then
            local header = label(inner, sectionName:upper(), 10, COLORS.subtext, Enum.Font.GothamBold)
            header.Size = UDim2.new(1, 0, 0, 14)
        end

        -- ── Toggle ──
        function Section:addToggle(lbl, default, callback)
            local state = default or false
            local row = frame(inner, UDim2.new(1, 0, 0, 30), nil, COLORS.element)
            corner(row, 6)
            row.AutomaticSize = Enum.AutomaticSize.None

            local txt = label(row, lbl, 12, COLORS.text, Enum.Font.Gotham)
            txt.Size = UDim2.new(1, -50, 1, 0)
            txt.Position = UDim2.new(0, 10, 0, 0)

            -- pill toggle
            local pill = frame(row, UDim2.new(0, 36, 0, 18), UDim2.new(1, -44, 0.5, -9), state and COLORS.accent or COLORS.accentOff)
            corner(pill, 99)

            local knob = frame(pill, UDim2.new(0, 14, 0, 14), UDim2.new(0, state and 20 or 2, 0.5, -7), Color3.fromRGB(255,255,255))
            corner(knob, 99)

            local function update(val)
                state = val
                tween(pill, {BackgroundColor3 = state and COLORS.accent or COLORS.accentOff})
                tween(knob, {Position = UDim2.new(0, state and 20 or 2, 0.5, -7)})
                if callback then callback(state) end
            end

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.Parent = row

            btn.MouseButton1Click:Connect(function() update(not state) end)
            btn.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = COLORS.elementHov}) end)
            btn.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = COLORS.element}) end)

            local ctrl = {}
            function ctrl:set(val) update(val) end
            function ctrl:get() return state end
            return ctrl
        end

        -- ── Slider ──
        function Section:addSlider(lbl, min, max, default, callback)
            min = min or 0; max = max or 100; default = default or min
            local value = default
            local dragging = false

            local container = frame(inner, UDim2.new(1, 0, 0, 52), nil, COLORS.element)
            corner(container, 6)

            local topRow = frame(container, UDim2.new(1,-20, 0, 20), UDim2.new(0, 10, 0, 8), Color3.new(0,0,0))
            topRow.BackgroundTransparency = 1

            local lblText = label(topRow, lbl, 12, COLORS.text, Enum.Font.Gotham)
            lblText.Size = UDim2.new(0.7, 0, 1, 0)

            local valText = label(topRow, tostring(value), 12, COLORS.accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            valText.Size = UDim2.new(0.3, 0, 1, 0)
            valText.Position = UDim2.new(0.7, 0, 0, 0)

            local track = frame(container, UDim2.new(1, -20, 0, 6), UDim2.new(0, 10, 0, 36), COLORS.slider)
            corner(track, 99)

            local pct = (value - min) / (max - min)
            local fill = frame(track, UDim2.new(pct, 0, 1, 0), nil, COLORS.sliderFill)
            corner(fill, 99)

            local function setVal(v)
                v = math.clamp(math.round(v), min, max)
                value = v
                local p = (v - min) / (max - min)
                tween(fill, {Size = UDim2.new(p, 0, 1, 0)})
                valText.Text = tostring(v)
                if callback then callback(v) end
            end

            local function onInput(input)
                local trackPos = track.AbsolutePosition.X
                local trackSize = track.AbsoluteSize.X
                local rel = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
                setVal(min + rel * (max - min))
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    onInput(i)
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    onInput(i)
                end
            end)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            container.MouseEnter:Connect(function() tween(container, {BackgroundColor3 = COLORS.elementHov}) end)
            container.MouseLeave:Connect(function() tween(container, {BackgroundColor3 = COLORS.element}) end)

            local ctrl = {}
            function ctrl:set(v) setVal(v) end
            function ctrl:get() return value end
            return ctrl
        end

        -- ── Button ──
        function Section:addButton(lbl, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = COLORS.accent
            btn.BorderSizePixel = 0
            btn.Text = lbl
            btn.TextSize = 12
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.Font = Enum.Font.GothamBold
            btn.Parent = inner
            corner(btn, 6)

            btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Color3.fromRGB(100,160,255)}) end)
            btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = COLORS.accent}) end)
            btn.MouseButton1Down:Connect(function() tween(btn, {BackgroundColor3 = Color3.fromRGB(60,110,200)}) end)
            btn.MouseButton1Up:Connect(function()
                tween(btn, {BackgroundColor3 = Color3.fromRGB(100,160,255)})
                if callback then callback() end
            end)
        end

        -- ── Dropdown ──
        function Section:addDropdown(lbl, options, default, callback)
            local selected = default or options[1]
            local open = false

            local wrapper = frame(inner, UDim2.new(1, 0, 0, 30), nil, Color3.new(0,0,0))
            wrapper.BackgroundTransparency = 1
            wrapper.ClipsDescendants = false
            wrapper.ZIndex = 10

            local header = frame(wrapper, UDim2.new(1, 0, 0, 30), nil, COLORS.element)
            corner(header, 6)

            local selLabel = label(header, selected, 12, COLORS.text, Enum.Font.Gotham)
            selLabel.Size = UDim2.new(1, -40, 1, 0)
            selLabel.Position = UDim2.new(0, 10, 0, 0)

            local arrow = label(header, "▾", 13, COLORS.subtext, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
            arrow.Size = UDim2.new(0, 24, 1, 0)
            arrow.Position = UDim2.new(1, -28, 0, 0)

            -- Dropdown list
            local list = frame(wrapper, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 32), COLORS.element)
            list.ClipsDescendants = true
            list.ZIndex = 20
            list.Visible = false
            corner(list, 6)
            stroke(list, COLORS.accent, 1)

            local listInner = frame(list, UDim2.new(1, 0, 0, 0), nil, COLORS.element)
            listInner.AutomaticSize = Enum.AutomaticSize.Y
            padding(listInner, 4)
            listLayout(listInner, Enum.FillDirection.Vertical, 2)

            local function close()
                open = false
                tween(arrow, {TextColor3 = COLORS.subtext})
                list.Visible = false
                wrapper.Size = UDim2.new(1, 0, 0, 30)
            end

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 26)
                optBtn.BackgroundColor3 = COLORS.element
                optBtn.BorderSizePixel = 0
                optBtn.Text = opt
                optBtn.TextSize = 12
                optBtn.TextColor3 = opt == selected and COLORS.accent or COLORS.text
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.ZIndex = 21
                optBtn.Parent = listInner
                corner(optBtn, 4)
                padding(optBtn, 8)

                optBtn.MouseEnter:Connect(function() tween(optBtn, {BackgroundColor3 = COLORS.elementHov}) end)
                optBtn.MouseLeave:Connect(function() tween(optBtn, {BackgroundColor3 = COLORS.element}) end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    selLabel.Text = opt
                    -- reset all colors
                    for _, c in ipairs(listInner:GetChildren()) do
                        if c:IsA("TextButton") then
                            c.TextColor3 = COLORS.text
                        end
                    end
                    optBtn.TextColor3 = COLORS.accent
                    if callback then callback(opt) end
                    close()
                end)
            end

            local headerBtn = Instance.new("TextButton")
            headerBtn.Size = UDim2.new(1, 0, 1, 0)
            headerBtn.BackgroundTransparency = 1
            headerBtn.Text = ""
            headerBtn.ZIndex = 11
            headerBtn.Parent = header

            headerBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    tween(arrow, {TextColor3 = COLORS.accent})
                    local itemCount = #options
                    local listH = math.min(itemCount * 30, 120)
                    list.Visible = true
                    list.Size = UDim2.new(1, 0, 0, listH)
                    wrapper.Size = UDim2.new(1, 0, 0, 30 + listH + 4)
                else
                    close()
                end
            end)

            header.MouseEnter:Connect(function() tween(header, {BackgroundColor3 = COLORS.elementHov}) end)
            header.MouseLeave:Connect(function() tween(header, {BackgroundColor3 = COLORS.element}) end)

            local ctrl = {}
            function ctrl:set(v)
                selected = v
                selLabel.Text = v
                if callback then callback(v) end
            end
            function ctrl:get() return selected end
            return ctrl
        end

        -- ── TextBox ──
        function Section:addTextbox(lbl, placeholder, callback)
            local container = frame(inner, UDim2.new(1, 0, 0, 52), nil, COLORS.element)
            corner(container, 6)

            local txt = label(container, lbl, 11, COLORS.subtext, Enum.Font.GothamBold)
            txt.Size = UDim2.new(1, -20, 0, 16)
            txt.Position = UDim2.new(0, 10, 0, 6)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -20, 0, 24)
            box.Position = UDim2.new(0, 10, 0, 24)
            box.BackgroundColor3 = COLORS.bg
            box.BorderSizePixel = 0
            box.Text = ""
            box.PlaceholderText = placeholder or "Type here..."
            box.PlaceholderColor3 = COLORS.subtext
            box.TextColor3 = COLORS.text
            box.TextSize = 12
            box.Font = Enum.Font.Gotham
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = false
            box.Parent = container
            corner(box, 4)
            padding(box, 6)
            stroke(box, COLORS.divider, 1)

            box.Focused:Connect(function() tween(box, {BackgroundColor3 = COLORS.elementHov}) end)
            box.FocusLost:Connect(function(enter)
                tween(box, {BackgroundColor3 = COLORS.bg})
                if callback then callback(box.Text, enter) end
            end)
        end

        -- ── Label ──
        function Section:addLabel(text, color)
            local lbl = label(inner, text, 12, color or COLORS.subtext, Enum.Font.Gotham)
            lbl.Size = UDim2.new(1, 0, 0, 18)
            lbl.RichText = true
            local ctrl = {}
            function ctrl:set(t) lbl.Text = t end
            return ctrl
        end

        -- ── Keybind ──
        function Section:addKeybind(lbl, default, callback)
            local key = default or Enum.KeyCode.Unknown
            local listening = false

            local row = frame(inner, UDim2.new(1, 0, 0, 30), nil, COLORS.element)
            corner(row, 6)

            local txt = label(row, lbl, 12, COLORS.text, Enum.Font.Gotham)
            txt.Size = UDim2.new(1, -90, 1, 0)
            txt.Position = UDim2.new(0, 10, 0, 0)

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 74, 0, 20)
            keyBtn.Position = UDim2.new(1, -82, 0.5, -10)
            keyBtn.BackgroundColor3 = COLORS.bg
            keyBtn.BorderSizePixel = 0
            keyBtn.Text = key.Name
            keyBtn.TextSize = 11
            keyBtn.TextColor3 = COLORS.accent
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.Parent = row
            corner(keyBtn, 4)
            stroke(keyBtn, COLORS.divider, 1)

            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
                keyBtn.TextColor3 = COLORS.subtext
            end)

            UserInputService.InputBegan:Connect(function(input, gp)
                if listening and not gp then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        keyBtn.Text = key.Name
                        keyBtn.TextColor3 = COLORS.accent
                        listening = false
                        if callback then callback(key) end
                    end
                end
            end)

            row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = COLORS.elementHov}) end)
            row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = COLORS.element}) end)

            local ctrl = {}
            function ctrl:get() return key end
            return ctrl
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
        t.page.Visible = false
        tween(t.button, {BackgroundColor3 = COLORS.tab})
        t.button.TextColor3 = COLORS.subtext
    end
    tab.page.Visible = true
    tween(tab.button, {BackgroundColor3 = COLORS.tabActive})
    tab.button.TextColor3 = COLORS.text
    self.activeTab = tab
end

--------------------------------------------------------------------------------
-- notify
--------------------------------------------------------------------------------

function HubUI:notify(title, message, duration)
    duration = duration or 3

    local notif = frame(self.gui,
        UDim2.new(0, 240, 0, 60),
        UDim2.new(1, -250, 1, 10),
        COLORS.titlebar
    )
    corner(notif, 8)
    stroke(notif, COLORS.accent, 1)

    local t = label(notif, title, 12, COLORS.accent, Enum.Font.GothamBold)
    t.Size = UDim2.new(1,-16, 0, 18)
    t.Position = UDim2.new(0, 8, 0, 8)

    local m = label(notif, message, 11, COLORS.subtext, Enum.Font.Gotham)
    m.Size = UDim2.new(1,-16, 0, 18)
    m.Position = UDim2.new(0, 8, 0, 28)

    tween(notif, {Position = UDim2.new(1, -250, 1, -70)}, 0.3)
    task.delay(duration, function()
        tween(notif, {Position = UDim2.new(1, 10, 1, -70)}, 0.3)
        task.wait(0.35)
        notif:Destroy()
    end)
end

return HubUI
