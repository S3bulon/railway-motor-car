local utils = require("prototypes.utils")
local flib = mods["flib"] and require( "__flib__.data-util")

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

      data:extend {motorcar}

      local equipment = utils.create_equipment(name, true)
      equipment.localised_name = motorcar.localised_name

      local item = utils.create_item(name)
      item.localised_name = motorcar.localised_name
      item.localised_description = {"item-description." .. shared.base_motorcar}

      if flib then
        -- with flib: Generate icons with overlay
        local motorcar_icon = {
          {
            icon = shared.root .. "/graphics/equipment/motorcar_overlay.png",
            icon_size = 64,
            tint = {r=1, g=1, b=1, a=1}
          }
        }
        item.icons = flib.create_icons(prototype, motorcar_icon) or motorcar_icon
        item.icon = nil
        item.icon_size = nil
      else
        -- fallback: copy icon of the original b/c they are dynamic
        item.icon = prototype_item.icon
        item.icon_size = prototype_item.icon_size
        item.icons = prototype_item.icons
      end

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