-- Bắt đầu
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Teams = game:GetService("Teams")

-- Giao diện UI Orion
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local Window = OrionLib:MakeWindow({Name = "Gunfight Arena Hub", HidePremium = false, SaveConfig = false, ConfigFolder = "GunfightHub"})

-- Settings
local Settings = {
    SilentAim = false,
    ESP = false,
    KillAura = false,
    KillAuraRange = 50
}

-- Tabs
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- Toggle UI
MainTab:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Callback = function(Value)
        Settings.SilentAim = Value
    end
})

MainTab:AddToggle({
    Name = "ESP (Box, Name, HP, Distance)",
    Default = false,
    Callback = function(Value)
        Settings.ESP = Value
    end
})

MainTab:AddToggle({
    Name = "Kill Aura (Auto Kill)",
    Default = false,
    Callback = function(Value)
        Settings.KillAura = Value
    end
})

MainTab:AddSlider({
    Name = "Kill Aura Range",
    Min = 10,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(Value)
        Settings.KillAuraRange = Value
    end
})

-- ESP Data
local espData = {}

local function setupESP(p)
    if espData[p] then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(0, 255, 0)

    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)

    espData[p] = {Box = box, Line = line, Text = name}
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then setupESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then setupESP(p) end
end)

-- Gần nhất
local function getClosestEnemy()
    local closest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local screenPos = Vector2.new(pos.X, pos.Y)
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local diff = (screenPos - center).Magnitude
                if diff < dist then
                    dist = diff
                    closest = p
                end
            end
        end
    end
    return closest
end

-- Hook Silent Aim
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if (Settings.SilentAim and method == "FireServer") and (tostring(self):lower():find("shoot") or tostring(self):lower():find("sync")) then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            args[2] = target.Character.Head.CFrame
            return old(self, unpack(args))
        end
    end

    return old(self, ...)
end)

-- Loop ESP + KillAura
RunService.RenderStepped:Connect(function()
    for player, d in pairs(espData) do
        local char = player.Character
        if Settings.ESP and player.Team ~= LocalPlayer.Team and char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") then
            local pos, visible = Camera:WorldToViewportPoint(char.Head.Position)
            if visible then
                -- Box
                d.Box.Position = Vector2.new(pos.X - 25, pos.Y - 50)
                d.Box.Size = Vector2.new(50, 100)
                d.Box.Visible = true

                -- Line
                d.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                d.Line.To = Vector2.new(pos.X, pos.Y)
                d.Line.Visible = true

                -- Text
                local hp = math.floor(char:FindFirstChild("Humanoid").Health)
                local dist = math.floor((char.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                d.Text.Text = string.format("%s [%dhp | %dm]", player.Name, hp, dist)
                d.Text.Position = Vector2.new(pos.X, pos.Y - 60)
                d.Text.Visible = true
            else
                d.Box.Visible = false
                d.Line.Visible = false
                d.Text.Visible = false
            end
        else
            d.Box.Visible = false
            d.Line.Visible = false
            d.Text.Visible = false
        end
    end

    -- Kill Aura
    if Settings.KillAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist <= Settings.KillAuraRange then
                    for _, remote in pairs(LocalPlayer:GetDescendants()) do
                        if remote:IsA("RemoteEvent") and tostring(remote):lower():find("shoot") then
                            remote:FireServer(nil, p.Character.Head.CFrame)
                        end
                    end
                end
            end
        end
    end
end)

-- UI Start
OrionLib:Init()
