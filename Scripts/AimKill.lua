-- Gunfight Arena: Silent Aim + ESP Full + Kill Aura + UI by ChatGPT

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    SilentAim = false,
    ESP = false,
    KillAura = false,
    KillAuraRange = 50
}

-- __namecall hook for silent aim
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if Settings.SilentAim and method == "FireServer" and tostring(self):lower():find("shoot") then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            args[1] = target.Character.Head.Position
            return old(self, unpack(args))
        end
    end

    return old(self, ...)
end)

function getClosestEnemy()
    local closest, dist = nil, math.huge
    local mpos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local screenPos, visible = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if visible then
                local diff = (Vector2.new(screenPos.X, screenPos.Y) - mpos).Magnitude
                if diff < dist then
                    dist = diff
                    closest = p
                end
            end
        end
    end
    return closest
end

-- ESP Drawing
local espData = {}

function setupESP(p)
    if espData[p] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(0, 255, 0)

    local name = Drawing.new("Text")
    name.Size = 14
    name.Color = Color3.new(1, 1, 1)
    name.Center = true
    name.Outline = true

    espData[p] = { box = box, line = line, name = name }
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then setupESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then setupESP(p) end
end)

RunService.RenderStepped:Connect(function()
    for p, d in pairs(espData) do
        if Settings.ESP and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, visible = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if visible then
                -- box
                d.box.Size = Vector2.new(50, 100)
                d.box.Position = Vector2.new(pos.X - 25, pos.Y - 50)
                d.box.Visible = true

                -- line
                d.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                d.line.To = Vector2.new(pos.X, pos.Y)
                d.line.Visible = true

                -- name (with HP & Distance)
                local hp = math.floor(p.Character.Humanoid.Health)
                local dist = math.floor((p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                d.name.Text = string.format("%s [%dhp | %dm]", p.Name, hp, dist)
                d.name.Position = Vector2.new(pos.X, pos.Y - 60)
                d.name.Visible = true
            else
                d.box.Visible = false
                d.line.Visible = false
                d.name.Visible = false
            end
        else
            d.box.Visible = false
            d.line.Visible = false
            d.name.Visible = false
        end
    end

    -- Kill Aura
    if Settings.KillAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if d <= Settings.KillAuraRange then
                    local ev = LocalPlayer:FindFirstChildWhichIsA("RemoteEvent", true)
                    if ev and tostring(ev):lower():find("shoot") then
                        ev:FireServer(p.Character.Head.Position)
                    end
                end
            end
        end
    end
end)

-- UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 140)
Main.Position = UDim2.new(0, 100, 0, 100)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.Active = true
Main.Draggable = true

local function makeButton(text, y, toggle)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.MouseButton1Click:Connect(function()
        Settings[toggle] = not Settings[toggle]
        btn.Text = text .. ": " .. (Settings[toggle] and "ON" or "OFF")
    end)
end

makeButton("Silent Aim", 10, "SilentAim")
makeButton("ESP", 50, "ESP")
makeButton("Kill Aura", 90, "KillAura")

-- Minimize button
local mini = Instance.new("TextButton", ScreenGui)
mini.Text = "≡"
mini.Size = UDim2.new(0, 30, 0, 30)
mini.Position = UDim2.new(0, 10, 0, 10)
mini.Visible = false
mini.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
mini.MouseButton1Click:Connect(function()
    Main.Visible = true
    mini.Visible = false
end)

local minBtn = Instance.new("TextButton", Main)
minBtn.Text = "_"
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -25, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    mini.Visible = true
end)
