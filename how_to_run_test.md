Test for a new development.

git submodule update --init

cd cime/scripts

export MY_BASELINE_DIR=/compyfs/xudo627/e3sm_baselines

export BASELINE_NAME=2862834

export TEST_ID=${BASELINE_NAME}

./create_test e3sm_land_developer  \
--baseline-root ${MY_BASELINE_DIR} \
-b ${BASELINE_NAME}                \
-t ${TEST_ID}                      \
-q short                           \
--walltime 00:30:00                \
--project esmd                     \
-g                                 \
-v                                 \
-j 4


git submodule update --init

cd cime/scripts

export MY_BASELINE_DIR=/compyfs/xudo627/e3sm_baselines

export BASELINE_NAME=2862834

export TEST_ID=newcode

./create_test e3sm_land_developer    \
--baseline-root ${MY_BASELINE_DIR}   \
-b ${BASELINE_NAME}                  \
-t ${TEST_ID}                        \
-q short                             \
--project esmd                       \
--walltime 02:00:00                  \
-c                                   \
-v                                   \
-j 4   
