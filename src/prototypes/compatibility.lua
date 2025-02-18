local utils = require("prototypes.utils")

-- check for modded locomotives and create equipment & entity for them
for prototype_name, prototype in pairs(data.raw["locomotive"]) do
  if prototype_name ~= "locomotive" and not shared.is_a_motorcar(prototype_name)
    and not utils.table_contains(railway_motorcar_ignored, prototype_name)
  then
    -- use item with the same name
    local prototype_item = data.raw["item-with-entity-data"][prototype_name] or data.raw["item"][prototype_name]
    -- search item otherwise
    if not prototype_item or prototype_item.place_result ~= prototype_name then
      for _, rec in pairs(data.raw["item-with-entity-data"]) do
        if rec.place_result == prototype_name then
          prototype_item = rec
          break
        end
      end

      if not prototype_item then
        for _, rec in pairs(data.raw["item"]) do
          if rec.place_result == prototype_name then
            prototype_item = rec
            break
          end
        end
      end
    end

    -- cannot create the recipe without the item (it must be visible to craft it)
    if prototype_item and not (prototype_item.flags and utils.table_contains(prototype_item.flags, "hidden")) then
      log("Creating motorcar for " .. prototype_name)

      local name = shared.motorcar_prefix .. prototype_name
      local motorcar = utils.create_entity(prototype_name, name, true)

      -- other mods may not use translations, but set the localized name instead
      local localised_name = {"", {"entity-name." .. shared.base_motorcar}, " ("};
      table.insert(localised_name, prototype_item.localised_name or {"entity-name." .. prototype_name})
      table.insert(localised_name, ")")
      motorcar.localised_name = localised_name

      if prototype_item.icons then
        motorcar.icons[1] = {
          icon = prototype_item.icons[1].icon,
          icon_size = prototype_item.icons[1].icon_size or 64,
          -- original is fixed at 128 - scale accordingly
          scale = 128 / ((prototype_item.icons[1].icon_size or 64) * (prototype_item.icons[1].scale or 1))
        }
      else
        motorcar.icons[1] = {
          icon = prototype_item.icon,
          icon_size = prototype_item.icon_size or 64,
          scale = 128 / (prototype_item.icon_size or 64)
        }
      end

      data:extend {motorcar}

      local equipment = utils.create_equipment(name, true)
      equipment.localised_name = motorcar.localised_name

      local item = utils.create_item(name)
      item.localised_name = motorcar.localised_name
      item.localised_description = {"item-description." .. shared.base_motorcar}

      local recipe = {
        type = "recipe",
        name = name,
        localised_name = motorcar.localised_name,
        enabled = false,
        ingredients = {
          {type="item", name="advanced-circuit", amount=10},
          {type="item", name=prototype_item.name, amount=1},
        },
        results = {{
          type = "item",
          name = name,
          amount = 1
        }},
        order = "g-h-a"
      }

      -- add recipe to the nuclear tech
      local technology = data.raw["technology"][shared.nuclear_motorcar]
      table.insert(technology.effects, {type = "unlock-recipe", recipe = name})

      data:extend {equipment, item, recipe, technology}
    else
      log("No item found to create " .. prototype_name .. ", cannot use as a motorcar")
    end
  end
end