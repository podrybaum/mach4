require("object")
require("profile")
require("button")
require("thumbstickaxis")

---@class Controller: Object
---@field profile Profile
---@field configValues table
---@field children table
---@field id string
---@field parent Object
---@field logLevels table
---@field logLevel string
---@field shiftButton string
---@field jogIncrement string
---@field xYReversed string
---@field frequency string
---@field simpleJogMapped string
---@field DPad_UP Button
---@field DPad_DOWN Button
---@field DPad_LEFT Button
---@field DPad_RIGHT Button
---@field Btn_START Button
---@field Btn_BACK Button
---@field Btn_LS Button
---@field Btn_RS Button
---@field Btn_LTH Button
---@field Btn_RTH Button
---@field Btn_A Button
---@field Btn_B Button
---@field Btn_X Button
---@field Btn_Y Button
---@field LTR_Val Trigger
---@field RTR_Val Trigger
---@field LTH_Y_Val ThumbstickAxis
---@field LTH_X_Val ThumbstickAxis
---@field RTH_Y_Val ThumbstickAxis
---@field RTH_X_Val ThumbstickAxis
Controller = setmetatable({}, Object)
Controller.__type = "Controller"
Controller.__index = Controller

function Controller:new()
    self = Object:new(self, "xc")
    self.configValues["shiftButton"] = ""
    self.configValues["jogIncrement"] = "0"
    self.configValues["logLevel"] = "0"
    self.configValues["xYReversed"] = "false"
    self.configValues["frequency"] = "0"
    self.configValues["simpleJogMapped"] = "false"
    self:addChild(Button:new(self, "DPad_UP"))
    self:addChild(Button:new(self, "DPad_DOWN"))
    self:addChild(Button:new(self, "DPad_LEFT"))
    self:addChild(Button:new(self, "DPad_RIGHT"))
    self:addChild(Button:new(self, "Btn_START"))
    self:addChild(Button:new(self, "Btn_BACK"))
    self:addChild(Button:new(self, "Btn_LS"))
    self:addChild(Button:new(self, "Btn_RS"))
    self:addChild(Button:new(self, "Btn_LTH"))
    self:addChild(Button:new(self, "Btn_RTH"))
    self:addChild(Button:new(self, "Btn_A"))
    self:addChild(Button:new(self, "Btn_B"))
    self:addChild(Button:new(self, "Btn_X"))
    self:addChild(Button:new(self, "Btn_Y"))
    self:addChild(Trigger:new(self, "LTR_Val"))
    self:addChild(Trigger:new(self, "RTR_Val"))
    self:addChild(ThumbstickAxis:new(self, "LTH_Y_Val"))
    self:addChild(ThumbstickAxis:new(self, "LTH_X_Val"))
    self:addChild(ThumbstickAxis:new(self, "RTH_Y_Val"))
    self:addChild(ThumbstickAxis:new(self, "RTH_X_Val"))
    self.logLevels = {"ERROR", "WARNING", "INFO", "DEBUG"}
    local profileId = mc.mcProfileGetString(inst, "XBC4MACH4", "lastProfile", "0")
    self.profile = Profile.new(profileId, Profile.getProfiles()[profileId], self)
    return self
end


--- Retrieve the state of the xbox controller.
function Controller:update()
    if self.shiftButton ~= "" then
        self[self.shiftButton]:getState()
    end
    for _, input in pairs(self.children) do
        if input ~= self.shiftButton then
            input:getState()
        end
    end
end

--- Convenience method to map jogging to the DPad, and incremental jogging to the DPad's alternate function.
function Controller:mapSimpleJog()
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s", tostring(self.xYReversed)), 4)
    self.DPad_UP.Down = self.xYReversed == "true" and "Jog Y+" or "Jog X+"
    self.DPad_UP.Up = self.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_DOWN.Down = self.xYReversed == "true" and "Jog Y-" or "Jog X-"
    self.DPad_DOWN.Up = self.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_RIGHT.Down = self.xYReversed == "true" and "Jog X+" or "Jog Y+"
    self.DPad_RIGHT.Up = self.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    self.DPad_LEFT.Down = self.xYReversed == "true" and "Jog X-" or "Jog Y-"
    self.DPad_LEFT.Up = self.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    if self.xYReversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end
    self.DPad_UP.AltDown = "xcJogIncUp"
    self.DPad_DOWN.AltDown = "xcJogIncDown"
    self.DPad_RIGHT.AltDown = "xcJogIncRight"
    self.DPad_LEFT.AltDown = "xcJogIncLeft"
    if self.xYReversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function",
            3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
    self.simpleJogMapped = "true"
end

--- Logging method for the Controller library
---@param msg string @The message to log
---@param level number @The logging level to display the message at
function Controller:xcCntlLog(msg, level)
    if self.logLevel == "0" then
        return
    end
    if level <= tonumber(self.logLevel) then
        if mc.mcInEditor() ~= 1 then
            mc.mcCntlLog(inst, "[[XBOX CONTROLLER " .. self.logLevels[level] .. "]]: " .. msg, "", -1)
        else
            print("[[XBOX CONTROLLER " .. self.logLevels[level] .. "]]: " .. msg)
        end
    end
end


--- Retrieve a numeric value from a Mach4 register.
---@param reg string @The register to read format
---@return number|nil @The number retrieved from the register or nil if not found
function Controller:xcGetRegValue(reg)
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


--- Initialize the UI panel for the Controller object.
---@param propertiesPanel userdata @A wxPanel object for the properties panel
---@return userdata @The wxSizer (or subclass thereof) for the properties panel object
function Controller:initUi(propertiesPanel)
    ---@diagnostic disable-next-line: undefined-field
    local propSizer = propertiesPanel:GetSizer()

    local profiles = {}
    for _, name in pairs(Profile.getProfiles()) do
        table.insert(profiles, name)
    end
    local profileLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Current Profile:")
    propSizer:Add(profileLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local profileChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, profiles)
    propSizer:Add(profileChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    profileChoice:SetSelection(profileChoice:FindString(self.profile.name))

    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Assign shift button:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local choices = {""}
    for _, input in ipairs(self.children) do
        if input.__type ~= "ThumbstickAxis" then
            table.insert(choices, input.id)
        end
    end
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    choice:SetSelection(choice:FindString(self.shiftButton))

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
    logChoice:SetSelection(tonumber(self.logLevel))

    local swapLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Swap X and Y axes:")
    propSizer:Add(swapLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local swapCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "")
    swapCheck:SetValue(self.xYReversed == "true")
    propSizer:Add(swapCheck, 1, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    local frequencyLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Update Frequency (Hz):")
    propSizer:Add(frequencyLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local frequencyCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, self.frequency, wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(frequencyCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- apply button
    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply")
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    -- event handler for apply button
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel = wx.wxPanel(applyId, wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local choiceSelection = choice:GetStringSelection()
        if choiceSelection and choiceSelection ~= self.shiftButton then
            self.shiftButton = choiceSelection
        end
        local jogInc = jogIncCtrl:GetValue()
        if jogInc ~= nil and jogIncCtrl:IsModified() then
            self.jogIncrement = jogInc
        end
        local logChoiceSelection = logChoice:GetSelection()
        self.logLevel = logChoiceSelection
        local swapSelection = swapCheck:GetValue()
        if swapSelection ~= self.xYReversed then
            self.xYReversed = swapSelection
            self:mapSimpleJog()
        end
        local frequencyValue = frequencyCtrl:GetValue()
        if frequencyValue ~= nil then
            self.frequency = frequencyValue
        end
    end)

    -- Trigger the layout update and return the new sizer
    propSizer:Layout()
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Layout()
    return propSizer
end

return {Controller = Controller}