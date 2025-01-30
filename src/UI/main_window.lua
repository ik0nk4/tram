local imgui = require "mimgui"
local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8

local main_window = {}

local new = imgui.new
local renderWindow = new.bool(false)

local function initializeImGui()
    imgui.GetIO().IniFilename = nil
end

local function createMainWindow()
    return imgui.OnFrame(
        function() return renderWindow[0] end,
        function(player)
            local resX, resY = getScreenResolution()
            local sizeX, sizeY = 300, 300
            imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
            imgui.Begin("", renderWindow)
            -- WINDOW CODE
            imgui.End()
        end
    )
end

function main_window.initialize()
    imgui.OnInitialize(initializeImGui)

    createMainWindow()

    sampRegisterChatCommand("tram", function()
        renderWindow[0] = not renderWindow[0]
    end)
end

-- Геттеры/сеттеры для доступа к состоянию окна
function main_window.show()
    renderWindow[0] = true
end

function main_window.hide()
    renderWindow[0] = false
end

function main_window.toggle()
    renderWindow[0] = not renderWindow[0]
end

function main_window.isVisible()
    return renderWindow[0]
end

return main_window
