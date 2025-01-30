script_name("Tram Bot")
script_version("3.1.0")

local UI = require("UI")
local Utils = require("Utils")
local core = require("core")

local font = renderCreateFont('Verdana', 10, 0, 0)

function main()
    while not isSampAvailable() do wait(0) end

    UI.initialize()
    Utils.initialize()
    core.initialize()

    while true do
        wait(0)
    end
end
