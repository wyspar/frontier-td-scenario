local building = {}
local mapModule = require('scripts.map')

function building.preventBuilding(event)
    local entity = event.created_entity or event.entity
    if not entity then 
        return 
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local slot = mapModule.getSlotByForceName(player.force.name)
    if not slot then
        return
    end

    local mapId = slot.id
    if not mapId then
        return
    end

    local slotDef = mapModule.slotDefinitions[mapId]
    if not slotDef then
        return
    end

    local isEntityInsidePlayerSlot = mapModule.isEntityInSlot(entity, slotDef)

    local surface = entity.surface
    local position = entity.position
    local item_name = entity.name
    local item_type = entity.type
    local tile = surface.get_tile(position)

    if tile.name == "red-refined-concrete" or isEntityInsidePlayerSlot == false then
        if item_type == "entity-ghost" or item_type == "tile-ghost" then
            entity.destroy()
            return
        end

        if string.find(item_name, "plant") then
            item_name = string.gsub(item_name, "plant", "seed")
        end

        if item_name == "jellystem" then
            item_name = "jellynut-seed"
        end

        if item_name == "yumako-tree" then
            item_name = "yumako-seed"
        end

        local inserted_count = player.insert({
            name = item_name,
            count = 1,
            quality = entity.quality
        })

        if inserted_count < 1 then
            player.print("Your inventory is full! The item could not be returned.")
        end

        entity.destroy()
        return
    end

    -- if item_name == "rocket-silo" then
    --     entity.destroy()
    --     return
    -- end

end

return building