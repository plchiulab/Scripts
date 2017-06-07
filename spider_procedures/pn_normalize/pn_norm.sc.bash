#!/bin/tcsh -f
# The script to run normalization for particle images using SPIDER. 
# The procedure automatically generates the noise background to estimate the 
# noise variance. 
#
# Requires 'pn_normalize.spi' and 'make_noise.spi'. 
#
# Po-Lin Chiu   2017.07.07 - Created. 
#

set box_size = 60
    # the box size

set outer_radius = 85			
    # The size of the outer radius for alignment mask
    #   - about 20-40% larger than your object radius

set micg_root = "rubisco"					
    # the root name of the raw micrograph
    
set out_prtc_stack_root	= "prtc_"	
    # the root name of the output stack 


###########
# PROGRAM
###########
# Replace the parameter in the pn_normalize.spi procedure file for execution in SPIDER.
sed "s/BOX_SIZE/${box_size}/g" pn_normalize.spi | sed "s/OUT_RADIUS/${outer_radius}/g" | sed "s/MICG_ROOT/${micg_root}/g" | sed "s/PRTC_ROOT/${out_prtc_stack_root}/g" > b21.spi

# Run SPIDER program.
set spider="/opt/spiderweb/22.03/spider/bin/spider_osx_64"

${spider} << EOSc 
spi 
b21
en d
EOSc

printf "\nDone. "
exit()


