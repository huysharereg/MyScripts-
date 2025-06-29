-- 🚫 Anti-Ban cơ bản (ẩn khỏi lệnh kick, log)
for _, conn in pairs(getconnections or function() return {} end(game.DescendantAdded)) do
    pcall(function()
        if typeof(conn) == "table" and conn.Function and tostring(conn.Function):lower():find("kick") then
            conn:Disable()
        end
    end)
end

-- Ẩn khỏi hàm Local Kick, Disconnect
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if tostring(method):lower():find("kick") then
        return
    end
    return old(self, ...)
end)
setreadonly(mt, true)

-- 📦 Dịch vụ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ Cài đặt
local Settings = {
    AimbotEnabled = false,
    AimbotAlways = false,
    AimbotFOV = 120,
    AimbotPart = "Head",
    AimbotSpeed = 6,
    AimbotPrediction = true,
    ShowTeam = false,
    ESPEnabled = false,
    FOVVisible = true
}

-- 🎯 Tìm địch gần nhất
local function IsVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if not Settings.ShowTeam and p.Team == LocalPlayer.Team then continue end
            local part = p.Character:FindFirstChild(Settings.AimbotPart)
            if part then
                local pos, vis = Camera:WorldToViewportPoint(part.Position)
                if vis and IsVisible(part) then -- 💡 Chỉ khi có Line of Sight
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < shortest and dist <= Settings.AimbotFOV then
                        closest = part
                        shortest = dist
                    end
                end
            end
        end
    end
    return closest
end

-- 🔁 Aimbot logic (chuột trái)
RunService.RenderStepped:Connect(function()
    if not Settings.AimbotEnabled then return end
    if not Settings.AimbotAlways and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end

    local target = GetClosestEnemy()
    if target then
        local predicted = target.Position
        local root = target.Parent:FindFirstChild("HumanoidRootPart")
        if Settings.AimbotPrediction and root then
            predicted = predicted + root.Velocity * 0.035
        end
        local pos = Camera.CFrame.Position
        local dir = (predicted - pos).Unit
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(pos, pos + dir), 1 / Settings.AimbotSpeed)
    end
end)

-- 🔵 FOV
local fov = Drawing.new("Circle")
fov.Color = Color3.fromRGB(255,255,0)
fov.Thickness = 1
fov.Filled = false
fov.Visible = true

RunService.RenderStepped:Connect(function()
    fov.Visible = Settings.FOVVisible
    fov.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    fov.Radius = Settings.AimbotFOV
end)

-- 🔥 Chams (ESP xuyên tường)
local esp = {}
RunService.RenderStepped:Connect(function()
    for _, v in pairs(esp) do v.Visible = false end
    if not Settings.ESPEnabled then return end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if not Settings.ShowTeam and p.Team == LocalPlayer.Team then continue end
            local head = p.Character.Head
            local pos, vis = Camera:WorldToViewportPoint(head.Position)
            if vis then
                if not esp[p] then
                    local box = Drawing.new("Text")
                    box.Size = 14
                    box.Center = true
                    box.Outline = true
                    box.Color = Color3.fromRGB(255, 0, 0) -- Đỏ = địch
                    esp[p] = box
                end
                esp[p].Text = "[CHAMS] " .. p.Name
                esp[p].Position = Vector2.new(pos.X, pos.Y - 25)
                esp[p].Visible = true
            end
        end
    end
end)

-- 🖥️ UI đơn giản
local Gui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0, 240, 0, 260)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.new(0.15,0.15,0.15)
Frame.Active = true
Frame.Draggable = true

local function AddToggle(y, name, key)
    local btn = Instance.new("TextButton", Frame)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Size = UDim2.new(0, 220, 0, 30)
    btn.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.Text = name .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
    end)
end

local function AddInput(y, label, key)
    local textLabel = Instance.new("TextLabel", Frame)
    textLabel.Position = UDim2.new(0, 10, 0, y)
    textLabel.Size = UDim2.new(0, 220, 0, 20)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1,1,1)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = label .. ":"

    local box = Instance.new("TextBox", Frame)
    box.Position = UDim2.new(0, 10, 0, y + 20)
    box.Size = UDim2.new(0, 220, 0, 25)
    box.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    box.TextColor3 = Color3.new(1,1,1)
    box.Text = tostring(Settings[key])
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then Settings[key] = num end
    end)
end

AddToggle(10, "Aimbot", "AimbotEnabled")
AddToggle(45, "Aimbot Always", "AimbotAlways")
AddToggle(80, "Aimbot Prediction", "AimbotPrediction")
AddInput(115, "Aimbot Speed", "AimbotSpeed")
AddToggle(150, "ESP (Chams)", "ESPEnabled")
AddToggle(185, "Show Team", "ShowTeam")
AddToggle(220, "FOV Circle", "FOVVisible")
