--- An object that manages access to a specific attribute of another object.
---@class Descriptor
---@field controller Controller
---@field attribute string
---@field object any
---@field datatype string
---@field default any
Descriptor = {}
Descriptor.__index = Descriptor
Descriptor.__type = "Descriptor"

--- Initialize a new Descriptor instance.
---@param controller Controller @A Controller instance
---@param object any @The object to attach the Descriptor to
---@param attribute string @The attribute the Descriptor will shadow
---@param datatype string @The type of the object or value stored by the attribute
---@return Descriptor @The new Descriptor instance
function Descriptor.new(controller, object, attribute, datatype)
    local self = setmetatable({}, Descriptor)
    self.controller = controller
    self.attribute = attribute
    self.object = object
    self.datatype = datatype
    local section = string.format("ControllerProfile %s", self.controller.profileName)
    if self.datatype == "number" then
        self.controller:xcProfileWriteDouble(section, self:lookup(), object.key)
    else
        self.controller:xcProfileWriteString(section, self:lookup(), object.key)
    end
    self:assign()
    return self
end

--- Assemble the section and key lookup strings for this Descriptor.
---@return string @A string ontaining the lookup key for this Descriptor.
function Descriptor:lookup()
    local otype = self.object.__type
    local lookup
    if otype == "Controller" then
        lookup = string.format("xc.%s", self.attribute)
    end
    if otype == "Button" or otype == "Trigger" then
        lookup = string.format("xc.%s.%s.slot", self.object.id, self.attribute)
    end
    if otype == "ThumbstickAxis" then
        lookup = string.format("xc.%s.%s", self.object.id, self.attribute)
    end
    return lookup
end


--- Returns the value assigned to the attribute shadowed by the Descriptor.
function Descriptor:get()
    local section = string.format("ControllerProfile %s", self.controller.profileName)
    if self.datatype == "number" then
        local val = self.controller:xcProfileGetDouble(section, self:lookup(), self.default)
        return tonumber(val)
    else
        local val = self.controller:xcProfileGetString(section, self:lookup(), self.default)
        if self.datatype == "string" then
            return val
        elseif self.datatype == "boolean" then
            return val == "true"
        elseif self.datatype == "object" then
            for _, input in self.controller.inputs do
                if input.id == val then
                    return input
                end
            end
            if self.attribute == "slot" then
                return self.controller:xcGetSlotById(val)
            end
        end
    end
end

--- Set the value assigned to the attribute shadowed by the Descriptor.
---@param value any @The value to assign
function Descriptor:set(value)
    local section = string.format("ControllerProfile %s", self.controller.profileName)
    self.controller.isCorrectSelf(self)
    if self.datatype == "number" then
---@diagnostic disable-next-line: param-type-mismatch
        self.controller:xcProfileWriteDouble(section, self:lookup(), tonumber(value))
        return
    else
        self.controller:xcProfileWriteString(section, self:lookup(), tostring(value))
        return
    end
end

--- Assign the Descriptor to shadow an attribute on a given object.
---___It is important to make sure that no value is ever actually
---assigned to the attribute shadowed by a Descriptor!___
function Descriptor:assign()
    table.insert(self.object.descriptors,self)
    self.object[self.attribute] = nil
    local oldIndex = self.object.__index
    local oldNewIndex = self.object.__newindex
    self.object.__index = function(object, key)
        if rawget(object, "__accessing") then
            return nil
        end
        rawset(object, "__accessing", true)
        for _, descriptor in ipairs(object.descriptors) do
            if descriptor["attribute"] == key then
                rawset(object, "__accessing", false)
                return descriptor:get()
            end
        end
        if type(oldIndex) == "function" then
            return (oldIndex(object, key))
        elseif type(oldIndex) == "table" then
            return oldIndex[key]
        else
            return nil
        end
    end
    self.object.__newindex = function(object, key, value)
        for _, descriptor in ipairs(object.descriptors) do
            if descriptor.attribute == key then
                descriptor:set(value)
                return
            end
        end
        if type(oldNewIndex) == "function" then
            return (oldNewIndex(object, key, value))
        elseif type(oldNewIndex) == "table" then
            oldNewIndex[key] = value
        end
    end
end
