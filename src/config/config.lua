local json = require "dkjson"

local config = {}

-- Путь к файлу конфигурации
local CONFIG_PATH = "moonloader/config/Tram Bot/settings.json"

-- Конфигурация по умолчанию
local defaultConfig = {
    -- Настройки бота
    bot = {
        enabled = false,
        deceleration = 14.5,
        maxSpeed = 85.0,
        safeDistance = 3.0,
        decisionInterval = 0.2,
        minSwitchInterval = 0.3,
        waitOnMarker = 0.1,
    },
    -- Настройки UI
    ui = {
        windowWidth = 300,
        windowHeight = 300,
        fontSize = 14,
    },
    -- Настройки отладки
    debug = {
        enabled = false,
        position = { x = 10, y = 10 },
    }
}
-- Текущая конфигурация
local currentConfig = {}

-- Создает директорию, если она не существует
local function ensureDirectoryExists(path)
    local dir = path:match("(.*[/\\])")
    if dir and not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
end

-- Загружает конфигурацию из файла
function config.load()
    ensureDirectoryExists(CONFIG_PATH)

    if doesFileExist(CONFIG_PATH) then
        local file = io.open(CONFIG_PATH, "r")
        if file then
            local content = file:read("*a")
            file:close()

            local decoded, pos, err = json.decode(content, 1, nil)
            if err then
                sampAddChatMessage("[Tram Bot] Ошибка загрузки конфигурации: " .. err, 0xFF0000)
                currentConfig = table.deepcopy(defaultConfig)
            else
                -- Загружаем конфигурацию и проверяем отсутствующие поля
                currentConfig = config.mergeWithDefaults(decoded)
            end
        else
            sampAddChatMessage("[Tram Bot] Не удалось открыть файл конфигурации", 0xFF0000)
            currentConfig = table.deepcopy(defaultConfig)
        end
    else
        sampAddChatMessage("[Tram Bot] Файл конфигурации не найден, используются настройки по умолчанию", 0xFFFFFF)
        currentConfig = table.deepcopy(defaultConfig)
        config.save() -- Сохраняем настройки по умолчанию в файл
    end

    return currentConfig
end

-- Слияние загруженной конфигурации с настройками по умолчанию для обратной совместимости
function config.mergeWithDefaults(loadedConfig)
    local result = {}

    local function mergeTables(default, loaded, output)
        for k, v in pairs(default) do
            if type(v) == "table" then
                output[k] = {}
                if loaded and loaded[k] and type(loaded[k]) == "table" then
                    mergeTables(v, loaded[k], output[k])
                else
                    mergeTables(v, nil, output[k])
                end
            else
                if loaded and loaded[k] ~= nil then
                    output[k] = loaded[k]
                else
                    output[k] = v
                end
            end
        end
    end

    mergeTables(defaultConfig, loadedConfig, result)
    return result
end

-- Сохраняет текущую конфигурацию в файл
function config.save()
    ensureDirectoryExists(CONFIG_PATH)

    local file = io.open(CONFIG_PATH, "w")
    if file then
        local encoded = json.encode(currentConfig, { indent = true })
        file:write(encoded)
        file:close()
        return true
    else
        sampAddChatMessage("[Tram Bot] Не удалось сохранить конфигурацию", 0xFF0000)
        return false
    end
end

-- Получает значение по ключу из конфигурации
function config.get(key)
    if not key then
        return currentConfig
    end

    local keys = {}
    for k in string.gmatch(key, "([^%.]+)") do
        table.insert(keys, k)
    end

    local value = currentConfig
    for _, k in ipairs(keys) do
        if type(value) ~= "table" then
            return nil
        end
        value = value[k]
        if value == nil then
            return nil
        end
    end

    return value
end

-- Устанавливает значение по ключу в конфигурации
function config.set(key, value)
    if not key then
        return false
    end

    local keys = {}
    for k in string.gmatch(key, "([^%.]+)") do
        table.insert(keys, k)
    end

    local current = currentConfig
    for i = 1, #keys - 1 do
        local k = keys[i]
        if type(current[k]) ~= "table" then
            current[k] = {}
        end
        current = current[k]
    end

    current[keys[#keys]] = value
    return true
end

-- Сбрасывает конфигурацию к настройкам по умолчанию
function config.reset()
    currentConfig = table.deepcopy(defaultConfig)
    config.save()
    return true
end

-- Глубокое копирование таблицы
function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

config.load()

return config
