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

Object.__newindex = function(object, key, value)
    local configTable = rawget(object, "configValues")
    if configTable == nil or rawget(configTable, key) == nil then
        rawset(object, key, value)
    elseif rawget(configTable, key) then
        rawset(configTable, key,value)
    else
        rawset(object, key, value)
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
    local child = path:match("(^%S+)[%.%s=]")
    if child == "configValues" then
        path = path:lstrip("configValues"):lstrip("%.")
        local attrib, value = path:match("(^%S+)[%s=]+(%S+)$")
        self.configValues[attrib] = value
        return
    else    
        return self[child]:deserialize(path, val)
    end
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
