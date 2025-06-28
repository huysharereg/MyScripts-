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
    ESPMode = "All", -- Name, Box, Line, All
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
Frame.Size = UDim2.new(0, 300, 0, 450)
Frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Gunfight Arena HUB"
Title.TextColor3 = Color3.new(1,1,1)
Title.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

local Minimize = Instance.new("TextButton", Frame)
Minimize.Size = UDim2.new(0, 30, 0, 30)
Minimize.Position = UDim2.new(1, -30, 0, 0)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.BackgroundColor3 = Color3.new(0.3,0.3,0.3)

local minimized = false
Minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, v in ipairs(Frame:GetChildren()) do
        if v:IsA("TextButton") or v:IsA("TextLabel") or v:IsA("TextBox") then
            if v ~= Title and v ~= Minimize then
                v.Visible = not minimized
            end
        end
    end
    Frame.Size = minimized and UDim2.new(0, 60, 0, 30) or UDim2.new(0, 300, 0, 450)
end)

local function createToggle(name, y, settingKey)
    local Button = Instance.new("TextButton", Frame)
    Button.Position = UDim2.new(0, 10, 0, y)
    Button.Size = UDim2.new(0, 280, 0, 30)
    Button.Text = name .. ": OFF"
    Button.TextColor3 = Color3.new(1,1,1)
    Button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    Button.Font = Enum.Font.SourceSans
    Button.TextSize = 16
    Button.Visible = true
    Button.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        Button.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    end)
end

local function createInput(name, y, settingKey, defaultText)
    local TextBox = Instance.new("TextBox", Frame)
    TextBox.Position = UDim2.new(0, 10, 0, y)
    TextBox.Size = UDim2.new(0, 280, 0, 30)
    TextBox.Text = defaultText or name
    TextBox.TextColor3 = Color3.new(1, 1, 1)
    TextBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    TextBox.Font = Enum.Font.SourceSans
    TextBox.TextSize = 16
    TextBox.FocusLost:Connect(function()
        local val = tonumber(TextBox.Text)
        if val then
            Settings[settingKey] = val
        end
    end)
end

local function createDropdown(name, y, settingKey, options)
    local Box = Instance.new("TextBox", Frame)
    Box.Position = UDim2.new(0, 10, 0, y)
    Box.Size = UDim2.new(0, 280, 0, 30)
    Box.Text = name .. ": " .. Settings[settingKey]
    Box.TextColor3 = Color3.new(1, 1, 1)
    Box.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    Box.Font = Enum.Font.SourceSans
    Box.TextSize = 16
    Box.FocusLost:Connect(function()
        local input = Box.Text:match("%w+")
        for _, opt in ipairs(options) do
            if input:lower() == opt:lower() then
                Settings[settingKey] = opt
                Box.Text = name .. ": " .. opt
                break
            end
        end
    end)
end

createToggle("Aimbot", 40, "Aimbot")
createToggle("Aimbot Always", 75, "AimbotAlways")
createToggle("Aimbot Prediction", 110, "AimbotPrediction")
createInput("Aimbot Speed", 145, "AimbotSpeed", tostring(Settings.AimbotSpeed))
createDropdown("Aimbot Target", 180, "AimbotTarget", {"Head", "HumanoidRootPart", "LeftLeg"})
createDropdown("ESP Mode", 215, "ESPMode", {"All", "Name", "Box", "Line"})
createToggle("Draw Team", 250, "DrawTeam")
createToggle("Low Gravity", 285, "LowGravity")
createToggle("Fly", 320, "Fly")

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Thickness = 1
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Radius = Settings.AimbotFOV
fovCircle.Visible = true

-- ESP Data
local ESPObjects = {}

-- Fly
local FlyVelocity = Vector3.zero
RunService.RenderStepped:Connect(function()
    fovCircle.Position = UIS:GetMouseLocation()
    fovCircle.Radius = Settings.AimbotFOV

    if Settings.LowGravity and workspace:FindFirstChild("Gravity") then
        workspace.Gravity = 20
    end

    if Settings.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local HRP = LocalPlayer.Character.HumanoidRootPart
        HRP.Velocity = Vector3.new(0, 50, 0)
    end

    -- ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local teamCheck = (plr.Team ~= LocalPlayer.Team or Settings.DrawTeam)
            if teamCheck then
                local headPos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
                if not ESPObjects[plr] then
                    ESPObjects[plr] = {
                        Name = Drawing.new("Text"),
                        Line = Drawing.new("Line"),
                        Box = Drawing.new("Square")
                    }
                    ESPObjects[plr].Name.Size = 14
                    ESPObjects[plr].Name.Center = true
                    ESPObjects[plr].Name.Outline = true
                    ESPObjects[plr].Box.Thickness = 1
                    ESPObjects[plr].Box.Filled = false
                    ESPObjects[plr].Line.Thickness = 1
                end
                local esp = ESPObjects[plr]
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude

                -- Name
                if Settings.ESP and (Settings.ESPMode == "Name" or Settings.ESPMode == "All") and onScreen then
                    esp.Name.Text = string.format("%s [%dm]", plr.Name, math.floor(dist))
                    esp.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
                    esp.Name.Visible = true
                else
                    esp.Name.Visible = false
                end

                -- Box
                if Settings.ESP and (Settings.ESPMode == "Box" or Settings.ESPMode == "All") and onScreen then
                    esp.Box.Position = Vector2.new(headPos.X - 25, headPos.Y - 50)
                    esp.Box.Size = Vector2.new(50, 100)
                    esp.Box.Visible = true
                else
                    esp.Box.Visible = false
                end

                -- Line
                if Settings.ESP and (Settings.ESPMode == "Line" or Settings.ESPMode == "All") and onScreen then
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(headPos.X, headPos.Y)
                    esp.Line.Visible = true
                else
                    esp.Line.Visible = false
                end
            end
        elseif ESPObjects[plr] then
            for _, d in pairs(ESPObjects[plr]) do
                d.Visible = false
            end
        end
    end
end)

-- Aimbot (mouse lock on left click)
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and Settings.Aimbot then
        local closest = nil
        local minDist = Settings.AimbotFOV
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild(Settings.AimbotTarget) then
                local pos, onScreen = Camera:WorldToViewportPoint(plr.Character[Settings.AimbotTarget].Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = plr
                    end
                end
            end
        end

        if closest then
            local targetPart = closest.Character[Settings.AimbotTarget]
            local dir = (targetPart.Position - Camera.CFrame.Position).Unit
            local newLook = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
            local step = Settings.AimbotAlways and 1 or Settings.AimbotSpeed/10

            for i = 1, math.floor(10 * step) do
                Camera.CFrame = Camera.CFrame:Lerp(newLook, step)
                task.wait()
            end
        end
    end
end)

