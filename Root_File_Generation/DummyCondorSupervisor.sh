#!/bin/bash

echo "STARTING DUMMY CONDOR SUPERVISOR";

cat $1 | while read line; 
do 
    Marlin $line
done 

