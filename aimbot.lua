local camera = workspace.CurrentCamera
local players = game:GetService("Players")
local user = players.LocalPlayer
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local predictionFactor, aimSpeed, fovRadius = 0.042, 10, 200
local holding, aimBotEnabled = false, true

if not user then return warn("LocalPlayer не найден!") end

-- FOV круг
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius, FOVCircle.Filled, FOVCircle.Thickness = fovRadius, false, 1
FOVCircle.Color, FOVCircle.Transparency, FOVCircle.Visible = Color3.new(1, 1, 1), 0.7, true

-- Получение ближайшего игрока
local function getClosestPlayer()
    local closest, minDist = nil, math.huge
    for _, player in pairs(players:GetPlayers()) do
        if player ~= user and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local head = player.Character:FindFirstChild("Head")
            local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - inputService:GetMouseLocation()).Magnitude
            if onScreen and distance <= fovRadius and distance < minDist then
                closest, minDist = player, distance
            end
        end
    end
    return closest
end

-- Предсказание позиции
local function predictHead(target)
    local head = target.Character.Head
    local velocity = target.Character.HumanoidRootPart.AssemblyLinearVelocity or Vector3.zero
    return head.Position + velocity * predictionFactor
end

-- Обработчики ввода
inputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then holding = true end
    if input.KeyCode == Enum.KeyCode.T then
        aimBotEnabled = not aimBotEnabled
        FOVCircle.Visible = aimBotEnabled
        if not aimBotEnabled then holding = false end
    end
end)

inputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then holding = false end
end)

-- Основной цикл
runService.RenderStepped:Connect(function()
    if not aimBotEnabled then return end
    FOVCircle.Position = inputService:GetMouseLocation()
    if holding then
        local target = getClosestPlayer()
        if target then
            local predicted = predictHead(target)
            camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, predicted), aimSpeed * 0.1)
        end
    end
end)
