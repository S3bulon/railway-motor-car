local shared = require "shared"

data:extend({
  {
    type = "bool-setting",
    name = shared.keep_schedule,
    setting_type = "runtime-per-user",
    default_value = false
  },
  {
    type = "bool-setting",
    name = shared.keep_temporary,
    setting_type = "runtime-per-user",
    default_value = true
  },
  {
    type = "string-setting",
    name = shared.home,
    setting_type = "runtime-per-user",
    default_value = "",
    allow_blank = true
  }
})
