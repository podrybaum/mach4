--- An object representing a signal emitted by a getRoot() input.
---@class Signal
---@field id string
---@field parent Button|Trigger
---@field children table
---@field slot Slot
Signal = setmetatable({}, Object)
Signal.__index = Signal
Signal.__newindex = function(t, k, v)
    local func
    if k == "slot" then
        func = Slot.getSlotFunctionById(v)
    end
    rawset(t, k, Slot:new(t, v, func))
end
Signal.__type = "Signal"

--- Initialize a new Signal instance.
---@param parent Button|Trigger @An input object
---@param id string @A unique (per input) identifier for the Signal
---@return Signal @The new Signal instance
function Signal:new(parent, id)
    self = Object.new(self, parent, id)
    return self
end

--- Connect a Signal to a Slot.
---@param slot Slot @The Slot to connect to this Signal
function Signal:connect(slot)
    if self.getRoot().shiftButton == self.parent then
        --self.getRoot():xcCntlLog("Ignoring call to connect a Slot on an assigned shift button!", 2)
        return
    end
   --[[ if self.slot ~= nil then
       self.getRoot():xcCntlLog(string.format(
           "%s Signal of input %s already has a connected Slot.  Did you mean to override it?", self.id, self.parent.id),
            2)
    end]]
    self.slot = self:addChild(slot)
   -- self.getRoot():xcCntlLog(self.parent.id .. self.id .. " connected to Slot " .. self.slot.id, 4)
end

--- Emit the Signal.
function Signal:emit()
    if not self.slot then return end
    if self.id == "Analog" then
        self.slot.func(self.parent.value)
    else
      --  self.getRoot():xcCntlLog("Signal " .. self.parent.id .. self.id .. " emitted.", 3)
        self.slot.func()
    end
end


local slots = require("slot_functions")

--- An object that wraps the callback function for a getRoot() input.
---@class Slot
---@field id string
---@field parent Signal
---@field func function
Slot = setmetatable({}, Object)
Slot.__index = Slot
Slot.__type = "Slot"

--- Initialize a new Slot instance.
---@param parent Signal @A Signal instance
---@param id string @A unique identifier for the Slot
---@param func function @The function to execute when the connected Signal is emitted
---@return Slot @The new Slot instance
function Slot:new(parent, id, func)
    self = Object.new(self, parent, id)
    self.func = func
    -- TODO: Slot functions module
    return self
end

function Slot.getSlotFunctionById(id)
    for slotId, slot in pairs(slots) do
        if id == slotId then
            return slot
        end
    end
end

--- Sorting function for GUI list of Slots
---@param slot1 Slot @a `Slot` object
---@param slot2 Slot @a `Slot` object
---@return boolean true if slot1 should come before slot2, false otherwise
function slotSort(slot1, slot2)
    return slot1.id < slot2.id
end