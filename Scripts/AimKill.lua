-- Gunfight Arena | Silent Aim + ESP + Kill Aura + GUI
-- Hook sâu __namecall để thay tọa độ và kích hoạt remote tốt nhất

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings toggles
local Settings = { SilentAim=false, ESP=false, KillAura=false, KillAuraRange=50 }
-- Hook __namecall
local mt=getrawmetatable(game); setreadonly(mt,false)
local old_nc=mt.__namecall
mt.__namecall=newcclosure(function(self,...)
    local args={...}
    local method = getnamecallmethod()
    if Settings.SilentAim and method=="FireServer" and tostring(self):find("ShootEvent") then
        local target = getClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            args[1] = target.Character.Head.Position
            return old_nc(self, unpack(args))
        end
    end
    return old_nc(self,...)
end)

-- Get nearest enemy head in FOV
function getClosestEnemy()
    local best, minDist = nil, math.huge
    local mpos = UserInputService:GetMouseLocation()
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local sPos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if vis then
                local dist=(Vector2.new(sPos.X,sPos.Y)-mpos).Magnitude
                if dist<minDist then minDist, best = dist, p end
            end
        end
    end
    return best
end

-- ESP using Drawing
local espObjects = {}
function toggleESP(p)
    if espObjects[p] then
        espObjects[p]:line:Remove(); espObjects[p]:box:Remove()
        espObjects[p]=nil
        return
    end
    local line = Drawing.new("Line"); line.Color=Color3.new(0,1,0); line.Thickness=1
    local box = Drawing.new("Square"); box.Color=Color3.new(1,0,0); box.Thickness=1; box.Filled=false
    espObjects[p] = {line=line, box=box}
end

Players.PlayerAdded:Connect(toggleESP)
for _,p in pairs(Players:GetPlayers()) do toggleESP(p) end

RunService.RenderStepped:Connect(function()
    for p,data in pairs(espObjects) do
        if Settings.ESP and p.Character and p.Character:FindFirstChild("Head") then
            local sPos, vis=Camera:WorldToViewportPoint(p.Character.Head.Position)
            if vis then
                data.box.Position = Vector2.new(sPos.X-25, sPos.Y-50)
                data.box.Size = Vector2.new(50,100)
                data.box.Visible = true
                data.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                data.line.To = Vector2.new(sPos.X,sPos.Y)
                data.line.Visible = true
            else
                data.line.Visible, data.box.Visible = false, false
            end
        else
            data.line.Visible, data.box.Visible = false, false
        end
    end

    if Settings.KillAura then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if d <= Settings.KillAuraRange then
                    local ev = LocalPlayer:FindFirstChild("ShootEvent",true)
                    if ev then ev:FireServer(p.Character.Head.Position) end
                end
            end
        end
    end
end)

-- UI
local ScreenGui=Instance.new("ScreenGui",game.CoreGui)
local Main=Instance.new("Frame",ScreenGui); Main.Size=UDim2.new(0,200,0,140); Main.Position=UDim2.new(0,100,0,100)
Main.BackgroundColor3=Color3.fromRGB(30,30,30); Main.Active=true; Main.Draggable=true

local function addToggle(text, prop, y)
    local btn=Instance.new("TextButton",Main)
    btn.Size=UDim2.new(1,-10,0,30); btn.Position=UDim2.new(0,5,0,y)
    btn.Text=text..": OFF"; btn.BackgroundColor3=Color3.fromRGB(50,50,50); btn.TextColor3=Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        Settings[prop]=not Settings[prop]
        btn.Text=text..": "..(Settings[prop] and "ON" or "OFF")
        if prop=="ESP" then for p in pairs(espObjects) do toggleESP(p); toggleESP(p) end end
    end)
end

addToggle("Silent Aim","SilentAim",10)
addToggle("ESP","ESP",50)
addToggle("KillAura","KillAura",90)

local mini=Instance.new("TextButton",ScreenGui); mini.Text="≡"; mini.Size=UDim2.new(0,30,0,30)
mini.Position=UDim2.new(0,10,0,10); mini.Visible=false
mini.MouseButton1Click:Connect(function() Main.Visible=true; mini.Visible=false end)

local minBtn=Instance.new("TextButton",Main); minBtn.Text="_"; minBtn.Size=UDim2.new(0,20,0,20)
minBtn.Position=UDim2.new(1,-25,0,5)
minBtn.MouseButton1Click:Connect(function() Main.Visible=false; mini.Visible=true end)
