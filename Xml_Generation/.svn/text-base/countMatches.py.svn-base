import os
import dircache
import sys
import re

#simple script to count matched slcio files in a given path. It also prints the first and last matched index (if there)
#so the user can debug the matching with the filename indices
def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    '''
    alist.sort(key=natural_keys) sorts in human order
    http://nedbatchelder.com/blog/200712/human_sorting.html
    (See Toothy's implementation in the comments)
    '''
    return [ atoi(c) for c in re.split('(\d+)', text) ]

if len(sys.argv)<3:
    print "Syntax: "+sys.argv[0]+" <lcio path> <filame format>"
    sys.exit(0)
    
fileDirectory = sys.argv[1]
Slcio_Format = sys.argv[2]



allFilesInDirectory = dircache.listdir(fileDirectory)

allFiles = []
allFiles.extend(allFilesInDirectory)
allFiles[:] = [ item for item in allFiles if re.match(Slcio_Format,item) ]
allFiles.sort(key=natural_keys)

if len(allFiles)==0 :
    print 0
    sys.exit(0)


matchObj = re.match(Slcio_Format, allFiles[0], re.M|re.I)

firstIndex=0
if len(matchObj.groups())>0:
    firstIndex = matchObj.group(1)

matchObj = re.match(Slcio_Format, allFiles[-1], re.M|re.I)
lastIndex=0

if len(matchObj.groups())>0:
    lastIndex = matchObj.group(1)

print "%d ( %s ... %s )" % (len(allFiles),firstIndex,lastIndex)
