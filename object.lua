---@class Object
---@field parent Object
---@field id string 
---@field children table
---@field configValues table
Object = {}
Object.__type = "Object"
Object.__tostring = function(self) return self.id end

Object.__index = function(object, key)
    return rawget(object.configValues, key) or rawget(object, key)
end

Object.__newindex = function(object, key, value)
    if rawget(object.configValues, key) then
        object.configValues[key] = value
    else
        rawset(object, key, value)
    end
end

-- Constructor
function Object:new(parent, id)
    local obj = setmetatable({}, self)
    obj.parent = parent
    obj.id = id
    obj.children = {}
    obj.configValues = {}
    return obj
end

-- Retrieve full path of an object in the hierarchy.
function Object:getPath()
    if self.parent == self then
        return self.id
    else
        return string.format("%s.%s", self.parent:getPath(), self.id)
    end
end

-- Add a child and store it by both index and ID.
function Object:addChild(child)
    table.insert(self.children, child)
    self[child.id] = child
end

-- Serialize the object's attributes and all its children.
function Object:serialize()
    local serial = ""
    for key, value in pairs(self.configValues) do
        if value ~= nil then
            self:getRoot().profile.profileData[self:getPath().."."..key] = value
        end
    end
    for _, child in ipairs(self.children) do
        serial = serial .. child:serialize()
    end
    return serial
end

-- Helper to strip a prefix from a string.
function string.lstrip(str, prefix)
    return str:sub(#prefix + 2)
end

-- Deserialize the given path-value string into the correct object.
function Object:deserialize(path, val)
    path = path:lstrip(self.id)
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
function Object:getRoot()
    if self.parent == self then
        return self
    else
        return self.parent:getRoot()
    end
end

return { Object = Object }