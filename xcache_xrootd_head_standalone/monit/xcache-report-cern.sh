#!/bin/bash

export XC_SITE="ESCAPE_CERN_XCACHE"
export XC_REPORT_COLLECTOR="http://monit-metrics:10012/"
export HOSTNAME=$HOSTNAME

python3.6 /root/xcache-report-cern.py --log=info
