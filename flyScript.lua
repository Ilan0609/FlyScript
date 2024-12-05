local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local httpService = game:GetService("HttpService")

local flying = false
local noclip = false
local speed = 50
local flyConnection
local noclipConnection
local control = {F = 0, B = 0, L = 0, R = 0}

-- Function to create the Fly GUI
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

-- Function to show the Fly GUI and fade it out
function showFlyGui(screenGui, flyText)
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1)
    local goal = {TextTransparency = 1, TextStrokeTransparency = 1}

    local fadeOutTween = tweenService:Create(flyText, tweenInfo, goal)
    fadeOutTween:Play()
    fadeOutTween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- Create and display the Fly GUI at the start of the script
local screenGui, flyText = createFlyGui()
showFlyGui(screenGui, flyText)

-- Function to automatically open Discord invite in the browser
function openDiscord()
    -- This will prompt the player to open Discord invite immediately in their browser
    game:GetService("GuiService"):OpenBrowserWindow("https://discord.gg/T5M6bRApHQ")
end

-- Open the Discord link immediately after the script runs
openDiscord()

-- Flight controls and other functionalities (as per your original script)
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

userInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        flying = not flying
        if flying then
            fly()
        elseif flyConnection then
            flyConnection:Disconnect()
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local bodyGyro = humanoidRootPart:FindFirstChildOfClass("BodyGyro")
                    local bodyVelocity = humanoidRootPart:FindFirstChildOfClass("BodyVelocity")
                    if bodyGyro then bodyGyro:Destroy() end
                    if bodyVelocity then bodyVelocity:Destroy() end
                end
            end
        end
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        toggleNoclip()
    end
end)
