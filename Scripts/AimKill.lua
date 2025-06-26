-- Silent Aim Hook + ESP Box + UI Panel for GunFight Arena
-- Features: Silent Aim, ESP Box+Line+Name+Distance, FOV Circle, Toggle Panel

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- SETTINGS
local Settings = {
    FOV = 180,
    SilentAim = true,
    ESP = true,
    AutoShoot = true
}

-- UI
local gui = Instance.new("ScreenGui", game.CoreGui); gui.Name = "SilentHookGui"
local panel = Instance.new("Frame", gui)
panel.Size, panel.Position = UDim2.new(0,240,0,200), UDim2.new(0,10,0,200)
panel.Active, panel.Draggable = true, true
panel.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", panel)
title.Size, title.BackgroundTransparency, title.Font, title.TextSize = UDim2.new(1,0,0,30), 1, Enum.Font.GothamBold, 20
title.TextColor3 = Color3.fromRGB(0,255,255); title.Text = "GunFight SilentHook"

local function addToggle(name,y)
    local cb = Instance.new("TextButton",panel)
    cb.Size, cb.Position = UDim2.new(0,20,0,30+y), UDim2.new(0,10,0,30+y)
    cb.TextColor3, cb.Font, cb.TextSize, cb.BackgroundColor3 = Color3.new(0,1,0), Enum.Font.SourceSans, 18, Color3.fromRGB(40,40,40)
    cb.Text = Settings[name] and "✔" or ""
    local lbl = Instance.new("TextLabel", panel)
    lbl.Position, lbl.Size = UDim2.new(0,40,0,30+y), UDim2.new(0,180,0,20)
    lbl.TextColor3, lbl.BackgroundTransparency, lbl.Font, lbl.TextSize = Color3.new(1,1,1), 1, Enum.Font.SourceSans, 18
    lbl.Text = name
    cb.MouseButton1Click:Connect(function()
        Settings[name] = not Settings[name]
        cb.Text = Settings[name] and "✔" or ""
    end)
end

addToggle("SilentAim", 10)
addToggle("ESP", 40)
addToggle("AutoShoot", 70)
-- FOV Input
local fovLbl = Instance.new("TextLabel", panel)
fovLbl.Position, fovLbl.Size = UDim2.new(0,10,0,110), UDim2.new(0,200,0,20)
fovLbl.TextColor3, fovLbl.BackgroundTransparency, fovLbl.Font, fovLbl.TextSize = Color3.new(1,1,0), 1, Enum.Font.SourceSans, 18
fovLbl.Text = "FOV: "..Settings.FOV
local fovBox = Instance.new("TextBox", panel)
fovBox.Position, fovBox.Size = UDim2.new(0,10,0,130), UDim2.new(0,100,0,24)
fovBox.Text = tostring(Settings.FOV)
fovBox.ClearTextOnFocus = false
fovBox.FocusLost:Connect(function()
    local v = tonumber(fovBox.Text)
    if v then Settings.FOV = math.clamp(v,50,1000); fovLbl.Text = "FOV: "..Settings.FOV end
end)

-- Minimize Button & Icon
local minBtn = Instance.new("TextButton", panel)
minBtn.Size, minBtn.Position = UDim2.new(0,30,0,0), UDim2.new(1,-30,0,0)
minBtn.Text, minBtn.TextColor3, minBtn.BackgroundColor3 = "─", Color3.new(1,1,1), Color3.fromRGB(50,50,50)
local icon = Instance.new("TextButton", gui)
icon.Size, icon.Position = UDim2.new(0,30,0,20), UDim2.new(1,-50,0,20)
icon.Text, icon.TextColor3, icon.BackgroundColor3 = "S", Color3.new(1,1,1), Color3.fromRGB(30,30,30)
icon.Visible = false
minBtn.MouseButton1Click:Connect(function() panel.Visible=false; icon.Visible=true end)
icon.MouseButton1Click:Connect(function() panel.Visible=true; icon.Visible=false end)

-- FOV Circle
local circle = Drawing.new("Circle")
circle.Color, circle.Thickness, circle.Transparency = Color3.new(1,1,0), 2, 0.5
circle.Filled = false

-- ESP Structures
local boxes = {}

-- UTIL
local function isEnemy(p)
    return p~=LP and p.Team~=LP.Team and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end

local function getClosest()
    local closest, minD = nil, Settings.FOV
    for _,p in pairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local part = p.Character.HumanoidRootPart
            local pos, on = Camera:WorldToViewportPoint(part.Position)
            if on then
                local d = (Vector2.new(pos.X,pos.Y)-UIS:GetMouseLocation()).Magnitude
                if d < minD then minD, closest = d, p end
            end
        end
    end
    return closest
end

-- Hook Silent Aim
hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}; local method = getnamecallmethod()
    if method=="Fire" and tostring(self)=="Sync" and Settings.SilentAim then
        local closest = getClosest()
        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            args[2] = closest.Character.Head.CFrame
        end
        return self.Fire(self, unpack(args))
    end
    return self[method](self, ...)
end))

-- RENDER
RunService.RenderStepped:Connect(function()
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV
    circle.Visible = Settings.SilentAim

    -- ESP Boxes & Lines
    for _,p in pairs(Players:GetPlayers()) do
        local part = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if part and isEnemy(p) then
            local pos,on = Camera:WorldToViewportPoint(part.Position)
            if on and Settings.ESP then
                local size = math.clamp(3000/Camera.CFrame.Position.Y, 50, 300)
                if not boxes[part] then
                    local b = Drawing.new("Square"); local l = Drawing.new("Line"); local t = Drawing.new("Text")
                    b.Thickness, b.Color = 2, Color3.new(1,0,0); b.Filled=false
                    l.Thickness, l.Color = 1, Color3.new(1,1,1)
                    t.Color, t.Size, t.Center = Color3.new(1,1,1), 16, true
                    boxes[part]={box=b,line=l,text=t}
                end
                local rec = boxes[part]
                rec.box.Position = Vector2.new(pos.X-size/2,pos.Y-size/2)
                rec.box.Size = size
                rec.box.Visible = true
                rec.line.From = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
                rec.line.To = Vector2.new(pos.X,pos.Y)
                rec.line.Visible = true
                rec.text.Position = Vector2.new(pos.X,pos.Y-size/2-10)
                rec.text.Text = p.Name.." ["..math.floor((LP.Character.HumanoidRootPart.Position-part.Position).Magnitude).."m]"
                rec.text.Visible = true
            elseif boxes[part] then
                boxes[part].box:Remove(); boxes[part].line:Remove(); boxes[part].text:Remove()
                boxes[part]=nil
            end
        elseif boxes[part] then
            boxes[part].box:Remove(); boxes[part].line:Remove(); boxes[part].text:Remove()
            boxes[part]=nil
        end
    end
end)
