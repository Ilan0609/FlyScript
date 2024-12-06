local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer
local aimbotEnabled = false
local isAimbotActive = false
local aimbotConnection = nil
local flyEnabled = false
local noclipEnabled = false
local flyConnection = nil
local noclipConnection = nil
local wallhackEnabled = false
local speed = 16 -- Vitesse par défaut au sol
local defaultFlySpeed = 50 -- Vitesse en vol

-- Contrôle pour Fly
local control = {F = 0, B = 0, L = 0, R = 0}

-- GUI "XploitUniversalHub By Redtrim"
function createFlyGui()
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "FlyGui"

    local flyText = Instance.new("TextLabel", screenGui)
    flyText.Name = "FlyText"
    flyText.Size = UDim2.new(0.3, 0, 0.1, 0)
    flyText.Position = UDim2.new(0.35, 0, 0.45, 0)
    flyText.Text = " XploitUniversalHub By Redtrim "
    flyText.TextColor3 = Color3.new(1, 1, 1)
    flyText.BackgroundTransparency = 1
    flyText.TextScaled = true
    flyText.Font = Enum.Font.SourceSansBold
    flyText.TextStrokeTransparency = 0

    -- Ajouter une animation de disparition en fondu après 3 secondes
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1)
    local goal = {TextTransparency = 1, TextStrokeTransparency = 1}

    local fadeOutTween = TweenService:Create(flyText, tweenInfo, goal)
    fadeOutTween:Play()

    fadeOutTween.Completed:Connect(function()
        screenGui:Destroy()
    end)

    return screenGui, flyText
end

function showFlyGui()
    local screenGui, flyText = createFlyGui()
    -- Déclenche la disparition en fondu après un certain temps
    wait(3) -- Attendre 3 secondes avant de démarrer le fondu
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1)
    local goal = {TextTransparency = 1, TextStrokeTransparency = 1}

    local fadeOutTween = TweenService:Create(flyText, tweenInfo, goal)
    fadeOutTween:Play()
    fadeOutTween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- GUI pour changer la vitesse au sol
function createSpeedGui()
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "SpeedGui"

    -- Cadre principal
    local frame = Instance.new("Frame", screenGui)
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0.2, 0, 0.1, 0)
    frame.Position = UDim2.new(0.8, 0, 0.05, 0) -- En haut à droite
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BorderSizePixel = 1
    frame.Draggable = true
    frame.Active = true

    -- Label pour afficher la vitesse actuelle
    local speedLabel = Instance.new("TextLabel", frame)
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, 0, 0.5, 0)
    speedLabel.Position = UDim2.new(0, 0, 0, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.new(1, 1, 1)
    speedLabel.TextScaled = true
    speedLabel.Font = Enum.Font.SourceSansBold
    speedLabel.Text = "Speed: " .. tostring(speed)

    -- Input pour changer la vitesse
    local speedInput = Instance.new("TextBox", frame)
    speedInput.Name = "SpeedInput"
    speedInput.Size = UDim2.new(1, 0, 0.5, 0)
    speedInput.Position = UDim2.new(0, 0, 0.5, 0)
    speedInput.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    speedInput.TextColor3 = Color3.new(1, 1, 1)
    speedInput.Font = Enum.Font.SourceSans
    speedInput.TextScaled = true
    speedInput.Text = "Enter Speed"

    speedInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newSpeed = tonumber(speedInput.Text)
            if newSpeed and newSpeed > 0 then
                speed = newSpeed
                speedLabel.Text = "Speed: " .. tostring(speed)

                -- Appliquer la nouvelle vitesse au sol
                local character = localPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = speed
                    end
                end
            else
                speedInput.Text = "Invalid"
            end
        end
    end)
end

-- Maintenir le GUI après la mort
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = speed -- Appliquer la vitesse actuelle
    createSpeedGui()
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

-- Fonction Fly
function toggleFly()
    flyEnabled = not flyEnabled

    local character = localPlayer.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    if flyEnabled then
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
                                    Camera.CFrame.RightVector * (control.R + control.L)) * defaultFlySpeed
            bodyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + Camera.CFrame.LookVector)
        end)
    else
        -- Réactivation de la gravité et suppression des objets
        if flyConnection then
            flyConnection:Disconnect()
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end

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

        -- Réactiver les collisions
        if localPlayer.Character then
            for _, part in ipairs(localPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
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
                    -- Wall Check
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

-- Gestion des touches
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.P then
        aimbotEnabled = not aimbotEnabled
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 and aimbotEnabled then
        isAimbotActive = true
        enableAimbot()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAimbotActive = false
        disableAimbot()
    end
end)

-- Afficher le GUI "XploitUniversalHub By Redtrim"
showFlyGui()
