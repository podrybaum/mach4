Profile = {}
Profile.__index = Profile
Profile.__type = "Profile"
Profile.__tostring = function(self)
    return string.format("Profile: %s", self.name)
end

function Profile.new(controller, name, id)
    local self = setmetatable({}, Profile)
    self.controller = controller
    self.id = id
    self.name = name
    -- Replace the global descriptorStorage table
    self.descriptors = setmetatable({}, { __mode = "k" })
    return self
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

--[[ {"xc.profileId=0","xc.profileName=default",
    "xc.LTH_Y_Val.deadzone=10.000000", "xc.RTH_X_Val.deadzone=10.000000",                           
    "xc.RTH_Y_Val.deadzone=10.000000", "xc.LTH_X_Val.deadzone=10.000000",
    "xc.jogIncrement=0.1", "xc.logLevel=2", "xc.xYReversed=false",
    "xc.frequency=4", "xc.simpleJogMapped=true", 
    "xc.shiftButton=LTR_Val", "xc.RTH_Y_Val.axis=2.000000", "xc.RTH_Y_Val.inverted=false",
    "xc.DPad_UP.Down.slot=Jog X+", "xc.DPad_UP.Up.slot=Jog X Off",
    "xc.DPad_DOWN.Down.slot=Jog X-", "xc.DPad_DOWN.Up.slot=Jog X Off",
    "xc.DPad_RIGHT.Down.slot=Jog Y+", "xc.DPad_RIGHT.Up.slot=Jog Y Off",
    "xc.DPad_LEFT.Down.slot=Jog Y-", "xc.DPad_LEFT.Up.slot=Jog Y Off",
    "xc.DPad_UP.AltDown.slot=xcJogIncUp", "xc.DPad_DOWN.AltDown.slot=xcJogIncDown",
    "xc.DPad_RIGHT.AltDown.slot=xcJogIncRight", "xc.DPad_LEFT.AltDown.slot=xcJogIncLeft",
    "xc.Btn_B.Down.slot=E Stop Toggle", "xc.Btn_RS.Down.slot=Enable Toggle",
    "xc.Btn_X.Down.slot=XC Run Cycle Toggle", "xc.Btn_BACK.AltDown.slot=Home All"} ]]