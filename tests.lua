xc = require("xc")

local function runTests(tests)
  local passed, failed = 0, 0

  for name, test in pairs(tests) do
      local ok, err = pcall(test)  -- Run each test in protected mode
      if ok then
          print(string.format("%s passed", name))
          passed = passed + 1
      else
          print(string.format("%s failed: %s", name, err))
          failed = failed + 1
      end
  end

  print(string.format("\nTests run: %d | Passed: %d | Failed: %d", 
                      passed + failed, passed, failed))
end

-- Example tests
local tests = {
  ["string.split correctly splits a string"] = function()
    assert(xc.string.split("xc.DPad_Down.UP.slot") == {"xc","DPad_Down","UP","slot"},
    "string.split: unexpected output")
  end,

  ["getProfile returns a number"] = function()
    assert(type(xc.getProfile() == "number"),
    "getProfile: unexpected return type")
  end
}

-- Run the tests
runTests(tests)


