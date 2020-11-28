local hardware = require("tde.lib-tde.hardware-check")

_G.DISPLAY_ID = 100

-- This function takes as argument stdout from awesomewm in the form of a string
-- It searches for IT-test-result:true and returns true if found otherwise returns false
local function parse_IT_test_stdout_awesome(stdout)
    return stdout:match("IT[-]test[-]result:true") ~= nil
end

-- Takes as parameter a string called config
-- which is the rc.lua file that should be executed with awesomewm
-- it returns a tuple of type, assertion and boolean and stdout
-- the assertion is of type boolean and tells use if no crash occured
-- the boolean tells us if we found IT-test-result:true in the output
-- this string should tell us if we encountered what we expect from the Integration Test
-- The last element is the stdout from awesomewm
function run_rc_config_in_xephyr(config, time)
    local timeout = 3
    if time ~= nil then
        timeout = time
    end
    if os.getenv("MULTIPLIER") then
        timeout = timeout * tonumber(os.getenv("MULTIPLIER"))
    end
    -- make sure we have the correct dependencies before running the intergation test
    assert(hardware.has_package_installed("xorg-server-xephyr"))
    assert(hardware.has_package_installed("awesome-tos"))
    assert(hardware.has_package_installed("bash"))

    -- we generate display values high enough to prevent collision from occuring
    _G.DISPLAY_ID = _G.DISPLAY_ID + 1
    -- we prevent collision between display that are not closed yet by always increasing the number for each Integration Test
    local DISPLAY = ":" .. _G.DISPLAY_ID

    -- this is the command to launch TDE
    local ENV = "XDG_CURRENT_DESKTOP=TDE TDE_ENV=develop DISPLAY=" .. DISPLAY
    local launchCMD = "tde --config " .. config
    local xephyrCommand = "DISPLAY=:0 Xephyr -br -ac -reset -once -terminate -screen 700x700 " .. DISPLAY .. " &"
    local command =
        "timeout " ..
        tostring(timeout) .. " bash -c '(" .. xephyrCommand .. "); sleep 1; " .. ENV .. " " .. launchCMD .. "'"
    print(command)
    local out, ret = hardware.execute(command)
    -- timeout command return exit code 124 if the command had to be halted
    -- we give 10 seconds boot time to test crashes
    return ret == 124, parse_IT_test_stdout_awesome(out), out
end

return {
    run_rc_config_in_xephyr = run_rc_config_in_xephyr
}
