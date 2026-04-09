#!/bin/bash

USERS=(
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

for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
        HOME_DIR=$(getent passwd "$user" | cut -d: -f6)
        GROUP=$(id -gn "$user")

        if [ ! -d "$HOME_DIR" ]; then
            mkdir -p "$HOME_DIR"
            chown "$user:$GROUP" "$HOME_DIR"
            chmod 700 "$HOME_DIR"
            echo "Creado el home de $user en $HOME_DIR"
        else
            echo "El home de $user ya existe: $HOME_DIR"
        fi
    else
        echo "Usuario no existe: $user"
    fi
done

