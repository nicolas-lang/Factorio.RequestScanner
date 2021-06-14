local inv_sensor = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
inv_sensor.name = "request-scanner"
inv_sensor.icon = "__nco-RequestScanner__/graphics/icons/request-scanner.png"
inv_sensor.icon_size = 32
inv_sensor.minable.result = "request-scanner"
inv_sensor.sprites = make_4way_animation_from_spritesheet(
  { layers =
    {
      {
        filename = "__nco-RequestScanner__/graphics/entity/request-scanner.png",
        width = 58,
        height = 52,
        frame_count = 1,
        shift = util.by_pixel(0, 5),
        hr_version =
        {
          scale = 0.5,
          filename = "__nco-RequestScanner__/graphics/entity/hr-request-scanner.png",
          width = 114,
          height = 102,
          frame_count = 1,
          shift = util.by_pixel(0, 5),
        },
      },
      {
        filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
        width = 50,
        height = 34,
        frame_count = 1,
        shift = util.by_pixel(9, 6),
        draw_as_shadow = true,
        hr_version =
        {
          scale = 0.5,
          filename = "__base__/graphics/entity/combinator/hr-constant-combinator-shadow.png",
          width = 98,
          height = 66,
          frame_count = 1,
          shift = util.by_pixel(8.5, 5.5),
          draw_as_shadow = true,
        },
      },
    },
  })

inv_sensor.item_slot_count = 1000
data:extend({ inv_sensor })