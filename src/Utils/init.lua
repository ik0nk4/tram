local Utils = {}

Utils.Debug = require "Utils.debug"

function Utils.initialize()
    -- Регистрируем команду для включения/выключения дебага
    sampRegisterChatCommand("debug", function()
        sampAddChatMessage(Utils.Debug.is_enabled, 0xFFFFFF)
        Utils.Debug.toggle()
        sampAddChatMessage("Debug mode: " .. (Utils.Debug.is_enabled and "ON" or "OFF"), 0xFFFFFF)
    end)
end

function Utils.findMarker()
    -- return search_marker.find()
end

return Utils
