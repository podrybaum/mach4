REM Download Lua 5.3 Windows 32-bit binaries
echo Downloading Lua 5.3 Windows 32-bit binaries...
curl.exe -L https://sourceforge.net/projects/luabinaries/files/5.3.6/Tools%20Executables/lua-5.3.6_Win32_bin.zip/download -o lua.zip

REM Verify that the file was downloaded
if not exist lua.zip (
    echo ERROR: Failed to download Lua!
    exit /b 1
)

REM Unzip Lua binaries
echo Unzipping Lua binaries...
powershell.exe -Command "Expand-Archive -Path lua.zip -DestinationPath ."

REM Check if lua53.exe was extracted
if not exist lua53.exe (
    echo ERROR: Failed to unzip Lua binaries!
    exit /b 1
)

REM Move Lua binaries to C:\Lua53 (create the directory if it doesn't exist)
echo Moving Lua binaries...
mkdir C:\Lua53
foreach ($file in Get-ChildItem -Path ". " -File) {

    if ($file -match "w*luac*53\...."){
        move $file C:\Lua53}
}

REM Verify the move was successful
if not exist C:\Lua53\lua53.exe (
    echo ERROR: Failed to move Lua binaries to C:\Lua53!
    exit /b 1
)

REM Add Lua to the PATH
echo Adding Lua to the PATH...
set PATH=%PATH%;C:\Lua53

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
powershell -command "Expand-Archive -Path darklua.zip -DestinationPath ."

REM Run the build script
echo Running the build script...
lua53 buildScript.lua
