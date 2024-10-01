if not mc then
    require("mocks")
end

wx = wx or require("wx")
mcLuaPanelParent = mcLuaPanelParent or wx.wxFrame()

inst = mc.mcGetInstance()

Controller = {}
Controller.__index = Controller
Controller.__type = "Controller"

profileRegisters = {
    ["profile"] = 20000,
    ["profileName"] = 20001,
    ["shiftButton"] = 20002,
    ["jogIncrement"] = 20003,
    ["logLevel"] = 20004,
}

function isCorrectSelf(self)
    local info = debug.getinfo(2, "nl") -- Get info about the calling function
    if info and info.name then
        local expected_class = getmetatable(self) -- Get the metatable of the instance (class)
        if expected_class then
            local function_in_class = expected_class[info.name] -- Get the function from the metatable by name
            local actual_function = debug.getinfo(2, "f").func -- Get the actual function pointer from the current stack frame
            return function_in_class == actual_function -- Check if the functions are the same
        end
        -- here we can die with a good error message
        error(string.format("Method %s was probably called with . instead of : at line %d.", info.name, info.currentline))
    end
    -- to die here means isCorrectSelf has been called outside of a method, which is an error in itself
    error(string.format("function isCorrectSelf should only be called from within a method! line: %d",info.currentline))
end

function Controller.customType(object)
    if type(object) == "table" then
        local mt = getmetatable(object)
        return object.__type or (mt and mt.__type) or "table"
    else
        return type(object)
    end
end

function Controller.typeCheck(objects, types)
    -- failed typeChecks are critical errors, so typeCheck now raises an error instead of just logging one.
    -- since we stop execution on failure, there is no need to return anything now.
    -- type checking has been removed from methods not meant to be part of the public API, as they should be unnecessary. 
    local funcName = debug.getinfo(2, "n").name or "Unknown function"
    for i, object in ipairs(objects) do
        local expectedTypes = types[i]
        local actualType = Controller.customType(object)
        if type(expectedTypes) == "string" then
            expectedTypes = {expectedTypes}
        end
        local typeMatch = false
        for _, expectedType in ipairs(expectedTypes) do
            if actualType == expectedType then
                typeMatch = true
                break
            end
        end
        if not typeMatch then
            error(string.format("Parameter %d of function %s expected one of %s, got %s at line: %d.", i, funcName,
                table.concat(expectedTypes, ", "), actualType, debug.getinfo(2, "l").currentline))
        end
    end
end

function Controller.new()
    local self = setmetatable({}, Controller)
    self.profile = 0
    self.profileName = "default"
    self.id = "Controller"
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
    self.RTH_X = self:newThumbstickAxis("RTH_X_Val")
    self.RTH_Y = self:newThumbstickAxis("RTH_Y_Val")
    self.LTH_X = self:newThumbstickAxis("LTH_X_Val")
    self.inputs = {self.UP, self.DOWN, self.RIGHT, self.LEFT, self.A, self.B, self.X, self.Y, self.START, self.BACK,
                   self.LTH, self.RTH, self.LSB, self.RSB, self.LTR, self.RTR}
    self.axes = {self.LTH_X, self.LTH_Y, self.RTH_X, self.RTH_Y}
    self.shiftButton = nil
    self.jogIncrement = 0.1
    self.logLevel = 2
    self.logLevels = {"ERROR", "WARNING", "INFO", "DEBUG"}

    self.slots = {}
    names = {"Cycle Start", "Cycle Stop", "Feed Hold", "Enable On", "Enable Off", "Enable Toggle", "Soft Limits On",
             "Soft Limits Off", "Soft Limits Toggle", "Position Remember", "Position Return", "Limit OV On",
             "Limit OV Off", "Limit OV Toggle", "Jog Mode Toggle", "Jog Mode Step", "Jog Mode Continuous", "Jog X+",
             "Jog Y+", "Jog Z+", "Jog A+", "Jog B+", "Jog C+", "Jog X-", "Jog Y-", "Jog Z-", "Jog A-", "Jog B-",
             "Jog C-", "Home All", "Home X", "Home Y", "Home Z", "Home A", "Home B", "Home C"}
    for i, name in ipairs(names) do
        self:newSlot(name, function()
            scr.DoFunctionName(name)
        end)
    end

    self:newSlot("E Stop Toggle", function()
        self:xcToggleMachSignalState(mc.ISIG_EMERGENCY)
    end)

    -- NOTE: Probably not generic enough to include as pre-defined Slot
    self.xcCntlTorchToggle = self:newSlot("Torch/THC Toggle", function()
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT3)
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT4)
    end)
    table.remove(self.slots)

    -- Deprecated in favor of scr.DoFunctionName("Enable Toggle") to be removed pending testing
    --[[self.xcCntlEnableToggle = self:newSlot("XC Enable Toggle", function()
        self:xcErrorCheck(
            mc.mcCntlEnable(
                inst, not self:xcGetMachSignalState(mc.OSIG_MACHINE_ENABLED)
            )
        )
    ]] -- end)

    -- Deprecated in favor of scr.DoFunctionName("Limit OV Toggle") to be removed pending testing
    --[[self.xcCntlAxisLimitOverride = self:newSlot("XC Limit Override Toggle", function()
        self:xcToggleMachSignalState(mc.ISIG_LIMITOVER)
    ]] -- end)

    -- Deprecated in favor of scr.DoFunctionName("JogModeToggle") to be removed pending testing
    --[[self.xcJogTypeToggle = self:newSlot("XC JogModeToggle", function()
        self:xcToggleMachSignalState(mc.OSIG_JOG_INC)
        self:xcToggleMachSignalState(mc.OSIG_JOG_CONT)
    ]] -- end)

    -- Deprecated in favor of scr.DoFunctionName("Home All") along with ("Home X","Home Y", etc)
    --[[self.xcAxisHomeAll = self:newSlot("XC Home ALL", function() self:xcErrorCheck(mc.mcAxisHomeAll(inst)) end)
    self.xcAxisHomeX = self:newSlot("XC Home X", function() self:xcErrorCheck(mc.mcAxisHome(inst, mc.X_AXIS)) end)
    self.xcAxisHomeY = self:newSlot("XC Home Y", function() self:xcErrorCheck(mc.mcAxisHome(inst, mc.Y_AXIS)) end)
    ]] -- self.xcAxisHomeZ = self:newSlot("XC Home Z", function() self:xcErrorCheck(mc.mcAxisHome(inst, mc.Z_AXIS)) end)

    self:newSlot("Goto Zero", function()
        self:xcErrorCheck(mc.mcCntlGotoZero(inst))
    end)

    -- Deprecated in favor of scr.DoFunctionName("Reset") to be removed pending testing
    -- self.xcCntlReset = self:newSlot(function() self:xcErrorCheck(mc.mcCntlReset(inst)) end)

    -- TODO: Research all the available "state" emums and the states they describe.  We probably need to cover more
    -- states than this.

    -- States 100-199 are all various states that apply once a file has started running
    -- States 200-299 are the same states that apply while MDI is running

    self:newSlot("XC Run Cycle Toggle", function()
        local state, rc = mc.mcCntlGetState()
        self:xcErrorCheck(rc)
        if state == mc.MC_STATE_IDLE or state == mc.MC_STATE_HOLD then
            scr.DoFunctionName('Cycle Start')
        elseif state > 99 and state < 200 then
            scr.DoFunctionName('Cycle Stop')
        else
            self:xcCntlLog('Attempt to Start/Stop cycle: machine is in invalid state.', 2)
            return
        end
    end)

    return self
end

function Controller:initUi(propertiesPanel)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation

    -- propSizer gets cleared in the event handler that calls initUi, so no need to do it again
    local propSizer = propertiesPanel:GetSizer()

    -- label and control for shift button option
    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Assign shift button:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local choices = {}
    for _, input in ipairs(self.inputs) do
        table.insert(choices, input.id)
    end
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    if self.shiftButton ~= nil then
        choice:SetSelection(choice:FindString(self.shiftButton.id))
    end

    -- label and control for jog increment option
    local jogIncLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Jog Increment:")
    propSizer:Add(jogIncLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local jogIncCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.jogIncrement), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(jogIncCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- label and control for logging level option
    local logLevels = {"0 - Disabled", "1 - Error", "2 - Warning", "3 - Info", "4 - Debug"}
    local logLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Logging level:")
    propSizer:Add(logLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local logChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, logLevels)
    propSizer:Add(logChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    logChoice:SetSelection(self.logLevel)

    -- apply button
    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize)
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    -- event handler for apply button
    propertiesPanel:Connect(applyId, wx.wxEVT_BUTTON, function()
        local choiceSelection = choice:GetStringSelection()
        if choiceSelection ~= self.shiftButton.id then
            self.assignShift(self:xcGetButtonById(choiceSelection))
        end
        local jogInc = tonumber(jogIncCtrl:GetValue())
        if jogInc ~= self.jogIncrement then
            self.jogIncrement = jogInc
        end
        local logChoiceSelection = logChoice:GetSelection()
        if self.logLevel ~= logChoiceSelection then
            self.logLevel = logChoiceSelection
        end
    end)

    -- Trigger the layout update and return the new sizer
    propSizer:Layout()
    propertiesPanel:Layout()
    propertiesPanel:Fit()
    propertiesPanel:Refresh()
    return propSizer
end

function Controller:xcGetInputById(id)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({id}, {"string"}) -- should raise an error if any param is of the wrong type
    for _, input in ipairs(self.inputs) do
        if input.id == id then
            return input
        end
    end
    self:xcCntlLog(string.format("No Button with id %s found", id), 1)
end

-- Convenience method for retrieving a pre-defined slot by its id
function Controller:xcGetSlotById(id)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({id}, {"string"}) -- should raise an error if any param is of the wrong type
    for i, slot in ipairs(self.slots) do
        if slot.id == id then
            return slot
        end
    end
    self:xcCntlLog(string.format("No Slot with id %s found", id), 1)
end

-- Convenience method for retrieving numeric register values in a single call with error handling.
function Controller:xcGetRegValueNumber(reg)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({reg}, {"string"}) -- should raise an error if any param is of the wrong type
    local hreg, rc = mc.mcRegGetHandle(inst, reg)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcRegGetValueLong(hreg)
        if rc == mc.MERROR_NOERROR then
            return val
        else
            self:xcCntlLog(string.format("Error in mcRegGetValueLong: %s",mc.mcCntlGetErrorString(inst, rc)), 1)
        end
    else
        self:xcCntlLog(string.format("Error in mcRegGetHandle: %s",mc.mcCntlGetErrorString(inst, rc)), 1)
    end
end

-- Convenience method for checking Mach4 signal states with a single call and error handling.
-- Note, this returns a boolean (true or false) instead of the numeric (1 or 0) values returned by the Mach4 function.
function Controller:xcGetMachSignalState(signal)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({signal}, {"number"}) -- should raise an error if any param is of the wrong type
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcSignalGetState(hsig)
        if rc == mc.MERROR_NOERROR then
            return val > 0
        else
            self:xcCntlLog(string.format("Error in mcSignalGetState: %s",mc.mcCntlGetErrorString(inst, rc)), 1)
        end
    else
        self:xcCntlLog(string.format("Error in mcSignalGetHandle: %s",mc.mcCntlGetErrorString(inst, rc)), 1)
    end
end

-- Convenience method to toggle the state of a Mach4 signal with a single call and error handling.
function Controller:xcToggleMachSignalState(signal)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({signal}, {"number"}) -- should raise an error if any param is of the wrong type
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        self:xcErrorCheck(mc.mcSignalSetState(hsig, not mc.mcSignalGetState(inst, hsig)))
    end
end

-- Logger method
function Controller:xcCntlLog(msg, level)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({msg, level}, {"string", "number"})  -- should raise an error if any param is of the wrong type
    if self.logLevel == 0 then return end -- indicates logging is disabled
    if level <= self.logLevel then
        if mc.mcInEditor() ~= 1 then
            mc.mcCntlLog(inst, "[[XBOX CONTROLLER " .. self.logLevels[level] .. "]]: " .. msg, "", -1)
        else
            print("[[XBOX CONTROLLER " .. self.logLevels[level] .. "]]: " .. msg)
        end
    end
end

-- check Mach4 return codes for errors with error handling
-- TODO: Should this function maybe return a boolean? or return the error string insead of logging it directly?
function Controller:xcErrorCheck(rc)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({rc}, {"number"}) -- should raise an error if any param is of the wrong type
    if rc ~= mc.MERROR_NOERROR then
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

-- Setter method for controller jog increment
function Controller:xcJogSetInc(val)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({val}, {"number"}) -- should raise an error if any param is of the wrong type
    self.jogIncrement = val
    self:xcCntlLog("Set jogIncrement to " .. tostring(self.jogIncrement), 4)
end

-- The loop method for input polling
function Controller:update()
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    if self.shiftButton ~= nil then
        self.shiftButton:getState()
    end
    for _, input in pairs(self.inputs) do
        if input ~= self.shiftButton then
            input:getState()
        end
    end
    for _, axis in pairs(self.axes) do
        axis:update()
    end
end

function Controller:assignShift(input)
    -- added warning message when overriding an assigned shift button
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({input}, {{"Button", "Trigger"}}) -- should raise an error if any param is of the wrong type

    if self.shiftButton ~= nil then
        self:xcCntlLog(string.format(
            "Call to assign a shift button with a shift button already assigned.\n%s will be unassigned before assigning new shift button.",
            self.shiftButton.id), 2)
    end
    self.shiftButton = input
    self:xcCntlLog("" .. input.id .. " assigned as controller shift button.", 3)
end

function Controller:mapSimpleJog(reversed)
    -- TODO: Connect this to the GUI configurator, implement it as a default, or deprecate it.
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({reversed}, {{"boolean", "nil"}}) -- should raise an error if any param is of the wrong type
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s", tostring(reversed)), 4)
    -- DPad regular jog
    self.UP.down:connect(self:newSlot('xcJogUp', function()
        mc.mcJogVelocityStart(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_POS)
    end))
    self.UP.up:connect(self:newSlot('xcJogStopY', function()
        mc.mcJogVelocityStop(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS)
    end))
    self.DOWN.down:connect(self:newSlot('xcJogDown', function()
        mc.mcJogVelocityStart(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_NEG)
    end))
    self.DOWN.up:connect(self:xcGetSlotById('xcJogStopY'))
    self.RIGHT.down:connect(self:newSlot('xcJogRight', function()
        mc.mcJogVelocityStart(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_POS)
    end))
    self.RIGHT.up:connect(self:newSlot('xcJogStopX', function()
        mc.mcJogVelocityStop(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS)
    end))
    self.LEFT.down:connect(self:newSlot('xcJogLeft', function()
        mc.mcJogVelocityStart(inst, (reversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_NEG)
    end))
    self.LEFT.up:connect(self:xcGetSlotById('xcJogStopX'))
    if reversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end

    self.UP.altDown:connect(self:newSlot('xcJogIncUp', function()
        mc.mcJogIncStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, self.jogIncrement)
    end))
    self.DOWN.altDown:connect(self:newSlot('xcJogIncDown', function()
        mc.mcJogIncStart(inst, reversed and mc.Y_AXIS or mc.X_AXIS, -1 * self.jogIncrement)
    end))
    self.RIGHT.altDown:connect(self:newSlot('xcJogIncRight', function()
        mc.mcJogIncStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, self.jogIncrement)
    end))
    self.LEFT.altDown:connect(self:newSlot('xcJogIncLeft', function()
        mc.mcJogIncStart(inst, reversed and mc.X_AXIS or mc.Y_AXIS, -1 * self.jogIncrement)
    end))
    if reversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function",
            3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
end

function Controller:newSignal(button, id)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({button, id}, {{"Button", "Trigger"}, "string"}) -- should raise an error if any param is of the wrong type
    return self.Signal.new(self, button, id)
end

Controller.Signal = {}
Controller.Signal.__index = Controller.Signal
Controller.Signal.__type = "Signal"
Controller.Signal.__tostring = function(self)
    return string.format("Signal: %s", self.id)
end

function Controller.Signal.new(controller, button, id)
    local self = setmetatable({}, Controller.Signal)
    self.id = id
    self.button = button
    self.controller = controller
    self.slot = nil
    return self
end

function Controller.Signal:connect(slot)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({slot}, {"Slot"}) -- should raise an error if any param is of the wrong type
    if self.controller.shift_btn == self.button then
        self.controller:xcCntlLog("Ignoring call to connect a Slot to an assigned shift button!", 2)
        return
    end
    if self.slot ~= nil then
        self.controller:xcCntlLog(string.format(
            "%s Signal of input %s already has a connected Slot.  Did you mean to override it?", self.id, self.button.id),
            2)
    end
    self.slot = slot
    self.controller:xcCntlLog(self.button.id .. self.id .. " connected to Slot " .. self.slot.id, 4)
end

function Controller.Signal:emit()
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    if self.id ~= "analog" then
        -- not logging analog Signal emissions because they will happen every update while active
        self.slot.func(self.button.value)
    else
        self.controller:xcCntlLog("Signal " .. self.button.id .. self.id .. " emitted.", 3)
        self.func()
    end
end

function Controller:newButton(id)
    isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({id}, {"string"}) -- should raise an error if any param is of the wrong type
    return self.Button.new(self, id)
end

Controller.Button = {}
Controller.Button.__index = Controller.Button
Controller.Button.__type = "Button"
Controller.Button.__tostring = function(self)
    return string.format("Button: %s", self.id)
end

function Controller.Button.new(controller, id)
    local self = setmetatable({}, Controller.Button)
    self.controller = controller
    self.id = id
    self.pressed = false
    self.up = self.controller:newSignal(self, "up")
    self.down = self.controller:newSignal(self, "down")
    self.altUp = self.controller:newSignal(self, "altUp")
    self.altDown = self.controller:newSignal(self, "altDown")
    self.signals = {self.up, self.down, self.altUp, self.altDown}
    return self
end

function Controller.Button:getState()
    -- added check to ensure that an assigned shift button will not emit Signals.
    if not self then
        self.controller.selfError()
        return
    end
    local state = self.controller:xcGetRegValueNumber(string.format("mcX360_LUA/%s", self.id))
    if type(state) ~= "number" then
        self.controller:xcCntlLog(string.format("Invalid state for %s", self.id), 1)
        return
    end
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        if self.controller.shift_btn ~= self then
            if not self.controller.shift_btn or not self.controller.shift_btn.pressed then
                self.down:emit()
            else
                self.altDown:emit()
            end
        end
    elseif (state == 0) and self.pressed then
        self.pressed = false
        if self.controller.shift_btn ~= self then
            if not self.controller.shift_btn or not self.controller.shift_btn.pressed then
                self.up:emit()
            else
                self.altUp:emit()
            end
        end
    end
end

function Controller.Button:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()

    -- Slot labels and dropdowns
    local options = {""}
    for _, slot in ipairs(self.controller.slots) do
        options[#options + 1] = slot.id
    end
    idMapping = {}
    for i, signal in ipairs({"Up", "Down", "Alternate Up", "Alternate Down"}) do
        local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, string.format("%s Action:", signal))
        propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
        local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, options)
        idMapping[self.signals[i]] = choice
        if self.signals[i].slot ~= nil then
            choice:SetSelection(choice:FindString(self.signals[i].slot.id))
        end
        propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    end

    -- Analog signal for Triggers
    -- TODO: create analog Slot type
    if self.__type == "Trigger" then
        local axes = {"mc.X_AXIS", "mc.Y_AXIS", "mc.Z_AXIS", "mc.A_AXIS", "mc.B_AXIS", "mc.C_AXIS"}
        local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Analog action:")
        propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
        local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, axes)
        idMapping[self.analog] = choice
        if self.analog.axis ~= nil then
            choice:SetSelection(choice:FindString(axes[self.analog.axis]))
        end
        propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    end

    -- Apply button
    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize)
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    -- Event handler
    propertiesPanel:Connect(applyId, wx.wxEVT_BUTTON, function()
        for i, signal in ipairs(self.signals) do
            local choice = idMapping[signal]
            local selection = choice:GetStringSelection()
            if (signal.slot == nil and selection ~= "") or (signal.slot and signal.slot.id ~= selection) then
                signal:connect(self.controller:xcGetSlotById(selection))
            elseif signal.slot and selection == "" then
                signal.slot = nil
            end
        end
    end)

    -- Refresh and return the layout
    propertiesPanel:Layout()
    propertiesPanel:Fit()
    propertiesPanel:Refresh()
    return propSizer
end

function Controller:newTrigger(id)
    return self.Trigger.new(self, id)
end

Controller.Trigger = {}
Controller.Trigger.__index = Controller.Button
Controller.Trigger.__type = "Trigger"
Controller.Trigger.__tostring = function(self)
    return string.format("Trigger: %s", self.id)
end

function Controller.Trigger.new(controller, id)
    if controller.typeCheck({controller, id}, {"Controller", "string"}) then
        return
    end
    local self = Controller.Button.new(controller, id)
    setmetatable(self, Controller.Trigger)
    self.__type = "Trigger"
    self.value = 0
    self.analog = self.controller:newSignal(self, "analog")
    table.insert(self.signals, self.analog)
    return self
end

function Controller.Trigger:getState()
    if not self then
        Controller.selfError()
        return
    end
    self.value = self.controller:xcGetRegValueNumber(string.format("mcX360_LUA/%s", self.id))
    if type(self.value) ~= "number" then
        self.controller:xcCntlLog("Invalid state for " .. self.id, 1)
        return
    end

    if self.value > 0 and self.analog.slot then
        self.analog:emit()
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
    if not self then
        Controller.selfError()
        return
    end
    if self.controller.typeCheck({func}, {"function"}) then
        return
    end
    self.func = func
end

function Controller:newThumbstickAxis(id)
    return self.ThumbstickAxis.new(self, id)
end

Controller.ThumbstickAxis = {}
Controller.ThumbstickAxis.__index = Controller.ThumbstickAxis
Controller.ThumbstickAxis.__type = "ThumbstickAxis"
Controller.ThumbstickAxis.__tostring = function(self)
    return string.format("ThumbstickAxis: %s", self.id)
end

function Controller.ThumbstickAxis.new(controller, id)
    if controller.typeCheck({controller, id}, {"Controller", "string"}) then
        return
    end
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
    if self.controller.typeCheck({deadzone}, {"number"}) then
        return
    end
    self.deadzone = math.abs(deadzone)
end

function Controller.ThumbstickAxis:connect(axis, inverted)
    if not self then
        Controller.selfError()
        return
    end
    if self.controller.typeCheck({axis, inverted}, {"number", "boolean"}) then
        return
    end
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
]] ---
--- TODO: It's probably possible to do all of our jog rate updating for the thumbstick analog control without actually updating Mach4's jog rate value.  We should probably
--- create our own jog rate value, track it on an instance attribute and refer to that instead.
function Controller.ThumbstickAxis:update()
    if not self then
        Controller.selfError()
        return
    end
    if self.axis == nil then
        return
    end
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

function Controller.ThumbstickAxis:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()

    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Connect to axis:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)

    -- Add choice control for the signal
    local choices = {}
    for _, axis in ipairs({"mc.X_AXIS", "mc.Y_AXIS", "mc.Z_AXIS", "mc.A_AXIS", "mc.B_AXIS", "mc.C_AXIS"}) do
        table.insert(choices, axis)
    end
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)

    if self.axis ~= nil then
        choice:SetSelection(self.axis)
    end

    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize)
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    propertiesPanel:Connect(applyId, wx.wxEVT_BUTTON, function()
        local axes = {mc.X_AXIS, mc.Y_AXIS, mc.Z_AXIS, mc.A_AXIS, mc.B_AXIS, mc.C_AXIS}
        selection = choice:GetSelection()
        if (self.axis == nil and selection ~= "") or (self.axis and self.axis ~= axes[selection]) then
            self.axis = axes[selection]
        end
    end)

    propSizer:Layout()
    propertiesPanel:Layout()

    -- Return the propertiesPanel sizer
    return propSizer
end

function Controller:newSlot(id, func)
    -- added a new 'id' attribute for Slots that we need to get from the constructor
    return self.Slot.new(self, id, func)
end

Controller.Slot = {}
Controller.Slot.__index = Controller.Slot
Controller.Slot.__type = "Slot"
Controller.Slot.__tostring = function(self)
    return string.format("Slot: %s", self.id)
end

function Controller.Slot.new(controller, id, func)
    if Controller.typeCheck({id, func}, {"string", "function"}) then
        return
    end
    local self = setmetatable({}, Controller.Slot)
    self.id = id
    self.controller = controller
    self.func = func
    table.insert(self.controller.slots, self)
    return self
end

xc = Controller.new()
---------------------------------
--- Custom Configuration Here ---

--- TODO: consider updating documentation to not mention any manual configuration of the controller object outside of the
--- "Advanced Usage" section.  When the GUI is fully working, most users will never need to do anything here.
--- TODO: update the GUI configurator to include a section of properties that are configured at the Controller level, such as
--- logging level, a
---
---
---
---
--- xes inversions and reversals, etc.
xc.logLevel = 4
xc:assignShift(xc.LTR)
xc.RTH_Y:connect(mc.Z_AXIS)
xc:mapSimpleJog(true)
xc.B.down:connect(xc:xcGetSlotById('E Stop Toggle'))
xc.Y.down:connect(xc.xcCntlTorchToggle)
xc.RSB.down:connect(xc:xcGetSlotById('Enable Toggle'))
xc.X.down:connect(xc:xcGetSlotById('XC Run Cycle Toggle'))
xc.BACK.altDown:connect(xc:xcGetSlotById('Home All'))
xc.START.altDown:connect(xc:xcGetSlotById('Home Z'))

-- End of custom configuration ---
----------------------------------
---
--[[ TODO: The current method of mocking the mcLuaPanelParent object doesn't actually work right, wxPanel is not a top-level gui object.
  We need to implement a mock that actually works and renders our GUI when we're not running connected to a live Mach4 instance.
  ]] --

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
]] --
local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
mcLuaPanelParent:SetMinSize(wx.wxSize(450, 500))
mcLuaPanelParent:SetMaxSize(wx.wxSize(450, 500))

-- Create a static box for the tree manager (left panel)
local treeBox = wx.wxStaticBox(mcLuaPanelParent, wx.wxID_ANY, "Controller Tree Manager")
local treeSizer = wx.wxStaticBoxSizer(treeBox, wx.wxVERTICAL)

-- Create tree control
local tree = wx.wxTreeCtrl.new(mcLuaPanelParent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(100, -1),
    wx.wxTR_HAS_BUTTONS, wx.wxDefaultValidator, "tree")

local root_id = tree:AddRoot(xc.id)
local treedata = {
    [root_id:GetValue()] = xc
}

-- Populate tree with inputs and axes
for i = 1, #xc.inputs do
    local child_id = tree:AppendItem(root_id, xc.inputs[i].id)
    treedata[child_id:GetValue()] = xc.inputs[i]
end
for i = 1, #xc.axes do
    local child_id = tree:AppendItem(root_id, xc.axes[i].id)
    treedata[child_id:GetValue()] = xc.axes[i]
end

tree:ExpandAll()

-- Add the tree control to the main sizer
treeSizer:Add(tree, 1, wx.wxEXPAND + wx.wxALL, 5)

-- Create a static box for the properties panel (right panel)
local propBox = wx.wxStaticBox(mcLuaPanelParent, wx.wxID_ANY, "Properties")
local propSizer = wx.wxStaticBoxSizer(propBox, wx.wxVERTICAL)

-- Create the properties panel
propertiesPanel = wx.wxPanel(mcLuaPanelParent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
local sizer = wx.wxFlexGridSizer(0, 2, 0, 0) -- 2 columns, auto-adjust rows
sizer:AddGrowableCol(1, 1)
propertiesPanel:SetSizer(sizer)
propertiesPanel:Layout()

local font = wx.wxFont(8, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL)
propertiesPanel:SetFont(font)
propBox:SetFont(font)
treeBox:SetFont(font)
tree:SetFont(font)

-- Add the properties panel to the properties sizer
propSizer:Add(propertiesPanel, 1, wx.wxEXPAND + wx.wxALL, 5)

tree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, function(event)
    -- Clear the current sizer's contents from the properties panel
    propertiesPanel:GetSizer():Clear(true) -- true ensures that the controls are destroyed

    -- Get the item associated with the tree selection
    local item = treedata[event:GetItem():GetValue()]

    -- Call the initUi method of the selected item and set it as the new sizer
    -- Set the new sizer and perform layout

    propertiesPanel:SetSizer(item:initUi(propertiesPanel))
    propertiesPanel:Fit()
    propertiesPanel:Layout()
end)

-- Add both sizers to the main sizer
mainSizer:Add(treeSizer, 0, wx.wxEXPAND + wx.wxALL, 5)
mainSizer:Add(propSizer, 1, wx.wxEXPAND + wx.wxALL, 5)

-- Set up the main sizer on the parent panel
mcLuaPanelParent:SetSizer(mainSizer)
mainSizer:Layout()

-- Show the parent panel and start the wx main loop
wx.wxGetApp():SetTopWindow(mcLuaPanelParent)
mcLuaPanelParent:Show(true)
wx.wxGetApp():MainLoop()

--[[ TODO: Is 100ms the right rate to be polling the inputs?  If 250ms(or some other longer amount of time) would be sufficient,
    the code would be more performant in terms of impact on the system itself, which is something we should at least be
    considering in a CNC application.  Setting the timer too long would result in the machine's response to controller inputs
    feeling sluggish, which is also unacceptable. Should probably do some testing to find a good happy medium value.]]
xc:xcCntlLog("Creating X360_timer", 4)
X360_timer = wx.wxTimer(mcLuaPanelParent)
mcLuaPanelParent:Connect(wx.wxEVT_TIMER, function()
    xc:update()
end)
xc:xcCntlLog("Starting X360_timer", 4)
X360_timer:Start(100)
