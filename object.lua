require("stringsExtended")

---@class Object
---@field parent Object
---@field id string
---@field children table
---@field configValues table
Object = {}
setmetatable(Object, Object)
Object.__type = "Object"
Object.__tostring = function(object) if object.id then return object.id else return "Object" end end

Object.__index = function(object, key)
    if rawget(object, "configValues") then
        local configTable = rawget(object, "configValues")        
        if rawget(configTable, key) then
            return rawget(configTable, key)
        end
    else
        return rawget(Object, key)
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
            self:getRoot().profile.profileData[self:getPath() .. "." .. key] = value
        end
    end
    for _, child in ipairs(self.children) do
        serial = serial .. child:serialize()
    end
    return serial
end

-- Deserialize the given path-value string into the correct object.
function Object:deserialize(path, val)
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
function Object:getRoot()
    if self.parent == self then
        return self
    else
        return self.parent:getRoot()
    end
end

-- Constructor
function Object:new(parent, id)
    local obj = setmetatable({}, self)
    obj.parent = parent
    obj.id = id
    obj.children = {}
    obj.configValues = setmetatable({}, nil)
    return obj
end

return { Object = Object }
