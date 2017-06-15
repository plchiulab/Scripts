#!/bin/bash
# A batch processing with mag_distort_estimate and MotionCor2. 
# The input data should be in TIFF (LZW-compressed) format.
# Requires IMOD, mag_distort_estimate, and MotionCor2 programs. 
#
# Po-Lin Chiu  2017.05.19 - Created. 
#              2017.06.07 - Updated. 
#

tif_file_root="PS1_"
    # the root name of the input image
    
mrc_file_root="ps1_"
    # the output root name of the average in MRC format
    
gain_reference="gain_reference.mrc"
    # gain reference in MRC format
    # the dm4 format can be converted using IMOD dm2mrc program. 

start_number=1
    # image start number

end_number=1000
    # image end number

super_pixel_size=0.54
    # the pixel size of the raw image data (Å/pixel)
    
frame_dose=1.54
    # the electron dose of each frame


#################### Main #####################
prog_motion_cor2="/opt/motioncor2/MotionCor2-01-30-2017"
prog_mag_distort="/opt/mag_distort_estimate/1.0.1/bin/mag_distortion_estimate_openmp_1_12_16.exe"

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
    if [ -f ${tif_file_root}${file_number}.tif ]; then
        # Unpack the image data
        tif2mrc ${tif_file_root}${file_number}.tif ${mrc_file_root}${file_number}.mrc
        clip unpack ${mrc_file_root}${file_number}.mrc ${gain_reference} ${mrc_file_root}${file_number}_nstack.mrc

        # Correct magnification distortion
        ${prog_mag_distort} >> ${mrc_file_root}${file_number}_magdist.txt << eof
${mrc_file_root}${file_number}_nstack.mrc
${mrc_file_root}${file_number}_spect.mrc
${mrc_file_root}${file_number}_spect_rota.mrc
${mrc_file_root}${file_number}_spect_corr.mrc
${super_pixel_size}
NO
eof

        file_magdist="${mrc_file_root}${file_number}_magdist.txt"

        # Motion correction
        ${prog_motion_cor2} -InMrc ${mrc_file_root}${file_number}_nstack.mrc \
-OutMrc ${mrc_file_root}${file_number}_sumavg.mrc \
-OutStack 1 \
-Iter 10 \
-Tol 0.5 \
-FtBin 1.5 \
-Mag $(get_magdist_params "${file_magdist}") \
-Kv 300 \
-PixSize ${super_pixel_size} \
-FmDose ${frame_dose} \
-Patch 5 5 \
-Gpu 0 1 >> ${mrc_file_root}${file_number}_motioncor2log.txt
    fi
done

echo "Done."

