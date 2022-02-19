local function scale(layer, shiftX, shiftY)
  layer.scale = (layer.scale or 1) * 0.5

  layer.shift = layer.shift or { 0, 0 }
  layer.shift = { layer.shift[1] * 0.5, layer.shift[2] * 0.5 }
  if shiftX and shiftY then
    layer.shift = { layer.shift[1] + shiftX, layer.shift[2] + shiftY }
  end

  if layer.hr_version then
    layer.hr_version.scale = (layer.hr_version.scale or 1) * 0.5

    layer.hr_version.shift = layer.hr_version.shift or { 0, 0 }
    layer.hr_version.shift = { layer.hr_version.shift[1] * 0.5, layer.hr_version.shift[2] * 0.5 }
    if shiftX and shiftY then
      layer.hr_version.shift = { layer.hr_version.shift[1] + shiftX, layer.hr_version.shift[2] + shiftY }
    end
  end
end

---@type Prototype_Locomotive
motorcar = table.deepcopy(data.raw["locomotive"]["locomotive"])

motorcar.name = shared.motorcar
motorcar.corpse = shared.corpse

-- cannot be mined or deconstructed
motorcar.minable = nil
motorcar.flags = {"player-creation", "placeable-off-grid", "not-blueprintable", "not-deconstructable"}
-- player default color
motorcar.icon = shared.root..'/graphics/equipment/motorcar.png'
-- smaller with less power, but faster braking
motorcar.max_health = 100
motorcar.weight = 300
motorcar.max_power = '560kW'
motorcar.friction_force = 0.1
-- no power source (use equipment)
motorcar.energy_source = { type = "void" }

-- smaller version of the train
--motorcar.collision_box = { { -0.3, -1.3 }, { 0.3, 1.3 } }
motorcar.collision_box = { { -1.2, -2.1 }, { 1.2, 2.1 } }
motorcar.selection_box = { { -1, -2 }, { 1, 2 } }
motorcar.drawing_box = { { -1, -3 }, { 1, 2 } }
motorcar.joint_distance = 2
motorcar.vertical_selection_shift = -0.25

for _, layer in pairs(motorcar.pictures.layers) do
  scale(layer, 0, 0.2)
end

scale(motorcar.wheels, 0, 0.35)

for _, layer in pairs(motorcar.front_light) do
  scale(layer, 0, -6.0)
end

for _, layer in pairs(motorcar.front_light_pictures.layers) do
  scale(layer, 0, 0.2)
end

for _, layer in pairs(motorcar.back_light) do
  scale(layer, 0, 0.2)
end

scale(motorcar.water_reflection.pictures, 0, 0.8)

for _, trigger in pairs(motorcar.stop_trigger) do
  if trigger.offset_deviation then
    trigger.offset_deviation = {
      {trigger.offset_deviation[1][1] * 0.5, trigger.offset_deviation[1][2] * 0.5},
      {trigger.offset_deviation[2][1] * 0.5, trigger.offset_deviation[2][2] * 0.5}
    }
  end
end

-- printTable("motorcar", motorcar)

---@type Prototype_Locomotive
nuclear_motorcar = table.deepcopy(motorcar)
nuclear_motorcar.name = shared.nuclear_motorcar

-- other icon
nuclear_motorcar.icon = shared.root..'/graphics/equipment/nuclear_motorcar.png'
-- more power than motorcar
nuclear_motorcar.max_power = '1000kW'
-- default max speed increased by nuclear-fuel
nuclear_motorcar.max_speed = nuclear_motorcar.max_speed * 1.15

---@type Prototype_Corpse
local corpse = table.deepcopy(data.raw["corpse"]["locomotive-remnants"])
corpse.name = shared.corpse

for _, layer in pairs(corpse.animation.layers) do
  scale(layer)
end

data:extend { motorcar, nuclear_motorcar, corpse }