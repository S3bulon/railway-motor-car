shared = require "shared"

require "scripts.use_equipment"
local informatron = require "scripts.informatron"

remote.add_interface("railway-motor-car", {
  -- informatron implementation
  informatron_menu = function(data)
    return informatron.menu(data.player_index)
  end,

  informatron_page_content = function(data)
    return informatron.page_content(data.page_name, data.player_index, data.element)
  end,
})