
-- ✅ FINAL GUNFIGHT ARENA SCRIPT (NO ERROR) - SilentAim, AimLock, KillAura, SmoothAim + UI

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- FLAGS
local silentAim = false
local aimLock = false
local killAura = false
local smoothAim = false
local aimDelay = 0.05

-- ANTI-FORCEFIELD
local noForceFields = false

-- GET WEAPONS & CAMOS
local weapons, camos = {}, {}
for _,v in pairs(ReplicatedStorage:WaitForChild("Weapons"):GetChildren()) do table.insert(weapons,v.Name) end
for _,v in pairs(ReplicatedStorage:WaitForChild("Camos"):GetChildren()) do table.insert(camos,v.Name) end

-- REMOVE SWAY
local steadiness = LocalPlayer.PlayerScripts.Vortex.Modifiers.Steadiness
local mobility = LocalPlayer.PlayerScripts.Vortex.Modifiers.Mobility
if steadiness then steadiness.Value = 0 end
if mobility then mobility.Value = 0 end

-- UTILS
local function hasLineOfSight(targetPos)
    local ray = Ray.new(Camera.CFrame.Position, (targetPos - Camera.CFrame.Position).Unit * 500)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return not hit or hit:IsDescendantOf(Workspace.Characters)
end

local function getClosestEnemy()
    local closest, minDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local headPos = plr.Character.Head.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            if onScreen and hasLineOfSight(headPos) then
                local diff = (Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if diff < minDist then
                    minDist = diff
                    closest = plr.Character
                end
            end
        end
    end
    return closest
end

-- HOOK SILENT AIM
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if method == "Fire" and tostring(self) == "Sync" then
        local target = getClosestEnemy()
        if target and silentAim and target:FindFirstChild("Head") and hasLineOfSight(target.Head.Position) then
            args[2] = target.Head.CFrame
            return old(self, unpack(args))
        end
    end

    return old(self, ...)
end)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    if aimLock and LocalPlayer.Character then
        local target = getClosestEnemy()
        if target and target:FindFirstChild("Head") and hasLineOfSight(target.Head.Position) then
            local cf = CFrame.lookAt(Camera.CFrame.Position, target.Head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(cf, smoothAim and aimDelay or 1)
        end
    end

    if killAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") then
                if hasLineOfSight(plr.Character.Head.Position) then
                    local sync = LocalPlayer:FindFirstChild("Sync") or ReplicatedStorage:FindFirstChild("Sync")
                    if sync then
                        local args = {nil, plr.Character.Head.CFrame, math.random(), "Gun", {}}
                        sync:Fire(sync, plr.Name.."_shoot", unpack(args))
                    end
                end
            end
        end
    end

    if noForceFields then
        for _,v in pairs(Workspace:FindFirstChild("Env"):GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("FullSphere") and v.FullSphere.Color ~= Color3.fromRGB(0, 102, 255) then
                v:Destroy()
            end
        end
    end
end)

-- UI: ORION LIBRARY
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local Window = OrionLib:MakeWindow({Name="Gunfight Arena (Final Build)", HidePremium=false, SaveConfig=false, ConfigFolder="gfa_final"})

-- AIM TAB
local aimTab = Window:MakeTab({Name="Aim", Icon="", PremiumOnly=false})
aimTab:AddToggle({Name="Silent Aim", Default=false, Callback=function(v) silentAim=v end})
aimTab:AddToggle({Name="AimLock (Cam follows)", Default=false, Callback=function(v) aimLock=v end})
aimTab:AddToggle({Name="Smooth Aim", Default=false, Callback=function(v) smoothAim=v end})
aimTab:AddSlider({Name="Smooth Delay", Min=0.01, Max=0.2, Default=0.05, Increment=0.01, Callback=function(v) aimDelay=v end})
aimTab:AddToggle({Name="Kill Aura", Default=false, Callback=function(v) killAura=v end})

-- WEAPON TAB
local weaponTab = Window:MakeTab({Name="Weapons", Icon="", PremiumOnly=false})
weaponTab:AddDropdown({Name="Primary Weapon", Options=weapons, Callback=function(v) LocalPlayer:SetAttribute("Primary", v) end})
weaponTab:AddDropdown({Name="Primary Camo", Options=camos, Callback=function(v) LocalPlayer:SetAttribute("PrimaryCamo", v) end})
weaponTab:AddDropdown({Name="Secondary Weapon", Options=weapons, Callback=function(v) LocalPlayer:SetAttribute("Secondary", v) end})
weaponTab:AddDropdown({Name="Secondary Camo", Options=camos, Callback=function(v) LocalPlayer:SetAttribute("SecondaryCamo", v) end})

-- MISC TAB
local miscTab = Window:MakeTab({Name="Misc", Icon="", PremiumOnly=false})
miscTab:AddToggle({Name="No Forcefields", Default=false, Callback=function(v) noForceFields = v end})

-- SETTINGS
local settingsTab = Window:MakeTab({Name="Settings", Icon="", PremiumOnly=false})
settingsTab:AddButton({Name="Destroy UI", Callback=function() OrionLib:Destroy() end})

OrionLib:Init()
