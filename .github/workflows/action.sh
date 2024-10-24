sudo apt install -y lua5.3
sudo apt install -y libwxbase3.0-0v5 libwxgtk3.0-gtk3-0v5 wxlua
cd mach4
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-linux-x86_64.zip -o darklua.zip
unzip darklua.zip
lua buildScript.lua
