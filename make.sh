#!/bin/bash

workdir=$1

cd "${workdir}"
beebasm -v -i downloader.asm
beebasm -v -i bbm.asm -do bbm.ssd -opt 3 -title 'BBM'
