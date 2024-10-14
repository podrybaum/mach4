Profile = {}
Profile.__index = Profile
Profile.__type = "Profile"
Profile.__tostring = function(self)
    return string.format("Profile: %s", self.name)
end

function Profile.new(name)
    local self = setmetatable({}, Profile)
    self.id = #profiles + 1
    self.name = name
    return self
end