-- ✅ Gunfight Arena Script với UI nâng cao (Aimbot Settings, ESP Settings, Extras)

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
    PlayerESP = true,
    BotESP = false,
    DrawNames = true,
    DrawTeam = false,

    HitboxExpander = false,
    LowGravity = false,
    Fly = false
}

-- UI Setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GunfightArenaUI"
local Frame = Instance.new("Frame", ScreenGui)
Frame.Position = UDim2.new(0.7, 0, 0.3, 0)
Frame.Size = UDim2.new(0, 300, 0, 400)
Frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
Frame.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Gunfight Arena HUB"
Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

local function createToggle(name, y, settingKey)
    local Button = Instance.new("TextButton", Frame)
    Button.Position = UDim2.new(0, 10, 0, y)
    Button.Size = UDim2.new(0, 280, 0, 30)
    Button.Text = name .. ": OFF"
    Button.TextColor3 = Color3.new(1,1,1)
    Button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    Button.Font = Enum.Font.SourceSans
    Button.TextSize = 16
    Button.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        Button.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    end)
end

createToggle("Aimbot", 40, "Aimbot")
createToggle("Aimbot Always", 75, "AimbotAlways")
createToggle("Aimbot Prediction", 110, "AimbotPrediction")
createToggle("ESP Player", 145, "PlayerESP")
createToggle("Draw Names", 180, "DrawNames")
createToggle("Draw Team", 215, "DrawTeam")
createToggle("Low Gravity", 250, "LowGravity")
createToggle("Fly", 285, "Fly")

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
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild(Settings.AimbotTarget) then
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

RunService.RenderStepped:Connect(function()
    -- FOV Circle Update
    Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    Circle.Radius = Settings.AimbotFOV
    Circle.Visible = Settings.Aimbot

    -- Aimbot
    if Settings.Aimbot and (Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        local target = getClosestEnemy()
        if target and target.Team ~= LocalPlayer.Team and target.Character and target.Character:FindFirstChild(Settings.AimbotTarget) then
            local aimPos = target.Character[Settings.AimbotTarget].Position
            if Settings.AimbotPrediction then
                local velocity = target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Velocity or Vector3.new()
                aimPos = aimPos + velocity * 0.1
            end
            local dir = (aimPos - Camera.CFrame.Position).Unit
            local newCF = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, Settings.AimbotSpeed * 0.1)
        end
    end

    -- ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("HumanoidRootPart") then
            local isEnemy = (plr.Team ~= LocalPlayer.Team)
            if (Settings.PlayerESP and isEnemy) or (Settings.DrawTeam and not isEnemy) then
                if not espCache[plr] then
                    espCache[plr] = {
                        Name = Drawing.new("Text"),
                        Box = Drawing.new("Square")
                    }
                    espCache[plr].Name.Size = 13
                    espCache[plr].Name.Center = true
                    espCache[plr].Name.Font = 2
                    espCache[plr].Name.Color = Color3.new(1, 1, 1)
                    espCache[plr].Name.Outline = true
                    espCache[plr].Box.Color = Color3.fromRGB(0,255,0)
                    espCache[plr].Box.Thickness = 1
                    espCache[plr].Box.Filled = false
                end
                local head = plr.Character.Head
                local root = plr.Character.HumanoidRootPart
                local pos, visible = Camera:WorldToViewportPoint(head.Position)
                if visible and Settings.ESP then
                    espCache[plr].Name.Text = plr.Name
                    espCache[plr].Name.Position = Vector2.new(pos.X, pos.Y - 15)
                    espCache[plr].Name.Visible = Settings.DrawNames

                    local size = Vector2.new(50, 100) / (root.Position - Camera.CFrame.Position).Magnitude * 5
                    local screenPos = Camera:WorldToViewportPoint(root.Position)
                    espCache[plr].Box.Size = size
                    espCache[plr].Box.Position = Vector2.new(screenPos.X - size.X/2, screenPos.Y - size.Y/2)
                    espCache[plr].Box.Visible = true
                else
                    espCache[plr].Name.Visible = false
                    espCache[plr].Box.Visible = false
                end
            elseif espCache[plr] then
                espCache[plr].Name.Visible = false
                espCache[plr].Box.Visible = false
            end
        end
    end

    -- Gravity
    workspace.Gravity = Settings.LowGravity and 50 or 196.2

    -- Fly
    if Settings.Fly then
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 50, 0)
    end
end)

print("✅ Gunfight Arena Script UI loaded")
