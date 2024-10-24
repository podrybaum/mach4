function string.split(a,...)local b={...}local c=b[1]or'%s'local d={}local e=1
while a do local f,g=string.match(a,string.format('(.-)%s+(.*)',c))if f then d[e
]=f a=g e=e+1 else d[e]=a break end end return d end function string.lstrip(a,
...)local b={...}return a:match(string.format('^[%s]+(.+)',b[1]or'%s'))end
function string.rstrip(a,...)local b={...}return a:match(string.format(
'^(.-)[%s]+',b[1]or'%s'))end function string.strip(a,...)local b={...}return a:
lstrip(b[1]or'%s'):rstrip(b[1]or'%s')end function string.startswith(a,b)return a
:sub(1,#b)==b end function string.endswith(a,b)return a:sub(-#b)==b end if mc
then inst=mc.mcGetInstance()end function pairsByKeys(a,b)local c={}for d in
pairs(a)do c[#c+1]=d end table.sort(c,b)local e=0 local f=#c local g=function()e
=e+1 if e>f then return nil else return c[e],a[c[e] ]end end return g end
function sortConfig(a,b)if a==b then return false end if a=='Down'then return
true elseif a=='altDown'then return(b=='Up'or b=='altUp')elseif a=='Up'then
return not(b=='Down'or b=='altDown')elseif a=='altUp'then return false end
return a<b end function class(a,b)local c={}c.__super=b or Type setmetatable(c,c
.__super)c.__index=c c.__type=a c.__name=a mt=getmetatable(c)c.__tostring=
function(e)if rawget(e,'id')then return e.id end if rawget(e,'__super')~=nil
then if rawget(e,'__super')==Type then return string.format(
'Class: %s - Inherits from Type',rawget(e,'__name'))else return string.format(
'Class: %s - Inherits from %s',rawget(e,'__name'),rawget(e,'__super'))end else
return string.format('Class: %s',rawget(e,'__name'))end end mt.__call=function(e
,f,...)if e.id~=nil then error'Attempt to call an instance object.'end local g={
...}local h if e.__super.__name~='Type'then h=setmetatable(e.__super.new(
Instance:new(f,g[1])),e)else h=setmetatable(Instance:new(f,g[1]),e)end table.
remove(g,1)if#g>0 then return e.new(h,table.unpack(g))else return e.new(h)end
end return c end Type={}setmetatable(Type,{__index=nil})Type.__index=Type Type.
__type='Class'Type.__name='Type'function Type.isInstance(a,b)local c=
getmetatable(a)if rawget(a,'id')then while true do if c.__type==b.__name then
return true end c=rawget(c,'__super')if c==Type then return false end end else
return b==Type end end Instance={}function Instance.new(a,b,c)a={}a.parent=c or
a a.id=b a.configValues={}a.children={}a.addChild=Instance.addChild a.serialize=
Instance.serialize a.deserialize=Instance.deserialize a.getRoot=Instance.getRoot
a.getPath=Instance.getPath return a end function Instance.getPath(a)if a.parent
==a then return a.id else return string.format('%s.%s',a.parent:getPath(),a.id)
end end Instance.addChild=function(a,b)table.insert(a.children,b)a[b.id]=b end
function Instance.serialize(a)local b=''for c,e in pairsByKeys(a.configValues,
sortConfig)do if e~=''then b=b..a:getPath()..'.configValues.'..c..'='..e..'\n'
end end for f,g in ipairs(a.children)do for h,i in pairs(g:serialize())do b=b..h
..'='..i..'\n'end end local h={}for i in b:gmatch'[^\n]+'do local j,k=i:match
'^(.-)%s*=%s*(.-)%s*$'if j and k then h[j]=k end end return h end function
Instance.deserialize(a,b,c)if b=='profileName'then return end b=b:lstrip(a.id):
lstrip'%.'local e=b:match'^(.-)[%.%s%=]'if e=='configValues'then b=b:lstrip
'configValues':lstrip'%.'a.configValues[b]=c return else for f,g in ipairs(a.
children)do if g.id==e then return g:deserialize(b,c)end end end end function
Instance.getRoot(a)if a.parent==a then return a else return a.parent:getRoot()
end end local a if mc then a='C:\\Mach4Hobby\\Profiles\\'..mc.mcProfileGetName(
inst)..'\\xbcontroller.ini'end Profile={}Profile.__index=Profile Profile.__type=
'Profile'Profile.__tostring=function(b)local c='[ControllerProfile-'..b.id..
']\n'for e,f in pairs(b.profileData)do c=c..string.format('%s=%s\n',e,f)end
return c end function Profile.new(b,c,e)local f=setmetatable({},Profile)f.id=b f
.name=c f.controller=e f.iniFile=a file=io.open(f.iniFile,'r+')if not file then
f.writeDefault(f.iniFile)else file:close()end f.profileData={}f.profileData.
profileName=f.name return f end function Profile.getId(b,c)for e,f in pairs(b.
getProfiles())do if f==c then return e end end end function Profile.exists(b)
local c=io.open(b.iniFile,'r+')if not c then error
'ini file is missing or corrupted!'else for e in c:lines()do if e==string.
format('[ControllerProfile-%s]',b.id)then c:close()return true end end end c:
close()return false end function Profile.write(b)if b:exists()then b:delete()b:
write()else local c=io.open(b.iniFile,'r+')if not c then error
'ini file is missing or corrupted!'else c:seek'end'c:write(string.format(
'\n[ControllerProfile-%s]\nprofileName=%s\n',b.id,b.name))for e,f in
pairsByKeys(b.profileData,sortConfig)do c:write(string.format('%s=%s\n',e,f))end
c:write'\n'c:close()end end end function Profile.delete(b)local c=io.open(b.
iniFile,'r+')if not c then error'ini file is missing or corrupted!'else local e=
{}local f=false for g in c:lines()do if not f and not g:startswith(string.
format('[ControllerProfile-%s]',b.id))then table.insert(e,g)elseif g:startswith(
string.format('[ControllerProfile-%s]',b.id))then f=true elseif f and g:
startswith' 'or g==''then f=false end end c:close()c=io.open(b.iniFile,'w')if c
then for h,i in ipairs(e)do c:write(i..'\n')end c:close()end end end function
Profile.load(b)b.controller:xcCntlLog('Loading profile: '..b.name,4)if b.
controller.dirtyConfig then b.controller.dirtyConfig=false end local c=io.open(b
.iniFile,'r+')local e={}if not c then error'ini file is missing or corrupted!'
else local f=false for g in c:lines()do if g:startswith'lastProfile='then table.
insert(e,'lastProfile='..b.id)else table.insert(e,g)if not f and g:startswith(
string.format('[ControllerProfile-%s]',b.id))then f=true elseif f and not g:
match'^%s*$'then local h,i=g:match'^(.-)=(.+)$'if h and i then b.profileData[h]=
i end end end end c:close()c=io.open(b.iniFile,'w')if c then for h,i in ipairs(e
)do c:write(i..'\n')end c:close()end end for f,g in pairs(b.profileData)do b.
controller:deserialize(f,g)end end function Profile.getLast(b)b=b or a local c=
io.open(b,'r')if not c then error'ini file is missing or corrupted!'else for e
in c:lines()do if e:match'^lastProfile=.*$'then c:close()return e:match
'^lastProfile=(.*)$'end end end c:close()end function Profile.writeDefault(b)b=b
or a local c=io.open(b,'w')local e=
'[XBC4MACH4]\r\nlastProfile=0\r\n[ControllerProfile-0]\r\nprofileName=default\r\nxc.Btn_B.configValues.Down=E Stop Toggle\r\nxc.Btn_BACK.configValues.altDown=Home Z\r\nxc.Btn_RS.configValues.Down=Enable Toggle\r\nxc.Btn_START.configValues.altDown=Home All\r\nxc.Btn_X.configValues.Down=Cycle Start/Stop\r\nxc.DPad_DOWN.configValues.Down=Jog Y-\r\nxc.DPad_DOWN.configValues.Up=Jog Y Off\r\nxc.DPad_DOWN.configValues.altDown=xcJogIncDown\r\nxc.DPad_LEFT.configValues.Down=Jog X-\r\nxc.DPad_LEFT.configValues.Up=Jog X Off\r\nxc.DPad_LEFT.configValues.altDown=xcJogIncLeft\r\nxc.DPad_RIGHT.configValues.Down=Jog X+\r\nxc.DPad_RIGHT.configValues.Up=Jog X Off\r\nxc.DPad_RIGHT.configValues.altDown=xcJogIncRight\r\nxc.DPad_UP.configValues.Down=Jog Y+\r\nxc.DPad_UP.configValues.Up=Jog Y Off\r\nxc.DPad_UP.configValues.altDown=xcJogIncUp\r\nxc.LTH_X_Val.configValues.deadzone=10\r\nxc.LTH_X_Val.configValues.inverted=false\r\nxc.LTH_Y_Val.configValues.deadzone=10\r\nxc.LTH_Y_Val.configValues.inverted=false\r\nxc.RTH_X_Val.configValues.deadzone=10\r\nxc.RTH_X_Val.configValues.inverted=false\r\nxc.RTH_Y_Val.configValues.axis=2\r\nxc.RTH_Y_Val.configValues.deadzone=10\r\nxc.RTH_Y_Val.configValues.inverted=false\r\nxc.configValues.frequency=4\r\nxc.configValues.jogIncrement=0.1\r\nxc.configValues.logLevel=2.0\r\nxc.configValues.shiftButton=Btn_Y\r\nxc.configValues.xYReversed=true'
if c then c:write(e)c:close()else error'Could not write default profile'end end
function Profile.save(b)b.profileData=b.controller:serialize()b:write()if b.
controller.dirtyConfig then b.controller.dirtyConfig=false end end function
Profile.getProfiles(b)b=b or a local c=io.open(b,'r')local e={}local f,g if not
c then error'ini file is missing or corrupted!'else for h in c:lines()do if h:
match'^%[ControllerProfile-.*%]$'then f=h:match'^%[ControllerProfile%-(%d+)%]$'
end if h:match'^profileName=.*$'then g=h:match'^profileName=(.*)$'e[f]=g end end
c:close()return e end end local function getMachSignalState(b)local c,e=mc.
mcSignalGetHandle(inst,b)if e==mc.MERROR_NOERROR then local f,g=mc.
mcSignalGetState(c)if g==mc.MERROR_NOERROR then return f>0 end end end
local function toggleMachSignalState(b)local c,e=mc.mcSignalGetHandle(inst,b)if
e==mc.MERROR_NOERROR then mc.mcSignalSetState(c,not mc.mcSignalGetState(inst,c))
end end local b={'Cycle Start','Cycle Stop','Feed Hold','Enable On',
'Soft Limits On','Soft Limits Off','Soft Limits Toggle','Position Remember',
'Position Return','Limit OV On','Limit OV Off','Limit OV Toggle',
'Jog Mode Toggle','Jog Mode Step','Jog Mode Continuous','Jog X Off','Jog Y Off',
'Jog Z Off','Jog A Off','Jog B Off','Jog C Off','Jog X+','Jog Y+','Jog Z+',
'Jog A+','Jog B+','Jog C+','Jog X-','Jog Y-','Jog Z-','Jog A-','Jog B-','Jog C-'
,'Home All','Home X','Home Y','Home Z','Home A','Home B','Home C'}local c={}for
e,f in ipairs(b)do c[f]=function()scr.DoFunctionName(f)end end c[
'Incremental Jog X+']=function(g)mc.mcJogIncStart(inst,mc.X_AXIS,g)end c[
'Incremental Jog Y+']=function(g)mc.mcJogIncStart(inst,mc.Y_AXIS,g)end c[
'Incremental Jog Z+']=function(g)mc.mcJogIncStart(inst,mc.Z_AXIS,g)end c[
'Incremental Jog A+']=function(g)mc.mcJogIncStart(inst,mc.A_AXIS,g)end c[
'Incremental Jog B+']=function(g)mc.mcJogIncStart(inst,mc.B_AXIS,g)end c[
'Incremental Jog C+']=function(g)mc.mcJogIncStart(inst,mc.C_AXIS,g)end c[
'Incremental Jog X-']=function(g)mc.mcJogIncStart(inst,mc.X_AXIS,-1*g)end c[
'Incremental Jog Y-']=function(g)mc.mcJogIncStart(inst,mc.Y_AXIS,-1*g)end c[
'Incremental Jog Z-']=function(g)mc.mcJogIncStart(inst,mc.Z_AXIS,-1*g)end c[
'Incremental Jog A-']=function(g)mc.mcJogIncStart(inst,mc.A_AXIS,-1*g)end c[
'Incremental Jog B-']=function(g)mc.mcJogIncStart(inst,mc.B_AXIS,-1*g)end c[
'Incremental Jog C-']=function(g)mc.mcJogIncStart(inst,mc.C_AXIS,-1*g)end c[
'Enable Off']=function()local g=mc.mcCntlGetState(inst)if(g~=mc.MC_STATE_IDLE)
then scr.StartTimer(2,250,1)end scr.DoFunctionName'Enable Off'end c[
'Enable Toggle']=function()if getMachSignalState(mc.OSIG_MACHINE_ENABLED)then c[
'Enable On']()else c['Enable Off']()end end c['E Stop Toggle']=
toggleMachSignalState(mc.ISIG_EMERGENCY)c['Go To Work Zero']=function()mc.
mcCntlGotoZero(inst)end local g,h=pcall(require,'slot_functions')if g then for i
,j in pairs(h)do c[i]=j end end Button=class('Button',Type)function Button.new(i
)i.pressed=false i.configValues.Up=''i.configValues.Down=''i.configValues.altUp=
''i.configValues.altDown=''return i end function Button.getState(i)local j=i.
parent:xcGetRegValue(string.format('mcX360_LUA/%s',i.id))if type(j)~='number'
then i.parent:xcCntlLog(string.format('Invalid state for %s',i.id),1)return end
if(j==1)and(not i.pressed)then i.pressed=true if i.parent.configValues.
shiftButton~=i then if not i.parent.configValues.shiftButton or not i.parent[i.
parent.configValues.shiftButton].pressed then if i.configValues.Down~=''then c[i
.configValues.Down]()end else if i.configValues.altDown~=''then c[i.configValues
.altDown]()end end end elseif(j==0)and i.pressed then i.pressed=false if i.
parent.configValues.shiftButton~=i then if not i.parent.configValues.shiftButton
or not i.parent[i.parent.configValues.shiftButton].pressed then c[i.configValues
.Up]()else c[i.configValues.altUp]()end end end end function Button.initUi(i,j)
local k=j:GetSizer()if not(i.id==i.parent.configValues.shiftButton)then local l=
{''}local m={''}for n,o in pairsByKeys(c)do l[#l+1]=n end local p={}for q,r in
pairsByKeys(i.configValues,sortConfig)do local s=wx.wxStaticText(j,wx.wxID_ANY,
string.format('%s Action:',q))k:Add(s,0,wx.wxALIGN_LEFT+wx.wxALL,5)local t if i:
isInstance(Trigger)then t=m else t=l end local u=wx.wxChoice(j,wx.wxID_ANY,wx.
wxDefaultPosition,wx.wxDefaultSize,t)p[q]=u if i.configValues[q]~=''then u:
SetSelection(u:FindString(i.configValues[q]))end k:Add(u,1,wx.wxEXPAND+wx.wxALL,
5)j:Connect(u:GetId(),wx.wxEVT_COMMAND_CHOICE_SELECTED,function()i:getRoot().
dirtyConfig=true i.configValues[q]=u:GetString(u:GetSelection())i:getRoot():
statusMessage(string.format('%s set to: %s',q,i.configValues[q]))end)end j:
Layout()j:Refresh()return k else local l=wx.wxStaticText(j,wx.wxID_ANY,
'This input is currently assigned as the shift button.')k:Add(0,0)k:Add(l,0,wx.
wxALIGN_LEFT+wx.wxALL,5)return k end end Trigger=class('Trigger',Button)function
Trigger.new(i)i.value=0 i.configValues.analog=''return i end function Trigger.
getState(i)local j=i.parent:xcGetRegValue(string.format('mcX360_LUA/%s',i.id))if
j~=nil then i.value=j end if type(i.value)~='number'then i.parent:xcCntlLog(
'Invalid state for '..i.id,1)return end if i.value>0 and i.configValues.analog~=
''then c[i.configValues.analog](i.value)return end if i.value>0 and(not i.
pressed)then i.pressed=true if i.parent.configValues.shiftButton~=i then if not
i.parent.configValues.shiftButton or not i.parent[i.parent.configValues.
shiftButton].pressed then if i.configValues.Down~=''then c[i.configValues.Down](
)end else if i.configValues.altDown~=''then c[i.configValues.altDown]()end end
end elseif i.value==0 and i.pressed then i.pressed=false if i.parent.
configValues.shiftButton~=i then if not i.parent.configValues.shiftButton or not
i.parent[i.parent.configValues.shiftButton].pressed then if i.configValues.Up~=
''then c[i.configValues.Up]()end else if i.configValues.altUp~=''then c[i.
configValues.altUp]()end end end end end ThumbstickAxis=class('ThumbstickAxis',
Type)function ThumbstickAxis.new(i)i.configValues.axis=''i.configValues.inverted
='false'i.configValues.deadzone='10'i.rate=0 i.value=0 i.moving=false i.rateSet=
false return i end function ThumbstickAxis.getState(i)if i.configValues.axis==
nil then return end local j=i.parent:xcGetRegValue(string.format('mcX360_LUA/%s'
,i.id))if j~=nil then i.value=j end if type(i.value)~='number'then i.parent:
xcCntlLog('Invalid value for ThumbstickAxis',1)return end if not i.moving and
not i.rateReset then if mc.mcJogGetRate(inst,i.configValues.axis)~=i.rate then
mc.mcJogSetRate(inst,i.configValues.axis,i.rate)i.rateReset=true end end if math
.abs(i.value)>tonumber(i.configValues.deadzone)and not i.moving then i.moving=
true i.rateReset=false mc.mcJogSetRate(inst,i.configValues.axis,math.abs(i.value
))local k=1 if i.configValues.inverted then k=(i.value>0)and mc.MC_JOG_NEG or mc
.MC_JOG_POS else k=(i.value>0)and mc.MC_JOG_POS or mc.MC_JOG_NEG end mc.
mcJogVelocityStart(inst,i.configValues.axis,k)end if math.abs(i.value)<tonumber(
i.configValues.deadzone)and i.moving then mc.mcJogVelocityStop(inst,i.
configValues.axis)i.moving=false mc.mcJogSetRate(inst,i.configValues.axis,i.rate
)i.rateReset=true end end function ThumbstickAxis.initUi(i,j)local k=j:GetSizer(
)local l=wx.wxStaticText(j,wx.wxID_ANY,'Thumbstick deadzone:')k:Add(l,0,wx.
wxALIGN_CENTER_VERTICAL+wx.wxALL,5)local m=wx.wxTextCtrl(j,wx.wxID_ANY,i.
configValues.deadzone,wx.wxDefaultPosition,wx.wxDefaultSize,wx.wxTE_RIGHT)m:
SetValue(i.configValues.deadzone)k:Add(m,1,wx.wxEXPAND+wx.wxALL,5)j:Connect(m:
GetId(),wx.wxEVT_COMMAND_TEXT_UPDATED,function()i:getRoot().dirtyConfig=true i.
configValues.deadzone=m:GetValue()i:getRoot():statusMessage(
'Update deadzone set to: '..i.configValues.deadzone)end)local n=wx.wxStaticText(
j,wx.wxID_ANY,'Connect to axis:')k:Add(n,0,wx.wxALIGN_CENTER_VERTICAL+wx.wxALL,5
)local p={'mc.X_AXIS','mc.Y_AXIS','mc.Z_AXIS','mc.A_AXIS','mc.B_AXIS',
'mc.C_AXIS',''}local q=wx.wxChoice(j,wx.wxID_ANY,wx.wxDefaultPosition,wx.
wxDefaultSize,p)k:Add(q,1,wx.wxEXPAND+wx.wxALL,5)q:SetSelection(tonumber(i.
configValues.axis)or 7)j:Connect(q:GetId(),wx.wxEVT_COMMAND_CHOICE_SELECTED,
function()i:getRoot().dirtyConfig=true i.configValues.axis=q:GetString(q:
GetSelection())i:getRoot():statusMessage('Axis set to: '..q:GetString(q:
GetSelection()))end)k:Add(0,0)local r=wx.wxCheckBox(j,wx.wxID_ANY,'Invert axis:'
,wx.wxDefaultPosition,wx.wxDefaultSize,wx.wxALIGN_RIGHT)r:SetValue(i.
configValues.inverted=='true')k:Add(r,1,wx.wxEXPAND+wx.wxALL,5)j:Connect(r:
GetId(),wx.wxEVT_COMMAND_CHECKBOX_CLICKED,function()i:getRoot().dirtyConfig=true
i.configValues.inverted=tostring(r:GetValue())i:getRoot():statusMessage(
'Inverted set to: '..r:GetValue())end)k:Layout()return k end Controller=class(
'Controller',Type)function Controller.new(i)i.guiMode=''i.dirtyConfig=false i.
timer=wx.wxTimer(mcLuaPanelParent,wx.wxID_ANY)i.timer:Connect(wx.wxEVT_TIMER,
function()i:update()end)i.configValues.shiftButton=''i.configValues.jogIncrement
='0'i.configValues.logLevel='0'i.configValues.xYReversed='false'i.configValues.
frequency='0'i:addChild(Button('DPad_UP',i))i:addChild(Button('DPad_DOWN',i))i:
addChild(Button('DPad_LEFT',i))i:addChild(Button('DPad_RIGHT',i))i:addChild(
Button('Btn_START',i))i:addChild(Button('Btn_BACK',i))i:addChild(Button('Btn_LS'
,i))i:addChild(Button('Btn_RS',i))i:addChild(Button('Btn_LTH',i))i:addChild(
Button('Btn_RTH',i))i:addChild(Button('Btn_A',i))i:addChild(Button('Btn_B',i))i:
addChild(Button('Btn_X',i))i:addChild(Button('Btn_Y',i))i:addChild(Trigger(
'LTR_Val',i))i:addChild(Trigger('RTR_Val',i))i:addChild(ThumbstickAxis(
'LTH_Y_Val',i))i:addChild(ThumbstickAxis('LTH_X_Val',i))i:addChild(
ThumbstickAxis('RTH_Y_Val',i))i:addChild(ThumbstickAxis('RTH_X_Val',i))i.
logLevels={'ERROR','WARNING','INFO','DEBUG'}local j=Profile.getLast()local k=
Profile.getProfiles()[j]i.profile=Profile.new(j,k,i)i.profile:load()i:xcCntlLog(
'Starting Controller loop',4)i.timer:Start(1000/tonumber(i.configValues.
frequency))return i end function Controller.update(i)if i.configValues.
shiftButton~=''then i[i.configValues.shiftButton]:getState()end for j,k in
ipairs(i.children)do if k~=i.configValues.shiftButton then k:getState()end end
end function Controller.updateUi(i)i.propertiesPanel:GetSizer():Clear(true)i:
initUi(i.propertiesPanel)end function Controller.mapSimpleJog(i)i:xcCntlLog(
string.format('Value of reversed flag for axis orientation: %s',tostring(i.
configValues.xYReversed)),4)i.DPad_UP.configValues.Down=i.configValues.
xYReversed=='true'and'Jog Y+'or'Jog X+'i.DPad_UP.configValues.Up=i.configValues.
xYReversed=='true'and'Jog Y Off'or'Jog X Off'i.DPad_DOWN.configValues.Down=i.
configValues.xYReversed=='true'and'Jog Y-'or'Jog X-'i.DPad_DOWN.configValues.Up=
i.configValues.xYReversed=='true'and'Jog Y Off'or'Jog X Off'i.DPad_RIGHT.
configValues.Down=i.configValues.xYReversed=='true'and'Jog X+'or'Jog Y+'i.
DPad_RIGHT.configValues.Up=i.configValues.xYReversed=='true'and'Jog X Off'or
'Jog Y Off'i.DPad_LEFT.configValues.Down=i.configValues.xYReversed=='true'and
'Jog X-'or'Jog Y-'i.DPad_LEFT.configValues.Up=i.configValues.xYReversed=='true'
and'Jog X Off'or'Jog Y Off'if i.configValues.xYReversed then i:xcCntlLog(
[[Standard velocity jogging with X and Y axis orientation reversed mapped to D-pad]]
,3)else i:xcCntlLog('Standard velocity jogging mapped to D-pad',3)end i.DPad_UP.
configValues.altDown=i.configValues.xYReversed=='true'and'Incremental Jog Y+'or
'Incremental Jog X+'i.DPad_DOWN.configValues.altDown=i.configValues.xYReversed==
'true'and'Incremental Jog Y-'or'Incremental Jog X-'i.DPad_RIGHT.configValues.
altDown=i.configValues.xYReversed=='true'and'Incremental Jog X+'or
'Incremental Jog Y+'i.DPad_LEFT.configValues.altDown=i.configValues.xYReversed==
'true'and'Incremental Jog X-'or'Incremental Jog Y-'if i.configValues.xYReversed
then i:xcCntlLog(
[[Incremental jogging with X and Y axis orientation reversed mapped to D-pad alternate function]]
,3)else i:xcCntlLog('Incremental jogging mapped to D-pad alternate function',3)
end end function Controller.xcCntlLog(i,j,k)if i.configValues.logLevel=='0'then
return end if k<=tonumber(i.configValues.logLevel)then if mc.mcInEditor()~=1
then mc.mcCntlLog(inst,'[[XBOX CONTROLLER '..i.configValues.logLevels[k]..']]: '
..j,'',-1)else print('[[XBOX CONTROLLER '..i.configValues.logLevels[k]..']]: '..
j)end end end function Controller.xcGetRegValue(i,j)local k,l=mc.mcRegGetHandle(
inst,j)if l==mc.MERROR_NOERROR then local m,n=mc.mcRegGetValue(k)if n==mc.
MERROR_NOERROR then return m else i:xcCntlLog(string.format(
'Error in mcRegGetValue: %s',mc.mcCntlGetErrorString(inst,n)),1)end else i:
xcCntlLog(string.format('Error in mcRegGetHandle: %s',mc.mcCntlGetErrorString(
inst,l)),1)end end function Controller.initUi(i,j)local k=j:GetSizer()local l={}
for m,n in pairs(Profile.getProfiles())do table.insert(l,n)end local p=wx.
wxStaticText(j,wx.wxID_ANY,'Current Profile:')k:Add(p,0,wx.
wxALIGN_CENTER_VERTICAL+wx.wxALL,5)local q=wx.wxChoice(j,wx.wxID_ANY,wx.
wxDefaultPosition,wx.wxDefaultSize,l)k:Add(q,1,wx.wxEXPAND+wx.wxALL,5)q:
SetSelection(q:FindString(i.profile.name))j:Connect(q:GetId(),wx.
wxEVT_COMMAND_CHOICE_SELECTED,function()if i.dirtyConfig then local r=wx.
wxMessageBox(
[[You have unsaved changes. Do you want to save before switching profiles?]],
'Unsaved Changes',wx.wxYES_NO+wx.wxCANCEL+wx.wxICON_QUESTION)if r==wx.wxYES then
i.profile:save()elseif r==wx.wxCANCEL then return false end end local r=q:
GetSelection()local s for t,u in pairs(l)do if u==r then s=t break end end i.
profile=Profile.new(s,r,i)i.profile:load()i:updateUi()i:statusMessage(
'Profile switched to: '..r)end)local r=wx.wxStaticText(j,wx.wxID_ANY,
'Assign shift button:')k:Add(r,0,wx.wxALIGN_CENTER_VERTICAL+wx.wxALL,5)local s={
''}for t,u in ipairs(i.children)do if u.__type~='ThumbstickAxis'then table.
insert(s,u.id)end end local v=wx.wxChoice(j,wx.wxID_ANY,wx.wxDefaultPosition,wx.
wxDefaultSize,s)k:Add(v,1,wx.wxEXPAND+wx.wxALL,5)v:SetSelection(v:FindString(i.
configValues.shiftButton))j:Connect(v:GetId(),wx.wxEVT_COMMAND_CHOICE_SELECTED,
function()i.dirtyConfig=true i.configValues.shiftButton=v:GetString(v:
GetSelection())i:statusMessage('Shift button set to: '..v:GetString(v:
GetSelection()))end)local w=wx.wxStaticText(j,wx.wxID_ANY,'Jog Increment:')k:
Add(w,0,wx.wxALIGN_CENTER_VERTICAL+wx.wxALL,5)local x=wx.wxTextCtrl(j,wx.
wxID_ANY,tostring(i.configValues.jogIncrement),wx.wxDefaultPosition,wx.
wxDefaultSize,wx.wxTE_RIGHT)k:Add(x,1,wx.wxEXPAND+wx.wxALL,5)j:Connect(x:GetId()
,wx.wxEVT_COMMAND_TEXT_UPDATED,function()i.dirtyConfig=true i.configValues.
jogIncrement=tonumber(x:GetValue())i:statusMessage('Jog increment set to: '..i.
configValues.jogIncrement)end)local y={'0 - Disabled','1 - Error','2 - Warning',
'3 - Info','4 - Debug'}local z=wx.wxStaticText(j,wx.wxID_ANY,'Logging level:')k:
Add(z,0,wx.wxALIGN_CENTER_VERTICAL+wx.wxALL,5)local A=wx.wxChoice(j,wx.wxID_ANY,
wx.wxDefaultPosition,wx.wxDefaultSize,y)k:Add(A,1,wx.wxEXPAND+wx.wxALL,5)A:
SetSelection(tonumber(i.configValues.logLevel))j:Connect(A:GetId(),wx.
wxEVT_COMMAND_CHOICE_SELECTED,function()i.dirtyConfig=true i.configValues.
logLevel=A:GetString(A:GetSelection())i:statusMessage('Log level set to: '..i.
configValues.logLevel)end)local B=wx.wxStaticText(j,wx.wxID_ANY,
'Swap X and Y axes:')k:Add(B,0,wx.wxALIGN_CENTER_VERTICAL+wx.wxALL,5)local C=wx.
wxCheckBox(j,wx.wxID_ANY,'')C:SetValue(i.configValues.xYReversed=='true')k:Add(C
,1,wx.wxALIGN_RIGHT+wx.wxALL,5)j:Connect(C:GetId(),wx.
wxEVT_COMMAND_CHECKBOX_CLICKED,function()i.dirtyConfig=true i.configValues.
xYReversed=C:GetValue()and'true'or'false'i:statusMessage(
'X and Y axes swapped: '..i.configValues.xYReversed)end)local D=wx.wxStaticText(
j,wx.wxID_ANY,'Update Frequency (Hz):')k:Add(D,0,wx.wxALIGN_CENTER_VERTICAL+wx.
wxALL,5)local E=wx.wxTextCtrl(j,wx.wxID_ANY,i.configValues.frequency,wx.
wxDefaultPosition,wx.wxDefaultSize,wx.wxTE_RIGHT)k:Add(E,1,wx.wxEXPAND+wx.wxALL,
5)j:Connect(E:GetId(),wx.wxEVT_COMMAND_TEXT_UPDATED,function()i.dirtyConfig=true
i.configValues.frequency=tonumber(E:GetValue())i:statusMessage(
'Update frequency set to: '..i.configValues.frequency..'Hz')end)k:Add(0,0,1,wx.
wxEXPAND)local F=wx.wxButton(j,wx.wxID_ANY,'Map Basic Jogging')k:Add(F,1,wx.
wxEXPAND+wx.wxALL,5)j:Connect(F:GetId(),wx.wxEVT_COMMAND_BUTTON_CLICKED,function
()i:mapSimpleJog()i:statusMessage'Basic jogging mapped to the DPad.'end)k:Add(0,
0,1,wx.wxEXPAND)k:Add(0,0,1,wx.wxEXPAND)local G=wx.wxButton(j,wx.wxID_ANY,
'Undo Unsaved Changes')k:Add(G,1,wx.wxEXPAND+wx.wxALL,5)local H=wx.wxButton(j,wx
.wxID_ANY,'Delete A Profile...')k:Add(H,1,wx.wxEXPAND+wx.wxALL,5)local I=wx.
wxButton(j,wx.wxID_ANY,'Save Profile As...')k:Add(I,1,wx.wxEXPAND+wx.wxALL,5)
local J=wx.wxButton(j,wx.wxID_ANY,'Save Current Profile')k:Add(J,1,wx.wxEXPAND+
wx.wxALL,5)local K={G,H,I,J}local L=0 for M,N in pairs(K)do local O=N:GetSize()L
=math.max(L,O:GetHeight())end for O,P in pairs(K)do P:SetMinSize(wx.wxSize(-1,L)
)P:SetSize(wx.wxSize(-1,L))end k:Layout()j:Layout()j:Connect(G:GetId(),wx.
wxEVT_COMMAND_BUTTON_CLICKED,function()local Q=wx.wxMessageBox(
'Are you sure you want to undo any unsaved changes?','Confirm',wx.wxYES_NO+wx.
wxICON_QUESTION)if Q==wx.wxYES then i.dirtyConfig=false i.profile:load()i:
updateUi()i:statusMessage('Restored profile: '..i.profile.name)else return false
end end)j:Connect(J:GetId(),wx.wxEVT_COMMAND_BUTTON_CLICKED,function()local Q=wx
.wxMessageBox(string.format('Save changes to profile: %s?',q:GetStringSelection(
)),'Confirm',wx.wxOK+wx.wxCANCEL)if Q==wx.wxOK then i.profile:save()i:
statusMessage(string.format('Changes saved to profile: %s',q:GetStringSelection(
)))end end)j:Connect(H:GetId(),wx.wxEVT_COMMAND_BUTTON_CLICKED,function()local Q
=wx.wxDialog(j,wx.wxID_ANY,'Delete Profile',wx.wxDefaultPosition,wx.wxSize(300,
300),wx.wxDEFAULT_DIALOG_STYLE)local R=wx.wxBoxSizer(wx.wxVERTICAL)local S=wx.
wxStaticText(Q,wx.wxID_ANY,'Select a profile:')R:Add(S,0,wx.wxALL,5)local T=wx.
wxListBox(Q,wx.wxID_ANY,wx.wxDefaultPosition,wx.wxSize(280,120),l,wx.wxLB_SINGLE
)R:Add(T,0,wx.wxEXPAND+wx.wxALL,5)local U=wx.wxBoxSizer(wx.wxHORIZONTAL)local V=
wx.wxButton(Q,wx.wxID_ANY,'Delete')local W=wx.wxButton(Q,wx.wxID_CANCEL,'Cancel'
)U:Add(V,1,wx.wxALL,5)U:Add(W,1,wx.wxALL,5)R:Add(U,0,wx.wxALIGN_RIGHT+wx.wxALL,5
)Q:SetSizer(R)R:Fit(Q)Q:Connect(V:GetId(),wx.wxEVT_COMMAND_BUTTON_CLICKED,
function()local X=T:GetStringSelection()local Y=wx.wxMessageBox(string.format(
'Delete profile: %s?',X),'Confirm',wx.wxOK+wx.wxCANCEL)if Y==wx.wxOK then local
Z=Profile.new(Profile:getId(X),X,i)Z:delete()i:statusMessage(string.format(
'Deleted profile: %s',X))end Q:EndModal(wx.wxOK)end)Q:Connect(W:GetId(),wx.
wxEVT_COMMAND_BUTTON_CLICKED,function()Q:EndModal(wx.wxCANCEL)end)Q:ShowModal()Q
:Destroy()end)j:Connect(I:GetId(),wx.wxEVT_COMMAND_BUTTON_CLICKED,function()
local Q=wx.wxDialog(j,wx.wxID_ANY,'Save Profile As',wx.wxDefaultPosition,wx.
wxSize(300,300),wx.wxDEFAULT_DIALOG_STYLE)local R=wx.wxBoxSizer(wx.wxVERTICAL)
local S=wx.wxStaticText(Q,wx.wxID_ANY,'Select an existing profile:')R:Add(S,0,wx
.wxALL,5)local T=wx.wxListBox(Q,wx.wxID_ANY,wx.wxDefaultPosition,wx.wxSize(280,
120),l,wx.wxLB_SINGLE)T:SetSelection(T:FindString(i.profile.name))R:Add(T,0,wx.
wxEXPAND+wx.wxALL,5)local U=wx.wxStaticText(Q,wx.wxID_ANY,
'Or enter a new profile name:')R:Add(U,0,wx.wxALL,5)local V=wx.wxTextCtrl(Q,wx.
wxID_ANY,'',wx.wxDefaultPosition,wx.wxSize(280,30))R:Add(V,0,wx.wxEXPAND+wx.
wxALL,5)local W=wx.wxBoxSizer(wx.wxHORIZONTAL)local X=wx.wxButton(Q,wx.wxID_SAVE
,'Save')local Y=wx.wxButton(Q,wx.wxID_CANCEL,'Cancel')W:Add(X,1,wx.wxALL,5)W:
Add(Y,1,wx.wxALL,5)R:Add(W,0,wx.wxALIGN_RIGHT+wx.wxALL,5)Q:SetSizer(R)R:Fit(Q)Q:
Connect(X:GetId(),wx.wxEVT_COMMAND_BUTTON_CLICKED,function()local Z=T:
GetStringSelection()local _=V:GetValue()local aa,ab if _~=''then aa=_ ab=#l i:
xcCntlLog(string.format('Saving as new profile: %s',_),3)elseif Z~=''then for ac
,ad in pairs(Profile.getProfiles())do if ad==Z then aa=Z ab=ac break end end i:
xcCntlLog(string.format('Saving over existing profile: %s',Z),3)else wx.
wxMessageBox('Please select a profile or enter a new name','Error',wx.wxOK+wx.
wxICON_ERROR)end if ab and aa then local ac=wx.wxMessageBox(string.format(
'Save changes to profile: %s?',aa),'Confirm',wx.wxOK+wx.wxCANCEL)if ac==wx.wxOK
then local ad=Profile.new(ab,aa,i)ad:save()i:statusMessage(string.format(
'Configuration saved to profile: %s',aa))else end end Q:EndModal(wx.wxID_SAVE)
end)Q:Connect(Y:GetId(),wx.wxEVT_COMMAND_BUTTON_CLICKED,function()Q:EndModal(wx.
wxID_CANCEL)end)Q:ShowModal()Q:Destroy()end)k:Layout()j:Layout()return k end
function Controller.initPanel(aa,ab)aa.guiMode=ab local ac if ab=='embedded'or
ab=='wizard'then ac=mcLuaPanelParent else ac=wx.wxFrame(wx.NULL,wx.wxID_ANY,
'Configure Xbox Controller Settings')end aa.panel=ac if aa.guiMode~='embedded'
then ac:CreateStatusBar(1)end local ad=wx.wxBoxSizer(wx.wxHORIZONTAL)ac:
SetMinSize(wx.wxSize(450,500))ac:SetMaxSize(wx.wxSize(450,500))local i=wx.
wxStaticBox(ac,wx.wxID_ANY,'Controller Tree Manager')local j=wx.
wxStaticBoxSizer(i,wx.wxVERTICAL)local k=wx.wxTreeCtrl.new(ac,wx.wxID_ANY,wx.
wxDefaultPosition,wx.wxSize(100,-1),wx.wxTR_HAS_BUTTONS,wx.wxDefaultValidator,
'tree')local l=k:AddRoot'Controller'local n={[l:GetValue()]=aa}for p=1,#aa.
children do local q=k:AppendItem(l,aa.children[p].id)n[q:GetValue()]=aa.children
[p]end k:ExpandAll()j:Add(k,1,wx.wxEXPAND+wx.wxALL,5)local p=wx.wxStaticBox(ac,
wx.wxID_ANY,'Properties')local q=wx.wxStaticBoxSizer(p,wx.wxVERTICAL)aa.
propertiesPanel=wx.wxPanel(ac,wx.wxID_ANY,wx.wxDefaultPosition,wx.wxDefaultSize)
local r=wx.wxFlexGridSizer(0,2,0,0)r:AddGrowableCol(1,1)aa.propertiesPanel:
SetSizer(r)aa.propertiesPanel:Layout()local s=wx.wxFont(8,wx.
wxFONTFAMILY_DEFAULT,wx.wxFONTSTYLE_NORMAL,wx.wxFONTWEIGHT_NORMAL)aa.
propertiesPanel:SetFont(s)p:SetFont(s)i:SetFont(s)k:SetFont(s)q:Add(aa.
propertiesPanel,1,wx.wxEXPAND+wx.wxALL,5)k:Connect(wx.
wxEVT_COMMAND_TREE_SEL_CHANGED,function(u)aa.propertiesPanel:GetSizer():Clear(
true)local v=n[u:GetItem():GetValue()]local w=wx.wxFlexGridSizer(0,2,0,0)w:
AddGrowableCol(1,1)if v==aa then w:AddGrowableRow(7,1)end aa.propertiesPanel:
SetSizer(w)aa.propertiesPanel:SetSizer(v:initUi(aa.propertiesPanel))aa.
propertiesPanel:Layout()end)ad:Add(j,0,wx.wxEXPAND+wx.wxALL,5)ad:Add(q,1,wx.
wxEXPAND+wx.wxALL,5)ac:SetSizer(ad)ad:Layout()function Controller.go()ac:
Connect(wx.wxEVT_CLOSE_WINDOW,function()if aa.dirtyConfig then local u=wx.
wxMessageBox(
[[You have unsaved changes to your controller profile. Do you want to save before exiting? (If you exit without saving, your applied changes will remain applied for the current session.)]]
,'Unsaved Changes',wx.wxYES_NO+wx.wxCANCEL+wx.wxICON_QUESTION)if u==wx.wxYES
then aa.profile:save()elseif u==wx.wxCANCEL then return false end end ac:
Destroy()wx.wxGetApp():ExitMainLoop()aa.go=function()end end)wx.wxApp(false)wx.
wxGetApp():SetTopWindow(ac)ac:Show(true)wx.wxGetApp():MainLoop()end aa:go()end
function Controller.statusMessage(aa,ab)if aa.guiMode=='embedded'then mc.
mcCntlSetLastError(inst,ab)else aa.panel:SetStatusText(ab)end end function
Controller.destroy(aa)if aa.timer then aa.timer:Stop()aa.timer=nil end if aa.
dirtyConfig then local ab=wx.wxMessageBox(
[[You have unsaved changes. Do you want to save before exiting?]],
'Unsaved Changes',wx.wxYES_NO+wx.wxICON_QUESTION)if ab==wx.wxYES then aa.profile
:save()elseif ab==wx.wxNO then end end end xc=Controller('xc',nil)xc:initPanel
'embedded'return{xc=xc}