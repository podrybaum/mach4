---@class Descriptor
---@field new function
---@field controller Controller
---@field attribute string
---@field object any 
---@field datatype string 
---@field default number|string|boolean
---@field get function
---@field set function 
---@field assign function 
Descriptor = {}
Descriptor.__index = Descriptor
Descriptor.__type = "Descriptor"

function Descriptor.new(controller, object, key, datatype, default)
	local self = setmetatable({}, Descriptor)
	self.controller = controller
	self.attribute = key
	self.object = object
    self.datatype = datatype
    self.default = default
    object.key = nil
	return self
end

function Descriptor:get()
	if self.datatype == "number" then
---@diagnostic disable-next-line: param-type-mismatch
        local val = self.controller:xcProfileGetDouble(self.object.id, self.attribute, self.default)
        return tonumber(val)
    else
---@diagnostic disable-next-line: param-type-mismatch
        local val = self.controller:xcProfileGetString(self.object.id, self.attribute, self.default)
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

function Descriptor:set(value)
	isCorrectSelf(self)
    if self.datatype == "number" then
	    Controller.typeCheck({value},{"number"})
        self.controller:xcProfileWriteDouble(self.object.id, self.attribute, value)
        return
	else
		value = tostring(value)
		self.controller:xcProfileWriteString(self.object.id, self.attribute, value)
		return
    end
end

--- Assign the Descriptor to shadow an attribute on a given object.  ___It is important to make sure that no value is ever actually 
--- assigned to the attribute shadowed by a Descriptor!___
function Descriptor:assign()
	if self.object.descriptors == nil then
        self.object.descriptors = {self}
		local mt = getmetatable(self.object)
        local oindex = mt.__index
        local onewindex = mt.__newindex
		print(self.object, self.attribute)
		mt.__index = function(object, key)
            for _, descriptor in ipairs(object.descriptors) do
                if descriptor["attribute"] == key then
                    return descriptor:get()
                end
            end
            if type(oindex) == "function" then
                return(oindex(object, key))
            elseif type(oindex) == "table" then
                return oindex[key]
            else
                return nil
            end
        end
		mt.__newindex = function(object, key, value)
            for _, descriptor in ipairs(object.descriptors) do
                if descriptor.attribute == key then
                    descriptor:set(value)
                    return
                end
            end
            if type(onewindex) == "function" then
                return(onewindex(object, key, value))
            elseif type(onewindex) == "table" then
                setIfNotEqual(object[key], value)
            end
        end
		
	else
		table.insert(self.object.descriptors, self)
	end
    if self.default ~= nil then
        self:set(self.default)
    end
end