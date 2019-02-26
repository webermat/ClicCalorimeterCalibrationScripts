#!/bin/bash

rm -f *~;
rm -f GearOutput.xml
rm -f Xml_Files/*.xml;
rm -f Root_Files/*.root;

rm -f Marlin_Xml/*.xml;

rm -rf calibrationOutput;

rm -rf Root_File_Generation/CondorLogs;

rm -f */*.so;
rm -f */*.d;


rm -f Kaon_Plot_Generation/outputplots.root;
rm -f Root_File_Generation/Marlin_Runfile_*txt;
rm -f Root_File_Generation/MarlinCalib[0-9]*.sh;
rm -f Root_File_Generation/temp_Calibration.job;
rm -f Root_File_Generation/credentials.krb5;
rm -f Root_File_Generation/CondorLogs/*;


rm -f output/*;

