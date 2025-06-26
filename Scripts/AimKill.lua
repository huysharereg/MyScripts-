-- UI
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sea = "Unknown"

-- Tự nhận diện Sea đang ở
if game.PlaceId == 2753915549 then
    Sea = "Sea 1"
elseif game.PlaceId == 4442272183 then
    Sea = "Sea 2"
elseif game.PlaceId == 7449423635 then
    Sea = "Sea 3"
end

-- Tải thư viện GUI Orion
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "🌊 BloxFruit Pro Hub | Sea: "..Sea,
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "BloxHub"
})

-- Avatar + Tên người dùng
local avatarTab = Window:MakeTab({Name = "Account", Icon = "", PremiumOnly = false})
avatarTab:AddParagraph("User:", LocalPlayer.Name)
avatarTab:AddLabel("Sea hiện tại: "..Sea)

--auto farm
_G.FarmMob = false
_G.FarmBoss = false
_G.AutoQuest = false

local farmTab = Window:MakeTab({Name = "🌿 Auto Farm", Icon = "rbxassetid://4483345998", PremiumOnly = false})

farmTab:AddToggle({
    Name = "✅ Auto Farm Mob",
    Default = false,
    Callback = function(Value) _G.FarmMob = Value end
})

farmTab:AddToggle({
    Name = "👑 Auto Farm Boss",
    Default = false,
    Callback = function(Value) _G.FarmBoss = Value end
})

farmTab:AddToggle({
    Name = "📝 Auto Quest",
    Default = false,
    Callback = function(Value) _G.AutoQuest = Value end
})

--auto ken/haki
_G.AutoKen = false
_G.AutoStat = false

local miscTab = Window:MakeTab({Name = "🔧 Misc Features", Icon = "rbxassetid://4483345998", PremiumOnly = false})

miscTab:AddToggle({
    Name = "⚔️ Auto Ken/Haki",
    Default = false,
    Callback = function(Value) _G.AutoKen = Value end
})

miscTab:AddToggle({
    Name = "📊 Auto Stat (All vào Melee)",
    Default = false,
    Callback = function(Value) _G.AutoStat = Value end
})

miscTab:AddButton({
    Name = "🔁 Server Hop",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"))
        for i,v in pairs(Servers.data) do
            if v.playing < v.maxPlayers then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id)
                break
            end
        end
    end
})

--teleprot
local teleportTab = Window:MakeTab({Name = "📍 Teleport", Icon = "", PremiumOnly = false})

teleportTab:AddButton({
    Name = "🚢 Đến Sea 1",
    Callback = function() game:GetService("TeleportService"):Teleport(2753915549) end
})

teleportTab:AddButton({
    Name = "⚓ Đến Sea 2",
    Callback = function() game:GetService("TeleportService"):Teleport(4442272183) end
})

teleportTab:AddButton({
    Name = "🌌 Đến Sea 3",
    Callback = function() game:GetService("TeleportService"):Teleport(7449423635) end
})

--farm boss
local TweenService = game:GetService("TweenService")
local function tweenTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local tween = TweenService:Create(char.HumanoidRootPart, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {CFrame = pos})
        tween:Play()
        tween.Completed:Wait()
    end
end

-- Danh sách Boss (cần cập nhật thêm nếu game update)
local BossList = {
    ["Sea 1"] = {
        {Name="The Gorilla King", CFrame=CFrame.new(-1599, 12, 160)},
        {Name="Buggy", CFrame=CFrame.new(-1140, 14, 4322)},
    },
    ["Sea 2"] = {
        {Name="Don Swan", CFrame=CFrame.new(2284, 15, 705)},
    },
    ["Sea 3"] = {
        {Name="Kaidou Clone", CFrame=CFrame.new(-12548, 401, -7583)},
    }
}

-- Hàm kiểm tra Boss có tồn tại
local function getAvailableBoss()
    for _, boss in ipairs(BossList[Sea] or {}) do
        local found = workspace:FindFirstChild(boss.Name)
        if found and found:FindFirstChild("Humanoid") and found.Humanoid.Health > 0 then
            return boss
        end
    end
    return nil
end

--tìm boss
task.spawn(function()
    while task.wait(1) do
        if _G.FarmBoss then
            local boss = getAvailableBoss()
            if boss then
                tweenTo(boss.CFrame + Vector3.new(0,5,0))
                repeat
                    task.wait(0.2)
                    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                until not workspace:FindFirstChild(boss.Name) or workspace[boss.Name].Humanoid.Health <= 0 or not _G.FarmBoss
            end
        end
    end
end)

--auto farm mob
function getClosestMob()
    local closest, dist = nil, math.huge
    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local d = (LocalPlayer.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
            if d < dist then
                closest = mob
                dist = d
            end
        end
    end
    return closest
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.FarmMob then
            local mob = getClosestMob()
            if mob then
                tweenTo(mob.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0))
                repeat
                    task.wait(0.1)
                    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                until not mob or mob.Humanoid.Health <= 0 or not _G.FarmMob
            end
        end
    end
end)

--auto nhiệm vụ
local QuestTable = {
    ["Bandit"] = {MinLevel = 10, QuestName = "BanditQuest1", NpcName = "QuestGiver", Pos = CFrame.new(1060, 16, 1548)},
    ["Monkey"] = {MinLevel = 15, QuestName = "JungleQuest", NpcName = "QuestGiver", Pos = CFrame.new(-1600, 12, 161)},
    -- Thêm các mob khác tại đây
}

_G.CustomMob = nil -- Nếu chọn mob cụ thể

function getBestQuest()
    local level = LocalPlayer.Data.Level.Value
    for mobName, info in pairs(QuestTable) do
        if level >= info.MinLevel then
            if _G.CustomMob and _G.CustomMob ~= mobName then continue end
            return mobName, info
        end
    end
    return nil, nil
end

task.spawn(function()
    while task.wait(2) do
        if _G.AutoQuest then
            local mobName, data = getBestQuest()
            if data and not LocalPlayer.PlayerGui.Main.Quest.Visible then
                tweenTo(data.Pos + Vector3.new(0,5,0))
                wait(1.2)
                local npc = workspace:FindFirstChild(data.NpcName)
                if npc then
                    local args = {
                        [1] = data.QuestName,
                        [2] = 1
                    }
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest", unpack(args))
                end
            end
        end
    end
end)

--auto start
local AutoStatPreset = {
    Melee = true,
    Defense = false,
    Sword = false,
    Gun = false,
    BloxFruit = false
}

task.spawn(function()
    while task.wait(3) do
        if _G.AutoStat then
            local points = LocalPlayer.Data.Points.Value
            if points > 0 then
                for stat, enabled in pairs(AutoStatPreset) do
                    if enabled then
                        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("AddPoint", stat, points)
                        break
                    end
                end
            end
        end
    end
end)
-- auto bật haki khi combat
task.spawn(function()
    while task.wait(1) do
        if _G.AutoKen then
            if LocalPlayer.Character:FindFirstChild("HasBuso") == nil then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
            end
        end
    end
end)
--gui chọn mob
farmTab:AddTextbox({
    Name = "🎯 Tên mob muốn farm (tuỳ chọn)",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        _G.CustomMob = Value
    end
})
--
