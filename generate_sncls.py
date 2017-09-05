#!/usr/bin/env python

"""
Parse a JSON formatted list of SNCL targets for the sample_mean metric and
use this to create separate javascript files that define global variables
used in the creation of SNCL selectors:

 * networks.js  -- defines G_networks:  array of network names
 * stations.js  -- defines G_stations:  dictionary of {net1:[sta1,sta2,sta3,...],..}
 * locations.js -- defines G_locations:  dictionary of {net1.sta1:[loc1,loc2,loc3,...],...}
 * channels.js  -- defines G_channels:  dictionary of {net1.sta1.loc1:[cha1,cha2,cha3,...],...}

These are used in js/__Databrowser.js for the dynamic creation of SNCL selectors.

The intention is for this script to be run regulary by a cron job witho utput
going to the databrowser js/ directory.

A single argument is accepted specifying the location of the directory in which these files
should be placed.
"""

import sys, os     # for argument and file handling
import json        # for json parsing
import urllib2     # for URL handling

# First argument, if supplied, is destination directory.
if len(sys.argv) < 2:
	sys.stderr.write('ERROR in generate_sncls.py: Destination directory must be specified as an argument.')
	sys.exit(1)
else:
	destDir = sys.argv[1]
	if not destDir.endswith('/'):
		destDir += '/'

# Parse json return from IRIS DMC 'targets' webserivce
sncls = json.load(urllib2.urlopen("http://service.iris.edu/mustangbeta/targets/1/query?metric=sample_mean&format=json"))

# Set up empty dictionaries
stations = {}   # key=net, val=[sta]
locations = {}  # key=(net,sta), val=[loc]
channels = {}   # key=(net,sta,loc), val=[cha]

# Fill in dictionaries
for sncl in sncls['targets']:
	net = sncl['net']
	sta = sncl['sta']
	loc = sncl['loc']
	cha = sncl['chan']
	if net and len(net) > 0 and \
		sta and len(sta) > 0 and \
		cha and len(cha) > 0:
		if not loc or len(loc) == 0:
			loc = "--"
		if not net in stations:
			stations[net] = set([sta,])
		else:
			stations[net].add(sta)
		if not (net,sta) in locations:
			locations[(net,sta)] = set([loc,])
		else:
			locations[(net,sta)].add(loc)
		if not (net,sta,loc) in channels:
			channels[(net,sta,loc)] = set([cha,])
		else:
			channels[(net,sta,loc)].add(cha)

# Networks
keysliststr = stations.keys()
valslist = list(stations.values())
valsliststr = [list(x) for x in valslist]
stationszip = zip(keysliststr,valsliststr)
outputFile = destDir + 'networks.js'
jsontofile = open(outputFile,'w')
jsontofile.write("var G_networks = %s;\n" % (json.dumps(sorted(dict(stationszip)))))
jsontofile.close()

# Stations
outputFile = destDir + 'stations.js'
jsontofile = open(outputFile,'w')
jsontofile.write("var G_stations = %s;\n" % (json.dumps(dict(stationszip))))
jsontofile.close()

# Locations
keyslist = list(locations.keys())
keysliststr = [".".join(x) for x in keyslist]
valslist = list(locations.values())
valsliststr = [list(x) for x in valslist]
locationszip = zip(keysliststr,valsliststr)
outputFile = destDir + 'locations.js'
jsontofile = open(outputFile,'w')
jsontofile.write("var G_locations = %s;\n" % (json.dumps(dict(locationszip))))
jsontofile.close()

# Channels
keyslist = list(channels.keys())
keysliststr = [".".join(x) for x in keyslist]
valslist = list(channels.values())
valsliststr = [list(x) for x in valslist]
channelszip = zip(keysliststr,valsliststr)
outputFile = destDir + 'channels.js'
jsontofile = open(outputFile,'w')
jsontofile.write("var G_channels = %s;\n" % (json.dumps(dict(channelszip))))
jsontofile.close()

