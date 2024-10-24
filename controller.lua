-- DEV_ONLY_START
require("object")
require("profile")
require("button")
require("thumbstickaxis")

if not mc then
    require("mocks")
    inst = mc.mcGetInstance()
end
-- DEV_ONLY_END

---@class Controller: Type
---@field profile Profile
---@field configValues table
---@field children table
---@field id string
---@field parent Controller
---@field logLevels table
---@field logLevel string
---@field shiftButton string
---@field jogIncrement string
---@field xYReversed string
---@field frequency string
---@field DPad_UP Button
---@field DPad_DOWN Button
---@field DPad_LEFT Button
---@field DPad_RIGHT Button
---@field Btn_START Button
---@field Btn_BACK Button
---@field Btn_LS Button
---@field Btn_RS Button
---@field Btn_LTH Button
---@field Btn_RTH Button
---@field Btn_A Button
---@field Btn_B Button
---@field Btn_X Button
---@field Btn_Y Button
---@field LTR_Val Trigger
---@field RTR_Val Trigger
---@field LTH_Y_Val ThumbstickAxis
---@field LTH_X_Val ThumbstickAxis
---@field RTH_Y_Val ThumbstickAxis
---@field RTH_X_Val ThumbstickAxis
---@field guiMode string
---@field dirtyConfig boolean
Controller = class("Controller", Type)


--- Initialize a new Controller instance.
---@return Controller @The new Controller instance
function Controller:new()
    --self.panel = nil
    self.guiMode = ''
    self.dirtyConfig = false
    self.timer = wx.wxTimer(mcLuaPanelParent, wx.wxID_ANY)
    self.timer:Connect(wx.wxEVT_TIMER, function() self:update() end)
    self.configValues["shiftButton"] = ""
    self.configValues["jogIncrement"] = "0"
    self.configValues["logLevel"] = "0"
    self.configValues["xYReversed"] = "false"
    self.configValues["frequency"] = "0"
---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("DPad_UP", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("DPad_DOWN", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("DPad_LEFT", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("DPad_RIGHT", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_START", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_BACK", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_LS", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_RS", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_LTH", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_RTH", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_A", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_B", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_X", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Button("Btn_Y", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Trigger("LTR_Val", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(Trigger("RTR_Val", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(ThumbstickAxis("LTH_Y_Val", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(ThumbstickAxis("LTH_X_Val", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(ThumbstickAxis("RTH_Y_Val", self))
    ---@diagnostic disable-next-line: undefined-field
    self:addChild(ThumbstickAxis("RTH_X_Val", self))
    self.logLevels = {"ERROR", "WARNING", "INFO", "DEBUG"}
    local profileId = Profile.getLast()
    local profileName = Profile.getProfiles()[profileId]
    self.profile = Profile.new(profileId, profileName, self)
    self.profile:load()
    self:xcCntlLog("Starting Controller loop", 4)
    self.timer:Start(1000 / tonumber(self.configValues.frequency))
    return self
end


--- Retrieve the state of the xbox controller.
function Controller:update()
    if self.configValues.shiftButton ~= "" then
        self[self.configValues.shiftButton]:getState()
    end
    for _, input in ipairs(self.children) do
        if input ~= self.configValues.shiftButton then
            input:getState()
        end
    end
end

function Controller:updateUi()
    self.propertiesPanel:GetSizer():Clear(true)
    self:initUi(self.propertiesPanel)
end

--- Convenience method to map jogging to the DPad, and incremental jogging to the DPad's alternate function.
function Controller:mapSimpleJog()
    self:xcCntlLog(string.format("Value of reversed flag for axis orientation: %s", tostring(self.configValues.xYReversed)), 4)
    self.DPad_UP.configValues.Down = self.configValues.xYReversed == "true" and "Jog Y+" or "Jog X+"
    self.DPad_UP.configValues.Up = self.configValues.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_DOWN.configValues.Down = self.configValues.xYReversed == "true" and "Jog Y-" or "Jog X-"
    self.DPad_DOWN.configValues.Up = self.configValues.xYReversed == "true" and "Jog Y Off" or "Jog X Off"
    self.DPad_RIGHT.configValues.Down = self.configValues.xYReversed == "true" and "Jog X+" or "Jog Y+"
    self.DPad_RIGHT.configValues.Up = self.configValues.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    self.DPad_LEFT.configValues.Down = self.configValues.xYReversed == "true" and "Jog X-" or "Jog Y-"
    self.DPad_LEFT.configValues.Up = self.configValues.xYReversed == "true" and "Jog X Off" or "Jog Y Off"
    if self.configValues.xYReversed then
        self:xcCntlLog("Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad", 3)
    else
        self:xcCntlLog("Standard velocity jogging mapped to D-pad", 3)
    end
    self.DPad_UP.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog Y+" or "Incremental Jog X+"
    self.DPad_DOWN.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog Y-" or "Incremental Jog X-"
    self.DPad_RIGHT.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog X+" or "Incremental Jog Y+"
    self.DPad_LEFT.configValues.altDown = self.configValues.xYReversed == "true" and "Incremental Jog X-" or "Incremental Jog Y-"
    if self.configValues.xYReversed then
        self:xcCntlLog("Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function",
            3)
    else
        self:xcCntlLog("Incremental jogging mapped to D-pad alternate function", 3)
    end
end

--- Logging method for the Controller library
---@param msg string @The message to log
---@param level number @The logging level to display the message at
function Controller:xcCntlLog(msg, level)
    if self.configValues.logLevel == "0" then
        return
    end
    if level <= tonumber(self.configValues.logLevel) then
        if mc.mcInEditor() ~= 1 then
            mc.mcCntlLog(inst, "[[XBOX CONTROLLER " .. self.configValues.logLevels[level] .. "]]: " .. msg, "", -1)
        else
            print("[[XBOX CONTROLLER " .. self.configValues.logLevels[level] .. "]]: " .. msg)
        end
    end
end


--- Retrieve a numeric value from a Mach4 register.
---@param reg string @The register to read format
---@return number|nil @The number retrieved from the register or nil if not found
function Controller:xcGetRegValue(reg)
    local hreg, rc = mc.mcRegGetHandle(inst, reg)
    if rc == mc.MERROR_NOERROR then
        local val, rc = mc.mcRegGetValue(hreg)
        if rc == mc.MERROR_NOERROR then
            return val
        else
            self:xcCntlLog(string.format("Error in mcRegGetValue: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
        end
    else
        self:xcCntlLog(string.format("Error in mcRegGetHandle: %s", mc.mcCntlGetErrorString(inst, rc)), 1)
    end
end


--- Initialize the UI panel for the Controller object.
---@param propertiesPanel userdata @A wxPanel object for the properties panel
---@return userdata @The wxSizer (or subclass thereof) for the properties panel object
function Controller:initUi(propertiesPanel)
    ---@diagnostic disable-next-line: undefined-field
    local propSizer = propertiesPanel:GetSizer()

    local profiles = {}
    for _, name in pairs(Profile.getProfiles()) do
        table.insert(profiles, name)
    end
    local profileLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Current Profile:")
    propSizer:Add(profileLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local profileChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, profiles)
    propSizer:Add(profileChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    profileChoice:SetSelection(profileChoice:FindString(self.profile.name))

    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Connect(profileChoice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
        if self.dirtyConfig then
            local answer = wx.wxMessageBox(
                "You have unsaved changes. Do you want to save before switching profiles?",
                "Unsaved Changes",
                wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION
            )

            if answer == wx.wxYES then
                -- Save the current profile before switching
                self.profile:save()

            elseif answer == wx.wxCANCEL then
                return false  -- Cancel profile swap
            end
        end

        local choice = profileChoice:GetSelection()
        local newId
        for id, name in pairs(profiles) do
            if name == choice then
                newId = id
                break
            end
        end
        self.profile = Profile.new(newId, choice, self)
        self.profile:load()
        self:statusMessage("Profile switched to: " .. choice)
    end)

    local label = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Assign shift button:")
    propSizer:Add(label, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local choices = {""}
    for _, input in ipairs(self.children) do
        if input.__type ~= "ThumbstickAxis" then
            table.insert(choices, input.id)
        end
    end
    local choice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, choices)
    propSizer:Add(choice, 1, wx.wxEXPAND + wx.wxALL, 5)
    choice:SetSelection(choice:FindString(self.configValues.shiftButton))

    propertiesPanel:Connect(choice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
        self.dirtyConfig = true
        self.configValues.shiftButton = choice:GetString(choice:GetSelection())
        self:statusMessage("Shift button set to: " .. choice:GetString(choice:GetSelection()))
    end)

    local jogIncLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Jog Increment:")
    propSizer:Add(jogIncLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local jogIncCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, tostring(self.configValues.jogIncrement), wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(jogIncCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    propertiesPanel:Connect(jogIncCtrl:GetId(), wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        self.dirtyConfig = true
        self.configValues.jogIncrement = tonumber(jogIncCtrl:GetValue())
        self:statusMessage("Jog increment set to: " .. self.configValues.jogIncrement)
    end)

    local logLevels = {"0 - Disabled", "1 - Error", "2 - Warning", "3 - Info", "4 - Debug"}
    local logLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Logging level:")
    propSizer:Add(logLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local logChoice = wx.wxChoice(propertiesPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, logLevels)
    propSizer:Add(logChoice, 1, wx.wxEXPAND + wx.wxALL, 5)
    logChoice:SetSelection(tonumber(self.configValues.logLevel))

    propertiesPanel:Connect(logChoice:GetId(), wx.wxEVT_COMMAND_CHOICE_SELECTED, function()
        self.dirtyConfig = true
        self.configValues.logLevel = logChoice:GetString(logChoice:GetSelection())
        self:statusMessage("Log level set to: " .. self.configValues.logLevel)
    end)

    local swapLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Swap X and Y axes:")
    propSizer:Add(swapLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local swapCheck = wx.wxCheckBox(propertiesPanel, wx.wxID_ANY, "")
    swapCheck:SetValue(self.configValues.xYReversed == "true")
    propSizer:Add(swapCheck, 1, wx.wxALIGN_RIGHT + wx.wxALL, 5)

    propertiesPanel:Connect(swapCheck:GetId(), wx.wxEVT_COMMAND_CHECKBOX_CLICKED, function()
        self.dirtyConfig = true
        self.configValues.xYReversed = swapCheck:GetValue() and "true" or "false"
        self:statusMessage("X and Y axes swapped: " .. self.configValues.xYReversed)
    end)

    local frequencyLabel = wx.wxStaticText(propertiesPanel, wx.wxID_ANY, "Update Frequency (Hz):")
    propSizer:Add(frequencyLabel, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALL, 5)
    local frequencyCtrl = wx.wxTextCtrl(propertiesPanel, wx.wxID_ANY, self.configValues.frequency, wx.wxDefaultPosition,
        wx.wxDefaultSize, wx.wxTE_RIGHT)
    propSizer:Add(frequencyCtrl, 1, wx.wxEXPAND + wx.wxALL, 5)

    propertiesPanel:Connect(frequencyCtrl:GetId(), wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        self.dirtyConfig = true
        self.configValues.frequency = tonumber(frequencyCtrl:GetValue())
        self:statusMessage("Update frequency set to: " .. self.configValues.frequency.. "Hz")
    end)

    propSizer:Add(0, 0, 1, wx.wxEXPAND)
    local mapSimpleJog = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Map Basic Jogging")
    propSizer:Add(mapSimpleJog, 1, wx.wxEXPAND + wx.wxALL, 5)

    propertiesPanel:Connect(mapSimpleJog:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self:mapSimpleJog()
        self:statusMessage("Basic jogging mapped to the DPad.")
    end)


    -- fill up growable row 7 to push profile management buttons down
    propSizer:Add(0, 0, 1, wx.wxEXPAND)
    propSizer:Add(0, 0, 1, wx.wxEXPAND)

    local undo = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Undo Unsaved Changes")
    propSizer:Add(undo, 1, wx.wxEXPAND + wx.wxALL, 5)

    local deleteProfile = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Delete A Profile...")
    propSizer:Add(deleteProfile, 1, wx.wxEXPAND + wx.wxALL, 5)

    local saveProfileAs = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Save Profile As...")
    propSizer:Add(saveProfileAs, 1, wx.wxEXPAND + wx.wxALL, 5)

    local saveProfile = wx.wxButton(propertiesPanel, wx.wxID_ANY, "Save Current Profile")
    propSizer:Add(saveProfile, 1, wx.wxEXPAND + wx.wxALL, 5)

    local buttons = {undo, deleteProfile, saveProfileAs, saveProfile}
    local maxWidth = 0
    for _, button in pairs(buttons) do
        local size = button:GetSize()
        maxWidth = math.max(maxWidth, size:GetHeight())
    end
    for _, button in pairs(buttons) do
        button:SetMinSize(wx.wxSize(-1, maxWidth))
        button:SetSize(wx.wxSize(-1, maxWidth))
    end

    propSizer:Layout()
    propertiesPanel:Layout()

    propertiesPanel:Connect(undo:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local answer = wx.wxMessageBox(
            "Are you sure you want to undo any unsaved changes?",
            "Confirm",
            wx.wxYES_NO + wx.wxICON_QUESTION
        )
        if answer == wx.wxYES then
            self.dirtyConfig = false
            self.profile:load()
            self:updateUi()
            self:statusMessage("Restored profile: " .. self.profile.name)
        else
            return false
        end
    end)

---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Connect(saveProfile:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local saveDialog = wx.wxMessageBox(string.format("Save changes to profile: %s?", profileChoice:GetStringSelection()), "Confirm", wx.wxOK + wx.wxCANCEL)
        if saveDialog == wx.wxOK then
            self.profile:save()
            self:statusMessage(string.format("Changes saved to profile: %s", profileChoice:GetStringSelection()))
        end
    end)
---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Connect(deleteProfile:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local dialog = wx.wxDialog(propertiesPanel, wx.wxID_ANY, "Delete Profile", wx.wxDefaultPosition, wx.wxSize(300, 300), wx.wxDEFAULT_DIALOG_STYLE)
        local vSizer = wx.wxBoxSizer(wx.wxVERTICAL)
        local profileCtlLabel = wx.wxStaticText(dialog, wx.wxID_ANY, "Select a profile:")
        vSizer:Add(profileCtlLabel, 0, wx.wxALL, 5)
        local profileListBox = wx.wxListBox(dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(280, 120), profiles, wx.wxLB_SINGLE)
        vSizer:Add(profileListBox, 0, wx.wxEXPAND + wx.wxALL, 5)

        local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
        local deleteButton = wx.wxButton(dialog, wx.wxID_ANY, "Delete")
        local cancelButton = wx.wxButton(dialog, wx.wxID_CANCEL, "Cancel")
        buttonSizer:Add(deleteButton, 1, wx.wxALL, 5)
        buttonSizer:Add(cancelButton, 1, wx.wxALL, 5)
        vSizer:Add(buttonSizer, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

        dialog:SetSizer(vSizer)
        vSizer:Fit(dialog)

        dialog:Connect(deleteButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            local profileName = profileListBox:GetStringSelection()
            local deleteDialog = wx.wxMessageBox(string.format("Delete profile: %s?", profileName), "Confirm", wx.wxOK + wx.wxCANCEL)
            if deleteDialog == wx.wxOK then
                local profile = Profile.new(Profile:getId(profileName), profileName, self)
                profile:delete()
                self:statusMessage(string.format("Deleted profile: %s", profileName))
            end
            dialog:EndModal(wx.wxOK)
        end)

        dialog:Connect(cancelButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            dialog:EndModal(wx.wxCANCEL)
        end)

        dialog:ShowModal()
        dialog:Destroy()

    end)
---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Connect(saveProfileAs:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        local dialog = wx.wxDialog(propertiesPanel, wx.wxID_ANY, "Save Profile As", wx.wxDefaultPosition, wx.wxSize(300, 300), wx.wxDEFAULT_DIALOG_STYLE)
        local vSizer = wx.wxBoxSizer(wx.wxVERTICAL)
        local profileCtlLabel = wx.wxStaticText(dialog, wx.wxID_ANY, "Select an existing profile:")
        vSizer:Add(profileCtlLabel, 0, wx.wxALL, 5)
        local profileListBox = wx.wxListBox(dialog, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(280, 120), profiles, wx.wxLB_SINGLE)
        profileListBox:SetSelection(profileListBox:FindString(self.profile.name))
        vSizer:Add(profileListBox, 0, wx.wxEXPAND + wx.wxALL, 5)

        local newProfileLabel = wx.wxStaticText(dialog, wx.wxID_ANY, "Or enter a new profile name:")
        vSizer:Add(newProfileLabel, 0, wx.wxALL, 5)
        local newProfileTextCtrl = wx.wxTextCtrl(dialog, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxSize(280, 30))
        vSizer:Add(newProfileTextCtrl, 0, wx.wxEXPAND + wx.wxALL, 5)

        local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
        local saveButton = wx.wxButton(dialog, wx.wxID_SAVE, "Save")
        local cancelButton = wx.wxButton(dialog, wx.wxID_CANCEL, "Cancel")
        buttonSizer:Add(saveButton, 1, wx.wxALL, 5)
        buttonSizer:Add(cancelButton, 1, wx.wxALL, 5)
        vSizer:Add(buttonSizer, 0, wx.wxALIGN_RIGHT + wx.wxALL, 5)

        dialog:SetSizer(vSizer)
        vSizer:Fit(dialog)


        dialog:Connect(saveButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            local selectedProfile = profileListBox:GetStringSelection()
            local newProfileName = newProfileTextCtrl:GetValue()
            local tmpProfileName, tmpProfileId

            if newProfileName ~= "" then
                tmpProfileName = newProfileName
                tmpProfileId = #profiles
                self:xcCntlLog(string.format("Saving as new profile: %s", newProfileName), 3)
            elseif selectedProfile ~= "" then
                for id, profileName in pairs(Profile.getProfiles()) do
                    if profileName == selectedProfile then
                        tmpProfileName = selectedProfile
                        tmpProfileId = id
                        break
                    end
                end
                self:xcCntlLog(string.format("Saving over existing profile: %s", selectedProfile), 3)
            else
                wx.wxMessageBox("Please select a profile or enter a new name", "Error", wx.wxOK + wx.wxICON_ERROR)
            end

            if tmpProfileId and tmpProfileName then
                local saveDialog = wx.wxMessageBox(string.format("Save changes to profile: %s?", tmpProfileName), "Confirm", wx.wxOK + wx.wxCANCEL)
                if saveDialog == wx.wxOK then
                    local tmpProfile = Profile.new(tmpProfileId, tmpProfileName, self)
                    tmpProfile:save()
                    self:statusMessage(string.format("Configuration saved to profile: %s", tmpProfileName))
                else
                    do end
                end
            end
            dialog:EndModal(wx.wxID_SAVE)
        end)

        dialog:Connect(cancelButton:GetId(), wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
            dialog:EndModal(wx.wxID_CANCEL)
        end)

        -- Show the dialog
        dialog:ShowModal()
        dialog:Destroy()
    end)

    -- Trigger the layout update and return the new sizer
    propSizer:Layout()
    ---@diagnostic disable-next-line: undefined-field
    propertiesPanel:Layout()
    return propSizer
end

--- Initialize the configuration GUI.
---@param mode string @One of 'embedded', 'wizard', or 'standalone' - the mode to run the GUI in.
function Controller:initPanel(mode)
    self.guiMode = mode
    local guiPanel
    if mode == "embedded" or mode == "wizard" then
        guiPanel = mcLuaPanelParent
    else
        guiPanel = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Configure Xbox Controller Settings")
    end
    self.panel = guiPanel
    if self.guiMode ~= "embedded" then
        guiPanel:CreateStatusBar(1)
    end
    local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    guiPanel:SetMinSize(wx.wxSize(450, 500))
    guiPanel:SetMaxSize(wx.wxSize(450, 500))

    local treeBox = wx.wxStaticBox(guiPanel, wx.wxID_ANY, "Controller Tree Manager")
    local treeSizer = wx.wxStaticBoxSizer(treeBox, wx.wxVERTICAL)
    local tree = wx.wxTreeCtrl.new(guiPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(100, -1),
        wx.wxTR_HAS_BUTTONS, wx.wxDefaultValidator, "tree")
    local root_id = tree:AddRoot("Controller")
    local treedata = {
        [root_id:GetValue()] = self
    }

    for i = 1, #self.children do
        local child_id = tree:AppendItem(root_id, self.children[i].id)
        treedata[child_id:GetValue()] = self.children[i]
    end
    tree:ExpandAll()
    treeSizer:Add(tree, 1, wx.wxEXPAND + wx.wxALL, 5)
    local propBox = wx.wxStaticBox(guiPanel, wx.wxID_ANY, "Properties")
    local propSizer = wx.wxStaticBoxSizer(propBox, wx.wxVERTICAL)
    self.propertiesPanel = wx.wxPanel(guiPanel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
    local sizer = wx.wxFlexGridSizer(0, 2, 0, 0) -- 2 columns, auto-adjust rows
    sizer:AddGrowableCol(1, 1)
    self.propertiesPanel:SetSizer(sizer)
    self.propertiesPanel:Layout()
    local font = wx.wxFont(8, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL)
    self.propertiesPanel:SetFont(font)
    propBox:SetFont(font)
    treeBox:SetFont(font)
    tree:SetFont(font)
    propSizer:Add(self.propertiesPanel, 1, wx.wxEXPAND + wx.wxALL, 5)
    tree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, function(event)
        self.propertiesPanel:GetSizer():Clear(true)

        local item = treedata[event:GetItem():GetValue()]
        local newSizer =  wx.wxFlexGridSizer(0, 2, 0, 0)
        newSizer:AddGrowableCol(1, 1)

        if item == self then
            newSizer:AddGrowableRow(7,1)
        end
        self.propertiesPanel:SetSizer(newSizer)

        self.propertiesPanel:SetSizer(item:initUi(self.propertiesPanel))

        self.propertiesPanel:Layout()
    end)
    mainSizer:Add(treeSizer, 0, wx.wxEXPAND + wx.wxALL, 5)
    mainSizer:Add(propSizer, 1, wx.wxEXPAND + wx.wxALL, 5)
    guiPanel:SetSizer(mainSizer)
    mainSizer:Layout()

    function Controller.go()
        guiPanel:Connect(wx.wxEVT_CLOSE_WINDOW, function()
            if self.dirtyConfig then
                local answer = wx.wxMessageBox(
                    "You have unsaved changes to your controller profile. Do you want to save before exiting? (If you exit without saving, your applied changes will remain applied for the current session.)",
                    "Unsaved Changes",
                    wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION
                )
    
                if answer == wx.wxYES then
                    -- Save the current profile
                    self.profile:save()
                elseif answer == wx.wxCANCEL then
                    return false  -- Cancel closing the window
                end
            end
           
            guiPanel:Destroy()
            
            wx.wxGetApp():ExitMainLoop()
            self.go = function() end
        end)

        local app = wx.wxApp(false)
        wx.wxGetApp():SetTopWindow(guiPanel)
        guiPanel:Show(true)
        wx.wxGetApp():MainLoop()
    end

    self:go()
end

function Controller:statusMessage(msg)
    if self.guiMode == "embedded" then
        mc.mcCntlSetLastError(inst, msg)
    else
        self.panel:SetStatusText(msg)
    end
end

function Controller:destroy()
    if self.timer then
        self.timer:Stop()
        self.timer = nil
    end

    if self.dirtyConfig then
        local choice = wx.wxMessageBox(
            "You have unsaved changes. Do you want to save before exiting?",
            "Unsaved Changes",
            wx.wxYES_NO + wx.wxICON_QUESTION
        )

        if choice == wx.wxYES then
            self.profile:save()
        elseif choice == wx.wxNO then
        end
    end
end

-- DEV_ONLY_START
return {Controller = Controller}
-- DEV_ONLY_END