local iniFile
if mc then
    iniFile = "C:\\Mach4Hobby\\Profiles\\" .. mc.mcProfileGetName(inst).. "\\xbcontroller.ini"
end
-- DEV_ONLY_START
if not mc then
    require("mocks")
end



if mc.mcInEditor() == 1 then
    iniFile = os.getenv("USERPROFILE") .. "\\mach4\\xbcontroller.ini"
end
-- DEV_ONLY_END


---@class Profile
---@field id string
---@field name string
---@field controller Controller
---@field profileData table
---@field iniFile string
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
xc.configValues.simpleJogMapped=true
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

-- DEV_ONLY_START
return {Profile = Profile}
-- DEV_ONLY_END