local exists = require("lib-tde.file").dir_exists

-- Used to enable custom widgets as a plugin mechanism for TDE
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/tde/?/init.lua"
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/tde/?.lua"

-- Setup custom lua scripts (libraries)
-- If the user dir exists then use that
-- Otherwise use the system files
if exists(os.getenv("HOME") .. "/.config/awesome/lib-tde/lib-lua") then
    package.path =
        package.path ..
        ";" ..
            os.getenv("HOME") ..
                "/.config/awesome/lib-tde/lib-lua/?/?.lua;" ..
                    os.getenv("HOME") .. "/.config/awesome/lib-tde/lib-lua/?.lua"
else
    package.path =
        package.path .. ";" .. "/etc/xdg/awesome/lib-tde/lib-lua/?/?.lua;" .. "/etc/xdg/awesome/lib-tde/lib-lua/?.lua"
end

-- same applies for the c libraries
if exists(os.getenv("HOME") .. "/.config/awesome/lib-tde/lib-so") then
    package.cpath =
        package.cpath ..
        ";" ..
            os.getenv("HOME") ..
                "/.config/awesome/lib-tde/lib-so/?/?.so;" .. os.getenv("HOME") .. "/.config/awesome/lib-tde/lib-so/?.so"
else
    package.cpath =
        package.cpath .. ";" .. "/etc/xdg/awesome/lib-tde/lib-so/?/?.so;" .. "/etc/xdg/awesome/lib-tde/lib-so/?.so"
end