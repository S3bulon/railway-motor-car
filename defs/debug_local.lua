function printTable(desc, table)
  if game then
    game.print(tostring(desc) .. ":")
    game.print(serpent.block(table))
  else
    log(tostring(desc) .. ":")
    log(serpent.block(table))
  end
end