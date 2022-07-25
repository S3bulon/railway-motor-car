local compatibility = {}

function compatibility.ignore_vehicle(name)
  -- RT: ignore dummy for jumping
  if game.active_mods["RenaiTransportation"] and name == "RTPropCar" then
    return true
  end

  return false
end

-- check if mounting is allowed
--- @param player LuaPlayer
function compatibility.can_mount(player)

  -- jetpack: cannot mount if jetpack is in use
  local jetpacks = remote.interfaces["jetpack"] and remote.call("jetpack", "get_jetpacks", {surface_index=player.surface.index})
  if jetpacks and jetpacks[player.character.unit_number] then
    player.create_local_flying_text({ text = { "flying-text."..shared.name.."-jetpack-in-use" }, position = player.position })
    return false
  end

  -- train tunnels: cannot mount b/c <enter vehicle> is used for changing surfaces
  if game.active_mods["traintunnels"] and table_size(player.surface.find_entities_filtered({
    position = player.position,
    radius = 10, -- large radius
    name = { "traintunnel", "traintunnelup", "traintunneldown" }
  })) > 0 then
    return false
  end

  return true
end

return compatibility