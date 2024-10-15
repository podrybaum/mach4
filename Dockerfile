# escape=`
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022
RUN if not exist C:\Mach4 mkdir C:\Mach4
WORKDIR C:\Mach4
COPY . .
RUN @echo off
RUN cd\
ENV LUA_VERSION=5.3.6
ENV LUA_INSTALL_DIR=C:\Lua\lua-%LUA_VERSION%
RUN echo Dowloading Lua %LUA_VERSION%
RUN curl -L -o lua-%LUA_VERSION%.tar.gz https://www.lua.org/ftp/lua-%LUA_VERSION%.tar.gz
RUN echo Extracting Lua...
RUN tar -xvf lua-%LUA_VERSION%.tar.gz
RUN echo Installing Lua...
RUN if not exist %LUA_INSTALL_DIR% ( mkdir %LUA_INSTALL_DIR% 2>nul && if not errorlevel 1 ( move lua-%LUA_VERSION% C:\Lua ) )
RUN echo Adding Lua to PATH...
RUN setx PATH "%PATH%;%LUA_INSTALL_DIR%"
RUN echo Cleaning up...
RUN del lua-%LUA_VERSION%.tar.gz
RUN cd\
RUN echo Downloading Luarocks...
RUN curl -L -o luarocks-3.11.1.zip https://luarocks.github.io/luarocks/releases/luarocks-3.11.1-win32.zip
RUN echo Extracting Luarocks...
ENV LUAROCKS_INSTALL_DIR=C:\Luarocks
RUN if not exist %LUAROCKS_INSTALL_DIR% (mkdir %LUAROCKS_INSTALL_DIR%)
RUN tar -xvf luarocks-3.11.1.zip
RUN cd luarocks-3.11.1-win32
RUN echo Installing Luarocks...
RUN C:\Lua\lua-5.3.6\lua53 install.bat -P %LUAROCKS_INSTALL_DIR% --SELFCONTAINED --LV=5.3 --LUA=%LUA_INSTALL_DIR% --MW --NOADMIN -Q
RUN echo Cleaning up...
RUN cd..
RUN del luarocks-3.11.1.zip
RUN echo Installing Git...
RUN winget install Git.Git
RUN cd C:\Mach4
RUN echo Cloning source repository...
RUN git clone https://github.com/podrybaum/mach4.git -b dev
ENV COMPILER_INSTALL_DIR=C:\Compilers
RUN if not exist %COMPILER_INSTALL_DIR% ( mkdir %COMPILER_INSTALL_DIR% )
RUN cd\
RUN echo Downloading C compilers...
RUN curl -L -o mingw.zip https://github.com/brechtsanders/winlibs_mingw/releases/download/14.2.0posix-19.1.1-12.0.0-ucrt-r2/winlibs-i686-posix-dwarf-gcc-14.2.0-llvm-19.1.1-mingw-w64ucrt-12.0.0-r2.zip
RUN echo Extracting C compilers...
RUN tar -xvf mingw.zip -C %COMPILER_INSTALL_DIR%
ENV CC=%COMPILER_INSTALL_DIR%\mingw32\bin\i686-w64-mingw32-gcc.exe


