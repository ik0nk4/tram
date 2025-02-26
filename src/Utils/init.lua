local utils = {}

local logger = require("utils.logger")

function utils.initialize()
    logger.initialize()
    logger.debug("Utils", "Утилиты инициализированы")
end

return utils
