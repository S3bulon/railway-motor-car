---@type Prototype_BatteryEquipment
local equipment = table.deepcopy(data.raw['battery-equipment']['battery-equipment'])

equipment.name = shared.equipment
equipment.sprite.filename = motorcar.icon
equipment.sprite.width = motorcar.icon_size
equipment.sprite.height = motorcar.icon_size
equipment.sprite.hr_version = nil
equipment.shape.width = 2
equipment.shape.height = 2
equipment.energy_source = {
  type = 'electric',
  input_flow_limit = '400kW',
  buffer_capacity = '2MJ',
  usage_priority = 'secondary-input',
}
equipment.take_result = shared.equipment
equipment.order = 'g-h-a'

-- printTable('equipment', equipment)

---@type Prototype_BatteryEquipment
local nuclear_equipment = table.deepcopy(equipment)
nuclear_equipment.name = shared.nuclear_equipment
nuclear_equipment.sprite.filename = nuclear_motorcar.icon
nuclear_equipment.sprite.width = nuclear_motorcar.icon_size
nuclear_equipment.sprite.height = nuclear_motorcar.icon_size
nuclear_equipment.energy_source.input_flow_limit = '600kW'
nuclear_equipment.take_result = shared.nuclear_equipment

---@type Prototype_Item
local item = table.deepcopy(data.raw['item']['battery-equipment'])

item.name = shared.equipment
item.icon = motorcar.icon
item.icon_size = motorcar.icon_size
item.placed_as_equipment_result = shared.equipment
item.order = 'g-h-a'

local nuclear_item = table.deepcopy(item)

nuclear_item.name = shared.nuclear_equipment
nuclear_item.icon = nuclear_motorcar.icon
nuclear_item.icon_size = nuclear_motorcar.icon_size
nuclear_item.placed_as_equipment_result = shared.nuclear_equipment

---@type Prototype_Recipe
local recipe = {
  type = 'recipe',
  name = shared.equipment,
  normal = {
    enabled = false,
    ingredients = {
      { 'electric-engine-unit', 20 },
      { 'steel-plate', 30 },
      { 'advanced-circuit', 10 },
    },
    result = shared.equipment,
    energy_consumption = 4,
  },
  icon = motorcar.icon,
  icon_size = motorcar.icon_size,
  order = 'g-h-a'
}

local nuclear_recipe = table.deepcopy(recipe)
nuclear_recipe.name = shared.nuclear_equipment
nuclear_recipe.normal.ingredients = {
  { 'electric-engine-unit', 20 },
  { 'steel-plate', 30 },
  { 'advanced-circuit', 10 },
  { 'nuclear-fuel', 5 }
}
nuclear_recipe.normal.result = shared.nuclear_equipment
nuclear_recipe.icon = nuclear_motorcar.icon
nuclear_recipe.icon_size = nuclear_motorcar.icon_size

---@type Prototype_Technology
local technology = {
  type = 'technology',
  name = shared.equipment,
  prerequisites = { 'railway', 'solar-panel-equipment' },
  effects = {
    {
      type = 'unlock-recipe',
      recipe = shared.equipment
    }
  },
  unit = {
    count = 50,
    ingredients = {
      { 'automation-science-pack', 1 },
      { 'logistic-science-pack', 1 },
      { 'chemical-science-pack', 1 },
    },
    time = 30,
  },
  icon = motorcar.icon,
  icon_size = motorcar.icon_size,
  order = 'g-h-a'
}

local nuclear_technology = table.deepcopy(technology)
nuclear_technology.name = shared.nuclear_equipment
nuclear_technology.effects[1].recipe = shared.nuclear_equipment
nuclear_technology.icon = nuclear_motorcar.icon
nuclear_technology.icon_size = nuclear_motorcar.icon_size
nuclear_technology.prerequisites = { shared.equipment, 'kovarex-enrichment-process' }

---@type Prototype_CustomInput
local key = {
  type = 'custom-input',
  name = shared.key,
  localised_name = 'Toggle Railway Motor Car',
  linked_game_control = 'toggle-driving',
  key_sequence = ''
}

---@type Prototype_CustomInput
local rotate = {
  type = 'custom-input',
  name = shared.rotate,
  localised_name = 'Rotate Railway Motor Car',
  linked_game_control = 'rotate',
  key_sequence = ''
}

data:extend {
  equipment, nuclear_equipment,
  item, nuclear_item,
  recipe, nuclear_recipe,
  technology, nuclear_technology,
  key, rotate
}

if not mods["informatron"] then
  ---@type Prototype_TipsAndTricksItem
  local tips_and_tricks = {
    type = 'tips-and-tricks-item',
    name = shared.name,
    tag = '[item=railway-motor-car-equipment]',
    trigger = {
      type = 'research',
      technology = shared.equipment
    }
  }
  data:extend {tips_and_tricks}
end
