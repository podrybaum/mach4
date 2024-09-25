if not mc then
    require("mocks")
end

--[[TODO: Most methods have 1-3 statements at the very beginning that are error checking methods of various types.  
    It may be possible to refactor all the error checking into a single function that dispatches the needed error 
    checking functions based on the method's signature.
    ]]--



inst = mc.mcGetInstance()
idMapping = {}

Controller = {}
Controller.__index = Controller
Controller.__type = "Controller"

function Controller.customType(object)
    if type(object) == "table" then
        local mt = getmetatable(object)
        return object.__type or (mt and mt.__type) or "table"
    else
        return type(object)
    end
end

function Controller.selfError()
	-- TODO: Test this, I haven't seen it triggered yet, I don't even know if it works
    local funcName = debug.getinfo(2, "n").name or "Unknown function"
    local line = debug.getinfo(2, "l").currentline or "unknown line"
    mc.mcCntlLog(inst, string.format("Method %s called with . instead of : at line %d.", funcName, line), "", -1)
end

function Controller.typeCheck(objects, types)
    local funcName = debug.getinfo(2, "n").name or "Unknown function"
    for i, object in ipairs(objects) do
        local expectedTypes = types[i]
        local actualType = Controller.customType(object)
        if type(expectedTypes) == "string" then
            expectedTypes = { expectedTypes }
        end
        local typeMatch = false
        for _, expectedType in ipairs(expectedTypes) do
            if actualType == expectedType then
                typeMatch = true
                break
            end
        end
        if not typeMatch then
            mc.mcCntlLog(inst, (string.format("Parameter %d of function %s expected one of %s, got %s.",
                i, funcName, table.concat(expectedTypes, ", "), actualType)), "", -1)
            return true
        end
    end
    return false
end

function Controller.new()
    local self = setmetatable({}, Controller)
    setmetatable(self, Controller)
    self.UP = self:newButton("DPad_UP")
    self.DOWN = self:newButton("DPad_DOWN")
    self.RIGHT = self:newButton("DPad_RIGHT")
    self.LEFT = self:newButton("DPad_LEFT")
    self.A = self:newButton("Btn_A")
    self.B = self:newButton("Btn_B")
    self.X = self:newButton("Btn_X")
    self.Y = self:newButton("Btn_Y")
    self.START = self:newButton("Btn_START")
    self.BACK = self:newButton("Btn_BACK")
    self.LTH = self:newButton("Btn_LTH")
    self.RTH = self:newButton("Btn_RTH")
    self.LSB = self:newButton("Btn_LS")
    self.RSB = self:newButton("Btn_RS")
    self.LTR = self:newTrigger("LTR_Val")
    self.RTR = self:newTrigger("RTR_Val")
    self.LTH_Y = self:newThumbstickAxis("LTH_Y_Val")
    self.RTH_X = self:newThumbstickAxis("RTH_Val")
    self.RTH_Y = self:newThumbstickAxis("RTH_Y_Val")
    self.LTH_X = self:newThumbstickAxis("LTH_X_Val")
    self.inputs = {
        self.UP, self.DOWN, self.RIGHT, self.LEFT, self.A, self.B, self.X, self.Y, self.START,
        self.BACK, self.LTH, self.RTH, self.LSB, self.RSB, self.LTR, self.RTR
    }
    self.axes = { self.LTH_X, self.LTH_Y, self.RTH_X, self.RTH_Y }
    self.shift_btn = nil
    self.jogIncrement = 0.1
    self.jogRate = 100
    self.logLevel = 2
    self.logLevels = { "ERROR", "WARNING", "INFO", "DEBUG" }

    -- TODO: Populate this with all pre-defined Slots
    self.slots = {}

    for func in pairs({ "", "Cycle Start", "Cycle Stop", "Feed Hold", "Enable On", "Enable Off", "Enable Toggle",
    "Soft Limits On", "Soft Limits Off", "Soft Limits Toggle", "Position Remember", "Position Return", "Limit OV On",
    "Limit OV Off", "Limit OV Toggle", "Jog Mode Toggle", "Jog Mode Step", "Jog Mode Continuous", "Jog X+", "Jog Y+",
    "Jog Z+", "Jog A+", "Jog B+", "Jog C+", "Jog X-", "Jog Y-", "Jog Z-", "Jog A-", "Jog B-", "Jog C-", "Home All",
    "Home X", "Home Y", "Home Z", "Home A", "Home B", "Home C" }) do
       table.insert(self.slots, self:newSlot(func, (function() scr.DoFunctionName(func) end)))
    end

    table.insert(self.slots, self:newSlot("E Stop Toggle", function() self:xcToggleMachSignalState(mc.ISIG_EMERGENCY) end))

    -- NOTE: Probably not generic enough to include as pre-defined Slot
    self.xcCntlTorchToggle = self:newSlot("Torch/THC Toggle", function()
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT3)
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT4)
    end)

    -- Deprecated in favor of scr.DoFunctionName("Enable Toggle") to be removed pending testing
    --[[self.xcCntlEnableToggle = self:newSlot("XC Enable Toggle", function()
        self:xcErrorCheck(
            mc.mcCntlEnable(
                inst, not self:xcGetMachSignalState(mc.OSIG_MACHINE_ENABLED)
            )
        )
    ]]--end)

    -- Deprecated in favor of scr.DoFunctionName("Limit OV Toggle") to be removed pending testing
    --[[self.xcCntlAxisLimitOverride = self:newSlot("XC Limit Override Toggle", function()
        self:xcToggleMachSignalState(mc.ISIG_LIMITOVER)
    ]]--end)

    -- Deprecated in favor of scr.DoFunctionName("JogModeToggle") to be removed pending testing
    --[[self.xcJogTypeToggle = self:newSlot("XC JogModeToggle", function()
        self:xcToggleMachSignalState(mc.OSIG_JOG_INC)
        self:xcToggleMachSignalState(mc.OSIG_JOG_CONT)
    ]]--end)

    -- Deprecated in favor of scr.DoFunctionName("Home All") along with ("Home X","Home Y", etc)
    --[[self.xcAxisHomeAll = self:newSlot("XC Home ALL", function() self:xcErrorCheck(mc.mcAxisHomeAll(inst)) end)
    self.xcAxisHomeX = self:newSlot("XC Home X", function() self:xcErrorCheck(mc.mcAxisHome(inst, mc.X_AXIS)) end)
    self.xcAxisHomeY = self:newSlot("XC Home Y", function() self:xcErrorCheck(mc.mcAxisHome(inst, mc.Y_AXIS)) end)
    ]]--self.xcAxisHomeZ = self:newSlot("XC Home Z", function() self:xcErrorCheck(mc.mcAxisHome(inst, mc.Z_AXIS)) end)


    table.insert(self.slots, self:newSlot("Goto Zero", function() self:xcErrorCheck(mc.mcCntlGotoZero(inst)) end))

    -- Deprecated in favor of scr.DoFunctionName("Reset") to be removed pending testing
    -- self.xcCntlReset = self:newSlot(function() self:xcErrorCheck(mc.mcCntlReset(inst)) end)

    table.insert(self.slots, self:newSlot("XC Run Cycle Toggle", function()
        local state, rc = mc.mcCntlGetState()
        self:xcErrorCheck(rc)
        if state == mc.MC_STATE_IDLE or state == mc.MC_STATE_HOLD then
            scr.DoFunctionName('Cycle Start')
        elseif state == mc.MCSTATE_FRUN_SUB or state == mc.MC_STATE_MRUN_SUB or state == mc.MC_STATE_DRYRUN then
            scr.DoFunctionName('Cycle Stop')
        else
            self:xcCntlLog('Attempt to Start/Stop cycle: machine is in invalid state.', 2)
            return
        end
    end))
        
    return self
end

-- Convenience method for retrieving a pre-defined slot by its id
function Controller:xcGetSlotById(id)
    if not self then Controller.selfError() return end
    if self.typeCheck({id}, {"string"}) then return end
    for slot in pairs(self.slots) do
        if slot.id == id then
            return slot
        end
    end
    self:xcCntlLog(string.format("No slot with id %s found", id), 1)
end

-- Convenience method for retrieving register values in a single call with error handling.
function Controller:xcGetRegValue(reg)
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ reg }, { "string" }) then return end
    local hreg, rc = mc.mcRegGetHandle(inst, reg)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcRegGetValueLong(hreg)
        if rc == mc.MERROR_NOERROR then
            return val
        else
            self:xcCntlLog("Error in mcRegGetValueLong", 1)
            self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
        end
    else
        self:xcCntlLog("Error in mcRegGetHandle", 1)
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

-- Convenience method for checking Mach4 signal states with a single call and error handling.
-- Note, this returns a boolean (true or false) instead of the numeric (1 or 0) values returned by the Mach4 function.
function Controller:xcGetMachSignalState(signal)
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ signal }, { "number" }) then return end
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcSignalGetState(hsig)
        if rc == mc.MERROR_NOERROR then
            return val > 0
        else
            self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
        end
    else
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

-- Convenience method to toggle the state of a Mach4 signal with a single call and error handling.
function Controller:xcToggleMachSignalState(signal)
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ signal }, { "number" }) then return end
    local hsig = mc.mcSignalGetHandle(inst, signal)
    self:xcErrorCheck(mc.mcSignalSetState(hsig, not mc.mcSignalGetState(inst, hsig)))
end

-- Logger method
function Controller:xcCntlLog(msg, level)
    if not self then
        Controller.selfError()
        return
    end
    if Controller.typeCheck({ msg, level }, { "string", "number" }) then return end
    if self.logLevel == 0 then return end
    if level <= self.logLevel then
        if mc.mcInEditor() ~= 1 then
            mc.mcCntlLog(inst, "[[XBOX CONTROLLER " .. self.logLevels[self.logLevel] .. "]]: " .. msg, "", -1)
        else
            print("[[XBOX CONTROLLER " .. self.logLevels[self.logLevel] .. "]]: " .. msg)
        end
    end
end

-- check Mach4 return codes for errors with error handling
-- TODO: Should this function maybe return a boolean? or return the error string insead of logging it directly?
function Controller:xcErrorCheck(rc)
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ rc }, { "number" }) then return end
    if rc ~= mc.MERROR_NOERROR then
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

-- Setter method for controller jog increment
-- TODO: Add to controller config
function Controller:xcJogSetInc(val)
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ val }, { "number" }) then return end
    self.jogIncrement = val
    self:xcCntlLog("Set jogIncrement to " .. tostring(self.jogIncrement), 4)
end

-- Setter method for controller jog rate
function Controller:xcJogSetRate(val)
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ val }, { "number" }) then return end
    self.jogRate = val
    self:xcCntlLog("Set jogRate to " .. tostring(self.jogRate), 4)
end

-- The loop method for input polling
function Controller:update()
    if not self then
        Controller.selfError()
        return
    end
    if self.shift_btn ~= nil then
        self.shift_btn:getState()
    end
    for _, input in pairs(self.inputs) do
		if input ~= self.shift_btn then
			input:getState()
		end
    end
    for _, axis in pairs(self.axes) do
        axis:update()
    end
end

function Controller:assignShift(input)
    -- added warning message when overriding an assigned shift button
    -- shift button is no longer removed from the Controller.inputs list.  This was needed by the new GUI config.
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ input }, { { "Button", "Trigger" } }) then return end

    if self.shift_btn ~= nil then
        self:xcCntlLog(string.format("Call to assign a shift button with a shift button already assigned.  %s will be unassigned before assigning new shift button.", self.shift_btn.id), 2)
    end
    self.shift_btn = input
    self:xcCntlLog("" .. input.id .. " assigned as controller shift button.", 3)
	-- The section below has been deprecated by the new GUI config manager, to be removed pending testing
    --[[for i, input in ipairs(self.inputs) do
        if input == self.shift_btn then
            table.remove(self.inputs, i)
            return
        end
    ]]--end
end

function Controller:mapSimpleJog(reversed)
	-- TODO: Connect this to the GUI configurator, implement it as a default, or deprecate it.
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ reversed }, { { "boolean", "nil" } }) then return end
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s", tostring(reversed)), 4)
    -- DPad regular jog
    self.UP.down:connect(self:newSlot(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_POS)
    end))
    self.UP.up:connect(self:newSlot(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS)
    end))
    self.DOWN.down:connect(self:newSlot(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_NEG)
    end))
    self.DOWN.up:connect(self:newSlot(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS)
    end))
    self.RIGHT.down:connect(self:newSlot(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_POS)
    end))
    self.RIGHT.up:connect(self:newSlot(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS)
    end))
    self.LEFT.down:connect(self:newSlot(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_NEG)
    end))
    self.LEFT.up:connect(self:newSlot(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS)
    end))
    if reversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end

    self.UP.down:connect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, self.jogIncrement)
    end), true)
    self.DOWN.down:connect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, -1 * self.jogIncrement)
    end), true)
    self.RIGHT.down:connect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, self.jogIncrement)
    end), true)
    self.LEFT.down:connect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, -1 * self.jogIncrement)
    end), true)
    if reversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function", 3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
end

function Controller:newSignal(button, id)
    if not self then
        Controller.selfError()
        return
    end
    if Controller.typeCheck({ button, id }, { { "Button", "Trigger" }, "string" }) then return end
    return self.Signal.new(self, button, id)
end

Controller.Signal = {}
Controller.Signal.__index = Controller.Signal
Controller.Signal.__type = "Signal"

function Controller.Signal.new(controller, button, id)
    local self = setmetatable({}, Controller.Signal)
    self.id = id
    self.button = button
    self.controller = controller
    self.slot = nil
    self.altSlot = nil
    return self
end

-- connect a Signal to a Slot.  pass true (or anything besides false or nil) to the alt parameter to connect alternate Slot
-- alternate Slot fires when Signal is emitted while an assigned shift button is pressed
function Controller.Signal:connect(slot, alt)
    if not self then
        Controller.selfError()
        return
    end
    if self.controller:typeCheck({ slot }, { "Slot" }) then return end
    if self.controller.shift_btn == self.button then
        self.controller:xcCntlLog("Ignoring call to connect a Slot to an assigned shift button!", 2)
        return
    end
    local alt = alt or false
    if self.slot ~= nil then
        self.controller:xcCntlLog(string.format("Signal %s of input %s already has a connected slot.  Did you mean to override it?", self.id, self.button.id), 2)
    end
    self.slot = slot
    self.controller:xcCntlLog(self.button.id .. self.id .. " connected to Slot " .. self.slot.id, 4)
    if alt then
        if self.altSlot ~= nil then
            self.controller:xcCntlLog(string.format("Signal %s of input %s already has a connected alternate slot.  Did you mean to override it?", self.id, self.button.id), 2)
        end
        self.altSlot = slot
        self.controller:xcCntlLog(self.button.id .. self.id .. " connected to Alt Slot " .. self.altSlot.id, 4)
    end
end

-- Deprecated in favor of Controller.Signal:connect(slot, alt=true) to be removed pending testing
--[[function Controller.Signal:altConnect(slot)
    if not self then
        Controller.selfError()
        return
    end
    if self.controller:typeCheck({ slot }, { "Slot" }) then return end
    if self.controller.shift_btn == self.button then
        self.controller:xcCntlLog("Ignoring call to connect a Slot to an assigned shift button!", 2)
        return
    end
    if self.altSlot ~= nil then
        self.controller:xcCntlLog(string.format("Signal %s of input %s already has a connected alternate slot.  Did you mean to override it?", self.id, self.button.id), 2)
    end
    self.altSlot = slot
    self.controller:xcCntlLog(self.button.id .. self.id .. " connected to Alt Slot " .. self.altSlot.id, 4)
]]--end

-- NOTE: We could implement a check to make sure we don't allow an assigned shift button to emit any Signals, but that *should* be impossible.
function Controller.Signal:emit()
    if not self then
        Controller.selfError()
        return
    end
    self.controller:xcCntlLog("Signal " .. self.button.id .. self.id .. " emitted.", 3)
    if (self.controller.shift_btn == nil or not self.controller.shift_btn.pressed) and (self.slot ~= nil) then
        self.slot.func()
    elseif (self.controller.shift_btn ~= nil and self.controller.shift_btn.pressed) and (self.altSlot ~= nil) then
        self.altSlot.func()
    end
end

function Controller:newButton(id)
    if not self then
        Controller.selfError()
        return
    end
    if self.typeCheck({ id }, { "string" }) then return end
    return self.Button.new(self, id)
end

Controller.Button = {}
Controller.Button.__index = Controller.Button
Controller.Button.__type = "Button"


function Controller.Button.new(controller, id)
    local self = setmetatable({}, Controller.Button)
    self.controller = controller
    self.id = id
    self.pressed = false
    self.up = controller:newSignal(self, "up")
    self.down = controller:newSignal(self, "down")
    return self
end

function Controller.Button:getState()
    -- added check to ensure that an assigned shift button will not emit Signals.
    if not self then
        self.controller.selfError()
        return
    end
    local state = self.controller:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(state) ~= "number" then
        self.controller:xcCntlLog(string.format("Invalid state for %s", self.id), 1)
        return
    end
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        if self.controller.shift_btn ~= self then
            self.down:emit()
        end
    elseif (state == 0) and self.pressed then
        self.pressed = false
        if self.controller.shift_btn ~= self then
            self.up:emit()
        end
    end
end

-- this method returns the various inputs needed to populate the "properties" panel in the gui configurator
-- TODO: There's got to be a way to do all of this in a loop or something.   This is not very DRY.
-- TODO: Predefined Slots will be added to a list assigned to an attribute of the Controller instance.  The "choiceOptions" value in this method should point at that list.
function Controller.Button:initUi(window)
	if not self then
		self.controller.selfError()
		return
	end

    local function capital(str)
        local first = string.upper(string.sub(str,1,1))
        local rest = string.sub(str,2)
        return first..rest
    end

    local signals = {"up", "down"}
    local output = {}

    local options = {}

    for slot in pairs(self.controller.slots) do
        table.insert(options, slot.id)
    end

    for signal in pairs(signals) do
        table.insert(output, wx.wxStaticText(window, wx.wxID_ANY, string.format("%s Action:",capital(signal))))
        table.insert(output, wx.wxStaticText(window, wx.wxID_ANY, string.format("Alternate %s Action:",capital(signal))))
        idMapping[string.format("choice%sId", capital(signal))] = {id=wx.wxNewId(), input=self, signal=signal}
        idMapping[string.format("choice%sAltId", capital(signal))] = {id=wx.wxNewId(), input=self, signal=signal}
        table.insert(output, wx.wxChoice(window, idMapping[string.format("choice%sId", capital(signal))].id, wx.wxDefaultPosition, wx.wxDefaultSize, options))
        table.insert(output, wx.wxChoice(window, idMapping[string.format("choice%sAltId", capital(signal))].id, wx.wxDefaultPosition, wx.wxDefaultSize, options))
        if self[signal].slot ~= nil then
            output[-2].SetSelection(output[-2].FindString(self.up.slot.id) or output[-2].FindString(""))
        end
        if self[signal].altSlot ~= nil then
            output[-1].SetSelection(output[-1].FindString(self.up.slot.id) or output[-1].FindString(""))
        end
    end

    -- Deprecated in favor of above loop, to be removed pending testing
	--local lblUp = wx.wxStaticText(window, wx.wxID_ANY, "Up Action:")
	--local lblDown = wx.wxStaticText(window, wx.wxID_ANY, "Down Action:")
	--local lblUpAlt = wx.wxStaticText(window, wx.wxID_ANY, "Alternate Up Action:")
	--local lblDownAlt = wx.wxStaticText(window, wx.wxID_ANY, "Alternate Down Action:")
	--local choiceUpId, choiceDownId, choiceUpAltId, choiceDownAltId = wx.wxNewId(), wx.wxNewId(), wx.wxNewId(), wx.wxNewId()
	--idMapping[choiceUpId] = { input = self, signal = "up" }
	--idMapping[choiceDownId] = { input = self, signal = "down" }
	--idMapping[choiceUpAltId] = { input = self, signal = "altUp" }
	--idMapping[choiceDownAltId] = { input = self, signal = "altDown" }
	--local choiceUp = wx.wxChoice(window, choiceUpId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	--local choiceDown = wx.wxChoice(window, choiceDownId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	--local choiceUpAlt = wx.wxChoice(window, choiceUpAltId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	--local choiceDownAlt = wx.wxChoice(window, choiceDownAltId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	--[[if self.up.slot ~= nil then
		output[3].SetSelection(output[3].FindString(self.up.slot.id) or output[3].FindString(""))
	end
	if self.up.altSlot ~= nil then
		output[4].SetSelection(output[4].FindString(self.up.altSlot.id) or output[4].FindString(""))
	end
	if self.down.slot ~= nil then
		output[7].SetSelection(output[7].FindString(self.down.slot.id) or output[7].FindString(""))
	end
	if self.down.altSlot ~= nil then
		output[8].SetSelection(output[8].FindString(self.down.altSlot.id) or output[8].FindString(""))
	end
	]]--return lblUp, choiceUp, lblDown, choiceDown, lblUpAlt, choiceUpAlt, lblDownAlt, choiceDownAlt
    return output
end


-- TODO: Trigger should probably be a subclass of Button.  Trigger is simply extending Button's functionality.
function Controller:newTrigger(id)
    return self.Trigger.new(self, id)
end

Controller.Trigger = Controller.Button.new()
Controller.Trigger.__type = "Trigger"

function Controller.Trigger.new(controller, id)
    if controller.typeCheck({ controller, id }, { "Controller", "string" }) then return end
    local self = setmetatable({}, Controller.Trigger)
    self.controller = controller
    self.id = id
    self.value = 0
    self.pressed = false
    self.down = controller:newSignal(self, "down")
    self.up = controller:newSignal(self, "up")
    self.func = nil
    return self
end

function Controller.Trigger:getState()
    if not self then
        Controller.selfError()
        return
    end
    self.value = self.controller:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(self.value) ~= "number" then
        self.controller:xcCntlLog("Invalid state for " .. self.id, 1)
        return
    end
    --important to return here, we want to lock out Button type functionality
    --if a Trigger has been assigned as an analog control.
    if self.func ~= nil then
        self.func(self.value)
        return
    end
    if math.abs(self.value) > 125 and not self.pressed then
        self.down.emit()
        self.pressed = true
    elseif math.abs(self.value) < 5 and self.pressed then
        self.up.emit()
        self.pressed = false
    end
end


-- Deprecated by inheritance from Button
--[[function Controller.Trigger:initUi(window)
	if not self then
		self.controller.selfError()
		return
	end
	local lblUp = wx.wxStaticText(window, wx.wxID_ANY, "Up Action:")
	local lblDown = wx.wxStaticText(window, wx.wxID_ANY, "Down Action:")
	local lblUpAlt = wx.wxStaticText(window, wx.wxID_ANY, "Alternate Up Action:")
	local lblDownAlt = wx.wxStaticText(window, wx.wxID_ANY, "Alternate Down Action:")
	local choiceUpId, choiceDownId, choiceUpAltId, choiceDownAltId = wx.wxNewId(), wx.wxNewId(), wx.wxNewId(), wx.wxNewId()
	idMapping[choiceUpId] = { input = self, signal = "up" }
	idMapping[choiceDownId] = { input = self, signal = "down" }
	idMapping[choiceUpAltId] = { input = self, signal = "altUp" }
	idMapping[choiceDownAltId] = { input = self, signal = "altDown" }
	local choiceUp = wx.wxChoice(window, choiceUpId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	local choiceDown = wx.wxChoice(window, choiceDownId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	local choiceUpAlt = wx.wxChoice(window, choiceUpAltId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	local choiceDownAlt = wx.wxChoice(window, choiceDownAltId, wx.wxDefaultPosition, wx.wxDefaultSize, choiceOptions)
	if self.up.slot ~= nil then
		choiceUp.SetSelection(choiceUp.FindString(self.up.slot.id) or choiceUp.FindString(""))
	end
	if self.up.altSlot ~= nil then
		choiceUpAlt.SetSelection(choiceUpAlt.FindString(self.up.altSlot.id) or choiceUpAlt.FindString(""))
	end
	if self.down.slot ~= nil then
		choiceDown.SetSelection(choiceDown.FindString(self.down.slot.id) or choiceDown.FindString(""))
	end
	if self.down.altSlot ~= nil then
		choiceDownAlt.SetSelection(choiceDownAlt.FindString(self.down.altSlot.id) or choiceDownAlt.FindString(""))
	end
	return lblUp, choiceUp, lblDown, choiceDown, lblUpAlt, choiceUpAlt, lblDownAlt, choiceDownAlt
]]--end


-- TODO: We expect the function passed to the connect method to have a specific signature, namely it should take a single numeric parameter.  Is this something we can validate?
function Controller.Trigger:connect(func)
    if not self then
        Controller.selfError()
        return
    end
    if self.controller.typeCheck({ func }, { "function" }) then return end
    self.func = func
end

function Controller:newThumbstickAxis(id)
    return self.ThumbstickAxis.new(self, id)
end

Controller.ThumbstickAxis = {}
Controller.ThumbstickAxis.__index = Controller.ThumbstickAxis
Controller.ThumbstickAxis.__type = "ThumbstickAxis"

function Controller.ThumbstickAxis.new(controller, id)
    if controller.typeCheck({ controller, id }, { "Controller", "string" }) then return end
    local self = setmetatable({}, Controller.ThumbstickAxis)
    self.controller = controller
    self.id = id
    self.axis = nil
    self.inverted = false
    self.deadzone = 10
    self.rate = nil
    self.value = 0
    self.moving = false
    self.rateSet = false
    return self
end

function Controller.ThumbstickAxis:setDeadzone(deadzone)
    if not self then
        Controller.selfError()
        return
    end
    if self.controller.typeCheck({ deadzone }, { "number" }) then return end
    self.deadzone = math.abs(deadzone)
end

function Controller.ThumbstickAxis:connect(axis, inverted)
    if not self then
        Controller.selfError()
        return
    end
    if self.controller.typeCheck({ axis, inverted }, { "number", "boolean" }) then return end
    self.axis = axis
    self.inverted = inverted
    local rc
    self.rate, rc = mc.mcJogGetRate(inst, self.axis)
    self.controller:xcErrorCheck(rc)
    self.controller:xcCntlLog(self.id .. " connected to " .. tostring(self.axis), 4)
    self.controller:xcCntlLog("Initial jog rate for " .. tostring(self.axis) .. " = " .. self.rate, 4)
end

--[[ TODO: Something seems to be not working entirely as intended with this method, as once in awhile the connected axis seems to 
    stay stuck at some arbitrary jog rate it was set to, and will continue to move in response to stick input, but will not update the jog rate
    with respect to the analog value.  Releasing the stick completely and starting to move again seems to reset this condition.  Not sure what's causing that.
]]--- 
--- TODO: It's probably possible to do all of our jog rate updating for the thumbstick analog control without actually updating Mach4's jog rate value.  We should probably 
--- create our own jog rate value, track it on an instance attribute and refer to that instead.
function Controller.ThumbstickAxis:update()
    if not self then
        Controller.selfError()
        return
    end
    if self.axis == nil then return end
    self.value = self.controller:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(self.value) ~= "number" then
        self.controller:xcCntlLog("Invalid value for ThumbstickAxis", 1)
        return
    end
    if not self.moving and not self.rateReset then
        if mc.mcJogGetRate(inst, self.axis) ~= self.rate then
            mc.mcJogSetRate(inst, self.axis, self.rate)
            self.rateReset = true
        end
    end

    if math.abs(self.value) > self.deadzone and not self.moving then
        self.moving = true
        self.rateReset = false
        self.controller:xcErrorCheck(mc.mcJogSetRate(inst, self.axis, math.abs(self.value)))
        local direction
        if self.inverted then
            direction = (self.value > 0) and mc.MC_JOG_NEG or mc.MC_JOG_POS
        else
            direction = (self.value > 0) and mc.MC_JOG_POS or mc.MC_JOG_NEG
        end

        self.controller:xcErrorCheck(mc.mcJogVelocityStart(inst, self.axis, direction))
    end

    if math.abs(self.value) < self.deadzone and self.moving then
        self.controller:xcErrorCheck(mc.mcJogVelocityStop(inst, self.axis))
        self.moving = false
        self.controller:xcErrorCheck(mc.mcJogSetRate(inst, self.axis, self.rate))
        self.rateReset = true
    end
end

function Controller:newSlot(id, func)
    -- added a new 'id' attribute for Slots that we need to get from the constructor
    return self.Slot.new(self, id, func)
end

Controller.Slot = {}
Controller.Slot.__index = Controller.Slot
Controller.Slot.__type = "Slot"

function Controller.Slot.new(controller, id, func)
    if Controller.typeCheck({ id, func }, { "string", "function" }) then return end
    local self = setmetatable({}, Controller.Slot)
	self.id = id
    self.controller = controller
    self.func = func
    return self
end

xc = Controller.new()
---------------------------------
--- Custom Configuration Here ---

--- TODO: consider updating documentation to not mention any manual configuration of the controller object outside of the
--- "Advanced Usage" section.  When the GUI is fully working, most users will never need to do anything here.  
--- TODO: update the GUI configurator to include a section of properties that are configured at the Controller level, such as
--- logging level, axes inversions and reversals, etc. 
xc.logLevel = 4
xc:assignShift(xc.LTR)
xc.RTH_Y:connect(mc.Z_AXIS)
xc:mapSimpleJog(true)
xc.B.down:connect(xc.xcCntlEStopToggle)
xc.Y.down:connect(xc.xcCntlTorchToggle)
xc.RSB.down:connect(xc.xcCntlEnableToggle)
xc.X.down:connect(xc.xcCntlCycleStart)
xc.BACK.down:connect(xc.xcAxisHomeAll, true)
xc.START.down:connect(xc.xcAxisHomeZ, true)

-- End of custom configuration ---
----------------------------------
---
--[[ TODO: The current method of mocking the mcLuaPanelParent object doesn't actually work right, wxPanel is not a top-level gui object.
  We need to implement a mock that actually works and renders our GUI when we're not running connected to a live Mach4 instance.
  ]]--

if mc.mcInEditor() == 1 then
    wx = require("wx")
    mcLuaPanelParent = wx.wxPanel()
end

-- Create the main sizer (horizontal layout with input list on the left and properties on the right)
--[[ TODO: It seems as though there should be a second column alongside the input list that displays 
    some sort of information about the current configuration state for each input.  Perhaps something 
    like "(#) connected Signals", "Assigned as shift button," where appropriate would suffice.
    
    Trigger objects need to be implemented as either analog controls OR buttons (not both at once), so we could 
    also display something like: "Button mode with 2 connected Signals" or "Analog mode with connection function" 
    for trigger objects.

    ThumbstickAxis objects only have one potential state, which is connection to the movement of an axis, so 
    "Connected to machine X Axis", etc or "Not Connected" is probably sufficient.

    Thinking about it in terms of the refactoring done up to now, we may want to populate this field from an
    attribute on the input object, as that would be the appropriate place for what amounts to state information 
    for the object.

    Additional NOTE: Would a single panel with a tree view be intuitive for most users? Each input would have
    it's Signal and or Analog input members as children, and each child could display the state of it's current configuration
    when expanded.  This makes the entire config easy to reach without jamming it all into the screen when it's not
    needed.  The controller ojbect would then have its various configurable settings as children, along with the input
    objects... which may be less intuitive.  

    A hybrid implementation of the tree view and the properties panel would exactly parallel how the Mach4 screen editor
    is set up, thus keeping our GUI "extension" consistent with the GUI's design.  
]]--
local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)


-- Create the input list (left side)
local inputList = wx.wxListCtrl(mcLuaPanelParent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(200, -1),
    wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL)
inputList:InsertColumn(0, "Inputs", wx.wxLIST_FORMAT_LEFT, 150)


-- Add input instances to the list
for i, input in ipairs(xc.inputs) do
    inputList:InsertItem(i, input.id)
end
for i, axis in ipairs(xc.axes) do
    inputList:InsertItem(i + #xc.inputs, axis.id)
end

mainSizer:Add(inputList, 0, wx.wxEXPAND + wx.wxALL, 5)

-- Event handler for when an input is selected

inputList:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED, function(event)
    local index = event:GetIndex() + 1
    local selectedInput
    if index <= #xc.inputs then
        selectedInput = xc.inputs[index]
    elseif index <= #xc.inputs + 4 then
        selectedInput = xc.axes[index - #xc.inputs]
    end
    -- Refresh the properties panel based on selected input
    refreshPropertiesPanel(selectedInput)
end)



--[[ TODO: This list should probably belong to the Controller object, and instead of a list of strings, be a list of pre-defined Slot objects
     A dispatch method could be created, example getSlotById(id) which returns the Slot object with the given name.
    ]]--
local choiceOptions = { "", "Cycle Start", "Cycle Stop", "Feed Hold", "Enable On", "Enable Off", "Enable Toggle",
    "Soft Limits On", "Soft Limits Off", "Soft Limits Toggle", "Position Remember", "Position Return", "Limit OV On",
    "Limit OV Off", "Limit OV Toggle", "Jog Mode Toggle", "Jog Mode Step", "Jog Mode Continuous", "Jog X+", "Jog Y+",
    "Jog Z+", "Jog A+", "Jog B+", "Jog C+", "Jog X-", "Jog Y-", "Jog Z-", "Jog A-", "Jog B-", "Jog C-", "Home All",
    "Home X", "Home Y", "Home Z", "Home A", "Home B", "Home C" }

-- TODO: Move this logic to the Controller object probably
local choiceSlots = {}
for i, choice in ipairs(choiceOptions) do
    choiceSlots[choice] = xc.Slot.new(function() scr.DoFunctionName(choice) end)
end
choiceSlots["E Stop Toggle"] = xc.xcCntlEStopToggle
choiceSlots["Goto Zero"] = xc.xcCntlGotoZero

-- TODO: This is probably best inlined into the ThumbstickAxis object's initUi method
local axisChoices = { "mc.X_AXIS", "mc.Y_AXIS", "mc.Z_AXIS" }

-- Create the properties panel (right side)
-- TODO: Make this more closely follow the style of the Properties panel in the Mach4 screen editor.
local propertiesPanel = wx.wxPanel(mcLuaPanelParent, wx.wxID_ANY)
local propertiesSizer = wx.wxFlexGridSizer(0, 2, 0, 0) -- 2 columns: label and control

propertiesPanel:SetSizer(propertiesSizer)

mainSizer:Add(propertiesPanel, 1, wx.wxEXPAND + wx.wxALL, 5)

--[[ TODO: I vaguely recall reading something about how this method of defining event handlers can handle connecting
    events directly to other object's methods or even lambda functions.  At any rate, the event table method isn't available in wxLua
    Since the main thing likely to occur in our event handler is connecting a Signal to a Slot, perhaps this should just
    be calling the Signal:connect methods on Signal objects belonging to the respective input objects.

    Maybe each input object should simply have a method that returns an entire PropertiesPanel object, which then Connects its event
    handler directly to it's parent object's various methods?  That's essentially what's happening here with the internal onChoiceSelected
    function, which is simply a dispatch functioning calling the appropriate methods on the appropriate instances.  Maybe this would eliminate
    the need for mapping the wxIds to input objects, since the method can simply refer to it's parent object?
--]]


-- Function to refresh the properties panel when a new input is selected
function refreshPropertiesPanel(input)
    -- Clear the existing controls in the properties panel
    propertiesSizer:Clear(true)

    -- TODO: This code smells like something that could be done in some kind of a loop.  There's a lot of repetition here.
    local function onChoiceSelected(event)
        local id, selected = event:GetId(), event:GetString()
        local input, signal = table.unpack(idMapping[id])

        if signal == "up" then
            if signal == "" then
                input.up.slot = nil
                return
            end
            input.up:connect(choiceSlots[selected])
        elseif signal == "down" then
            if signal == "" then
                input.down.slot = nil
                return
            end
            input.down:connect(choiceSlots[selected])
        elseif signal == "altUp" then
            if signal == "" then
                input.up.altSlot = nil
                return
            end
            input.up:connect(choiceSlots[selected], true)
        elseif signal == "altDown" then
            if signal == "" then
                input.down.altSlot = nil
                return
            end
            input.down:connect(choiceSlots[selected], true)
        elseif signal == "analog" then
            input:connect(selected)
        elseif signal == "shift" then
            xc.assignShift(input)
        end
    end

    -- Add Signal config inputs to the panel
    if input.__type == "Button" or input.__type == "Trigger" and xc.shift_btn ~= input then
        -- TODO: More code that seems like it might be best executed in some sort of a loop.
		if xc.shift_btn ~= input then 
			local lblUp, choiceUp, lblDown, choiceDown, lblAltUp, choiceAltUp, lblAltDown, choiceAltDown = input:initUi(propertiesPanel)
			propertiesSizer:Add(lblUp, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 1)
			propertiesSizer:Add(choiceUp, 0, wx.wxEXPAND + wx.wxALL, 1)
			propertiesSizer:Add(lblDown, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 1)
			propertiesSizer:Add(choiceDown, 1, wx.wxEXPAND + wx.wxALL, 1)
			propertiesSizer:Add(lblAltUp, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 1)
			propertiesSizer:Add(choiceAltUp, 0, wx.wxEXPAND + wx.wxALL, 1)
			propertiesSizer:Add(lblAltDown, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 1)
			propertiesSizer:Add(choiceAltDown, 1, wx.wxEXPAND + wx.wxALL, 1)

			propertiesPanel:Connect(choiceUp.id, wx.wxEVT_COMMAND_CHOICE_SELECTED, onChoiceSelected)
			propertiesPanel:Connect(choiceDown.id, wx.wxEVT_COMMAND_CHOICE_SELECTED, onChoiceSelected)
			propertiesPanel:Connect(choiceAltUp.id, wx.wxEVT_COMMAND_CHOICE_SELECTED, onChoiceSelected)
			propertiesPanel:Connect(choiceAltDown.id, wx.wxEVT_COMMAND_CHOICE_SELECTED, onChoiceSelected)
		end
    end

	-- add analog config inputs to the panel
    --[[ TODO: lift out the creation of the gui elements (which depend on the config state of a particular input)
        and refactor into the respective classes.]]
    if input.__type == "Trigger" or input.__type == "ThumbstickAxis" then
        if xc.shift_btn ~= input then
            -- Add "Analog Action" label and dropdown
            local lblAnalog = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Analog Action:")
            local choiceAnalogId = wx.wxNewId()
            local choiceAnalog = wx.wxChoice(propertiesPanel, choiceAnalogId, wx.wxDefaultPosition, wx.wxDefaultSize,
                axisChoices)
            idMapping[choiceAnalogId] = { input = input, signal = "analog" }
            propertiesSizer:Add(lblAnalog, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
            propertiesSizer:Add(choiceAnalog, 1, wx.wxEXPAND + wx.wxALL, 5)
            propertiesPanel:Connect(choiceAnalogId, wx.wxEVT_COMMAND_CHOICE_SELECTED, onChoiceSelected)
        end
    end

	-- add shift button inputs to the panel
    --[[ TODO: This feels like the wrong place to do this, since the shift button assignment really belongs to the Controller,
        not the inputs.  We should probably lift this logic out into a "Controller-level" configuration menu/panel.]]
    if input.__type == "Trigger" or input.__type == "Button" then
        local sig, lbl
        if xc.shift_btn ~= input then
            sig, lbl = "shift", "Assign as Shift"
        else
            sig, lbl = "unassign", "Unassign as Shift"
        end
        local shiftButtonId = wx.wxNewId()
        local shiftButton = wx.wxButton(propertiesPanel, shiftButtonId, lbl, wx.wxDefaultPosition, wx.wxDefaultSize)
        propertiesSizer:Add(shiftButton, 0, wx.wxALIGN_CENTER_VERTICAL)
        propertiesSizer:Add(0, 0)
        idMapping[shiftButtonId] = { input = input, signal = sig }
        propertiesPanel:Connect(shiftButtonId, wx.wxEVT_BUTTON, onChoiceSelected)
    end
    -- Add controls to the sizer
    -- Refresh the layout to apply changes

    propertiesSizer:Layout()
    propertiesPanel:Layout()
    propertiesPanel:Refresh()
end

mcLuaPanelParent:SetSizer(mainSizer)

mainSizer:Layout()


--[[ TODO: Is 100ms the right rate to be polling the inputs?  If 250ms(or some other longer amount of time) would be sufficient, 
    the code would be more performant in terms of impact on the system itself, which is something we should at least be 
    considering in a CNC application.  Setting the timer too long would result in the machine's response to controller inputs 
    feeling sluggish, which is also unacceptable. Should probably do some testing to find a good happy medium value.]]
xc:xcCntlLog("Creating X360_timer", 4)
X360_timer = wx.wxTimer(mcLuaPanelParent)
mcLuaPanelParent:Connect(wx.wxEVT_TIMER, function() xc:update() end)
xc:xcCntlLog("Starting X360_timer", 4)
X360_timer:Start(100)
