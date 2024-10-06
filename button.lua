--- Object representing a digital pushbutton controller input.
---@class Button
---@field controller Controller
---@field id string
---@field pressed boolean
---@field up Signal
---@field down Signal
---@field altUp Signal
---@field altDown Signal
---@field signals table
Button = {}
Button.__index = Button
Button.__type = "Button"
Button.__tostring = function(self)
    return string.format("Button: %s", self.id)
end

--- Initialize a new Button instance.
---@param controller Controller @A Controller instance.
---@param id string @A unique identifier for the input.
function Button.new(controller, id)
    local self = setmetatable({}, Button)
    self.controller = controller
    self.id = id
    self.pressed = false
    self.up = self.controller:newSignal(self, "Up")
    self.down = self.controller:newSignal(self, "Down")
    self.altUp = self.controller:newSignal(self, "Alternate Up")
    self.altDown = self.controller:newSignal(self, "Alternate Down")
    self.signals = {self.up, self.down, self.altUp, self.altDown}
    return self
end

--- Retrieves the state of the input.
function Button:getState()
    local state = self.controller:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(state) ~= "number" then
        self.controller:xcCntlLog(string.format("Invalid state for %s", self.id), 1)
        return
    end
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        if self.controller.shiftButton ~= self then
            if not self.controller.shiftButton or not self.controller.shiftButton.pressed then
                self.down:emit()
            else
                self.altDown:emit()
            end
        end
    elseif (state == 0) and self.pressed then
        self.pressed = false
        if self.controller.shiftButton ~= self then
            if not self.controller.shiftButton or not self.controller.shiftButton.pressed then
                self.up:emit()
            else
                self.altUp:emit()
            end
        end
    end
end

--- Create the properties panel UI for the input.
---@param propertiesPanel userdata @A wxPanel Object
---@return userdata @A wxSizer object containing the UI layout
function Button:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()

    if not self == self.controller.shiftButton then
        -- Slot labels and dropdowns
        local options = {""}
        local analogOptions = {""}
        for _, slot in ipairs(self.controller.slots) do
            options[#options + 1] = slot.id
        end
        local idMapping = {}
        for i, signal in ipairs(self.signals) do
            local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, string.format("%s Action:", signal.id))
            propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
            local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,
                self.__type == "Trigger" and analogOptions or options)
            idMapping[self.signals[i]] = choice
            if self.signals[i].slot ~= nil then
                choice:SetSelection(choice:FindString(self.signals[i].slot.id))
            end
            propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
        end

        -- Add the apply button and the event handler 
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
    else
        -- Disable config for an assigned shift button.
        local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "This input is currently assigned as the shift button.")
        propSizer:Add(0,0)
        propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
        return propSizer
    end
end

--- Object representing an analog pushbutton controller input.
---@class Trigger: Button 
---@field new function
---@field value number|nil
---@field analog Signal
---@field getState function
---@field connect function
Trigger = {}
Trigger.__index = Button
Trigger.__type = "Trigger"
Trigger.__tostring = function(self)
    return string.format("Trigger: %s", self.id)
end

--- Initialize a new Trigger instance.
---@param controller Controller @A Controller instance
---@param id string @unique identifier for the Trigger object
---@return Trigger @the new Trigger instance
function Trigger.new(controller, id)
    ---@class Trigger
    local self --[[@as Trigger]] = Button.new(controller, id)
    setmetatable(self, Trigger)
    self.__type = "Trigger"
    self.value = 0
    self.analog = self.controller:newSignal(self, "Analog")
    table.insert(self.signals, self.analog)
    return self
end

--- Retrieve the state of the input.
function Trigger:getState()
    self.value = self.controller:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
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

--- Connect a Trigger's analog output to a function.
---@param func function @The function to connect.
function Trigger:connect(func)
    self.controller.isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    self.controller.typeCheck({func}, {"function"}) -- should raise an error if any param is of the wrong type
    self.func = func
end
