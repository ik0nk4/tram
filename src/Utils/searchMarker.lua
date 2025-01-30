local searchMarker = {}

function searchMarker.find()
    local isFind = false
    if not isFind then
        local ret_posX = 0.0
        local ret_posY = 0.0
        local ret_posZ = 0.0

        for id = 0, 31, 1 do
            local MarkerStruct = 0
            MarkerStruct = 0xC7F168 + id * 56
            local MarkerPosX = representIntAsFloat(readMemory(MarkerStruct + 0, 4, false))
            local MarkerPosY = representIntAsFloat(readMemory(MarkerStruct + 4, 4, false))
            local MarkerPosZ = representIntAsFloat(readMemory(MarkerStruct + 8, 4, false))
            if MarkerPosX ~= 0.0 or MarkerPosY ~= 0.0 or MarkerPosZ ~= 0.0 then
                ret_posX = MarkerPosX
                ret_posY = MarkerPosY
                ret_posZ = MarkerPosZ
                isFind = true
            end
        end
        return isFind, ret_posX, ret_posY, ret_posZ
    end
end

function searchMarker.update()
    print("Marker search: " .. tostring(searchMarker.find()))
end

return searchMarker
