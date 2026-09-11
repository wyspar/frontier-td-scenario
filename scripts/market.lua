local market = {}
market.custom_events = {
    ['playerItemsMarket'] = 'playerItemsMarket',
}

local sciMarket_Items = {
    {
        price = {
            { name = 'coal', count = 50 },
            { name = 'stone', count = 50 },
            { name = 'iron-ore', count = 50 },
            { name = 'copper-ore', count = 50 },
        },
        offer = { type = 'give-item', item = 'automation-science-pack', count = 1 }
    },
    {
        price = {
            { name = 'small-lamp', count = 50 },
            { name = 'steel-plate', count = 100 },
            { name = 'weed-indica-bag', count = 50 },
            { name = 'inserter', count = 50 },
        },
        offer = { type = 'give-item', item = 'logistic-science-pack', count = 1 }
    },
    {
        price = {
            { name = 'coin', count = 2000 },
        },
        offer = { type = 'give-item', item = 'aai-loader', count = 1 }
    },
}

local drugMarket_Items = {
    {
        price = {
            { name = 'weed-indica-bag', count = 1 }
        },
        offer = { type = 'give-item', item = 'coin', count = 1 }
    },
    {
        price = {
            { name = 'cocaine-bag', count = 1 }
        },
        offer = { type = 'give-item', item = 'coin', count = 20 }
    },
}

local landMarket_Items = {
}

local playerItemsMarket_items = {
    { price = { { name = 'iron-gear-wheel', count = 1 } },     offer = { type = 'give-item', item = 'raw-fish', count = 1 } },
    { price = { { name = 'iron-plate', count = 3 } },     offer = { type = 'give-item', item = 'firearm-magazine', count = 1 } },
    { price = { { name = 'iron-plate', count = 2 },{ name = 'steel-plate', count = 1 },{ name = 'copper-plate', count = 1 } },     offer = { type = 'give-item', item = 'piercing-rounds-magazine', count = 1 } },
    { price = { { name = 'iron-plate', count = 15 } },    offer = { type = 'give-item', item = 'pistol', count = 1 } },
    { price = { { name = 'iron-gear-wheel', count = 15 } },    offer = { type = 'give-item', item = 'submachine-gun', count = 1 } },
    --{ price = { { name = 'coin', count = 32 } },    offer = { type = 'give-item', item = 'cluster-grenade', count = 1 } },
    -- { price = { { name = 'coin', count = 80 } },    offer = { type = 'give-item', item = 'car', count = 1 } },
    -- { price = { { name = 'coin', count = 1200 } },  offer = { type = 'give-item', item = 'tank', count = 1 } },
    -- { price = { { name = 'coin', count = 3 } },     offer = { type = 'give-item', item = 'cannon-shell', count = 1 } },
    -- { price = { { name = 'coin', count = 7 } },     offer = { type = 'give-item', item = 'explosive-cannon-shell', count = 1 } },
    {
        price = {
            { name = 'iron-plate', count = 1, quality = "normal" },
            { name = 'copper-plate', count = 1, quality = "normal" },
        },
        offer = { type = 'give-item', item = 'shotgun-shell', count = 1, quality = "uncommon" }
    },
    {
        price = {
            { name = 'iron-plate', count = 10, quality = "normal" },
            { name = 'copper-plate', count = 10, quality = "normal" },
        },
        offer = { type = 'give-item', item = 'shotgun', count = 1, quality = "uncommon" }
    },
    {
        price = {
            { name = 'coin', count = 6}
        },
        offer = { type = 'give-item', item = 'piercing-shotgun-shell', count = 1, quality = "uncommon" }
    },
    {
        price = {
            { name = 'coin', count = 250}
        },
        offer = { type = 'give-item', item = 'combat-shotgun', count = 1, quality = "uncommon" }
    },
    { price = { { name = 'coin', count = 50 } },   offer = { type = 'give-item', item = 'flamethrower', count = 1 } },
    { price = { { name = 'coin', count = 1 } },    offer = { type = 'give-item', item = 'flamethrower-ammo', count = 1 } },
    { price = { { name = 'coin', count = 125 } },   offer = { type = 'give-item', item = 'rocket-launcher', count = 1 } },
    { price = { { name = 'coin', count = 2 } },     offer = { type = 'give-item', item = 'rocket', count = 1 } },
    { price = { { name = 'coin', count = 7 } },     offer = { type = 'give-item', item = 'explosive-rocket', count = 1 } },
    { price = { { name = 'coin', count = 25 } },    offer = { type = 'give-item', item = 'poison-capsule', count = 1 } },
    { price = { { name = 'coin', count = 5 } },     offer = { type = 'give-item', item = 'defender-capsule', count = 1 } },
    { price = { { name = 'iron-plate', count = 10 } },    offer = { type = 'give-item', item = 'light-armor', count = 1 } },
    { price = { { name = 'coin', count = 25 } },   offer = { type = 'give-item', item = 'heavy-armor', count = 1 } },
    {
        price = {
            { name = 'electronic-circuit', count = 100, quality = "uncommon" },
            { name = 'advanced-circuit', count = 100, quality = "normal" },
        },
        offer = { type = 'give-item', item = 'modular-armor', count = 1, quality = "uncommon" }
    },
    -- { price = { { name = 'coin', count = 350 } },   offer = { type = 'give-item', item = 'modular-armor', count = 1 } },
    -- { price = { { name = 'coin', count = 1500 } },  offer = { type = 'give-item', item = 'power-armor', count = 1 } },
    -- { price = { { name = 'coin', count = 12000 } }, offer = { type = 'give-item', item = 'power-armor-mk2', count = 1 } },
    -- { price = { { name = 'coin', count = 50 } },    offer = { type = 'give-item', item = 'solar-panel-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 2250 } },  offer = { type = 'give-item', item = 'fission-reactor-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 100 } },   offer = { type = 'give-item', item = 'battery-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 200 } },   offer = { type = 'give-item', item = 'energy-shield-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 850 } },   offer = { type = 'give-item', item = 'personal-laser-defense-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 175 } },   offer = { type = 'give-item', item = 'exoskeleton-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 125 } },   offer = { type = 'give-item', item = 'night-vision-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 200 } },   offer = { type = 'give-item', item = 'belt-immunity-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 250 } },   offer = { type = 'give-item', item = 'personal-roboport-equipment', count = 1 } },
    -- { price = { { name = 'coin', count = 350 } },   offer = { type = 'give-item', item = 'roboport', count = 1 } },
    -- { price = { { name = 'coin', count = 50 } },    offer = { type = 'give-item', item = 'storage-chest', count = 1 } },
    -- { price = { { name = 'coin', count = 35 } },    offer = { type = 'give-item', item = 'construction-robot', count = 1 } },
}

local east_Market_Items = {
    {
        price = {
            { name = 'coin', count = 1500 }
        },
        offer = {
            type = 'nothing',
            effect_description = market.custom_events["player-upgrade-build-range"]
        }
    },
}

function market.fillMarket(surface, marketName, entityName)
    for _, entity in pairs(surface.find_entities_filtered({name = entityName})) do
        if entity and entity.valid then
            if entity.name_tag == marketName then
                entity.clear_market_items()
                if marketName == market.custom_events["playerItemsMarket"] then
                    for _, item in pairs(playerItemsMarket_items) do
                        entity.add_market_item(item)
                    end
                -- elseif marketName == market.custom_events["playerSciMarket"] then
                --     for _, item in pairs(sciMarket_Items) do
                --         entity.add_market_item(item)
                --     end
                end
            end
        end
    end
end

function market.removeItemFromMarket(surface, itemName, marketName, entityName)
    for _, entity in pairs(surface.find_entities_filtered({name = entityName})) do
        if entity and entity.valid then
            if entity.name_tag == marketName then
                local items = entity.get_market_items()
                for index, item in pairs(items) do
                    if item.offer.item == itemName then
                        entity.remove_market_item(index)
                        break
                    end
                end
            end
        end
    end
end

function market.removeEffectFromMarket(surface, effectName, marketName, entityName)
    for _, entity in pairs(surface.find_entities_filtered({name = entityName})) do
        if entity and entity.valid then
            if entity.name_tag == marketName then
                local items = entity.get_market_items()
                for index, item in pairs(items) do
                    if item.offer.effect_description == effectName then
                        entity.remove_market_item(index)
                        break
                    end
                end
            end
        end
    end
end

return market