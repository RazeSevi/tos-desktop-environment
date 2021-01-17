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
local signals = require("lib-tde.signals")
local gettime = require("socket").gettime

local screen_geometry = {}

local function update_screens()
    -- cleanup
    screen_geometry = {}

    -- repopulate screen geometry
    for s in screen do
        table.insert(screen_geometry, s.geometry)
    end

    -- notify tde of screen changes
    signals.emit_refresh_screen()
end

-- listen for screen changes
awesome.connect_signal(
    "screen::change",
    function()
        print("Screen layout changed")

        update_screens()
    end
)

local prev_time = gettime()
-- specify how often to poll
local refresh_timeout_in_seconds = 0.5

local function are_screens_equal(s1, s2)
    return s1.x == s2.x and s1.y == s2.y and s1.width == s2.width and s1.height == s2.height
end

local function perform_refresh()
    if not (#screen_geometry == screen.count()) then
        print("Size is different: " .. #screen_geometry .. " and " .. screen.count())
        update_screens()
    end
    -- check if our output changed
    local i = 1
    for s in screen do
        if not are_screens_equal(s.geometry, screen_geometry[i]) then
            update_screens()
        end
        i = i + 1
    end
end

awesome.connect_signal(
    "refresh",
    function()
        local time = gettime()
        if prev_time < (time - refresh_timeout_in_seconds) then
            prev_time = time
            print("Polling screen geometry changes")
            perform_refresh()
        end
    end
)
