#!/usr/bin/env python

from math import *
import numpy as np
import matplotlib.pyplot as plt
import os

def get_travel_distance(algn_shifts_x, algn_shifts_y):
    travel_distance = 0.0

    for i in xrange(len(algn_shifts_x) - 1):
        dx = (algn_shifts_x[i+1] - algn_shifts_x[i])
        dy = (algn_shifts_y[i+1] - algn_shifts_y[i])
        dist = sqrt(pow(dx, 2) + pow(dy, 2))
        travel_distance = travel_distance + dist
    
    avg = float(travel_distance) / (len(algn_shifts_x)-1)

    return travel_distance, avg

def get_shifts(in_log):
    data = open(in_log, 'r').readlines()

    algn_shifts_x = []
    algn_shifts_y = []

    for line in data:
        if '...... Frame' in line:
            shft_x = float(line.split()[-2])
            shft_y = float(line.split()[-1])
        
            algn_shifts_x.append(shft_x)
            algn_shifts_y.append(shft_y)
    
    return algn_shifts_x, algn_shifts_y

def get_overall_error(in_log):
    data = open(in_log, 'r').readlines()
    
    for line in data:
        if 'Full-frame alignment shift' in line:
            ind_err = data.index(line) - 2
            break
    
    error = float(data[ind_err].split()[-1])

    return error


for i in range(2400):
    in_log = "micg_frm_rmvd/cf1f0_%04d_motioncor2log.txt" % (i+1)
    
    if os.path.isfile(in_log):
        x, y = get_shifts(in_log)
        travel_dist, avg_dist = get_travel_distance(x, y)
        error = get_overall_error(in_log)

        if error > 2.0:
            print "%04d ..... Total travel distance in pixels:  %f" % (i+1, travel_dist)
            print "     ..... The distance per frame in pixels: %f" % avg_dist       
            print "     ..... Total error:                      %f" % error


in_log = "micg_frm_rmvd/cf1f0_2186_motioncor2log.txt"

algn_shifts_x, algn_shifts_y = get_shifts(in_log)
algn_shifts_x = np.array(algn_shifts_x)
algn_shifts_y = np.array(algn_shifts_y)
fig, ax = plt.subplots()
ax.plot(algn_shifts_x, algn_shifts_y, 'o-', lw=2)
ax.set_title('Trajectory')
#plt.savefig("temp.png")
plt.show()

        

