
Button = {}
Button.__index = Button
Button.__type = "Button"
Button.__tostring = function(self)
    return string.format("Button: %s", self.id)
end

function Button.new(controller, id)
    local self = setmetatable({}, Button)
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

function Button:getState()
    local state = self.controller:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
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

function Button:initUi(propertiesPanel)
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
    propertiesPanel:Connect(applyId, wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
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
