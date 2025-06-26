-- GunFight Arena – PRO ESP + Aimbot + UI Panel
-- Bật/tắt tùy chỉnh mọi thứ  
-- Cầm chuột trái để aim

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- Settings
local Settings = {
    FOV = 120,
    ESP = true,
    Aimbot = true,
    AutoShoot = true
}

-- UI Elements
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ModPanelGui"

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 220, 0, 180)
panel.Position = UDim2.new(0, 15, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(30,30,30)
panel.Active, panel.Draggable = true,true

-- Title
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(0,255,255)
title.Text = "GunFight Arena Mod"

-- Toggle Checkboxes
local function makeCheckbox(name, posY)
    local cb = Instance.new("TextButton", panel)
    cb.Size = UDim2.new(0,20,0,20)
    cb.Position = UDim2.new(0,10,0,posY)
    cb.Text = Settings[name] and "✔" or ""
    cb.TextColor3 = Color3.new(0,1,0)
    cb.BackgroundColor3 = Color3.fromRGB(40,40,40)
    cb.MouseButton1Click:Connect(function()
        Settings[name] = not Settings[name]
        cb.Text = Settings[name] and "✔" or ""
    end)
    local lbl = Instance.new("TextLabel", panel)
    lbl.Position = UDim2.new(0,40,0,posY-2)
    lbl.Size = UDim2.new(0,150,0,24)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 18
end

makeCheckbox("ESP",40)
makeCheckbox("Aimbot",70)
makeCheckbox("AutoShoot",100)

-- FOV Slider
local fovTxt = Instance.new("TextLabel", panel)
fovTxt.Position = UDim2.new(0,10,0,130)
fovTxt.Size = UDim2.new(0,200,0,20)
fovTxt.BackgroundTransparency = 1
fovTxt.TextColor3 = Color3.new(1,1,0)
fovTxt.Font = Enum.Font.SourceSans
fovTxt.TextSize = 16
fovTxt.Text = "FOV: "..Settings.FOV

local fovBox = Instance.new("TextBox", panel)
fovBox.Position = UDim2.new(0,10,0,150)
fovBox.Size = UDim2.new(0,100,0,24)
fovBox.Text = tostring(Settings.FOV)
fovBox.ClearTextOnFocus = false
fovBox.FocusLost:Connect(function()
    local v = tonumber(fovBox.Text)
    if v then Settings.FOV = math.clamp(v,50,500); fovTxt.Text = "FOV: "..Settings.FOV end
end)

-- Minimize Button
local minBtn = Instance.new("TextButton", panel)
minBtn.Size = UDim2.new(0,30,0,30)
minBtn.Position = UDim2.new(1,-40,0,0)
minBtn.Text = "☰"
minBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    icon.Visible = true
end)

-- Mini-icon
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,40,0,40)
icon.Position = UDim2.new(0,15,0.3,0)
icon.Text = "👁"
icon.BackgroundColor3 = Color3.fromRGB(20,20,20)
icon.TextColor3 = Color3.new(1,1,1)
icon.Visible = false
icon.MouseButton1Click:Connect(function()
    panel.Visible = true
    icon.Visible = false
end)

-- Drawing: FOV circle
local circle = Drawing.new("Circle")
circle.Color = Color3.new(1,1,0)
circle.Thickness = 2
circle.Transparency = 0.5

-- Drawing: ESP lines
local lines = {} -- mapping part to drawing line

-- Utility: is enemy check
function IsEnemy(p)
    return p~=LP and p.Character and p.Character:FindFirstChild("Humanoid") and p.Team~=LP.Team
end

-- Main loop
RunService.RenderStepped:Connect(function()
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV
    circle.Visible = Settings.Aimbot

    -- Process enemies
    for _, p in pairs(Players:GetPlayers()) do
        if IsEnemy(p) then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, visible = Camera:WorldToViewportPoint(head.Position)
                if visible and Settings.ESP then
                    local dist = (Vector2.new(pos.X,pos.Y)-UIS:GetMouseLocation()).Magnitude
                    local key = head
                    -- create line if not exists
                    if not lines[key] then
                        lines[key] = Drawing.new("Line")
                        lines[key].Thickness = 1
                        lines[key].Color = Color3.new(1,0,0)
                    end
                    local ln = lines[key]
                    ln.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    ln.To = Vector2.new(pos.X, pos.Y)
                    ln.Visible = true

                    local nameTxt = " " .. p.Name .. " [".. math.floor((LP.Character.Head.Position - head.Position).Magnitude).. "m]"
                    ln.Text = nameTxt
                elseif lines[head] then
                    lines[head]:Remove()
                    lines[head] = nil
                end
            end
        end
    end

    -- Clean unneeded lines
    for k,v in pairs(lines) do
        if not v.Visible then
            v:Remove()
            lines[k] = nil
        end
    end

    -- Aimbot when firing
    if Settings.Aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local closest, minDist = nil, Settings.FOV
        for _, p in pairs(Players:GetPlayers()) do
            if IsEnemy(p) then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local pos, vis = Camera:WorldToViewportPoint(head.Position)
                    if vis then
                        local d = (Vector2.new(pos.X,pos.Y)-UIS:GetMouseLocation()).Magnitude
                        if d<minDist then
                            minDist, closest = d, head
                        end
                    end
                end
            end
        end
        if closest then
            -- move mouse to head
            local sp = Camera:WorldToViewportPoint(closest.Position)
            local mp = UIS:GetMouseLocation()
            mousemoverel((sp.X-mp.X)*0.5, (sp.Y-mp.Y)*0.5)
            if Settings.AutoShoot then mouse1click() end
        end
    end
end)
