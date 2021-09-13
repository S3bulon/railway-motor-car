function init()
  global.data = global.data or {}
end

script.on_init(init)
script.on_configuration_changed(init)

--- checks if the player has the equipment equipped
---@param player LuaPlayer
function hasEquipment(player)
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
function at_rail(player)
  local res = player.surface.find_entities_filtered({
    position = player.position,
    radius = 3,
    type = { 'straight-rail', 'curved-rail' }
  })
  return table_size(res) > 0
end

--- leave the vehicle
---@param player LuaPlayer
function unmount(player)
  -- request unmount, and wait for base-mod
  global.data[player.index].unmount = player.position
end

--- enter the vehicle
---@param player LuaPlayer
function mount(player)
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

-- 'enter vehicle'-button
script.on_event(shared.key, function(event)
  local player = game.get_player(event.player_index)
  if player.character then
    if player.driving and global.data[event.player_index] and global.data[event.player_index].motorcar then
      -- unmount (also allowed if equipment is unequipped)
      unmount(player)

    elseif not player.driving and at_rail(player) and hasEquipment(player) and global.data[player.index].equipment.energy > 0 then
      -- mount (only allowed if equipment is equipped and player is standing on top of a rail)
      local jetpacks = remote.interfaces["jetpack"] and remote.call("jetpack", "get_jetpacks", {surface_index=player.surface.index})
      if jetpacks and jetpacks[player.character.unit_number] then
        -- also cannot mount if jetpack is in use
        player.create_local_flying_text({ text = { 'flying-text.jetpack-in-use' }, position = player.position })
      else
        mount(player)
      end
    end
  end
end)

-- event for entering or leaving a vehicle (via base-mod)
script.on_event(defines.events.on_player_driving_changed_state, function(event)
  local player = game.get_player(event.player_index)
  -- remove motorcar if unmounting was requested
  if global.data[player.index] and global.data[player.index].unmount and global.data[player.index].motorcar then
    global.data[player.index].motorcar.destroy()
    -- move character to exact place as before
    player.character.teleport(global.data[player.index].unmount)
    global.data[player.index] = nil

  -- mounted another entity (e.g. a spidertron standing on top of the rail) -> destroy created motorcar
  elseif global.data[player.index] and global.data[player.index].motorcar and not global.data[player.index].motorcar.get_driver() then
    global.data[player.index].motorcar.destroy()
    global.data[player.index] = nil
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

-- checking if equipment is still valid and has power
script.on_nth_tick(60, function(event)
  ---@param player LuaPlayer
  for _, player in pairs(game.players) do
    if global.data[player.index] and global.data[player.index].motorcar and not (
      player.character and player.driving and
        global.data[player.index].motorcar.valid and
        hasEquipment(player) and global.data[player.index].equipment.energy > 0
    ) then
      -- player is still active and driving -> unmount
      if player.character and player.driving then
        if global.data[player.index].equipment and global.data[player.index].equipment.valid and global.data[player.index].equipment.energy == 0 then
          player.create_local_flying_text({ text = { 'flying-text.no-power' }, position = player.position })
        else
          player.create_local_flying_text({ text = { 'flying-text.missing-equipment' }, position = player.position })
        end
        unmount(player)
        player.driving = false
      else
        -- otherwise: remove locomotive and clear data (if the player is still active and not driving, he could not enter -> show hint)
        if player.character then
          player.create_local_flying_text({ text = { 'flying-text.could-not-enter' }, position = global.data[player.index].motorcar.position })
        end
        global.data[player.index].motorcar.destroy()
        global.data[player.index] = nil
      end
    end
  end
end)
