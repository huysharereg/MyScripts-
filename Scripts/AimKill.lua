-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FLAGS
local silentAim = false
local aimLock = false
local smoothAim = false
local aimDelay = 0.05
local killAura = false
local ESP_Enabled = false
local noForceFields = false

-- ESP TABLE
local ESP = {}

-- TEAM & MAP
local function GetCurrentMap()
    for _,v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v.Name ~= "Characters" and v.Name ~= "Env" then
            return v.Name
        end
    end
    return "Unknown"
end

local function GetEnemyPlayers()
    local enemies = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(enemies, p)
        end
    end
    return enemies
end

-- ESP DRAWING
function CreateESP(p)
    if ESP[p] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(255,0,0)

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.fromRGB(0,255,0)

    local name = Drawing.new("Text")
    name.Size = 13
    name.Center = true
    name.Outline = true
    name.Color = Color3.new(1,1,1)

    ESP[p] = {Box=box, Line=line, Name=name}
end

function UpdateESP()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then CreateESP(p) end
    end
    for p,draw in pairs(ESP) do
        local char = p.Character
        if ESP_Enabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local pos, visible = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if visible then
                draw.Box.Size = Vector2.new(60,100)
                draw.Box.Position = Vector2.new(pos.X-30, pos.Y-50)
                draw.Box.Visible = true
                draw.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                draw.Line.To = Vector2.new(pos.X,pos.Y)
                draw.Line.Visible = true
                draw.Name.Text = string.format("%s [%dhp | %dm]", p.Name, math.floor(char.Humanoid.Health), math.floor((char.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude))
                draw.Name.Position = Vector2.new(pos.X, pos.Y-60)
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

-- AIM
function hasLineOfSight(targetPos)
    local ray = Ray.new(Camera.CFrame.Position, (targetPos - Camera.CFrame.Position).Unit * 500)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return not hit or hit:IsDescendantOf(Workspace.Characters)
end

function getClosestEnemy()
    local closest, dist = nil, math.huge
    for _,p in pairs(GetEnemyPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local pos, visible = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if visible and hasLineOfSight(p.Character.Head.Position) then
                local diff = (Vector2.new(pos.X,pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if diff < dist then
                    dist = diff
                    closest = p.Character
                end
            end
        end
    end
    return closest
end

-- HOOK SILENT
local old
old = hookmetamethod(game, "__namecall", function(self,...)
    local args = {...}
    local method = getnamecallmethod()
    if tostring(self) == "Sync" and method == "Fire" and silentAim then
        local target = getClosestEnemy()
        if target and target:FindFirstChild("Head") then
            args[2] = target.Head.CFrame
            return old(self, unpack(args))
        end
    end
    return old(self,...)
end)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    if aimLock then
        local t = getClosestEnemy()
        if t and t:FindFirstChild("Head") then
            local look = CFrame.lookAt(Camera.CFrame.Position, t.Head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(look, smoothAim and aimDelay or 1)
        end
    end
    if killAura then
        for _,p in pairs(GetEnemyPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") and hasLineOfSight(p.Character.Head.Position) then
                local remote = LocalPlayer:FindFirstChild("Sync") or ReplicatedStorage:FindFirstChild("Sync")
                if remote then
                    remote:Fire(remote, p.Name.."_shoot", nil, p.Character.Head.CFrame, math.random(), "Gun", {})
                end
            end
        end
    end
    if noForceFields then
        local env = Workspace:FindFirstChild("Env")
        if env then
            for _,v in pairs(env:GetChildren()) do
                if v.Name:lower():find("forcefield") then
                    v:Destroy()
                end
            end
        end
    end
    if ESP_Enabled then UpdateESP() end
end)

-- UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local Window = OrionLib:MakeWindow({Name="Gunfight Arena Pro", HidePremium=false, SaveConfig=false, ConfigFolder="GFAPro"})

local a = Window:MakeTab({Name="Aimbot", Icon="", PremiumOnly=false})
a:AddToggle({Name="Silent Aim", Default=false, Callback=function(v) silentAim = v end})
a:AddToggle({Name="AimLock", Default=false, Callback=function(v) aimLock = v end})
a:AddToggle({Name="Smooth Aim", Default=false, Callback=function(v) smoothAim = v end})
a:AddSlider({Name="Smooth Delay", Min=0.01, Max=0.2, Default=0.05, Increment=0.01, Callback=function(v) aimDelay = v end})
a:AddToggle({Name="Kill Aura", Default=false, Callback=function(v) killAura = v end})

local e = Window:MakeTab({Name="ESP", Icon="", PremiumOnly=false})
e:AddToggle({Name="Enable ESP", Default=false, Callback=function(v) ESP_Enabled = v end})

local m = Window:MakeTab({Name="Misc", Icon="", PremiumOnly=false})
m:AddToggle({Name="No ForceFields", Default=false, Callback=function(v) noForceFields = v end})
m:AddButton({Name="Print Current Map", Callback=function() print("🗺️ Map:", GetCurrentMap()) end})
m:AddButton({Name="Print Team", Callback=function() print("🏳️ Team:", LocalPlayer.Team and LocalPlayer.Team.Name or "Unknown") end})

OrionLib:Init()
