local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Settings = {
    Aimbot = false,
    AimbotAlways = false,
    AimbotSpeed = 1,
    AimbotDelay = 0,
    AimbotPrediction = true,
    AimbotTarget = "Head",
    ESP_Enemies = true,
    ESP_Teammates = false
}

-- 🧠 UI đơn giản
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GFA_UI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 350)
Frame.Position = UDim2.new(0.7, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Draggable = true
Frame.Active = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "Gunfight Arena Aimbot/ESP"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

-- 🧩 UI Toggle Elements
local function addToggle(name, posY, setting)
	local toggle = Instance.new("TextButton", Frame)
	toggle.Size = UDim2.new(1, -20, 0, 30)
	toggle.Position = UDim2.new(0, 10, 0, posY)
	toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
	toggle.TextColor3 = Color3.new(1,1,1)
	toggle.TextSize = 14
	toggle.Font = Enum.Font.SourceSansBold
	toggle.Text = name .. ": OFF"

	toggle.MouseButton1Click:Connect(function()
		Settings[setting] = not Settings[setting]
		toggle.Text = name .. ": " .. (Settings[setting] and "ON" or "OFF")
	end)
end

addToggle("Aimbot", 40, "Aimbot")
addToggle("Aimbot Always", 75, "AimbotAlways")
addToggle("ESP Enemies", 110, "ESP_Enemies")
addToggle("ESP Teammates", 145, "ESP_Teammates")

-- 🎯 Closest Enemy
function GetClosest()
	local closest, shortest = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimbotTarget) then
			local sameTeam = player.Team == LocalPlayer.Team
			if (not sameTeam) or Settings.ESP_Teammates then
				local pos, onScreen = Camera:WorldToViewportPoint(player.Character[Settings.AimbotTarget].Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
					if dist < shortest then
						shortest = dist
						closest = player
					end
				end
			end
		end
	end
	return closest
end

-- 🧲 Aimbot (chuột phải hoặc luôn)
RunService.RenderStepped:Connect(function()
	if not Settings.Aimbot then return end
	if not (Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then return end

	local target = GetClosest()
	if target and target.Character and target.Character:FindFirstChild(Settings.AimbotTarget) then
		local aimPart = target.Character[Settings.AimbotTarget]
		local targetPos = aimPart.Position
		if Settings.AimbotPrediction and target.Character:FindFirstChild("HumanoidRootPart") then
			targetPos = targetPos + target.Character.HumanoidRootPart.Velocity * 0.05
		end

		local screen = Camera:WorldToViewportPoint(targetPos)
		local moveVector = (Vector2.new(screen.X, screen.Y) - Vector2.new(Mouse.X, Mouse.Y)) / Settings.AimbotSpeed
		if Settings.AimbotDelay > 0 then wait(Settings.AimbotDelay) end
		mousemoverel(moveVector.X, moveVector.Y)
	end
end)

-- 👁️ ESP Full Box / Line / Name
local drawings = {}

RunService.RenderStepped:Connect(function()
	for _, d in pairs(drawings) do
		if d.Remove then d:Remove() end
	end
	table.clear(drawings)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local sameTeam = player.Team == LocalPlayer.Team
			if sameTeam and not Settings.ESP_Teammates then continue end
			if not sameTeam and not Settings.ESP_Enemies then continue end

			local headPos, visible = Camera:WorldToViewportPoint(player.Character.Head.Position)
			if visible then
				local name = Drawing.new("Text")
				name.Text = player.Name
				name.Position = Vector2.new(headPos.X, headPos.Y - 20)
				name.Color = sameTeam and Color3.new(0,1,0) or Color3.new(1,0,0)
				name.Size = 14
				name.Center = true
				name.Outline = true
				name.Visible = true
				table.insert(drawings, name)

				local box = Drawing.new("Square")
				box.Size = Vector2.new(50, 60)
				box.Position = Vector2.new(headPos.X - 25, headPos.Y - 30)
				box.Color = sameTeam and Color3.new(0,1,0) or Color3.new(1,0,0)
				box.Visible = true
				box.Thickness = 2
				table.insert(drawings, box)

				local line = Drawing.new("Line")
				line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
				line.To = Vector2.new(headPos.X, headPos.Y)
				line.Color = sameTeam and Color3.new(0,1,0) or Color3.new(1,0,0)
				line.Visible = true
				table.insert(drawings, line)
			end
		end
	end
end)
