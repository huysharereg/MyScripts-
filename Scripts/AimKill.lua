-- Silent Aim + ESP (Fixed) + UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local Settings = {
    FOV = 200,
    SilentAim = true,
    ESP = true,
    AutoShoot = true
}

-- UI panel (giữ nguyên code UI trước đó)...

-- Drawing objects
local espData = {}  -- Maps part to {box, line, text}

-- Check enemy
local function isEnemy(p)
    return p ~= LP
        and p.Character
        and (p.Team ~= LP.Team)
        and p.Character:FindFirstChild("Head")
end

-- Find closest
local function getClosest()
    local best, bestD = nil, Settings.FOV
    local mousePos = UIS:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local head = p.Character.Head
            local screen, on = Camera:WorldToViewportPoint(head.Position)
            if on then
                local d = (Vector2.new(screen.X, screen.Y) - mousePos).Magnitude
                if d < bestD then bestD, best = d, head end
            end
        end
    end
    return best
end

-- Hook Silent
hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}; local method = getnamecallmethod()
    if method=="Fire" and tostring(self)=="Sync" and Settings.SilentAim then
        local target = getClosest()
        if target then
            args[2] = target.CFrame
        end
        return self.Fire(self, unpack(args))
    end
    return self[method](self, ...)
end))

-- Render loop
RunService.RenderStepped:Connect(function()
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV
    circle.Visible = Settings.SilentAim

    for _, p in ipairs(Players:GetPlayers()) do
        local head = p.Character and p.Character:FindFirstChild("Head")
        if head and isEnemy(p) and Settings.ESP then
            local screen, on = Camera:WorldToViewportPoint(head.Position)
            if on then
                local depth = (Camera.CFrame.Position - head.Position).Magnitude
                local size = math.clamp(2000 / depth, 20, 250)

                if not espData[head] then
                    local box = Drawing.new("Square")
                    box.Thickness, box.Filled, box.Color = 2, false, Color3.new(1, 0, 0)
                    local line = Drawing.new("Line")
                    line.Thickness, line.Color = 1, Color3.new(1, 1, 1)
                    local txt = Drawing.new("Text")
                    txt.Color, txt.Size, txt.Center = Color3.new(1, 1, 1), 16, true
                    espData[head] = {box=box, line=line, txt=txt}
                end

                local o = espData[head]
                o.box.Position = Vector2.new(screen.X - size/2, screen.Y - size/2)
                o.box.Size = size
                o.box.Visible = true
                o.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                o.line.To = Vector2.new(screen.X, screen.Y)
                o.line.Visible = true
                o.txt.Position = Vector2.new(screen.X, screen.Y - size/2 - 12)
                o.txt.Text = p.Name .. " [" .. math.floor(depth) .. "m]"
                o.txt.Visible = true
            elseif espData[head] then
                espData[head].box:Remove()
                espData[head].line:Remove()
                espData[head].txt:Remove()
                espData[head] = nil
            end
        elseif head and espData[head] then
            espData[head].box:Remove()
            espData[head].line:Remove()
            espData[head].txt:Remove()
            espData[head] = nil
        end
    end
end)
