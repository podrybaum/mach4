-- DEV_ONLY_START
if not mc then
    local home = os.getenv("USERPROFILE")
    package.path = string.format("%s;%s\\mach4\\?.lua;", package.path, home)
    package.cpath = string.format("%s;C:\\Mach4Hobby\\ZeroBraneStudio\\bin\\clibs53\\?.dll", package.cpath)
    package.cpath = string.format("%s;.\\build\\?.dll", package.cpath)
    require("mocks")
end

if mc.mcInEditor() == 1 then -- needed for ZeroBraneStudio in Mach4, where mocks won't be loaded.
    mcLuaPanelParent = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Mock Panel")
end

-- TODO: implement more user-friendly names for inputs to use in the GUI
-- TODO: installer script
-- TODO: Something seems to be not working entirely as intended with ThumbstickAxis:connect method. The Jog rate doesn't seem to always update appropriately.
-- TODO: update docs 
-- TODO: prompt for saving unsaved changes on exiting mach4

require("object")
require("profile")
require("button")
require("thumbstickaxis")
require("controller")
-- DEV_ONLY_END

xc=Controller("xc",nil)
--[[
xc:initPanel('embedded')
--]]
-- DEV_ONLY_START
if mc.mcInEditor() == 1 then
    xc:initPanel('standalone')
end
-- DEV_ONLY_END

return { xc = xc }

