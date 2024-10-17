local iniFile = "xbcontroller.ini"

if not mc then
    require("mocks")
end


if not mc.mcInEditor() == 1 then
    local path = "C:\\Mach4Hobby\\Profiles\\" .. mc.mcProfileGetName(inst)
    iniFile = path .. "\\" .. iniFile
else
    iniFile = os.getenv("USERPROFILE") .. "\\mach4\\" .. iniFile
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
    self.profileData = {}
    self.profileData["profileName"] = self.name
    return self
end

function Profile:exists()
    local file = io.open(iniFile, "r+")
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
        local iniLines = {}
        local file = io.open(iniFile, "r+")
        if file then
            for line in file:lines() do
                table.insert(iniLines, line)
            end
            file:close()
            local sectionStart = 0
            for i, line in ipairs(iniLines) do
                if line == string.format("[ControllerProfile-%s]", self.id) then
                    sectionStart = i + 1
                end
                if sectionStart > 0 and not line:match("^%s*$") then
                    table.remove(iniLines, i)
                end
            end
            if sectionStart > 0 then
                local lineNo = sectionStart + 1
                table.insert(iniLines, sectionStart, string.format("profileName=%s", self.name))
                for k, v in pairs(self.profileData) do
                    table.insert(iniLines, lineNo, string.format("%s=%s", k, v))
                    lineNo = lineNo + 1
                end
                table.insert(iniLines, lineNo, "")
            end
            file = io.open(iniFile, "w")
            if file then
                for _, line in ipairs(iniLines) do
                    file:write(line, "\n")
                end
                file:close()
            end
        end
    end
end

function Profile:delete()
    local file = io.open(iniFile, "r+")
    if file then
        local iniLines = {}
        local inProfile = false
        for line in file:lines() do
            if not inProfile and not line == string.format("[ControllerProfile-%s]", self.id) then
                table.insert(iniLines, line)
            elseif line == string.format("[ControllerProfile-%s]", self.id) then
                inProfile = true
            elseif inProfile and line:match("^%s*$") then
                inProfile = false
            end
        end
        file:close()
        file = io.open(iniFile, "w")
        if file then
            for _, line in ipairs(iniLines) do
                file:write(line, "\n")
            end
            file:close()
        end
    end
end

function Profile:load()
    local file = io.open(iniFile, "r+")
    if file then
        local inProfile = false
        for line in file:lines() do
            if not inProfile and line == string.format("[ControllerProfile-%s]", self.id) then
                inProfile = true
            elseif inProfile and not line:match("^%s*$") then
                local key, value = line:match("^(.-)=(.*)$")
                if key and value then
                    self.profileData[key] = value
                end
            end
        end
    end
    if self.profileData["profileName"] then
        self.name = self.profileData["profileName"]
        table.remove(self.profileData, 1)
    end
    for k, v in pairs(self.profileData) do
        self.controller:deserialize(k, v)
    end
    mc.mcProfileWriteString(inst, "XBC4MACH4", "lastProfile", tostring(self.id))
end

function Profile:save()
    self.profileData = self.controller:serialize()
    self:write()
end

function Profile.getProfiles()
    local file = io.open(iniFile, "r")
    local profiles = {}
    local id, name
    if file then
        for line in file:lines() do
            if line:match("^%[ControllerProfile-.*%]$") then
                id = line:match("^%[ControllerProfile-(%d+)%]$")
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