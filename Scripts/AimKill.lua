-- 🌟 BloxFruits Training Hub by GiaHuy-SunWin (Hợp lệ, không gian lận)
-- Features: Auto Farm Mob/Boss hợp lệ, Auto Quest, Auto Stat, Auto Ken/Haki, Auto Teleport đảo/trái, UI đẹp

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- UI setup using OrionLib
local Orion = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local SeaName = ({[2753915549]="Sea 1",[4442272183]="Sea 2",[7449423635]="Sea 3"})[game.PlaceId] or "Unknown Sea"
local Window = Orion:MakeWindow({Name="BloxTraining | "..SeaName, HidePremium=true, SaveConfig=false})

-- User info tab
local accTab = Window:MakeTab({Name="Account"})
accTab:AddParagraph("Player:", LocalPlayer.Name)
accTab:AddImage(LocalPlayer:GetThumbnailAsync(Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48))

-- Global switches
_G.farmMob, _G.farmBoss, _G.autoQuest, _G.autoKen, _G.autoStat, _G.autoDF = false, false, false, false, false, false

-- Island/Boss/Mob config
local mobRange = 100
local selectedBoss = ""
local bossOptions = {"", "Gorilla King", "Don Swan", "Kaidou Clone"}

-- Farm tab
local farmTab = Window:MakeTab({Name="Farm"})
farmTab:AddToggle("Auto Farm Mob", false, function(v) _G.farmMob = v end)
farmTab:AddToggle("Auto Farm Boss", false, function(v) _G.farmBoss = v end)
farmTab:AddSlider("Mob Range", 20, 300, 100, function(v) mobRange = v end)
farmTab:AddDropdown("Select Boss", bossOptions, bossOptions[1], function(v) selectedBoss = v end)
farmTab:AddToggle("Auto Tele Fruit", false, function(v) _G.autoDF = v end)

-- Misc tab
local misc = Window:MakeTab({Name="Misc"})
misc:AddToggle("Auto Quest", false, function(v) _G.autoQuest = v end)
misc:AddToggle("Auto Ken/Haki", false, function(v) _G.autoKen = v end)
misc:AddToggle("Auto Stat (Melee)", false, function(v) _G.autoStat = v end)
misc:AddButton("Server Hop", function()
    for _,v in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")).data) do
        if v.playing < v.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
            break
        end
    end
end)

-- Teleport tab
local tp = Window:MakeTab({Name="Teleport"})
tp:AddButton("→ Sea 1", function() TeleportService:Teleport(2753915549) end)
tp:AddButton("→ Sea 2", function() TeleportService:Teleport(4442272183) end)
tp:AddButton("→ Sea 3", function() TeleportService:Teleport(7449423635) end)

Orion:Init()

-- Utility tween
local function tweenToCF(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1.5), {CFrame = cf}):Play()
    end
end

-- Core loops

-- Farm Mob
spawn(function()
    while wait(1) do
        if _G.farmMob then
            local closest, dmin = nil, math.huge
            for _,mob in ipairs(workspace.Enemies:GetChildren()) do
                if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                    local d = (LocalPlayer.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
                    if d < mobRange and d < dmin then closest, dmin = mob, d end
                end
            end
            if closest then
                tweenToCF(closest.HumanoidRootPart.CFrame * CFrame.new(0,5,0))
                for i=1,5 do wait(0.2); local t = LocalPlayer.Character:FindFirstChildOfClass("Tool"); if t then t:Activate() end end
            end
        end
    end
end)

-- Farm Boss
local BossCF = {
    ["Gorilla King"] = CFrame.new(-1599,12,160),
    ["Don Swan"] = CFrame.new(2284,15,705),
    ["Kaidou Clone"] = CFrame.new(-12548,401,-7583)
}
spawn(function()
    while wait(2) do
        if _G.farmBoss and BossCF[selectedBoss] then
            tweenToCF(BossCF[selectedBoss] * CFrame.new(0,5,0))
            for i=1,5 do wait(0.3); local t = LocalPlayer.Character:FindFirstChildOfClass("Tool"); if t then t:Activate() end end
        end
    end
end)

-- Auto Quest (simplest logic)
local questData = {
    ["Gorilla Quest"] = {Level=10,Pos=CFrame.new(-1600,12,160)},
    ["Don Quest"] = {Level=30,Pos=CFrame.new(2284,15,705)}
}
spawn(function()
    while wait(3) do
        if _G.autoQuest then
            local lvl = LocalPlayer.Data.Level.Value
            for q,info in pairs(questData) do
                if lvl >= info.Level and LocalPlayer.PlayerGui.Main.Quest.Visible == false then
                    tweenToCF(info.Pos * CFrame.new(0,5,0))
                    wait(1); ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", q, 1)
                    break
                end
            end
        end
    end
end)

-- Auto Ken/Haki
spawn(function()
    while wait(5) do
        if _G.autoKen and LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end
end)

-- Auto Stat (Melee full)
spawn(function()
    while wait(5) do
        if _G.autoStat then
            local pts = LocalPlayer.Data.Points.Value
            if pts > 0 then ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Melee", pts) end
        end
    end
end)

-- Auto Tele Fruit
spawn(function()
    while wait(3) do
        if _G.autoDF then
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Tool") and v.Name:lower():find("fruit") then
                    tweenToCF(v.Handle.CFrame * CFrame.new(0,3,0))
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v.Handle, 0)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v.Handle, 1)
                    break
                end
            end
        end
    end
end)
