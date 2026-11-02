print("████ FRUIT SNIPER INICIADO (V3 - NATIVO) █████")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
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
			print("[AVISO] Equipando fruta para armazenar...")
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

-- Server Hop Nativo e à prova de falhas
local function serverHop()
	print("[TELEPORTE] Procurando novo servidor público automaticamente...")
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ServerBindingMode = Enum.ServerBindingMode.PublicServers
	
	local success, err = pcall(function()
		TeleportService:TeleportAsync(placeId, {player}, teleportOptions)
	end)
	
	if not success then
		print("[ERRO] Falha no teleporte nativo, tentando método de emergência: " .. tostring(err))
		-- Método alternativo caso o principal falhe
		pcall(function()
			TeleportService:Teleport(placeId, player)
		end)
	end
end

print("Script carregado! Monitoramento de frutas iniciado.")

task.spawn(function()
	while true do
		print("[SCANNER] Procurando frutas míticas no servidor...")
		local fruit = findMythicalFruit()
		
		if fruit then
			local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
			if part then
				print("[AÇÃO] Fruta mítica encontrada! Voando até ela...")
				moveTo(part.Position)
				task.wait(1)
				
				-- Coleta física (Simula o clique/toque na fruta)
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
			print("[SCANNER] Nenhuma fruta mítica aqui. Trocando de servidor em 3 segundos...")
			task.wait(3)
			serverHop()
			task.wait(10) -- Aguarda a tela de carregamento do Roblox
		end
		task.wait(2)
	end
end)
