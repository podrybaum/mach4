
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

REM Set up the Lua paths for modules and dlls
set LUA_MODULES_PATH=%CD%
set LUA_CPATH=%CD%\build

REM Update package.path and package.cpath for Lua scripts
lua53 -e "package.path = package.path .. ';%LUA_MODULES_PATH%\\?.lua;'; package.cpath = package.cpath .. ';%LUA_CPATH%\\?.dll'; print('Updated package.path:', package.path); print('Updated package.cpath:', package.cpath);"

REM Change directory to the mach4 directory (adjust this path if needed)
REM cd mach4

REM Download and unzip darklua
echo Downloading and unzipping DarkLua...
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-windows-x86_64.zip -o darklua.zip
powershell.exe -Command "Expand-Archive -Path 'darklua.zip' -DestinationPath ."

REM Run the build script using CALL to avoid 'unexpected at this time' error
echo Running the build script...
CALL lua53 buildScript.lua
