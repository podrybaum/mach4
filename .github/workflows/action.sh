# Install Lua 5.3 and other dependencies
sudo apt install -y lua5.3 libgtk2.0-dev libwxgtk3.0-gtk3-dev liblua5.3-dev cmake unzip curl build-essential

# Clone wxLua and build it with CMake
git clone https://github.com/pkulchenko/wxlua.git
cd wxlua/wxLua

# Create build directory and compile wxLua
mkdir build
cd build
cmake ..
make
sudo make install

# Navigate back to your Mach4 directory (adjust if your actual directory is different)
cd ../../../mach4

# Download and unzip darklua
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-linux-x86_64.zip -o darklua.zip
unzip darklua.zip

# Run your build script
lua buildScript.lua
