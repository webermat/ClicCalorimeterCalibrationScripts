#!/bin/bash
#### NOT WORKING YET!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1


echo "LSF BATCH SUPERVISOR NOT IMPLEMENTED YET!"
#You will need to make it work for LSF or whatever job scheduling system you are using. 
#In principle this "supervisor" should handle the creation of (any) temporary jobs scripts/config
#and the submission and monitoring of the jobs. Additionally, it should check whether the input files
#(lcio files, pandora configuration files, gear xml files and Marlin xmlfiles) are accessible at the worker nodes.
#otherwise, it should ensure their transfer. For example, in the case of condor they are added to the list
#of files transferred by condor. For batch probably everything should be on AFS or setup some scp commands in the job script.
#I implemented some basic way of checking whether the jobs have finished (via bjobs) but have not checked it

exit 


echo "STARTING LSF BATCH SUPERVISOR";

#myrunlist is actually a list of paths to Marlin XML files, one for each job (one job for each lcio file typically).


if [ $1 ]; then
    #myrunlist=$1
    # If this is included the runlist will not be deleted as it is processed.
    myrunlistPre=$1
    myrunlist="$TMPDIR/jobs.${myrunlistPre}.tmp"
    rm -f ${myrunlist}
    cp ${myrunlistPre} ${myrunlist}
    
else
    echo "Not given a runlist! exiting"
    exit 0;
fi

if [ $2 ]; then
    maxRuns=$2
else
    maxRuns=70
fi

maxRuns=999
directory=${PWD}
directory="${directory}/"

JOBNAME="MarlinCalib"`date +"%M%S"`

cp Marlin_Calibration.sh ${JOBNAME}.sh

echo "Supervisor will allow no more than $maxRuns jobs to be queued at any time."
nRun=0
nRun=`wc -l < $myrunlist | sed 's/ //g'`

if [ $nRun -le 0 ]; then
    echo "$myrunlist is empty. Exiting..."
    exit 0;
else
    
    
    echo "There are still $nRun jobs to be submitted"

    rm -f temp_Calibration.sh
    cat >> temp_Calibration.sh << EOF


EOF

    while  [ $nRun -gt 0 ]
    do
        njobs=`bjobs -w| grep "${JOBNAME}.sh" | wc -l | sed 's/ //g'`		
        tmpfilename="$TMPDIR/job.$$.tmp"
        thisjob=0
        n=0
        rm -f ${tmpfilename};
        touch $tmpfilename

        cat $myrunlist | while read line
        do
            if [ $n -eq 0 ]; then
                #${line} is actually the current Marlin XML steering file that controls the reconstruction of the current lcio file(s)
                baseFileName=`basename ${line}`
                transferFiles=`sed -n '/<parameter name="LCIOInputFiles">/,/<\/parameter>/p' ${line}|grep slcio| awk '{print $1}'|grep -v "/afs/cern.ch/" |tr '\n' ','|sed 's/\,$//'`
                echo "arguments = -t ./${JOBNAME}.sh ${baseFileName}                                                     " >> temp_Calibration.job
                
                if [ "$transferFiles" ]; then
                    for file in `echo $transferFiles|tr ',' '\n'`; do 
                        bnf=`basename $file`; 
                        sed -i 's|'"$file"'|'"$bnf"'|' ${line}; 
                    done

                    #Files that are not on AFS (not accessible by the nodes) should be somehow scp'd to the nodes
                    #add relevant commands to the job script here
                else
                    #All LCIO files are accessible through the network. Therefore at this point you should only
                    #make sure PandoraSettings.xml, PandoraLikelihoodData12EBin.xml, GearOutput.xml, the MarlinJob script,
                    #and the Marlin XML file (as contained in ${line}) are accessible from the node
                fi
            else
                echo $line >> $tmpfilename;
            fi
                let "n++"
        done
        cp ${tmpfilename} ${myrunlist}
        rm ${tmpfilename}
        echo "queue 1"                                                                         >> temp_Calibration.job

        nRun=`wc -l < $myrunlist | sed 's/ //g'`
    done
    
#submit all the jobs together. Or modify the logic to create one script per job
#     bsub temp_Calibration.sh 
    
fi
echo "$myrunlist is empty. Exiting..."

echo "Checking the jobs are finished..."

njobs2=`bjobs -w| grep "${JOBNAME}.sh" | wc -l | sed 's/ //g'`

while [ $njobs2 -gt 0 ];
do
    echo "Not finished yet, come back later."
    sleep 10s
    njobs2=`bjobs -w| grep "${JOBNAME}.sh" | wc -l | sed 's/ //g'`
done


echo "Jobs finished."

rm -f ${JOBNAME}.sh;

mv pfoAnalysis*.root ../Root_Files/
# echo "Finished, supposedly. Press any key to continue..."
# read bah;

exit 0;
