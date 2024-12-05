local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

local flying = false
local noclip = false
local aimbotEnabled = false
local wallhackEnabled = false
local speed = 50
local aimbotRange = 1000 -- Augmenté pour une plus grande portée
local flyConnection
local noclipConnection
local aimbotConnection
local wallhackObjects = {}
local control = {F = 0, B = 0, L = 0, R = 0}

-- Fonction pour créer l'affichage Fly
function createFlyGui()
    local playerGui = player:WaitForChild("PlayerGui")
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

function showFlyGui(screenGui, flyText)
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1)
    local goal = {TextTransparency = 1, TextStrokeTransparency = 1}

    local fadeOutTween = tweenService:Create(flyText, tweenInfo, goal)
    fadeOutTween:Play()
    fadeOutTween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- Crée et affiche le GUI au démarrage du script
local screenGui, flyText = createFlyGui()
showFlyGui(screenGui, flyText)

-- Fonction de vol
function fly()
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local bodyGyro = Instance.new("BodyGyro", humanoidRootPart)
    local bodyVelocity = Instance.new("BodyVelocity", humanoidRootPart)

    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.cframe = humanoidRootPart.CFrame

    bodyVelocity.velocity = Vector3.new(0, 0, 0)
    bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

    humanoid.PlatformStand = true

    flyConnection = runService.RenderStepped:Connect(function()
        if not flying then
            flyConnection:Disconnect()
            humanoid.PlatformStand = false
            bodyGyro:Destroy()
            bodyVelocity:Destroy()
            return
        end

        control.F = (userInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        control.B = (userInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0)
        control.L = (userInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0)
        control.R = (userInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)

        bodyVelocity.Velocity = (workspace.CurrentCamera.CFrame.LookVector * (control.F + control.B) +
                                 workspace.CurrentCamera.CFrame.RightVector * (control.R + control.L)) * speed
        bodyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + workspace.CurrentCamera.CFrame.LookVector)
    end)
end

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
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                local character = player.Character
                if character then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 0.5
                            part.Material = Enum.Material.Neon
                            table.insert(wallhackObjects, part)
                        end
                    end
                end
            end
        end
    else
        for _, part in pairs(wallhackObjects) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                part.Material = Enum.Material.Plastic
            end
        end
        wallhackObjects = {}
    end
end

-- Fonction Aimbot
function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        aimbotConnection = runService.RenderStepped:Connect(function()
            local character = player.Character
            if not character then return end
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end

            local closestEnemy
            local closestDistance = aimbotRange

            for _, target in ipairs(game.Players:GetPlayers()) do
                if target.Team ~= player.Team and target.Character then
                    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        local distance = (humanoidRootPart.Position - targetRoot.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestEnemy = targetRoot
                        end
                    end
                end
            end

            if closestEnemy then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, closestEnemy.Position)
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
    if input.KeyCode == Enum.KeyCode.E then
        flying = not flying
        if flying then
            fly()
        elseif flyConnection then
            flyConnection:Disconnect()
        end
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.P then
        toggleWallhack()
        toggleAimbot()
    end
end)
