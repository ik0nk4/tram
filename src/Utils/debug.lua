local debug_utils = {}

local font = renderCreateFont('Verdana', 10, 0, 0)
local debug_data = {}
local is_debug_enabled = false

-- Позиция дебаг окна
local position = { x = 10, y = 10 }
local is_dragging = false
local drag_offset = { x = 0, y = 0 }

-- Размеры области захвата для перетаскивания
local DRAG_AREA_HEIGHT = 20
local MIN_WIDTH = 150

local function isMouseInBox(x, y, width, height)
    local mouseX, mouseY = getCursorPos()
    return mouseX >= x and mouseX <= x + width and
        mouseY >= y and mouseY <= y + height
end

function debug_utils.render()
    if not is_debug_enabled then return end

    -- Обработка перетаскивания
    local width = MIN_WIDTH
    if isKeyDown(1) then -- Левая кнопка мыши
        local mouseX, mouseY = getCursorPos()
        if is_dragging then
            position.x = mouseX - drag_offset.x
            position.y = mouseY - drag_offset.y
        elseif isMouseInBox(position.x, position.y, width, DRAG_AREA_HEIGHT) then
            is_dragging = true
            drag_offset.x = mouseX - position.x
            drag_offset.y = mouseY - position.y
        end
    else
        is_dragging = false
    end

    -- Рендерим заголовок (область для перетаскивания)
    renderFontDrawText(font, "Debug Info (drag me)", position.x, position.y, 0xFFFFFFFF)

    -- Рендерим данные
    local y = position.y + DRAG_AREA_HEIGHT
    for key, value in pairs(debug_data) do
        renderFontDrawText(font, string.format("%s: %s", key, value), position.x, y, 0xFFFFFFFF)
        y = y + 15
    end
end

function debug_utils.log(key, value)
    debug_data[key] = tostring(value)
end

function debug_utils.clear()
    debug_data = {}
end

function debug_utils.is_enabled()
    return is_debug_enabled
end

function debug_utils.toggle()
    is_debug_enabled = not is_debug_enabled
end

return debug_utils
