local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local Settings = {
    Aimbot = false,
    AimbotAlways = false,
    AimbotSpeed = 8, -- Giảm tốc độ để aim mượt hơn
    AimbotPrediction = false,
    AimbotFOV = 300, -- Tăng FOV để dễ nhắm
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
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

local Minimize = Instance.new("TextButton", Frame)
Minimize.Size = UDim2.new(0, 30, 0, 30)
Minimize.Position = UDim2.new(1, -30, 0, 0)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)

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
    Button.Text = name .. ": " .. (Settings[settingKey] and "ON" or "OFF")
    Button.TextColor3 = Color3.new(1, 1, 1)
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
        else
            TextBox.Text = tostring(Settings[settingKey])
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
            if input and input:lower() == opt:lower() then
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
createInput("Aimbot FOV", 180, "AimbotFOV", tostring(Settings.AimbotFOV))
createDropdown("Aimbot Target", 215, "AimbotTarget", {"Head", "HumanoidRootPart", "LeftLeg"})
createDropdown("ESP Mode", 250, "ESPMode", {"All", "Name", "Box", "Line"})
createToggle("Draw Team", 285, "DrawTeam")
createToggle("Hitbox Expander", 320, "HitboxExpander")
createToggle("Low Gravity", 355, "LowGravity")
createToggle("Fly", 390, "Fly")

-- Get closest enemy
local function isVisible(targetPos, target)
    local success, result = pcall(function()
        local ray = Ray.new(Camera.CFrame.Position, (targetPos - Camera.CFrame.Position).Unit * 1000)
        local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
        return hit == nil or hit:IsDescendantOf(target)
    end)
    return success and result
end

local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team then -- Chỉ nhắm địch
            local success, result = pcall(function()
                local targetPart = p.Character and p.Character:FindFirstChild(Settings.AimbotTarget)
                if not targetPart then
                    print("No target part '" .. Settings.AimbotTarget .. "' for " .. p.Name)
                    return
                end
                local pos, visible = Camera:WorldToViewportPoint(targetPart.Position)
                if visible and (not Settings.AimbotVisibility or isVisible(targetPart.Position, p.Character)) then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < shortest and dist <= Settings.AimbotFOV then
                        closest, shortest = p, dist
                        print("Found enemy: " .. p.Name .. ", Part: " .. Settings.AimbotTarget .. ", Dist: " .. dist .. ", Team: " .. tostring(p.Team))
                    end
                else
                    print("Enemy not visible: " .. p.Name .. ", Visible: " .. tostring(visible))
                end
            end)
            if not success then warn("Error in GetClosestEnemy: " .. result) end
        end
    end
    if not closest then print("No valid enemy found") end
    return closest
end

-- Aimbot and Fly
local flySpeed = 50
local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

RunService.RenderStepped:Connect(function()
    -- Fly
    local success, result = pcall(function()
        if Settings.Fly and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                humanoid.PlatformStand = true
                bodyVelocity.Parent = root
                bodyGyro.Parent = root
                local camLook = Camera.CFrame.LookVector
                local moveDir = Vector3.new(0, 0, 0)
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camLook end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camLook end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                bodyVelocity.Velocity = moveDir.Unit * flySpeed
                bodyGyro.CFrame = Camera.CFrame
            end
        else
            bodyVelocity.Parent = nil
            bodyGyro.Parent = nil
            if LocalPlayer.Character then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
            end
        end
    end)
    if not success then warn("Error in Fly: " .. result) end

    -- Aimbot
    if Settings.Aimbot and (Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        local success, result = pcall(function()
            local target = GetClosestEnemy()
            if target and target.Character and target.Character:FindFirstChild(Settings.AimbotTarget) then
                local pos = target.Character[Settings.AimbotTarget].Position
                if Settings.AimbotPrediction and target.Character:FindFirstChild("HumanoidRootPart") then
                    pos = pos + target.Character.HumanoidRootPart.Velocity * 0.05
                end
                local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
                if onScreen then
                    local mousePos = Vector2.new(mouse.X, mouse.Y)
                    local move = (Vector2.new(screenPos.X, screenPos.Y) - mousePos) * (Settings.AimbotSpeed / 100)
                    local success, err = pcall(function()
                        mousemoverel(move.X, move.Y)
                    end)
                    if not success then
                        warn("mousemoverel failed: " .. err)
                    else
                        print("Aiming at: " .. target.Name .. ", Part: " .. Settings.AimbotTarget .. ", ScreenPos: " .. tostring(screenPos))
                    end
                else
                    print("Enemy not on screen: " .. target.Name)
                end
            end
        end)
        if not success then warn("Error in Aimbot: " .. result) end
    end

    -- Low Gravity
    if Settings.LowGravity then
        workspace.Gravity = 50
    else
        workspace.Gravity = 196.2
    end

    -- Hitbox Expander
    for _, p in pairs(Players:GetPlayers()) do
        local success, result = pcall(function()
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                if Settings.HitboxExpander then
                    head.Size = Vector3.new(5, 5, 5)
                    head.Transparency = 0.5
                else
                    head.Size = Vector3.new(2, 1, 1)
                    head.Transparency = 0
                end
            end
        end)
        if not success then warn("Error in Hitbox Expander: " .. result) end
    end
end)

-- ESP
local espObjects = {}
RunService.RenderStepped:Connect(function()
    for _, v in pairs(espObjects) do
        local success, result = pcall(function()
            v:Remove()
        end)
        if not success then warn("Error in ESP cleanup: " .. result) end
    end
    table.clear(espObjects)

    if not Settings.ESP then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (Settings.DrawTeam or plrELECTIONS
            local success, result = pcall(function()
                if plr.Character and plr.Character:FindFirstChild("Head") then
                    local headPos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
                    if onScreen then
                        local isEnemy = plr.Team ~= LocalPlayer.Team
                        if isEnemy or Settings.DrawTeam then
                            local color = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                            if Settings.ESPMode == "All" or Settings.ESPMode == "Name" then
                                local nameDraw = Drawing.new("Text")
                                nameDraw.Text = plr.Name .. (isEnemy and " [Enemy]" or " [Teammate]")
                                nameDraw.Size = 14
                                nameDraw.Center = true
                                nameDraw.Outline = true
                                nameDraw.Position = Vector2.new(headPos.X, headPos.Y - 25)
                                nameDraw.Color = color
                                nameDraw.Visible = true
                                table.insert(espObjects, nameDraw)
                            end
                            if Settings.ESPMode == "All" or Settings.ESPMode == "Box" then
                                local box = Drawing.new("Square")
                                box.Size = Vector2.new(50, 60)
                                box.Position = Vector2.new(headPos.X - 25, headPos.Y - 30)
                                box.Color = color
                                box.Thickness = 2
                                box.Visible = true
                                table.insert(espObjects, box)
                            end
                            if Settings.ESPMode == "All" or Settings.ESPMode == "Line" then
                                local line = Drawing.new("Line")
                                line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                                line.To = Vector2.new(headPos.X, headPos.Y)
                                line.Color = color
                                line.Thickness = 1
                                line.Visible = true
                                table.insert(espObjects, line)
                            end
                        end
                    end
                end
            end)
            if not success then warn("Error in ESP: " .. result) end
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
circle.Visible = Settings.Aimbot

RunService.RenderStepped:Connect(function()
    local success, result = pcall(function()
        circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        circle.Radius = Settings.AimbotFOV
        circle.Visible = Settings.Aimbot
    end)
    if not success then warn("Error in FOV Circle: " .. result) end
end)
