# A More Robust Xbox Controller Library

## Concept Overview

This library builds upon (and requires) the wonderful mcx360_Lua plugin by DazTheGas, available [here](https://www.machsupport.com/forum/index.php?topic=33121.0).

This implementation is an object-oriented (*more on this below*) approach to a completely customizable Xbox controller integration with Mach4.  The goal of the project is to provide an interface to defining a custom control scheme that can be easily utilized by anyone, regardless of their experience with Lua or any other type of programming.  Those users should find it possible to make the Xbox controller work exactly the way they want it to in Mach4 without referring to any other document than this one.

A further goal of the project is to provide an interface to customizing the Xbox controller that prioritizes safety and reliability.  To this end, a very robust system of error checking has been implemented that has sufficed in all testing to date to guarantee that no mistake in the configuration ever results in unsafe, unexpected or undefined machine behavior.

The first sections of this documentation are aimed at users with little or even no programming experience, and are unlikely to be of interest to more advanced users.  Those users may want to skip ahead to the "Advanced Usage" or "API Reference" sections.

### What is meant by "object-oriented?"

In 'functional programming', we provide explicit instructions to the machine in what amounts to a "to-do list".  Do this, then do this, then do that, and finally, exit.  Object-oriented programming is a much different sort of approach, in which we define objects and assign them specific properties and behaviors, and then simply provide a context in which our objects can interact with one another (and potentially the user) according to the way in which we have defined them.  In programmer jargon, we often refer to the properties of an object as its 'attributes' and the behaviors of an object as 'methods.'  Those terms will be used henceforth in this documentation.  The object oriented approach makes it possible for a code library to expose an 'API' (*Application Programming Interface, or simply "interface"*) through which a user can leverage complex behaviors through a simplified syntax.  Novice programmers or even non-programmers will appreciate that they can achieve the functionality they desire without needing to understand or even care how it's implemented.  More advanced programmers will likely understand the amount of time such an API saves them, so hopefully there's something here for everyone.

### Core concepts of this library:
Following from that extremely basic explanation of object-oriented programming, here's a basic rundown of how this library works:

An interface is presented to a Controller object.  The Controller object in turn exposes access to Button, Trigger and ThumbstickAxis objects.  Button objects are associated with Signal objects, with a "down" signal being emitted when a button is pressed, and an "up" signal being emitted when the button is released.  These Signals can be 'connected' to Slot objects.  A Slot object contains the actual code we want to execute in response to a particular Signal being emitted.  ThumbstickAxis objects don't have Signals.  Instead, they directly 'connect' to a machine axis and provide analog control of that axis' motion.  Trigger objects output analog values just like ThumbstickAxis objects do, and they also emit "down" and "up" Signals like Button objects do.  So Triggers can be used as either Buttons or as analog control inputs, but not both at once.  Finally, it is possible to assign any Button or Trigger as a "shift button".  Having a shift button assigned enables the ability to connect a Slot *and* an alternate Slot to a given Signal.  The alternate Slot function will be called if the Signal is emitted while the assigned shift button is pressed.

## Using This Library

The prerequisites to using this library are as follows:
* Download the mcx360_Lua plugin by DazTheGas from the link provided above.
* Copy the mcx360_LUA.m4pw and mcx360_LUA.sig files into your Mach4Hobby/Plugins directory.
* In Mach4, go to Configure > Control and click on the Plugins tab.  Ensure that the mxX360 LUA line appears in the list of plugins, and if it shows a red X in the enabled field: simply click the red X, which should toggle it to a green checkmark, indicating the plugin has been enabled.
* Add a hidden "Lua Panel" to your Mach4 screen set:
1. Click on Operator > Edit Screen
2. Click on "Add Lua Panel" button from the toolbar near the top of the screen.
3. In the "Properties" box at the lower left corner of the screen, ensure that a check is placed in the box for "Hidden".
4. Click the "Events" tab near the top of the "Properties" box - (the one with the lightning bolt).
5. In the new tab that opens should be a single box, and at the far right of that box is a button with "..." on it.   Click that button, which will open the script editor.
6. Copy and paste the contents of the xc.lua file provided here into the script editor window that just opened.
7. Scroll to the section near the bottom that starts with:
   ```lua
   ---------------------------------
   --- Custom Configuration Here ---
   ```
8. This section is where you will implement your own custom configuration for the Xbox controller
* The rest of this documentation explains how to customize your Xbox controller's behavior in Mach4, with code examples.  Any code provided henceforth is placed in this "Custom Configuration Here" section of the file.
  
## The Controller Object

The library provides you with a controller object that implements all the required code to recognize any of the controller inputs being manipulated and do useful things based on the input it receives.  All that remains for the user is to define what inputs trigger what functions.  Less experienced users will hopefully appreciate that the most common functions that people want to map to controller inputs have already been defined for them.

We address the Controller object provided by the library through the identifier "xc."  This identifier works in much the same way as the "mc" identifier works for the Mach4 API, and in fact, this Xbox controller API has been designed to utilize the same syntax conventions as the Mach4 API as much as possible, so it should feel familiar to users who have done some Lua coding for Mach4 previously.  

One of the first things you might want to do with the Controller object is to increase the logging level to "DEBUG" while you're working on your custom configuration.  To do so add this line to your custom configuration:

```lua
xc.logLevel = 4
```

There are 4 levels of logging.  Each level provides a different type of logging output, and each level you activate keeps all previous levels activated.  So logLevel 4, or "DEBUG" is the most verbose logging output.  It may even generate enough log output to cause some lag on lower-end PCs.  It is not recommended that you leave the logLevel set this high all the time, but while you are working on your configuration, the information it provides can be very helpful if you find something isn't working quite the way you expect it to.  The 4 levels of log output are, from least verbose to most:

|logLevel|log message type|
|:------:|:---------------|
|1|ERROR|
|2|WARNING|
|3|INFO|
|4|DEBUG|

Note that it is also possible to set the logLevel to 0, which disables all log output.  It is recommended that you leave the logLevel at 2 most of the time, so you will see any ERROR or WARNING type messages related to the Xbox controller in the logs.

Next, you might want to consider assigning a shift button.  Having a shift button assigned enables the mapping of a "regular" Slot and/or an "alternate" Slot to any Signal.  It works the same way as the shift button on your keyboard.  When it's pressed, any Signal being emitted that is connected to an "alternate" Slot will call that alternate Slot instead of its normal one.  You can also choose to connect *only* an "alternate" Slot to a given Signal, which is useful to ensure that an accidental button press won't make your machine do something you don't want it to.  Any Button or Trigger can be assigned as a shift button.  The Controller's inputs can be addressed as follows:

|identifier|input|object type
|:--------:|:----|:----------
|xc.UP|D-Pad up|Button
|xc.DOWN|D-Pad down|Button
|xc.LEFT|D-Pad left|Button
|xc.RIGHT|D-Pad right|Button
|xc.START|Start button|Button
|xc.BACK|Back button|Button
|xc.LSB|Left shoulder button|Button
|xc.RSB|Right shoulder button|Button
|xc.LTR|Left trigger|Trigger
|xc.RTR|Right trigger|Trigger
|xc.LTH|Left thumbstick pushbutton|Button
|xc.RTH|Right thumbstick pushbutton|Button
|xc.LTH_X|Left thumbstick X axis|ThumbstickAxis
|xc.LTH_Y|Left thumbstick Y axis|ThumbstickAxis
|xc.RTH_X|Right thumbstick X axis|ThumbstickAxis
|xc.RTH_Y|Right thumbsick Y axis|ThumbstickAxis

So to assign the Left trigger (for example) as the Controller's shift button:
```lua
xc:assignShift(xc.LTR)
```
>**IMPORTANT:** Note the use of a colon rather than a period in this line.  In the previous example, we were accessing one of the Controller object's *attributes*.  Attribute access uses the period form, as in 'xc.logLevel'.  Here, we are calling one of the Controller object's **methods**.  Method access uses the colon form.  Using a period instead of a colon to access a method of an object in Lua can produce unexpected, undesireable or undefined behavior, due to some very technical details of how Lua internally handles object-oriented code.  We definitely don't want our machines doing anything unexpected, undesireable or undefined, so to avoid those issues, this library implements a check on all method calls that will simply return from the method call without doing anything and log an error message if you attempt to use the period form to call a method.  

Now let's get the controller actually doing things with the machine.  We'll start with assigning analog control of our Z axis to the right thumbstick's Y axis.  (*The Y axis of a thumbstick is its up and down axis, and the X axis is its left to right axis.*)

```lua
xc.LTH_Y:connect(mc.Z_AXIS)
```

That's all it takes to enable analog control of an axis!  (*Analog control means that if we move the stick only a small amount, the axis will move slowly, and increase speed up to its maximum velocity as we continue to push the stick farther.*) Here, we've passed 'mc.Z_AXIS', which is an identifer provided by the Mach4 Core API representing the Z axis of the machine, as the parameter to the Left ThumbstickAxis object's 'connect' **method** (so remember to use a colon!).

If you find that the axis moves in the opposite direction that you expect it to in response to the thumbstick input, pass true as a second parameter to the connect method, like so:
```lua
xc.LTH_Y:connect(mc.Z_AXIS,true)
```
This will invert the motion of the Axis relative to the thumbstick input.

Mapping normal velocity jogging to the DPad is unfortunately, quite a bit more involved.   The D-Pad is comprised of 4 individual buttons, each of which has a "down" and an "up" signal, and to make jogging work right, we have to connect both Signals to Slots for each button.  That looks like this:

```lua
xc.UP.down:connect(Slot.new(function()
    mc.mcJogVelocityStart(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS, mc.MC_JOG_POS)
end))
xc.UP.up:connect(Slot.new(function()
    mc.mcJogVelocityStop(inst, (reversed and mc.Y_AXIS) or mc.X_AXIS)
end))
xc.DOWN.down:connect(Slot.new(function()
    mc.mcJogVelocityStart(inst,...
```
Just kidding.

How about we try this?
```lua
xc:mapSimpleJog()
```
mapSimpleJog is a method that has been provided for your convenience, which maps jogging of the X and Y axes to the D-Pad, and also maps *incremental* jogging of the X and Y axes to the D-Pad's alternate function.  Regular jogging works just the way you would expect, for as long as you hold down a directional button on the D-Pad, the machine jogs in that direction.  When you release the button, it stops.  If the Controller object has an assigned shift button, pressing a button on the D-Pad while the shift button is depressed will jog the machine in the appropriate direction by the currently configured jog increment, which we can set through this call:
```lua
xc:xcSetJogIncrement(0.01)
```
This sets the jog increment (*only for the controller, it does not affect the jog increment of the keyboard, the Mach4 screen or any other controller*) to 0.01 ***units***, where the units are whatever units Mach4 is currently configured to use.  The Controller object has a default jog increment of 0.1 units, so if you're satisfied with that value, there is no need to call xcSetJogIncrement at all.

Some users may need to reverse the orientation of the X and Y axes.  If you have reversed the orientation of the X and Y axes in Mach4, you need to also reverse them here.  To that end, the mapSimpleJog method has a *reversed* parameter, which we ignored previously.  To set it, pass a value of true as a parameter to the mapSimpleJog method, like so:
```lua
xc.mapSimpleJog(true)
```

This will reverse the orientation of the X and Y axes mapping to the D-Pad, so that the up and down directions control the Y axis and the left and right directions control the X axis.

There are several more of these convenient pre-defined functions available in the library.  The rest of them are available through pre-defined Slots, ready to be connected to whatever Signal you want.  For a complete list of pre-defined Slots, see the API Reference section of this documentation.

To connect a Signal from a Button to a Slot:
```lua
xc.B.down:connect(xc.xcCntlEStopToggle)
```

And, that's it.  The Controller's B button now toggles the E-stop.  Most users will find everything they might want to map in the controller is already defined in the API, so the custom controller configuration will boil down to just a few lines of statements connecting Signals to pre-defined slots.

## Advanced Usage

This library represents an attempt to produce a simple interface for configuring and customizing the Xbox controller in Mach4.  To that end, a number of convenience methods (or Slots in this case) have been predefined, and it is the aim of this project that the corpus of predefined Slots will cover the needs of 90% of users.  But for the other 10% who have special requirements not covered by the API's predefined Slots, or for those users who really just like to tinker, the Signal > Slot mechanism leaves the door wide open for infinite customization.

A Slot is simply a data structure that encapsulates some function, a particular set of parameters to pass to the function, and some syntax sugar that streamlines the process of establishing an event loop with callback functions.  There are no restrictions whatsoever on what manner of function is referenced by a given Slot object, but if the function call a user wants to assign to a Slot normally requires paramaters, do note that the parameter values will need to be assigned when the Slot function is defined, as there is currently no straightforward way to pass parameters to a Slot function when it is being called.  (No need for such a feature has yet presented itself.)

Thus, anything that can be achieved with a function call in Lua can be assigned as a Slot function, conected to a Signal, and subsequently executed whenever that Signal is emitted.  Custom slots can be defined like this:
```lua
mySlot = Slot:new(function() print("Slots are powerful!") end)  
```
In this example, we've used a closure (aka anonymous function) as the Slot function.  Using a closure allows for prepopuating the parameters that will be passed when the function is called.  There is another way to achieve the same goal that may be preferred by some users; namely passing a reference (by name) to some custom function or method call, as in:
```lua
function myFunction()
    msg = "Slots are powerful!"
    print(msg)
end

mySlot = Slot:new(myFunction)
```
This example is entirely equivalent to the proceeding example.  Do take care that when passing a reference to a function by name that you don't include parentheses behind the function name.  Doing so *calls* the function rather than providing a reference to it.  As a good example of a slot encapsulating more in-depth logic, refer to the definition of xc.xcCntlTorchToggle:
```lua
self.xcCntlTorchToggle = Slot.new(function()
    self:toggleMachSignalState(mc.OSIG_OUTPUT3)
    self:toggleMachSignalState(mc.OSIG_OUTPUT4)
    end)
```

While much of the logic is abstraced away behind the toggleMachSignalState method, hopefully it's readily apparent that the Slot function is manipulating not one but two output signals of the machine.  