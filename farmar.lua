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

local function criarESP(fruta, part)
	if part:FindFirstChild("FruitESP") then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FruitESP"
	billboard.Parent = part
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true

	local text = Instance.new("TextLabel")
	text.Parent = billboard
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Font = Enum.Font.Code
	text.TextSize = 18
	text.TextColor3 = Color3.fromRGB(0, 255, 0)
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

	task.spawn(function()
		while part and part.Parent and part.Parent.Parent ~= player.Character do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - part.Position).Magnitude
				text.Text = string.format("%s\n[ %d m ]", fruta.Name, math.floor(dist))
			end
			task.wait(0.1)
		end
		if billboard then billboard:Destroy() end
	end)
end

local function getFruit()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if (v:IsA("Model") or v:IsA("Tool")) and string.find(v.Name, "Fruit") then
			if not v:FindFirstChildOfClass("Humanoid") and not string.find(string.lower(v.Name), "dealer") then
				local part = v:FindFirstChild("Handle") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
				if part then
					criarESP(v, part)
				end
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
	local speed = 250 
	local timeToTravel = distance / speed
	
	-- Corrige o bug de movimentação (gravidade/tremedeira) usando BodyVelocity
	local antiGravity = Instance.new("BodyVelocity")
	antiGravity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	antiGravity.Velocity = Vector3.zero
	antiGravity.Parent = root
	
	local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
	
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
	if antiGravity then
		antiGravity:Destroy()
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
			-- Fica um pouco acima da fruta para coletar em segurança e evitar prender no chão
			tweenTo(part.Position + Vector3.new(0, 2, 0))
			task.wait(2)
			
			autoFarmFruit()
		end
	else
		print("Nenhuma fruta no mapa. A procurar noutro servidor...")
		serverHop()
	end
end

autoFarmFruit()
