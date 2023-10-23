#!/bin/bash

workdir=$1

cd "${workdir}"

# Tool names
beebasm="beebasm"

# Tool options
verbose="-v"

# When run from VSC, remove verbose as it can cause summary to be lost
if [ "${workdir}" != "" ]
then
  verbose=""
fi

${beebasm} ${verbose} -i downloader.asm
${beebasm} ${verbose} -i bbm.asm -do bbm.ssd -opt 3 -title 'BBM'
