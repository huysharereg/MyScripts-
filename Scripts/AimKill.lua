local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local Settings = {
    Aimbot = false,
    AimbotAlways = false,
    AimbotSpeed = 5, -- Tốc độ aim mượt
    AimbotFOV = 500, -- FOV lớn để dễ nhắm
    AimbotTarget = "Head",
    AimbotVisibility = false, -- Nhắm xuyên tường
    Chams = true,
    DrawTeam = false,
    UseDrawingChams = false -- Bật nếu Highlight không hoạt động
}

-- Kiểm tra executor
local function checkMouseMoveRel()
    local success, err = pcall(function()
        mousemoverel(0, 0)
    end)
    if not success then
        warn("Executor không hỗ trợ mousemoverel: " .. err)
    else
        print("mousemoverel được hỗ trợ bởi executor")
    end
    return success
end
local function checkDrawingAPI()
    local success, err = pcall(function()
        local test = Drawing.new("Square")
        test:Remove()
    end)
    if not success then
        warn("Executor không hỗ trợ Drawing API: " .. err)
    else
        print("Drawing API được hỗ trợ bởi executor")
    end
    return success
end
print("Kiểm tra mousemoverel: " .. (checkMouseMoveRel() and "Hỗ trợ" or "Không hỗ trợ"))
print("Kiểm tra Drawing API: " .. (checkDrawingAPI() and "Hỗ trợ" or "Không hỗ trợ"))

-- UI Setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GunfightArenaUI"
local Frame = Instance.new("Frame", ScreenGui)
Frame.Position = UDim2.new(0.7, 0, 0.3, 0)
Frame.Size = UDim2.new(0, 300, 0, 200)
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
    Frame.Size = minimized and UDim2.new(0, 60, 0, 30) or UDim2.new(0, 300, 0, 200)
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

createToggle("Aimbot", 40, "Aimbot")
createToggle("Aimbot Always", 75, "AimbotAlways")
createInput("Aimbot Speed", 110, "AimbotSpeed", tostring(Settings.AimbotSpeed))
createInput("Aimbot FOV", 145, "AimbotFOV", tostring(Settings.AimbotFOV))
createToggle("Chams", 180, "Chams")
createToggle("Draw Team", 215, "DrawTeam")

-- Get closest enemy
local function isVisible(targetPos, target)
    if not Settings.AimbotVisibility then return true end
    local success, result = pcall(function()
        local ray = Ray.new(Camera.CFrame.Position, (targetPos - Camera.CFrame.Position).Unit * 1000)
        local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character or {}})
        return hit == nil or hit:IsDescendantOf(target)
    end)
    if not success then
        warn("Error in isVisible: " .. result)
    end
    return success and result
end

local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    if not LocalPlayer.Team then
        warn("LocalPlayer has no team assigned! Targeting all players.")
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (not LocalPlayer.Team or p.Team ~= LocalPlayer.Team) then -- Chỉ nhắm địch
            local success, result = pcall(function()
                if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local targetPart = p.Character:FindFirstChild(Settings.AimbotTarget)
                    if not targetPart then
                        print("No target part '" .. Settings.AimbotTarget .. "' for " .. p.Name)
                        return
                    end
                    local pos, visible = Camera:WorldToViewportPoint(targetPart.Position)
                    if visible and isVisible(targetPart.Position, p.Character) then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                        if dist < shortest and dist <= Settings.AimbotFOV then
                            closest, shortest = p, dist
                            print("Found enemy: " .. p.Name .. ", Part: " .. Settings.AimbotTarget .. ", Dist: " .. dist .. ", Team: " .. tostring(p.Team))
                        end
                    else
                        print("Enemy not visible: " .. p.Name .. ", Visible: " .. tostring(visible))
                    end
                else
                    print("No valid character or dead: " .. p.Name)
                end
            end)
            if not success then warn("Error in GetClosestEnemy: " .. result) end
        end
    end
    if not closest then print("No valid enemy found") end
    return closest
end

-- Aimbot
RunService.RenderStepped:Connect(function()
    if Settings.Aimbot and (Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
        local success, result = pcall(function()
            local target = GetClosestEnemy()
            if target and target.Character and target.Character:FindFirstChild(Settings.AimbotTarget) then
                local pos = target.Character[Settings.AimbotTarget].Position
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
end)

-- Chams (Highlight + Drawing fallback)
local chamsObjects = {}
RunService.RenderStepped:Connect(function()
    for _, v in pairs(chamsObjects) do
        local success, result = pcall(function()
            if v:IsA("Highlight") then
                v:Destroy()
            else
                v:Remove()
            end
        end)
        if not success then warn("Error in Chams cleanup: " .. result) end
    end
    table.clear(chamsObjects)

    if not Settings.Chams then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (Settings.DrawTeam or (plr.Team and plr.Team ~= LocalPlayer.Team)) then
            local success, result = pcall(function()
                if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                    local isEnemy = not LocalPlayer.Team or plr.Team ~= LocalPlayer.Team
                    if isEnemy or Settings.DrawTeam then
                        if not Settings.UseDrawingChams then
                            local highlight = Instance.new("Highlight")
                            highlight.Parent = plr.Character
                            highlight.FillColor = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            table.insert(chamsObjects, highlight)
                            print("Highlight Chams applied to: " .. plr.Name .. (isEnemy and " [Enemy]" or " [Teammate]"))
                        else
                            local head = plr.Character:FindFirstChild("Head")
                            if head then
                                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                                if onScreen then
                                    local box = Drawing.new("Square")
                                    box.Size = Vector2.new(50, 60)
                                    box.Position = Vector2.new(headPos.X - 25, headPos.Y - 30)
                                    box.Color = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                                    box.Thickness = 2
                                    box.Filled = false
                                    box.Visible = true
                                    table.insert(chamsObjects, box)
                                    print("Drawing Chams applied to: " .. plr.Name .. (isEnemy and " [Enemy]" or " [Teammate]"))
                                end
                            end
                        end
                    end
                else
                    print("No valid character or dead: " .. plr.Name)
                end
            end)
            if not success then warn("Error in Chams: " .. result) end
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
