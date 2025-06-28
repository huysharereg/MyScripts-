-- ✅ Gunfight Arena Script với UI nâng cao (Aimbot Settings, ESP Settings, Extras)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local Settings = {
    Aimbot = false,
    AimbotAlways = false,
    AimbotSpeed = 1,
    AimbotPrediction = false,
    AimbotFOV = 150,
    AimbotTarget = "Head",
    AimbotVisibility = true,

    ESP = true,
    ESPMode = "All",
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

-- UI Elements
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

-- ✅ Get closest enemy only
local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team then
            if p.Character and p.Character:FindFirstChild(Settings.AimbotTarget) then
                local pos, visible = Camera:WorldToViewportPoint(p.Character[Settings.AimbotTarget].Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < shortest and dist <= Settings.AimbotFOV then
                        closest, shortest = p, dist
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if Settings.Fly then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
        LocalPlayer.Character:TranslateBy(Vector3.new(0, 0.5, 0))
    end

    if Settings.Aimbot and (Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        local target = GetClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild(Settings.AimbotTarget) then
            local pos = target.Character[Settings.AimbotTarget].Position
            if Settings.AimbotPrediction and target.Character:FindFirstChild("HumanoidRootPart") then
                pos = pos + target.Character.HumanoidRootPart.Velocity * 0.05
            end
            local screenPos = Camera:WorldToViewportPoint(pos)
            local mousePos = Vector2.new(mouse.X, mouse.Y)
            local move = (Vector2.new(screenPos.X, screenPos.Y) - mousePos) / Settings.AimbotSpeed
            mousemoverel(move.X, move.Y)
        end
    end
end)

-- ESP Circle + Box
local espObjects = {}
RunService.RenderStepped:Connect(function()
    for _, v in pairs(espObjects) do v:Remove() end
    table.clear(espObjects)

    if not Settings.ESP then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (Settings.DrawTeam or plr.Team ~= LocalPlayer.Team) and plr.Character and plr.Character:FindFirstChild("Head") then
            local headPos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                if Settings.ESPMode == "All" or Settings.ESPMode == "Name" then
                    local nameDraw = Drawing.new("Text")
                    nameDraw.Text = plr.Name
                    nameDraw.Size = 14
                    nameDraw.Center = true
                    nameDraw.Outline = true
                    nameDraw.Position = Vector2.new(headPos.X, headPos.Y - 25)
                    nameDraw.Color = Color3.fromRGB(255, 255, 255)
                    nameDraw.Visible = true
                    table.insert(espObjects, nameDraw)
                end
                if Settings.ESPMode == "All" or Settings.ESPMode == "Box" then
                    local box = Drawing.new("Square")
                    box.Size = Vector2.new(50, 60)
                    box.Position = Vector2.new(headPos.X - 25, headPos.Y - 30)
                    box.Color = Color3.fromRGB(255, 0, 0)
                    box.Thickness = 2
                    box.Visible = true
                    table.insert(espObjects, box)
                end
                if Settings.ESPMode == "All" or Settings.ESPMode == "Line" then
                    local line = Drawing.new("Line")
                    line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(headPos.X, headPos.Y)
                    line.Color = Color3.fromRGB(0, 255, 0)
                    line.Thickness = 1
                    line.Visible = true
                    table.insert(espObjects, line)
                end
            end
        end
    end
end)

-- FOV Circle
local circle = Drawing.new("Circle")
circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
circle.Radius = Settings.AimbotFOV
circle.Thickness = 1
circle.Color = Color3.fromRGB(255, 255, 0)
circle.Filled = false
circle.Visible = true

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    circle.Radius = Settings.AimbotFOV
end)
