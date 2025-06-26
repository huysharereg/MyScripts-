-- ✅ Aimbot AutoShoot with ESP + FOV + GUI Toggle by ChatGPT
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ⚙ Settings
local Settings = {
    FOV_RADIUS = 120,
    AimbotEnabled = true,
    AutoShoot = true,
    AimPartName = "Head",
    GUIVisible = true,
}

-- 🎯 FOV circle
local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.Color = Color3.new(1, 1, 0)
circle.Filled = false
circle.Visible = true
circle.Radius = Settings.FOV_RADIUS

-- 🔍 Tìm kẻ địch gần nhất trong FOV
function GetClosestEnemy()
    local closest, shortest = nil, Settings.FOV_RADIUS
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild(Settings.AimPartName) then
            local part = p.Character[Settings.AimPartName]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - UIS:GetMouseLocation()).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

-- 🧠 Dịch chuột đến mục tiêu
function MoveMouseToTarget(part)
    local screenPos = Camera:WorldToViewportPoint(part.Position)
    local mousePos = UIS:GetMouseLocation()
    local moveVec = Vector2.new(screenPos.X, screenPos.Y) - mousePos
    mousemoverel(moveVec.X, moveVec.Y)
end

-- 🧩 UI
local GUI = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", GUI)
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Visible = Settings.GUIVisible
Frame.Active = true
Frame.Draggable = true

local function MakeButton(name, y, callback)
    local Btn = Instance.new("TextButton", Frame)
    Btn.Size = UDim2.new(1, -20, 0, 30)
    Btn.Position = UDim2.new(0, 10, 0, y)
    Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14
    Btn.Text = name
    Btn.MouseButton1Click:Connect(callback)
end

MakeButton("Toggle Aimbot", 10, function()
    Settings.AimbotEnabled = not Settings.AimbotEnabled
end)

MakeButton("Toggle AutoShoot", 50, function()
    Settings.AutoShoot = not Settings.AutoShoot
end)

MakeButton("Toggle FOV", 90, function()
    circle.Visible = not circle.Visible
end)

-- 🔄 Vòng lặp chính
RunService.RenderStepped:Connect(function()
    if not Settings.GUIVisible then return end
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV_RADIUS

    if Settings.AimbotEnabled then
        local target = GetClosestEnemy()
        if target then
            MoveMouseToTarget(target)
            if Settings.AutoShoot then
                mouse1click()
            end
        end
    end
end)

-- 🛑 Toggle UI bằng phím INSERT
UIS.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Insert and not processed then
        Settings.GUIVisible = not Settings.GUIVisible
        Frame.Visible = Settings.GUIVisible
    end
end)
