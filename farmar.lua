local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local placeId = game.PlaceId
local jobId = game.JobId

-- Usa a função interna do Delta para não ser bloqueado pelo Roblox
local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request

if not requestFunc then
	print("Erro: O executor não suporta requests HTTP.")
	return
end

print("A procurar um novo servidor...")

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
					TeleportService:TeleportToPlaceInstance(placeId, server.id, Players.LocalPlayer)
					return
				end
			end
		end
	end
end

print("Nenhum servidor com vagas encontrado de momento. Tente novamente.")
