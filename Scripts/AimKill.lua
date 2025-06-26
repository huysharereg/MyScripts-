-- ✅ Full GUI: ESP Tên + Khoảng cách + Line + Slider FOV + Ẩn/Hiện Panel
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local Settings = {
    FOV_RADIUS = 120,
    AimbotEnabled = false,
    AutoShoot = false,
    ESPEnabled = false,
    AimFOVEnabled = false,
    TeamCheck = true,
    AimPartName = "Head",
    GUIVisible = true,
    AimSmoothness = 0.15,
}

local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.Color = Color3.new(1, 1, 0)
circle.Filled = false
circle.Visible = false
circle.Radius = Settings.FOV_RADIUS

local ESPObjects = {}
function ClearESP()
    for _, obj in pairs(ESPObjects) do
        for _, part in pairs(obj) do
            part:Remove()
        end
    end
    ESPObjects = {}
end

local function IsEnemy(player)
    return not Settings.TeamCheck or player.Team ~= LP.Team
end

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

function MoveMouseSmoothlyToTarget(part)
    local screenPos = Camera:WorldToViewportPoint(part.Position)
    local mousePos = UIS:GetMouseLocation()
    local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos
    local smooth = delta * Settings.AimSmoothness
    mousemoverel(smooth.X, smooth.Y)
end

function UpdateESP()
    ClearESP()
    if not Settings.ESPEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and IsEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local head = p.Character:FindFirstChild("Head")
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local nameTag = Drawing.new("Text")
                nameTag.Text = p.Name
                nameTag.Size = 13
                nameTag.Color = Color3.new(1, 1, 1)
                nameTag.Position = Vector2.new(screenPos.X, screenPos.Y - 35)
                nameTag.Outline = true
                nameTag.Visible = true

                local distTag = Drawing.new("Text")
                distTag.Text = string.format("%.0fm", (LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                distTag.Size = 13
                distTag.Color = Color3.new(0, 1, 1)
                distTag.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
                distTag.Outline = true
                distTag.Visible = true

                local line = Drawing.new("Line")
                line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                line.To = Vector2.new(screenPos.X, screenPos.Y)
                line.Thickness = 1
                line.Color = Color3.new(1, 0, 0)
                line.Visible = true

                table.insert(ESPObjects, {nameTag, distTag, line})
            end
        end
    end
end

-- GUI Panel + Toggle Button
local GUI = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", GUI)
Frame.Size = UDim2.new(0, 240, 0, 260)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.Active = true
Frame.Draggable = true
Frame.Visible = Settings.GUIVisible

local ToggleBtn = Instance.new("TextButton", GUI)
ToggleBtn.Text = "☰"
ToggleBtn.Size = UDim2.new(0, 30, 0, 30)
ToggleBtn.Position = UDim2.new(0, 0, 0.3, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.TextSize = 20
ToggleBtn.MouseButton1Click:Connect(function()
    Settings.GUIVisible = not Settings.GUIVisible
    Frame.Visible = Settings.GUIVisible
end)

local function MakeCheckbox(label, yPos, settingName)
    local box = Instance.new("TextButton", Frame)
    box.Size = UDim2.new(0, 200, 0, 25)
    box.Position = UDim2.new(0, 20, 0, yPos)
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

MakeCheckbox("Aimbot (When Shoot)", 10, "AimbotEnabled")
MakeCheckbox("AutoShoot", 40, "AutoShoot")
MakeCheckbox("ESP (Name + Line)", 70, "ESPEnabled")
MakeCheckbox("Show FOV", 100, "AimFOVEnabled")
MakeCheckbox("Team Check", 130, "TeamCheck")

-- Slider FOV
local Slider = Instance.new("TextBox", Frame)
Slider.Position = UDim2.new(0, 20, 0, 170)
Slider.Size = UDim2.new(0, 200, 0, 25)
Slider.Text = "FOV Radius: " .. Settings.FOV_RADIUS
Slider.TextColor3 = Color3.new(1,1,1)
Slider.BackgroundColor3 = Color3.fromRGB(50,50,50)
Slider.FocusLost:Connect(function()
    local num = tonumber(Slider.Text:match("%d+"))
    if num then
        Settings.FOV_RADIUS = math.clamp(num, 30, 500)
        Slider.Text = "FOV Radius: " .. Settings.FOV_RADIUS
    end
end)

local MouseHeld = false
UIS.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHeld = true
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MouseHeld = false
    end
end)

RunService.RenderStepped:Connect(function()
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV_RADIUS
    circle.Visible = Settings.AimFOVEnabled

    UpdateESP()

    if Settings.AimbotEnabled and MouseHeld then
        local target = GetClosestEnemy()
        if target then
            MoveMouseSmoothlyToTarget(target)
            if Settings.AutoShoot then mouse1click() end
        end
    end
end)
