require("stringsExtended")

local esc = string.char(27)
local red = esc.."[1;31m"
local green = esc.."[1;32m"
local reset = esc.."[0m"

local function runTests(tests)
  local passed, failed = 0, 0

  for name, test in pairs(tests) do
      local ok, err = pcall(test)
      if ok then
          print(string.format("%s: %spassed%s", name, green, reset))
          passed = passed + 1
      else
          print(string.format("%s: %sfailed%s: %s", name, red, reset, err))
          failed = failed + 1
      end
  end

  if failed > 1 then
    red = esc.."[1;31m"
  else
    red = ""
  end
  print(string.format("\nTests run: %d | Passed: %s%d%s | Failed: %s%d%s", 
                      passed + failed, green, passed, reset, red, failed, reset))
end

-- Example tests
local tests = {
  ["string.split correctly splits a string"] = function()
    assert(table.unpack(string.split("xc.DPad_Down.UP.slot", "%.")) == "xc","DPad_Down","UP","slot",
    string.format("string.split: unexpected output: %s", string.split("xc.DPad_Down.UP.slot", "%.")))
  end,

  ["string.strip correctly strips a string"] = function()
    assert(string.strip(" string ") == "string",
    "string.strip: unexpected output")
  end,

  ["string.lstrip correctly strips a string"] = function()
    assert(string.lstrip(" string") == "string",
  "string.lstrip: unexpected output")
  end,

  ["string.rstrip correctly strips a string"] = function()
    assert(string.rstrip("string ") == "string",
  "string.rstrip: unexpected output")
  end,


}

-- Run the tests
runTests(tests)


