sudo apt install -y lua5.3
git clone https://github.com/podrybaum/mach4.git
cd mach4
curl -L https://github.com/seaofvoices/darklua/releases/download/v0.14.0/darklua-linux-x86_64.zip -o darklua.zip
unzip darklua.zip
lua buildScript.lua
