local markers = {}

local logger = require("utils.logger")

-- Найти ближайший маркер
function markers.find()
    local is_found = false
    local ret_pos_x = 0.0
    local ret_pos_y = 0.0
    local ret_pos_z = 0.0

    -- Перебираем все возможные маркеры
    for id = 0, 31 do
        local marker_struct = 0xC7F168 + id * 56
        local pos_x = representIntAsFloat(readMemory(marker_struct + 0, 4, false))
        local pos_y = representIntAsFloat(readMemory(marker_struct + 4, 4, false))
        local pos_z = representIntAsFloat(readMemory(marker_struct + 8, 4, false))

        -- Если координаты ненулевые, маркер найден
        if pos_x ~= 0.0 or pos_y ~= 0.0 or pos_z ~= 0.0 then
            ret_pos_x = pos_x
            ret_pos_y = pos_y
            ret_pos_z = pos_z
            is_found = true

            -- logger.debug("Marker", "Найден маркер, координаты: %.2f, %.2f, %.2f",
            --     pos_x, pos_y, pos_z)

            break
        end
    end

    return is_found, ret_pos_x, ret_pos_y, ret_pos_z
end

return markers
