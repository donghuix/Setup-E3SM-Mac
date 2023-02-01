 #!/bin/sh
 
 export RES=1x1_brazil
 export COMPSET=ICLM45
 export COMPILER=gnu
 export MACH=mac
 export CASE_NAME=${RES}.${COMPSET}.${COMPILER}

 cd your-path-to-e3sm/cime/scripts
 
  ./create_newcase \
 -case ${CASE_NAME} \
 -compset ${COMPSET} \
 -res ${RES} \
 -compiler ${COMPILER} \
 -mach ${MACH}
 cd $CASE_NAME
 