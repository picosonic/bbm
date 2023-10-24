#!/bin/bash

workdir=$1

cd "${workdir}"

# Tool names
exo="./exomizer"
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

# Set filenames
beebscr="loadscr2"
exoscr="XSCR"

# When source is newer, rebuild
if refreshrequired ${exoscr} ${beebscr}
then
  if [ ! -x ${exo} ]
  then
    echo "Can't find exomizer"
    exit 1
  fi

  # Compress beeb format with exomizer
  #
  # -c required when LITERAL_SEQUENCES_NOT_USED = 1
  # -M256 required when MAX_SEQUENCE_LENGTH_256 = 1
  # -P+16 required when EXTRA_TABLE_ENTRY_FOR_LENGTH_THREE = 1
  # -P-32 required when DONT_REUSE_OFFSET = 1
  # -f required when DECRUNCH_FORWARDS = 1

  ${exo} level -M256 -P+16-32 -c ${beebscr}@0x0000 -o ${exoscr}
fi

##############################################################

# Build exomiser'd loader screen loader if required
if refreshrequired EXOSCR os.asm consts.asm exomizer310decruncher.h.asm exomizer310decruncher.asm XSCR exoloader.asm
then
  ${beebasm} ${verbose} -i exoloader.asm
fi

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
