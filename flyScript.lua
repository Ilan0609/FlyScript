local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local flying = false
local noclip = false
local aimbotEnabled = false
local wallhackEnabled = false
local speed = 50
local flyConnection
local noclipConnection
local aimbotConnection
local wallhackObjects = {}
local targetedEnemy = nil

-- Contrôle des mouvements
local control = {F = 0, B = 0, L = 0, R = 0}

-- Fonction Noclip
function toggleNoclip()
    noclip = not noclip
    if noclip then
        noclipConnection = runService.Stepped:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Fonction Wallhack
function toggleWallhack()
    wallhackEnabled = not wallhackEnabled
    if wallhackEnabled then
        wallhackObjects = {}
        wallhackConnection = runService.RenderStepped:Connect(function()
            for _, targetPlayer in pairs(game.Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Team ~= player.Team and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local rootPart = targetPlayer.Character.HumanoidRootPart

                    if not wallhackObjects[targetPlayer] then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Adornee = rootPart
                        box.AlwaysOnTop = true
                        box.ZIndex = 5
                        box.Color3 = Color3.new(1, 0, 0)
                        box.Size = Vector3.new(4, 6, 4)
                        box.Transparency = 0.5
                        box.Parent = camera
                        wallhackObjects[targetPlayer] = box
                    end
                end
            end
        end)
    else
        if wallhackConnection then
            wallhackConnection:Disconnect()
        end
        for _, box in pairs(wallhackObjects) do
            if box then box:Destroy() end
        end
        wallhackObjects = {}
    end
end

-- Fonction Aimbot
function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        aimbotConnection = runService.RenderStepped:Connect(function()
            local closestPlayer
            local shortestDistance = math.huge
            local mouse = player:GetMouse()
            
            for _, targetPlayer in pairs(game.Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Team ~= player.Team and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local targetPart = targetPlayer.Character.HumanoidRootPart
                    local origin = camera.CFrame.Position
                    local direction = (targetPart.Position - origin).Unit * 500
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {player.Character, camera}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local ray = workspace:Raycast(origin, direction, rayParams)

                    if ray and ray.Instance:IsDescendantOf(targetPlayer.Character) then
                        local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local mousePosition = Vector2.new(mouse.X, mouse.Y)
                            local targetScreenPosition = Vector2.new(screenPosition.X, screenPosition.Y)
                            local distance = (mousePosition - targetScreenPosition).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestPlayer = targetPlayer
                            end
                        end
                    end
                end
            end

            if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
                camera.CFrame = CFrame.new(camera.CFrame.Position, closestPlayer.Character.HumanoidRootPart.Position)
            end
        end)
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
        end
    end
end

-- Bind des touches
userInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.P then
        toggleWallhack()
        toggleAimbot()
    end
end)
