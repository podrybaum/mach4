inst = mc.mcGetInstance()

MINUS = {[0] = mc.ISIG_MOTOR0_MINUS, [1] = mc.ISIG_MOTOR1_MINUS, [2] = mc.ISIG_MOTOR2_MINUS, [3] = mc.ISIG_MOTOR3_MINUS}
PLUS = {[0] = mc.ISIG_MOTOR0_PLUS, [1] = mc.ISIG_MOTOR1_PLUS, [2] = mc.ISIG_MOTOR2_PLUS, [3] = mc.ISIG_MOTOR3_PLUS}

Axis = {}

function Axis:new(machId)
    local object = {}
    setmetatable(object, {__index = self})
    object.machId = machId
    object.homeDir = mc.mcAxisGetHomeDir(inst, machId)
    object.homeOffset = mc.mcAxisGetHomeOffset(inst, machId)
    object.getPos = function() return mc.mcAxisGetMachinePos(inst, machId) end
    object.motorIds = {}
    local id, rc = mc.mcAxisGetMotorId(inst, machId, 0)
    local i = 0
    repeat
        if rc == mc.MERROR_NOERROR then
            table.insert(object.motorIds, id)
        end
        i = i + 1
        id, rc = mc.mcAxisGetMotorId(inst, machId, i)
    until rc == mc.MERROR_MOTOR_NOT_FOUND

    object.motors = {}
    for _, motorId in ipairs(object.motorIds) do
        table.insert(object.motors, Motor:new(machId, motorId))
    end
    object.areWeThereYet = function()
            for _, motor in ipairs(object.motors) do
                local hsig = mc.mcSignalGetHandle(inst, motor.signal)
                if mc.mcSignalGetState(hsig) == 0 then
                    return false
                end
            end
            return true
        end
    return object
end

Motor = {}

function Motor:new(axisMachId, id)
    local object = {}
    setmetatable(object, {__index = self})
    object.axis = axisMachId
    object.id = id
    object.signal = mc.mcAxisGetHomeDir(inst, axisMachId) > 0 and PLUS[id] or MINUS[id]
    object.isStill = (function() return mc.mcMotorIsStill(inst, id) end)
    return object
end

Axes = {Axis:new(mc.X_AXIS), Axis:new(mc.Y_AXIS), Axis:new(mc.Z_AXIS)}
AxesHomed = {mc.OSIG_HOMED_X, mc.OSIG_HOMED_Y, mc.OSIG_HOMED_Z}

for i = 1,3 do
    local goHome = coroutine.create(function()
        local origVel = mc.mcMotorGetMaxVel(inst, Axes[i].motors[1])
        for _, motor in ipairs(Axes[i].motors) do
            mc.mcMotorSetMaxVel(inst, motor.id, 70)
        end
        mc.mcJogVelocityStart(inst, Axes[i].machId, (Axes[i].homeDir > 0) and mc.MC_JOG_POS or mc.MC_JOG_NEG)
        repeat
            coroutine.yield()
        until Axes[i].areWeThereYet()
        mc.mcJogVelocityStop(inst, Axes[i].machId)
        for _, motor in ipairs(Axes[i].motors) do
            mc.mcMotorSetMaxVel(inst, motor.id, origVel)
        end
    end)
    while coroutine.status(goHome) ~= "dead" do
        coroutine.resume(goHome)
    end
    local hsig = mc.mcSignalGetHandle(inst, AxesHomed[i])
    mc.mcSignalSetState(hsig, 1)
end