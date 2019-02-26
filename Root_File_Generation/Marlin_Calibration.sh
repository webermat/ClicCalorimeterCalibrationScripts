#!/bin/bash

source /cvmfs/clicdp.cern.ch/iLCSoft/builds/2018-10-11/x86_64-slc6-gcc62-opt//init_ilcsoft.sh

echo "Here is the content of $ILCSOFT"
ls $ILCSOFT

echo "My environment"
env

echo "User: "$USER
echo "Hostname: "$HOSTNAME
condor_config_val FULL_HOSTNAME
id -u -n
hostname -A
hostname -i

ls -l


sleep $[ ( $RANDOM % 10 )  + 1 ]s

echo "Executing Marlin $1"

Marlin  $1


