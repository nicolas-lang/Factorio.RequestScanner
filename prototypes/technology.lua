-- add to circuit-network-3 if exists otherwise create tech
local mytech = "circuit-network-2"

if data.raw["technology"]["circuit-network-2"] then
	mytech = "circuit-network-3"
end

if data.raw["technology"][mytech] then
  table.insert( data.raw["technology"][mytech].effects, { type = "unlock-recipe", recipe = "request-scanner" } )  
else
  data:extend({
    {
      type = "technology",
      name = mytech,
      icon = "__base__/graphics/technology/circuit-network.png",
      icon_size = 128,
      prerequisites = {"circuit-network", "advanced-electronics"},
      effects =
      {
        { type = "unlock-recipe", recipe = "request-scanner" },
      },
      unit =
      {
        count = 150,
        ingredients = {
          {"automation-science-pack", 1},
          {"logistic-science-pack", 1},
        },
        time = 30
      },
      order = "a-d-d"
    }
  })
end