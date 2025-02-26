local json = require "dkjson"

local config = {}

-- ���� � ����� ������������
local CONFIG_PATH = "moonloader/config/Tram Bot/settings.json"

-- ������������ �� ���������
local defaultConfig = {
    -- ��������� ����
    bot = {
        enabled = false,
        deceleration = 14.5,
        maxSpeed = 85.0,
        safeDistance = 3.0,
        decisionInterval = 0.2,
        minSwitchInterval = 0.3,
        waitOnMarker = 0.1,
    },
    -- ��������� UI
    ui = {
        windowWidth = 300,
        windowHeight = 300,
        fontSize = 14,
    },
    -- ��������� �������
    debug = {
        enabled = false,
        position = { x = 10, y = 10 },
    }
}
-- ������� ������������
local currentConfig = {}

-- ������� ����������, ���� ��� �� ����������
local function ensureDirectoryExists(path)
    local dir = path:match("(.*[/\\])")
    if dir and not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
end

-- ��������� ������������ �� �����
function config.load()
    ensureDirectoryExists(CONFIG_PATH)

    if doesFileExist(CONFIG_PATH) then
        local file = io.open(CONFIG_PATH, "r")
        if file then
            local content = file:read("*a")
            file:close()

            local decoded, pos, err = json.decode(content, 1, nil)
            if err then
                sampAddChatMessage("[Tram Bot] ������ �������� ������������: " .. err, 0xFF0000)
                currentConfig = table.deepcopy(defaultConfig)
            else
                -- ��������� ������������ � ��������� ������������� ����
                currentConfig = config.mergeWithDefaults(decoded)
            end
        else
            sampAddChatMessage("[Tram Bot] �� ������� ������� ���� ������������", 0xFF0000)
            currentConfig = table.deepcopy(defaultConfig)
        end
    else
        sampAddChatMessage("[Tram Bot] ���� ������������ �� ������, ������������ ��������� �� ���������", 0xFFFFFF)
        currentConfig = table.deepcopy(defaultConfig)
        config.save() -- ��������� ��������� �� ��������� � ����
    end

    return currentConfig
end

-- ������� ����������� ������������ � ����������� �� ��������� ��� �������� �������������
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

-- ��������� ������� ������������ � ����
function config.save()
    ensureDirectoryExists(CONFIG_PATH)

    local file = io.open(CONFIG_PATH, "w")
    if file then
        local encoded = json.encode(currentConfig, { indent = true })
        file:write(encoded)
        file:close()
        return true
    else
        sampAddChatMessage("[Tram Bot] �� ������� ��������� ������������", 0xFF0000)
        return false
    end
end

-- �������� �������� �� ����� �� ������������
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

-- ������������� �������� �� ����� � ������������
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

-- ���������� ������������ � ���������� �� ���������
function config.reset()
    currentConfig = table.deepcopy(defaultConfig)
    config.save()
    return true
end

-- �������� ����������� �������
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
