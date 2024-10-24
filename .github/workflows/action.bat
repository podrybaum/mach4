@echo off

REM Install Lua 5.3 using Chocolatey
choco install lua53 -y

REM Add Lua to the PATH
set PATH=%PATH%;C:\ProgramData\chocolatey\lib\lua53\tools

refreshenv

REM Confirm Lua is in the PATH
lua53 -v

REM Update the package path for the Windows environment
setlocal enabledelayedexpansion

lua53 -e "package.cpath = package.cpath .. ';%CD%\\build\\?.dll'; require('mocks'); print('Lua environment set up')"

REM Change directory to the mach4 directory (adjust this path if needed)
cd mach4

REM Download and unzip darklua
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-windows-x86_64.zip -o darklua.zip
powershell -command "Expand-Archive -Path darklua.zip -DestinationPath ."

REM Run the build script
lua53 buildScript.lua
