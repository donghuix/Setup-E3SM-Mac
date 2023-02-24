RES=ELMMOS_USRDAT
COMPSET=IELM
MACH=compy
COMPILER=intel
PROJECT=esmd

SRC_DIR=~/e3sm_trial
CASE_DIR=${SRC_DIR}/cime/scripts

cd ${SRC_DIR}/cime/scripts

GIT_HASH=`git log -n 1 --format=%h`
CASE_NAME=ELMMOS_SUS_half_${GIT_HASH}.`date "+%Y-%m-%d-%H%M%S"`

####create a case 
./create_newcase \
-case ${CASE_NAME} \
-res ${RES} \
-mach ${MACH} \
-compiler ${COMPILER} \
-compset ${COMPSET} --project ${PROJECT}

cd ${CASE_DIR}/${CASE_NAME}

./xmlchange -file env_run.xml -id DOUT_S             -val FALSE
./xmlchange -file env_run.xml -id INFO_DBUG          -val 2

./xmlchange DATM_MODE=CLMMOSARTTEST
./xmlchange LND_DOMAIN_FILE=domain_lnd_SUS_half_c230224.nc
./xmlchange ATM_DOMAIN_FILE=domain_lnd_SUS_half_c230224.nc
./xmlchange LND_DOMAIN_PATH=./
./xmlchange ATM_DOMAIN_PATH=./

./xmlchange --file env_run.xml --id STOP_N --val 1
./xmlchange --file env_run.xml --id STOP_OPTION --val nyears
./xmlchange --file env_run.xml -id DATM_CLMNCEP_YR_START -val 2000
./xmlchange --file env_run.xml -id DATM_CLMNCEP_YR_END -val 2000
./xmlchange --file env_run.xml -id DATM_CLMNCEP_YR_ALIGN -val 1
./xmlchange --file env_run.xml -id RUN_STARTDATE --val 2000-01-01
./xmlchange PIO_BUFFER_SIZE_LIMIT=67108864
./xmlchange NTASKS=40
./xmlchange JOB_WALLCLOCK_TIME=01:00:00
./xmlchnage JOB_QUEUE=short

cat >> user_nl_elm << EOF
fsurdat = './surfdata_SUS_half_c230224.nc'
EOF

cat >> user_nl_mosart << EOF
frivinp_rtm = './MOSART_SUS_half_c230224.nc'
EOF

./case.setup
./case.build
./case.submit
















