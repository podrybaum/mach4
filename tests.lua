require("stringsExtended")
local object=require("object")
local button = require("button")
require("controller")

local esc = string.char(27)
local red = esc .. "[1;31m"
local green = esc .. "[1;32m"
local reset = esc .. "[0m"
local passed, failed = 0, 0

-- setup some objects
local panel = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Mock Panel")
local xc = Controller("xc", nil, panel)

---@diagnostic disable-next-line: missing-parameter
local base = class("BaseClass")
local derived = class("DerivedClass", base)
function base.new(self)
  return self
end

function derived.new(self)
  return self
end

local tmpIni = "test.ini"

local function beforeEach()
  panel = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Mock Panel")
  xc = Controller("xc", nil, panel)
  Profile.writeDefault(tmpIni)
end

local function afterEach()
  local file = io.open(tmpIni, "r")
  if file then
    file:close()
    os.remove(tmpIni)
  end
end

local function runTests(tests)
  for name, test in object.pairsByKeys(tests) do
    beforeEach()
    local ok, err = xpcall(test, debug.traceback)
    if ok then
      print(string.format("%s: %spassed%s", name, green, reset))
      passed = passed + 1
    else
      print(string.format("%s: %sfailed%s: %s", name, red, reset, err))
      failed = failed + 1
    end
    afterEach()
  end

  if failed > 0 then
    red = esc .. "[1;31m"
  else
    red = ""
  end
  print(string.format("\nTests run: %d | Passed: %s%d%s | Failed: %s%d%s",
    passed + failed, green, passed, reset, red, failed, reset))
end

-- Test for the serialize method
local function testSerializeMethod()
  -- Create a root instance and set configValues
  local rootInstance = base("root")
  rootInstance.configValues["key1"] = "value1"
  rootInstance.configValues["key2"] = "value2"

  -- Create a child instance and set configValues
  local childInstance = base("child", rootInstance) -- Pass rootInstance as parent
  childInstance.configValues["childKey1"] = "childValue1"
  childInstance.configValues["childKey2"] = "childValue2"
  rootInstance:addChild(childInstance)

  -- Expected serialized output as a table
  local expected = {
    ["root.configValues.key1"] = "value1",
    ["root.configValues.key2"] = "value2",
    ["root.child.configValues.childKey1"] = "childValue1",
    ["root.child.configValues.childKey2"] = "childValue2"
  }

  -- Serialize the root instance
  local serializedOutput = rootInstance:serialize()

  -- Assert that the output matches expected table
  for key, value in pairs(expected) do
    assert(serializedOutput[key] == value, string.format("Mismatch on %s", key))
  end

  -- Check if any unexpected keys are in the serialized output
  for key, _ in pairs(serializedOutput) do
    assert(expected[key], string.format("Unexpected key in output: %s", key))
  end
end


local tests = {
  ["object.lua - serialize function correctly serializes an object and its children"] = testSerializeMethod(),

  ["stringsExtended.lua - string.split correctly splits a string"] = function()
    assert(table.unpack(string.split("xc.DPad_Down.UP.slot", "%.")) == "xc", "DPad_Down", "UP", "slot",
      string.format("string.split: unexpected output: %s", string.split("xc.DPad_Down.UP.slot", "%.")))
  end,

  ["stringsExtended.lua - string.strip correctly strips a string"] = function()
    assert(string.strip(" string ") == "string",
      "string.strip: unexpected output")
  end,

  ["stringsExtended.lua - string.lstrip correctly strips a string"] = function()
    assert(string.lstrip(" string") == "string",
      "string.lstrip: unexpected output")
  end,

  ["stringsExtended.lua - string.rstrip correctly strips a string"] = function()
    assert(string.rstrip("string ") == "string",
      "string.rstrip: unexpected output")
  end,

  ["stringsExtended.lua - string.startswith correctly matches a string"] = function()
    assert(string.startswith("string", "str"), "string.startswith: unexpected output")
    assert(not string.startswith("string", "ing"), "string.startswith: unexpected output")
  end,

  ["stringsExtended.lua - string.endswith correctly matches a string"] = function()
    assert(string.endswith("string", "ing"), "string.endswith: unexpected output")
    assert(not string.endswith("string", "str"), "string.endswith: unexpected output")
  end,

  ["object.lua - class function correctly returns a 'class'"] = function()
    assert(type(base) == "table")
    assert(base.__type == "BaseClass")
    local mt = getmetatable(base)
    assert(type(mt) == "table")
    assert(mt.__type == "Class")
    assert(mt.__name == "Type")
    assert(mt.__index == Type)
  end,

  ["object.lua - class function correctly inherits a class"] = function()
    assert(type(derived) == "table")
    assert(derived.__type == "DerivedClass")
    assert(derived.__name == "DerivedClass")
    assert(derived.__super == base)
    local mt = getmetatable(derived)
    assert(mt == base)
  end,

  ["object.lua class function correctly establishes metatable chain"] = function()
    assert(derived.__index == derived)
    assert(base.__index == base)
    assert(getmetatable(derived) == base)
    assert(getmetatable(base) == Type)
    assert(getmetatable(getmetatable(derived)) == Type)
    assert(Type.__index == Type)
  end,

  ["object.lua - isInstance function correctly identifies custom types"] = function()
    local inst = derived("test")
    assert(inst:isInstance(Type) == false)
    assert(inst:isInstance(derived) == true)
    assert(inst:isInstance(base) == true)
    assert(inst:isInstance(Trigger) == false)
    assert(derived:isInstance(Type) == true)
  end,

  ["object.lua - pairsByKeys function with sortConfig correctly sorts a non-Button table"] = function()
    local t = {
      ["c"] = "value1",
      ["b"] = "value2",
      ["a"] = "value3",
    }
    local sortedKeys = { "a", "b", "c" }
    local keys = {}
    for key in object.pairsByKeys(t, object.sortConfig) do
      table.insert(keys, key)
    end
    for i, key in ipairs(sortedKeys) do
      assert(keys[i] == key)
    end
  end,

  ["object.lua - pairsByKeys function with sortConfig correctly sorts a Button table"] = function()
    local t = {
      ["Up"] = "foo",
      ["Down"] = "foo",
      ["altUp"] = "foo",
      ["altDown"] = "foo"
    }
    local sortedKeys = { "Down", "altDown", "Up", "altUp" }
    local keys = {}
    for key in object.pairsByKeys(t, object.sortConfig) do
      table.insert(keys, key)
    end
    for i, key in ipairs(sortedKeys) do
      assert(keys[i] == key)
    end
  end,

  ["object.lua - getRoot returns the Controller object"] = function()
    assert(xc.children[1]:getRoot() == xc)
  end,

  ["object.lua - deserialize function correctly deserializes a key value pair from the ini file"] = function()
    local o = xc.children[2].configValues.Up
    local id = xc.children[2].id
    xc:deserialize(string.format("xc.%s.configValues.Up", id), "Jog Y+")
    assert(xc.children[2].configValues.Up == "Jog Y+")
    xc.children[2].configValues.Up = o -- we should always undo changes so the order of execution of tests doesn't matter
  end,

  ["object.lua - getPath returns the correct path"] = function()
    local id = xc.children[3].id
    assert(xc.children[3]:getPath() == string.format("xc.%s", id))
  end,

  ["profile.lua - writeDefault correctly writes a default ini file to disk"] = function()
    xc.profile.iniFile = tmpIni
    xc.profile.writeDefault(tmpIni)
    local file = io.open(xc.profile.iniFile, "r")
    assert(file)
    local content = file:read("*all")
    file:close()
    assert(content:match("lastProfile=0"), "writeDefault: unexpected output")
  end,

  ["profile.lua - load correctly loads the profile data"] = function()
    xc.profile.iniFile = tmpIni
    xc.profile.id = "0"
    xc.profile.name = "default"
    xc.profile:load()

    assert(xc.profile.profileData["xc.DPad_DOWN.configValues.Down"] == "Jog Y-")
    assert(xc.profile.profileData["xc.DPad_DOWN.configValues.Up"] == "Jog Y Off")
  end,

  ["profile.lua - save correctly saves the profile data"] = function()
    local ovalue = xc.configValues.logLevel
    xc.profile.id = "0"
    xc.profile.name = "default"
    xc.profile.iniFile = tmpIni
    xc.configValues.logLevel = ovalue + 1
    if xc.configValues.logLevel > 4 then
      xc.configValues.logLevel = 0
    end
    ovalue = xc.configValues.logLevel
    xc.profile:save()

    local file = io.open(xc.profile.iniFile, "r")
    assert(file)
    local content = file:read("*all")
    file:close()
    assert(content:match("lastProfile=0"), "save: unexpected output")
    assert(content:match(string.format("logLevel=%s", ovalue)), "save: unexpected output")
  end,

  ["button.lua - all keys in the slots table return functions"] = function()
    for _, slot in pairs(button.slots) do
      assert(type(slot) == "function")
    end
  end,

}

-- Run the tests
runTests(tests)
if failed == 0 then
  print("All tests passed!")
  local file = io.open(tmpIni, "r")
  if file then
    file:close()
    local ret, err = os.remove(tmpIni)
    if not ret then
      print("Failed to remove temporary ini file: " .. err)
    end
  end
  os.exit(0)
else
  os.exit(1)
end
