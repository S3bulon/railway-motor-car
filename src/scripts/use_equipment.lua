local utils = require("global-utils")
local compatibility = require("scripts.compatibility")

local function init()
  storage.data = storage.data or {}
  storage.schedules = storage.schedules or {}
  storage.return_schedule = storage.return_schedule or {}
end

local function config_changed()
  init()

  -- load additional trains added by compatibility.lua
  for _, force in pairs(game.forces) do
    force.reset_technology_effects()
  end
end

script.on_init(init)
script.on_configuration_changed(config_changed)

--- checks if the player has the equipment equipped
---@param player LuaPlayer
local function hasEquipment(player)
  local inventory = player.character.get_inventory(defines.inventory.character_armor)
  ---@type LuaItemStack
  local armor = not inventory.is_empty() and inventory[1] or nil

  ---@type LuaEquipment[]
  local equipments = armor and armor.grid and armor.grid.equipment or {}
  for _, equipment in pairs(equipments) do
    if shared.is_a_motorcar(equipment.name) and equipment.valid then
      if not storage.data[player.index] then
        storage.data[player.index] = {}
      end

      storage.data[player.index].armor = armor
      storage.data[player.index].equipment = equipment
      return true
    end
  end
  return false
end

--- check if the player is standing on top of a rail
---@param player LuaPlayer
local function at_rail(player)
  local res = player.physical_surface.find_entities_filtered({
    position = player.position,
    radius = 3,
    type = compatibility.rails()
  })
  return table_size(res) > 0
end

--- leave the vehicle
---@param player LuaPlayer
local function unmount(player)
  -- request unmount, and wait for base-mod
  storage.data[player.index].unmount = player.position
end

--- cleanup the given schedule by removing invalid entities (or from other surfaces)
---@param entity LuaEntity
---@param schedule TrainSchedule
local function cleanup_schedule(entity, schedule, keep_temporary)
  if not schedule then
    return nil
  end

  for i, record in pairs(schedule.records) do
    if record.rail and not (record.rail.valid and record.rail.surface == entity.surface) or (record.temporary and not keep_temporary) then
      table.remove(schedule.records, i)
    end
  end

  return table_size(schedule.records) > 0 and schedule or nil
end

--- check if any vehicle is close to the player
---@param player LuaPlayer
---@param position Position
---@param check_driveable boolean check if the vehicles allow passengers
local function is_vehicle_nearby(player, position, check_driveable)
  -- using a smaller radius for checking all vehicles (when using set_driver instead of normal entering in #mount) - thanks to Kocou/XyuNaBlude
  local radius = check_driveable and 5 or 3.6
  local vehicles = player.physical_surface.find_entities_filtered({type = {"spider-vehicle", "car", "locomotive"}, position = position, radius = radius})

  for _, entity in pairs(vehicles) do
    if not shared.is_a_motorcar(entity.name) and (not check_driveable or entity.prototype.allow_passengers) then
      return true
    end
  end
  return false
end

--- enter the vehicle
---@param player LuaPlayer
local function mount(player)
  local position = player.position
  local direction = player.character.direction
  -- teleport character to any position to make space for creating the entity
  local pos = player.physical_surface.find_non_colliding_position("character", position, 100, 10)
  if not pos then
    player.create_local_flying_text({ text = { "flying-text."..shared.name.."-can-not-spawn" }, position = player.position })
    return
  end
  player.teleport(pos)

  ---@type LuaEntity
  local motorcar = player.physical_surface.create_entity {
    name = storage.data[player.index].equipment.name,
    quality = storage.data[player.index].equipment.quality,
    position = position,
    force = player.force,
    direction = direction,
  }

  if motorcar then

    -- teleport close to position of the motorcar to allow entering (see below)
    pos = player.physical_surface.find_non_colliding_position("character", motorcar.position, 10, 0.1)
    if not pos then
      motorcar.destroy()
      player.teleport(position)
      player.create_local_flying_text({ text = { "flying-text."..shared.name.."-can-not-spawn" }, position = player.position })
      return
    end
    player.teleport(pos)

    motorcar.color = player.color

    storage.data[player.index].motorcar = motorcar
    storage.data[player.index].mount = true

    -- load schedule, if needed
    if player.mod_settings[shared.keep_schedule].value and storage.schedules[player.index] then
      motorcar.train.schedule = cleanup_schedule(motorcar, storage.schedules[player.index], player.mod_settings[shared.keep_temporary].value)
    end

    -- Factorio 1.1.87 executes a "toggle-driving"-event if any vehicle is nearby (even if it does not allow passengers), thus the driver must be set by the base-mod
    -- otherwise the driver must be set manually
    -- see https://forums.factorio.com/108553
    if not is_vehicle_nearby(player, position,false) then
      motorcar.set_driver(player.character)
    end
  else
    player.teleport(position)
  end
end

-- check if mounting is allowed
--- @param player LuaPlayer
local function can_mount(player)
  -- any driveable vehicle is standing on top of the rails - enter it instead of the train
  if is_vehicle_nearby(player, player.position, true) then
    return false
  end

  return compatibility.can_mount(player)
end

--- Save return path when travelling home
---@param player LuaPlayer
local function save_return(player)
  local motorcar = storage.data[player.index] and storage.data[player.index].motorcar

  if motorcar and motorcar.valid then

    local rails = player.physical_surface.find_entities_filtered({
      position = motorcar.position,
      radius = 3,
      type = compatibility.rails()
    })

    local return_rail = rails[1]

    if return_rail then
      storage.return_schedule[player.index] = {
        current = 1,
        records = {
          {
            rail = return_rail,
            temporary = true
          }
        }
      }
    end
  end
end

-- "enter vehicle"-button
script.on_event(shared.key, function(event)
  local player = game.get_player(event.player_index)
  if player.character then
    if player.physical_vehicle and storage.data[event.player_index] and storage.data[event.player_index].motorcar then
      -- unmount (also allowed if equipment is unequipped)
      unmount(player)

    elseif not player.physical_vehicle and at_rail(player) and hasEquipment(player) and storage.data[player.index].equipment.energy > 0 then
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
  local data = storage.data[player.index]

  -- manual unmounting: remove motorcar
  if data and data.unmount then
    -- only if the player is not driving anymore
    if data.motorcar and not player.physical_vehicle then
      -- store schedule, if needed
      if player.mod_settings[shared.keep_schedule].value and not data.do_not_store_schedule then
        storage.schedules[player.index] = data.motorcar.train.schedule
        -- todo: interrupts cannot be stored?
      end

      data.motorcar.destroy()
      -- move character to close place as before (not the same in case the player uses e.g. elevated rails)
      local new_pos = player.physical_surface.find_non_colliding_position("character", data.unmount, 10, 0.1)
      player.character.teleport(new_pos)
      storage.data[player.index] = nil
    else
      -- otherwise: invalid -> reset
      data.unmount = nil
    end

  -- manual mounting: check motorcar
  elseif data and data.mount then
    -- mounted another entity (e.g. a spidertron standing on top of the rail) -> destroy created motorcar
    if not player.physical_vehicle or not shared.is_a_motorcar(player.vehicle.name) or not data.motorcar.get_driver() then
      data.motorcar.destroy()
      storage.data[player.index] = nil
    end

    data.mount = nil -- check done

  -- driving state changed by other mods: is not valid or has no driver
  elseif data and data.motorcar and (not data.motorcar.valid or not data.motorcar.get_driver()) then
    -- may have been swapped - replace
    if player.physical_vehicle and shared.is_a_motorcar(player.vehicle.name) then
      data.motorcar = player.vehicle
    else
      -- any other change: cleanup (other mods should clean their entities themselves)
      storage.data[player.index] = nil

      -- There is a small chance that this mod creates a motorcar which cannot be mounted. And since it is unlinked, it will not be deleted.
      -- But the player can enter the vehicle and link it.
    end

  -- mounting an unused motor car (possibly copied by other mods) -> link it
  elseif event.entity and shared.is_a_motorcar(event.entity.name) then
    if hasEquipment(player) then
      event.entity.color = player.color
      storage.data[player.index].motorcar = event.entity
    else
      -- cannot mount it -> destroy it
      -- possible issue: equipment removed while copying (e.g. jumping in renai transportation) may cause an error. but it is unlikely
      player.driving = false
      event.entity.destroy()
      player.create_local_flying_text({ text = { "flying-text."..shared.name.."-missing-equipment" }, position = player.position })
    end
  end
end)

-- pressing "rotate" while in motorcar without selection -> rotate motorcar
script.on_event(shared.rotate, function(event)
  local player = game.get_player(event.player_index)
  if not player.selected then
    ---@type LuaEntity
    local motorcar = storage.data[player.index] and storage.data[player.index].motorcar
    if motorcar and motorcar.valid then
      motorcar.rotate()
    end
  end
end)

-- pressing "H" while in motorcar will send the motorcar to the players "Home" station
script.on_event(shared.home, function(event)
  local player = game.get_player(event.player_index)
  ---@type LuaEntity
  local motorcar = storage.data[player.index] and storage.data[player.index].motorcar

  if motorcar and motorcar.valid then
    local home_config = player.mod_settings[shared.home].value
    local home_station = nil
    local had_matches = false

    -- Try to find the home station for the players surface (do not use "=" b/c icons are saved like this: "[item=iron-plate] Smelting")
    for surface, station in string.gmatch(home_config, "(%w+):([^,]+)") do
      had_matches = true -- if we iterated at least once, then we had a fancy config.
      if string.lower(surface) == string.lower(player.surface.name) then
        home_station = station
        break
      end
    end

    -- If we never iterated over the config, we expect it to be a station name
    if not had_matches then
      home_station = home_config
    end

    -- Give up with a warning if no home station was found
    if not home_station or home_station == '' then
      if not had_matches then
        player.create_local_flying_text({ text = { "flying-text."..shared.name.."-no-home" }, position = player.position })
      else
        player.create_local_flying_text({
          text = { "flying-text." .. shared.name .. "-no-home-surface", player.physical_surface.name:gsub("^%l", string.upper) },
          position = player.position
        })
      end
      return
    end

    -- check existing home station
    local home = game.train_manager.get_train_stops({
      station_name = home_station,
      surface = player.physical_surface,
      force = player.force
    })[1]

    if not home then
      player.create_local_flying_text({ text = { "flying-text."..shared.name.."-no-home-found", home_station }, position = player.position })
      return
    end

    -- already at home: do not return (and do not overwrite return position)
    if utils.table_contains(player.physical_surface.find_entities_filtered({
      position = motorcar.position,
      radius = 10,
      name = home.name
    }), home) then
      player.create_local_flying_text({ text = { "flying-text."..shared.name.."-already-at-home", home_station }, position = player.position })
      return
    end

    save_return(player)

    -- Replace train schedule with the found home station and switch the train to automatic to get going!
    player.create_local_flying_text({ text = { "flying-text."..shared.name.."-going-home", home_station }, position = player.position })
    motorcar.train.schedule = {
      current = 1,
      records = {
        {
          station = home_station,
          temporary = true
        }
      }
    }
    motorcar.train.manual_mode = false

    -- do not overwrite stored schedule!
    storage.data[player.index].do_not_store_schedule = true
  end
end)

-- pressing "shift+H" while in motorcar will send the motorcar back to where the player went home from
script.on_event(shared.home_return, function(event)
  local player = game.get_player(event.player_index)
  ---@type LuaEntity
  local motorcar = storage.data[player.index] and storage.data[player.index].motorcar
  local return_schedule = storage.return_schedule[player.index]

  if motorcar and motorcar.valid then
    local return_rail = return_schedule and return_schedule.records[1].rail
    if return_rail and return_rail.valid and return_rail.surface == player.physical_surface then
      -- Replace train schedule with the stored return_schedule and switch the train to automatic to get going!
      player.create_local_flying_text({
        text = { "flying-text." .. shared.name .. "-returning" },
        position = player.position
      })
      motorcar.train.schedule = return_schedule
      motorcar.train.manual_mode = false

      -- do not overwrite stored schedule!
      storage.data[player.index].do_not_store_schedule = true
    else
      player.create_local_flying_text({ color = { 1, 1, 0 },
        text = { "flying-text." .. shared.name .. "-no-return" }, position = player.position })
    end

    storage.return_schedule[player.index] = nil
  end
end)

-- checking if equipment is still valid and has enough power
script.on_nth_tick(30, function(event)
  ---@param player LuaPlayer
  for _, player in pairs(game.players) do
    -- check only needed if in use
    local invalid = storage.data[player.index] and storage.data[player.index].motorcar

    -- may ignore check for compatibility
    invalid = invalid and not compatibility.ignore_tick(player)

    -- check only if equipped
    if invalid and
      player.character and player.physical_vehicle and
      storage.data[player.index].motorcar.valid and
      hasEquipment(player)
    then
      -- drain energy: half of the input flow limit (per tick) is the drain -> subtract it
      ---@type LuaEquipment
      local equipment = storage.data[player.index].equipment;
      if equipment.energy > 0 then
        equipment.energy = math.max(equipment.energy - equipment.prototype.energy_source.get_input_flow_limit() * 30 / 2, 0)
      end
      invalid = equipment.energy == 0
    end

    if invalid then
      -- player is still active and driving -> unmount
      if player.character and player.physical_vehicle then
        if storage.data[player.index].equipment and storage.data[player.index].equipment.valid and storage.data[player.index].equipment.energy == 0 then
          player.create_local_flying_text({ text = { "flying-text."..shared.name.."-no-power" }, position = player.position })
        else
          player.create_local_flying_text({ text = { "flying-text."..shared.name.."-missing-equipment" }, position = player.position })
        end
        unmount(player)
        player.driving = false
      elseif not storage.data[player.index].motorcar.valid then
        -- invalid by any unknown cause -> simply remove link
        storage.data[player.index] = nil
      else
        -- otherwise: remove locomotive and clear data (if the player is still active and not driving, he could not enter -> show hint)
        if player.character then
          player.create_local_flying_text({ text = { "flying-text."..shared.name.."-could-not-enter" }, position = storage.data[player.index].motorcar.position })
        end
        storage.data[player.index].motorcar.destroy()
        storage.data[player.index] = nil
      end
    end
  end
end)
