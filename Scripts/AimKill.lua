-- 📦 SERVICES & VARIABLES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ⚙️ SETTINGS
local SilentAim = false
local KillAura = false
local ESP_Enabled = false
local espObjects = {}

-- 📌 FUNCTION: Kiểm tra có phải địch không
local function IsEnemy(p)
    return p ~= LocalPlayer
        and p.Team ~= nil
        and LocalPlayer.Team ~= nil
        and p.Team ~= LocalPlayer.Team
        and p.Character
        and p.Character:FindFirstChild("Humanoid")
        and p.Character.Humanoid.Health > 0
end

-- 📌 FUNCTION: Lấy danh sách địch
local function GetEnemies()
    local enemies = {}
    for _, p in pairs(Players:GetPlayers()) do
        if IsEnemy(p) then
            table.insert(enemies, p)
        end
    end
    return enemies
end

-- 📌 FUNCTION: Kiểm tra có bị vật cản không
local function HasLineOfSight(pos)
    local ray = Ray.new(Camera.CFrame.Position, (pos - Camera.CFrame.Position).Unit * 500)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return not hit or hit:IsDescendantOf(Workspace.Characters)
end

-- 📌 FUNCTION: Lấy kẻ địch gần nhất
local function GetClosestEnemy()
    local closest = nil
    local shortest = math.huge
    for _, enemy in pairs(GetEnemies()) do
        local head = enemy.Character and enemy.Character:FindFirstChild("Head")
        if head then
            local pos, visible = Camera:WorldToViewportPoint(head.Position)
            if visible and HasLineOfSight(head.Position) then
                local distance = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if distance < shortest then
                    shortest = distance
                    closest = head
                end
            end
        end
    end
    return closest
end

-- 📌 FUNCTION: Tạo ESP cho 1 player
local function CreateESP(p)
    if espObjects[p] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(0, 255, 0)

    local name = Drawing.new("Text")
    name.Size = 13
    name.Color = Color3.new(1, 1, 1)
    name.Center = true
    name.Outline = true

    espObjects[p] = {Box = box, Line = line, Name = name}
end

-- 📌 FUNCTION: Update ESP liên tục
local function UpdateESP()
    for _, p in pairs(GetEnemies()) do
        CreateESP(p)
    end

    for p, draw in pairs(espObjects) do
        if ESP_Enabled and IsEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local root = p.Character.HumanoidRootPart
            local screenPos, visible = Camera:WorldToViewportPoint(root.Position)
            if visible then
                draw.Box.Size = Vector2.new(60, 100)
                draw.Box.Position = Vector2.new(screenPos.X - 30, screenPos.Y - 50)
                draw.Box.Visible = true

                draw.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                draw.Line.To = Vector2.new(screenPos.X, screenPos.Y)
                draw.Line.Visible = true

                local dist = (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                local hp = math.floor(p.Character.Humanoid.Health)
                draw.Name.Text = string.format("%s [%dhp | %dm]", p.Name, hp, math.floor(dist))
                draw.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 60)
                draw.Name.Visible = true
            else
                draw.Box.Visible = false
                draw.Line.Visible = false
                draw.Name.Visible = false
            end
        else
            draw.Box.Visible = false
            draw.Line.Visible = false
            draw.Name.Visible = false
        end
    end
end

-- 🧠 HOOK Silent Aim
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()
    if tostring(self) == "Sync" and method == "Fire" and SilentAim then
        local head = GetClosestEnemy()
        if head then
            args[2] = head.CFrame
            return old(self, unpack(args))
        end
    end
    return old(self, ...)
end)

-- 🔁 Main loop
RunService.RenderStepped:Connect(function()
    if ESP_Enabled then UpdateESP() end
    if KillAura then
        for _, p in pairs(GetEnemies()) do
            local head = p.Character and p.Character:FindFirstChild("Head")
            if head and HasLineOfSight(head.Position) then
                local sync = LocalPlayer:FindFirstChild("Sync") or game:GetService("ReplicatedStorage"):FindFirstChild("Sync")
                if sync then
                    sync:Fire(sync, p.Name .. "_shoot", nil, head.CFrame, math.random(), "Gun", {})
                end
            end
        end
    end
end)

-- 📋 UI (OrionLib)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local Window = OrionLib:MakeWindow({Name = "Gunfight Arena | HuyESP", HidePremium = false, SaveConfig = false, ConfigFolder = "GunfightESP"})

local tab = Window:MakeTab({Name = "Main", Icon = "", PremiumOnly = false})
tab:AddToggle({Name = "Silent Aim", Default = false, Callback = function(v) SilentAim = v end})
tab:AddToggle({Name = "Kill Aura (AutoKill)", Default = false, Callback = function(v) KillAura = v end})
tab:AddToggle({Name = "ESP [Box/Line/Name]", Default = false, Callback = function(v) ESP_Enabled = v end})

OrionLib:Init()
