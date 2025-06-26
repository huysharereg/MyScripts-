-- Stylish Silent Aim + ESP + UI Panel for GunFight Arena

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- Settings
local Settings = {
    FOV = 200,
    SilentAim = true,
    ESP = true,
    AutoShoot = true
}

-- UI -------------------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "StylishSilentMod"

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 250, 0, 260)
panel.Position = UDim2.new(0, 15, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
panel.BorderSizePixel = 0
panel.ClipsDescendants = true

local Corner = Instance.new("UICorner", panel)
Corner.CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, 0, 0, 32)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.Text = "🔫 GunFight Silent UI"

-- Stylish toggles
local function mkToggle(label, property, posY)
    local cb = Instance.new("TextButton", panel)
    cb.Size = UDim2.new(0, 24, 0, 24)
    cb.Position = UDim2.new(0, 12, 0, 40 + posY * 40)
    cb.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    cb.TextColor3 = Color3.fromRGB(200, 200, 200)
    cb.Font = Enum.Font.SourceSans
    cb.TextSize = 18
    cb.Text = Settings[property] and "✔" or ""
    local lbl = Instance.new("TextLabel", panel)
    lbl.Position = UDim2.new(0, 50, 0, 40 + posY * 40)
    lbl.Size = UDim2.new(0, 160, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 18
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Text = label
    cb.MouseButton1Click:Connect(function()
        Settings[property] = not Settings[property]
        cb.Text = Settings[property] and "✔" or ""
    end)
end

mkToggle("Silent Aim", "SilentAim", 0)
mkToggle("ESP Box/Line", "ESP", 1)
mkToggle("AutoShoot", "AutoShoot", 2)

-- FOV slider + label
local fovLabel = Instance.new("TextLabel", panel)
fovLabel.Position = UDim2.new(0, 12, 0, 160)
fovLabel.Size = UDim2.new(0, 180, 0, 24)
fovLabel.BackgroundTransparency = 1
fovLabel.Font = Enum.Font.SourceSans
fovLabel.TextSize = 16
fovLabel.TextColor3 = Color3.new(1, 1, 0)
fovLabel.Text = "FOV: " .. Settings.FOV

local sliderBg = Instance.new("Frame", panel)
sliderBg.Position = UDim2.new(0, 12, 0, 190)
sliderBg.Size = UDim2.new(0, 220, 0, 8)
sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
local slider = Instance.new("Frame", sliderBg)
slider.Size = UDim2.new(Settings.FOV / 500, 0, 1, 0)
slider.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local function move(pt)
            local x = math.clamp(pt.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
            slider.Size = UDim2.new(x / sliderBg.AbsoluteSize.X, 0, 1, 0)
            Settings.FOV = math.floor(x / sliderBg.AbsoluteSize.X * 500)
            Settings.FOV = math.clamp(Settings.FOV, 50, 500)
            fovLabel.Text = "FOV: " .. Settings.FOV
        end
        local moveConn, upConn
        moveConn = UIS.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then move(i.Position) end
        end)
        upConn = UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConn:Disconnect(); upConn:Disconnect()
            end
        end)
    end
end)

-- Minimize icon
local min = Instance.new("TextButton", panel)
min.Size = UDim2.new(0, 24, 0, 24)
min.Position = UDim2.new(1, -36, 0, 4)
min.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
min.TextSize = 18
min.Text = "─"
min.Font = Enum.Font.SourceSans
min.TextColor3 = Color3.new(1, 1, 1)

local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0, 32, 0, 32)
icon.Position = UDim2.new(0, 15, 0.3, 0)
icon.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
icon.Text = "🔫"
icon.TextSize = 18
icon.Font = Enum.Font.GothamSemibold
icon.TextColor3 = Color3.new(1, 1, 1)
icon.Visible = false

min.MouseButton1Click:Connect(function()
    panel.Visible = false
    icon.Visible = true
end)
icon.MouseButton1Click:Connect(function()
    panel.Visible = true
    icon.Visible = false
end)

-- Drawings ------------------------------------------------------
local circle = Drawing.new("Circle")
circle.Color, circle.Thickness, circle.Transparency, circle.Filled = Color3.fromRGB(255,255,0), 2, 0.4, false
local espLines = {}

-- Utility functions ------------------------------------------------
local function isEnemy(p)
    return p ~= LP and p.Team ~= LP.Team and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Head")
end

local function getClosest()
    local closest, minD = nil, Settings.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local head = p.Character.Head
            local pos, on = Camera:WorldToViewportPoint(head.Position)
            if on then
                local d = (Vector2.new(pos.X,pos.Y) - UIS:GetMouseLocation()).Magnitude
                if d < minD then
                    minD, closest = d, head
                end
            end
        end
    end
    return closest
end

-- Silent Aim Hook ------------------------------------------------
hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "Fire" and tostring(self) == "Sync" and Settings.SilentAim then
        local targetHead = getClosest()
        if targetHead then
            args[2] = targetHead.CFrame
        end
        return self.Fire(self, unpack(args))
    end
    return self[method](self, ...)
end))

-- RenderStepped --------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- FOV circle
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV
    circle.Visible = Settings.SilentAim

    -- ESP Box/Line/Name/Distance
    for _, p in ipairs(Players:GetPlayers()) do
        local head = p.Character and p.Character:FindFirstChild("Head")
        if head and isEnemy(p) and Settings.ESP then
            local pos, on = Camera:WorldToViewportPoint(head.Position)
            if on then
                local size = 2000 / head.Position.Z
                -- Create drawing objects if needed
                if not espLines[head] then
                    local box = Drawing.new("Square")
                    box.Color, box.Thickness, box.Filled = Color3.new(1,0,0), 2, false
                    local line = Drawing.new("Line")
                    line.Color, line.Thickness = Color3.new(1,1,1), 1
                    local txt = Drawing.new("Text")
                    txt.Color, txt.Size, txt.Center = Color3.new(1,1,1), 16, true
                    espLines[head] = {box=box,line=line,txt=txt}
                end
                local obj = espLines[head]
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                update = Vector2.new(pos.X,pos.Y)
                obj.box.Position = Vector2.new(pos.X-size/2,pos.Y-size/2)
                obj.box.Size = size
                obj.box.Visible = true
                obj.line.From = center
                obj.line.To = update
                obj.line.Visible = true
                obj.txt.Position = update + Vector2.new(0, -size/2 - 10)
                obj.txt.Text = p.Name.." ["..math.floor((head.Position - LP.Character.HumanoidRootPart.Position).Magnitude).."m]"
                obj.txt.Visible = true
            elseif espLines[head] then
                espLines[head].box:Remove()
                espLines[head].line:Remove()
                espLines[head].txt:Remove()
                espLines[head] = nil
            end
        elseif head and espLines[head] then
            espLines[head].box:Remove()
            espLines[head].line:Remove()
            espLines[head].txt:Remove()
            espLines[head] = nil
        end
    end
end)
