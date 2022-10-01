require "debug"

local data = {}

data.name = "railway-motor-car"
data.motorcar_prefix = data.name.."-"

data.corpse = data.name.."-corpse"
data.base_motorcar = data.motorcar_prefix .."base"
data.nuclear_motorcar = data.motorcar_prefix .."nuclear"

data.key = data.name.."-key"
data.rotate = data.name.."-rotate"
data.home = data.name.."-home"

data.keep_schedule = data.name.."-keep-schedule"
data.keep_temporary = data.name.."-keep-temporary"

data.root = "__railway-motor-car__"

function data.is_a_motorcar(name)
  return string.find(name, data.motorcar_prefix, 1, true)
end

return data
