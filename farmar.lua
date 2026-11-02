print("████ FRUIT SNIPER (VERSÃO FINAL DETONADORA) █████")

-- Cancela qualquer instância fantasma se o executor suportar
if _G.FruitSniperLoop then
    _G.FruitSniperLoop = false
    print("[SISTEMA] Instância antiga desativada com sucesso.")
    task.wait(1)
end

_G.FruitSniperLoop = true

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
				print("[SUCESSO INTERNO] Fruta mítica localizada: " .. instance.Name)
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
	print("[BAÚ] Movendo item coletado para o inventário...")
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local storeRemote = remotes and remotes:FindFirstChild("CommF_")
	
	if storeRemote then
		local tool = player.Character:FindFirstChildWhichIsA("Tool")
		if tool then
			storeRemote:InvokeServer("StoreFruit", tool.Name)
			print("[BAÚ] Armazenado.")
		else
			local backpackFruit = player.Backpack:FindFirstChildWhichIsA("Tool")
			if backpackFruit and string.find(backpackFruit.Name, "Fruit") then
				backpackFruit.Parent = player.Character
				task.wait(0.5)
				storeRemote:InvokeServer("StoreFruit", backpackFruit.Name)
				print("[BAÚ] Armazenado da Mochila.")
			end
		end
	end
end

-- Mecanismo Forçado Nativo (À prova de erros de API externa)
local function forceServerHop()
	print("[TELEPORTE] Forçando inicialização do TeleportService...")
	
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ServerBindingMode = Enum.ServerBindingMode.PublicServers
	
	-- Método Principal Assíncrono Roblox
	local success, _ = pcall(function()
		TeleportService:TeleportAsync(placeId, {player}, teleportOptions)
	end)
	
	-- Método de Emergência Se o primário falhar ou sofrer throttling
	if not success then
		print("[TELEPORTE] Acionando canal secundário direto...")
		pcall(function()
			TeleportService:Teleport(placeId, player)
		end)
	end
end

print("[START] Novo monitor ativo e desvinculado de APIs externas.")

task.spawn(function()
	while _G.FruitSniperLoop do
		local fruit = findMythicalFruit()
		
		if fruit then
			local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
			if part then
				print("[ALERTA] Rota traçada até a fruta!")
				moveTo(part.Position)
				task.wait(1)
				
				if firetouchinterest then
					firetouchinterest(player.Character.HumanoidRootPart, part, 0)
					task.wait(0.3)
					firetouchinterest(player.Character.HumanoidRootPart, part, 1)
				end
				
				task.wait(1)
				storeFruit()
				task.wait(2)
			end
		else
			print("[SISTEMA-V4] Servidor limpo. Realizando Server Hop nativo direto...")
			forceServerHop()
			task.wait(8) -- Janela de segurança para congelamento da engine antes de deslogar
		end
		task.wait(3)
	end
end)
