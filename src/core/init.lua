local core = {}

local botLogic = require('core.botLogic')

function core.initialize()
    lua_thread.create(botLogic.update)
end

return core
