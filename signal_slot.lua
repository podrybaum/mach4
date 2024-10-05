
Signal = {}
Signal.__index = Signal
Signal.__type = "Signal"
Signal.__tostring = function(self)
    return string.format("Signal: %s", self.id)
end

function Signal.new(controller, button, id)
    local self = setmetatable({}, Signal)
    self.id = id
    self.button = button
    self.controller = controller
    self.controller:newDescriptor(self, "slot", "object", nil)
    -- self.slot = nil
    return self
end

function Signal:connect(slot)
    self.controller.isCorrectSelf(self) -- should raise an error if method has been called with dot notation
    self.controller.typeCheck({slot}, {"Slot"}) -- should raise an error if any param is of the wrong type
    if self.controller.shift_btn == self.button then
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

function Signal:emit()
    if self.id ~= "analog" then
        -- not logging analog Signal emissions because they will happen every update while active
        self.slot.func(self.button.value)
    else
        self.controller:xcCntlLog("Signal " .. self.button.id .. self.id .. " emitted.", 3)
        self.func()
    end
end



Slot = {}
Slot.__index = Slot
Slot.__type = "Slot"
Slot.__tostring = function(self)
    return string.format("Slot: %s", self.id)
end

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

---Sorting function for Controller object's slots array
---@param slot1 Slot @a `Slot` object
---@param slot2 Slot @a `Slot` object
---@return boolean true if slot1 should come before slot2, false otherwise
function slotSort(slot1, slot2)
    return slot1.id < slot2.id
end