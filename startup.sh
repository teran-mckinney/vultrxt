#!/bin/sh

progress() {
	echo "vultrxt: $*" > /dev/console
	echo "vultrxt: $*"
}

# This runs at the top of cloud-init. We don't even have SSHD running without
# this.

export ASSUME_ALWAYS_YES=yes

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# pkg isn't installed by default on vultr, but this will bootstrap it
# with the above option of ASSUME_ALWAYS_YES=yes

progress 'Starting pkg upgrade'
pkg upgrade

progress 'Starting pkg install'
pkg upgrade
pkg install ca_root_nss autotools pkgconf gmake boost-libs openssl db48 git micro_httpd micro_inetd #FIXME TODO: Remove git
chmod 700 /root
mkdir /root/.bitcoin
echo 'debug=net
maxoutbound=32
logtimemicros=1
rpcuser=vultrxt
rpcpassword=vultrxtpassword' > /root/.bitcoin/bitcoin.conf
# ^ If the user and password are the same, it will fail.

mkdir /root/bitcoinxt

# tmpfs for speed and because / is too small otherwise.
# growfs seems to have problems, not sure why.
mount -t tmpfs tmpfs /root/bitcoinxt
cd /root/bitcoinxt
#FIXME This seems to have a 302 loop right now.
#fetch -qo - https://github.com/bitcoinxt/bitcoinxt/archive/$TAG.tar.gz | tar xzf -

progress 'Starting git clone'
# Using jtoomin's fortestnet branch.
git clone --depth 1 https://github.com/jtoomim/bitcoinxt.git -b fortestnet
cd bitcoinxt
./autogen.sh
./configure --with-gui=no --without-miniupnpc --disable-wallet
progress 'About to compile'
gmake -j 2
gmake install
cd /
umount /root/bitcoinxt

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

chmod 500 /etc/rc.local
chmod 500 /usr/local/bin/honeybadgermoneystats

# Let the boot process start rc.local on its own.
#/etc/rc.local
