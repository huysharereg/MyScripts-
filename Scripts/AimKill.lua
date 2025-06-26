-- ✅ Script Aimbot + ESP + UI toggle for Gun Fight Arena by HuyMod

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local LocalTeam = LocalPlayer.Team

-- Settings
local Settings = {
    FOV = 120,
    Aimbot = false,
    ESP = false,
    AutoShoot = false,
    AimPart = "Head"
}

-- FOV Circle
local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.Color = Color3.fromRGB(0,255,0)
circle.Filled = false
circle.Transparency = 0.5
circle.Visible = true
circle.Radius = Settings.FOV

-- Aim Line
local line = Drawing.new("Line")
line.Thickness = 1
line.Color = Color3.fromRGB(255,0,0)
line.Transparency = 0.7
line.Visible = false

-- UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "GunFightUI"

local frame = Instance.new("Frame", gui)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.Size = UDim2.new(0, 180, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "🎯 GunFight Arena Hack"
title.TextColor3 = Color3.fromRGB(0,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

function makeBtn(text, y, toggleVar)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.Text = text .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[toggleVar] = not Settings[toggleVar]
        btn.Text = text .. ": " .. (Settings[toggleVar] and "ON" or "OFF")
    end)
end

makeBtn("Toggle Aimbot", 40, "Aimbot")
makeBtn("Toggle ESP", 75, "ESP")
makeBtn("Toggle AutoShoot", 110, "AutoShoot")

-- Get enemy heads
function GetEnemies()
    local targets = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == Settings.AimPart then
            local model = obj:FindFirstAncestorOfClass("Model")
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            local teamVal = model and model:FindFirstChild("Team")
            if humanoid and humanoid.Health > 0 and teamVal and teamVal.Value ~= LocalTeam then
                table.insert(targets, obj)
            end
        end
    end
    return targets
end

-- Get closest to mouse
function GetClosest()
    local closest, minDist = nil, Settings.FOV
    for _, head in pairs(GetEnemies()) do
        local pos, visible = Camera:WorldToViewportPoint(head.Position)
        if visible then
            local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
            if dist < minDist then
                closest = head
                minDist = dist
            end
        end
    end
    return closest
end

-- Add ESP
function AddESP(part)
    if not part or part:FindFirstChild("ESP") then return end
    local gui = Instance.new("BillboardGui", part)
    gui.Name = "ESP"
    gui.Size = UDim2.new(0, 100, 0, 40)
    gui.AlwaysOnTop = true

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = part.Parent.Name
    label.TextColor3 = Color3.new(1, 0, 0)
    label.TextScaled = true
end

-- Main loop
RunService.RenderStepped:Connect(function()
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV

    -- ESP
    if Settings.ESP then
        for _, head in pairs(GetEnemies()) do
            AddESP(head)
        end
    else
        -- Remove all ESP
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("Head") then
                local esp = plr.Character.Head:FindFirstChild("ESP")
                if esp then esp:Destroy() end
            end
        end
    end

    -- Aimbot
    local target = GetClosest()
    if Settings.Aimbot and target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        local screenPos = Camera:WorldToViewportPoint(target.Position)
        line.Visible = true
        line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        line.To = Vector2.new(screenPos.X, screenPos.Y)
        if Settings.AutoShoot then mouse1click() end
    else
        line.Visible = false
    end
end)
