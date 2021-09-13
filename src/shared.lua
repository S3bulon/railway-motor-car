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