require "debug"

local data = {}

data.name = 'railway-motor-car'
data.equipment = data.name..'-equipment'
data.motorcar = data.name..'-train'
data.corpse = data.name..'-corpse'
data.nuclear_equipment = data.name..'-nuclear-equipment'
data.nuclear_motorcar = data.name..'-nuclear-train'
data.map = {}
data.map[data.equipment] = data.motorcar
data.map[data.nuclear_equipment] = data.nuclear_motorcar


data.key = data.name..'-key'
data.rotate = data.name..'-rotate'

data.root = '__railway-motor-car__'

return data