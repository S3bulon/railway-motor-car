local function init()
  global.data = global.data or {}
end

script.on_init(init)
script.on_configuration_changed(init)

--- checks if the player has the equipment equipped
---@param player LuaPlayer
local function hasEquipment(player)
  local inventory = player.get_inventory(defines.inventory.character_armor)
  ---@type LuaItemStack
  local armor = not inventory.is_empty() and inventory[1] or nil

  ---@type LuaEquipment[]
  local equipments = armor and armor.grid and armor.grid.equipment or {}
  for _, equipment in pairs(equipments) do
    if shared.map[equipment.name] and equipment.valid then
      if not global.data[player.index] then
        global.data[player.index] = {}
      end

      global.data[player.index].armor = armor
      global.data[player.index].equipment = equipment
      return true
    end
  end
  return false
end

--- check if the player is standing on top of a rail
---@param player LuaPlayer
local function at_rail(player)
  local res = player.surface.find_entities_filtered({
    position = player.position,
    radius = 3,
    type = { 'straight-rail', 'curved-rail' }
  })
  return table_size(res) > 0
end

--- leave the vehicle
---@param player LuaPlayer
local function unmount(player)
  -- request unmount, and wait for base-mod
  global.data[player.index].unmount = player.position
end

--- enter the vehicle
---@param player LuaPlayer
local function mount(player)
  local position = player.position
  local direction = player.character.direction
  -- teleport character to any position to make space for creating the entity
  player.teleport(player.surface.find_non_colliding_position('character', position, 100, 10))

  ---@type LuaEntity
  local motorcar = player.surface.create_entity {
    name = shared.map[global.data[player.index].equipment.name],
    position = position,
    force = player.force,
    direction = direction,
  }

  if motorcar then
    motorcar.color = player.color
    -- teleport close to position of the motorcar to allow entering (done in base mod)
    player.teleport(player.surface.find_non_colliding_position('character', motorcar.position, 10, 0.1))

    global.data[player.index].motorcar = motorcar
  else
    player.teleport(position)
  end
end

-- check if mounting is allowed (compatibility for other mods)
local function can_mount(player)
  -- cannot mount if jetpack is in use
  local jetpacks = remote.interfaces["jetpack"] and remote.call("jetpack", "get_jetpacks", {surface_index=player.surface.index})
  if jetpacks and jetpacks[player.character.unit_number] then
    player.create_local_flying_text({ text = { 'flying-text.'..shared.name..'-jetpack-in-use' }, position = player.position })
    return false
  end

  -- train tunnels: cannot mount b/c <enter vehicle> is used for changing surfaces
  if game.active_mods["traintunnels"] and table_size(player.surface.find_entities_filtered({
      position = player.position,
      radius = 10, -- large radius
      name = { 'traintunnel', 'traintunnelup', 'traintunneldown' }
    })) > 0 then
    return false
  end

  return true
end

-- 'enter vehicle'-button
script.on_event(shared.key, function(event)
  local player = game.get_player(event.player_index)
  if player.character then
    if player.driving and global.data[event.player_index] and global.data[event.player_index].motorcar then
      -- unmount (also allowed if equipment is unequipped)
      unmount(player)

    elseif not player.driving and at_rail(player) and hasEquipment(player) and global.data[player.index].equipment.energy > 0 then
      -- mount (only allowed if equipment is equipped and player is standing on top of a rail)
      if can_mount(player) then
        mount(player)
      end
    end
  end
end)

-- event for entering or leaving a vehicle (via base-mod)
script.on_event(defines.events.on_player_driving_changed_state, function(event)
  local player = game.get_player(event.player_index)
  local data = global.data[player.index]
  -- remove motorcar if unmounting was requested (and the player is not driving anymore)
  if data and data.unmount and data.motorcar and not player.driving then
    data.motorcar.destroy()
    -- move character to exact place as before
    player.character.teleport(data.unmount)
    global.data[player.index] = nil

  -- mounted another entity (e.g. a spidertron standing on top of the rail) -> destroy created motorcar
  -- or not valid anymore - may have been swapped - replace
  elseif data and data.motorcar and (not data.motorcar.valid or not data.motorcar.get_driver()) then
    if player.driving and player.vehicle.name == shared.map[data.equipment.name] then
      data.motorcar.destroy()
      data.motorcar = player.vehicle
      data.unmount = nil
    else
      data.motorcar.destroy()
      global.data[player.index] = nil
    end
  end
end)

-- pressing "rotate" while in motorcar without selection -> rotate motorcar
script.on_event(shared.rotate, function(event)
  local player = game.get_player(event.player_index)
  if not player.selected and global.data[player.index] and global.data[player.index].motorcar then
    ---@type LuaEntity
    local motorcar = global.data[player.index].motorcar
    motorcar.rotate()
  end
end)

-- checking if equipment is still valid and has enough power
script.on_nth_tick(30, function(event)
  ---@param player LuaPlayer
  for _, player in pairs(game.players) do
    -- check only needed if in use
    local invalid = global.data[player.index] and global.data[player.index].motorcar

    -- check only if equipped
    if invalid and
      player.character and player.driving and
      global.data[player.index].motorcar.valid and
      hasEquipment(player)
    then
      -- drain energy: half of the input flow limit (per tick) is the drain -> subtract it
      ---@type LuaEquipment
      local equipment = global.data[player.index].equipment;
      if equipment.energy > 0 then
        equipment.energy = math.max(equipment.energy - equipment.prototype.energy_source.input_flow_limit * 30 / 2, 0)
      end
      invalid = equipment.energy == 0
    end

    if invalid then
      -- player is still active and driving -> unmount
      if player.character and player.driving then
        if global.data[player.index].equipment and global.data[player.index].equipment.valid and global.data[player.index].equipment.energy == 0 then
          player.create_local_flying_text({ text = { 'flying-text.'..shared.name..'-no-power' }, position = player.position })
        else
          player.create_local_flying_text({ text = { 'flying-text.'..shared.name..'-missing-equipment' }, position = player.position })
        end
        unmount(player)
        player.driving = false
      else
        -- otherwise: remove locomotive and clear data (if the player is still active and not driving, he could not enter -> show hint)
        if player.character then
          player.create_local_flying_text({ text = { 'flying-text.'..shared.name..'-could-not-enter' }, position = global.data[player.index].motorcar.position })
        end
        global.data[player.index].motorcar.destroy()
        global.data[player.index] = nil
      end
    end
  end
end)
