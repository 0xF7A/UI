local lib = {}
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local g = gethui()

local C3 = Color3.fromRGB
local U2 = UDim2.new
local ud = UDim.new
local v2 = Vector2.new
local In = Instance.new

local cl = {
	bg = C3(26, 26, 26),
	bg2 = C3(35, 35, 35),
	bg3 = C3(45, 45, 45),
	bl = C3(74, 74, 74),
	bd = C3(10, 10, 10),
	bm = C3(30, 30, 30),
	tx = C3(200, 200, 200),
	tx2 = C3(160, 160, 160),
	acc = C3(180, 120, 50),
	hov = C3(55, 55, 55),
	act = C3(180, 120, 50),
}

local ft = Enum.Font.Code
local fs = 14

local _r = {}
local _k = {}

local function p(c, o)
	local v = In(c)
	for k, val in pairs(o) do
		v[k] = val
	end
	return v
end

local function br(par, w, h, raised)
	local lt, dk = cl.bl, cl.bd
	if not raised then lt, dk = cl.bd, cl.bl end
	local bw = 2

	p("Frame", {
		Name = "BT", Parent = par, Size = U2(1, 0, 0, bw),
		Position = U2(0, 0, 0, 0), BackgroundColor3 = lt,
		BorderSizePixel = 0, ZIndex = par.ZIndex + 1
	})
	p("Frame", {
		Name = "BL", Parent = par, Size = U2(0, bw, 1, 0),
		Position = U2(0, 0, 0, 0), BackgroundColor3 = lt,
		BorderSizePixel = 0, ZIndex = par.ZIndex + 1
	})
	p("Frame", {
		Name = "BB", Parent = par, Size = U2(1, 0, 0, bw),
		Position = U2(0, 0, 1, -bw), BackgroundColor3 = dk,
		BorderSizePixel = 0, ZIndex = par.ZIndex + 1
	})
	p("Frame", {
		Name = "BR", Parent = par, Size = U2(0, bw, 1, 0),
		Position = U2(1, -bw, 0, 0), BackgroundColor3 = dk,
		BorderSizePixel = 0, ZIndex = par.ZIndex + 1
	})
end

local function bs(par)
	br(par, nil, nil, false)
end

local function mkdrag(f)
	local dd, dx, dy = false, 0, 0
	f.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dd = true
			dx = i.Position.X - f.AbsolutePosition.X
			dy = i.Position.Y - f.AbsolutePosition.Y
		end
	end)
	f.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dd = false
		end
	end)
	uis.InputChanged:Connect(function(i)
		if dd and i.UserInputType == Enum.UserInputType.MouseMovement then
			f.Position = U2(0, i.Position.X - dx, 0, i.Position.Y - dy)
		end
	end)
end

local function anim(obj, props, dur)
	dur = dur or 0.15
	local ti = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	ts:Create(obj, ti, props):Play()
end

function lib.new(t, x, y, kc)
	x = x or 100
	y = y or 100

	if t == "panel" then
		local sg = p("ScreenGui", {
			Name = "HL_Panel", Parent = g, ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		})
		local mf = p("Frame", {
			Name = "Root", Parent = sg, Size = U2(0, 400, 0, 300),
			Position = U2(0, x, 0, y), BackgroundColor3 = cl.bg,
			BorderSizePixel = 0, ZIndex = 1
		})
		br(mf, 400, 300, true)

		local inner = p("Frame", {
			Name = "Inner", Parent = mf, Size = U2(1, -8, 1, -8),
			Position = U2(0, 4, 0, 4), BackgroundColor3 = cl.bg2,
			BorderSizePixel = 0, ZIndex = 2
		})
		bs(inner)

		local cont = p("Frame", {
			Name = "Content", Parent = inner, Size = U2(1, -6, 1, -6),
			Position = U2(0, 3, 0, 3), BackgroundColor3 = cl.bg,
			BorderSizePixel = 0, ZIndex = 3
		})

		mkdrag(mf)

		if kc then
			local kce = typeof(kc) == "EnumItem" and kc or Enum.KeyCode[kc]
			_k[kce] = sg
		end

		table.insert(_r, sg)
		return {sg = sg, root = mf, inner = inner, content = cont}

	elseif t == "header" then
		local hf = p("Frame", {
			Name = "Header", Parent = (lib._cp or g),
			Size = U2(1, 0, 0, 28), Position = U2(0, 0, 0, x),
			BackgroundColor3 = cl.bg3, BorderSizePixel = 0, ZIndex = 5
		})
		br(hf, nil, nil, true)

		local hl = p("TextLabel", {
			Name = "Title", Parent = hf,
			Size = U2(1, -10, 1, -4), Position = U2(0, 5, 0, 2),
			BackgroundTransparency = 1, Text = y or "HEADER",
			Font = ft, TextSize = fs, TextColor3 = cl.acc,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6
		})
		return {frame = hf, label = hl}

	elseif t == "button" then
		local bf = p("Frame", {
			Name = "BtnWrap", Parent = (lib._cp or g),
			Size = U2(1, -10, 0, 26), Position = U2(0, 5, 0, x),
			BackgroundColor3 = cl.bg3, BorderSizePixel = 0, ZIndex = 5
		})
		br(bf, nil, nil, true)

		local bl = p("TextButton", {
			Name = "Btn", Parent = bf,
			Size = U2(1, -4, 1, -4), Position = U2(0, 2, 0, 2),
			BackgroundColor3 = cl.bg2, BorderSizePixel = 0,
			Text = y or "Button", Font = ft, TextSize = fs,
			TextColor3 = cl.tx, ZIndex = 6, AutoButtonColor = false
		})
		bs(bl)

		local _cb = nil

		bl.MouseEnter:Connect(function()
			anim(bl, {BackgroundColor3 = cl.hov})
		end)
		bl.MouseLeave:Connect(function()
			anim(bl, {BackgroundColor3 = cl.bg2})
		end)
		bl.MouseButton1Down:Connect(function()
			bl.BackgroundColor3 = cl.bd
		end)
		bl.MouseButton1Up:Connect(function()
			bl.BackgroundColor3 = cl.hov
		end)
		bl.MouseButton1Click:Connect(function()
			if _cb then _cb() end
		end)

		local obj = {frame = bf, btn = bl}
		function obj:OnClick(fn) _cb = fn end
		return obj

	elseif t == "textbox" then
		local tf = p("Frame", {
			Name = "TbWrap", Parent = (lib._cp or g),
			Size = U2(1, -10, 0, 26), Position = U2(0, 5, 0, x),
			BackgroundColor3 = cl.bg3, BorderSizePixel = 0, ZIndex = 5
		})
		br(tf, nil, nil, true)

		local lbl = nil
		if y and typeof(y) == "string" then
			lbl = p("TextLabel", {
				Name = "Lbl", Parent = tf,
				Size = U2(0.4, -4, 1, -4), Position = U2(0, 4, 0, 2),
				BackgroundTransparency = 1, Text = y,
				Font = ft, TextSize = fs - 1, TextColor3 = cl.tx2,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6
			})
		end

		local xo = lbl and 0.4 or 0
		local tb = p("TextBox", {
			Name = "Tb", Parent = tf,
			Size = U2(1 - xo, -6, 1, -4), Position = U2(xo, 3, 0, 2),
			BackgroundColor3 = cl.bg, BorderSizePixel = 0,
			Text = "", PlaceholderText = "...", PlaceholderColor3 = cl.tx2,
			Font = ft, TextSize = fs, TextColor3 = cl.tx,
			ClearTextOnFocus = false, ZIndex = 6
		})
		bs(tb)

		local _ch = nil
		tb.FocusLost:Connect(function(ep)
			if _ch then _ch(tb.Text, ep) end
		end)

		local obj = {frame = tf, textbox = tb, label = lbl}
		function obj:OnChanged(fn) _ch = fn end
		function obj:GetText() return tb.Text end
		function obj:SetText(s) tb.Text = s end
		return obj

	elseif t == "label" then
		local lf = p("TextLabel", {
			Name = "Lbl", Parent = (lib._cp or g),
			Size = U2(1, -10, 0, 20), Position = U2(0, 5, 0, x),
			BackgroundTransparency = 1, Text = y or "Label",
			Font = ft, TextSize = fs - 1, TextColor3 = cl.tx2,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5
		})
		return {label = lf}

	elseif t == "checkbox" then
		local cf = p("Frame", {
			Name = "CbWrap", Parent = (lib._cp or g),
			Size = U2(1, -10, 0, 22), Position = U2(0, 5, 0, x),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5
		})
		local box = p("Frame", {
			Name = "Box", Parent = cf,
			Size = U2(0, 16, 0, 16), Position = U2(0, 0, 0, 3),
			BackgroundColor3 = cl.bg, BorderSizePixel = 0, ZIndex = 6
		})
		bs(box)
		local ck = p("Frame", {
			Name = "Check", Parent = box,
			Size = U2(0, 8, 0, 8), Position = U2(0, 4, 0, 4),
			BackgroundColor3 = cl.acc, BorderSizePixel = 0,
			Visible = false, ZIndex = 7
		})
		local cl2 = p("TextLabel", {
			Name = "Lbl", Parent = cf,
			Size = U2(1, -24, 1, 0), Position = U2(0, 22, 0, 0),
			BackgroundTransparency = 1, Text = y or "Checkbox",
			Font = ft, TextSize = fs - 1, TextColor3 = cl.tx,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6
		})
		local btn = p("TextButton", {
			Name = "Hit", Parent = cf,
			Size = U2(1, 0, 1, 0), BackgroundTransparency = 1,
			Text = "", ZIndex = 8
		})

		local st = false
		local _cb = nil
		btn.MouseButton1Click:Connect(function()
			st = not st
			ck.Visible = st
			if _cb then _cb(st) end
		end)

		local obj = {frame = cf, check = ck}
		function obj:OnToggle(fn) _cb = fn end
		function obj:GetState() return st end
		function obj:SetState(v)
			st = v
			ck.Visible = v
		end
		return obj

	elseif t == "slider" then
		local sf = p("Frame", {
			Name = "SlWrap", Parent = (lib._cp or g),
			Size = U2(1, -10, 0, 36), Position = U2(0, 5, 0, x),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5
		})
		local sl = p("TextLabel", {
			Name = "Lbl", Parent = sf,
			Size = U2(0.5, 0, 0, 14), Position = U2(0, 0, 0, 0),
			BackgroundTransparency = 1, Text = y or "Slider",
			Font = ft, TextSize = fs - 1, TextColor3 = cl.tx,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6
		})
		local sv = p("TextLabel", {
			Name = "Val", Parent = sf,
			Size = U2(0.5, 0, 0, 14), Position = U2(0.5, 0, 0, 0),
			BackgroundTransparency = 1, Text = "0",
			Font = ft, TextSize = fs - 1, TextColor3 = cl.acc,
			TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6
		})
		local trk = p("Frame", {
			Name = "Track", Parent = sf,
			Size = U2(1, 0, 0, 8), Position = U2(0, 0, 0, 18),
			BackgroundColor3 = cl.bg, BorderSizePixel = 0, ZIndex = 6
		})
		bs(trk)
		local fill = p("Frame", {
			Name = "Fill", Parent = trk,
			Size = U2(0, 0, 1, 0), BackgroundColor3 = cl.acc,
			BorderSizePixel = 0, ZIndex = 7
		})
		local knob = p("Frame", {
			Name = "Knob", Parent = trk,
			Size = U2(0, 10, 0, 14), Position = U2(0, -5, 0, -3),
			BackgroundColor3 = cl.bg3, BorderSizePixel = 0, ZIndex = 8
		})
		br(knob, nil, nil, true)

		local mn, mx, val = kc or 0, 100, 0
		if typeof(kc) == "table" then
			mn = kc[1] or 0
			mx = kc[2] or 100
			val = kc[3] or mn
		end

		local _ch = nil
		local dragging = false

		local function upd(pct)
			pct = math.clamp(pct, 0, 1)
			val = math.floor(mn + (mx - mn) * pct + 0.5)
			fill.Size = U2(pct, 0, 1, 0)
			knob.Position = U2(pct, -5, 0, -3)
			sv.Text = tostring(val)
			if _ch then _ch(val) end
		end

		local hitb = p("TextButton", {
			Name = "Hit", Parent = trk,
			Size = U2(1, 0, 1, 6), Position = U2(0, 0, 0, -3),
			BackgroundTransparency = 1, Text = "", ZIndex = 9
		})

		hitb.MouseButton1Down:Connect(function(ix, iy)
			dragging = true
			local pct = math.clamp((ix - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
			upd(pct)
		end)
		uis.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		uis.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local pct = math.clamp((i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
				upd(pct)
			end
		end)

		upd((val - mn) / math.max(mx - mn, 1))

		local obj = {frame = sf, fill = fill, knob = knob}
		function obj:OnChanged(fn) _ch = fn end
		function obj:GetValue() return val end
		function obj:SetValue(v)
			upd((v - mn) / math.max(mx - mn, 1))
		end
		return obj

	elseif t == "dropdown" then
		local df = p("Frame", {
			Name = "DdWrap", Parent = (lib._cp or g),
			Size = U2(1, -10, 0, 26), Position = U2(0, 5, 0, x),
			BackgroundColor3 = cl.bg3, BorderSizePixel = 0,
			ZIndex = 5, ClipsDescendants = false
		})
		br(df, nil, nil, true)

		local sel = p("TextButton", {
			Name = "Sel", Parent = df,
			Size = U2(1, -4, 1, -4), Position = U2(0, 2, 0, 2),
			BackgroundColor3 = cl.bg2, BorderSizePixel = 0,
			Text = y or "Select...", Font = ft, TextSize = fs,
			TextColor3 = cl.tx, ZIndex = 6, AutoButtonColor = false
		})
		bs(sel)

		local arrow = p("TextLabel", {
			Name = "Arr", Parent = sel,
			Size = U2(0, 20, 1, 0), Position = U2(1, -22, 0, 0),
			BackgroundTransparency = 1, Text = "▼",
			Font = ft, TextSize = 10, TextColor3 = cl.tx2, ZIndex = 7
		})

		local lst = p("Frame", {
			Name = "List", Parent = df,
			Size = U2(1, 0, 0, 0), Position = U2(0, 0, 1, 2),
			BackgroundColor3 = cl.bg, BorderSizePixel = 0,
			Visible = false, ZIndex = 50, ClipsDescendants = true
		})
		br(lst, nil, nil, true)

		local open = false
		local items = kc or {}
		local _ch = nil
		local cur = nil

		local function build()
			for _, c in ipairs(lst:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			for i, item in ipairs(items) do
				local ib = p("TextButton", {
					Name = "I" .. i, Parent = lst,
					Size = U2(1, -4, 0, 22), Position = U2(0, 2, 0, (i-1)*22 + 2),
					BackgroundColor3 = cl.bg2, BorderSizePixel = 0,
					Text = item, Font = ft, TextSize = fs - 1,
					TextColor3 = cl.tx, ZIndex = 51, AutoButtonColor = false
				})
				ib.MouseEnter:Connect(function()
					anim(ib, {BackgroundColor3 = cl.hov})
				end)
				ib.MouseLeave:Connect(function()
					anim(ib, {BackgroundColor3 = cl.bg2})
				end)
				ib.MouseButton1Click:Connect(function()
					cur = item
					sel.Text = item
					open = false
					lst.Visible = false
					lst.Size = U2(1, 0, 0, 0)
					if _ch then _ch(item) end
				end)
			end
			lst.Size = U2(1, 0, 0, #items * 22 + 4)
		end

		sel.MouseButton1Click:Connect(function()
			open = not open
			if open then
				build()
				lst.Visible = true
			else
				lst.Visible = false
			end
		end)

		local obj = {frame = df, selected = sel, list = lst}
		function obj:OnChanged(fn) _ch = fn end
		function obj:GetSelected() return cur end
		function obj:SetItems(tbl)
			items = tbl
			if open then build() end
		end
		return obj

	elseif t == "separator" then
		local sp = p("Frame", {
			Name = "Sep", Parent = (lib._cp or g),
			Size = U2(1, -10, 0, 6), Position = U2(0, 5, 0, x),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5
		})
		local ln1 = p("Frame", {
			Name = "L1", Parent = sp,
			Size = U2(1, 0, 0, 1), Position = U2(0, 0, 0.5, -1),
			BackgroundColor3 = cl.bd, BorderSizePixel = 0, ZIndex = 6
		})
		local ln2 = p("Frame", {
			Name = "L2", Parent = sp,
			Size = U2(1, 0, 0, 1), Position = U2(0, 0, 0.5, 0),
			BackgroundColor3 = cl.bl, BorderSizePixel = 0, ZIndex = 6
		})
		return {frame = sp}
	end
end

function lib.setParent(cont)
	lib._cp = cont
end

function lib.destroy()
	for _, v in ipairs(_r) do
		if v and v.Parent then v:Destroy() end
	end
	_r = {}
	_k = {}
end

function lib.hideAll()
	for _, v in ipairs(_r) do v.Enabled = false end
end

function lib.showAll()
	for _, v in ipairs(_r) do v.Enabled = true end
end

function lib.toggleAll()
	for _, v in ipairs(_r) do v.Enabled = not v.Enabled end
end

uis.InputBegan:Connect(function(i, gpe)
	if gpe then return end
	if i.UserInputType == Enum.UserInputType.Keyboard then
		local sg = _k[i.KeyCode]
		if sg then sg.Enabled = not sg.Enabled end
	end
end)

lib.sensitive = false
lib._version = "1.0.0-hl1"

function lib.enableSensitive()
	lib.sensitive = true
	local mt = getrawmetatable(lib)
	if mt then
		local old = mt.__index
		hookmetamethod(lib, "__index", function(s, k)
			if k == "_version" then return "1.0.0-hl1" end
			if old then return old(s, k) end
			return nil
		end)
	end
end

return lib
