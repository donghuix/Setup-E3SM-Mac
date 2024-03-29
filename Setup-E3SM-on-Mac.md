<!--- **Author: Donghui Xu** (<donghui.xu@pnnl.gov>) -->

# Setup E3SM on Mac

## 1. Xcode

* Download and install Xcode

* Install Xcode command line developers tool by running the following command on terminal `xcode-select --install` and click on Install button

* Launch Xcode and accept licence.

## 2. Install Package Manager

* Homebrew: open terminal and type ```ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"```

* MacPort: checkout https://github.com/bishtgautam/misc-scripts-for-acme/edit/master/md-notes/Setting-ACME-on-mac.md

## 3. Install packages with homebrew

* brew install gcc cmake mpich netcdf

Note: I used ``gcc-12`` on my MacBook Pro M2 Max. To install ``mpich`` and ``netcdf`` with ``gcc-12``, I used the following command: 
```
export HOMEBREW_CC=gcc-12
brew install mpich --build-from-source
brew install netcdf --build-from-source
```

Note: If you see an error while running create_newcase that indicates perl can't find XML::LibXML, you may need to install p5-xml-libxml as well

Note for install XML::LibXML 
	```
	brew install libxml2
	cpan XML::LibXML
	```

## 4. Download E3SM code from github

* git clone https://github.com/E3SM-Project/E3SM.git e3sm_trial 
* cd e3sm_trial
* git fetch origin
* git checkout origin/master
* git submodule update  --init  --recursive

Note: Need to setup SSH key for Github: https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
Note: May need to do ``chmod 600 ~/.ssh/config``
## 5. Register your mac for E3SM

* Current master of E3SM
	1. Create a ``.cime`` folder in home directory

	2. Copy and modify ``config_machines.xml`` from your-E3SM-dir/cime_config/machines/ to ~/.cime/

	3. Create a ``gnu_mac.cmake``:
	```
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
	```

* Old version E3SM (before cime_config moved out cime)
	1. Create a ```.cime``` folder in home directory

	2. Modify and copy ```config_compilers.xml``` and ```config_machines.xml``` from ```your-E3SM-dir/cime/config/e3sm/machines/userdefined_laptop_template/``` to ```~/.cime/```
	* Find examples of modification at https://gist.github.com/donghuix/434a73a2adfbf8816cb13d0e326bb93e

## 6. Test case

* Create a new case
	```
	export RES=1x1_brazil
	export COMPSET=IELM
	export COMPILER=gnu
	export MACH=mac
	export CASE_NAME=${RES}.${COMPSET}.${COMPILER}
	```

	```
	cd your-path-to-e3sm/cime/scripts
	```

	```
	./create_newcase \
	-case ${CASE_NAME} \
	-compset ${COMPSET} \
	-res ${RES} \
	-compiler ${COMPILER} \
	-mach ${MACH}
	cd $CASE_NAME
	```
* Modify env_mach_pes.xml

* Modify env_build.xml
	```
	./xmlchange -file env_build.xml -id MPILIB -val mpich
	./xmlchange -file env_build.xml -id OS -val Darwin
	./xmlchange -file env_build.xml -id CESMSCRATCHROOT -val ${PWD}
	./xmlchange -file env_build.xml -id EXEROOT -val ${PWD}/bld
	```

* Modify env_run.xml
	```
	./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_END -val 2000
	./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_START -val 2000
	./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_ALIGN -val 1
	./xmlchange -file env_run.xml -id RUNDIR -val ${PWD}/run
	```

* Do the setup
	```
	./case.setup
	```

* Download the input data
	```
	./check_input_data --download
	```

* Build the case
	```
	./case.build
	```

* In the run folder, ```mkdir -p ./timing/checkpoints/```

* Run the case
	```
	./preview_run
	``` 
	to see the command to run the case

## 6. User defined land grid
	
* Creating surface dataset and domain file: https://github.com/bishtgautam/matlab-script-for-clm-sparse-grid
	* Use this script to generate a new mesh that comprises of two grids cells corresponding to two watersheds in our study region. The watersheds are shown in the first image on https://icom.atlassian.net/wiki/spaces/ICOM/pages/91848940/CC+Mesh+Generation

* Creating a ELM case that uses the new datasets
	* Create a new case using ```--compset ICLM45 --res CLM_USRDAT --case ${CASE_NAME} --compiler ${COMPILER} --mach ${MACH}```
	* Point to the new domain file via
	  ```
	  ./xmlchange LND_DOMAIN_FILE=<name-of-domain-file>
	  ./xmlchange ATM_DOMAIN_FILE=<name-of-domain-file>
	  ./xmlchange LND_DOMAIN_PATH=<dir-path-to-domain-file>
	  ./xmlchange ATM_DOMAIN_PATH=<dir-path-to-domain-file>
	  ```
	* Point to the surface dataset via
	  ```
	  cat >> user_nl_clm << EOF
	  fsurdat = '<full-path-and-filename-of-new-surface-dataset>'
	  EOF
	  ```
	* ```./case.setup``` and ```./case.build```

## 7. User defined land + river grid on Cori

* Update the submodules: ```git submodule update --init```

* Download the following data:
	```
	wget https://web.lcrc.anl.gov/public/e3sm/inputdata/share/domains domain.lnd.r05_oEC60to30v3.190418.nc
	wget https://web.lcrc.anl.gov/public/e3sm/inputdata/lnd/clm2/surfdata_map/surfdata_0.5x0.5_simyr2000_c190418.nc
	wget https://web.lcrc.anl.gov/public/e3sm/inputdata/rof/mosart/MOSART_global_half_20180721a.nc
	```
* Create new case
	```
	RES=ELMMOS_USRDAT
	COMPSET=IELM
	MACH=cori-knl
	COMPILER=gnu
	PROJECT=project-name
	CASE_NAME=CLMMOS_USRDAT.01.`date "+%Y-%m-%d-%H%M%S"`
	```
	cd your-path-to-E3SM/cime/scripts
	```
	./create_newcase \
	-case ${CASE_DIR}/${CASE_NAME} \
	-res ${RES} \
	-mach ${MACH} \
	-compiler ${COMPILER} \
	-compset ${COMPSET} 
	-project ${PROJECT}
	```
* Setup, Build, Submit
	```
	cd ${CASE_NAME}
	```
	```
	./xmlchange -file env_run.xml -id DOUT_S             -val FALSE
	./xmlchange -file env_run.xml -id INFO_DBUG          -val 2
	```
	```
	./xmlchange CLM_USRDAT_NAME=test_r05_r05
	./xmlchange LND_DOMAIN_FILE=domain.lnd.r05_oEC60to30v3.190418.nc
	./xmlchange ATM_DOMAIN_FILE=domain.lnd.r05_oEC60to30v3.190418.nc
	./xmlchange LND_DOMAIN_PATH=path-to-domain.lnd.r05_oEC60to30v3.190418.nc
	./xmlchange ATM_DOMAIN_PATH=path-to-domain.lnd.r05_oEC60to30v3.190418.nc
	```
	May need to ```./xmlchange PIO_VERSION=1```
	```
	cat >> user_nl_clm << EOF
	fsurdat = 'path-and-filename-to-surfdata_0.5x0.5_simyr2000_c190418.nc'
	EOF
	```
	```
	cat >> user_nl_mosart << EOF
	frivinp_rtm = 'path-and-filename-to-MOSART_global_half_20180721a.nc'
	EOF
	```
	```
	./case.setup
	```
	```
	./case.build
	```
	```
	./case.submit
	```

## 8. User defined river grid

* Resolution and Compset
	```
	RES=MOS_USRDAT
	COMPSET=RMOSGPCC
	```
* Provide ```LND_DOMAIN_FILE``` and ```ATM_DOMAIN_FILE``` that are consistent with domain of MOSART

* dlnd.streams

	Default dlnd.streams for ```COMPSET=RMOSGPCC``` is GPCC forcing, which locates at ```/compyfs/inputdata/lnd/dlnd7/hcru_hcru```

	One can also change the forcing of runoff with user defined file by using the following lines:
	```
	cp ${CASE_DIR}/${CASE_NAME}/CaseDocs/dlnd.streams.txt.lnd.gpcc ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
	chmod +rw ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
	perl -w -i -p -e "s@/compyfs/inputdata/lnd/dlnd7/hcru_hcru@/compyfs/inputdata/lnd/dlnd7/NLDAS@" ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
	perl -w -i -p -e "s@GPCC.daily.nc@Livneh_NLDAS_1915_2011.nc@" ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
	sed -i '/ZBOT/d' ${CASE_DIR}/${CASE_NAME}/user_dlnd.streams.txt.lnd.gpcc
	```

	Change the start and end period for DATM and DLND
	```
	./xmlchange DATM_CLMNCEP_YR_START=2000
	./xmlchange DATM_CLMNCEP_YR_END=2000
	./xmlchange DLND_CPLHIST_YR_START=2000
	./xmlchange DLND_CPLHIST_YR_END=2000
	```
## 9. Output coupler history
	```
	./xmlchange HIST_OPTION=nsteps
	./xmlchange HIST_N=1
	```




