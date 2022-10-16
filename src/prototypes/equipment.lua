local utils = require "utils"

local base_motorcar = data.raw["locomotive"][shared.base_motorcar]
local nuclear_motorcar = data.raw["locomotive"][shared.nuclear_motorcar]

local base_equipment = utils.create_equipment(shared.base_motorcar, false)
local nuclear_equipment = utils.create_equipment(shared.nuclear_motorcar, true)

local base_item = utils.create_item(shared.base_motorcar)
local nuclear_item = utils.create_item(shared.nuclear_motorcar)

---@type Prototype_Recipe
local base_recipe = {
  type = "recipe",
  name = shared.base_motorcar,
  normal = {
    enabled = false,
    ingredients = {
      { "electric-engine-unit", 20 },
      { "steel-plate", 30 },
      { "advanced-circuit", 10 },
    },
    result = shared.base_motorcar,
    energy_consumption = 4,
  },
  icon = base_motorcar.icon,
  icon_size = base_motorcar.icon_size,
  order = "g-h-a"
}

local nuclear_recipe = table.deepcopy(base_recipe)
nuclear_recipe.name = shared.nuclear_motorcar
nuclear_recipe.normal.ingredients = {
  { "electric-engine-unit", 20 },
  { "steel-plate", 30 },
  { "advanced-circuit", 10 },
  { "nuclear-fuel", 5 }
}
nuclear_recipe.normal.result = shared.nuclear_motorcar
nuclear_recipe.icon = nuclear_motorcar.icon
nuclear_recipe.icon_size = nuclear_motorcar.icon_size

---@type Prototype_Technology
local base_technology = {
  type = "technology",
  name = shared.base_motorcar,
  prerequisites = { "railway", "solar-panel-equipment" },
  effects = {
    {
      type = "unlock-recipe",
      recipe = shared.base_motorcar
    }
  },
  unit = {
    count = 50,
    ingredients = {
      { "automation-science-pack", 1 },
      { "logistic-science-pack", 1 },
      { "chemical-science-pack", 1 },
    },
    time = 30,
  },
  icon = base_motorcar.icon,
  icon_size = base_motorcar.icon_size,
  order = "g-h-a"
}

local nuclear_technology = table.deepcopy(base_technology)
nuclear_technology.name = shared.nuclear_motorcar
nuclear_technology.effects[1].recipe = shared.nuclear_motorcar
nuclear_technology.icon = nuclear_motorcar.icon
nuclear_technology.icon_size = nuclear_motorcar.icon_size
nuclear_technology.prerequisites = {shared.base_motorcar, "kovarex-enrichment-process" }

---@type Prototype_CustomInput
local key = {
  type = "custom-input",
  name = shared.key,
  localised_name = "Toggle Railway Motor Car",
  linked_game_control = "toggle-driving",
  key_sequence = ""
}

---@type Prototype_CustomInput
local rotate = {
  type = "custom-input",
  name = shared.rotate,
  localised_name = "Rotate Railway Motor Car",
  linked_game_control = "rotate",
  key_sequence = ""
}

---@type Prototype_CustomInput
local home = {
  type = "custom-input",
  name = shared.home,
  localised_name = "Go Home",
  localised_description = "Send the train to the Home station configured in player mod settings.",
  -- linked_game_control = "",
  key_sequence = "H"
}

---@type Prototype_CustomInput
local home_return = {
  type = "custom-input",
  name = shared.home_return,
  localised_name = "Return to previous location",
  localised_description = "Send the train to the location where it last traveled to home from.",
  -- linked_game_control = "",
  key_sequence = "SHIFT + H"
}

data:extend {
  base_equipment, nuclear_equipment,
  base_item, nuclear_item,
  base_recipe, nuclear_recipe,
  base_technology, nuclear_technology,
  key, rotate, home, home_return
}

if not mods["informatron"] then
  ---@type Prototype_TipsAndTricksItem
  local tips_and_tricks = {
    type = "tips-and-tricks-item",
    name = shared.name,
    tag = "[item=railway-motor-car-base]",
    trigger = {
      type = "research",
      technology = shared.base_motorcar
    }
  }
  data:extend {tips_and_tricks}
end
