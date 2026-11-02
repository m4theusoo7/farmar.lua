print("███ VERIFICADOR DE FRUTAS + ESP + HOP ███")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId

-- Garante que o jogo carregou antes de procurar
repeat task.wait() until game:IsLoaded()

---------------------------------------------------------
-- SISTEMA DE ESP (NOME E DISTÂNCIA)
---------------------------------------------------------
local function criarESP(frutaModel)
	local part = frutaModel.PrimaryPart or frutaModel:FindFirstChildWhichIsA("BasePart")
	if not part then return end

	-- Evita criar duas ESPs na mesma fruta
	if part:FindFirstChild("FruitESP") then return end

	-- Criar a interface visual (Billboard)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FruitESP"
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0) -- Fica a flutuar em cima da fruta
	billboard.AlwaysOnTop = true -- Vê-se através das paredes
	
	-- Tenta esconder a ESP na pasta CoreGui (mais seguro), se falhar põe na própria fruta
	local success = pcall(function()
		billboard.Parent = game:GetService("CoreGui")
	end)
	if not success then
		billboard.Parent = part
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Parent = billboard
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Font = Enum.Font.Code
	textLabel.TextSize = 18
	textLabel.TextColor3 = Color3.fromRGB(0, 255, 100) -- Verde néon chamativo
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Borda preta

	-- Atualizar a distância constantemente
	task.spawn(function()
		while part and part.Parent do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local rootPos = player.Character.HumanoidRootPart.Position
				local dist = (rootPos - part.Position).Magnitude
				textLabel.Text = string.format("%s\n[ %d m ]", frutaModel.Name, math.floor(dist))
			end
			task.wait(0.1)
		end
		-- Limpa a ESP se a fruta for comida ou sumir
		if billboard then billboard:Destroy() end
	end)
end

---------------------------------------------------------
-- VERIFICADOR DE FRUTAS
---------------------------------------------------------
local function buscarFrutas()
	local encontrou = false
	for _, obj in ipairs(Workspace:GetDescendants()) do
		-- O Blox Fruits usa "Fruit" no nome dos modelos que estão caídos no chão
		if obj:IsA("Model") and string.find(obj.Name, "Fruit") then
			criarESP(obj)
			encontrou = true
		end
	end
	return encontrou
end

---------------------------------------------------------
-- SERVER HOP (MUDAR DE SERVIDOR)
---------------------------------------------------------
local function serverHop()
	local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request
	
	if not requestFunc then
		print("Erro: O seu executor não suporta requests HTTP.")
		return
	end

	print("Nenhuma fruta no mapa. A procurar um novo servidor...")
	local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"

	local success, response = pcall(function()
		return requestFunc({ Url = url, Method = "GET" })
	end)

	if success and response and response.Body then
		local dataSuccess, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		
		if dataSuccess and data and data.data then
			for _, server in ipairs(data.data) do
				if type(server) == "table" and server.id ~= jobId then
					local playing = server.playing or 0
					local max = server.maxPlayers or 12
					
					if playing < max then
						print("A teleportar para o servidor: " .. tostring(server.id))
						TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
						return
					end
				end
			end
		end
	end
	
	print("Nenhum servidor com vagas encontrado. A tentar novamente em 5 segundos...")
	task.wait(5)
	serverHop()
end

---------------------------------------------------------
-- EXECUÇÃO PRINCIPAL
---------------------------------------------------------
print("A verificar o mapa...")
local temFruta = buscarFrutas()

if temFruta then
	print("Fruta encontrada! A ESP foi ativada no seu ecrã.")
	
	-- Caso nasça uma fruta NOVA enquanto você ainda está nesse servidor
	Workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("Model") and string.find(obj.Name, "Fruit") then
			task.wait(1) -- Aguarda os polígonos carregarem
			criarESP(obj)
			print("Uma fruta nova acabou de nascer (" .. obj.Name .. ")!")
		end
	end)
else
	-- Se não tiver fruta nenhuma ao entrar, muda logo de server
	serverHop()
end
