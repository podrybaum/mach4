-- DEV_ONLY_START
if not mc then
    local home = os.getenv("USERPROFILE")
    package.path = string.format("%s;%s\\mach4\\?.lua;", package.path, home)
    package.cpath = string.format("%s;C:\\Mach4Hobby\\ZeroBraneStudio\\bin\\clibs53\\?.dll", package.cpath)
    require("mocks")
end

if mc.mcInEditor() == 1 then
    mcLuaPanelParent = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Mock Panel")
end

-- TODO: implement more user-friendly names for inputs to use in the GUI
-- TODO: make ui controls for profiles update dynamically 
-- TODO: installer script
-- TODO: Something seems to be not working entirely as intended with ThumbstickAxis:connect method. The Jog rate doesn't seem to always update appropriately.
-- TODO: update docs 
require("object")
require("profile")
require("button")
require("thumbstickaxis")
require("controller")
-- DEV_ONLY_END

xc=Controller("xc",nil,mcLuaPanelParent)

-- DEV_ONLY_START
if mc.mcInEditor() == 1 then
    xc:initPanel()
    xc:go()
end
-- DEV_ONLY_END

return { xc = xc }

