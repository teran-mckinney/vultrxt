#!/bin/sh

TAG=v0.11C

pkg update -qf
pkg upgrade -qfy

pkg install -qfy pwgen autotools pkgconf gmake boost-libs openssl db48 git curl micro_httpd micro_inetd #FIXME TODO: Remove git
chmod 700 /root
mkdir /root/.bitcoin
echo "rpcpassword=$(pwgen -s 20 1)" > /root/.bitcoin/bitcoin.conf

mkdir bitcoinxt; cd bitcoinxt
#FIXME This seems to have a 302 loop right now.
#fetch -qo - https://github.com/bitcoinxt/bitcoinxt/archive/$TAG.tar.gz | tar xzf -
git clone https://github.com/bitcoinxt/bitcoinxt.git
cd bitcoinxt
git checkout $TAG
./autogen.sh
./configure --with-gui=no --without-miniupnpc --disable-wallet
gmake
gmake install

fetch -q \
https://raw.githubusercontent.com/teran-mckinney/bitnoder/master/fs/etc/rc.local \
-o /etc/rc.local

fetch -q \
https://raw.githubusercontent.com/teran-mckinney/bitnoder/master/fs/usr/local/bin/honeybadgermoneystats \
-o /usr/local/bin/honeybadgermoneystats

# 2GiB node for testnet, 4GiB node for main
if [ "$(sysctl -n hw.realmem)" -gt 4000000000 ]; then
	echo > /usr/local/etc/bitnoder.conf
else
	echo 'TESTNET=1' > /usr/local/etc/bitnoder.conf
fi

# This is a slow DD for a reason.
dd if=/dev/zero bs=10M count=400 of=/var/tmp/swap
mkswap /var/tmp/swap
echo 'md99	none	swap	sw,file=/var/tmp/swap	0	0' >> /etc/fstab
# Should look into swap blocksize down the road
swapon -a

chmod 500 /etc/rc.local
chmod 500 /usr/local/bin/honeybadgermoneystats

/etc/rc.local
