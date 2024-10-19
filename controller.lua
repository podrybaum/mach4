require("object")
require("profile")
require("button")
require("thumbstickaxis")

---@class Controller: Type
---@field profile Profile
---@field configValues table
---@field children table
---@field id string
---@field parent Controller
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
Controller = class("Controller", Type)

function Controller:new()
    self.configValues["shiftButton"] = ""
    self.configValues["jogIncrement"] = "0"
    self.configValues["logLevel"] = "0"
    self.configValues["xYReversed"] = "false"
    self.configValues["frequency"] = "0"
    self.configValues["simpleJogMapped"] = "false"
    self:addChild(Button("DPad_UP", self))
    self:addChild(Button("DPad_DOWN", self))
    self:addChild(Button("DPad_LEFT", self))
    self:addChild(Button("DPad_RIGHT", self))
    self:addChild(Button("Btn_START", self))
    self:addChild(Button("Btn_BACK", self))
    self:addChild(Button("Btn_LS", self))
    self:addChild(Button("Btn_RS", self))
    self:addChild(Button("Btn_LTH", self))
    self:addChild(Button("Btn_RTH", self))
    self:addChild(Button("Btn_A", self))
    self:addChild(Button("Btn_B", self))
    self:addChild(Button("Btn_X", self))
    self:addChild(Button("Btn_Y", self))
    print(getmetatable(getmetatable(Trigger)).__name)
    self:addChild(Trigger("LTR_Val", self))
    self:addChild(Trigger("RTR_Val", self))
    self:addChild(ThumbstickAxis("LTH_Y_Val", self))
    self:addChild(ThumbstickAxis("LTH_X_Val", self))
    self:addChild(ThumbstickAxis("RTH_Y_Val", self))
    self:addChild(ThumbstickAxis("RTH_X_Val", self))
    self.logLevels = {"ERROR", "WARNING", "INFO", "DEBUG"}
    local profileId = mc.mcProfileGetString(inst, "XBC4MACH4", "lastProfile", "0")
    self.profile = Profile.new(profileId, Profile.getProfiles()[profileId], self)
    self.profile:load()
    return self
end


--- Retrieve the state of the xbox controller.
function Controller:update()
    if self.configValues.shiftButton ~= "" then
        self[self.configValues.shiftButton]:getState()
    end
    for _, input in pairs(self.children) do
        if input ~= self.configValues.shiftButton then
            input:getState()
        end
    end
end

--- Convenience method to map jogging to the DPad, and incremental jogging to the DPad's alternate function.
function Controller:mapSimpleJog()
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s", tostring(self.configValues.xYReversed)), 4)
    self.DPad_UP.Down = self.configValues.xYReversed == "true" and "Jog Y+" or "Jog X+"
    self.DPad_UP.Up = self.configValues.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_DOWN.Down = self.configValues.xYReversed == "true" and "Jog Y-" or "Jog X-"
    self.DPad_DOWN.Up = self.configValues.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_RIGHT.Down = self.configValues.xYReversed == "true" and "Jog X+" or "Jog Y+"
    self.DPad_RIGHT.Up = self.configValues.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    self.DPad_LEFT.Down = self.configValues.xYReversed == "true" and "Jog X-" or "Jog Y-"
    self.DPad_LEFT.Up = self.configValues.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    if self.configValues.xYReversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end
    self.DPad_UP.AltDown = "xcJogIncUp"
    self.DPad_DOWN.AltDown = "xcJogIncDown"
    self.DPad_RIGHT.AltDown = "xcJogIncRight"
    self.DPad_LEFT.AltDown = "xcJogIncLeft"
    if self.configValues.xYReversed then
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
    if self.configValues.logLevel == "0" then
        return
    end
    if level <= tonumber(self.configValues.logLevel) then
        if mc.mcInEditor() ~= 1 then
            mc.mcCntlLog(inst, "[[XBOX CONTROLLER " .. self.configValues.logLevels[level] .. "]]: " .. msg, "", -1)
        else
            print("[[XBOX CONTROLLER " .. self.configValues.logLevels[level] .. "]]: " .. msg)
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
    choice:SetSelection(choice:FindString(self.configValues.shiftButton))

    local jogIncLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Jog Increment:")
    propSizer:Add(jogIncLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local jogIncCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.configValues.jogIncrement), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(jogIncCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    local logLevels = {"0 - Disabled", "1 - Error", "2 - Warning", "3 - Info", "4 - Debug"}
    local logLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Logging level:")
    propSizer:Add(logLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local logChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, logLevels)
    propSizer:Add(logChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    logChoice:SetSelection(tonumber(self.configValues.logLevel))

    local swapLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Swap X and Y axes:")
    propSizer:Add(swapLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local swapCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "")
    swapCheck:SetValue(self.configValues.xYReversed == "true")
    propSizer:Add(swapCheck, 1, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    local frequencyLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Update Frequency (Hz):")
    propSizer:Add(frequencyLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local frequencyCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, self.configValues.frequency, wx.wxDefaultPosition,
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
        local choiceSelection = choice:GetStringSelection()
        if choiceSelection and choiceSelection ~= self.configValues.shiftButton then
            self.configValues.shiftButton = choiceSelection
        end
        local jogInc = jogIncCtrl:GetValue()
        if jogInc ~= nil and jogIncCtrl:IsModified() then
            self.configValues.jogIncrement = jogInc
        end
        local logChoiceSelection = logChoice:GetSelection()
        self.configValues.logLevel = logChoiceSelection
        local swapSelection = swapCheck:GetValue()
        if swapSelection ~= self.configValues.xYReversed then
            self.configValues.xYReversed = swapSelection
            self:mapSimpleJog()
        end
        local frequencyValue = frequencyCtrl:GetValue()
        if frequencyValue ~= nil then
            self.configValues.frequency = frequencyValue
        end
    end)

    -- Trigger the layout update and return the new sizer
    propSizer:Layout()
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Layout()
    return propSizer
end

return {Controller = Controller}