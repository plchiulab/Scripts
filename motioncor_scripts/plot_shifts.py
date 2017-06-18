#!/usr/bin/env python
# Plot the shifts of the full frames from the MotionCor2 results. 
#
# Po-Lin Chiu  2017.06.18 - Created
#

import numpy
import matplotlib.pyplot as plt
import matplotlib.lines as lines



in_log_file = "/data02/plchiu/Jy-CF1F0/cryo-061517/cf1f0_0242_motioncor2log.txt"
frame_number = 50

lines_log_file = open(in_log_file, 'r').readlines()
shifts = []
for i, line in enumerate(lines_log_file):
    if 'Full-frame alignment shift' in line: 
        error_rate = float(lines_log_file[i-2].split(':')[2])
        
        for n in xrange(frame_number):
            shifts.append([float(lines_log_file[i+n+1].split(':')[1].split()[0]), float(lines_log_file[i+n+1].split(':')[1].split()[1])])

shifts = numpy.array(shifts)

fig, ax = plt.subplots()
for i in xrange(frame_number):
    ax.plot(shifts[i][0], shifts[i][1], marker='o')
plt.show()


print "The total error rate of the motion correction: %f" % error_rate
print shifts
