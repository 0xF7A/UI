# UI Module — Documentation

> flat cheat GUI library for Roblox Luau executors.

---

## Quick Start

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/0xF7A/UI/refs/heads/main/module.luau"))()

local hub = UI.new("my cheat", 520, 380)

local tab = hub:addTab("AIMBOT")
local section = tab:addSection("Settings")

section:addToggle("Enabled", false, function(state)
    print("aimbot:", state)
end)

section:addSlider("FOV", 0, 360, 120, function(val)
    print("fov:", val)
end)

section:addKeybind("Toggle Key", Enum.KeyCode.F, function(key)
    print("bound to:", key.Name)
end)
```

---

## API Reference

### `HubUI.new(title, width?, height?)`

Creates and shows the window.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `title` | `string` | *required* | Window title (shown in title bar) |
| `width` | `number` | `520` | Window width in pixels |
| `height` | `number` | `380` | Window height in pixels |

**Returns:** `HubUI` instance

```lua
local hub = UI.new("sense", 520, 380)
```

---

### `HubUI:addTab(name, icon?)`

Adds a horizontal top tab.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | *required* | Tab label (auto-uppercased) |
| `icon` | `string?` | `nil` | File path for icon via `getcustomasset()` |

**Returns:** `Tab` object

```lua
local tab = hub:addTab("VISUALS", "icons/eye.png")
```

---

### `HubUI:selectTab(tab)`

Programmatically switches to a tab. Called automatically for the first tab added.

---

### `HubUI:toggle()`

Toggles window visibility. Bind to a key for show/hide.

```lua
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        hub:toggle()
    end
end)
```

---

### `HubUI:destroy()`

Fades out and destroys the entire UI. Disconnects all events, destroys the ScreenGui.

---

### `HubUI:notify(title, message, duration?)`

Shows a slide-in notification in the bottom-right corner.

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `title` | `string` | *required* | Notification header |
| `message` | `string` | *required* | Notification body |
| `duration` | `number` | `3` | Seconds before auto-dismiss |

```lua
hub:notify("aimbot", "target locked", 2)
```

---

## Tab Methods

### `Tab:addSection(name)`

Creates a groupbox inside the tab page.

**Returns:** `Section` object

```lua
local section = tab:addSection("Targeting")
```

---

## Section Widgets

### `Section:addToggle(label, default, callback)`

Checkbox toggle (square, CS:GO style).

| Param | Type | Description |
|-------|------|-------------|
| `label` | `string` | Display text |
| `default` | `boolean` | Initial state |
| `callback` | `(state: boolean) -> ()` | Called on toggle |

**Returns:** `{ set(self, bool), get() -> bool }`

```lua
local aimbot = section:addToggle("Aimbot", false, function(state)
    Settings.aimbot = state
end)

-- programmatic control
aimbot:set(true)
print(aimbot:get()) -- true
```

---

### `Section:addSlider(label, min, max, default, callback)`

Flat slider with square thumb and numeric display.

| Param | Type | Description |
|-------|------|-------------|
| `label` | `string` | Display text |
| `min` | `number` | Minimum value |
| `max` | `number` | Maximum value |
| `default` | `number` | Initial value |
| `callback` | `(value: number) -> ()` | Called on change |

**Returns:** `{ set(self, number), get() -> number }`

```lua
local fov = section:addSlider("FOV", 0, 360, 120, function(val)
    Settings.fov = val
end)
```

---

### `Section:addButton(label, callback)`

Flat button with red hover effect.

| Param | Type | Description |
|-------|------|-------------|
| `label` | `string` | Button text |
| `callback` | `() -> ()` | Called on click |

```lua
section:addButton("Reset All", function()
    -- reset logic
end)
```

---

### `Section:addDropdown(label, options, default, callback)`

Dropdown selector with expandable option list.

| Param | Type | Description |
|-------|------|-------------|
| `label` | `string` | Display text |
| `options` | `{string}` | Array of choices |
| `default` | `string?` | Initial selection (defaults to first) |
| `callback` | `(selected: string) -> ()` | Called on change |

**Returns:** `{ set(self, string), get() -> string }`

```lua
local bone = section:addDropdown("Target Bone",
    {"Head", "Chest", "Pelvis"}, "Head",
    function(opt)
        Settings.bone = opt
    end
)
```

---

### `Section:addTextbox(label, placeholder, callback)`

Text input field with accent border on focus.

| Param | Type | Description |
|-------|------|-------------|
| `label` | `string` | Display text |
| `placeholder` | `string?` | Placeholder text |
| `callback` | `(text: string, enterPressed: boolean) -> ()` | Called on focus lost |

```lua
section:addTextbox("Player Name", "username...", function(text, enter)
    if enter then print("searching:", text) end
end)
```

---

### `Section:addKeybind(label, default, callback)`

Keybind picker — displays as `[KeyName]`, click to rebind.

| Param | Type | Description |
|-------|------|-------------|
| `label` | `string` | Display text |
| `default` | `Enum.KeyCode?` | Initial key |
| `callback` | `(key: Enum.KeyCode) -> ()` | Called on rebind |

**Returns:** `{ get() -> Enum.KeyCode }`

```lua
local toggleKey = section:addKeybind("Toggle Key", Enum.KeyCode.F, function(key)
    print("new key:", key.Name)
end)
```

---

### `Section:addLabel(text, color?)`

Static text label. Supports RichText.

**Returns:** `{ set(self, string) }`

```lua
local status = section:addLabel("status: idle")
status:set("status: <font color='#34C759'>active</font>")
```

---

### `Section:addColorPicker(label, default, callback)`

Inline color preview square.

| Param | Type | Description |
|-------|------|-------------|
| `label` | `string` | Display text |
| `default` | `Color3?` | Initial color |
| `callback` | `(color: Color3) -> ()` | Called on change |

**Returns:** `{ set(self, Color3), get() -> Color3 }`

```lua
local espColor = section:addColorPicker("ESP Color",
    Color3.fromRGB(255, 0, 0),
    function(color)
        Settings.espColor = color
    end
)
```

---

## Stealth Features

| Feature | Description |
|---------|-------------|
| **Random instance names** | Every `Instance.new()` gets a random lowercase name |
| **Multi-fallback parenting** | `gethui()` → `syn.protect_gui` + CoreGui → CoreGui → PlayerGui |
| **pcall everywhere** | All callbacks, instance creation, and property access wrapped |
| **Connection tracking** | All `.Connect()` calls stored and cleaned up on `:destroy()` |
| **Draggable fallback** | Manual drag impl if `.Draggable` is unavailable |

---

## Color Palette

All colors are exposed in the `COLORS` table at the top of the module:

| Key | RGB | Usage |
|-----|-----|-------|
| `bg` | `12, 12, 12` | Window body |
| `titlebar` | `18, 18, 18` | Header bar |
| `accent` | `170, 40, 40` | Red accent (toggles, sliders, active highlights) |
| `text` | `200, 200, 200` | Primary text |
| `subtext` | `120, 120, 120` | Secondary / inactive text |
| `border` | `40, 40, 40` | All border strokes |
| `element` | `24, 24, 24` | Control backgrounds |
| `check` | `170, 40, 40` | Filled checkbox |
| `checkOff` | `30, 30, 30` | Empty checkbox |

To change the accent color, modify `COLORS.accent`, `COLORS.accentHov`, `COLORS.sliderFill`, and `COLORS.check`.

---

## Full Example

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/0xF7A/UI/refs/heads/main/module.luau"))()
local hub = UI.new("sense v2", 520, 380)

-- Aimbot tab
local aim = hub:addTab("AIMBOT")
local s1 = aim:addSection("Targeting")
s1:addToggle("Enabled", false, function(v) end)
s1:addSlider("FOV", 0, 360, 120, function(v) end)
s1:addDropdown("Bone", {"Head", "Chest"}, "Head", function(v) end)
s1:addKeybind("Toggle", Enum.KeyCode.F, function(k) end)

-- Visuals tab
local vis = hub:addTab("VISUALS")
local s2 = vis:addSection("ESP")
s2:addToggle("Box ESP", false, function(v) end)
s2:addToggle("Name ESP", true, function(v) end)
s2:addColorPicker("ESP Color", Color3.fromRGB(255, 0, 0), function(c) end)
s2:addSlider("Max Distance", 100, 2000, 500, function(v) end)

-- Misc tab
local misc = hub:addTab("MISC")
local s3 = misc:addSection("Settings")
s3:addButton("Reset Config", function() end)
s3:addTextbox("Webhook URL", "https://...", function(t, e) end)
s3:addLabel("build: 2.0.0")

-- Toggle keybind
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        hub:toggle()
    end
end)

hub:notify("loaded", "press RightShift to toggle", 3)
```
