sudo apt update
sudo apt install -y lua5.3
sudo ln -s /usr/bin/lua5.3 /usr/bin/lua
sudo git clone https://github.com/podrybaum/mach4.git
sudo cd mach4
sudo git checkout dev
sudo curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-linux-x86_64.zip -o darklua.zip
sudo unzip darklua.zip
sudo lua buildScript.lua
