print(_VERSION)
print(package.cpath)
require("xc")
require 'busted.runner'()

assert.is_true(true)

describe("XC Module", function()
  
    -- Test type checking
    it("should validate custom types correctly", function()
      local testBtn = xc:newButton("test")
      assert.is_true(xc.customType(testBtn) == "Button")
      local testSignal = xc:newSignal(testBtn, "test2")
      assert.is_true(xc.customType(testSignal) == "Signal")
      local testTrigger = xc:newTrigger("LTR")
      assert.is_true(xc.customType(testTrigger) == "Trigger")
      local testSlot = xc:newSlot("Up", function() return end)
      assert.is_true(xc.customType(testSlot) == "Slot")
      local testAxis = xc:newThumbstickAxis("test3")
      assert.is_true(xc.customType(testAxis) == "newThumbstickAxis")
      local testTable = {}
      assert.is_true(xc.customType(testTable) == "table")
      local testString = 'test'
      assert.is_true(xc.customType(testString) == 'string')
      local testNumber = {1}
      assert.is_true(xc.customType(testNumber) == 'number')
    end)
  
    it("should set and retrieve descriptor values correctly", function()
        local function doStuff()
        end
        local xbc = Controller.new()
        xbc.marco = ''
        xbc:newDescriptor(xbc, "marco", "string")
        xbc.marco = "polo"
        assert.True(type(xbc.marco) == "string")
        assert.is_true(xbc.marco == "polo")
        xbc.numeral = nil
        xbc:newDescriptor(xbc,"numeral","number")
        xbc.numeral = 31337
        assert.is_true(type(xbc.numeral)=="number")
        assert.is_true(xbc.numeral==31337)
        xbc.someSlot = nil
        xbc:newDescriptor(xbc,"someSlot","object")
        xbc.someSlot = xbc:newSlot("doStuff",doStuff)
        assert.is_true(xbc.customType(xbc.someSlot) == "Slot")
        assert.is_true(xbc.someSlot.func == doStuff)
    end)
    

  
  end)
