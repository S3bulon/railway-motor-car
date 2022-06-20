local compatibility = {}

function compatibility.ignore_vehicle(name)
  -- RT: ignore dummy for jumping
  if game.active_mods["RenaiTransportation"] and name == "RTPropCar" then
    return true
  end

  return false
end

return compatibility