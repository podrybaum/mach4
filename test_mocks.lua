mocks = require("mocks")

local esc = string.char(27)
local red = esc.."[1;31m"
local green = esc.."[1;32m"
local reset = esc.."[0m"

local function beforeEach()
    profileData = {}
end

local function runTests(tests)
  local passed, failed = 0, 0

  for name, test in pairs(tests) do
      local ok, err = pcall(test)  -- Run each test in protected mode
      if ok then
          print(string.format("%s: %spassed%s", name, green, reset))
          passed = passed + 1
      else
          print(string.format("%s: %sfailed%s: %s", name, red, reset, err))
          failed = failed + 1
      end
  end

  print(string.format("\nTests run: %d | Passed: %s%d%s | Failed: %s%d%s", 
                      passed + failed, green, passed, reset, red, failed, reset))
end

-- Example tests
local tests = {
  ["trim function correctly trims a string"] = function()
    local toTrim = "  myString  "
    assert(trim(toTrim) == "myString",
    "trim: unexpected output")
  end,

  ["loadIniFile loads the ini file"] = function()
    loadIniFile()
    assert(profileData["ControllerProfile-0"] ~= nil,
    "loadIniFile: failed to load machine.ini")
  end, 

  ["mcSignalGetHandle returns a number"] = function()
    assert(type(mc.mcSignalGetHandle() == "number"))
  end,
  ["mcSignalGetState returns a number"] = function()
    assert(type(mc.mcSignalGetState(0,1) == "number"))
  end,
  ["mcSignalSetState returns 0"] = function()
    assert(mc.mcSignalSetState(1,1) == 0)
  end,
  ["mcCntlEnable returns 0"] = function()
    assert(mc.mcCntlEnable(0,1) == 0)
  end,
  ["mcJogVelocityStart returns 0"] = function()
    assert(mc.mcJogVelocityStart(0,mc.Y_AXIS,mc.MC_JOG_POS) == 0)
  end,
  ["mcJogVelocityStop returns 0"] = function()
    assert(mc.mcJogVelocityStop(0,mc.Y_AXIS) == 0)
  end,
  ["mcJogSetRate returns 0"] = function()
    assert(mc.mcJogSetRate(0,mc.Y_AXIS,100) == 0)
  end,
  ["mcJogGetRate returns a number and a zero"] = function()
    local re, rc = mc.mcJogGetRate(0, mc.Y_AXIS)
    assert(type(re) == "number" and rc == 0)
  end,
  ["mcJogIncStart returns 0"] = function()
    assert(mc.mcJogIncStart(0,mc.Y_AXIS,0.1) == 0)
  end,
  ["mcCntlCyleStart returns 0"] = function()
    assert(mc.mcCntlCycleStart(0) == 0)
  end,
  ["mcCntlFeedHold returns 0"] = function()
    assert(mc.mcCntlFeedHold(0) == 0)
  end,
  ["mcGetInstance returns 0"] = function()
    assert(mc.mcGetInstance() == 0)
  end,
  ["mcRegGetHandle returns a number and a 0"] = function()
    local re, rc = mc.mcRegGetHandle(0, "someRegister")
    assert(type(re) == "number" and rc == 0)
  end,
  ["mcRegGetValue returns a number and a 0"] = function()
    local re, rc = mc.mcRegGetValue(0)
    assert(type(re) == "number" and rc == 0)
  end,
  ["mcInEditor returns 1"] = function()
    assert(mc.mcInEditor() == 1)
  end,
  ["mcCntlGetErrorString returns a string"] = function()
    assert(type(mc.mcCntlGetErrorString(0, 1)) == "string")
  end,
  ["mcProfileFlush returns 0"] = function()
    assert(mc.mcProfileFlush(0) == 0)
  end,
  ["mcCntlGetState returns a number and a 0"] = function()
    local re,rc = mc.mcCntlGetState(0)
    assert(type(re) == "number" and rc == 0)
  end,
  ["mcProfileExists returns true when key exists"] = function()
    assert(mc.mcProfileExists(0,"ControllerProfile-0","xc.profileName") == mc.MC_TRUE)
  end,
  ["mcProfileExists returns false when key does not exist"] = function()
    assert(mc.mcProfileExists(0,"ControllerProfile-0","wrongKey") == mc.MC_FALSE)
  end,
  ["mcProfileExists returns false when section does not exist"] = function()
    assert(mc.mcProfileExists(0,"wrongSection","xc.profileName") == mc.MC_FALSE)
  end,
  ["mcProfileReload returns 0"] = function()
    assert(mc.mcProfileReload(0) == 0)
  end,

  ["mcProfileWriteString stores a string value"] = function() beforeEach()
    mc.mcProfileWriteString(0, "ControllerProfile-999", "testKey", "testValue")
    assert(profileData["ControllerProfile-999"]["testKey"] == "testValue",
           "Failed to write string value to profile")
end,

["mcProfileWriteDouble stores a numeric value"] = function() beforeEach()
    mc.mcProfileWriteDouble(0, "ControllerProfile-999", "testNumber", 42.42)
    assert(profileData["ControllerProfile-999"]["testNumber"] == 42.42,
           "Failed to write double value to profile")
end,

["mcProfileGetString retrieves an existing string value"] = function() beforeEach()
    mc.mcProfileWriteString(0, "ControllerProfile-999", "testKey", "retrievedValue")
    local val, rc = mc.mcProfileGetString(0, "ControllerProfile-999", "testKey", "default")
    assert(val == "retrievedValue" and rc == 0,
           "Failed to retrieve existing string value")
end,

["mcProfileGetString returns default if key is missing"] = function() beforeEach()
    local val, rc = mc.mcProfileGetString(0, "ControllerProfile-999", "missingKey", "default")
    assert(val == "default" and rc == 0,
           "Did not return default value for missing key")
end,

["mcProfileGetDouble retrieves an existing numeric value"] = function() beforeEach()
    mc.mcProfileWriteDouble(0, "ControllerProfile-999", "testNumber", 42.42)
    local val, rc = mc.mcProfileGetDouble(0, "ControllerProfile-999", "testNumber", 0)
    assert(val == 42.42 and rc == 0,
           "Failed to retrieve existing double value")
end,

["mcProfileGetDouble returns default if key is missing"] = function() beforeEach()
    local val, rc = mc.mcProfileGetDouble(0, "ControllerProfile-999", "missingNumber", 0)
    assert(val == 0 and rc == 0,
           "Did not return default value for missing double key")
end,
 
["mcProfileWriteString overrides existing value"] = function() beforeEach()
    mc.mcProfileWriteString(0, "ControllerProfile-999", "overrideKey", "initial")
    mc.mcProfileWriteString(0, "ControllerProfile-999", "overrideKey", "overridden")
    assert(profileData["ControllerProfile-999"]["overrideKey"] == "overridden",
           "Failed to override existing string value")
end,

["mcProfileWriteDouble overrides existing numeric value"] = function() beforeEach()
    mc.mcProfileWriteDouble(0, "ControllerProfile-999", "overrideNumber", 1.23)
    mc.mcProfileWriteDouble(0, "ControllerProfile-999", "overrideNumber", 4.56)
    assert(profileData["ControllerProfile-999"]["overrideNumber"] == 4.56,
           "Failed to override existing double value")
end,

}

-- Run the tests
runTests(tests)