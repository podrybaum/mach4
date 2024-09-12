return {
  xc = {
    type = "lib",
    description = "Xbox controller API library",
    childs = {
        Controller = {
            type = "class",
            description = "Defines a Controller object.",
            valuetype = "Controller",
            childs = {
                new = {
                    type = "function",
                    returns = "Controller"
                },
                UP = {type = "Button"},
                DOWN = {type = "Button"},
                LEFT = {type = "Button"},
                RIGHT = {type = "Button"},
                A = {type = "Button"},
                B  = {type = "Button"},
                X = {type = "Button"},
                Y = {type = "Button"},
                START = {type = "Button"},
                BACK = {type = "Button"},
                LTH = {type = "Button"},
                RTH = {type = "Button"},
                LSB = {type = "Button"},
                RSB = {type = "Button"},
                LTR  = {type = "Analog"},
                RTR = {type = "Analog"},
                LTH_X = {type = "Analog"},
                RTH_X = {type = "Analog"},
                LTH_Y = {type = "Analog"},
                RTH_Y = {type = "Analog"},
                inputs = {type = "table"},
                LTH_X_Axis = {type = "ThumbstickAxis"},
                LTH_Y_Axis = {type = "ThumbstickAxis"},
                RTH_X_Axis = {type = "ThumbstickAxis"},
                RTH_Y_Axis = {type = "ThumbstickAxis"},
                axes = {type = "table"},
                shift_btn = {type = "Button|nil"},
                jogIncrement = {type = "value"},
                logLevel = {type = "value"},
                xcLOG_ERROR = {type = "value"},
                xcLOG_WARNING = {type = "value"},
                xcLOG_INFO = {type = "value"},
                xcLOG_DEBUG = {type = "value"},
                logLevels = {type = "table"},
                xcCntlEStop = {
                    type = "function",
                    valuetype = "Slot",
                },
                xcCntlTorchOn = {
                    type = "function",
                    valuetype = "Slot",
                },
                xcCntlEnable = {
                    type = "function",
                    valuetype = "Slot",
                },
                xcCntlCycleStart = {
                    type = "function",
                    valuetype = "Slot",
                },
                xcCntlLog = {
                    type = "function",
                    args = "(msg: string, level: number)"
                },
                xcErrorCheck = {
                    type = "function",
                    args = "(rc: number)",
                },
                xcJogGetInc = {
                    type = "function",
                    returns = "number",
                    valuetype = "number",
                },
                xcJogSetInc = {
                    type = "function",
                    args = "(inc: number)"
                },
                update = {
                    type = "function",
                },
                assignShift = {
                    type = "function",
                    args = "(input: Button|Analog)"
                },
                mapSimpleJog = {
                    type = "function",
                    args = "(reversed: boolean|nil)"
                }
            }
        },
        Signal = {
            type = "class",
            description = "Defines a Signal object.",
            valuetype = "Signal",
            childs = {
                new = {
                    type = "function",
                    args = "(controller: Controller, btn: Button, id: string)",
                    returns = "Signal",
                    typevalue = "Signal"
                },
                id = {type = "value"},
                btn = {type = "Button"},
                slot = {type = "Slot|nil"},
                altSlot = {type = "Slot|nil"},
                controller = {type = "Controller"},
                connect = {
                    type = "function",
                    args = "(slot: Slot)",
                    returns = "nil",
                },
                altConnect = {
                    type = "function",
                    args = "(slot: Slot)",
                    returns = "nil",
                },
                emit = {type = "function"}
            }
        },
        Button = {
            type = "class",
            description = "Defines a Button object.",
            valuetype = "Button",
            childs = {
                new = {
                    type = "function",
                    args = "(controller: Controller, id: string)",
                    returns = "Button",
                    typevalue = "Button"
                },
                controller = {type = "Controller"},
                id = {type = "value"},
                pressed = {type = "boolean"},
                up = {type = "Signal"},
                down = {type = "Signal"},
                getState = {type = "function"}
            }
        },
        Analog = {
            type  = "class",
            description = "Defines an Analog object.",
            valuetype = "Analog",
            childs = {
                new = {
                    type = "function",
                    args = "(controller: Controller, id: string)",
                    returns = "Analog",
                    typevalue = "Analog"
                },
                controller = {type = "Controller"},
                id = {type = "value"},
                value = {type = "value"},
                pressed = {type = "boolean"},
                getState = {type = "function"}
            }
        },
        ThumbstickAxis = {
            type = "class",
            description = "Defines a ThumbstickAxis object.",
            valuetype = "ThumbstickAxis",
            childs = {
                new = {
                    type = "function",
                    args = "(controller: Controller, analog: Analog)",
                    returns = "ThumbstickAxis",
                    typevalue = "ThumbstickAxis"
                },
                controller = {type = "Controller"},
                analog = {type = "Analog"},
                axis = {type = "number|nil"},
                deadzone = {type = "value"},
                rate = {type = "number|nil"},
                moving = {type = "boolean"},
                rateSet = {type = "boolean"},
                connect = {
                    type = "function",
                    args = "(axis: number)"
                },
                update = {
                    type = "function",
                    returns = "nil"
                },
            }
        },
        Slot = {
            type = "class",
            description = "Defines a Slot object.",
            valuetype = "Slot",
            childs = {
                new = {
                    type = "function",
                    args = "(func: function)",
                    returns = "Slot",
                    valuetype = "Slot"
                },
                func = {type = "function"},
                btn = {type = "Button"},
                call = {type = "function"}
            }
        }
    }
  }
}