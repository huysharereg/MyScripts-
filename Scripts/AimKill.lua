-- FIX OrionLib không dính lỗi ThirdPartyUserService
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Trung1107/OrionLite/main/orionlite.lua"))()

local Window = Library:MakeWindow({
	Name = "Gunfight Arena HUB [SAFE]",
	HidePremium = false,
	IntroEnabled = false
})

-- Cài đặt
local Settings = {
	SilentAim = false,
	ESP = false,
	KillAura = false,
	KillAuraRange = 50
}

-- Tab chính
local MainTab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998"
})

MainTab:AddToggle({
	Name = "Silent Aim",
	Default = false,
	Callback = function(v) Settings.SilentAim = v end
})

MainTab:AddToggle({
	Name = "ESP",
	Default = false,
	Callback = function(v) Settings.ESP = v end
})

MainTab:AddToggle({
	Name = "Auto Kill (Kill Aura)",
	Default = false,
	Callback = function(v) Settings.KillAura = v end
})

MainTab:AddSlider({
	Name = "Kill Aura Range",
	Min = 10,
	Max = 100,
	Default = 50,
	Callback = function(v) Settings.KillAuraRange = v end
})

-- Khởi động UI
Library:Init()

-- ===== CORE SCRIPT =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Lấy địch gần nhất
local function getClosestEnemy()
	local closest = nil
	local shortest = math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") then
			local pos, visible = Camera:WorldToViewportPoint(plr.Character.Head.Position)
			if visible then
				local diff = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
				if diff < shortest then
					shortest = diff
					closest = plr
				end
			end
		end
	end
	return closest
end

-- Silent Aim Hook
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
	local args = { ... }
	local method = getnamecallmethod()

	if Settings.SilentAim and method == "FireServer" and (tostring(self):lower():find("shoot") or tostring(self):lower():find("sync")) then
		local target = getClosestEnemy()
		if target and target.Character and target.Character:FindFirstChild("Head") then
			args[2] = target.Character.Head.CFrame
			return old(self, unpack(args))
		end
	end

	return old(self, ...)
end)

-- ESP & Kill Aura
local espData = {}
RunService.RenderStepped:Connect(function()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") then
			local head = plr.Character.Head
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if head and root then
				local pos, visible = Camera:WorldToViewportPoint(head.Position)

				if Settings.ESP and visible then
					if not espData[plr] then
						local text = Drawing.new("Text")
						text.Size = 14
						text.Color = Color3.fromRGB(255, 255, 255)
						text.Center = true
						text.Outline = true
						espData[plr] = text
					end
					local distance = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
					espData[plr].Text = string.format("[%s] %dm", plr.Name, distance)
					espData[plr].Position = Vector2.new(pos.X, pos.Y - 20)
					espData[plr].Visible = true
				elseif espData[plr] then
					espData[plr].Visible = false
				end
			end
		elseif espData[plr] then
			espData[plr].Visible = false
		end
	end

	if Settings.KillAura then
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character and p.Character:FindFirstChild("Head") then
				local dist = (p.Character.Head.Position - LocalPlayer.Character.Head.Position).Magnitude
				if dist <= Settings.KillAuraRange then
					for _, remote in pairs(LocalPlayer:GetDescendants()) do
						if remote:IsA("RemoteEvent") and tostring(remote):lower():find("shoot") then
							remote:FireServer(nil, p.Character.Head.CFrame)
						end
					end
				end
			end
		end
	end
end)
