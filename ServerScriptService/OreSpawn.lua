-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Настройки
local ORE_SPAWN_AREA = workspace.OreSpawnArea
local MAX_ORES = 15
local SPAWN_INTERVAL = 1
local ORE_TYPES = {
	["Iron"] = {weight = 25, model = "IrOre"},
	["Copper"] = {weight = 70, model = "CoOre"},
	["Uranium"] = {weight = 4, model = "UrOre"},
	["DIAMONDS!"] = {weight = 1, model = "DIAORE"},
}
-- Здоровье руды
local ORE_HEALTH = {
	Iron = 15,
	Copper = 10,
	Uranium = 55,
	DIAMOND = 1
}

-- Подготовка папки для руды
local oresFolder = workspace:FindFirstChild("Ores")
if not oresFolder then
	oresFolder = Instance.new("Folder")
	oresFolder.Name = "Ores"
	oresFolder.Parent = workspace
end

-- Загрузка моделей
local oreModels = {}
for oreName, data in pairs(ORE_TYPES) do
	local model = ServerStorage:FindFirstChild(data.model)
	if model then
		oreModels[oreName] = model
	else
		warn("Модель для "..oreName.." не найдена: "..data.model)
	end
end

-- Расчет суммарного веса
local totalWeight = 0
for _, data in pairs(ORE_TYPES) do
	totalWeight += data.weight
end

-- Функция выбора случайного типа руды
local function getRandomOreType()
	local randomValue = math.random(1, totalWeight)
	local cumulative = 0

	for oreName, data in pairs(ORE_TYPES) do
		cumulative += data.weight
		if randomValue <= cumulative then
			return oreName
		end
	end
	return "Iron"
end

-- Основная функция спавна
local function spawnOre()
	if #oresFolder:GetChildren() >= MAX_ORES then
		return
	end

	-- Генерация позиции ВНУТРИ области (только X и Z)
	local minX = ORE_SPAWN_AREA.Position.X - ORE_SPAWN_AREA.Size.X/2
	local maxX = ORE_SPAWN_AREA.Position.X + ORE_SPAWN_AREA.Size.X/2

	local minZ = ORE_SPAWN_AREA.Position.Z - ORE_SPAWN_AREA.Size.Z/2
	local maxZ = ORE_SPAWN_AREA.Position.Z + ORE_SPAWN_AREA.Size.Z/2

	-- Только X и Z - Y будем определять через raycast
	local spawnPosX = math.random(minX, maxX)
	local spawnPosZ = math.random(minZ, maxZ)

	-- ПОДНИМАЕМ точку старта ВЫШЕ области спавна
	local rayStartHeight = ORE_SPAWN_AREA.Position.Y + ORE_SPAWN_AREA.Size.Y + 50
	local rayEndHeight = ORE_SPAWN_AREA.Position.Y - 100

	-- Raycast параметры
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {oresFolder, ORE_SPAWN_AREA} -- Исключаем саму область спавна
	raycastParams.CollisionGroup = "Default"

	-- Ищем поверхность СНАЧАЛА ВЫШЕ области спавна
	local rayOrigin = Vector3.new(spawnPosX, rayStartHeight, spawnPosZ)
	local rayDirection = Vector3.new(0, rayEndHeight - rayStartHeight, 0)
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if not raycastResult or not raycastResult.Instance then
		return
	end

	-- Фиксируем позицию на поверхности
	local surfacePos = raycastResult.Position
	local spawnCFrame = CFrame.new(surfacePos) * CFrame.new(0, 2, 0)

	-- Проверка коллизий
	local regionSize = Vector3.new(3, 3, 3)
	local region = Region3.new(
		spawnCFrame.Position - regionSize/2,
		spawnCFrame.Position + regionSize/2
	)

	-- Игнорируем только руду при проверке
	local partsInRegion = workspace:FindPartsInRegion3WithIgnoreList(region, {oresFolder}, 50)

	for _, part in ipairs(partsInRegion) do
		if part:IsA("BasePart") and part.CanCollide then
			return -- Место занято
		end
	end

	-- Создание руды
	local oreType = getRandomOreType()
	if not oreModels[oreType] then return end

	local newOre = oreModels[oreType]:Clone()
	newOre:PivotTo(spawnCFrame)

	-- Установка атрибутов
	for _, child in ipairs(newOre:GetDescendants()) do
		if child:IsA("BasePart") then
			child:SetAttribute("OreType", oreType)
		end
	end

	newOre.Parent = oresFolder
	
	-- Внутри цикла где создается руда:
	for _, child in ipairs(newOre:GetDescendants()) do
		if child:IsA("BasePart") then
			child:SetAttribute("OreType", oreType)

			-- Только для урана добавляем hitbox
			if oreType == "Uranium" then
				-- Создаем невидимую зону поражения
				local hitbox = Instance.new("Part")
				hitbox.Name = "UraniumHitbox"
				hitbox.Size = Vector3.new(15, 15, 15) -- Размер зоны поражения
				hitbox.Transparency = 1               -- Полностью невидимый
				hitbox.CanCollide = false
				hitbox.Anchored = true
				hitbox.Parent = newOre

				-- Позиционируем в центре руды
				hitbox.CFrame = child.CFrame
				
				local hitboxSize = Vector3.new(15, 15, 15) -- В скрипте спавна

				-- Параметры урона:
				local DAMAGE_PER_INTERVAL = 5  -- Урон за проверку
				local DAMAGE_RADIUS = 7.5      -- Радиус действия
				task.wait(0.5)                 -- Интервал проверки (0.5 сек)
			end
		end
	end
end

-- Запуск спавнера с интервалом
while true do
	local success, err = pcall(spawnOre)
	if not success then
		warn("Ошибка спавна руды: "..err)
	end
	task.wait(SPAWN_INTERVAL)
end