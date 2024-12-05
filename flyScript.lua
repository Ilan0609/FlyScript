local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer
local flyEnabled = false
local noclipEnabled = false
local wallhackEnabled = false
local aimbotEnabled = false
local aimbotConnection = nil
local wallhackObjects = {}
local flyConnection = nil
local noclipConnection = nil
local isAimbotActive = false -- Utilisé pour détecter si clic droit est maintenu
local speed = 50

-- Contrôle pour Fly
local control = {F = 0, B = 0, L = 0, R = 0}

-- Fonction pour créer le GUI de Fly
function createFlyGui()
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "FlyGui"

    local flyText = Instance.new("TextLabel", screenGui)
    flyText.Name = "FlyText"
    flyText.Size = UDim2.new(0.3, 0, 0.1, 0)
    flyText.Position = UDim2.new(0.35, 0, 0.45, 0)
    flyText.Text = "Fly by Redtrim"
    flyText.TextColor3 = Color3.new(1, 1, 1)
    flyText.BackgroundTransparency = 1
    flyText.TextScaled = true
    flyText.Font = Enum.Font.SourceSansBold
    flyText.TextStrokeTransparency = 0

    return screenGui, flyText
end

-- Afficher le GUI
function showFlyGui()
    local screenGui, flyText = createFlyGui()
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1)
    local goal = {TextTransparency = 1, TextStrokeTransparency = 1}

    local fadeOutTween = TweenService:Create(flyText, tweenInfo, goal)
    fadeOutTween:Play()
    fadeOutTween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- Fonction Fly
function toggleFly()
    flyEnabled = not flyEnabled

    local character = localPlayer.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    if flyEnabled then
        -- Créer un BodyGyro et BodyVelocity pour le vol
        local bodyGyro = Instance.new("BodyGyro", humanoidRootPart)
        local bodyVelocity = Instance.new("BodyVelocity", humanoidRootPart)

        bodyGyro.P = 9e4
        bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.cframe = humanoidRootPart.CFrame

        bodyVelocity.velocity = Vector3.zero
        bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled then
                flyConnection:Disconnect()
                bodyGyro:Destroy()
                bodyVelocity:Destroy()
                return
            end

            control.F = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
            control.B = UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
            control.L = UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
            control.R = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0

            bodyVelocity.Velocity = (Camera.CFrame.LookVector * (control.F + control.B) +
                                    Camera.CFrame.RightVector * (control.R + control.L)) * speed
            bodyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + Camera.CFrame.LookVector)
        end)
    else
        -- Quand le vol est désactivé, réactiver la gravité et supprimer le BodyGyro et BodyVelocity
        if flyConnection then
            flyConnection:Disconnect()
        end

        -- Réactiver la gravité et revenir à l'état normal
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end

        -- Réinitialiser le BodyGyro et le BodyVelocity
        local bodyGyro = humanoidRootPart:FindFirstChildOfClass("BodyGyro")
        local bodyVelocity = humanoidRootPart:FindFirstChildOfClass("BodyVelocity")
        if bodyGyro then bodyGyro:Destroy() end
        if bodyVelocity then bodyVelocity:Destroy() end
    end
end

-- Fonction Noclip
function toggleNoclip()
    noclipEnabled = not noclipEnabled

    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            if localPlayer.Character then
                for _, part in ipairs(localPlayer.Character:GetDescendants()) do
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
        if localPlayer.Character then
            for _, part in ipairs(localPlayer.Character:GetDescendants()) do
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
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= localPlayer and targetPlayer.Team ~= localPlayer.Team and targetPlayer.Character then
                for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 0.5
                        part.Material = Enum.Material.Neon
                    end
                end
            end
        end
    else
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer.Character then
                for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 0
                        part.Material = Enum.Material.Plastic
                    end
                end
            end
        end
    end
end

-- Fonction Aimbot
function enableAimbot()
    if aimbotConnection then return end

    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not isAimbotActive then return end

        local closestPlayer
        local shortestDistance = math.huge

        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= localPlayer and targetPlayer.Team ~= localPlayer.Team and targetPlayer.Character then
                local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local origin = Camera.CFrame.Position
                    local direction = (targetRoot.Position - origin).Unit * 500
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {localPlayer.Character}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

                    local rayResult = workspace:Raycast(origin, direction, rayParams)
                    if rayResult and rayResult.Instance:IsDescendantOf(targetPlayer.Character) then
                        local distance = (Camera.CFrame.Position - targetRoot.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = targetPlayer
                        end
                    end
                end
            end
        end

        if closestPlayer and closestPlayer.Character then
            local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetRoot.Position)
            end
        end
    end)
end

function disableAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

-- Gestion Aimbot (clic droit)
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAimbotActive = true
        enableAimbot()
    elseif input.KeyCode == Enum.KeyCode.E then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.P then
        toggleWallhack()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAimbotActive = false
        disableAimbot()
    end
end)

-- Afficher GUI Fly
showFlyGui()
