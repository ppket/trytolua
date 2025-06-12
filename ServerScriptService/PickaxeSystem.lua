-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

-- Создаем удаленное событие для добычи
local MiningEvent = Instance.new("RemoteEvent")
MiningEvent.Name = "MiningEvent"
MiningEvent.Parent = ReplicatedStorage

-- Настройки кирок
local PICKAXE_STATS = {
	["Rusty Pickaxe"] = {
		MiningPower = 0.5,  -- Слабая
		MiningSpeed = 0.5,  -- Медленная
		Range = 8
	},
	["Pickaxe"] = {
		MiningPower = 1.0,  -- Нормальная
		MiningSpeed = 1.0,  -- Нормальная
		Range = 10
	},
	["Golden Pickaxe"] = {
		MiningPower = 0.7,  -- Слабая
		MiningSpeed = 1.5,  -- Быстрая
		Range = 12
	},
	["Steel Pickaxe"] = {
		MiningPower = 1.5,  -- Сильная
		MiningSpeed = 0.8,  -- Медленная
		Range = 15
	},
	["Uranium Pickaxe"] = {
		MiningPower = 2,  -- Сильная
		MiningSpeed = 1,  -- Медленная
		Range = 14
	}
}

-- Здоровье руды
local ORE_HEALTH = {
	Iron = 15,
	Copper = 10,
	Uranium = 55,
	DIAMOND = 1
}

-- Таблица для хранения кирок игроков
local playerTools = {}

-- Функция выдачи кирки игроку
local function givePickaxe(player, pickaxeName)
	local character = player.Character
	if not character then return end

	-- Удаляем старую кирку
	for name, _ in pairs(PICKAXE_STATS) do
		local oldTool = character:FindFirstChild(name)
		if oldTool then oldTool:Destroy() end
	end

	-- Создаем новую кирку
	local tool = ServerStorage.Pickaxes:FindFirstChild(pickaxeName)
	if tool then
		local newTool = tool:Clone()
		local stats = PICKAXE_STATS[pickaxeName]

		-- Устанавливаем атрибуты
		newTool:SetAttribute("MiningPower", stats.MiningPower)
		newTool:SetAttribute("MiningSpeed", stats.MiningSpeed)
		newTool:SetAttribute("Range", stats.Range)

		newTool.Parent = character
		playerTools[player] = newTool
	end
end

-- Функция спавна ресурсов при разрушении руды
local function spawnResources(oreModel, oreType)
	local position = oreModel:GetPivot().Position
	local resourceTemplate = ReplicatedStorage.Ores2:FindFirstChild(oreType)

	if resourceTemplate then
		local resource = resourceTemplate:Clone()

		-- Случайный размер (1-25 кг)
		local sizeMultiplier = 0.5 + math.random() * 2.5
		local primaryPart = resource.PrimaryPart or resource:FindFirstChildWhichIsA("BasePart")

		-- Применяем размер ко всем частям
		for _, part in ipairs(resource:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Size = part.Size * sizeMultiplier
				part.CustomPhysicalProperties = PhysicalProperties.new(
					sizeMultiplier * 2, -- Плотность
					0.3, -- Трение
					0.5, -- Эластичность
					sizeMultiplier * 0.5, -- Объем
					sizeMultiplier * 0.1 -- Водное сопротивление
				)

				-- Для меди - случайный цвет
				if oreType == "Copper" then
					part.BrickColor = math.random() > 0.5 and BrickColor.new("Dark orange") or BrickColor.new("Shamrock")
				end
			end
		end

		-- Позиция спавна с небольшим смещением
		local spawnPos = position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))
		resource:PivotTo(CFrame.new(spawnPos))

		-- Физика (разлетаются)
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(math.random(-5, 5), 10, math.random(-5, 5))
		bodyVelocity.Parent = primaryPart
		Debris:AddItem(bodyVelocity, 0.5)

		resource.Parent = workspace
		Debris:AddItem(resource, 60) -- Автоудаление через 60 сек
	end
end

-- Обработчик событий добычи
MiningEvent.OnServerEvent:Connect(function(player, oreModel, hitPosition)
	local tool = playerTools[player]
	if not tool or not oreModel or not oreModel.Parent then return end

	-- Проверка расстояния
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	if (humanoidRootPart.Position - hitPosition).Magnitude > tool:GetAttribute("Range") then
		return
	end

	-- Получаем тип руды
	local oreType = oreModel:GetAttribute("OreType")
	if not oreType then return end

	-- Наносим урон
	local currentHealth = oreModel:GetAttribute("Health") or ORE_HEALTH[oreType] or 10
	currentHealth = currentHealth - tool:GetAttribute("MiningPower")
	oreModel:SetAttribute("Health", currentHealth)

	-- Если здоровье закончилось
	if currentHealth <= 0 then
		spawnResources(oreModel, oreType)
		oreModel:Destroy()
		return true
	end

	return false
end)

-- Выдача кирок при входе
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Rusty Pickaxe уже в StarterPack, просто обновляем атрибуты
		local rustyPick = character:WaitForChild("Rusty Pickaxe")
		if rustyPick then
			local stats = PICKAXE_STATS["Rusty Pickaxe"]
			rustyPick:SetAttribute("MiningPower", stats.MiningPower)
			rustyPick:SetAttribute("MiningSpeed", stats.MiningSpeed)
			rustyPick:SetAttribute("Range", stats.Range)
			playerTools[player] = rustyPick
		end
	end)
end)