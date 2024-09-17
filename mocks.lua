---@diagnostic disable: lowercase-global
package.cpath = package.cpath..";C:/Program Files (x86)/Lua/5.1/clibs/?.dll;"
wx = require("wx")
-- Mock the mc object if it doesn't exist
if not mc then
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
        end,
        mcCntlEnable = function(inst, state)
            print("[MOCK]: mcCntlEnable called with state: " .. tostring(state))
        end,
        mcJogVelocityStart = function(inst, axis, direction)
            print("[MOCK]: Jog started on axis " .. tostring(axis) .. " in direction " .. tostring(direction))
        end,
        mcJogVelocityStop = function(inst, axis)
            print("[MOCK]: Jog stopped on axis " .. tostring(axis))
        end,
        mcJogSetRate = function(inst, axis, rate)
            print("[MOCK]: Jog rate set on axis " .. tostring(axis) .. " to " .. tostring(rate))
        end,
        mcJogGetRate = function(inst, axis)
            --print("[MOCK]: Getting jog rate for axis " .. tostring(axis))
            return 100  -- Return a dummy rate
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
        mcRegGetValueLong = function(handle)
            return keyStates[handle] and 1 or 0
        end,
        mcInEditor = function()
            return 1
        end,
        AXIS1 = 1,
        AXIS0 = 0,
        AXIS2 = 2,
        Y_AXIS = 1,
        X_AXIS = 0,
        Z_AXIS = 2,
        MC_JOG_POS = 1,
        MC_JOG_NEG = -1,
    }
end

mcLuaPanelParent = wx.wxPanel()

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

-- Mock mcRegGetValueLong: Return 1 if the key is pressed, 0 if not
function mcRegGetValueLong(handle)
    return keyStates[handle] and 1 or 0
end
function main()

    -- create the frame window
    frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "wxLua Very Minimal Demo",
                        wx.wxDefaultPosition, wx.wxSize(450, 450),
                        wx.wxDEFAULT_FRAME_STYLE )

    frame:Connect(wx.wxEVT_KEY_DOWN, function(event)
        local keyCode = event:GetKeyCode()
        keyStates[keyCode] = true  -- Mark the key as pressed
        event:Skip()  -- Let the event propagate
    end)
    
    -- Event handler for key up
    frame:Connect(wx.wxEVT_KEY_UP, function(event)
        local keyCode = event:GetKeyCode()
        keyStates[keyCode] = false  -- Mark the key as released
        event:Skip()  -- Let the event propagate
    end)
    -- show the frame window
    frame:Show(true)
end

function machineIsIdle()
    -- Check if the machine is enabled
    local hsig_enabled = mc.mcSignalGetHandle(inst, mc.OSIG_MACHINE_ENABLED)
    local machine_enabled = mc.mcSignalGetState(hsig_enabled)

    -- Check if a program is running
    local hsig_run = mc.mcSignalGetHandle(inst, mc.OSIG_RUNNING_GCODE)
    local program_running = mc.mcSignalGetState(hsig_run)

    -- Check for feed hold
    local hsig_hold = mc.mcSignalGetHandle(inst, mc.OSIG_FEEDHOLD)
    local feed_hold = mc.mcSignalGetState(hsig_hold)

    -- Check if E-stop is active
    local hsig_estop = mc.mcSignalGetHandle(inst, mc.ISIG_EMERGENCY)
    local estop_active = mc.mcSignalGetState(hsig_estop)

    -- Determine if machine is idle
    if machine_enabled == 1 and feed_hold == 0 and program_running == 0 and estop_active == 0 then
        return true
    else
        return false
    end
end

return{mc,wx,mcLuaPanelParent}