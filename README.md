# Hem Extensions to cmake
This repository adds cmake modules you have to install to compile Hem projects.
Version: 1.1.1

## Features:
* conan.cmake based on official repository v. 0.15.0 + RTOSes + arch from CMAKE_SYSTEM_PROCESSOR
* cross-gcc-arm-toolchain.cmake

## Installation:
Just copy files to your <CMAKE_INSTALL_FOLDER>/Modules eg. /usr/share/cmake-3.15/Modules

## Revision history:
### Version 1.1.1:
* fixed caching compilers variables in toolchain file

### Version 1.1.0:
* added support for arch.cpu in conan.cmake 

### Version 1.0.0:
* Initial version with:
    * conan.cmake based on official repository v. 0.15.0 + RTOSes + arch from CMAKE_SYSTEM_PROCESSOR
    * cross-gcc-arm-toolchain.cmake
