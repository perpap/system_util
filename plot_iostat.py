#! /usr/bin/env python3

###################################################
#
# file: storage_metrics.py
#
# @Author:   Iacovos G. Kolokasis
# @Version:  20-02-2020
# @email:    kolokasis@ics.forth.gr
#
# Write here brief explanation about your code
#
###################################################

import sys, getopt
import operator
import optparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import config
import os

# Parse input arguments
usage = "usage: %prog [options]"
parser = optparse.OptionParser(usage=usage)
parser.add_option("-i", "--input", dest="input", metavar="FILE", help="Input file")
parser.add_option("-o", "--outputPath", metavar="PATH", dest="outputPath", default="output.svg", help="Output Path")
parser.add_option("-s", "--storage", dest="storage", help="Storage device e.g sdb, nvme0n1")
(options, args) = parser.parse_args()

if not os.path.exists(options.outputPath):
    os.makedirs(options.outputPath)

# Open input file 
inputFile = open(options.input, 'r')

flag = 0
userCPU = []                            # User CPU Utilization
systemCPU = []                          # System CPU Utilization
iowaitCPU = []                          # Iowait CPU
idleCPU = []                            # Idle CPU
rRqMerge = []                           # Read Request Merge
wRqMerge = []                           # Write Request Merge
readThroughput = []                     # Read Throughput Storage Device
writeThroughput = []                    # Write Throughput Storage Device
avgRqSize = []                          # Average Req. Size
avgQuSize = []                          # Average Queue Size
util = []                               # Storage Device Utilization

for line in inputFile.readlines():
    repLine = line.replace(',', '.')

    if flag == 1:
        # Reset flag
        flag = 0
        
        # Append each metric values to the proper array
        userCPU.append(float(repLine.split()[0]))
        systemCPU.append(float(repLine.split()[2]))
        iowaitCPU.append(float(repLine.split()[3]))
        idleCPU.append(float(repLine.split()[5]))

        continue

    if "avg-cpu:" in repLine:
        # Set flag to 1
        flag = 1

        continue

    if options.storage in repLine:
        # Append each metric value to the proper array
        rRqMerge.append(float(repLine.split()[1]))
        wRqMerge.append(float(repLine.split()[2]))
        readThroughput.append(float(repLine.split()[5]))
        writeThroughput.append(float(repLine.split()[6]))
        avgRqSize.append(float(repLine.split()[7]))
        avgQuSize.append(float(repLine.split()[8]))
        util.append(float(repLine.split()[13]))

        continue

#------------------------------------------------------------------------------
# CPU Utilization
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

# Prepare x-axis data
time = range(1, len(userCPU) + 1)

# Draw Plot
ax.fill_between(time, y1=userCPU, y2=0, label='User', alpha=0.5, color=config.B_color_cycle[0], linewidth=2)
ax.fill_between(time, y1=systemCPU, y2=0, label='System', alpha=0.5, color=config.B_color_cycle[3], linewidth=2)
ax.fill_between(time, y1=iowaitCPU, y2=0, label='IOwait', alpha=0.5, color=config.B_color_cycle[2], linewidth=2)
ax.fill_between(time, y1=idleCPU, y2=0, label='Idle', alpha=0.2, color=config.B_color_cycle[1], linewidth=2)

# Axis name and Title
ax.set_title('CPU Utilization', fontsize=config.fontsize)
ax.set(ylim=[0, 100])
plt.ylabel('% CPU Utilization \nby User tasks', ha="center", fontsize=config.fontsize)
plt.xlabel('Time (s)', fontsize=config.fontsize)

# Legend
plt.legend(loc='upper right')

# Lighten Borders
plt.gca().spines["top"].set_alpha(0)
plt.gca().spines["bottom"].set_alpha(.3)
plt.gca().spines["right"].set_alpha(0)
plt.gca().spines["left"].set_alpha(.3)

# Save figure
plt.savefig('%s/cpu.png' % options.outputPath, bbox_inches='tight')


#------------------------------------------------------------------------------
# User CPU Utilization
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

time = range(1, len(userCPU) + 1)

p1 = plt.plot(time, userCPU, color=config.B_color_cycle[0], label='User', zorder=2)

# Axis name
plt.ylabel('% CPU Utilization \nby User tasks', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/user_cpu.png' % options.outputPath, bbox_inches='tight')

#------------------------------------------------------------------------------
# System CPU Utilization
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

p1 = plt.plot(time, systemCPU, color=config.B_color_cycle[1], label='System', zorder=2)

# Axis name
plt.ylabel('% CPU Utilization \nby System tasks', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/sys_cpu.png' % options.outputPath, bbox_inches='tight')

#------------------------------------------------------------------------------
# IOwait CPU
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

p1 = plt.plot(time, iowaitCPU, color=config.B_color_cycle[2], label='IOwait', zorder=2)

# Axis name
plt.ylabel('% IOwait CPU Percentage Time \nWaiting for IO requests', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/iow_cpu.png' % options.outputPath, bbox_inches='tight')

#------------------------------------------------------------------------------
# Idle CPU
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

p1 = plt.plot(time, idleCPU, color=config.B_color_cycle[3], label='Idle', zorder=2)

# Axis name
plt.ylabel('% Idle CPU Percentage Time \nand no Waiting for IO requests', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/idle_cpu.png' % options.outputPath, bbox_inches='tight')

#------------------------------------------------------------------------------
# Read Throughput Storage Device
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

time = range(1, len(readThroughput) + 1)
p1 = plt.plot(time, readThroughput, color=config.B_color_cycle[4], label='Read', zorder=2)

# Axis name
plt.ylabel('Read Throughput (MB/s)', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/r_thrput.png' % options.outputPath, bbox_inches='tight')

#------------------------------------------------------------------------------
# Write Throughput Storage Device
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

p1 = plt.plot(time, writeThroughput, color=config.B_color_cycle[5], label='Write', zorder=2)

# Axis name
plt.ylabel('Write Throughput (MB/s)', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/wr_thrput.png' % options.outputPath, bbox_inches='tight', zorder=2)

#------------------------------------------------------------------------------
# Read + Write Throughput Storage Device
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

ax.fill_between(time, y1=writeThroughput, y2=0, label='Write', alpha=0.7, color=config.B_color_cycle[0], linewidth=2)
ax.fill_between(time, y1=readThroughput, y2=0, label='Read', alpha=0.7, color=config.B_color_cycle[1], linewidth=2)

# Axis name
ax.set_title('Read and Write Throughput', fontsize=config.fontsize)
plt.ylabel('Throughput (MB/s)', ha="center", fontsize=config.fontsize)
plt.xlabel('Time (s)', fontsize=config.fontsize)

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/thrput.png' % options.outputPath, bbox_inches='tight', zorder=2)

#------------------------------------------------------------------------------
# Average Request Size Storage Device
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

time = range(1, len(avgRqSize) + 1)

p1 = plt.plot(time, avgRqSize, color=config.B_color_cycle[6], label='Avg. Req. Size', zorder=2)

# Axis name
plt.ylabel('Average Size of IO requests \n(sectors)', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/avg_rq_sz.png' % options.outputPath, bbox_inches='tight')

#------------------------------------------------------------------------------
# Average Queue Size Storage Device
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

time = range(1, len(avgRqSize) + 1)

p1 = plt.plot(time, avgQuSize, color=config.B_color_cycle[6], label='Avg. Queue. Size', zorder=2)

# Axis name
plt.ylabel('Average Queue Length of IO requests \n(sectors)', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/avg_qu_sz.png' % options.outputPath, bbox_inches='tight')

#------------------------------------------------------------------------------
# Utilization of Storage Device
#------------------------------------------------------------------------------

# Plot figure with fix size
fig, ax = plt.subplots(figsize=config.fullfigsize)

# Grid
plt.grid(True, linestyle='--', color='grey', zorder=0)

time = range(1, len(util) + 1)

p1 = plt.plot(time, util, color=config.B_color_cycle[7], label='Util', zorder=2)

# Axis name
plt.ylabel('% of CPU time for IO Requests', ha="center")
plt.xlabel('Time (s)')

# Legend
plt.legend(loc='upper right')

# Save figure
plt.savefig('%s/util.png' % options.outputPath, bbox_inches='tight')
