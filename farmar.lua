print("████ FRUIT SNIPER INICIADO (VERSÃO LITE) █████")

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
				print("Fruta mítica detetada: " .. instance.Name)
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
	local tweenTime = distance / 250 -- Velocidade segura
	
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
	local url = "https://games.roproxy.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
	local success, res = pcall(function() return game:HttpGet(url) end)
	
	if success and res then
		local data = HttpService:JSONDecode(res)
		if data and data.data then
			for _, server in ipairs(data.data) do
				if server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 12) then
					print("A teleportar para um novo servidor...")
					TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
					return
				end
			end
		end
	end
	print("Nenhum servidor novo encontrado. A tentar novamente em breve...")
end

print("Script carregado! À procura de frutas...")

while task.wait(3) do
	local fruit = findMythicalFruit()
	if fruit then
		local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
		if part then
			print("A voar até à fruta...")
			moveTo(part.Position)
			task.wait(2)
		end
	else
		print("Nenhuma fruta mítica no mapa. A iniciar Server Hop...")
		serverHop()
		task.wait(10) -- Espera o teleporte acontecer
	end
end
