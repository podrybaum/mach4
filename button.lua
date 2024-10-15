require("signal_slot")

--- Object representing a digital pushbutton controller input.
---@class Button: Object
---@field parent Controller
---@field id string
---@field pressed boolean
---@field Up Signal
---@field Down Signal
---@field AltUp Signal
---@field AltDown Signal
---@field children table
Button = setmetatable({}, Object)
Button.__index = Button
Button.__type = "Button"

--- Initialize a new Button instance.
---@param parent Controller @A Controller instance
---@param id string @A unique identifier for the input.
function Button:new(parent, id)
    self = Object.new(self, parent, id)
    self.pressed = false
    self:addChild(Signal:new(self, "Up"))
    self:addChild(Signal:new(self, "Down"))
    self:addChild(Signal:new(self, "AltUp"))
    self:addChild(Signal:new(self, "AltDown"))
    return self
end

--- Retrieves the state of the input.
function Button:getState()
    local state = self.parent:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(state) ~= "number" then
        self.parent:xcCntlLog(string.format("Invalid state for %s", self.id), 1)
        return
    end
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        if self.parent.shiftButton ~= self then
            if not self.parent.shiftButton or not self.parent.shiftButton.pressed then
                self.Down:emit()
            else
                self.AltDown:emit()
            end
        end
    elseif (state == 0) and self.pressed then
        self.pressed = false
        if self.parent.shiftButton ~= self then
            if not self.parent.shiftButton or not self.parent.shiftButton.pressed then
                self.Up:emit()
            else
                self.AltUp:emit()
            end
        end
    end
end

--- Create the properties panel UI for the input.
---@param propertiesPanel userdata @A wxPanel Object
---@return userdata @A wxSizer object containing the UI layout
function Button:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()

    if not (self == self.parent.shiftButton) then
        -- Slot labels and dropdowns
        local options = {""}
        local analogOptions = {""}
        for _, slot in ipairs(self.parent.slots) do
            options[#options + 1] = slot.id
        end
        local idMapping = {}
        for i, signal in ipairs(self.children) do
            local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, string.format("%s Action:", signal.id))
            propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
            local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,
                self.__type == "Trigger" and analogOptions or options)
            idMapping[self.children[i]] = choice
            if self.children[i].slot ~= nil then
                choice:SetSelection(choice:FindString(self.children[i].slot.id))
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
            for i, signal in ipairs(self.children) do
                local choice = idMapping[signal]
                local selection = choice:GetStringSelection()
                if (signal.slot == nil and selection ~= "") or (signal.slot and signal.slot.id ~= selection) then
                    signal:connect(self.parent:xcGetSlotById(selection))
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
---@field parent Controller
---@field id string
---@field value number|nil
---@field Analog Signal
---@field children table
Trigger = setmetatable({}, Button)
Trigger.__index = Trigger
Trigger.__type = "Trigger"
setmetatable(Trigger, {__index = Button})

--- Initialize a new Trigger instance.
---@param parent Controller @A Controller instance
---@param id string @unique identifier for the Trigger object
---@return Trigger @the new Trigger instance
function Trigger:new(parent, id)
    self = Button.new(self, parent, id)
    self.value = 0
    self:addChild(Signal:new(self, "Analog"))
    return self
end

--- Retrieve the state of the input.
function Trigger:getState()
    self.value = self.parent:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(self.value) ~= "number" then
        self.parent:xcCntlLog("Invalid state for " .. self.id, 1)
        return
    end

    if self.value > 0 and self.Analog.slot then
        self.Analog:emit()
        return
    end

    if math.abs(self.value) > 125 and not self.pressed then
        self.Down:emit()
        self.pressed = true
    elseif math.abs(self.value) < 5 and self.pressed then
        self.Up:emit()
        self.pressed = false
    end
end

--- Connect a Trigger's analog output to a function.
---@param func function @The function to connect.
function Trigger:connect(func)
    self.parent.isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    self.parent.typeCheck({func}, {"function"}) -- should raise an error if any param is of the wrong type
    self.func = func
end

return Button, Trigger