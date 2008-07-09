#!/usr/local/bin/python
#
#  getGensatEntrez.py
###########################################################################
#
#  Purpose:
#
#      This script will generate the input file for the GENSAT load by
#      invoking the GENSAT query tool to get the EntrezGene IDs.
#
#  Usage:
#
#      getGensatEntrez.py
#
#  Env Vars:
#
#      GENSATLOAD_INPUTFILE
#      GENSATTOOL_DB
#      GENSATTOOL_MAX_ROWS
#      GENSATTOOL_URL
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
#  07/09/2008  DBM  Initial development
#
###########################################################################

import sys
import os
import urllib
from xml.dom.minidom import parse

#
#  GLOBALS
#
outputFile = os.environ['GENSATLOAD_INPUTFILE']
gensatDB = os.environ['GENSATTOOL_DB']
gensatMaxRows = os.environ['GENSATTOOL_MAX_ROWS']
gensatURL = os.environ['GENSATTOOL_URL']

#
# Establish the parameters for the GENSAT query tool.
#
params = urllib.urlencode(
   {'db': gensatDB,
    'retmax': gensatMaxRows,
    'term': 'gene_gensat[filter] AND "Mus musculus"[organism]'})

#
# Open the output file.
#
try:
    fpOutputFile = open(outputFile, 'w')
except:
    print 'Cannot open output file: ' + outputFile
    sys.exit(1)

#
# Access the GENSAT query tools to get the EntrezGene IDs in XML format.
#
f = urllib.urlopen("%s%s" % (gensatURL,params))

#
# Parse the XML document and close the query tool link.
#
doc = parse(f)
f.close()

#
# Get the list of EntrezGene IDs and write each one to the output file.
#
ids = doc.getElementsByTagName("Id")
for id in ids:
    fpOutputFile.write(id.firstChild.data + '\n')

#
# Close the output file.
#
fpOutputFile.close()

sys.exit(0)
