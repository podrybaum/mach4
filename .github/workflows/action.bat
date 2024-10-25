
REM Set the path to the Lua binaries in the repo
set LUA_PATH=%CD%\Lua53

REM Add Lua to the PATH
echo Adding Lua to the PATH...
set PATH=%PATH%;%LUA_PATH%

REM Confirm Lua is in the PATH
lua53 -v
if %errorlevel% neq 0 (
    echo ERROR: Lua is not properly installed!
    exit /b 1
)

REM Run the build script using CALL to avoid 'unexpected at this time' error
echo Running the build script...
CALL lua53 buildScript.lua
