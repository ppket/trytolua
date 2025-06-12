-- @ScriptType: Script
-- ServerScriptService: UraniumDamage.lua
local Players = game:GetService("Players")
local DAMAGE_PER_INTERVAL = 5  -- Урон каждые 0.5 секунды
local DAMAGE_RADIUS = 7.5      -- Радиус поражения (половина размера hitbox)

local function damagePlayers()
	while true do
		task.wait(0.5) -- Проверка каждые 0.5 секунды

		-- Ищем все урановые руды в игре
		for _, ore in ipairs(workspace.Ores:GetChildren()) do
			local hitbox = ore:FindFirstChild("UraniumHitbox")
			if hitbox then
				local hitboxPosition = hitbox.Position

				-- Проверяем всех игроков
				for _, player in ipairs(Players:GetPlayers()) do
					local character = player.Character
					if character then
						local humanoid = character:FindFirstChild("Humanoid")
						local rootPart = character:FindFirstChild("HumanoidRootPart")

						if humanoid and humanoid.Health > 0 and rootPart then
							-- Рассчитываем расстояние до руды
							local distance = (hitboxPosition - rootPart.Position).Magnitude

							-- Если игрок в радиусе поражения
							if distance <= DAMAGE_RADIUS then
								-- Наносим урон
								humanoid:TakeDamage(DAMAGE_PER_INTERVAL)
							end
						end
					end
				end
			end
		end
	end
end

-- Запускаем систему урона
damagePlayers()