local botLogic = {}

local searchMarker = require("Utils.searchMarker")

local DECELERATION = 14.5       -- (км/ч)/с
local MAX_SPEED = 85.0          -- км/ч, лимит скорости
local SAFE_DISTANCE = 3.0       -- запас к тормозной дистанции
local DECISION_INTERVAL = 0.2   -- как часто пересматриваем решение (сек)
local MIN_SWITCH_INTERVAL = 0.3 -- не менять состояние чаще, чем раз в 0.4 сек
local WAIT_ON_MARKER = 0.1      -- секунд подождать на маркере (эмуляция остановки)

local STATE_IDLE = 0
local STATE_DRIVE_FWD = 1
local STATE_BRAKE_FWD = 2
local STATE_REVERSE = 3
local STATE_STOPPED = 4

local function pressGas()
    writeMemory(12006520, 1, 255, false)
end

local function pressBrake()
    writeMemory(12006516, 1, 255, false)
end

local function calcBrakingDistance(v_kmh) -- Рассчёт тормозной дистанции: S = v^2 / (2a), где v (км/ч)->м/с, a -> м/с^2
    local v_ms = (v_kmh * 1000) / 3600
    local dec_ms2 = (DECELERATION * 1000) / 3600
    return (v_ms * v_ms) / (2 * dec_ms2)
end

local botState = STATE_IDLE
local lastStateSwitchTime = 0 -- когда последний раз меняли состояние
local lastDecisionTime = 0    -- когда последний раз пересчитывали логику
local prevDist = 999999

function botLogic.handleTrainMovement()
    -- 1) Определяем, есть ли маркер и мы в трамвае
    local vehicle = storeCarCharIsInNoSave(PLAYER_PED)
    local foundMarker, mX, mY, mZ = searchMarker.find()
    if not vehicle or not isCharInAnyTrain(PLAYER_PED) or not foundMarker then
        -- Нет трамвая или нет маркера -> STATE_IDLE
        botState = STATE_IDLE
        return
    end

    -- 2) Считаем скорость и расстояние
    local speedKmh = getCarSpeed(vehicle) * 3.6
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local dist = getDistanceBetweenCoords3d(mX, mY, mZ, px, py, pz)

    -- Проверяем, прошло ли время для принятия нового решения
    local now = os.clock()
    local doDecision = false
    if (now - lastDecisionTime) >= DECISION_INTERVAL then
        doDecision = true
        lastDecisionTime = now
    end

    -- 3) Логика состояний
    if botState == STATE_IDLE then
        -- Если в трамвае и маркер есть => переключаемся на DRIVE_FWD
        if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
            botState = STATE_DRIVE_FWD
            lastStateSwitchTime = now
        end
    elseif botState == STATE_DRIVE_FWD then
        --[[
            3.1) В режиме DRIVE_FWD мы обычно жмём газ (до MAX_SPEED)
            Но если мы проехали маркер (dist начал расти), значит надо REVERSE
            Или если dist < brakingDist => BRAKE_FWD
        ]]
        if speedKmh < MAX_SPEED then
            pressGas()
        end

        -- Если можно, делаем решение
        if doDecision then
            local brakeDist = calcBrakingDistance(speedKmh) + SAFE_DISTANCE
            -- local brakeThreshold = brakeDist * 0.95

            -- Проверка "пропустили маркер" (dist растёт?)
            --[[
            if dist > prevDist + 0.1 then
                -- Дистанция растёт, значит мы проехали точку
                if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                    botState = STATE_REVERSE
                    lastStateSwitchTime = now
                end
            elseif dist <= brakeDist then
                -- Нужно тормозить
                if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                    botState = STATE_BRAKE_FWD
                    lastStateSwitchTime = now
                end
            end
            ]]
            if dist <= brakeDist then
                if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                    botState = STATE_BRAKE_FWD
                    lastStateSwitchTime = now
                end
            end
        end
    elseif botState == STATE_BRAKE_FWD then
        --[[
            3.2) В режиме BRAKE_FWD мы жмём тормоз
            Если мы слишком близко (dist < 2 и скорость мала), STOPPED
            Если dist внезапно вырос, значит проехали -> REVERSE
            Если dist снова стало > brakeDist => DRIVЕ_FWD
        ]]

        pressBrake()

        if dist < 4.0 and speedKmh < 5.0 then
            setTrainSpeed(vehicle, 0)
            -- wait(100)
            if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                botState = STATE_STOPPED
                lastStateSwitchTime = now
            end
        end

        if doDecision then
            local brakeDist = calcBrakingDistance(speedKmh) + SAFE_DISTANCE
            -- local releaseThreshold = brakeDist * 1.05

            -- Проверяем, не проехали ли
            --[[
            if dist > prevDist + 0.1 then
                    -- Уходим в REVERSE
                    if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                        botState = STATE_REVERSE
                    lastStateSwitchTime = now
                end
            else
                -- Если расстояние опять стало "большим" => DriveForward
                if dist > brakeDist then
                    if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                        botState = STATE_DRIVE_FWD
                        lastStateSwitchTime = now
                    end
                end
            end
            ]]
            if dist > brakeDist then
                if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                    botState = STATE_DRIVE_FWD
                    lastStateSwitchTime = now
                end
            end
        end
    elseif botState == STATE_REVERSE then -- Ебля с дистанцией, как вариант записать в память NEED FIX
        --[[
            3.3) РЕЖИМ REVERSE (едем назад, чтобы "поймать" маркер)
            Допустим, чтобы ехать назад, мы жмём тормоз, если скорость > -20,
            но в GTA вряд ли трамвай задом ездит логично...
            Покажем концепцию:
        ]]

        pressBrake()

        -- Когда dist < 2, speed мала => STOPPED
        if dist < 2.0 and speedKmh < 5.0 then
            setTrainSpeed(vehicle, 0)
            wait(200)
            if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
                botState = STATE_STOPPED
                lastStateSwitchTime = now
            end
        end
    elseif botState == STATE_STOPPED then
        --[[
            3.4) РЕЖИМ STOPPED (стоим на маркере)
            Можем подождать WAIT_ON_MARKER секунд, а затем перейти DriveFwd
            (или к следующему маркеру).
        ]]

        setTrainSpeed(vehicle, 0)
        wait(WAIT_ON_MARKER * 1000)

        --[[
            После этого можно, напр., сменить маркер на следующий (если их несколько)
            Или просто ехать дальше (DRIVE_FWD) - зависит от вашей логики.
        ]]
        if (now - lastStateSwitchTime) >= MIN_SWITCH_INTERVAL then
            botState = STATE_DRIVE_FWD
            lastStateSwitchTime = now
        end
    end

    -- prevDist = dist
end

function botLogic.update()
    while true do
        wait(0)
        botLogic.handleTrainMovement()
    end
end

return botLogic
