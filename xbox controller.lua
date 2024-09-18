if not mc then
    require("mocks")
end
inst = mc.mcGetInstance()

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
    local funcName = debug.getinfo(2, "n").name or "Unknown function"
    local line = debug.getinfo(2, "l").currentline or "unknown line"
    mc.mcCntlLog(inst, string.format("Method %s called with . instead of : at line %d.", funcName, line), "", -1)
end

function Controller.typeCheck(objects, types)
    local funcName = debug.getinfo(2,"n").name or "Unknown function"
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
    self.__type = "Controller"
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
    self.LTH_Y = self:newThumbstickAxix("LTH_Y_Val")
    self.RTH_X = self:newThumbstickAxix("RTH_Val")
    self.RTH_Y = self:newThumbstickAxix("RTH_Y_Val")
    self.LTH_X = self:newThumbstickAxix("LTH_X_Val")
    self.inputs = {
        self.UP, self.DOWN, self.RIGHT, self.LEFT, self.A, self.B, self.X, self.Y, self.START,
        self.BACK, self.LTH, self.RTH, self.LSB, self.RSB, self.LTR, self.RTR
    }
    self.axes = { self.LTH_X, self.LTH_Y, self.RTH_X, self.RTH_Y }
    self.shift_btn = nil
    self.jogIncrement = 0.1
    self.logLevel = 1
    self.logLevels = { "ERROR", "WARNING", "INFO", "DEBUG" }

    self.xcCntlEStopToggle = self:newSlot(function()
        self:xcToggleMachSignalState(mc.ISIG_EMERGENCY)
    end)

    self.xcCntlTorchToggle = self:newSlot(function()
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT3)
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT4)
    end)

    self.xcCntlEnableToggle = self:newSlot(function()
        self:xcErrorCheck(
            mc.mcCntlEnable(
                inst, not self.xcGetMachSignalState(mc.OSIG_MACHINE_ENABLED)
            )
        )
    end)

    self.xcCntlCycleStart = self:newSlot(function()
        if self:xcGetMachSignalState(mc.OSIG_RUNNING_GCODE) then
            self:xcErrorCheck(mc.mcCntlFeedHold(inst))
        else
            self:xcErrorCheck(mc.mcCntlCycleStart(inst))
        end
    end)

    return self
end

function Controller:xcGetRegValue(reg)
    if not self then Controller.selfError() return end
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

function Controller:xcGetMachSignalState(signal)
    if not self then Controller.selfError() return end
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

function Controller:xcToggleMachSignalState(signal)
    if not self then Controller.selfError() return end
    if self.typeCheck({ signal }, { "number" }) then return end
    self:xcErrorCheck(mc.mcSignalSetState(signal, self.xcGetMachSignalState(signal) and 0 or 1))
end

function Controller:xcCntlLog(msg, level)
    if not self then Controller.selfError() return end
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

function Controller:xcErrorCheck(rc)
    if not self then Controller.selfError() return end
    if self.typeCheck({ rc }, { "number" }) then return end
    if rc ~= mc.MERROR_NOERROR then
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

function Controller:xcJogSetInc(val)
    if not self then Controller.selfError() return end
    if self.typeCheck({ val }, { "number" }) then return end
    self.jogIncrement = val
    self:xcCntlLog("Set jogIncrement to " .. tostring(self.jogIncrement), 4)
end

function Controller:update()
    if not self then Controller.selfError() return end
    if self.shift_btn ~= nil then
        self.shift_btn:getState()
    end
    for _, input in pairs(self.inputs) do
        input:getState()
    end
    for _, axis in pairs(self.axes) do
        axis:update()
    end
end

function Controller:assignShift(input)
    if not self then Controller.selfError() return end
    if self.typeCheck({ input }, { { "Button", "Trigger" } }) then return end
    self.shift_btn = input
    self:xcCntlLog("" .. input.id .. " assigned as controller shift button.", 3)
    for i, input in ipairs(self.inputs) do
        if input == self.shift_btn then
            table.remove(self.inputs, i)
            return
        end
    end
end

function Controller:mapSimpleJog(reversed)
    if not self then Controller.selfError() return end
    if self.typeCheck({ reversed }, { { "boolean", "nil" } }) then return end
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s",tostring(reversed)), 4)
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

    self.UP.down:altConnect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, self.jogIncrement)
    end))
    self.DOWN.down:altConnect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, -1 * self.jogIncrement)
    end))
    self.RIGHT.down:altConnect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, self.jogIncrement)
    end))
    self.LEFT.down:altConnect(self:newSlot(function()
        mc.mcJogIncStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, -1 * self.jogIncrement)
    end))
    if reversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function", 3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
end

function Controller:newSignal(button, id)
    if not self then Controller.selfError() return end
    if Controller.typeCheck({ button, id }, {{"Button","Trigger"}, "string" }) then return end
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

function Controller.Signal:connect(slot)
    if not self then Controller.selfError() return end
    if self.controller:typeCheck({ slot }, { "Slot" }) then return end
    self.slot = slot
    self.controller:xcCntlLog(self.button.id .. self.id .. " connected to Slot " .. tostring(self.slot), 4)
end

function Controller.Signal:altConnect(slot)
    if not self then Controller.selfError() return end
    if self.controller:typeCheck({ slot }, { "Slot" }) then return end
    self.altSlot = slot
    self.controller:xcCntlLog(self.button.id .. self.id .. " connected to Alt Slot " .. tostring(self.altSlot), 4)
end

function Controller.Signal:emit()
    if not self then Controller.selfError() return end
    self.controller:xcCntlLog("Signal " .. self.button.id .. self.id .. " emitted.", 3)
    if (self.controller.shift_btn == nil or not self.controller.shift_btn.pressed) and (self.slot ~= nil) then
        self.slot.func()
    elseif (self.controller.shift_btn ~= nil and self.controller.shift_btn.pressed) and (self.altSlot ~= nil) then
        self.altSlot.func()
    end
end

function Controller:newButton(id)
    if not self then Controller.selfError() return end
    if self.typeCheck({id},{"string"}) then return end
    return self.Button.new(self,id)
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
    if not self then self.controller.selfError() return end
    local state = self.controller:getRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(state) ~= "number" then
        self.controller:xcCntlLog(string.format("Invalid state for %s", self.id), 1)
        return
    end
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        self.down:emit()
    elseif (state == 0) and self.pressed then
        self.pressed = false
        self.up:emit()
    end
end

function Controller:newTrigger(id)
    return self.Trigger.new(self, id)
end

Controller.Trigger = {}
Controller.Trigger.__index = Controller.Trigger
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
    if not self then Controller.selfError() return end
    self.value = self.controller:getRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(self.value) ~= "number" then
        self.controller:xcCntlLog("Invalid state for " .. self.id, 1)
        return
    end
    --Semi-important to return here, we want to lock out Button type functionality
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

function Controller.Trigger:connect(func)
    if not self then Controller.selfError() return end
    if self.controller.typeCheck({ func }, { "function" }) then return end
    self.func = func
end

function Controller:newThumbstickAxix(id)
    return self.ThumbstickAxis.new(self,id)
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
    if not self then Controller.selfError() return end
    if self.controller.typeCheck({ deadzone }, { "number" }) then return end
    self.deadzone = math.abs(deadzone)
end

function Controller.ThumbstickAxis:connect(axis, inverted)
    if not self then Controller.selfError() return end
    if self.controller.typeCheck({ axis, inverted }, { "number", "boolean" }) then return end
    self.axis = axis
    self.inverted = inverted
    local rc
    self.rate, rc = mc.mcJogGetRate(inst, self.axis)
    self.controller:xcErrorCheck(rc)
    self.controller:xcCntlLog(self.id .. " connected to " .. tostring(self.axis), 4)
    self.controller:xcCntlLog("Initial jog rate for " .. tostring(self.axis) .. " = " .. self.rate, 4)
end

function Controller.ThumbstickAxis:update()
    if not self then Controller.selfError() return end
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
        self.controller:xcErrorCheck(mc.mcJogVelocityStart(inst, self.axis,
            (self.inverted and self.value > 0) and mc.MC_JOG_POS or mc.MC_JOG_NEG))
    end

    if math.abs(self.value) < self.deadzone and self.moving then
        self.controller:xcErrorCheck(mc.mcJogVelocityStop(inst, self.axis))
        self.moving = false
        self.controller:xcErrorCheck(mc.mcJogSetRate(inst, self.axis, self.rate))
        self.rateReset = true
    end
end

function Controller:newSlot(func)
    return self.Slot.new(self, func)
end

Controller.Slot = {}
Controller.Slot.__index = Controller.Slot
Controller.Slot.__type = "Slot"

function Controller.Slot.new(controller, func)
    if Controller.typeCheck({ func }, { "function" }) then return end
    local self = setmetatable({}, Controller.Slot)
    self.controller = controller
    self.func = func
    return self
end

local xc = Controller.new()
---------------------------------
--- Custom Configuration Here ---

xc.logLevel = 2
xc:assignShift(xc.LTR)
xc.RTH_Y:connect(mc.Z_AXIS)
print(xc.UP)
xc:mapSimpleJog(true)
xc.B.down:connect(xc.xcCntlEStopToggle)
xc.Y.down:connect(xc.xcCntlTorchToggle)
xc.RSB.down:connect(xc.xcCntlEnableToggle)
xc.X.down:connect(xc.xcCntlCycleToggle)

-- End of custom configuration ---
----------------------------------
xc:xcCntlLog("Creating X360_timer", 4)
X360_timer = wx.wxTimer(mcLuaPanelParent)
mcLuaPanelParent:Connect(wx.wxEVT_TIMER, function() xc:update() end)
xc:xcCntlLog("Starting X360_timer", 4)
X360_timer:Start(100)
