---@diagnostic disable: lowercase-global
package.cpath = package.cpath..";C:/Program Files (x86)/Lua/5.1/clibs/?.dll;"

wx = require("wx")

profile = {}


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
            local sec = profile[section]
            if not sec then
                table.insert(profile, section)
            end
            sec = profile[section]
            if sec[key] then
                return sec[key], 0
            else
                sec[key] = defval
                return sec[key], 0
            end
        end,
        mcProfileWriteString = function(inst, section, key, val)
            if not profile[section] then
                table.insert(profile, section)
                profile[section] = {}
                profile[section][key] = val
            end
            profile[section][key] = val
            return 0
        end,
        mcProfileFlush = function(inst)
            return 0
        end,
        mcProfileGetDouble = function(inst, section, key, defval)
            local sec = profile[section]
            if not sec then
                table.insert(profile, section)
            end
            sec = profile[section]
            if sec[key] then
                return sec[key], 0
            else
                sec[key] = defval
                return sec[key], 0
            end
        end,
        mcProfileWriteDouble = function(inst, section, key, val)
            if not profile[section] then
                table.insert(profile, section)
                profile[section] = {}
                profile[section][key] = val
            end
            profile[section][key] = val
            return 0
        end,
        mcCntlGetState = function(inst)
            return 0, 0
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