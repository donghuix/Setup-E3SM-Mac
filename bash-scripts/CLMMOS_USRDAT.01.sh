#!/bin/sh

RES=CLMMOS_USRDAT
COMPSET=ICLM45
MACH=cori-knl #$HOSTNAME
COMPILER=gnu
PROJECT=m3426

SRC_DIR=~/e3sm_trial
CASE_DIR=${SRC_DIR}/cime/scripts

cd ${SRC_DIR}/cime/scripts

#GIT_HASH=`git log -n 1 --format=%h`
CASE_NAME=CLMMOS_USRDAT.01.`date "+%Y-%m-%d-%H%M%S"`

./create_newcase \
-case ${CASE_NAME} \
-res ${RES} \
-mach ${MACH} \
-compiler ${COMPILER} \
-compset ${COMPSET} \
-project ${PROJECT}


cd ${CASE_DIR}/${CASE_NAME}

./xmlchange -file env_run.xml -id DOUT_S             -val FALSE
./xmlchange -file env_run.xml -id INFO_DBUG          -val 2

./xmlchange CLM_USRDAT_NAME=test_r05_r05
./xmlchange LND_DOMAIN_FILE=domain.lnd.r05_oEC60to30v3.190418.nc
./xmlchange ATM_DOMAIN_FILE=domain.lnd.r05_oEC60to30v3.190418.nc
./xmlchange LND_DOMAIN_PATH=/global/homes/d/donghui/inputdata
./xmlchange ATM_DOMAIN_PATH=/global/homes/d/donghui/inputdata

./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_END -val 2000
./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_START -val 2000
./xmlchange -file env_run.xml -id DATM_CLMNCEP_YR_ALIGN -val 1
./xmlchange -file env_run.xml -id RUNDIR -val ${PWD}/run

cat >> user_nl_clm << EOF
fsurdat = '/global/homes/d/donghui/inputdata/surfdata_0.5x0.5_simyr2000_c190418.nc'
EOF

cat >> user_nl_mosart << EOF
frivinp_rtm = '/global/homes/d/donghui/inputdata/MOSART_global_half_20180721a.nc'
EOF

./case.setup

./case.build

#./case.submit