ThumbstickAxis = {}
ThumbstickAxis.__index = ThumbstickAxis
ThumbstickAxis.__type = "ThumbstickAxis"
ThumbstickAxis.__tostring = function(self)
    return string.format("ThumbstickAxis: %s", self.id)
end

function ThumbstickAxis.new(controller, id)
    local self = setmetatable({}, ThumbstickAxis)
    self.controller = controller
    self.id = id
    self.controller:newDescriptor(self, "axis", "number", nil)
    -- self.axis = nil
    self.controller:newDescriptor(self, "inverted", "boolean", false)
    -- self.inverted = false
    self.controller:newDescriptor(self, "deadzone", "number", 10)
    -- self.deadzone = 10
    self.rate = nil
    self.value = 0
    self.moving = false
    self.rateSet = false
    return self
end

function ThumbstickAxis:connect(axis, inverted)
    Controller.isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    Controller.typeCheck({axis, inverted}, {"number", "boolean"}) -- should raise an error if any param is of the wrong type
    self.axis = axis
    self.inverted = inverted
    local rc
    self.rate, rc = mc.mcJogGetRate(inst, self.axis)
    self.controller:xcErrorCheck(rc)
    self.controller:xcCntlLog(self.id .. " connected to " .. tostring(self.axis), 4)
    self.controller:xcCntlLog("Initial jog rate for " .. tostring(self.axis) .. " = " .. self.rate, 4)
end

function ThumbstickAxis:update()
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

function ThumbstickAxis:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()

    -- deadzone label and control
    local deadzoneLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Thumbstick deadzone:")
    propSizer:Add(deadzoneLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local deadzoneCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.deadzone), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(deadzoneCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- label and control
    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Connect to axis:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local choices = {}
    for _, axis in ipairs({"mc.X_AXIS", "mc.Y_AXIS", "mc.Z_AXIS", "mc.A_AXIS", "mc.B_AXIS", "mc.C_AXIS"}) do
        table.insert(choices, axis)
    end
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    if self.axis ~= nil then
        choice:SetSelection(self.axis)
    end

    -- inversion toggle
    -- local invertLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Invert axis:")
    -- propSizer:Add(invertLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    propSizer:Add(0, 0)
    local invertCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "Invert axis:")
    propSizer:Add(invertCheck, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- apply button
    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize)
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    -- event handler
    propertiesPanel:Connect(applyId, wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local axes = {mc.X_AXIS, mc.Y_AXIS, mc.Z_AXIS, mc.A_AXIS, mc.B_AXIS, mc.C_AXIS}
        local deadzone = tonumber(deadzoneCtrl:GetValue())
        setIfNotEqual(self.deadzone, deadzone)
        local selection = choice:GetSelection()
        if not (self.axis == nil and selection == "") then
            self.axis = axes[selection]
        end
        setIfNotEqual(self.inverted, invertCheck:GetValue())
    end)

    -- Refresh and return the new layout
    propSizer:Layout()
    propertiesPanel:Layout()
    propertiesPanel:Fit()
    propertiesPanel:Refresh()
    return propSizer
end