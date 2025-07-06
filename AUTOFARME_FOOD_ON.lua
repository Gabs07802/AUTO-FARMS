-- AUTO FARM IFOOD ROBUSTO PARA SERVIDORES LAGADOS
-- Ajuste a velocidade do fly aqui:
local FLY_VELOCIDADE = 25 -- <<<<< ALTERE AQUI A VELOCIDADE

-- Altura em que o personagem "voa" (0 = encostado no chão)
local ALTURA_FLY = 1.5

local MAX_TENTATIVAS_PEDIDO = 2 -- Quantas tentativas de pegar pedido caso não apareça o pad

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- Caminho para pegar pedido/bag
local pedidoPrompt = workspace:WaitForChild("Construcoes"):WaitForChild("Pizzaria"):WaitForChild("ifoodplace"):WaitForChild("Pizza3"):WaitForChild("ProximityPrompt")

-- Caminho dos pads de entrega
local padsFolder = workspace:WaitForChild("Construcoes"):WaitForChild("Pizzaria"):WaitForChild("OrderCharSpawns")

local tolerancia = 2

-- Noclip enquanto voa
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

-- Função de fly baixo, disfarçando como andar
local function flyAte(pos)
    local destino = Vector3.new(pos.X, pos.Y + ALTURA_FLY, pos.Z)
    while (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destino.X, 0, destino.Z)).Magnitude > tolerancia and _G.ifood_autofarm_ativo do
        ativarNoclip()
        local atual = hrp.Position
        local dir = (Vector3.new(destino.X, atual.Y, destino.Z) - atual).Unit
        local passoXZ = math.min((Vector3.new(atual.X, 0, atual.Z) - Vector3.new(destino.X, 0, destino.Z)).Magnitude, FLY_VELOCIDADE * 0.08)
        local proximo = Vector3.new(atual.X, 0, atual.Z) + Vector3.new(dir.X, 0, dir.Z) * passoXZ
        hrp.CFrame = CFrame.new(proximo.X, pos.Y + ALTURA_FLY, proximo.Z)
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.PlatformStand = false
        wait(0.03)
    end
    if _G.ifood_autofarm_ativo then
        hrp.CFrame = CFrame.new(destino)
    end
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
    ativarNoclip()
    while _G.ifood_autofarm_ativo do
        -- 1. Vai voando baixo até o prompt do pedido
        local pedidoObtido = false
        local tentativas = 0
        repeat
            tentativas = tentativas + 1
            flyAte(pedidoPrompt.Parent.Position)
            wait(0.2)
            firePrompt(pedidoPrompt)
            wait(0.2)
            firePrompt(pedidoPrompt)
            wait(0.3)
            pedidoObtido = existePedidoEmPad()
            if pedidoObtido then break end
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

        -- 3. Vai voando baixo até o pad de entrega
        flyAte(pad.Position)
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
