-- ✅ Gunfight Arena Script với UI đơn giản (Aimbot Settings, ESP Settings, Extras)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    Aimbot = false,
    AimbotAlways = false,
    AimbotSpeed = 1,
    AimbotPrediction = false,
    AimbotFOV = 150,
    AimbotTarget = "Head",
    AimbotVisibility = true,

    ESP = false,
    PlayerESP = false,
    BotESP = false,
    DrawNames = false,
    DrawTeam = false,

    HitboxExpander = false,
    LowGravity = false,
    Fly = false
}

-- UI Menu đơn giản bằng nút bấm
local function createToggle(text, default, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 200, 0, 25)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 18
    button.Text = text .. ": OFF"
    button.Parent = screenGui
    local state = default
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = text .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "SimpleHackMenu"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 300)
frame.Position = UDim2.new(0, 20, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder

createToggle("Aimbot", Settings.Aimbot, function(v) Settings.Aimbot = v end)
createToggle("ESP", Settings.ESP, function(v) Settings.ESP = v end)
createToggle("Low Gravity", Settings.LowGravity, function(v) Settings.LowGravity = v end)

-- FOV Circle
local Circle = Drawing.new("Circle")
Circle.Thickness = 2
Circle.Filled = false
Circle.Transparency = 1
Circle.Color = Color3.fromRGB(255, 255, 0)
Circle.Visible = true
Circle.Radius = Settings.AimbotFOV

local espCache = {}

local function getClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (Settings.DrawTeam or plr.Team ~= LocalPlayer.Team) and plr.Character and plr.Character:FindFirstChild(Settings.AimbotTarget) then
            local part = plr.Character[Settings.AimbotTarget]
            local pos, visible = Camera:WorldToViewportPoint(part.Position)
            if visible or not Settings.AimbotVisibility then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortest and dist < Settings.AimbotFOV then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function createESP(plr)
    if not espCache[plr] then
        espCache[plr] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Line = Drawing.new("Line"),
            Distance = Drawing.new("Text")
        }
        for _, obj in pairs(espCache[plr]) do
            obj.Visible = false
            obj.Outline = true
            obj.Transparency = 1
            if obj:IsA("Text") then
                obj.Size = 13
                obj.Center = true
                obj.Font = 2
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    Circle.Radius = Settings.AimbotFOV
    Circle.Visible = Settings.Aimbot

    if Settings.Aimbot and (Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild(Settings.AimbotTarget) then
            local aimPos = target.Character[Settings.AimbotTarget].Position
            if Settings.AimbotPrediction then
                local velocity = target.Character["HumanoidRootPart"] and target.Character.HumanoidRootPart.Velocity or Vector3.new()
                aimPos = aimPos + velocity * 0.1
            end
            local dir = (aimPos - Camera.CFrame.Position).Unit
            local newCF = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, Settings.AimbotSpeed * 0.1)
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("HumanoidRootPart") then
            local isEnemy = (plr.Team ~= LocalPlayer.Team)
            if (Settings.PlayerESP and isEnemy) or (Settings.DrawTeam and not isEnemy) then
                createESP(plr)
                local head = plr.Character.Head
                local root = plr.Character.HumanoidRootPart
                local pos, visible = Camera:WorldToViewportPoint(head.Position)
                if visible and Settings.ESP then
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    local size = Vector2.new(50, 100) / dist * 20

                    local box = espCache[plr].Box
                    box.Size = size
                    box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                    box.Color = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                    box.Visible = true

                    if Settings.DrawNames then
                        local name = espCache[plr].Name
                        name.Text = plr.Name
                        name.Position = Vector2.new(pos.X, pos.Y - size.Y/2 - 15)
                        name.Color = Color3.fromRGB(0, 255, 255)
                        name.Visible = true
                    end

                    local line = espCache[plr].Line
                    line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Color = Color3.fromRGB(255, 255, 255)
                    line.Thickness = 1
                    line.Visible = true

                    local disText = espCache[plr].Distance
                    disText.Text = string.format("%.0fm", dist)
                    disText.Position = Vector2.new(pos.X, pos.Y + size.Y/2 + 10)
                    disText.Color = Color3.fromRGB(0, 255, 0)
                    disText.Visible = true
                else
                    for _, obj in pairs(espCache[plr]) do obj.Visible = false end
                end
            elseif espCache[plr] then
                for _, obj in pairs(espCache[plr]) do obj.Visible = false end
            end
        end
    end

    if Settings.LowGravity then
        workspace.Gravity = 50
    else
        workspace.Gravity = 196.2
    end
end)

print("✅ Gunfight Arena Script loaded with GUI toggles!")
