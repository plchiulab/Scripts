#!/bin/tcsh -f
# Multireference alignment and classification
#   The procedure randomly generates for the first-round references.
#   Edit the variables for your processing. 
#   Run using command : ./mra.sc > mra.log &				
#
#
# Sub-procedure required:
# 		alqmd.mra
# 		center.mra
# 		combat.mra
#
# Po-Lin Chiu  Last updated: 09/29/2012
#

###########
# VARIABLES
###########

set outer_radius = 85			
    # The size of the outer radius for alignment mask
    #   - about 20-40% larger than your object radius

set inner_radius = 1			
    # The size of the inner radius for alignment mask

set factors_or_raw = 1			
    # If factors_or_raw = 1 classify based on raw data
	# If factors_or_raw = 2 classify based on factors from the PCA

set num_of_factors = 10			
    # If factors_or_raw = 2, set the number of factors to use

set num_of_groups = 100			
    # Set the number of groups to align particles into
    
set num_of_iterations = 10		
    # The number of times we should iterate alignment procedure
    
set ext = "spi"					
    # the data extension for your project (ie file_0001.EXT, EXT is extension)
    
set input_stack	= "../tempprtc"	
    # The name of the input stack to be aligned


###########
# PROGRAM
###########
# Replace the parameter in the b03template.mra procedure file for execution in SPIDER.
set stack_name = `echo $input_stack | awk -F "/" '{printf("%s",$NF)}' | awk -F "." '{printf("%s",$1)}'`
set stack_path = `echo $input_stack | awk -F "/" 'BEGIN{i=1}{while( i < NF){printf("%s/",$i); i++}}'`
set real_stack = `echo $stack_path$stack_name`

sed "s/OUT_RAD/$outer_radius/g" b03template.mra | sed "s/IN_RAD/$inner_radius/g" | sed "s/RAW/$factors_or_raw/g" | sed "s/FACTORS/$num_of_factors/" | sed "s/GROUP/$num_of_groups/" | sed "s/ITER/$num_of_iterations/" | sed "s;INPUT;$real_stack;" > b03.mra

# Run SPIDER program.
set spider="/opt/spiderweb/22.03/spider/bin/spider_osx_64"

${spider} << EOSc 
mra/$ext 
b03
en d
EOSc

# Run order.sc for each cluster.
chmod ugo+x order.sc

set num_plus=`echo $num_of_iterations | awk '{printf("%d",$1+1)}'`
set i=1
while ($i <= $num_plus)
	set current = `echo $i | awk '{printf("%02d",$1)}'`
	cd cluster$current
	../order.sc
	cd ../
	printf "\nCluster$current ordered\n"
	@ i ++
end

printf "\nDone. "
exit()
