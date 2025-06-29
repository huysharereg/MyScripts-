-- ⚙️ SETUP
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

-- ⚙️ SETTINGS
local Settings = {
    AimbotEnabled = true,
    AimbotAlways = false, -- false = chỉ khi nhấn chuột phải
    AimbotFOV = 120,
    AimbotPart = "Head", -- Head, HumanoidRootPart, v.v.
    AimbotPrediction = true,
    AimbotSpeed = 5, -- càng cao càng chậm

    ESPEnabled = true,
    DrawTeam = false -- true = hiện đồng đội, false = chỉ hiện địch
}

-- 🎯 FUNCTION: Get closest enemy
local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if not Settings.DrawTeam and player.Team == LocalPlayer.Team then continue end
            local part = player.Character:FindFirstChild(Settings.AimbotPart)
            if part then
                local pos, visible = Camera:WorldToViewportPoint(part.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < shortest and dist <= Settings.AimbotFOV then
                        closest = part
                        shortest = dist
                    end
                end
            end
        end
    end
    return closest
end

-- 🎯 Aimbot (Camera LookAt)
RunService.RenderStepped:Connect(function()
    if not Settings.AimbotEnabled then return end

    local aiming = Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if aiming then
        local targetPart = GetClosestEnemy()
        if targetPart then
            local targetPos = targetPart.Position
            if Settings.AimbotPrediction and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
                local vel = targetPart.Parent.HumanoidRootPart.Velocity
                targetPos = targetPos + (vel * 0.035)
            end

            local current = Camera.CFrame.Position
            local direction = (targetPos - current).Unit
            local newLook = CFrame.lookAt(current, current + direction)
            Camera.CFrame = Camera.CFrame:Lerp(newLook, 1 / Settings.AimbotSpeed)
        end
    end
end)

-- 👁️ ESP (Drawing API)
local espObjects = {}

RunService.RenderStepped:Connect(function()
    -- Clear
    for _, obj in pairs(espObjects) do
        obj.Visible = false
    end

    if not Settings.ESPEnabled then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if not Settings.DrawTeam and player.Team == LocalPlayer.Team then continue end

            local head = player.Character.Head
            local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local text = espObjects[player]
                if not text then
                    text = Drawing.new("Text")
                    text.Size = 14
                    text.Center = true
                    text.Outline = true
                    text.Color = Color3.fromRGB(255, 255, 255)
                    espObjects[player] = text
                end
                text.Position = Vector
