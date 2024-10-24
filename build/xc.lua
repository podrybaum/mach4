function string.split(str, ...)
    local args = {...}
    local delim = args[1] or "%s"
    local out = {}
    local i = 1
    while str do
        local part, remainder = string.match(str, string.format("(.-)%s+(.*)", delim))
        if part then
            out[i] = part
            str = remainder
            i = i + 1
        else
            out[i] = str
            break
        end
    end
    return out
end
function string.lstrip(str, ...)
    local args = {...}
    return str:match(string.format("^[%s]+(.+)", args[1] or "%s"))
end
function string.rstrip(str, ...)
    local args = {...}
    return str:match(string.format("^(.-)[%s]+", args[1] or "%s"))
end
function string.strip(str, ...)
    local args = {...}
    return str:lstrip(args[1] or "%s"):rstrip(args[1] or "%s")
end
function string.startswith(str, start)
    return str:sub(1, #start) == start
end
function string.endswith(str, strEnd)
    return str:sub(-#strEnd) == strEnd
end
if mc then
    inst = mc.mcGetInstance()
end
function pairsByKeys(t, f)
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
function sortConfig(a, b)
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
function Instance.getPath(self)
    if self.parent == self then
        return self.id
    else
        return string.format("%s.%s", self.parent:getPath(), self.id)
    end
end
Instance.addChild = function(self, child)
    table.insert(self.children, child)
    self[child.id] = child
end
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
function Instance.getRoot(self)
    if self.parent == self then
        return self
    else
        return self.parent:getRoot()
    end
end
local iniFile
if mc then
    iniFile = "C:\\Mach4Hobby\\Profiles\\" .. mc.mcProfileGetName(inst).. "\\xbcontroller.ini"
end
Profile = {}
Profile.__index = Profile
Profile.__type = "Profile"
Profile.__tostring = function(self)
    local str = "[ControllerProfile-" .. self.id .. "]\n"
    for k, v in pairs(self.profileData) do
        str = str .. string.format("%s=%s\n", k, v)
    end
    return str
end
function Profile.new(id, name, controller)
    local self = setmetatable({}, Profile)
    self.id = id
    self.name = name
    self.controller = controller
    self.iniFile = iniFile
    file = io.open(self.iniFile, "r+")
    if not file then
        self.writeDefault(self.iniFile)
    else
        file:close()
    end
    self.profileData = {}
    self.profileData["profileName"] = self.name
    return self
end
function Profile:getId(name)
    for k, v in pairs(self.getProfiles()) do
        if v == name then
            return k
        end
    end
end
function Profile:exists()
    local file = io.open(self.iniFile, "r+")
    if not file then
        error("ini file is missing or corrupted!")
    else
        for line in file:lines() do
            if line == string.format("[ControllerProfile-%s]", self.id) then
                file:close()
                return true
            end
        end
    end
    file:close()
    return false
end
function Profile:write()
    if self:exists() then
        self:delete()
        self:write()
    else
        local file = io.open(self.iniFile, "r+")
        if not file then
            error("ini file is missing or corrupted!")
        else
            file:seek("end")
            file:write(string.format("\n[ControllerProfile-%s]\nprofileName=%s\n", self.id, self.name))
            for k, v in pairsByKeys(self.profileData, sortConfig) do
                file:write(string.format("%s=%s\n", k, v))
            end
            file:write("\n")
            file:close()
        end
    end
end
function Profile:delete()
    local file = io.open(self.iniFile, "r+")
    if not file then
        error("ini file is missing or corrupted!")
    else
        local iniLines = {}
        local inProfile = false
        for line in file:lines() do
            if not inProfile and not line:startswith(string.format("[ControllerProfile-%s]", self.id)) then
                table.insert(iniLines, line)
            elseif line:startswith(string.format("[ControllerProfile-%s]", self.id)) then
                inProfile = true
            elseif inProfile and line:startswith(" ") or line == "" then
                inProfile = false
            end
        end
        file:close()
        file = io.open(self.iniFile, "w")
        if file then
            for _, line in ipairs(iniLines) do
                file:write(line.."\n")
            end
            file:close()
        end
    end
end
function Profile:load()
    self.controller:xcCntlLog("Loading profile: " .. self.name, 4)
    if self.controller.dirtyConfig then
        self.controller.dirtyConfig = false
    end
    local file = io.open(self.iniFile, "r+")
    local iniLines = {}
    if not file then
        error("ini file is missing or corrupted!")
    else
        local inProfile = false
        for line in file:lines() do
            if line:startswith("lastProfile=") then
                table.insert(iniLines, "lastProfile=" .. self.id)
            else
                table.insert(iniLines, line)
                if not inProfile and line:startswith(string.format("[ControllerProfile-%s]", self.id)) then
                    inProfile = true
                elseif inProfile and not line:match("^%s*$") then
                    local key, value = line:match("^(.-)=(.+)$")
                    if key and value then
                        self.profileData[key] = value
                    end
                end
            end
        end
        file:close()
        file = io.open(self.iniFile, "w")
        if file then
            for _, line in ipairs(iniLines) do
                file:write(line.."\n")
            end
            file:close()
        end
    end
    for k, v in pairs(self.profileData) do
        self.controller:deserialize(k, v)
    end
end
function Profile.getLast(filePath)
    filePath = filePath or iniFile
    local file = io.open(filePath, "r")
    if not file then
        error("ini file is missing or corrupted!")
    else
        for line in file:lines() do
            if line:match("^lastProfile=.*$") then
                file:close()
                return line:match("^lastProfile=(.*)$")
            end
        end
    end
    file:close()
end
function Profile.writeDefault(filePath)
    filePath = filePath or iniFile
    local file = io.open(filePath, "w")
    local defaultProfile = [[[XBC4MACH4]
lastProfile=0
[ControllerProfile-0]
profileName=default
xc.Btn_B.configValues.Down=E Stop Toggle
xc.Btn_BACK.configValues.altDown=Home Z
xc.Btn_RS.configValues.Down=Enable Toggle
xc.Btn_START.configValues.altDown=Home All
xc.Btn_X.configValues.Down=Cycle Start/Stop
xc.DPad_DOWN.configValues.Down=Jog Y-
xc.DPad_DOWN.configValues.Up=Jog Y Off
xc.DPad_DOWN.configValues.altDown=xcJogIncDown
xc.DPad_LEFT.configValues.Down=Jog X-
xc.DPad_LEFT.configValues.Up=Jog X Off
xc.DPad_LEFT.configValues.altDown=xcJogIncLeft
xc.DPad_RIGHT.configValues.Down=Jog X+
xc.DPad_RIGHT.configValues.Up=Jog X Off
xc.DPad_RIGHT.configValues.altDown=xcJogIncRight
xc.DPad_UP.configValues.Down=Jog Y+
xc.DPad_UP.configValues.Up=Jog Y Off
xc.DPad_UP.configValues.altDown=xcJogIncUp
xc.LTH_X_Val.configValues.deadzone=10
xc.LTH_X_Val.configValues.inverted=false
xc.LTH_Y_Val.configValues.deadzone=10
xc.LTH_Y_Val.configValues.inverted=false
xc.RTH_X_Val.configValues.deadzone=10
xc.RTH_X_Val.configValues.inverted=false
xc.RTH_Y_Val.configValues.axis=2
xc.RTH_Y_Val.configValues.deadzone=10
xc.RTH_Y_Val.configValues.inverted=false
xc.configValues.frequency=4
xc.configValues.jogIncrement=0.1
xc.configValues.logLevel=2.0
xc.configValues.shiftButton=Btn_Y
xc.configValues.xYReversed=true]]
    if file then
        file:write(defaultProfile)
        file:close()
    else
        error("Could not write default profile")
    end
end
function Profile:save()
    self.profileData = self.controller:serialize()
    self:write()
    if self.controller.dirtyConfig then
        self.controller.dirtyConfig = false
    end
end
function Profile.getProfiles(filePath)
    filePath = filePath or iniFile
    local file = io.open(filePath, "r")
    local profiles = {}
    local id, name
    if not file then
        error("ini file is missing or corrupted!")
    else
        for line in file:lines() do
            if line:match("^%[ControllerProfile-.*%]$") then
                id = line:match("^%[ControllerProfile%-(%d+)%]$")
            end
            if line:match("^profileName=.*$") then
                name = line:match("^profileName=(.*)$")
                profiles[id] = name
            end
        end
        file:close()
        return profiles
    end
end
local function getMachSignalState(signal)
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcSignalGetState(hsig)
        if rc == mc.MERROR_NOERROR then
            return val > 0
        end
    end
end
local function toggleMachSignalState(signal)
    local hsig, rc = mc.mcSignalGetHandle(inst, signal)
    if rc == mc.MERROR_NOERROR then
        mc.mcSignalSetState(hsig, not mc.mcSignalGetState(inst, hsig))
    end
end
local names = {"Cycle Start", "Cycle Stop", "Feed Hold", "Enable On", "Soft Limits On", "Soft Limits Off",
                "Soft Limits Toggle", "Position Remember", "Position Return", "Limit OV On", "Limit OV Off",
                "Limit OV Toggle", "Jog Mode Toggle", "Jog Mode Step", "Jog Mode Continuous", "Jog X Off",
                "Jog Y Off", "Jog Z Off", "Jog A Off", "Jog B Off", "Jog C Off", "Jog X+", "Jog Y+", "Jog Z+",
                "Jog A+", "Jog B+", "Jog C+", "Jog X-", "Jog Y-", "Jog Z-", "Jog A-", "Jog B-", "Jog C-", "Home All",
                "Home X", "Home Y", "Home Z", "Home A", "Home B", "Home C"}
local slots = {}
for _, name in ipairs(names) do
    slots[name] = function()scr.DoFunctionName(name) end
end
slots["Incremental Jog X+"] = function(inc)
    mc.mcJogIncStart(inst, mc.X_AXIS, inc)
end
slots["Incremental Jog Y+"] = function(inc)
    mc.mcJogIncStart(inst, mc.Y_AXIS, inc)
end     
slots["Incremental Jog Z+"] = function(inc)
    mc.mcJogIncStart(inst, mc.Z_AXIS, inc)
end 
slots["Incremental Jog A+"] = function(inc) 
    mc.mcJogIncStart(inst, mc.A_AXIS, inc)
end
slots["Incremental Jog B+"] = function(inc)
    mc.mcJogIncStart(inst, mc.B_AXIS, inc)
end
slots["Incremental Jog C+"] = function(inc)
    mc.mcJogIncStart(inst, mc.C_AXIS, inc)
end
slots["Incremental Jog X-"] = function(inc)
    mc.mcJogIncStart(inst, mc.X_AXIS, -1 * inc)
end 
slots["Incremental Jog Y-"] = function(inc) 
    mc.mcJogIncStart(inst, mc.Y_AXIS, -1 * inc)
end
slots["Incremental Jog Z-"] = function(inc)
    mc.mcJogIncStart(inst, mc.Z_AXIS, -1 * inc)
end
slots["Incremental Jog A-"] = function(inc)
    mc.mcJogIncStart(inst, mc.A_AXIS, -1 * inc)
end
slots["Incremental Jog B-"] = function(inc)
    mc.mcJogIncStart(inst, mc.B_AXIS, -1 * inc)
end
slots["Incremental Jog C-"] = function(inc)
    mc.mcJogIncStart(inst, mc.C_AXIS, -1 * inc)
end
slots["Enable Off"] = function()
    local state = mc.mcCntlGetState(inst)
    if (state ~= mc.MC_STATE_IDLE) then
        scr.StartTimer(2, 250, 1);
    end
    scr.DoFunctionName("Enable Off")
end
slots["Enable Toggle"] = function()
    if getMachSignalState(mc.OSIG_MACHINE_ENABLED) then
        slots["Enable On"]()
    else
        slots["Enable Off"]()
    end
end
slots["E Stop Toggle"] = toggleMachSignalState(mc.ISIG_EMERGENCY)
slots["Go To Work Zero"] = function()
    mc.mcCntlGotoZero(inst)
end
local success, customSlots = pcall(require, "slot_functions")
if success then
    for k, v in pairs(customSlots) do
        slots[k] = v
    end
end
Button = class("Button", Type)
function Button.new(self)
    self.pressed = false
    self.configValues["Up"] = ""
    self.configValues["Down"] = ""
    self.configValues["altUp"] = ""
    self.configValues["altDown"] = ""
    return self
end
function Button:getState()
    local state = self.parent:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if type(state) ~= "number" then
        self.parent:xcCntlLog(string.format("Invalid state for %s", self.id), 1)
        return
    end
    if (state == 1) and (not self.pressed) then
        self.pressed = true
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                if self.configValues["Down"] ~= "" then
                    slots[self.configValues["Down"]]()
                end
            else
                if self.configValues["altDown"] ~= "" then
                    slots[self.configValues["altDown"]]()
                end
            end
        end
    elseif (state == 0) and self.pressed then
        self.pressed = false
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                slots[self.configValues["Up"]]()
            else
                slots[self.configValues["altUp"]]()
            end
        end
    end
end
function Button:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()
    if not (self.id == self.parent.configValues.shiftButton) then
        local options = {""}
        local analogOptions = {""}
        for name, _ in pairsByKeys(slots) do
            options[#options + 1] = name
        end
        local idMapping = {}
        for state, _ in pairsByKeys(self.configValues, sortConfig) do
            local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, string.format("%s Action:", state))
            propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
            local choices
            if self:isInstance(Trigger) then
                choices = analogOptions
            else
                choices = options
            end
            local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,choices)
            idMapping[state] = choice
            if self.configValues[state] ~= "" then
                choice:SetSelection(choice:FindString(self.configValues[state]))
            end
            propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
            propertiesPanel:Connect(choice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
                self:getRoot().dirtyConfig = true
                self.configValues[state] = choice:GetString(choice:GetSelection())
                self:getRoot():statusMessage(string.format("%s set to: %s", state, self.configValues[state]))
            end)
        end
       
        propertiesPanel:Layout()
        propertiesPanel:Refresh()
        return propSizer
    else
        local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "This input is currently assigned as the shift button.")
        propSizer:Add(0,0)
        propSizer:Add(label, 0, wx.wxALIGN_LEFT + wx.wxALL, 5)
        return propSizer
    end
end
Trigger = class("Trigger", Button)
function Trigger.new(self)
    self.value = 0
    self.configValues["analog"] = ""
    return self
end
function Trigger:getState()
    local val = self.parent:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if val ~= nil then
        self.value = val
    end
    if type(self.value) ~= "number" then
        self.parent:xcCntlLog("Invalid state for " .. self.id, 1)
        return
    end
    if self.value > 0 and self.configValues["analog"] ~= "" then
        slots[self.configValues["analog"]](self.value)
        return
    end
    if self.value > 0 and (not self.pressed) then
        self.pressed = true
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                if self.configValues["Down"] ~= "" then
                    slots[self.configValues["Down"]]()
                end
            else
                if self.configValues["altDown"] ~= "" then
                    slots[self.configValues["altDown"]]()
                end
            end
        end
    elseif self.value == 0 and self.pressed then
        self.pressed = false
        if self.parent.configValues.shiftButton ~= self then
            if not self.parent.configValues.shiftButton or not self.parent[self.parent.configValues.shiftButton].pressed then
                if self.configValues["Up"] ~= "" then
                    slots[self.configValues["Up"]]()
                end
            else
                if self.configValues["altUp"] ~= "" then
                    slots[self.configValues["altUp"]]()
                end
            end
        end
    end
end
ThumbstickAxis = class("ThumbstickAxis", Type)
function ThumbstickAxis.new(self)
    self.configValues["axis"] = ""
    self.configValues["inverted"] = "false"
    self.configValues["deadzone"] = "10"
    self.rate = 0
    self.value = 0
    self.moving = false
    self.rateSet = false
    return self
end
function ThumbstickAxis:getState()
    if self.configValues.axis == nil then
        return
    end
    local val = self.parent:xcGetRegValue(string.format("mcX360_LUA/%s", self.id))
    if val ~= nil then
        self.value = val
    end
    if type(self.value) ~= "number" then
        self.parent:xcCntlLog("Invalid value for ThumbstickAxis", 1)
        return
    end
    if not self.moving and not self.rateReset then
        if mc.mcJogGetRate(inst, self.configValues.axis) ~= self.rate then
            mc.mcJogSetRate(inst, self.configValues.axis, self.rate)
            self.rateReset = true
        end
    end
    if math.abs(self.value) > tonumber(self.configValues.deadzone) and not self.moving then
        self.moving = true
        self.rateReset = false
        mc.mcJogSetRate(inst, self.configValues.axis, math.abs(self.value))
        local direction = 1
        if self.configValues.inverted then
            direction = (self.value > 0) and mc.MC_JOG_NEG or mc.MC_JOG_POS
        else
            direction = (self.value > 0) and mc.MC_JOG_POS or mc.MC_JOG_NEG
        end
        mc.mcJogVelocityStart(inst, self.configValues.axis, direction)
    end
    if math.abs(self.value) < tonumber(self.configValues.deadzone) and self.moving then
        mc.mcJogVelocityStop(inst, self.configValues.axis)
        self.moving = false
        mc.mcJogSetRate(inst, self.configValues.axis, self.rate)
        self.rateReset = true
    end
end
function ThumbstickAxis:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()
    local deadzoneLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Thumbstick deadzone:")
    propSizer:Add(deadzoneLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local deadzoneCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, self.configValues.deadzone, wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    deadzoneCtrl:SetValue(self.configValues.deadzone)
    propSizer:Add(deadzoneCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)
    propertiesPanel:Connect(deadzoneCtrl:GetId(), wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        self:getRoot().dirtyConfig = true
        self.configValues.deadzone = deadzoneCtrl:GetValue()
        self:getRoot():statusMessage("Update deadzone set to: " .. self.configValues.deadzone)
    end)
    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Connect to axis:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local choices = {"mc.X_AXIS", "mc.Y_AXIS", "mc.Z_AXIS", "mc.A_AXIS", "mc.B_AXIS", "mc.C_AXIS", ""}
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    choice:SetSelection(tonumber(self.configValues.axis) or 7)
    propertiesPanel:Connect(choice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
        self:getRoot().dirtyConfig = true
        self.configValues.axis = choice:GetString(choice:GetSelection())
        self:getRoot():statusMessage("Axis set to: " .. choice:GetString(choice:GetSelection()))
    end)
    propSizer:Add(0, 0)
    local invertCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "Invert axis:", wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxALIGN_RIGHT)
    invertCheck:SetValue(self.configValues.inverted == "true")
    propSizer:Add(invertCheck, 1, wx.wxEXPAND + wx.wxALL, 5)
    propertiesPanel:Connect(invertCheck:GetId(), wx.wxEVT_COMMAND_CHECKBOX_CLICKED, function()
        self:getRoot().dirtyConfig = true
        self.configValues.inverted = tostring(invertCheck:GetValue())
        self:getRoot():statusMessage("Inverted set to: " .. invertCheck:GetValue())
    end)
    propSizer:Layout()
    return propSizer
end
Controller = class("Controller", Type)
function Controller:new()
    self.guiMode = ''
    self.dirtyConfig = false
    self.timer = wx.wxTimer(mcLuaPanelParent, wx.wxID_ANY)
    self.timer:Connect(wx.wxEVT_TIMER, function() self:update() end)
    self.configValues["shiftButton"] = ""
    self.configValues["jogIncrement"] = "0"
    self.configValues["logLevel"] = "0"
    self.configValues["xYReversed"] = "false"
    self.configValues["frequency"] = "0"
    self:addChild(Button("DPad_UP", self))
    self:addChild(Button("DPad_DOWN", self))
    self:addChild(Button("DPad_LEFT", self))
    self:addChild(Button("DPad_RIGHT", self))
    self:addChild(Button("Btn_START", self))
    self:addChild(Button("Btn_BACK", self))
    self:addChild(Button("Btn_LS", self))
    self:addChild(Button("Btn_RS", self))
    self:addChild(Button("Btn_LTH", self))
    self:addChild(Button("Btn_RTH", self))
    self:addChild(Button("Btn_A", self))
    self:addChild(Button("Btn_B", self))
    self:addChild(Button("Btn_X", self))
    self:addChild(Button("Btn_Y", self))
    self:addChild(Trigger("LTR_Val", self))
    self:addChild(Trigger("RTR_Val", self))
    self:addChild(ThumbstickAxis("LTH_Y_Val", self))
    self:addChild(ThumbstickAxis("LTH_X_Val", self))
    self:addChild(ThumbstickAxis("RTH_Y_Val", self))
    self:addChild(ThumbstickAxis("RTH_X_Val", self))
    self.logLevels = {"ERROR", "WARNING", "INFO", "DEBUG"}
    local profileId = Profile.getLast()
    local profileName = Profile.getProfiles()[profileId]
    self.profile = Profile.new(profileId, profileName, self)
    self.profile:load()
    self:xcCntlLog("Starting Controller loop", 4)
    self.timer:Start(1000 / tonumber(self.configValues.frequency))
    return self
end
function Controller:update()
    if self.configValues.shiftButton ~= "" then
        self[self.configValues.shiftButton]:getState()
    end
    for _, input in ipairs(self.children) do
        if input ~= self.configValues.shiftButton then
            input:getState()
        end
    end
end
function Controller:updateUi()
    self.propertiesPanel:GetSizer():Clear(true)
    self:initUi(self.propertiesPanel)
end
function Controller:mapSimpleJog()
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s", tostring(self.configValues.xYReversed)), 4)
    self.DPad_UP.configValues.Down = self.configValues.xYReversed == "true" and "Jog Y+" or "Jog X+"
    self.DPad_UP.configValues.Up = self.configValues.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_DOWN.configValues.Down = self.configValues.xYReversed == "true" and "Jog Y-" or "Jog X-"
    self.DPad_DOWN.configValues.Up = self.configValues.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_RIGHT.configValues.Down = self.configValues.xYReversed == "true" and "Jog X+" or "Jog Y+"
    self.DPad_RIGHT.configValues.Up = self.configValues.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    self.DPad_LEFT.configValues.Down = self.configValues.xYReversed == "true" and "Jog X-" or "Jog Y-"
    self.DPad_LEFT.configValues.Up = self.configValues.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    if self.configValues.xYReversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end
    self.DPad_UP.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog Y+" or "Incremental Jog X+"
    self.DPad_DOWN.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog Y-" or "Incremental Jog X-"
    self.DPad_RIGHT.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog X+" or "Incremental Jog Y+"
    self.DPad_LEFT.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog X-" or "Incremental Jog Y-"
    if self.configValues.xYReversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function",
            3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
end
function Controller:xcCntlLog(msg, level)
    if self.configValues.logLevel == "0" then
        return
    end
    if level <= tonumber(self.configValues.logLevel) then
        if mc.mcInEditor() ~= 1 then
            mc.mcCntlLog(inst, "[[XBOX CONTROLLER " .. self.configValues.logLevels[level] .. "]]: " .. msg, "", -1)
        else
            print("[[XBOX CONTROLLER " .. self.configValues.logLevels[level] .. "]]: " .. msg)
        end
    end
end
function Controller:xcGetRegValue(reg)
    local hreg, rc = mc.mcRegGetHandle(inst, reg)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcRegGetValue(hreg)
        if rc == mc.MERROR_NOERROR then
            return val
        else
            self:xcCntlLog(string.format("Error in mcRegGetValue: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
        end
    else
        self:xcCntlLog(string.format("Error in mcRegGetHandle: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
    end
end
function Controller:initUi(propertiesPanel)
    local propSizer = propertiesPanel:GetSizer()
    local profiles = {}
    for _, name in pairs(Profile.getProfiles()) do
        table.insert(profiles, name)
    end
    local profileLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Current Profile:")
    propSizer:Add(profileLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local profileChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, profiles)
    propSizer:Add(profileChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    profileChoice:SetSelection(profileChoice:FindString(self.profile.name))
    propertiesPanel:Connect(profileChoice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
        if self.dirtyConfig then
            local answer = wx.wxMessageBox(
                "You have unsaved changes. Do you want to save before switching profiles?",
                "Unsaved Changes",
                wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION
            )
            if answer == wx.wxYES then
                self.profile:save()
            elseif answer == wx.wxCANCEL then
                return false  -- Cancel profile swap
            end
        end
        local choice = profileChoice:GetSelection()
        local newId
        for id, name in pairs(profiles) do
            if name == choice then
                newId = id
                break
            end
        end
        self.profile = Profile.new(newId, choice, self)
        self.profile:load()
        self:updateUi()
        self:statusMessage("Profile switched to: " .. choice)
    end)
    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Assign shift button:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local choices = {""}
    for _, input in ipairs(self.children) do
        if input.__type ~= "ThumbstickAxis" then
            table.insert(choices, input.id)
        end
    end
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    choice:SetSelection(choice:FindString(self.configValues.shiftButton))
    propertiesPanel:Connect(choice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
        self.dirtyConfig = true
        self.configValues.shiftButton = choice:GetString(choice:GetSelection())
        self:statusMessage("Shift button set to: " .. choice:GetString(choice:GetSelection()))
    end)
    local jogIncLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Jog Increment:")
    propSizer:Add(jogIncLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local jogIncCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.configValues.jogIncrement), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(jogIncCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)
    propertiesPanel:Connect(jogIncCtrl:GetId(), wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        self.dirtyConfig = true
        self.configValues.jogIncrement = tonumber(jogIncCtrl:GetValue())
        self:statusMessage("Jog increment set to: " .. self.configValues.jogIncrement)
    end)
    local logLevels = {"0 - Disabled", "1 - Error", "2 - Warning", "3 - Info", "4 - Debug"}
    local logLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Logging level:")
    propSizer:Add(logLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local logChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, logLevels)
    propSizer:Add(logChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    logChoice:SetSelection(tonumber(self.configValues.logLevel))
    propertiesPanel:Connect(logChoice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
        self.dirtyConfig = true
        self.configValues.logLevel = logChoice:GetString(logChoice:GetSelection())
        self:statusMessage("Log level set to: " .. self.configValues.logLevel)
    end)
    local swapLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Swap X and Y axes:")
    propSizer:Add(swapLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local swapCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "")
    swapCheck:SetValue(self.configValues.xYReversed == "true")
    propSizer:Add(swapCheck, 1, wx.wxALIGN_RIGHT + wx.wxALL, 5)
    propertiesPanel:Connect(swapCheck:GetId(), wx.wxEVT_COMMAND_CHECKBOX_CLICKED, function()
        self.dirtyConfig = true
        self.configValues.xYReversed = swapCheck:GetValue() and "true" or "false"
        self:statusMessage("X and Y axes swapped: " .. self.configValues.xYReversed)
    end)
    local frequencyLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Update Frequency (Hz):")
    propSizer:Add(frequencyLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local frequencyCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, self.configValues.frequency, wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(frequencyCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)
    propertiesPanel:Connect(frequencyCtrl:GetId(), wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        self.dirtyConfig = true
        self.configValues.frequency = tonumber(frequencyCtrl:GetValue())
        self:statusMessage("Update frequency set to: " .. self.configValues.frequency.. "Hz")
    end)
    propSizer:Add(0, 0, 1, wx.wxEXPAND)
    local mapSimpleJog = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Map Basic Jogging")
    propSizer:Add(mapSimpleJog, 1, wx.wxEXPAND + wx.wxALL, 5)
    propertiesPanel:Connect(mapSimpleJog:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self:mapSimpleJog()
        self:statusMessage("Basic jogging mapped to the DPad.")
    end)
    propSizer:Add(0, 0, 1, wx.wxEXPAND)
    propSizer:Add(0, 0, 1, wx.wxEXPAND)
    local undo = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Undo Unsaved Changes")
    propSizer:Add(undo, 1, wx.wxEXPAND + wx.wxALL, 5)
    local deleteProfile = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Delete A Profile...")
    propSizer:Add(deleteProfile, 1, wx.wxEXPAND + wx.wxALL, 5)
    local saveProfileAs = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Save Profile As...")
    propSizer:Add(saveProfileAs, 1, wx.wxEXPAND + wx.wxALL, 5)
    local saveProfile = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Save Current Profile")
    propSizer:Add(saveProfile, 1, wx.wxEXPAND + wx.wxALL, 5)
    local buttons = {undo, deleteProfile, saveProfileAs, saveProfile}
    local maxWidth = 0
    for _, button in pairs(buttons) do
        local size = button:GetSize()
        maxWidth = math.max(maxWidth, size:GetHeight())
    end
    for _, button in pairs(buttons) do
        button:SetMinSize(wx.wxSize(-1, maxWidth))
        button:SetSize(wx.wxSize(-1, maxWidth))
    end
    propSizer:Layout()
    propertiesPanel:Layout()
    propertiesPanel:Connect(undo:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local answer = wx.wxMessageBox(
            "Are you sure you want to undo any unsaved changes?",
            "Confirm",
            wx.wxYES_NO + wx.wxICON_QUESTION
        )
        if answer == wx.wxYES then
            self.dirtyConfig = false
            self.profile:load()
            self:updateUi()
            self:statusMessage("Restored profile: " .. self.profile.name)
        else
            return false
        end
    end)
    propertiesPanel:Connect(saveProfile:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local saveDialog = wx.wxMessageBox(string.format("Save changes to profile: %s?", profileChoice:GetStringSelection()), "Confirm", wx.wxOK + wx.wxCANCEL)
        if saveDialog == wx.wxOK then
            self.profile:save()
            self:statusMessage(string.format("Changes saved to profile: %s", profileChoice:GetStringSelection()))
        end
    end)
    propertiesPanel:Connect(deleteProfile:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local dialog = wx.wxDialog(propertiesPanel, wx.wxID_ANY, "Delete Profile", wx.wxDefaultPosition, wx.wxSize(300, 300), wx.wxDEFAULT_DIALOG_STYLE)
        local vSizer = wx.wxBoxSizer(wx.wxVERTICAL)
        local profileCtlLabel = wx.wxStaticText(dialog, wx.wxID_ANY, "Select a profile:")
        vSizer:Add(profileCtlLabel, 0, wx.wxALL, 5)
        local profileListBox = wx.wxListBox(dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(280, 120), profiles, wx.wxLB_SINGLE)
        vSizer:Add(profileListBox, 0, wx.wxEXPAND + wx.wxALL, 5)
        local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
        local deleteButton = wx.wxButton(dialog, wx.wxID_ANY, "Delete")
        local cancelButton = wx.wxButton(dialog, wx.wxID_CANCEL, "Cancel")
        buttonSizer:Add(deleteButton, 1, wx.wxALL, 5)
        buttonSizer:Add(cancelButton, 1, wx.wxALL, 5)
        vSizer:Add(buttonSizer, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)
        dialog:SetSizer(vSizer)
        vSizer:Fit(dialog)
        dialog:Connect(deleteButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            local profileName = profileListBox:GetStringSelection()
            local deleteDialog = wx.wxMessageBox(string.format("Delete profile: %s?", profileName), "Confirm", wx.wxOK + wx.wxCANCEL)
            if deleteDialog == wx.wxOK then
                local profile = Profile.new(Profile:getId(profileName), profileName, self)
                profile:delete()
                self:statusMessage(string.format("Deleted profile: %s", profileName))
            end
            dialog:EndModal(wx.wxOK)
        end)
        dialog:Connect(cancelButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            dialog:EndModal(wx.wxCANCEL)
        end)
        dialog:ShowModal()
        dialog:Destroy()
    end)
    propertiesPanel:Connect(saveProfileAs:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local dialog = wx.wxDialog(propertiesPanel, wx.wxID_ANY, "Save Profile As", wx.wxDefaultPosition, wx.wxSize(300, 300), wx.wxDEFAULT_DIALOG_STYLE)
        local vSizer = wx.wxBoxSizer(wx.wxVERTICAL)
        local profileCtlLabel = wx.wxStaticText(dialog, wx.wxID_ANY, "Select an existing profile:")
        vSizer:Add(profileCtlLabel, 0, wx.wxALL, 5)
        local profileListBox = wx.wxListBox(dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(280, 120), profiles, wx.wxLB_SINGLE)
        profileListBox:SetSelection(profileListBox:FindString(self.profile.name))
        vSizer:Add(profileListBox, 0, wx.wxEXPAND + wx.wxALL, 5)
        local newProfileLabel = wx.wxStaticText(dialog, wx.wxID_ANY, "Or enter a new profile name:")
        vSizer:Add(newProfileLabel, 0, wx.wxALL, 5)
        local newProfileTextCtrl = wx.wxTextCtrl(dialog, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxSize(280, 30))
        vSizer:Add(newProfileTextCtrl, 0, wx.wxEXPAND + wx.wxALL, 5)
        local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
        local saveButton = wx.wxButton(dialog, wx.wxID_SAVE, "Save")
        local cancelButton = wx.wxButton(dialog, wx.wxID_CANCEL, "Cancel")
        buttonSizer:Add(saveButton, 1, wx.wxALL, 5)
        buttonSizer:Add(cancelButton, 1, wx.wxALL, 5)
        vSizer:Add(buttonSizer, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)
        dialog:SetSizer(vSizer)
        vSizer:Fit(dialog)
        dialog:Connect(saveButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            local selectedProfile = profileListBox:GetStringSelection()
            local newProfileName = newProfileTextCtrl:GetValue()
            local tmpProfileName, tmpProfileId
            if newProfileName ~= "" then
                tmpProfileName = newProfileName
                tmpProfileId = #profiles
                self:xcCntlLog(string.format("Saving as new profile: %s", newProfileName), 3)
            elseif selectedProfile ~= "" then
                for id, profileName in pairs(Profile.getProfiles()) do
                    if profileName == selectedProfile then
                        tmpProfileName = selectedProfile
                        tmpProfileId = id
                        break
                    end
                end
                self:xcCntlLog(string.format("Saving over existing profile: %s", selectedProfile), 3)
            else
                wx.wxMessageBox("Please select a profile or enter a new name", "Error", wx.wxOK + wx.wxICON_ERROR)
            end
            if tmpProfileId and tmpProfileName then
                local saveDialog = wx.wxMessageBox(string.format("Save changes to profile: %s?", tmpProfileName), "Confirm", wx.wxOK + wx.wxCANCEL)
                if saveDialog == wx.wxOK then
                    local tmpProfile = Profile.new(tmpProfileId, tmpProfileName, self)
                    tmpProfile:save()
                    self:statusMessage(string.format("Configuration saved to profile: %s", tmpProfileName))
                else
                    do end
                end
            end
            dialog:EndModal(wx.wxID_SAVE)
        end)
        dialog:Connect(cancelButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            dialog:EndModal(wx.wxID_CANCEL)
        end)
        dialog:ShowModal()
        dialog:Destroy()
    end)
    propSizer:Layout()
    propertiesPanel:Layout()
    return propSizer
end
function Controller:initPanel(mode)
    self.guiMode = mode
    local guiPanel
    if mode == "embedded" or mode == "wizard" then
        guiPanel = mcLuaPanelParent
    else
        guiPanel = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Configure Xbox Controller Settings")
    end
    self.panel = guiPanel
    if self.guiMode ~= "embedded" then
        guiPanel:CreateStatusBar(1)
    end
    local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    guiPanel:SetMinSize(wx.wxSize(450, 500))
    guiPanel:SetMaxSize(wx.wxSize(450, 500))
    local treeBox = wx.wxStaticBox(guiPanel, wx.wxID_ANY, "Controller Tree Manager")
    local treeSizer = wx.wxStaticBoxSizer(treeBox, wx.wxVERTICAL)
    local tree = wx.wxTreeCtrl.new(guiPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(100, -1),
        wx.wxTR_HAS_BUTTONS, wx.wxDefaultValidator, "tree")
    local root_id = tree:AddRoot("Controller")
    local treedata = {
        [root_id:GetValue()] = self
    }
    for i = 1, #self.children do
        local child_id = tree:AppendItem(root_id, self.children[i].id)
        treedata[child_id:GetValue()] = self.children[i]
    end
    tree:ExpandAll()
    treeSizer:Add(tree, 1, wx.wxEXPAND + wx.wxALL, 5)
    local propBox = wx.wxStaticBox(guiPanel, wx.wxID_ANY, "Properties")
    local propSizer = wx.wxStaticBoxSizer(propBox, wx.wxVERTICAL)
    self.propertiesPanel = wx.wxPanel(guiPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
    local sizer = wx.wxFlexGridSizer(0, 2, 0, 0) -- 2 columns, auto-adjust rows
    sizer:AddGrowableCol(1, 1)
    self.propertiesPanel:SetSizer(sizer)
    self.propertiesPanel:Layout()
    local font = wx.wxFont(8, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL)
    self.propertiesPanel:SetFont(font)
    propBox:SetFont(font)
    treeBox:SetFont(font)
    tree:SetFont(font)
    propSizer:Add(self.propertiesPanel, 1, wx.wxEXPAND + wx.wxALL, 5)
    tree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, function(event)
        self.propertiesPanel:GetSizer():Clear(true)
        local item = treedata[event:GetItem():GetValue()]
        local newSizer =  wx.wxFlexGridSizer(0, 2, 0, 0)
        newSizer:AddGrowableCol(1, 1)
        if item == self then
            newSizer:AddGrowableRow(7,1)
        end
        self.propertiesPanel:SetSizer(newSizer)
        self.propertiesPanel:SetSizer(item:initUi(self.propertiesPanel))
        self.propertiesPanel:Layout()
    end)
    mainSizer:Add(treeSizer, 0, wx.wxEXPAND + wx.wxALL, 5)
    mainSizer:Add(propSizer, 1, wx.wxEXPAND + wx.wxALL, 5)
    guiPanel:SetSizer(mainSizer)
    mainSizer:Layout()
    function Controller.go()
        guiPanel:Connect(wx.wxEVT_CLOSE_WINDOW, function()
            if self.dirtyConfig then
                local answer = wx.wxMessageBox(
                    "You have unsaved changes to your controller profile. Do you want to save before exiting? (If you exit without saving, your applied changes will remain applied for the current session.)",
                    "Unsaved Changes",
                    wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION
                )
    
                if answer == wx.wxYES then
                    self.profile:save()
                elseif answer == wx.wxCANCEL then
                    return false  -- Cancel closing the window
                end
            end
           
            guiPanel:Destroy()
            
            wx.wxGetApp():ExitMainLoop()
            self.go = function() end
        end)
        local app = wx.wxApp(false)
        wx.wxGetApp():SetTopWindow(guiPanel)
        guiPanel:Show(true)
        wx.wxGetApp():MainLoop()
    end
    self:go()
end
function Controller:statusMessage(msg)
    if self.guiMode == "embedded" then
        mc.mcCntlSetLastError(inst, msg)
    else
        self.panel:SetStatusText(msg)
    end
end
function Controller:destroy()
    if self.timer then
        self.timer:Stop()
        self.timer = nil
    end
    if self.dirtyConfig then
        local choice = wx.wxMessageBox(
            "You have unsaved changes. Do you want to save before exiting?",
            "Unsaved Changes",
            wx.wxYES_NO + wx.wxICON_QUESTION
        )
        if choice == wx.wxYES then
            self.profile:save()
        elseif choice == wx.wxNO then
        end
    end
end
xc=Controller("xc",nil)
xc:initPanel('embedded')
return { xc = xc }
