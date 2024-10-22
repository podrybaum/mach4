require("stringsExtended")

local function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        a[#a+1] = n
    end
    table.sort(a, f)
    local i = 0
    local n = #a
    local iter = function()
        i = i + 1
        if i > n then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end


local function sortConfig(a, b)
    if a == b then
        return false
    end
    if a == "Down" then
        return true
    elseif a == "altDown" then
        return (b == "Up" or b == "altUp")
    elseif a == "Up" then
        return not (b == "Down" or b == "altDown")
    elseif a == "altUp" then
        return false
    end
    return a < b
end

--- Create a new class
---@param name string @The name of the new class
---@param super table @Class to inherit from, defaults to Type
---@return table @The new class, which is an instance of Type
function class(name, super)
    local cls = {}

    cls.__super = super or Type
    setmetatable(cls, cls.__super)
    cls.__index = cls
    cls.__type = name
    cls.__name = name
    mt = getmetatable(cls)

    cls.__tostring = function(object)
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
        if class.id ~= nil then
            error("Attempt to call an instance object.")
        end
        local callArgs = { ... }
        local inst
        if class.__super.__name ~= "Type" then
            inst = setmetatable(class.__super.new(Instance:new(id, callArgs[1])), class)
        else
            inst = setmetatable(Instance:new(id, callArgs[1]), class)
        end
        table.remove(callArgs, 1)
        if #callArgs > 0 then
            return class.new(inst, table.unpack(callArgs))
        else
            return class.new(inst)
        end
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
setmetatable(Type, { __index = nil })
Type.__index = Type
Type.__type = "Class"
Type.__name = "Type"


function Type:isInstance(class)
    local mt = getmetatable(self)
    if rawget(self, "id") then
        while true do
            if mt.__type == class.__name then
                return true
            end
            mt = rawget(mt, "__super") 
            if mt == Type then
                return false         
            end
        end
    else
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
    self.getPath = Instance.getPath
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
    for key, value in pairsByKeys(self.configValues, sortConfig) do
        if value ~= "" then
            serial = serial .. self:getPath() .. ".configValues." .. key .. "=" .. value .. "\n"
        end
    end
    for _, child in ipairs(self.children) do
        for k, v in pairs(child:serialize()) do
            serial = serial .. k .. "=" .. v .. "\n"
        end
    end
    local parsed = {}
    for line in serial:gmatch("[^\n]+") do
        local key, value = line:match("^(.-)%s*=%s*(.-)%s*$")
        if key and value then
            parsed[key] = value
        end
    end
    return parsed
end


-- Deserialize the given path-value string into the correct object.
function Instance.deserialize(self, path, val)
    if path == "profileName" then
        return
    end
    path = path:lstrip(self.id):lstrip("%.") -- we do it this way to ensure we don't overstrip the path
    local child = path:match("^(.-)[%.%s%=]")
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

-- DEV_ONLY_START
return { Type = Type, class = class, Instance = Instance, pairsByKeys = pairsByKeys, sortConfig = sortConfig }
-- DEV_ONLY_END



