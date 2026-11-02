local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local placeId = game.PlaceId
local jobId = game.JobId
local player = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()

local function createESP(fruit)
	local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
	if not part then return end

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

	task.spawn(function()
		while part and part.Parent do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - part.Position).Magnitude
				text.Text = string.format("%s\n[ %d m ]", fruit.Name, math.floor(dist))
			end
			task.wait(0.1)
		end
		if billboard then billboard:Destroy() end
	end)
end

local foundFruit = false
for _, v in ipairs(Workspace:GetDescendants()) do
	if v:IsA("Model") and string.find(v.Name, "Fruit") then
		createESP(v)
		foundFruit = true
	end
end

if foundFruit then
	print("Fruta encontrada no mapa! ESP ativada.")
	return
end

local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request

if not requestFunc then
	print("Erro: O executor não suporta requests HTTP.")
	return
end

print("Nenhuma fruta encontrada no mapa. A procurar um novo servidor...")

local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"

local success, response = pcall(function()
	return requestFunc({
		Url = url,
		Method = "GET"
	})
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
					print("Servidor encontrado! A iniciar teleporte para: " .. tostring(server.id))
					TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
					return
				end
			end
		end
	end
end

print("Nenhum servidor com vagas encontrado de momento. Tente novamente.")
