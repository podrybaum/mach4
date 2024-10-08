---@diagnostic disable: lowercase-global
package.cpath = package.cpath..";C:/Program Files (x86)/Lua/5.1/clibs/?.dll;"

wx = require("wx")

local function getSection(section)
    local sectionString = string.format("[%s]", section)
    local i = 0
    local sectionArray = {}
    local found = false
    for line in io.lines("profile.ini") do
        if found and string.sub(line,1,1) ~= '[' then
            table.insert(sectionArray, line)
        elseif found and string.sub(line,1,1) == '[' then
            return sectionArray
        end
        if line == sectionString then
            found = true
        end
    end
end

local function getKey(section, key)
    local sec = getSection(section)
    if sec then
        for i, line in ipairs(sec) do
            if string.sub(line, 1, #key) == key then
                local pattern = string.format("%s = ",key)
                return string.gsub(line, pattern, "")
            end
        end
    end
end

local function getTable()
    local t = {}
    for line in io.lines("profile.ini") do
        local current = ''
        if string.sub(line, 1, 1) == '[' then
            current = string.sub(line, 2, -2)
        else
            for k, v in string.gmatch(line, "(%w+) = (%w+)") do
                if t[current] then
                    local tk = t[current]
                    tk.k = v
                else
                   t[current] = {[k]=v}
                end
            end
        end
    end
    return t
end

local function writeTable(t)
    print("writeTable called")
    local file = io.open("profile.ini","w+")
    if file then
        print(string.format("file %s opened", tostring(file)))
    end
    local output = ''
    for k,v in pairs(t) do
        output = output .. string.format("[%s]\n",k)
        for key, value in pairs(v) do
            output = output .. string.format("%s = %s\n",key,value)
        end
    end
    if file ~= nil then
        file:write(output)
        file:close()
    end
end


    mc = {
        mcCntlLog = function(inst, message, style, level)
            print("[MOCK LOG]: " .. message)
        end,
        mcSignalGetHandle = function(inst, signal)
            print("[MOCK]: mcSignalGetHandle called for signal: " .. tostring(signal))
            return 123  -- Return a dummy handle
        end,
        mcSignalSetState = function(handle, state)
            print("[MOCK]: mcSignalSetState called on handle " .. tostring(handle) .. " with state " .. tostring(state))
            return 1 --- return a dummy state
        end,
        mcSignalGetState = function(inst, handle)
            print("[MOCK]: mcSignalGetState called on handle:"..handle)
            return 1 --- return a dummy state
        end,
        mcCntlEnable = function(inst, state)
            print("[MOCK]: mcCntlEnable called with state: " .. tostring(state))
        end,
        mcJogVelocityStart = function(inst, axis, direction)
            print("[MOCK]: Jog started on axis " .. tostring(axis) .. " in direction " .. tostring(direction))
            return 0
        end,
        mcJogVelocityStop = function(inst, axis)
            print("[MOCK]: Jog stopped on axis " .. tostring(axis))
            return 0
        end,
        mcJogSetRate = function(inst, axis, rate)
            print("[MOCK]: Jog rate set on axis " .. tostring(axis) .. " to " .. tostring(rate))
            return 0
        end,
        mcJogGetRate = function(inst, axis)
            --print("[MOCK]: Getting jog rate for axis " .. tostring(axis))
            return 100, 0  -- Return a dummy rate
        end,
        mcJogIncStart = function(inst, axis, increment)
            print("[MOCK]: Incremental jog on axis " .. tostring(axis) .. " by " .. tostring(increment))
        end,
        mcCntlCycleStart = function(inst)
            print("[MOCK]: Cycle start")
        end,
        mcCntlFeedHold = function(inst)
            print("[MOCK]: Feed hold")
        end,
        mcGetInstance = function()
            print("[MOCK]: mcGetInstance called")
            return 0  -- Return a dummy instance
        end,
        mcRegGetHandle = function(inst, regName)
            return keyMap[regName] or 0  -- Return key code or 0 if not found
        end,
        mcRegGetValue = function(handle)
            return keyStates[handle] and 1 or 0
        end,
        mcInEditor = function()
            return 1
        end,
        mcCntlGetErrorString = function(inst, rc)
            return rc
        end,
        mcProfileGetString = function(inst, section, key, defval)
            return mc.mcProfileGetDouble(inst, section, key, defval)
        end,
        mcProfileWriteString = function(inst, section, key, val)
            local profileTable = getTable()
            for k, v in pairs(profileTable) do
                if k == section then
                    table.insert(profileTable[k],{[key] = val})
                    writeTable(profileTable)
                    return 0
                end
                profileTable[k] = {[key] = val}
                writeTable(profileTable)
            end
        end,
        mcProfileFlush = function(inst)
            return 0
        end,
        mcProfileGetDouble = function(inst, section, key, defval)
            local profileTable = getTable()
            for k, v in pairs(profileTable) do
                if k == section then
                    for fkey, val in pairs(v) do
                        if fkey == key then
                            return val, 0
                        end
                        if defval ~= nil then
                            profileTable.k[key] = defval
                            writeTable(profileTable)
                            return defval, 0
                        end
                    end
                end
                profileTable[section] = {[key] = defval}
                writeTable(profileTable)
                return defval, 0
            end
        end,
        mcProfileWriteDouble = function(inst, section, key, val)
            return mc.mcProfileWriteString(inst, section, key, val)
        end,
        mcCntlGetState = function(inst)
            return 0, 0
        end,
        mcProfileExists = function(inst, section, key)
            if not key then
                if getSection(section) then
                    return mc.MC_TRUE
                else
                    return mc.MC_FALSE
                end
            else
                if getKey(section, key) then
                    return mc.MC_TRUE
                else
                    return mc.MC_FALSE
                end
            end
        end,
        mcProfileReload = function(inst)
            return 0
        end,
        MC_STATE_IDLE = 0,
        MERROR_NOERROR = 0,
        AXIS1 = 1,
        AXIS0 = 0,
        AXIS2 = 2,
        Y_AXIS = 1,
        X_AXIS = 0,
        Z_AXIS = 2,
        MC_JOG_POS = 1,
        MC_JOG_NEG = -1,
        MC_TRUE = 1,
        MC_FALSE = 0
    }


scr = {}
scr.DoFunctionName = function(name) return name end

mcLuaPanelParent = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Mock Panel")

keyMap = {
    ["mcX360_LUA/DPad_UP"] = wx.WXK_UP,
    ["mcX360_LUA/DPad_DOWN"] = wx.WXK_DOWN,
    ["mcX360_LUA/DPad_LEFT"] = wx.WXK_LEFT,
    ["mcX360_LUA/DPad_RIGHT"] = wx.WXK_RIGHT,
    ["mcX360_LUA/Btn_A"] = string.byte("A"),  -- Map 'A' button to the 'A' key
    ["mcX360_LUA/Btn_B"] = string.byte("B"),  -- Map 'B' button to the 'B' key
    -- Add more mappings as needed
}

keyStates = {}


return{mc,wx,mcLuaPanelParent}