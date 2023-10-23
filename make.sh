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

##############################################################

function refreshrequired()
{
  local target="$1"
  local targettime=`stat -c %Y ${target} 2>/dev/null`

  if [ "${targettime}" == "" ]
  then
    return 0
  fi
  
  for var in "$@"
  do
    local source="$var"
    local sourcetime=`stat -c %Y ${source} 2>/dev/null`
    
    if [ ${sourcetime} -gt ${targettime} ]
    then
      return 0
    fi
  done

  return 1
}

##############################################################

# Append loader asm to BASIC
if refreshrequired loadertok.bin loader.bas loader2.asm loader.asm
then
  # Tokenise the BASIC
  ${beebasm} ${verbose} -i loader.asm -do loader.ssd 2>/dev/null

  # Determine how big the tokenised BASIC file is from DFS catalogue
  baslen=`dd if=loader.ssd bs=1 count=2 skip=268 2>/dev/null | hexdump -C | head -1 | awk '{ print $3$2 }'`

  # Extract tokenised BASIC from disc image, then remove image
  dd if=loader.ssd bs=1 count=$((0x${baslen})) skip=512 > loadertok.bin 2>/dev/null
  rm loader.ssd >/dev/null 2>&1
fi

##############################################################

${beebasm} ${verbose} -i downloader.asm
${beebasm} ${verbose} -i bbm.asm -do bbm.ssd -opt 3 -title 'BBM'
