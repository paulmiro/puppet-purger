#!/bin/sh

# Script:   puppet-purger.sh
# Purpose:  deletes old puppet reports
# Author:   Alexander Zenger, github (at) zengers (dot) de
# License:  GPLv2, see LICENSE file

# be strict
set -e
set -u
# pipefail is not supported on BSD bourne sh
#set -o pipefail

# global variables
SCRIPTNAME=$(basename $0 .sh)
VERSION=0.1
# exit codes
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

# variables
# directory, where the reports are
reportDir="/var/lib/puppet/reports"
# number of days a report must be old to be deleted
days="30"
# simulate action instead of deleting something for real
simulate="false"
# suppress output
quiet="false"

# functions 
#
# delete puppet reports which are older than $days
# orginal code idea from https://groups.google.com/d/msg/puppet-users/q8vWDr3bn4Q/nsjpAHPsvrEJ
purgeReports()
{
  local nodes
  local files=""

  nodes=`find ${reportDir} -mindepth 1 -maxdepth 1 -type d`

  for node in ${nodes}
  do
    files=`find ${node} -type f -name '*.yaml' -mtime +${days} |
      sort -r |
      tail -n +2`

    for file in ${files}
    do
      if [ ${simulate} = "true" ]
      then
        echo "Simulating: rm -f ${file}"
      else
        if [ ${quiet} = "true" ]
        then
          echo "rm -f ${file}"
        fi
        
        # actual do something
        rm -f ${file}
      fi
    done

    files=""
  done
}

# prints usage
usage()
{
  echo ""
  echo "This script deletes puppet reports file which are older than the"
  echo "given number of days. The newest report will always be not deleted,"
  echo "even if it's older than the given number of days."
  echo "The script is intended to run on the puppet master, where the reports"
  echo "are saved."
  echo ""
  echo "Usage: ${SCRIPTNAME} [-h] [-v] [-q] [-s] [-d report directory]"
  echo "                   [ -n file age in days]"
  echo ""
  echo "Options:"
  echo "-h Print this help message"
  echo "-v Print script version"
  echo "-d Sets directory where the reports are (default: ${reportDir})"
  echo "-n delete reports older than number of days (default: ${days})"
  echo "-s enables simulating mode where not files are deleted"
  echo "-q enables quiet mode where no unnecessary output is made"
  [ ${#} -eq 1 ] && exit ${1} || exit ${EXIT_FAILURE}
}

# get options
while getopts ':d:n:sqvh' OPTION 
do
 case ${OPTION} in
 d) reportDir="${OPTARG}"
 ;;
 n) days="${OPTARG}"
 ;;
 s) simulate="true"
 ;;
 q) quiet="true"
 ;;
 v) echo "VERSION: ${VERSION}"
    exit ${EXIT_SUCCESS}
 ;;
 h) usage ${EXIT_SUCCESS}
 ;;
 \?) echo "Unknown option \"-${OPTARG}\"" >&2
 usage ${EXIT_ERROR}
 ;;
 :) echo "Option \"-${OPTARG}\" needs an argument" >&2
 usage ${EXIT_ERROR}
 ;;
 *) echo "This shouldn't happen and is kind of embarrassing" >&2
 usage ${EXIT_BUG}
 ;;
 esac
done

# all fine, begin actual work
purgeReports

exit ${EXIT_SUCCESS}
