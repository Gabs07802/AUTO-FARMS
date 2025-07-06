-- AUTO FARM IFOOD AVANÇADO
-- Ajuste aqui a velocidade do fly (studs/segundo):
local FLY_VELOCIDADE = 20 -- <<<<< ALTERE AQUI A VELOCIDADE

-- Altura em que o personagem "voa" (0 = encostado no chão)
local ALTURA_FLY = 1.5

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
    -- Mantém o humanoid sempre "Running" e nunca caindo
    local destino = Vector3.new(pos.X, pos.Y + ALTURA_FLY, pos.Z)
    while (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(destino.X, 0, destino.Z)).Magnitude > tolerancia and _G.ifood_autofarm_ativo do
        -- Noclip sempre ligado
        ativarNoclip()
        -- Calcula direção só no plano XZ
        local atual = hrp.Position
        local dir = (Vector3.new(destino.X, atual.Y, destino.Z) - atual).Unit
        local passoXZ = math.min((Vector3.new(atual.X, 0, atual.Z) - Vector3.new(destino.X, 0, destino.Z)).Magnitude, FLY_VELOCIDADE * 0.08)
        -- Mantém altura constante (ALTURA_FLY acima do solo)
        local proximo = Vector3.new(atual.X, 0, atual.Z) + Vector3.new(dir.X, 0, dir.Z) * passoXZ
        hrp.CFrame = CFrame.new(proximo.X, pos.Y + ALTURA_FLY, proximo.Z)
        -- Simula andar (evita estado de queda)
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

_G.ifood_autofarm_ativo = true

spawn(function()
    ativarNoclip()
    while _G.ifood_autofarm_ativo do
        -- 1. Vai voando baixo até o prompt do pedido
        flyAte(pedidoPrompt.Parent.Position)
        wait(0.2)
        firePrompt(pedidoPrompt)
        wait(0.2)
        firePrompt(pedidoPrompt)
        wait(0.3)

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

--[[ 
Se quiser parar o autofarm:
_G.ifood_autofarm_ativo = false 
if getgenv().noclipConn then pcall(function() getgenv().noclipConn:Disconnect() end) end
]]

--[[ 
DICA: Para ajustar velocidade altere a variável FLY_VELOCIDADE no topo do script!
]]
