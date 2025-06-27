local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    SilentAim = false,
    ESP = false,
    KillAura = false,
    AimLock = false,
    KillAuraRange = 50,
    AimSmoothness = 0.1,
    FOV = 120
}

-- Enemy check & closest
local function isEnemy(player)
    return player.Team ~= LocalPlayer.Team
end

local function getClosestEnemy()
    local closest, dist = nil, math.huge
    local mouse = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible then
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if mag < Settings.FOV and mag < dist then
                    dist = mag
                    closest = p
                end
            end
        end
    end
    return closest
end

-- Hook __namecall (Sync:Fire)
local old_namecall
old_namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if method == "Fire" and self.Name == "Sync" then
        local caller = args[1]
        local message = args[2]
        local ammo, cframe, id, weapon, projectile = unpack(args, 3)

        local function isShootEvent()
            return typeof(message) == "Instance" and message.Name and message.Name:find(LocalPlayer.Name)
        end

        if isShootEvent() and Settings.SilentAim then
            local target = getClosestEnemy()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                cframe = target.Character.Head.CFrame
                return old_namecall(self, caller, message, ammo, cframe, id, weapon, projectile)
            end
        end
    end

    return old_namecall(self, ...)
end))

-- ESP setup
local espData, fovCircle = {}, Drawing.new("Circle")
fovCircle.Radius = Settings.FOV
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Thickness = 1
fovCircle.Transparency = 0.3
fovCircle.Filled = false

local function setupESP(p)
    if espData[p] then return end
    local box = Drawing.new("Square")
    local name = Drawing.new("Text")
    box.Thickness, box.Filled, box.Color = 1, false, Color3.new(1, 0, 0)
    name.Size, name.Center, name.Outline, name.Color = 14, true, true, Color3.new(1, 1, 1)
    espData[p] = { box = box, name = name }
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then setupESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then setupESP(p) end end)

RunService.RenderStepped:Connect(function()
    local mouse = UserInputService:GetMouseLocation()
    fovCircle.Position = mouse
    fovCircle.Visible = Settings.SilentAim

    for p, d in pairs(espData) do
        if Settings.ESP and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") and isEnemy(p) then
            local head = p.Character.Head
            local hrp = p.Character.HumanoidRootPart
            local top = Camera:WorldToViewportPoint(head.Position)
            local bottom = Camera:WorldToViewportPoint(hrp.Position)

            if top.Z > 0 and bottom.Z > 0 then
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2
                d.box.Size = Vector2.new(width, height)
                d.box.Position = Vector2.new(top.X - width / 2, top.Y)
                d.box.Visible = true

                local dist = math.floor((hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                local hp = math.floor(p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health or 0)
                d.name.Text = string.format("%s [%dhp | %dm]", p.Name, hp, dist)
                d.name.Position = Vector2.new(top.X, top.Y - 20)
                d.name.Visible = true
            else
                d.box.Visible = false
                d.name.Visible = false
            end
        else
            d.box.Visible = false
            d.name.Visible = false
        end
    end

    -- Kill Aura
    if Settings.KillAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local sync = game:GetService("ReplicatedStorage"):FindFirstChild("Sync") or workspace:FindFirstChild("Sync")
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                local dist = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist <= Settings.KillAuraRange and sync then
                    local head = p.Character.Head
                    local fakeMsg = Instance.new("Model", LocalPlayer)
                    fakeMsg.Name = LocalPlayer.Name .. "_shoot"
                    sync:Fire(sync, fakeMsg, nil, head.CFrame, nil, nil)
                    fakeMsg:Destroy()
                end
            end
        end
    end

    -- Smooth Aim Lock
    if Settings.AimLock and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local camPos = Camera.CFrame.Position
            local targetPos = target.Character.Head.Position
            local currentLook = Camera.CFrame.LookVector
            local direction = (targetPos - camPos).Unit
            local lerped = currentLook:Lerp(direction, Settings.AimSmoothness)
            Camera.CFrame = CFrame.new(camPos, camPos + lerped)
        end
    end
end)

-- UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 290)
Main.Position = UDim2.new(0, 100, 0, 100)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.Active, Main.Draggable = true, true

local function makeButton(text, y, toggle)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.MouseButton1Click:Connect(function()
        Settings[toggle] = not Settings[toggle]
        btn.Text = text .. ": " .. (Settings[toggle] and "ON" or "OFF")
    end)
end

makeButton("Silent Aim", 10, "SilentAim")
makeButton("ESP", 50, "ESP")
makeButton("Kill Aura", 90, "KillAura")
makeButton("Aim Lock", 130, "AimLock")

-- Smoothness Slider
local smoothSlider = Instance.new("TextButton", Main)
smoothSlider.Size = UDim2.new(1, -10, 0, 30)
smoothSlider.Position = UDim2.new(0, 5, 0, 170)
smoothSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
smoothSlider.TextColor3 = Color3.new(1, 1, 1)
smoothSlider.Text = "Smoothness: " .. Settings.AimSmoothness
smoothSlider.MouseButton1Click:Connect(function()
    Settings.AimSmoothness = Settings.AimSmoothness + 0.05
    if Settings.AimSmoothness > 1 then Settings.AimSmoothness = 0.01 end
    smoothSlider.Text = "Smoothness: " .. string.format("%.2f", Settings.AimSmoothness)
end)

-- Minimize
local mini = Instance.new("TextButton", ScreenGui)
mini.Text, mini.Visible = "≡", false
mini.Size = UDim2.new(0, 30, 0, 30)
mini.Position = UDim2.new(0, 10, 0, 10)
mini.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
mini.MouseButton1Click:Connect(function()
    Main.Visible, mini.Visible = true, false
end)

local minBtn = Instance.new("TextButton", Main)
minBtn.Text = "_"
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -25, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minBtn.MouseButton1Click:Connect(function()
    Main.Visible, mini.Visible = false, true
end)
