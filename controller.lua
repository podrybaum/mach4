require("object")
require("button")
require("thumbstickaxis")

Controller = setmetatable({}, Object)
Controller.__type = "Controller"
Controller.__index = Controller

function Controller:new()
    self = Object:new(self, "xc")
    self.profileId = 0
    table.insert(self.configValues, {"shiftButton", nil})
    table.insert(self.configValues, {"jogIncrement", 0})
    table.insert(self.configValues, {"logLevel", 0})
    table.insert(self.configValues, {"xYReversed", false})
    table.insert(self.configValues, {"frequency", 0})
    table.insert(self.configValues, {"simpleJogMapped", false})
    self:addChild(Button:new(self, "DPad_UP"))
    self:addChild(Button:new(self, "DPad_DOWN"))
    self:addChild(Button:new(self, "DPad_LEFT"))
    self:addChild(Button:new(self, "DPad_RIGHT"))
    self:addChild(Button:new(self, "Btn_START"))
    self:addChild(Button:new(self, "Btn_BACK"))
    self:addChild(Button:new(self, "Btn_LS"))
    self:addChild(Button:new(self, "Btn_RS"))
    self:addChild(Button:new(self, "Btn_LTH"))
    self:addChild(Button:new(self, "Btn_RTH"))
    self:addChild(Button:new(self, "Btn_A"))
    self:addChild(Button:new(self, "Btn_B"))
    self:addChild(Button:new(self, "Btn_X"))
    self:addChild(Button:new(self, "Btn_Y"))
    self:addChild(Trigger:new(self, "LTR_Val"))
    self:addChild(Trigger:new(self, "RTR_Val"))
    self:addChild(ThumbstickAxis:new(self, "LTH_Y_Val"))
    self:addChild(ThumbstickAxis:new(self, "LTH_X_Val"))
    self:addChild(ThumbstickAxis:new(self, "RTH_Y_Val"))
    self:addChild(ThumbstickAxis:new(self, "RTH_X_Val"))
    self.logLevels = {"ERROR", "WARNING", "INFO", "DEBUG"}
    return self
end