#!/bin/bash
#shellcheck disable=SC1012,SC2140,SC2027,SC2154,SC2207,SC2194,SC2034,SC1083,SC2165,SC2167,SC2319,SC2063,SC2062,SC2046,SC2155,SC2092,SC2254,SC1001,SC1003,SC2001,SC2002,SC2004,SC2006,SC2021,SC2026,SC2028,SC2086,SC2102,SC2116,SC2126,SC2143,SC2153,SC2162,SC2181,SC2196,SC2219,SC2236,SC2268,SC2269
#===============================================================================
# Version Date         # Author             Description
#===============================================================================
# V1.0   2012-02-10 # Vladislav Tembekov Ported from ksh to bash
# V1.1   2012-04-13 # Vladislav Tembekov Fixed extraction GSA users from sudoers file issue
# V1.1.1 2012-04-13 # Vladislav Tembekov Fixed incorrect priv group assignment
# V1.1.2 2012-06-18 # Vladislav Tembekov Fixed incorrect SUDO_ALL assignment
# V1.1.3 2012-07-24 # Vladislav Tembekov Added labeling LDAP IDS in autoldap mode
# V1.1.4 2012-09-06 # Vladislav Tembekov Added check user state on tru64
# V1.1.5 2012-09-20 # Vladislav Tembekov Added -l switch
# V1.1.6 2012-09-28 # Vladislav Tembekov Added check belonging user to a group 
# V1.1.7 2012-10-16 # Vladislav Tembekov Improved check user state on AIX
# V1.1.8 2012-10-30 # Vladislav Tembekov Change GSA config check condition
# V1.1.9 2012-11-16 # Vladislav Tembekov Fixed parsing sudoers include directive
# V1.2.0 2012-11-21 # Vladislav Tembekov Added filter of NIS users
# V1.2.1 2013-02-12 # Vladislav Tembekov Added processing wildcards in host_alias name of sudoers files
# V1.2.2 2013-03-01 # Vladislav Tembekov Added new pattern for account_locked values "yes" and "always"
# V1.2.3 2013-03-13 # Vladislav Tembekov Changed checking existence of ldapsearch on AIX
# V1.2.4 2013-03-28 # Vladislav Tembekov Fixed incorrect SUDO privilege issue 
# V1.2.5 2013-05-15 # Vladislav Tembekov Fixed printing user ID as privileged if GID < 100 on Linux
# V1.2.6 2013-05-28 # Vladislav Tembekov Extended list of privileged users and groups
# V1.2.7 2013-06-05 # Vladislav Tembekov Fixed issue with "ALL" hostname in sudoers file
# V1.2.8 2013-07-15 # Vladislav Tembekov Added trim #includedir directive of sudoers file 
# V1.2.9 2013-08-06 # Vladislav Tembekov Improved check user state on HPUX
# V1.3.0 2013-11-05 # Vladislav Tembekov Change GSA config check condition
# V1.3.1 2013-11-05 # Vladislav Tembekov mef4 support implemented
# V1.3.2 2013-11-18 # Vladislav Tembekov Added Vintela support 
# V1.3.3 2013-11-27 # Vladislav Tembekov Changed privilege user check for RedHat and Debian
# V1.3.4 2014-02-25 # Vladislav Tembekov Fixed issue with incorrect group assignment
# V1.3.5 2014-02-27 # Vladislav Tembekov Rewrite code to check user state on AIX
# V1.3.6 2014-04-03 # Vladislav Tembekov Fixed incorrect LastLogon date output on SunOS 
# V1.3.7 2014-04-04 # Vladislav Tembekov Added Vintela check user state
# V1.3.8 2014-04-09 # Vladislav Tembekov Fixed incorrect sudo groups assignment
# V1.3.9 2014-05-03 # Vladislav Tembekov Improved Vintela check user state
# V1.4.0 2014-05-15 # Vladislav Tembekov Fixed incorrect assignment LDAP user prefix
# V1.4.1 2014-05-26 # Vladislav Tembekov Centrify support implemented
# V1.4.2 2014-06-24 # Vladislav Tembekov Fixed incorrect SUDO_ALIAS assignment causing "blank" entry
# V1.4.3 2014-06-26 # Vladislav Tembekov Added processing local users in vintela mode
# V1.4.4 2014-08-04 # Vladislav Tembekov Added timezone info in output file
# V1.4.5 2014-08-05 # Vladislav Tembekov Improved parsing sudoers include directive
# V1.4.6 2014-09-03 # Vladislav Tembekov Improved removing comments from sudoers file
# V1.4.7 2014-09-04 # Christopher Short  Added regex statements to remove the prefix that are returned during the vastool user 
#                   #                    and group lists from the ABC environment. Changed "vastool list users" command to "vastool list users-allowed"
#                   #                    so the list of users fetched from AD contain only the users relevant to the host the script is executed on.
#                   #                    also added sed statement to strip out prefix when the tmp sudoers file is created
# V1.4.8 2014-09-10 # Vladislav Tembekov Added Centrify user state checking
# V1.4.9 2014-10-10 # Javier Zayas       Fixed Centrify checking - grep regex error
# V1.5.0 2014-11-17 # Vladislav Tembekov Added possibility to change user filter in LDAP query 
# V1.5.1 2014-11-18 # Vladislav Tembekov Fixed includedir directive processing
# V1.5.2 2014-11-25 # Vladislav Tembekov Added code to avoid replace gecos fileld when description field has data
# V1.5.3 2014-12-10 # Vladislav Tembekov Changed code to check existence of user password on AIX
# V1.5.4 2015-01-12 # Vladislav Tembekov Update UNIX Extractors to report sudo privilege *access* using "user token(s)" from command allocation stanza.
# V9.0.1 2015-01-26 # Vladislav Tembekov Update version for all OS scripts. Realign numbering of perl, korn shell and bash scripts.
# V9.0.5 2015-02-23 # Vladislav Tembekov Changed vastool cmdline to list all groups from AD
# V9.0.6 2015-04-09 # Vladislav Tembekov Added path to ldapsearch command to LDAPPARAM file
# V9.0.7 2015-04-09 # Vladislav Tembekov Remove Case sensitivity compare LDAP host attribute
# V9.0.8 2015-06-04 # Vladislav Tembekov Fixed issue reporting user state on AIX
# V9.0.9 2015-07-02 # Vladislav Tembekov Added -i switch for custom signature
# V9.1.0 2015-08-06 # Vladislav Tembekov Hide LDAP password
# V9.1.1 2015-08-12 # Vladislav Tembekov Add error code to the signature record of MEF3/MEF4
# V9.1.2 2015-08-13 # Vladislav Tembekov Added duplicate userid and group check
# V9.1.3 2015-09-24 # Vladislav Tembekov Optimized LDAP connection check
# V9.1.4 2015-10-12 # Vladislav Tembekov Fixed sudoers ##includedir issue 
# V9.1.5 2015-12-11 # Vladislav Tembekov Fixed duplicate local UID finding issue
# V9.1.6 2015-12-14 # Vladislav Tembekov Set priority to GECOS field while extracting user data from AD 
# V9.1.7 2016-01-15 # Vladislav Tembekov Support VIO
# V9.1.8 2016-01-28 # Vladislav Tembekov Improved LDAP user password extracting
# V9.1.9 2016-02-09 # Vladislav Tembekov R000-753 Global Unix OS - check for duplicate IDs and get data from first entry
# V9.2.0 2016-02-24 # Vladislav Tembekov Update UNIX Extractor to be compliant with latest security tech spec version V4.0
# V9.2.1 2016-04-11 # Vladislav Tembekov Skip netgroup id from passwd file while lists local users
# V9.4.0 2016-11-10 # Vladislav Tembekov Update Global Unix Extractor to provide additional information when dealing with LDAP/NIS environments for consumption by UAT
# V9.4.1 2016-12-22 # Pavel Pisakov      Fixed syntax errors 
# V9.4.2 2017-01-10 # Vladislav Tembekov AIX fix user state and lastlogon date
# V9.4.3 2017-02-09 # Balagopal R Kalluri  implemented restriction for "-uat" flag, which is not possible to use among with "-centrify" and "vintela" switches.
# V9.4.4 2017-02-13 # Balagopal R Kalluri  Fixed non-privilege IDs are extract as privilege ID and User state for VIO server issue .
# V9.4.5 2017-06-14 # Balagopal R Kalluri  Implemented code for LDAP support TLS certificate R000-895(003952fiR) .
# V9.4.6 2017-11-29 # Balagopal R Kalluri  Fixed Accounts incorrectly reported as Enabled on VIO issue(004216ilP).
# V9.4.7 2018-02-19 # Balagopal R Kalluri  Fixed v9.4.6 causing for server hang due to recursive loop(004839zkP).
# V9.4.8 2018-03-16 # Balagopal R Kalluri  Done fixes required for R000-891 requirement
# V9.4.9 2018-07-30 # Balagopal R Kalluri  Fixed Alias issue (004988gvP) and check sum issue(005023dnP) .
# V9.5.0 2018-08-06 # Balagopal R Kalluri  Implemented auto-detection of vintela(R000-684).
# V9.5.1 2018-08-02 # Balagopal R Kalluri  Fixed TLS issue(004981fjP and 005106omP)
# V9.5.2 2018-09-09 # Balagopal R Kalluri  R000-683,R000-685 - Implemented auto-detection of NIS and Centrify
# V9.5.3 2019-05-06 # Balagopal R Kalluri  005390shP - fixed the issue to auto detect nisplus
# V9.5.4 2019-06-24 # Balagopal R Kalluri  005459opP,005447heP,005257foP - Privileges not extracted in mef3 file for privilege users.
# V9.5.5 2019-05-26 # Balagopal R Kalluri  Same version for all scripts.
# V9.5.6 2019-11-26 # Balagopal R Kalluri  Updated the privilege definitions of ExtractorTool as per Policy Tech spec(004877lpQ)
# V9.5.7 2019-11-29 # Balagopal R Kalluri  Changed Last logon date format to YYYYMMDD and Added Last Expiry date field in to MEF3 file
# V9.5.8 2020-02-27 # Balagopal R Kalluri  R001-168:Added last password change attribute and mef3x switch with ON_ON,ON_OFF,OFF_OFF values.
# V9.5.9 2020-03-17 # Balagopal R Kalluri  R001-168:Added reliability check for lastlogon date and last password change date.
# V9.6.0 2020-07-30 # Balagopal R Kalluri  006100gxP,005890exP: Fixed Centrify auto detection issue
# V9.6.1 2020-08-18 # Balagopal R Kalluri  R001-154: Added unix extractor to support the  feature to report NIS+ group for local IDs 
# V9.6.2 2020-08-18 # Balagopal R Kalluri  Same version for all scripts.
# V9.6.3 2020-12-18 # Balagopal R Kalluri  R001-226: UNIX Extractors make LDAP/<group>, NIS/<group> denotation (aka UAT mode) the default MEF3 behavior.
# V9.6.4 2020-12-24 # Balagopal R Kalluri  006261zzP:Modified the extractor to report enable when NP set in /etc/shadow file
# V9.6.5 2020-12-27 # Balagopal R Kalluri  Same version for all scripts.
# V9.7.0 2020-03-08 # Chethan R            R001-134:Enhance UNIX extractor to handle Red Hat Linux Domain DAC, RBAC with ID Manager or ipa.
# V9.8.0 2020-03-18 # Balagopal R Kalluri  Same version for all scripts.
# V10.0.0 2021-06-15 # Balagopal R Kalluri R12-Default customer name changed from IBM  to Kyndryl and ibmOnly parameter changed to kyndrylOnly parameter.
# V10.1.0 2021-10-13 # Balagopal R Kalluri Removed code for tru64 Platform as its discontinued.
# V10.2.0 2022-01-20 # Balagopal R Kalluri #331 Fixed issue with kyndrylOnly switch listing all IDs.
# V10.2.1 2022-07-14 # Balagopal R Kalluri #587 Fixed extractor to fetch only kyndryl IDs when -I switch passed.
# V10.3.0 2022-07-14 # Balagopal R Kalluri Same version for all scripts.
# V10.4.0 2023-05-17 # Balagopal R Kalluri #963 Fixed LDAP user state issue.
# V10.5.0 2023-05-17 # Balagopal R Kalluri #109 report platform field as Linux-PHOTON for PHOTON OS systems.
# V10.6.0 2023-05-17 # Balagopal R Kalluri #1002 Added extractor to support LDAP server without passing server details.
# V10.6.1 2023-08-01 # Balagopal R Kalluri #1109 Fixed photon reporting issue.
# V10.7.0 2023-12-13 # Balagopal R Kalluri #1193 Fixed nslookup hanging issues.
# V10.7.1 2024-03-26 # Balagopal R Kalluri Added return code 8, it reports when user runs the extractor without root level access.
# V10.8.0 2024-03-26 # Balagopal R Kalluri Added more warning messagse when the user ran witout root level access.
# V10.9.0 2024-07-08 # Balagopal R Kalluri #1380 Fixed shell check lint errors for CE Certification.
# V11.0.0 2024-10-23 # Balagopal R Kalluri #1510 Extractor to run with ON_ON by default.
# V11.0.1 2024-10-23 # Balagopal R Kalluri #1539 Added field in signature line to identify whether MEF3 generated with sudo access or not.
# V11.1.0 2024-10-23 # Balagopal R Kalluri #132 Added new parameter to extract except customerIDs.	
# V11.2.0 2025-04-30 # Balagopal R Kalluri Same version for all scripts.
# V11.3.0 2025-08-12 # Balagopal R Kalluri #1704 Labelling Format for KyndrylOnly parameter updated.
#===============================================================================

VERSION="V11.3.0"

################################################################################
SIG=""
HOST=""
FQDN=0
DEBUG=0
NOTROOT=0
EXIT_CODE=0
OUTPUTFILE=""
KNOWPAR=""
UNKNOWPAR=""
AIXDEFSTATE="Enabled"
Dormant="ON_ON"
MEF3X=0
#################################################################################
function logMsg
{
  level=$1
  msg=$2
  echo "[$level] $msg"
}

function logDiv
{
  logMsg "INFO" "==========================================="
}

function logAbort
{
  logMsg "ERROR" "$1"
  EXIT_CODE=9
  logFooter
  exit 9
}

function logDebug
{
  if [[ $DEBUG -ne 0 ]]; then
    logMsg "DEBUG" "$1"
  fi
}

function logInfo
{
  logMsg "INFO" "$1"
}

function logHeader
{
  STARTTIME=$(date +%Y-%m-%d-%H.%M.%S)
  
  logInfo "UID EXTRACTOR EXECUTION - Started"
  logInfo "START TIME: $STARTTIME"
  logDiv
  logInfo "IAM Global OS Extractor"
  logDiv
}

function logPostHeader
{
  if [[ $KNOWPAR != "" ]]; then
    logInfo "Following parameters will be processed: $KNOWPAR"
  fi
  
  if [[ $UNKNOWPAR != "" ]]; then
    logMsg "WARN" "Following unknown parameters will not be processed: $UNKNOWPAR"
  fi
  
  logDiv
  logInfo "SCRIPT NAME: ${1#./}"
  logInfo "SCRIPT VERSION: $VERSION"
  logInfo "CKSUM: $CKSUM"
  logInfo "OS CAPTION: $(uname)"
  if [[ $OS = "AIX" ]]; then
    logInfo "OS VERSION: $(uname -v).$(uname -r)"
  else
    logInfo "OS VERSION: $(uname -r)"
  fi
  logInfo "HOSTNAME: $HOSTNAME"
  logInfo "CUSTOMER: $CUSTOMER"
  logInfo "OUTPUTFILE: $OUTPUTFILE"
  logInfo "SIGNATURE: $SIG"
  logInfo "mef3x: $Dormant"

  logInfo "IS_AG: no"
  logInfo "IS_ALLUSERIDS: yes"
  
  if [ $FQDN -ne 0 ]; then
    logInfo "IS_FQDN: yes"
  else
    logInfo "IS_FQDN: no"
  fi

  if [ $DEBUG -ne 0 ]; then
    logInfo "IS_DEBUG: yes"
  else
    logInfo "IS_DEBUG: no"
  fi
#TLS
  if [ $TLS -ne 0 ]; then
    logInfo "TLS: yes"
  else
    logInfo "TLS: no"
  fi  

  logDiv
  
  logInfo "EXTRACTION PROCESS - Started"
  if [ $DEBUG -ne 0 ]; then
    logDiv
  fi
}

function logFooter
{
  if [ $DEBUG -ne 0 ]; then
    logDiv
  fi
  
  logInfo "EXTRACTION PROCESS - Finished"
  logDiv
  if [[ $EXIT_CODE -lt 2 ]]; then
    logInfo "The mef3 data has been collected"
  else
    logInfo "The mef3 data has not been collected"
    rm -f $OUTPUTFILE
  fi
  logDiv
  logInfo "Time elapsed: $(echo $SECONDS)"
  logDiv
  
  if [[ $EXIT_CODE -lt 2 ]]; then
	  if [[ $NOTROOT -eq 1 ]]; then
		logInfo "The report has been finished with success"
		logInfo "General return code: 8"
		logInfo "Return code 8 means Script not executed with root privileges,Running the script less than this level of access does not guarantee the ability to extract all required user data.So we recommend to run the script with root level access to get all user ID data with accuracy"
	
	  else 
		logInfo "The report has been finished with success" 
		logInfo "General return code: $EXIT_CODE"
	  fi
  else
    logInfo "The report has been finished without success" 
	logInfo "General return code: $EXIT_CODE"
  fi
    
  logInfo "UID EXTRACTOR EXECUTION - Finished"
 
}
#####################################################################################

### Start of AssocArr lib
# Associative array routines
# @(#) AssocArr 1.5
# 1993-06-25 john h. dubois iii (john@armory.com)
# 1993-07-09 Changed syntax of AStore so that these functions can be used
#            for set operations.
# 1994-06-26 Added append capability to AStore
# 1995-10-19 Keep track of highest element used, and pass it to Ind
# 2000-11-26 Added m_AStore and APrintAll
# 2001-06-24 Avoid some evals by using (()) to dereference integer var names.
# 2001-07-14 Fixed bug in AStore
# 2002-01-30 Fixed bugs in AGet and ADelete
# 2002-02-03 Added ANElem
# 2002-11-14 ksh93 compatibility fix
# 2003-07-27 1.5 Added AInit
#
# These routines use two shell arrays and an integer variable for each
# associative array:
# For associative array "foo", the values are stored in foo_val[1..255] and the
# indices (free form character strings) are stored in foo_ind[].
# The free pointer is stored in foo_free.  It has the value of the lowest index
# that may be free. The end pointer is stored in foo_end; it has the value of
# the highest index used.
# Only 255 values can be stored.
# Arrays must have names that are valid shell variable names.
# A null array index is not allowed.

# Usage: Ind <arrayname> <value> [[<nsearch>] <firstelem>]
# Returns the index of the first element of <arrayname> that has value <value>.
# Note, <arrayname> is a full ksh array name, not an associate array name as
# used by this library.
# Returns 0 if it is none found.
# Works only for indexes 1..255.
# If <nsearch> is given, the first <nsearch> elements of the array are
# searched, with only nonempty elements counted.
# If not, the first n nonempty elements are searched,
# where n is the number of elements in the array.
# If a fourth argument (<firstelem>) is given, it is the index to start with;
# the search continues for <nsearch> elements.
# Element zero should not be set.
function Ind
{
  declare -i NElem ElemNum=${5:-1} NumNonNull=0 num_set
  declare Arr=$1 Val=$2 Res=$3 ElemVal

  eval num_set=\${#"${Arr}"[*]}
    if [[ $# -eq 4 ]]; then
      NElem=$4
      # No point in searching more elements than are set
      (( NElem > num_set )) && NElem=num_set
    else
    NElem=$num_set
  fi
  while (( ElemNum <= 99999 && NumNonNull < NElem )); do
  eval ElemVal=\"\${"${Arr}"[ElemNum]}\"
    shopt -s nocasematch
    if [[ $Val = "$ElemVal" ]]; then
      eval "${Res}"=$ElemNum
    return 1
  fi
  [[ -n $ElemVal ]] && ((NumNonNull+=1))
  ((ElemNum+=1))
  done
  return 0
}

function Ind1
{
  declare -i NElem ElemNum=${5:-1} NumNonNull=0 num_set
  declare Arr=$1 Val=$2 Res=$3 ElemVal
  eval num_set=\${#"${Arr}"[*]}
    if [[ $# -eq 4 ]]; then
      NElem=$4
      # No point in searching more elements than are set
      (( NElem > num_set )) && NElem=num_set
    else
    NElem=$num_set
  fi
  while (( ElemNum <= 99999 && NumNonNull < NElem )); do
    eval ElemVal=\"\${"${Arr}"[ElemNum]}\"
   # shopt -s nocasematch
    if [[ $Val = "$ElemVal" ]]; then
      eval "${Res}"=$ElemNum
    return 1
  fi
  [[ -n $ElemVal ]] && ((NumNonNull+=1))
  ((ElemNum+=1))
  done
  return 0
}

# Usage: AInit <arrayname> <index1> <value1> [<index2> <value2>] ...
# Stores each value in associative array <arrayname> under the associated
# index.  Up to 255 index/value pairs may be given.
# <arrayname> is treated as though it is initially empty.
# Return value is 0 for success, 1 for failure due to full array,
# 2 for failure due to bad index or arrayname, 3 for bad syntax
function AInit
{
  declare Arr=$1
  declare -i Ind

  shift
  # Arr must be a valid ksh variable name
  #[[ $Arr != [[:alpha:]_]*([[:word:]]) ]] && return 2
  (( $# % 2 != 0 )) && return 3

  Ind=1
  while (( $# > 0 && Ind < 100000 )); do
    Index=$1
    Val=$2
  [[ -z $Index ]] && return 2
  eval ${Arr}_ind[Ind]=\$Index ${Arr}_val[Ind]=\$Val
  ((Ind+=1))
  shift 2
  done
  (( ${Arr}_free=Ind ))
  (( ${Arr}_end=Ind-1 ))
  (( $# > 0 )) && return 1
  return 0
}

# Usage: AStore <arrayname> <index> [<value> [<append>]]
# Stores value <value> in associative array <arrayname> with index <index>
# If no <value> is given, nothing is stored in the value array.
# This can be used for set operations.
# If a 4th argument is given, the value is appended to the current value
# stored for the index (if any).
# Return value is 0 for success, 1 for failure due to full array,
# 2 for failure due to bad index or arrayname, 3 for bad syntax
function AStore
{
  declare Arr=$1 Index=$2 Val=$3
  declare -i Used Free=0 NumArgs=$# arrEnd
  NumInd=0
  [[ -z $Index ]] && return 2
  # Arr must be a valid ksh variable name
  #    [[ $Arr != [[:alpha:]_]*([[:word:]]) ]] && return 2

  if eval [[ -z \"\$${Arr}_free\" ]]; then      # New array
    # Start free pointer at 1 - we do not use element 0
    Free=1
    arrEnd=0
    NumInd=0
  else  # Extant array
    (( arrEnd=${Arr}_end ))
    Ind ${Arr}_ind "$Index" NumInd $arrEnd
  fi
  # If the supplied <index> is not in use yet, we must find a slot for it
  # and store the index in that slot.
  if [[ NumInd -eq 0 ]]; then
    if [[ Free -eq 0 ]]; then # If this is not a newly created array...
      eval Used=\${#"${Arr}"_ind[*]}
      if [[ Used -eq 99999 ]]; then
        logMsg "ERROR" "Adding $Val to Array:$Arr is FULL: $Used of 99999"
        EXIT_CODE=1
        return 1 # No space available
      fi
      (( Free=${Arr}_free ))
    fi
    # Find an unused element
    while eval [[ -n \"\${"${Arr}"_ind[Free]}\" ]]; do
      ((Free+=1))
      (( Free > 99999 )) && Free=1  # wrap
    done
    NumInd=Free
            ((Free+=1))
    (( NumInd > arrEnd )) && arrEnd=NumInd
    (( ${Arr}_free=Free ))
    (( ${Arr}_end=$arrEnd ))
    # Store index
    eval ${Arr}_ind[NumInd]=\$Index
  fi
  case $NumArgs in
    2) return 0;;     # Set no value
    3) eval ${Arr}_val[NumInd]=\$Val;;  # Store value
    4)  # Append value
	  eval "${Arr}"_val[NumInd]=\"\${"${Arr}"_val[NumInd]}\$Val\";;      
    *) return 3;;
  esac
  return 0
}

function AStore1
{
  declare Arr=$1 Index=$2 Val=$3
  declare -i Used Free=0 NumArgs=$# arrEnd
  NumInd=0
  [[ -z $Index ]] && return 2
  # Arr must be a valid ksh variable name
  #    [[ $Arr != [[:alpha:]_]*([[:word:]]) ]] && return 2

  if eval [[ -z \"\$${Arr}_free\" ]]; then      # New array
    # Start free pointer at 1 - we do not use element 0
    Free=1
    arrEnd=0
    NumInd=0
  else  # Extant array
    (( arrEnd=${Arr}_end ))
    Ind ${Arr}_ind "$Index" NumInd $arrEnd
  fi
  # If the supplied <index> is not in use yet, we must find a slot for it
  # and store the index in that slot.
  if [[ NumInd -eq 0 ]]; then
    if [[ Free -eq 0 ]]; then # If this is not a newly created array...
      eval Used=\${#"${Arr}"_ind[*]}
      if [[ Used -eq 99999 ]]; then
        logMsg "ERROR" "Adding $Val to Array:$Arr is FULL: $Used of 99999"
        EXIT_CODE=1
        return 1 # No space available
      fi
      (( Free=${Arr}_free ))
    fi
    # Find an unused element
    while eval [[ -n \"\${"${Arr}"_ind[Free]}\" ]]; do
      ((Free+=1))
      (( Free > 99999 )) && Free=1  # wrap
    done
    NumInd=Free
            ((Free+=1))
    (( NumInd > arrEnd )) && arrEnd=NumInd
    (( ${Arr}_free=Free ))
    (( ${Arr}_end=$arrEnd ))
    # Store index
    eval ${Arr}_ind[NumInd]=\$Index
  fi
  case $NumArgs in
    2) return 0;;     # Set no value
    3) eval ${Arr}_val[NumInd]=\$Val;;  # Store value
    4)  # Append value
      eval "${Arr}"_val[NumInd]=\"\${"${Arr}"_val[NumInd]}\$Val\";;
    *) return 3;;
  esac
  return 0
}


# Usage: m_AStore <arrayname> <append> <index> <value> [<index> <value> ...]
# Stores multiple values in associative array <arrayname>.
# For each <index>,<value> pair, <value> is stored under the index <index>
# in associate array <arrayname>.
# If <append> is non-null, values are appended to current values
# stored for indexes (if any).
# See AStore for details.
# On success, 0 is returned.
# If an error occurs, array insertion stops and the error returned by
# AStore is returned.
function m_AStore
{
  declare Arr=$1 Append=$2

  shift 2
  while (( $# > 0 )); do
    AStore "$Arr" "$1" "$2" $Append || return $?
    shift 2
  done
  return 0
}

# Usage: AGet <arrayname> <index> <var>
# Finds the value indexed by <index> in associative array <arrayname>.
# If there is no such array or index, 0 is returned and <var> is not touched.
# Otherwise, <var> (if given) is set to the indexed value and the numeric index
# for <index> in the arrays is returned.
function AGet
{
  declare Arr=$1 Index=$2 Var=$3 End
  NumInd=0
  # Can't use implicit integer referencing on ${Arr}_end here because it may
  # not be set yet.
  eval End=\$${Arr}_end
  [[ -z $End ]] && return 0

  Ind ${Arr}_ind "$Index" NumInd $End
  if (( NumInd > 0 )) && [[ -n $Var ]]; then
    eval "$Var"=\"\${"${Arr}"_val[NumInd]}\"
  fi
  return $NumInd
}

function AGet1
{
  declare Arr=$1 Index=$2 Var=$3 End
  NumInd=0
  # Can't use implicit integer referencing on ${Arr}_end here because it may
  # not be set yet.
  eval End=\$${Arr}_end
  [[ -z $End ]] && return 0

  Ind ${Arr}_ind "$Index" NumInd $End
  if (( NumInd > 0 )) && [[ -n $Var ]]; then
    eval "$Var"=\"\${"${Arr}"_val[NumInd]}\"
  fi
  return $NumInd
}

# Usage: AUnset <arrayname>
# Removes all elements from associative array <arrayname>
function AUnset
{
  declare Arr=$1
  eval unset ${Arr}_ind ${Arr}_val ${Arr}_free
}

# Usage: ADelete <arrayname> <index>
# Removes index <index> from associative array <arrayname>
# Returns 0 on success, 1 if <index> was not an index of <arrayname>
function ADelete
{
  declare Arr=$1 Index=$2 End
  NumInd=0
  # Can't use implicit integer referencing on ${Arr}_end here because it may
  # not be set yet.
  eval End=\$${Arr}_end

  Ind ${Arr}_ind "$Index" NumInd $End
  if (( NumInd > 0 )); then
    eval unset ${Arr}_ind[NumInd] ${Arr}_val[NumInd]
    (( NumInd < ${Arr}_free )) && (( ${Arr}_free=NumInd ))
    return 0
  else
    return 1
  fi
}

# Usage: AGetAll <arrayname> <varname>
# All of the indices of array <arrayname> are stored in shell array <varname>
# with indices starting with 0.
# The total number of indices is returned.
function AGetAll
{
  declare -i NElem ElemNum=1 NumNonNull=0
  declare Arr=$1 VarName=$2 ElemVal
  eval NElem=\${#"${Arr}"_ind[*]}
    while (( ElemNum <= 99999 && NumNonNull < NElem )); do
      eval ElemVal=\"\${"${Arr}"_ind[ElemNum]}\"
      if [[ -n $ElemVal ]]; then
        eval ${VarName[NumNonNull]}=\$ElemVal
        ((NumNonNull+=1))
      fi
      ((ElemNum+=1))
    done
  return $NumNonNull
}
# Usage: APrintAll <arrayname> [<sep>]
# For each value stored in <arrayname>, a line containing the index and value
# is printed in the form: index<sep>value
# If <sep> is not passed, '=' is used.
# The total number of indices is returned.
function APrintAll
{
  declare -i NElem ElemNum=1 NumNonNull=0
  declare Arr=$1 Sep=$2 ElemVal ElemInd

  (( $# < 2 )) && Sep="="
  eval NElem=\${#"${Arr}"_ind[*]}  
    while (( ElemNum <= 99999 && NumNonNull < NElem )); do
      eval ElemInd=\"\${"${Arr}"_ind[ElemNum]}\" \
      ElemVal=\"\${"${Arr}"_val[ElemNum]}\"
      if [[ -n $ElemInd ]]; then
        echo "$ElemInd$Sep$ElemVal"
        ((NumNonNull+=1))
      fi
      ((ElemNum+=1))
    done
  return $NumNonNull
}

# Usage: ANElem <arrayname>
# The total number of indices in <arrayname> is returned.
function ANElem
{
  eval return \${#"${1}"_ind[*]}
}

# Read a defaults file
# Usage: ReadDefaults filename var ...
# Any of the named vars that are listed in the file are set globally
function ReadDefaults
{
  declare Defaults var file=$1
  shift

  set_Avars Defaults "$file"
  for var in "$@"; do
    AGet Defaults $var $var
  done
}

# set_Avars: store variable assignments in an associative array.
# 1993-12-28 John H. DuBois III (john@armory.com)
# Converts values to forms that won't be messed with by the shell.
# Usage: set_Avars [-c] array-name [filename ...]
# where the lines in filename (or the input) are of the form
# var=value
# value may contain spaces, backslashes, quote characters, etc.;
# they will become part of the value assigned to index var.
# Lines that begin with a # (optionally preceded by whitespace)
# and lines that do not contain a '=' are ignored.
# Variables are stored in associative array array-name.
# If -c is given, an error message is printed & the program is exited
# if an attempt is made to set a value for a parameter that has already
# been set.

function set_Avars
{
  declare Arr store

  if [[ $1 = -c ]]; then
    store=ChkStore
    shift
  else
    store=AStore
  fi
  Arr=$1
  shift
  for file; do
    if [[ ! -r $file ]]; then
      logMsg "WARNING" "$file: Could not open."
      return 1
    fi
  done
  # return exit status of eval
  eval "$(sed "
/^[ 	]*#/d
  /=/!d
  s/'/'\\\\''/g
  s/=/ '/
  s/$/'/
  s/^/$store $Arr /" "$@")"
}

# Usage: ChkStore <arrname> <index> <value>
# Exit if <index> is already set
function ChkStore
{
  declare arrname=$1 index=$2 value=$3

  if AGet $arrname $index; then
    # 0 return means index not found
    AStore $arrname $index "$value"
  else
    logAbort "$index already set.  Exiting."
  fi
}
#################################################################################################################

function trim
{
  trimmed=$1
  trimmed=$(echo "$trimmed" | sed 's/^[ ]*//;s/[ ]*$//')
  echo "$trimmed"
}  

function toLower
{
  echo $1 | tr "[:upper:]" "[:lower:]"
}

function checkforldappasswd
{
  NETGROUP=0
  FPASSWDFILE=$PASSWDFILE
  while read line; do
    matched=$(echo $line|grep ^+|wc -l)
    if [[ $matched -gt 0 ]]; then
      NETGROUP=1
      return 0 
    fi
  done < $FPASSWDFILE
  logDebug "checkforldappasswd: $NETGROUP"
  return 1
}

function GetDistrName
{
  DISTR="unknown"
  if [[ $USEROSNAME -eq 0 && $OS = "Linux" ]]; then
    if [ -f /etc/SuSE-release ]; then
      DISTR="suse"
    elif [ -f /etc/debian_version ]; then
      DISTR="debian"
    elif [ -f /etc/redhat-release ]; then
      DISTR="redhat"
    fi
    fi
  echo $DISTR
}
  
function GetDistrVer
{
  DISTR=$1
  VER="unknown"
  if [[ $DISTR = "redhat" ]]; then
	which lsb_release >/dev/null 2>&1
    if [ $? -eq 0 ]; then

        VER=$(lsb_release -s -r | cut -d '.' -f 1)
    fi
#new change
	matched=$(echo $VER | grep -i "no lsb" | wc -l)
	if [[ $matched -ne 1 ]]; then
		if [[ $VER == "" ]];then
			VER=$(cat /etc/redhat-release | sed -e 's#[^0-9.]##g' | cut -d "." -f1)
		fi
		elif [[ $DISTR = "debian" ]]; then
			VER=$(cat /etc/debian_version)
		elif [[ $DISTR = "suse" ]]; then
			VER=$(cat /etc/SuSE-release | grep 'VERSION' | sed  -e 's#[^0-9]##g')
		fi
		echo $VER
	else
		echo ""
	fi
  
}


function is_priv_group
{
  declare groupname=$1
  declare gid=$2
  declare matched
  matched=$(echo "$groupname"|egrep "$PRIVGROUPS"|wc -l)
  
  matched=$(trim "$matched")
  
  if [[ $matched -ne 1 ]]; then
  if [[ $OS = "Linux" && $DISTRVER != "" ]]; then
      if [[ $gid -le 99 ]]; then
        matched=1
      elif [[ $DISTRNAME = "suse" ]]; then
        if [[ $DISTRVER -ge 9 && $gid -ge 101 && $gid -le 499 ]]; then 
          matched=1
        fi
      elif [[ $DISTRNAME = "debian" ]]; then 
        if [[ ($DISTRVER -eq 5 && $gid -ge 101 && $gid -le 199) ]]; then
          matched=1
        fi
        if [[ ($DISTRVER -ge 6 && $gid -ge 101 && $gid -le 999) ]]; then
          matched=1
        fi
      elif [[ $DISTRNAME = "redhat" ]]; then 
	if [[ $gid = "" ]];then
         logDebug "$gid is empty so groupname is not privileged"
         return 1
        fi
	
        if [[ ($DISTRVER -ge 5 && $gid -ge 101 && $gid -le 499) ]]; then
          matched=1
        fi
        if [[ ($DISTRVER -ge 7 && $gid -ge 500 && $gid -le 999) ]]; then
          matched=1
        fi
      fi
    fi
  fi  
  echo "$matched"
  return 0
}

function get_group_info
{
  logDebug "get_group_info: start"
  
  while IFS=: read -r _group _gpasswd _gid _members
  do
    logDebug "get_group_info: $_group:$_gpasswd:$_gid:$_members"
    if [[ $_group = "" ]]; then
      logDebug "get_group_info: Skip empty groupname"
      continue
    fi
    matched=$(echo $_group|grep ^+|wc -l)
    if [[ $matched -eq 1 ]]; then
      logDebug "get_group_info: Skip group $_group"
      continue
    fi
    
    testvar=""
    AGet local_groups "${_group}" testvar
    if [[ $testvar != "" ]]; then    
      logMsg "WARN" "Group \"$_group\" already exists in $GROUPFILE file. Output file can be incorrect."
      EXIT_CODE=1
    fi
    AStore local_groups ${_group} "1"
    matched=$(is_priv_group "$_group" "$_gid")
    if [[ $matched -eq 1 ]]; then
      logDebug "get_group_info: $_group is privileged"
      AStore privgroups ${_group} "1"
    fi
  done < $GROUPFILE
  IFS=" "
}  

function passwd_ids
{
  logDebug "passwd_ids: start"
  while IFS=: read -r _userid _passwd _uid _gid _gecos _home _shell
  do
    logDebug "passwd_ids: $_userid:$_passwd:$_uid:$_gid:$_gecos:$_home:$_shell"
    if [[ $_userid = "" ]]; then
      logDebug "passwd_ids: Skip empty username"
      continue
    fi
    matched=$(echo $_userid|grep ^+|wc -l)
    if [[ $matched -eq 1 ]]; then
      logDebug "passwd_ids: Skip netgroup $_userid"
      continue
    fi
    testvar=""
    AGet local_users "${_userid}" testvar
    if [[ $testvar != "" ]]; then
      logMsg "WARN" "User \"$_userid\" already exists in $PASSWDFILE file. Output file can be incorrect."
      EXIT_CODE=1
      continue
      fi
    AStore local_users ${_userid} "1"
  done < $PASSWDFILE
  IFS=" "
}  

function LoadPrivfile
{
  declare privfile=$1
  
  if [[ $privfile != "" ]]; then
    logDebug "Reading PRIVFILE: $privfile"
    if [ -r $privfile ]; then
      while read line; do
        if echo "$line" | grep -i "=" > /dev/null; then
          role=$(echo $line|cut -d"=" -f1)
          role_name=$(echo $line|cut -d"=" -f2 | tr -d '\"')
          if [[ $role != "" && $role_name != "" ]]; then
            logDebug "Add role $role, role name $role_name"
            AStore ROLE ${role} "$role_name"
          fi
          role=""
          role_name=""
        else  
          matched=$(echo $line|egrep -v '^\s*$'|wc -l)
          if [[ $matched -gt 0 ]]; then
            logDebug "Found Additional Priv group: $line"
            if [[ $PRIVGROUPS != "" ]]; then
              PRIVGROUPS=$PRIVGROUPS"|"
            fi
            PRIVGROUPS=$PRIVGROUPS"^"$line'$'
          fi
        fi  
      done < $privfile
    else
      logMsg "WARNING" "unable to read PRIVFILE:$privfile."
      EXIT_CODE=1
    fi
  fi
}

function StoreUserData
{
  AStore userPassword ${userid} "$passwd"
  AStore userPrimaryGroup ${userid} "$gid"
  AStore userGECOS ${userid} "$gecos"
  AStore userHome ${userid} "$home"
  AStore userShell ${userid} "$shell"  
}

function CleanUserData
{
  AUnset PasswdUser
  AUnset userPassword
  AUnset userprimaryGroup
  AUnset userGECOS
  AUnset userHome
  AUnset userShell
}

function Parse_User
{
    KRB5AUTH=""
    SSSD_CONFIG="/etc/sssd/sssd.conf"
    KRBCheck=$(grep "auth_provider = krb5" $SSSD_CONFIG |wc -l)
    if [[ $KRBCheck -gt 0 ]]; then
            logDebug "parsepw:KRB5 authentication in use"
                KRB5AUTH="yes"
    fi


  ### extracting primary groups from passwd file
  if [[ $PROCESSNIS -eq 1 ]]; then

    cat $PASSWDFILE >> $NISPASSWD
    FPASSWDFILE=$NISPASSWD
  fi

  if [[ $PROCESSLDAP -eq 1 ]]; then
    FPASSWDFILE=$LDAPPASSWD
  fi	
    
  if [[ $PROCESSNIS -eq 0 && $PROCESSLDAP -eq 0 ]]; then
    FPASSWDFILE=$PASSWDFILE
  fi

  if [[ $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0 ]]; then
    if [[ $IS_ADMIN_ENT_ACC -eq 1 && ($OS = "Linux" || $OS = "SunOS") ]]; then
      getent passwd > $ADMENTPASSWD
      FPASSWDFILE=$ADMENTPASSWD
    fi
    
    if [[ $IS_ADMIN_ENT_ACC -eq 2 ]]; then
      if [[ $VPREFIX = "" ]]; then
        /opt/quest/bin/vastool list users-allowed > $ADMENTPASSWD
      else
        /opt/quest/bin/vastool list users-allowed | sed 's/'$VPREFIX'//g' > $ADMENTPASSWD
      fi    
      cat $PASSWDFILE >> $ADMENTPASSWD
      FPASSWDFILE=$ADMENTPASSWD
    fi
    
    if [[ $IS_ADMIN_ENT_ACC -eq 3 ]]; then
      adquery user > $ADMENTPASSWD
      cat $PASSWDFILE >> $ADMENTPASSWD
      FPASSWDFILE=$ADMENTPASSWD
    fi
  fi

  logDebug "Reading PASSWDFILE: $FPASSWDFILE"

  while IFS=: read -r userid passwd uid gid gecos home shell
    do
	declare domainname_user=""
	logDebug "Before excluding domain name from user:$userid"
	if [[ $(echo "$userid" | awk -F'\' '{print NF}') == 2 ]]; then
	domainname_user=$(echo "$userid" | awk -F'\' '{print $1}')
	userid=$(echo "$userid" | awk -F'\' '{print $2}')
	logDebug "After excluding domain name from user:\"$userid\" and domain: \"$domainname_user\""
	fi	

	if [[ "$domainname_user" != "" ]]; then
	AStore Domain_user $userid $domainname_user
	AGet Domain_user $userid Domain
	logDebug "Domain name:$Domain,User name:$userid"
	fi

      logDebug "Parse_User read userid=$userid passwd=$passwd uid=$uid gid=$gid gecos=$gecos home=$home shell=$shell"
    
      if [[ $userid = "" ]]; then
        logDebug "Skip empty username"
        continue
      fi

      testvar=""
      AGet PasswdUser ${userid} testvar
      if [[ $testvar != "" ]]; then
        logDebug "Skip duplicate userid $userid"
        continue
      fi

      if [[ $PROCESSNIS -eq 1 && $NISPLUS -eq 1 ]]; then
        groups $userid >/dev/null 2>&1
        if [ $? -ne 0 ]; then
          logDebug "Skip NIS+ user"
          continue
        fi
      fi
        
      if [[ $PROCESSNIS -eq 0 && $PROCESSLDAP -eq 0 ]]; then
        matched=$(echo $userid|grep ^+|wc -l)
        if [[ $matched -gt 0 ]]; then
          if [[ $LDAP -eq 0 ]]; then
            logInfo "User $userid is excluded from output file use, -L option to lookup LDAP NetGrp IDs"
            continue
          fi
          matched=$(echo $userid|grep ^+@|wc -l)
          if [[ $matched -gt 0 ]]; then
            logDebug "Parse_User: netgroup found $userid"
            Parse_LDAP_Netgrp $userid
            continue
          else
            userid=$(echo $userid | tr -d '+')

          testvar=""
          AGet PasswdUser "${userid}" testvar
          if [[ $testvar = "" ]]; then
            logDebug "Parse_User: netuser found $userid"
            Parse_LDAP_Netuser $userid
          else
            logDebug "User $userid Already exist"
          fi
        fi
      fi
    fi
    AStore PasswdUser ${userid} "$uid"
    testvar=""
    AGet primaryGroupUsers ${gid} testvar
    if  [[ $testvar = "" ]]; then
      AStore primaryGroupUsers ${gid} "$userid"
    else
      AStore primaryGroupUsers ${gid} ",$userid" append
    fi
    
    matched=$(echo $userid|egrep $PRIVUSERS|wc -l)
    if [[ $matched -gt 0 ]]; then
      logDebug "Parse_User: found privileged user $userid"
      AStore privUser ${userid} "$userid"
    fi
    
  StoreUserData
  done < $FPASSWDFILE
  rm -f $ADMENTPASSWD
}

function Parse_Grp
{
  if [[ $PROCESSNIS -eq 1 ]]; then
    cat $GROUPFILE >> $NISGROUP
    FGROUPFILE=$NISGROUP
  fi

  if [[ $PROCESSLDAP -eq 1 ]]; then
    FGROUPFILE=$LDAPGROUP
  fi
        
  if [[ $PROCESSNIS -eq 0 && $PROCESSLDAP -eq 0 ]]; then
    FGROUPFILE=$GROUPFILE
  fi

  if [[ $NIS -eq 0 && $LDAP -eq 0  && $NOAUTOLDAP -eq 0 ]]; then
    if [[ $IS_ADMIN_ENT_ACC -eq 1 && ($OS = "Linux" || $OS = "SunOS") ]]; then
      getent group > $ADMENTGROUP
      FGROUPFILE=$ADMENTGROUP
    fi
    if [[ $IS_ADMIN_ENT_ACC -eq 2 ]]; then
      if [[ $VPREFIX = "" ]]; then
        /opt/quest/bin/vastool list -a groups > $ADMENTGROUP
      else
        /opt/quest/bin/vastool list -a groups | sed 's/'$VPREFIX'//g'> $ADMENTGROUP
      fi  
      cat $GROUPFILE >> $ADMENTGROUP
      FGROUPFILE=$ADMENTGROUP
    fi
    
    if [[ $IS_ADMIN_ENT_ACC -eq 3 ]]; then
      adquery group > $ADMENTGROUP
      cat $GROUPFILE >> $ADMENTGROUP
      FGROUPFILE=$ADMENTGROUP
    fi
  fi

  logDebug "Reading GROUPFILE: $FGROUPFILE"

  while IFS=: read -r group gpasswd gid members
    do
     
      declare domainname_group="" 
      logDebug "Parse_Grp read group=$group gpasswd=$gpasswd gid=$gid members=$members"
      if [[ $group = "" ]]; then
        logDebug "Skip empty groupname"
        continue
      fi
      if [[ $(echo "$group" | awk -F'\' '{print NF}') == 2 ]]; then
	domainname_group=$(echo "$group" | awk -F'\' '{print $1}')
	group=$(echo "$group" | awk -F'\' '{print $2}')
	logDebug "After excluding domain name from group:\"$group\",domain group: \"$domainname_group\""
      fi

      if [[ "$domainname_group" != "" ]]; then
	AStore Domain_group "$group" $domainname_group
        AGet Domain_group "$group" Domain
        logDebug "Domain name:$Domain,group:$group"
      fi  

      AStore groupGIDName ${gid} "$group"
      allusers=""
      AGet primaryGroupUsers ${gid} allusers

      logDebug "Reading in users with $group as a primary group"
      logDebug "grpgid: $gid"
      logDebug "$group pgusers: $allusers"

      if [[ $allusers != "" ]]; then
        if [[ $members != "" ]]; then
          allusers=$allusers",$members"
        else
          allusers=$allusers
        fi
      else
        allusers="$members"
      fi

      logDebug "Reading in $group memberlist from group file"
      logDebug "$group allusers: $allusers"
      logDebug "Uniquifying list"

      AUnset UniqueUsers
      uniqueusers=""
      IFS=,;for nextuser in ${allusers}
        do
          testvar=""
          AGet UniqueUsers $nextuser testvar
          if  [[ $? -eq 0 && $testvar = "" ]]; then
            AStore UniqueUsers  $nextuser "$nextuser"
            if [[ $uniqueusers != "" ]]; then
              uniqueusers=$uniqueusers",$nextuser"
            else
              uniqueusers="$nextuser"
            fi
          else
            continue
          fi
      done
  IFS=" "
  logDebug "Uniqufied allusers:$group $uniqueusers"
  ## storing users ist whihc includes primary groups
        
  testvar=""
  AGet ALLGroupUsers "${group}" testvar
  if [[ $testvar != "" ]]; then
    testvar="$testvar,$uniqueusers"
  else
    testvar="$uniqueusers"
  fi
  uniqueusers=$testvar
  #echo "group================$group"
  AStore ALLGroupUsers "${group}" "$uniqueusers"

  IFS=,;for nextuser in ${uniqueusers}
    do
      testvar=""
      AGet AllUserGroups ${nextuser} testvar
      if [[ $? -eq 0 && $testvar = "" ]]; then
        logDebug "Parse_Grp: Set group $group to user $nextuser "
        AStore AllUserGroups "$nextuser" "$group"
      else
        logDebug "testvar value:$testvar"
        is_dublicate_checker=0
        for bufgroup in ${testvar}
          do
            if [[ $bufgroup = "$group" ]]; then
              is_dublicate_checker=1
              break
            fi
          done
        if [[ $is_dublicate_checker -eq 0 ]]; then
          AStore AllUserGroups ${nextuser} ",$group" append
          logDebug "Parse_Grp: Append group $group to user $nextuser "
        fi
      fi
    done
  IFS=" "

  matched=$(is_priv_group "$group" "$gid")

  if [[ $matched = "1" ]]; then
    logDebug "Found Priv group: $group:""$members"
    IFS=,;for nextuser in ${uniqueusers}
    do
      testvar=""
      AGet privUserGroups ${nextuser} testvar
      if  [[ $? -eq 0 && $testvar = "" ]]; then
        AStore privUserGroups ${nextuser} "$group"
      else
        is_dublicate_checker=0
        for bufgroup in ${testvar}
        do
          if [[ $bufgroup = "$group" ]]; then
            is_dublicate_checker=1
            break
          fi
        done
        if [[ $is_dublicate_checker -eq 0 ]]; then
          AStore privUserGroups ${nextuser} ",$group" append
        fi
      fi
    done
    IFS=" "
  fi
  done < $FGROUPFILE
  rm -f $ADMENTGROUP
}

function EPOCHtoDate
{
  declare val=$1
  tmp=""
    tmp=$($PERL -e "print scalar(localtime($val))")
    if [[ $tmp != "" ]]; then
      tmp_year=$(echo "$tmp" | awk '{print $5}' | tr -d '\n')
      tmp_month=$(echo "$tmp" | awk '{print $2}' | tr -d '\n')
      tmp_day=$(echo "$tmp" | awk '{print $3}' | tr -d '\n')
      tmp_day_count=${#tmp_day}
      if [[ $tmp_day_count -ne 2 ]]; then
                tmp_day="0$tmp_day"
      fi
      tmp="$tmp_day $tmp_month $tmp_year"	  
      AGet MonthNames "$tmp_month" month_format
      tmp=$tmp_year$month_format$tmp_day
    fi

  echo "$tmp"
}


#args MM DD YY
function formatDate
{
  declare MM=$1
  declare DD=$2
  declare YY=$3
  AGet MonthNames "$MM" MMM

  echo "20$YY$MMM$DD"
}


function parse_shadow
{
  FSPASSWD=$SPASSWD;
  
  logDebug "parse_shadow: start"
    
  if [[ $IS_ADMIN_ENT_ACC -eq 1 && $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0 ]]; then
    if [[ $USERSPASSWD -eq 0 && $OS = "Linux" ]]; then 
      getent shadow > $ADMENTSPASSWD
      FSPASSWD=$ADMENTSPASSWD
      logDebug "parse_shadow: load shadow from LDAP"
    fi
  fi
  
  if [ ! -e $FSPASSWD ]; then
    return;
  fi
  while IFS=":" read -r username crypt_passwd passwd_changed passwd_minage passwd_maxage passwd_war_period passwd_inactivity_period account_expiration reserved
  do
    if [[ $username = "" ]]; then
      continue  
    fi
    AStore PWNeverExpires_Arr ${username} "FALSE"
      
    if [[ $passwd_changed = "0" ]]; then
      AStore PWChg_Arr ${username} ""
    else
      if [[ $passwd_changed = "" ]]; then
        AStore PWNeverExpires_Arr ${username} "TRUE"
        AStore PWExp_Arr ${username} "31 Dec 9999"
      else
      (( tmp=passwd_changed * 86400 ))
        
      if [ -e $PERL ]; then
        tmp=`EPOCHtoDate "$tmp"`
        else
          tmp=""  
        fi  
      AStore PWChg_Arr ${username} "$tmp"
          
      if [[ $passwd_maxage != "" ]]; then
        if [[ $passwd_inactivity_period = "" || $passwd_inactivity_period = "99999" ]]; then
          passwd_inactivity_period="0"
        fi
        (( tmp=passwd_changed+passwd_maxage+passwd_inactivity_period ))
        (( tmp=tmp * 86400 ))
        if [ -e $PERL ]; then
         tmp=`EPOCHtoDate "$tmp"`
        else
          tmp=""
        fi    
       AStore PWExp_Arr ${username} "$tmp"
     else
       AStore PWExp_Arr ${username} ""
     fi
    fi
   fi
    AStore PWMinAge_Arr ${username} "$passwd_minage"
    AStore PWMaxAge_Arr ${username} "$passwd_maxage"
    if [[ $passwd_maxage = "99999" || $passwd_maxage = "" ]]; then
      AStore PWNeverExpires_Arr ${username} "TRUE"
      AStore PWExp_Arr ${username} "31 Dec 9999"
    fi

  done < $FSPASSWD
  IFS=" "
  rm -f $ADMENTSPASSWD
}

function store_aix_data
{
  if [[ $username != "" ]]; then
    AGet PWMaxAge_Arr $username maxage
    AGet PWMaxExpired_Arr $username maxexpired
    if [[ $maxage = "0" || $maxexpired = "-1" ]]; then
      AStore PWNeverExpires_Arr ${username} "TRUE"
      AStore PWExp_Arr ${username} "31 Dec 9999"
      AStore PWMaxAge_Arr ${username} "99999"  
    else
      AStore PWNeverExpires_Arr ${username} "FALSE"
      LastUpdate=""
      AGet PWLastUpdate $username LastUpdate
      if [[ $LastUpdate != "" ]]; then
        ((maxexpired=$maxexpired*7*86400))
        ((maxage=$maxage*86400))
        ((tmp=$LastUpdate+$maxage+$maxexpired))
        if [ -e $PERL ]; then
          tmp=$(EPOCHtoDate $tmp)
        else
          tmp=""
        fi  
        AStore PWExp_Arr ${username} "$tmp"
      else
        AStore PWExp_Arr ${username} ""
      fi  
    fi  
 fi      
}

function parse_spwaix
{
  while read line; do
    
    if echo "$line" | grep -i ".*:$" > /dev/null; then
      username=$(echo "$line" | sed -n 's/\(.*\):/\1/p')
      continue
    fi
    
    if echo "$line" | grep -i "lastupdate = " > /dev/null; then
      passwd_changed=$(echo "$line" | sed -n 's/lastupdate = \([0-9]*\).*/\1/p')
      AStore PWLastUpdate ${username} "$passwd_changed"
      if [ -e $PERL ]; then
        tmp=`EPOCHtoDate "$passwd_changed"`
      else
        tmp=""
      fi  
      AStore PWChg_Arr ${username} "$tmp"
      continue
    fi
    
  done < $SPASSWD

  username=""
  while read line; do
  
    if echo "$line" | grep -i "^\*" > /dev/null; then
      continue  
    fi
    
    if echo "$line" | grep -i ".*:$" > /dev/null; then
      store_aix_data
      username=$(echo "$line" | sed -n 's/\(.*\):/\1/p')
      
      if [[ $username != "default" ]]; then
        AGet PWMinAge_Arr "default" tmp
        AStore PWMinAge_Arr ${username} "$tmp"

        AGet PWMaxAge_Arr "default" tmp
        AStore PWMaxAge_Arr ${username} "$tmp"
        
        AGet PWExp_Arr "default" tmp
        AStore PWExp_Arr ${username} "$tmp"
        
        AGet PWMinLen_Arr "default" tmp
        AStore PWMinLen_Arr ${username} "$tmp"

        AGet PWMaxExpired_Arr "default" tmp
        AStore PWMaxExpired_Arr ${username} "$tmp"

        AGet PWNeverExpires_Arr "default" tmp
        AStore PWNeverExpires_Arr ${username} "$tmp"
      fi
      continue
    fi

    if echo "$line" | grep -i "minage = " > /dev/null; then
      tmp=$(echo "$line" | awk 'match($0, /[0-9]+/) {print substr($0, RSTART, RLENGTH)}')
      ((tmp=$tmp*7))
      AStore PWMinAge_Arr ${username} "$tmp"
      continue
    fi

    if echo "$line" | grep -i "maxage = " > /dev/null; then
      tmp=$(echo "$line" | awk 'match($0, /[0-9]+/) {print substr($0, RSTART, RLENGTH)}')
      ((tmp=$tmp*7))
      AStore PWMaxAge_Arr ${username} "$tmp"
      continue
    fi
      
    if echo "$line" | grep -i "minlen = " > /dev/null; then
      tmp=$(echo "$line" | awk 'match($0, /[0-9]+/) {print substr($0, RSTART, RLENGTH)}')
      AStore PWMinLen_Arr ${username} "$tmp"
      continue
    fi
    
    if echo "$line" | grep -i "maxexpired = " > /dev/null; then
      tmp=$(echo "$line" | awk 'match($0, /[0-9\-]+/) {print substr($0, RSTART, RLENGTH)}')
      AStore PWMaxExpired_Arr ${username} "$tmp"
      continue
    fi
    
  done < $SECUSER
    
  store_aix_data    
}

function parse_LDAP_grp
{
	ldaptmp="/tmp/ldap_group"
  	logDebug "parse_LDAP_grp: reading LDAP group"
	echo "
" > $ldap_tmp
	if [[ $TLS -eq 1 ]]; then
		logDebug "process_TLS_LDAP_groups: "
        	if [[ $LDAPFILE = "" ]]; then
       			logDebug "Command used to get LDAP Group: $LDAPCMD -LLL -h ldaps://$LDAPSVR -b $LDAPBASE -p $LDAPPORT -Z objectClass=posixGroup  cn gidNumber memberUid "
                	DATA=`$LDAPCMD -LLL -h ldaps://$LDAPSVR -b $LDAPBASE -p $LDAPPORT -Z objectClass=posixGroup  cn gidNumber memberUid >> $ldap_tmp`
        	else
			logDebug "Command used to get LDAP Group:$LDAPCMD -LLL -h ldaps://$LDAPSVR -b $LDAPBASEGROUP -p $LDAPPORT $LDAPADDITIONAL -Z objectClass=$LDAPGROUPOBJCLASS cn gidNumber memberUid "
               		DATA=`$LDAPCMD -LLL -h ldaps://$LDAPSVR -b $LDAPBASEGROUP -p $LDAPPORT $LDAPADDITIONAL -Z objectClass=$LDAPGROUPOBJCLASS cn gidNumber memberUid >> $ldap_tmp`
        	fi 

	else
  		if [[ $LDAPFILE = "" && $LDAPNULL -ne 1 ]]; then
    
			logDebug "Command used to get LDAP Group: $LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASE objectClass=posixGroup cn gidNumber memberUid"
    			DATA=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASE objectClass=posixGroup cn gidNumber memberUid >> $ldap_tmp`
		elif [[ $LDAPNULL -eq 1 ]];then 
			DATA=`ldapsearch cn gidNumber member> $ldaptmp`
			logDebug "Command used to get LDAP Group: ldapsearch cn gidNumber member"
			
			EnableUser=0
			IFS=" "
			while read group_line; do
				if echo "$group_line" | egrep -i "^dn: uid" > /dev/null; then
					EnableUser=1
					continue
				fi
				if [[ $EnableUser -eq 1 ]];then
					if echo "$group_line" | grep -i "^cn: .*" > /dev/null; then
						continue
					fi
				fi
				if [[ $EnableUser -eq 1 ]];then
					if echo "$group_line" | egrep -i "^gidNumber: .*" > /dev/null; then
						EnableUser=0
						continue
					fi
				fi
				echo "$group_line" >> "$TMPFILE"
							
			done < $ldaptmp
  		else
   			logDebug "Command used to get LDAP Group:$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASEGROUP $LDAPADDITIONAL objectClass=$LDAPGROUPOBJCLASS cn gidNumber memberUid" 
    			DATA=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASEGROUP $LDAPADDITIONAL objectClass=$LDAPGROUPOBJCLASS cn gidNumber memberUid >> $ldap_tmp`
  		fi  
	fi  
  awk "  /^cn:/ { print }" $ldap_tmp | cut -d" "  -f2 > $ldap_tmp1
  
  group=""
  gid=""
  gmem=""

  IFS=" "  
  while read group; do    
	attr=$(awk " { RS="\n\n" }  /^dn: cn="$group",/ { print }" $ldap_tmp | sed 's/: /:/g')    
    logDebug "parse_LDAP_grp->read attr=$attr"
    gmem=""
    if echo "$attr" | grep -i "gidNumber:" > /dev/null; then
      gid=$(echo "$attr" | sed -n 's/^gidNumber:\(.*\)/\1/p')
    fi
    if echo "$attr" | grep -i "memberUid:" > /dev/null; then
      gmem=$(echo "$attr" | sed -n 's/^memberUid:\(.*\)/\1/p' | tr "\n" "," )
    fi
    logDebug "parse_LDAP_grp processed group=$group gid=$gid gmem=$gmem"
    echo "$group::$gid:$gmem" >> $LDAPGROUP
    group=""
    gid=""
    gmem=""
  done < $ldap_tmp1
}
function auto_detect_vintela 
{
        /opt/quest/bin/vastool info servers > /dev/null 2>&1
	vintela_status=$(echo $?)

        if [[ $vintela_status -eq 0 ]];then
                IS_ADMIN_ENT_ACC=2
    		logDebug "Vintela is enabled in $OSNAME"
       	else 
    		logDebug "Vintela is disabled in $OSNAME"
	fi
}
function auto_detect_centrify
{
        CENT_TMP="/tmp/cent.tmp"
        FILE_CENT="/etc/nsswitch.conf"
	if [[ $OS = 'AIX' ]]; then
                attr=$(lssrc -s centrify-sshd > $CENT_TMP)
		if  [[ $? -ne 0 ]]; then
                        logDebug "Checking other centrify service"
                        attr=$(lssrc -s centrifydc > $CENT_TMP)
                fi
                while read -r CENTLine 
                do
                        logDebug "Reading nsswitch.conf file from AIX:$CENTLine"
                        VAR=`echo $CENTLine | grep centrify | awk '{print $4}' | tr '[A-Z]' '[a-z]'`
                        if [[ $VAR = 'active' ]]; then
                                IS_ADMIN_ENT_ACC=3
                                logInfo "Centrify found with ACTIVE state, So Cetrify Enabled in server"
                        elif [[ $VAR = 'inoperative' ]]; then
                                logInfo "Centrify is installed but is INOPERATIVE, SO Centrify Disabled in server"
                        else
                                logInfo "Centrify is not installed, So Centrify Disabled in server"
                        fi

                done < $CENT_TMP
        fi

	if [[ $OS = 'Linux' ]]; then
                FILE_CENT="/etc/nsswitch.conf";
                if [[ -e $FILE_CENT ]]; then
                        logInfo "nsswitch.conf file found in $OS, Proceeding further..."
                        CentrifyDetect=`cat $FILE_CENT | grep -v "^#" | grep "^passwd" | egrep -wi "centrify|centrifydc"`
                        while read -r line
                        do
                                logDebug "Reading nsswitch.conf file:$line"
                        done < $FILE_CENT
                        if [[ $CentrifyDetect != "" && $? -eq 0 ]]; then
                                logInfo "Centrify is enabled with $OS"
                                IS_ADMIN_ENT_ACC=3
                        else
                                logInfo "Centrify is disabled with $OS"
                        fi
                else
                        logInfo "nsswitch.conf does not exist in $OS, cannot fetch NIS information!"
                fi
        fi
}

function auto_detect_nis
{
	 FILE_NIS="/etc/nsswitch.conf";
	 if [[ -e $FILE_NIS ]]; then
 		logInfo "nsswitch.conf(NIS) found in $OS, Proceeding further..."
 		NisDetect=`cat $FILE_NIS | grep -v "^#" | grep "^passwd" | egrep -i "nis|nisplus"`
		while read -r line
                do
                        logDebug "Reading nsswitch.conf file:$line"
                done < $FILE_NIS	
    		if [[ $NisDetect != "" && $? -eq 0 ]]; then
       			logInfo "NIS is enabled with $OS"
       			NIS=1
       			NOAUTOLDAP=1
      		else
       			logInfo "NIS is disabled with $OS"
       			NIS=0
       			NOAUTOLDAP=0
      		fi
  	else
  		logInfo "nsswitch.conf does not exist in $OS, cannot fetch NIS information!"
 	fi
}

#V9.7.0 added
#function to detect presence of ipa software of rhel idm for rbac
#Command=ipactl status
function auto_detect_rhel_idm_ipa_rbac
{

    logDebug "---auto_detect_rhel_idm_ipa_rbac: start---"
    logDebug "Initially RHELIDMIPA= $RHELIDMIPA"

    RHELIDMIPA_TMP="/tmp/rhelidmipa.tmp";
    runCmd="ipactl status > $RHELIDMIPA_TMP 2>&1"
    logDebug "Command=$runCmd"
    #`$runCmd`
    ipactl status > $RHELIDMIPA_TMP 2>&1
    declare exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        logDebug "Command ipactl status Executed: exit_code=$exit_code"
        logDebug "Processing File $RHELIDMIPA_TMP for ipactl command was successful"

        success_found=0;
        if [[ -e $RHELIDMIPA_TMP ]]; then
		while read -r Line
                do
	                logDebug "line:   $Line"
    			if [[ $success_found -eq 0 ]]; then
    				if [[ $(echo $Line | grep "ipa: INFO: The ipactl command was successful") ]]; then
        	                        logInfo "rhel Idm-Ipa for rbac is Detected - Installed"
	                                success_found=1;
                                	RHELIDMIPA=1;
				fi
			fi
                done < $RHELIDMIPA_TMP	
    		rm -f $RHELIDMIPA_TMP

	        if [[ $success_found -eq 0 ]]; then
        	        logInfo "rhel Idm-Ipa for rbac is Detected But Not Successful- Not Running"
		fi
  	else
    		logAbort "Can't open $RHELIDMIPA_TMP"
	fi
    else  
	        logInfo "Command ipactl status Failed: exit_code=$exit_code="
                logInfo "rhel Idm-Ipa for rbac is Not Detected - Not Installed, Not Exists"
    fi

    logDebug "Finally RHELIDMIPA= $RHELIDMIPA"
    logDebug "---auto_detect_rhel_idm_ipa_rbac: end---"
}

#V9.7.0 added
#function to process each user for the found rhel idm ipa environment 
#to get list of direct roles, indirect role:correponding group for each user
function process_user_rhel_idm_ipa_rbac 
{

  declare username=$1
  declare is_idmUsr=0

  logDebug "---process_user_rhel_idm_ipa_rbac start---"

  logDebug "Calling check_user_rhel_idm_ipa_rbac,,  user=$username, is_idmUsr=$is_idmUsr"
  check_user_rhel_idm_ipa_rbac $username $is_idmUsr
  is_idmUsr=$?
  logDebug "Returned check_user_rhel_idm_ipa_rbac,, is_idmUsr=$is_idmUsr"

  if [[ $is_idmUsr -eq 1 ]]; then
        logDebug "Calling check_userRole_rhel_idm_ipa_rbac,, user=$username"
        check_userRole_rhel_idm_ipa_rbac $username 
  fi


  if [[ $usr_direct_domRoles != "" ]];then
        usr_all_domRoles=$usr_direct_domRoles
  fi
  if [[ $usr_indirect_domRoles != "" ]];then
  	if [[ $usr_all_domRoles != "" ]];then
                usr_all_domRoles="$usr_all_domRoles,$usr_indirect_domRoles"
	else
                usr_all_domRoles=$usr_indirect_domRoles;
	fi
  fi

  logDebug "Returning usr_all_domRoles = '$usr_all_domRoles'"

  logDebug "---process_user_rhel_idm_ipa_rbac end---"

}

#V9.7.0 added
#function to cross check user is from the ipa software of rhel idm for rbac
#Command=ipa user-find <username>
function check_user_rhel_idm_ipa_rbac 
{

  declare username=$1 is_idmUsr=$2

  logDebug "---check_user_rhel_idm_ipa_rbac: start---"
  logDebug "Received username=$username, is_idmUsr=$is_idmUsr"

  RHELIDMIPA_TMP="/tmp/rhelidmipa1.tmp"

  runCmd="ipa user-find $username > $RHELIDMIPA_TMP 2>&1"
  logDebug "Command=$runCmd"
  ipa user-find $username > $RHELIDMIPA_TMP 2>&1
  declare exit_code=$?

  logDebug "Command Output="
  if [[ -e $RHELIDMIPA_TMP ]]; then
	while read -r Line
        do
		logDebug "line:   $Line"
	done < $RHELIDMIPA_TMP	
    	rm -f $RHELIDMIPA_TMP
  else
 	logAbort "Can't open $RHELIDMIPA_TMP"
  fi

  if [[ $exit_code -eq 0 ]]; then
	logDebug "Command ipa user-find Executed Successful : exit_code=$exit_code"
        logInfo "user $username is In Idm-Ipa, will process further.."
        is_idmUsr=1;
  else
        logDebug "Command ipa user-find Executed : exit_code=$exit_code"
        logInfo "user $username is Not in Idm-Ipa, further process not required.."
        is_idmUsr=0;
  fi
  logDebug "Returning   is_idmUsr=$is_idmUsr"
  logDebug "---check_user_rhel_idm_ipa_rbac: end---"
  return $is_idmUsr

}

#V9.7.0 added
#function to find the group bringing the indirect role
function parse_group_bringing_role 
{

  declare indiRol=$1 idm_memberGroups=$2
  declare count
  count=$(echo "$idm_memberGroups" |awk -F',' '{ print NF }')
  declare roleGrp=""

  logDebug "---parse_group_bringing_role: start---"
  logDebug "Received Indirect Role='$indiRol', idm_memberGroups= $count Groups='$idm_memberGroups'"
  
  declare i	
  for (( i=1; i<=$count; i++ ))
  do
    declare idmGrp
	idmGrp=$(echo "$idm_memberGroups" |awk -F',' '{ print $'$i' }')
	logDebug "Parsing Group $i='$idmGrp'"

        RHELIDMIPA_TMP="/tmp/rhelidmipa3.tmp";
        runCmd="ipa group-show $idmGrp > $RHELIDMIPA_TMP 2>&1"
  	logDebug "Command=$runCmd"
        ipa group-show $idmGrp > $RHELIDMIPA_TMP 2>&1
  	declare exit_code=$?

  	if [[ $exit_code -eq 0 ]]; then
                logDebug "Command group-show Executed Successful : exit_code=$exit_code"
	else
                logDebug "Command group-show Executed not Successful : exit_code=$exit_code"
                logAbort "Error in command execution, cross check command execution manually"
                return;
	fi
        logDebug "Command Output="
  	if [[ -e $RHELIDMIPA_TMP ]]; then
		while read -r Line
	        do
			logDebug "line:   $Line"

    			if [[ $(echo $Line | grep "Roles:") ]]; then
	                        logDebug "d. Group '$idmGrp' has Membership of ROLEs"
				idmGrp_memberRoles=$(echo $Line|cut -d":" -f2)
           	    		#$idmGrp_memberRoles= role1, role2, role 3..
				idmGrp_memberRoles=$(echo "$idmGrp_memberRoles" | sed 's/^ //;s/, /,/g')
           	    		#$idmGrp_memberRoles=role1,role2,role 3..
  				count_idmGrpRoles=$(echo "$idmGrp_memberRoles" |awk -F',' '{ print NF }')

	                        logDebug "GROUP ROLEs = $count_idmGrpRoles ROLE(s) =$idmGrp_memberRoles"
				declare j
				for (( j=1; j<=$count_idmGrpRoles; j++ ))
				do
								declare idm_GrpRol
		                        idm_GrpRol=$(echo "$idmGrp_memberRoles" |awk -F',' '{ print $'$j' }')
	                                logDebug "Parsing for Match: Group's Role $i='$idm_GrpRol' V/S Indirect Role='$indiRol'"
  				
					if [[ $idm_GrpRol == "$indiRol" ]];then
	                                        logDebug "Matched, Group bringing Role '$indiRol' is '$idmGrp'"
	                                        roleGrp="$idmGrp"
						break 3
					else
	                                        logDebug "Not Matched, Group bringing Role '$indiRol' is Not '$idmGrp'"
					fi
				done
    			fi

		done < $RHELIDMIPA_TMP	
    		rm -f $RHELIDMIPA_TMP

	  else
 		logAbort "Can't open $RHELIDMIPA_TMP"
	  fi

  done #outer for ends here

  logDebug "---parse_group_bringing_role: end---"

  if [[ $roleGrp == "" ]];then
	logDebug "Group NOT Found for bringing Role '$indiRol'='$roleGrp'"
        logAbort "Found erroneous data: no group matched for said role"
        return;
  else
        logDebug "Returning Group='$roleGrp' for the Role='$indiRol'"
	idmGrpRol="$roleGrp"
        logDebug "Returning idmGrpRol='$idmGrpRol' Group='$roleGrp' for the Role='$indiRol'"
  fi

}


#V9.7.0 added
#function to check if the rhel idm user is Member/ accessor of any rbac Role
#user can be a role accessor either:
#a)directly as user b)indirectly through group c)none role
#Command=ipa user-show <username>
function check_userRole_rhel_idm_ipa_rbac 
{

  declare username=$1

  logDebug "---check_userRole_rhel_idm_ipa_rbac: start---"
  logDebug "Received username='$username'"

  RHELIDMIPA_TMP="/tmp/rhelidmipa2.tmp"
  runCmd="ipa user-show $username > $RHELIDMIPA_TMP 2>&1"
  logDebug "Command=$runCmd"
  ipa user-show $username > $RHELIDMIPA_TMP 2>&1
  declare exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
	logDebug "Command ipa user-show Executed Successful : exit_code=$exit_code"
  else
	logDebug "Command ipa user-show Executed not Successful : exit_code=$exit_code"
        logAbort "Error in command execution, cross check command execution manually"
        return
  fi

  logDebug "Command Output="
  if [[ -e $RHELIDMIPA_TMP ]]; then
	while read -r Line
        do
		logDebug "line:   $Line"
    		if [[ $(echo $Line | grep "Member of groups:") ]]; then
	                logDebug "a. User $username has Membership of GROUPs"

			idm_memberGroups=$(echo $Line|cut -d":" -f2)
           	    	#$idm_memberGroup= group1, group2, group 3..
			idm_memberGroups=$(echo "$idm_memberGroups" | sed 's/^ //;s/, /,/g')
           	    	#$idm_memberGroup=group1,group2,group 3..

	                count_memberGroups=$(echo "$idm_memberGroups" |awk -F',' '{ print NF }')
	                logDebug "MEMBER GROUPs = $count_memberGroups GROUP(s) =$idm_memberGroups"

    		elif [[ $(echo $Line | grep "Roles:") ]]; then
	                logDebug "b. User $username has DIRECT Membership of ROLEs"

	                idm_directRoles=$(echo $Line|cut -d":" -f2)
           	    	#$idm_directRoles= role1, role2, role 3..
			idm_directRoles=$(echo "$idm_directRoles" | sed 's/^ //;s/, /,/g')
           	    	#$idm_directRoles=role1,role2,role 3..

           	    	count_directRoles=$(echo "$idm_directRoles" |awk -F',' '{ print NF }')
	                logDebug "DIRECT ROLEs = $count_directRoles ROLE(s) =$idm_directRoles"

			usr_direct_domRoles="$idm_directRoles"
	                logInfo "Total DIRECT ROLEs STORED='$usr_direct_domRoles'"

    		elif [[ $(echo $Line | grep "Indirect Member of role:") ]]; then
                	logDebug "c. User $username has INDIRECT Member of ROLEs"

	                idm_indirectRoles=`echo $Line|cut -d":" -f2`
           	    	#$idm_indirectRoles= role1, role2, role 3..
			idm_indirectRoles=$(echo "$idm_indirectRoles" | sed 's/^ //;s/, /,/g')
           	    	#$idm_indirectRoles=role1,role2,role 3..

           	    	count_indirectRoles=$(echo "$idm_indirectRoles" |awk -F',' '{ print NF }')
        	        logDebug "INDIRECT ROLEs = $count_indirectRoles ROLE(s) =$idm_indirectRoles"

			declare i
			for (( i=1; i<=$count_indirectRoles; i++ ))
			do
							declare indiRol
	                        indiRol=$(echo "$idm_indirectRoles" |awk -F',' '{ print $'$i' }')
	                        logDebug "Finding Group bringing this Indirect Role $i='$indiRol'"
				idmGrpRol=""
                        	parse_group_bringing_role $indiRol $idm_memberGroups
	                        logDebug "Received Group='$idmGrpRol'"

  				if [[ $usr_indirect_domRoles == "" ]];then
			     		usr_indirect_domRoles="$indiRol:%LDAP/$idmGrpRol"
				else
			     		usr_indirect_domRoles="$usr_indirect_domRoles,$indiRol:%LDAP/$idmGrpRol"
				fi

			done

                        logInfo "Total INDIRECT ROLEs STORED='$usr_indirect_domRoles'"

		fi

	done < $RHELIDMIPA_TMP	
    	rm -f $RHELIDMIPA_TMP

  else
 	logAbort "Can't open $RHELIDMIPA_TMP"
  fi

  logDebug "---check_userRole_rhel_idm_ipa_rbac: end---"

}

function get_state
{
  declare ckid=$1 ostype=$2
  ckid=$(echo $1|sed 's/\//\\\//g')
  state="Enabled"
  
  logDebug "get_state:user $ckid"
 
if [[ $(echo "$ckid" | awk -F'\' '{print NF}') == 2 ]]; then
	ckid=$(echo "$ckid" | awk -F'\' '{print $2}')
fi

logDebug "User name after excluding domain from user:$ckid"
      testvar=""
      AGet local_users "${ckid}" testvar
      if [[ $testvar = "" ]]; then
        if [[ $KRB5AUTH = "yes" || $IS_ADMIN_ENT_ACC -eq 1 && $state != "SSH-Enabled" ]]; then
          	logDebug "Bypassing check for kerberos user:$ckid enabled by * in password field"
                state="Enabled"
	  	return
	  fi
     fi
  if [[ $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0 ]]; then 
    if [[ $IS_ADMIN_ENT_ACC -eq 2 ]];then
    #get state from vintela
      testvar=""
      AGet local_users "${ckid}" testvar
      if [[ $testvar = "" ]]; then
      attr=$(/opt/quest/bin/vastool -u host/ attrs $ckid userAccountControl)
      logDebug "get_state: LDAP user $ckid, attr is $attr"
      if [[ ! -z $attr ]]; then
        attr=$(echo "$attr" | awk 'match($0, /[0-9]+/) {print substr($0, RSTART, RLENGTH)}')
        let "st=$attr & 2"
        if [[ $st -eq 0 && $attr != "" ]]; then
          state="Enabled"  
        else 
          state="Disabled"
        fi 
      else
        state="Disabled"  
      fi  
      return
     fi
    fi
    #centrify
    if [[  $IS_ADMIN_ENT_ACC -eq 3 ]];then 
      if [[ ! -f $CENTRTMP ]]; then
        adquery user --unixname --disabled  > $CENTRTMP
      fi
      locked=$(grep ^$ckid:accountDisabled $CENTRTMP|cut -d: -f3)
      if [[ $locked = "false" ]];then
        state="Enabled"  
      else 
        state="Disabled"
      fi 
      return
    fi
  fi
    
  if [[ $shell = "/bin/false" ]]; then
    state="Disabled"
  fi
  if [[ $shell = "/usr/bin/false" ]]; then
    state="Disabled"
  fi
  
  logDebug "get_state: shell $shell, state $state"
  
  if [[ $ostype = "AIX" ]]; then
    acclocked=$AIXDEFSTATE
	locked=$(awk "{ RS="\n\n" } /^$ckid:/ { print }" "$SECUSER"|grep account_locked|sed 's/^[ ]*//;s/[ ]*$//'|cut -d" " -f3)
    logDebug "AIX SECUSER $ckid: locked:$locked"
    if [[ $locked = "true" || $locked = "yes" || $locked = "always" ]]; then
      acclocked="Disabled"
    fi
    logDebug "AIX SECUSER account $acclocked"
    
    if [[ $acclocked = "Enabled" && $state != "Disabled" ]] ;then   #check when acclocked is enabled!!!
      crypt=$(awk " /^$ckid:/,/password/ { print }" $SPASSWD|grep password|sed 's/^[ ]*//;s/[ ]*$//'|tr -d " "|cut -d = -f 2)
      logDebug "AIX SPASSWD $ckid :$crypt"
      if [[ $crypt = "*" ]]; then
        state="Disabled"
      else
      if [[ -n $crypt ]]; then
        state="Enabled"
        else
          state="Disabled"  
      fi  
    fi  
  fi  
    
    logDebug "1 acclocked $acclocked state $state "
    if [[ $acclocked = "Disabled" || $state = "" ]]; then
      state="Disabled"
    fi
    logDebug "2 acclocked $acclocked state $state "
    
    if [[ $acclocked = "Enabled" && $state = "Disabled" ]]; then
      if [[ $PUBKEYAUTH = "yes" ]]; then
        if [[ -s $home/$AUTHKEYSFILE || -s $home/$AUTHKEYSFILE2 ]]; then
          state="SSH-Enabled"
          logDebug "SSH Key file:$home/$AUTHKEYSFILE is found for $userid"
        fi
      fi
    fi  
  else
    if [  -r $SPASSWD ]; then
      crypt=$(grep ^$ckid: $SPASSWD|cut -d: -f2)
      logDebug "SECUSER $ckid: crypt"
      # check for user disabled by LOCKED, NP, *LK*, !!, or * in password field
      if [[ $crypt = "LOCKED" ]]; then
        state="Disabled"
      fi
      if [[ $crypt = "*" ]]; then
        state="Disabled"
      fi
      if echo "$crypt" | grep "LK" > /dev/null; then    #V 4.5
        state="Disabled"
      fi
      if echo "$crypt" | grep "^!" > /dev/null; then
        state="Disabled"
      fi
    fi
  fi
  logDebug "get_state:user $ckid:$state" 
}

function hp_logins
{ 
  declare username=$1
  userdata=$(logins -axo -l $username)
  F11=$(echo ${userdata}|awk -F : '{ print $11 }')
  F10=$(echo ${userdata}|awk -F : '{ print $10 }')
  F9=$(echo ${userdata}|awk -F : '{ print $9 }')
  logDebug "hp_logins:$username, MaxAge=$F11, MinAge=$F10, Chg=$F9"
  
  if [[ ($F11 = "-1" && $F10 = "-1") || $F9 = "000000" || $F9 = "" ]]; then
    logDebug "hp_logins:NeverExpires TRUE"
    AStore PWNeverExpires_Arr ${username} "TRUE"
  else
    logDebug "hp_logins:NeverExpires FALSE"
    AStore PWNeverExpires_Arr ${username} "FALSE"
  fi

  if [[ $F11 = "-1" ]]; then
    F11="99999"
  fi  
 
  F10=$(echo ${userdata}|awk -F : '{ print $10 }')
  if [[ $F10 = "-1" ]]; then
    F10="0"
  fi  

  AStore PWMaxAge_Arr ${username} "$F11"
  AStore PWMinAge_Arr ${username} "$F10"

  if [[ $F11 != "99999" && $F9 != "000000" ]]; then
    logDebug "hp_logins:calculating Exp"
    MM=$(echo $F9|cut -c0-2)
    ((MM=$MM-1))
    DD=$(echo $F9|cut -c3-4)
    YY="1970"
    if [[ $F9 != "010170" ]]; then
    YY=$(echo $F9|cut -c5-6)
    fi
    if command -v $PERL >/dev/null 2>&1; then
      tmp="`perl -e 'use Time::Local; print timelocal('0','0','0','${DD}','${MM}','${YY}'),\"\n\";'`"
      ((tmp=$tmp+$F11*86400))
      tmp=`EPOCHtoDate "$tmp"`        
    else
      tmp=""
    fi  
    logDebug "hp_logins:Exp is set to $tmp"
    logDebug "hp_logins:NeverExpires FALSE"
    AStore PWExp_Arr ${username} "$tmp"
    AStore PWNeverExpires_Arr ${username} "FALSE"
  else
    logDebug "hp_logins:Exp is set to 31 Dec 9999"
    AStore PWExp_Arr ${username} "31 Dec 9999"
  fi  
  
  if [[ $F9 = "000000" || $F9 = "" || $F9 = "010170" ]]; then
    F9="01 Jan 1970"
  else
    MM=$(echo $F9|cut -c0-2)
    DD=$(echo $F9|cut -c3-4)
    YY=$(echo $F9|cut -c5-6)
    F9=`formatDate "$MM" "$DD" "$YY"`
  fi    
  logDebug "hp_logins:Chg is set to $F9"
  AStore PWChg_Arr ${username} "$F9"
}

# V2.6 iwong
function hpux_get_state
{
    declare ckid=$1 ostype=$2 
    state="Enabled"
    # process shadow file if it exists
    if [  -r $SPASSWD ]; then
      crypt=$(grep ^$ckid: $SPASSWD|cut -d: -f2)

      # check for user disabled by LOCKED, NP, *LK*, !!, or * in password field
      if [[ $crypt = "LOCKED" ]]; then
        logDebug "hpux_get_state:HPUX SPASSWD DISABLED $ckid: crypt:$crypt"
        state="Disabled"
      fi
      if [[ $crypt = "*" ]]; then
        logDebug "hpux_get_state:HPUX SPASSWD DISABLED $ckid: crypt:$crypt"
        state="Disabled"
      fi
      if [[ $crypt = "*LK*" ]]; then
        logDebug "hpux_get_state:HPUX SPASSWD DISABLED $ckid: crypt:$crypt"
        state="Disabled"
      fi
    if [[ $crypt = "LK" ]]; then
        logDebug "hpux_get_state:HPUX SPASSWD DISABLED $ckid: crypt:$crypt"
      state="Disabled"
    fi
    if echo "$crypt" | grep "^!" > /dev/null; then
        logDebug "hpux_get_state:HPUX SPASSWD DISABLED $ckid: crypt:$crypt"
      state="Disabled"
    fi
    ## additional check for HP TCB systems
  fi
  # peform getprpw check if TCB machine
  if [[ $TCB_READABLE -eq 1 ]]; then
    lockout=$(/usr/lbin/getprpw -m lockout $ckid)
    matched=$(echo $lockout|grep 1|wc -l)
    if [[ $matched -gt 0 ]]; then
      state="Disabled"
      logDebug "hpux_get_state:HPUX getprpw $ckid: $lockout"
    fi
  else
    ISDISABLED=$(passwd \96s $ckid|egrep "\sLK" | wc -l)
    if [[ $ISDISABLED = "1" ]]; then
      state="Disabled"
    fi  
  fi
}

Remove_Labeling_Delimiter()
{
  declare labellingData=$1
  
  outLabellingData=$(echo "$labellingData" | sed "s/|/ /g")
  echo "$outLabellingData"
  return 0
}

GetURTFormat()
{
  declare _gecos=$1

  userstatus="C"
  userccc=$USERCC
  userserial=""
  usercust=""
  usercomment=$_gecos

  ## LOOK FOR CIO Format
  matched=$(echo $_gecos | grep -i "s\=" | wc -l)
  if [[ $matched -gt 0 ]]; then
    serialccc=$(echo $gecos | tr "[:upper:]" "[:lower:]" | sed -n 's/.*\(s=[a-zA-Z0-9]*\).*/\1/p')
    serial=$(echo $serialccc|cut -c3-8)
    ccc=$(echo $serialccc|cut -c9-11)

    if [[ ${#serialccc} -ge 11 ]]; then
      userserial=$serial
      userccc=$ccc
      userstatus="I"
      usercust=""
      usercomment=$_gecos
    fi
  fi

    ## LOOK FOR IBM SSSSSS CCC Format
  matched=$(echo $_gecos | egrep -i "IBM|Kyndryl [a-zA-Z0-9-]\{6\} [a-zA-Z0-9]\{3\}" | wc -l)
    if [[ $matched -gt 0 ]]; then
      oIFS="$IFS"
      IFS=' ,' 
      declare -a tokens=("$_gecos")
      IFS="$oIFS"

      count=0
      while(( $count < ${#tokens[*]} )); do
      if [[ ${tokens[$count]} = "IBM" || ${tokens[$count]} = "Kyndryl" ]]; then
        if [[ count+3 > ${#tokens[*]} ]]; then
          break
        fi

        serial=${tokens[$count+1]}
        ccc=${tokens[$count+2]}
        if [[ ${#serial} -ne 6 ]]; then
          break
        fi
      if [[ ${#ccc} -ne 3 ]]; then
          break
        else
		ccc3=$(echo "$ccc"}|cut -c1-3)
      fi

      userserial=$serial
      userccc=$ccc3
      userstatus="I"
      usercomment=$_gecos
      break
    fi
    let count=count+1
    done
    IFS=$oIFS
  fi

  usergecos="$userccc/$userstatus/$userserial/$usercust/$usercomment"

  ## LOOK FOR URT Format
  matched=$(echo $_gecos | grep ".\{2,3\}\/.\{1\}\/" | wc -l)
  if [[ $matched -gt 0 ]]; then
    usergecos=$_gecos
  fi
  IFS=" "

  usergecos=$(Remove_Labeling_Delimiter "$usergecos")
  echo "$usergecos"
}

Last_Alias_index=0
function find_last_alias
{
    declare alias=$1
    _subalias=""
    found=""
    AGet AliasOfAlias $alias _subalias
    logDebug "find_last_alias: alias $alias subalias $_subalias"
    if [[ $_subalias != "" && $found == "" ]]; then
        oFS=$IFS
        IFS=,;for _tempAlias in ${_subalias}
        do
            if [[ $found == "" ]]; then
                AStore Last_Alias ${Last_Alias_index} $_subalias
                logDebug "find_last_alias:alias $_tempAlias, found subalias $_subalias"
                if [[ $_subalias == "" ]]; then
                    found=$alias
                    break
                fi
            fi
         done
     else
        found=$alias
     fi
     logDebug "find_last_alias: return subalias $found"
     IFS=$oFS
}

function make_alias_of_alias
{
  declare _user=$1
  declare alias=$2
  declare _group=$3

  logDebug "make_alias_of_alias: user $_user, alias $alias, group $_group"

  AUnset Last_Alias
  Last_Alias_index=0
  find_last_alias "$alias"
  
  _subalias=""
  (( Last_Alias_index-=1 ))
  AGet Last_Alias $Last_Alias_index _subalias
      
  logDebug "make_alias_of_alias: user $_user, alias $alias, Index $Last_Alias_index, subalias $_subalias"
  if [[ $alias = "$_subalias" ]]; then
    _subalias=""
  fi
  
  if [[ $_subalias != "" ]];then
    _str="$alias:$_subalias"
    store_user_alias $_user $_str
    make_alias_of_group_val=""
    make_alias_of_group "$user" "$_subalias"
    aliasgroup=$make_alias_of_group_val
    if [[ $aliasgroup != "" ]]; then
      store_user_alias $user "$alias:%$aliasgroup"
    fi
  fi
  
  if [[ $_group != "" ]];then
    store_user_alias $_user "$alias:%$_group"
  else
    store_user_alias $_user $alias  
  fi
}

function store_user_alias
{
  _user=$1
  valstr=$2
  if [[ $valstr = "" ]];then
    return;
  fi
  sudostr=""
  AGet UserAlias $_user sudostr
  if echo "$sudostr" | egrep "$valstr,|$valstr$" >/dev/null; then 
    logDebug "store_user_alias: $valstr is found"
    return;
  fi

  logDebug "store_user_alias: user $_user, value $valstr, sudostr $sudostr"
  if [[ $sudostr != "" ]];then
    AStore UserAlias $_user ",$valstr" append
  else
    AStore UserAlias $_user "SUDO_ALIAS($valstr"
  fi
  #APrintAll UserAlias ":"
}

make_alias_of_group_val=""
function make_alias_of_group
{
  user=$1
  alias=$2
  
  aliaslist=""
  AGet AliasList $alias aliaslist
  usergroups=""
  AGet $user_allgroups $user usergroups
  
  #logDebug "make_alias_of_group: user $user, alias $alias, aliaslist $aliaslist, usergroups $usergroups"
  oFS=$IFS
  IFS=,;for aliasgroup in ${aliaslist}
  do
    if echo "$aliasgroup" | grep "^%" >/dev/null; then 
      aliasgroup=$(echo ${aliasgroup}|tr -d %:)
      for usergroup in ${usergroups}
      do
        if [[ $usergroup = "$aliasgroup" ]]; then
          #logDebug("make_alias_of_group: user $user, alias $alias, found usergroup $usergroup");
          make_alias_of_group_val=$usergroup
          IFS=$oFS
          return 0
        fi
      done
    fi
  done
  make_alias_of_group_val=""
  IFS=$oFS
  return 1
}

function ProcessSubAlias
{
  declare parent_alias=$1
  declare alias=$2
  
  testvar=""
  AGet1 aliasUsers $alias testvar
  declare aliaslist=$testvar
  logDebug "ProcesssSubAlias: parent $parent_alias, alias $alias, aliaslist $aliaslist"
  declare oFS=$IFS
  IFS=,;for nxt in ${aliaslist}
  do
    if echo "$nxt" | grep "^%" >/dev/null; then 
      nxt=$(echo ${nxt}|tr -d %:)
      testvar=""
      AGet ALLGroupUsers $nxt testvar
      declare Members=$testvar
      if [[ $Members != "" ]];then
        for NewName in ${Members}
        do
          logDebug "ProcessSubAlias: Found user $NewName in group $nxt in $alias"
          store_user_alias $NewName "$parent_alias:%$nxt"
        done
      fi 
    elif [[ $nxt != "" ]]; then
      testvar=""
      AGet PasswdUser $nxt testvar 
      if [[ $testvar != "" ]]; then
        logDebug "ProcessSubAlias: Add alias to user $nxt $useralias"
        store_user_alias $nxt "$parent_alias:$alias"
      else
        testvar=""
        AGet1 aliasUsers $nxt testvar
        if [[ $testvar != "" ]]; then
          logDebug "ProcessSubAlias: Found subalias user $NewName, alias $nxt"
          ProcessSubAlias $parent_alias $nxt
        fi
      fi
    fi  
  done
} 
###########################################################################
function preparsesudoers
{
  declare sudo_file=$1
  declare tmp_sudo=$2
  declare include_file=""
  declare include_dir=""
  
  logDebug "Preprocess sudo file $sudo_file";
  if [[ $VPREFIX = "" ]]; then
    cat $sudo_file >> $tmp_sudo
  else
    cat $sudo_file | sed 's/'$VPREFIX'//g'>> $tmp_sudo
  fi
  while read nextline; do
    if echo "$nextline" | egrep -i "^#includedir[ \t]*" > /dev/null; then
      include_dir=$(echo "$nextline" | awk '{print $2}')
      logDebug "SUDOERS:include dir $include_dir"
      
      if [ ! -d $include_dir ]; then
        logDebug "SUDOERS: $include_dir doesn't exist"
        continue  
      fi
      declare content 
	  content=$(ls $include_dir)
      logDebug "SUDOERS:content of include dir: $content"
      IFS="
      ";for include_file in $content
      do
        include_file="$include_dir/$include_file"
        
        logDebug "SUDOERS:check file $include_file"
        if [ ! -e $include_file ]; then
          logDebug "SUDOERS:$include_file is not a file"
          continue
        fi  
        
        if echo "$include_file" | grep -i "~$" > /dev/null; then
          logDebug "SUDOERS: Skip file $include_file"
          continue
        fi
        
        if [ -d $include_file ]; then
          logDebug "SUDOERS:Skip directory $include_file"
          continue
        fi
        logDebug "SUDOERS: Found #includedir directive. $include_dir"
        preparsesudoers $include_file $tmp_sudo
      done
      IFS=" "    
      continue
    fi  
    
    if echo "$nextline" | egrep -i "^#include[ \t]*" > /dev/null; then
      include_file=`echo "$nextline" | awk '{print $2}'`
      
      if echo "$include_file" | grep -i "%h$" > /dev/null; then
        include_file=${include_file%%\%h}
        include_file=$include_file"$HOST"
        logDebug "SUDOERS: Add host name to sudo file $include_file"
      fi
      
      if [ ! -e $include_file ]; then
         logDebug "SUDOERS:$include_file is not a file"
         continue
      fi  
      
      logDebug "SUDOERS: Found #include directive. $include_file"
      preparsesudoers $include_file $tmp_sudo
    fi
  done < $sudo_file
}

function ProcessUser_Alias
{
   declare alias=$1 
   AGet1 aliasUsers ${alias} aliasusers
   logDebug "Starting ProcessUser_Alias:User_Alias: $alias, aliasusers $aliasusers"
   ## process throu list of users
   IFS=,;for nextuser in ${aliasusers}
    do
      ## added code to process groups in the user_alias
      if echo "$nextuser" | grep "^%" >/dev/null; then 
        ## parse out % in group name
        group=`echo ${nextuser}|tr -d %:`
        logDebug "ProcessUser_Alias: Found GROUP in User_Alias->$group"

        ## check if goup already read
        uniqueusers=""
        AGet ALLGroupUsers "$group" uniqueusers
        if [[ $uniqueusers = "" ]]; then
            logMsg "WARNING" "Invalid group in $SUDOERFILE in User_Alias $alias: $group"
            EXIT_CODE=1
        else
          #AStore sudoGroups  "${group}" "$alias" 
          logDebug "ProcessUser_Alias: SUDOERS: User_Alias Adding group: $group, alias $alias"
          IFS=,;for nextu in ${uniqueusers}
          do
            logDebug "ProcessUser_Alias: make user alias string user $nextu, alias $alias, group $group"
            make_alias_of_alias $nextu $alias "$group"
          done
          IFS=" "
        fi
      else
        testvar=""
        AGet PasswdUser $nextuser testvar
        if [[ $testvar != "" ]]; then
          make_alias_of_alias $nextuser $alias ""
        else
          testvar=""
          AGet1 aliasUsers ${nextuser} testvar
	  nextuser=`echo $nextuser | tr '[:upper:]' '[:lower:]'`
          testvar=`echo $testvar | tr '[:upper:]' '[:lower:]'`
          if [[ $testvar != "" && $nextuser != "$testvar" ]];then
            ProcessSubAlias $alias $nextuser
          else
            logMsg "WARNING" "Invalid user in $SUDOERFILE in User_Alias $alias: $nextuser"
            EXIT_CODE=1
          fi
        fi
      fi
   done
   IFS=" "
   logDebug "Finished ProcessUser_Alias:User_Alias: $alias"
}

function Parse_Sudo
{
  declare tmp_sudo_file="/tmp/sudoersfile.tmp"
  rm -f $tmp_sudo_file

  preparsesudoers $SUDOERFILE $tmp_sudo_file
  
  SUDOALL="2"
  # egrep removes comments
  # egrep removes netgroup id ( any id starting with +)
  # sed remove leading and trailing spaces
  # sed -e join line with backslash
  # sed replace = with blank
  # sed replace tab with blank
  # tr remove multiple spaces
  # sed delete blank lines
  # remove space between commas
  # remove space between =
  
  DATA=`egrep -v "^[ ]*#" $tmp_sudo_file| sed 's/^\+\(.*\)/LDAP\/\1/g' | sed 's/^[    ]*//;s/[	 ]*$//'|sed -e :a -e '/\\\\$/N; s/\\\\\n//; ta'|sed 's/	/ /g'|tr -s '[:space:]'|sed '/^$/d'|sed 's/, /,/g'|sed 's/ ,/,/g'|sed 's/ =/=/g'|sed 's/= /=/g'>$TMPFILE` 

  while read nextline; do
    #echo  "SUDOERS: $nextline "
    declare -a tokens=($(echo "$nextline"|sed 's/(/ /g'))
    logDebug "SUDOERS: ----> $nextline"
    case ${tokens[0]} in
      Cmnd_Alias ) continue ;;
      Runas_Alias )continue ;;
      Defaults )continue ;;
      ALL )
      if echo "$nextline" | egrep "(!|NOEXEC)" > /dev/null; then
        logMsg "WARNING" "Found ALL=!Cmnd_Alias $nextline"
        SUDOALL="0"
      else
        if [[ $SUDOALL = "2" ]]; then
        tmphostalias=${tokens[1]}
        tmphostalias=${tmphostalias%%=*}
        tmphostalias=`trim "$tmphostalias"`
        
        testvar=""
        AGet validHostAlias $tmphostalias testvar
        if [[ $testvar != "" || $tmphostalias = "ALL" ]]; then
          logDebug "Found SUDOALL $tmphostalias"
          SUDOALL="1"
        fi        
      fi
    fi
    continue
    ;;
    Host_Alias )
    declare -a HAtokens=($(echo "$nextline"|sed 's/=/ /g'))
    alias=${HAtokens[1]}
    aliashosts=${HAtokens[2]}
    ## add alias name in to array
    logDebug "SUDOERS HOST ALIAS: $nextline"
    logDebug "SUDOERS HOST ALIAS: Found host alias: $alias"
    ## process throu list of hosts
    IFS=,;for nexthost in ${aliashosts}
      do
        logDebug "SUDOER HOST ALIAS: Host_Alias: $alias checking $nexthost = $HOST"
        ## added code to process groups in the user_alias
        HOSTALIASFOUND=0
        case $HOST in 
          "$nexthost" ) HOSTALIASFOUND=1
          ;;
        esac
        
        case $LONG_HOST_NAME in 
          "$nexthost" ) HOSTALIASFOUND=1
          ;;
        esac

        case "ALL" in 
          "$nexthost" ) HOSTALIASFOUND=1
          ;;
        esac

        if [[ $HOSTALIASFOUND -ne 0 ]]; then
          AStore validHostAlias "${alias}" "$alias"
          logDebug "SUDOER HOST ALIAS: Found valid Host_Alias $alias = $HOST"
          continue
        fi
      done
      IFS=" "
      ;;
      User_Alias )
	  declare -a UAtokens=($(echo "$nextline"|sed 's/=/ /g'))
      alias=${UAtokens[1]}
      aliasusers=${UAtokens[2]}
      ## add alias name in to array
      logDebug "SUDOERS USER ALIAS: $nextline"
      logDebug "SUDOERS USER ALIAS: Found user alias: $alias, aliasusers $aliasusers"
      AStore1 aliasUsers ${alias} $aliasusers
      
      IFS=,;for usr in $aliasusers
      do
        testvar=""
        AGet UserAliasList $usr testvar
        if  [[ $testvar != "" ]]; then
          testvar=$testvar",$alias"
          AStore UserAliasList ${usr} "$testvar"
        else
          AStore UserAliasList ${usr} $alias
        fi    
       testvar=""
       AGet1 aliasUsers $usr testvar
       if  [[ $testvar != "" ]]; then
        logDebug "SUDOERS:Alias of Alias $alias:$usr"
        testvar=""
        AGet AliasOfAlias $alias testvar
        if  [[ $testvar != "" ]]; then
          testvar=$testvar",$usr"
          AStore AliasOfAlias ${alias} "$testvar"
          logDebug "SUDOERS:Store AliasofAlias $alias:$testvar"
        else
          AStore AliasOfAlias ${alias} "$usr"
          logDebug "SUDOERS:Store AliasofAlias $alias:$usr"
        fi    
       fi
       done   
       IFS=" "
      ;;
      * )
      #Checking to see if this is a valid host/Host_Alias/ALL
      logDebug "SUDOERS USER/GROUP: $nextline"
      PROCESS_LINE=0

      for nexttoken in ${nextline}
        do
          logDebug "SUDOERS USER/GROUP: checking nexttoken: $nexttoken"
          if echo "$nexttoken" | grep "=" >/dev/null; then
            hosttoken=$(echo $nexttoken|cut -d"=" -f1)
            logDebug "SUDOERS USER/GROUP: FOUND nexttoken: $nexttoken"
            logDebug "SUDOERS USER/GROUP: FOUND hosttoken: $hosttoken"

            # process throu each hostname and Host_alias
            IFS=,;for nexthost in ${hosttoken}
              do
                logDebug "SUDOERS USER/GROUP: FOUND nexthost: $nexthost"
                ## process through users in the group
                ## Check to seeing if valid host_alias
                testvar=""
                AGet validHostAlias $nexthost testvar
                if [[ $? -eq 0 && $testvar = "" ]]; then
                  logDebug "INFO: Not a valid Host_alias: $nexthost"
                else
                  logDebug "INFO: Found a valid Host_alias: $nexthost"
                  PROCESS_LINE=1
                fi

              if [[ $nexthost = "ALL" ]]; then
                logDebug "INFO: Found ALL: $nexthost"
                PROCESS_LINE=1
                elif [[ $nexthost = "$HOST" || $nexthost = "$LONG_HOST_NAME" ]]; then
                  logDebug "INFO: Found match hostname $HOST: $nexthost"
                  PROCESS_LINE=1
                fi
                ## Check to seeing if valid hostname
              done
              IFS=" "
            fi
          done

          logDebug "SUDOERS: PROCESS_LINE ->$PROCESS_LINE"
          if [[ $PROCESS_LINE -eq 1 ]]; then
            tokenlist=${tokens[0]}

            if echo "$tokenlist" | grep "^\@" > /dev/null; then   # V4.5
              tokenlist=$(echo ${tokenlist}|tr -d @)
              echo "$tokenlist is netgrp"
              testvar=""
              AGet Netgrplist $tokenlist testvar
              if [[ $testvar != "" ]]; then
                tokenlist=$testvar
                logDebug "SUDOERS USER: Adding netgrp list $tokenlist"
              fi
            fi

            IFS=,;for nexttoken in ${tokenlist}
              do

                ## process token if group
                if echo "$nexttoken" | grep "^%" >/dev/null; then
                  ## parse out % in group name
                  group=$(echo ${nexttoken}|tr -d %:)
                  logDebug "SUDOERS GROUP: Found GROUP ->$group"
                  testvar=""
                  AGet sudoGroups "$group" testvar
                  ## check if goup already read
                  if  [[ $testvar = "" ]]; then
                    ## process through users in the group
                    uniqueusers=""
                    AGet ALLGroupUsers "$group" uniqueusers
			echo "uniqueusers==============$uniqueusers,group=============$group"
                    if [[ $uniqueusers = "" ]]; then
                      logMsg "WARNING" "Invalid group in $SUDOERFILE: $group"
                      #let errorCount=errorCount+1
                      EXIT_CODE=1
                      continue
                    else
                    logDebug "SUDOERS GROUP: Adding group: $group"
                    AStore sudoGroups  "${group}" "$group"
                    IFS=,;for nextu in ${uniqueusers}
                      do
                        testvar=""
                        AGet sudoUserGroups ${nextu} testvar
                        if [[ $testvar = "" ]]; then
                          AStore sudoUserGroups ${nextu} "$group"
                          logDebug "SUDOERS GROUP: user $nextu add sudogroup $group"
                        else
                          if echo "$testvar" | grep -i "$group" > /dev/null; then
                            continue
                          else  
                            AStore sudoUserGroups ${nextu} ",$group" append
                            logDebug "SUDOERS GROUP: user $nextu add sudogroup $group"
                          fi  
                      fi
                    done
                    IFS=" "
                  fi
                else
                logDebug "SUDODERS GROUP: WARNING: group: $group read in already"
                continue
              fi
              ## else process as user
            else
            nextuser=$nexttoken
            logDebug "SUDOERS USER: nextuser ->$nextuser"

            ## cheack if this is an user_alias
            testvar=""
            AGet1 aliasUsers $nextuser testvar
            if [[ $testvar != "" ]]; then
              logDebug "SUDOERS USER:  Matched User_Alias->$nextuser"
              ProcessUser_Alias $nextuser
              continue
            fi
            testvar=""
            AGet PasswdUser $nextuser testvar
            if [[ $testvar = "" ]]; then
              logMsg "WARNING" "Invalid user $nextuser in $SUDOERFILE"
              #let errorCount=errorCount+1
              EXIT_CODE=1
            else
              testvar=""      
              AGet sudoUsers $nextuser testvar
              if [[ $testvar = "" ]]; then
                AStore sudoUsers ${nextuser} "sudo"
                logDebug "SUDOERS USER: Adding user: $nextuser"
              else
               logDebug "SUDOERS USER: WARNING: user: $nextuser read in already"
              continue
          fi
        fi
      fi
    done
    IFS=" "
  fi
  ;;
  esac
  done < $TMPFILE
  if [[ $SUDOALL = "2" ]]; then
    SUDOALL="0"
  fi
  
  rm -f $tmp_sudo_file
}
Get_Last_Logon_User_Id() {
  declare userID=$1

  LAST_LOGIN_DATE=""

  if [[ $OS = 'Linux' ]]; then
    LOGIN_DATA=$(lastlog -u $userID 2>/dev/null | grep "$userID" | grep -v grep)

    NEVER_LOGGED_IN=$(echo "$LOGIN_DATA" | awk '{if($0 ~ /Never logged in/){print $0}}')

    if [[ $LOGIN_DATA != "" && $NEVER_LOGGED_IN = "" ]]; then
    wordcount=$(echo "$LOGIN_DATA" | wc -w)
    wordcount=$(trim $wordcount)
    if [[ "9" = "$wordcount" ]]; then    
      LAST_LOGIN_YEAR=$(echo "$LOGIN_DATA" | awk '{print $9}' | tr -d '\n')
      LAST_LOGIN_MONTH=$(echo "$LOGIN_DATA" | awk '{print $5}' | tr -d '\n')
      LAST_LOGIN_DAY=$(echo "$LOGIN_DATA" | awk '{print $6}' | tr -d '\n')
      LAST_LOGIN_TIME=$(echo "$LOGIN_DATA" | awk '{print $7}' | tr -d '\n')
    else
      LAST_LOGIN_YEAR=$(echo "$LOGIN_DATA" | awk '{print $8}' | tr -d '\n')
      LAST_LOGIN_MONTH=$(echo "$LOGIN_DATA" | awk '{print $4}' | tr -d '\n')
      LAST_LOGIN_DAY=$(echo "$LOGIN_DATA" | awk '{print $5}' | tr -d '\n')
      LAST_LOGIN_TIME=$(echo "$LOGIN_DATA" | awk '{print $6}' | tr -d '\n')
    fi  
      LAST_LOGIN_DATE="$LAST_LOGIN_DAY $LAST_LOGIN_MONTH $LAST_LOGIN_YEAR"
    fi
    elif [[ $OS = 'AIX' ]]; then
      LOGIN_DATA=$(lsuser -f $userID 2>/dev/null | grep time_last_login | grep -v grep | sed -e "s/.*=//")
      if [[ $LOGIN_DATA != "" ]]; then
        if [ -e $PERL ]; then
        LAST_LOGIN_DATE=$($PERL -e "use POSIX qw(strftime); print strftime(\"%d %b %Y\", localtime($LOGIN_DATA))")
        fi
      fi
    else
        #CURRENT_YEAR=$(date +%Y)
        CURRENT_MONTH=$(date +%b)

      ON_SINCE_DATA=$(finger $userID 2>/dev/null | awk '{if($0 ~ /On since/){ printf( "%s,", $0 ) }}')

      if [[ $ON_SINCE_DATA != "" ]]; then
      # Work with situation when user still works with an account 
	    ON_SINCE_DATA=$(echo "$ON_SINCE_DATA" | sed -e "s/.*On since //" | sed -e "s/ on.*//")
        PROCESSING_DATA=$(echo "$ON_SINCE_DATA" | awk '{ if ($0 ~ /,/) {print $0}}')

        if [[ $PROCESSING_DATA != "" ]]; then
          # Found the last login year
          LAST_LOGIN_YEAR=$(echo "$ON_SINCE_DATA" | awk '{print $4}' | tr -d '\n')
          LAST_LOGIN_MONTH=$(echo "$ON_SINCE_DATA" | awk '{print $2}' | tr -d '\n')
                lastLoginMonth=""
                curLoginMonth=""
                AGet MNames "$LAST_LOGIN_MONTH"                
                if  [[ $? -ne 0 ]]; then
                    AGet MNames "$LAST_LOGIN_MONTH" lastLoginMonth
                fi

                AGet MNames "$CURRENT_MONTH"                
                if  [[ $? -ne 0 ]]; then
                    AGet MNames "$CURRENT_MONTH" curLoginMonth
                fi

                if [[ $lastLoginMonth != "" && $curLoginMonth != "" ]]; then
                    if [[ $lastLoginMonth -lt 7 && $curLoginMonth -gt 6 ]]; then
                        ((LAST_LOGIN_YEAR -= 1))
                    fi
                fi
          LAST_LOGIN_DAY=$(echo "$ON_SINCE_DATA" | awk '{ if($3 ~ /,/){outString=substr($3, 0, length($3)-1);print outString;}else{print $3}}' | tr -d '\n')
          LAST_LOGIN_TIME=""
	    else
                LAST_LOGIN_YEAR=$(date +%Y)
                LAST_LOGIN_MONTH=$(echo "$ON_SINCE_DATA" | awk '{print $1}' | tr -d '\n')
                LAST_LOGIN_DAY=$(echo "$ON_SINCE_DATA" | awk '{print $2}' | tr -d '\n')
                LAST_LOGIN_TIME=$(echo "$ON_SINCE_DATA" | awk '{print $3}' | tr -d '\n')
        fi
        LAST_LODIN_DATE=$LAST_LOGIN_DAY" "$LAST_LOGIN_MONTH" "$LAST_LOGIN_YEAR
      fi
      LAST_LOGIN=$(finger $userID 2>/dev/null | awk '{if($0 ~ /Last login/){ print $0 }}')
      if [[ $LAST_LOGIN != "" ]]; then
        LAST_LOGIN=$(echo "$LAST_LOGIN" | sed -e "s/Last login //" | sed -e "s/ on.*//")
        PROCESSING_DATA=$(echo "$LAST_LOGIN" | awk '{ if ($0 ~ /,/) {print $0}}')
        if [[ $PROCESSING_DATA != "" ]]; then
          # Found the last login year
          LAST_LOGIN_YEAR=$(echo "$LAST_LOGIN" | awk '{print $4}' | tr -d '\n')
          LAST_LOGIN_MONTH=$(echo "$LAST_LOGIN" | awk '{print $2}' | tr -d '\n')

          LAST_LOGIN_DAY=$(echo "$LAST_LOGIN" | awk '{ if($3 ~ /,/){outString=substr($3, 0, length($3)-1);print outString;}else{print $3}}' | tr -d '\n')
          LAST_LOGIN_TIME=""
    else
        if [ $OS = 'SunOS' ]; then
          LAST_LOGIN_YEAR=$(date +%Y)
          LAST_LOGIN_MONTH=$(echo "$LAST_LOGIN" | awk '{print $2}' | tr -d '\n')

                    lastLoginMonth=""
                    curLoginMonth=""

                    AGet MNames "$LAST_LOGIN_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$LAST_LOGIN_MONTH" lastLoginMonth
                    fi

                    AGet MNames "$CURRENT_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$CURRENT_MONTH" curLoginMonth
                    fi

                    if [[ $lastLoginMonth != "" && $curLoginMonth != "" ]]; then
                        if [[ $lastLoginMonth -lt 7 && $curLoginMonth -gt 6 ]]; then
                            ((LAST_LOGIN_YEAR -= 1))
                        fi
                    fi

        LAST_LOGIN_DAY=$(echo "$LAST_LOGIN" | awk '{print $3}' | tr -d '\n')
        LAST_LOGIN_TIME=$(echo "$LAST_LOGIN" | awk '{print $4}' | tr -d '\n')
    else
        LAST_LOGIN_YEAR=$(date +%Y)
          LAST_LOGIN_MONTH=$(echo "$LAST_LOGIN" | awk '{print $2}' | tr -d '\n')

                    lastLoginMonth=""
                    curLoginMonth=""

                    AGet MNames "$LAST_LOGIN_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$LAST_LOGIN_MONTH" lastLoginMonth
                    fi

                    AGet MNames "$CURRENT_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$CURRENT_MONTH" curLoginMonth
                    fi

                    if [[ $lastLoginMonth != "" && $curLoginMonth != "" ]]; then
                        if [[ $lastLoginMonth -lt 7 && $curLoginMonth -gt 6 ]]; then
                            ((LAST_LOGIN_YEAR -= 1))
                        fi
          fi

            LAST_LOGIN_DAY=$(echo "$LAST_LOGIN" | awk '{print $3}' | tr -d '\n')
            LAST_LOGIN_TIME=$(echo "$LAST_LOGIN" | awk '{print $4}' | tr -d '\n')
    fi
      fi
      LAST_LOGIN_DATE="$LAST_LOGIN_DAY $LAST_LOGIN_MONTH $LAST_LOGIN_YEAR"
      fi
    fi
  echo $LAST_LOGIN_DATE
}

Get_Last_Logon_User_Id_new_format() {
  declare userID=$1

  LAST_LOGIN_DATE=""


  if [[ $OS = 'Linux' ]]; then
    LOGIN_DATA=$(lastlog -u $userID 2>/dev/null | grep "$userID" | grep -v grep)

    NEVER_LOGGED_IN=$(echo "$LOGIN_DATA" | awk '{if($0 ~ /Never logged in/){print $0}}')
    last_login_format=""
    if [[ $LOGIN_DATA != "" && $NEVER_LOGGED_IN = "" ]]; then
    wordcount=`echo "$LOGIN_DATA" | wc -w`
    wordcount=$(trim $wordcount)
    if [[ "9" = "$wordcount" ]]; then    
      LAST_LOGIN_YEAR=$(echo "$LOGIN_DATA" | awk '{print $9}' | tr -d '\n')
      LAST_LOGIN_MONTH=$(echo "$LOGIN_DATA" | awk '{print $5}' | tr -d '\n')
      AGet MonthNames "$LAST_LOGIN_MONTH" last_login_format
      LAST_LOGIN_DAY=$(echo "$LOGIN_DATA" | awk '{print $6}' | tr -d '\n')
      LAST_LOGIN_TIME=$(echo "$LOGIN_DATA" | awk '{print $7}' | tr -d '\n')
    else
      LAST_LOGIN_YEAR=$(echo "$LOGIN_DATA" | awk '{print $8}' | tr -d '\n')
      LAST_LOGIN_MONTH=$(echo "$LOGIN_DATA" | awk '{print $4}' | tr -d '\n')
      AGet MonthNames "$LAST_LOGIN_MONTH" last_login_format
      LAST_LOGIN_DAY=$(echo "$LOGIN_DATA" | awk '{print $5}' | tr -d '\n')
      LAST_LOGIN_TIME=$(echo "$LOGIN_DATA" | awk '{print $6}' | tr -d '\n')
    fi  
      tmp_day_count=${#LAST_LOGIN_DAY}
      if [[ $tmp_day_count -ne 2 ]]; then
                tmp_day="0$LAST_LOGIN_DAY"
                LAST_LOGIN_DATE=$LAST_LOGIN_YEAR$last_login_format$tmp_day
      else
                LAST_LOGIN_DATE=$LAST_LOGIN_YEAR$last_login_format$LAST_LOGIN_DAY
      fi

    fi
    elif [[ $OS = 'AIX' ]]; then
      LOGIN_DATA=$(lsuser -f $userID 2>/dev/null | grep time_last_login | grep -v grep | sed -e "s/.*=//")
      if [[ $LOGIN_DATA != "" ]]; then
        if [ -e $PERL ]; then
        LAST_LOGIN_DATE=$($PERL -e "use POSIX qw(strftime); print strftime(\"%Y%m%d\", localtime($LOGIN_DATA))")
        fi
      fi
    else
        #CURRENT_YEAR=$(date +%Y)
        CURRENT_MONTH=$(date +%m)

      ON_SINCE_DATA=$(finger $userID 2>/dev/null | awk '{if($0 ~ /On since/){ printf( "%s,", $0 ) }}')

      if [[ $ON_SINCE_DATA != "" ]]; then
      # Work with situation when user still works with an account 
	    ON_SINCE_DATA=$(echo "$ON_SINCE_DATA" | sed -e "s/.*On since //" | sed -e "s/ on.*//")			
        PROCESSING_DATA=$(echo "$ON_SINCE_DATA" | awk '{ if ($0 ~ /,/) {print $0}}')
ST_LOGIN_DAY
        if [[ $PROCESSING_DATA != "" ]]; then
          # Found the last login year
          LAST_LOGIN_YEAR=$(echo "$ON_SINCE_DATA" | awk '{print $4}' | tr -d '\n')
          LAST_LOGIN_MONTH=$(echo "$ON_SINCE_DATA" | awk '{print $2}' | tr -d '\n')
                lastLoginMonth=""
                curLoginMonth=""
                AGet MNames "$LAST_LOGIN_MONTH"                
                if  [[ $? -ne 0 ]]; then
                    AGet MNames "$LAST_LOGIN_MONTH" lastLoginMonth
                fi

                AGet MNames "$CURRENT_MONTH"                
                if  [[ $? -ne 0 ]]; then
                    AGet MNames "$CURRENT_MONTH" curLoginMonth
                fi

                if [[ $lastLoginMonth != "" && $curLoginMonth != "" ]]; then
                    if [[ $lastLoginMonth -lt 7 && $curLoginMonth -gt 6 ]]; then
                        ((LAST_LOGIN_YEAR -= 1))
                    fi
                fi
          LAST_LOGIN_DAY=$(echo "$ON_SINCE_DATA" | awk '{ if($3 ~ /,/){outString=substr($3, 0, length($3)-1);print outString;}else{print $3}}' | tr -d '\n')
          LAST_LOGIN_TIME=""
	    else
                LAST_LOGIN_YEAR=$(date +%Y)
                LAST_LOGIN_MONTH=$(echo "$ON_SINCE_DATA" | awk '{print $1}' | tr -d '\n')
                LAST_LOGIN_DAY=$(echo "$ON_SINCE_DATA" | awk '{print $2}' | tr -d '\n')
                LAST_LOGIN_TIME=$(echo "$ON_SINCE_DATA" | awk '{print $3}' | tr -d '\n')
        fi
        LAST_LODIN_DATE="$LAST_LOGIN_DAY $LAST_LOGIN_MONTH $LAST_LOGIN_YEAR"
      fi
      LAST_LOGIN=$(finger $userID 2>/dev/null | awk '{if($0 ~ /Last login/){ print $0 }}')
      if [[ $LAST_LOGIN != "" ]]; then
        LAST_LOGIN=$(echo "$LAST_LOGIN" | sed -e "s/Last login //" | sed -e "s/ on.*//")
        PROCESSING_DATA=$(echo "$LAST_LOGIN" | awk '{ if ($0 ~ /,/) {print $0}}')
        if [[ $PROCESSING_DATA != "" ]]; then
          # Found the last login year
          LAST_LOGIN_YEAR=$(echo "$LAST_LOGIN" | awk '{print $4}' | tr -d '\n')
          LAST_LOGIN_MONTH=$(echo "$LAST_LOGIN" | awk '{print $2}' | tr -d '\n')

          LAST_LOGIN_DAY=$(echo "$LAST_LOGIN" | awk '{ if($3 ~ /,/){outString=substr($3, 0, length($3)-1);print outString;}else{print $3}}' | tr -d '\n')
          LAST_LOGIN_TIME=""
	    else
        if [ $OS = 'SunOS' ]; then
		    LAST_LOGIN_YEAR=$(date +%Y)
		    LAST_LOGIN_MONTH=$(echo "$LAST_LOGIN" | awk '{print $2}' | tr -d '\n')

                    lastLoginMonth=""
                    curLoginMonth=""

                    AGet MNames "$LAST_LOGIN_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$LAST_LOGIN_MONTH" lastLoginMonth
                    fi

                    AGet MNames "$CURRENT_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$CURRENT_MONTH" curLoginMonth
                    fi

                    if [[ $lastLoginMonth != "" && $curLoginMonth != "" ]]; then
                        if [[ $lastLoginMonth -lt 7 && $curLoginMonth -gt 6 ]]; then
                            ((LAST_LOGIN_YEAR -= 1))
                        fi
                    fi

        LAST_LOGIN_DAY=$(echo "$LAST_LOGIN" | awk '{print $3}' | tr -d '\n')
        LAST_LOGIN_TIME=$(echo "$LAST_LOGIN" | awk '{print $4}' | tr -d '\n')
    else
        LAST_LOGIN_YEAR=$(date +%Y)
          LAST_LOGIN_MONTH=$(echo "$LAST_LOGIN" | awk '{print $2}' | tr -d '\n')

                    lastLoginMonth=""
                    curLoginMonth=""

                    AGet MNames "$LAST_LOGIN_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$LAST_LOGIN_MONTH" lastLoginMonth
                    fi

                    AGet MNames "$CURRENT_MONTH"                
                    if  [[ $? -ne 0 ]]; then
                        AGet MNames "$CURRENT_MONTH" curLoginMonth
                    fi

                    if [[ $lastLoginMonth != "" && $curLoginMonth != "" ]]; then
                        if [[ $lastLoginMonth -lt 7 && $curLoginMonth -gt 6 ]]; then
                            ((LAST_LOGIN_YEAR -= 1))
                        fi
          fi

            LAST_LOGIN_DAY=$(echo "$LAST_LOGIN" | awk '{print $3}' | tr -d '\n')
            LAST_LOGIN_TIME=$(echo "$LAST_LOGIN" | awk '{print $4}' | tr -d '\n')
    fi
      fi
      AGet MonthNames "$LAST_LOGIN_MONTH" last_login_format
      LAST_LOGIN_DATE=$LAST_LOGIN_YEAR$last_login_format$LAST_LOGIN_DAY
      fi
    fi
  echo $LAST_LOGIN_DATE
}



function report_group
{
  remote_group="FALSE"
  privilege=""
  
  if [[ $PROCESSLDAP -eq 1 || $PROCESSNIS -eq 1 ]]; then 
    remote_group="TRUE"
  fi
  groupAndGID=`APrintAll groupGIDName ":"` 
  
  IFS="
  ";for line in $groupAndGID
  do
    groupgid=${line%%:*}
    groupname=${line#*:} 
    logDebug "report_group: group $groupname gid $groupgid"  
    if [[ $IS_ADMIN_ENT_ACC -ne 0 && $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0 ]]; then
      testvar=""
      AGet local_groups "${groupname}" testvar
      if [[ $testvar = "" ]]; then    
        remote_group="TRUE"
      else
        remote_group="FALSE"  
      fi
    fi 
    
    logDebug "report_group: $groupname remote $remote_group"
    
    if [[ $remote_group = "FALSE" ]]; then
      testvar=""
      AGet privgroups $groupname testvar
      if  [[ $testvar != "" ]]; then
        privilege="TRUE"
      else
        privilege="FALSE"
      fi  
    else
     privilege=""     
    fi
    
    echo "G|$CUSTOMER|S|$HOSTNAME|$OS|$groupname||$groupgid||$remote_group|$privilege" >> $OUTPUTFILE
  done
  IFS=" "
}

function add_domain_to_group_name
{
	eval privs_group=$1 
	declare -a All_groups=()
	oldIFS=$IFS
	IFS=","
	for each_group in ${privs_group}
	{
		declare groups_with_domain=""
		declare domain=""
		AGet Domain_group "$each_group" domain
		if [[ $domain != "" ]]; then
			groups_with_domain="$domain\\$each_group"
			groups_with_domain=`echo "$groups_with_domain" | sed 's/ /:/g'`		
			All_groups[${#All_groups[@]}]="$groups_with_domain"
               else
			All_groups[${#All_groups[@]}]="$each_group"
	       fi
	}
	IFS=$oldIFS
	if [[ ${#All_groups[@]} -ne 0 ]]; then
		declare groups_with_domain=""
		for each_group in "${All_groups[@]}"
		{
			groups_with_domain="$groups_with_domain,$each_group"
		}
		groups_with_domain=$(echo "$groups_with_domain" | sed 's/^,//g')		
		groups_with_domain=$(echo "$groups_with_domain" | sed 's/:/ /g')		
	fi
	echo "$groups_with_domain"
}
function print_report
{
  userid=$1
  if [[ $userid = "" ]]; then
    return
  fi
	
      matched=$(echo $userid|grep ^+|wc -l)
      if [[ $matched -gt 0 ]]; then
    return
      fi
      
  passwd=""
  AGet userPassword "${userid}" passwd
  uID=""
  AGet PasswdUser "${userid}" uID
  gid=""
  AGet userPrimaryGroup "${userid}" gid
  gecos=""
  AGet userGECOS "${userid}" gecos
  home=""
  AGet userHome "${userid}" home
  shell=""
  AGet userShell "${userid}" shell
    
  logDebug "report->read userid=$userid passwd=$passwd uid=$uID gid=$gid gecos=$gecos home=$home shell=$shell"
              
      gecos=`Remove_Labeling_Delimiter "$gecos"`
      
      privilege=""
      userstate="Enabled"
      userllogon=""
      privField=""
      groupField=""
      privGroup=""
      userllogon=""
      
      UICmode=""
      PWChg=""
      PWMaxAge="99999"
      PWMinAge="0"
      PWExp="31 Dec 9999"
      PWNeverExpires="FALSE"
      
      if [[ $DLLD -eq 0 ]]; then
	    if [[ $Dormant == "ON_ON" || $Dormant == "ON_OFF" ]];then
        	userllogon=`Get_Last_Logon_User_Id_new_format "$userid"`
	   
	    else
        	userllogon=`Get_Last_Logon_User_Id "$userid"`
	    fi
      fi
      
      testvar=""
      AGet groupGIDName $gid testvar
      if [[ $testvar = "" ]]; then
        EXIT_CODE=1
        logMsg "WARNING" "user $userid is in group $gid. Unable to resolve group $gid to a name"
        if [[ $PROCESSNIS -eq 1 || $PROCESSLDAP -eq 1 ]]; then 
          logMsg "WARNING" "skip user $userid"
          return
        fi
      fi
      
      testvar=""      
      AGet privUser $userid testvar
      if [[ $testvar != "" ]]; then
        privField="$userid"
      fi

      if [[ $OS = "VIO" ]]; then
        userroles=$(lsuser -a roles $userid 2>/dev/null)
        logDebug "Report: User roles $userroles"
        userroles=$(echo $userroles|cut -d"=" -f2)
        logDebug "Report: 2 User roles $userroles"
        IFS=", ";for role in $userroles
        do
          role_name=""      
          AGet ROLE $role role_name
          logDebug "Report:add user role $role \"$role_name\""
          if [[ $role_name = "" ]]; then
            role_name=$role
          else 
            if [[ $privField = "" ]]; then
              privField="ROLE($role_name)"
            else
              privField=$privField",ROLE($role_name)"
            fi
          fi
          if [[ $groupField = "" ]]; then
            groupField="ROLE($role_name)"
          else
            groupField=$groupField",ROLE($role_name)"
          fi
        done
      fi
      
      testvar=""
      AGet privUserGroups $userid testvar
      if  [[ $testvar != "" ]]; then

	group_privs=$testvar
	logDebug "Prefixing domain name to GRP groups:$group_privs"
	groupname_with_domain2=$(add_domain_to_group_name "\${group_privs}")	
        logDebug "GRP groups after prefixing domain name:$groupname_with_domain2"
        privGroup="GRP($groupname_with_domain2)"
	if [[ $PROCESSLDAP -eq 1 || $IS_ADMIN_ENT_ACC -eq 2 || $IS_ADMIN_ENT_ACC -eq 3 ]]; then
        	declare -a Pgroups=()
        	oldIFS=$IFS
        	IFS=","
        	for Pgroup in $groupname_with_domain2
        	{
			AGet local_groups "${Pgroup}" testvar
      			if [[ $testvar != "" ]]; then
				groups_with_ldap_prefix="LDAP/"$Pgroup
                        	Pgroups[${#Pgroups[@]}]=$groups_with_ldap_prefix
                        	logDebug "Report group for privilige: $Pgroup - Add LDAP group prefix"
               		else
                        	Pgroups[${#Pgroups[@]}]=$Pgroup
               		fi
        	}
        	IFS=$oldIFS
		groupname_with_domain2=$(IFS=,; echo "${Pgroups[*]}")
		privGroup="GRP($groupname_with_domain2)"	
	fi
        if [[ $privField != "" ]]; then
          privField=$privField",$privGroup"
        else
          privField=$privGroup
        fi
      fi

      if [[ $SUDOALL = "1" ]]; then
        if [[ $privField != "" ]]; then
          privField=$privField",SUDO_ALL"
        else
          privField="SUDO_ALL"
        fi
      fi
      
      testvar=""
      AGet sudoUserGroups $userid testvar
      logDebug "Report:Sudo group $userid:$testvar"
      if  [[ $testvar != "" ]]; then
	group_privs1=$testvar
        logDebug "Prefixing domain name to SUDO GRP groups:$group_privs1"
        groupname_with_domain1=$(add_domain_to_group_name "\${group_privs1}")
        logDebug "SUDO GRP groups after prefixing domain name:$groupname_with_domain1"

        sudoGroup="SUDO_GRP($groupname_with_domain1)"
        if [[ $privField != "" ]]; then
          privField=$privField",$sudoGroup"
        else
          privField=$sudoGroup
        fi
      fi
      
      testvar=""
      AGet UserAlias $userid testvar
      logDebug "Report:Sudo alias $userid:$testvar"
      if  [[ $testvar != "" ]]; then
        if [[ $privField != "" ]]; then
          privField="$privField,$testvar"
        else
          privField=$testvar
        fi
        privField="$privField)"
        ADelete UserAliasList $userid
        ADelete UserAlias $userid
        logDebug "SUDOERS: deleting UserAliasList arrays entry: $userid"
      fi

      testvar=""
      SudoValue=""
      AGet sudoUsers $userid testvar
      if  [[ $testvar != "" ]]; then

	 if [[ $IS_ADMIN_ENT_ACC -ne 0 && $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0 ]]; then
             testvar1=""
             AGet local_users "${userid}" testvar1
		logDebug "local user check:$testvar1"
             if [[ $testvar1 = "" ]]; then
	         sudo_user="SUDO_LDAP/"
	         logDebug "$userid is priviliged sudo user, So adding SUDO_LDAP to prefix"
	     else
	         sudo_user="SUDO_"
	         logDebug "$userid is priviliged user, So adding SUDO to prefix"
             fi
	else
	      sudo_user="SUDO_"
              logDebug "else:$userid is priviliged user, So adding SUDO to prefix"
        fi
	user_with_domain=""
	AGet Domain_user $userid user_with_domain
        if [[ $user_with_domain != "" ]];then
            userid="$user_with_domain\\$userid"
            logDebug "Adding domain name:$user_with_domain to SUDO user: $userid"
        fi

	SudoValue="$sudo_user$userid"
        if [[ $privField != "" ]]; then
          privField="$privField,$SudoValue"
        else
          privField=$SudoValue
        fi
        ADelete sudoUsers $userid
        logDebug "SUDOERS: deleting sudoUser array entry: $userid"
      fi

      groupField=""
      AGet AllUserGroups $userid groupField
      if [[ $groupField = "" ]]; then
        logMsg "WARNING" "no any group found for user $userid"
        EXIT_CODE=1
      fi  

      
      if [[ $OS = "HP-UX" ]]; then
        hpux_get_state "$userid" "$OS"
        userstate=$state
        if [ $MEF4FORMAT -eq 1 ]; then
          hp_logins "$userid"
        fi
          if [[ $SEC_READABLE -eq 0 && $passwd = "*" && $TCB_READABLE -ne 1 ]]; then
          userstate="Disabled"
        fi        
      else
        if [[ $SEC_READABLE -eq 1 ]]; then
          get_state "$userid" "$OS"
          userstate=$state
          logDebug "Report: SEC_READABLE user $userid state $userstate"
        else
          userstate="Enabled"
        fi
      fi

      # V2.6 iwong
      if [[ $TCB_READABLE -eq 0 ]]; then
        if [[ $userstate = "Disabled" || $passwd = "*" ]]; then
          if [[ $PUBKEYAUTH = "yes" ]]; then          #v4.4 Code to check SSH public key authentation status for users having password "*" in passwd file
            logDebug "Checking SSH public key file $home/$AUTHKEYSFILE for user $userid"
            userstate="Disabled"
            if [[ -s $home/$AUTHKEYSFILE || -s $home/$AUTHKEYSFILE2 ]]; then
              logDebug "SSH Key file:$home/$AUTHKEYSFILE is found for $userid"
              if [[ $OS = "AIX" ]]; then
                if [[ $acclocked = "Enabled" && $userstate = "Disabled" ]]; then
              userstate="SSH-Enabled"
                fi
            else
                userstate="SSH-Enabled"
              fi  
            fi
          else
            if [[ $PROCESSNIS -eq 1 ]]; then
              logDebug "Dummy"
            else
             userstate="Disabled"
             logDebug "User disabled $userid: passwd:$passwd"
          fi
        fi
      fi
      else
        logDebug "Bypassing * passwd check: $userid"
      fi
      scmstate=""
      if [[ $userstate = "Enabled" ]]; then
        scmstate="0"
      fi
      if [[ $userstate = "Disabled" ]]; then
        scmstate="1"
      fi

     
        tmpval=""
        AGet PWChg_Arr $userid PWChg
        AGet PWExp_Arr $userid PWExp
        AGet PWNeverExpires_Arr $userid PWNeverExpires
        
        if [ $OS = "AIX" ]; then
          PWMinLen=""
          AGet PWMinLen_Arr $userid PWMinLen
        fi
             
        AGet PWMaxAge_Arr $userid tmpval
        if [[ $tmpval != "" ]]; then
          PWMaxAge=$tmpval
          if [[ $OS = "AIX" && $PWMaxAge = "0" ]]; then
            PWNeverExpires="TRUE"
            PWExp="31 Dec 9999"
          fi
        

        AGet PWMinAge_Arr $userid tmpval
        if [[ $tmpval != "" ]]; then
          PWMinAge=$tmpval
        fi  
      fi
	user_with_domain=""
	AGet Domain_user $userid user_with_domain
	if [[ $user_with_domain != "" ]];then

	    userid="$user_with_domain\\$userid"
            logDebug "Adding domain name:$user_with_domain= to user: $userid"
	fi
	groupField_with_domain=""
        logDebug "Prefixing domain name to groups:$groupField"
        groupField_with_domain=$(add_domain_to_group_name "\${groupField}")
        logDebug "Groups after prefixing domain name: $groupField_with_domain"
        groupField=$groupField_with_domain;

      if [[ $PROCESSNIS -eq 1 ]]; then
        	testvar=""
        	AGet local_users "${userid}" testvar
        	if [[ $testvar = "" ]]; then
        		userid="NIS/"$userid
			if [[ $Dormant == "ON_ON" ]];then
                		userllogon=""
                        	PWChg=""
                	elif [[ $Dormant == "ON_OFF" ]];then
                        	userllogon=""
                	fi
		fi
      fi

      if [[ $PROCESSLDAP -eq 1 ]]; then

	#V9.7.0 added 
      	if [[ $RHELIDMIPA -eq 1 ]]; then
	     	usr_all_domRoles=""
	     	usr_direct_domRoles=""
	     	usr_indirect_domRoles=""

		logDebug "Calling Location A"
		logDebug "Calling process_user_rhel_idm_ipa_rbac,,  user=$userid, usr_all_domRoles='$usr_all_domRoles'"
		process_user_rhel_idm_ipa_rbac $userid 
		logDebug "Returned process_user_rhel_idm_ipa_rbac,, usr_all_domRoles='$usr_all_domRoles'"

  		if [[ $usr_all_domRoles != "" ]];then
	        	usr_all_domRoles="DOM_ROLE($usr_all_domRoles)"
		        logDebug "Report usr_all_domRoles privilege: '$usr_all_domRoles' "
		        if [[ $privField == "" ]]; then
		        	privField="$usr_all_domRoles"
			else
		                privField="$privField,$usr_all_domRoles"
			fi
		fi

	fi #if for RHELIDMIPA ends here

        userid="LDAP/"$userid
	if [[ $Dormant == "ON_ON" ]];then
		userllogon=""
		PWChg=""
	elif [[ $Dormant == "ON_OFF" ]];then
		userllogon=""
	fi
      fi

      if [[ $IS_ADMIN_ENT_ACC -ne 0 && $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0 ]]; then
        	testvar=""
        	AGet local_users "${userid}" testvar
        	if [[ $testvar = "" ]]; then
			
			#V9.7.0 added 
      			if [[ $RHELIDMIPA -eq 1 ]]; then
			     	usr_all_domRoles=""
			     	usr_direct_domRoles=""
			     	usr_indirect_domRoles=""

		   	     	logDebug "Calling Location B"
			     	logDebug "Calling process_user_rhel_idm_ipa_rbac,,  user=$userid, usr_all_domRoles='$usr_all_domRoles'"
			     	process_user_rhel_idm_ipa_rbac $userid 
			        logDebug "Returned process_user_rhel_idm_ipa_rbac,, usr_all_domRoles='$usr_all_domRoles'"

  				if [[ $usr_all_domRoles != "" ]];then
			                usr_all_domRoles="DOM_ROLE($usr_all_domRoles)"
			                logDebug "Report usr_all_domRoles privilege: '$usr_all_domRoles' "
			                if [[ $privField == "" ]]; then
			                        privField="$usr_all_domRoles"
					else
			                        privField="$privField,$usr_all_domRoles"
					fi
				fi

			fi #if for RHELIDMIPA ends here

            		userid="LDAP/"$userid
	    		logDebug "Report: $userid - Add LDAP prefix"
			if [[ $Dormant == "ON_ON" ]];then
               			userllogon=""
                		PWChg=""
        		elif [[ $Dormant == "ON_OFF" ]];then
                		userllogon=""
        		fi
          	fi
      fi

			logDebug "Checking LDAP groupField: $groupField"
	if [[ ($PROCESSLDAP -eq 1 || $IS_ADMIN_ENT_ACC -eq 2 || $IS_ADMIN_ENT_ACC -eq 3) || ($IS_ADMIN_ENT_ACC -ne 0 && $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0) ]]; then
                declare -a Sgroups=()
                oldIFS=$IFS
                IFS=","
                for Sgroup in $groupField
                {
			logDebug "Checking LDAP group $Sgroup"
			AGet local_groups "${Sgroup}" testvar
                        if [[ $testvar -ne 1 ]]; then
                                groups_with_ldap_prefix="LDAP/"$Sgroup
                                Sgroups[${#Sgroups[@]}]=$groups_with_ldap_prefix
                                logDebug "Report group for group: $Sgroup - Add LDAP group prefix"
                        else
                                Sgroups[${#Sgroups[@]}]=$Sgroup
                        fi
                }
                IFS=$oldIFS
                groupField=$(IFS=,; echo "${Sgroups[*]}")
        fi
	if [[ $PROCESSNIS -eq 1 ]]; then
                declare -a Sgroups=()
                oldIFS=$IFS
                IFS=","
                for Sgroup in $groupField
                {
                        logDebug "Checking LDAP group $Sgroup"
                        AGet local_groups "${Sgroup}" testvar
                        if [[ $testvar -ne 1 ]]; then
                                groups_with_ldap_prefix="NIS/"$Sgroup
                                Sgroups[${#Sgroups[@]}]=$groups_with_ldap_prefix
                                logDebug "Report group for group: $Sgroup - Add NIS group prefix"
                        else
                                Sgroups[${#Sgroups[@]}]=$Sgroup
                        fi
                }
                IFS=$oldIFS
                groupField=$(IFS=,; echo "${Sgroups[*]}")
        fi
		
	matched=$(echo $userid | grep -i ldap | wc -l)
	if [[ $matched -gt 0 ]]; then
		logDebug "Ldap user ID : $userid is Enabeld."
		userstate="Enabled"
	fi
	if [[ $PHOTON_FLAG -eq 1 ]]; then
		OS=$OS_PHOTON
	fi
      if [[ $SCMFORMAT -eq 1 ]]; then
        echo "$HOSTNAME\t$OS\t$myAUDITDATE\t$userid\t$gecos\t$scmstate\t$userllogon\t$groupField\t$privField" >> $OUTPUTFILE
        elif [[ $MEF2FORMAT -eq 1 ]]; then
          #MEF2 customer|system|account|userID convention data|group|state|l_logon|privilege
          echo "$CUSTOMER|$HOSTNAME|$userid|$gecos|$groupField|$userstate|$userllogon|$privField" >> $OUTPUTFILE
        elif [[ $MEF4FORMAT -eq 1 ]]; then
          echo "U|$CUSTOMER|S|$HOSTNAME|$OS|$userid|$UICmode|$gecos|$userstate|$userllogon|$groupField|$privField|$uID|$PWMaxAge|$PWMinAge|$PWExp|$PWChg|$PWMinLen|$PWNeverExpires" >> $OUTPUTFILE
        else
          #MEF3 \93customer|identifier type|server identifier/application identifier|OS name/Application name|account|UICMode|userID convention data|state|l_logon |group|privilege\94

    		if [[ $Dormant == "ON_ON" ]];then
		
          		echo "$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField|$PWChg" >> $OUTPUTFILE
          		logDebug "MEF3_onon:$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField|$PWChg"
    		elif [[ $Dormant == "ON_OFF" ]];then
          		echo "$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField|" >> $OUTPUTFILE
          		logDebug "MEF3_onoff:$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField|"
    		elif [[ $Dormant == "OFF_OFF" ]];then
		
          		echo "$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField" >> $OUTPUTFILE
          		logDebug "MEF3_offoff:$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField"
		else
          		echo "$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField|$PWChg" >> $OUTPUTFILE
          		logDebug "MEF3_onon:$CUSTOMER|S|$HOSTNAME|$OS|$userid||$gecos|$userstate|$userllogon|$groupField|$privField|$PWChg"
		fi
      fi
}  

function report
{
  UICmode=""
  uID=""
  PWMinLen=""

  if [[ $OS = "AIX" ]]; then
    locked=$(awk "{ RS="\n\n" } /^default:/ { print }" "$SECUSER"|grep account_locked|cut -d" " -f3)
    if [[ $locked = "true" || $locked = "yes" || $locked = "always" ]]; then
      AIXDEFSTATE="Disabled"    
    fi
    logDebug "report: AIX default user state is $AIXDEFSTATE"
  fi  
  
  if [ $MEF4FORMAT -eq 1 ]; then
    if [[ $OS = "Linux" ]]; then
      PWMinLen=$(grep "pam_cracklib.so.*minlen=" "/etc/pam.d/system-auth" | sed -n 's/.*minlen=\([0-9]*\).*/\1/p')
      if [[ $PWMinLen = "" ]]; then
        PWMinLen=$(awk '/^PASS_MIN_LEN/ {print $2}' "/etc/login.defs")
      fi
      logDebug "report:PWMinLen=$PWMinLen"
    elif [[ $OS = "SunOS" ]]; then 
      PWMinLen=$(awk '/^PASSLENGTH=/ {print $1}' "/etc/default/passwd"|cut -d = -f2|tail -1)
      logDebug "report:PWMinLen=$PWMinLen"
    elif [[ $OS = "HP-UX" ]]; then 
      if [ -f "/etc/default/security" ]; then      
        PWMinLen=$(awk '/^MIN_PASSWORD_LENGTH=/ {print $1}' "/etc/default/security"|cut -d = -f2|tail -1)
      fi  
      if [[ "X$PWMinLen" = "X" ]]; then
        PWMinLen="6"
      fi
    fi  
  fi
  
  AUTHKEYSFILE=""
  AUTHKEYSFILE2=""
  PUBKEYAUTH=""
  #V4.4 Code to check SSH public key authentation status for users having password "*" in passwd file
  if [[ $OS = "SunOS" ]]; then
    SSHD_CONFIG="/etc/ssh/sshd_config"
    if [ -f "/usr/local/etc/sshd_config" ]; then
      SSHD_CONFIG="/usr/local/etc/sshd_config"
    fi
    AUTHKEYSFILE=$(grep 'AuthorizedKeysFile[[:space:]]\{1,\}' $SSHD_CONFIG | grep -v "\#" | nawk {'print $2'})
    AUTHKEYSFILE2=$(grep 'AuthorizedKeysFile2' $SSHD_CONFIG | grep -v "\#" | nawk {'print $2'})
    PUBKEYAUTH=$(grep PubkeyAuthentication $SSHD_CONFIG | grep -v "\#" | nawk {'print $2'})
  else
    if [ -f "/etc/ssh/sshd_config" ]; then
      AUTHKEYSFILE=$(grep 'AuthorizedKeysFile[[:space:]]\{1,\}' /etc/ssh/sshd_config | grep -v "\#" | awk {'print $2'})
      AUTHKEYSFILE2=$(grep 'AuthorizedKeysFile2' /etc/ssh/sshd_config | grep -v "\#" | awk {'print $2'})
      PUBKEYAUTH=$(grep PubkeyAuthentication /etc/ssh/sshd_config | grep -v "\#" | awk {'print $2'})
    fi
  fi

  if [[ $AUTHKEYSFILE = "" ]]; then
    AUTHKEYSFILE=".ssh/authorized_keys"
  fi
  
  if [[ $AUTHKEYSFILE2 = "" ]]; then
    AUTHKEYSFILE2=".ssh/authorized_keys2"
  fi
  logDebug "Authorized_keys file path:$AUTHKEYSFILE and SSH public key auth enabled is $PUBKEYAUTH "
  
  declare -i NElem ElemNum=1 NumNonNull=0
  declare Arr=PasswdUser VarName ElemVal

  eval NElem=\${#"${Arr}"_ind[*]}
    while (( ElemNum <= 99999 && NumNonNull < NElem )); do
      eval ElemVal=\"\${"${Arr}"_ind[ElemNum]}\"
        if [[ -n $ElemVal ]]; then
        eval userid=\$ElemVal
          print_report $userid
        ((NumNonNull+=1))
        fi
      ((ElemNum+=1))
  done
  
  if [[ $MEF4FORMAT -eq 1 ]]; then
    report_group
  fi    
}

function Parse_LDAP_Netuser
{

  ################## Processing LDAP Ids #################
#TLS
attr_tls="/tmp/tls.out"
if [[ $TLS -eq 0 ]]; then
    logDebug "Checking TLS certificate for LDAP BASE DN"
    DATA=$(ldapsearch -x -H ldaps://$LDAPSVR:$LDAPPORT -b $LDAPBASE -Z > $attr_tls 2>&1)
    logDebug "Command used to get TLS users :ldapsearch -x -b $LDAPBASE -H ldaps://$LDAPSVR:$LDAPPORT -Z"
    cmd_res=$(grep "TLS already started" $attr_tls)
    if [[ $cmd_res != "" ]]; then
	logDebug "Found TLS already started in the output...considering TLS certificate enabled"
            TLS=1 
    fi
fi

	 
if [[ $TLS -eq 0 ]]; then
    logDebug "Checking TLS certificate for LDAP w/o BASE DN"
    DATA=$(ldapsearch -x -b -H ldaps://$LDAPSVR -Z > $attr_tls 2>&1)
    logDebug "Command used to get TLS users :ldapsearch -x -b -H ldaps://$LDAPSVR -Z"
    cmd_res=$(grep "TLS already started" $attr_tls)
    if [[ $cmd_res != "" ]]; then
        logDebug "Found TLS already started in the output...considering TLS certificate enabled"
            TLS=1 
    fi
fi     

if [[ $LDAP -eq 1 ]]; then
    gecos=""
    
    IFS=" "

    if [[ $TLS -eq 1 ]]; then
        logDebug "process_TLS_LDAP_users: "
        attr=$(ldapsearch -x -H ldaps://$LDAPSVR:$LDAPPORT -b $LDAPBASE -Z)
        logDebug "Command used to get TLS users:ldapsearch -x -H ldaps://$LDAPSVR:$LDAPPORT -b $LDAPBASE -Z "
    else
        if [[ $LDAPFILE = "" ]]; then
            attr=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASE uid=$1 uid userPassword uidNumber gidNumber loginShell gecos description`
        else
            attr=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASE $LDAPADDITIONAL uid=$1 uid userPassword uidNumber gidNumber loginShell gecos description`
        fi
    fi	

    if [[ $? -ne 0 ]]; then
      logAbort "unable access LDAP server"
    fi
    userid=$(echo "$attr" | sed -n 's/^uid: \(.*\)/\1/p')
	if [[ $LDAPNULL -eq 1 ]];then
	
		gid=$(echo "$attr" | sed -n 's/^uidNumber: \(.*\)/\1/p')
		uid=$(echo "$attr" | sed -n 's/^gidNumber: \(.*\)/\1/p')
	else
		uid=$(echo "$attr" | sed -n 's/^uidNumber: \(.*\)/\1/p')
		gid=$(echo "$attr" | sed -n 's/^gidNumber: \(.*\)/\1/p')
	fi
    passwd=$(echo "$attr" | sed -n 's/^userPassword::* \(.*\)/\1/p')
    shell=$(echo "$attr" | sed -n 's/^loginShell: \(.*\)/\1/p')
    gecos=$(echo "$attr" | sed -n 's/^gecos: \(.*\)/\1/p')
    if [[ $gecos = "" ]]; then
      gecos=$(echo "$attr" | sed -n 's/^description: \(.*\)/\1/p')
    fi

    echo "$userid:$passwd:$uid:$gid:$gecos:$shell" >> $LDAPPASSWD

    logDebug "Parse_LDAP_Netuser attr is $attr "
    logDebug "Parse_LDAP_Netuser LDAP ID: $userid:$uid:$gid:$gecos:$shell:$passwd"
  fi
}

function Parse_LDAP_Subnetgrp
{
  declare subnetgrp=$1
  declare subldapgroup=""
  declare subattr=""
  declare sub_temp_file
  sub_temp_file=$(mktemp)
  
  
  logDebug "Subnetgroup is $subnetgrp"

  if [[ $LDAPFILE = "" ]]; then
    subattr=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASE cn=$subnetgrp cn nisNetgroupTriple memberNisNetgroup  > $sub_temp_file`
  else
    subattr=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASEGROUP $LDAPADDITIONAL cn=$subnetgrp cn nisNetgroupTriple memberNisNetgroup  > $sub_temp_file`
  fi

  logDebug "Parse_LDAP_Subnetgrp attr is $subattr"
  
  IFS=" "
  while read -r tmpline subldapgroup
  do  
    if echo "$tmpline" | grep -i "memberNisNetgroup:" > /dev/null; then
        Parse_LDAP_Subnetgrp $subldapgroup
    fi  
  done < $sub_temp_file  

  echo "" >> $LDAP_NETGOUP_TMP
  subattr=$(cat $sub_temp_file >> $LDAP_NETGOUP_TMP)

  if [ -e $sub_temp_file ]; then
    rm $sub_temp_file
  fi
}

function Parse_LDAP_Netgrp
{
  if [[ $LDAP -eq 1 ]]; then
    netgrp=$(echo $1 | tr -d '+' | tr -d '@')
    logDebug "Netgroup is $netgrp "
    netgr_temp_file=`mktemp`
    
    if [[ $LDAPFILE = "" ]]; then
      attr=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASE cn=$netgrp cn nisNetgroupTriple memberNisNetgroup > $LDAP_NETGOUP_TMP`
    else
      attr=`$LDAPCMD -LLL -h $LDAPSVR -p $LDAPPORT -b $LDAPBASEGROUP $LDAPADDITIONAL cn=$netgrp cn nisNetgroupTriple memberNisNetgroup > $LDAP_NETGOUP_TMP`
    fi

    attr1=$(cp $LDAP_NETGOUP_TMP $netgr_temp_file)

    logDebug "Parse_LDAP_Netgrp attr is $attr"

    IFS=" "
    while read -r tmpline ldapgroup
    do  
      if echo "$tmpline" | grep -i "memberNisNetgroup:" > /dev/null; then
          Parse_LDAP_Subnetgrp $ldapgroup
      fi
    done < $netgr_temp_file
    
    rm $netgr_temp_file
    
    if grep -i "nisNetgroupTriple:" $LDAP_NETGOUP_TMP > /dev/null; then
      ldapmem=$(sed -n 's/^nisNetgroupTriple:.*,\(.*\),.*/\1/p' $LDAP_NETGOUP_TMP | tr "\n" "," )
    fi

    logDebug "Parse_LDAP_Netgrp $netgrp : $ldapmem"

    IFS=,;for nextuser in ${ldapmem}
      do
        logDebug "Parse_LDAP_Netgrp $nextuser is processing "

        testvar=""
        AGet PasswdUser "${nextuser}" testvar
        if [[ $testvar = "" ]]; then
          Parse_LDAP_Netuser $nextuser
        else
          logDebug "Parse_LDAP_Netgrp User $nextuser Already exist"
          testvar=""
          AGet Netgrplist ${netgrp} testvar
          if  [[ $testvar = "" ]]; then
            AStore Netgrplist ${netgrp} "$nextuser"
          else
            AStore Netgrplist ${netgrp} ",$nextuser" append
          fi
          continue
        fi

        testvar=""
        AGet Netgrplist ${netgrp} testvar
        if  [[ $testvar = "" ]]; then
          AStore Netgrplist ${netgrp} "$userid"
        else
          AStore Netgrplist ${netgrp} ",$userid" append
        fi

        AStore PasswdUser ${userid} "$uid"
        testvar=""
        AGet primaryGroupUsers ${gid} testvar
        if  [[ $testvar = "" ]]; then
          AStore primaryGroupUsers ${gid} "$userid"
        else
          AStore primaryGroupUsers ${gid} ",$userid" append
        fi
        
        StoreUserData
      done
    IFS=" "
  fi
  
  if [ -e $LDAP_NETGOUP_TMP ]; then
    rm $LDAP_NETGOUP_TMP
  fi

}

function IsAdminEntAccessible
{
  if [[ $IS_ADMIN_ENT_ACC -eq 0 ]]; then
    if [[ $OS = "AIX" && $LDAP -eq 1 ]]; then
      ret=$(lsuser -R LDAP ALL  2>/dev/null)
      if [[ $? -eq 0 ]]; then
        IS_ADMIN_ENT_ACC=1
      else
        logInfo "Server $HOSTNAME ($OS) is not LDAP connected"
      fi  
    fi
    
    if [[ ($OS = "Linux" || $OS = "SunOS") && ($NOAUTOLDAP -eq 0 || $LDAP -eq 1)  ]]; then
      if [[ x"`getent passwd`" = x ]]; then
        logInfo "Server $HOSTNAME ($OS) is not support getent utility"   
      else
        IS_ADMIN_ENT_ACC=1    
      fi
    fi
  fi
  logDebug "IsAdminEntAccessible $IS_ADMIN_ENT_ACC"
  return 0
}

function check_pam
{
  if [ -e $LDAPCONF ]; then
    while read line; do 
      if echo "$line" | grep -i "^pam_check_host_attr" > /dev/null; then
        val=$(echo "$line" | sed -n 's/^pam_check_host_attr \(.*\)/\1/p')
        if [[ $val = "yes" ]]; then
          logDebug "pam_check_host_attr yes"
          return 1;
        fi   
      fi
    done < $LDAPCONF
  fi
  logDebug "pam_check_host_attr no"
  return 0
}

function process_LDAP_users
{
  IsPAM=0
  check_pam
  if  [[ $? -eq 1 ]]; then
    IsPAM=1
  fi
  #TLS
  attr_tls="/tmp/tls.out"
  if [[ $TLS -eq 0 ]]; then
      logDebug "Checking TLS certificate for LDAP BASE DN"
      DATA=`ldapsearch -x -H ldaps://$LDAPSVR:$LDAPPORT -b $LDAPBASE -Z > $attr_tls 2>&1`
      logDebug "Command used to get TLS users :ldapsearch -x -b $LDAPBASE -H ldaps://$LDAPSVR:$LDAPPORT -Z"
      cmd_res=$(grep "TLS already started" $attr_tls)
      if [[ $cmd_res != "" ]]; then
          logDebug "Found TLS already started in the output...considering TLS certificate enabled"
          TLS=1
      fi
  fi

  if [[ $TLS -eq 0 ]]; then
      logDebug "Checking TLS certificate for LDAP w/o BASE DN"
      DATA=$(ldapsearch -x -b -H ldaps://$LDAPSVR -Z > $attr_tls 2>&1)
      logDebug "Command used to get TLS users :ldapsearch -x -b -H ldaps://$LDAPSVR -Z"
      cmd_res=$(grep "TLS already started" "$attr_tls")
      if [[ $cmd_res != "" ]]; then
          logDebug "Found TLS already started in the output...considering TLS certificate enabled"
          TLS=1
      fi
  fi

  if [[ $TLS -eq 1 ]]; then
      logDebug "process_TLS_LDAP_users: "
      DATA=`ldapsearch -x -H ldaps://$LDAPSVR:$LDAPPORT -b $LDAPBASE >> /tmp/ldap_users`
      logDebug "Command used to get TLS users:ldapsearch -x -H ldaps://$LDAPSVR:$LDAPPORT -b $LDAPBASE "
  else
    if [[ $LDAPFILE = "" && $LDAPNULL -ne 1 ]]; then
      DATA=`$LDAPCMD -LLL -h $LDAPSVR -b $LDAPBASE -p $LDAPPORT uid=* uid userpassword uidNumber gidNumber loginShell gecos host description >> /tmp/ldap_users`
    elif [[ $LDAPNULL -eq 1 ]];then
	
		DATA=`$LDAPCMD -LLL  uid=* uid userpassword uidNumber gidNumber loginShell gecos host description >> /tmp/ldap_users`
		
	else
      DATA=`$LDAPCMD -LLL -h $LDAPSVR -b $LDAPBASE -p $LDAPPORT $LDAPADDITIONAL $LDAPUSERFILTER uid userpassword uidNumber gidNumber loginShell gecos host description >> /tmp/ldap_users`
    fi
  fi    
  if [[ $? -ne 0 ]]; then
    logAbort "unable access LDAP server"
  fi

  firsttime='true'
  userid=''
  passwd=''
  uid=''
  gid=''
  gecos=''
  shell=''
  checkHost=0
  
  while read line; do
    logDebug "process_LDAP_users->read line=$line"

    if echo "$line" | grep -i "uidNumber:" > /dev/null; then
      uid=$(echo "$line" | sed -n 's/^uidNumber: \(.*\)/\1/p')
    fi

    if echo "$line" | grep -i "gidNumber:" > /dev/null; then
      gid=$(echo "$line" | sed -n 's/^gidNumber: \(.*\)/\1/p')
    fi

    if echo "$line" | grep -i "userPassword::*" > /dev/null; then
      passwd=$(echo "$line" | sed -n 's/^userPassword::* \(.*\)/\1/p')
    fi

    if echo "$line" | grep -i "loginShell:" > /dev/null; then
      shell=$(echo "$line" | sed -n 's/^loginShell: \(.*\)/\1/p')
    fi

    if echo "$line" | grep -i "gecos:" > /dev/null; then
        gecos=$(echo "$line" | sed -n 's/^gecos: \(.*\)/\1/p')
      fi

    if echo "$line" | grep -i "description:" > /dev/null; then
      if [[ $gecos = "" ]]; then
        gecos=$(echo "$line" | sed -n 's/^description: \(.*\)/\1/p')
      fi
    fi

    if echo "$line" | grep -i "uid:" > /dev/null; then
      userid=$(echo "$line" | sed -n 's/^uid: \(.*\)/\1/p')
    fi

    if echo "$line" | grep -i "host:" > /dev/null; then
      host=$(echo "$line" | sed -n 's/^host: \(.*\)/\1/p' | tr "[:upper:]" "[:lower:]")
      if [[ $IsPAM -eq 1 && ($host = "$HOST" || $host = "$LONG_HOST_NAME") ]]; then
        checkHost=1
        logDebug "process_LDAP_users userhost=$host"
      fi  
    fi
    
    if echo "$line" | grep -i "dn: " > /dev/null; then
      if [[ $firsttime = 'true' ]]; then
        firsttime='false'
        continue
      fi
      if [[ $OS = "AIX" ]]; then
        testvar=0
        AGet LDAP_users ${userid} testvar
        if [[ $testvar -eq 1 ]]; then
          echo "$userid:$passwd:$uid:$gid:$gecos::$shell" >> $LDAPPASSWD
        else
          logDebug "process_LDAP_users: skip user $userid"
        fi  
      else  
        if [[ $IsPAM -eq 1 ]]; then
          if [[ $checkHost -eq 1 ]]; then 
            echo "$userid:$passwd:$uid:$gid:$gecos::$shell" >> $LDAPPASSWD
          else
            logDebug "process_LDAP_users: skip user $userid"
          fi  
        else
          echo "$userid:$passwd:$uid:$gid:$gecos::$shell" >> $LDAPPASSWD          
        fi  
          checkHost=0
      fi
        
      logDebug "process_LDAP_users->processed userid=$userid passwd=$passwd uid=$uid gid=$gid gecos=$gecos shell=$shell"

      passwd=""
      uid=""
      gid=""
      gecos=""
      shell=""
    fi
    done < /tmp/ldap_users

  if [ -n "$userid" ]; then
    if [[ $OS = "AIX" ]]; then
      testvar=0
      AGet LDAP_users ${userid} testvar
      if [[ $testvar -eq 1 ]]; then
        echo "$userid:$passwd:$uid:$gid:$gecos::$shell" >> $LDAPPASSWD
      else
        logDebug "process_LDAP_users: skip user $userid"
      fi  
    else  
      if [[ $IsPAM -eq 1 ]]; then
        if [[ $checkHost -eq 1 ]]; then 
      echo "$userid:$passwd:$uid:$gid:$gecos::$shell" >> $LDAPPASSWD
        else
          logDebug "process_LDAP_users: skip user $userid"
        fi  
      else
        echo "$userid:$passwd:$uid:$gid:$gecos::$shell" >> $LDAPPASSWD          
      fi  
    fi
  fi

  if [ -e /tmp/ldap_users ]; then
    rm /tmp/ldap_users
  fi
}

function findSudoersFile
{
  SUDOERFILE="/dev/null"
  SUDOERFILE1="/etc/sudoers"
  SUDOERFILE2="/opt/sfw/etc/sudoers"
  SUDOERFILE3="/usr/local/etc/sudoers"
  SUDOERFILE4="/opt/sudo/etc/sudoers"
  SUDOERFILE5="/opt/sudo/etc/sudoers/sudoers"
  SUDOERFILE6="/usr/local/etc/sudoers/sudoers"
  SUDOERFILE7="/opt/sudo/sudoers"

  if [ -r $SUDOERFILE1 ]; then
    SUDOERFILE=$SUDOERFILE1
  elif [ -r $SUDOERFILE2 ]; then
    SUDOERFILE=$SUDOERFILE2
  elif [ -r $SUDOERFILE3 ]; then
    SUDOERFILE=$SUDOERFILE3
  elif [ -r $SUDOERFILE4 ]; then
    SUDOERFILE=$SUDOERFILE4
  elif [ -r $SUDOERFILE5 ]; then
    SUDOERFILE=$SUDOERFILE5
  elif [ -r $SUDOERFILE6 ]; then
    SUDOERFILE=$SUDOERFILE6
  elif [ -r $SUDOERFILE7 ]; then
    SUDOERFILE=$SUDOERFILE7
  fi
}

function check_nisplus
{
  if [ -s "/var/nis/NIS_COLD_START" ]; then
   return 1
  fi
  return 0;  
}

ClearFile()
{
    declare FILE=$1
    
    echo "" > $FILE && rm $FILE
    if [[ $? -ne 0 ]]; then
      logMsg "WARNING" "Unable to open $FILE"
    fi
}

function Mef_Users_Post_Process
{
    declare outputFile=$1 ibmOnly=$2 customerOnly=$3 non_customer_only=$4
    
    isIbmUser=0
    returnCode=0
    iscustomerID=0
    logDebug "Report: mef_users_post_process: $ibmOnly===$customerOnly===$non_customer_only"
    if [[ $ibmOnly -eq 1 && $customerOnly -eq 1 && $non_customer_only -eq 1 ]]; then
        return 1
    fi
    
    if [[ $ibmOnly -eq 0 && $customerOnly -eq 0 && $non_customer_only -eq 0 ]]; then
        return 1
    fi
    
    baseMefName=$(basename "$outputFile")
    tmpOut="/tmp/${baseMefName}_tmp"
    
    if [[ -f "$outputFile" ]]; then
        # Storing file's data
        echo "" >> "$outputFile"
        cat "$outputFile" > "$tmpOut"
        echo "" >> "$tmpOut"
        
        # Clear the output file
        ClearFile "$outputFile"
        
        while read -r nextline; do
            if [[ $nextline != "" ]]; then
                isIbmUser=0
    		iscustomerID=0
                CUSTOMER_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[1];
                            }
                        ')
                        
                HOST_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[3];
                            }
                        ')
                        
                INSTANCE_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[4];
                            }
                        ')
                        
                USER_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[5];
                            }
                        ')
                        
                FLAG_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[6];
                            }
                        ')
                        
                DESCRIPTION_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[7];
                            }
                        ')
                        
                USERSTATE_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[8];
                            }
                        ')
                        
                USERLLOGON_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[9];
                            }
                        ')
                        
                GROUPS_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[10];
                            }
                        ')
                        
                ROLES_MEF3=$(echo "$nextline" | awk '
                            {
                                split($0, str, "|");
                                print str[11];
                            }
                        ')
                
                # 1. Checking on the signature record
                matched=$(echo "$nextline" | egrep "NOTaRealID" | wc -l)
                if [[ $matched -gt 0 ]]; then
                    echo "$nextline" >> $outputFile
                    continue
                fi
                
                # 2. Checking if user has this format <login name>@<location>.ibm.com
                SPECIAL_FLAG=$(echo $USER_MEF3 | grep -i '.*@.*\.ibm\.com')              
                SPECIAL_FLAG_K=$(echo $USER_MEF3 | grep -i '.*@kyndryl\.com')               
                if [[ ($SPECIAL_FLAG != "" || $SPECIAL_FLAG_K != "" ) && $ibmOnly -ne 0 ]]; then
                    echo "$nextline" >> $outputFile
                    continue
                fi
                
                if [[ $SPECIAL_FLAG != "" && $customerOnly -ne 0 ]]; then
                    continue
                fi
                #if [[ $non_customer_only -eq 0 ]]; then
				#	matched=$(echo "$DESCRIPTION_MEF3" | grep ".\{3\}\/[^\/]*\/[^\/]*\/[^\/]*\/.*" | wc -l)
				#	if [[ $matched -eq 0 ]]; then
				#		# description of the current userID doesn't contain URT format information in the description field
				#		USERGECOS_MEF3=$(GetURTFormat "$DESCRIPTION_MEF3")
				#	else
				#		USERGECOS_MEF3=$DESCRIPTION_MEF3
				#	fi
              	#fi
				#matched=$(echo "$USERGECOS_MEF3" | egrep -i "\w{2,3}\/[^\/]*\/[^\/]*\/[^\/]*\/.*" | wc -l)
                #if [[ $matched -ne 0 ]]; then
                matched=$(echo "$DESCRIPTION_MEF3" | egrep -i "\/([ISFTENK])\/" | wc -l)
                if [[ $matched -ne 0 ]]; then
                    isIbmUser=1
                fi
                
				matched=$(echo "$DESCRIPTION_MEF3" | egrep -i "\/([CV])\/" | wc -l)
                if [[ $matched -ne 0 ]]; then
					iscustomerID=1
				fi
                if [[ $iscustomerID -eq 0 && $non_customer_only -eq 1 ]]; then
					logDebug "Report: mef_users_post_process: except customerids :$nextline"
                    echo "$nextline" >> "$outputFile"
                    continue
                fi
				
                if [[ $isIbmUser -eq 1 && $ibmOnly -eq 1 ]]; then
					logDebug "Report: mef_users_post_process: kyndryl only ids :$nextline"
                    echo "$nextline" >> "$outputFile"
                    continue
                fi
                
                if [[ $isIbmUser -eq 0 && $customerOnly -eq 1 ]]; then
					logDebug "Report: mef_users_post_process: customer only ids :$nextline"
                    echo "$nextline" >> "$outputFile"
                    continue
                fi
            fi
        done < "$tmpOut"
    else
        return 2
    fi
    
    ClearFile "$tmpOut"
    logInfo "Finished .MEF3 report filtering"  
    return $returnCode
}

function Filter_mef3
 {
  logInfo "Started .MEF3 report filtering"
  logDebug "filter: OutputFile:$OUTPUTFILE"
  logDebug "filter: kyndrylOnly:$IBMONLY"
  logDebug "filter: customerOnly:$CUSTOMERONLY"
  logDebug "filter: customerOnly:$NONCUSTOMERONLY"

  if [[ $IBMONLY != 0 || $customeronly != 0 || $NONCUSTOMERONLY != 0 ]]; then
      Mef_Users_Post_Process $OUTPUTFILE $IBMONLY $CUSTOMERONLY $NONCUSTOMERONLY
  fi
}

function collect_LDAP_users_aix
{
  tmp_user_file="/tmp/ldapuser_tmp"
      
  if [[ $OS = "AIX" ]]; then
    attr=$(lsuser -R LDAP ALL > $tmp_user_file)
    while read nextline; do
      logDebug "collect_LDAP_users_aix: read $nextline"
      
      if echo "$nextline" | grep "registry=LDAP.*SYSTEM=.*LDAP" >/dev/null; then
        username=$(echo $nextline | awk '{ print $1 }')
        testvar=1
        AStore LDAP_users ${username} "$testvar"
        logDebug "collect_LDAP_users_aix: $username added "
      fi
    done < $tmp_user_file
    
    rm -f $tmp_user_file
  fi  
}

function getdomainname
{
  domain=""
  if [ -r /etc/resolv.conf ]; then  
    domain=$(awk '/^domain/ {print $2}' /etc/resolv.conf)
  fi
  
  #if [[ $domain = "" ]]; then
  #  domain=`nslookup $HOST | awk '/^Name:/{print $2}'`
  #  domain=${domain#*\.}
  #fi  
  echo "$domain" | tr "[:upper:]" "[:lower:]"
}
#####################################################################################################
# GSA
#####################################################################################################
function checkGSAconfig
{
  flag=0
  METHODCFG="/usr/lib/security/methods.cfg"
  
  logDebug "checkGSAconfig: check configuration"
  
  if [ $OS = "AIX" ]; then
      if [[ ! -z $(cat "$SECUSER"|grep SYSTEM|grep -v '*'|grep GSA) && ! -z $(cat $METHODCFG|grep -v ^*|grep GSA) ]]; then
        flag=1
      fi  
  fi  
  
  if [ $OS = "Linux" ]; then
    if [[ (! -z `cat /etc/nsswitch.conf|grep ldap` && ! -z `cat /etc/pam.d/*|grep "^\([[:space:]]\|[[:alnum:]]\).*gsa"`) || ! -z `grep "^\([[:space:]]\|[[:alnum:]]\).*gsa" /etc/security/*`  ]]; then
      flag=1
    fi  
  fi
  logDebug "checkGSAconfig: return value is $flag"
  return $flag
}

function GSALDAP
{
  logDebug "GSALDAP: get LDAP server address"
  
  LDAPSVR=""
  if [ -r $GSACONF ]; then
    LDAPSVR=$(awk '/^cellname/ {print $2}' $GSACONF |cut -d , -f1|tail -1)
    if [[ $LDAPSVR = "" ]]; then
      LDAPSVR=$(awk '/^ldaphost/ {print $2}' $GSACONF |cut -d , -f1|tail -1)
    fi  
  
    if [[ $LDAPSVR = "" ]]; then
      LDAPSVR=$(awk '/^host/ {print $2}' $GSACONF |cut -d , -f1|tail -1)
    fi  
  fi
   
  if [ -e $LDAPCONF ]; then
    if [[ $OS = "Linux" && $LDAPSVR = "" ]]; then
      LDAPSVR=$(awk '/^host/ {print $2}' $LDAPCONF |cut -d , -f1|tail -1)
    fi
  else
    logDebug "GSALDAP: $LDAPCONF not found"
  fi  
  logDebug "GSALDAP: LDAP server address is $LDAPSVR"
}

function getLDAPBASE
{
  logDebug "getLDAPBASE: start"
  
  gsabase=""
  
  if [ -r $GSACONF ]; then
    gsabase=$(cat $GSACONF|egrep '^base|^ldapbase'|awk '{print $2}')
  fi
  
  if [ -e $LDAPCONF ]; then
    if [[ $gsabase = "" ]]; then
      gsabase=$(cat $LDAPCONF|egrep '^base|^ldapbase'|awk '{print $2}')
    fi
  else
    logDebug "getLDAPBASE: $LDAPCONF not found"
  fi  
    
  if [[ $gsabase != "" ]]; then
    PEOPLEBASE="ou=People,$gsabase"
    GROUPBASE="ou=Group,$gsabase"
  fi
  
  if [ -e $LDAPCONF ]; then
    if [[ $OS = "Linux" && $gsabase = "" ]]; then
      PEOPLEBASE=$(awk '/^nss_base_passwd/ {print $2}' $LDAPCONF)
      PEOPLEBASE=${PEOPLEBASE%%*\?}
      GROUPBASE=$(awk '/^nss_base_group/ {print $2}' $LDAPCONF)
      GROUPBASE=${GROUPBASE%%*\?}
    fi
  else
    logDebug "getLDAPBASE: $LDAPCONF not found"
  fi  
    
  #not checked
  logDebug "getLDAPBASE:$PEOPLEBASE : $GROUPBASE"
}

function extractSudoUsersGroups
{
 declare tmp_sudo_file="/tmp/sudoersfile.tmp"
 rm -f $tmp_sudo_file

 preparsesudoers $SUDOERFILE $tmp_sudo_file
 
 DATA=`egrep -v "^[ ]*#" $tmp_sudo_file| sed 's/^\+\(.*\)/LDAP\/\1/g' | sed 's/^[    ]*//;s/[	 ]*$//'|sed -e :a -e '/\\\\$/N; s/\\\\\n//; ta'|sed 's/	/ /g'|tr -s '[:space:]'|sed '/^$/d'|sed 's/, /,/g'|sed 's/ ,/,/g'|sed 's/ =/=/g'|sed 's/= /=/g'>$TMPFILE` 

 while read nextline; do
   declare -a tokens=($(echo "$nextline"))
   case ${tokens[0]} in
     Cmnd_Alias ) continue ;;
     Runas_Alias )continue ;;
     Defaults )continue ;;
     ALL ) continue ;;
     Host_Alias ) continue ;;
     User_Alias )
     declare -a UAtokens=($(echo "$nextline"|sed 's/=/ /g'))
     tokenlist=${UAtokens[2]}
       
     IFS=,;for nexttoken in ${tokenlist}
     do
      if echo "$nexttoken" | grep "^%" >/dev/null; then
        group=`echo ${nexttoken}|tr -d %:`
        group=`trim "$group"`
        if [[ $gsagrouplist = "" ]]; then
          gsagrouplist="$group"
        else  
         if echo "$gsagrouplist" | grep -v "$group" > /dev/null; then
           gsagrouplist=$gsagrouplist",$group"
         fi  
        fi  
      fi  
     done   
     IFS=" "
      continue 
     ;;
     * )
     for nexttoken in ${nextline}
     do
       tokenlist=${tokens[0]}
       IFS=,;for nexttoken in ${tokenlist}
       do
        if echo "$nexttoken" | grep "^%" >/dev/null; then
          group=`echo ${nexttoken}|tr -d %:`
          group=`trim "$group"`
          if [[ $gsagrouplist = "" ]]; then
            gsagrouplist="$group"
          else  
           if echo "$gsagrouplist" | grep -v "$group" > /dev/null; then
             gsagrouplist=$gsagrouplist",$group"
           fi  
          fi  
        fi  
       done   
     done
     IFS=" "
 ;;
 esac
 done < $TMPFILE
 
 rm -f $tmp_sudo_file
}

function getGSAgroup
{
  grouplist=$1
  logDebug "getGSAgroup: starting: $grouplist"
  echo "" > $LDAPGROUP&& rm $LDAPGROUP
  oIFS=$IFS
  IFS=,
  declare -a groupz=($(echo "$grouplist"))
  IFS=$oIFS
  for gsagroup in "${groupz[@]}"
  do
    logDebug "getGSAgroup: get gsagroup $gsagroup information"
    $LDAPCMD -LLL -h $LDAPSVR -b "$GROUPBASE" cn="$gsagroup" cn gidNumber memberUid > /tmp/gsatmp.tmp
    if [[ $? -ne 0 ]]; then
      logAbort "accessing LDAP server $($?)"
    fi
    
    gidNumber=""
    memberUid=""
    
    while read line; do
      
      logDebug "getGSAgroup: line=$line"
      
      if echo "$line" | grep -i "gidNumber:" > /dev/null; then
        gidNumber=$(echo "$line" | sed -n 's/^gidNumber: \(.*\)/\1/p')
        logDebug "getGSAgroup: gidNumber=$gidNumber"
        continue
      fi

      if echo "$line" | grep -i "memberUid:" > /dev/null; then
        tempUid=$(echo "$line" | sed -n 's/^memberUid: \(.*\)/\1/p')
        logDebug "getGSAgroup Add ID $tempUid" 
        testvar=1
        AStore MEMBERS ${tempUid} "$testvar"
        if [[ $memberUid = "" ]]; then
          memberUid="$tempUid"
        else
          memberUid="$memberUid,$tempUid"
        fi
        logDebug "getGSAgroup: memberUid=$memberUid"
        continue
      fi
    done </tmp/gsatmp.tmp
    
    echo "$gsagroup:!:$gidNumber:$memberUid" >> $LDAPGROUP
    logDebug "getGSAgroup:groupfile->$gsagroup:!:$gidNumber:$memberUid"
  done
  #IFS=$oIFS
  rm /tmp/gsatmp.tmp
}

function getGroupGID
{
  group=$1
  $LDAPCMD -LLL -h $LDAPSVR -b "$GROUPBASE" cn="$group" gidNumber > /tmp/getGroupGID.tmp
  if [[ $? -ne 0 ]]; then
    logAbort "accessing LDAP server $($?)"
  fi
  tempGid=""
  while read str
  do
    if echo "$str" | grep -i "gidNumber:" > /dev/null; then
      tempGid=$(echo "$str" | sed -n 's/^gidNumber: \(.*\)/\1/p')
      break
    fi
  done < /tmp/getGroupGID.tmp
  rm /tmp/getGroupGID.tmp
  echo "$tempGid"  
}

function getAdditionalGroup
{
  AGetAll MEMBERS keys
  for gsauid in "${keys[@]}"
  do
    logDebug "getAdditionalGroup: uid=$gsauid"
    $LDAPCMD -LLL -h $LDAPSVR -b "$GROUPBASE" memberUid="$gsauid" cn > /tmp/getAdditionalGroup.tmp
    while read line
    do
      logDebug "getAdditionalGroup:$line"
      if echo "$line" | grep -i "cn:" > /dev/null; then
        gsagroup=$(echo "$line" | sed -n 's/^cn:\(.*\)/\1/p')
        gsagroup=`trim "$gsagroup"`
        gidNumber=`getGroupGID "$gsagroup"`
        logDebug "getAdditionalGroup: gsagroup=$gsagroup, gidNumber=$gidNumber"
        echo "$gsagroup:!:$gidNumber:$gsauid" >> $LDAPGROUP
        continue
      fi
    done < /tmp/getAdditionalGroup.tmp
  done
  rm /tmp/getAdditionalGroup.tmp
}

function getGSAuser
{
  logDebug "getGSAuser: starting"
  
  AGetAll MEMBERS keys 
    
  for gsauid in "${keys[@]}"
  do  
    logDebug "getGSAuser: gsauid=$gsauid"
    $LDAPCMD -LLL -h $LDAPSVR -b "$PEOPLEBASE" uid="$gsauid" uniqueIdentifier cn > /tmp/getGSAuser.tmp
    
    uniqueIdentifier="";
    cn="";

    while read line
    do    
      logDebug "getGSAuser: line=$line"
      if echo "$line" | grep -i "uniqueIdentifier:" > /dev/null; then
        uniqueIdentifier=$(echo "$line" | sed -n 's/^uniqueIdentifier: \(.*\)/\1/p')
        logDebug "getGSAuser: uniqueIdentifier=$uniqueIdentifier"
        continue
      fi
      
      if echo "$line" | grep -i "cn:" > /dev/null; then
        cn=$(echo "$line" | sed -n 's/^cn: \(.*\)/\1/p')
        cn=$(trim "$cn")
        logDebug "getGSAuser: cn=$cn"
      fi  
    done < /tmp/getGSAuser.tmp
    
    if [[ $uniqueIdentifier = "" ]]; then
      continue
    fi  
    
    CC=$(echo $uniqueIdentifier|cut -c7-9)
    SN=$(echo $uniqueIdentifier|cut -c1-6)
    
    IDs=$(id -u $gsauid)
    IDs=$(trim "$IDs")
    GROUPID=$(id -g $gsauid)
    GROUPID=$(trim "$GROUPID")
    
    echo "$gsauid:!:$IDs:$GROUPID:$CC/K/$SN/Kyndryl/$cn-GSA::" >> $LDAPPASSWD
    logDebug "getGSAuser:passwd->$gsauid:!:$IDs:$GROUPID:$CC/K/$SN/Kyndryl/$cn-GSA::"
  done
  rm /tmp/getGSAuser.tmp
}


function collectGSAusers
{
  logDebug "collectGSAusers: started"
  
  GSALDAP
  if [[ $LDAPSVR = "" ]]; then 
    logAbort "LDAP server address not found"
  fi 
  
  getLDAPBASE
  
  if [ -r $GSACONF ]; then
    gsagrouplist=`cat $GSACONF | grep "^gsagroupallow" | sed "s/gsagroupallow //g"|sed "s/,/ /g"`
    logDebug "collectGSAusers: gsagrouplist = $gsagrouplist"
  fi  
  
  if [ -e $LDAPCONF ]; then
    if [[ $OS = "Linux" && $gsagrouplist = "" ]]; then
      gsagrouplist=`cat $LDAPCONF|grep "^gsagroupallow" |sed "s/gsagroupallow //g"|sed "s/,/ /g"`
    fi
  else
    logDebug "collectGSAusers: $LDAPCONF not found"
  fi  
  
  if [[ $gsagrouplist = "" ]]; then
    for groupid in "${keys[@]}"
    do
      if [[ $gsagrouplist = "" ]]; then
        gsagrouplist="$groupid"
      else  
        gsagrouplist=$gsagrouplist",$groupid"
      fi  
    done        
    extractSudoUsersGroups
  fi
  
  logDebug "collectGSAusers: gsagrouplist = $gsagrouplist"

  if [[ $gsagrouplist = "" ]]; then
    logAbort "Can't get GSA group list"
  fi

  getGSAgroup "$gsagrouplist"
  getGSAuser
  
  if [[ $gsagrouplist != "" ]]; then
    getAdditionalGroup 
  fi
  
  logDebug "collectGSAusers: finished"
}  

function getTimeZone
{
    declare RAWTIMEZONE=""
    declare TIMEZONE
    declare sign
    declare hours
    declare minutes
    declare tz
    if [ $OS != 'HP-UX' ]; then
        RAWTIMEZONE=$(date +%z)
        if [ $OS = "AIX" ]; then
            sign=$(echo $RAWTIMEZONE|cut -c4-4) 
            hours=$(echo $RAWTIMEZONE|cut -c5-6) 
            minutes=$(echo $RAWTIMEZONE|cut -c8-9) 
        else
            sign=$(echo $RAWTIMEZONE|cut -c1-1) 
            hours=$(echo $RAWTIMEZONE|cut -c2-3) 
            minutes=$(echo $RAWTIMEZONE|cut -c4-5) 
        fi
        if [[ $sign != '+' && $sign != '-' ]];then
            sign=''
        else
            if [[ $minutes -gt 0 ]];then     
                tz=$(echo $hours+$minutes/60 | bc -l | sed 's/0*//g')
            else
                tz=$(echo $hours | bc -l)
            fi
        fi
        TIMEZONE=$(echo $sign$tz)
    else
        _time_zone_abbr=`date +%Z`
        if test "X$_time_zone_abbr" = "X"; then
            # abbreviation was not found
            return
        fi
        # /usr/lib/tztab
        # This file contains sections. Each section has a header in format:
        # tznamediffdstzname
        # where
        # tzname - time zone name or abbreviation
        # diff - difference in hours from UTC
        # dstzname - name of "Daylight Savings" time zone
        # Fractional values of diff are expressed in minutes preceded by a
        # colon.  Each such string will start with an alphabetic character.
        #
        # The second and subsequent lines of each entry details the time zone
        # adjustments for that time zone.  The lines contain seven fields each.
        # The first six fields specify the first minute in which the time zone
        # adjustment, specified in the seventh field, applies.  The fields are
        # separated by spaces or tabs.
        #
        # The seventh field is a string that describes the time zone adjustment
        # in its simplest form: tznamediff where tzname is an alphabetic string
        # giving the time zone name or abbreviation, and diff is the difference
        # in hours from UTC.  tzname must match either the tzname field or the
        # dstzname field in the first line of the time zone adjustment entry.
        # Any fractional diff is shown in minutes.
        # Comments begin with a # in the first column, and include all
        # characters up to a new-line.  Comments are ignored.
        # If the value of the TZ string does not match any line in the table, it
        # is interpreted according to the current U.S. pattern. ???

        tztab_location="/usr/lib/tztab"

        if test ! -f $tztab_location; then
            # file with info about timezones is not found
            # there is only way to parse TZ variable
            return
        fi

        # 1) need to compare it with current TIMEZONE ($TZ)
        # 2) if TZ is empty (unset) just get the latest occurence
        _block=0

        if test "X$TZ" != "X"; then

            while read -r line; do

                line=`echo $line | sed -e 's/#.*//'`

                if test "X$line" = "X$TZ"; then
                    _block=1
                    continue
                fi

                test $_block -ne 1 && continue

                # end of the block
                # storing the cached value and exit
                test $_block -eq 1 -a "X$line" = "X" && break

                # Read all entries in the section.
                # Section may contain normal and DS values.
                # On the available machines the latest line is the current one

                # A negative value is interpreted as minutes EAST fromd UTC!!!
                _tmp_val=`echo $line | \
                    awk "\\$7 ~ /^${_time_zone_abbr[0-9:-]}*\\$/ {

                        _value=\\$7;
                        sub(/$_time_zone_abbr/, \"\", _value)

                        _sign = \"-\"

                        if (match(_value, /^-/)) {
                            _sign = \"+\"
                            sub(/^-/, \"\", _value)
                        }

                        _offset = \"\"

                        if (match(_value, /:/)) {

                            split(_value, arr, \":\")

                            _hours = arr[1]
                            _minutes = sprintf(\"%0.2f\", arr[2] / 60)

                            if (_minutes == 0) {

                                if (_hours == 0) {
                                    _sign = \"+\"
                                }

                                _offset = _sign _hours

                            } else {

                                _offset = _sign _hours + _minutes

                            }

                        } else {

                            if (_value == 0) {
                                _sign = \"+\"
                            }

                            _offset = _sign _value
                        }

                        print _offset

                    }"`

                if test "X$_tmp_val" != "X"; then
                    _time_zone_diff=$_tmp_val
                fi

            done < $tztab_location

        else
            # just read all lines in tzdata and get the latest one with the same
            # timezone name
            _time_zone_diff=`cat $tztab_location | \

                sed -e 's/#.*//' | \
                awk "\\$7 ~ /^${_time_zone_abbr[0-9:-]}*\\$/ {

                    _value=\\$7;
                    sub(/$_time_zone_abbr/, \"\", _value)

                    _sign = \"-\"

                    if (match(_value, /^-/)) {
                        _sign = \"+\"
                        sub(/^-/, \"\", _value)
                    }

                    _offset = \"\"

                    if (match(_value, /:/)) {

                        split(_value, arr, \":\")

                        _hours = arr[1]
                        _minutes = sprintf(\"%0.2f\", arr[2] / 60)

                        if (_minutes == 0) {

                            if (_hours == 0) {
                                _sign = \"+\"
                            }

                            _offset = _sign _hours

                        } else {

                            _offset = _sign _hours + _minutes

                        }

                    } else {

                        if (_value == 0) {
                            _sign = \"+\"
                        }

                        _offset = _sign _value
                    }

                    print _offset

                }" | \
                tail -n 1`

        fi
        if test "X$_time_zone_diff" != "X"; then
            _offset=`printf "%s\n" "$_time_zone_diff" | sed -e 's/:/./'`
        fi
        TIMEZONE="$_offset"
    fi
    echo "$TIMEZONE"
}

function CleanArrays
{  
  AUnset primaryGroupUsers
  AUnset PasswdUser
  AUnset groupGIDName
  AUnset ALLGroupUsers
  AUnset AllUserGroups
  AUnset privUserGroups
  AUnset privUser
  AUnset Ullogon
  AUnset sudoUsers
  AUnset sudoGroups
  AUnset sudoUserGroups
  AUnset aliasUsers
  AUnset validHostAlias
  AUnset Netgrplist    
  AUnset UserAlias
  AUnset AliasOfAlias
  AUnset AliasList
}

function Report_UAT
{
  IsMaster=0
  UATStr=""
  
  serveraddr=$(ypwhich 2>/dev/null)

  if [[ $? -eq 0 ]]; then
    serveraddr=$(trim $serveraddr)
    if [[ $serveraddr = "" ]]; then
      logMsg "WARN" "NIS server address is empty"
      EXIT_CODE=1
      return 1 
    fi
    logDebug "Report_UAT: found NIS serveraddr $serveraddr"
    CompareAddr "$serveraddr"
    if [[ $? -eq 0 ]]; then
      UATStr="NIS_MASTER_SERVER"
    else  
      UATStr="NIS_MEMBER_SERVER:$serveraddr"
    fi
    logDebug "Report_UAT: return string $UATStr"
    return 0
  elif [[ $OS = "SunOS" ]]; then
    outstr=$(ldapclient list 2>/dev/null)
    if [[ $? -ne 0 ]]; then
      logMsg "WARN" "Error reading LDAP info"
      EXIT_CODE=1
      return 1
    fi

  oFS=$IFS
  IFS="
";for line in $outstr
  do
    if echo "$line" | grep "NS_LDAP_SERVERS" > /dev/null; then
      serveraddr=$(echo $line|cut -d"=" -f2)
      serveraddr=$(trim $serveraddr)
      logDebug "Report_UAT: serveraddr $serveraddr"
      CompareAddr "$serveraddr"
      if [[ $? -eq 0 ]]; then
        IsMaster=1
      fi
      break
    fi
  done
  IFS=$oFS
  elif [[ $OS = "Linux" ]]; then
    serveraddr=$(cat "/etc/openldap/ldap.conf" | egrep '^URI' | sed -n 's/^URI \(.*\)/\1/p')
    if [[ $serveraddr != "" ]]; then
      serveraddr=$(echo "$serveraddr" | sed 's/ldap:\/\///g')
      logDebug "Report_UAT: serveraddr $serveraddr"
      CompareAddr "$serveraddr"
      if [[ $? -eq 0 ]]; then
        IsMaster=1
      fi
    else
      logMsg "WARN" "No LDAP server address in ldap.conf"
      EXIT_CODE=1
      return 1
    fi
  elif [[ $OS = "AIX" ]]; then
    secldapsrv=$(ls-secldapclntd 2>/dev/null)
    if [[ $? -ne 0 ]]; then
      logMsg "WARN" "Error reading LDAP info"
      EXIT_CODE=1
      return 1
    fi
    oFS=$IFS
    IFS="
    ";for line in $secldapsrv
    do
      if echo "$line" | grep -i "ldapservers=" > /dev/null; then
        serveraddr=$(echo $line|cut -d"=" -f2)
        serveraddr=$(trim $serveraddr)
        logDebug "Report_UAT: ls-secldapclntd $serveraddr"
        break  
      fi
    done  
    IFS=$oFS

    serveraddr2=$(cat "/etc/security/ldap/ldap.cfg" | egrep '^ldapservers:'|awk '{print $2}')
    if [[ $serveraddr2 = "" ]]; then
      logMsg "WARN" "No LDAP server address in ldap.cfg"
      EXIT_CODE=1
      return 1
    fi
    serveraddr="$serveraddr,$serveraddr2"
    logDebug "Report_UAT: serveraddr $serveraddr"
    
    CompareAddr "$serveraddr"
    if [[ $? -eq 0 ]]; then
      IsMaster=1  
    fi
  fi
  
  if [[ $IsMaster -eq 1 ]]; then
    UATStr="LDAP_MASTER_SERVER"
  elif [[ $serveraddr != "" ]]; then
    UATStr="LDAP_MEMBER_SERVER:$serveraddr"
  fi
  logDebug "Report_UAT: return string $UATStr"
  return 0
}

function CompareAddr
{
  cfg_addr=$(toLower "$1")
  cfg_addr=$(echo $cfg_addr | tr -d \/)
  local_addr=""
  
  logDebug "CompareAddr: cfg_addr $cfg_addr"
  local_addr=${LONG_HOST_NAME%%.*}
  local_addr="$local_addr,$LONG_HOST_NAME"
  local_addr="$local_addr,localhost"
  
  #tmp_addr=`ifconfig -a | grep "inet " | awk '{print $2}' | sed 's/addr://'`
  tmp_addr=`ifconfig -a | grep "inet " | sed 's/addr://'|awk '{print $2}' | tr "\n" ","`
  tmp_addr=`trim $tmp_addr`
  #tmp_addr=`echo $tmp_addr | tr "\n" ","`
  logDebug "CompareAddr: local address $tmp_addr"
  if [[ $tmp_addr != "" ]]; then
    local_addr="$tmp_addr$local_addr"
  fi
  logDebug "CompareAddr: local address $local_addr"
  
  oFS=$IFS
  IFS=,;for cfg_a in $cfg_addr
  do
    cfg_a=$(trim "$cfg_a")
    for local_a in $local_addr
    do
      logDebug "CompareAddr: compare local addr $local_a, config addr $cfg_a"
      if [[ $local_a = "$cfg_a" ]]; then
        logDebug "CompareAddr: found local addr $local_a, config addr $cfg_a"
        IFS=$oFS
        return 0
      fi
    done
  done  
  IFS=$oFS
  logDebug "CompareAddr: not found local addr $local_addr, config addr $cfg_addr"
  return 1
}

#####################################################################################################
## MAIN
#####################################################################################################
OS=$(uname -a|cut -d" " -f1)
if [[ $OS = "AIX" ]]; then
  if [[ -e "/usr/ios/cli/ioscli" ]]; then
    logDebug "VIO"
    OS="VIO";
  fi
fi

matched=$(uname -v | grep -i photon | wc -l)
if [[ $matched -gt 0 ]]; then
	logDebug "PHOTON OS detected:`uname -v`"
	PHOTON_FLAG=1
	OS_PHOTON="$OS-PHOTON"
fi  
PERL=`which perl`

#SCRIPTNAME=$0
SCRIPTNAME=$(echo $0 | sed -e 's/ /\\\ /g')
CKSUM=$(eval cksum $SCRIPTNAME | awk '{ print $1 }')

logHeader
 
date=$(date +%d%b%Y)
DATE=$(echo $date | tr -d ' ' | tr "[:upper:]" "[:lower:]")
myAUDITDATE=$(date +%Y-%m-%d-%H.%M.%S)
findSudoersFile
PASSWDFILE="/etc/passwd"
GROUPFILE="/etc/group"

HOST=$(hostname)
LONG_HOST_NAME=$HOST
HOST=${LONG_HOST_NAME%%.*}
HOSTNAME=$HOST

if [ $HOST = $LONG_HOST_NAME ]; then
DOMAINNAME=$(getdomainname)
if [[ $DOMAINNAME != "" ]]; then
  LONG_HOST_NAME=$HOST".$DOMAINNAME"
  fi
fi  

HOST=$(echo "$HOST" | tr "[:upper:]" "[:lower:]")
LONG_HOST_NAME=$(echo "$LONG_HOST_NAME" | tr "[:upper:]" "[:lower:]")

ENABLEFQDN=1
TMPFILE="/tmp/iam_extract.tmp"       #4.2 Updated to keep tmpfile in /tmp
CUSTOMER="Kyndryl"
OUTPUTFILE="/tmp/$CUSTOMER""_""$DATE""_""$HOST.mef"

USERCC="897"
NETGROUP=0
LDAP_NETGOUP_TMP="/tmp/ldap_netgroup.tmp"

GSACONF="/usr/gsa/etc/gsa.conf"
LDAPCONF="/etc/ldap.conf"

uname=$(uname)
export uname

if [ -f /bin/sudo ]; then
  SUDOCMD="/bin/sudo"
  SUDOVER=$($SUDOCMD -V|grep -i 'Sudo version'|cut -f3 -d" ")
  logInfo "SUDO Version: $SUDOVER"
elif [ -f /usr/bin/sudo ]; then
  SUDOCMD="/usr/bin/sudo"
  SUDOVER=$($SUDOCMD -V|grep -i 'Sudo version'|cut -f3 -d" ")
  logInfo "SUDO Version: $SUDOVER"
elif [ -f /usr/local/bin/sudo ]; then
  SUDOCMD="/usr/local/bin/sudo"
  SUDOVER=$($SUDOCMD -V|grep -i 'Sudo version'|cut -f3 -d" ")
  logInfo "SUDO Version: $SUDOVER"
elif [ -f /usr/local/sbin/sudo ]; then
  SUDOCMD="/usr/local/sbin/sudo"
  SUDOVER=$($SUDOCMD -V|grep -i 'Sudo version'|cut -f3 -d" ")
  logInfo "SUDO Version: $SUDOVER"
else
  SUDOVER="NotAvailable"
  logMsg "WARNING" "unable to get Sudo Version:$SUDOVER."
  EXIT_CODE=1
fi

if [[ $OS = "AIX" || $OS = "VIO" ]]; then
  SECUSER="/etc/security/user"
  SPASSWD="/etc/security/passwd"
elif [[ $OS = "HP-UX" ]]; then
  SECUSER=""
  SPASSWD="/etc/shadow"
elif [[ $OS = "SunOS" ]]; then
  SECUSER=""
  SPASSWD="/etc/shadow"
elif [[ $OS = "Linux" ]]; then
  SECUSER=""
  SPASSWD="/etc/shadow"
else
  SECUSER=""
  SPASSWD="/etc/shadow"
fi

SCMFORMAT="0"
MEF2FORMAT="0"
NEWOUTPUTFILE=""
NIS=0
LDAP=0
ldap_tmp="/tmp/iam_temp"
ldap_tmp1="/tmp/iam_temp1"
CENTRTMP="/tmp/centr_temp"
NOAUTOLDAP=0
CUSTOMERONLY=0
NONCUSTOMERONLY=0
IBMONLY=0
OWNER=""
DLLD=0
NOGSA=0
LDAPFILE=""
LDAPBASEGROUP=""
LDAPGROUPOBJCLASS=""
LDAPADDITIONAL=""
NISPLUSDIR=""
VPREFIX=""
MEF4FORMAT=0
USERSPASSWD=0
USEROSNAME=0
SIGNATURE=""
IS_ADMIN_ENT_ACC=0
UAT=0
#TLS
TLS=0
RHELIDMIPA=0 #V9.7.0 added

c=0
for var in "$@"
do
  argums[$c]=$var   
  let "c+=1"
done
c=0
while ((c<${#argums[*]}))
do
  case "${argums[$c]}" in
  -f ) 
    let "c+=1"
    SUDOERFILE="${argums[$c]}"
    KNOWPAR=$(echo "$KNOWPAR -f ${argums[$c]}#")
    ;;
  -g ) 
    let "c+=1"
    GROUPFILE="${argums[$c]}"
    NOAUTOLDAP=1
    KNOWPAR=$(echo "$KNOWPAR -g ${argums[$c]}#")
    ;;
  -p ) 
    let "c+=1"
    PASSWDFILE="${argums[$c]}"
    NOAUTOLDAP=1
    KNOWPAR=$(echo "$KNOWPAR -p ${argums[$c]}#")
    ;;
  -r ) 
    let "c+=1"
    NEWOUTPUTFILE="${argums[$c]}"
    KNOWPAR=$(echo "$KNOWPAR -r ${argums[$c]}#")
    ;;
  -c ) 
    let "c+=1"
    CUSTOMER="${argums[$c]}"
    KNOWPAR=$(echo "$KNOWPAR -c ${argums[$c]}#")
    ;;
  -mef3x ) 
    let "c+=1"
    MEF3X=1
    Dormant="${argums[$c]}"
    Dormant=`echo "$Dormant" | tr '[:lower:]' '[:upper:]'`
    KNOWPAR=$(echo "$KNOWPAR -mef3x ${argums[$c]}#")
    ;;
  -o ) 
    let "c+=1"
    OS="${argums[$c]}"
    USEROSNAME=1
    KNOWPAR=$(echo "$KNOWPAR -o ${argums[$c]}#")
    ;;
  -s ) 
    let "c+=1"
    SPASSWD="${argums[$c]}"
    USERSPASSWD=1
    KNOWPAR=$(echo "$KNOWPAR -s ${argums[$c]}#")
    ;;
  -u ) 
    let "c+=1"
    SECUSER="${argums[$c]}"
    KNOWPAR=$(echo "$KNOWPAR -u ${argums[$c]}#")
    ;;
  -m ) 
    let "c+=1"
    LONG_HOST_NAME="${argums[$c]}"
    HOSTNAME=$LONG_HOST_NAME
    HOST=${LONG_HOST_NAME%%.*}
    ENABLEFQDN=0
    KNOWPAR=$(echo "$KNOWPAR -m  ${argums[$c]}#")
    ;;
  -d ) 
    DEBUG="1"
    KNOWPAR=$(echo "$KNOWPAR -d#")
    ;;
  -S ) 
    SCMFORMAT="1"
    KNOWPAR=$(echo "$KNOWPAR -S#")
    ;;
  -M ) 
    MEF2FORMAT="1"
    KNOWPAR=$(echo "$KNOWPAR -M#")
    ;;
  -P ) 
    let "c+=1"
    PRIVFILE="${argums[$c]}"
    KNOWPAR=$(echo "$KNOWPAR -p ${argums[$c]}#")
    ;;
  -n )                     #4.3 Custom Signature
    let "c+=1"
    SIG=`echo "${argums[$c]}" | tr "[:upper:]" "[:lower:]"`
    KNOWPAR=$(echo "$KNOWPAR -n ${argums[$c]}#")
    ;;
  -i )
    let "c+=1"
    SIGNATURE=`echo "${argums[$c]}"`
    KNOWPAR=$(echo "$KNOWPAR -i ${argums[$c]}#")
    ;;
   -N )    
    let "c1=$c+1"
    if [ $c1 -lt ${#argums[*]} ]; then
      if echo "${argums[$c1]}" | grep  "^-" >/dev/null; then
        NISPLUSDIR=""
        KNOWPAR=$(echo "$KNOWPAR -N#")
      else
        NISPLUSDIR=".${argums[$c1]}"
        KNOWPAR=$(echo "$KNOWPAR -N $NISPLUSDIR#")
        c=$c1
      fi  
    fi  
    NISPLUSDIR=""
    NIS=1
    NOAUTOLDAP=1
    ;;
  -L )
    LDAP=1
    NOAUTOLDAP=1
    let "c+=1"
    if echo "${argums[$c]}" | grep  "\:" >/dev/null; then
      LDAPSVR=`echo "${argums[$c]}" | awk -F: '{ print $1 }'`
      LDAPPORT=`echo "${argums[$c]}" | awk -F: '{ print $2 }'`
      LDAPBASE=`echo "${argums[$c]}" | awk -F: '{ print $3 }'`
    else
     logAbort "-L ServerName/IP:port:BaseDN\neg: iam_extract_ibm.ksh -L 127.0.0.1:389:DC=IBM,DC=COM"
    fi
    LDAPP=$(echo "${argums[$c]}" | sed 's/\(-w \)[^ ]*/\1\*\*\*\*\*\*\*\*/')
    KNOWPAR=$(echo "$KNOWPAR -L $LDAPP#")
    ;;
  -l )
    let "c+=1"
    LDAP=1
    NOAUTOLDAP=1
    LDAPFILE="${argums[$c]}"
    KNOWPAR=$(echo "$KNOWPAR -l ${argums[$c]}#")
    ;;
  -K )                      
    CUSTOMERONLY=1
    KNOWPAR=$(echo "$KNOWPAR -K#")
    ;;
  -I )                       
    IBMONLY=1
    KNOWPAR=$(echo "$KNOWPAR -I#")
    ;;
  -E )                      
    NONCUSTOMERONLY=1
    KNOWPAR=$(echo "$KNOWPAR -E#")
    ;;
  -4 )
    MEF4FORMAT=1
    KNOWPAR=$(echo "$KNOWPAR -4#")
    ;;
  -h|-help ) 
    echo
    echo "Version: $VERSION"
    echo "USAGE: iam_extract_global.sh [-f sudoers_file] [-r results_file] [-p passwd_file]"
    echo "                           [-g group_file] [-c customer] [-m hostname]" 
    echo "                           [-o ostype] [-s shadowfile] -u [secuserfile]" 
    echo "                           [-S] [-M] [-P privfile] [-n TSCM|SCR|TCM|FUS]" 
    echo "                           [-L <LDAP SERVER IP:Port:BASE DN>] [-N [<directory>]] [-v[<regexp>]] [-q] [-a]" 
    echo "                           [-K] [-I] [-O <owner>] [-D] [-G] [-d]" 
    echo "                           [-l <ldap_cfg_file>] [-4] [-e] [-i <signature>]" 
    echo
    echo "  -S   Change output file format to scm9, instead of mef3"
    echo "  -M   Change output file format to mef2, instead of mef3"
    echo "  -4   Change output file format to mef4, instead of mef3"
    echo "  -q   Use fully qualified domain name(FQDN)"
    echo "  -a   Fetch only local user IDs (Linux, Solaris)"
    echo "  -K   Flag to indicate if only Customer userID's should be written to the output"
    echo "  -I   Flag to indicate if only Kyndryl userID's should be written to the output"
	echo "  -E   Flag to exclude Customer userID's and rest of the IDs should be written to the output"
    echo "  -G   Disable GSA"
    echo "  -d   Debug mode"    
    echo "  -v   Vintela support"    
    echo "  -e   Centrify support"
#TLS
    echo "  -t   support LDAP TLS certificate"
    echo "  -mef3x   Flag to set Dormant values: 
on-on ... 12th attribute exists and is populated, last-login and last-password-change dates are in new standardized format. (on-on will be future default)
on-off ... 12th attribute exists but is not populated, last-login date is in new standardized format. (avoids unnecessary compute resource consumption)
off-off ... 12th attribute does not exist ... last-login-date is in legacy format (off-off is initial default to decouple AE compatibility timing)"
    echo
    echo " Defaults:"
    echo "     CUSTOMER: $CUSTOMER"
    echo "   SUDOERFILE: $SUDOERFILE"
    echo "   PASSWDFILE: $PASSWDFILE"
    echo "    GROUPFILE: $GROUPFILE"
    echo "  RESULTSFILE: $OUTPUTFILE"
    echo "   SHADOWFILE: $SPASSWD"
    echo "  SECUSERFILE: $SECUSER"
    echo "           OS: $OS(AIX|HP-UX|SunOS|Linux"
    echo "     HOSTNAME: $HOST"
    echo "        CKSUM: $CKSUM"
    echo
    echo " Output is mef format including SUDO privilege data."
    echo " User 'state' (enabled/disabled) is extracted if possible."
    exit 9
    ;;
  -q )                   
    FQDN=1
    KNOWPAR=$(echo "$KNOWPAR -q#")
    ;;
  -a )
    NOAUTOLDAP=1
    KNOWPAR=$(echo "$KNOWPAR -a#")
    ;;
  -A )
    LDAPNULL=1
    KNOWPAR=$(echo "$KNOWPAR -A#")
    ;;
  -O )        
    let "c+=1"           
    OWNER="${argums[$c]}"
    KNOWPAR=$(echo "$KNOWPAR -O ${argums[$c]}#")
    ;;
  -D )                   
    DLLD=1
    KNOWPAR=$(echo "$KNOWPAR -D#")
    ;;
  -G )                   
    NOGSA=1
    KNOWPAR=$(echo "$KNOWPAR -G#")
    ;;
  -v ) #vintela
    IS_ADMIN_ENT_ACC=2
    let "c1=$c+1"
    if [ $c1 -lt ${#argums[*]} ]; then
      if echo "${argums[$c1]}" | grep  "^-" >/dev/null; then
        VPREFIX=""
        KNOWPAR=$(echo "$KNOWPAR -v#")
      else
        KNOWPAR=$(echo "$KNOWPAR -v $VPREFIX#")
        VPREFIX="${argums[$c1]}[\\92\\|\\92\\92]"
        c=$c1
      fi  
    fi  
    ;;
  -e )#centrify     
    IS_ADMIN_ENT_ACC=3
    KNOWPAR=$(echo "$KNOWPAR -e#")
    ;;
  -w )#UAT
    UAT=1
    KNOWPAR=$(echo "$KNOWPAR -w#")
    ;;
  -t )#TLS
    TLS=1
    KNOWPAR=$(echo "$KNOWPAR -t#")
    ;;
   * )
 
    if [ $c -lt ${#argums[*]} ]; then
      UNKNOWPAR=$(echo "$UNKNOWPAR ${argums[$c]}#")
    fi
   ;; 
  esac
  let "c+=1"
done

if [[ $UAT -eq 1 && ($IS_ADMIN_ENT_ACC -eq 2 || $IS_ADMIN_ENT_ACC -eq 3) ]]
then
	UAT=0		
	logMsg "WARN" "-w switch is not allowed with -e and -v,So ignoring -w switch."
	EXIT_CODE=1
fi
if [[ $Dormant != "" || $MEF3X -eq 1 ]];then
	Dormant_values='^ON_ON$|^ON_OFF$|^OFF_OFF$'
	matched=$(echo $Dormant|egrep -i $Dormant_values|wc -l)
    	if [[ $matched -eq 0 ]]; then
		logMsg "WARN" "-mef3x switch values should be having (ON_ON,ON_OFF,OFF_OFF), Extractor won't support any other values."
		EXIT_CODE=1
   	fi
fi
DISTRNAME=`GetDistrName`
logDebug "GetDistrName: $DISTRNAME"
if [[ $DISTRNAME != "unknown" ]]; then
  DISTRVER=`GetDistrVer $DISTRNAME`
fi
logDebug "GetDistrVer: $DISTRVER"

IsAdminEntAccessible

if [[ $IS_ADMIN_ENT_ACC -eq 3 ]]; then
  logInfo "Flush the Centrify and nscd cache"
  /usr/sbin/adflush >/dev/null 2>&1
  logInfo "Flush completed, exit code $?"
fi

if [[ $OS = "AIX" ]]; then
  logInfo "Found AIX"
      PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^nuucp$|^lpd$|^imnadm$|^ipsec$|^ldap$|^lp$|^snapp$|^invscout$|^nobody$|^notes$|^esaadmin$|^pconsole$|^srvproxy$'
      PRIVGROUPS='^system$|^security$|^bin$|^sys$|^adm$|^uucp$|^mail$|^printq$|^cron$|^audit$|^shutdown$|^ecs$|^imnadm$|^ipsec$|^ldap$|^lp$|^haemrm$|^snapp$|^hacmp$|^notes$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$|^SSHD$|^sshd$|^invscout$|^pconsole$'

elif [[ $OS = "VIO" ]]; then
  logInfo "Found VIO"
  PRIVUSERS='^padmin$'
  PRIVGROUPS=''
  AStore ROLE "SYSAdm" "System Administrator"
  AStore ROLE "SRUser" "Service Representative"
  AStore ROLE "DEUser" "Development Engineer"
elif [[ $OS = "HP-UX" ]]; then
  logInfo "Found HP-UX"
    PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^lp$|^nuucp$|^hpdb$|^imnadm$|^nobody$|^notes$|^auth$|^cron$|^ris$|^tcb$|^uucpa$|^wnn$'
    PRIVGROUPS='^root$|^other$|^bin$|^sys$|^adm$|^daemon$|^mail$|^lp$|^tty$|^nuucp$|^nogroup$|^imnadm$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$|^notes$|^SSHD$|^sshd$|^auth$|^backup$|^cron$|^kmem$|^lpr$|^mem$|^news$|^operator$|^opr$|^ris$|^sec$|^sysadmin$|^system$|^tape$|^tcb$|^terminal$|^uucp$'
 
elif [[ $OS = "SunOS" || $OS = "Solaris" ]]; then
  logInfo "Found SunOS"
     PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^nuucp$|^imnadm$|^lp$|^smmsp$|^listen$|^nobody$|^notes$|^lpd$|^ipsec$|^snapp$|^invscout$|^aiuser$|^dhcpserv$|^dladm$|^ftp$|^gdm$|^ikeuser$|^mysql$|^netadm$|^netcfg$|^noaccess$|^openldap$|^pkg5srv$|^postgres$|^sms-svc$|^svctag$|^upnp$|^webservd$|^xvm$|^zfssnap$'
     PRIVGROUPS='^system$|^security$|^bin$|^sys$|^uucp$|^mail$|^imnadm$|^lp$|^root$|^other$|^adm$|^tty$|^nuucp$|^daemon$|^sysadmin$|^smmsp$|^nobody$|^notes$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$|^SSHD$|^sshd$|^printq$|^cron$|^audit$|^ecs$|^shutdown$|^ipsec$|^ldap$|^haemrm$|^snapp$|^hacmp$|^cimsrvr$|^ftp$|^gdm$|^mlocate$|^mysql$|^netadm$|^noaccess$|^openldap$|^pkg5srv$|^postgres$|^root$|^slocate$|^sms $|^staff$|^upnp$|^webservd$|^xvm$'

elif [[ $OS = "Linux" ]]; then
  logInfo "Found Linux"
  PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^nobody$|^notes$'
  PRIVGROUPS='^notes$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$|^wheel$|^SSHD$|^sshd$'
else
  logInfo "Found Unknown OS"
  PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^nuucp$|^lpd$|^imnadm$|^ipsec$|^ldap$|^lp$|^snapp$|^invscout$|^nobody$|^notes$|^hpdb$|^smmsp$|^listen$'
  PRIVGROUPS='^1bmadmin$|^adm$|^audit$|^bin$|^cron$|^daemon$|^db2admin$|^db2iadm1$|^dba$|^ecs$|^hacmp$|^haemrm$|^ibmadmin$|^imnadm$|^ipsec$|^ldap$|^lp$|^mail$|^mqm$|^nobody$|^nogroup$|^notes$|^nuucp$|^other$|^printq$|^root$|^sapsys$|^security$|^shutdown$|^smmsp$|^snapp$|^suroot$|^sys$|^sysadm$|^system$|^tty$|^uucp$|^wheel$|^SSHD$|^sshd$|^sudo$|^sysad$|^sysadmin$'
fi

if [[ $ENABLEFQDN -eq 1 && $FQDN -eq 1 ]]; then
  HOSTNAME=$LONG_HOST_NAME
fi

logDebug "init: host $HOST:$LONG_HOST_NAME"

if [[ $NEWOUTPUTFILE != "" ]]; then
  if echo "$NEWOUTPUTFILE" | grep "/" > /dev/null; then
    OUTPUTFILE=$NEWOUTPUTFILE
  else
    OUTPUTFILE="/tmp/$NEWOUTPUTFILE"
  fi
else
  if [[ $SCMFORMAT -eq 1 ]]; then
    OUTPUTFILE="/tmp/$CUSTOMER""_""$DATE""_""$HOSTNAME.scm9"
  elif [[ $MEF2FORMAT -eq 1 ]]; then
    OUTPUTFILE="/tmp/$CUSTOMER""_""$DATE""_""$HOSTNAME.mef"
  elif [[ $MEF4FORMAT -eq 1 ]]; then
    OUTPUTFILE="/tmp/$CUSTOMER""_""$DATE""_""$HOSTNAME.mef4"
  else
    OUTPUTFILE="/tmp/$CUSTOMER""_""$DATE""_""$HOSTNAME.mef3"
  fi
fi

LoadPrivfile $PRIVFILE

logDebug "PRIVSUSERS: $PRIVUSERS"
logDebug "PRIVSGROUPS: $PRIVGROUPS"

SEC_READABLE=1
if [ ! -r $SPASSWD ]; then
  logMsg "WARNING" "unable to read SPASSWD:$SPASSWD. Account state may be missing from extract"
  SEC_READABLE=0
  EXIT_CODE=1
fi

if [[ $OS = "AIX" ]]; then
  if [ ! -r $SECUSER ]; then
    logMsg "WARNING" "unable to read SECUSER:$SECUSER. Account state may be missing from extract"
    SEC_READABLE=0
    EXIT_CODE=1
  fi
fi

TCB_READABLE=0
if [[ $OS = "HP-UX" ]]; then
  #echo "CHECKING: /usr/lbin/getprpw."
  if [ ! -x /usr/lbin/getprpw ]; then
    logMsg "WARNING" "unable to execute /usr/lbin/getprpw. Account state may be missing from extract"
    TCB_READABLE=0
    EXIT_CODE=1
  else
    TCB_READABLE=1
  fi
fi

logDebug "TCB_READABLE: $TCB_READABLE"

if [ $SUDOERFILE = "/dev/null" ]; then
  logMsg "WARNING" "unable to find sudoers file.  Account SUDO privileges will be missing from extract"
  EXIT_CODE=1
elif [ ! -r $SUDOERFILE ]; then
  logMsg "WARNING" "unable to read SUDOERFILE:$SUDOERFILE file.  Account SUDO privileges will be missing from extract"
  EXIT_CODE=1
fi

if [ ! -r $GROUPFILE ]; then
logAbort "unable to read $GROUPFILE"
fi

if [ ! -r $PASSWDFILE ]; then
logAbort "unable to read $PASSWDFILE"
fi

echo "" > $OUTPUTFILE && rm $OUTPUTFILE
if [[ $? -ne 0 ]]; then
  logAbort "unable to open OUTPUTFILE:$OUTPUTFILE"
fi

echo "" > $TMPFILE && rm $TMPFILE
if [[ $? -ne 0 ]]; then
  logAbort "unable to open $TMPFILE"
fi

AStore MNames "Jul" "1"
AStore MNames "Aug" "2"
AStore MNames "Sep" "3"
AStore MNames "Oct" "4"
AStore MNames "Nov" "5"
AStore MNames "Dec" "6"
AStore MNames "Jan" "7"
AStore MNames "Feb" "8"
AStore MNames "Mar" "9"
AStore MNames "Apr" "10"
AStore MNames "May" "11"
AStore MNames "Jun" "12"

AStore MNames2 "01" "Jan" 
AStore MNames2 "02" "Feb" 
AStore MNames2 "03" "Mar" 
AStore MNames2 "04" "Apr"
AStore MNames2 "05" "May" 
AStore MNames2 "06" "Jun" 
AStore MNames2 "07" "Jul" 
AStore MNames2 "08" "Aug" 
AStore MNames2 "09" "Sep" 
AStore MNames2 "10" "Oct" 
AStore MNames2 "11" "Nov" 
AStore MNames2 "12" "Dec" 

AStore MonthNames "Jan" "01"
AStore MonthNames "Feb" "02"
AStore MonthNames "Mar" "03"
AStore MonthNames "Apr" "04"
AStore MonthNames "May" "05"
AStore MonthNames "Jun" "06"
AStore MonthNames "Jul" "07"
AStore MonthNames "Aug" "08"
AStore MonthNames "Sep" "09"
AStore MonthNames "Oct" "10"
AStore MonthNames "Nov" "11"
AStore MonthNames "Dec" "12"

errorCount=0
if [[ $NIS -eq 0 && $LDAP -eq 0 && $NOAUTOLDAP -eq 0 ]];then
  	logInfo "Starting auto detection of NIS"
        auto_detect_nis
fi
if [[ $IS_ADMIN_ENT_ACC -eq 2 ]];then
        logInfo "User passed the Vintela parameter,So auto detecting of vintela is not Enabled"
else 
        logInfo "Starting auto detection of vintela"
        auto_detect_vintela
fi
if [[ $IS_ADMIN_ENT_ACC -eq 3 ]];then
        logInfo "User passed the Centrify parameter,So auto detecting of centrify is not Enabled"
else
        logInfo "Starting auto detection of centrify"
        auto_detect_centrify
fi

logDebug "After Auto detection IsAdminEntAccessible: $IS_ADMIN_ENT_ACC"

#V9.7.0 added
if [[ $OS = "Linux" ]]; then
        logInfo "Starting auto detection of rhel idm-ipa for rbac"
        auto_detect_rhel_idm_ipa_rbac
fi

ADMENTPASSWD="/tmp/adment_passwd"
ADMENTGROUP="/tmp/adment_group"

ADMENTSPASSWD="/tmp/adment_spasswd"

LDAPPASSWD="/tmp/ldappasswd"
LDAPGROUP="/tmp/ldapgroup"
current_id=$(id -u)
if [[ $current_id -ne 0 ]]; then 
	NOTROOT=1
	logInfo "********* Script not executed with root privileges,Running the script less than this level of access does not guarantee the ability to extract all required user data.So we recommend to run the script with root level access to get all user ID data with accuracy *********"
fi
logPostHeader $0

PROCESSNIS=0
PROCESSLDAP=0

if [[ $LDAP -eq 1 ]]; then
  if [[ $OS = "AIX" || $OS = "SunOS" ]]; then
    LDAPCMD="ldapsearch"
    if [[ $OS = "AIX" ]]; then
      attr=$("$LDAPCMD" 2>/dev/null)
      if [[ $? -eq 127 ]]; then
        LDAPCMD="idsldapsearch"
      fi
    fi  
  else
    LDAPCMD="ldapsearch -x"
  fi
  
  if [[ $LDAPFILE != "" ]]; then
    LDAPSVR=$(awk -F: '/^LDAPSVR:/ {print $2}' $LDAPFILE)
    LDAPBASE=$(awk -F: '/^LDAPBASEPASSWD:/ {print $2}' $LDAPFILE)
    LDAPBASEGROUP=$(awk  -F: '/^LDAPBASEGROUP:/ {print $2}' $LDAPFILE)
    LDAPPORT=$(awk -F: '/^LDAPPORT:/ {print $2}' $LDAPFILE)
    LDAPGROUPOBJCLASS=$(awk -F: '/^LDAPGROUPOBJCLASS:/ {print $2}' $LDAPFILE)
    LDAPADDITIONAL=$(awk -F: '/^LDAPADDITIONAL:/ {print $2}' $LDAPFILE)
    LDAPUSERFILTER=$(awk -F: '/^LDAPUSERFILTER:/ {print $2}' $LDAPFILE)
    LDAPCMDTMP=$(awk -F: '/^LDAPCMD:/ {print $2}' $LDAPFILE)

    if [[ $LDAPCMDTMP != "" ]]; then
      LDAPCMD=$LDAPCMDTMP
    fi
    
    if [[ $LDAPUSERFILTER = "" ]]; then
      LDAPUSERFILTER="uid=*"
    fi
#   logDebug "\nLDAPFILE:$LDAPFILE\nLDAPSVR:$LDAPSVR\nLDAPBASEPASSWD:$LDAPBASE\nLDAPBASEGROUP:$LDAPBASEGROUP\nLDAPPORT:$LDAPPORT\nLDAPGROUPOBJCLASS:$LDAPGROUPOBJCLASS\nLDAPADDITIONAL:$LDAPADDITIONAL"
    if [[ $LDAPSVR = "" || $LDAPBASE = "" || $LDAPPORT = "" || $LDAPGROUPOBJCLASS = "" || $LDAPBASEGROUP = "" ]]; then
      logAbort "Invalid $LDAPFILE, exiting"
    fi
  fi
fi

get_group_info
passwd_ids

if [[ NOGSA -eq 0 ]]; then
  checkGSAconfig
  if [[ $? -eq 1 ]]; then
    logInfo "Start GSA processing"
    LDAPPASSWD="/tmp/ldappasswd"
    LDAPGROUP="/tmp/ldapgroup"
    if [[ $OS = "AIX" || $OS = "SunOS" ]]; then
      LDAPCMD="/usr/gsa/bin/ldapsearch"
    else
      LDAPCMD="/usr/bin/ldapsearch -x"
    fi    
    NOAUTOLDAP=1
    collectGSAusers
    PROCESSLDAP=1
    LDAP=1
    Parse_User
    Parse_Grp
    
    LDAP=0
    Parse_Grp
    
    if [[ $OS != "AIX" ]]; then
      LDAP=0
      PROCESSLDAP=0
      Parse_Grp
      LDAP=1
      PROCESSLDAP=1
    fi      
    LDAP=1
    logInfo "Parse Sudo"    
    Parse_Sudo        
    logInfo "Finish GSA processing"    
    report
    
    LDAP=0
    
    CleanArrays
    CleanUserData
    
    if [ -a $LDAPPASSWD ]; then
      rm "$LDAPPASSWD"
    fi

    if [ -a $LDAPGROUP ]; then
      rm "$LDAPGROUP"
    fi
    
  fi
fi

if [[ $NIS -eq 1 ]]; then
    NISPLUS=0
    check_nisplus
    if  [[ $? -eq 1 ]]; then
      NISPLUS=1
    fi
    logInfo "Start NIS processing"
    if [[ NISPLUS -eq 1 ]]; then
      ret=$(niscat passwd.org_dir"$NISPLUSDIR" > /tmp/nis_passwd)
      ret=$(niscat group.org_dir > /tmp/nis_group)
    else
      ret=$(ypcat passwd > /tmp/nis_passwd)
      ret=$(ypcat group > /tmp/nis_group)
    fi
    
    if [[ $? -ne 0 ]]; then
       logAbort "Unable to accessing NIS server"
    fi
    PROCESSNIS=1
    NISPASSWD="/tmp/nis_passwd"
    NISGROUP="/tmp/nis_group"
    logInfo "Parse NIS users"    
    Parse_User
    logInfo "Parse NIS groups"        
    Parse_Grp
    
    NIS=0
    PROCESSNIS=0
    Parse_Grp
    NIS=1
    PROCESSNIS=1
    
    logInfo "Parse Sudo"    
    Parse_Sudo        # for NIS's accounts we must extract all data from SUDO-settings
    report
    rm -f /tmp/nis_passwd /tmp/nis_group
    
    CleanArrays    
    CleanUserData
    
    logInfo "Finish NIS processing"  
    PROCESSNIS=0  
fi

if [[ $IS_ADMIN_ENT_ACC -ne 0 && $NIS -eq 0 && $LDAP -eq 1 ]];
then
  checkforldappasswd
  if [[ $? -eq 1 ]]; then
    logInfo "Start LDAP processing"
    PROCESSLDAP=1
    logInfo "Parse LDAP users"
    collect_LDAP_users_aix
    process_LDAP_users
    parse_LDAP_grp
    Parse_User
    logInfo "Parse LDAP groups"     
    Parse_Grp
    
    if [[ $OS != "AIX" ]]; then
      LDAP=0
      PROCESSLDAP=0
      Parse_Grp
      LDAP=1
      PROCESSLDAP=1
    fi  
    
    logInfo "Parse Sudo"
    Parse_Sudo
    logInfo "Finish LDAP processing"
    report  
    CleanArrays
    CleanUserData
  
    if [ -e $LDAPPASSWD ]; then
      rm "$LDAPPASSWD"
    fi

    if [ -e $LDAPGROUP ]; then
      rm "$LDAPGROUP"
    fi

    if [ -e $ldap_tmp ]; then 
      rm $ldap_tmp
    fi

    if [ -e $ldap_tmp1 ]; then 
      rm $ldap_tmp1
    fi
  fi      
fi  

PROCESSLDAP=0

if [[ $NIS -ne 1 ]]; then
	Parse_User
	Parse_Grp
	Parse_Sudo
  	if [[ $OS = "AIX" ]]; then
    		parse_spwaix
  	elif [[ $OS != "HP-UX" ]]; then  
    		parse_shadow
  	fi  

	logInfo "Writing report"
	report

	CleanArrays
	CleanUserData
fi
if [ -e $LDAPPASSWD ]; then
   rm "$LDAPPASSWD"
fi

case $SIG in            #4.3 Custom Signature
TSCM )
  NOTAREALID="NOTaRealID-TSCM"
  ;;
SCR )
  NOTAREALID="NOTaRealID-SCR"
  ;;
TCM ) 
  NOTAREALID="NOTaRealID-TCM"
  ;;
FUS )
  NOTAREALID="NOTaRealID-FUS"
  ;;
*)
  NOTAREALID="NOTaRealID"
  ;;
esac

if [[ $SIGNATURE != "" ]];then
  NOTAREALID="NOTaRealID$SIGNATURE"
fi

TIMEZONE=$(getTimeZone)
  
UATStr=""
if [[ $UAT  -eq 1 ]]; then
  Report_UAT
fi  

if [[ $NOTROOT  -eq 1 ]]; then
  Rootaccess="NO"
else
  Rootaccess="YES"
fi 
  
# adding dummy record
 if [[ $SCMFORMAT -eq 1 ]]; then 
    echo "$HOSTNAME\t$OS\t$myAUDITDATE\t$NOTAREALID\t000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER\t1\t\t\t" >> $OUTPUTFILE
  elif [[ $MEF2FORMAT -eq 1 ]]; then
#MEF2 customer|system|account|userID convention data|group|state|l_logon|privilege
    echo "$CUSTOMER|$HOSTNAME|$NOTAREALID|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER||||" >> $OUTPUTFILE
  elif [[ $MEF4FORMAT -eq 1 ]]; then    
    echo "S|$CUSTOMER|S|$HOSTNAME|$OS|$NOTAREALID|$UATStr|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER||$TIMEZONE|$KNOWPAR|$EXIT_CODE|||||||" >> $OUTPUTFILE
  else
#MEF3 \93customer|identifier type|server identifier/application identifier|OS name/Application name|account|UICMode|userID convention data|state|l_logon |group|privilege\94
    if [[ $Dormant == "ON_ON" || $Dormant == "ON_OFF" ]];then
    	echo "$CUSTOMER|S|$HOSTNAME|$OS|$NOTAREALID|$UATStr|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER:ROOT=$Rootaccess||$TIMEZONE|$KNOWPAR|$EXIT_CODE|" >> $OUTPUTFILE
    	logDebug "MEF3_onon_onoff:$CUSTOMER|S|$HOSTNAME|$OS|$NOTAREALID|$UATStr|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER:ROOT=$Rootaccess||$TIMEZONE|$KNOWPAR|$EXIT_CODE|" 

    elif [[ $Dormant == "OFF_OFF" ]];then
    	echo "$CUSTOMER|S|$HOSTNAME|$OS|$NOTAREALID|$UATStr|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER:ROOT=$Rootaccess||$TIMEZONE|$KNOWPAR|$EXIT_CODE" >> $OUTPUTFILE
    	logDebug "MEF3_offoff:$CUSTOMER|S|$HOSTNAME|$OS|$NOTAREALID|$UATStr|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER:ROOT=$Rootaccess||$TIMEZONE|$KNOWPAR|$EXIT_CODE" 

    else
    	echo "$CUSTOMER|S|$HOSTNAME|$OS|$NOTAREALID|$UATStr|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER:ROOT=$Rootaccess||$TIMEZONE|$KNOWPAR|$EXIT_CODE" >> $OUTPUTFILE
    	logDebug "MEF3:$CUSTOMER|S|$HOSTNAME|$OS|$NOTAREALID|$UATStr|000/V///$myAUDITDATE:FN=$0:VER=$VERSION:CKSUM=$CKSUM:SUDO=$SUDOVER:ROOT=$Rootaccess||$TIMEZONE|$KNOWPAR|$EXIT_CODE" 
    fi
 fi
DATA=$(APrintAll sudoUsers " "> $TMPFILE)

#APrintAll sudoUsers " "| while read nextline; do
while read nextline; do
  declare -a tokens=($(echo "$nextline"))
  userid=${tokens[0]}
  logMsg "WARNING" "invalid user in $SUDOERFILE: $userid"
  EXIT_CODE=1
done < $TMPFILE

if [ -e $TMPFILE ]; then
rm $TMPFILE
fi

if [ -e $CENTRTMP ]; then
rm $CENTRTMP
fi

AUnset local_groups
AUnset local_users
AUnset ROLE

if [ $errorCount -gt 0 ]; then
  logInfo "$errorCount errors encountered"
fi

Filter_mef3

if [[ $OWNER != "" ]]; then
    chown $OWNER $OUTPUTFILE
fi

logFooter
exit $EXIT_CODE
