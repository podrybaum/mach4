--- An object representing an analog joystick parent input.
---@class ThumbstickAxis : Type
---@field id string
---@field parent Controller
---@field rate number
---@field value number
---@field moving boolean
---@field rateSet boolean
---@field configValues table
ThumbstickAxis = class("ThumbstickAxis", Type)

--- Initialize a new ThumbstickAxis object.
---@return ThumbstickAxis @The new ThumbstickAxis instance
function ThumbstickAxis.new(self)
    self.configValues["axis"] = ""
    self.configValues["inverted"] = "false"
    self.configValues["deadzone"] = "10"
    self.rate = 0
    self.value = 0
    self.moving = false
    self.rateSet = false
    return self
end

--- Retrieve the state of the input.
function ThumbstickAxis:getState()
    if self.configValues.axis == nil then
        return
    end
    local val = self.parent:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if val ~= nil then
        self.value = val
    end
    if type(self.value) ~= "number" then
        self.parent:xcCntlLog("Invalid value for ThumbstickAxis", 1)
        return
    end
    if not self.moving and not self.rateReset then
        if mc.mcJogGetRate(inst, self.configValues.axis) ~= self.rate then
            mc.mcJogSetRate(inst, self.configValues.axis, self.rate)
            self.rateReset = true
        end
    end

    if math.abs(self.value) > tonumber(self.configValues.deadzone) and not self.moving then
        self.moving = true
        self.rateReset = false
        mc.mcJogSetRate(inst, self.configValues.axis, math.abs(self.value))
        local direction = 1
        if self.configValues.inverted then
            direction = (self.value > 0) and mc.MC_JOG_NEG or mc.MC_JOG_POS
        else
            direction = (self.value > 0) and mc.MC_JOG_POS or mc.MC_JOG_NEG
        end
        mc.mcJogVelocityStart(inst, self.configValues.axis, direction)
    end

    if math.abs(self.value) < tonumber(self.configValues.deadzone) and self.moving then
        mc.mcJogVelocityStop(inst, self.configValues.axis)
        self.moving = false
        mc.mcJogSetRate(inst, self.configValues.axis, self.rate)
        self.rateReset = true
    end
end

--- Create the properties panel UI for the input.
---@param propertiesPanel userdata @A wxPanel Object
---@return userdata @A wxSizer object containing the UI layout
function ThumbstickAxis:initUi(propertiesPanel)
    ---@diagnostic disable-next-line: undefined-field
    local propSizer = propertiesPanel:GetSizer()

    -- deadzone label and control
    local deadzoneLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Thumbstick deadzone:")
    propSizer:Add(deadzoneLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local deadzoneCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, self.configValues.deadzone, wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    deadzoneCtrl:SetValue(self.configValues.deadzone)
    propSizer:Add(deadzoneCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- axis label and control
    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Connect to axis:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local choices = {"mc.X_AXIS", "mc.Y_AXIS", "mc.Z_AXIS", "mc.A_AXIS", "mc.B_AXIS", "mc.C_AXIS", ""}
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    choice:SetSelection(tonumber(self.configValues.axis) or 7)

    propSizer:Add(0, 0)
    local invertCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "Invert axis:", wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxALIGN_RIGHT)
    invertCheck:SetValue(self.configValues.inverted == "true")
    propSizer:Add(invertCheck, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- apply button
    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize)
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    -- event handler
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Connect(applyId, wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local axes = {mc.X_AXIS, mc.Y_AXIS, mc.Z_AXIS, mc.A_AXIS, mc.B_AXIS, mc.C_AXIS}
        local deadzone = deadzoneCtrl:GetValue()
        self.configValues.deadzone = deadzone
        local selection = choice:GetSelection()
        self.configValues.axis = selection
        self.configValues.inverted = tostring(invertCheck:GetValue())
    end)

    -- Refresh and return the new layout
    propSizer:Layout()
    return propSizer
end

return {ThumbstickAxis = ThumbstickAxis}