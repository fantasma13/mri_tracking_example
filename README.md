# MRI TRACKING EXAMPLE
This is sample code associated with the paper [**A Modular Motion Compensation Pipeline for Prospective Respiratory Motion Correction of Multi-Nuclear MR Spectroscopy**](https://doi.org/10.1038/s41598-024-61403-w) by **Wampl et al.** (2024). 

This is a wrapper around [OpenCV](https://opencv.org) tracking functionality to demonstrate the applicability to MRI.

This code and data are for illustration and educational purposes only. It comes as is, use at your own risk, the authors take no warranty.

The module comes in two parts, the C++ code and a matlab interface. First, build the C++ interface. We used linux for
development and testing. You may have varying success when trying on other OSes. Please let me know if you make it work.

## Prerequisits
You need to have a recent copy of the following software

* [cmake](https://cmake.org)
* [OpenCV](https://opencv.org), version >= 3
* a C/C++ compiler, e.g. g++

## Build C++ sources
First, go into src, create a build directory.
```bash
cd src
mkdir build
cd build
cmake ..
```

Check the output and make sure all errors are corrected. Refer to cmake documentation if you have trouble finding
libraries that you know are installed.
```bash
make 
sudo make install
```

This will install the libraries and executables in /usr/local/lib and /usr/local/bin, respectively. 

Add /usr/local/lib to LD_LIBRARY_PATH in your environment.
```bash
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
```


## MATLAB

We used releases 2021B and 2023A

* OXSA is required to import DICOM images (available on github: [OXSA](https://github.com/OXSAtoolbox/OXSA)).

Prepare the C++/MATLAB interface by running in MATLAB
```MATLAB
mexgen_tracking
mexgen_calcshiftvector
```

### Optional
Some older versions of MATLAB require the LD_LIBRARY_PATH to be set after generation of the interface files but prior to starting MATLAB. Therefore, close MATLAB and add the new files to the LD_LIBRARY_PATH. From a shell run the following, replace '*F_U_L_L__P_A_T_H*' by the the actual full path to the cloned repository (i.e., where the new files recide).
```
export LD_LIBRARY_PATH="F_U_L_L__P_A_T_H/matlab/libtrackinginmatlab:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="F_U_L_L__P_A_T_H/matlab/libcalcshiftvector:$LD_LIBRARY_PATH"
```
Now, start MATLAB from this shell!

### Test
Try everything worked by running the example script in MATLAB:
```MATLAB
mri_example_tracking()
```
After successful completion, the script should display a figure with the motion trace of the moving phantom in patient coordinates (sagittal/coronal/transversal).
You can try different phantom datasets by providing the appropriate number:
```MATLAB
example_number = 2;
mri_example_tracking(example_number)
```


---

## Troubleshooting

The Matlab C++ interface is notorious in not working. There are several important steps.

Make sure LD_LIBRARY_PATH is set correctly before starting matlab. Also, use system('ldd -d libtrackinginmatlab.so') to
ensure all dependencies are met. If all fails, use the binary from the command line for tracking. SVD (libcalcshiftvector.so)
ususally is simpler to make work.

