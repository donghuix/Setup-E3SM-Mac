**Author: Donghui Xu** (<donghui.xu@pnnl.gov>)

# Setup E3SM on Mac

1. Xcode 
 - Download and install Xcode
 - Install Xcode command line developers tool by running the following command on terminal ```xcode-select --install``` and click on Install button
 - Launch Xcode and accept licence.

2. Install Package Manager
	* Homebrew: open terminal and type ```ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"```
	* MacPort: checkout https://github.com/bishtgautam/misc-scripts-for-acme/edit/master/md-notes/Setting-ACME-on-mac.md

3. Install packages with homebrew
	* brew install gcc cmake mpich netcdf

	Note: If you see an error while running create_newcase that indicates perl can't find XML::LibXML, you may need to install p5-xml-libxml as well

4. Download E3SM code from github
	* git clone https://github.com/E3SM-Project/E3SM.git e3sm_trial 
	* cd e3sm_trial
	* git fetch origin
	* git checkout origin/master
	* git submodule update  --init  --recursive

	Note: Need to setup SSH key for Github: https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

5. Test case
	* Create a ```.cime``` folder in home director

	* Modify and copy ```config_compilers.xml``` and ```config_machines.xml``` to ```~/.cime/```

	* Create a new case
	```
	export RES=1x1_brazil
	export COMPSET=ICLM45
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
    ``` to see the command to run the case

6. User defined land grid
	
	* Creating surface dataset and domain file: https://github.com/bishtgautam/matlab-script-for-clm-sparse-grid
		* This script generate a new mesh that comprises of two grids cells corresponding to two watersheds in our study region. The watersheds are shown in the first image on https://icom.atlassian.net/wiki/spaces/ICOM/pages/91848940/CC+Mesh+Generation

	* Creating a ELM case that uses the new datasets
		* Create a new case using ```--compset ICLM45 --res CLM_USRDAT```
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

7. User defined land + river grid

8. User defined river grid




