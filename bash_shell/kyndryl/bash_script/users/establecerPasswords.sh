#!/bin/bash

# Lista de usuarios
usuarios=(
kyndjlfm
kyndjcoc
kyndjjac
kyndjdpr
kyndtssc
kyndajue
kyndjdar
kyndjvpp
kynddrpg
kyndcacc
kyndbsdc
kyndascy
kyndaype
kyndfmmf
kyndorcd
kyndrcgd
kyndflgi
kyndjalp
kyndwpgm
kyndjrrv
kyndjagd
kyndpaml
kyndlrpt
kyndyrch
kyndmxac
kyndvaeb
kyndjtrc
kyndwapw
kyndkpoa
kyndwccl
kyndjavc
kyndmaom
kyndjrha
kyndysam
)

# Establece la contraseña 'r3dr3dl1' para cada usuario
for user in "${usuarios[@]}"; do
  echo "$user:r3dr3dl1" | chpasswd
  if [ $? -eq 0 ]; then
    echo "Contraseña cambiada para: $user"
  else
    echo "Error cambiando contraseña para: $user"
  fi
done

