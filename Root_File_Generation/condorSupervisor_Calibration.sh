#!/bin/bash

echo
echo "STARTING CONDOR SUPERVISOR";
echo

#myrunlist is actually a list of paths to Marlin XML files, one for each job (one job for each lcio file typically).

export TMPDIR=$PWD

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

cp ${KRB5CCNAME/FILE:/} credentials.krb5

cp Marlin_Calibration.sh ${JOBNAME}.sh

echo "Supervisor will allow no more than $maxRuns jobs to be queued at any time."
nRun=0
nRun=`wc -l < $myrunlist | sed 's/ //g'`

if [ $nRun -le 0 ]; then
    echo "$myrunlist is empty. Exiting..."
    exit 0;
else
    
    
    echo "There are still $nRun jobs to be submitted"

    rm -f temp_Calibration.job
    touch temp_Calibration.job
    
    mkdir -p CondorLogs
    while  [ $nRun -gt 0 ]
    do
        njobs=`condor_q -wide | grep "${JOBNAME}.sh" | wc -l | sed 's/ //g'`		
		
        echo "executable              = /usr/bin/krenew                                          " >> temp_Calibration.job 
#             echo "initial_dir             = ${directory}                                                    " >> temp_Calibration.job
        echo "notification            = never                                                           " >> temp_Calibration.job
#             echo "Requirements            = (LoadAvg < 0.5) && (POOL == \"GENERAL\") && (OSTYPE == \"SLC6\")" >> temp_Calibration.job
#             echo "Rank                    = memory                                                          " >> temp_Calibration.job
        echo "output                  = ${PWD}/CondorLogs/${JOBNAME}.out.\$(cluster).\$(Process)               " >> temp_Calibration.job
        echo "error                   = ${PWD}/CondorLogs/${JOBNAME}.err.\$(cluster).\$(Process)             " >> temp_Calibration.job
        echo "log                     = ${PWD}/CondorLogs/${JOBNAME}.log.\$(cluster).\$(Process)             " >> temp_Calibration.job
        echo "environment             = CONDOR_JOB=true                                                 " >> temp_Calibration.job
        echo "Universe                = vanilla                                                         " >> temp_Calibration.job
        echo "getenv                  = false                                                           " >> temp_Calibration.job
        echo "environment=\"KRB5CCNAME=FILE:./credentials.krb5 AKLOG=/usr/bin/aklog HOME=${HOME}\"                   " >> temp_Calibration.job
        
        echo "copy_to_spool           = true                                                            " >> temp_Calibration.job
        echo "should_transfer_files   = yes                                                             " >> temp_Calibration.job
        echo "when_to_transfer_output = on_exit_or_evict                                                " >> temp_Calibration.job
    
        echo "priority = 20                                                " >> temp_Calibration.job
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
                #files on AFS don't need to be transferred
                transferFiles=`sed -n '/<parameter name="LCIOInputFiles">/,/<\/parameter>/p' ${line}|grep slcio| awk '{print $1}'|grep -v "/afs/" |tr '\n' ','|sed 's/\,$//'`
                echo "arguments = -t ./${JOBNAME}.sh ${baseFileName}                                                     " >> temp_Calibration.job
                
                if [ "$transferFiles" ]; then
                    for file in `echo $transferFiles|tr ',' '\n'`; do 
                        bnf=`basename $file`; 
                        sed -i 's|'"$file"'|'"$bnf"'|' ${line}; 
                    done

                    echo "transfer_input_files = ${directory}./${JOBNAME}.sh,${line},../Xml_Generation/PandoraSettingsDefault.xml,../Xml_Generation/PandoraLikelihoodData12EBin.xml,./credentials.krb5,../GearOutput.xml,${transferFiles}" >> temp_Calibration.job
                else
                    echo "transfer_input_files = ${directory}./${JOBNAME}.sh,${line},../Xml_Generation/PandoraSettingsDefault.xml,../Xml_Generation/PandoraLikelihoodData12EBin.xml,./credentials.krb5,../GearOutput.xml" >> temp_Calibration.job
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
    
    condor_submit temp_Calibration.job
    
fi
echo "$myrunlist is empty. All jobs submitted."

sleep 600s

echo "Checking whether the jobs have finished..."

njobs2=`condor_q -wide | grep "${JOBNAME}.sh" | wc -l | sed 's/ //g'`
while [ $njobs2 -gt 0 ];
do
    echo "Not finished yet, come back later."
    njobs2=`condor_q -wide | grep "${JOBNAME}.sh" | wc -l | sed 's/ //g'`
done


echo "Jobs finished."

rm -f ${JOBNAME}.sh;

mv pfoAnalysis*.root ../Root_Files/
# echo "Finished, supposedly. Press any key to continue..."
# read bah;

exit $?;
