--- An object representing an analog joystick controller input.
---@class ThumbstickAxis
---@field id string
---@field controller Controller
---@field rate number
---@field value number
---@field moving boolean
---@field rateSet boolean
---@field deadzone number
---@field inverted boolean
---@field axis number|nil
ThumbstickAxis = {}
ThumbstickAxis.__index = ThumbstickAxis
ThumbstickAxis.__type = "ThumbstickAxis"
ThumbstickAxis.__tostring = function(self)
    return string.format("ThumbstickAxis: %s", self.id)
end

--- Initialize a new ThumbstickAxis object.
---@param controller Controller @A Controller instance
---@param id string @A unique identifier for the input
---@return ThumbstickAxis @The new ThumbstickAxis instance
function ThumbstickAxis.new(controller, id)
    local self = setmetatable({}, ThumbstickAxis)
    self.controller = controller
    self.id = id
    -- MUST be unset when Descriptor is assigned
    self.deadzone = 10
    self.controller:newDescriptor(self, "axis", "number", nil)
    self.controller:newDescriptor(self, "inverted", "boolean", false)
    self.controller:newDescriptor(self, "deadzone", "number", 10)
    self.rate = 0
    self.value = 0
    self.moving = false
    self.rateSet = false
    return self
end

--- Connect the analog output of a ThumbstickAxis object to a machine axis.
---@param axis number @A Mach4 enum representing a machine axis
---@param inverted boolean @Whether or not to invert the axis travel direction
function ThumbstickAxis:connect(axis, inverted)
    self.controller.isCorrectSelf(self)
    self.controller.typeCheck({axis, inverted}, {"number", "boolean"})
    self.axis = axis
    self.inverted = inverted
    local rc
    self.rate, rc = mc.mcJogGetRate(inst, self.axis)
    self.controller:xcErrorCheck(rc)
    self.controller:xcCntlLog(self.id .. " connected to " .. tostring(self.axis), 4)
    self.controller:xcCntlLog("Initial jog rate for " .. tostring(self.axis) .. " = " .. self.rate, 4)
end

--- Retrieve the state of the input.
function ThumbstickAxis:update()
    if self.axis == nil then
        return
    end
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

--- Create the properties panel UI for the input.
---@param propertiesPanel userdata @A wxPanel Object
---@return userdata @A wxSizer object containing the UI layout
function ThumbstickAxis:initUi(propertiesPanel)
    ---@diagnostic disable-next-line: undefined-field
    local propSizer = propertiesPanel:GetSizer()

    -- deadzone label and control
    local deadzoneLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Thumbstick deadzone:")
    propSizer:Add(deadzoneLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local deadzoneCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.deadzone), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(deadzoneCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    -- axis label and control
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

    propSizer:Add(0, 0)
    local invertCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "Invert axis:", wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxALIGN_RIGHT)
    propSizer:Add(invertCheck, 1, wx.wxALIGN_LEFT | wx.wxEXPAND + wx.wxALL, 5)

    -- apply button
    propSizer:Add(0, 0)
    local applyId = wx.wxNewId()
    local apply = wx.wxButton(propertiesPanel, applyId, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize)
    propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    -- event handler
    ---@diagnostic disable-next-line: undefined-field
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
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Layout(); propertiesPanel:Fit(); propertiesPanel:Refresh()
    return propSizer
end