data:extend({
  {
    type = "int-setting",
    name = "request-scanner_update_interval",
    order = "aa",
    setting_type = "runtime-global",
    default_value = 120,
    minimum_value = 1,
    maximum_value = 216000, -- 1h
  },
  {
    type = "int-setting",
    name = "request-scanner_max_results",
    order = "ab",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 0,
  },
  {
    type = "int-setting",
    name = "request-scanner_networkID",
    order = "ac",
    setting_type = "runtime-global",
    default_value = 0,
    minimum_value = 0,
	maximum_value = 50
  },
  {
    type = "bool-setting",
    name = "request-scanner-negative-output",
    order = "ba",
    setting_type = "runtime-global",
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "request-scanner-round2stack",
    order = "ba",
    setting_type = "runtime-global",
    default_value = false,
  },
})