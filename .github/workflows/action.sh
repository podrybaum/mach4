# Install Lua 5.3 and other dependencies
sudo apt install -y lua5.3 

# Download and unzip darklua
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-linux-x86_64.zip -o darklua.zip
unzip darklua.zip

# Run your build script
lua buildScript.lua
