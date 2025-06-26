-- PRO AimKill by your dev 😎
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Config
local Aimbot = false
local ESP = false
local AutoKill = false
local FOV = 120
local AimPart = "Head"
local TeamColor = LocalPlayer.TeamColor

-- Vẽ FOV circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = FOV
fovCircle.Thickness = 2
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Filled = false
fovCircle.Transparency = 0.5
fovCircle.Visible = false

-- Vẽ aim line
local aimLine = Drawing.new("Line")
aimLine.Thickness = 2
aimLine.Color = Color3.fromRGB(255, 0, 0)
aimLine.Visible = false

-- Tạo UI
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 160)
frame.Position = UDim2.new(0, 15, 0.4, -80)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local function makeButton(text, y, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Text = text
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 20
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.MouseButton1Click:Connect(callback)
end

makeButton("🎯 Toggle Aimbot", 10, function()
    Aimbot = not Aimbot
    fovCircle.Visible = Aimbot
end)
makeButton("👁 Toggle ESP", 50, function() ESP = not ESP end)
makeButton("🔪 Toggle AutoKill", 90, function() AutoKill = not AutoKill end)
makeButton("❌ Close UI", 130, function() frame.Visible = false end)

-- Kiểm tra địch hay đồng đội
local function isEnemy(player)
    return player.TeamColor ~= TeamColor
end

-- Tạo ESP trên đầu địch
local function createESP(p)
    if p.Character and p.Character:FindFirstChild("Head") and not p.Character.Head:FindFirstChild("ESP") then
        local bg = Instance.new("BillboardGui", p.Character.Head)
        bg.Name = "ESP"
        bg.Size = UDim2.new(0, 100, 0, 40)
        bg.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bg)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = p.Name
        txt.TextColor3 = Color3.fromRGB(255, 0, 0)
        txt.TextScaled = true
    end
end

-- Lấy target địch gần tâm chuột trong FOV
local function getClosest()
    local target, dist = nil, FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isEnemy(p) and p.Character and p.Character:FindFirstChild(AimPart) then
            local pos, onScreen = Camera:WorldToViewportPoint(p.Character[AimPart].Position)
            if onScreen then
                local diff = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                if diff < dist then
                    target, dist = p, diff
                end
            end
        end
    end
    return target
end

-- Render loop
RunService.RenderStepped:Connect(function()
    fovCircle.Position = UIS:GetMouseLocation()
    fovCircle.Radius = FOV

    if ESP then
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) then createESP(p) end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") then
                local esp = p.Character.Head:FindFirstChild("ESP")
                if esp then esp:Destroy() end
            end
        end
    end

    if Aimbot or AutoKill then
        local targ = getClosest()
        if targ then
            local part = targ.Character[AimPart]
            local pos = Camera:WorldToViewportPoint(part.Position)
            -- quay cam
            if Aimbot then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                aimLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                aimLine.To = Vector2.new(pos.X, pos.Y)
                aimLine.Visible = true
            end
            -- tự bắn
            if AutoKill then
                mouse1click()
            end
        else
            aimLine.Visible = false
        end
    else
        aimLine.Visible = false
    end
end)

-- Điều chỉnh FOV bằng phím [ ]
UIS.InputBegan:Connect(function(inp, g)
    if g then return end
    if inp.KeyCode == Enum.KeyCode.LeftBracket then
        FOV = math.max(20, FOV - 10)
    elseif inp.KeyCode == Enum.KeyCode.RightBracket then
        FOV = math.min(300, FOV + 10)
    end
end)
