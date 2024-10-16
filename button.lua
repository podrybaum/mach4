require("object")
require("controller")
local slots = require("slot_functions")

--- Object representing a digital pushbutton controller input.
---@class Button: Object
---@field parent Controller
---@field id string
---@field pressed boolean
---@field configValues table
---@field Up string
---@field Down string
---@field altUp string
---@field altDown string
Button = setmetatable({}, Object)
Button.__index = Button
Button.__type = "Button"

--- Initialize a new Button instance.
---@param parent Controller @A Controller instance
---@param id string @A unique identifier for the input.
function Button:new(parent, id)
    self = Object.new(self, parent, id)
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
        if self.parent.shiftButton ~= self then
            if not self.parent.shiftButton or not self.parent[self.parent.shiftButton].pressed then
                if self.configValues["down"] ~= "" then
                    slots[self.configValues["down"]]()
                end
            else
                if self.configValues["altDown"] ~= "" then
                    slots[self.configValues["altDown"]]()
                end
            end
        end
    elseif (state == 0) and self.pressed then
        self.pressed = false
        if self.parent.shiftButton ~= self then
            if not self.parent.shiftButton or not self.parent[self.parent.shiftButton].pressed then
                slots[self.configValues["up"]]()
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

    if not (self.id == self.parent.shiftButton) then
        -- Slot labels and dropdowns
        local options = {""}
        local analogOptions = {""}
        for _, slot in ipairs(slots) do
            options[#options + 1] = slot.id
        end
        local idMapping = {}
        for state, _ in pairs(self.configValues) do
            local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, string.format("%s Action:", state))
            propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
            local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,
                self.__type == "Trigger" and analogOptions or options)
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
            for state, _ in pairs(self.configValues) do
                local choice = idMapping[state]
                local selection = choice:GetStringSelection()
                self.configValues[state] = selection
            end
        end)

        -- Refresh and return the layout
    ---@diagnostic disable-next-line: undefined-field
        propertiesPanel:Layout()
    ---@diagnostic disable-next-line: undefined-field
        propertiesPanel:Fit()
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
---@field analog string
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
        if self.parent.shiftButton ~= self then
            if not self.parent.shiftButton or not self.parent[self.parent.shiftButton].pressed then
                if self.configValues["down"] ~= "" then
                    slots[self.configValues["down"]]()
                end
            else
                if self.configValues["altDown"] ~= "" then
                    slots[self.configValues["altDown"]]()
                end
            end
        end
    elseif self.value == 0 and self.pressed then
        self.pressed = false
        if self.parent.shiftButton ~= self then
            if not self.parent.shiftButton or not self.parent[self.parent.shiftButton].pressed then
                slots[self.configValues["up"]]()
            else
                slots[self.configValues["altUp"]]()
            end
        end
    end
end

return {Button=Button, Trigger=Trigger}