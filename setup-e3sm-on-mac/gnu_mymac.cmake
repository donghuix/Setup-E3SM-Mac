set(NETCDF_C_PATH "/opt/homebrew/Cellar/netcdf/4.9.2_1/")
set(NETCDF_FORTRAN_PATH "/opt/homebrew/Cellar/netcdf-fortran/4.6.1/")

#set(NETCDF_PATH "/usr/local")

#string(APPEND LDFLAGS " -Wl -ld_classic -lstdc++ -framework Accelerate")
string(APPEND LDFLAGS " -lstdc++ -framework Accelerate")

string(APPEND FFLAGS " -fallow-argument-mismatch -fallow-invalid-boz ")


# This is needed to run the Fortran unit tests;
# this isn't needed to build and run CESM.
# The following paths aren't necessary on my machine because I have my PATH set so that
# the right compilers are picked up by default. But it doesn't hurt to be explicit.
set(SFC "/opt/homebrew/bin/gfortran")
set(SCC "//usr/bin/clang")
set(SCXX "/usr/bin/clang++")
set(MPIFC "/opt/homebrew/bin/mpif90")
set(MPICC "/opt/homebrew/bin/mpicc")
set(MPICXX "/opt/homebrew/bin/mpicxx")