local predictionFactor = 0.042  -- Чувствительность предсказания
local aimSpeed = 10  -- Скорость наводки
local fovRadius = 200  -- Радиус FOV
local camera = game:GetService("Workspace").CurrentCamera
local players = game:GetService("Players")
local user = players.LocalPlayer  -- LocalPlayer работает только на клиенте
local holding = false

-- Проверка, существует ли игрок в игре
if not user then
    warn("LocalPlayer не найден. Убедитесь, что это локальный скрипт.")
    return
end

-- Функция нахождения ближайшего игрока в FOV
function getClosestPlayerInFOV()
    local closestDistance = math.huge
    local closestPlayer = nil

    for _, player in pairs(players:GetPlayers()) do
        if player ~= user and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local head = character:FindFirstChild("Head")
            if head then
                local screenPosition, onScreen = camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local distanceFromCenter = (Vector2.new(screenPosition.X, screenPosition.Y) - Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).Magnitude

                    if distanceFromCenter <= fovRadius then
                        local distance = (camera.CFrame.Position - head.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Предсказание позиции головы цели
function predictHeadPosition(target)
    local targetHead = target.Character:FindFirstChild("Head")
    local targetVelocity = target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
    return targetHead.Position + targetVelocity * predictionFactor
end

-- Настройка круга FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
FOVCircle.Radius = fovRadius
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = true
FOVCircle.Transparency = 0.7
FOVCircle.Thickness = 1

-- Обработка нажатий мыши
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = true
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
    end
end)

-- Основной цикл
game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()

    if holding then
        local targetPlayer = getClosestPlayerInFOV()
        if targetPlayer then
            local predictedPosition = predictHeadPosition(targetPlayer)
            local direction = (predictedPosition - camera.CFrame.Position).Unit
            local targetPosition = camera.CFrame.Position + direction * 15

            camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, targetPosition), aimSpeed * 0.1)
        end
    end
end)
