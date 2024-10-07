-- DEV_ONLY_START
-- Development environment specific hacks
if not mc then
    package.path = string.format("%s;%s?.lua", package.path,"C:\\Users\\Michael\\mach4\\")
    mocks = require("mocks")
end
scr = scr or require("scr")
wx = wx or require("wx")

-- Import needed modules.
require("descriptor")
require("button")
require("thumbstickaxis")
require("signal_slot")
-- DEV_ONLY_END

if mocks and mc == mocks.mc or mc.mcInEditor() == 1 then
    local luaPanelId = wx.wxNewId()
    mcLuaPanelParent = wx.wxFrame(wx.NULL, luaPanelId, "Mock Panel")
end

-- Global Mach4 instance
inst = mc.mcGetInstance()

--- Alias for a helpful one-liner.  If x ~= y, assign y to x.
---@param x any @a variable
---@param y any @a variable
function setIfNotEqual(x, y)
    x = (x ~= y) and y or x
end

-- TODO: implement more user-friendly names for inputs to use in the GUI
-- TODO: test slot functions provided by scr.DoFunctionName.
-- TODO: implement profile saving
-- TODO: unit tests
-- TODO: installer script
-- TODO: once tested, map screen functions to mapSimpleJog method
-- TODO: Something seems to be not working entirely as intended with ThumbstickAxis:connect method. The Jog rate doesn't seem to always update appropriately.
-- TODO: update docs 
-- TODO: create default controller profile
-- TODO: finish testing controller polling rate

--- An object representing an Xbox controller connected to Mach4.
---@class Controller
---@field profile number
---@field profileName string
---@field id string
---@field UP Button
---@field DOWN Button
---@field RIGHT Button
---@field LEFT Button
---@field A Button
---@field X Button
---@field B Button
---@field Y Button
---@field START Button
---@field BACK Button
---@field LTH Button
---@field RTH Button
---@field LSB Button
---@field RSB Button
---@field LTR Trigger
---@field RTR Trigger
---@field LTH_Y ThumbstickAxis
---@field RTH_Y ThumbstickAxis
---@field LTH_X ThumbstickAxis
---@field RTH_X ThumbstickAxis
---@field inputs table
---@field axes table
---@field shiftButton Button|nil
---@field jogIncrement number
---@field logLevel number
---@field logLevels table
---@field slots table
---@field xYReversed boolean
---@field frequency number
---@field xcCntlTorchToggle Slot
---@field simpleJogMapped boolean
---@field descriptors table
Controller = {}
Controller.__index = Controller
Controller.__type = "Controller"

--- Initialize a new Controller instance.
---@return Controller @The new Controller instance
function Controller.new()
    local self = setmetatable({}, Controller)
    self.id = "Controller"
    self.profileName = "default"
    self.shiftButton = self.LTR
    self.jogIncrement = 0.1
    self.logLevel = 2
    self.xYReversed = false
    self.frequency = 4
    self.simpleJogMapped = false

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
    self.logLevels = {"ERROR", "WARNING", "INFO", "DEBUG"}

    self.slots = {}
    local names = {"Cycle Start", "Cycle Stop", "Feed Hold", "Enable On", "Soft Limits On", "Soft Limits Off",
                   "Soft Limits Toggle", "Position Remember", "Position Return", "Limit OV On", "Limit OV Off",
                   "Limit OV Toggle", "Jog Mode Toggle", "Jog Mode Step", "Jog Mode Continuous", "Jog X+", "Jog Y+",
                   "Jog Z+", "Jog A+", "Jog B+", "Jog C+", "Jog X-", "Jog Y-", "Jog Z-", "Jog A-", "Jog B-", "Jog C-",
                   "Home All", "Home X", "Home Y", "Home Z", "Home A", "Home B", "Home C"}
    for i, name in ipairs(names) do
        self:newSlot(name, function()
            scr.DoFunctionName(name)
        end)
    end

    self:newSlot("Enable Off", function()
        local state = mc.mcCntlGetState(inst)
        if (state ~= mc.MC_STATE_IDLE) then
            scr.StartTimer(2, 250, 1);
        end
        scr.DoFunctionName("Enable Off")
    end)

    -- Tested and working as intended.
    self:newSlot("Enable Toggle", function()
        local enabled = self:xcGetMachSignalState(mc.OSIG_MACHINE_ENABLED)
        if enabled then
            local state = mc.mcCntlGetState(inst)
            if (state ~= mc.MC_STATE_IDLE) then
                scr.StartTimer(2, 250, 1);
            end
            scr.DoFunctionName("Enable Off")
        else
            scr.DoFunctionName("Enable On")
        end
    end)

    -- Tested and working as intended.
    self:newSlot("E Stop Toggle", function()
        self:xcToggleMachSignalState(mc.ISIG_EMERGENCY)
    end)

    -- NOTE: Probably not generic enough to include as pre-defined Slot
    self.xcCntlTorchToggle = self:newSlot("Torch/THC Toggle", function()
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT3)
        self:xcToggleMachSignalState(mc.OSIG_OUTPUT4)
    end)
    for i, slot in ipairs(self.slots) do
        if slot.id == "Torch/THC Toggle" then
            table.remove(self.slots, i)
        end
    end

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


    self:newDescriptor(self, "shiftButton", "input")
    self:newDescriptor(self, "jogIncrement", "number")
    self:newDescriptor(self, "logLevel", "number")
    self:newDescriptor(self, "xYReversed", "boolean")
    self:newDescriptor(self, "frequency", "number")
    self:newDescriptor(self, "simpleJogMapped", "boolean")
    self:newDescriptor(self, "profileName", "string")

    return self
end

--- STATIC METHOD: Checks to make sure that an instance of the correct class has been passed as the first parameter to a method call.
---This catches the error when a method that should use a colon is called with a period, so we can deliver a better error message.
---@param self any @the first parameter passed to the method.
---@return boolean @true if the method was called correctly.
function Controller.isCorrectSelf(self)
    local info = debug.getinfo(2, "nl")
    if info and info.name then
        local expected_class = getmetatable(self)
        if expected_class then
            local function_in_class = expected_class[info.name]
            local actual_function = debug.getinfo(2, "f").func
            return function_in_class == actual_function
        end
        error(
            string.format("Method %s was probably called with . instead of : at line %d.", info.name, info.currentline))
    end
    error(string.format("function Controller.isCorrectSelf should only be called from within a method! line: %d", info.currentline))
end

--- Type checking for custom types used by this module.
---@param object any @The object to typecheck
---@return string @The object's type, accounting for custom types defined in __type
function Controller.customType(object)
    if type(object) == "table" then
        local mt = getmetatable(object)
        return object.__type or (mt and mt.__type) or "table"
    else
        return type(object)
    end
end

--- Strict type checking to be imposed on all public methods.  Raises an error on failed type check.
---@param objects table @An array of objects to typecheck
---@param types table @Contains an array of arrays or strings containing types to check against for each object.
function Controller.typeCheck(objects, types)
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

--- Retrieve a numeric value from the profile.ini file.
---@param section string @The section of the profile.ini file to read from
---@param key string @The key from the section to retrieve
---@return number|boolean @The retrieved value or false if an error was encountered
function Controller:xcProfileGetDouble(section, key)
	defval = 0
    local val, rc = mc.mcProfileGetDouble(inst, section, key, defval)
	mc.mcProfileFlush(inst)
    if rc == mc.MERROR_NOERROR then
        return val
    end
    return false
end

--- Retrieve a string value from the profile.ini file.
---@param section string @The section of the profile.ini file to read from
---@param key string @The key from the section to retrieve
---@return string|boolean @The retrieved value or `false` if an error was encountered
function Controller:xcProfileGetString(section, key)
	local defval = ''
    local val, rc = mc.mcProfileGetString(inst, section, key, defval)
	mc.mcProfileFlush(inst)
    if rc == mc.MERROR_NOERROR then
        return val
    end
    return false
end

--- Write a numeric value to the profile.ini file.
---@param section string @The section of the profile.ini file to write to
---@param key string @The key to be written
---@param val number @The value to write
function Controller:xcProfileWriteDouble(section, key, val)
    print(string.format("writing %s, %s, %s",section, key, val))
    mc.mcProfileWriteDouble(inst, section, key, val)
    self:xcErrorCheck(mc.mcProfileFlush(inst))
   -- local state, rc = mc.mcCntlGetState(inst)
   -- if rc == mc.MERROR_NOERROR and state == mc.MC_STATE_IDLE then
  --      self:xcErrorCheck(mc.mcProfileReload(inst))
  --  end
end

--- Write a numeric value to the profile.ini file.
---@param section string @The section of the profile.ini file to write to
---@param key string @The key to be written
---@param val string @The value to write
function Controller:xcProfileWriteString(section, key, val)
    print(string.format("writing %s, %s, %s",section, key, val))
    mc.mcProfileWriteString(inst, section, key, val)
    self:xcErrorCheck(mc.mcProfileFlush(inst))
  --  local state, rc = mc.mcCntlGetState(inst)
  --  if rc == mc.MERROR_NOERROR and state == mc.MC_STATE_IDLE then
  --      self:xcErrorCheck(mc.mcProfileReload(inst))
  --  end
end

--- Initialize the UI panel for the Controller object.
---@param propertiesPanel userdata @A wxPanel object for the properties panel
---@return userdata @The wxSizer (or subclass thereof) for the properties panel object
function Controller:initUi(propertiesPanel)
    Controller.isCorrectSelf(self)
    ---@diagnostic disable-next-line: undefined-field
    local propSizer = propertiesPanel:GetSizer()

    local profiles = {"default"}
    local profileLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Current Profile:")
    propSizer:Add(profileLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local profileChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, profiles)
    propSizer:Add(profileChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    profileChoice:SetSelection(profileChoice:FindString(self.profileName))

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

    local jogIncLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Jog Increment:")
    propSizer:Add(jogIncLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local jogIncCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.jogIncrement), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(jogIncCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    local logLevels = {"0 - Disabled", "1 - Error", "2 - Warning", "3 - Info", "4 - Debug"}
    local logLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Logging level:")
    propSizer:Add(logLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local logChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, logLevels)
    propSizer:Add(logChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    logChoice:SetSelection(self.logLevel)

    local swapLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Swap X and Y axes:")
    propSizer:Add(swapLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local swapCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "")
    propSizer:Add(swapCheck, 1, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    local frequencyLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Update Frequency (Hz):")
    propSizer:Add(frequencyLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local frequencyCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.frequency), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(frequencyCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- apply button
    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply")
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    -- event handler for apply button
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Connect(applyId, wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local choiceSelection = self:xcGetInputById(choice:GetStringSelection())
        if choiceSelection and choiceSelection ~= self.shiftButton.id then
            self:assignShift(choiceSelection)
        end
        local jogInc = tonumber(jogIncCtrl:GetValue())
        if jogInc ~= nil and jogIncCtrl:IsModified() then
            self.jogIncrement = jogInc
        end
        local logChoiceSelection = logChoice:GetSelection()
        setIfNotEqual(self.logLevel, logChoiceSelection)
        local swapSelection = swapCheck:GetValue()
        if swapSelection ~= self.xYReversed then
            self.xYReversed = swapSelection
            self:mapSimpleJog()
        end
        local frequencyValue = tonumber(frequencyCtrl:GetValue())
        if frequencyValue ~= nil then
            setIfNotEqual(self.frequency, frequencyValue)
        end
    end)

    -- Trigger the layout update and return the new sizer
    propSizer:Layout()
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Layout()
    return propSizer
end

--- Retrieve an input by its id.
---@param id string @The id of the input to retrieve
---@return Button|Trigger|nil @The input with the given id or nil if not found
function Controller:xcGetInputById(id)
    Controller.isCorrectSelf(self)
    Controller.typeCheck({id}, {"string"})
    for _, input in ipairs(self.inputs) do
        if input.id == id then
            return input
        end
    end
    self:xcCntlLog(string.format("No Button with id %s found", id), 1)
    return nil
end

--- Retrieve a Slot by its id.
---@param id string @The id for the Slot to retrieve
---@return Slot|nil @The Slot with the given id or nil if not found
function Controller:xcGetSlotById(id)
    Controller.isCorrectSelf(self)
    Controller.typeCheck({id}, {"string"})
    for i, slot in ipairs(self.slots) do
        if slot.id == id then
            return slot
        end
    end
    self:xcCntlLog(string.format("No Slot with id %s found", id), 1)
end

--- Retrieve a numeric value from a Mach4 register.
---@param reg string @The register to read format
---@return number|nil @The number retrieved from the register or nil if not found
function Controller:xcGetRegValue(reg)
    Controller.isCorrectSelf(self) 
    Controller.typeCheck({reg}, {"string"}) 
    local hreg, rc = mc.mcRegGetHandle(inst, reg)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcRegGetValue(hreg)
        if rc == mc.MERROR_NOERROR then
            return val
        else
            self:xcCntlLog(string.format("Error in mcRegGetValue: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
        end
    else
        self:xcCntlLog(string.format("Error in mcRegGetHandle: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
    end
end

--- Check Mach4 signal state in a single call
---@param signal number the Mach4 signal to check
---@return boolean|nil true if signal is 1 false in the case of 0 or nil if not found
function Controller:xcGetMachSignalState(signal)
    Controller.isCorrectSelf(self) 
    Controller.typeCheck({signal}, {"number"}) 
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcSignalGetState(hsig)
        if rc == mc.MERROR_NOERROR then
            return val > 0
        else
            self:xcCntlLog(string.format("Error in mcSignalGetState: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
        end
    else
        self:xcCntlLog(string.format("Error in mcSignalGetHandle: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
    end
end

--- Toggle the state of a Mach4 signal.
---@param signal number @The Mach4 signal to toggle
function Controller:xcToggleMachSignalState(signal)
    Controller.isCorrectSelf(self) 
    Controller.typeCheck({signal}, {"number"}) 
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        self:xcErrorCheck(mc.mcSignalSetState(hsig, not mc.mcSignalGetState(inst, hsig)))
    end
end

--- Logging method for the Controller library
---@param msg string @The message to log
---@param level number @The logging level to display the message at
function Controller:xcCntlLog(msg, level)
    Controller.isCorrectSelf(self) 
    Controller.typeCheck({msg, level}, {"string", "number"}) 
    if self.logLevel == 0 then
        return
    end
    if level <= self.logLevel then
        if mc.mcInEditor() ~= 1 then
            mc.mcCntlLog(inst, "[[XBOX CONTROLLER " .. self.logLevels[level] .. "]]: " .. msg, "", -1)
        else
            print("[[XBOX CONTROLLER " .. self.logLevels[level] .. "]]: " .. msg)
        end
    end
end

--- Check Mach4 error return codes.
---@param rc number the return code to check
function Controller:xcErrorCheck(rc)
    Controller.isCorrectSelf(self) 
    Controller.typeCheck({rc}, {"number"}) 
    if rc ~= mc.MERROR_NOERROR then
        self:xcCntlLog(mc.mcCntlGetErrorString(inst, rc), 1)
    end
end

--- Retrieve the state of the xbox controller.
function Controller:update()
    Controller.isCorrectSelf(self) 
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

--- Assign an input as the controller's shift button.
---@param input Button|Trigger @The input to assign as a shift button
function Controller:assignShift(input)
    Controller.isCorrectSelf(self) 
    Controller.typeCheck({input}, {{"Button", "Trigger"}}) 
    if self.shiftButton ~= nil then
        self:xcCntlLog(string.format(
            "Call to assign a shift button with a shift button already assigned.\n%s will be unassigned before assigning new shift button.",
            tostring(self.shiftButton)), 2)
    end
    self.shiftButton = input
    self:xcCntlLog("" .. input.id .. " assigned as controller shift button.", 3)
end

--- Convenience method to map jogging to the DPad, and incremental jogging to the DPad's alternate function.
function Controller:mapSimpleJog()
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s", tostring(self.xYReversed)), 4)
    self.UP.Down:connect(self:newSlot('xcJogUp', function()
        mc.mcJogVelocityStart(inst, (self.xYReversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_POS)
    end))
    self.UP.Up:connect(self:newSlot('xcJogStopY', function()
        mc.mcJogVelocityStop(inst, (self.xYReversed and mc.Y_AXIS) or mc.X_AXIS)
    end))
    self.DOWN.Down:connect(self:newSlot('xcJogDown', function()
        mc.mcJogVelocityStart(inst, (self.xYReversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_NEG)
    end))
    self.DOWN.Up:connect(self:xcGetSlotById('xcJogStopY'))
    self.RIGHT.Down:connect(self:newSlot('xcJogRight', function()
        mc.mcJogVelocityStart(inst, (self.xYReversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_POS)
    end))
    self.RIGHT.Up:connect(self:newSlot('xcJogStopX', function()
        mc.mcJogVelocityStop(inst, (self.xYReversed and mc.X_AXIS) or mc.Y_AXIS)
    end))
    self.LEFT.Down:connect(self:newSlot('xcJogLeft', function()
        mc.mcJogVelocityStart(inst, (self.xYReversed and mc.X_AXIS) or mc.Y_AXIS, mc.MC_JOG_NEG)
    end))
    self.LEFT.Up:connect(self:xcGetSlotById('xcJogStopX'))
    if self.xYReversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end
    self.UP.AltDown:connect(self:newSlot('xcJogIncUp', function()
        mc.mcJogIncStart(inst, self.xYReversed and mc.Y_AXIS or mc.X_AXIS, self.jogIncrement)
    end))
    self.DOWN.AltDown:connect(self:newSlot('xcJogIncDown', function()
        mc.mcJogIncStart(inst, self.xYReversed and mc.Y_AXIS or mc.X_AXIS, -1 * self.jogIncrement)
    end))
    self.RIGHT.AltDown:connect(self:newSlot('xcJogIncRight', function()
        mc.mcJogIncStart(inst, self.xYReversed and mc.X_AXIS or mc.Y_AXIS, self.jogIncrement)
    end))
    self.LEFT.AltDown:connect(self:newSlot('xcJogIncLeft', function()
        mc.mcJogIncStart(inst, self.xYReversed and mc.X_AXIS or mc.Y_AXIS, -1 * self.jogIncrement)
    end))
    if self.xYReversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function",
            3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
    self.simpleJogMapped = true
end

--- Initialize a new Descriptor.
---@param object any @The object to attach the Descriptor to
---@param key string @The attribute to shadow
---@param datatype string @The data type the Descriptor manages
---@return Descriptor @The new Descriptor instance
function Controller:newDescriptor(object, key, datatype)
    local newDesc = Descriptor.new(self, object, key, datatype)
    newDesc:assign()
    return newDesc
end

--- Initialize a new Signal.
---@param button Button|Trigger @The input object the Signal belongs to
---@param id string @A unique(per input) identifier for the Signal
---@return Signal @The new Signal instance
function Controller:newSignal(button, id)
    return Signal.new(self, button, id)
end

--- Initialize a new Button.
---@param id string @A unique identifier for the Button.
---@return Button @The new Button instance
function Controller:newButton(id)
    return Button.new(self, id)
end

--- Initialize a new Trigger.
---@param id string @A unique identifier for the Trigger
---@return Trigger @The new Trigger instance
function Controller:newTrigger(id)
    return Trigger.new(self, id)
end

--- Initialize a new ThumbstickAxis
---@param id string @A unique identifier for the ThumbstickAxis
---@return ThumbstickAxis @The new ThumbstickAxis instance
function Controller:newThumbstickAxis(id)
    return ThumbstickAxis.new(self, id)
end

--- Initialize a new Slot.
---@param id string @A unique identifier for the Slot 
---@return Slot @The new Slot instance
function Controller:newSlot(id, func)
    Controller.isCorrectSelf(self) 
    Controller.typeCheck({id, func}, {"string", "function"}) 
    return Slot.new(self, id, func)
end

--- Create and save configuration profile.
function Controller:createProfile(id)
    xc:xcCntlLog("Building controller profile:",4)
    local section = string.format("ControllerProfile %s", id)
    local profile = {}
    for _, desc in ipairs(descriptorsStorage[self.id]) do
        profile[desc:lookup()] = desc:get()
    end
    for _, input in ipairs(self.inputs) do
        for _, desc in ipairs(descriptorsStorage[input.id]) do
            profile[desc:lookup()] = desc:get()
        end
    end
    for _, axis in ipairs(self.axes) do
        for _, desc in ipairs(descriptorsStorage[axis.id]) do
            profile[desc:lookup()] = desc:get()
        end
    end
    for k,v in pairs(profile) do
        if type(v) == "number" then
            self:xcProfileWriteDouble(section, k, v)
        else
            self:xcProfileWriteString(section, k, v)
        end
    end
end


--- Load a saved controller configuration.
---@param id string @The name of the saved config
function Controller:loadProfile(id)
    local section = string.format("ControllerProfile %s", id)
    local descMap = {}
    for _, desc in ipairs(self.descriptors) do
        local val
        if desc.datatype == "number" then
            val = self:xcProfileGetDouble(section, desc:lookup())
        else
            val = self:xcProfileGetString(section, desc:lookup())
        end
        rc = mc.mcProfileExists(inst, section, desc:lookup())
        if rc == mc.MC_TRUE then
            descMap[desc.attribute] = {desc.datatype, val}
        end
    end
    self.descriptors = {}
    for attribute, map in pairs(descMap) do
        self[attribute] = map[2]
        self:newDescriptor(self, attribute, map[1])
    end
    descMap = {}
    for _, input in ipairs(self.inputs) do
        for _, desc in ipairs(descriptorsStorage[input.id]) do
            local val
            if desc.datatype == "number" then
                val = self:xcProfileGetDouble(section, desc:lookup())
            else
                val = self:xcProfileGetString(section, desc:lookup())
            end
            rc = mc.mcProfileExists(inst, section, desc:lookup())
            if rc == mc.MC_TRUE then
                descMap[desc.object.id] = {desc.datatype, val}
            end
        end
        input.descriptors = {}
        for signalId, map in pairs(descMap) do
            for _, signal in ipairs(input.signals) do
                if signal.id == signalId then
                    input[signal.id].slot = self:xcGetSlotById(map[2])
                    self:newDescriptor(input, "slot", map[1])
                end
            end
        end
    end
end

xc = Controller.new()
---------------------------------
--- Custom Configuration Here ---

xc.logLevel = 4
xc:assignShift(xc.LTR)
xc.RTH_Y:connect(mc.Z_AXIS)
xc.xYReversed = true
print(xc.profileName, xc.simpleJogMapped)
if xc.profileName == 'default' and not xc.simpleJogMapped then

    xc:mapSimpleJog()
end
xc.B.Down:connect(xc:xcGetSlotById('E Stop Toggle'))
--xc.Y.down:connect(xc.xcCntlTorchToggle)
xc.RSB.Down:connect(xc:xcGetSlotById('Enable Toggle'))
xc.X.Down:connect(xc:xcGetSlotById('XC Run Cycle Toggle'))
xc.BACK.AltDown:connect(xc:xcGetSlotById('Home All'))
--xc.START.altDown:connect(xc:xcGetSlotById('Home Z'))

--xc:createProfile("default")
-- End of custom configuration ---
----------------------------------
local mcLuaPanelParent = mcLuaPanelParent
local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
mcLuaPanelParent:SetMinSize(wx.wxSize(450, 500))
mcLuaPanelParent:SetMaxSize(wx.wxSize(450, 500))

local treeBox = wx.wxStaticBox(mcLuaPanelParent, wx.wxID_ANY, "Controller Tree Manager")
local treeSizer = wx.wxStaticBoxSizer(treeBox, wx.wxVERTICAL)
local tree = wx.wxTreeCtrl.new(mcLuaPanelParent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(100, -1),
    wx.wxTR_HAS_BUTTONS, wx.wxDefaultValidator, "tree")
local root_id = tree:AddRoot(xc.id)
local treedata = {[root_id:GetValue()] = xc}
for i = 1, #xc.inputs do
    local child_id = tree:AppendItem(root_id, xc.inputs[i].id)
    treedata[child_id:GetValue()] = xc.inputs[i]
end
for i = 1, #xc.axes do
    local child_id = tree:AppendItem(root_id, xc.axes[i].id)
    treedata[child_id:GetValue()] = xc.axes[i]
end
tree:ExpandAll()
treeSizer:Add(tree, 1, wx.wxEXPAND + wx.wxALL, 5)
local propBox = wx.wxStaticBox(mcLuaPanelParent, wx.wxID_ANY, "Properties")
local propSizer = wx.wxStaticBoxSizer(propBox, wx.wxVERTICAL)
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
propSizer:Add(propertiesPanel, 1, wx.wxEXPAND + wx.wxALL, 5)
tree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, function(event)
    propertiesPanel:GetSizer():Clear(true)
    local item = treedata[event:GetItem():GetValue()]
    propertiesPanel:SetSizer(item:initUi(propertiesPanel))
    propertiesPanel:Fit()
    propertiesPanel:Layout()
end)
mainSizer:Add(treeSizer, 0, wx.wxEXPAND + wx.wxALL, 5)
mainSizer:Add(propSizer, 1, wx.wxEXPAND + wx.wxALL, 5)
mcLuaPanelParent:SetSizer(mainSizer)
mainSizer:Layout()


if mocks and mcLuaPanelParent == mocks.mcLuaPanelParent or mc.mcInEditor() == 1 then
    local app = wx.wxApp(false)
    wx.wxGetApp():SetTopWindow(mcLuaPanelParent)
    mcLuaPanelParent:Show(true)
    wx.wxGetApp():MainLoop()
end

xc:xcCntlLog("Creating X360_timer", 4)
X360_timer = wx.wxTimer(mcLuaPanelParent)
mcLuaPanelParent:Connect(wx.wxEVT_TIMER, function()
    xc:update()
end)
xc:xcCntlLog("Starting X360_timer", 4)
X360_timer:Start(1000 / xc.frequency)
