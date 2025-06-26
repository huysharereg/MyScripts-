-- ✅ FULL SCRIPT AIMBOT + ESP + UI TOGGLE
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local FOV_RADIUS = 120
local AimbotEnabled = false
local ESPEnabled = false
local AutoShoot = false
local AimPart = "Head"

-- Vẽ FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = FOV_RADIUS
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Filled = false
fovCircle.Transparency = 0.5
fovCircle.Visible = true

-- AimLine
local aimLine = Drawing.new("Line")
aimLine.Thickness = 1
aimLine.Color = Color3.fromRGB(255, 0, 0)
aimLine.Transparency = 0.7
aimLine.Visible = false

-- UI Toggle
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.Size = UDim2.new(0, 200, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Draggable = true
frame.Active = true

local function makeBtn(text, y, callback)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 18
    b.MouseButton1Click:Connect(callback)
end

makeBtn("🎯 Toggle Aimbot", 10, function()
    AimbotEnabled = not AimbotEnabled
end)
makeBtn("👁 Toggle ESP", 50, function()
    ESPEnabled = not ESPEnabled
end)
makeBtn("🔫 Toggle AutoShoot", 90, function()
    AutoShoot = not AutoShoot
end)

-- Tìm địch gần chuột nhất trong FOV
function GetClosestEnemy()
    local closest = nil
    local shortest = FOV_RADIUS
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Team ~= LocalPlayer.Team and v.Character and v.Character:FindFirstChild(AimPart) then
            local pos, visible = Camera:WorldToViewportPoint(v.Character[AimPart].Position)
            if visible then
                local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                if dist < shortest then
                    closest = v
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- Vẽ ESP
function DrawESP(player)
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if player.Character.Head:FindFirstChild("ESP") then return end

    local bb = Instance.new("BillboardGui", player.Character.Head)
    bb.Name = "ESP"
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.AlwaysOnTop = true

    local txt = Instance.new("TextLabel", bb)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.new(1, 0, 0)
    txt.TextScaled = true
    txt.Text = player.Name
end

-- Vòng lặp render
RunService.RenderStepped:Connect(function()
    fovCircle.Position = UIS:GetMouseLocation()

    -- ESP
    if ESPEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team then
                DrawESP(plr)
            end
        end
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("Head") then
                local esp = plr.Character.Head:FindFirstChild("ESP")
                if esp then esp:Destroy() end
            end
        end
    end

    -- Aimbot + Shoot
    if AimbotEnabled then
        local enemy = GetClosestEnemy()
        if enemy and enemy.Character and enemy.Character:FindFirstChild(AimPart) then
            local target = enemy.Character[AimPart]
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            aimLine.Visible = true
            aimLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local screenPos = Camera:WorldToViewportPoint(target.Position)
            aimLine.To = Vector2.new(screenPos.X, screenPos.Y)

            if AutoShoot then
                mouse1click()
            end
        else
            aimLine.Visible = false
        end
    else
        aimLine.Visible = false
    end
end)
