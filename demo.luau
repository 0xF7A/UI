local HubUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/0xF7A/UI/refs/heads/main/module.luau"))()

local window = HubUI.new("Dawg", 480, 340)

local mainTab = window:addTab("Tab1")
local espTab  = window:addTab("Tab2")

local general = mainTab:addSection("General")

general:addToggle("God Mode", false, function(v)
    print("God Mode:", v)
end)

general:addSlider("Walk Speed", 0, 100, 16, function(v)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
end)

general:addButton("Teleport to Spawn", function()
    print("Teleporting!")
end)

general:addDropdown("Team", {"Red", "Blue", "Green"}, "Red", function(v)
    print("Selected:", v)
end)

general:addKeybind("Toggle UI", Enum.KeyCode.RightShift, function(key)
    print("Key set to:", key.Name)
end)

general:addTextbox("Custom Name", "Enter name...", function(text, entered)
    print("Name:", text)
end)

window:notify("Welcome", "Hub loaded successfully!", 3)
