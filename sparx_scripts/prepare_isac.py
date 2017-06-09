#!/usr/bin/env python
#
# Po-Lin Chiu        2015.05.14 - Created. 
#


from EMAN2 import *
from sparx import *

def write_ctfs2header(ctf_txtfile, in_image, out_image):
    """
    Write the CTF parameters into the image header (for stack). 
    
    ctf_txtfile:  'sxcter.py' ctf output list
    in_image:      input image data
    out_image:     output image data with header written
    """
    import os
    import re    
    ctfs = read_text_row(ctf_txtfile) 
    f_name = os.path.basename(in_image)
    
    for i in xrange(len(ctfs)):
        im_name = ctfs[i][-1].split('/')[-1]
        im_number = (re.findall(r'\d+', im_name)[0])
        ptstk_number = (re.findall(r'\d+', in_image)[0])
        
        if (ptstk_number == im_number):
            ctf = ctfs[i]
            
            n_im = EMUtil.get_image_count(in_image)
            for j in xrange(n_im):
                a = EMData()
                a.read_image(in_image, j)
                a.set_attr("ctf", generate_ctf(ctf[:9]))
                a.write_image(out_image, -1)
            return generate_ctf(ctf[:9])
    return 0   

def flip_phases_stack(in_image, out_image, e2ctf, oversampling=1):    
    """    
    e2ctf: EMAN2 object for CTF.  
    """
    n_im = EMUtil.get_image_count(in_image)
    
    for i in xrange(n_im):
        aData = EMData()
        aData.read_image(in_image, i)
        
        im_size = aData.get_xsize()
        osam_size = im_size * oversampling
    
        if oversampling > 1:
            aData.clip_inplace(Region(-(im_size*(oversampling-1)/2), 
                                      -(im_size*(oversampling-1)/2), 
                                      osam_size, 
                                      osam_size))
        
        fft_im = aData.do_fft()
        flipim = fft_im.copy()
        e2ctf.compute_2d_complex(flipim, Ctf.CtfType.CTF_SIGN)
        fft_im.mult(flipim)
        out = fft_im.do_ift()
        out['ctf'] = e2ctf
        out['apix_x'] = e2ctf.apix
        out['apix_y'] = e2ctf.apix
        out['apix_z'] = e2ctf.apix
        out.clip_inplace(Region(int(im_size*(oversampling-1)/2), 
                                int(im_size*(oversampling-1)/2), 
                                im_size, 
                                im_size))
        out.write_image(out_image, -1)

def normalize_stack(in_image, out_image, contrast_inversion=False):
    n_im = EMUtil.get_image_count(in_image)
    if contrast_inversion:
        invert = -1.0
    else:
        invert = 1.0
    
    for i in xrange(n_im):
        a = EMData()
        a.read_image(in_image, i)
        st = Util.infomask(a, None, True)
        b = ramp((a-st[0]) / st[1] * invert) 
        b.write_image(out_image, i)  

def scale_stack(in_image, out_image, out_size=64):
    n_im = EMUtil.get_image_count(in_image)
    for i in xrange(n_im):
        a = EMData()
        a.read_image(in_image, i)
        im_size = a.get_xsize()
    
        s = float(out_size) / im_size
        b = resample(a, s)
        b.write_image(out_image, i)
        
def clean_file(filename):
    import os
    
    if os.path.isfile(filename):
        os.remove(filename)

    
def main():
    clean_file("temp1.hdf")
    clean_file("temp2.hdf")
    clean_file("temp3.hdf")    

    import glob
    file_list = glob.glob("ptrc_qfviii_*.hdf")
    ctf_list = "../../ctf_estm/3001_041315/ctf_params_3001.txt"
    
    for stack in file_list:
        print stack, EMUtil.get_image_count(stack)
        out_stack = "pre%s" % stack
        clean_file(out_stack)
        
        ctf_obj = write_ctfs2header(ctf_list, stack, "temp1.hdf")
        flip_phases_stack("temp1.hdf", "temp2.hdf", ctf_obj, oversampling=1)
        normalize_stack("temp2.hdf", "temp3.hdf", contrast_inversion=True)
        scale_stack("temp3.hdf", out_stack, out_size=64)
        
        clean_file("temp1.hdf")
        clean_file("temp2.hdf")
        clean_file("temp3.hdf")    

if __name__ == '__main__':
    main()
