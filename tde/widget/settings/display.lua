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
local rounded = require("lib-tde.widget.rounded")
local filesystem = require("lib-tde.file")
local icons = require("theme.icons")
local signals = require("lib-tde.signals")
local dpi = beautiful.xresources.apply_dpi
local configWriter = require("lib-tde.config-writer")
local datetime = require("lib-tde.function.datetime")
local filehandle = require("lib-tde.file")
local imagemagic = require("lib-tde.imagemagic")
local scrollbox = require("lib-widget.scrollbox")
local slider = require("lib-widget.slider")
local card = require("lib-widget.card")

-- this will hold the scrollbox, used to reset it
local body = nil

local m = dpi(10)
local settings_index = dpi(40)
local settings_height = dpi(900)

local tempDisplayDir = filehandle.mktempdir()

local screens = {}
local mon_size = {
  w = nil,
  h = nil
}
local refresh = function()
end

local bSelectWallpaper = false

-- wall is the scaled wallpaper
-- fullwall is a fullscreen (or original wallpaper)
-- the disable_number argument tells use if we should show the number in the center of the monitor
local function make_mon(wall, id, fullwall, disable_number)
  fullwall = fullwall or wall
  local monitor =
    wibox.widget {
    widget = wibox.widget.imagebox,
    shape = rounded(),
    clip_shape = rounded(),
    resize = true,
    forced_width = mon_size.w,
    forced_height = mon_size.h
  }
  monitor:set_image(wall)
  monitor:connect_signal(
    "button::press",
    function(_, _, _, button)
      -- we check if button == 1 for a left mouse button (this way scrolling still works)
      if bSelectWallpaper and button == 1 then
        awful.spawn.easy_async(
          "tos theme set " .. fullwall,
          function()
            bSelectWallpaper = false
            refresh()
            local themeFile = os.getenv("HOME") .. "/.config/tos/theme"
            -- our theme file exists
            if filesystem.exists(themeFile) then
              local newContent = ""
              for _, line in ipairs(filesystem.lines(themeFile)) do
                -- if the line is a file then it is a picture, otherwise it is a configuration option
                if not filesystem.exists(line) then
                  newContent = newContent .. line .. "\n"
                end
              end
              newContent = newContent .. fullwall
              filesystem.overwrite(themeFile, newContent)
            end
            -- collect the garbage to remove the image cache from memory
            collectgarbage("collect")
          end
        )
      end
    end
  )
  if disable_number then
    return wibox.container.place(monitor)
  end
  return wibox.container.place(
    wibox.widget {
      layout = wibox.layout.stack,
      forced_width = mon_size.w,
      forced_height = mon_size.h,
      wibox.container.place(monitor),
      {
        layout = wibox.container.place,
        valign = "center",
        halign = "center",
        {
          layout = wibox.container.background,
          fg = beautiful.fg_normal,
          bg = beautiful.bg_settings_display_number,
          shape = rounded(dpi(100)),
          forced_width = dpi(100),
          forced_height = dpi(100),
          wibox.container.place(
            {
              widget = wibox.widget.textbox,
              font = beautiful.monitor_font,
              text = id
            }
          )
        }
      }
    }
  )
end

return function()
  local view = wibox.container.margin()
  view.left = m
  view.right = m
  view.bottom = m

  local title = wibox.widget.textbox(i18n.translate("Display"))
  title.font = beautiful.title_font
  title.forced_height = settings_index + m + m

  local close = wibox.widget.imagebox(icons.close)
  close.forced_height = settings_index
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

  local monitors = card()

  local layout = wibox.layout.grid()
  layout.spacing = m
  layout.forced_num_cols = 4
  layout.homogeneous = true
  layout.expand = true
  layout.min_rows_size = dpi(100)

  local changewall = card()
  changewall.top = m
  changewall.bottom = m
  changewall.bg = beautiful.accent.hue_600

  local brightness =
    slider(
    0,
    100,
    1,
    0,
    function(value)
      if _G.oled then
        awful.spawn("brightness -s " .. tostring(value) .. " -F")
      else
        awful.spawn("brightness -s 100 -F") -- reset pixel values when using backlight
        awful.spawn("brightness -s " .. tostring(value))
      end
    end
  )

  signals.connect_brightness(
    function(value)
      brightness.update(tonumber(value))
    end
  )

  local screen_time =
    slider(
    10,
    600,
    1,
    tonumber(general["screen_on_time"]) or 120,
    function(value)
      print("Updated screen time: " .. tostring(value) .. "sec")
      screen_time_tooltip.text = datetime.numberInSecToMS(value) .. i18n.translate(" before sleeping")
      general["screen_on_time"] = tostring(value)
      configWriter.update_entry(os.getenv("HOME") .. "/.config/tos/general.conf", "screen_on_time", tostring(value))
      if general["screen_timeout"] == "1" or general["screen_timeout"] == nil then
        awful.spawn("pkill -f autolock.sh")
        awful.spawn("sh /etc/xdg/tde/autolock.sh " .. tostring(value))
      end
    end,
    function()
      return datetime.numberInSecToMS(tonumber(general["screen_on_time"]) or 120) .. i18n.translate(" before sleeping")
    end
  )

  changewall:connect_signal(
    "mouse::enter",
    function()
      changewall.bg = beautiful.accent.hue_700
    end
  )
  changewall:connect_signal(
    "mouse::leave",
    function()
      changewall.bg = beautiful.accent.hue_600
    end
  )

  changewall:buttons(
    gears.table.join(
      awful.button(
        {},
        1,
        function()
          -- TODO: change wallpaper
          bSelectWallpaper = not bSelectWallpaper
          refresh()
        end
      )
    )
  )

  changewall.update_body(
    wibox.widget {
      layout = wibox.container.background,
      shape = rounded(),
      {
        layout = wibox.container.place,
        valign = "center",
        forced_height = settings_index,
        {
          widget = wibox.widget.textbox,
          text = "Change wallpaper",
          font = beautiful.title_font
        }
      }
    }
  )

  body = scrollbox(layout)
  monitors.update_body(
    wibox.widget {
      layout = wibox.container.margin,
      margins = m,
      body
    }
  )

  local brightness_card = card()
  local screen_time_card = card()

  brightness_card.update_body(
    wibox.widget {
      layout = wibox.layout.fixed.vertical,
      {
        layout = wibox.container.margin,
        margins = m,
        {
          font = beautiful.font,
          text = i18n.translate("Brightness"),
          widget = wibox.widget.textbox
        }
      },
      {
        layout = wibox.container.margin,
        left = m,
        right = m,
        bottom = m,
        brightness
      }
    }
  )
  screen_time_card.update_body(
    wibox.widget {
      layout = wibox.layout.fixed.vertical,
      {
        layout = wibox.container.margin,
        margins = m,
        {
          font = beautiful.font,
          text = i18n.translate("Screen on time"),
          widget = wibox.widget.textbox
        }
      },
      {
        layout = wibox.container.margin,
        left = m,
        right = m,
        bottom = m,
        screen_time
      }
    }
  )

  brightness_card.forced_height = (m * 6) + dpi(30)
  screen_time_card.forced_height = (m * 6) + dpi(30)

  view:setup {
    layout = wibox.container.background,
    {
      layout = wibox.layout.align.vertical,
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
      {
        layout = wibox.layout.fixed.vertical,
        brightness_card,
        {
          layout = wibox.container.margin,
          top = m,
          screen_time_card
        },
        {layout = wibox.container.margin, top = m, monitors},
        {layout = wibox.container.margin, top = m, changewall}
      },
      nil
    }
  }

  -- The user option tells use if these are pictures supplied by the user
  local function load_monitor(k, table, done, user)
    local v = table[k]
    -- check if it is a file
    if filesystem.exists(v) then
      local base = filehandle.basename(v)
      -- TODO: 16/9 aspect ratio (we might want to calulate it form screen space)
      local width = dpi(300)
      local height = (width / 16) * 9
      local scaledImage = tempDisplayDir .. "/" .. base
      if user then
        scaledImage = tempDisplayDir .. "/user-" .. base
      end
      if filesystem.exists(scaledImage) and bSelectWallpaper then
        layout:add(make_mon(scaledImage, k, v, true))
        if done then
          done(user, table, k)
        end
      else
        -- We use imagemagick to generate a "thumbnail"
        -- This is done to save memory consumption
        -- However note that our cache (tempDisplayDir) is stored in ram
        imagemagic.scale(
          v,
          width,
          height,
          scaledImage,
          function()
            if filesystem.exists(scaledImage) and bSelectWallpaper then
              layout:add(make_mon(scaledImage, k, v, true))
            else
              print("Something went wrong scaling " .. v)
            end
            if done then
              done(user, table, k)
            end
          end
        )
      end
    else
      -- in case the entry is a directory and not a file
      if done then
        done(user, table, k)
      end
    end
  end

  local recursive_monitor_load_func

  local function loadMonitors()
    local usr_files = filesystem.list_dir("/usr/share/backgrounds/tos")

    recursive_monitor_load_func = function(bool, table, i)
      if i < #table then
        i = i + 1
        load_monitor(i, table, recursive_monitor_load_func, bool)
      end
    end
    load_monitor(1, usr_files, recursive_monitor_load_func, false)
    local pictures = os.getenv("HOME") .. "/Pictures/tde"
    if filesystem.dir_exists(pictures) then
      local home_dir = filesystem.list_dir_full(pictures)
      -- true to tell the function that these are user pictures
      load_monitor(1, home_dir, recursive_monitor_load_func, true)
    end
  end

  local timer =
    gears.timer {
    timeout = 0.1,
    call_now = false,
    autostart = false,
    single_shot = true,
    callback = loadMonitors
  }

  refresh = function()
    screens = {}
    layout:reset()
    body:reset()
    -- remove all images from memory (to save memory space)
    collectgarbage("collect")

    awful.spawn.easy_async_with_shell(
      "brightness -g",
      function(o)
        brightness:set_value(math.floor(tonumber(o)))
      end
    )
    if bSelectWallpaper then
      -- do an asynchronous render of all wallpapers
      timer:start()
      layout.forced_num_cols = 4
    else
      awful.spawn.with_line_callback(
        "tos theme active",
        {
          stdout = function(o)
            table.insert(screens, o)
          end,
          output_done = function()
            monitors.forced_height = settings_height / 2
            if #screen < 4 then
              layout.forced_num_cols = #screen
            end
            for k, v in pairs(screens) do
              local base = filehandle.basename(v)
              -- TODO: 16/9 aspect ratio (we might want to calulate it form screen space)
              local width = dpi(600)
              local height = (width / 16) * 9
              local scaledImage = tempDisplayDir .. "/monitor-" .. base
              if filesystem.exists(scaledImage) then
                layout:add(make_mon(scaledImage, k, v))
              else
                -- We use imagemagick to generate a "thumbnail"
                -- This is done to save memory consumption
                -- However note that our cache (tempDisplayDir) is stored in ram
                imagemagic.scale(
                  v,
                  width,
                  height,
                  scaledImage,
                  function()
                    layout:add(make_mon(scaledImage, k, v))
                  end
                )
              end
            end
          end
        }
      )
    end
  end

  view.refresh = refresh
  return view
end
