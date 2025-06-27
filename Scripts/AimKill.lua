-- 📌 Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local SilentAimEnabled = true
local KillAuraEnabled = true
local ESPEnabled = true
local KillAuraRange = 60

-- 📌 Helper
local function getClosestEnemy()
    local closest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Team ~= LocalPlayer.Team then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local diff = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if diff < dist then
                    dist = diff
                    closest = p
                end
            end
        end
    end
    return closest
end

-- 📌 ESP Setup
local ESP = {}

function addESP(player)
    if ESP[player] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.new(1, 0, 0)
    box.Filled = false

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.new(0, 1, 0)

    local text = Drawing.new("Text")
    text.Size = 14
    text.Color = Color3.new(1, 1, 1)
    text.Center = true
    text.Outline = true

    ESP[player] = {box = box, line = line, text = text}
end

Players.PlayerAdded:Connect(addESP)
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then addESP(p) end
end

-- 📌 Silent Aim Hook
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if SilentAimEnabled and method == "FireServer" and tostring(self):lower():find("shoot") then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            args[1] = target.Character.Head.Position
            return old(self, unpack(args))
        end
    end
    return old(self, ...)
end)

-- 📌 Render Loop
RunService.RenderStepped:Connect(function()
    -- ESP Update
    for player, data in pairs(ESP) do
        if ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            local hrp = player.Character.HumanoidRootPart
            local head = player.Character.Head
            local hp = math.floor(player.Character:FindFirstChild("Humanoid").Health)
            local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)

            if visible then
                -- Box
                data.box.Size = Vector2.new(50, 100)
                data.box.Position = Vector2.new(pos.X - 25, pos.Y - 50)
                data.box.Visible = true

                -- Line
                data.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                data.line.To = Vector2.new(pos.X, pos.Y)
                data.line.Visible = true

                -- Name
                data.text.Text = player.Name .. " ["..hp.."hp | "..dist.."m]"
                data.text.Position = Vector2.new(pos.X, pos.Y - 60)
                data.text.Visible = true
            else
                data.box.Visible = false
                data.line.Visible = false
                data.text.Visible = false
            end
        else
            data.box.Visible = false
            data.line.Visible = false
            data.text.Visible = false
        end
    end

    -- Kill Aura
    if KillAuraEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if d <= KillAuraRange then
                    local evt = LocalPlayer:FindFirstChildWhichIsA("RemoteEvent", true)
                    if evt and tostring(evt):lower():find("shoot") then
                        evt:FireServer(p.Character.Head.Position)
                    end
                end
            end
        end
    end
end)

-- ✅ Toggle GUI (simple buttons)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 140)
Frame.Position = UDim2.new(0, 20, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true

local function addButton(text, posY, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Text = text
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.MouseButton1Click:Connect(callback)
end

addButton("Toggle Silent Aim", 10, function()
    SilentAimEnabled = not SilentAimEnabled
end)
addButton("Toggle Kill Aura", 50, function()
    KillAuraEnabled = not KillAuraEnabled
end)
addButton("Toggle ESP", 90, function()
    ESPEnabled = not ESPEnabled
end)
