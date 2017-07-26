#!/bin/bash
#
# Gain reference transformation: 
#     newstack -rot -270 gatanRef.mrc gatanRef_rot-270.mrc
#     clip flipy gatanRef_rot-270.mrc  gatanRef_rot-270_flipy.mrc
#
# For packed and unpacked tiffs:
#   Packed frames -
#     clip unpack packed_frames.mrc gain_ref.mrc norm_frames.mrc
#   Unpacked frames (working in the mode 2) - 
#     clip mult -m 2 packed_frames.mrc gain_ref.mrc norm_frames.mrc
#
# Po-Lin Chiu   2017.05.19 - Created.
#               2017.06.05 - Make the file moving to run in the background.  
#               2017.07.24 - Not perform the correction with error rate larger 
#                            than 2.0. 
#
#


tif_file_root="tifstack2/CF1F0_"
mrc_file_root="micg_corr/cf1f0_"
gain_reference="tifstack2/gain_reference.mrc"
start_number=3001
end_number=6097
super_pixel_size=0.525
frame_dose=1.451247

#################### Advanced Internals #####################
error_rate_threshold=2.0



#################### Functions #####################
function get_magdist_params {
python - << eof
with open('$1', 'r') as f:
    for i, line in enumerate(f):
        if " Stretch only parameters would be as follows :-" in line:
            start = i

text = open('$1', 'r').readlines()
dist_angle = float(text[start+2].split('=')[1])
major_axis = float(text[start+3].split('=')[1])
minor_axis = float(text[start+4].split('=')[1])  

print "%f %f %f" % (major_axis, minor_axis, dist_angle)
eof
}

function get_global_error_rate {
python - << eof
with open('$1', 'r') as f:
    for i, line in enumerate(f):
        if "Full-frame alignment shift" in line:
            start = i - 2

error_rate = float(open('$1', 'r').readlines()[start].split(':')[2]) 

print "%f" % error_rate
eof
}

#################### Main #####################
for i in $(seq ${start_number} ${end_number})
do
    file_number=`printf "%04d" ${i}`
    tif_filename=`ls ${tif_file_root}* | grep "${tif_file_root}${file_number}"`
    if [[ -f ${tif_filename} ]]; then
        # Unpack the image data
        tif2mrc ${tif_filename} ${mrc_file_root}${file_number}.mrc
        clip unpack ${mrc_file_root}${file_number}.mrc ${gain_reference} ${mrc_file_root}${file_number}_nstack.mrc


        # Correct magnification distortion
        /opt/mag_distort_estimate/1.0.1/bin/mag_distortion_estimate_openmp_1_12_16.exe >> ${mrc_file_root}${file_number}_magdist.txt << eof
${mrc_file_root}${file_number}_nstack.mrc
${mrc_file_root}${file_number}_spect.mrc
${mrc_file_root}${file_number}_spect_rota.mrc
${mrc_file_root}${file_number}_spect_corr.mrc
${super_pixel_size}
NO
eof

        file_magdist="${mrc_file_root}${file_number}_magdist.txt"

        # Motion correction
        echo "Motion correction on ${mrc_file_root}${file_number}. "
        /opt/motioncor2/MotionCor2-01-30-2017 -InMrc ${mrc_file_root}${file_number}_nstack.mrc \
-OutMrc ${mrc_file_root}sumavg_full_${file_number}.mrc \
-OutStack 1 \
-LogFile ${mrc_file_root}${file_number}_motioncor2log.txt \
-Iter 10 \
-Tol 0.5 \
-FtBin 1.5 \
-Mag $(get_magdist_params "${file_magdist}") \
-Kv 300 \
-PixSize ${super_pixel_size} \
-FmDose ${frame_dose} \
-Patch 5 5 \
-Gpu 0 1 2 >> ${mrc_file_root}${file_number}_motioncor2log.txt

        # Check the quality of the alignment. 
#        error_rate=$(get_global_error_rate "${mrc_file_root}${file_number}_motioncor2log.txt")
#        if (( $(echo "$error_rate_threshold > $error_rate" | bc -l) )); then
#            /opt/motioncor2/MotionCor2-01-30-2017 -InMrc ${mrc_file_root}${file_number}_nstack.mrc \
#-OutMrc ${mrc_file_root}sumavg_less_${file_number}.mrc \
#-Iter 10 \
#-Tol 0.5 \
#-FtBin 1.5 \
#-Mag $(get_magdist_params "${file_magdist}") \
#-Kv 300 \
#-PixSize ${super_pixel_size} \
#-FmDose ${frame_dose} \
#-Throw 2 \
#-Trunc 10 \
#-Patch 5 5 \
#-Gpu 0 1 2
#        else
#            # rm -f ${mrc_file_root}sumavg_full_${file_number}*
#            echo "The image of ${file_number} has a large alignment error rate. "
#        fi
#
#    fi
    
    # Moving out files to get some space. 
    rm -f ${mrc_file_root}${file_number}.mrc
    rm -f ${mrc_file_root}${file_number}_nstack.mrc
    echo "========================================================="

done

echo "Done."


