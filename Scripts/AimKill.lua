-- ⚙️ Settings
local Settings = {
    AimbotEnabled = false,
    ESPEnabled = false,
    FOVVisible = false,
    AimbotSpeed = 5,
    ShowTeam = false,
    ShowDistance = true,
    HighlightESP = true
}

-- 📦 Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 🛡️ Anti-Ban & Anti-Cheat Bypass
pcall(function()
    for _,v in pairs(getconnections(game.DescendantAdded)) do
        if typeof(v) == "table" and v.Function and islclosure(v.Function) then
            v:Disable()
        end
    end
end)

local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        if tostring(self):lower():find("report") or tostring(self):lower():find("ban") then
            return nil
        end
    end
    return old(self, ...)
end)
setreadonly(mt, true)

-- 🎯 Aimbot
local function GetClosestEnemy()
    local closest, shortest = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortest then
                    closest = plr.Character.Head
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- 🔁 Aimbot logic
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = GetClosestEnemy()
        if target then
            local headPos = target.Position + Vector3.new(0, 0.15, 0)
            local dir = (headPos - Camera.CFrame.Position).Unit
            local goal = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + dir)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / Settings.AimbotSpeed)
        end
    end
end)

-- 🔵 FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Thickness = 1
fovCircle.Radius = 120
fovCircle.Filled = false
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    fovCircle.Visible = Settings.FOVVisible
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end)

-- 👁️ ESP
local esp = {}
RunService.RenderStepped:Connect(function()
    for _,v in pairs(esp) do
        if v.Text then v.Text.Visible = false end
        if v.Highlight then v.Highlight:Destroy() end
    end
    esp = {}

    if not Settings.ESPEnabled then return end

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") then
            if not Settings.ShowTeam and plr.Team == LocalPlayer.Team then continue end

            local headPos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                -- ESP text
                local dist = math.floor((Camera.CFrame.Position - plr.Character.Head.Position).Magnitude)
                local tag = Drawing.new("Text")
                tag.Text = plr.Name .. (Settings.ShowDistance and (" [" .. dist .. "m]") or "")
                tag.Size = 14
                tag.Center = true
                tag.Outline = true
                tag.Position = Vector2.new(headPos.X, headPos.Y - 25)
                tag.Color = Color3.fromRGB(255, 255, 255)
                tag.Visible = true

                -- Highlight ESP
                local highlight
                if Settings.HighlightESP then
                    highlight = Instance.new("Highlight", plr.Character)
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                end

                esp[plr] = {Text = tag, Highlight = highlight}
            end
        end
    end
end)

-- 🖥️ UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 280)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
Frame.Active = true
Frame.Draggable = true

local function AddToggle(y, text, key)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 230, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = text .. ": OFF"
    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = text .. ": " .. (Settings[key] and "ON" or "OFF")
    end)
end

local function AddTextBox(y, text, key)
    local label = Instance.new("TextLabel", Frame)
    label.Position = UDim2.new(0, 10, 0, y)
    label.Size = UDim2.new(0, 230, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = text .. ":"
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", Frame)
    box.Position = UDim2.new(0, 10, 0, y + 20)
    box.Size = UDim2.new(0, 230, 0, 25)
    box.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    box.TextColor3 = Color3.new(1,1,1)
    box.Text = tostring(Settings[key])
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then Settings[key] = num end
    end)
end

AddToggle(10, "Aimbot", "AimbotEnabled")
AddToggle(45, "ESP", "ESPEnabled")
AddToggle(80, "Show FOV", "FOVVisible")
AddToggle(115, "Show Team", "ShowTeam")
AddToggle(150, "Show Distance", "ShowDistance")
AddToggle(185, "Highlight ESP", "HighlightESP")
AddTextBox(220, "Aimbot Speed", "AimbotSpeed")
