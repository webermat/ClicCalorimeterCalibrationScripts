# -*- coding: utf-8 -*-
import os
import re
import random
import dircache
import sys

Source_File = sys.argv[1]

baseFileName =  os.path.join(os.getcwd(), 'Marlin_Calibration.sh')

base = open(baseFileName,'r')
baseContent = base.read()
base.close()

newContent=''

with open(baseFileName, 'r') as f:
    searchlines = f.readlines()
    for line in searchlines:
        if 'source ' in line:
            newContent += 'source ' + Source_File + '\n'
        else:
            newContent += line

file = open(baseFileName,'w')
file.write(newContent)
file.close()
