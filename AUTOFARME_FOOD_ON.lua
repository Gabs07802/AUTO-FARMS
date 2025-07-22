-- AUTO FARM IFOOD ROBUSTO COM FLY RAYCAST
-- Usa fly baixo com raycast, noclip e controle para ativar/desativar noclip ao pegar e entregar pedidos.

local FLY_VELOCIDADE = 25 -- Velocidade do fly
local ALTURA_FLY = 1.5    -- Altura do fly
local DISTANCIA_MINIMA_CHAO = 1
local tolerancia = 2
local MAX_TENTATIVAS_PEDIDO = 2 -- Quantas tentativas de pegar pedido caso não apareça o pad

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local pedidoPrompt = workspace:WaitForChild("Construcoes"):WaitForChild("Pizzaria"):WaitForChild("ifoodplace"):WaitForChild("Pizza3"):WaitForChild("ProximityPrompt")
local padsFolder = workspace:WaitForChild("Construcoes"):WaitForChild("Pizzaria"):WaitForChild("OrderCharSpawns")

-- Noclip (raycast)
getgenv().noclipConn = getgenv().noclipConn or nil
local function ativarNoclip()
    if not getgenv().noclipConn then
        getgenv().noclipConn = game:GetService("RunService").Stepped:Connect(function()
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end
local function desativarNoclip()
    if getgenv().noclipConn then
        pcall(function() getgenv().noclipConn:Disconnect() end)
        getgenv().noclipConn = nil
    end
end

-- Fly com raycast, igual ao script de plantas (ativa/desativa noclip internamente)
local function flyAteProximoChao(pos, toleranciaChegada)
    toleranciaChegada = toleranciaChegada or tolerancia
    local destinoXZ = Vector3.new(pos.X, 0, pos.Z)
    while (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - destinoXZ).Magnitude > toleranciaChegada and _G.ifood_autofarm_ativo do
        ativarNoclip()
        local atual = hrp.Position
        local dir = (Vector3.new(pos.X, atual.Y, pos.Z) - atual).Unit
        local passoXZ = math.min((Vector3.new(atual.X, 0, atual.Z) - destinoXZ).Magnitude, FLY_VELOCIDADE * 0.08)
        local proximoXZ = Vector3.new(atual.X, 0, atual.Z) + Vector3.new(dir.X, 0, dir.Z) * passoXZ
        local rayOrigem = Vector3.new(proximoXZ.X, atual.Y + 50, proximoXZ.Z)
        local rayDirecao = Vector3.new(0, -200, 0)
        local hit, hitPos = workspace:FindPartOnRay(Ray.new(rayOrigem, rayDirecao), char)
        local alturaDestino = hitPos and (hitPos.Y + DISTANCIA_MINIMA_CHAO + ALTURA_FLY) or (pos.Y + ALTURA_FLY)
        hrp.CFrame = CFrame.new(proximoXZ.X, alturaDestino, proximoXZ.Z)
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.PlatformStand = false
        wait(0.03)
    end
    -- Chegou no destino: desativa noclip/raycast
    desativarNoclip()
    hrp.CFrame = CFrame.new(pos.X, pos.Y + ALTURA_FLY, pos.Z)
end

-- Função universal para acionar ProximityPrompt
local function firePrompt(prompt)
    if prompt then
        if typeof(fireproximityprompt) == "function" then
            pcall(function() fireproximityprompt(prompt, 0) end)
        elseif typeof(fireProximityPrompt) == "function" then
            pcall(function() fireProximityPrompt(prompt, 0) end)
        end
        wait(0.35)
        return true
    end
    return false
end

-- Busca pad com pedido pronto (tem ProximityPrompt em OrderChar)
local function encontrarPadComPrompt()
    for i = 1, 7 do
        local pad = padsFolder:FindFirstChild("Pad"..i)
        if pad and pad:FindFirstChild("OrderChar") then
            local prompt = pad.OrderChar:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                return pad.OrderChar, prompt
            end
        end
    end
    return nil, nil
end

-- Função para verificar se algum pad ficou com pedido
local function existePedidoEmPad()
    for i = 1, 7 do
        local pad = padsFolder:FindFirstChild("Pad"..i)
        if pad and pad:FindFirstChild("OrderChar") then
            local prompt = pad.OrderChar:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                return true
            end
        end
    end
    return false
end

_G.ifood_autofarm_ativo = true

spawn(function()
    while _G.ifood_autofarm_ativo do
        -- 1. Vai voando baixo (fly raycast) até o prompt do pedido
        ativarNoclip() -- Garante que começa com noclip ativado
        local pedidoObtido = false
        local tentativas = 0
        repeat
            tentativas = tentativas + 1
            flyAteProximoChao(pedidoPrompt.Parent.Position) -- Desativa noclip ao chegar
            -- Noclip agora está DESATIVADO aqui
            wait(0.2)
            firePrompt(pedidoPrompt)
            wait(0.2)
            firePrompt(pedidoPrompt)
            wait(0.3)
            pedidoObtido = existePedidoEmPad()
            if pedidoObtido then break end
            ativarNoclip() -- Reativa noclip antes de tentar voar de novo, se necessário
        until pedidoObtido or tentativas >= MAX_TENTATIVAS_PEDIDO or not _G.ifood_autofarm_ativo

        -- Se não pegou o pedido, pode esperar e tentar de novo (volta pro início do loop)
        if not pedidoObtido then
            wait(0.8)
            continue
        end

        -- 2. Busca o pad de entrega com pedido pronto!
        local pad, padPrompt = nil, nil
        repeat
            pad, padPrompt = encontrarPadComPrompt()
            if not pad then wait(0.5) end
        until pad and padPrompt or not _G.ifood_autofarm_ativo
        if not pad or not padPrompt then wait(1) continue end

        -- 3. Vai voando baixo até o pad de entrega (com raycast/noclip)
        ativarNoclip()
        flyAteProximoChao(pad.Position)
        -- Noclip DESATIVADO ao chegar
        wait(0.2)

        -- 4. Entrega o pedido
        firePrompt(padPrompt)
        wait(0.5)
    end
    desativarNoclip()
end)

-- Para parar o autofarm:
-- _G.ifood_autofarm_ativo = false 
-- if getgenv().noclipConn then pcall(function() getgenv().noclipConn:Disconnect() end) end

-- DICA: Para ajustar velocidade altere a variável FLY_VELOCIDADE no topo do script!
