descriptorsStorage = setmetatable({}, { __mode = "k" })

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
        if self.object[self.attribute] ~= nil then
            print(section, self:lookup(), self.object[self.attribute])
            self.controller:xcProfileWriteDouble(section, self:lookup(), tonumber(self.object[self.attribute]))
			mc.mcProfileFlush(inst)
        end
    else
        if self.object[self.attribute] ~= nil then
            print(section, self:lookup(), self.object[self.attribute])
            if self.object.__type == "Signal" then
                self.controller:xcProfileWriteString(section, self:lookup(), self.object[self.attribute].id)
            else
                self.controller:xcProfileWriteString(section, self:lookup(), tostring(self.object[self.attribute]))
            end
			mc.mcProfileFlush(inst)
        end
    end
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
    if otype == "Signal" then
        lookup = string.format("xc.%s.%s.slot", self.object.button.id, self.object.id)
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
        local val = self.controller:xcProfileGetDouble(section, self:lookup())
        print(string.format("returning %s",val))
        return tonumber(val)
    else
        local val = self.controller:xcProfileGetString(section, self:lookup())
        if self.datatype == "boolean" then
            val = val == "true"
        end
        if self.datatype == "object" then
            for _, input in ipairs(self.controller.inputs) do
                if input.id == val then
                    val = input
                end
            end
        end
        if self.attribute == "slot" then
			val = string.sub(tostring(val), 7, -1)
            val = self.controller:xcGetSlotById(tostring(val))
			
        end
        print(string.format("returning %s",val))
        return val
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
    -- Store descriptors globally
    descriptorsStorage[self.object] = descriptorsStorage[self.object] or {}
    table.insert(descriptorsStorage[self.object], self)

    -- Save the initial value to the profile
    

    -- Prepare the metatable
    local mt = getmetatable(self.object)
    if not mt then
        mt = {}
        setmetatable(self.object, mt)
    end

    -- Save old metamethods
    local oldIndex = mt.__index
    local oldNewIndex = mt.__newindex

    -- Define the __index metamethod
    mt.__index = function(object, key)
        if key == nil then
            print("Warning: __index called with nil key")
            print(debug.traceback())
            return nil
        end

        local descriptors = descriptorsStorage[object]
        if descriptors then
            for _, descriptor in ipairs(descriptors) do
                if descriptor.attribute == key then
                    return descriptor:get()
                end
            end
        end

        if type(oldIndex) == "function" then
            return oldIndex(object, key)
        elseif type(oldIndex) == "table" then
            return oldIndex[key]
        else
            return rawget(object, key)
        end
    end

    -- Define the __newindex metamethod
    mt.__newindex = function(object, key, value)
        if key == nil then
            print("Warning: __newindex called with nil key")
            print(debug.traceback())
            return
        end

        local descriptors = descriptorsStorage[object]
        if descriptors then
            for _, descriptor in ipairs(descriptors) do
                if descriptor.attribute == key then
                    descriptor:set(value)
                    return
                end
            end
        end

        if type(oldNewIndex) == "function" then
            oldNewIndex(object, key, value)
        else
            rawset(object, key, value)
        end
    end
end
