#!/usr/bin/env python
from TOSSIM import Tossim
from random import *
from TestNetworkMsg import *
import sys
import socket
import os
import time

enable_main=0;
if enable_main:
	def main():
		rssi_level=sys.argv[1]
		return {'y0':rssi_level}
	rssi_level=int(main()['y0'])
else:

    noise_offset = 7 #80

    #noise_offset = 7 #84
	#noise_offset = 9 #82
	#noise_offset = 10 #81
	#noise_offset = 11 #80
	#noise_offset = 12 #79
	#noise_offset = 13 #78
	#noise_offset = 14 #77
	#noise_offset = 15 #76
	#noise_offset = 16 #75
	#noise_offset = 17 #74   ##noise levels are changed by offset change--yh
	#noise_offset = 18 #73
	#noise_offset = 19 #72
	#noise_offset = 14 #77
	#noise_offset = 16 #75
	#noise_offset = 18 #73
t = Tossim([])

#t.addChannel('printf', sys.stdout)
t.addChannel("DataFeedback", sys.stdout)
t.addChannel("receive", sys.stdout)
t.addChannel("transmission", sys.stdout)
#t.addChannel("TossimPacketModelC", sys.stdout)

#t.addChannel("Gain", sys.stdout)
#t.addChannel("AM", sys.stdout)


#t.addChannel('Gain', sys.stdout)



#Log Data
#Log = open("log.txt", "w")
#t.addChannel('radio_send', Log)

r = t.radio()
L=list()
for channel_1 in [22, 23, 24, 25, 26]:
	channel=channel_1
	neignbour_strength=-20;
	sync_rssi_strength=-10
	sync_rssi_strength_2 = -30


	for sensor in [1, 2, 10]:		# Set network topology
		if sensor == 1:
			r.add(sensor, 0, sync_rssi_strength, channel_1)	#add(source, destination, gain)
			r.add(0, sensor, sync_rssi_strength, channel_1)
		elif sensor == 2:
			r.add(sensor, 0, sync_rssi_strength_2, channel_1)	#add(source, destination, gain)
			r.add(0, sensor, sync_rssi_strength_2, channel_1)
		elif sensor == 10:
			r.add(sensor, 0, sync_rssi_strength_2, channel_1)	#add(source, destination, gain)
			r.add(0, sensor, sync_rssi_strength_2, channel_1)



f = open("topo_rssis_ch_22_ex1.txt", "r")##topo and RSSI strength
for line in f:
	s = line.split()
	if s:
		#print " ", s[0], " ", s[1], " ", s[2];
		r.add(int(s[0]), int(s[1]), float(s[2]) - 4, 22)##Topos in two channels are the same. RSSI different--yh

f = open("topo_rssis_ch_23_ex1.txt", "r")
for line in f:
	s = line.split()
	if s:
		#print " ", s[0], " ", s[1], " ", s[2];
		r.add(int(s[0]), int(s[1]), float(s[2]) - 4, 23)##It seems that the r.add is modified by Bo--yh


for node in [0, 10, 1, 2]:
	m = t.getNode(node);
	for channel in [22, 23, 24, 25, 26]:
		if channel==22:
			noise = open("noise_ch_22_26_1000.txt", "r")
			lines = noise.readlines()
		elif channel==23:
			noise = open("noise_ch_23_26_1000.txt", "r")
			lines = noise.readlines()
		for line in lines:
			strrr = line.strip()
			if (strrr != ""):
				val = int(strrr) + noise_offset
				m.addNoiseTraceReading(val, channel)
		m.createNoiseModel(channel);
	m.turnOn()
	m.bootAtTime(0)
	#print "Booting ", node, " at time ", str(0)


run_count = 10 * 1000;
#0 means not received.
while (t.time() <= 97656250*run_count):
	rcved = t.runNextEvent()

'''
for i in range(0, 500):
  t.runNextEvent();
'''