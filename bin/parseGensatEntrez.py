#!/usr/local/bin/python
#
#  getGensatEntrez.py
###########################################################################
#
#  Purpose:
#
#      This script replaces getGensatEntrez.py which used NCBI eutils
#      to get the EntrezGene IDs.
#
#  Usage:
#
#      parseGensatEntrez.py
#
#  Env Vars:
#      INPUTFILE
#      GENSATLOAD_INPUTFILE
#
#  Inputs:  None
#
#  Outputs:
#
#      - Generated Input File (${GENSATLOAD_INPUTFILE}) containing a list of
#        EntrezGene IDs
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  An exception occurred
#
#  Assumes:  Nothing
#
#  Notes:  None
#
###########################################################################
#
#  Modification History:
#
#  Date        SE   Change Description
#  ----------  ---  -------------------------------------------------------
#
#  03/20/2012  sc  Initial development
#
###########################################################################

import sys
import os
import string

#
#  GLOBALS
#
inputFile = os.environ['INPUTFILE']

outputFile = os.environ['GENSATLOAD_INPUTFILE']
TAB = '\t'
CRT = '\n'
HEADER = 'EntrezGeneID'

#
# Open the input file
#
try:
    fpInputFile = open(inputFile, 'r')
except:
    print 'Cannot open input file: ' + inputFile
    sys.exit(1)

#
# Open the output file.
#
try:
    fpOutputFile = open(outputFile, 'w')
except:
    print 'Cannot open output file: ' + outputFile
    sys.exit(1)

for line in fpInputFile.readlines():
    tokens = string.split(line, TAB)
    if len(tokens) >= 3:
	egId = string.strip(tokens[2])
	if egId != HEADER:
	    fpOutputFile.write('%s%s' % (egId, CRT) )

#
# Close the files
#
fpInputFile.close()
fpOutputFile.close()

sys.exit(0)
