-- Gun Fight Arena Script Hook with Full UI, Multi-ESP, AimKill, AutoKill

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- Settings table
local Settings = {
    FOV = 120,
    Aimbot = false,
    ESP = false,
    AutoKill = false
}

-- GUI
local GUI = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", GUI)
Frame.Position = UDim2.new(0, 20, 0.4, 0)
Frame.Size = UDim2.new(0, 180, 0, 170)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Active = true
Frame.Draggable = true

local function MakeToggle(name, y, setting)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = name .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        btn.Text = name .. ": " .. (Settings[setting] and "ON" or "OFF")
    end)
end

MakeToggle("Aimbot", 10, "Aimbot")
MakeToggle("ESP", 60, "ESP")
MakeToggle("AutoKill", 110, "AutoKill")

-- ESP storage
local allESP = {}

local function CreateESP(part)
    if allESP[part] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = Color3.new(1, 0, 0)
    box.Filled = false
    box.Visible = true
    allESP[part] = box
end

local function UpdateESP()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Part") and v.Name == "Head" and v:IsDescendantOf(workspace) then
            CreateESP(v)
        end
    end
end

-- Hook RemoteEvent target
local HookedTargets = {}
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" and tostring(self):lower():find("shoot") then
        if typeof(args[1]) == "Vector3" then
            table.insert(HookedTargets, args[1])
        end
    end
    return old(self, ...)
end)
setreadonly(mt, true)

-- Aimbot functions
local function GetClosestTarget()
    local closest, minDist = nil, Settings.FOV
    for _, vec in ipairs(HookedTargets) do
        local pos, onScreen = Camera:WorldToViewportPoint(vec)
        if onScreen then
            local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
            if dist < minDist then
                minDist = dist
                closest = vec
            end
        end
    end
    return closest
end

-- FOV circle
local circle = Drawing.new("Circle")
circle.Color = Color3.new(0, 1, 0)
circle.Thickness = 2
circle.Radius = Settings.FOV
circle.Filled = false

-- Render loop
RunService.RenderStepped:Connect(function()
    circle.Position = UIS:GetMouseLocation()
    circle.Radius = Settings.FOV
    circle.Visible = Settings.Aimbot

    UpdateESP()

    for part, box in pairs(allESP) do
        if part and part:IsDescendantOf(workspace) and Settings.ESP then
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local size = math.clamp(5000 / (part.Position - Camera.CFrame.Position).Magnitude, 20, 80)
                box.Position = Vector2.new(pos.X - size/2, pos.Y - size/2)
                box.Size = Vector2.new(size, size)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end

    local target = GetClosestTarget()
    if target and Settings.Aimbot then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target)
        if Settings.AutoKill then mouse1click() end
    end
end)
