-- 📦 Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ Settings
local SETTINGS = {
    SilentAim = false,
    KillAura = false,
    ESP = false,
    KillAuraRange = 100
}

-- 🧠 Function: Kiểm tra có phải địch không
local function IsEnemy(player)
    return player ~= LocalPlayer
        and player.Team ~= nil
        and LocalPlayer.Team ~= nil
        and player.Team ~= LocalPlayer.Team
        and player.Character
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

-- 📌 Lấy địch gần nhất có LineOfSight
local function GetClosestEnemy()
    local closest = nil
    local minDist = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if IsEnemy(player) and player.Character and player.Character:FindFirstChild("Head") then
            local screenPos, visible = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if visible then
                local distance = (UserInputService:GetMouseLocation() - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if distance < minDist then
                    minDist = distance
                    closest = player
                end
            end
        end
    end
    return closest
end

-- 🧠 Hook Silent Aim
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if tostring(self) == "Sync" and method == "Fire" and SETTINGS.SilentAim then
        local closest = GetClosestEnemy()
        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            args[2] = closest.Character.Head.CFrame
            return old(self, unpack(args))
        end
    end

    return old(self, ...)
end)

-- 🎯 ESP System
local ESP_DRAWINGS = {}

local function CreateESP(player)
    if ESP_DRAWINGS[player] then return end

    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 1
    box.Filled = false

    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(0, 255, 0)
    line.Thickness = 1

    local name = Drawing.new("Text")
    name.Color = Color3.new(1, 1, 1)
    name.Size = 13
    name.Center = true
    name.Outline = true

    ESP_DRAWINGS[player] = {Box = box, Line = line, Name = name}
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if IsEnemy(player) then
            CreateESP(player)
        end
    end

    for player, draw in pairs(ESP_DRAWINGS) do
        if SETTINGS.ESP and IsEnemy(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            if head then
                local pos, visible = Camera:WorldToViewportPoint(root.Position)
                if visible then
                    draw.Box.Size = Vector2.new(60, 100)
                    draw.Box.Position = Vector2.new(pos.X - 30, pos.Y - 60)
                    draw.Box.Visible = true

                    draw.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    draw.Line.To = Vector2.new(pos.X, pos.Y)
                    draw.Line.Visible = true

                    local dist = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                    local hp = math.floor(player.Character.Humanoid.Health)
                    draw.Name.Text = string.format("%s [%dhp | %dm]", player.Name, hp, dist)
                    draw.Name.Position = Vector2.new(pos.X, pos.Y - 70)
                    draw.Name.Visible = true
                else
                    draw.Box.Visible = false
                    draw.Line.Visible = false
                    draw.Name.Visible = false
                end
            end
        else
            if draw.Box then draw.Box.Visible = false end
            if draw.Line then draw.Line.Visible = false end
            if draw.Name then draw.Name.Visible = false end
        end
    end
end

-- ⚔️ Kill Aura
local function DoKillAura()
    for _, player in pairs(Players:GetPlayers()) do
        if IsEnemy(player) and player.Character and player.Character:FindFirstChild("Head") then
            local dist = (player.Character.Head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if dist <= SETTINGS.KillAuraRange then
                local sync = LocalPlayer:FindFirstChild("Sync") or ReplicatedStorage:FindFirstChild("Sync")
                if sync then
                    sync:Fire(sync, player.Name .. "_shoot", nil, player.Character.Head.CFrame, math.random(), "Gun", {})
                end
            end
        end
    end
end

-- 🔁 Main Loop
RunService.RenderStepped:Connect(function()
    if SETTINGS.ESP then UpdateESP() end
    if SETTINGS.KillAura then DoKillAura() end
end)

-- 🧩 UI (Orion)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local Window = OrionLib:MakeWindow({Name = "Gunfight Arena | HuyScript", HidePremium = false, SaveConfig = false, ConfigFolder = "GunfightConfig"})

local MainTab = Window:MakeTab({Name = "Main", Icon = "", PremiumOnly = false})

MainTab:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Callback = function(v) SETTINGS.SilentAim = v end
})

MainTab:AddToggle({
    Name = "Kill Aura (AutoKill)",
    Default = false,
    Callback = function(v) SETTINGS.KillAura = v end
})

MainTab:AddToggle({
    Name = "ESP (Box, Name, Line)",
    Default = false,
    Callback = function(v) SETTINGS.ESP = v end
})

MainTab:AddSlider({
    Name = "Kill Aura Range",
    Min = 20,
    Max = 200,
    Default = 100,
    Callback = function(v) SETTINGS.KillAuraRange = v end
})

OrionLib:Init()
