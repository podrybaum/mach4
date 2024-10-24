apt update
apt install -y lua5.3
ln -s /usr/bin/lua5.3 /usr/bin/lua
git clone https://github.com/podrybaum/mach4.git
cd mach4
git checkout dev
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-linux-x86_64.zip -o darklua.zip
unzip darklua.zip
lua buildScript.lua
