print("████ FRUIT SNIPER (VERSÃO ULTRA - INTEGRAL) █████")

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

local function isMythicalFruit(name)
	local normalized = string.lower(name or "")
	for _, mythical in ipairs(MYTHICAL_FRUITS) do
		if string.find(normalized, mythical) then 
			return true 
		end
	end
	return false
end

local function findMythicalFruit()
	for _, instance in ipairs(Workspace:GetDescendants()) do
		if instance:IsA("Model") and string.find(instance.Name, "Fruit") then
			if isMythicalFruit(instance.Name) then
				print("[SUCESSO] Fruta mítica localizada: " .. instance.Name)
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
	local tweenTime = distance / 250 
	
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

local function storeFruit()
	print("[SISTEMA] Guardando fruta no inventário...")
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local storeRemote = remotes and remotes:FindFirstChild("CommF_")
	
	if storeRemote then
		local tool = player.Character:FindFirstChildWhichIsA("Tool")
		if tool then
			storeRemote:InvokeServer("StoreFruit", tool.Name)
			print("[SISTEMA] Fruta armazenada!")
		else
			local backpackFruit = player.Backpack:FindFirstChildWhichIsA("Tool")
			if backpackFruit and string.find(backpackFruit.Name, "Fruit") then
				backpackFruit.Parent = player.Character
				task.wait(0.5)
				storeRemote:InvokeServer("StoreFruit", backpackFruit.Name)
				print("[SISTEMA] Fruta armazenada!")
			end
		end
	end
end

-- Novo Sistema de Server Hop via API Oficial decodificada por Executor
local function serverHop()
	print("[SISTEMA] Escaneando a lista oficial de servidores públicos do Roblox...")
	
	local requestMethod = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request)
	if not requestMethod then
		print("[ERRO] Seu executor não suporta requisições HTTP básicas.")
		return
	end
	
	-- API Oficial do Roblox (sem proxy intermediário que costuma cair)
	local url = "https://roblox.com" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
	
	local success, response = pcall(function()
		return requestMethod({ Url = url, Method = "GET" })
	end)
	
	if success and response and response.Body then
		local data = HttpService:JSONDecode(response.Body)
		if data and data.data then
			local validServers = {}
			
			for _, server in ipairs(data.data) do
				-- Filtra para NÃO pegar o seu próprio servidor e verificar se há vagas livres
				if tostring(server.id) ~= tostring(game.JobId) and (server.playing or 0) < (server.maxPlayers or 12) then
					table.insert(validServers, server.id)
				end
			end
			
			if #validServers > 0 then
				-- Escolhe um servidor aleatório da lista válida para evitar tentar entrar no mesmo toda hora
				local randomServerId = validServers[math.random(1, #validServers)]
				print("[TELEPORTE] Servidor encontrado com sucesso! Conectando...")
				
				-- Executa o teleporte forçado via ID de instância externa
				TeleportService:TeleportToPlaceInstance(placeId, randomServerId, player)
				return
			end
		end
	end
	
	-- Fallback ultra-básico caso a listagem falhe por completo
	print("[AVISO] Falha ao ler lista detalhada. Forçando teleporte básico randômico...")
	pcall(function()
		TeleportService:Teleport(placeId, player)
	end)
end

print("Script carregado! Verificação iniciada.")

task.spawn(function()
	while true do
		local fruit = findMythicalFruit()
		
		if fruit then
			local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
			if part then
				print("[AÇÃO] Fruta mítica na área! Coletando...")
				moveTo(part.Position)
				task.wait(1)
				
				if firetouchinterest then
					firetouchinterest(player.Character.HumanoidRootPart, part, 0)
					task.wait(0.5)
					firetouchinterest(player.Character.HumanoidRootPart, part, 1)
				end
				
				task.wait(1)
				storeFruit()
				task.wait(2)
			end
		else
			print("[SCANNER] Sem frutas míticas neste servidor. Mudando de mapa agora...")
			serverHop()
			task.wait(7) -- Tempo de segurança para a engine processar a troca de mapa
		end
		task.wait(2)
	end
end)
