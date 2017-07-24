#!/bin/bash
#
# Po-Lin Chiu   2017.05.19 - Created.
#               2017.06.05 - Make the file moving to run in the background.  
#


tif_file_root="../tifstack/CF1F0_"
mrc_file_root="cf1f0_"
gain_reference="gain_reference.mrc"
start_number=10
end_number=100
super_pixel_size=0.525
frame_dose=1.451247


#################### Main #####################
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
-Iter 10 \
-Tol 0.5 \
-FtBin 1.5 \
-Mag $(get_magdist_params "${file_magdist}") \
-Kv 300 \
-PixSize ${super_pixel_size} \
-FmDose ${frame_dose} \
-Patch 5 5 \
-Gpu 0 1 2 >> ${mrc_file_root}${file_number}_motioncor2log.txt

        /opt/motioncor2/MotionCor2-01-30-2017 -InMrc ${mrc_file_root}${file_number}_nstack.mrc \
-OutMrc ${mrc_file_root}sumavg_less_${file_number}.mrc \
-Iter 10 \
-Tol 0.5 \
-FtBin 1.5 \
-Mag $(get_magdist_params "${file_magdist}") \
-Kv 300 \
-PixSize ${super_pixel_size} \
-FmDose ${frame_dose} \
-Throw 2 \
-Trunc 30 \
-Patch 5 5 \
-Gpu 0 1 2 >> ${mrc_file_root}${file_number}_motioncor2log.txt
    fi
    
    # Moving out files to get some space. 
    rm -f ${mrc_file_root}${file_number}.mrc
    rm -f ${mrc_file_root}${file_number}_nstack.mrc
done

echo "Done."


