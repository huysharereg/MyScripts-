-- ⚙️ Settings
local Settings = {
    AimbotEnabled = false,
    ESPEnabled = false,
    UseChams = false,
    ShowTeam = false,
    FOVVisible = false,
    AimbotSpeed = 5,
    AimbotFOV = 120
}

-- 📦 Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 🎯 Get Closest Enemy
local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortest then
                    closest = plr.Character.Head
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- 🔁 Aimbot Logic
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = GetClosestEnemy()
        if target then
            local dir = (target.Position - Camera.CFrame.Position).Unit
            local goal = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / Settings.AimbotSpeed)
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
circle.Visible = false

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    circle.Radius = Settings.AimbotFOV
    circle.Visible = Settings.FOVVisible
end)

-- 👁️ ESP Drawing Text
local esp = {}
RunService.RenderStepped:Connect(function()
    for _, v in pairs(esp) do v.Visible = false end
    if not Settings.ESPEnabled then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                if not esp[plr] then
                    local text = Drawing.new("Text")
                    text.Size = 14
                    text.Center = true
                    text.Outline = true
                    text.Color = Color3.fromRGB(255, 255, 255)
                    esp[plr] = text
                end
                esp[plr].Text = plr.Name
                esp[plr].Position = Vector2.new(pos.X, pos.Y - 25)
                esp[plr].Visible = true
            end
        end
    end
end)

-- 🔲 CHAMS ESP (Box xuyên tường)
RunService.RenderStepped:Connect(function()
    if not Settings.UseChams then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end
            if not plr.Character:FindFirstChild("ESPBox") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox"
                box.Adornee = plr.Character
                box.Size = Vector3.new(4, 6, 2)
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.Transparency = 0.5
                box.Parent = plr.Character
            end
        end
    end
end)

-- 🖥️ UI
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 320)
frame.Position = UDim2.new(0, 20, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

local function AddToggle(y, label, setting)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 230, 0, 30)
    btn.Position = UDim2.new(0, 15, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = label .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        btn.Text = label .. ": " .. (Settings[setting] and "ON" or "OFF")
    end)
end

local function AddTextBox(y, label, setting)
    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(0, 230, 0, 20)
    textLabel.Position = UDim2.new(0, 15, 0, y)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = label

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0, 230, 0, 25)
    box.Position = UDim2.new(0, 15, 0, y + 20)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(Settings[setting])
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            Settings[setting] = val
        else
            box.Text = tostring(Settings[setting])
        end
    end)
end

-- 🧩 Add Controls
AddToggle(10,  "Aimbot", "AimbotEnabled")
AddToggle(45,  "ESP Text", "ESPEnabled")
AddToggle(80,  "ESP Chams", "UseChams")
AddToggle(115, "Show Team", "ShowTeam")
AddToggle(150, "Show FOV", "FOVVisible")
AddTextBox(190, "Aimbot Speed", "AimbotSpeed")
AddTextBox(240, "FOV Radius", "AimbotFOV")
