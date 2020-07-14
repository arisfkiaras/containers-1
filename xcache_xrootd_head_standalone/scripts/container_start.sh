#!/bin/bash

if [ ! -f /tmp/container_cert/hostcert.pem ]; then
    echo "The hostcert.pem and hostkey.pem of XCache should be placed locally in /tmp/container_cert"
    echo "Then do 'docker run' with option '-v /tmp/container_cert/hostcert.pem:/tmp/container_cert/hostcert.pem -v /tmp/container_cert/hostkey.pem:/tmp/container_cert/hostkey.pem'"
    exit
fi

if [ ! -f /tmp/container_cert/xrdcert.pem ]; then
    echo "The xrdcert.pem and xrdkey.pem of XCache should be placed locally in /tmp/container_cert"
    echo "Then do 'docker run' with option '-v /tmp/container_cert/xrdcert.pem:/tmp/container_cert/xrdcert.pem -v /tmp/container_cert/xrdkey.pem:/tmp/container_cert/xrdkey.pem'"
    exit
fi

echo "Setting xrootd:xrootd ownership"

GRID_SECURITY='/etc/grid-security/'
XRD="$GRID_SECURITY/xrd/"

cp /tmp/container_cert/hostcert.pem $GRID_SECURITY
cp /tmp/container_cert/hostkey.pem  $GRID_SECURITY

chown -R xrootd:xrootd $GRID_SECURITY/hostcert.pem
chown -R xrootd:xrootd $GRID_SECURITY/hostkey.pem

cp /tmp/container_cert/xrdcert.pem $XRD
cp /tmp/container_cert/xrdkey.pem  $XRD

chown -R xrootd:xrootd $XRD

chown -R xrootd:xrootd /data/xrd

export DEAMON_INSTANCE="xcache"
echo "XRootD - xrootd daemon instance $DEAMON_INSTANCE"

sudo -E -u xrootd /usr/bin/xrootd -l /var/log/xrootd/xrootd.log -c /etc/xrootd/xrootd-$DEAMON_INSTANCE.cfg -k fifo -s /var/run/xrootd/xrootd-$DEAMON_INSTANCE.pid -n $DEAMON_INSTANCE &

sudo -E -u xrootd /bin/voms-proxy-init --cert /etc/grid-security/xrd/xrdcert.pem --key /etc/grid-security/xrd/xrdkey.pem --voms escape:/escape/Role=xcache -valid 12:00 &> VOMS-proxy-init.out
sudo -E -u xrootd /bin/voms-proxy-info -all &> VOMS-proxy-info.out

echo "Starting crond deamon"
/usr/sbin/crond

cat > /etc/cron.d/xcache-report-cern << EOF
SHELL=/bin/bash 
PATH=/sbin:/bin:/usr/sbin:/usr/bin 
MAILTO=root HOME=/  
*/15 * * * * root /root/xcache-report-cern.sh
EOF

cat > /etc/cron.d/VOMS-cron << EOF
SHELL=/bin/bash 
PATH=/sbin:/bin:/usr/sbin:/usr/bin 
MAILTO=root HOME=/  
0 */12 * * * xrootd /bin/voms-proxy-init --cert /etc/grid-security/xrd/xrdcert.pem --key /etc/grid-security/xrd/xrdkey.pem --voms escape:/escape/Role=xcache -valid 12:00
EOF

echo "Done!"
sleep infinity