local map = {}
local market = require("scripts.market")
local map1 = require("scripts.maps.map1")
local main_surface_name = "frontier"

--this is where player spawns their map
--+10 offset, (50 + width)
map.slotDefinitions = {
	[1] = {
		id = 1,
		x = 10,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	},
	[2] = {
		id = 2,
		x = 260,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	},
	[3] = {
		id = 3,
		x = 510,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	},
	[4] = {
		id = 4,
		x = 760,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	},
	[5] = {
		id = 5,
		x = 1010,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	},
	[6] = {
		id = 6,
		x = 1260,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	},
	[7] = {
		id = 7,
		x = 1510,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	},
	[8] = {
		id = 8,
		x = 1760,
		y = -5,
		width = 200,
		height = 200,
		structures = nil,
		biterPaths = nil,
		mapName = nil,
	}
}

map.difficulties = {
    [1] = {
        id = 1,
        label = "Normal"
    },
    [2] = {
        id = 2,
        label = "Easy"
    },
    [3] = {
        id = 3,
        label = "Hard"
    }
}

map.allMaps = {
    [1] = {
        id = 1,
        name = map1.mapName,
        label = map1.mapLabel,
        tile = map1.mapTile,
        icon = map1.mapIcon,
    }
}

local sandRockNames = {
    "big-sand-rock",
}

local forbiddenTilesForSpawningRocksOn = {
    ["water"] = true,
    ["deepwater"] = true,
    ["red-refined-concrete"] = true,
    ["yellow-refined-concrete"] = true,
    ["out-of-map"] = true
}

function map.create_main_surface(player)
    local surface_name = "frontier"
    local surface = game.surfaces[surface_name]

    if not surface then
        surface = game.create_surface(surface_name, {
            terrain_segmentation = "none",
            -- width = startingWidth,
            -- height = startingHeight,
            peaceful_mode = false,
            no_enemies_mode = false,
            starting_area = "none",
            default_enable_all_autoplace_controls = false
        })

        surface.request_to_generate_chunks({0, 0}, 2)
        surface.force_generate_chunk_requests()
    
    end

    return surface
end

-- Function to place the teleporter entity on Nauvis when the scenario starts
function map.spawn_teleporter(surface,position)
    local foundBeam = false
    for _, entity in pairs(surface.find_entities_filtered({name = "electric-beam-no-sound", entity_tag = "mainToHomeBeam"})) do
        if entity and entity.valid then
            foundBeam = true
        end
    end
    if not foundBeam then

        local center = position
        local size = 1 -- half the length of the square side
        local top_left     = {x = center.x - size, y = center.y - size}
        local top_right    = {x = center.x + size, y = center.y - size}
        local bottom_left  = {x = center.x - size, y = center.y + size}
        local bottom_right = {x = center.x + size, y = center.y + size}

        local force = game.forces["neutral"]

        -- Top side
        local beam1 = surface.create_entity{
            name = "electric-beam-no-sound",
            source = top_left,
            position = position,
            target = top_right,
            force = force
        }

        -- Right side
        local beam2 = surface.create_entity{
            name = "electric-beam-no-sound",
            source = top_right,
            position = position,
            target = bottom_right,
            force = force
        }

        -- Bottom side
        local beam3 = surface.create_entity{
            name = "electric-beam-no-sound",
            position = position,
            source = bottom_right,
            target = bottom_left,
            force = force
        }

        -- Left side
        local beam4 = surface.create_entity{
            name = "electric-beam-no-sound",
            position = position,
            source = bottom_left,
            target = top_left,
            force = force
        }

        if beam1 then
            beam1.tags = { custom_tag = "mainToHomeBeam" }
            beam2.tags = { custom_tag = "mainToHomeBeam" }
            beam3.tags = { custom_tag = "mainToHomeBeam" }
            beam4.tags = { custom_tag = "mainToHomeBeam" }
        end
    end
end

function map.getRelativeSlotPosition(slotDef, local_x, local_y)
    return {
        x = slotDef.x + local_x,
        y = slotDef.y + local_y
    }
end

local function generate_structures(surface, slot)
    local mapSlot = storage.mapSlots[slot.id]
    local force = game.forces[tostring(mapSlot.forceName)]
    for _, structure in ipairs(slot.structures or {}) do
        local position = map.getRelativeSlotPosition(
            slot,
            structure.x,
            structure.y
        )


        local entity = surface.create_entity({
            name = structure.name,
            position = position,
            direction = structure.direction or defines.direction.north,
            force = force
        })

        entity.minable = false
        if (entity.name ~= "rocket-silo") then
            entity.destructible = false
        end
    end

    --generate stupid shit like decorations, trees, rocks
    local random = game.create_random_generator()
    local rockCount = random(50, 150)

    for _ = 1, rockCount do
        local rockName = sandRockNames[random(1, #sandRockNames)]

        local position = map.getRelativeSlotPosition(
            slot,
            random() * slot.width,
            random() * slot.height
        )

        local tile = surface.get_tile(position)

        if tile and not forbiddenTilesForSpawningRocksOn[tile.name] then
            local entity = surface.create_entity({
                name = rockName,
                position = position
            })

            if entity then
                entity.minable = true
                entity.destructible = true
            end
        end
    end
end

local function set_tile_area(surface, slot, tile_name, x1, y1, x2, y2)
    local tiles = {}

    for x = x1, x2 do
        for y = y1, y2 do
            local position = map.getRelativeSlotPosition(slot, x, y)

            tiles[#tiles + 1] = {
                name = tile_name,
                position = position
            }
        end
    end

    surface.set_tiles(tiles, true)
end

local function createCircleOfTiles(surface, center_x, center_y, radius)
    local tiles = {}
    for x = center_x - radius, center_x + radius do
        for y = center_y - radius, center_y + radius do
            local dx = x - center_x
            local dy = y - center_y
            if dx * dx + dy * dy < radius * radius then
                local tile = surface.get_tile(x, y)
                if  tile.name ~= "red-refined-concrete" and 
                    tile.name ~= "out-of-map" 
                then
                    tiles[#tiles + 1] = {
                        name = "water",
                        position = {x = x, y = y}
                    }
                end
            end
        end
    end

    surface.set_tiles(tiles, true)
end

local function createOutlineCircleOfTiles(surface, center_x, center_y, radius, inner_radius, inner_tile, outer_tile)
    local tiles = {}
    for x = center_x - radius, center_x + radius do
        for y = center_y - radius, center_y + radius do
            local dx = x - center_x
            local dy = y - center_y
            local distance_squared = dx * dx + dy * dy
            if distance_squared < radius * radius then
                local tile = surface.get_tile(x, y)
                if  tile.name ~= "red-refined-concrete" and 
                    tile.name ~= "out-of-map" and
                    tile.name ~= inner_tile
                then
                    local tile_name
                    if distance_squared < inner_radius * inner_radius then
                        tile_name = inner_tile
                    else
                        tile_name = outer_tile
                    end

                    tiles[#tiles + 1] = {
                        name = tile_name,
                        position = {
                            x = x,
                            y = y
                        }
                    }
                end
            end
        end
    end

    surface.set_tiles(tiles, true)
end


function map.generateSlotLand(surface, slot, generateStructures)
    local area = {
        {slot.x, slot.y},
        {
            slot.x + slot.width - 1,
            slot.y + slot.height - 1
        }
    }

    local position = map.getRelativeSlotPosition(
        slot,
        slot.width / 2,
        slot.height / 2
    )
    surface.request_to_generate_chunks(position, 4)

    -- Destroy entities
    for _, entity in pairs(surface.find_entities_filtered({
        area = area
    })) do
        if entity.valid and entity.type ~= "character" then
            entity.destroy()
        end
    end

    -- Destroy decoratives
    surface.destroy_decoratives({
        area = area
    })

    local tiles = {}
    local getMap = map.getMapByName(slot.mapName)
    if not getMap then
        game.print("Error getting getMap in map.generateSlotLand in map.lua")
        return
    end

    for x = slot.x, slot.x + slot.width - 1 do
        for y = slot.y, slot.y + slot.height - 1 do
            tiles[#tiles + 1] = {
                name = getMap.mapTile,
                position = {
                    x = x,
                    y = y
                }
            }
        end
    end
    surface.set_tiles(tiles, true)

    if getMap.waterCompleteTiles then
        for i, point in ipairs(getMap.waterCompleteTiles) do
            local position = map.getRelativeSlotPosition(slot, point.x, point.y)
            createCircleOfTiles(surface, position.x, position.y, point.radius)
        end
    end

    if getMap.waterOutlineTiles then
        for i, point in ipairs(getMap.waterOutlineTiles) do
            local position = map.getRelativeSlotPosition(slot, point.x, point.y)
            createOutlineCircleOfTiles(surface, position.x, position.y, point.radius, point.innerRadius, point.innerTile, point.outerTile)
        end
    end

    if (slot.biterPaths) then
        local tiles = {}

        for i, path in ipairs(slot.biterPaths) do
            local position = map.getRelativeSlotPosition(slot, path.x, path.y)


            if i == 1 then
                -- first path

                set_tile_area(
                    surface,
                    slot,
                    "red-refined-concrete",
                    path.x - 14,
                    path.y - 14,
                    path.x + 14,
                    path.y + 14
                )

                local spawner = surface.create_entity({
                    name = "biter-spawner",
                    position = position,
                    force = game.forces.enemy
                })
                spawner.destructible = false
                spawner.active = false
                spawner.minable = false
            elseif i == #slot.biterPaths then
                -- last path
                tiles[#tiles + 1] = {
                    name = "red-refined-concrete",
                    position = position
                }
            else
                -- middle paths
                tiles[#tiles + 1] = {
                    name = "yellow-refined-concrete",
                    position = position
                }
            end

        end

        surface.set_tiles(tiles, true)
    end

    if not getMap.DefaultMapStructures then
        game.print("No getMap.DefaultMapStructures found in map.generateSlotLand in map.lua")
    end
    
    if (generateStructures ) then
        slot.structures = getMap.DefaultMapStructures

        local silo = map.findStructureByName(slot.structures, "rocket-silo")
        -- Volcanic ash flats around silo
        set_tile_area(
            surface,
            slot,
            "volcanic-ash-flats",
            silo.x - 5,
            silo.y - 5,
            silo.x + 5,
            silo.y + 5
        )

        -- Grass at top, 21 tiles wide
        -- set_tile_area(
        --     surface,
        --     slot,
        --     "grass-1",
        --     40, 0,
        --     61, 5
        -- )

        generate_structures(surface, slot)
    end
end

function map.isPositionInSlot(x, y)
    if not storage.mapSlots then
        return
    end

    for _, slot in pairs(map.slotDefinitions) do

        if x >= slot.x
        and x < slot.x + slot.width
        and y >= slot.y
        and y < slot.y + slot.height then
            return true
        end
    end

    return false
end

function map.getPositionInSlot(position, slotDef)
    return position.x >= slotDef.x
       and position.x < slotDef.x + slotDef.width
       and position.y >= slotDef.y
       and position.y < slotDef.y + slotDef.height
end

function map.isEntityInSlot(entity, slotDef)
    local box = entity.bounding_box

    return box.left_top.x >= slotDef.x
       and box.right_bottom.x <= slotDef.x + slotDef.width
       and box.left_top.y >= slotDef.y
       and box.right_bottom.y <= slotDef.y + slotDef.height
end

function map.getSlotByForceName(forceName)
    for _, slot in pairs(storage.mapSlots) do
        if tostring(slot.forceName) == tostring(forceName) then
            return slot
        end
    end
    return nil
end

function map.getSlotDefinitionById(id)
    for _, slotDef in pairs(map.slotDefinitions) do
        if tostring(slotDef.id) == tostring(id) then
            return slotDef
        end
    end

    return nil
end

function map.findSlotPlayerSpawnPoint(surface, force)
    if not force then
        game.print('Error finding force in map.findSlotPlayerSpawnPoint in map.lua')
        return
    end
    local entities = surface.find_entities_filtered({
        name = "rocket-silo",
        force = force,
        limit = 1
    })

    local spawnPoint = entities[1]
    if not spawnPoint then
        --get the slot pos instead if silo is missing
        local slot = map.getSlotByForceName(force.name)
        if not slot then
            return
        end
        local slotDef = map.getSlotDefinitionById(slot.id)
        if not slotDef then
            return
        end
        local centerOfMap = {
            x = slotDef.x + slotDef.width / 2,
            y = slotDef.y + slotDef.height / 2
        }
        return centerOfMap
    end

    return spawnPoint.position
end

function map.getMapByName(mapName)
    if not mapName then
        return nil
    end
    if(tostring(mapName) == "map-1-sand")then
        return map1
    end
end

function map.getMapWaveData(mapName, difficulty)
    if not difficulty or not mapName then
        return nil
    end
    local findMap = map.getMapByName(mapName)
    if findMap then
        return findMap.mapBiterWaveData[difficulty]
    end
    return nil
end

function map.chooseDifficulty(mapName, difficulty)
    if not difficulty or not mapName then
        return nil
    end
end

function map.getMapBiterPaths(mapName, difficulty)
    if not difficulty or not mapName then
        return nil
    end
    local findMap = map.getMapByName(mapName)
    if findMap then
        return findMap.mapBiterPaths[difficulty]
    end
    return nil
end

function map.createStartingPlayer(player, slot)
    if not player then
        return
    end

    local force = player.force
    local surface = game.surfaces[main_surface_name]
	if not surface then
		game.print("No surface found in map.createStartingPlayer(player)")
		return
	end
	local spawnPos = map.findSlotPlayerSpawnPoint(surface, force)
	if not spawnPos then
		spawnPos = {
			x = slot.x + slot.width / 2,
			y = slot.y + slot.height / 2
		}
	end
	local findBestPosition = surface.find_non_colliding_position("character", spawnPos, 20, 0.5)
	if findBestPosition then
		player.teleport(findBestPosition, surface)
	else
		player.teleport(spawnPos, surface)
	end

    player.insert({name = "iron-plate", count = 200})
    player.insert({name = "copper-plate", count = 200})
    player.insert({name = "big-mining-drill", count = 20})
    player.insert({name = "small-electric-pole-iron", count = 150})
    player.insert({name = "furnace-pro-01", count = 10})
    player.insert({name = "infinite-gun-turret", count = 10})
    --player.insert({name = "firearm-magazine", count = 200})

    player.insert({name = "electric-energy-interface", count = 1})
    player.insert({name = "coin", count = 3000})

    local inventory = player.get_inventory(defines.inventory.character_main)
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    if armor_inventory then
        armor_inventory.insert({
            name = "mech-armor",
            count = 1
        })
    end

    local guns = player.get_inventory(defines.inventory.character_guns)
    local ammo = player.get_inventory(defines.inventory.character_ammo)

    if guns then
        guns[1].set_stack({
            name = "submachine-gun",
            count = 1
        })
        if ammo then
            ammo[1].set_stack({
                name = "firearm-magazine",
                count = 100
            })
        end
    end
end

function map.resetMapSlot(surface, slotId, isHardReset)
    if not slotId or not surface then
			game.print('no surface or slotId in map.resetMapSlot()')
			return
    end

    local slotDef = map.slotDefinitions[slotId]
    if not slotDef then
			game.print('no slotDef in map.resetMapSlot()')
			return
    end

    local area = {
			{slotDef.x, slotDef.y},
			{
				slotDef.x + slotDef.width - 1,
				slotDef.y + slotDef.height - 1
			}
    }

    -- Destroy entities
    for _, entity in pairs(surface.find_entities_filtered({
			area = area
    })) do
			if entity.valid and entity.type ~= "character" then
				entity.destroy()
			end
    end

    -- Destroy decoratives
    surface.destroy_decoratives({
			area = area
    })

    local tiles = {}

    for x = slotDef.x, slotDef.x + slotDef.width - 1 do
        for y = slotDef.y, slotDef.y + slotDef.height - 1 do
            tiles[#tiles + 1] = {
                name = "tutorial-grid",
                position = {
                    x = x,
                    y = y
                }
            }
        end
    end

    surface.set_tiles(tiles, true)

    local mapSlot = storage.mapSlots[slotDef.id]
		local forceName = mapSlot.forceName
		local force = game.forces[forceName]
		if not force then
			return
		end

    mapSlot.isGameStarted = false
    mapSlot.isPvp = false
    mapSlot.enemyForce = nil
    mapSlot.isDead = false
    mapSlot.isEndless = false
    mapSlot.currentWave = 0
    mapSlot.totalWaves = 0
    mapSlot.difficulty = 1
    mapSlot.mapName = nil
    mapSlot.mapWaveData = nil
    mapSlot.mapBiterPaths = nil
    mapSlot.mapVotes = {}
    mapSlot.mapDifficultyVotes = {}
    mapSlot.waveTimer = 0
    mapSlot.waveStartTick = 0
    mapSlot.waveGroups = nil
		local oldMapTagId = mapSlot.mapTagId
		mapSlot.mapTagId = nil

		if oldMapTagId ~= nil then
			for _, tag in pairs(force.find_chart_tags(surface)) do
				if tag.tag_number == oldMapTagId then
					tag.destroy()
					break
				end
			end
		end

    if isHardReset then
			slotDef.structures = nil
			slotDef.biterPaths = nil
			slotDef.mapName = nil
			mapSlot.isOccupied = false
			mapSlot.slotOwnerIndex = nil
    end
end

local bossRewardData = {
    ["boss-biter-1"] = {
        coins = 200,
        rewardItemAmount = 1
    },
    ["boss-biter-2"] = {
        coins = 1000,
        rewardItemAmount = 1
    },
    ["boss-biter-3"] = {
        coins = 2500,
        rewardItemAmount = 2
    },
    ["boss-biter-4"] = {
        coins = 5000,
        rewardItemAmount = 2
    }
}

function map.getBossRewardData(entityName)
    return bossRewardData[entityName]
end

function map.findStructureByName(structures, structureName)
    for _, structure in pairs(structures) do
        if structure.name == structureName then
            return structure
        end
    end
    return nil
end

function map.getWinningMapNameAndMapDifficulty(slot, enemySlot)
    local mapVoteCounts = {}
    local difficultyVoteCounts = {}

    local function countVotes(voteSlot)
        if not voteSlot then
            return
        end

        -- Count map votes
        if voteSlot.mapVotes then
            for playerIndex, mapName in pairs(voteSlot.mapVotes) do
                mapVoteCounts[mapName] = (mapVoteCounts[mapName] or 0) + 1
            end
        end

        -- Count difficulty votes
        if voteSlot.mapDifficultyVotes then
            for playerIndex, difficultyName in pairs(voteSlot.mapDifficultyVotes) do
                difficultyVoteCounts[difficultyName] = (difficultyVoteCounts[difficultyName] or 0) + 1
            end
        end
    end

    -- Count votes from your slot
    countVotes(slot)
    -- Count votes from enemy slot, if it exists
    countVotes(enemySlot)

    -- Find winning map
    local winningMap
    local winningMapVotes = 0
    for mapName, voteCount in pairs(mapVoteCounts) do
        if voteCount > winningMapVotes then
            winningMap = mapName
            winningMapVotes = voteCount
        end
    end

    -- Find winning difficulty
    local winningDifficulty
    local winningDifficultyVotes = 0
    for difficultyName, voteCount in pairs(difficultyVoteCounts) do
        if voteCount > winningDifficultyVotes then
            winningDifficulty = difficultyName
            winningDifficultyVotes = voteCount
        end
    end

    return winningMap, winningDifficulty
end

local enemyRewardData = {
    ["small-biter"] = {
        coins = 1
    },
    ["medium-biter"] = {
        coins = 4
    },
    ["big-biter"] = {
        coins = 9
    },
    ["behemoth-biter"] = {
        coins = 15
    }
}

function map.getEnemyRewardData(entityName)
    return enemyRewardData[entityName]
end

return map