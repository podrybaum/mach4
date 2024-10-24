
-- DEV_ONLY_START
local object = require("object")
local pairsByKeys = object.pairsByKeys
local sortConfig = object.sortConfig
-- DEV_ONLY_END

local slots = {}

local success, customSlots = pcall(require, "slot_functions")
if success then
    for k, v in pairs(customSlots) do
        slots[k] = v
    end
end




--- Object representing a digital pushbutton controller input.
---@class Button: Type
---@field parent Controller
---@field id string
---@field pressed boolean
---@field configValues table
Button = class("Button", Type)

--- Initialize a new Button instance.
---@return Button @The new Button instance
function Button.new(self)
    self.pressed = false
    self.configValues["Up"] = ""
    self.configValues["Down"] = ""
    self.configValues["altUp"] = ""
    self.configValues["altDown"] = ""
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
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                if self.configValues["Down"] ~= "" then
                    slots[self.configValues["Down"]]()
                end
            else
                if self.configValues["altDown"] ~= "" then
                    slots[self.configValues["altDown"]]()
                end
            end
        end
    elseif (state == 0) and self.pressed then
        self.pressed = false
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                slots[self.configValues["Up"]]()
            else
                slots[self.configValues["altUp"]]()
            end
        end
    end
end

--- Create the properties panel UI for the input.
---@param propertiesPanel userdata @A wxPanel Object
---@return userdata @A wxSizer object containing the UI layout
function Button:initUi(propertiesPanel)
---@diagnostic disable-next-line: undefined-field
    local propSizer = propertiesPanel:GetSizer()
    if not (self.id == self.parent.configValues.shiftButton) then
        -- Slot labels and dropdowns
        local options = {""}
        local analogOptions = {""}
        for name, _ in pairsByKeys(slots) do
            options[#options + 1] = name
        end
        local idMapping = {}
        for state, _ in pairsByKeys(self.configValues, sortConfig) do
            local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, string.format("%s Action:", state))
            propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
            local choices
            if self:isInstance(Trigger) then
                choices = analogOptions
            else
                choices = options
            end
            local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,choices)
            idMapping[state] = choice
            if self.configValues[state] ~= "" then
                choice:SetSelection(choice:FindString(self.configValues[state]))
            end
            propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
        end

        -- Add the apply button and the event handler 
        propSizer:Add(0, 0)
        local applyId = wx.wxNewId()
        local apply = wx.wxButton(propertiesPanel, applyId, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize)
        propSizer:Add(apply, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

        -- Event handler
    ---@diagnostic disable-next-line: undefined-field
        propertiesPanel:Connect(applyId, wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            for state, _ in pairsByKeys(self.configValues, sortConfig) do
                local choice = idMapping[state]
                local selection = choice:GetStringSelection()
                self.configValues[state] = selection
            end
        end)

        -- Refresh and return the layout
    ---@diagnostic disable-next-line: undefined-field
        propertiesPanel:Layout()
    ---@diagnostic disable-next-line: undefined-field
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
---@field value number
---@field pressed boolean
---@field configValues table
Trigger = class("Trigger", Button)

--- Initialize a new Trigger instance.
---@return Trigger @The new Trigger instance
function Trigger.new(self)
    self.value = 0
    self.configValues["analog"] = ""
    return self
end

--- Retrieve the state of the input.
function Trigger:getState()
    local val = self.parent:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if val ~= nil then
        self.value = val
    end
    if type(self.value) ~= "number" then
        self.parent:xcCntlLog("Invalid state for " .. self.id, 1)
        return
    end

    if self.value > 0 and self.configValues["analog"] ~= "" then
        slots[self.configValues["analog"]](self.value)
        return
    end

    if self.value > 0 and (not self.pressed) then
        self.pressed = true
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                if self.configValues["Down"] ~= "" then
                    slots[self.configValues["Down"]]()
                end
            else
                if self.configValues["altDown"] ~= "" then
                    slots[self.configValues["altDown"]]()
                end
            end
        end
    elseif self.value == 0 and self.pressed then
        self.pressed = false
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                if self.configValues["Up"] ~= "" then
                    slots[self.configValues["Up"]]()
                end
            else
                if self.configValues["altUp"] ~= "" then
                    slots[self.configValues["altUp"]]()
                end
            end
        end
    end
end

-- DEV_ONLY_START
return {Button=Button, Trigger=Trigger, slots=slots}
-- DEV_ONLY_END