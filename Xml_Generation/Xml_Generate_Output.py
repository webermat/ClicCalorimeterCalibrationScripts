# -*- coding: utf-8 -*-
import os
import re
import random
import dircache
import sys

def find_between( s, first, last ):
    try:
        start = s.index( first ) + len( first )
        end = s.index( last, start )
        return s[start:end]
    except ValueError:
        return ''

#===========================
# Input Variables
#===========================
print sys.argv

ECALTOEM = sys.argv[1]
HCALTOEM = sys.argv[2]
ECALTOHAD = sys.argv[3]
HCALTOHAD = sys.argv[4]

CALIBR_ECAL_BARREL_INPUT = sys.argv[5]
CALIBR_ECAL_BARREL_INPUT2 = float(CALIBR_ECAL_BARREL_INPUT)
CALIBR_ECAL_BARREL = str(CALIBR_ECAL_BARREL_INPUT) + ' ' + str(CALIBR_ECAL_BARREL_INPUT2)
#Of the form: <parameter name="CalibrECAL" type="FloatVec">42.91 85.82 </parameter>

CALIBR_ECAL_ENDCAPCORR = sys.argv[6]

CALIBR_HCAL_BARREL = sys.argv[7]
CALIBR_HCAL_ENDCAP = sys.argv[8]
CALIBR_HCAL_OTHER = sys.argv[9]

MHHHE = sys.argv[10]

ECalGeVToMIP = sys.argv[11]
HCalGeVToMIP = sys.argv[12]
MuonGeVToMIP = sys.argv[13]

HCALBarrelTimeWindowMax = sys.argv[14]
HCALEndcapTimeWindowMax = sys.argv[15]
ECALBarrelTimeWindowMax = sys.argv[16]
ECALEndcapTimeWindowMax = sys.argv[17]

Output_Path = sys.argv[18]

#===========================

ECAL_MIP_THRESHOLD = '0.5'
HCAL_MIP_THRESHOLD = '0.3'

baseFileName = 'CLIC_PfoAnalysis_AAAA_SN_BBBB.xml'

jobList = ''

base = open(baseFileName,'r')
baseContent = base.read()
base.close()

newContent = baseContent

newContent = re.sub('ECALTOEM_XXXX',ECALTOEM,newContent)
newContent = re.sub('HCALTOEM_XXXX',HCALTOEM,newContent)
newContent = re.sub('ECALTOHAD_XXXX',ECALTOHAD,newContent)
newContent = re.sub('HCALTOHAD_XXXX',HCALTOHAD,newContent)
newContent = re.sub('MHHHE_XXXX',MHHHE,newContent)
newContent = re.sub('CALIBR_ECAL_BARREL_XXXX',CALIBR_ECAL_BARREL,newContent)
newContent = re.sub('CALIBR_ECAL_ENDCAPCORR_XXXX' ,CALIBR_ECAL_ENDCAPCORR,newContent)
newContent = re.sub('CALIBR_HCAL_BARREL_XXXX',CALIBR_HCAL_BARREL,newContent)
newContent = re.sub('CALIBR_HCAL_ENDCAP_XXXX',CALIBR_HCAL_ENDCAP,newContent)
newContent = re.sub('CALIBR_HCAL_OTHER_XXXX',CALIBR_HCAL_OTHER,newContent)
newContent = re.sub('EMT_XXXX',ECAL_MIP_THRESHOLD,newContent)
newContent = re.sub('HMT_XXXX',HCAL_MIP_THRESHOLD,newContent)
newContent = re.sub('ECalGeVToMIP_XXXX',ECalGeVToMIP,newContent)
newContent = re.sub('HCalGeVToMIP_XXXX',HCalGeVToMIP,newContent)
newContent = re.sub('MuonGeVToMIP_XXXX',MuonGeVToMIP,newContent)
newContent = re.sub('HCALBarrelTimeWindowMax_XXXX',HCALBarrelTimeWindowMax,newContent)
newContent = re.sub('HCALEndcapTimeWindowMax_XXXX',HCALEndcapTimeWindowMax,newContent)
newContent = re.sub('ECALBarrelTimeWindowMax_XXXX',ECALBarrelTimeWindowMax,newContent)
newContent = re.sub('ECALEndcapTimeWindowMax_XXXX',ECALEndcapTimeWindowMax,newContent)

Fullpath = os.path.join(Output_Path, baseFileName)

file = open(Fullpath,'w')
file.write(newContent)
file.close()


