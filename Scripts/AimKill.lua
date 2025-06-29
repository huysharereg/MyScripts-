-- ⚙️ Settings
local Settings = {
    AimbotEnabled = false,
    ESPEnabled = false,
    FOVVisible = false,
    AimbotSpeed = 5,
    ShowTeam = false
}

-- 📦 Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 🎯 Aimbot
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

-- 🔁 Aimbot logic chuẩn ghim Head
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = GetClosestEnemy()
        if target then
            local headPos = target.Position + Vector3.new(0, 0.2, 0)
            local dir = (headPos - Camera.CFrame.Position).Unit
            local goal = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / Settings.AimbotSpeed)
        end
    end
end)


-- 🔵 FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Thickness = 1
fovCircle.Radius = 120
fovCircle.Filled = false
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    fovCircle.Visible = Settings.FOVVisible
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end)

-- 👁️ ESP
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

-- 🖥️ Simple UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 250)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
Frame.Active = true
Frame.Draggable = true

local function AddToggle(y, text, key)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 230, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    end)
end

local function AddTextBox(y, text, key)
    local label = Instance.new("TextLabel", Frame)
    label.Position = UDim2.new(0, 10, 0, y)
    label.Size = UDim2.new(0, 230, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = text .. ":"
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", Frame)
    box.Position = UDim2.new(0, 10, 0, y + 20)
    box.Size = UDim2.new(0, 230, 0, 25)
    box.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    box.TextColor3 = Color3.new(1,1,1)
    box.Text = tostring(Settings[key])
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then Settings[key] = num end
    end)
end

AddToggle(10, "Aimbot", "AimbotEnabled")
AddToggle(45, "ESP", "ESPEnabled")
AddToggle(80, "Show FOV", "FOVVisible")
AddToggle(115, "Show Team", "ShowTeam")
AddTextBox(150, "Aimbot Speed", "AimbotSpeed")
