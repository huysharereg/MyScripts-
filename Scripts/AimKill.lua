-- ⚙️ SETTINGS
local Settings = {
    AimbotEnabled = false,
    AimbotAlways = false,
    AimbotSpeed = 5,
    AimbotFOV = 120,
    AimbotPart = "Head",
    AimbotVisibility = true,
    ESPEnabled = false,
    ShowTeam = false,
    ShowFOV = true
}

-- 📦 SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 🎯 FIND CLOSEST ENEMY
local function GetClosest()
    local closest, shortest = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Settings.AimbotPart) and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if not Settings.ShowTeam and p.Team == LocalPlayer.Team then continue end
            local part = p.Character[Settings.AimbotPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if Settings.AimbotVisibility and not onScreen then continue end
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize / 2).Magnitude
            if dist < shortest and dist <= Settings.AimbotFOV then
                closest = part
                shortest = dist
            end
        end
    end
    return closest
end

-- 🎯 AIMBOT
RunService.RenderStepped:Connect(function()
    if not Settings.AimbotEnabled then return end
    local active = Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if not active then return end
    local target = GetClosest()
    if target then
        local dir = (target.Position - Camera.CFrame.Position).Unit
        local cf = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir)
        Camera.CFrame = Camera.CFrame:Lerp(cf, 1 / Settings.AimbotSpeed)
    end
end)

-- 🔵 FOV CIRCLE
local circle = Drawing.new("Circle")
circle.Thickness = 1
circle.NumSides = 64
circle.Filled = false
circle.Transparency = 1
circle.Color = Color3.fromRGB(255, 255, 0)
circle.Radius = Settings.AimbotFOV

RunService.RenderStepped:Connect(function()
    circle.Visible = Settings.ShowFOV
    circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    circle.Radius = Settings.AimbotFOV
end)

-- 👁️ ESP
local esp = {}
RunService.RenderStepped:Connect(function()
    for _, v in pairs(esp) do v.Visible = false end
    if not Settings.ESPEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if not Settings.ShowTeam and p.Team == LocalPlayer.Team then continue end
            local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if vis then
                if not esp[p] then
                    local t = Drawing.new("Text")
                    t.Size = 14
                    t.Center = true
                    t.Outline = true
                    t.Color = Color3.fromRGB(255, 255, 255)
                    esp[p] = t
                end
                esp[p].Text = p.Name
                esp[p].Position = Vector2.new(pos.X, pos.Y - 20)
                esp[p].Visible = true
            end
        end
    end
end)

-- 🖥️ UI FULL
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 320)
frame.Position = UDim2.new(0, 20, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Active = true
frame.Draggable = true

-- Toggle Button
local function AddToggle(y, name, key)
    local btn = Instance.new("TextButton", frame)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Size = UDim2.new(0, 230, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = name .. ": OFF"
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
    end)
end

-- Input Box (Number)
local function AddInput(y, label, key)
    local lb = Instance.new("TextLabel", frame)
    lb.Position = UDim2.new(0, 10, 0, y)
    lb.Size = UDim2.new(0, 230, 0, 20)
    lb.Text = label .. ":"
    lb.TextColor3 = Color3.new(1,1,1)
    lb.BackgroundTransparency = 1
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Font = Enum.Font.SourceSans
    lb.TextSize = 16

    local box = Instance.new("TextBox", frame)
    box.Position = UDim2.new(0, 10, 0, y + 20)
    box.Size = UDim2.new(0, 230, 0, 25)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    box.TextColor3 = Color3.new(1,1,1)
    box.Text = tostring(Settings[key])
    box.Font = Enum.Font.SourceSans
    box.TextSize = 16
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then Settings[key] = num end
    end)
end

-- UI Elements
AddToggle(10, "Aimbot", "AimbotEnabled")
AddToggle(45, "Aimbot Always", "AimbotAlways")
AddToggle(80, "ESP", "ESPEnabled")
AddToggle(115, "Show FOV", "ShowFOV")
AddToggle(150, "Show Team", "ShowTeam")
AddToggle(185, "Aimbot Visibility", "AimbotVisibility")
AddInput(220, "Aimbot Speed", "AimbotSpeed")
AddInput(260, "FOV Radius", "AimbotFOV")
