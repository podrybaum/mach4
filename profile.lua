Profile = {}
Profile.__index = Profile
Profile.__type = "Profile"
Profile.__tostring = function(self)
    local output = string.format("Profile: %s\n", self.name)
    if self.profileString ~= '' then
        output = output .. self.profileString
    end
    return output
end

function Profile.new(id, name)
    local self = setmetatable({}, Profile)
    self.id = id
    self.name = name
    self.profileString = ''
    return self
end

function Profile:createFromActive(controller)
    profile = string.format("xc.profileId = %s", self.id)
    return controller.serialize()
end
    

--- Load profile data from the machine.ini file.
---@param id number the id number of the profile (0 for default)
function Profile:read(id)
    local section = string.format("ControllerProfile-%s", id)
    self.id = id
    if mc.mcProfileExists(inst, section, "xc.profileName") == mc.MC_TRUE then
        local numAttribs = {"jogIncrement", "logLevel", "frequency"}
        local stringAttribs = {"shiftButton", "xYReversed", "simpleJogMapped", "profileName"}
        for _, attrib in ipairs(numAttribs) do
            if mc.mcProfileExists(inst, section, string.format("xc.%s", attrib)) == mc.MC_TRUE then
                local val = self.controller:xcProfileGetDouble(section, string.format("xc.%s", attrib))
                if type(val) == "number" then
                    self.controller[attrib] = val
                    self.controller:newDescriptor(self.controller, attrib, "number")
                    self.controller:xcCntlLog(string.format("returning a descriptor for %s.%s = %s", self.controller.id, attrib, val), 4)
                end
            end
        end
        for _, attrib in ipairs(stringAttribs) do
            if mc.mcProfileExists(inst, section, string.format("xc.%s", attrib)) == mc.MC_TRUE then
                local val = self:xcProfileGetString(section, string.format("xc.%s", attrib))
                if type(val) == "string" then
                    if attrib == "shiftButton" then
                        self.controller.shiftButton = self.controller:xcGetInputById(val)
                        self.controller:newDescriptor( self.controller, "shiftButton", "object")
                        self.controller:xcCntlLog(string.format("returning a descriptor for Controller.shiftButton = %s", val), 4)
                    elseif attrib == "xYReversed" then
                        self.controller.xYReversed = val == true
                        self.controller:newDescriptor( self.controller, "xYReversed", "boolean")
                        self.controller:xcCntlLog(string.format("returning a descriptor for Controller.xYReversed = %s", val), 4)
                    elseif attrib == "simpleJogMapped" then
                        self.controller.simpleJogMapped = val == true
                        self.controller:newDescriptor( self.controller, "simpleJogMapped", "boolean")
                        self.controller:xcCntlLog(string.format("returning a descriptor for Controller.simpleJogMapped = %s", val), 4)
                        if  self.controller.simpleJogMapped then
                            self.controller:mapSimpleJog()
                        end
                    else
                        self.controller[attrib] = val
                        self.controller:newDescriptor( self.controller, attrib, "string")
                        self.controller:xcCntlLog(string.format("returning a descriptor for %s = %s", attrib, val), 4)
                    end
                end
            end
        end
        for _, input in ipairs( self.controller.inputs) do
            for i, signal in ipairs(input.signals) do
                local lookup = string.format("xc.%s.%s.slot", input.id, signal.id)
                if mc.mcProfileExists(inst, section, lookup) == mc.MC_TRUE then
                    local val = string.strip( self.controller:xcProfileGetString(section, lookup))
                    if type(val) == "string" then
                        input[signal.id].slot =  self.controller:xcGetSlotById(val)
                        self.controller:newDescriptor(signal, "slot", "object")
                        self.controller:xcCntlLog(
                            string.format("returning a descriptor for %s.%s = %s", input.id, input.signals[i], val), 4)
                    end
                end
            end
        end
        for _, axis in ipairs( self.controller.axes) do
            if mc.mcProfileExists(inst, section, string.format("xc.%s.axis", axis)) == mc.MC_TRUE then
                -- deadzone, axis, inverted
                local val =  self.controller:xcProfileGetDouble(section, string.format("xc.%s.axis", axis))
                if type(val) == "number" then
                    self.controller[axis.id][axis] = val
                    self.controller:newDescriptor(axis, "axis", "number")
                    self.controller:xcCntlLog(string.format("returning a descriptor for xc.%s.axis = %s", axis.id, val), 4)
                end
                local val =  self.controller:xcProfileGetDouble(section, string.format("xc.%s.deadzone = %s", axis.id, val), 4)
                if type(val) == "number" then
                    self.controller[axis.id]["deadzone"] = val
                    self.controller:newDescriptor(axis, "deadzone", "number")
                    self.controller:xcCntlLog(string.format("returning a descriptor for %s.deadzone = %s", axis.id, val), 4)
                end
                local val =  self.controller:xcProfileGetString(section, string.format("xc.%s.inverted", axis))
                if type(val) == "string" then
                    self.controller[axis.id]["inverted"] = val == true
                    self.controller:newDescriptor(axis, "inverted", "boolean")
                    self.controller:xcCntlLog(string.format("returning a descriptor for xc.%s.inverted = %s", axis.id, val), 4)
                end
            end
        end
        self.controller:xcProfileWriteDouble("XBC4MACH4", "profileId", self.profileId)
    else
        self.controller:xcCntlLog(string.format("No profile found for name: %s", id), 1)
    end
end
