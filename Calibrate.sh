#!/bin/bash
#Calibration procedure originally created by S. Green (Cambridge). 
#Cleanup, comments and modifications by N. Nikiforou (CERN) to make it compatible
#with DD4hep, CLIC and the computing setup at CERN. 


submissionDir=$PWD
# Paths must end in a /
# The serial number in the slcio file must look like a wildcard (.*?) in python.
# Source ilcsoft to begin with !!

#===============================================
# Input File Information
#===============================================

# Note: Could modify script to take command line argumens. Instead, let's configure the variables within the script (see further down)
# if [ $# -lt 1 ]; 
# then
#     echo "Are you sure you don't want to provide arguments?"
#     echo "Syntax: $0 <INPUT LCIO FILE LOCATION> <FORMAT> <COMPACT XML FILE> <HCALEndcapTimeWindowMax> <HCALBarrelTimeWindowMax> <ECALEndcapTimeWindowMax> <ECALBarrelTimeWindowMax> <MHHHE> <numberHCalLayers>"
#     echo "Example: $0 /scratch1/CalibDataForDD4hep/ \"DDSim_CLIC_o2_v04_PARTICLE_ENERGYGeV([0-9]+)_.*.slcio\" /afs/cern.ch/eng/clic/work/ilcsoft/HEAD-2016-01-19/lcgeo/HEAD/CLIC/compact/CLIC_o2_v04/CLIC_o2_v04.xml /home/nikiforo/CalibDD4hepV2/output/ 10.0 10.0 20.0 20.0 1.0 60.0"
# 
#     exit 0
# fi
# 
# #echo $@
# slcioPath="${1}"
# slcioFormat="${2}"
# dd4hep_compact_xml="${3}"
# outputPath="${4}"
# HCALEndcapTimeWindowMax=${5}
# HCALBarrelTimeWindowMax=${6}
# ECALEndcapTimeWindowMax=${7}
# ECALBarrelTimeWindowMax=${8}
# MHHHE=${9}
# numberHCalLayers="${10}"


############################# CONFIGURATION ##############################################

#=========================================================================================
#the release to use to run the calibration (defines the geometry, the reconstruction, ...)
ilcsoftPath="/cvmfs/clicdp.cern.ch/iLCSoft/builds/2019-02-20/x86_64-slc6-gcc62-opt/"

PandoraAnalysisPath="${ilcsoftPath}/PandoraAnalysis/HEAD/" #change if not HEAD
#PandoraAnalysisPath="/scratch0/scratch1/DD4hepDetCalibration/PandoraAnalysisLocal171014/"
#=========================================================================================

sourceFile="${ilcsoftPath}/init_ilcsoft.sh"
source $sourceFile #setup ilcsoft to get the variables
export PATH=${PandoraAnalysisPath}/bin:$PATH
if [ ! -d $PandoraAnalysisPath ]; then
    echo "Error! PandoraAnalysisPath does not exist!"
    exit 1
fi

#the name of the geometry. Used in naming the output file with the calibration results
#but also referenced to variables below
geometryModelName="CLIC_o3_v14"
#=========================================================================================

#=========================================================================================
#The location of the compact xml defining the geometry of the detector. 
#Usually, the "geometryModelName" variable set above defines the compact file uniquely 
#assuming the CLIC conventions for the compact xml file within lcgeo
dd4hep_compact_xml="${lcgeo_DIR}/CLIC/compact/${geometryModelName}/${geometryModelName}.xml"
if [ ! -f $dd4hep_compact_xml ]; then
    echo "Error! Compact XML file at ${dd4hep_compact_xml} not accessible!"
    exit 1
fi
#=========================================================================================


#=========================================================================================
#the location of the simulated photon, muon and kaon files. The structure should be the following:
#For example if slcioPath=/scratch0/scratch1/CalibDataForDD4hep/CLIC_o2_v04/, there should be:
#/scratch0/scratch1/CalibDataForDD4hep/CLIC_o2_v04/gamma/10/
#/scratch0/scratch1/CalibDataForDD4hep/CLIC_o2_v04/mu-/10/
#/scratch0/scratch1/CalibDataForDD4hep/CLIC_o2_v04/K0L/50/
#with the relevant lcio files stored in the above directories
slcioPath="/scratch0/scratch1/CalibDataForDD4hep/${geometryModelName}/"

#Derive slcio file locations
gammaPath="$slcioPath/gamma/10/"
muonPath="$slcioPath/mu-/10/"
kaonPath="$slcioPath/K0L/50/"
#=========================================================================================


#=========================================================================================
#Regular expression to select the particular files for each particle type and energy
#Useful only if all the files are dumped in one directory. For example:
# slcioFormat="DDSim_${geometryModelName}_PARTICLE_ENERGYGeV([0-9]+)_.*.slcio"
#We use different directories for each particle type and energy, so the following should be sufficient:
slcioFormat=".*_([0-9]+).slcio"
#notice that these are Python-compatible regular expressions. The above should be read as
#"match anything on the front of the string, followed by a '_' and then match any number at least one time
#and create a group, followed by the string ".slcio". The group is used to match the index of the slcio file and 
#use it to tag the intermediate files with this number. For example, the above will match the file named
#"DDSim_CLIC_o2_v04_gamma_10GeV89_89_250116102012_89.slcio" and will extract the index number "89" to be 
#used in the xml and root file naming. Please see "Xml_Generate.py". 
#The first and last indices are printed together with the total number of matched files 
#as a cross-check before the calibration starts
#=========================================================================================

#=========================================================================================
#A directory where to store the calibration output. By default it is under $PWD/output
outputPath="$submissionDir/outputCLIC_o3_v14_190220_gcc62_PandoraSettingsDefaultNoSWC_PhNEW_LocalPandoraAnalysis_ECAL_Si_HCAL_SiPM/"
calibrResultsFile=${outputPath}/calib.${geometryModelName}.txt
#=========================================================================================

#=========================================================================================
#Timing window configuration. Usually it shouldn't change if the calorimeter 
#material doesn't change
#not used as parameters anymore, those 4 are fixed
HCALEndcapTimeWindowMax=10
HCALBarrelTimeWindowMax=10
ECALEndcapTimeWindowMax=10
ECALBarrelTimeWindowMax=10

#Max HCal Hit Hadronic Energy. (i.e. Energy truncation) to be used in reconstruction
#VERY IMPORTANT FOR THINGS TO CHECK HERE-PUT VERY VERY HIGH RIGHT NOW FOR SWC RUN
MHHHE=10000000.

#Number of layers in the HCal. Used someplace for some calculation. Could be determined 
#from geometry but to lazy to do so
numberHCalLayers=60
#=========================================================================================
########################## END OF MAJOR CONFIGURATION ####################################

#minor configuration (i.e. shouldn't change often) below



#=========================================================================================
pandoraSettingsFile="PandoraSettingsDefault.xml"

#Better get the most up to date files from MarlinPandora
#PANDORASETTINGSFILEPATH=`find $ILCSOFT/MarlinPandora/ -name "${pandoraSettingsFile}"`
#PANDORALIKELIHOODDATAFILE=`find $ILCSOFT/MarlinPandora/ -name "PandoraLikelihoodData12EBin.xml"`

PANDORALIKELIHOODDATAFILE="PandoraLikelihoodData12EBin.xml"

hadronicScaleSettingPandora="CSM" #TEM or CSM
#=========================================================================================

#the script returns a string in the format NNN ( AAA ... ZZZ )
gammaFiles=`python Xml_Generation/countMatches.py $gammaPath ${slcioFormat}`
muonFiles=`python Xml_Generation/countMatches.py $muonPath ${slcioFormat}`
kaonFiles=`python Xml_Generation/countMatches.py $kaonPath ${slcioFormat}`

#Trick to get the tokens separately
gammaFiles=($gammaFiles)
muonFiles=($muonFiles)
kaonFiles=($kaonFiles)

if [ "${gammaFiles}" == 0 ] || [ "${muonFiles}" == 0 ] || [ "${kaonFiles}" == 0 ]; then
    echo "Error! Some or all of the calibration files are missing!:"
    echo "gamma: $gammaFiles muon: $muonFiles kaon: $kaonFiles"
    exit;
else 
    
    #Check if first and last index is the same
    if [ ${gammaFiles[2]} -eq ${gammaFiles[4]} ]; then
        echo
        echo "Warning! Photon file indices same, not matched or not existing! [ ${gammaFiles[*]} ]"
        echo "Could mess up ROOT-file generation later! Proceed at your own peril."
        echo 
    fi

    if [ ${muonFiles[2]} -eq ${muonFiles[4]} ]; then
        echo
        echo "Warning! Muon file indices same, not matched or not existing! [ ${muonFiles[*]} ]"
        echo "Could mess up ROOT-file generation later! Proceed at your own peril."
        echo 
    fi
    
    if [ ${kaonFiles[2]} -eq ${kaonFiles[4]} ]; then
        echo
        echo "Warning! Kaon file indices same, not matched or not existing! [ ${kaonFiles[*]} ]"
        echo "Could mess up ROOT-file generation later! Proceed at your own peril."
        echo 
    fi  
    
fi

########################## END OF MAJOR CONFIGURATION ########################

#minor configuration (i.e. shouldn't change often) below

#===============================================
#Job configuration
batchSystem="Condor"
maxNumCondorJobs=100
#===============================================

digitisationAccuracy=0.05                       # Fractional accuracy targetted by digitisation stage 
pandoraPFAAccuracy=0.005                        # Fractional accuracy targeted by PandoraPFA calibration stage 

#==============================================
# Calibration Information
#==============================================
# PandoraPFA Point To Calibration
#===================
kaonLEnergyCalibration=50
photonEnergyCalibration=10

#===================
# KaonL Points for non linearity corrections if implemented.
#===================
kaonLEnergies[0]=1
kaonLEnergies[1]=2
kaonLEnergies[2]=5
kaonLEnergies[3]=10
kaonLEnergies[4]=20
kaonLEnergies[5]=50 #actually only using this energy
kaonLEnergies[6]=100

#===================
# Do not change
#===================
kaonLMass=0.497614
kaonLKineticEnergyCalibration=$(echo "scale=10; ${kaonLEnergyCalibration} -${kaonLMass}" | bc)

#===================
# MIP definition 
#===================
muonEnergyCalibration=10

#===============================================
# Initial Guesses For Calibration Parameters
#===============================================
# Digitisation (Inital Guesses = Defaults)
#===============================================
# This gets doubled in the code to become 42.91 85.82 as ECal thickness doubles in detector
CalibrECAL=35.7
CalibrECALBarrel=35.7
CalibrECALEndCap=35.7

CalibrECALEndCapCorr=1.070

CalibrHCALBarrel=49.59
CalibrHCALEndCap=53.32
CalibrHCALOther=58.23

#CalibrHCALBarrel=$(echo "scale=10; ${CalibrHCALBarrel} * 48 / ${numberHCalLayers}" | bc)
#CalibrHCALEndCap=$(echo "scale=10; ${CalibrHCALEndCap} * 48 / ${numberHCalLayers}" | bc)

#===============================================
# Pandora PFA
#===============================================
ECalToEm=1.000
HCalToEm=1.000
ECalToHad=0.97
HCalToHad=1.059

#===============================================
# GeVToMIP
#===============================================
ECalGeVToMIP=163.93
HCalGeVToMIP=43.29
MuonGeVToMIP=9000.0

ECalMIPMPV=0.00015
HCalMIPMPV=0.00004

##### STARTING CALIBRATION PROCEDURE ####


echo "Will perform calibration with the following settings: "
echo 
echo "ILCSOFT: "$ILCSOFT
echo "AnalysePerformance: "`which AnalysePerformance`
echo "dd4hep_compact_xml: "$dd4hep_compact_xml
echo "LCIO File path: "$slcioPath
echo "     Photon path: "$gammaPath" [ ${gammaFiles[*]} files found ]"
echo "     Muon path:   "$gammaPath" [ ${muonFiles[*]} files found ]"
echo "     Kaon path:   "$kaonPath"  [ ${kaonFiles[*]} files found ]"

echo "HCALEndcapTimeWindowMax: "$HCALEndcapTimeWindowMax" HCALBarrelTimeWindowMax: "$HCALBarrelTimeWindowMax" ECALEndcapTimeWindowMax: "$ECALEndcapTimeWindowMax" ECALBarrelTimeWindowMax: "$ECALBarrelTimeWindowMax" MHHHE: "               $MHHHE
echo "Run on batch system: "$batchSystem
echo
echo "Please make sure your Marlin Steering file (by default named CLIC_PfoAnalysis_AAAA_SN_BBBB.xml and bundled with this package in the Xml_Generation directory) is up to date for the rest of the reconstruction software! Cosnider a diff with the one provided in the ClicPerformance package."
echo
echo "Strike any key to continue..."
read bah;

############################ THERE BE DRAGONS! #################
################################################################

gearFile=GearOutput.xml

echo "Converting DD4hep to gear for backwards compatibility"
#the gear file should go away in the future, but
#I couldn't bother changing all the scripts to take one less argument
convertToGear "GearForCLIC" ${dd4hep_compact_xml} ${gearFile}

#===============================================
# Clear previous files
#===============================================
rm -rf Root_Files
mkdir -p Root_Files
rm -rf Marlin_Xml
mkdir -p Marlin_Xml

#===============================================
# Output File Information
#===============================================
calibrationFile="${outputPath}/Calibration.txt"
rm -f ${calibrationFile}
mkdir -p $outputPath
touch ${calibrationFile}
#===============================================
# Path To Root Files
#===============================================
path=$(pwd)

PythonReadScripts="${path}/Python_Read_Scripts/"
MarlinXml="${path}/Marlin_Xml/"
RootFileGeneration="${path}/Root_File_Generation/"
RootFiles="${path}/Root_Files/"
XmlGeneration="${path}/Xml_Generation/"

#cp -f $PANDORASETTINGSFILEPATH ${XmlGeneration}/
#cp -f $PANDORALIKELIHOODDATAFILE ${XmlGeneration}/

kaonRootFiles="${path}/Root_Files/pfoAnalysis_${kaonLEnergyCalibration}_GeV_Energy_K0L_SN_*.root"
photonRootFiles="${path}/Root_Files/pfoAnalysis_${photonEnergyCalibration}_GeV_Energy_gamma_SN_*.root"
muonRootFiles="${path}/Root_Files/pfoAnalysis_${muonEnergyCalibration}_GeV_Energy_mu-_SN_*.root"

#==============================================
if [ "$batchSystem" = "Condor" ];then
    cd ${RootFileGeneration}

    python Source.py ${sourceFile}
elif [ "$batchSystem" = "No" ];then
    source ${sourceFile}

else
    echo "Please select whether you wish to use condor."
fi

#===============================================#
#===============================================#
#                 Digitisation                  #
#===============================================#
#===============================================#
#===============================================#
#          ECAL Digitisation Constants          #
#===============================================#
echo "ECAL Digitisation: Generate Marlin steering files with initial guesses"

# Generate Marlin steering files with initial guesses
cd ${XmlGeneration}

echo python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  

python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  

#Energy = sys.argv[1]
#Particle = sys.argv[2]
#ECALTOEM = sys.argv[3]
#HCALTOEM = sys.argv[4]
#ECALTOHAD = sys.argv[5]
#HCALTOHAD = sys.argv[6]
#CALIBR_ECAL = sys.argv[7] + 2*sys.argv[7]
#CALIBR_HCAL_BARREL = sys.argv[8]
#CALIBR_HCAL_ENDCAP = sys.argv[9]
#CALIBR_HCAL_OTHER = sys.argv[10]
#NLC = sys.argv[11]
#MHHHE = sys.argv[12]
#slcioPath = sys.argv[13]
#slcioFormat = sys.argv[14]
#gearFile = sys.argv[15]
#Pandora_Settings_File = sys.argv[16]

# Generate root files

cd ${RootFileGeneration}

chmod u+x condorSupervisor_Calibration.sh
chmod u+x DummyCondorSupervisor.sh
chmod u+x Marlin_Calibration.sh

Runfile="Marlin_Runfile_${photonEnergyCalibration}_GeV_Energy_gamma.txt"

if [ "$batchSystem" = "Condor" ];then
    ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 

elif [ "$batchSystem" = "No" ];then
    ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 

else
    echo "Please select whether you wish to use condor."
fi


if [ $? -ne 0 ]; then 
 echo "Problem with root file generation! Check job log files!"
 exit 1

fi

echo "ECAL Digitisation: Update CalibrECAL"

# Find and update CalibrECAL
ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e 90 
ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "Barrel" -i "-0.1" -j "0.65"
ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "EndCap" -i "0.8" -j "0.92"


cd ${PythonReadScripts}

CalibrECAL=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECAL} "Calibration_Constant" "")
ECal_Mean=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECAL} "Mean" "")

CalibrECALBarrel=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALBarrel} "Calibration_Constant" "Barrel")
CalibrECALEndCap=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALEndCap}  "Calibration_Constant" "EndCap")

ECal_Barrel_Mean=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALBarrel} "Mean" "Barrel")
ECal_EndCap_Mean=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALEndCap} "Mean" "EndCap")

CalibrECALEndCapCorr=$(python -c "print ${CalibrECALEndCapCorr}*${CalibrECALEndCap}/${CalibrECALBarrel}")

Fractional_Error_ECal_Mean=$(echo "scale=10; sqrt((${photonEnergyCalibration} -${ECal_Mean})^2)/${photonEnergyCalibration}" | bc)

# Loop until CalibrECAL acceptable
CheckECalDigi=$(echo "$Fractional_Error_ECal_Mean >= ${digitisationAccuracy}" | bc -l)

echo "ECAL Digitisation: CheckECalDigi="$CheckECalDigi

while [[ $CheckECalDigi -gt 0 ]] 
do

    echo "ECAL Digitisation: iterating. Creating xml files"

    cd ${XmlGeneration}
    echo python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  
    python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  

    cd ${RootFileGeneration}
    Runfile="Marlin_Runfile_${photonEnergyCalibration}_GeV_Energy_gamma.txt"

    if [ "$batchSystem" = "Condor" ];then
        ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 

    elif [ "$batchSystem" = "No" ];then
        ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 

    else
        echo "Please select whether you wish to use condor."
    fi

    if [ $? -ne 0 ]; then 
      echo "Problem with root file generation! Check job log files!"
      exit 1

    fi

#    ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e 90 -g "Barrel"  -i "0.2" -j "0.6"
#    ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e 90 -g "EndCap" -i "0.2" -j "0.6"
    ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e 90 
    ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "Barrel" -i "-0.1" -j "0.65"
    ECalDigitisation_ContainedEvents -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "EndCap" -i "0.8" -j "0.92"

    cd ${PythonReadScripts}
    CalibrECAL=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECAL} "Calibration_Constant" "")
    ECal_Mean=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECAL} "Mean" "")

    CalibrECALBarrel=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALBarrel} "Calibration_Constant" "Barrel")
    CalibrECALEndCap=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALEndCap}  "Calibration_Constant" "EndCap")
    
    ECal_Barrel_Mean=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALBarrel} "Mean" "Barrel")
    ECal_EndCap_Mean=$(python ECal_Digi_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${CalibrECALEndCap} "Mean" "EndCap")

    CalibrECALEndCapCorr=$(python -c "print ${CalibrECALEndCapCorr}*${CalibrECALEndCap}/${CalibrECALBarrel}")

    Fractional_Error_ECal_Mean=$(echo "scale=10; sqrt((${photonEnergyCalibration} -${ECal_Mean})^2)/${photonEnergyCalibration}" | bc)

    CheckECalDigi=$(echo "$Fractional_Error_ECal_Mean >= ${digitisationAccuracy}" | bc -l)
done


#===============================================#
#          HCAL Digitisation Constants          #
#===============================================#
# Generate Marlin steering files with initial guesses
echo "HCAL Digitisation: Generate Marlin steering files with initial guesses"

cd ${XmlGeneration}
echo python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 

python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  

# Generate root files

cd ${RootFileGeneration}
Runfile="Marlin_Runfile_${kaonLEnergyCalibration}_GeV_Energy_K0L.txt"

if [ "$batchSystem" = "Condor" ];then
    ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 

elif [ "$batchSystem" = "No" ];then
    ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 

else
    echo "Please select whether you wish to use condor."
fi


if [ $? -ne 0 ]; then 
 echo "Problem with root file generation! Check job log files!"
 exit 1

fi

# Find and update CalibrHCALBarrel and CalibrHCALEndCap

HCalDigitisation_ContainedEvents -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "Barrel" -i "0.2" -j "0.6" 
HCalDigitisation_ContainedEvents -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "EndCap" -i "0.8" -j "0.9" 

cd ${PythonReadScripts}
CalibrHCALBarrel=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALBarrel} "Barrel" "Calibration_Constant")
CalibrHCALEndCap=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALEndCap} "EndCap" "Calibration_Constant")

HCal_Barrel_Mean=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALBarrel} "Barrel" "Mean")
HCal_EndCap_Mean=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALEndCap} "EndCap" "Mean")

Fractional_HCal_Barrel_Mean=$(echo "scale=10; sqrt((${kaonLKineticEnergyCalibration} -${HCal_Barrel_Mean})^2)/${kaonLKineticEnergyCalibration}" | bc)
Fractional_HCal_EndCap_Mean=$(echo "scale=10; sqrt((${kaonLKineticEnergyCalibration} -${HCal_EndCap_Mean})^2)/${kaonLKineticEnergyCalibration}" | bc)

# Loop until CalibrHCALBarrel and CalibrHCALEndCap acceptable
CheckHCalBarrelDigi=$(echo "$Fractional_HCal_Barrel_Mean >= ${digitisationAccuracy}" | bc -l)
CheckHCalEndCapDigi=$(echo "$Fractional_HCal_EndCap_Mean >= ${digitisationAccuracy}" | bc -l)

while [[ $CheckHCalBarrelDigi -gt 0 ]] || [[ $CheckHCalEndCapDigi -gt 0 ]]
do
    echo "HCAL Digitisation: iterating. Creating xml files"

    cd ${XmlGeneration}
    echo python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}
    
    python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  

    cd ${RootFileGeneration}
    Runfile="Marlin_Runfile_${kaonLEnergyCalibration}_GeV_Energy_K0L.txt"

    if [ "$batchSystem" = "Condor" ];then
        ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 

    elif [ "$batchSystem" = "No" ];then
        ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 

    else
        echo "Please select whether you wish to use condor."
    fi


    if [ $? -ne 0 ]; then 
      echo "Problem with root file generation! Check job log files!"
      exit 1

    fi

    HCalDigitisation_ContainedEvents -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "Barrel" -i "0.2" -j "0.6"
    HCalDigitisation_ContainedEvents -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${digitisationAccuracy}" -d "${outputPath}" -e "90" -g "EndCap" -i "0.8" -j "0.9"

    cd ${PythonReadScripts}
    CalibrHCALBarrel=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALBarrel} "Barrel" "Calibration_Constant")
    CalibrHCALEndCap=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALEndCap} "EndCap" "Calibration_Constant")

    HCal_Barrel_Mean=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALBarrel} "Barrel" "Mean")
    HCal_EndCap_Mean=$(python HCal_Digi_Extract.py ${calibrationFile} ${kaonLKineticEnergyCalibration} ${CalibrHCALEndCap} "EndCap" "Mean")

    Fractional_HCal_Barrel_Mean=$(echo "scale=10; sqrt( (${kaonLKineticEnergyCalibration} -${HCal_Barrel_Mean})^2)/${kaonLKineticEnergyCalibration}" | bc)
    Fractional_HCal_EndCap_Mean=$(echo "scale=10; sqrt( (${kaonLKineticEnergyCalibration} -${HCal_EndCap_Mean})^2)/${kaonLKineticEnergyCalibration}" | bc)

    CheckHCalBarrelDigi=$(echo "$Fractional_HCal_Barrel_Mean >= ${digitisationAccuracy}" | bc -l)
    CheckHCalEndCapDigi=$(echo "$Fractional_HCal_EndCap_Mean >= ${digitisationAccuracy}" | bc -l)
done

echo "Generate Marlin steering files for muons, needed for HCal ring calibration"
cd ${XmlGeneration}
echo python Xml_Generate.py ${muonEnergyCalibration} "mu-" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${muonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  
python Xml_Generate.py ${muonEnergyCalibration} "mu-" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${muonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}  

# Process steering files
cd ${RootFileGeneration}
Runfile="Marlin_Runfile_${muonEnergyCalibration}_GeV_Energy_mu-.txt"

if [ "$batchSystem" = "Condor" ];then
    ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 

elif [ "$batchSystem" = "No" ];then
    ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 

else
    echo "Please select whether you wish to use condor."
fi


if [ $? -ne 0 ]; then 
 echo "Problem with root file generation! Check job log files!"
 exit 1

fi

HCalDigitisation_DirectionCorrectionDistribution -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${outputPath}" 
SimCaloHitEnergyDistribution -a "${muonRootFiles}" -b "${muonEnergyCalibration}" -c "${outputPath}" 

cd ${PythonReadScripts}

Absorber_Thickness_EndCap=20.0
Scintillator_Thickness_Ring=3.0
Absorber_Thickness_Ring=20.0
Scintillator_Thickness_EndCap=3.0

Absorber_Scintillator_Ratio=$(echo "(${Absorber_Thickness_EndCap}*${Scintillator_Thickness_Ring})/(${Absorber_Thickness_Ring}*${Scintillator_Thickness_EndCap})"|bc)

# # Ratio is (Ab_Ec*Sc_R)/(Ab_R*Sc_Ec)
# Absorber_Scintillator_Ratio=$(python HCal_Ring_Gear_Information.py ${calibrationFile} ${gearFile} ${muonEnergyCalibration})

# Ratio is MIP_Peak_Ec/MIP_Peak_Ring
MIP_Peak_Ratio=$(python HCal_Ring_Digi_Extract.py ${calibrationFile} ${muonEnergyCalibration})

# Ratio is Dir_Corr_Ec/Dir_Corr_Ring
Direction_Correction_Ratio=$(python HCal_Direction_Corrections_Extract.py ${calibrationFile} ${kaonLEnergyCalibration})

CalibrHCALOther=$(echo "scale=10; " ${Direction_Correction_Ratio}*${MIP_Peak_Ratio}*${Absorber_Scintillator_Ratio}*${CalibrHCALEndCap}*${kaonLKineticEnergyCalibration}/${HCal_EndCap_Mean}| bc)


echo "CalibrHCALOther is: "${CalibrHCALOther}

if [ "${CalibrHCALOther}" ]; then
    echo "CalibrHCALOther is: "${CalibrHCALOther}
else

    CalibrHCALOther=$CalibrHCALEndCap
    echo "WARNING! CalibrHCALOther is NOT CALCULATED! SET MANUALLY TO: "${CalibrHCALOther}

fi


echo "_____________________________________________________________________________________" >> ${calibrationFile} 
echo "CalibrHCALOther                                     : ${CalibrHCALOther} " >> ${calibrationFile} 

#===============================================#
#             GeV To MIP Constants              #
#===============================================#

PandoraPFACalibrate_MipResponse -a "${muonRootFiles}" -b "${muonEnergyCalibration}" -c "${outputPath}" 

cd ${PythonReadScripts}
ECalGeVToMIP=$(python Extract_GeVToMIP.py ${calibrationFile} ${muonEnergyCalibration} "ECal")

HCalGeVToMIP=$(python Extract_GeVToMIP.py ${calibrationFile} ${muonEnergyCalibration} "HCal")

MuonGeVToMIP=$(python Extract_GeVToMIP.py ${calibrationFile} ${muonEnergyCalibration} "Muon")

ECalMIPMPV=$(python Extract_SimCaloHitMIPMPV.py ${calibrationFile} "ECal")
HCalMIPMPV=$(python Extract_SimCaloHitMIPMPV.py ${calibrationFile} "HCal")

#===============================================#
#===============================================#
#            PandoraPFA Calibration             #
#===============================================#
#===============================================#

#===============================================#
# Electromagnetic Energy Scale (gamma Events)  #
#===============================================#
echo "Pandora PFA Calibration: Generate Marlin steering files with initial guesses"

# Generate Xml Files With Initial Guesses
cd ${XmlGeneration}
echo python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 
python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 

# Generate Root Files

cd ${RootFileGeneration}
Runfile="Marlin_Runfile_${photonEnergyCalibration}_GeV_Energy_gamma.txt"

if [ "$batchSystem" = "Condor" ];then
    ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 

elif [ "$batchSystem" = "No" ];then
    ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 

else
    echo "Please select whether you wish to use condor."
fi


if [ $? -ne 0 ]; then 
 echo "Problem with root file generation! Check job log files!"
 exit 1

fi

# ECalToEm and HCalToEM Calibration 

PandoraPFACalibrate_EMScale -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${pandoraPFAAccuracy}" -d "${outputPath}" -e "90" 

cd ${PythonReadScripts}
ECalToEm=$(python EM_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${ECalToEm} "Calibration_Constant")
HCalToEm=${ECalToEm}

EM_Mean=$(python EM_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${ECalToEm} "Mean")

Fractional_EM_Error=$(echo "scale=10; sqrt( (${photonEnergyCalibration} -${EM_Mean})^2)/${photonEnergyCalibration}" | bc)

CheckECalToEMPandoraPFA=$(echo "$Fractional_EM_Error >= ${pandoraPFAAccuracy}" | bc -l)

while [ $CheckECalToEMPandoraPFA -gt 0 ]
do

    echo "Pandora PFA Calibration: Iterating for ECalToEM"

    cd ${XmlGeneration}
    echo python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml}
    python Xml_Generate.py ${photonEnergyCalibration} "gamma" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${gammaPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 

    cd ${RootFileGeneration}
    Runfile="Marlin_Runfile_${photonEnergyCalibration}_GeV_Energy_gamma.txt"

    if [ "$batchSystem" = "Condor" ];then
        ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 

    elif [ "$batchSystem" = "No" ];then
        ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 

    else
        echo "Please select whether you wish to use condor."
    fi


    if [ $? -ne 0 ]; then 
      echo "Problem with root file generation! Check job log files!"
      exit 1

    fi

    PandoraPFACalibrate_EMScale -a "${photonRootFiles}" -b "${photonEnergyCalibration}" -c "${pandoraPFAAccuracy}" -d "${outputPath}" -e "90" 

    cd ${PythonReadScripts}
    ECalToEm=$(python EM_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${ECalToEm} "Calibration_Constant")
    HCalToEm=${ECalToEm}

    EM_Mean=$(python EM_Extract.py ${calibrationFile} ${photonEnergyCalibration} ${ECalToEm} "Mean")
    Fractional_EM_Error=$(echo "scale=10; sqrt( (${photonEnergyCalibration} -${EM_Mean})^2)/${photonEnergyCalibration}" | bc)

    CheckECalToEMPandoraPFA=$(echo "$Fractional_EM_Error >= ${pandoraPFAAccuracy}" | bc -l)
done

#===============================================#
#      Hadronic Energy Scale (KaonL Events)     #
#===============================================#
echo "Pandora PFA Had Calibration: Generate Xml Files With Initial Guesses for Had"

# Generate Xml Files With Initial Guesses
cd ${XmlGeneration}
echo python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 
python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 

# Generate Root Files
cd ${RootFileGeneration}
Runfile="Marlin_Runfile_${kaonLEnergyCalibration}_GeV_Energy_K0L.txt"

if [ "$batchSystem" = "Condor" ];then
    ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 
elif [ "$batchSystem" = "No" ];then
    ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 
else
    echo "Please select whether you wish to use condor."
fi


if [ $? -ne 0 ]; then 
 echo "Problem with root file generation! Check job log files!"
 exit 1

fi
# HCalToHad and ECalToHad Calibration 

echo ${kaonLEnergyCalibration}
echo "${kaonRootFiles}"
echo "${numberHCalLayers}"
echo "${pandoraPFAAccuracy}"
echo "${outputPath}" 

if [ "$hadronicScaleSettingPandora" = "CSM" ];then
    PandoraPFACalibrate_HadronicScale_ChiSquareMethod -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${pandoraPFAAccuracy}" -d "${outputPath}" -e "${numberHCalLayers}" 
elif [ "$hadronicScaleSettingPandora" = "TEM" ];then
    PandoraPFACalibrate_HadronicScale_TotalEnergyMethod -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${pandoraPFAAccuracy}" -d "${outputPath}" -e "90" -f "${numberHCalLayers}" 
else
    echo "Select a calibration method."
fi

# Update HCTH and ECTH
cd ${PythonReadScripts}

HCalToHad=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "HCTH" ${HCalToHad} "Calibration_Constant" ${hadronicScaleSettingPandora}) 
echo $HCalToHad

ECalToHad=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "ECTH" ${ECalToHad} "Calibration_Constant" ${hadronicScaleSettingPandora}) 
echo $ECalToHad

HCalToHad_Fom=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "HCTH" ${HCalToHad} "FOM" ${hadronicScaleSettingPandora}) 
echo $HCalToHad_Fom

ECalToHad_Fom=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "ECTH" ${ECalToHad} "FOM" ${hadronicScaleSettingPandora}) 
echo $ECalToHad_Fom

# Target Limits on recostruction
UpperLimit=$(echo "1 + ${pandoraPFAAccuracy}" | bc)
LowerLimit=$(echo "1 - ${pandoraPFAAccuracy}" | bc)
echo $UpperLimit
echo $LowerLimit

# Limits on reconstruction

if [ "$hadronicScaleSettingPandora" = "CSM" ];then
    HCalToHad_UL=$(echo "${kaonLKineticEnergyCalibration}*${UpperLimit}" | bc)
    HCalToHad_LL=$(echo "${kaonLKineticEnergyCalibration}*${LowerLimit}" | bc)
    ECalToHad_UL=$(echo "${kaonLKineticEnergyCalibration}*${UpperLimit}" | bc)
    ECalToHad_LL=$(echo "${kaonLKineticEnergyCalibration}*${LowerLimit}" | bc)

    CheckOne=$(echo "$HCalToHad_Fom >= $HCalToHad_UL" | bc -l)
    CheckTwo=$(echo "$HCalToHad_Fom <= $HCalToHad_LL" | bc -l)
    CheckThree=$(echo "$ECalToHad_Fom >= $ECalToHad_UL" | bc -l)
    CheckFour=$(echo "$ECalToHad_Fom <= $ECalToHad_LL" | bc -l)
elif [ "$hadronicScaleSettingPandora" = "TEM" ];then
    HCalToHad_UL=$(echo "${UpperLimit}" | bc)
    HCalToHad_LL=$(echo "${LowerLimit}" | bc)
    ECalToHad_UL=$(echo "${UpperLimit}" | bc)
    ECalToHad_LL=$(echo "${LowerLimit}" | bc)

    CheckOne=$(echo "$HCalToHad_Fom >= $HCalToHad_UL" | bc -l)
    CheckTwo=$(echo "$HCalToHad_Fom <= $HCalToHad_LL" | bc -l)
    CheckThree=$(echo "$ECalToHad_Fom >= $ECalToHad_UL" | bc -l)
    CheckFour=$(echo "$ECalToHad_Fom <= $ECalToHad_LL" | bc -l)
else
    echo "Select a calibration method."
fi

# Itterate ECTH and HCTH until they are within acceptable limits
while [[ $CheckOne -gt 0 ]] || [[ $CheckTwo -gt 0 ]] || [[ $CheckThree -gt 0 ]] || [[ $CheckFour -gt 0 ]] 
do

    echo "Pandora PFA Had Calibration: Iterating for Had"

    cd ${XmlGeneration}
    echo python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 
    python Xml_Generate.py ${kaonLEnergyCalibration} "K0L" ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${kaonPath} ${slcioFormat} ${gearFile} ${pandoraSettingsFile} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${dd4hep_compact_xml} 
  
    cd ${RootFileGeneration}
    Runfile="Marlin_Runfile_${kaonLEnergyCalibration}_GeV_Energy_K0L.txt"

    if [ "$batchSystem" = "Condor" ];then
        ./condorSupervisor_Calibration.sh ${Runfile} ${maxNumCondorJobs} 
    elif [ "$batchSystem" = "No" ];then
        ./DummyCondorSupervisor.sh ${Runfile} ${maxNumCondorJobs} 
    else
        echo "Please select whether you wish to use condor."
    fi


    if [ $? -ne 0 ]; then 
      echo "Problem with root file generation! Check job log files!"
      exit 1

    fi

    if [ "$hadronicScaleSettingPandora" = "CSM" ];then
        PandoraPFACalibrate_HadronicScale_ChiSquareMethod -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${pandoraPFAAccuracy}" -d "${outputPath}" -e "${numberHCalLayers}" 
    elif [ "$hadronicScaleSettingPandora" = "TEM" ];then
        PandoraPFACalibrate_HadronicScale_TotalEnergyMethod -a "${kaonRootFiles}" -b "${kaonLEnergyCalibration}" -c "${pandoraPFAAccuracy}" -d "${outputPath}" -e "90" -f "${numberHCalLayers}" 
    else
        echo "Select a calibration method."
    fi

    cd ${PythonReadScripts}
    HCalToHad=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "HCTH" ${HCalToHad} "Calibration_Constant" ${hadronicScaleSettingPandora}) 
    ECalToHad=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "ECTH" ${ECalToHad} "Calibration_Constant" ${hadronicScaleSettingPandora}) 
    HCalToHad_Fom=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "HCTH" ${HCalToHad} "FOM" ${hadronicScaleSettingPandora}) 
    ECalToHad_Fom=$(python Had_Extract.py ${calibrationFile} ${kaonLEnergyCalibration} "ECTH" ${ECalToHad} "FOM" ${hadronicScaleSettingPandora}) 

    if [ "$hadronicScaleSettingPandora" = "CSM" ];then
        HCalToHad_UL=$(echo "${kaonLKineticEnergyCalibration}*${UpperLimit}" | bc) 
        HCalToHad_LL=$(echo "${kaonLKineticEnergyCalibration}*${LowerLimit}" | bc) 
        ECalToHad_UL=$(echo "${kaonLKineticEnergyCalibration}*${UpperLimit}" | bc) 
        ECalToHad_LL=$(echo "${kaonLKineticEnergyCalibration}*${LowerLimit}" | bc) 

        CheckOne=$(echo "$HCalToHad_Fom >= $HCalToHad_UL" | bc -l) 
        CheckTwo=$(echo "$HCalToHad_Fom <= $HCalToHad_LL" | bc -l) 
        CheckThree=$(echo "$ECalToHad_Fom >= $ECalToHad_UL" | bc -l) 
        CheckFour=$(echo "$ECalToHad_Fom <= $ECalToHad_LL" | bc -l) 

    elif [ "$hadronicScaleSettingPandora" = "TEM" ];then
        HCalToHad_UL=$(echo "${UpperLimit}" | bc) 
        HCalToHad_LL=$(echo "${LowerLimit}" | bc) 
        ECalToHad_UL=$(echo "${UpperLimit}" | bc) 
        ECalToHad_LL=$(echo "${LowerLimit}" | bc) 
        
        CheckOne=$(echo "$HCalToHad_Fom >= $HCalToHad_UL" | bc -l) 
        CheckTwo=$(echo "$HCalToHad_Fom <= $HCalToHad_LL" | bc -l) 
        CheckThree=$(echo "$ECalToHad_Fom >= $ECalToHad_UL" | bc -l) 
        CheckFour=$(echo "$ECalToHad_Fom <= $ECalToHad_LL" | bc -l) 

    else
        echo "Select a calibration method."
    fi
done

#===============================================#
#           Final Calibration Numbers           #
#===============================================#
echo
echo "All jobs done. Calculating final calibration numbers."
echo 
cd ${PythonReadScripts}
python Final_Calibration.py ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCap} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${outputPath} 

cd ${XmlGeneration}
python Xml_Generate_Output.py ${ECalToEm} ${HCalToEm} ${ECalToHad} ${HCalToHad} ${CalibrECALBarrel} ${CalibrECALEndCapCorr} ${CalibrHCALBarrel} ${CalibrHCALEndCap} ${CalibrHCALOther} ${MHHHE} ${ECalGeVToMIP} ${HCalGeVToMIP} ${MuonGeVToMIP} ${HCALBarrelTimeWindowMax} ${HCALEndcapTimeWindowMax} ${ECALBarrelTimeWindowMax} ${ECALEndcapTimeWindowMax} ${outputPath} 


echo
echo "All output results are collected in "${calibrResultsFile}
echo 
cat > ${calibrResultsFile} << EOF

#Calibration data for ${geometryModelName} with Cassette
#Commands used: $@

#Digitization constants
CALIBRECAL="${CalibrECAL}"
CALIBRECALBARREL="${CalibrECALBarrel}" 
CALIBRECALENDCAP="${CalibrECALEndCap}"
CALIBRECALENDCAPCORR="${CalibrECALEndCapCorr}" 
CALIBRHCALBARREL="${CalibrHCALBarrel}"
CALIBRHCALENDCAP="${CalibrHCALEndCap}"
CALIBRHCALOTHER="${CalibrHCALOther}"
CALIBRMUON="70.1"
ECALTOMIP="${ECalGeVToMIP}" 
HCALTOMIP="${HCalGeVToMIP}"
MUONTOMIP="${MuonGeVToMIP}"

#Pandora Constants
ECALTOEM=${ECalToEm}
HCALTOEM=${HCalToEm}
ECALTOHADBARREL=${ECalToHad}
ECALTOHADENDCAP=${ECalToHad}
HCALTOHAD=${HCalToHad}
MHHHE=${MHHHE}

DO_NLC=0
INPUT_ENERGY_CORRECTION_POINTS="${energies[@]}"
OUTPUT_ENERGY_CORRECTION_POINTS="${energies[@]}"
EOF

#===============================================#
#                      End                      #
#===============================================#
echo
echo "All done!"
