#!/bin/sh

# This runs at the top of cloud-init. We don't even have SSHD running without
# this.

export ASSUME_ALWAYS_YES=yes

# Just have a gig free without this.
service growfs onestart

# pkg isn't installed by default on vultr, but this will bootstrap it
# with the above option of ASSUME_ALWAYS_YES=yes
pkg upgrade

pkg install ca_root_nss autotools pkgconf gmake boost-libs openssl db48 git micro_httpd micro_inetd #FIXME TODO: Remove git
chmod 700 /root
mkdir /root/.bitcoin
echo 'debug=net
maxoutbound=32
logtimemicros=1
rpcuser=*
rpcpassword=*' > /root/.bitcoin/bitcoin.conf

mkdir bitcoinxt; cd bitcoinxt
#FIXME This seems to have a 302 loop right now.
#fetch -qo - https://github.com/bitcoinxt/bitcoinxt/archive/$TAG.tar.gz | tar xzf -

# Using jtoomin's fortestnet branch.
 git clone --depth 1 https://github.com/jtoomim/bitcoinxt.git -b fortestnet
cd bitcoinxt
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
# All testnet, actually.
#if [ "$(sysctl -n hw.realmem)" -gt 4000000000 ]; then
#echo > /usr/local/etc/bitnoder.conf
#else

echo 'TESTNET=1' > /usr/local/etc/bitnoder.conf

#fi

## This is not working out as planned...
# This is a slow DD for a reason.
#dd if=/dev/zero bs=10M count=400 of=/var/tmp/swap
#mkswap /var/tmp/swap
#echo 'md99	none	swap	sw,file=/var/tmp/swap	0	0' >> /etc/fstab
# Should look into swap blocksize down the road
#swapon -a

echo 'ntpd_enable="YES"' >> /etc/rc.conf
service ntpd start

chmod 500 /etc/rc.local
chmod 500 /usr/local/bin/honeybadgermoneystats

# Let the boot process start rc.local on its own.
#/etc/rc.local
