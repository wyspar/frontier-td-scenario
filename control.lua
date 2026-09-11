local buildingModule = require('scripts.building')
local mapModule = require('scripts.map')
local TICKS_PER_SECOND = 60
local main_surface_name = "frontier"

--find an empty slot and make sure its not the public one
local function findEmptySlotDefinition()
	for _, definition in pairs(mapModule.slotDefinitions) do
		local slot = storage.mapSlots[definition.id]

		if not slot.isOccupied and slot.id ~= 1 then
			return definition
		end
	end
	return nil
end

local function createDefaultPlayerGui(player)
	if not player and not player.valid then
		return
	end

	-- delete any wave inprogress guis
	if player.gui.top.menu_bar then
		player.gui.top.menu_bar.destroy()
	end

	local menu_bar = player.gui.top.add {
		type = "flow",
		name = "menu_bar",
		direction = "horizontal"
	}
	local mainButton = menu_bar.add {
		type = "sprite-button",
		name = "open_mainMenu_button",
		sprite = "item/thruster",
		caption = "Frontier",
		tooltip = "Frontier"
	}
	mainButton.style.width = 60;
	mainButton.style.height = 60;
	mainButton.style.padding = 5;
	mainButton.style.font = "default-bold"
	mainButton.style.font_color = {
		r = 1,
		g = 1,
		b = 1
	}

	local teamButton = menu_bar.add {
		type = "sprite-button",
		name = "teamMenu_button",
		sprite = "item/power-armor-mk2",
		caption = "Teams",
		tooltip = "Teams"
	}
	teamButton.style.width = 60;
	teamButton.style.height = 60;
	teamButton.style.padding = 5;
	teamButton.style.font = "default-bold"
	teamButton.style.font_color = {
		r = 1,
		g = 1,
		b = 1
	}

	local playButton = menu_bar.add {
		type = "sprite-button",
		name = "play_button",
		sprite = "item/rocket-part",
		caption = "Play",
		tooltip = "Play"
	}
	playButton.style.width = 60;
	playButton.style.height = 60;
	playButton.style.padding = 5;
	playButton.style.font = "default-bold"
	playButton.style.font_color = {
		r = 1,
		g = 1,
		b = 1
	}
end

local function teleportPlayerToTheirSpawn(surface, force, slotDef, player)
  local spawnPos = mapModule.findSlotPlayerSpawnPoint(surface, force)
	if not spawnPos then
		spawnPos = {
			x = slotDef.x + slotDef.width / 2,
			y = slotDef.y + slotDef.height / 2
		}
	end
	local findBestPosition = surface.find_non_colliding_position("character", spawnPos, 20, 0.5)
	if findBestPosition then
		player.teleport(findBestPosition, surface)
	else
		player.teleport(spawnPos, surface)
	end
end

local function createIsGameStartedGui(player, slot, getMap)
	if not player and not player.valid then
		return
	end

	local menu_bar = player.gui.top.menu_bar
	if menu_bar then

		-- delete some of the default gui like play button
		if menu_bar.play_button ~= nil then
			menu_bar.play_button.destroy()
		end

		if player.gui.screen.difficulty_selection_gui then
			player.gui.screen.difficulty_selection_gui.destroy()
		end

		if player.gui.screen.map_selection_gui then
			player.gui.screen.map_selection_gui.destroy()
		end

		local waveTimerButton = menu_bar.add {
			type = "sprite-button",
			name = "open_waveTimer_button",
			caption = "Timer",
			tooltip = "Timer"
		}
		waveTimerButton.style.width = 60;
		waveTimerButton.style.height = 60;
		waveTimerButton.style.padding = 5;
		waveTimerButton.style.font = "default-bold"
		waveTimerButton.style.font_color = {
			r = 1,
			g = 1,
			b = 1
		}

		local waveRoundButton = menu_bar.add {
			type = "sprite-button",
			name = "waveRound_button",
			sprite = "entity/small-biter",
			caption = "Wave: 1",
			tooltip = "Wave: 1"
		}
		waveRoundButton.style.width = 60;
		waveRoundButton.style.height = 60;
		waveRoundButton.style.padding = 5;
		waveRoundButton.style.font = "default-bold"
		waveRoundButton.style.font_color = {
			r = 1,
			g = 1,
			b = 1
		}

		local difficultyLabel = mapModule.difficulties[slot.difficulty].label
		local mapDifficultyButton = menu_bar.add {
			type = "sprite-button",
			name = "mapDifficulty_button",
			caption = difficultyLabel,
			tooltip = difficultyLabel
		}
		mapDifficultyButton.style.width = 60;
		mapDifficultyButton.style.height = 60;
		mapDifficultyButton.style.padding = 5;
		mapDifficultyButton.style.font = "default-bold"
		mapDifficultyButton.style.font_color = {
			r = 1,
			g = 1,
			b = 1
		}

		local mapLabelButton = menu_bar.add {
			type = "sprite-button",
			name = "mapLabel_button",
			sprite = getMap.mapIcon,
			caption = getMap.mapLabel,
			tooltip = getMap.mapLabel
		}
		mapLabelButton.style.width = 60;
		mapLabelButton.style.height = 60;
		mapLabelButton.style.padding = 5;
		mapLabelButton.style.font = "default-bold"
		mapLabelButton.style.font_color = {
			r = 1,
			g = 1,
			b = 1
		}
	end
end

--assign the player to a private slot
local function assignPlayerToEmptySlot(player, slot)
	if not player then
		return
	end
	if not player.valid then
		return
	end
  if slot.slotOwnerIndex ~= nil or slot.id == 1 then
    return
  end

	slot.isOccupied = true
	slot.slotOwnerIndex = player.index

	local forceName = slot.forceName
	local force = game.forces[forceName]
	if not force then
		force = game.create_force(forceName)
	end
	player.force = force

	local slotDef = mapModule.getSlotDefinitionById(slot.id)
	if not slotDef then
		return
	end

	local surface = game.surfaces[main_surface_name]

  teleportPlayerToTheirSpawn(surface, force, slotDef, player)
end

local function set_biter_waypoint(group, path_data, surface, slotDef)
	local waypoint = path_data.waypoint
	local target = path_data.path[waypoint]

	if not target or not surface then
		-- Path is finished
		return false
	end

  target = mapModule.getRelativeSlotPosition(
    slotDef,
    target.x,
    target.y
  )

	local newDestination = surface.find_non_colliding_position("big-biter", target, 100, .1)

	if not newDestination then
    newDestination = target
	end

	-- for _, biter in pairs(group.members) do
	--     if biter.valid then
	--         biter.commandable.set_command{
	--             type = defines.command.go_to_location,
	--             destination = newDestination,
	--             distraction = defines.distraction.none
	--         }
	--     end
	-- end

	group.set_command {
		type = defines.command.go_to_location,
		destination = newDestination,
		radius = 1,
		distraction = defines.distraction.none
	}

	return true
end

local function send_biter_path(surface, spawn, path, count, biter_name, slot)
  local slotDef = mapModule.getSlotDefinitionById(slot.id)
  if not slotDef then
    return
  end
  spawn = mapModule.getRelativeSlotPosition(
    slotDef,
    spawn.x-5,
    spawn.y
  )

	local group = surface.create_unit_group {
		position = spawn,
		force = game.forces.enemy
	}

	for i = 1, count do
		local position = surface.find_non_colliding_position(biter_name, spawn, 1, 1)

		if position then
			local unit = surface.create_entity {
				name = biter_name,
				position = position,
				force = game.forces.enemy
			}

			group.add_member(unit)
		end
	end

	-- group.set_command{
	--     type = defines.command.go_to_location,
	--     destination = path[1],
	--     distraction = defines.distraction.none
	-- }

	-- Store the path information using the group's unique ID.
	storage.biter_paths = storage.biter_paths or {}

	storage.biter_paths[group.unique_id] = {
		group = group,
		path = path,
		waypoint = 1,
		targetForceName = slot.forceName
	}

	-- Send them to the first waypoint.
	set_biter_waypoint(group, storage.biter_paths[group.unique_id], surface, slotDef)

	return group
end

local function fullClearPlayerInventory(player)
  local inventory = player.get_main_inventory()
  if inventory then
    inventory.clear()
  end
  player.get_inventory(defines.inventory.character_guns).clear()
  player.get_inventory(defines.inventory.character_ammo).clear()
  player.get_inventory(defines.inventory.character_armor).clear()
  player.get_inventory(defines.inventory.character_trash).clear()
end

local function checkForWinnerSoloSlot(slot)
  if not slot then
    return
  end

  if slot.enemyForce or slot.isEndless or slot.slotOwnerIndex == nil or slot.isDead or not slot.isGameStarted then
    return
  end

  local surface = game.surfaces[main_surface_name]
	local enemy_force = game.forces["enemy"]

	if not enemy_force then
		return
	end

	local enemies = surface.find_entities_filtered({
		force = enemy_force,
		type = "unit"
	})

	if #enemies == 0 then
		-- No enemies alive: slot has won
		
    local playerThatWon = nil
    if slot.id == 1 then
			playerThatWon = "Public Slot "..tostring(slot.id)
		else
			playerThatWon = game.get_player(tonumber(slot.slotOwnerIndex))
			if not playerThatWon then
				playerThatWon = "???"
      else
			  playerThatWon = playerThatWon.name
			end
		end

    local findOtherForce = nil
		local difficulty = mapModule.difficulties[tonumber(slot.difficulty)]
		if not difficulty then
			difficulty = "nil"
		else
			difficulty = difficulty.label
		end
    
    local force = game.forces[slot.forceName]
    local mapData = mapModule.getMapByName(slot.mapName)
		if not mapData then
			for _, player in pairs(force.connected_players) do
				player.print("No mapData found in checkForWinnerSoloSlot()")
			end
			return
		end

    local publicSlotDef = mapModule.getSlotDefinitionById(1)
    if not publicSlotDef then
      return
    end

		game.print(playerThatWon .. "'s team is Victorious! Map: " .. mapData.mapLabel .. " on " .. difficulty)

    mapModule.resetMapSlot(surface, slot.id, true)
    local publicForce = game.forces["mapSlotDef_1"]
    for _, player in pairs(force.players) do
      if player.valid then
        fullClearPlayerInventory(player)
        player.force = publicForce
        createDefaultPlayerGui(player)
        teleportPlayerToTheirSpawn(surface, publicForce, publicSlotDef, player)
      end
    end
    force.reset()
  else
    table.insert(storage.delayedTickActions, {
			tick = game.tick + 600,
			callback = function()
        checkForWinnerSoloSlot(slot)
			end
		})
	end
end

local function updateWaveRoundGui(slot, waveCount)
	for _, player in pairs(game.players) do
		if player.valid and player.force.name == tostring(slot.forceName) then
			local menuBar = player.gui.top.menu_bar
			if menuBar and menuBar.valid then
				local waveButton = menuBar.waveRound_button
				if waveButton and waveButton.valid then
					waveButton.caption = tostring(waveCount)
					waveButton.tooltip = "Wave: " .. tostring(waveCount)
				end
			end
		end
	end
end

local function startWave(slot)
	slot.currentWave = slot.currentWave + 1
	updateWaveRoundGui(slot, slot.currentWave)
	slot.waveStartTick = game.tick
	slot.waveTimer = 0

	local wave = slot.mapWaveData[slot.currentWave]

	-- No more predefined waves
  if slot.isDead == true then
		slot.waveGroups = nil
		return
	end

	if not wave then
    table.insert(storage.delayedTickActions, {
			tick = game.tick + 600,
			callback = function()
        checkForWinnerSoloSlot(slot)
			end
		})

		slot.waveGroups = nil
    return
  end

	slot.waveGroups = {}

	for _, group in ipairs(wave.groups) do
		local intervalTicks = group.interval * TICKS_PER_SECOND

		local startDelayTicks = group.startDelay * TICKS_PER_SECOND

		slot.waveGroups[#slot.waveGroups + 1] = {
			name = group.name,
			remaining = group.count,

			intervalTicks = intervalTicks,
			startDelayTicks = startDelayTicks,

			nextSpawnTick = game.tick + startDelayTicks
		}
	end
end

local function processWave(slot)

		local wave = slot.mapWaveData[slot.currentWave]
		if not wave then
			return
		end

		local biterPaths = slot.mapBiterPaths
		if not biterPaths then
			return
		end

		local surface = game.surfaces[main_surface_name]

		-- UPDATE TIMER
		local waveDurationTicks = wave.waveDuration * TICKS_PER_SECOND
		slot.waveTimer = math.max(0, waveDurationTicks - (game.tick - slot.waveStartTick))
		-- PROCESS SPAWN GROUPS
		if slot.waveGroups then
			for i = #slot.waveGroups, 1, -1 do
				local group = slot.waveGroups[i]
				if group.remaining > 0 and game.tick >= group.nextSpawnTick then
					-- INTERVAL = 0
					-- Spawn entire group simultaneously
					if group.intervalTicks == 0 then
						for _ = 1, group.remaining do
              send_biter_path(surface, biterPaths[1], biterPaths, group.remaining, group.name,
                  slot)
						end
						group.remaining = 0
						-- NORMAL INTERVAL
					else
						send_biter_path(surface, biterPaths[1], biterPaths, 1, group.name, slot)

						group.remaining = group.remaining - 1

						group.nextSpawnTick = group.nextSpawnTick + group.intervalTicks
					end
				end

				if group.remaining <= 0 then
					table.remove(slot.waveGroups, i)
				end
			end
		end

	if slot.waveTimer <= 0 then
		startWave(slot)
	end
end

local function updateWaveTimerGui(slot)
	local seconds = math.floor(slot.waveTimer / 60)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	-- local caption = string.format(
	--     "%02d:%02d",
	--     minutes,
	--     remainingSeconds
	-- )
	for _, player in pairs(game.players) do
		if player.valid and player.force.name == tostring(slot.forceName) then
			local menuBar = player.gui.top.menu_bar

			if menuBar and menuBar.valid then
				local timerButton = menuBar.open_waveTimer_button
				if timerButton and timerButton.valid then
					timerButton.caption = remainingSeconds
					timerButton.tooltip = "Time Left: " .. remainingSeconds
				end
			end
		end
	end
end

local function startRoundForForce(slot, force)
	if not force then
		return
	end
	if not slot then
		return
	end

	local slotMapDef = mapModule.slotDefinitions[slot.id]
	if not slotMapDef then
		for _, player in pairs(force.connected_players) do
			player.print('You have a map slot, but not map slot def in control.lua')
		end
		return
	end
	slotMapDef.mapName = slot.mapName

	local getMap = mapModule.getMapByName(slotMapDef.mapName)
	if not getMap then
		for _, player in pairs(force.connected_players) do
			player.print("Error finding getMap " .. tostring(slotMapDef.mapName) .. " " .. tostring(slot.difficulty) ..
													" in control.lua ")
		end
		return
	end

	local biterPaths = mapModule.getMapBiterPaths(slotMapDef.mapName, slot.difficulty)
	if not biterPaths then
		for _, player in pairs(force.connected_players) do
			player.print("Error finding biterPaths from getMapBiterPaths() in control.lua " ..
					tostring(slotMapDef.mapName) .. " " .. tostring(slot.difficulty))
		end
		return
	end

	local waveData = mapModule.getMapWaveData(slotMapDef.mapName, slot.difficulty)
	if not waveData then
		for _, player in pairs(force.connected_players) do
			player.print(
						"Error finding waveData from getMapWaveData() in control.lua " .. tostring(slotMapDef.mapName) .. " " ..
								tostring(slot.difficulty))
		end
		return
	end

	local surface = game.surfaces[main_surface_name]
	if not surface then
		for _, player in pairs(force.connected_players) do
			player.print("No surface?")
		end
		return
	end

	slot.isGameStarted = true
	for _, player in pairs(force.connected_players) do
		mapModule.createStartingPlayer(player, slot)

		-- delete some of the default gui like play button
		if player.gui.top.menu_bar ~= nil and player.gui.top.menu_bar.play_button ~= nil then
			player.gui.top.menu_bar.play_button.destroy()
		end

		if player.gui.screen.difficulty_selection_gui then
			player.gui.screen.difficulty_selection_gui.destroy()
		end

		if player.gui.screen.map_selection_gui then
			player.gui.screen.map_selection_gui.destroy()
		end

		-- give player timer gui
		if player.gui.top.menu_bar ~= nil then
			createIsGameStartedGui(player, slot, getMap)
		end

		player.print("Game started!")
	end

	slotMapDef.biterPaths = biterPaths
	mapModule.generateSlotLand(surface, slotMapDef, true);

  if not slot.mapTagId then
    local spawnPos = mapModule.findSlotPlayerSpawnPoint(surface, force)
    if not spawnPos then
      spawnPos = {
        x = slotMapDef.x + slotMapDef.width / 2,
        y = slotMapDef.y + slotMapDef.height / 2
      }
    end
		local mapTag = force.add_chart_tag(surface, {
			position = spawnPos,
			text = "YOUR SILO",
			icon = {
				type = "item",
				name = "rocket-silo"
			}
		})
		slot.mapTagId = mapTag.tag_number
	end 

	slot.currentWave = 0
	slot.waveTimer = 0
	slot.waveStartTick = game.tick
	slot.waveGroups = nil
	slot.mapWaveData = waveData
	slot.mapBiterPaths = biterPaths
	slot.totalWaves = #waveData
  force.manual_mining_speed_modifier = 3

	-- Immediately start Wave 1
	startWave(slot)
end

local function createMapSelectionGui(event, player)
	local frame = nil
	local scroll = nil
	local table = nil

	-- close the difficulty selection gui if open, since we need to let the player back here
	if player.gui.screen.difficulty_selection_gui then
		player.gui.screen.difficulty_selection_gui.destroy()
	end

	if player.gui.screen.map_selection_gui then
		player.gui.screen.map_selection_gui.destroy()
		return
	end

	if not player.gui.screen.map_selection_gui then
		frame = player.gui.screen.add {
			type = "frame",
			name = "map_selection_gui",
			direction = "vertical"
		}

		local titlebar = frame.add {
			type = "flow",
			name = "titlebar",
			direction = "horizontal"
		}

		titlebar.add {
			type = "label",
			caption = "Choose a map",
			style = "frame_title",
			ignored_by_interaction = true
		}

		local dragger = titlebar.add {
			type = "empty-widget",
			style = "draggable_space_header",
		}

		dragger.style.horizontally_stretchable = true
		dragger.style.height = 24
		dragger.style.right_margin = 4
		dragger.drag_target = frame

		titlebar.add {
			type = "sprite-button",
			name = "close",
			sprite = "utility/close",
			style = "frame_action_button"
		}

		frame.force_auto_center()

		scroll = frame.add {
			type = "scroll-pane",
			name = "force_list",
			direction = "vertical"
		}

		scroll.style.maximal_height = 600
		scroll.style.minimal_width = 300

		table = scroll.add {
			type = "table",
			column_count = 2
		}

		for id, mapData in pairs(mapModule.allMaps) do
			local mapLabel = mapData.label
			local mapName = mapData.name
			local mapLabelLabel = table.add {
				type = "label",
				caption = mapLabel
			}
			mapLabelLabel.style.minimal_width = 200

			local mapIconButton = table.add {
				type = "sprite-button",
				name = "mapIcon_select_button_" .. tostring(mapName),
				sprite = mapData.icon,
				caption = tostring(mapLabel),
				tooltip = tostring(mapLabel)
			}
			mapIconButton.style.width = 120;
			mapIconButton.style.height = 50;
			mapIconButton.style.padding = 5;
			mapIconButton.style.font = "default-bold"
			mapIconButton.style.font_color = {
				r = 1,
				g = 1,
				b = 1
			}
		end
	end
end

local function createDifficultyGui(event, player, availableDifficulties)
	local frame = nil
	local scroll = nil
	local table = nil
	if not player.gui.screen.difficulty_selection_gui then
		frame = player.gui.screen.add {
			type = "frame",
			name = "difficulty_selection_gui",
			direction = "vertical"
		}
		local titlebar = frame.add {
			type = "flow",
			name = "titlebar",
			direction = "horizontal"
		}

		titlebar.add {
			type = "label",
			caption = "Choose a difficulty",
			style = "frame_title"
		}

		local dragger = titlebar.add {
			type = "empty-widget",
			style = "draggable_space_header",
		}

		dragger.style.horizontally_stretchable = true
		dragger.style.height = 24
		dragger.style.right_margin = 4
		dragger.drag_target = frame

		titlebar.add {
			type = "sprite-button",
			name = "back_to_map_gui_button",
			sprite = "utility/close",
			style = "frame_action_button"
		}

		frame.force_auto_center()

		scroll = frame.add {
			type = "scroll-pane",
			name = "force_list",
			direction = "vertical"
		}

		scroll.style.maximal_height = 600
		scroll.style.minimal_width = 300

		table = scroll.add {
			type = "table",
			column_count = 2
		}

		for id, diffData in pairs(availableDifficulties) do
			local difficultyLabel = diffData.label
			local difficultyLabelLabel = table.add {
				type = "label",
				caption = difficultyLabel
			}
			difficultyLabelLabel.style.minimal_width = 200

			local voteDiffButton = table.add {
				type = "sprite-button",
				name = "difficulty_select_button_" .. tostring(diffData.id),
				caption = tostring(difficultyLabel),
				tooltip = tostring(difficultyLabel)
			}
			voteDiffButton.style.width = 120;
			voteDiffButton.style.height = 50;
			voteDiffButton.style.padding = 5;
			voteDiffButton.style.font = "default-bold"
			voteDiffButton.style.font_color = {
				r = 1,
				g = 1,
				b = 1
			}
		end
	end
end

local function updateTeamMenuGui(player)
  if not player then
    return
  end

  local frame = player.gui.screen.force_gui
  if not frame then
    return
  end
  local oldScrollPane = frame.force_list
  if oldScrollPane then
    oldScrollPane.destroy()
  end

  local scroll = frame.add {
    type = "scroll-pane",
    name = "force_list",
    direction = "vertical"
  }

  scroll.style.maximal_height = 600
  scroll.style.minimal_width = 500

  for _, slot in pairs(storage.mapSlots) do
    -- Slot container
    local slotFlow = scroll.add {
      type = "flow",
      name = "slot_" .. tostring(slot.id),
      direction = "vertical"
    }

    -- Slot header row
    local row = slotFlow.add {
      type = "flow",
      name = "slot_header_" .. tostring(slot.id),
      direction = "horizontal"
    }

    -- Slot label
    local slotLabelCaption = "Slot " .. tostring(slot.id) .. " Private"
    if slot.id == 1 then
      slotLabelCaption = "Slot " .. tostring(slot.id) .. " Public"
    end
    row.add {
      type = "label",
      caption = slotLabelCaption
    }.style.minimal_width = 200

    -- Join / Challenge buttons
    if slot.forceName ~= player.force.name then
      row.add {
        type = "button",
        name = "join_slot_" .. tostring(slot.id),
        caption = "Join"
      }

      row.add {
        type = "button",
        name = "challenge_slot_" .. tostring(slot.id),
        caption = "Challenge"
      }
    end
      
    -- Slot owner
    if slot.slotOwnerIndex then
      local slotOwnerPlayer = game.get_player(
        tonumber(slot.slotOwnerIndex)
      )

      if slotOwnerPlayer and slotOwnerPlayer.valid then
        row.add {
          type = "label",
          caption = "Owner: "..slotOwnerPlayer.name
        }.style.minimal_width = 200
      end
    end

    -- Connected players in this force
    local playersFlow = slotFlow.add {
      type = "flow",
      name = "players_" .. tostring(slot.id),
      direction = "vertical"
    }
    for _, forcePlayer in pairs(game.connected_players) do
      if forcePlayer.force.name == slot.forceName then
        playersFlow.add {
          type = "label",
          caption = "  " .. forcePlayer.name
        }
      end
    end

    -- Separator between slots
    slotFlow.add {
      type = "line"
    }
  end
end

local function createSnapshotInventory(player, tickOverride)
	if not player then
		return
	end
	local playerIndex = player.index

	local surface = game.surfaces[main_surface_name]
	if not surface then
		return
	end

	local force = player.force
	local spawnPos = mapModule.findSlotPlayerSpawnPoint(surface, force)

	local mainInventory = player.get_inventory(defines.inventory.character_main)
	local gunInventory = player.get_inventory(defines.inventory.character_guns)
	local ammoInventory = player.get_inventory(defines.inventory.character_ammo)
	local armorInventory = player.get_inventory(defines.inventory.character_armor)

	local snapshot = {
		main = game.create_inventory(#mainInventory),
		guns = game.create_inventory(#gunInventory),
		ammo = game.create_inventory(#ammoInventory),
		armor = game.create_inventory(#armorInventory),

		surface = player.surface,
		position = spawnPos
	}

	-- Main inventory
	for i = 1, #mainInventory do
		snapshot.main[i].set_stack(mainInventory[i])
		mainInventory[i].clear()
	end

	-- Guns
	for i = 1, #gunInventory do
		snapshot.guns[i].set_stack(gunInventory[i])
		gunInventory[i].clear()
	end

	-- Ammo
	for i = 1, #ammoInventory do
		snapshot.ammo[i].set_stack(ammoInventory[i])
		ammoInventory[i].clear()
	end

	-- Armor
	for i = 1, #armorInventory do
		snapshot.armor[i].set_stack(armorInventory[i])
		armorInventory[i].clear()
	end

	storage.leftPlayers = storage.leftPlayers or {}
	storage.leftPlayers[playerIndex] = {
		inventory = snapshot,
		surface = player.surface,
		position = spawnPos
	}

	local tickWaitAmount = 18000	
	if tickOverride then
		tickWaitAmount = tickOverride
	end
	storage.leftPlayers[playerIndex].action = {
		tick = game.tick + tickWaitAmount, -- use 18000 for 5 minutes
		playerIndex = playerIndex,

		callback = function()
			local data = storage.leftPlayers[playerIndex]

			-- Player rejoined / action was cancelled
			if not data then
				return
			end

			local snapshot = data.inventory

			if snapshot then
				local safePlacePos = data.surface.find_non_colliding_position(
					"character",
					data.position,
					20,
					1
				)
				local corpse = data.surface.create_entity({
					name = "character-corpse",
					position = safePlacePos,
					inventory_size = #snapshot.main + #snapshot.guns + #snapshot.ammo + #snapshot.armor
				})
				if corpse then
					local corpseInventory =
						corpse.get_inventory(defines.inventory.character_corpse)

					if corpseInventory then
						if snapshot.main and #snapshot.main > 0 and not snapshot.main.is_empty() then
							for i, forcePlayer in ipairs(force.connected_players) do
								if forcePlayer and forcePlayer.valid then
									forcePlayer.print(
										"Player Inventory Here: [gps=" ..
										math.floor(safePlacePos.x) .. "," ..
										math.floor(safePlacePos.y) .. "," ..
										data.surface.name ..
										"]"
									)
								end
							end
						end

						-- Main inventory
						for i = 1, #snapshot.main do
							if snapshot.main[i].valid_for_read then
								corpseInventory.insert(snapshot.main[i])
							end
						end

						-- Guns
						for i = 1, #snapshot.guns do
							if snapshot.guns[i].valid_for_read then
								corpseInventory.insert(snapshot.guns[i])
							end
						end

						-- Ammo
						for i = 1, #snapshot.ammo do
							if snapshot.ammo[i].valid_for_read then
								corpseInventory.insert(snapshot.ammo[i])
							end
						end

						-- Armor
						for i = 1, #snapshot.armor do
							if snapshot.armor[i].valid_for_read then
								corpseInventory.insert(snapshot.armor[i])
							end
						end
					end
				end

				-- Destroy the temporary inventories
				snapshot.main.destroy()
				snapshot.guns.destroy()
				snapshot.ammo.destroy()
				snapshot.armor.destroy()
			end

			storage.leftPlayers[playerIndex] = nil
		end
	}

	table.insert(
		storage.delayedTickActions,
		storage.leftPlayers[playerIndex].action
	)
end

local function giveBackInventoryAndCancelRemovingInventory(player)
	if not player then
		return
	end

	local playerIndex = player.index
	local data = storage.leftPlayers and storage.leftPlayers[playerIndex]

	if not data then
		return
	end

	-- Remove the delayed action
	for i = #storage.delayedTickActions, 1, -1 do
		if storage.delayedTickActions[i] == data.action then
			table.remove(storage.delayedTickActions, i)
			break
		end
	end

	local snapshot = data.inventory

	if snapshot then
		local mainInventory = player.get_inventory(
			defines.inventory.character_main
		)

		local gunInventory = player.get_inventory(
			defines.inventory.character_guns
		)

		local ammoInventory = player.get_inventory(
			defines.inventory.character_ammo
		)

		local armorInventory = player.get_inventory(
			defines.inventory.character_armor
		)

		-- Main inventory
		if mainInventory then
			for i = 1, #snapshot.main do
				if snapshot.main[i].valid_for_read then
					mainInventory.insert(snapshot.main[i])
				end
			end
		end

		-- Guns
		if gunInventory then
			for i = 1, #snapshot.guns do
				if snapshot.guns[i].valid_for_read then
					gunInventory.insert(snapshot.guns[i])
				end
			end
		end

		-- Ammo
		if ammoInventory then
			for i = 1, #snapshot.ammo do
				if snapshot.ammo[i].valid_for_read then
					ammoInventory.insert(snapshot.ammo[i])
				end
			end
		end

		-- Armor
		if armorInventory then
			for i = 1, #snapshot.armor do
				if snapshot.armor[i].valid_for_read then
					armorInventory.insert(snapshot.armor[i])
				end
			end
		end

		snapshot.main.destroy()
		snapshot.guns.destroy()
		snapshot.ammo.destroy()
		snapshot.armor.destroy()
	end

	storage.leftPlayers[playerIndex] = nil
end



script.on_init(function()
	storage.mapSlots = storage.mapSlots or {};
	storage.delayedTickActions = storage.delayedTickActions or {}
	for _, slotInfo in pairs(mapModule.slotDefinitions) do
		storage.mapSlots[slotInfo.id] = {
			id = slotInfo.id,
			isOccupied = false,
			isGameStarted = false,
			isPvp = false,
			enemyForce = nil,
			isDead = false,
			isEndless = false,
			currentWave = 0,
			totalWaves = 0,
			difficulty = 1,
			mapName = nil,
			mapWaveData = nil,
			mapBiterPaths = nil,
			mapVotes = {},
			mapDifficultyVotes = {},
			waveTimer = 0, -- ticks not seconds
			waveStartTick = 0,
			waveGroups = nil,
			slotOwnerIndex = nil,
			forceName = "mapSlotDef_"..tostring(slotInfo.id), --do not reset this
			mapTagId = nil --do not reset this, until the tag needs to be removed
		}
	end
	storage.mapSlots[1].isOccupied = true

	local surface = game.surfaces[main_surface_name]
	if not surface then
		surface = mapModule.create_main_surface()
	end
	if surface then
		surface.always_day = true;
	end
end)

script.on_load(function()
end)

script.on_event(defines.events.on_tick, function(event)
	for _, slot in pairs(storage.mapSlots) do
		if slot.isGameStarted and slot.isDead == false then
			local seconds = math.floor(slot.waveTimer / 60)
			processWave(slot)

			if game.tick % 60 == 0 then
				updateWaveTimerGui(slot)
			end
		end
	end

	if storage.delayedTickActions then
		for i = #storage.delayedTickActions, 1, -1 do
			local action = storage.delayedTickActions[i]

			if event.tick >= action.tick then
				table.remove(storage.delayedTickActions, i)
				action.callback()
			end
		end
	end
end)

script.on_event(defines.events.on_entity_died, function(event)
	local entity = event.entity

	if not entity or not entity.valid then
		return
	end

	local isBoss = string.find(entity.name:lower(), "boss")
	local isSilo = entity.name == "rocket-silo"
	local isRewardEnemy = mapModule.getEnemyRewardData(entity.name:lower())
	if not isSilo and not isBoss and not isRewardEnemy then
		return
	end

	local surface = game.surfaces[main_surface_name]
	if not surface then
		return
	end

	if isBoss then
		local killedByForce = event.force
		if not killedByForce then
			return
		end

		local players = killedByForce.connected_players
		local slot = mapModule.getSlotByForceName(killedByForce.name)
		if not slot then
			for _, player in pairs(players) do
				player.print("No slot found in events.on_entity_died in isBoss")
			end
			return
		end

		-- give all players on the force coins
		local player_count = #players
		local total_coins = nil
		local total_items = nil

		local bossReward = mapModule.getBossRewardData(tostring(entity.name))
		if bossReward == nil then
			total_coins = 100
			total_items = 1
		else
			total_coins = bossReward.coins
			total_items = bossReward.rewardItemAmount
		end

		if player_count > 0 and total_coins and total_items then
			local coins_each = math.floor(total_coins / player_count)
			local coins_remainder = total_coins % player_count

			local items_each = math.floor(total_items / player_count)
			local items_remainder = total_items % player_count

			for _, player in pairs(players) do
				if coins_each > 0 then
					player.insert({
						name = "coin",
						count = coins_each
					})
				end

				if items_each > 0 then
					player.insert({
						name = "boss-reward-item",
						count = items_each
					})
				end

				-- Give remainders to the owner
				if tostring(player.index) == tostring(slot.slotOwnerIndex) then
					if coins_remainder > 0 then
						player.insert({
							name = "coin",
							count = coins_remainder
						})
					end

					if items_remainder > 0 then
						player.insert({
							name = "boss-reward-item",
							count = items_remainder
						})
					end
				end
			end
		end

		return
	end

	if isSilo then
		local force = entity.force
		if not force then
      return
		end

		local slot = mapModule.getSlotByForceName(force.name)
		if not slot then
			for _, player in pairs(force.connected_players) do
				player.print("No slot found in events.on_entity_died in isSilo")
			end
			return
		end

		local mapData = mapModule.getMapByName(slot.mapName)
		if not mapData then
			for _, player in pairs(force.connected_players) do
				player.print("No mapData found in events.on_entity_died in isSilo")
			end
			return
		end

		slot.isDead = true
		local playerThatLost = nil

		if slot.id == 1 then
			playerThatLost = "Public Slot "..tostring(slot.id)
		else
			playerThatLost = "Slot "..tostring(slot.id)
			if slot.slotOwnerIndex then
				playerThatLost = game.get_player(tonumber(slot.slotOwnerIndex))
				if playerThatLost and playerThatLost.valid then
					playerThatLost = playerThatLost.name
				end
			end
		end

		local findOtherForce = nil
		local difficulty = mapModule.difficulties[tonumber(slot.difficulty)]
		if not difficulty then
			difficulty = "nil"
		else
			difficulty = difficulty.label
		end
		if slot.isPvp and slot.enemyForce ~= nil then
			findOtherForce = game.forces[slot.enemyForce]
			if not findOtherForce then
				game.print(playerThatLost .. "'s team has been defeated! Map: " .. mapData.mapLabel .. " on " .. difficulty)
			end
			game.print(playerThatLost .. "'s team has been defeated by " .. findOtherForce.name " Map: " .. mapData.mapLabel .. " on " .. difficulty)
		else
			game.print(playerThatLost .. "'s team has been defeated! Map: " .. mapData.mapLabel .. " on " .. difficulty)
		end

		table.insert(storage.delayedTickActions, {
			tick = game.tick + 600, -- 300 = 5 seconds later
      -- reset map slot, reset players on each force
			callback = function()
        mapModule.resetMapSlot(surface, slot.id, true)
        local publicForce = game.forces["mapSlotDef_1"]
        local publicSlotDef = mapModule.getSlotDefinitionById(1)
        for _, player in pairs(force.players) do
          if player.valid then
            fullClearPlayerInventory(player)
            player.force = publicForce
            createDefaultPlayerGui(player)
            teleportPlayerToTheirSpawn(surface, publicForce, publicSlotDef, player)
          end
        end
        force.reset()

				if findOtherForce ~= nil then
					local otherForceSlot = mapModule.getSlotByForceName(findOtherForce.name)
					if not otherForceSlot then
						for _, player in pairs(findOtherForce.connected_players) do
							if player.valid then
								player.print("No slot found in otherForceSlot in isSilo died")
							end
						end
						return
					end
					mapModule.resetMapSlot(surface, otherForceSlot.id, true)
          local publicSlotDef = mapModule.getSlotDefinitionById(1)

					for _, player in pairs(findOtherForce.players) do
						if player.valid then
							fullClearPlayerInventory(player)
							player.force = publicForce
              createDefaultPlayerGui(player)
              teleportPlayerToTheirSpawn(surface, publicForce, publicSlotDef, player)
						end
					end
					findOtherForce.reset()
				end--end of findOtherForce

			end--callback func
		})
		return
	end--end of isSilo

	if isRewardEnemy then
		local killedByForce = event.force
		if not killedByForce then
			return
		end

		local players = killedByForce.connected_players
		local slot = mapModule.getSlotByForceName(killedByForce.name)
		if not slot then
			for _, player in pairs(players) do
				player.print("No slot found in events.on_entity_died in isRewardEnemy")
			end
			return
		end

		-- give all players on the force coins
		local player_count = #players
		local total_coins = isRewardEnemy.coins
		if not total_coins then
			total_coins = 1
		end

		if player_count > 0 and total_coins then
			local coins_each = math.floor(total_coins / player_count)
			local coins_remainder = total_coins % player_count

			for _, player in pairs(players) do
				if coins_each > 0 then
					player.insert({
						name = "coin",
						count = coins_each
					})
				end

				-- Give remainders to the owner
				if tostring(player.index) == tostring(slot.slotOwnerIndex) then
					if coins_remainder > 0 then
						player.insert({
							name = "coin",
							count = coins_remainder
						})
					end
				end
			end
		end
		return
	end--end of isRewardEnemy
end)

script.on_event(defines.events.on_player_changed_position, function(event)
  -- local player = game.get_player(event.player_index)
  -- local position = player.position
  -- local force = player.force
  -- local forceName = force.name
  -- if get_player_index then
  --     local surface_name = "player_surface_" .. get_player_index
  --     local forceSurface = game.surfaces[surface_name]
  --     if player.surface == mainSurface then
  --         if position.x >= mainToHomeTeleporterPosition.x - 1 and position.x <= mainToHomeTeleporterPosition.x + 1 and
  --         position.y >= mainToHomeTeleporterPosition.y - 1 and position.y <= mainToHomeTeleporterPosition.y + 1 then
  --             map.teleport_to_force_surface(player)
  --         end
  --     elseif player.surface == forceSurface then
  --         if position.x >= homeToMainTeleporterPosition.x - 1 and position.x <= homeToMainTeleporterPosition.x + 1 and
  --         position.y >= homeToMainTeleporterPosition.y - 1 and position.y <= homeToMainTeleporterPosition.y + 1 then
  --             player.teleport(centerOfMap, mainSurface)
  --         end
  --     end
  -- end
end)

-- only called once when player is created
script.on_event(defines.events.on_player_created, function(event)
	local player = game.get_player(event.player_index)
	if not player then
		return
	end

	local slotDef = mapModule.slotDefinitions[1]
	if not slotDef then
		player.print("No slotDef in events.on_player_created")
	end

	local slot = storage.mapSlots[slotDef.id]
	if not slot then
		player.print("No slot in events.on_player_created")
	end

	local forceName = slot.forceName
	local force = game.forces[forceName]
	if not force then
		force = game.create_force(forceName)
	end
	player.force = force

	local surface = game.surfaces[main_surface_name]
	if not surface then
		game.print("No surface in events.on_player_created")
		return
	end

	teleportPlayerToTheirSpawn(surface, force, slotDef, player)

	player.print("Welcome to Frontier!")
end)

script.on_event(defines.events.on_gui_click, function(event)
	local element = event.element

	if not element or not element.valid then
		return
	end

	local player = game.get_player(event.player_index)

	if not player then
		return
	end

	if element.name == "teamMenu_button" then
    local frame = nil
    local scroll = nil

    if player.gui.screen.force_gui then
      player.gui.screen.force_gui.destroy()
      return
    else
      frame = player.gui.screen.add {
        type = "frame",
        name = "force_gui",
        direction = "vertical"
      }

      local titlebar = frame.add {
        type = "flow",
        name = "titlebar",
        direction = "horizontal"
      }

      titlebar.add {
        type = "label",
        caption = "Request to Join a Team",
        style = "frame_title"
      }

      local dragger = titlebar.add {
        type = "empty-widget",
        style = "draggable_space_header",
      }

      dragger.style.horizontally_stretchable = true
      dragger.style.height = 24
      dragger.style.right_margin = 4
      dragger.drag_target = frame

      titlebar.add {
        type = "sprite-button",
        name = "close",
        sprite = "utility/close",
        style = "frame_action_button"
      }

      frame.force_auto_center()
      updateTeamMenuGui(player)
    end
		return
	end--end of teamMenu_button

	if element.name:find("^join_slot_") then
		local slotId = string.match(element.name, "^join_slot_(.+)$")
		if not slotId then
			return
		end

		local slot = storage.mapSlots[tonumber(slotId)]
		if not slot then
			player.print("No slot found in element.name:find(join_slot_)")
			return
		end

    local joiningForce = game.forces[slot.forceName]
    local playersOnJoiningForce = 0
    if joiningForce ~= nil then
      playersOnJoiningForce = #joiningForce.connected_players
    end

    local currentForce = player.force
    local currentSlot = mapModule.getSlotByForceName(currentForce.name)
    local currentForcePlayers = #currentForce.connected_players
    if currentForcePlayers and currentForcePlayers <= 1 and currentSlot then
      currentSlot.slotOwnerIndex = nil
    end

    --check if the slot is not public, and check if empty. if so make player the owner
    if playersOnJoiningForce and playersOnJoiningForce <= 0 and slot.id ~= 1 then
      local slotDef = mapModule.getSlotDefinitionById(slot.id)
      if not slotDef then
        return
      end

			createDefaultPlayerGui(player)
      if slot.isGameStarted then
				local getMap = mapModule.getMapByName(slotDef.mapName)
				if not getMap then
					return
				end
				createIsGameStartedGui(player, slot, getMap)
			end

      createSnapshotInventory(player, 0)
      assignPlayerToEmptySlot(player,slot)
      updateTeamMenuGui(player)
      return
    else--joiningForce has players and is not a public slot
      if slot.id == 1 then -- public slot to join, no owner to ask just join
		    local surface = game.surfaces[main_surface_name]
        local slotDef = mapModule.getSlotDefinitionById(slot.id)
        if not slotDef or not surface then
          return
        end

				createDefaultPlayerGui(player)
        if slot.isGameStarted then
          local getMap = mapModule.getMapByName(slotDef.mapName)
          if not getMap then
            return
          end
          createIsGameStartedGui(player, slot, getMap)
        end

				createSnapshotInventory(player, 0)
        player.force = joiningForce
        teleportPlayerToTheirSpawn(surface, joiningForce, slotDef, player)
        updateTeamMenuGui(player)
      else--ask to join the force
        local findPlayerToJoin = game.get_player(slot.slotOwnerIndex)
        if not findPlayerToJoin then
          player.print("Cannot find that player in element.name:find(join_slot_)")
          return
        end

        local findGui = "bum_joining_" .. tostring(player.index)
        if findPlayerToJoin.gui.screen[findGui] then
          return
        else
          local container = findPlayerToJoin.gui.screen.add {
            type = "flow",
            name = findGui,
            direction = "horizontal"
          }

          container.style.width = findPlayerToJoin.display_resolution.width
          container.style.height = findPlayerToJoin.display_resolution.height
          container.style.vertical_align = "top"
          container.style.horizontal_align = "center"

          local frame = container.add {
            type = "frame",
            name = "joining_frame",
            direction = "vertical"
          }

          local titlebar = frame.add {
            type = "flow",
            name = "titlebar",
            direction = "horizontal"
          }

          titlebar.add {
            type = "label",
            caption = player.name .. " wants to join!",
            style = "frame_title"
          }

          titlebar.add {
            type = "sprite-button",
            name = "close",
            sprite = "utility/close",
            style = "frame_action_button"
          }

          local row = frame.add {
            type = "flow",
            direction = "horizontal"
          }

          local yesButton = row.add {
            type = "button",
            name = "player_request_" .. tostring(player.index),
            caption = "Yes"
          }
          local noButton = row.add {
            type = "button",
            name = "no_button",
            caption = "No"
          }
        end
      end
    end--end of checking playersOnForce
    return
	end

	if element.name:find("^player_request_") then
		local player = game.get_player(event.player_index)
		if not player then
			return
		end
		local requestingPlayerIndex = tonumber(string.match(element.name, "^player_request_(.+)$"))
		if not requestingPlayerIndex then
			return
		end
		local requestingPlayer = game.get_player(requestingPlayerIndex)
		if not requestingPlayer then
			return
		end
		if not requestingPlayer.valid then
			return
		end
		local surface = game.surfaces[main_surface_name]
		local force = game.forces[tostring(player.force.name)]
		if force and surface then
			local slot = mapModule.getSlotByForceName(force.name)
			if not slot then
				return
			end
			local slotDef = mapModule.getSlotDefinitionById(slot.id)
			if not slotDef then
				return
			end

			createDefaultPlayerGui(player)
			if slot.isGameStarted then
				local getMap = mapModule.getMapByName(slotDef.mapName)
				if not getMap then
					return
				end
				createIsGameStartedGui(player, slot, getMap)
			end

			createSnapshotInventory(player, 0)
			requestingPlayer.force = force
			teleportPlayerToTheirSpawn(surface, force, slotDef, requestingPlayer)
      updateTeamMenuGui(player)
		else
			return
		end

		local frame = player.gui.screen["bum_joining_" .. player.index]
		if frame and frame.valid then
			frame.destroy()
			return
		end
	end

	if element.name == "play_button" or element.name == "back_to_map_gui_button" then
		createMapSelectionGui(event, player)
		return
	end

	if element.name:find("^mapIcon_select_button_") then
		local mapName = element.name:match("^mapIcon_select_button_(.+)$")
		local player = game.get_player(event.player_index)
		if not player then
			return
		end

		local forceName = player.force.name
		local slot = mapModule.getSlotByForceName(forceName)
		if not slot then
			return
		end
		slot.mapVotes[player.index] = mapName

		if player.gui.screen.map_selection_gui then
			player.gui.screen.map_selection_gui.destroy()
		end

		local mapData = mapModule.getMapByName(mapName)
		if not mapData then
			return
		end

		local mapBiterWaveData = mapData.mapBiterWaveData
		local availableDifficulties = {}
		for difficultyId, difficulty in pairs(mapModule.difficulties) do
			if mapBiterWaveData[difficultyId] then
				table.insert(availableDifficulties, difficulty)
			end
		end
		createDifficultyGui(event, player, availableDifficulties)

		return
	end

	if element.name:find("^difficulty_select_button_") then
		local difficultyName = element.name:match("^difficulty_select_button_(.+)$")
		local player = game.get_player(event.player_index)
		local forceName = player.force.name
		local force = game.forces[forceName]
		if not force then
			return
		end
		local slot = mapModule.getSlotByForceName(forceName)
		if not slot then
			return
		end
		slot.mapDifficultyVotes[player.index] = difficultyName
		if slot.isGameStarted then
			player.print("Game already started.")
			return
		end

		local isEveryoneVoted = false
		local enemyForce = nil
		local enemySlot = nil

		if slot.isPvp and slot.enemyForce then
			enemyForce = game.forces[slot.enemyForce]
			if not enemyForce then
				return
			end

			-- find enemyslot
			enemySlot = mapModule.getSlotByForceName(enemyForce.name)
			if not enemySlot then
				return
			end

			if (#slot.mapDifficultyVotes + #enemySlot.mapDifficultyVotes) >= (#force.players + #enemyForce.players) then
				isEveryoneVoted = true
			end
		else
			if #slot.mapDifficultyVotes >= #force.players then
				isEveryoneVoted = true
			end
		end

		if player.gui.screen.difficulty_selection_gui then
			local scroll = player.gui.screen.difficulty_selection_gui.force_list
			if scroll then
				local startRoundButton = scroll.add {
					type = "sprite-button",
					name = "force_start_game_button",
					sprite = "utility/danger_icon",
					caption = "Force Start",
					tooltip = "Stops voting and starts the game"
				}
				startRoundButton.style.width = 120;
				startRoundButton.style.height = 50;
				startRoundButton.style.padding = 5;
				startRoundButton.style.font = "default-bold"
				startRoundButton.style.font_color = {
					r = 1,
					g = 1,
					b = 1
				}
			end
		end

		if isEveryoneVoted then
			if player.gui.screen.difficulty_selection_gui then
				player.gui.screen.difficulty_selection_gui.destroy()
			end

			-- need to choose the most map and difficulty votes
			local winningMap, winningDifficulty = mapModule.getWinningMapNameAndMapDifficulty(slot, enemySlot)

			if not winningMap or not winningDifficulty then
				player.print('No winningMap or winningDifficulty found')
				return
			end

			slot.difficulty = tonumber(winningDifficulty)
			slot.mapName = winningMap
			startRoundForForce(slot, force)
			if enemySlot and enemyForce then
				enemySlot.difficulty = tonumber(winningDifficulty)
				enemySlot.mapName = winningMap
				startRoundForForce(enemySlot, enemyForce)
			end
		end

		return
	end

	if element.name == "force_start_game_button" then
		local force = game.forces[player.force.name]
		if not force then
			player.print("No force found in element.name == force_start_game_button")
			return
		end
		
		local slot = mapModule.getSlotByForceName(force.name)
		if not slot then
			player.print('You have no map slot.')
			return
		end

		if slot.isGameStarted == false then
			if player.gui.screen.difficulty_selection_gui then
				player.gui.screen.difficulty_selection_gui.destroy()
			end

			local enemyForce = nil
			local enemySlot = nil
			if slot.isPvp and slot.enemyForce then
				enemyForce = game.forces[slot.enemyForce]
				if not enemyForce then
					return
				end

				enemySlot = mapModule.getSlotByForceName(enemyForce.name)
			end

			if enemySlot and enemyForce then
				--two forces, is pvp
				local winningMap, winningDifficulty = mapModule.getWinningMapNameAndMapDifficulty(slot, enemySlot)
				if not winningMap then
					player.print('No map chosen!')
					return
				end

				if not winningDifficulty then
					winningDifficulty = 1
				end

				enemySlot.difficulty = tonumber(winningDifficulty)
				enemySlot.mapName = winningMap
				startRoundForForce(enemySlot, enemyForce)
				slot.difficulty = tonumber(winningDifficulty)
				slot.mapName = winningMap
				startRoundForForce(slot, force)

				for _, forcePlayer in pairs(enemyForce.connected_players) do
					if player then
						forcePlayer.print(player.name .. " force started the game!")
					end
				end
				for _, forcePlayer in pairs(force.connected_players) do
					if player then
						forcePlayer.print(player.name .. " force started the game!")
					end
				end
			else
				--only one force, not pvp
				local winningMap, winningDifficulty = mapModule.getWinningMapNameAndMapDifficulty(slot, nil)
				if not winningMap then
					player.print('No map chosen!')
					return
				end

				if not winningDifficulty then
					winningDifficulty = 1
				end

				slot.difficulty = tonumber(winningDifficulty)
				slot.mapName = winningMap
				startRoundForForce(slot, force)
				for _, forcePlayer in pairs(force.connected_players) do
					if player then
						forcePlayer.print(player.name .. " force started the game!")
					end
				end
			end

		else
			player.print("Game started already.")
		end
		return
	end

	if element.name == "open_mainMenu_button" then
		if not player.gui.screen.mainMenu_gui then
			local frame = player.gui.screen.add {
				type = "frame",
				name = "mainMenu_gui",
				direction = "vertical"
			}
			local titlebar = frame.add {
				type = "flow",
				name = "titlebar",
				direction = "horizontal"
			}

			titlebar.add {
				type = "label",
				caption = "Frontier Tower Defense",
				style = "frame_title"
			}

			local dragger = titlebar.add {
				type = "empty-widget",
				style = "draggable_space_header",
			}

			dragger.style.horizontally_stretchable = true
			dragger.style.height = 24
			dragger.style.right_margin = 4
			dragger.drag_target = frame

			titlebar.add {
				type = "sprite-button",
				name = "close",
				sprite = "utility/close",
				style = "frame_action_button"
			}

			-- Scrollable content
			local scroll = frame.add {
				type = "scroll-pane",
				name = "content_scroll",
				direction = "vertical"
			}

			-- Header / logo
			local header = scroll.add {
				type = "flow",
				name = "header",
				direction = "vertical"
			}

			local icons = header.add {
				type = "flow",
				name = "icons",
				direction = "horizontal"
			}

			local rocket = icons.add {
				type = "sprite-button",
				name = "rocket_silo",
				sprite = "entity/rocket-silo",
				tooltip = "Frontier"
			}
			rocket.style.width = 64
			rocket.style.height = 64

			local turret = icons.add {
				type = "sprite-button",
				name = "gun_turret",
				sprite = "entity/gun-turret",
				tooltip = "Tower"
			}
			turret.style.width = 64
			turret.style.height = 64

			local biter = icons.add {
				type = "sprite-button",
				name = "small_biter",
				sprite = "entity/small-biter",
				tooltip = "Defense"
			}
			biter.style.width = 64
			biter.style.height = 64

			header.add {
				type = "label",
				name = "title",
				caption = "Welcome to Frontier Tower Defense!",
				style = "frame_title"
			}

			header.add {
				type = "label",
				name = "description",
				caption = "Build towers to defend your silo. Automate science for upgrades or sending.",
				style = "caption_label"
			}

			-- Separator
			scroll.add {
				type = "line",
				direction = "horizontal"
			}

			-- About section
			local about = scroll.add {
				type = "flow",
				name = "about",
				direction = "vertical"
			}

			about.add {
				type = "label",
				caption = "About",
				style = "bold_label"
			}

			local description = about.add {
				type = "label",
				caption = "Frontier Tower Defense is a scenario and mod combo that lets players choose maps and difficulties to defend a silo from enemies.\nEnemies use different types of waves, resistances, or bosses to get to your silo. Build towers to stop the enemies from getting to the silo. \nTo get more coins, enemies drop coins, and bosses drop special items to craft unique powerful towers.",
				single_line = false
			}
			description.style.width = 500

			-- How to play section
			local how_to_play = scroll.add {
				type = "flow",
				name = "how_to_play",
				direction = "vertical"
			}

			how_to_play.add {
				type = "label",
				caption = "How to Play",
				style = "bold_label"
			}

			local howToPlayDescription = how_to_play.add {
				type = "label",
				caption = "1. Press Play at the top of your screen.\n2. Select a map and a difficulty.\n3. Place down your starting towers.\n4. Use coins to build more towers.",
				single_line = false
			}
			howToPlayDescription.style.width = 500

			frame.force_auto_center()
		else
			player.gui.screen.mainMenu_gui.destroy()
		end
		return
	end

	if element.name == "close" or element.name == "no_button" then
		local frame = element.parent.parent

		if frame and frame.valid then
			local findBiggerParent = frame.parent
			if findBiggerParent and findBiggerParent.valid then
				if findBiggerParent.name:find("bum_joining_", 1, true) then
					findBiggerParent.destroy()
					return
				end
			end
			frame.destroy()
			return
		end
	end
end)

-- Listen for player-built entities
script.on_event(defines.events.on_built_entity, function(event)
	buildingModule.preventBuilding(event)

	-- local success, result = pcall(function()
	--     buildingModule.preventBuilding(event)
	-- end)
end)

-- Listen for robot-built entities
script.on_event(defines.events.on_robot_built_entity, function(event)
	local success, result = pcall(function()
		buildingModule.preventBuilding(event)
	end)
end)

script.on_event(defines.events.on_market_item_purchased, function(event)
end)

script.on_event(defines.events.on_player_died, function(event)	
	local player = game.get_player(event.player_index)
	if not player then
		return
	end

	player.ticks_to_respawn = 0
end)

script.on_event(defines.events.on_player_respawned, function(event)
	local player = game.get_player(event.player_index)
	if not player then
		return
	end
	player.character_running_speed_modifier = 1

	local force = player.force
	local slot = mapModule.getSlotByForceName(force.name)
	if not slot then
		player.print("No slot found when you respawned.")
		return
	end
	local slotDef = mapModule.getSlotDefinitionById(slot.id)
	if not slotDef then
		player.print("No slotDef found when you respawned.")
		return
	end

	local surface = game.surfaces[main_surface_name]
	if not surface then
		player.print("No surface found in defines.events.on_player_respawned")
		return
	end

	teleportPlayerToTheirSpawn(surface, force, slotDef, player)
end)

-- script.on_event(defines.events.on_console_chat, function(event)
-- end)

script.on_event(defines.events.on_entity_damaged, function(event)
	local entity = event.entity

	if not entity.valid or entity.name ~= "rocket-silo" then
		return
	end

	local cause = event.cause

	if cause and cause.valid and cause.type == "character" then
		entity.health = math.min(
			entity.health + event.final_damage_amount,
			entity.max_health
		)
	end
end)

script.on_event(defines.events.on_ai_command_completed, function(event)
	if not storage.biter_paths then
		-- game.print("wow")
		return
	end

	if not storage.biter_paths[event.unit_number] then
		-- game.print("wow2")
		return
	end

	local path_data = storage.biter_paths[event.unit_number]

	if not path_data then
		-- game.print("wow3")
		return
	end

	local group = path_data.group

	if not group.valid then
		-- game.print("wow4")
		storage.biter_paths[event.unit_number] = nil
		return
	end

	-- Only advance if the command actually succeeded.
	if event.result ~= defines.behavior_result.success then
		-- game.print("wow5")
		storage.biter_paths[event.unit_number] = nil
		return
	end

	-- Move to the next waypoint.
	path_data.waypoint = path_data.waypoint + 1

	local surface = game.surfaces[main_surface_name]

  if not storage.biter_paths[event.unit_number] then
    return
  end

  local targetForceName = storage.biter_paths[event.unit_number].targetForceName
  if not targetForceName then
    storage.biter_paths[event.unit_number] = nil
    return
  end
  
  local force = game.forces[tostring(targetForceName)]
  local slot = mapModule.getSlotByForceName(targetForceName)
	local slotDef = mapModule.getSlotDefinitionById(slot.id)
	if not slotDef or not slot then
		return
	end

	if not set_biter_waypoint(group, path_data, surface, slotDef) then
		-- game.print("wow6")
		-- Finished the entire path.

		if force then
			local silos = surface.find_entities_filtered({
				name = "rocket-silo",
				force = force,
				limit = 1
			})

			local silo = silos[1]

			if silo and group then
				group.set_command {
					type = defines.command.attack,
					target = silo,
					distraction = defines.distraction.none
				}
			end
		end
		storage.biter_paths[event.unit_number] = nil
	end
end)

script.on_event(defines.events.on_chunk_generated, function(event)
	local surface = event.surface

	if surface.name ~= "frontier" then
			return
	end

	local area = event.area

	-- Remove any cliffs generated in this chunk
	for _, cliff in pairs(surface.find_entities_filtered {
			area = area,
			type = "cliff"
	}) do
		if cliff.valid then
			cliff.destroy()
		end
	end

	local tiles = {}

	for x = area.left_top.x, area.right_bottom.x - 1 do
		for y = area.left_top.y, area.right_bottom.y - 1 do
			if not mapModule.isPositionInSlot(x, y) then
				tiles[#tiles + 1] = {
					name = "out-of-map",
					position = {
						x = x,
						y = y
					}
				}
				-- else
				--     tiles[#tiles + 1] = {
				--         name = "tutorial-grid",
				--         position = {
				--             x = x,
				--             y = y
				--         }
				--     }
			end
		end
	end

	if #tiles > 0 then
		surface.set_tiles(tiles)
	end
end)

script.on_event(defines.events.on_player_built_tile, function(event)
	local surface = game.surfaces[event.surface_index]
	local restore = {}

	for _, tile in ipairs(event.tiles) do
		if tile.old_tile.name == "red-refined-concrete" then
			restore[#restore + 1] = {
				name = "red-refined-concrete",
				position = tile.position
			}
		end
	end

	if #restore > 0 then
		surface.set_tiles(restore, true)
	end
end)

-- called when player joins the game
script.on_event(defines.events.on_player_joined_game, function(event)
	local player = game.get_player(event.player_index)
	-- game.print(serpent.block(event))
	-- player.print("Welcome back to Frontier!")
	if player.gui.top.menu_bar == nil then
		createDefaultPlayerGui(player)
	end
	player.character_running_speed_modifier = 1
	giveBackInventoryAndCancelRemovingInventory(player)
end)

-- when player leaves the game
script.on_event(defines.events.on_player_left_game, function(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not player then
		return
	end

	local force = player.force
	local slot = mapModule.getSlotByForceName(force.name)
	if not slot then
		return
	end

	local slotId = slot.id
	local slotDef = mapModule.slotDefinitions[slotId]
	if not slotDef then
		return
	end

	local remainingPlayers = {}
	for _, forcePlayer in pairs(force.players) do
		if forcePlayer.index ~= player_index then
      updateTeamMenuGui(forcePlayer)
			table.insert(remainingPlayers, forcePlayer)
		end
	end

	-- No players left on the force.
	if #remainingPlayers == 0 then
		-- Don't reset immediately.
		-- Give the player 5 minutes to reconnect.
		table.insert(storage.delayedTickActions, {
			tick = game.tick + 600, --18000 is 5 minutes
			callback = function()
				local currentSlot = storage.mapSlots[slotId]

				if not currentSlot then
					return
				end

				--check if the slot is a public one
				if currentSlot.id == 1 then
					return
				end

				--Check whether anyone is currently on the force.
				local currentForce = game.forces[tostring(currentSlot.forceName)]

				if currentForce and #currentForce.players > 0 then
					return
				end
				
				local surface = game.surfaces[main_surface_name]
				if surface then
					map.resetMapSlot(
						surface,
						slotId,
						true
					)
				end
			end
		})

		return
	end

	-- There are still players on the force.
	-- If the leaving player was the slot owner, assign a new owner.
	local newOwner = remainingPlayers[1]

	if slot.slotOwnerIndex == player_index and newOwner and slot.id ~= 1 then
		slot.slotOwnerIndex = newOwner.index
	end

	createSnapshotInventory(player)
end)

script.on_event(defines.events.on_chart_tag_removed, function(event)
	for i, slot in ipairs(storage.mapSlots) do
		if slot and slot.mapTagId then
			if tostring(slot.mapTagId) == tostring(event.tag.tag_number) then
				local tag = event.tag
				local newTag = tag.force.add_chart_tag(tag.surface, {
					position = tag.position,
					text = tag.text,
					icon = tag.icon
				})

				slot.mapTagId = newTag.tag_number

				return
			end
		end
	end
end)

commands.add_command("suicide", "Kill your character.", function(command)
	local player = game.get_player(command.player_index)
	if player and player.character and player.character.valid then
		if player.character.destructible == false then
			player.character.destructible = true
		end
		player.character.die()
	else
		player.print("You have no character to kill.")
	end
end)

commands.add_command("dropinv", "Drops your inventory.", function(command)
	local player = game.get_player(command.player_index)
	if player and player.character and player.character.valid then
		createSnapshotInventory(player, 0)
	end
end)
	
commands.add_command("canceldropinv", "Cancel your inventory.", function(command)
	local player = game.get_player(command.player_index)
	if player and player.character and player.character.valid then
		giveBackInventoryAndCancelRemovingInventory(player)
	end
end)


