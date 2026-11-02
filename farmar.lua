print("████ FRUIT SNIPER INICIADO (VERSÃO CORRIGIDA) █████")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- Nomes das frutas em letras minúsculas para facilitar a busca por aproximação
local MYTHICAL_FRUITS = {
	"leopard", "dragon", "kitsune", "spirit", "venom", "dough",
	"shadow", "gravity", "mammoth", "trex"
}

local function isMythicalFruit(name)
	local normalized = string.lower(name or "")
	for _, mythical in ipairs(MYTHICAL_FRUITS) do
		-- Mudado para 'find' para detectar mesmo se o nome for "Leopard Fruit" ou "Physical Leopard"
		if string.find(normalized, mythical) then 
			return true 
		end
	end
	return false
end

local function findMythicalFruit()
	for _, instance in ipairs(Workspace:GetDescendants()) do
		-- No Blox Fruits, as frutas no chão geralmente são Models e contêm "Fruit" no nome
		if instance:IsA("Model") and string.find(instance.Name, "Fruit") then
			if isMythicalFruit(instance.Name) then
				print("Fruta mítica detectada: " .. instance.Name)
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
	local tweenTime = distance / 250 -- Velocidade de segurança contra anti-cheat
	
	local tween = TweenService:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPosition)})
	
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
	end)
	
	tween:Play()
	tween.Completed:Wait()
	
	if noclipConnection then 
		noclipConnection:Disconnect() 
		noclipConnection = nil
	end
end

-- Função para armazenar a fruta (Blox Fruits usa eventos remotos para isso)
local function storeFruit()
	print("Tentando armazenar a fruta...")
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local storeRemote = remotes and remotes:FindFirstChild("CommF_")
	
	if storeRemote then
		-- Dispara o comando interno do Blox Fruits para guardar a fruta que está na mão
		storeRemote:InvokeServer("StoreFruit", player.Character:FindFirstChildWhichIsA("Tool") and player.Character:FindFirstChildWhichIsA("Tool").Name)
		print("Fruta armazenada com sucesso!")
	else
		print("Não foi possível encontrar o evento de armazenar.")
	end
end

local function serverHop()
	local url = "https://games.roproxy.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
	
	-- ATENÇÃO: HttpGet é uma função que depende do seu EXECUTOR. Mudado para syn.request/http_request se disponível.
	local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request)
	
	if httpRequest then
		local success, response = pcall(function()
			return httpRequest({ Url = url, Method = "GET" })
		end)
		
		if success and response and response.Body then
			local data = HttpService:JSONDecode(response.Body)
			if data and data.data then
				for _, server in ipairs(data.data) do
					if server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 12) then
						print("Teleportando para um novo servidor...")
						TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
						return
					end
				end
			end
		end
	elseif game.HttpGet then -- Fallback caso seu executor use a sintaxe antiga
		local success, res = pcall(function() return game:HttpGet(url) end)
		if success and res then
			local data = HttpService:JSONDecode(res)
			if data and data.data then
				for _, server in ipairs(data.data) do
					if server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 12) then
						print("Teleportando para um novo servidor...")
						TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
						return
					end
				end
			end
		end
	end
	print("Nenhum servidor novo encontrado. Tentando novamente...")
end

print("Script carregado! Procurando frutas...")

-- Loop principal
task.spawn(function()
	while true do
		local fruit = findMythicalFruit()
		if fruit then
			local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
			if part then
				print("Voando até a fruta...")
				moveTo(part.Position)
				task.wait(1)
				-- Coleta automática ao encostar (tocando a fruta se necessário)
				firetouchinterest(player.Character.HumanoidRootPart, part, 0)
				task.wait(0.5)
				firetouchinterest(player.Character.HumanoidRootPart, part, 1)
				task.wait(1)
				storeFruit() -- Tenta guardar no baú
				task.wait(2)
			end
		else
			print("Nenhuma fruta mítica no mapa. Iniciando Server Hop...")
			serverHop()
			task.wait(5) -- Espera antes de tentar outro hop se falhar
		end
		task.wait(2)
	end
end)
