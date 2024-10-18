function class(name, ...)
    local cls = {}
    local args = { ... }
    if args[1] then
        setmetatable(cls, args[1])
        cls.__super = args[1]
    else
        setmetatable(cls, cls)
    end
    cls.__index = cls
    cls.__type = name
    cls.__tostring = function(inst)
        return inst.id
    end
    cls.__name = name

    return cls
end

---@class Type
---@field __index Type
---@field __type string
---@field __tostring function
Type = {}
setmetatable(Type, Type)
Type.__index = Type
Type.__type = "Class"
Type.__name = "Type"
Type.__tostring = function(object)
    if rawget(object, "id") then
        return object.id
    end
    if rawget(object, "__super") then
        if rawget(object, "__super") == Type then
            return string.format("Class: %s - Inherits from Type", rawget(object, "__type"))
        else
            return string.format("Class: %s - Inherits from %s", rawget(object, "__type"), rawget(object, "__super"))
        end
    else
        return string.format("Class: %s", rawget(object, "__type"))
    end
end
Type.__call = function(class, parent, id, ...)
    local inst = Instance:new(parent, id)
    return class.new(inst, table.unpack({ ... }))
end
function Type:isInstance(class)
    local mt = getmetatable(self)

    -- If self has an id, it's an instance
    if rawget(self, "id") then
        while true do
            if mt.__type == class.__name and class ~= Type then
                return true
            end
            mt = rawget(mt, "__super") -- Traverse the chain of superclasses
            if mt == Type then
                return false           -- Stop when we hit Type - no instance is an instance of Type
            end
        end
    else
        -- If self is a class, return true if checking against Type only
        return class == Type
    end
end

Instance = {}
-- Initialize a new instance of a class.
function Instance:new(parent, id)
    self = {}
    self.parent = parent
    self.id = id
    self.configValues = {}
    self.children = {}
    return self
end

-- Retrieve full path of an object in the hierarchy.
function Instance:getPath()
    if self.parent == self then
        return self.id
    else
        return string.format("%s.%s", self.parent:getPath(), self.id)
    end
end

-- Add a child and store it by both index and ID.
function Instance:addChild(child)
    table.insert(self.children, child)
    self[child.id] = child
end

-- Serialize the object's attributes and all its children.
function Instance:serialize()
    local serial = ""
    for key, value in pairs(self.configValues) do
        if value ~= nil then
            self:getRoot().profile.profileData[self:getPath() .. "." .. key] = value
        end
    end
    for _, child in ipairs(self.children) do
        serial = serial .. child:serialize()
    end
    return serial
end

require("stringsExtended")
-- Deserialize the given path-value string into the correct object.
function Instance:deserialize(path, val)
    path = path:lstrip(self.id):lstrip("%.") -- we do it this way to ensure we don't overstrip the path
    local child = path:match("^(%S+)[%.$]")
    if #self.configValues > 0 then
        for k, _ in pairs(self.configValues) do
            if k == child then
                self[k] = val
                return
            end
        end
    end
    return self[child]:deserialize(path, val)
end

-- Get the root object of the hierarchy.
function Instance:getRoot()
    if self.parent == self then
        return self
    else
        return self.parent:getRoot()
    end
end

ExampleClass = class("ExampleClass", Type)
function ExampleClass.new(self)
    self = setmetatable(self, ExampleClass)
    return self
end

inst = ExampleClass("None", "ExampleInstance")

print(ExampleClass, inst)
print(inst:isInstance(ExampleClass))
print(inst:isInstance(Type))
print(ExampleClass:isInstance(Type))

return { Type = Type, class = class, Object = Instance }
