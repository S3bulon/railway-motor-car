local utils = require("global-utils")

function utils.scale(layer, shiftX, shiftY)
  if not layer then
    return

  elseif layer.rotated then
    utils.scale(layer.rotated, shiftX, shiftY)
    utils.scale(layer.sloped, shiftX, shiftY)
    return

  elseif layer.layers then
    for _, l in pairs(layer.layers) do
      utils.scale(l, shiftX, shiftY)
    end
    return
  end

  layer.scale = (layer.scale or 1) * 0.5

  layer.shift = layer.shift or {0, 0}
  layer.shift = {layer.shift[1] * 0.5, layer.shift[2] * 0.5}
  if shiftX and shiftY then
    layer.shift = {layer.shift[1] + shiftX, layer.shift[2] + shiftY}
  end

  if layer.hr_version then
    layer.hr_version.scale = (layer.hr_version.scale or 1) * 0.5

    layer.hr_version.shift = layer.hr_version.shift or {0, 0}
    layer.hr_version.shift = {layer.hr_version.shift[1] * 0.5, layer.hr_version.shift[2] * 0.5}
    if shiftX and shiftY then
      layer.hr_version.shift = {layer.hr_version.shift[1] + shiftX, layer.hr_version.shift[2] + shiftY}
    end
  end
end

function utils.create_entity(prototype_name, name, nuclear)
  ---@type Prototype_Locomotive
  local motorcar = table.deepcopy(data.raw["locomotive"][prototype_name])

  motorcar.name = name
  motorcar.corpse = shared.corpse

  motorcar.order = "g-h-a[" .. name .. "]"
  motorcar.subgroup = "equipment"
  -- todo factoriopedia simulation

  -- cannot be mined or deconstructed
  motorcar.minable = nil
  motorcar.flags = {"player-creation", "placeable-off-grid", "not-blueprintable", "not-deconstructable"}
  -- smaller with less power, but faster braking
  motorcar.max_health = 100
  motorcar.weight = 300

  if not nuclear then
    -- base has less power
    motorcar.max_power = "560kW"
  elseif motorcar.max_speed < 7 then
    -- nuclear has more power and increased max speed (using modifier of nuclear fuel)
    motorcar.max_power = "1000kW"
    motorcar.max_speed = motorcar.max_speed * 1.15
  else
    -- nuclear and really fast (modded) trains have even more power
    motorcar.max_power = "2000kW"
  end
  motorcar.friction_force = 0.1
  -- decrease braking force to prevent gate crashes
  motorcar.braking_force = 6
  -- no power source (use equipment)
  motorcar.energy_source = {type = "void"}

  -- todo: use quality to increase speed

  -- smaller version of the train
  --motorcar.collision_box = { { -0.3, -1.3 }, { 0.3, 1.3 } }
  motorcar.collision_box = {{-0.6, -2.1}, {0.6, 2.1}}
  motorcar.selection_box = {{-1, -2}, {1, 2}}
  motorcar.drawing_box = {{-1, -3}, {1, 2}}
  motorcar.joint_distance = 2
  motorcar.vertical_selection_shift = -0.25

  utils.scale(motorcar.pictures, 0, 0.2)
  utils.scale(motorcar.wheels, 0, 0.35)

  for _, layer in pairs(motorcar.front_light or {}) do
    utils.scale(layer, 0, -6.0)
  end

  utils.scale(motorcar.front_light_pictures, 0, 0.2)

  for _, layer in pairs(motorcar.back_light or {}) do
    utils.scale(layer, 0, 0.2)
  end

  for _, layer in pairs(motorcar.stand_by_light or {}) do
    utils.scale(layer, 0, 0.2)
  end

  utils.scale(motorcar.water_reflection and motorcar.water_reflection.pictures, 0, 0.8)

  for _, trigger in pairs(motorcar.stop_trigger or {}) do
    if trigger.offset_deviation then
      trigger.offset_deviation = {
        {trigger.offset_deviation[1][1] * 0.5, trigger.offset_deviation[1][2] * 0.5},
        {trigger.offset_deviation[2][1] * 0.5, trigger.offset_deviation[2][2] * 0.5}
      }
    end
  end

  return motorcar
end

function utils.create_equipment(name, nuclear)
  local motorcar = data.raw["locomotive"][name]

  ---@type Prototype_BatteryEquipment
  local equipment = table.deepcopy(data.raw["battery-equipment"]["battery-equipment"])

  equipment.name = name

  if motorcar.icons then
    equipment.sprite.filename = motorcar.icons[1].icon
    equipment.sprite.width = motorcar.icons[1].icon_size
    equipment.sprite.height = motorcar.icons[1].icon_size
  else
    equipment.sprite.filename = motorcar.icon
    equipment.sprite.size = motorcar.icon_size or 64 -- icons may have no size anymore -> use 64 which is the default icon size
    equipment.sprite.scale = 1
  end
  equipment.sprite.hr_version = nil
  equipment.shape.width = 2
  equipment.shape.height = 2
  equipment.energy_source = {
    type = "electric",
    buffer_capacity = "2MJ",
    usage_priority = "secondary-input",
  }
  equipment.take_result = name
  equipment.order = motorcar.order

  if nuclear then
    equipment.energy_source.input_flow_limit = "600kW"
  else
    equipment.energy_source.input_flow_limit = "400kW"
  end

  return equipment
end

function utils.create_item(name)
  local motorcar = data.raw["locomotive"][name]

  ---@type Prototype_Item
  local item = table.deepcopy(data.raw["item"]["battery-equipment"])

  item.name = name
  item.localised_name = {"item-name." .. name} -- this is somehow equipment-name.battery-equipment, not item-name...??
  item.icon = motorcar.icon
  item.icons = motorcar.icons
  item.icon_size = motorcar.icon_size
  item.place_as_equipment_result = name
  item.order = motorcar.order

  return item
end

return utils
