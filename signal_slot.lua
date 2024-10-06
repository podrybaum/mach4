--- An object representing a signal emitted by a controller input.
---@class Signal
---@field id string
---@field button Button|Trigger
---@field controller Controller
---@field descriptors table
Signal = {}
Signal.__index = Signal
Signal.__type = "Signal"
Signal.__tostring = function(self)
    return string.format("Signal: %s", self.id)
end

--- Initialize a new Signal instance.
---@param controller Controller @A Controller instance
---@param button Button|Trigger @The input the Signal is assigned to
---@param id string @A unique (per input) identifier for the Signal
---@return Signal @The new Signal instance
function Signal.new(controller, button, id)
    local self = setmetatable({}, Signal)
    self.id = id
    self.button = button
    self.controller = controller
    self.descriptors = {}
    self.controller:newDescriptor(self, "slot", "object", nil)
    return self
end

--- Connect a Signal to a Slot.
---@param slot Slot @The Slot to connect to this Signal
function Signal:connect(slot)
    self.controller.isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    self.controller.typeCheck({slot}, {"Slot"}) -- should raise an error if any param is of the wrong type
    if self.controller.shiftButton == self.button then
        self.controller:xcCntlLog("Ignoring call to connect a Slot to an assigned shift button!", 2)
        return
    end
    if self.slot ~= nil then
        self.controller:xcCntlLog(string.format(
            "%s Signal of input %s already has a connected Slot.  Did you mean to override it?", self.id, self.button.id),
            2)
    end
    self.slot = slot
    self.controller:xcCntlLog(self.button.id .. self.id .. " connected to Slot " .. self.slot.id, 4)
end

--- Emit the Signal.
function Signal:emit()
    if self.id == "Analog" then
        self.slot.func(self.button.value)
    else
        self.controller:xcCntlLog("Signal " .. self.button.id .. self.id .. " emitted.", 3)
        self.slot.func()
    end
end

--- An object that wraps the callback function for a controller input.
---@class Slot
---@field new function
---@field id string
---@field controller Controller
---@field func function
Slot = {}
Slot.__index = Slot
Slot.__type = "Slot"
Slot.__tostring = function(self)
    return string.format("Slot: %s", self.id)
end

--- Initialize a new Slot instance.
---@param controller Controller @A Controller instance
---@param id string @A unique identifier for the Slot
---@param func function @The function to execute when the connected Signal is emitted
---@return Slot @The new Slot instance
function Slot.new(controller, id, func)
    local self = setmetatable({}, Slot)
    self.id = id
    self.controller = controller
    self.func = func
    table.insert(self.controller.slots, self)
    if #self.controller.slots > 1 then
        table.sort(self.controller.slots, slotSort)
    end
    return self
end

--- Sorting function for Controller object's slots array
---@param slot1 Slot @a `Slot` object
---@param slot2 Slot @a `Slot` object
---@return boolean true if slot1 should come before slot2, false otherwise
function slotSort(slot1, slot2)
    return slot1.id < slot2.id
end