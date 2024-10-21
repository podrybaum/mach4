if not mc then
    require("mocks")
end

local iniFile
if not mc.mcInEditor() == 1 then
    local path = "C:\\Mach4Hobby\\Profiles\\" .. mc.mcProfileGetName(inst)
    iniFile = path .. "\\" .. "xbcontroller.ini"
else
    iniFile = os.getenv("USERPROFILE") .. "\\mach4\\xbcontroller.ini"
end

---@class Profile
---@field id string
---@field name string
---@field controller Controller
---@field profileData table
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
    self.profileData = {}
    self.profileData["profileName"] = self.name
    return self
end

function Profile:exists()
    local file = io.open(self.iniFile, "r+")
    if file ~= nil then
        for line in file:lines() do
            if line == string.format("[ControllerProfile-%s]", self.id) then
                return true
            end
        end
    end
end

function Profile:write()
    if self:exists() then
        self:delete()
        self:write()
    else
        local file = io.open(self.iniFile, "a")
        if file then
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
    if file then
        local iniLines = {}
        local inProfile = false
        for line in file:lines() do
            if not inProfile and not line:startswith(string.format("[ControllerProfile-%s]", self.id)) then
                table.insert(iniLines, line)
            elseif line:startswith(string.format("[ControllerProfile-%s]", self.id)) then
                inProfile = true
                print(string.format("matching line: %s to id: %s", line, self.id))
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
    if file then
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
    if file then
        for line in file:lines() do
            if line:match("^lastProfile=.*$") then
                return line:match("^lastProfile=(.*)$")
            end
        end
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
    if file then
        for line in file:lines() do
            if line:match("^%[ControllerProfile-.*%]$") then
                id = line:match("^%[ControllerProfile%-(%d+)%]$")
            end
            if line:match("^profileName=.*$") then
                name = line:match("^profileName=(.*)$")
                profiles[id] = name
            end
        end
        return profiles
    end
end

return {Profile = Profile}