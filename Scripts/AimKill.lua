-- ⚙️ SETTINGS
local Settings = {
    AimbotEnabled = false,
    ESPEnabled = false,
    FOVVisible = false,
    AimbotSpeed = 5,
    ShowTeam = false,
    AimbotTarget = "Head",
    UseChams = false,
    FlyEnabled = false,
    LowGravity = false
}

-- 📦 SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local StarterGravity = workspace.Gravity

-- 🎯 GET CLOSEST ENEMY
local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(Settings.AimbotTarget) and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character[Settings.AimbotTarget].Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortest and dist <= 120 then
                    closest = plr.Character[Settings.AimbotTarget]
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- 🎯 AIMBOT
RunService.RenderStepped:Connect(function()
    if Settings.LowGravity then
        workspace.Gravity = 20
    else
        workspace.Gravity = StarterGravity
    end

    if Settings.FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 50, 0)
        end
    end

    if Settings.AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = GetClosestEnemy()
        if target then
            local dir = (target.Position - Camera.CFrame.Position).Unit
            local goal = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / Settings.AimbotSpeed)
        end
    end
end)

-- 🔵 FOV CIRCLE
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

-- 👁️ ESP (TEXT)
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

-- 🖥️ UI WITH MINIMIZE
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 350)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local minimized = false
local MinBtn = Instance.new("TextButton", Frame)
MinBtn.Size = UDim2.new(0, 250, 0, 25)
MinBtn.Position = UDim2.new(0, 0, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MinBtn.Text = "☰ Gunfight Arena Script"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.TextSize = 16
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, v in pairs(Frame:GetChildren()) do
        if v:IsA("TextButton") or v:IsA("TextLabel") or v:IsA("TextBox") then
            if v ~= MinBtn then v.Visible = not minimized end
        end
    end
    Frame.Size = minimized and UDim2.new(0, 250, 0, 25) or UDim2.new(0, 250, 0, 350)
end)

local y = 30
local function AddToggle(text, key)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 230, 0, 25)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    end)
    y = y + 30
end

local function AddTextBox(text, key)
    local label = Instance.new("TextLabel", Frame)
    label.Text = text .. ":"
    label.Position = UDim2.new(0, 10, 0, y)
    label.Size = UDim2.new(0, 230, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 20

    local box = Instance.new("TextBox", Frame)
    box.Position = UDim2.new(0, 10, 0, y)
    box.Size = UDim2.new(0, 230, 0, 25)
    box.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    box.TextColor3 = Color3.new(1,1,1)
    box.Text = tostring(Settings[key])
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then Settings[key] = num end
    end)
    y = y + 30
end

-- 🌟 Add all toggles/inputs
AddToggle("Aimbot", "AimbotEnabled")
AddToggle("ESP Text", "ESPEnabled")
AddToggle("ESP Chams", "UseChams")
AddToggle("Show FOV", "FOVVisible")
AddToggle("Show Team", "ShowTeam")
AddToggle("Low Gravity", "LowGravity")
AddToggle("Fly Mode", "FlyEnabled")
AddTextBox("Aimbot Speed", "AimbotSpeed")
