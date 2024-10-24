package.cpath = string.format("%s;C:\\Mach4Hobby\\ZeroBraneStudio\\bin\\clibs53\\?.dll", package.cpath)
package.cpath = string.format("%s;./build/?.dll", package.cpath)

wx = require("wx")

-- Make profileData global to access it across modules
profileData = {}

-- Helper function to trim leading and trailing whitespace
function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Reload the INI file on every call, ensuring whitespace is handled
function loadIniFile()
    profileData = {} -- Clear existing data

    local iniFile = io.open("machine.ini", "r")
    if not iniFile then
        error("[MOCK]: Failed to open machine.ini")
    end

    local currentSection = nil
    for line in iniFile:lines() do
        local section = line:match("^%[(.-)%]$")
        if section then
            currentSection = trim(section)
            profileData[currentSection] = {}
        else
            local key, value = line:match("^(.-)=(.*)$")
            if key and currentSection then
                key = trim(key)
                value = trim(value)
                profileData[currentSection][key] = value
            end
        end
    end
    iniFile:close()
end

-- Helper: Write `profileData` back to the INI file
function saveIniFile()
    local iniFile = io.open("machine.ini", "w")
    if iniFile ~= nil then
        for section, data in pairs(profileData) do
            iniFile:write(string.format("[%s]\n", section))
            for key, value in pairs(data) do
                iniFile:write(string.format("%s=%s\n", key, value))
            end
        end
        iniFile:close()
    end
end

mc = { --TODO: mcProfileGetName and mcCntlSetLastError need tests and mc ProfileGetName needs a proper implementation
    mcProfileGetName = function(inst)
        return "default"
    end,
    mcCntlLog = function(inst, message, style, level)
        print("[MOCK LOG]: " .. message)
    end,
    mcCntlSetLastError = function(inst, message)
        print("[MOCK LAST_ERROR]: " .. message)
    end,
    mcSignalGetHandle = function(inst, signal)
        print("[MOCK]: mcSignalGetHandle called for signal: " .. tostring(signal))
        return 123 -- Return a dummy handle
    end,
    mcSignalSetState = function(handle, state)
        print("[MOCK]: mcSignalSetState called on handle " .. tostring(handle) .. " with state " .. tostring(state))
        return 0
    end,
    mcSignalGetState = function(inst, handle)
        print("[MOCK]: mcSignalGetState called on handle:" .. handle)
        return 1 --- return a dummy state
    end,
    mcCntlEnable = function(inst, state)
        print("[MOCK]: mcCntlEnable called with state: " .. tostring(state))
        return 0
    end,
    mcJogVelocityStart = function(inst, axis, direction)
        print("[MOCK]: Jog started on axis " .. tostring(axis) .. " in direction " .. tostring(direction))
        return 0
    end,
    mcJogVelocityStop = function(inst, axis)
        print("[MOCK]: Jog stopped on axis " .. tostring(axis))
        return 0
    end,
    mcJogSetRate = function(inst, axis, rate)
        print("[MOCK]: Jog rate set on axis " .. tostring(axis) .. " to " .. tostring(rate))
        return 0
    end,
    mcJogGetRate = function(inst, axis)
        -- print("[MOCK]: Getting jog rate for axis " .. tostring(axis))
        return 100, 0 -- Return a dummy rate
    end,
    mcJogIncStart = function(inst, axis, increment)
        print("[MOCK]: Incremental jog on axis " .. tostring(axis) .. " by " .. tostring(increment))
        return 0
    end,
    mcCntlCycleStart = function(inst)
        print("[MOCK]: Cycle start")
        return 0
    end,
    mcCntlFeedHold = function(inst)
        print("[MOCK]: Feed hold")
        return 0
    end,
    mcGetInstance = function()
        print("[MOCK]: mcGetInstance called")
        return 0 -- Return a dummy instance
    end,
    mcRegGetHandle = function(inst, regName)
        return 123, 0 -- return dummy handle and 0 for success
    end,
    mcRegGetValue = function(handle)
        return 123, 0 -- return dummy numeric value and 0 for success
    end,
    mcInEditor = function()
        return 1
    end,
    mcCntlGetErrorString = function(inst, rc)
        return "This is an error string"
    end,
    mcProfileFlush = function(inst)
        return 0
    end,
    mcCntlGetState = function(inst)
        return 123, 0 -- return dummy state and 0 for success
    end,
    -- Mock function to check for section and key existence
    mcProfileExists = function(inst, section, key)
        loadIniFile()

        section = trim(section)
        key = trim(key)

        if not profileData[section] then
            return mc.MC_FALSE
        end

        local exists = profileData[section][key] ~= nil
        return exists and mc.MC_TRUE or mc.MC_FALSE
    end,

    mcProfileReload = function(inst)
        return 0
    end,

    mcProfileWriteString = function(inst, section, key, value)
        loadIniFile() -- Ensure we're working with the latest data
        section = trim(section)
        key = trim(key)
        value = tostring(value):gsub("%s+$", "") -- Trim trailing spaces from value

        profileData[section] = profileData[section] or {}
        profileData[section][key] = value

        saveIniFile()
        return 0 -- Simulate success
    end,

    -- Mock: Write a numeric value to the INI file
    mcProfileWriteDouble = function(inst, section, key, value)
        loadIniFile()
        section = trim(section)
        key=trim(key)
        value=tonumber(value)
        profileData[section] = profileData[section] or {}
        profileData[section][key] = tonumber(value)
        saveIniFile()
        return 0 -- Simulate success
    end,

    -- Mock: Read a string value from the INI file
    mcProfileGetString = function(inst, section, key, defaultValue)
        loadIniFile()
        if profileData[section] and profileData[section][key] then
            return profileData[section][key], 0 -- Return value and success code
        else
            return defaultValue, 0 -- Return default value if key not found
        end
    end,

    -- Mock: Read a numeric value from the INI file
    mcProfileGetDouble = function(inst, section, key, defaultValue)
        loadIniFile()
        if profileData[section] and profileData[section][key] then
            return tonumber(profileData[section][key]), 0 -- Return value and success code
        else
            return defaultValue, 0 -- Return default value if key not found
        end
    end,

    MC_STATE_IDLE = 0,
    MERROR_NOERROR = 0,
    AXIS1 = 1,
    AXIS0 = 0,
    AXIS2 = 2,
    AXIS3 = 3,
    AXIS4 = 4,
    AXIS5 = 5,
    Y_AXIS = 1,
    X_AXIS = 0,
    Z_AXIS = 2,
    A_AXIS = 3,
    B_AXIS = 4,
    C_AXIS = 5,
    MC_JOG_POS = 1,
    MC_JOG_NEG = -1,
    MC_TRUE = 1,
    MC_FALSE = 0
}

scr = {}
scr.DoFunctionName = (function(name)
    return name
end)

mcLuaPanelParent = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Configure Xbox Controller Settings")

return {mc, wx, scr, mcLuaPanelParent, trim, loadIniFile, saveIniFile}
