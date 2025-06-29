-- ✅ FULL AIMBOT + CHAMS ESP + UI

-- ⚙️ Settings
local Settings = {
    AimbotEnabled = false,
    ESPEnabled = false,
    ShowFOV = false,
    ShowTeam = false,
    AimbotPart = "Head",
    AimbotFOV = 120,
    AimbotSpeed = 5
}

-- 📦 Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 🎯 Get Closest Target
local function GetClosestTarget()
    local closest, shortest = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(Settings.AimbotPart) and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end
            local part = plr.Character[Settings.AimbotPart]
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortest and dist <= Settings.AimbotFOV then
                    closest = part
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- 🔁 Aimbot
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = GetClosestTarget()
        if target then
            local pos = target.Position
            local dir = (pos - Camera.CFrame.Position).Unit
            local goal = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / Settings.AimbotSpeed)
        end
    end
end)

-- 🔴 ESP CHAMS bằng Highlight
local highlights = {}
RunService.RenderStepped:Connect(function()
    if not Settings.ESPEnabled then
        for _, h in pairs(highlights) do h:Destroy() end
        highlights = {}
        return
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end
            if not highlights[plr] or not highlights[plr].Parent then
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 1
                hl.Adornee = plr.Character
                hl.Parent = plr.Character
                highlights[plr] = hl
            end
        end
    end
end)

-- 🔵 FOV Circle
local circle = Drawing.new("Circle")
circle.Thickness = 1
circle.NumSides = 64
circle.Radius = Settings.AimbotFOV
circle.Color = Color3.fromRGB(255, 255, 0)
circle.Filled = false
circle.Visible = true

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    circle.Radius = Settings.AimbotFOV
    circle.Visible = Settings.ShowFOV
end)

-- 🖥️ UI Setup
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 300)
frame.Position = UDim2.new(0, 20, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local function AddToggle(y, text, setting)
    local btn = Instance.new("TextButton", frame)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Size = UDim2.new(0, 230, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        btn.Text = text .. ": " .. (Settings[setting] and "ON" or "OFF")
    end)
end

local function AddSlider(y, text, setting, min, max)
    local label = Instance.new("TextLabel", frame)
    label.Position = UDim2.new(0, 10, 0, y)
    label.Size = UDim2.new(0, 230, 0, 20)
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = text .. ": " .. Settings[setting]
    label.BackgroundTransparency = 1

    local box = Instance.new("TextBox", frame)
    box.Position = UDim2.new(0, 10, 0, y + 20)
    box.Size = UDim2.new(0, 230, 0, 25)
    box.Text = tostring(Settings[setting])
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.new(1,1,1)
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val and val >= min and val <= max then
            Settings[setting] = val
            label.Text = text .. ": " .. val
        else
            box.Text = tostring(Settings[setting])
        end
    end)
end

AddToggle(10, "Aimbot", "AimbotEnabled")
AddToggle(45, "ESP (Chams)", "ESPEnabled")
AddToggle(80, "Show FOV", "ShowFOV")
AddToggle(115, "Show Team", "ShowTeam")
AddSlider(150, "Aimbot Speed", "AimbotSpeed", 1, 15)
AddSlider(200, "FOV Radius", "AimbotFOV", 50, 300)
