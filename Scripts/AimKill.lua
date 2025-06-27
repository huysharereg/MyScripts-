local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Teams = game:GetService("Teams")

local Settings = {
    SilentAim = true,
    ESP = true,
    KillAura = true,
    KillAuraRange = 50
}

-- 🔍 Get Closest Enemy
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

-- 🧠 Silent Aim Hook
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if (Settings.SilentAim and method == "FireServer") and (tostring(self):lower():find("shoot") or tostring(self):lower():find("sync")) then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            args[2] = target.Character.Head.CFrame -- đây là pos/cframe trong nhiều game
            return old(self, unpack(args))
        end
    end

    return old(self, ...)
end)

-- 📦 ESP setup
local espData = {}

local function setupESP(player)
    if espData[player] then return end
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(0, 255, 0)

    local text = Drawing.new("Text")
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.Color = Color3.fromRGB(255, 255, 255)

    espData[player] = {Box = box, Line = line, Text = text}
end

-- ESP add for current and future players
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then setupESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then setupESP(p) end
end)

-- 🔁 ESP + Kill Aura loop
RunService.RenderStepped:Connect(function()
    for player, drawings in pairs(espData) do
        local char = player.Character
        if Settings.ESP and char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") and player.Team ~= LocalPlayer.Team then
            local pos, visible = Camera:WorldToViewportPoint(char.Head.Position)
            if visible then
                -- ESP Box
                drawings.Box.Position = Vector2.new(pos.X - 25, pos.Y - 50)
                drawings.Box.Size = Vector2.new(50, 100)
                drawings.Box.Visible = true

                -- ESP Line
                drawings.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                drawings.Line.To = Vector2.new(pos.X, pos.Y)
                drawings.Line.Visible = true

                -- ESP Text
                local hp = math.floor(char:FindFirstChild("Humanoid").Health)
                local dist = math.floor((char.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                drawings.Text.Text = string.format("%s [%dhp | %dm]", player.Name, hp, dist)
                drawings.Text.Position = Vector2.new(pos.X, pos.Y - 60)
                drawings.Text.Visible = true
            else
                drawings.Box.Visible = false
                drawings.Line.Visible = false
                drawings.Text.Visible = false
            end
        else
            drawings.Box.Visible = false
            drawings.Line.Visible = false
            drawings.Text.Visible = false
        end
    end

    -- ⚔ Kill Aura
    if Settings.KillAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist <= Settings.KillAuraRange then
                    -- Gọi Remote để bắn
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
