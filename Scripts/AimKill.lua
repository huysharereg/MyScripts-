return function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    local Settings = {
        SilentAim = false,
        ESP = false,
        KillAura = false,
        KillAuraRange = 50
    }

    -- Đợi PlayerGui chắc chắn tồn tại
    repeat wait() until LocalPlayer:FindFirstChild("PlayerGui")

    -- UI using PlayerGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XenoUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer.PlayerGui

    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 200, 0, 140)
    Main.Position = UDim2.new(0, 100, 0, 100)
    Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Main.Active = true
    Main.Draggable = true

    local function makeButton(text, y, settingKey)
        local btn = Instance.new("TextButton", Main)
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.Text = text .. ": OFF"
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.MouseButton1Click:Connect(function()
            Settings[settingKey] = not Settings[settingKey]
            btn.Text = text .. ": " .. (Settings[settingKey] and "ON" or "OFF")
        end)
    end

    makeButton("Silent Aim", 10, "SilentAim")
    makeButton("ESP", 50, "ESP")
    makeButton("Kill Aura", 90, "KillAura")

    -- Silent Aim (__namecall hook)
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local args = { ... }
        local method = getnamecallmethod()
        if Settings.SilentAim and method == "FireServer" and tostring(self):lower():find("shoot") then
            local target = getClosestEnemy()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                args[1] = target.Character.Head.Position
                return old(self, unpack(args))
            end
        end
        return old(self, ...)
    end)

    function getClosestEnemy()
        local closest, dist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local d = (p.Character.Head.Position - Camera.CFrame.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = p
                end
            end
        end
        return closest
    end

    -- ESP
    local espParts = {}

    function createESP(p)
        if espParts[p] then return end
        if not p.Character then return end

        local hl = Instance.new("Highlight")
        hl.Name = "XenoESP"
        hl.Adornee = p.Character
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Parent = ScreenGui

        local bb = Instance.new("BillboardGui")
        bb.Name = "NameTag"
        bb.Adornee = p.Character:FindFirstChild("Head")
        bb.Size = UDim2.new(0, 200, 0, 50)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.AlwaysOnTop = true
        bb.Parent = p.Character:FindFirstChild("Head")

        local nameLabel = Instance.new("TextLabel", bb)
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextScaled = true
        nameLabel.Text = p.Name

        espParts[p] = { hl = hl, bb = bb }
    end

    function removeESP(p)
        if espParts[p] then
            espParts[p].hl:Destroy()
            espParts[p].bb:Destroy()
            espParts[p] = nil
        end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            createESP(p)
        end
    end

    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then
            p.CharacterAdded:Connect(function()
                wait(1)
                createESP(p)
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function(p)
        removeESP(p)
    end)

    RunService.RenderStepped:Connect(function()
        for p, esp in pairs(espParts) do
            if Settings.ESP and p.Character and p.Character:FindFirstChild("Head") then
                esp.hl.Enabled = true
                esp.bb.Enabled = true
            else
                esp.hl.Enabled = false
                esp.bb.Enabled = false
            end
        end

        -- Kill Aura
        if Settings.KillAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if d <= Settings.KillAuraRange then
                        local ev = LocalPlayer:FindFirstChildWhichIsA("RemoteEvent", true)
                        if ev and tostring(ev):lower():find("shoot") then
                            ev:FireServer(p.Character.Head.Position)
                        end
                    end
                end
            end
        end
    end)
end
