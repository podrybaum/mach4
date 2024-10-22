-- DEV_ONLY_START
-- Development environment specific hacks

if not mc then
    local home = os.getenv("USERPROFILE")
    package.path = string.format("%s;%s\\mach4\\?.lua;", package.path, home)
    package.cpath = string.format("%s;C:\\Mach4Hobby\\ZeroBraneStudio\\bin\\clibs53\\?.dll", package.cpath)
    require("mocks")
end
scr = scr or require("scr")
wx = wx or require("wx")

if mc.mcInEditor() == 1 then
    local luaPanelId = wx.wxNewId()
    mcLuaPanelParent = wx.wxFrame(wx.NULL, luaPanelId, "Mock Panel")
end

-- TODO: implement more user-friendly names for inputs to use in the GUI
-- TODO: make ui controls for profiles update dynamically 
-- TODO: test slot functions provided by scr.DoFunctionName.
-- TODO: review and decide on final version of default profile.
-- TODO: installer script
-- TODO: Something seems to be not working entirely as intended with ThumbstickAxis:connect method. The Jog rate doesn't seem to always update appropriately.
-- TODO: update docs 

-- DEV_ONLY_END

require("controller")
inst = mc.mcGetInstance()
xc=Controller("xc",nil,mcLuaPanelParent)

if mc.mcInEditor() == 1 then
    xc:initPanel()
    xc:go()
end

return {
    xc = xc
}

