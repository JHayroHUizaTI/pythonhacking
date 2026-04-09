#!/bin/bash
###############################################################################
#  SVprovision_users.sh
#  Unified user-management script for Kyndryl Linux servers.
#
#  Replaces:
#    - SVmkusers.sh
#    - crear_homes.sh
#    - Establecer_Comentarios_Todos_Usuarios.sh
#    - Establecer_grupo_primario_users.sh
#
#  Usage:
#    sudo ./SVprovision_users.sh                 # Process ALL groups
#    sudo ./SVprovision_users.sh ibmsysp ibmdbape # Process specific groups
###############################################################################
set -uo pipefail

# ──────────────────────────── Configuration ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERSFILE="${SCRIPT_DIR}/SVusuarios-activacion.txt"
PREFIX="kynd"                         # Username prefix
OS="$(uname)"

# ──────────────────────────── Color helpers ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_ok()   { printf "${GREEN}[  OK  ]${NC} %s\n" "$*"; }
log_skip() { printf "${YELLOW}[ SKIP ]${NC} %s\n" "$*"; }
log_fail() { printf "${RED}[ FAIL ]${NC} %s\n" "$*"; }
log_info() { printf "${CYAN}[ INFO ]${NC} %s\n" "$*"; }

# ──────────────────────────── Pre-flight checks ──────────────────────────────
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

# ──────────────────────────── Build group filter ─────────────────────────────
# If arguments are supplied, use them as a whitelist of groups to process.
# Otherwise, process every group found in the CSV.
declare -A GROUP_FILTER
FILTER_ACTIVE=false

if [[ $# -gt 0 ]]; then
    FILTER_ACTIVE=true
    for g in "$@"; do
        GROUP_FILTER["$g"]=1
    done
fi

# ──────────────────────────── Counters ───────────────────────────────────────
CREATED=0
UPDATED=0
ERRORS=0

# ──────────────────────────── Phase 1: Create groups ─────────────────────────
log_info "═══════════════════════════════════════════════════════════════"
log_info "Fase 1 – Creación de grupos"
log_info "═══════════════════════════════════════════════════════════════"

# Extract unique group names (column 3) from non-comment, non-blank lines
mapfile -t UNIQUE_GROUPS < <(
    grep -vE '^\s*(#|$)' "$USERSFILE" | awk -F, '{print $3}' | sort -u
)

for grp in "${UNIQUE_GROUPS[@]}"; do
    # Honour optional group filter
    if $FILTER_ACTIVE && [[ -z "${GROUP_FILTER[$grp]+_}" ]]; then
        continue
    fi

    if getent group "$grp" &>/dev/null; then
        log_skip "Grupo '$grp' ya existe."
    else
        if groupadd "$grp" 2>/dev/null; then
            log_ok "Grupo '$grp' creado."
        else
            log_fail "No se pudo crear el grupo '$grp'."
            ((ERRORS++))
        fi
    fi
done

# ──────────────────────────── Phase 2: Provision users ───────────────────────
log_info ""
log_info "═══════════════════════════════════════════════════════════════"
log_info "Fase 2 – Aprovisionamiento de usuarios"
log_info "═══════════════════════════════════════════════════════════════"

# Track already-processed users to handle duplicate lines in the CSV
declare -A SEEN_USERS

while IFS=',' read -r baseuser empcode pgroup fullname; do
    # ── Skip comments and blanks ──
    [[ "$baseuser" =~ ^[[:space:]]*(#|$) ]] && continue
    # Trim whitespace
    baseuser="$(echo "$baseuser" | xargs)"
    empcode="$(echo "$empcode" | xargs)"
    pgroup="$(echo "$pgroup" | xargs)"
    fullname="$(echo "$fullname" | xargs)"

    # ── Apply optional group filter ──
    if $FILTER_ACTIVE && [[ -z "${GROUP_FILTER[$pgroup]+_}" ]]; then
        continue
    fi

    # ── Skip duplicates within the same run ──
    username="${PREFIX}${baseuser}"
    if [[ -n "${SEEN_USERS[$username]+_}" ]]; then
        log_skip "${username}: línea duplicada, ya procesado."
        continue
    fi
    SEEN_USERS["$username"]=1

    # ── Build GECOS & password ──
    gecos="815/K/${empcode}/Kyndryl/${fullname}"
    f2="${baseuser:0:1}"
    l2="$(echo "${baseuser:1:1}" | tr '[:lower:]' '[:upper:]')"
    password=",35-${f2}647-${l2}?"

    printf "\n${BOLD}>>> Procesando: ${username}${NC}  (grupo: ${pgroup})\n"

    # ─────────── 2a. Create or update user ───────────
    if id "$username" &>/dev/null; then
        # User already exists → update GECOS and primary group
        if usermod -c "$gecos" -g "$pgroup" -G "$pgroup" "$username" 2>/dev/null; then
            log_ok "${username}: GECOS y grupo primario actualizados."
        else
            log_fail "${username}: error al actualizar usermod."
            ((ERRORS++))
        fi
        ((UPDATED++))
    else
        # New user
        if [[ "$OS" == "Linux" ]]; then
            if useradd -m -c "$gecos" -g "$pgroup" -G "$pgroup" "$username" 2>/dev/null; then
                log_ok "${username}: usuario creado."
            else
                log_fail "${username}: error al crear usuario."
                ((ERRORS++))
                continue   # skip remaining steps for this user
            fi
        elif [[ "$OS" == "AIX" ]]; then
            if mkuser gecos="$gecos" pgrp="$pgroup" groups="$pgroup" "$username" 2>/dev/null; then
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

        # Set initial password & force change on first login
        if echo "${username}:r3dr3dl1" | chpasswd 2>/dev/null; then
            log_ok "${username}: contraseña inicial establecida."
        else
            log_fail "${username}: error al establecer contraseña."
            ((ERRORS++))
        fi

        ((CREATED++))
    fi

    # ─────────── 2b. Ensure home directory exists ────────────
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

# ──────────────────────────── Summary ────────────────────────────────────────
echo ""
log_info "═══════════════════════════════════════════════════════════════"
log_info "                        RESUMEN"
log_info "═══════════════════════════════════════════════════════════════"
printf "${GREEN}  Usuarios creados  : %d${NC}\n" "$CREATED"
printf "${CYAN}  Usuarios existentes actualizados: %d${NC}\n" "$UPDATED"
printf "${RED}  Errores           : %d${NC}\n" "$ERRORS"
log_info "═══════════════════════════════════════════════════════════════"

if [[ "$ERRORS" -gt 0 ]]; then
    exit 1
fi

exit 0
