local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

local function createESP(fruit)
	-- Procura a parte principal da fruta (Handle, PrimaryPart ou BasePart)
	local part = fruit:FindFirstChild("Handle") or fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
	if not part then return end
	if part:FindFirstChild("FruitESP") then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FruitESP"
	billboard.Adornee = part
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	
	pcall(function() billboard.Parent = game:GetService("CoreGui") end)
	if billboard.Parent ~= game:GetService("CoreGui") then
		billboard.Parent = part
	end

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
		-- Mantém a ESP apenas enquanto a fruta estiver no chão (se for apanhada, apaga)
		while part and part.Parent and part.Parent.Parent ~= player.Character do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - part.Position).Magnitude
				text.Text = string.format("%s\n[ %d m ]", fruit.Name, math.floor(dist))
			end
			task.wait(0.1)
		end
		if billboard then billboard:Destroy() end
	end)
end

local function scanFruits()
	for _, v in ipairs(Workspace:GetDescendants()) do
		-- Verifica se o nome contém "Fruit" (Ignorando se é Model ou Tool)
		if string.find(v.Name, "Fruit") then
			-- Garante que não é um NPC (Vendedor/Dealer)
			if not v:FindFirstChildOfClass("Humanoid") and not string.find(string.lower(v.Name), "dealer") then
				createESP(v)
			end
		end
	end
end

-- 1. Escaneia o mapa ao entrar no jogo
scanFruits()

-- 2. Fica a observar caso nasçam frutas novas ou alguém deixe cair uma
Workspace.DescendantAdded:Connect(function(v)
	task.wait(0.5) -- Aguarda a fruta carregar totalmente
	if v and v.Parent and string.find(v.Name, "Fruit") then
		if not v:FindFirstChildOfClass("Humanoid") and not string.find(string.lower(v.Name), "dealer") then
			createESP(v)
		end
	end
end)
