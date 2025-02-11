1. Fork E3SM
[E3SM git repo](https://github.com/E3SM-Project/E3SM)
![fork](setup-e3sm-on-compy/fork.png)

2. Cloning your forked E3SM
```
git clone https://github.com/your-github-username/E3SM.git e3sm_test
cd e3sm_test
git fetch origin
git checkout origin/master
git submodule update --init --recursive
```
Note: Need to setup SSH key for Github: https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent Note: May need to do chmod 600 ~/.ssh/config

3. land-river coupled configuration for [NLDAS](https://ldas.gsfc.nasa.gov/nldas/specifications) domain

``RES=NLDAS_NLDAS #Define RESolution``
``COMPSET=IELM #Define configuration``
long name: 2000_DATM%QIA_ELM%SPBC_SICE_SOCN_MOSART_SGLC_SWAV
``MACH=compy #Define MACHine``
``COMPILER=intel #Define compiler``
``PROJECT=esmd #Define project``
``SRC_DIR=~/e3sm_test #Define E3SM directory``
``CASE_DIR=${SRC_DIR}/cime/scripts #Define the case directory``
``cd ${SRC_DIR}/cime/scripts``
`` GIT_HASH=`git log -n 1 --format=%h` ``
`` CASE_NAME=ELMMOS_NLDAS_${GIT_HASH}.`date "+%Y-%m-%d-%H%M%S"` ``

Create case
```
./create_newcase \
-case ${CASE_NAME} \
-res ${RES} \
-mach ${MACH} \
-compiler ${COMPILER} \
-compset ${COMPSET} --project ${PROJECT}
```

Configure case
```
cd ${CASE_DIR}/${CASE_NAME}

./xmlchange -file env_run.xml -id DOUT_S             -val FALSE
./xmlchange -file env_run.xml -id INFO_DBUG          -val 2
./xmlchange DEBUG=1

# Specify which DATM forcing to use
# ./xmlchange DATM_MODE=CLMMOSARTTEST 

# Specify the simualtion start time
./xmlchange DATM_CLMNCEP_YR_START=1979
./xmlchange DATM_CLMNCEP_YR_ALIGN=1979
./xmlchange DATM_CLMNCEP_YR_END=2000
./xmlchange RUN_STARTDATE=1979-01-01

./xmlchange PIO_BUFFER_SIZE_LIMIT=67108864
# If need to run for longer period
#./xmlchange STOP_N=41,STOP_OPTION=nyears #ndays, nmonths
#./xmlchange JOB_QUEUE=slurm
#./xmlchange REST_N=10,REST_OPTION=nyears
#./xmlchange RESUBMIT=1
#./xmlchange JOB_WALLCLOCK_TIME=24:00:00


#cat >> user_nl_elm << EOF
#fsurdat = '/compyfs/inputdata/lnd/clm2/surfdata_map/surfdata_nldas2_simyr2000_c181207.nc'
#EOF
cat >> user_nl_mosart << EOF
frivinp_mesh = 'UNDEFINED'
rtmhist_nhtfrq = -24
rtmhist_mfilt = 1
EOF

./case.setup

./case.build

./case.submit
```
MOSART features:
#inundflag = .true.
#routingmethod = 2
#opt_elevprof = 1
https://ncar.github.io/CESM-Tutorial/notebooks/namelist/output/output_clm.html
ELM outputs: QOVER: surface runoff
             QDRAI: subsurface runoff
             QRUNOFF: total runoff
             ZWT: ground water table
MOSART outputs: RIVER_DISCHARGE_OVER_LAND_LIQ: river discharge on land grid cells
			    RIVER_DISCHARGE_TO_OCEAN_LIQ: river discharge on river mouth cells
			    FLOODPLAIN_FRACTION: floodplain inundation fraction (if inundation is turned on)
                FLOODED_FRACTION: floodplain fraction + river area

sacct to check the status of job.

4. Only river configuration

``RES=NLDAS_NLDAS #Define RESolution``
``COMPSET=RMOSGPCC #Define configuration``
long name: 2000_DATM%QIA_DLND%GPCC_SICE_SOCN_MOSART_SGLC_SWAV
``MACH=compy #Define MACHine``
``COMPILER=intel #Define compiler``
``PROJECT=esmd #Define project``
``SRC_DIR=~/e3sm_test #Define E3SM directory``
``CASE_DIR=${SRC_DIR}/cime/scripts #Define the case directory``
``cd ${SRC_DIR}/cime/scripts``
`` GIT_HASH=`git log -n 1 --format=%h` ``
`` CASE_NAME=MOS_NLDAS_${GIT_HASH}.`date "+%Y-%m-%d-%H%M%S"` ``

Follow previous case for creating a new case.

./xmlchange DATM_CLMNCEP_YR_START=1979
./xmlchange DATM_CLMNCEP_YR_ALIGN=1979
./xmlchange DATM_CLMNCEP_YR_END=2000
./xmlchange DLND_CPLHIST_YR_START=1979
./xmlchange DLND_CPLHIST_YR_ALIGN=1979
./xmlchange DLND_CPLHIST_YR_END=2000
./xmlchange RUN_STARTDATE=1979-01-01

cat >> user_nl_mosart << EOF
frivinp_mesh = 'UNDEFINED'
rtmhist_nhtfrq = -24
rtmhist_mfilt = 1
EOF

5. User costumize configuration
``RES=ELMMOS_USRDAT``
``RES=MOS_USRDAT``

6. Run Python scripts on compy
```
#!/bin/csh

#SBATCH --job-name=test         ## job_name
#SBATCH --partition=short
#SBATCH --account=esmd          ## project_name
#SBATCH --time=00:10:00         ## time_limit
#SBATCH --nodes=1               ## number_of_nodes
#SBATCH --ntasks-per-node=1     ## number_of_cores
#SBATCH --output=mat.stdout1    ## job_output_filename
#SBATCH --error=mat.stderr1     ## job_errors_filename

ulimit -s unlimited

module load python/3.7.3

python3 test.py > test.log
```
6. git notes

* create a new branch: ``git checkout -b donghui/rof/new-feature``: Name convention --> username/component/feature 

* check what modifications are made: ``git status``
* how to commit the branch: ``git add files, git commit -m 'message'``, 
                            ``git push origin donghui/rof/new-feature``

* Issue a PR. 

Check which branch is on: ``git branch``

7. How to calibrate parameters 
ensemble e3sm simulation.

8. Validating ELM-MOSART simulations

9. Spin-up 
Target Simulation: 1980 - 2009.
Spinup Simulation: 1971 - 1980.
    * Specify the forcing to be 1971 -1980
    * Specify the STOP_N to be 20 years (or longer depends on how long you want to spin up the simulation).
    <pre>
    * Simulation time -> 1971, 1972, …, 1980, 1981, 1982, …, 1990.
    * Forcing    time -> 1971, 1972, …, 1980, 1971, 1972, …, 1980.
    </pre>
Specifiy the initial condition file for the Target Simulation in user_nl_*.
    * ELM:    finidat
    * MOSART: finidat_rtm

10. How to run python in parallel

```python 
from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

data = np.arange(size)
print(f"Hello from process {rank} out of {size} processes!")
print(f"The data is " + str(data[rank]))
```

```bash
#!/bin/csh

#SBATCH --job-name=test         ## job_name
#SBATCH --partition=short
#SBATCH --account=esmd          ## project_name
#SBATCH --time=00:10:00         ## time_limit
#SBATCH --nodes=1               ## number_of_nodes
#SBATCH --ntasks-per-node=20     ## number_of_cores
#SBATCH --output=mat.stdout1    ## job_output_filename
#SBATCH --error=mat.stderr1     ## job_errors_filename

ulimit -s unlimited

module load python/3.7.3

mpirun -n 20 python3 test.py > test.log
```