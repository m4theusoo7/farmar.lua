local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

local function isValidFruit(obj)
	-- Evita o erro de "Folder" garantindo que é apenas Model ou Tool
	if not (obj:IsA("Model") or obj:IsA("Tool")) then return false end
	
	-- Verifica se o nome contém "Fruit"
	if not string.find(string.lower(obj.Name), "fruit") then return false end
	
	-- Bloqueia Vendedores de Fruta e outros NPCs (Eles sempre têm um Humanoid)
	if obj:FindFirstChildWhichIsA("Humanoid") then return false end
	if string.find(string.lower(obj.Name), "dealer") then return false end
	
	return true
end

local function createESP(fruit)
	local part = fruit:FindFirstChild("Handle") or fruit:FindFirstChildWhichIsA("BasePart")
	if fruit:IsA("Model") and not part then
		part = fruit.PrimaryPart
	end
	
	if not part then return end
	if part:FindFirstChild("FruitESPMarker") then return end

	-- Marca a parte para não duplicar a ESP
	local marker = Instance.new("BoolValue")
	marker.Name = "FruitESPMarker"
	marker.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FruitESP"
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	
	-- Tenta esconder na CoreGui para segurança contra o Anti-Cheat
	local success = pcall(function() billboard.Parent = CoreGui end)
	if not success then billboard.Parent = part end

	local text = Instance.new("TextLabel")
	text.Parent = billboard
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Font = Enum.Font.Code
	text.TextSize = 16
	text.TextColor3 = Color3.fromRGB(0, 255, 127) -- Verde claro chamativo
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

	-- Usa o Heartbeat para atualizar a distância sem causar lag
	local connection
	connection = RunService.Heartbeat:Connect(function()
		-- Se a fruta for apanhada ou sumir, destroi a ESP e cancela a atualização
		if not part or not part.Parent or part.Parent.Parent == player.Character or part.Parent.Parent == game.Players.LocalPlayer:FindFirstChild("Backpack") then
			if billboard then billboard:Destroy() end
			if connection then connection:Disconnect() end
			return
		end
		
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - part.Position).Magnitude
			text.Text = string.format("%s\n[ %d m ]", fruit.Name, math.floor(dist))
		end
	end)
end

local function scanFruits()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if isValidFruit(obj) then
			createESP(obj)
		end
	end
end

-- 1. Verifica tudo assim que entra no servidor
scanFruits()

-- 2. Fica monitorando se alguma fruta nova spawnar no mapa
Workspace.DescendantAdded:Connect(function(obj)
	task.wait(1) -- Aguarda 1 segundo para a fruta carregar todas as suas partes físicas
	if isValidFruit(obj) then
		createESP(obj)
	end
end)
