function printTable(desc, table, indent)
  if not table then
    return
  end

  indent = indent or ''

  if game then
    game.print(indent .. desc .. ':')
  else
    log(indent .. desc .. ':')
  end

  for key, value in pairs(table) do
    if type(value) == 'table' then
      printTable(key, value, indent .. '  ')
    else
      if game then
        game.print(indent .. '  ' .. tostring(key) .. ': ' .. tostring(value))
      else
        log(indent .. '  ' .. tostring(key) .. ': ' .. tostring(value))
      end
    end
  end
end

local data = {}

data.equipment = 'railway-motor-car-equipment'
data.motorcar = 'railway-motor-car-train'
data.corpse = 'railway-motor-car-corpse'
data.nuclear_equipment = 'railway-motor-car-nuclear-equipment'
data.nuclear_motorcar = 'railway-motor-car-nuclear-train'
data.map = {}
data.map[data.equipment] = data.motorcar
data.map[data.nuclear_equipment] = data.nuclear_motorcar


data.key = 'railway-motor-car-key'
data.rotate = 'railway-motor-car-rotate'

data.root = '__railway-motor-car__'

return data