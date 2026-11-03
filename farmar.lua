local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
repeat task.wait() until game:IsLoaded()

local function criarESP(fruta)
	-- Identifica a parte física da fruta
	local part = fruta:FindFirstChild("Handle") or fruta.PrimaryPart or fruta:FindFirstChildWhichIsA("BasePart")
	if not part then return end

	-- Evita duplicar a ESP
	if part:FindFirstChild("FruitESP") then return end

	-- Cria o texto flutuante preso diretamente à fruta
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

	-- Loop independente para atualizar a distância a cada meio segundo
	task.spawn(function()
		while part and part.Parent and part.Parent.Parent ~= player.Character do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - part.Position).Magnitude
				text.Text = string.format("%s\n[ %d m ]", fruta.Name, math.floor(dist))
			end
			task.wait(0.5) -- Pausa maior para não travar o executor Delta
		end
		if billboard then billboard:Destroy() end
	end)
end

local function verificarFruta(obj)
	-- Filtra objetos irrelevantes imediatamente
	if not (obj:IsA("Model") or obj:IsA("Tool")) then return end
	if not string.find(string.lower(obj.Name), "fruit") then return end
	
	-- Ignora o NPC Vendedor de Frutas
	if obj:FindFirstChildOfClass("Humanoid") or string.find(string.lower(obj.Name), "dealer") then return end
	
	criarESP(obj)
end

-- 1. Verifica todas as partes do mapa assim que inicia
for _, obj in ipairs(Workspace:GetDescendants()) do
	verificarFruta(obj)
end

-- 2. Monitoriza ativamente caso nasça uma fruta nova
Workspace.DescendantAdded:Connect(function(obj)
	task.wait(1) -- Dá tempo para o servidor renderizar a fruta física
	if obj and obj.Parent then
		verificarFruta(obj)
	end
end)

print("Sistema de ESP de Frutas ativado com sucesso!")
