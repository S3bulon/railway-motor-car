local compatibility = {}

-- check if mounting is allowed
--- @param player LuaPlayer
function compatibility.can_mount(player)

  -- jetpack: cannot mount if jetpack is in use (only actual flying)
  local jetpacks = remote.interfaces["jetpack"] and remote.call("jetpack", "get_jetpacks", {surface_index=player.surface.index})
  if jetpacks and jetpacks[player.character.unit_number] then
    player.create_local_flying_text({ text = { "flying-text."..shared.name.."-jetpack-in-use" }, position = player.position })
    return false
  end

  -- cargo ships: cannot mount waterways which are rails internally
  if script.active_mods["cargo-ships"] and table_size(player.surface.find_entities_filtered({
    position = player.position,
    radius = 4,
    name = { "straight-waterway", "curved-waterway-a", "curved-waterway-b", "half-diagonal-waterway" }
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

-- return the supported rails to detect entering the motorcar
function compatibility.rails()
  return {
    -- default rails
    "straight-rail", "curved-rail-a", "curved-rail-b", "half-diagonal-rail",
    -- elevated rails
    "elevated-straight-rail", "elevated-curved-rail-a", "elevated-curved-rail-b", "elevated-half-diagonal-rail"
  }
end

return compatibility