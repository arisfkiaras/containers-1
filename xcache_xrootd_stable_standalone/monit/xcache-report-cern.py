#!/usr/bin/env python3.6

import os
import sys
from glob import glob
import struct
import time
import datetime
import requests
import json
import logging
import argparse

parser = argparse.ArgumentParser(description="Log level")

parser.add_argument("--log",required=False,dest="loglevel",help="Log level")
parser.set_defaults(loglevel="INFO")

arg = parser.parse_args()
loglevel = str(arg.loglevel)

numeric_level = getattr(logging, loglevel.upper(), None)
if not isinstance(numeric_level, int):
    raise ValueError('Invalid log level: %s' % loglevel)
logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',level=numeric_level,filename='xcache-report-cern.log')

BASE_DIR = '/data/xrd'

ct 		= time.time()
start_time 	= ct - 3600/4
end_time 	= ct
now 		= datetime.datetime.now()
timestamp 	= datetime.datetime.timestamp(now)
#print(' * Reporter Start Time', start_time)
#print(' * Reporter End Time', end_time) 
#print(' * Timestamp', timestamp) 

## The .sh substitutes the following exporting.
#os.environ['XC_SITE'] 			= 'ESCAPE_CERN_XCACHE'
#os.environ['XC_REPORT_COLLECTOR'] 	= 'http://escape-wp2-rucio-demo.cern.ch:8080'
#os.environ['XC_REPORT_COLLECTOR']      = 'http://monit-metrics:10012/'

if 'XC_SITE' not in os.environ:
	print("*** XCache Reporter: Must set $XC_SITE. Exiting.")
	sys.exit(1)
if 'XC_REPORT_COLLECTOR' not in os.environ:
	print("*** XCache Reporter: Must set $XC_REPORT_COLLECTOR. Exiting.")
	sys.exit(1)

site 		= os.environ['XC_SITE']
collector 	= os.environ['XC_REPORT_COLLECTOR']
machine 	= os.environ['HOSTNAME']
reports = []


def get_info(filename):

	fin = open(filename, "rb")

	_, = struct.unpack('i', fin.read(4))
#	print (" * File Version (version 1 does not show AttachTime):", _)
	bs, = struct.unpack('q', fin.read(8))
#	print (' * Block Size (specified in xcache.cfg - pfc.blocksize):', bs)
	fs, = struct.unpack('q', fin.read(8))
#	print (' * File Size:', fs)

	buckets = int((fs - 1) / bs + 1)
#	print (' * Number of Blocks:', buckets)

	StateVectorLengthInBytes = int((buckets - 1) / 8 + 1)
	sv = struct.unpack(str(StateVectorLengthInBytes) + 'B', fin.read(StateVectorLengthInBytes))  # disk written state vector
#	print (' * Disk written State Vector:\n *->', sv, '<-*')

	chksum, = struct.unpack('16p', fin.read(16))
#	print (' * Checksum:', chksum.hex())

	time_of_creation, = struct.unpack('Q', fin.read(8))
#	print (' * Time of Creation:', datetime.datetime.fromtimestamp(time_of_creation))

	accesses, = struct.unpack('Q', fin.read(8))
#	print (' * Number of Accesses:', accesses)

	last_access_time = os.stat(filename).st_atime
#	print(filename, ' * Time of Last Access:', last_access_time)

	last_modification_time = os.stat(filename).st_mtime
#	print(filename, ' * Time of Last Data Modification:', last_modification_time)
	
	last_statuschange_time = os.stat(filename).st_ctime
#	print(filename, ' * Time of Last Status Change', last_statuschange_time*1000)
#	print(filename.replace(BASE_DIR, '').replace('/data/xrd/', '').replace('.cinfo', ''))

	rec = {
		'timestamp':		int(timestamp *1000),
		'producer':		'escape_wp2', 
		'type':			'XCache_data',
		'sender':		'XCache',
		'site':			site,
		'site_collector':	collector,
		'site_machine':		machine,
		'reporter_start_time':	int(start_time *1000),
		'reporter_end_time':	int(end_time *1000),
		'file':			filename.replace(BASE_DIR, '').replace('/data/xrd/', '').replace('.cinfo', ''),
		'file_version':		_,
		'os_file_last_access_time': 		int(last_access_time *1000),
		'os_file_last_modification_time': 	int(last_modification_time *1000),
		'os_file_last_statuschange_time': 	int(last_statuschange_time *1000),
		'file_blocksize':	bs,
		'file_size':		fs,
		'file_blocks':		buckets,
		'file_checksum':	chksum.hex(),
		'file_created_at':	int(time_of_creation *1000),
		'file_accesses':	accesses
	}

	min_access = max(0, accesses - 20)
	for a in range(min_access, accesses):
		attach_time, 	= struct.unpack('Q', fin.read(8))
		detach_time, 	= struct.unpack('Q', fin.read(8))
		bytes_disk, 	= struct.unpack('q', fin.read(8))
		bytes_ram, 	= struct.unpack('q', fin.read(8))
		bytes_missed, 	= struct.unpack('q', fin.read(8))
#		print (	' * Access Number:', 	a,'\n', 
#			' * Time of Attach:', 	datetime.datetime.fromtimestamp(attach_time),'\n',
#			' * Time of Detach:', 	datetime.datetime.fromtimestamp(detach_time),'\n',
#			' * Bytes Disk:', 	bytes_disk,'\n',
#			' * Bytes RAM:', 	bytes_ram,'\n',
#			' * Bytes Missed:', 	bytes_missed,'\n')
		if detach_time > start_time and detach_time < end_time:
			dp = rec.copy()
			dp['file_access_number']	= a
			dp['file_attached_at'] 		= int(attach_time *1000)
			dp['file_detached_at'] 		= int(detach_time *1000)
			dp['file_bytes_disk'] 		= bytes_disk
			dp['file_bytes_ram'] 		= bytes_ram
			dp['file_bytes_missed'] 	= bytes_missed
			reports.append(dp)


files = [y for x in os.walk(BASE_DIR) for y in glob(os.path.join(x[0], '*.cinfo'))]
#print(' ** ', files)

for filename in files:
	last_modification_time = os.stat(filename).st_mtime
#	print(' ** ', filename, last_modification_time)
	if last_modification_time > start_time and last_modification_time < end_time:	
		get_info(filename)

#print(' **-> ', reports)
#print(datetime.datetime.fromtimestamp(timestamp)," * XCache Reporter: Files touched:", len(reports))
logging.info(' * XCache Reporter: Files touched: {}'.format(len(reports)))
if len(reports) > 0:
#	r = requests.post(collector, json=reports)
	r = requests.post(collector, data=json.dumps(reports), headers={ "Content-Type": "application/json; charset=UTF-8"})
#	print(' * XCache Reporter: Indexing response:', r.status_code)
	logging.info(' * XCache Reporter: Indexing response: {}'.format(r.status_code))
#	print(' * XCache Reporter: Headers:', r.request.headers)
#	print(' * XCache Reporter: Body:', r.request.body)
else:
#	print(" * XCache Reporter: Nothing to report!")
	logging.warning(' * XCache Reporter: Nothing to report!')

