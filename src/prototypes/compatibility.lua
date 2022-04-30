local utils = require "utils"

-- check for modded locomotives and create equipment & entity for them
for prototype_name, prototype in pairs(data.raw["locomotive"]) do
  if prototype_name ~= "locomotive" and not shared.is_a_motorcar(prototype_name)
  then
    -- use item with the same name
    local prototype_item = data.raw["item-with-entity-data"][prototype_name]
    -- search item otherwise
    if not prototype_item or prototype_item.place_result ~= prototype_name then
      for _, rec in pairs(data.raw["item-with-entity-data"]) do
        if rec.place_result == prototype_name then
          prototype_item = rec
          break
        end
      end
    end

    -- cannot create the recipe without the item
    if prototype_item then
      local name = shared.motorcar_prefix .. prototype_name
      local motorcar = utils.create_entity(prototype_name, name, true)
      motorcar.localised_name = {"", {"entity-name." .. shared.base_motorcar}, " (", {"entity-name." .. prototype_name}, ")"}
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
        normal = {
          enabled = false,
          ingredients = {
            {"advanced-circuit", 10},
            {prototype_item.name, 1},
          },
          result = name,
          energy_consumption = 4,
        },
        icon = prototype.icon,
        icon_size = prototype.icon_size,
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