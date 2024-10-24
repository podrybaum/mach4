
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

REM Update the package path for the Windows environment
setlocal enabledelayedexpansion
lua53 -e "package.cpath = package.cpath .. ';%CD%\\build\\?.dll'; require('mocks'); print('Lua environment set up')"

REM Change directory to the mach4 directory (adjust this path if needed)
cd mach4

REM Download and unzip darklua
echo Downloading and unzipping DarkLua...
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-windows-x86_64.zip -o darklua.zip
powershell.exe -Command "Expand-Archive -Path 'darklua.zip' -DestinationPath ."

REM Run the build script
echo Running the build script...
lua53 buildScript.lua
