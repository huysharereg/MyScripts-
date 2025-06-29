-- Gunfight Arena Aimbot + ESP Script with Simple UI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local Settings = {
    Aimbot = false,
    AimbotAlways = false,
    AimbotSpeed = 1,
    AimbotFOV = 150,
    AimbotTarget = "Head",
    DrawTeam = false,
    ESP = true,
    ESPMode = "All"
}

-- UI Setup
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 300)
frame.Position = UDim2.new(0.75, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local function createToggle(name, y, key)
	local button = Instance.new("TextButton", frame)
	button.Size = UDim2.new(0, 280, 0, 30)
	button.Position = UDim2.new(0, 10, 0, y)
	button.Text = name .. ": OFF"
	button.TextColor3 = Color3.new(1,1,1)
	button.BackgroundColor3 = Color3.fromRGB(60,60,60)
	button.MouseButton1Click:Connect(function()
		Settings[key] = not Settings[key]
		button.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
	end)
end

local function createTextBox(name, y, key, default)
	local box = Instance.new("TextBox", frame)
	box.Size = UDim2.new(0, 280, 0, 30)
	box.Position = UDim2.new(0, 10, 0, y)
	box.Text = default
	box.TextColor3 = Color3.new(1,1,1)
	box.BackgroundColor3 = Color3.fromRGB(60,60,60)
	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val then
			Settings[key] = val
		end
	end)
end

local function createDropdown(name, y, key, options)
	local box = Instance.new("TextBox", frame)
	box.Size = UDim2.new(0, 280, 0, 30)
	box.Position = UDim2.new(0, 10, 0, y)
	box.Text = name .. ": " .. Settings[key]
	box.TextColor3 = Color3.new(1,1,1)
	box.BackgroundColor3 = Color3.fromRGB(60,60,60)
	box.FocusLost:Connect(function()
		for _, opt in pairs(options) do
			if box.Text:lower():find(opt:lower()) then
				Settings[key] = opt
				box.Text = name .. ": " .. opt
			end
		end
	end)
end

-- UI Elements
createToggle("Aimbot", 10, "Aimbot")
createToggle("Aimbot Always", 45, "AimbotAlways")
createTextBox("Aimbot Speed", 80, "AimbotSpeed", tostring(Settings.AimbotSpeed))
createTextBox("FOV", 115, "AimbotFOV", tostring(Settings.AimbotFOV))
createDropdown("Target Part", 150, "AimbotTarget", {"Head", "HumanoidRootPart", "LeftLeg"})
createDropdown("ESP Mode", 185, "ESPMode", {"All", "Name", "Box", "Line"})
createToggle("Draw Team", 220, "DrawTeam")
createToggle("ESP", 255, "ESP")

-- FOV Circle
local circle = Drawing.new("Circle")
circle.Color = Color3.fromRGB(255,255,0)
circle.Filled = false
circle.Thickness = 1
circle.NumSides = 60
circle.Visible = true
circle.Transparency = 1

-- Aimbot
local function getClosest()
	local closest, shortest = nil, math.huge
	for _,plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
			if plr.Team ~= LocalPlayer.Team or Settings.DrawTeam then
				local part = plr.Character:FindFirstChild(Settings.AimbotTarget)
				if part then
					local pos, visible = Camera:WorldToViewportPoint(part.Position)
					local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
					if visible and dist < shortest and dist <= Settings.AimbotFOV then
						shortest = dist
						closest = part
					end
				end
			end
		end
	end
	return closest
end

-- ESP
local drawings = {}
RunService.RenderStepped:Connect(function()
	-- Aimbot Circle
	circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
	circle.Radius = Settings.AimbotFOV
	circle.Visible = true

	-- Aimbot
	if Settings.Aimbot and (Settings.AimbotAlways or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
		local target = getClosest()
		if target then
			local screenPos = Camera:WorldToViewportPoint(target.Position)
			local mousePos = Vector2.new(mouse.X, mouse.Y)
			local move = (Vector2.new(screenPos.X, screenPos.Y) - mousePos) / Settings.AimbotSpeed
			mousemoverel(move.X, move.Y)
		end
	end

	-- Clear ESP
	for _, obj in pairs(drawings) do
		obj.Visible = false
		obj:Remove()
	end
	table.clear(drawings)

	-- ESP
	if Settings.ESP then
		for _,plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
				if plr.Team ~= LocalPlayer.Team or Settings.DrawTeam then
					local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
					if onScreen then
						if Settings.ESPMode == "All" or Settings.ESPMode == "Name" then
							local nameTag = Drawing.new("Text")
							nameTag.Text = plr.Name
							nameTag.Position = Vector2.new(pos.X, pos.Y - 30)
							nameTag.Color = Color3.fromRGB(255,255,255)
							nameTag.Size = 14
							nameTag.Center = true
							nameTag.Outline = true
							nameTag.Visible = true
							table.insert(drawings, nameTag)
						end
						if Settings.ESPMode == "All" or Settings.ESPMode == "Box" then
							local box = Drawing.new("Square")
							box.Position = Vector2.new(pos.X - 25, pos.Y - 30)
							box.Size = Vector2.new(50, 60)
							box.Color = Color3.fromRGB(255,0,0)
							box.Thickness = 1
							box.Visible = true
							table.insert(drawings, box)
						end
						if Settings.ESPMode == "All" or Settings.ESPMode == "Line" then
							local line = Drawing.new("Line")
							line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
							line.To = Vector2.new(pos.X, pos.Y)
							line.Color = Color3.fromRGB(0,255,0)
							line.Thickness = 1
							line.Visible = true
							table.insert(drawings, line)
						end
					end
				end
			end
		end
	end
end)
