#!/bin/bash

#
# SCRIPT: snapshotLinux.sh
# AUTHOR: Martin Grados Marquina
# EMAIL: magrados@pe.ibm.com
# DATE: 19/10/2018
# REV: 01.02
#
#
#
# set -n
# Uncomment to check your syntax, without execution.
#
# NOTES: 
#
# the shell script will not execute!
# set -x
# Uncomment to debug this shell script (Korn shell only)
#
##########################################################
########### DEFINE FILES AND VARIABLES HERE ##############
##########################################################


SYSCONFINF="1- SYSTEM CONFIGURATION INFOMATION"
PROCMEM="2- PROCESADOR Y MEMORIA"
NETWORK="3- NETWORK"
LVM="4- LOGICAL VOLUME MANAGER"
ADAPTERS="5- ADAPTADORES"
APPS="6- PROCESSORS"
USERS="7- USERS"
GPFS="8- GPFS"
PACKAGE="9- PACKAGE MANAGER"
ERROR="10- ERROR"

RANDOM="$$"

#VERBOSE="ON" # VERBOSE="OFF"
if [[ $# -eq 0 ]]; then
  VERBOSE="OFF"
  PATHTEMP="/tmp/auto_snapshot"
  test -d "${PATHTEMP}" || mkdir "${PATHTEMP}"
  LOGFILE="${PATHTEMP}/snapshot_$(hostname)_$(date '+%d%b%Y_%H%M%S').txt"
else
  IP_SERVER=$1
  SESION="$2"
  PATHTEMP=".temp_snap.${SESION}"  
  test -d "${PATHTEMP}" || mkdir "${PATHTEMP}"
  VERBOSE="ON"
  LOGFILE="${PATHTEMP}/snapshot_$(hostname)_${IP_SERVER}_$(date '+%d%b%Y_%H%M%S').txt"

  RANDOM="$2"
fi
touch $LOGFILE
chmod 700 $LOGFILE

#typeset -A SectionSnapshot
declare -a SectionSnapshot

SectionSnapshot[0]="$SYSCONFINF"
SectionSnapshot[1]="$PROCMEM"
SectionSnapshot[2]="$NETWORK"
SectionSnapshot[3]="$LVM"
SectionSnapshot[4]="$ADAPTERS"
SectionSnapshot[5]="$APPS"
SectionSnapshot[6]="$USERS"
SectionSnapshot[7]="$GPFS"
SectionSnapshot[8]="$PACKAGE"
SectionSnapshot[9]="$ERROR"

HOSTNAME=$(hostname -s)

OSLINUXRELEASE=0

OSLINUXDIST=$(lsb_release -a  2> /dev/null | awk -F: '$0 ~ /Distributor/ {print $2}'  | awk '{print $1}' )
OSLINUXRELEASE=$(lsb_release -a  2> /dev/null | awk -F: '$0 ~ /Release/ {print $2}' | awk '{print $1}' )

if [[ -z ${OSLINUXDIST} ]]; then
	CHECKVAR=$(cat /etc/*release | grep '^NAME')
	if [[ ! -z ${CHECKVAR} ]]; then
		OSLINUXDIST=$( cat /etc/*release | grep '^NAME' | sed 's/NAME=//g;s/"//g;s/Linux//g' | awk '{ print $1 }' )
	else
		[[ -z ${OSLINUXDIST} ]] && [[ ! -z $( cat /etc/*release | grep -e "Red" -e "Oracle" -e "CentOS" ) ]] && OSLINUXDIST="Red"
		[[ -z ${OSLINUXDIST} ]] && [[ ! -z $( cat /etc/*release | grep -e "Debian" ) ]] && OSLINUXDIST="Debian"
		[[ -z ${OSLINUXDIST} ]] && [[ ! -z $( cat /etc/*release | grep -e "SUSE" ) ]] && OSLINUXDIST="SUSE"
	fi
fi

#REDHATRELEASE="0"
CHECKDEB=$(cat /etc/*release | grep -i debian )
if [[ -z ${CHECKDEB} ]]; then
	CHECKDEB=""
fi

[[ -z ${OSLINUXRELEASE} ]] && [[ "${OSLINUXDIST}" =~ "Red" ]] && OSLINUXRELEASE=$(for str in $(cat /etc/*release | grep release ); do echo "$str" | awk '$0 ~ /^[0-9].+/ {print $0}'; done | uniq | cut -d'.' -f1);
 
seq()
{
	i=$1
	while [[ $i -le $2 ]] ; do
			echo "$i"
			i=$(expr $i + 1)
	done
}

progressBar() 
{  
	# Calculate number of fill/empty slots in the bar
	progress=$(echo "scale=2;$progressBarWidth/$taskCount*$tasksDone" | bc -l)  
	fill=$(echo "$progress" | awk '{ printf "%.0f\n", $0 }' )

	var=$(awk -v FILL=$fill -v PROGRESSBARWIDTH=${progressBarWidth} 'BEGIN{ if( PROGRESSBARWIDTH < FILL ) print "1"; else print "0";}')
	
	[ "$var" -eq 1 ] && fill=$progressBarWidth || empty=$(($fill-$progressBarWidth))

	percent=$(echo "scale=2;100/$taskCount*$tasksDone" | bc -l)
	percent=$(echo $percent | awk '{ printf "%.2f\n", $0 }' )
	var=$(echo $percent | awk '{if ($0 > 100) print "1"}' )
	
	[ "$var" -eq 1 ] && percent="100.00"

	# Output to screen
	printf "\r["
	printf "%${fill}s" '' | tr ' ' =
	printf "%${empty}s" '' | tr ' ' -
	printf "] $percent%% : ${2} "
}


progressText()
{
	# Calculate number of fill/empty slots in the bar
	progress=$(echo "scale=2;$progressBarWidth/$taskCount*$tasksDone" | bc -l)
	fill=$(echo "$progress" | awk '{ printf "%.0f\n", $0 }' )

	var=$(awk -v FILL=$fill -v PROGRESSBARWIDTH=${progressBarWidth} 'BEGIN{ if( PROGRESSBARWIDTH < FILL ) print "1"; else print "0";}')
 
	[ "$var" -eq 1 ] && fill=$progressBarWidth || empty=$(($fill-$progressBarWidth))

	percent=$(echo "scale=2;100/$taskCount*$tasksDone" | bc -l)
	percent=$(echo $percent | awk '{ printf "%.2f\n", $0 }' )
	var=$(echo $percent | awk '{if ($0 > 100) print "1"}' )
 
	[ "$var" -eq 1 ] && percent="100.00"

	printf "\r"
	printf "Running...$percent%% : ${2}"

}

get_index()
{
	LOGFILE=$1
	NUMLINESINDEX=$2
  SUBSECTIONLINE="${PATHTEMP}/SUBSECTIONLINE.$$"

  declare -a indSection
  posfile=0
  LASTLINE=$( cat $LOGFILE  | grep -n "^*\*"   | grep 'SALIDA DE COMANDOS' | awk -F: '{print $1}' )

  (( LASTLINE = LASTLINE - 2 ))

  for ind in $( cat $LOGFILE | grep -n "[0-9]- " | awk -F: '{print $1}') ; do
    #echo "$posfile - $ind "
    indSection[$posfile]="$ind"
    (( posfile = posfile + 1 ))
  done

  indSection[$posfile]="$LASTLINE"
  #echo "$posfile - $LASTLINE "

  NUMELEM="${#indSection[@]}"
  (( NUMELEM = NUMELEM - 1 ))

  declare -a LINESUBSECTION
  declare -a SUBSECTION

  printf "\n%-40s %39s :%7s\n" "SECTION" "SUB-SECTION" "LINE"
  printf "%-40s %39s :%7s\n" "-------" "-----------" "----"
  for ind in $( seq 1 $NUMELEM ); do

    (( indsec = ind - 1 ))
    printf "\n\nSECTION: ${SectionSnapshot[$indsec]} \n"
    (( pre = ind - 1 ))
    (( ENDSUBSECT = ${indSection[$ind]} - 1 ))
    #print "${indSection[$pre]} : $ENDSUBSECT"
    posfile=0
    #sed -n ${indSection[$pre]},${ENDSUBSECT}p $LOGFILE | grep -n '^[[:space:]]\{10\}' | grep ':$' | sed 's/  //g' > $SUBSECTIONLINE
    sed -n ${indSection[$pre]},${ENDSUBSECT}p $LOGFILE | grep -ne '^[[:space:]]\{10\}.*:$' -ne '^REVISAR' | sed 's/  //g' > $SUBSECTIONLINE
	  
    cat $SUBSECTIONLINE | while read linesec 
    do 
      
      NUMLINE=$(echo "$linesec" | awk -F: '{print $1}')
      STRSUBSEC=$(echo "$linesec" | awk -F: '{print $2}')
      (( NUMLINE = NUMLINE + ${indSection[$pre]} - 1 ))
      (( NUMLINE = NUMLINE + NUMLINESINDEX ))
      LINESUBSECTION[$posfile]="$NUMLINE"
      SUBSECTION[$posfile]="$STRSUBSEC"
      printf "%80s : %6s\n" "${SUBSECTION[$posfile]}"  "${LINESUBSECTION[$posfile]}" 
      (( posfile = posfile + 1 ))
    done
  done

  test -f $SUBSECTIONLINE && rm -f $SUBSECTIONLINE

}

set_index2photo()
{ 
	LOGFILE=$1
  INDEXTMP="${PATHTEMP}/INDEXTMP.$$"
  NUMLINESINDEX="0"

  get_index $LOGFILE $NUMLINESINDEX > $INDEXTMP
  NUMLINESINDEX=$(cat $INDEXTMP | wc -l )
  get_index $LOGFILE $NUMLINESINDEX > $INDEXTMP

  LOGFILETMP="${PATHTEMP}/LOGFILETMP.$$"
  NUMLINESTOTAL=$( wc -l $LOGFILE | awk '{print $1}' )
  (( NUMLINESTOTAL = NUMLINESTOTAL + NUMLINESINDEX ))
  sed -n 1,4p $LOGFILE > $LOGFILETMP 
  cat $INDEXTMP >> $LOGFILETMP
  sed -n 5,${NUMLINESTOTAL}p $LOGFILE >> $LOGFILETMP

  test -e $INDEXTMP && rm -f $INDEXTMP
  mv "$LOGFILETMP" "$LOGFILE"

}

set_files_temp()
{

  NETSTAT_RI="${PATHTEMP}/$HOSTNAME_NETSTAT_RI.$RANDOM"
  NETSTAT_RN="${PATHTEMP}/$HOSTNAME_NETSTAT_RN.$RANDOM"
  MODELSERIALPLAT="${PATHTEMP}/$HOSTNAME_MODELSERIALPLAT.$RANDOM"

  # FILES TEMP TO NETWORKS
  BLOCK_ROUTE="${PATHTEMP}/$HOSTNAME_BLOCK_ROUTE.$RANDOM"
  BLOCK_IPV4="${PATHTEMP}/$HOSTNAME_BLOCK_IPV4.$RANDOM"
  BLOCK_IPV6="${PATHTEMP}/$HOSTNAME_BLOCK_IPV6.$RANDOM"
  PRTCONF="${PATHTEMP}/$HOSTNAME_PRTCONF.$RANDOM"
  ENV_VAR="${PATHTEMP}/$HOSTNAME_ENV_VAR.$RANDOM"
  LOADPROCCESSOR="${PATHTEMP}/$HOSTNAME_LOADPROCCESSOR.$RANDOM"
  LISTENPORT="${PATHTEMP}/$HOSTNAME_LISTENPORT.$RANDOM"
  MEMCONSUMPTION="${PATHTEMP}/$HOSTNAME_MEMCONSUMPTION.$RANDOM$"
  DISK="${PATHTEMP}/$HOSTNAME_DISK.$RANDOM"
  LSPATH="${PATHTEMP}/$HOSTNAME_LSPATH.$RANDOM"
  DF="${PATHTEMP}/$HOSTNAME_DF.$RANDOM"
  MOUNT="${PATHTEMP}/$HOSTNAME_MOUNT.$RANDOM"
  FILEPASSWD="${PATHTEMP}/$HOSTNAME_PASSWD.$RANDOM"
  HDISK_LUNID="${PATHTEMP}/$HOSTNAME_HDISK_LUNID.$RANDOM"
  LISTRPM="${PATHTEMP}/$HOSTNAME_LISTRPM.$RANDOM"
  VGA="${PATHTEMP}/$HOSTNAME_VGA.$RANDOM"
  NETSTATALLSOCK="${PATHTEMP}/$HOSTNAME_NETSTATALLSOCK.$RANDOM"
  LISTDETAILSUSERS="${PATHTEMP}/$HOSTNAME_LISTDETAILSUSERS.$RANDOM"

}

rm_files_temp()
{
  test -f $OSLEVEL && rm -f $OSLEVEL
  test -f $NETSTAT_RI && rm -f $NETSTAT_RI
  test -f $NETSTAT_RN && rm -f $NETSTAT_RN
  test -f $MODELSERIALPLAT && rm -f $MODELSERIALPLAT
  test -f $PRTCONF && rm -f $PRTCONF
  test -f $BLOCK_ROUTE && rm -f $BLOCK_ROUTE
  test -f $BLOCK_IPV4 && rm -f $BLOCK_IPV4
  test -f $BLOCK_IPV6 && rm -f $BLOCK_IPV6
  test -f $ENV_VAR && rm -f $ENV_VAR
  test -f $LPARSTAT && rm -f $LPARSTAT
  test -f $LOADPROCCESSOR && rm -f $LOADPROCCESSOR
  test -f $LISTENPORT && rm -f $LISTENPORT
  test -f $MEMCONSUMPTION && rm -f $MEMCONSUMPTION
  test -f $DISK && rm -f $DISK
  test -f $LSPATH && rm -f $LSPATH
  test -f $DF && rm -f $DF
  test -f $MOUNT && rm -f $MOUNT
  test -f $FILEPASSWD && rm -f $FILEPASSWD
  test -f $LSMAP_ALL && rm -f $LSMAP_ALL
  test -f $HDISK_LUNID && rm -f $HDISK_LUNID
  test -f $LSPV && rm -f $LSPV
  test -f $VIOS && rm -f $VIOS
  test -f $HMC && rm -f $HMC
  test -f $LSLPP && rm -f $LSLPP
  test -f $VGA && rm -f $VGA
  test -f $NETSTATALLSOCK && rm -f $NETSTATALLSOCK
  test -f $LISTDETAILSUSERS && rm -f $LISTDETAILSUSERS
}

put_line()
{
   if [[ -z "$1" ]]; then
        printf "%80s\n" "$(for i in $(seq 1 80); do printf '-'; done)"
   else
        NUM=$1
        if [[ -z "$2" ]]; then
	  printf "%${NUM}s\n" "$(for i in $(seq 1 ${NUM}); do printf '-'; done)"
	else
	  CHARACT=$2
	  printf "%${NUM}s\n" "$(for i in $(seq 1 ${NUM}); do printf ${CHARACT}; done)"
	fi
   fi  
}

get_host()
{
  HOSTSERVER=$(hostname)
}

get_etc_passwd()
{
  cat /etc/passwd > $FILEPASSWD
}

get_OS ()
{
    uname -s
}

cpu_info()
{

	cpuinfo=/proc/cpuinfo
	model_cpu=$(awk -F: '/^model name/{print $2; exit}' <"$cpuinfo")
	# If no model detected (e.g. on Itanium), try to use vendor+family
	[[ -z $model_cpu ]] && {
		vendor=$(awk -F: '/^vendor /{print $2; exit}' <"$cpuinfo")
		family=$(awk -F: '/^family /{print $2; exit}' <"$cpuinfo")
		model_cpu="$vendor$family"
	}

	# Clean up cpu model string
	model_cpu=$(sed -e 's,(R),,g' -e 's,(TM),,g' -e 's,  *, ,g' -e 's,^ ,,' <<<"$model_cpu")
	# Clean up cpu model string
	model_cpu=$(sed -e 's,(R),,g' -e 's,(TM),,g' -e 's,  *, ,g' -e 's,^ ,,' <<<"$model_cpu")

	# Get number of logical processors
	num_cpu=$(awk '/^processor/{n++} END{print n}' <"$cpuinfo")

	# Get number of physical processors
	num_cpu_phys=$(grep '^physical id' <"$cpuinfo" | sort -u | wc -l)

	# If "physical id" not found, we cannot make any assumptions (Virtualization--)
	# But still, multiplying by 0 in some crazy corner case is bad, so set it to 1
	# If num of physical *was* detected, add it to the beginning of the model string
	[[ $num_cpu_phys == 0 ]] && num_cpu_phys=1 || model_cpu="$num_cpu_phys $model_cpu"

	# If number of logical != number of physical, try to get info on cores & threads
	if [[ $num_cpu != $num_cpu_phys ]]; then
		
		# Detect number of threads (logical) per cpu
		num_threads_per_cpu=$(awk '/^siblings/{print $3; exit}' <"$cpuinfo")
		
		# Two possibile ways to detect number of cores
		cpu_cores=$(awk '/^cpu cores/{print $4; exit}' <"$cpuinfo")
		core_id=$(grep '^core id' <"$cpuinfo" | sort -u | wc -l)
		
		# The first is the most accurate, if it works
		if [[ -n $cpu_cores ]]; then
			num_cores_per_cpu=$cpu_cores
		
		# If "cpu cores" doesn't work, "core id" method might (e.g. Itanium)
		elif [[ $core_id -gt 0 ]]; then
			num_cores_per_cpu=$core_id
		fi
		
		# If found info on cores, setup core variables for printing
		if [[ -n $num_cores_per_cpu ]]; then
			cores1="($((num_cpu_phys*num_cores_per_cpu)) CPU cores)"
			cores2=" / $num_cores_per_cpu cores"
		# If didn't find info on cores, assume single-core cpu(s)
		else
			cores2=" / 1 core"
		fi
		
		# If found siblings (threads), setup the variable for the final line
		[[ -n $num_threads_per_cpu ]] &&
			coresNthreads="\n└─$num_threads_per_cpu threads${cores2} each"
	fi

	# Check important cpu flags
	# pae=physical address extensions  *  lm=64-bit  *  vmx=Intel hw-virt  *  svm=AMD hw-virt
	# ht=hyper-threading  *  aes=AES-NI  *  constant_tsc=Constant Time Stamp Counter
	cpu_flags=$(egrep -o "pae|lm|vmx|svm|ht|aes|constant_tsc" <"$cpuinfo" | sort -u | sed ':a;N;$!ba;s/\n/,/g')
	[[ -n $cpu_flags ]] && cpu_flags="(flags: $cpu_flags)"

	# Check kernel version; print warning if Xen
	[[ $(uname -r) =~ xen ]] && {
		echo "Warning: kernel for localhost detected as $(uname -r)"
		echo "With Xen, CPU layout in /proc/cpuinfo will be inaccurate; consult dmidecode"
	}

	# Print out the deets
	echo -e "${num_cpu} logical processors ${cores1}"
	echo -e "${model_cpu} ${cpu_flags} ${coresNthreads}"

}

show_info_cpu()
{

  test -f /usr/bin/lscpu && (
  	printf "\n%80s\n" "Display Information on CPU Architecture(lscpu):"
  	put_line 80
  	/usr/bin/lscpu
  	put_line 80
  	)
 
  test -f /usr/bin/lscpu && (
  	printf "\n%80s\n" "Summary of CPU Architecture(lscpu):"
  	put_line 80
  	/usr/bin/lscpu | egrep 'Thread|Core|Socket|^CPU\('
  	put_line 80
  	)

  printf "\n%80s\n" "Display Information of CPU [Logical/Physical/Threads for CPU] (/proc/cpuinfo):"
  put_line 80  
  cpu_info
  put_line 80	
	
}

show_date_server()
{
	local DATEVAR
	local PLATFORM

  DATEVAR=$(date  | tr '[:lower:]' '[:upper:]')
  PLATFORM=$(uname  | tr '[:lower:]' '[:upper:]')
  printf  "%80s\n" "============================"
  printf "%-29s %50s\n" "${PLATFORM} HOSTNAME: $HOSTSERVER" "$DATEVAR" 
  printf "%80s\n" "============================"
}

show_resumen_server_name()
{
   
   test -f /usr/bin/lsb_release && (
   	printf "\n%80s\n" "Print Linux Distribution-Specific Information:"
  	put_line 80
   	/usr/bin/lsb_release -a
   	put_line 80
   	) || ( 
   	printf "\n%80s\n" "Print Linux Distribution-Specific Information:"
  	put_line 80
   	cat /etc/*release
   	put_line 80
   	)  
}

show_info_bios()
{
	printf "\n%80s\n" "Display information of BIOS:"
	put_line 80
	if (( $( echo " ${OSLINUXRELEASE} == 4 " | bc -l ) )); then
  		/usr/sbin/dmidecode | grep -e 'Vendor' -e 'Version' -e 'Release Date' | head -n 3
  	else
			/usr/sbin/dmidecode -t 0 | grep -e 'Vendor' -e 'Version' -e 'Release Date' | cut -f 2
		fi
	put_line 80
}

show_info_system()
{
	test -f /usr/sbin/dmidecode && (
		printf "\n%80s\n" "Display information of System(dmidecode):"
  	put_line 80
  	if (( $( echo " ${OSLINUXRELEASE} == 4 " | bc -l )  )); then
  		/usr/sbin/dmidecode | grep -e 'Manufacturer' -e 'Product Name' -e 'Serial Number' | head -n 3
  	else
			/usr/sbin/dmidecode -t 1 | grep -e 'Manufacturer' -e 'Product Name' -e 'Serial Number' | head -n 3
		fi
		put_line 80
		) || (
		test -d /sys/class/dmi/id && (
			printf "\n%80s\n" "Display information of System(grep \"\" /sys/class/dmi/id/[pbs]*):"
  		put_line 80
  		grep "" /sys/class/dmi/id/[pbs]*  2> /dev/null
  		put_line 80
			) || (
			printf "\n%80s\n" "Display information of System( dmesg | grep -w -i DMI):"
  		put_line 80
			dmesg | grep -w -i DMI
			put_line 80
			)
		)
}

show_list_device_Storage()
{
	local CHECKMULTIPATH
	
	test -f /bin/lsblk && (
		printf "\n%80s\n" "List Block Devices(lsblk -a):"
  	put_line 80
  	/bin/lsblk -a
  	put_line 80

		) || (
		printf "\n%80s\n" "Display information of System(dmidecode -t 1):"
  	put_line 80
  	/sbin/fdisk -l | grep -e '^Disk' -e 'System$' -e '^/dev' | grep -v 'identifier'
  	put_line 80		
		)

	CHECKMULTIPATH=$( cat /proc/modules | grep -i dm_multipath )
	if [[ ! -z ${CHECKMULTIPATH} ]]; then
		test -f /sbin/multipath && (
			printf "\n%80s\n" "Show the Current Multipath Topology from all Available Information:"
			put_line 80
			/sbin/multipath -ll
			put_line 80

			)
	else 
		echo "INFO - DM multipath kernel driver not loaded"
	fi


	test -f /usr/bin/lsscsi && (
		printf "\n%80s\n" "Informations about SCSI devices(lsscsi):"
		put_line 80
		/usr/bin/lsscsi
		put_line 80
		) || ( test -f /proc/scsi/scsi && (
			printf "\n%80s\n" "Informations about SCSI devices(cat /proc/scsi/scsi):"
			put_line 80
			cat /proc/scsi/scsi
			put_line 80
			)
		)

}


show_resume_kernel()
{
	local NETWNAMESRV=$(/bin/uname -n)
  local KERNRELE=$(/bin/uname -r)
  local MACHHARDNAM=$(/bin/uname -m)
	printf "\n%80s\n" "Display information of kernel:"
	put_line 80
	printf "| %-18s | %-32s | %-17s |\n" "SRV_NAME_NET" "KERNEL_RELEASE" "MACHINE_HARDWARE" 
	printf "| %-18s | %-32s | %-17s |\n" "${NETWNAMESRV}" "${KERNRELE}" "${MACHHARDNAM}" 
	put_line 80		

	test -f /bin/lsmod && (
		printf "\n%80s\n" "Status of Modules in the Linux kernel:"
		put_line 80
		/bin/lsmod
		put_line 80
		) || (
		printf "\n%80s\n" "Status of Modules in the Linux kernel:"
		put_line 80
		cat /proc/modules | column -t
		put_line 80

		)
}

get_host()
{
  HOSTSERVER=$(hostname)
}

show_memory_details()
{
	printf "\n%80s\n" "Memory Usage:"
	put_line 80
	/usr/bin/free -m
	put_line 40

	printf "\n%80s\n" "Memory Info(/proc/meminfo):"
	put_line 80
	cat /proc/meminfo 
	put_line 80

	printf "\n%80s\n" "Memory Usage Statistics(vmstat -s):"
	put_line 80
	/usr/bin/vmstat -s 
	put_line 80

	test -e /proc/swaps && (
			printf "\n%80s\n" "Show Total and used swap size(cat /proc/swaps):"
			put_line 80
			cat /proc/swaps
			put_line 80

		)
}

show_interfaces()
{
	printf "\n%80s\n" "Show file of configuration of Network Interfaces:"
	put_line 80
	#local CHECKDEB
	echo ""
	#CHECKDEB=$(cat /etc/*release | grep -i debian )
	#if [[ -z $CHECKDEB ]]; then
	if [[ "${OSLINUXDIST}" =~ "Red" ]]; then
		for ind in $(ls /sys/class/net | grep -v -w lo); do 
			put_line 60
			if [[ "${ind}" == "bonding_masters" ]]; then
				printf "\n%60s\n" "File config BONDING_MASTER: ${ind}"	
				for ibond in $(cat /sys/class/net/bonding_masters); do
					printf "\n%60s\n" "Slaves of bond: ${ibond}"
					test -f "/sys/class/net/${ibond}/bonding/slaves" && cat "/sys/class/net/${ibond}/bonding/slaves"
				done

			else
				IFNET=$(ls /etc/sysconfig/network-scripts | grep ${ind} );	
				for iif in $(echo ${IFNET} ); do
					test -f "/etc/sysconfig/network-scripts/${iif}" && (	
					printf "\n%60s\n" "File config: ${iif}"			
					cat "/etc/sysconfig/network-scripts/${iif}"
					)

				done

			fi

		done 
	elif [[ "${OSLINUXDIST}" =~ "SUSE" ]]; then

		test -f /etc/sysconfig/network/config && printf "\n%60s\n" "File config: /etc/sysconfig/network/config" && ( grep -v '^#' /etc/sysconfig/network/config | grep '^[A-Za-z]' )

		for ind in $(ls /sys/class/net | grep -v -w lo); do 
			
			if [[ "${ind}" == "bonding_masters" ]]; then
				put_line 60
				printf "\n%60s\n" "File config BONDING_MASTER: ${ind}"	
				for ibond in $(cat /sys/class/net/bonding_masters); do
					printf "\n%60s\n" "Slaves of bond: ${ibond}"
					test -f "/sys/class/net/${ibond}/bonding/slaves" && cat "/sys/class/net/${ibond}/bonding/slaves"
				done

			else
				IFNET=$(ls /etc/sysconfig/network | grep ${ind} );	
				for iif in $(echo ${IFNET} ); do
					test -f "/etc/sysconfig/network/${iif}" && (	
					put_line 60
					printf "\n%60s\n" "File config: ${iif}"			
					cat "/etc/sysconfig/network/${iif}"
					)
				done
			fi
		done 		

	elif [[ "${OSLINUXDIST}" =~ "Debian" ]]; then
		
		test -f /etc/network/interfaces && (
			printf "\n%60s\n" "File config: /etc/network/interfaces"			
			cat /etc/network/interfaces
			)
	fi
	put_line 80
}

show_network_inter()
{
	local FILETMP="${PATHTEMP}/FILETMPNETW.$$"
	local NUMLINTES
	local NUMRUTASDIM
	local NUMRUTASESTA

	NUMLINTES=0
	NUMRUTASDIM=0
	NUMRUTASESTA=0

	touch ${FILETMP} 
	printf "\n%80s\n" "Information on Network Interfaces:"
	put_line 80
	for ind in $(ls /sys/class/net ); do 
		ifconfig $ind; 
		put_line 40
	done
	put_line 80

	printf "\n%80s\n" "Display a Table of All Network Interfaces:"
	put_line 80
	netstat -i | column -t 
	put_line 80

	printf "\n%80s\n" "Display the kernel Routing Tables(netstat -rn):"
	put_line 80
	netstat -rn > ${FILETMP}
	NUMLINTES=$(wc -l ${FILETMP} | awk '{ print $1 }'  )
	if (( ${NUMLINTES} > 2 )); then 
		NUMRUTASDIM=$( grep '^[0-9]' ${FILETMP} | grep -v "0.0.0.0" | wc -l  )
		cat ${FILETMP}
	else
	 echo "PROBLEMAS CON OBTENER LAS RUTAS DEL SERVIDOR: netstat -rn " 
	fi
	put_line 80


	#local CHECKDEB
	local CHECKROUTEST
	local PATHNETWORK

	echo ""
	#CHECKDEB=$(cat /etc/*release | grep -i debian )
	#if [[ -z $CHECKDEB ]]; then
	if [[ "${OSLINUXDIST}" =~ "Red" ]]; then
		PATHNETWORK="/etc/sysconfig/network-scripts"
		CHECKROUTEST=$(ls ${PATHNETWORK} | grep 'route-' | wc -l )

		if (( ${CHECKROUTEST} != 0 )) ; then 
			printf "\n%80s\n" "Display Static Routing Tables:"
			put_line 80
			
			for ind in $(ls ${PATHNETWORK} | grep 'route-'); do
				put_line 60
				if test -f "${PATHNETWORK}/${ind}" ; 
				then
					printf "\n%60s\n" "File config: ${ind}"
					cat ${PATHNETWORK}/${ind} > ${FILETMP}
					NUMLINTES=$( grep '[A-Z]' ${FILETMP} | wc -l )
					(( NUMLINTES = NUMLINTES / 3 ))
					(( NUMRUTASESTA = NUMRUTASESTA + NUMLINTES ))
				fi					
			done
			
			put_line 80
		fi
	elif [[ "${OSLINUXDIST}" =~ "SUSE" ]]; then
		PATHNETWORK="/etc/sysconfig/network"
		CHECKROUTEST=$(ls ${PATHNETWORK} | grep 'ifroute-' | wc -l )
		printf "\n%80s\n" "Display Static Routing Tables:"
		test -f /etc/sysconfig/network/routes && cat /etc/sysconfig/network/routes

		if (( ${CHECKROUTEST} != 0 )) ; then 
			printf "\n%80s\n" "Display Static Routing Tables:"
			put_line 80
			
			for ind in $(ls ${PATHNETWORK} | grep 'ifroute-'); do
				put_line 60
				if test -f "${PATHNETWORK}/${ind}" ; 
				then
					printf "\n%60s\n" "File config: ${ind}"
					cat ${PATHNETWORK}/${ind} > ${FILETMP}
					NUMLINTES=$( grep '[A-Z]' ${FILETMP} | wc -l )
					(( NUMLINTES = NUMLINTES / 3 ))
					(( NUMRUTASESTA = NUMRUTASESTA + NUMLINTES ))
				fi					
			done
		fi
			
			put_line 80


	elif [[ "${OSLINUXDIST}" =~ "Debian" ]]; then
		#rutas en Debian
		PATHNETWORK="/etc/network/interfaces"
		NUMRUTASESTA=$( cat ${PATHNETWORK}  | grep route | wc -l  )
	fi

	if (( $NUMRUTASDIM != $NUMRUTASESTA )); then
		echo "REVISAR - Numero de rutas dinamicas es diferente al numero de rutas estaaticas"
	fi 

	printf "\n%80s\n" "Display TCP - UDP Ports connections(netstat -tupan):"
	put_line 80
	netstat -tulpn
	put_line 80

	test -f ${FILETMP} && rm -f ${FILETMP} 

}

show_hba_card()
{

	CHECKHBA=$(lspci | grep Fibre)
	if [[ ! -z ${CHECKHBA} ]]; then
		printf "\n%80s\n" "Information of HBA Card Installed on the Host:"
		put_line 80
		lspci | grep Fibre
		put_line 80

		printf "\n%80s\n" "Details of HBA Card Installed on the Host:"
		put_line 80
		for ind in $( lspci | grep Fibre | awk '{ print $1 '}); do 
			lspci -v -s $ind; 
		done
		put_line 80

		printf "\n%80s\n" "HBA Port and Device Block:"
		put_line 80
		for IDSLOT in $( ls -l /sys/class/scsi_host | grep -v total |  awk '{ print $11 }' | awk -F'/' '$6 ~ /^[0-9]+/{ print $6 }' | awk -F: '{print $2}' | uniq ); do 
		  CHECKDIR=$(ls -l /sys/class/pci_bus/0000\:${IDSLOT}/device/0000\:${IDSLOT}\:00.0/host*/rport-*/target*/*/block/*/stat 2> /dev/null )
		  [[ ! -z ${CHECKDIR} ]] && (
		    echo "Port of pcs Slot: 0000:${IDSLOT}" 
		    find   /sys/class/pci_bus/0000\:${IDSLOT}/device/0000\:${IDSLOT}\:00.0/host*/rport-*/target*/*/block/*/stat | awk -F'/' 'BEGIN{ printf "| %-10s | %-6s|\n" ,"HBA Port", "Device" }{printf "| %-10s | %-6s|\n" ,$11, $13}' 
		  )
		  echo " "
		done
		put_line 80
	fi

  test -d /sys/class/fc_host && ( 
		printf "\n%80s\n" "Get HBA WWNA info(/sys/class/fc_host/\$PORT/port_name):"
		put_line 80
		echo " "
		put_line 43
		printf "| %-8s | %-28s |\n" "FC_host" "WWN"
		for port in $(ls /sys/class/fc_host/ ); do 
		  test -f /sys/class/fc_host/${port}/port_name && (
		    WWWN=$( cat /sys/class/fc_host/${port}/port_name | sed 's/^0x//g;s/../&:/g;s/:$//' );
		    printf "| %-8s | %-28s |\n" "$port" "$WWWN"
		  )
		done 
		put_line 43
		echo " "
		put_line 80
	)

}

show_imm_server()
{

	local CHECKIMM
	local CHECKVIRTUAL

	CHECKVIRTUAL=$(dmesg | grep "Hypervisor detected")
	if [[ -z ${CHECKVIRTUAL} ]]; then
		CHECKIMM=$(cat /proc/modules  | grep -i ipmi)
		if [[ ! -z ${CHECKIMM} ]]; then
			test -f /usr/bin/ipmitool && (
				printf "\n%80s\n" "Show information of IMM(ipmitool lan print 1):"
				put_line 80
				ipmitool lan print 1 2> /dev/null
				ipmitool lan print 2 2> /dev/null
				put_line 80
				)
		fi
	fi
	
}


# Linux / UNIX Crontab File Location
# CentOS/Red Hat/RHEL/Fedora/Scientific Linux – /var/spool/cron/ (user cron location /var/spool/cron/vivek)
# Debian / Ubuntu Linux – /var/spool/cron/crontabs/ (user cron location /var/spool/cron/crontabs/vivek)

get_crontab_users()
{
  printf "\n%80s\n" "Crontab of Users(crontab USER):"
  put_line 80

  TMPCRONT="${PATHTEMP}/tmpcrontab.$$"
  touch $TMPCRONT
  put_line 40
  if [[ "${OSLINUXDIST}" =~ "SUSE" ]]; then
  	CRONTABDIR="/var/spool/cron/tabs /var/spool/cron/lastrun"
  	for ind in $(echo $CRONTABDIR); 
  	do 
  		for user in $( ls -l ${ind} | grep  -v total  | grep -v core |  awk '{ print $9 }' );
  		do
	      cat ${ind}/${user} > $TMPCRONT 2>&1
	      TEST=$(cat $TMPCRONT | grep "Cannot open a file" )
	      if [[ -z $TEST  ]]; then
	      	ACTCRON=$(cat $TMPCRONT| grep -v '^\#' | wc -l  | sed 's/ //g' | awk '{ print $1 }')
	      	put_line 60
	      	printf "\n| %-33s | %-18s |\n" "CRON's DEL USUARIO: $user" "CRON's ACTIVOS:$ACTCRON"
	      	cat $TMPCRONT
	        put_line 60
	        echo " "
	      fi  			

  		done
  	done
  	

  else
  	if [[ ! -z $CHECKDEB ]]; then
	 		CRONTABDIR="/var/spool/cron/crontabs"
	 	else
	 		CRONTABDIR="/var/spool/cron"
	 	fi
	#   for user in $(lsuser ALL | awk '{ print $1 }' ); 
	  if [[ -d ${CRONTABDIR} ]]; then
	    
	    for user in $( ls -l ${CRONTABDIR} | grep  -v total  | grep -v core |  awk '{ print $9 }' ); 
	    do 
	      #su - $user  -c "crontab -l " > $TMPCRONT 2>&1
	      cat ${CRONTABDIR}/${user} > $TMPCRONT 2>&1
	      TEST=$(cat $TMPCRONT | grep "Cannot open a file" )
	      if [[ -z $TEST  ]]; then
	      	ACTCRON=$(cat $TMPCRONT| grep -v '^\#' | wc -l  | sed 's/ //g' | awk '{ print $1 }')
	      	put_line 60
	      	printf "\n| %-33s | %-18s |\n" "CRON's DEL USUARIO: $user" "CRON's ACTIVOS:$ACTCRON"
	      	cat $TMPCRONT
	        put_line 60
	        echo " "
	      fi
	    done
	  fi


  fi
  
  test -f $TMPCRONT && rm -f $TMPCRONT 

  put_line 80

}


show_LVM_config()
{

	test -f /proc/partitions && (
		printf "\n%80s\n" "Partition Block Allocation Information(cat /proc/partitions):"
		put_line 80
		cat /proc/partitions
		put_line 80

		)

	test -f && (
		printf "\n%80s\n" "List the Partition Tables for the Specified devices(fdisk -l):"
		put_line 80
		/sbin/fdisk -l | grep -e '^Disk' -e 'System$' -e '^/dev' | grep -v 'identifier'
		put_line 80
	)

	test -f /sbin/pvdisplay && (
		printf "\n%80s\n" "Display Attributes of a Physical Volume(pvdisplay):"
		put_line 80
		/sbin/pvdisplay
		put_line 40

		put_line 80
		)

	test -f /sbin/vgdisplay && (
		printf "\n%80s\n" "Display Attributes of Volume Group(vgdisplay):"
		put_line 80
		/sbin/vgdisplay
		put_line 80
		)

	test -f /sbin/lvdisplay && (
		printf "\n%80s\n" "Display Attributes of Logical Volume(lvdisplay):"
		put_line 80
		/sbin/lvdisplay
		put_line 80
		)

	
	test -f /sbin/pvs && (
		printf "\n%80s\n" "Report Information about Physical Volumes(pvs):"
		put_line 80
		/sbin/pvs 
		put_line 80
		)

	test -f /sbin/vgs && (
		printf "\n%80s\n" "Report Information about Volumes Group:"
		put_line 80
		/sbin/vgs
		put_line 80
		)

	test -f /sbin/lvs && (
		printf "\n%80s\n" "Report Information about Logical Volumes:"
		put_line 80
		/sbin/lvs 
		put_line 80
		)
	
	VARCHECKACL=$(grep -i acl /boot/config* | grep 'POSIX_ACL=Y')
	if [[ ! -z ${VARCHECKACL} ]]; then
		printf "\n%80s\n" "Permissions ACL of FileSystems:"
		put_line 80
		test -f /sbin/tune2fs && (
			for FS in $(df -Plh | awk '{print $1}' | egrep -v '^(Mounted|/dev)'); do 
				VARENABLEACL=$( tune2fs -l ${FS} | grep acl )
				if [[ ! -z ${VARENABLEACL} ]]; then
					getfacl ${FS}
				fi
			done
		)
		put_line 80

	fi

	printf "\n%80s\n" "Permissions of FileSystems Mounted:"
	put_line 80
	for FS in $(df -Plh | awk '{print $6}' | egrep -v '^(Mounted|/dev)'); do 
		ls -ld $FS; 
	done
	put_line 80

	printf "\n%80s\n" "File /etc/fstab:"
	put_line 80
	cat /etc/fstab
	put_line 80


}

show_PCI_device()
{
	test -f /sbin/lspci && (
		printf "\n%80s\n" "PCI's buses in the System and Devices Connected(lspci):"
		put_line 80
		/sbin/lspci
		put_line 80
	)

}

get_users()
{
	local TMPVARENV
	local NUMLINES

	TMPVARENV="${PATHTEMP}/tmpcrontab.$$"
  printf "\n%80s\n" "Users of System:"
  put_line 80
  cat /etc/passwd 
  put_line 80

  printf "\n%80s\n" "Password of Users of System:"
  put_line 80
  cat /etc/shadow
  put_line 80

  printf "\n%80s\n" "Groups of System:"
  put_line 80
  cat /etc/group
  put_line 80

  printf "\n%80s\n" "Variables of Environment:"
  put_line 80
  for iduser in $( grep -v '^ibm' /etc/passwd | awk -F: '$7 !~ /nologin/{ print $1 }' | grep -ve sync -ve shutdown -ve halt -ve ssh -ve bin -ve at -ve daemon -ve ftp -ve games -ve gdm -ve haldaemon -ve lp -ve mail -ve main -ve messagebus -ve news -ve nobody -ve ntp -ve pesign -ve polkituser -ve man -ve postfix -ve pulse -ve puppet -ve suse-ncc -ve uucp -ve uuidd  ); do
  	su $iduser -c "env" > ${TMPVARENV}
  	NUMLINES=$(wc -l ${TMPVARENV} | awk '{ print $1 }'  )
  	put_line 47
  	printf "\n| %-18s | %-12s | %-4s | \n" "Variables's of User:" "$iduser" "${NUMLINES}"
  	put_line 47
  	cat ${TMPVARENV}
  	put_line 47
  	echo " "
  done
  put_line 80
  test -f ${TMPVARENV} && rm -f ${TMPVARENV}



}


GPFS_CLUSTER_INFORMATION()
{
  printf "\n%80s\n" "GPFS Cluster Information(mmlscluster):"
  put_line 80
  /usr/lpp/mmfs/bin/mmlscluster
  put_line 80

}

GPFS_CLUSTER_SUMMARY()
{
  printf "\n%80s\n" "GPFS Cluster Summary(mmgetstat -s):"
  put_line 80
  /usr/lpp/mmfs/bin/mmgetstate -s
  put_line 80

}

GPFS_NODES_INFORMATION()
{
  printf "\n%80s\n" "GPFS Nodes Information(mmgetstat -a):"
  put_line 80
  /usr/lpp/mmfs/bin/mmgetstate -a 
  /usr/lpp/mmfs/bin/mmgetstate -La 
  put_line 80

}

GPFS_NSD()
{
  printf "\n%80s\n" "GPFS Network Shared Disk NSD(mmlsnsd):"
  put_line 80
  /usr/lpp/mmfs/bin/mmlsnsd
  /usr/lpp/mmfs/bin/mmlsnsd -m
  /usr/lpp/mmfs/bin/mmlsnsd -L
  put_line 80
}

GPFS_FILESYSTEMS()
{
  printf "\n%80s\n" "GPFS Filesystems(mmlsfs all):"
  put_line 80
  /usr/lpp/mmfs/bin/mmlsfs all 
  put_line 80
}

GPFS_REMOTE_CLUSTER()
{
  printf "\n%80s\n" "GPFS Remote Cluster Information(mmremotecluster show all):"
  put_line 80
  /usr/lpp/mmfs/bin/mmremotecluster show all 
  put_line 80

}

GPFS_REMOTE_FILESYSTEMS()
{
  printf "\n%80s\n" "GPFS Remote Filesystem Information(mmremotefs show all):"
  put_line 80
  /usr/lpp/mmfs/bin/mmremotefs show all 
  put_line 80
  
}

GPFS_LOGS()
{
  printf "\n%80s\n" "GPFS last Logs):"
  put_line 80
  tail -50 /var/adm/ras/mmfs.log.latest 
  put_line 80

}

show_firewall_rules()
{
	test -f /sbin/iptables && ( 
	  printf "\n%80s\n" "Show Iptables Firewall Rules(iptables -L):"
	  put_line 80
		/sbin/iptables -L -v -n --line-numbers
		put_line 80
	)
}


show_SELINUX()
{

	test -f /usr/sbin/sestatus && ( 
	  printf "\n%80s\n" "Show Status SELINUX:"
	  put_line 80
	  /usr/sbin/sestatus
	  put_line 80
	)
	test -f /etc/selinux/config && (
	  printf "\n%80s\n" "Show Config file /etc/selinux/config :"
	  put_line 80	  
		cat /etc/selinux/config
	  put_line 80
	  test -f /usr/sbin/semanage && (
		  printf "\n%80s\n" "Show map of user of SELINUX(semanage login -l):"
		  put_line 80	  
	  	/usr/sbin/semanage login -l 
	  	put_line 80	  
	  )
	)
}

get_status_agentITM()
{
  if [ -f /opt/IBM/ITM/bin/cinfo ]; then 
    printf "\n%80s\n" "State of ITM Agent(/opt/IBM/ITM/bin/cinfo -r):"
    put_line 102
    /opt/IBM/ITM/bin/cinfo -r ;
    put_line 102
    
  fi
}
show_ReportFS()
{
  printf "\n%80s\n" "Report Filesystem Disk Space Usage (df -mP | $NDF FS):"
  put_line 80
  df -mP
  put_line 80
}

get_mount()
{
  mount > $MOUNT
}


show_mount()
{
  NUMMOUNT=$(cat $MOUNT | wc -l | sed 's/ //g' )
  (( NUMMOUNT = NUMMOUNT -2 ))
  printf "\n%80s\n" "File System Available (mount | $NUMMOUNT FS mounts):"
  
  put_line 80
  cat $MOUNT
  put_line 80
}

show_serviceNTP()
{
  printf "\n%80s\n" "Check NTP Service:"
  FILETTMP="${PATHTEMP}/NTPHA.$$"
  touch ${FILETTMP}
  put_line 80
  local num
  local a 

  SRVNTP=$( grep '^server' /etc/ntp.conf  | tail -1 )
  CMDNTPDATE=$( echo ${SRVNTP} | awk '{print "/usr/sbin/ntpdate -d " $2 }' )
  echo $CMDNTPDATE | sh > ${FILETTMP}
  cat ${FILETTMP}
 # VARTIME=$( grep '^offset' ${FILETTMP} | awk '{print $2 }'  ) 
 # if [[ ! -z ${VARTIME} ]]; then
 # 	VARTIME=$( echo ${VARTIME}  | grep '^0\.' | sed 's/^0\./\./g' )
  #  num=${VARTIME}
  #  (( ${VARTIME} < 0 )) && num=$(( ${VARTIME} * -1 ))
  #  if (( $num > 61 )); then 
  #    if [ "${VARTIME}" -ge 0 ] ; then 
  #      printf "%-40s\n" "REVISAR NTP esta con $(( ${VARTIME} / 60 )) min Adelantado"; 
  #    else 
  #      a=${VARTIME}; 
  #      (( ${VARTIME} < 0 )) && a=$(( ${VARTIME} * -1 )); 
  #      printf "%-40s\n"  "REVISAR NTP esta con $(( ${a} / 60 )) min Retrasado"; 
  #    fi ; 
  #  else 
  #    printf "%-40s\n"  "Desface es de ${VARTIME} segundos"; 
  #  fi
  #else
    printf "%-40s\n"  "REVISAR NTP - No se puede ejecutar ntpdate" 
  #fi
        
  test -f ${FILETTMP} && rm -f ${FILETTMP}
  
}

show_RAID_disk()
{
	local RAIDCLI_CMD

  if [ -e /opt/MegaRAID/storcli/storcli64 ]; then
  	RAIDCLI_CMD=/opt/MegaRAID/storcli/storcli64
  elif [ -e /opt/MegaRAID/MegaCli/MegaCli64 ] ; then
  	RAIDCLI_CMD=/opt/MegaRAID/MegaCli/MegaCli64
  fi

	if [ ! -z "${RAIDCLI_CMD}" ]; then

		printf "%80s\n" "Display Controller properties"
		put_line 80
		${RAIDCLI_CMD} /c0 show 
		put_line 80

		printf "%80s\n" "Display all Megaraid controller Configuration overview"
		put_line 80
		${RAIDCLI_CMD} show all
		put_line 80		

		printf "%80s\n" "List all physical disks"
		put_line 80
		${RAIDCLI_CMD} /call/dall show
		put_line 80

		printf "%80s\n" "List a physical disk detail info"
		put_line 80
		${RAIDCLI_CMD} /c0/d0 show all
		put_line 80		

		printf "%80s\n" "List Virtual Drive info"
		put_line 80
		${RAIDCLI_CMD} /c0/vall show 
		put_line 80

		printf "%80s\n" "Display one virtual drive detail info:"
		put_line 80
		${RAIDCLI_CMD} /c0/v0 show all
		put_line 80

		printf "%80s\n" "View information about the battery backup-up unit state"
		put_line 80
		${RAIDCLI_CMD} /c0/dall show
		put_line 80

	fi
}

show_packages_installed()
{

	if [[ "${OSLINUXDIST}" =~ "Red" ]]; then

		printf "%80s\n" "List All Packages Installed(rpm -aq):"
		put_line 80
		rpm -aq
		put_line 80

		printf "%80s\n" "Show yum history(yum history list all):"
		put_line 80
		yum history list all
		put_line 80

		printf "%80s\n" "Show yum history Statistics(yum history stats):"
		put_line 80
		yum history stats
		put_line 80

		printf "%80s\n" "Show yum Info of Repositories(yum repoinfo):"
		put_line 80
		yum repoinfo
		put_line 80

	elif [[ "${OSLINUXDIST}" =~ "SUSE" ]]; then

		printf "%80s\n" "List All Packages Installed:"
		put_line 80
		zypper se --installed-only
		put_line 80


	elif [[ "${OSLINUXDIST}" =~ "Debian" ]]; then
		
		printf "%80s\n" "List All Packages Installed:"
		put_line 80
		dpkg -l #|awk '/^[hi]i/{print $2}'
		put_line 80


	fi

}


set_files_temp

get_host

show_date_server > ${LOGFILE} 2>&1

(
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[0]}"
	NUM=$(echo ${#SectionSnapshot[0]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"

	show_resume_kernel

	show_imm_server

	show_info_bios

	show_info_system

	show_resumen_server_name

	#SectionSnapshot[1]="$PROCMEM"
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[1]}"
	NUM=$(echo ${#SectionSnapshot[1]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"	

	show_info_cpu

	show_memory_details

	#SectionSnapshot[2]="$NETWORK"
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[2]}"
	NUM=$(echo ${#SectionSnapshot[2]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"

	show_interfaces

	show_network_inter

	show_firewall_rules

	show_SELINUX

	#SectionSnapshot[3]="$LVM"
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[3]}"
	NUM=$(echo ${#SectionSnapshot[3]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"

	show_ReportFS

	get_mount

	show_mount

	show_LVM_config

	#SectionSnapshot[4]="$ADAPTERS"
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[4]}"
	NUM=$(echo ${#SectionSnapshot[4]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"

	show_hba_card

	show_PCI_device	

	show_list_device_Storage

	show_RAID_disk

	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[5]}"
	NUM=$(echo ${#SectionSnapshot[5]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"


	get_status_agentITM

	show_serviceNTP

	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[6]}"
	NUM=$(echo ${#SectionSnapshot[6]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"	

	get_users

	get_crontab_users

	# GPFS	
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[7]}"
	NUM=$(echo ${#SectionSnapshot[7]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"	


	if [[ -f /usr/lpp/mmfs/bin/mmlscluster ]]; then
		GPFS_CLUSTER_INFORMATION
		GPFS_CLUSTER_SUMMARY
		GPFS_NODES_INFORMATION
		GPFS_NSD
		GPFS_FILESYSTEMS
		GPFS_REMOTE_CLUSTER
		GPFS_REMOTE_FILESYSTEMS
		GPFS_LOGS
	fi

	# PACKAGES
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[8]}"
	NUM=$(echo ${#SectionSnapshot[8]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"

	show_packages_installed


	# ERROR	
	printf "\n%-80s\n" "********************************************************************************"
	printf "%80s\n" "${SectionSnapshot[9]}"
	NUM=$(echo ${#SectionSnapshot[9]})
	printf "%80s\n\n" "$(for i in $(seq 1 ${NUM}); do printf '*'; done)"

	printf "%80s\n" "Error in files of logs:"
	put_line 80
	echo " "

	LISTFILES="dmesg
	messages
	secure
	sudo.log
	"

	for ind in $( echo ${LISTFILES} ); do 
		if [[ -e "/var/log/${ind}" ]]; then
			printf "| %-19s : %-19s |\n\n" "Error in file Log" "/var/log/${ind}"
			grep -ni error "/var/log/${ind}" | head -50
			put_line 46
			echo " "
		else
			echo "Error log: /var/log/${ind}, don't exist"
		fi
	done

	put_line 80

	printf "\n\n%-80s\n" "********************************************************************************"
	printf "%-80s\n" "************************SALIDA DE COMANDOS SIN FORMATO**************************"
	printf "%-80s\n" "********************************************************************************"

	printf "\n%80s\n" "cat /etc/resolv.conf"
	put_line 80
	test -f /etc/resolv.conf && cat /etc/resolv.conf

	printf "\n%80s\n" "/sbin/chkconfig --list"
	put_line 80
	/sbin/chkconfig --list

	printf "\n%80s\n" "Show IP Alias"
	put_line 80
	ip a s 


 ) >> ${LOGFILE} 2>&1

set_index2photo ${LOGFILE}

rm_files_temp

test -f ${LOGFILE} && printf "\rSnapshot of LINUX: ${LOGFILE}                                                  \n"

