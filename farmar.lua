print("████ FRUIT SNIPER INICIADO (VERSÃO LITE V2) █████")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

local MYTHICAL_FRUITS = {
	"leopard", "dragon", "kitsune", "spirit", "venom", "dough",
	"shadow", "gravity", "mammoth", "trex"
}

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
	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Model") and instance.Name:find("Fruit", 1, true) then
			if isMythicalFruit(instance.Name) then
				print("Fruit Sniper: Fruta mítica detetada -> " .. instance.Name)
				return instance
			end
		end
	end
	return nil
end

local noclipConnection
local function moveTo(targetPosition)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local root = char.HumanoidRootPart
	
	local distance = (root.Position - targetPosition).Magnitude
	local tweenTime = distance / 250 -- Velocidade segura para não ser expulso
	
	local tween = TweenService:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPosition)})
	
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
	
	tween:Play()
	tween.Completed:Wait()
	
	if noclipConnection then 
		noclipConnection:Disconnect() 
		noclipConnection = nil
	end
end

local function serverHop()
	-- API oficial do Roblox (sem usar o proxy antigo que estava a falhar)
	local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
	
	-- Deteta e usa a função nativa de requisições do executor (muito mais forte que o HttpGet normal)
	local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request or function(options)
		local success, response = pcall(function() return game:HttpGet(options.Url) end)
		if success then return {Body = response} else return nil end
	end

	print("Fruit Sniper: A procurar novos servidores...")
	
	local success, response = pcall(function()
		return requestFunc({
			Url = url,
			Method = "GET"
		})
	end)

	if success and response and response.Body then
		local dataSuccess, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		
		if dataSuccess and data and data.data then
			for _, server in ipairs(data.data) do
				if type(server) == "table" and server.id ~= game.JobId then
					local playingCount = server.playing or 0
					local maxPlayers = server.maxPlayers or 12
					
					if playingCount < maxPlayers then
						print("Fruit Sniper: A teleportar para o servidor -> " .. tostring(server.id))
						TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
						return
					end
				end
			end
		end
	end
	
	print("Fruit Sniper: Nenhum servidor encontrado ou falha na API. A tentar novamente em breve...")
end

print("Fruit Sniper: Script carregado! À espera para iniciar a busca...")

while task.wait(3) do
	local fruit = findMythicalFruit()
	if fruit then
		local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
		if part then
			print("Fruit Sniper: A voar até à fruta...")
			moveTo(part.Position)
			task.wait(2)
		end
	else
		print("Fruit Sniper: Nenhuma fruta mítica no mapa. A iniciar Server Hop em 3s...")
		task.wait(3)
		serverHop()
		task.wait(10) -- Espera 10 segundos para dar tempo ao jogo de iniciar o teleporte
	end
end
