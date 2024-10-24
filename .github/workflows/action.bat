@echo off

REM Download Lua 5.3 Windows binaries
curl -L https://sourceforge.net/projects/luabinaries/files/5.3.5/Windows%20x64%20DLL/lua-5.3.5_Win64_bin.zip/download -o lua.zip

REM Unzip Lua binaries
powershell -command "Expand-Archive -Path lua.zip -DestinationPath ."

REM Move Lua binaries to C:\Lua53 (create the directory if it doesn't exist)
mkdir C:\Lua53
move lua-5.3.5_Win64_bin\* C:\Lua53\

REM Add Lua to the PATH
set PATH=%PATH%;C:\Lua53

REM Confirm Lua is in the PATH
lua -v

REM Update the package path for the Windows environment
setlocal enabledelayedexpansion

lua -e "package.cpath = package.cpath .. ';%CD%\\build\\?.dll'; require('mocks'); print('Lua environment set up')"

REM Change directory to the mach4 directory (adjust this path if needed)
cd mach4

REM Download and unzip darklua
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-windows-x86_64.zip -o darklua.zip
powershell -command "Expand-Archive -Path darklua.zip -DestinationPath ."

REM Run the build script
lua buildScript.lua
