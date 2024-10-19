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
-- TODO: test slot functions provided by scr.DoFunctionName.
-- TODO: unit tests
-- TODO: installer script
-- TODO: Something seems to be not working entirely as intended with ThumbstickAxis:connect method. The Jog rate doesn't seem to always update appropriately.
-- TODO: update docs 

-- DEV_ONLY_END
-- Import needed modules.
require("controller")


-- Global Mach4 instance
inst = mc.mcGetInstance()

xc = Controller("xc")
---------------------------------
--- Custom Configuration Here ---

--[[   xc.logLevel = 4
    xc:assignShift(xc.LTR)
    xc.RTH_Y:connect(mc.Z_AXIS)
    xc.xYReversed = true
    print(xc.profileName, xc.simpleJogMapped)
    if xc.profileName == 'default' and not xc.simpleJogMapped then

        xc:mapSimpleJog()
    end
    xc.B.Down:connect(xc:xcGetSlotById('E Stop Toggle'))
    --xc.Y.down:connect(xc.xcCntlTorchToggle)
    xc.RSB.Down:connect(xc:xcGetSlotById('Enable Toggle'))
    xc.X.Down:connect(xc:xcGetSlotById('XC Run Cycle Toggle'))
    xc.BACK.AltDown:connect(xc:xcGetSlotById('Home All'))
    --xc.START.altDown:connect(xc:xcGetSlotById('Home Z'))

   ]] -- xc:createProfile("default")
-- End of custom configuration ---
----------------------------------
local mcLuaPanelParent = mcLuaPanelParent
local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
mcLuaPanelParent:SetMinSize(wx.wxSize(450, 500))
mcLuaPanelParent:SetMaxSize(wx.wxSize(450, 500))

local treeBox = wx.wxStaticBox(mcLuaPanelParent, wx.wxID_ANY, "Controller Tree Manager")
local treeSizer = wx.wxStaticBoxSizer(treeBox, wx.wxVERTICAL)
local tree = wx.wxTreeCtrl.new(mcLuaPanelParent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(100, -1),
    wx.wxTR_HAS_BUTTONS, wx.wxDefaultValidator, "tree")
local root_id = tree:AddRoot(xc.id)
local treedata = {
    [root_id:GetValue()] = xc
}

for i = 1, #xc.children do
    local child_id = tree:AppendItem(root_id, xc.children[i].id)
    treedata[child_id:GetValue()] = xc.children[i]
end
tree:ExpandAll()
treeSizer:Add(tree, 1, wx.wxEXPAND + wx.wxALL, 5)
local propBox = wx.wxStaticBox(mcLuaPanelParent, wx.wxID_ANY, "Properties")
local propSizer = wx.wxStaticBoxSizer(propBox, wx.wxVERTICAL)
propertiesPanel = wx.wxPanel(mcLuaPanelParent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
local sizer = wx.wxFlexGridSizer(0, 2, 0, 0) -- 2 columns, auto-adjust rows
sizer:AddGrowableCol(1, 1)
propertiesPanel:SetSizer(sizer)
propertiesPanel:Layout()
local font = wx.wxFont(8, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL)
propertiesPanel:SetFont(font)
propBox:SetFont(font)
treeBox:SetFont(font)
tree:SetFont(font)
propSizer:Add(propertiesPanel, 1, wx.wxEXPAND + wx.wxALL, 5)
tree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, function(event)
    propertiesPanel:GetSizer():Clear(true)
    local item = treedata[event:GetItem():GetValue()]
    propertiesPanel:SetSizer(item:initUi(propertiesPanel))
    propertiesPanel:Fit()
    propertiesPanel:Layout()
end)
mainSizer:Add(treeSizer, 0, wx.wxEXPAND + wx.wxALL, 5)
mainSizer:Add(propSizer, 1, wx.wxEXPAND + wx.wxALL, 5)
mcLuaPanelParent:SetSizer(mainSizer)
mainSizer:Layout()

function Controller.go()
    xc:xcCntlLog("Creating X360_timer", 4)
    X360_timer = wx.wxTimer(mcLuaPanelParent)
    mcLuaPanelParent:Connect(wx.wxEVT_TIMER, function()
        xc:update()
    end)
    xc:xcCntlLog("Starting X360_timer", 4)
    X360_timer:Start(1000 / xc.configValues.frequency)

    mcLuaPanelParent:Connect(wx.wxEVT_CLOSE_WINDOW, function(event)

        -- Stop the timer if running
        if X360_timer then
            X360_timer:Stop()
            X360_timer = nil
        end

        -- Destroy the window to clean up
        mcLuaPanelParent:Destroy()

        -- Call this to make sure the event loop exits
        wx.wxGetApp():ExitMainLoop()
    end)
    local app = wx.wxApp(false)
    wx.wxGetApp():SetTopWindow(mcLuaPanelParent)
    mcLuaPanelParent:Show(true)
    wx.wxGetApp():MainLoop()
end

if mc.mcInEditor() == 1 then
   xc.go()
end
return {
    xc = xc
}

