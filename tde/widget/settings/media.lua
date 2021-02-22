--[[
--MIT License
--
--Copyright (c) 2019 manilarome
--Copyright (c) 2020 Tom Meyers
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.
]]
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local icons = require("theme.icons")
local signals = require("lib-tde.signals")
local slider = require("lib-widget.slider")
local card = require("lib-widget.card")
local volume = require("lib-tde.volume")
local button = require("lib-widget.button")
local mat_icon_button = require("widget.material.icon-button")
local mat_icon = require("widget.material.icon")
local sound = require("lib-tde.sound")


local dpi = beautiful.xresources.apply_dpi

local m = dpi(10)
local settings_index = dpi(40)
local settings_width = dpi(1100)
local settings_nw = dpi(260)

local refresh = function()
end

return function()
  local view = wibox.container.margin()
  view.left = m
  view.right = m

  local title = wibox.widget.textbox(i18n.translate("Media"))
  title.font = beautiful.title_font
  title.forced_height = settings_index + m + m

  local close = wibox.widget.imagebox(icons.close)
  close.forced_height = dpi(30)
  close:buttons(
    gears.table.join(
      awful.button(
        {},
        1,
        function()
          if root.elements.settings then
            root.elements.settings.close()
          end
        end
      )
    )
  )

  local vol_heading = wibox.widget.textbox(i18n.translate("Volume"))
  vol_heading.font = beautiful.font

  local vol_footer = wibox.widget.textbox(i18n.translate("test"))
  vol_footer.font = beautiful.font
  vol_footer.align = "right"

  local mic_footer = wibox.widget.textbox(i18n.translate("test"))
  mic_footer.font = beautiful.font
  mic_footer.align = "right"

  local vol_slider =
    slider(
    0,
    100,
    1,
    0,
    function(value)
      signals.emit_volume(value)
    end
  )

  signals.connect_volume(
    function(value)
      local number = tonumber(value)
      if not (number == vol_slider.value) then
        vol_slider.update(tonumber(value) or 0)
      end
    end
  )

  local function create_volume_widget(button_icon, text, obj, set_function)
    local button_wgt = mat_icon_button(mat_icon(button_icon, dpi(25)))
    button_wgt:buttons(
      gears.table.join(
        awful.button(
          {},
          1,
          nil,
          function()
            print("Setting default sink to: " .. obj.sink)
            set_function(obj.sink)
            refresh()
          end
        )
      )
    )

    return wibox.widget {
      wibox.container.margin(
        wibox.widget {
          widget = wibox.widget.textbox,
          text = text,
          font = beautiful.font,
          forced_width = (((settings_width - settings_nw) / 2) - (m * 8) - dpi(25))
        },
        dpi(10),
        dpi(10),
        dpi(10),
        dpi(10)
      ),
      nil,
      button_wgt,
      forced_height = settings_index,
      layout = wibox.layout.align.horizontal
    }
  end

  local function create_sink_widget(sink)
    return create_volume_widget(icons.volume, sink.name, sink, volume.set_default_sink)
  end

  local function create_source_widget(source)
    return create_volume_widget(icons.microphone, source.name, source, volume.set_default_source)
  end

  local body = wibox.layout.flex.horizontal()

  local function generate_sink_setting_body(sinks, sources, sink_sink, source_sink)
    body.children = {}

    local sink_children = wibox.layout.fixed.vertical()
    local source_children = wibox.layout.fixed.vertical()

    for _, sink in ipairs(sinks) do
      if not (sink.sink == sink_sink) then
        sink_children:add(create_sink_widget(sink))
      end
    end

    for _, source in ipairs(sources) do
      if not (source.sink == source_sink) then
        source_children:add(create_source_widget(source))
      end
    end

    if #sink_children.children == 0 then
      sink_children:add(
        wibox.widget {
          text = i18n.translate("No extra output found"),
          align = "center",
          valign = "center",
          font = beautiful.font,
          widget = wibox.widget.textbox
        }
      )
    end

    if #source_children.children == 0 then
      source_children:add(
        wibox.widget {
          text = i18n.translate("No extra input found"),
          align = "center",
          valign = "center",
          font = beautiful.font,
          widget = wibox.widget.textbox
        }
      )
    end

    local sink_widget = card("Output")
    sink_widget.update_body(wibox.container.margin(sink_children, m, m, m, m))

    local source_widget = card("Input")

    source_widget.update_body(wibox.container.margin(source_children, m, m, m, m))

    body:add(wibox.container.margin(sink_widget, m, m, m, m))
    body:add(wibox.container.margin(source_widget, m, m, m, m))
  end

  refresh = function()
    local sink = volume.get_default_sink()
    local source = volume.get_default_source()
    local sinks = volume.get_sinks()
    local sources = volume.get_sources()

    vol_footer.markup = 'Output: <span font="' .. beautiful.font .. '">' .. sink.name .. "</span>"

    mic_footer.markup = 'Input: <span font="' .. beautiful.font .. '">' .. source.name .. "</span>"

    generate_sink_setting_body(sinks, sources, sink.sink, source.sink)
  end

  view.refresh = refresh

  local volume_card = card()
  volume_card.update_body(
    wibox.widget {
      layout = wibox.layout.fixed.vertical,
      {
        layout = wibox.container.margin,
        margins = m,
        {
          layout = wibox.layout.align.horizontal,
          vol_heading,
          nil,
          nil
        }
      },
      {
        layout = wibox.container.margin,
        left = m,
        right = m,
        bottom = m,
        forced_height = dpi(30) + (m * 2),
        vol_slider
      },
      {
        layout = wibox.container.margin,
        left = m,
        right = m,
        vol_footer
      },
      {
        layout = wibox.container.margin,
        left = m,
        right = m,
        bottom = m,
        mic_footer
      }
    }
  )

  local audio_settings =
    wibox.container.margin(
    wibox.widget {
      widget = wibox.widget.textbox,
      text = i18n.translate("Audio list"),
      font = "SF Pro Display Bold 24"
    },
    dpi(20),
    0,
    dpi(20),
    dpi(20)
  )

  view:setup {
    layout = wibox.container.background,
    {
      layout = wibox.layout.fixed.vertical,
      spacing = m,
      {
        layout = wibox.layout.align.horizontal,
        nil,
        wibox.container.margin(
          {
            layout = wibox.container.place,
            title
          },
          settings_index * 2
        ),
        close
      },
      volume_card,
      wibox.container.margin(button("Reset Audio Server", function()
        volume.reset_server()
      end),m, m, m*2),
      wibox.container.margin(button("Test sound", function()
        sound()
      end),m, m, m),
      audio_settings,
      body
    }
  }

  return view
end
