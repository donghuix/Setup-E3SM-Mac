RES=1x1_brazil
COMPSET=I1850ELM
MACH=mymac
COMPILER=gnu

SRC_DIR=/Users/xudo627/Developments/e3sm-master
CASE_DIR=${SRC_DIR}/cime/scripts

cd ${SRC_DIR}
GIT_HASH=`git log -n 1 --format=%h`
CASE_NAME=${RES}.${COMPSET}.${MACH}.${GIT_HASH}.`date "+%Y-%m-%d"`

cd ${SRC_DIR}/cime/scripts

./create_newcase -case ${CASE_DIR}/${CASE_NAME} \
-res ${RES} -mach ${MACH} -compiler ${COMPILER} -compset ${COMPSET}

cd ${CASE_DIR}/${CASE_NAME}

./xmlchange DATM_CLMNCEP_YR_END=1948
./xmlchange PIO_TYPENAME=netcdf
./xmlchange RUNDIR=${PWD}/run

./xmlchange MPILIB=mpich
./xmlchange OS=Darwin
./xmlchange EXEROOT=${PWD}/bld
./xmlchange PIO_VERSION=2


 ./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_END -val 2000
 ./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_START -val 2000
 ./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_ALIGN -val 1
 ./xmlchange -file env_run.xml -id RUNDIR -val ${PWD}/run

 
./case.setup
./case.build