-- Tải UI Orion
local Orion = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Khởi tạo UI
local SeaName = ({[2753915549]="Sea 1",[4442272183]="Sea 2",[7449423635]="Sea 3"})[game.PlaceId] or "Unknown"
local Window = Orion:MakeWindow({
	Name = "Blox Fruits Trainer | "..SeaName,
	HidePremium = false,
	IntroEnabled = false,
	SaveConfig = false
})

-- Toggle lưu trữ
_G.farmMob, _G.farmBoss, _G.autoQuest, _G.autoKen, _G.autoStat = false,false,false,false,false
_G.autoDF, _G.autoAwaken, _G.autoBounty = false,false,false
local mobRange = 100
local selectedBoss = ""
local bossOptions = {"Gorilla King","Don Swan","Kaidou Clone"}

-- Tween đến vị trí
local function tweenToCF(cf)
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1.5), {CFrame = cf}):Play()
	end
end

-- 📌 Tab Account
local accTab = Window:MakeTab({Name = "Account", Icon = "", PremiumOnly = false})
accTab:AddParagraph("Player:", LocalPlayer.Name)
accTab:AddImage(LocalPlayer:GetUserThumbnailAsync(Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100))

-- 📌 Tab Farm
local farmTab = Window:MakeTab({Name = "Farm", Icon = "", PremiumOnly = false})
farmTab:AddToggle("Auto Farm Mob", false, function(v) _G.farmMob = v end)
farmTab:AddToggle("Auto Farm Boss", false, function(v) _G.farmBoss = v end)
farmTab:AddDropdown("Chọn Boss", bossOptions, function(v) selectedBoss = v end)
farmTab:AddSlider("Mob Range", 20, 300, 100, function(v) mobRange = v end)
farmTab:AddToggle("Auto Teleport Fruit", false, function(v) _G.autoDF = v end)
farmTab:AddToggle("Auto Bounty (PvP)", false, function(v) _G.autoBounty = v end)

-- 📌 Tab Misc
local miscTab = Window:MakeTab({Name = "Misc", Icon = "", PremiumOnly = false})
miscTab:AddToggle("Auto Quest", false, function(v) _G.autoQuest = v end)
miscTab:AddToggle("Auto Haki (Ken/Buso)", false, function(v) _G.autoKen = v end)
miscTab:AddToggle("Auto Awakening", false, function(v) _G.autoAwaken = v end)
miscTab:AddToggle("Auto Stat (Melee)", false, function(v) _G.autoStat = v end)
miscTab:AddButton("Server Hop", function()
	local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
	local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet(url)).data
	for _,v in pairs(servers) do
		if v.playing < v.maxPlayers then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
			break
		end
	end
end)

-- 📌 Tab Teleport
local tpTab = Window:MakeTab({Name = "Teleport", Icon = "", PremiumOnly = false})
tpTab:AddButton("→ Sea 1", function() TeleportService:Teleport(2753915549) end)
tpTab:AddButton("→ Sea 2", function() TeleportService:Teleport(4442272183) end)
tpTab:AddButton("→ Sea 3", function() TeleportService:Teleport(7449423635) end)

-- ⭐ Farm Mob
spawn(function()
	while task.wait(1) do
		if _G.farmMob then
			local closest, dmin = nil, math.huge
			for _,mob in ipairs(workspace.Enemies:GetChildren()) do
				if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
					local d = (LocalPlayer.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
					if d < mobRange and d < dmin then
						closest = mob
						dmin = d
					end
				end
			end
			if closest then
				tweenToCF(closest.HumanoidRootPart.CFrame * CFrame.new(0,5,0))
				local t = LocalPlayer.Character:FindFirstChildOfClass("Tool")
				if t then for _=1,5 do t:Activate(); task.wait(0.15) end end
			end
		end
	end
end)

-- ⭐ Farm Boss
local BossCF = {
	["Gorilla King"] = CFrame.new(-1599,12,160),
	["Don Swan"] = CFrame.new(2284,15,705),
	["Kaidou Clone"] = CFrame.new(-12548,401,-7583)
}
spawn(function()
	while wait(3) do
		if _G.farmBoss and BossCF[selectedBoss] then
			tweenToCF(BossCF[selectedBoss] * CFrame.new(0,5,0))
			local t = LocalPlayer.Character:FindFirstChildOfClass("Tool")
			if t then for _=1,5 do t:Activate(); task.wait(0.2) end end
		end
	end
end)

-- ⭐ Auto Quest
local questData = {
	["Gorilla Quest"] = {Level=10,Pos=CFrame.new(-1600,12,160)},
	["Don Quest"] = {Level=30,Pos=CFrame.new(2284,15,705)}
}
spawn(function()
	while wait(3) do
		if _G.autoQuest then
			local lvl = LocalPlayer.Data.Level.Value
			for q,data in pairs(questData) do
				if lvl >= data.Level and not LocalPlayer.PlayerGui.Main.Quest.Visible then
					tweenToCF(data.Pos * CFrame.new(0,5,0))
					wait(1)
					ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", q, 1)
				end
			end
		end
	end
end)

-- ⭐ Auto Haki
spawn(function()
	while wait(5) do
		if _G.autoKen and not LocalPlayer.Character:FindFirstChild("HasBuso") then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
		end
	end
end)

-- ⭐ Auto Stat
spawn(function()
	while wait(5) do
		if _G.autoStat then
			local pts = LocalPlayer.Data.Points.Value
			if pts > 0 then
				ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Melee", pts)
			end
		end
	end
end)

-- ⭐ Auto Awakening
spawn(function()
	while wait(4) do
		if _G.autoAwaken then
			pcall(function()
				local Remote = ReplicatedStorage.Remotes.CommF_
				Remote:InvokeServer("AwakeningProgress")
				Remote:InvokeServer("AwakeningTrigger")
			end)
		end
	end
end)

-- ⭐ Auto Bounty PvP
spawn(function()
	while wait(3) do
		if _G.autoBounty then
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					tweenToCF(p.Character.HumanoidRootPart.CFrame * CFrame.new(0,6,0))
					wait(1)
					local t = LocalPlayer.Character:FindFirstChildOfClass("Tool")
					if t then for _=1,4 do t:Activate(); wait(0.15) end end
					break
				end
			end
		end
	end
end)

-- ⭐ Auto DF Tele
spawn(function()
	while wait(2) do
		if _G.autoDF then
			for _,v in pairs(workspace:GetDescendants()) do
				if v:IsA("Tool") and v.Name:lower():find("fruit") then
					tweenToCF(v.Handle.CFrame * CFrame.new(0,3,0))
					wait(0.3)
					firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v.Handle, 0)
					firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v.Handle, 1)
					break
				end
			end
		end
	end
end)

Orion:Init()
