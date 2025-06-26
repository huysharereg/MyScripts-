-- ✅ Aimbot + AutoShoot + ESP Enemy Only + GUI with Checkboxes by ChatGPT
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ⚙ Settings
local Settings = {
    FOV_RADIUS = 120,
    AimbotEnabled = false,
    AutoShoot = false,
    ESPEnabled = false,
    AimFOVEnabled = false,
    TeamCheck = true,
    AimPartName = "Head",
    GUIVisible = true,
}

-- 🎯 FOV circle
local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.Color = Color3.new(1, 1, 0)
circle.Filled = false
circle.Visible = false
circle.Radius = Settings.FOV_RADIUS

-- 🔲 ESP boxes
local ESPBoxes = {}
function ClearESP()
    for _, box in pairs(ESPBoxes) do
        box:Remove()
    end
    ESPBoxes = {}
end

-- 🆔 Kiểm tra team địch
local function IsEnemy(player)
    return not Settings.TeamCheck or player.Team ~= LP.Team
end

-- 🔍 Tìm kẻ địch gần nhất trong FOV
function GetClosestEnemy()
    local closest, shortest = nil, Settings.FOV_RADIUS
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and IsEnemy(p) and p.Character and p.Character:FindFirstChild(Settings.AimPartName) then
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

-- 📦 ESP cho địch
function UpdateESP()
    ClearESP()
    if not Settings.ESPEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and IsEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local part = p.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local box = Drawing.new("Square")
                box.Color = Color3.new(1, 0, 0)
                box.Thickness = 1
                box.Size = Vector2.new(40, 40)
                box.Position = Vector2.new(screenPos.X - 20, screenPos.Y - 20)
                box.Visible = true
                table.insert(ESPBoxes, box)
            end
        end
    end
end

-- 🧩 GUI với checkbox
local GUI = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", GUI)
Frame.Size = UDim2.new(0, 220, 0, 200)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Visible = Settings.GUIVisible
Frame.Active = true
Frame.Draggable = true

local function MakeCheckbox(label, yPos, settingName)
    local box = Instance.new("TextButton", Frame)
    box.Size = UDim2.new(0, 200, 0, 25)
    box.Position = UDim2.new(0, 10, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    box.Font = Enum.Font.Gotham
    box.TextColor3 = Color3.new(1, 1, 1)
    box.TextSize = 14
    box.Text = "[ ] " .. label
    box.MouseButton1Click:Connect(function()
        Settings[settingName] = not Settings[settingName]
        box.Text = (Settings[settingName] and "[X] " or "[ ] ") .. label
        if settingName == "AimFOVEnabled" then
            circle.Visible = Settings.AimFOVEnabled
        end
    end)
end

MakeCheckbox("Aimbot", 10, "AimbotEnabled")
MakeCheckbox("AutoShoot", 40, "AutoShoot")
MakeCheckbox("ESP (Enemy Only)", 70, "ESPEnabled")
MakeCheckbox("Show FOV", 100, "AimFOVEnabled")
MakeCheckbox("Team Check", 130, "TeamCheck")

-- 🔄 Main loop
RunService.RenderStepped:Connect(function()
    if not Settings.GUIVisible then return end
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV_RADIUS
    UpdateESP()

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

-- 🛑 Toggle GUI bằng INSERT
UIS.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Insert and not processed then
        Settings.GUIVisible = not Settings.GUIVisible
        Frame.Visible = Settings.GUIVisible
    end
end)
