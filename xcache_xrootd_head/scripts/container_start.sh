#!/bin/bash

if [ ! -f /etc/grid-security/hostcert.pem ]; then
    echo "The hostcert.pem and hostkey.pem of XCache should be placed locally in /etc/grid-security"
    echo "Then do 'docker run' with option '-v /etc/grid-security/hostcert.pem:/etc/grid-security/hostcert.pem -v /etc/grid-security/hostkey.pem:/etc/grid-security/hostkey.pem'"
    exit
fi

if [ ! -f /etc/grid-security/xrd/xrdcert.pem ]; then
    echo "The xrdcert.pem and xrdkey.pem of XCache should be placed locally in /etc/grid-security/xrd"
    echo "Then do 'docker run' with option '-v /etc/grid-security/xrd:/etc/grid-security/xrd'"
    exit
fi

export DEAMON_INSTANCE="xcache"
echo "XRootD - xrootd daemon instance $DEAMON_INSTANCE"

chown -R xrootd:xrootd /etc/grid-security/hostcert.pem
chown -R xrootd:xrootd /etc/grid-security/hostkey.pem
chown -R xrootd:xrootd /etc/grid-security/xrd

sudo -E -u xrootd /usr/bin/xrootd -l /var/log/xrootd/xrootd.log -c /etc/xrootd/xrootd-$DEAMON_INSTANCE.cfg -k fifo -s /var/run/xrootd/xrootd-$DEAMON_INSTANCE.pid -n $DEAMON_INSTANCE &
sudo -E -u xrootd /usr/bin/cmsd   -l /var/log/xrootd/cmsd.log   -c /etc/xrootd/xrootd-$DEAMON_INSTANCE.cfg -k fifo -s /var/run/xrootd/cmsd-$DEAMON_INSTANCE.pid   -n $DEAMON_INSTANCE &

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

sleep infinity