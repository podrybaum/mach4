local scr = require("scr")
local mc = require("mc")

local inst = mc.mcGetInstance()
--- Check Mach4 signal state in a single call
---@param signal number the Mach4 signal to check
---@return boolean|nil true if signal is 1 false in the case of 0 or nil if not found
local function getMachSignalState(signal)
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcSignalGetState(hsig)
        if rc == mc.MERROR_NOERROR then
            return val > 0
        end
    end
end

--- Toggle the state of a Mach4 signal.
---@param signal number @The Mach4 signal to toggle
local function toggleMachSignalState(signal)
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        mc.mcSignalSetState(hsig, not mc.mcSignalGetState(inst, hsig))
    end
end

local names = {"Cycle Start", "Cycle Stop", "Feed Hold", "Enable On", "Soft Limits On", "Soft Limits Off",
                "Soft Limits Toggle", "Position Remember", "Position Return", "Limit OV On", "Limit OV Off",
                "Limit OV Toggle", "Jog Mode Toggle", "Jog Mode Step", "Jog Mode Continuous", "Jog X Off",
                "Jog Y Off", "Jog Z Off", "Jog A Off", "Jog B Off", "Jog C Off", "Jog X+", "Jog Y+", "Jog Z+",
                "Jog A+", "Jog B+", "Jog C+", "Jog X-", "Jog Y-", "Jog Z-", "Jog A-", "Jog B-", "Jog C-", "Home All",
                "Home X", "Home Y", "Home Z", "Home A", "Home B", "Home C"}

local slots = {}
for _, name in ipairs(names) do
    slots[name] = scr.DoFunctionName(name)
end

slots["Incremental Jog X+"] = function(inc)
    mc.mcJogIncStart(inst, mc.X_AXIS, inc)
end

slots["Incremental Jog Y+"] = function(inc)
    mc.mcJogIncStart(inst, mc.Y_AXIS, inc)
end     

slots["Incremental Jog Z+"] = function(inc)
    mc.mcJogIncStart(inst, mc.Z_AXIS, inc)
end 

slots["Incremental Jog A+"] = function(inc) 
    mc.mcJogIncStart(inst, mc.A_AXIS, inc)
end

slots["Incremental Jog B+"] = function(inc)
    mc.mcJogIncStart(inst, mc.B_AXIS, inc)
end

slots["Incremental Jog C+"] = function(inc)
    mc.mcJogIncStart(inst, mc.C_AXIS, inc)
end

slots["Incremental Jog X-"] = function(inc)
    mc.mcJogIncStart(inst, mc.X_AXIS, -1 * inc)
end 

slots["Incremental Jog Y-"] = function(inc) 
    mc.mcJogIncStart(inst, mc.Y_AXIS, -1 * inc)
end

slots["Incremental Jog Z-"] = function(inc)
    mc.mcJogIncStart(inst, mc.Z_AXIS, -1 * inc)
end

slots["Incremental Jog A-"] = function(inc)
    mc.mcJogIncStart(inst, mc.A_AXIS, -1 * inc)
end

slots["Incremental Jog B-"] = function(inc)
    mc.mcJogIncStart(inst, mc.B_AXIS, -1 * inc)
end

slots["Incremental Jog C-"] = function(inc)
    mc.mcJogIncStart(inst, mc.C_AXIS, -1 * inc)
end

slots["Enable Off"] = function()
    local state = mc.mcCntlGetState(inst)
    if (state ~= mc.MC_STATE_IDLE) then
        scr.StartTimer(2, 250, 1);
    end
    scr.DoFunctionName("Enable Off")
end

slots["Enable Toggle"] = function()
    if getMachSignalState(mc.OSIG_MACHINE_ENABLED) then
        slots["Enable On"]()
    else
        slots["Enable Off"]()
    end
end

slots["E Stop Toggle"] = toggleMachSignalState(mc.ISIG_EMERGENCY)

slots["Go To Work Zero"] = mc.mcCntlGotoZero(inst)

--- Below this line, slot functions depend on modules that may not be present in all Mach4 deployments ---
--- These should go in some kind of custom code section ---
slots["Torch/THC Toggle"] = function()
    local hreg = mc.mcRegGetHandle(inst, string.format("ESS/HC/Command"))
    mc.mcRegSetValueString(hreg, "(ESS_TORCH_TOGGLE=1)")
end

slots["Cycle Start/Stop"] = function()
    local state = mc.mcCntlGetState(inst)
    if state == mc.MC_STATE_IDLE or state == mc.MC_STATE_HOLD then
        scr.DoFunctionName('Cycle Start')
    elseif state > 99 and state < 200 then
        scr.DoFunctionName('Cycle Stop')
    end
end

return slots