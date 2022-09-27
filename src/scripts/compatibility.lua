local compatibility = {}

-- check if mounting is allowed
--- @param player LuaPlayer
function compatibility.can_mount(player)

  -- jetpack: cannot mount if jetpack is in use (only actual flying)
  local jetpacks = remote.interfaces["jetpack"] and remote.call("jetpack", "get_jetpacks", {surface_index=player.surface.index})
  if jetpacks and jetpacks[player.character.unit_number] and jetpacks[player.character.unit_number].status == "flying" then
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

-- ignore tick-check (which removes unused motor cars)
--- @param player LuaPlayer
function compatibility.ignore_tick(player)
  -- SE: nav-view removes the character - do not remove the motorcar
  if remote.interfaces["space-exploration"] and remote.call("space-exploration", "remote_view_is_active", {player=player}) then
    return true
  end

  return false
end

return compatibility