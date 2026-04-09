#!/bin/bash
###############################################################################
# SVprovision_users.sh
#
# Script unificado para aprovisionar usuarios en servidores Linux/AIX.
#
# Objetivo:
# - Leer un archivo CSV con la definicion de usuarios.
# - Crear primero los grupos necesarios.
# - Crear usuarios nuevos o actualizar usuarios ya existentes.
# - Ajustar comentario/GECOS, grupo primario, grupos suplementarios y home.
# - Centralizar la asignacion/reseteo de contrasena.
#
# Este script reemplaza la logica que antes estaba repartida en:
# - SVmkusers.sh
# - crear_homes.sh
# - Establecer_Comentarios_Todos_Usuarios.sh
# - Establecer_grupo_primario_users.sh
# - establecerPasswords.sh
#
# Formato esperado del archivo SVusuarios-activacion.txt:
#   usuario_base,codigo_empleado,grupo_funcional,nombre_completo
#
# Ejemplos de uso:
#   sudo ./SVprovision_users.sh
#     Procesa todos los grupos presentes en el CSV.
#
#   sudo ./SVprovision_users.sh ibmsysp ibmdbape
#     Procesa solo los usuarios cuyo grupo funcional coincida con
#     alguno de los grupos pasados como argumento.
#
#   sudo ./SVprovision_users.sh --comments-only
#     Solo corrige el comentario/GECOS de los usuarios ya existentes.
###############################################################################
set -uo pipefail

# Ruta del directorio donde vive el script.
# Se usa para ubicar el CSV en la misma carpeta sin depender del cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERSFILE="${SCRIPT_DIR}/SVusuarios-activacion.txt"

# Prefijo corporativo que se agrega a cada usuario base del CSV.
# Ejemplo: "jlfm" -> "kyndjlfm"
PREFIX="kynd"

# Grupo primario estandar.
# Replica la intencion del script legado Establecer_grupo_primario_users.sh.
PRIMARY_GROUP="users"

# Contrasena centralizada aplicada a todos los usuarios procesados.
# Replica la intencion del script legado establecerPasswords.sh.
DEFAULT_PASSWORD="r3dr3dl1"

# Permite decidir entre comandos Linux y AIX.
OS="$(uname)"

# Colores para hacer mas legible la salida por consola.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Funciones auxiliares para estandarizar mensajes.
log_ok()   { printf "${GREEN}[  OK  ]${NC} %s\n" "$*"; }
log_skip() { printf "${YELLOW}[ SKIP ]${NC} %s\n" "$*"; }
log_fail() { printf "${RED}[ FAIL ]${NC} %s\n" "$*"; }
log_info() { printf "${CYAN}[ INFO ]${NC} %s\n" "$*"; }

# Crea un grupo si no existe.
ensure_group() {
    local group_name="$1"

    if getent group "$group_name" &>/dev/null; then
        log_skip "Grupo '$group_name' ya existe."
        return 0
    fi

    if groupadd "$group_name" 2>/dev/null; then
        log_ok "Grupo '$group_name' creado."
        return 0
    fi

    log_fail "No se pudo crear el grupo '$group_name'."
    ((ERRORS++))
    return 1
}

# Validaciones previas:
# - Debe ejecutarse como root porque crea grupos, usuarios y homes.
# - El archivo CSV debe existir y ser legible.
if [[ "$EUID" -ne 0 ]]; then
    log_fail "Este script debe ejecutarse como root (use sudo)."
    exit 1
fi

if [[ ! -f "$USERSFILE" ]]; then
    log_fail "Archivo de usuarios no encontrado: $USERSFILE"
    exit 1
fi

if [[ ! -r "$USERSFILE" ]]; then
    log_fail "Sin permisos de lectura sobre: $USERSFILE"
    exit 1
fi

# Si el usuario pasa argumentos, se interpretan como un filtro por grupo
# funcional, salvo la opcion especial --comments-only.
# Esto permite aprovisionar solo una porcion del CSV o ejecutar solo la
# correccion de comentarios.
declare -A GROUP_FILTER
FILTER_ACTIVE=false
COMMENTS_ONLY=false

if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        if [[ "$arg" == "--comments-only" ]]; then
            COMMENTS_ONLY=true
            continue
        fi

        FILTER_ACTIVE=true
        GROUP_FILTER["$arg"]=1
    done
fi

if $COMMENTS_ONLY; then
    log_info "Modo activo: solo correccion de comentarios (--comments-only)."
fi

# Contadores para el resumen final.
CREATED=0
UPDATED=0
PASSWORDS_SET=0
ERRORS=0

###############################################################################
# Fase 1: creacion de grupos
#
# Antes de tocar usuarios, el script asegura que existan:
# - el grupo primario estandar (`users`)
# - los grupos funcionales declarados en la columna 3 del CSV
#
# Esto evita fallos posteriores en useradd/usermod por grupos inexistentes.
#
# En modo --comments-only esta fase se omite porque no se modifican grupos.
###############################################################################
if $COMMENTS_ONLY; then
    log_info "================================================================"
    log_info "Fase 1 omitida - modo solo comentarios"
    log_info "================================================================"
else
    log_info "================================================================"
    log_info "Fase 1 - Creacion de grupos"
    log_info "================================================================"

    # Asegura primero el grupo primario comun a todos los usuarios.
    ensure_group "$PRIMARY_GROUP"

    # Se extraen grupos unicos ignorando lineas vacias y comentarios.
    mapfile -t UNIQUE_GROUPS < <(
        grep -vE '^\s*(#|$)' "$USERSFILE" | awk -F, '{print $3}' | sort -u
    )

    for grp in "${UNIQUE_GROUPS[@]}"; do
        # Si hay filtro activo, solo se atienden los grupos solicitados.
        if $FILTER_ACTIVE && [[ -z "${GROUP_FILTER[$grp]+_}" ]]; then
            continue
        fi

        ensure_group "$grp"
    done
fi

###############################################################################
# Fase 2: aprovisionamiento de usuarios
#
# Por cada registro del CSV:
# - arma el nombre final con el prefijo corporativo
# - evita reprocesar lineas duplicadas en la misma corrida
# - crea o actualiza el usuario
# - asegura el home directory
#
# En modo --comments-only solo actualiza el comentario/GECOS del usuario si ya
# existe, sin tocar grupos, contrasena ni home.
###############################################################################
log_info ""
log_info "================================================================"
if $COMMENTS_ONLY; then
    log_info "Fase 2 - Correccion de comentarios"
else
    log_info "Fase 2 - Aprovisionamiento de usuarios"
fi
log_info "================================================================"

# Registro en memoria para evitar procesar el mismo usuario dos veces si el
# CSV trae lineas duplicadas.
declare -A SEEN_USERS

while IFS=',' read -r baseuser empcode pgroup fullname; do
    # Ignora comentarios y lineas vacias.
    [[ "$baseuser" =~ ^[[:space:]]*(#|$) ]] && continue

    # Limpia espacios alrededor de cada campo.
    baseuser="$(echo "$baseuser" | xargs)"
    empcode="$(echo "$empcode" | xargs)"
    pgroup="$(echo "$pgroup" | xargs)"
    fullname="$(echo "$fullname" | xargs)"

    # Si se pidio filtrar por grupo, se descartan usuarios fuera de ese set.
    if $FILTER_ACTIVE && [[ -z "${GROUP_FILTER[$pgroup]+_}" ]]; then
        continue
    fi

    username="${PREFIX}${baseuser}"

    # Evita reprocesar duplicados dentro de la misma ejecucion.
    if [[ -n "${SEEN_USERS[$username]+_}" ]]; then
        log_skip "${username}: linea duplicada, ya procesado."
        continue
    fi
    SEEN_USERS["$username"]=1

    # GECOS/comentario que queda visible en /etc/passwd o equivalente.
    # Replica la logica del script legado Establecer_Comentarios_Todos_Usuarios.sh.
    gecos="815/K/${empcode}/Kyndryl/${fullname}"

    printf "\n${BOLD}>>> Procesando: ${username}${NC}  (grupo: ${pgroup})\n"

    if $COMMENTS_ONLY; then
        if id "$username" &>/dev/null; then
            if usermod -c "$gecos" "$username" 2>/dev/null; then
                log_ok "${username}: comentario/GECOS actualizado."
                ((UPDATED++))
            else
                log_fail "${username}: error al actualizar comentario/GECOS."
                ((ERRORS++))
            fi
        else
            log_skip "${username}: usuario no existe, comentario no aplicado."
        fi
        continue
    fi

    # 2a. Crear o actualizar el usuario.
    if id "$username" &>/dev/null; then
        # Si ya existe, no se recrea: solo se actualiza su comentario,
        # grupo primario y grupo suplementario para mantener consistencia.
        # El grupo primario queda fijo en `users` y el funcional se toma del CSV.
        if usermod -c "$gecos" -g "$PRIMARY_GROUP" -G "$pgroup" "$username" 2>/dev/null; then
            log_ok "${username}: GECOS, grupo primario y grupo funcional actualizados."
        else
            log_fail "${username}: error al actualizar usermod."
            ((ERRORS++))
        fi
        ((UPDATED++))
    else
        # Si no existe, se crea segun el sistema operativo detectado.
        if [[ "$OS" == "Linux" ]]; then
            if useradd -m -c "$gecos" -g "$PRIMARY_GROUP" -G "$pgroup" "$username" 2>/dev/null; then
                log_ok "${username}: usuario creado."
            else
                log_fail "${username}: error al crear usuario."
                ((ERRORS++))
                continue
            fi
        elif [[ "$OS" == "AIX" ]]; then
            if mkuser gecos="$gecos" pgrp="$PRIMARY_GROUP" groups="$pgroup" "$username" 2>/dev/null; then
                log_ok "${username}: usuario creado (AIX)."
            else
                log_fail "${username}: error al crear usuario (AIX)."
                ((ERRORS++))
                continue
            fi
        else
            log_fail "${username}: OS no soportado ($OS)."
            ((ERRORS++))
            continue
        fi

        ((CREATED++))
    fi

    # 2b. Asignar o resetear contrasena.
    # Se aplica tanto a usuarios nuevos como existentes para centralizar
    # el comportamiento de establecerPasswords.sh en un solo flujo.
    if echo "${username}:${DEFAULT_PASSWORD}" | chpasswd 2>/dev/null; then
        log_ok "${username}: contrasena aplicada."
        ((PASSWORDS_SET++))
    else
        log_fail "${username}: error al establecer contrasena."
        ((ERRORS++))
    fi

    # 2c. Verificar que el directorio home exista.
    # Si getent no devuelve home, se asume la ruta estandar /home/usuario.
    HOME_DIR="$(getent passwd "$username" | cut -d: -f6)"
    if [[ -z "$HOME_DIR" ]]; then
        HOME_DIR="/home/${username}"
    fi

    if [[ -d "$HOME_DIR" ]]; then
        log_skip "${username}: home ya existe (${HOME_DIR})."
    else
        if mkdir -p "$HOME_DIR" 2>/dev/null; then
            chown "${username}:${pgroup}" "$HOME_DIR"
            chmod 700 "$HOME_DIR"
            log_ok "${username}: home creado (${HOME_DIR})."
        else
            log_fail "${username}: no se pudo crear home (${HOME_DIR})."
            ((ERRORS++))
        fi
    fi
done < "$USERSFILE"

###############################################################################
# Resumen final
###############################################################################
echo ""
log_info "================================================================"
log_info "                           RESUMEN"
log_info "================================================================"
printf "${GREEN}  Usuarios creados                 : %d${NC}\n" "$CREATED"
printf "${CYAN}  Usuarios existentes actualizados : %d${NC}\n" "$UPDATED"
printf "${YELLOW}  Contrasenas aplicadas            : %d${NC}\n" "$PASSWORDS_SET"
printf "${RED}  Errores                          : %d${NC}\n" "$ERRORS"
log_info "================================================================"

if [[ "$ERRORS" -gt 0 ]]; then
    exit 1
fi

exit 0
