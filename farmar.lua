--[[
	====================================================================
	   Fruit Sniper / Server Hopper (Corrigido para Executores)
	   Blox Fruits — Script de Automação e Otimização de Farm
	====================================================================
]]

print("████ FRUIT SNIPER INICIADO █████")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

local CONFIG = {
	FRUIT_KEYWORD = "Fruit",
	SCAN_TIMEOUT = 3,
	TWEEN_SPEED = 250, -- Velocidade (Studs por segundo). Mantenha abaixo de 300 para não tomar Kick/Ban.
	COLLECT_SETTLE_TIME = 2,
	SERVER_LIMIT = 100,
	FILE_NAME = "FruitSniper_VisitedServers.json"
}

local MYTHICAL_FRUITS = {
	"leopard", "dragon", "kitsune", "spirit", "venom", "dough",
	"shadow", "gravity", "mammoth", "trex",
}

------------------------------------------------------------------------
-- SISTEMA DE SALVAMENTO DE SERVIDORES (EVITA VOLTAR PRO MESMO SERVER)
------------------------------------------------------------------------
local visitedServers = {}

-- Carrega os servidores visitados do arquivo, se existir
if isfile and isfile(CONFIG.FILE_NAME) then
	local success, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(CONFIG.FILE_NAME))
	end)
	if success and type(decoded) == "table" then
		visitedServers = decoded
	end
end

local function saveServers()
	if writefile then
		writefile(CONFIG.FILE_NAME, HttpService:JSONEncode(visitedServers))
	end
end

------------------------------------------------------------------------
-- LÓGICA DE BUSCA DE FRUTAS
------------------------------------------------------------------------
local function normalizeFruitName(name)
	local normalized = string.lower(name or "")
	normalized = string.gsub(normalized, "%s", "")
	normalized = string.gsub(normalized, "fruit", "")
	return normalized
end

local function isMythicalFruit(name)
	local normalized = normalizeFruitName(name)
	for _, mythical in ipairs(MYTHICAL_FRUITS) do
		if normalized == mythical then return true end
	end
	return false
end

local function findMythicalFruit()
	local descendants = Workspace:GetDescendants()
	for _, instance in ipairs(descendants) do
		if instance:IsA("Model") and instance.Name:find(CONFIG.FRUIT_KEYWORD, 1, true) then
			if isMythicalFruit(instance.Name) then
				print("Fruit Sniper: Fruta mítica detectada -> " .. instance.Name)
				return instance
			end
		end
	end
	return nil
end

local function getFruitPosition(fruit)
	if not fruit:IsA("Model") then return nil end
	local primaryPart = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
	return primaryPart and primaryPart.Position or nil
end

------------------------------------------------------------------------
-- MOVIMENTAÇÃO SEGURA (TWEEN + NOCLIP)
------------------------------------------------------------------------
local noclipConnection

local function movePlayerToPosition(targetPosition)
	local character = player.Character
	if not character then return false end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Calcula o tempo de viagem baseado na distância (Evita Anti-Cheat)
	local distance = (rootPart.Position - targetPosition).Magnitude
	local tweenTime = distance / CONFIG.TWEEN_SPEED

	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(rootPart, tweenInfo, { CFrame = CFrame.new(targetPosition) })

	-- Ativa o Noclip para atravessar paredes durante o voo
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end)

	tween:Play()
	tween.Completed:Wait()

	-- Desativa o Noclip ao chegar
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end

	return true
end

------------------------------------------------------------------------
-- SERVER HOP (MUDANÇA DE SERVIDOR)
------------------------------------------------------------------------
local function getAvailableServer()
	-- Usa o RoProxy pois o Roblox bloqueia requisições para a própria API dentro do jogo
	local url = "https://games.roproxy.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=" .. tostring(CONFIG.SERVER_LIMIT)

	print("Fruit Sniper: Buscando novos servidores...")
	
	local success, response = pcall(function()
		return game:HttpGet(url)
	end)

	if not success or not response then
		warn("Fruit Sniper: Falha ao buscar servidores.")
		return nil
	end

	local okJson, body = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not okJson or not body or not body.data then
		warn("Fruit Sniper: Resposta inválida da API.")
		return nil
	end

	-- Adiciona o servidor atual na lista de visitados para não cair nele de novo
	visitedServers[game.JobId] = true
	saveServers()

	for _, server in ipairs(body.data) do
		if type(server) == "table" and server.id ~= game.JobId then
			local playingCount = server.playing or 0
			local maxPlayers = server.maxPlayers or 12

			if playingCount < maxPlayers and not visitedServers[server.id] then
				visitedServers[server.id] = true
				saveServers()
				return server.id
			end
		end
	end
	
	return nil
end

local function teleportToServer(serverId)
	print("Fruit Sniper: Teleportando para -> " .. tostring(serverId))
	local success, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
	end)

	if not success then
		warn("Fruit Sniper: Falha ao teleportar -> " .. tostring(err))
	end
end

------------------------------------------------------------------------
-- LOOP PRINCIPAL
------------------------------------------------------------------------
while task.wait(1) do
	local mythicalFruit = findMythicalFruit()

	if mythicalFruit then
		local fruitPosition = getFruitPosition(mythicalFruit)
		if fruitPosition then
			print("Fruit Sniper: Indo coletar a fruta...")
			movePlayerToPosition(fruitPosition)
			task.wait(CONFIG.COLLECT_SETTLE_TIME)
		end
	else
		print("Fruit Sniper: Nenhuma fruta mítica no mapa. Iniciando Server Hop em " .. CONFIG.SCAN_TIMEOUT .. "s...")
		task.wait(CONFIG.SCAN_TIMEOUT)

		local nextServerId = getAvailableServer()
		if nextServerId then
			teleportToServer(nextServerId)
			task.wait(10) -- Aguarda o teleporte iniciar antes de tentar novamente
		else
			print("Fruit Sniper: Nenhum servidor novo encontrado. Limpando lista de servidores e tentando novamente...")
			-- Se esgotar os servidores, limpa a lista e recomeça
			visitedServers = {}
			saveServers()
			task.wait(5)
		end
	end
end

------------------------------------------------------------------------
-- LOOP PRINCIPAL
------------------------------------------------------------------------
while task.wait(1) do
	local mythicalFruit = findMythicalFruit()

	if mythicalFruit then
		local fruitPosition = getFruitPosition(mythicalFruit)
		if fruitPosition then
			print("Fruit Sniper: Indo coletar a fruta...")
			movePlayerToPosition(fruitPosition)
			task.wait(CONFIG.COLLECT_SETTLE_TIME)
		end
	else
		print("Fruit Sniper: Nenhuma fruta mítica no mapa. Iniciando Server Hop em " .. CONFIG.SCAN_TIMEOUT .. "s...")
		task.wait(CONFIG.SCAN_TIMEOUT)

		local nextServerId = getAvailableServer()
		if nextServerId then
			teleportToServer(nextServerId)
			task.wait(10) -- Aguarda o teleporte iniciar antes de tentar novamente
		else
			print("Fruit Sniper: Nenhum servidor novo encontrado. Limpando lista de servidores e tentando novamente...")
			-- Se esgotar os servidores, limpa a lista e recomeça
			visitedServers = {}
			saveServers()
			task.wait(5)
		end
	end
end
