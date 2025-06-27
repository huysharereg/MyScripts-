--// 🔥 GUNFIGHT ARENA FULL SCRIPT BY WUMBJI + CHATGPT (Enhanced)
// ✅ Includes: Silent Aim with wall-check, AimLock, Smooth Aim, KillAura (line of sight), Weapon/Camo changer, Orion UI

-- Optimization
local game, workspace = game, workspace
local players = game:GetService("Players")
local player = players.LocalPlayer
local rs = game:GetService("RunService")
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local teams = game:GetService("Teams")

local silentaim, aimlock, smoothlock, killAura, noforcefields = false, false, false, false, false
local aimDelay = 0.05 -- default smooth aim delay

-- Load Orion UI
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
OrionLib:MakeNotification({Name = "GunFight Arena Enhanced", Content = "SilentAim, AimLock, KillAura, etc", Image = "", Time = 5})

local weapons, camos = {}, {}
for _,v in pairs(game:GetService("ReplicatedStorage").Weapons:GetChildren()) do table.insert(weapons,v.Name) end
for _,v in pairs(game:GetService("ReplicatedStorage").Camos:GetChildren()) do table.insert(camos,v.Name) end

-- Remove sway
local s = player.PlayerScripts.Vortex.Modifiers.Steadiness
local m = player.PlayerScripts.Vortex.Modifiers.Mobility
local function r() if s and s.Value>0 then s.Value=0 end if m and m.Value>0 then m.Value=0 end end
if s then s.Changed:Connect(r) end if m then m.Changed:Connect(r) end r()

-- Utility
local function hasLineOfSight(targetPos)
    local ray = Ray.new(camera.CFrame.Position, (targetPos - camera.CFrame.Position).Unit * 500)
    local hit = workspace:FindPartOnRay(ray, player.Character)
    return not hit or hit:IsDescendantOf(workspace.Characters)
end

local function get_closest_enemy()
    local closest, distance = nil, math.huge
    for _, character in pairs(workspace:GetChildren()) do
        local p = players:FindFirstChild(character.Name)
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if p and p ~= player and hrp and p.Team ~= player.Team and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen and hasLineOfSight(hrp.Position) then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - uis:GetMouseLocation()).Magnitude
                if dist < distance then
                    distance, closest = dist, character
                end
            end
        end
    end
    return closest
end

-- Silent Aim Hook
local events = {
    ["ShootEvent"] = function(arg)
        return (typeof(arg) == "Instance" and arg.Name and (string.find(arg.Name, players.LocalPlayer.Name)))
    end,
}
local old_namecall
old_namecall = hookmetamethod(game, "__namecall", function(self, caller, message, ...)
    local method = getnamecallmethod()
    if method == "Fire" and self.Name == "Sync" then
        for event, identify in pairs(events) do
            if event == "ShootEvent" and identify(message) then
                local closest = get_closest_enemy()
                local ammo, cframe, id, weapon, projectile = ...
                if closest and closest:FindFirstChild("Head") and silentaim and hasLineOfSight(closest.Head.Position) then
                    cframe = closest.Head.CFrame
                    return old_namecall(self, caller, message, ammo, cframe, id, weapon, projectile, ...)
                end
            end
        end
    end
    return old_namecall(self, caller, message, ...)
end)

-- KillAura + Smooth Aim
rs.RenderStepped:Connect(function()
    local target = get_closest_enemy()
    if aimlock and target and target:FindFirstChild("Head") then
        local headPos = target.Head.Position
        if hasLineOfSight(headPos) then
            local newCF = CFrame.lookAt(camera.CFrame.Position, headPos)
            camera.CFrame = camera.CFrame:Lerp(newCF, aimDelay)
        end
    end

    if killAura and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        for _, p in pairs(players:GetPlayers()) do
            if p ~= player and p.Team ~= player.Team and p.Character and p.Character:FindFirstChild("Head") and hasLineOfSight(p.Character.Head.Position) then
                local sync = player:FindFirstChild("Sync") or game:GetService("ReplicatedStorage"):FindFirstChild("Sync")
                if sync and typeof(sync) == "Instance" and sync:IsA("RemoteEvent") then
                    local args = {nil, p.Character.Head.CFrame, math.random(), "Gun", {}}
                    sync:Fire(sync, p.Name.."_shoot", unpack(args))
                end
            end
        end
    end

    if noforcefields then
        for _,v in pairs(workspace.Env:GetChildren()) do
            if string.find(v.Name, "Forcefield") and v.FullSphere and v.FullSphere.Color ~= Color3.fromRGB(0, 102, 255) then
                v:Destroy()
            end
        end
    end
end)

-- UI
local win = OrionLib:MakeWindow({Name="Gunfight Arena | Enhanced", HidePremium=false, SaveConfig=false, ConfigFolder="gunarena"})
local aimtab = win:MakeTab({Name="Aim", Icon="", PremiumOnly=false})
local misc = win:MakeTab({Name="Misc", Icon="", PremiumOnly=false})
local weapon = win:MakeTab({Name="Weapons", Icon="", PremiumOnly=false})
local settings = win:MakeTab({Name="Settings", Icon="", PremiumOnly=false})

-- Aim Settings
aimtab:AddToggle({Name="Silent Aim", Default=false, Callback=function(v) silentaim=v end})
aimtab:AddToggle({Name="AimLock", Default=false, Callback=function(v) aimlock=v end})
aimtab:AddToggle({Name="Smooth Aim (Lerp)", Default=false, Callback=function(v) smoothlock=v end})
aimtab:AddSlider({Name="Smooth Delay", Min=0.01, Max=0.2, Default=0.05, Increment=0.01, Callback=function(val) aimDelay=val end})
aimtab:AddToggle({Name="Kill Aura", Default=false, Callback=function(v) killAura=v end})

-- Misc
misc:AddToggle({Name="No Forcefields", Default=false, Callback=function(v) noforcefields=v end})

-- Weapon Camo
weapon:AddDropdown({Name="Primary", Options=weapons, Callback=function(v) player:SetAttribute("Primary",v) end})
weapon:AddDropdown({Name="Primary Camo", Options=camos, Callback=function(v) player:SetAttribute("PrimaryCamo",v) end})
weapon:AddDropdown({Name="Secondary", Options=weapons, Callback=function(v) player:SetAttribute("Secondary",v) end})
weapon:AddDropdown({Name="Secondary Camo", Options=camos, Callback=function(v) player:SetAttribute("SecondaryCamo",v) end})

-- Settings
settings:AddButton({Name="Destroy UI", Callback=function() OrionLib:Destroy() end})

OrionLib:Init()
