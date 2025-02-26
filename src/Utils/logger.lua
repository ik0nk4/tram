local logger = {}

-- Уровни логирования
logger.LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    FATAL = 5
}

-- Текущий уровень логирования
local currentLevel = logger.LEVEL.DEBUG

-- Форматирование времени
local function formatTime()
    local time = os.date("*t")
    return string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
end

-- Форматирование сообщения лога
local function formatMessage(level, module, message)
    local levelNames = { "DEBUG", "INFO", "WARN", "ERROR", "FATAL" }
    local levelName = levelNames[level] or "UNKNOWN"

    return string.format("[%s] [%s] [%s] %s",
        formatTime(),
        levelName,
        module or "MAIN",
        tostring(message))
end

-- Общий метод для логирования
local function log(level, module, message, ...)
    if level < currentLevel then return end

    -- Форматирование сообщения с параметрами
    if select('#', ...) > 0 then
        message = string.format(message, ...)
    end

    local formattedMessage = formatMessage(level, module, message)

    -- Вывод в консоль
    print(formattedMessage)

    -- Вывод в чат SAMP, если доступен
    if isSampAvailable() and level >= logger.LEVEL.WARN then
        local colors = { 0x00FF00, 0xFFFFFF, 0xFFFF00, 0xFF0000, 0xFF00FF }
        sampAddChatMessage(formattedMessage, colors[level])
    end

    -- Запись в файл
    local file = io.open("moonloader/config/Tram Bot/logs/latest.log", "a")
    if file then
        file:write(formattedMessage .. "\n")
        file:close()
    end
end

-- Публичные методы для разных уровней логирования
function logger.debug(module, message, ...)
    log(logger.LEVEL.DEBUG, module, message, ...)
end

function logger.info(module, message, ...)
    log(logger.LEVEL.INFO, module, message, ...)
end

function logger.warn(module, message, ...)
    log(logger.LEVEL.WARN, module, message, ...)
end

function logger.error(module, message, ...)
    log(logger.LEVEL.ERROR, module, message, ...)
end

function logger.fatal(module, message, ...)
    log(logger.LEVEL.FATAL, module, message, ...)
end

-- Установка уровня логирования
function logger.setLevel(level)
    if type(level) == "number" and level >= logger.LEVEL.DEBUG and level <= logger.LEVEL.FATAL then
        currentLevel = level
        return true
    end
    return false
end

-- Ротация логов
function logger.rotateLogs()
    -- Создаем архивные логи с датой
    local dateStr = os.date("%Y-%m-%d_%H-%M-%S")
    os.rename(
        "moonloader/config/Tram Bot/logs/latest.log",
        string.format("moonloader/config/Tram Bot/logs/log_%s.log", dateStr)
    )
end

function logger.initialize()
    -- Создаем директорию для логов, если не существует
    if not doesDirectoryExist("moonloader/config/Tram Bot/logs") then
        createDirectory("moonloader/config/Tram Bot/logs")
    end

    -- Ротация логов при запуске
    logger.rotateLogs()

    -- Пишем первую строку лога
    logger.info("System", "Logger initialized")
end

return logger
