#!/bin/bash
USERSFILE="./SVusuarios-activacion.txt"
OS=$(uname)
VAR1=$1

if [ $# != 1 ]
 then
   echo -e "\033[31m ERROR - Debe pasar como parametro el nombre del grupo a crear \033[0m"
   echo "Usage: $0 $(awk -F, '{print $3}' ${USERSFILE} | sort | uniq | grep ^ibm | tr "\n"  "|")"
   exit 1
fi

mktemp()
{
  if [ $OS = "Linux" ]
  then
    $(which mktemp)
  else
    local filename=/tmp/tmp.$(date +%d%m%Y%H%M%S).${RANDOM}
    touch $filename
    echo $filename
  fi
}

checkinput()
{
  tmp=$(mktemp)
  awk -F, '{print $3":"}' ${USERSFILE} | sort | uniq | grep ^ibm > $tmp
    if ! grep "${VAR1}:" $tmp &> /dev/null
    then
        echo -e "\033[31m ERROR - Grupo invalido ${VAR1} \033[0m"
        echo "Usage: $0 $(awk -F, '{print $3}' ${USERSFILE} | sort | uniq | grep ^ibm | tr "\n"  "|")"
        rm -f $tmp
        exit 1
    fi
}

mkgroups()
{
  local cmd
  if [ $OS = "Linux" ]
  then
    cmd="groupadd"
  elif [ $OS = "AIX" ]
  then
    cmd="mkgroup"
  fi
  $cmd ${VAR1} &> /dev/null
}

mkusers()
{
  if [ -n "$1" ]
  then
    IFS=","
    for grupo in $@
    do
      echo $grupo
      grep -vE "^(#|$)" $USERSFILE | grep -w $grupo |
      while read baseuser empcode pgroup fullname
      do
        gecos="815/K/${empcode}/Kyndryl/${fullname}"
        username="kynd${baseuser}"
        f2=$(echo $baseuser | cut -c 1)
        l2=$(echo $baseuser | cut -c 2 | tr a-z A-Z)
        password=",35-${f2}647-${l2}?"
        if [ "$OS" = "Linux" ]
        then
          if ! id $username &> /dev/null
          then
            useradd -c "$gecos" -g $pgroup -G $pgroup $username
            echo "${username}:${password}" | chpasswd
            chage -d 0 $username
          else
            usermod -c "$gecos" $username
          fi
        elif [ "$OS" = "AIX" ]
        then
          if ! id $username &> /dev/null
          then
            mkuser gecos="$gecos" pgrp="$pgroup" groups="$ibmgroup" $username
            echo "${username}:${password}" | chpasswd
          else
            chuser gecos="$gecos" $username
          fi
        fi
      done
    done
    unset IFS
  fi
}

checkusers()
{
  tmp=$(mktemp)
  grep "^ibm" /etc/passwd | cut -d : -f 1 > $tmp
  grep -E "815\/[[:alpha:]]\/[[:alpha:]][[:digit:]]{5}\/" /etc/passwd | cut -d : -f 1 >> $tmp
  sort $tmp | uniq |
  while read ibmuser
  do
    tuser=$(echo $ibmuser | sed "s/^ibm//g")
    if ! grep $tuser $USERSFILE &> /dev/null
    then
      if [ "$OS" = "Linux" ]
      then
        userdel -r $ibmuser
      elif [ "$OS" = "AIX" ]
      then
        rmuser -p $ibmuser
      fi
    else
      ibmgroup=$(grep -E "^${tuser}," $USERSFILE | cut -d , -f 3)
      if [ "$OS" = "Linux" ]
      then
        usermod -g "$ibmgroup" -G "$ibmgroup" "ibm${tuser}"
      elif [ "$OS" = "AIX" ]
      then
        chuser pgrp="$ibmgroup" groups="$ibmgroup" "ibm${tuser}"
      fi
    fi
  done
  rm -f $tmp
}
checkinput
mkgroups
mkusers $@
#checkusers