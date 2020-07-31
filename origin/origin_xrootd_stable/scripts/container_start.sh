#!/bin/bash

if [ ! -f /tmp/container_cert/hostcert.pem ]; then
    echo "The hostcert.pem and hostkey.pem of XCache should be placed locally in /tmp/container_cert"
    echo "Then do 'docker run' with option '-v /tmp/container_cert/hostcert.pem:/tmp/container_cert/hostcert.pem -v /tmp/container_cert/hostkey.pem:/tmp/container_cert/hostkey.pem'"
    exit
fi

echo "Setting xrootd:xrootd ownership"

GRID_SECURITY='/etc/grid-security/'

cp /tmp/container_cert/hostcert.pem $GRID_SECURITY
cp /tmp/container_cert/hostkey.pem  $GRID_SECURITY

chown -R xrootd:xrootd $GRID_SECURITY/hostcert.pem
chown -R xrootd:xrootd $GRID_SECURITY/hostkey.pem

chown -R xrootd:xrootd /data/xrd

export MOCKDATA_INSTANCE="mockdata_port1213"
echo "XRootD - xrootd daemon instance $MOCKDATA_INSTANCE"

sudo -E -u xrootd /usr/bin/xrootd -l /var/log/xrootd/xrootd.log -c /etc/xrootd/xrootd-$MOCKDATA_INSTANCE.cfg -k fifo -s /var/run/xrootd/xrootd-$MOCKDATA_INSTANCE.pid -n $MOCKDATA_INSTANCE &

export MOCKSTORAGE_INSTANCE="mockstorage"
echo "XRootD - xrootd daemon instance $MOCKSTORAGE_INSTANCE"

sudo -E -u xrootd /usr/bin/xrootd -l /var/log/xrootd/xrootd.log -c /etc/xrootd/xrootd-$MOCKSTORAGE_INSTANCE.cfg -k fifo -s /var/run/xrootd/xrootd-$MOCKSTORAGE_INSTANCE.pid -n $MOCKSTORAGE_INSTANCE &

echo "Done!"
sleep infinity