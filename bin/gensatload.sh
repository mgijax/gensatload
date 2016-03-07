#!/bin/sh
#
#  gensatload.sh
###########################################################################
#
#  Purpose:
#
#      This script serves as a wrapper for the gensatload.py script.
#
#  Usage:
#
#      gensatload.sh
#
#
#  Env Vars:
#
#      See the configuration files
#
#  Inputs:  None
#
#  Outputs:
#
#      - Generated Input File (${GENSATLOAD_INPUTFILE}) containing a list of
#        EntrezGene IDs
#
#      - Log file (${GENSATLOAD_LOGFILE})
#
#  Exit Codes:
#
#      0:  Successful completion
#      1:  Fatal error occurred
#
#  Assumes:  Nothing
#
#  Implementation:
#
#      This script will perform following steps:
#
#      1) Call the Python script (parseGensatEntrez.py) to generate the input
#         file for the load 
#      2) Create the temp table for the input data.
#      3) Load the input file into the temp table.
#      4) Call the Python script (gensatload.py) to create a bcp file with
#         GENSAT associations and a discrepancy report for input records that
#         could not be processed.
#      5) Drop the temp table.
#      6) Delete the existing GENSAT associations.
#      7) Load the bcp file into the ACC_Accession table to establish the
#         new GENSAT associations.
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
#  07/11/2008  DBM  Initial development
#
###########################################################################

cd `dirname $0`
. ../Configuration

LOG=${GENSATLOAD_LOGFILE}
rm -rf ${LOG}
touch ${LOG}

#
# Create a temporary file that will hold the return code from calling the
# Python script.  Make sure the file is removed when this script terminates.
#
TMP_RC=/tmp/`basename $0`.$$
TMP_DIFF=/tmp/`basename $0`.diff.$$
trap "rm -f ${TMP_RC} ${TMP_DIFF}" 0 1 2 15

if [ -f ${INPUTFILE_BAK} ]
then
    diff ${INPUTFILE} ${INPUTFILE_BAK} >> ${TMP_DIFF} 2>&1
    # if the diff file is empty don't run the load
    if [ ! -s ${TMP_DIFF} ] 
    then
	echo "The GENSAT load input file has not changed " | tee -a ${LOG}
	echo "" >> ${LOG}
	date >> ${LOG}
	exit 0
    fi
fi

#
# Generate the input file for the load.
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Generate the input file for the load" | tee -a ${LOG}
{ ./parseGensatEntrez.py 2>&1; echo $? > ${TMP_RC}; } >> ${LOG}
if [ `cat ${TMP_RC}` -ne 0 ]
then
    echo "GENSAT load failed" | tee -a ${LOG}
    exit 1
elif [ ! -s ${GENSATLOAD_INPUTFILE} ]
then
    echo "The GENSAT load input file is empty" | tee -a ${LOG}
    exit 1
fi

#
# Create the temp table for the input data.
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Create the temp table (${GENSAT_TEMP_TABLE}) for the input data" | tee -a ${LOG}
cat - <<EOSQL | psql -h${MGD_DBSERVER} -d${MGD_DBNAME} -U ${MGD_DBUSER} -e  >> ${LOG}

create table ${GENSAT_TEMP_TABLE} (
    entrezgeneID text not null
);

create index idx_entrezgeneID on ${GENSAT_TEMP_TABLE} (lower(entrezgeneID));

grant all on ${GENSAT_TEMP_TABLE} to public;

EOSQL

#
# Load the input file into the temp table.
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Load the input file into the temp table" | tee -a ${LOG}
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} ${GENSAT_TEMP_TABLE} "/" ${GENSATLOAD_INPUTFILE} "\t" "\n" mgd >> ${LOG}

#
# Create the GENSAT association file and discrepancy report.
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Create the GENSAT association file and discrepancy report" | tee -a ${LOG}
{ ./gensatload.py 2>&1; echo $? > ${TMP_RC}; } >> ${LOG}
if [ `cat ${TMP_RC}` -ne 0 ]
then
    echo "GENSAT load failed" | tee -a ${LOG}
    QUIT=1
elif [ ! -s ${GENSATLOAD_ACC_BCPFILE} ]
then
    echo "The association file is empty" | tee -a ${LOG}
    QUIT=1
else
    QUIT=0
fi

#
# Drop the temp table.
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Drop the temp table (${GENSAT_TEMP_TABLE})" | tee -a ${LOG}
cat - <<EOSQL | psql -h${MGD_DBSERVER} -d${MGD_DBNAME} -U ${MGD_DBUSER} -e  >> ${LOG}

drop table ${GENSAT_TEMP_TABLE};

EOSQL

#
# Do not attempt to delete/reload the GENSAT associations if there was a
# problem creating the assocation file.
#
if [ ${QUIT} -eq 1 ]
then
    exit 1
fi

#
# Delete the existing GENSAT associations.
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Delete the existing GENSAT associations" | tee -a ${LOG}
cat - <<EOSQL | psql -h${MGD_DBSERVER} -d${MGD_DBNAME} -U ${MGD_DBUSER} -e  >> ${LOG}


delete from ACC_Accession a
using ACC_LogicalDB ldb
where ldb._LogicalDB_key = a._logicaldb_key
	and ldb.name = 'GENSAT'
;

EOSQL

#
# Load the new GENSAT associations.
#
echo "" >> ${LOG}
date >> ${LOG}
echo "Load the new GENSAT associations" | tee -a ${LOG}
${PG_DBUTILS}/bin/bcpin.csh ${MGD_DBSERVER} ${MGD_DBNAME} ACC_Accession "/" ${GENSATLOAD_ACC_BCPFILE} "\t" "\n" mgd >> ${LOG}

date >> ${LOG}

echo "" >> ${LOG}
echo "Backup processed file" | tee -a ${LOG}
cp -p ${INPUTFILE} ${INPUTFILE_BAK}

date >> ${LOG}

exit 0
