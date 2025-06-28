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
        if v:IsA("TextButton") or v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("DropdownMenu") then
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
    local Dropdown = Instance.new("TextButton", Frame)
    Dropdown.Position = UDim2.new(0, 10, 0, y)
    Dropdown.Size = UDim2.new(0, 280, 0, 30)
    Dropdown.Text = name .. ": " .. Settings[settingKey]
    Dropdown.TextColor3 = Color3.new(1, 1, 1)
    Dropdown.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    Dropdown.Font = Enum.Font.SourceSans
    Dropdown.TextSize = 16

    Dropdown.MouseButton1Click:Connect(function()
        local currentIndex = table.find(options, Settings[settingKey]) or 1
        local nextIndex = currentIndex + 1
        if nextIndex > #options then
            nextIndex = 1
        end
        Settings[settingKey] = options[nextIndex]
        Dropdown.Text = name .. ": " .. Settings[settingKey]
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

-- FOV Circle Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0,255,0)
FOVCircle.Thickness = 1.5
FOVCircle.Radius = Settings.AimbotFOV
FOVCircle.NumSides = 64
FOVCircle.Transparency = 0.75
FOVCircle.Filled = false

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Visible = Settings.Aimbot
    FOVCircle.Radius = Settings.AimbotFOV
end)

-- Aimbot logic with mouse control
RunService.RenderStepped:Connect(function()
    if Settings.Aimbot and (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or Settings.AimbotAlways) then
        local closest, shortest = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimbotTarget) then
                if Settings.DrawTeam == false and player.Team == LocalPlayer.Team then continue end
                local part = player.Character[Settings.AimbotTarget]
                local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
                if visible then
                    local mousePos = UIS:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist <= Settings.AimbotFOV and dist < shortest then
                        shortest = dist
                        closest = part
                    end
                end
            end
        end
        if closest then
            local mouse = game:GetService("VirtualInputManager")
            local pos = Camera:WorldToViewportPoint(closest.Position)
            local move = Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()
            mouse:SendMouseMoveRelative(math.floor(move.X / Settings.AimbotSpeed), math.floor(move.Y / Settings.AimbotSpeed))
        end
    end
end)

-- Bạn có thể tiếp tục bổ sung ESP Box/Name/Line bằng Drawing API tại đây
