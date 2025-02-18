local utils = require "utils"

---@type Prototype_Locomotive
local base_motorcar = utils.create_entity("locomotive", shared.base_motorcar, false)
base_motorcar.icons[1].icon = shared.root .. "/graphics/equipment/motorcar.png"

---@type Prototype_Locomotive
local nuclear_motorcar = utils.create_entity("locomotive", shared.nuclear_motorcar, true)
nuclear_motorcar.icons[1].icon = shared.root .. "/graphics/equipment/nuclear_motorcar.png"

---@type Prototype_Corpse
local corpse = table.deepcopy(data.raw["corpse"]["locomotive-remnants"])
corpse.name = shared.corpse

for _, layer in pairs(corpse.animation.layers) do
  utils.scale(layer)
end

data:extend {base_motorcar, nuclear_motorcar, corpse}