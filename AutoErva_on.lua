-- AUTO FARM PLANTAS - Equipando potes pelo nome, sem repetir e sem vender vazio!
-- Adaptação para potes que têm mesmo nome ("PoteErva") e podem se repetir
-- Ref: ![image1](image1)

local FLY_VELOCIDADE = 45
local ALTURA_FLY = 1.5
local DISTANCIA_MINIMA_CHAO = 1
local tolerancia = 2
local toleranciaEntrega = 5

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local backpack = player:WaitForChild("Backpack")

local plantasFolder = workspace:WaitForChild("Construcoes"):WaitForChild("Plantinha_Ilegal")
local vendedorPrompt = plantasFolder:WaitForChild("Vendedor"):WaitForChild("PROXI"):WaitForChild("ProximityPrompt")

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

local function flyAteProximoChao(pos, toleranciaChegada)
    toleranciaChegada = toleranciaChegada or tolerancia
    local destinoXZ = Vector3.new(pos.X, 0, pos.Z)
    while (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - destinoXZ).Magnitude > toleranciaChegada and _G.plant_autofarm_ativo do
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
    hrp.CFrame = CFrame.new(pos.X, pos.Y + ALTURA_FLY, pos.Z)
end

local function firePrompt(prompt)
    if prompt then
        if typeof(fireproximityprompt) == "function" then
            pcall(function() fireproximityprompt(prompt, 0) end)
        elseif typeof(fireProximityPrompt) == "function" then
            pcall(function() fireProximityPrompt(prompt, 0) end)
        end
        wait(0.4)
        return true
    end
    return false
end

local function encontrarPlantaDisponivel()
    for _, plantinha in ipairs(plantasFolder:GetChildren()) do
        if plantinha.Name == "Plantinha" and plantinha:FindFirstChild("ProximityPrompt") then
            local prompt = plantinha:FindFirstChild("ProximityPrompt")
            if prompt.Enabled then
                return plantinha, prompt
            end
        end
    end
    return nil, nil
end

-- Detecta todos os potes com mesmo nome e retorna como uma tabela: {tool = ToolInstance, plantas = int}
local function getPotes()
    local potes = {}
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name == "PoteErva" then
            table.insert(potes, {tool = item, plantas = 0})
        end
    end
    return potes
end

-- Equipa o pote pelo objeto ToolInstance
local function equiparPoteObj(poteObj)
    if poteObj and poteObj.tool and player.Character then
        player.Character.Humanoid:EquipTool(poteObj.tool)
        wait(0.35)
    end
end

local function poteCheio(poteObj)
    return poteObj.plantas >= 10
end

local function todosPotesCheios(potes)
    for _, poteObj in ipairs(potes) do
        if poteObj.plantas < 10 then return false end
    end
    return true
end

local function todosPotesVendidos(potes)
    for _, poteObj in ipairs(potes) do
        if poteObj.plantas > 0 then return false end
    end
    return true
end

_G.plant_autofarm_ativo = true

spawn(function()
    ativarNoclip()
    while _G.plant_autofarm_ativo do
        local potes = getPotes()
        if #potes == 0 then
            warn("Nenhum pote encontrado!")
            wait(1)
            continue
        end

        -- 1. Encher todos os potes (sem repetir, só enche quem não está cheio)
        for poteIdx, poteObj in ipairs(potes) do
            while not poteCheio(poteObj) and _G.plant_autofarm_ativo do
                equiparPoteObj(poteObj)
                local planta, prompt = encontrarPlantaDisponivel()
                if not planta or not prompt then
                    wait(0.5)
                    continue
                end
                flyAteProximoChao(planta.Position)
                wait(0.18)
                firePrompt(prompt)
                wait(6)
                poteObj.plantas = poteObj.plantas + 1
                if poteCheio(poteObj) then
                    break
                end
            end
        end

        -- 2. Se todos potes cheios, ir ao vendedor e vender só os potes que têm plantas (>0)
        if todosPotesCheios(potes) then
            for _, poteObj in ipairs(potes) do
                if poteObj.plantas > 0 then
                    equiparPoteObj(poteObj)
                    flyAteProximoChao(vendedorPrompt.Parent.Position, toleranciaEntrega)
                    wait(0.2)
                    firePrompt(vendedorPrompt)
                    poteObj.plantas = 0
                    wait(1.2)
                end
            end
        end

        if not todosPotesVendidos(potes) then
            wait(0.5)
        end
    end
    desativarNoclip()
end)

-- Para parar o autofarm:
-- _G.plant_autofarm_ativo = false
-- if getgenv().noclipConn then pcall(function() getgenv().noclipConn:Disconnect() end) end
