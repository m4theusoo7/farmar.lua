local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
repeat task.wait() until game:IsLoaded()

local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request
local noclipConnection

local function getFruit()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if (v:IsA("Model") or v:IsA("Tool")) and string.find(v.Name, "Fruit") then
			if not v:FindFirstChildOfClass("Humanoid") and not string.find(string.lower(v.Name), "dealer") then
				return v
			end
		end
	end
	return nil
end

local function tweenTo(targetPos)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local root = char.HumanoidRootPart
	
	local distance = (root.Position - targetPos).Magnitude
	local speed = 250 -- Velocidade segura para evitar ser "kickado"
	local timeToTravel = distance / speed
	
	local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
	
	-- Ativa o Noclip (atravessar paredes) durante o voo
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
	
	tween:Play()
	tween.Completed:Wait()
	
	-- Desativa o Noclip ao chegar
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
end

local function serverHop()
	if not requestFunc then
		print("Erro: O seu executor não suporta a função de Server Hop.")
		return
	end
	
	print("A iniciar Server Hop...")
	local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
	
	local success, response = pcall(function() return requestFunc({Url = url, Method = "GET"}) end)
	
	if success and response and response.Body then
		local dataSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
		if dataSuccess and data and data.data then
			for _, server in ipairs(data.data) do
				if type(server) == "table" and server.id ~= game.JobId then
					local playing = server.playing or 0
					local max = server.maxPlayers or 12
					if playing < max then
						print("A teleportar para um novo servidor...")
						TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
						return
					end
				end
			end
		end
	end
	
	print("Falha ao encontrar servidor. A tentar novamente em 5 segundos...")
	task.wait(5)
	serverHop()
end

local function autoFarmFruit()
	print("A procurar frutas no servidor...")
	local fruit = getFruit()
	
	if fruit then
		local part = fruit:FindFirstChild("Handle") or fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
		if part then
			print("Fruta encontrada (" .. fruit.Name .. ")! A voar até ela...")
			-- Fica um pouco acima da fruta para coletar em segurança
			tweenTo(part.Position)
			task.wait(2) -- Aguarda 2 segundos para o jogo registar a coleta
			
			-- Procura novamente para ver se há mais frutas ou se muda de servidor
			autoFarmFruit()
		end
	else
		print("Nenhuma fruta no mapa. A procurar noutro servidor...")
		serverHop()
	end
end

-- Inicia a automação
autoFarmFruit()
