function class(name, super)
    local cls = {}
    cls.__super = super or Type
    setmetatable(cls, cls.__super)
    cls.__index = cls
    cls.__type = name
    cls.__name = name
    mt = getmetatable(cls)

    mt.__tostring = function(object)
        if rawget(object, "id") then
            return object.id
        end
        if rawget(object, "__super") ~= nil then
            if rawget(object, "__super") == Type then
                return string.format("Class: %s - Inherits from Type", rawget(object, "__name"))
            else
                return string.format("Class: %s - Inherits from %s", rawget(object, "__name"), rawget(object, "__super"))
            end
        else
            return string.format("Class: %s", rawget(object, "__name"))
        end
    end
    mt.__call = function(class, id, ...)
        local callArgs = {...}
        print(class, id, callArgs[1])
        
        local inst

        if class.__super.__name ~= "Type" then
            inst = setmetatable(class.__super.new(Instance:new(id, callArgs[1])), class)
            print(inst.id)
        else
            inst = setmetatable(Instance:new(id, callArgs[1]), class)
            print(inst.id)
        end
        return class.new(inst)
    end

    return cls
end

---@class Type
---@field __index Type
---@field __type string
---@field __name string
---@field __tostring function
---@field __call function
Type = {}
setmetatable(Type, {__index=nil})
Type.__index = Type
Type.__type = "Class"
Type.__name = "Type"


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
function Instance:new(id, parent)
    self = {}
    self.parent = parent or self
    self.id = id
    self.configValues = {}
    self.children = {}
    self.addChild = Instance.addChild
    self.serialize = Instance.serialize
    self.deserialize = Instance.deserialize
    self.getRoot = Instance.getRoot
    return self
end

-- Retrieve full path of an object in the hierarchy.
function Instance.getPath(self)
    if self.parent == self then
        return self.id
    else
        return string.format("%s.%s", self.parent:getPath(), self.id)
    end
end

-- Add a child and store it by both index and ID.
Instance.addChild = function(self, child)
    table.insert(self.children, child)
    self[child.id] = child
end

-- Serialize the object's attributes and all its children.
function Instance.serialize(self)
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
function Instance.deserialize(self, path, val)
    if path == "profileName" then
        return
    end
    path = path:lstrip(self.id):lstrip("%.") -- we do it this way to ensure we don't overstrip the path
    local child = path:match("^(.+)[%.%s=]")
    if child == "configValues" then
        path = path:lstrip("configValues"):lstrip("%.")
        self.configValues[path] = val
        return
    else    
        for _, myChild in ipairs(self.children) do
            if myChild.id == child then
                return myChild:deserialize(path, val)
            end
        end
    end
end

-- Get the root object of the hierarchy.
function Instance.getRoot(self)
    if self.parent == self then
        return self
    else
        return self.parent:getRoot()
    end
end


return { Type = Type, class = class, Instance = Instance }
