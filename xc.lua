xc = {}

xc.Controller = {}

function xc.Controller:new()
    local object = {}
    setmetatable(object, {__index = self})
    object.UP = Button:new(object, "DPad_UP")
    object.DOWN = Button:new(object, "DPad_DOWN")
    object.RIGHT = Button:new(object, "DPad_RIGHT")
    object.LEFT = Button:new(object, "DPad_LEFT")
    object.A = Button:new(object, "Btn_A")
    object.B = Button:new(object, "Btn_B")
    object.X = Button:new(object, "Btn_X")
    object.Y = Button:new(object, "Btn_Y")
    object.START = Button:new(object, "Btn_START")
    object.BACK = Button:new(object, "Btn_BACK")
    object.LTH = Button:new(object, "Btn_LTH")
    object.RTH = Button:new(object, "Btn_RTH")
    object.LSB = Button:new(object, "Btn_LS")
    object.RSB = Button:new(object, "Btn_RS")
    object.LTR = Analog:new(object, "LTR_Val")
    object.RTR = Analog:new(object, "RTR_Val")
    object.LTH_X = Analog:new(object, "LTH_X_Val")
    object.LTH_Y = Analog:new(object, "LTH_Y_Val")
    object.RTH_X = Analog:new(object, "RTH_Val")
    object.RTH_Y = Analog:new(object, "RTH_Y_Val")
    object.inputs = {
        object.UP, object.DOWN, object.RIGHT, object.LEFT, object.A, object.B, object.X, object.Y, object.START,
        object.BACK, object.LTH, object.RTH, object.LSB, object.RSB, object.LTR, object.RTR, object.LTH_X, object.LTH_Y,
        object.RTH_X, object.RTH_Y
    }
    object.LTH_X_Axis = ThumbstickAxis:new(object, object.LTH_X)
    object.LTH_Y_Axis = ThumbstickAxis:new(object, object.LTH_Y)
    object.RTH_X_Axis = ThumbstickAxis:new(object, object.RTH_X)
    object.RTH_Y_Axis = ThumbstickAxis:new(object, object.RTH_Y)
    object.axes = {object.LTH_X_Axis, object.LTH_Y_Axis, object.RTH_X_Axis, object.RTH_Y_Axis}
    object.shift_btn = nil
    object.jogIncrement = 0.1
    object.logLevel = 1
    object.xcLOG_ERROR = "ERROR"
    object.xcLOG_WARNING = "WARNING"
    object.xcLOG_INFO = "INFO"
    object.xcLOG_DEBUG = "DEBUG"
    object.logLevels = {object.xcLOG_ERROR, object.xcLOG_WARNING, object.xcLOG_INFO, object.xcLOG_DEBUG}

    object.xcCntlEStop = Slot:new(function()
		local hsig = mc.mcSignalGetHandle(inst, mc.ISIG_EMERGENCY)
		local state = mc.mcSignalGetState(hsig)
		mc.mcSignalSetState(hsig, state and true or false)
    end)

    object.xcCntlTorchOn = Slot:new(function()
		local hsig = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT3)
		local hsig2 = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT4)
		local state = mc.mcSignalGetState(hsig)
		local state2 = mc.mcSignalGetState(hsig2)
		mc.mcSignalSetState(hsig, state and true or false)
		mc.mcSignalSetState(hsig2, state and true or false)
    end)

    object.xcCntlEnable = Slot:new(function()
		local hsig = mc.mcSignalGetHandle(inst, mc.OSIG_MACHINE_ENABLED)
		local state = mc.mcSignalGetState(hsig)
		mc.mcCntlEnable(inst, state and true or false)
    end)

    object.xcCntlCycleStart = Slot:new(function()
		local hsig = mc.mcSignalGetHandle(inst, mc.OSIG_RUNNING_GCODE)
		local state = mc.mcSignalGetState(hsig)
		if state then
			mc.mcCntlFeedHold(inst)
		else
			mc.mcCntlCycleStart(inst)
		end
    end)

    return object
end

function xc.Controller:xcCntlLog(msg, level)
    print(msg, level)
    if self.logLevel == 0 then return end
    print(level, self.logLevel)
    if level <= self.logLevel then
        mc.mcCntlLog(inst, "[[XBOX CONTROLLER "..self.logLevels[self.logLevel].."]]: "..msg, "", -1)
    end
end

function xc.Controller:xcErrorCheck(rc)
    if rc ~= mc.MERROR_NOERROR then
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

function xc.Controller:xcJogGetInc()
    return self.jogIncrement
end

function xc.Controller:xcJogSetInc(val)
    if type(val) ~= "number" then
        self:xcCntlLog("Jog increment must be a number.", 1)
        return
    end
    self.jogIncrement = val
end

function xc.Controller:update()
    if self.shift_btn ~= nil then
        self.shift_btn:getState()
    end
    for i, input in ipairs(self.inputs) do
        input:getState()
    end
    for i, axis in ipairs(self.axes) do
        axis:update()
    end
end

function xc.Controller:assignShift(input)
    if type(input) ~= "table" then
        self:xcCntlLog("Parameter (input) of Controller:assignShift method expected Button or Analog, got "..type(input), 1)
        return
    end
    self.shift_btn = input
    self:xcCntlLog(""..input.id.." assigned as controller shift button.", 3)
    for i, input in ipairs(self.inputs) do
        if input == self.shift_btn then
            table.remove(self.inputs, i)
            return
        end
    end
end

function xc.Controller:mapSimpleJog(reversed)
    if type(reversed) ~= "boolean" and reversed ~= nil then
        self:xcCntlLog("Parameter (reversed) of xc.mapSimpleJog expected boolean, got "..type(reversed), 1)
        return
    end
    reversed = reversed and true or false
	self:xcCntlLog("Jog reverse flag set to: "..tostring(reversed),4)
    -- DPad regular jog
    self.UP.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_POS)
    end))
    self.UP.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS)
    end))
    self.DOWN.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_NEG)
    end))
    self.DOWN.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS)
    end))
    self.RIGHT.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_POS)
    end))
    self.RIGHT.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS)
    end))
    self.LEFT.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_NEG)
    end))
    self.LEFT.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS)
    end))
    if reversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end

    self.UP.down:altConnect(Slot:new(function()
        mc.mcJogIncStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, self.jogIncrement)
    end))
    self.DOWN.down:altConnect(Slot:new(function()
        mc.mcJogVelocityStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, -1 * self.jogIncrement)
    end))
    self.RIGHT.down:altConnect(Slot:new(function()
        mc.mcJogVelocityStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, self.jogIncrement)
    end))
    self.LEFT.down:altConnect(Slot:new(function()
        mc.mcJogVelocityStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, -1 * self.jogIncrement)
    end))
    if reversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function", 3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
end

xc.Signal = {}

function xc.Signal:new(controller, btn, id)
    local object = {}
    setmetatable(object, {__index = self})
    object.id = id
    object.btn = btn
    object.slot = nil
    object.altSlot = nil
    object.controller = controller
    return object
end

function xc.Signal:connect(slot)
    if type(slot) ~= "table" then
        self.controller:xcCntlLog("Parameter (slot) of Signal:connect method expected a Slot, got "..type(slot), 1)
        return
    end
    self.slot = slot
    self.slot.btn = self.btn
end

function xc.Signal:altConnect(slot)
    if type(slot) ~= "table" then
        self.controller:xcCntlLog("Parameter (slot) of Signal:altConnect method expected a Slot, got "..type(slot), 1)
        return
    end
    self.altSlot = slot
    self.altSlot.btn = self.btn
end

function xc.Signal:emit()
    self.controller:xcCntlLog("Signal "..self.btn.id..self.id.." emitted.", 3)
    if (not self.controller.shift_btn.pressed) and (self.slot ~= nil) then
        self.slot.func()
    elseif (self.controller.shift_btn.pressed) and (self.altSlot ~= nil) then
        self.altSlot.func()
    end
end

xc.Button = {}

function xc.Button:new(controller, name)
    local object = {}
    setmetatable(object, {__index = self})
    object.controller = controller
    object.id = name
    object.pressed = false
    object.up = Signal:new(object.controller, object, "up")
    object.down = Signal:new(object.controller, object, "down")
    return object
end

function xc.Button:getState()
    local hreg, rc = mc.mcRegGetHandle(inst, string.format("mcX360_LUA/%s", self.id))
    --self.controller:xcErrorCheck(rc)
    local state, rc = mc.mcRegGetValueLong(hreg)
    --self.controller:xcErrorCheck(rc)
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        self.down:emit()
    elseif (state == 0) and self.pressed then
        self.pressed = false
        self.up:emit()
    end
end

xc.Analog = {}

function xc.Analog:new(controller, name)
    local object = {}
    setmetatable(object, {__index = self})
    object.controller = controller
    object.id = name
    object.value = 0
    object.pressed = false
    return object
end

function xc.Analog:getState()
    local hreg, rc = mc.mcRegGetHandle(inst, string.format("mcX360_LUA/%s", self.id))
    --self.controller:xcErrorCheck(rc)
    local val, rc = mc.mcRegGetValueLong(hreg)
    --self.controller:xcErrorCheck(rc)
    self.pressed = math.abs(val) > 25
    self.value = val
end

xc.ThumbstickAxis = {}

function xc.ThumbstickAxis:new(controller, analog)
    local object = {}
    setmetatable(object, {__index = self})
    object.controller = controller
    object.analog = analog
    object.axis = nil
    object.deadzone = 10
    object.rate = nil
    object.moving = false
    object.rateSet = false
    return object
end

function xc.ThumbstickAxis:connect(axis)
    if type(axis) ~= "number" then
        self.controller:xcCntlLog("Parameter (axis) of ThumbstickAxis:connect method expected axis number, got "..type(axis), 1)
        return
    end
    self.axis = axis
    self.rate, rc = mc.mcJogGetRate(inst, self.axis)
    self.controller:xcErrorCheck(rc)
    self.controller:xcCntlLog(tostring(self.analog).." connected to "..tostring(self.axis), 4)
    self.controller:xcCntlLog("Initial rate = "..self.rate, 4)
end

function xc.ThumbstickAxis:update()
    if self.axis == nil then return end

    if not self.moving and not self.rateSet then
        if mc.mcJogGetRate(inst, self.axis) ~= self.rate then
            mc.mcJogSetRate(inst, self.axis, self.rate)
            self.rateSet = true
        end
    end

    if math.abs(self.analog.value) > self.deadzone then
        if not self.moving then
            self.moving = true
            self.rateSet = false
        end
        rc = mc.mcJogSetRate(inst, self.axis, math.abs(self.analog.value))
        self.controller:xcErrorCheck(rc)
        if self.analog.value > 0 then
            rc = mc.mcJogVelocityStart(inst, self.axis, mc.MC_JOG_POS)
            self.controller:xcErrorCheck(rc)
        elseif self.analog.value < 0 then
            mc.mcJogVelocityStart(inst, self.axis, mc.MC_JOG_NEG)
            self.controller:xcErrorCheck(rc)
        end
    end

    if math.abs(self.analog.value) < self.deadzone and self.moving then
        rc = mc.mcJogVelocityStop(inst, self.axis)
        self.controller:xcErrorCheck(rc)
        self.moving = false
        rc = mc.mcJogSetRate(inst, self.axis, self.rate)
        self.controller:xcErrorCheck(rc)
    end
end


xc.Slot = {}

function xc.Slot:new(func)
    local object = {}
    setmetatable(object, {__index = self})
    object.func = func
    if type(func) ~= "function" then
        Controller:xcCntlLog("Parameter (func) of Slot:new method expected function, got "..type(func), 1)
        return
    end
    object.btn = nil
    return object
end

return xc