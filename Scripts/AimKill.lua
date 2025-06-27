-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Uis = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local SilentAim = false
local KillAura = false
local ESP_Enabled = false
local AimLock = false
local KillAuraRange = 100
local AimSmooth = false
local AimDelay = 0.1

-- UTILS
local function IsEnemy(p)
    return p ~= LocalPlayer and p.Team and LocalPlayer.Team and p.Team ~= LocalPlayer.Team
end

local function GetEnemies()
    return Players:GetPlayers()
end

local function HasLOS(pos)
    local ray = Ray.new(Camera.CFrame.Position, (pos - Camera.CFrame.Position).Unit * 500)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return not hit or hit:IsDescendantOf(Workspace.Characters)
end

local function GetClosestEnemyHead()
    local bestHead, bestDist = nil, math.huge
    for _, p in pairs(GetEnemies()) do
        if IsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local screen, vis = Camera:WorldToViewportPoint(head.Position)
            if vis and HasLOS(head.Position) then
                local dist = (Uis:GetMouseLocation() - Vector2.new(screen.X, screen.Y)).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestHead = head
                end
            end
        end
    end
    return bestHead
end

-- HOOK SILENT AIM
local old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if tostring(self) == "Sync" and getnamecallmethod() == "Fire" then
        if SilentAim then
            local head = GetClosestEnemyHead()
            if head then args[2] = head.CFrame end
        end
        if KillAura then
            for _, p in pairs(GetEnemies()) do
                if IsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
                    local head = p.Character.Head
                    if (head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= KillAuraRange and HasLOS(head.Position) then
                        args[2] = head.CFrame
                        break
                    end
                end
            end
        end
        return old(self, unpack(args))
    end
    return old(self, ...)
end))

-- ESP
local ESPData = {}
local function CreateESP(p)
    if ESPData[p] then return end
    local box = Drawing.new("Square"); box.Thickness=1; box.Filled=false; box.Color=Color3.fromRGB(255,0,0)
    local line = Drawing.new("Line");   line.Thickness=1; line.Color=Color3.fromRGB(0,255,0)
    local txt  = Drawing.new("Text");   txt.Center=true; txt.Outline=true; txt.Color=Color3.new(1,1,1); txt.Size=13
    ESPData[p] = {B=box,L=line,T=txt}
end

local function UpdateESP()
    for _,p in pairs(GetEnemies()) do
        if IsEnemy(p) then CreateESP(p) end
    end
    for p,d in pairs(ESPData) do
        if ESP_Enabled and IsEnemy(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") then
            local root = p.Character.HumanoidRootPart
            local head = p.Character.Head
            local screen, vis = Camera:WorldToViewportPoint(root.Position)
            if vis then
                d.B.Size = Vector2.new(60,100)
                d.B.Position = Vector2.new(screen.X-30, screen.Y-50); d.B.Visible=true
                d.L.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                d.L.To = Vector2.new(screen.X, screen.Y); d.L.Visible=true
                local dist = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                local hp = math.floor(p.Character.Humanoid.Health)
                d.T.Text = string.format("%s [%dhp %dm]", p.Name, hp, dist)
                d.T.Position = Vector2.new(screen.X, screen.Y-60); d.T.Visible=true
            else
                d.B.Visible=false; d.L.Visible=false; d.T.Visible=false
            end
        else
            d.B.Visible=false; d.L.Visible=false; d.T.Visible=false
        end
    end
end

-- AIMLOCK
RunService.RenderStepped:Connect(function()
    if AimLock then
        local head = GetClosestEnemyHead()
        if head then
            local targetCF = CFrame.lookAt(Camera.CFrame.Position, head.Position)
            local r = AimSmooth and AimDelay or 1
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, r)
        end
    end
    if ESP_Enabled then UpdateESP() end
end)

-- UI
local Orion = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local Window = Orion:MakeWindow({Name="GFA Pro+ Enhanced", HidePremium=false, SaveConfig=false, ConfigFolder="GFA_ProPlus"})

local Tab = Window:MakeTab({Name="Main", Icon="", PremiumOnly=false})
Tab:AddToggle({Name="Silent Aim",Default=false,Callback=function(v) SilentAim=v end})
Tab:AddToggle({Name="Kill Aura",Default=false,Callback=function(v) KillAura=v end})
Tab:AddSlider({Name="KillAura Range",Min=20,Max=300,Default=100,Callback=function(v) KillAuraRange=v end})
Tab:AddToggle({Name="ESP",Default=false,Callback=function(v) ESP_Enabled=v end})
Tab:AddToggle({Name="AimLock",Default=false,Callback=function(v) AimLock=v end})
Tab:AddToggle({Name="Smooth Aim Lock",Default=false,Callback=function(v) AimSmooth=v end})
Tab:AddSlider({Name="AimLock Delay",Min=0.01,Max=0.3,Default=0.1,Callback=function(v) AimDelay=v end})

Orion:Init()
