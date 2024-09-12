inst = mc.mcGetInstance()

---@class Controller
---@field new function
---@field UP Button
---@field DOWN Button
---@field RIGHT Button
---@field LEFT Button
---@field A Button
---@field B Button
---@field X Button
---@field Y Button
---@field START Button
---@field BACK Button
---@field LTH Button
---@field RTH Button
---@field LSB Button
---@field RSB Button
---@field LTR Analog
---@field RTR Analog
---@field LTH_X Analog
---@field LTH_Y Analog
---@field RTH_X Analog
---@field RTH_Y Analog
---@field inputs table
---@field LTH_Y_Axis ThumbstickAxis
---@field LTH_X_Axis ThumbstickAxis
---@field RTH_Y_Axis ThumbstickAxis
---@field RTH_X_Axis ThumbstickAxis
---@field axes table
---@field shift_btn Button|Analog|nil
---@field jogIncrement number
---@field logLevel number
---@field xcLOG_ERROR number
---@field xcLOG_WARNING number
---@field xcLOG_INFO number
---@field xcLOG_DEBUG number
---@field logLevels table
---@field xcCntlEStop Slot
---@field xcCntlTorchOn Slot
---@field xcCntlEnable Slot
---@field xcCntlCycleStart Slot
---@field xcCntlLog function
---@field xcErrorCheck function
---@field xcJogGetInc function
---@field xcJogSetInc function
---@field update function
---@field assignShift function
---@field mapSimpleJog function


Controller = {}

---@return Controller
function Controller:new()
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

    object.xcCntlEStop = Slot:new(function(btn)
        if btn then
            local hsig = mc.mcSignalGetHandle(inst, mc.ISIG_EMERGENCY)
            local state = mc.mcSignalGetState(hsig)
            mc.mcSignalSetState(hsig, state and true or false)
        else
            object:xcCntlLog("Slot function xcCntlEStop called with no connection.", 1)
        end
    end)

    object.xcCntlTorchOn = Slot:new(function(btn)
        if btn then
            local hsig = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT3)
            local hsig2 = mc.mcSignalGetHandle(inst, mc.OSIG_OUTPUT4)
            local state = mc.mcSignalGetState(hsig)
            local state2 = mc.mcSignalGetState(hsig2)
            mc.mcSignalSetState(hsig, state and true or false)
            mc.mcSignalSetState(hsig2, state and true or false)
        else
            object:xcCntlLog("Slot function xcCntlTorchOn called with no connection.", 1)
        end
    end)

    object.xcCntlEnable = Slot:new(function(btn)
        if btn then
            local hsig = mc.mcSignalGetHandle(inst, mc.OSIG_MACHINE_ENABLED)
            local state = mc.mcSignalGetState(hsig)
            mc.mcCntlEnable(inst, state and true or false)
        else
            object:xcCntlLog("Slot function xcCntlEnable called with no connection.", 1)
        end
    end)

    object.xcCntlCycleStart = Slot:new(function(btn)
        if btn then
            local hsig = mc.mcSignalGetHandle(inst, mc.OSIG_RUNNING_GCODE)
            local state = mc.mcSignalGetState(hsig)
            if state then
                mc.mcCntlFeedHold(inst)
            else
                mc.mcCntlCycleStart(inst)
            end
        else
            object:xcCntlLog("Slot function xcCntlCycleStart called with no connection.", 1)
        end
    end)

    return object
end

---@param msg string
---@param level number
function Controller:xcCntlLog(msg, level)
    print(msg, level)
    if self.logLevel == 0 then return end
    print(level, self.logLevel)
    if level <= self.logLevel then
        mc.mcCntlLog(inst, "[[XBOX CONTROLLER "..self.logLevels[self.logLevel].."]]: "..msg, "", -1)
    end
end

---@param rc number
function Controller:xcErrorCheck(rc)
    if rc ~= mc.MERROR_NOERROR then
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

---@return number
function Controller:xcJogGetInc()
    return self.jogIncrement
end

---@param val number
function Controller:xcJogSetInc(val)
    if type(val) ~= "number" then
        self:xcCntlLog("Jog increment must be a number.", 1)
        return
    end
    self.jogIncrement = val
end

function Controller:update()
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

---@param input Button|Analog
function Controller:assignShift(input)
    if type(input) ~= "table" then
        self:xcCntlLog("Parameter (input) of Controller:assignShift method expected Button or Analog, got "..type(input), 1)
        return
    end
    for _, analog in ipairs({self.LTH_X, self.LTH_Y, self.RTH_X, self.RTH_Y}) do
        if input == analog then
            self:xcCntlLog("You have assigned a thumbstick axis as the controller's shift button. Are you sure this is what you want?", 2)
        end
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

---@param reversed boolean|nil
---@return nil
function Controller:mapSimpleJog(reversed)
    if type(reversed) ~= "boolean" or reversed ~= nil then
        self:xcCntlLog("Parameter (reversed) of xc.mapSimpleJog expected boolean, got "..type(reversed), 1)
        return
    end
    reversed = reversed and true or false
    -- DPad regular jog
    self.UP.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, mc.MC_JOG_POS)
    end))
    self.UP.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, reversed and mc.Y_AXIS or mc.X_AXIS)
    end))
    self.DOWN.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, mc.MC_JOG_NEG)
    end))
    self.DOWN.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, reversed and mc.Y_AXIS or mc.X_AXIS)
    end))
    self.RIGHT.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, mc.MC_JOG_POS)
    end))
    self.RIGHT.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, reversed and mc.X_AXIS or mc.Y_AXIS)
    end))
    self.LEFT.down:connect(Slot:new(function()
        mc.mcJogVelocityStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, mc.MC_JOG_NEG)
    end))
    self.LEFT.up:connect(Slot:new(function()
        mc.mcJogVelocityStop(inst, reversed and mc.X_AXIS or mc.Y_AXIS)
    end))
    if reversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end

    -- DPad incremental jog
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

---@class Signal
---@field new function
---@field id string
---@field btn Button
---@field slot Slot|nil
---@field altSlot Slot|nil
---@field controller Controller
---@field connect function
---@field altConnect function
---@field emit function
Signal = {}

---@param controller Controller
---@param btn Button
---@param id string
---@return Signal
function Signal:new(controller, btn, id)
    local object = {}
    setmetatable(object, {__index = self})
    object.id = id
    object.btn = btn
    object.slot = nil
    object.altSlot = nil
    object.controller = controller
    return object
end

---@param slot Slot
function Signal:connect(slot)
    if type(slot) ~= "table" then
        self.controller:xcCntlLog("Parameter (slot) of Signal:connect method expected a Slot, got "..type(slot), 1)
        return
    end
    self.slot = slot
    self.slot.btn = self.btn
end

---@param slot Slot
function Signal:altConnect(slot)
    if type(slot) ~= "table" then
        self.controller:xcCntlLog("Parameter (slot) of Signal:altConnect method expected a Slot, got "..type(slot), 1)
        return
    end
    self.altSlot = slot
    self.altSlot.btn = self.btn
end

function Signal:emit()
    self.controller:xcCntlLog("Signal "..self.btn.id..self.id.." emitted.", 3)
    if (not self.controller.shift_btn.pressed) and (self.slot ~= nil) then
        self.slot:call()
    elseif (self.controller.shift_btn.pressed) and (self.altSlot ~= nil) then
        self.altSlot:call()
    end
end

---@class Button
---@field new function
---@field controller table
---@field id string
---@field pressed boolean
---@field toggled boolean
---@field up Signal
---@field down Signal
---@field getState function
Button = {}

---@param controller Controller
---@param id string
---@return Button
function Button:new(controller, id)
    local object = {}
    setmetatable(object, {__index = self})
    object.controller = controller
    object.id = id
    object.pressed = false
    object.up = Signal:new(object.controller, object, "up")
    object.down = Signal:new(object.controller, object, "down")
    return object
end

function Button:getState()
    local hreg, rc = mc.mcRegGetHandle(inst, string.format("mcX360_LUA/%s", self.id))
    self.controller:xcErrorCheck(rc)
    local state, rc = mc.mcRegGetValueLong(hreg)
    self.controller:xcErrorCheck(rc)
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        self.down:emit()
    elseif (state == 0) and self.pressed then
        self.pressed = false
        self.up:emit()
    end
end

---@class Analog
---@field new function
---@field controller table
---@field id string
---@field value number
---@field pressed boolean
---@field getState function
Analog = {}

---@param controller Controller
---@param id string
---@return Analog
function Analog:new(controller, id)
    local object = {}
    setmetatable(object, {__index = self})
    object.controller = controller
    object.id = id
    object.value = 0
    object.pressed = false
    return object
end

function Analog:getState()
    local hreg, rc = mc.mcRegGetHandle(inst, string.format("mcX360_LUA/%s", self.id))
    self.controller:xcErrorCheck(rc)
    local val, rc = mc.mcRegGetValueLong(hreg)
    self.controller:xcErrorCheck(rc)
    self.pressed = math.abs(val) > 25
    self.value = val
end

---@class ThumbstickAxis
---@field new function
---@field controller table
---@field analog table
---@field axis number|nil
---@field deadzone number
---@field rate number
---@field moving boolean
---@field rateSet boolean
---@field connect function
---@field update function
ThumbstickAxis = {}

---@param controller Controller
---@param analog Analog
---@return ThumbstickAxis
function ThumbstickAxis:new(controller, analog)
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

---@param axis number
function ThumbstickAxis:connect(axis)
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

---@return nil
function ThumbstickAxis:update()
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

---@class Slot
---@field new function
---@field func function
---@field btn Button
---@field call function
Slot = {}

---@param func function
---@return Slot|nil
function Slot:new(func)
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

function Slot:call()
    if self.btn then
        self.func(self.btn)
    end
end

---------------------------------
--- Custom Configuration Here ---

-- create a Controller instance.  
-- You can name it anything, but using "xc" makes the Controller's API closely resemble
-- the Mach4 API, and is the recommended convention.
local xc = Controller:new()

-- log levels are:
-- 0: Disabled
-- 1: Error
-- 2: Warning
-- 3: Info
-- 4: Debug
-- Log messages will only be displayed for the current log level and all lower log levels.
-- Default logLevel is 1, so there is no need to explicitly set it like this if you only want 
-- error message output, this is merely an example.
xc.logLevel = 1

-- Assign left trigger as shift
-- You can use any Button or Analog object.  The Analog object defines its self.pressed
-- attribute as true when the value is over 25, so if you use a trigger for your shift
-- button, shift will be active as long as the trigger is at least 25% depressed.
-- This has the side effect of making the assignment of a thumbstick Analog object
-- as a shift button technically valid, but for obvious reasons this is not recommended
-- and will raise a warning in the logs.
xc:assignShift(xc.LTR)

-- Connect machine Z Axis to Right thumbstick Y axis
-- A Controller has 4 ThumbstickAxis objects, representing the X and Y axes of each thumbstick
-- Simply call the connect method and pass it a Mach4 axis to enable analog control of that 
-- axis via the assigned thumbstick axis.  Here, the machine's Z axis is connected to the
-- "up and down" axis of the right thumbstick
xc.RTH_Y_Axis:connect(mc.Z_AXIS)

-- Map simple jogging to the DPad
-- pass true to reverse orientation of X and Y axes
-- for regular orientation, pass nil, false or simply omit the parameter
-- the mapSimpleJog method is provided as a convenience and maps regular jogging to the D-pad 
-- and incremental jogging to the D-pad's "alternate function."  alternate functions for an input
-- are mapped by using the altConnect method to connect any of an input's signals to a Slot
-- An input's "alternate function" will be called if the connected Signal is emitted while 
-- the Controller's assigned "shift button" is pressed (assuming a shift button has been assigned)
xc:mapSimpleJog(true)

-- Set jog increment to 0.1 units
-- This only affects the jog increment when using the controller, it does not affect incremental
-- jogging from the Mach4 screen or any other controller.  This value uses whatever units (in or mm)
-- are in use by Mach4.  0.1 is the default, so there is no need to call xcJogSetInc unless you want
-- a different value, this is merely an example.
xc:xcJogSetInc(0.1)

-- Map E-Stop to B button
-- xcCntlEStop is a Slot that has been pre-defined for your convenience.  It toggles the state of the EStop,
-- so connecting any button's down Signal to this Slot wil cause the Estop (signal) to be triggered if it isn't
-- currently triggered, or deactivated if it is currently activated.  If the Estop has been set through an
-- external physical EStop switch, this function will have no effect until the physical switch has been reset.
xc.B.down:connect(xc.xcCntlEStop)

-- Map torch on/off (with THC) to Y button
-- xcCntlTorchOn assumes that output signal #3 turns the torch on and output signal #4
-- enables Torch Height Control.  If these are not the appropriate output signals
-- for your setup, either edit the xcCntlTorchOn method in the code above, or define your
-- own Slot that toggles the appropriate signals.  the xcCntlTorchOn Slot provides a good template to follow
-- for toggling Mach4 output signals.
xc.Y.down:connect(xc.xcCntlTorchOn)

-- Map machine enable to Right Shoulder button
-- xcCntlEnable is another Slot that has been predefined for your convenience.  It simply toggles the 
-- enabled/disabled state of the machine.
xc.RSB.down:connect(xc.xcCntlEnable)

-- Map cycle start/feed hold to X button
-- xcCntlCycleStart is another predefined Slot that calls mcCntlCycleStart if Gcode is not
-- currently running, or mcCntlFeedHold if Gcode is currently running. In other words, it is a toggle
-- for executing/pausing execution of Gcode.
xc.X.down:connect(xc.xcCntlCycleStart)

-- End of custom configuration
---------------------------------

X360_timer = wx.wxTimer(mcLuaPanelParent)
mcLuaPanelParent:Connect(wx.wxEVT_TIMER, function(event) xc:update(event) end)
X360_timer:Start(100)