Object = {}
Object.__type = "Object"
Object.__tostring = function(self) return self.id end

Object.__index = function(object, key)
    if object.configValues and object.configValues[key] then
        return object.configValues[key]
    else
        return rawget(object, key)
    end
end

Object.__newindex = function(object, key, value)
    if object.configValues and object.configValues[key] then
        object.configValues[key] = value
    else
        rawset(object, key, value)
    end
end

function Object:new(parent, id)
    self = setmetatable({}, self)
    self.parent = parent
    self.id = id
    self.children = {}
    self.configValues = {}
    return self
end

function Object:getPath()
    if self.parent == self then
        return self.id
    else
        return string.format("%s.%s", self.parent:getPath(), self.id)
    end
end

function Object:addChild(child)
    table.insert(self.children, child)
    self[child.id] = child
end

function Object:serialize()
    local serial = ''
    for attrib, value in ipairs(self.configValues) do
        if value ~= nil then
            serial = serial + string.format("%s = %s\n", self:getPath() .. "." .. attrib, tostring(value))
        end
    end
    for _, child in ipairs(self.children) do
        serial = serial + child:serialize()
    end
    return serial
end

function Object:getRoot()
    if self.parent == self then
        return self
    else
        return self.parent:getRoot()
    end
end

return Object