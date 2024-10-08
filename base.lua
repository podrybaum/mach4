--[[
    The object model heirarchy.
    Every object has a "parent" and an "id".   The Controller object, which is the top of the heirarchy, is its own parent.
    Every object with children in the heirarchy stores those children in fields such that object[child.id] = child.  It may also
    refer to them through other fields, but these associative fields are always added so that we can traverse the heirarchy from
    any descendant all the way to the root object. (xc in this case, the Controller)

    Besides the base fields and methods, we also want to inherit types, so that __type ends up containing all types

    So we need a traversal method that traverses heirarchical parents and a traversal method that traverses derived types.  We keep
    derived types in reverse order of inheritance so __index can search from the object, to derived types, and finally to Object, from 
    which everything derives
]]--

--- Base class for all objects
---@class Object
---@field id string
---@field parent Object
Object = {}
Object.__index = Object
Object.__type = "Object"
Object.__types = {Object.__type}
Object.__inheritsFrom = {Object}
Object.__tostring = function(self) return self.__type..": "..self.id end

function Object.new(id, parent)
    local self = setmetatable({}, Object)
    self.id = id
    self.parent = parent or self
    self.FQN = self:getFQN()
    if self.parent ~= self then
        if not self.parent[self.id] then
            self.parent[self.id] = self
        end
    end
end

function Object:getFQN()
    -- build our lookup string
    -- example:  xc.Up.Down.slot ends up being an alies for xc.Up.Down.xcJogUp if the slot assigned has the id "xcJogUp"
    local lookup = string.format(".%s", self.id)
    local parent = self.parent
    while parent.parent ~= parent do
        lookup = string.format(".%s%s", parent.id, lookup)
        parent = parent.parent
    end
    -- by here we've reached the Controller object
    return "xc"..lookup
end

function Object:type()
    return self.__type
end