#!/bin/bash

###############################################################################
# deploy_nmon.sh
#
# Objetivo:
# - Desplegar scripts nmon desde una ruta fuente fija hacia /usr/local/bin.
# - Ajustar permisos finales segun el tipo de script o directorio.
# - Respaldar y actualizar el crontab de root con los jobs requeridos.
# - Asegurar que exista /nmondir para el trabajo de nmon.
# - Evitar activaciones duplicadas si ya hay procesos nmon corriendo.
#
# Flujo general:
# 1. Valida ejecucion como root.
# 2. Verifica que exista el paquete fuente en /home/kyndjrha/nmon.
# 3. Copia el contenido hacia /usr/local/bin.
# 4. Corrige permisos de archivos y directorios relacionados.
# 5. Respalda el crontab actual de root y agrega entradas faltantes.
# 6. Crea /nmondir si no existe.
# 7. Verifica que no haya procesos nmon activos.
# 8. Ejecuta checks iniciales para dejar el monitoreo operativo.
#
# Nota:
# Este script no intenta eliminar archivos viejos del destino ni versionar
# despliegues. Su objetivo es dejar operativo el paquete nmon esperado.
###############################################################################

# Modo estricto:
# -e  aborta ante errores no controlados
# -E  mantiene traps en funciones y subshells
# -u  falla ante variables no definidas
# -o pipefail hace fallar pipelines si un comando interno falla
set -Eeuo pipefail

# Si un glob no encuentra coincidencias, se expande a vacio en lugar de texto.
shopt -s nullglob

# Directorio fuente desde donde se toma el paquete nmon.
SRC_DIR="/home/kyndjrha/nmon"

# Directorio destino donde se instalaran scripts operativos.
DEST_DIR="/usr/local/bin"

# Directorio operativo esperado para archivos nmon.
NMONDIR="/nmondir"

# Ruta base para respaldos operativos.
BACKUP_DIR="/home/kyndjrha"

# Archivo backup del crontab de root con timestamp.
CRON_BACKUP="${BACKUP_DIR}/crontab_root_backup_$(date +%Y%m%d_%H%M%S).txt"

# Archivo temporal usado para reconstruir el crontab antes de instalarlo.
TMP_CRON="$(mktemp)"

# Siempre limpia el archivo temporal al salir.
trap 'rm -f "$TMP_CRON"' EXIT

# Logger simple con timestamp.
log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

# Logger de advertencias.
warn() {
    printf '[%s] WARN: %s\n' "$(date '+%F %T')" "$*" >&2
}

# Logger de error que termina la ejecucion.
die() {
    printf '[%s] ERROR: %s\n' "$(date '+%F %T')" "$*" >&2
    exit 1
}

# Este despliegue requiere root porque copia a /usr/local/bin, cambia
# permisos, crea directorios y modifica el crontab de root.
require_root() {
    [[ "${EUID}" -eq 0 ]] || die "Este script debe ejecutarse como root."
}

# Aplica un modo solo si el target existe.
# Si un archivo o directorio no existe, lo reporta sin cortar el proceso.
set_mode_if_exists() {
    local mode="$1"
    shift
    local target

    for target in "$@"; do
        if [[ -e "$target" ]]; then
            chmod "$mode" "$target"
            log "Permiso $mode aplicado a $target"
        else
            warn "No existe: $target"
        fi
    done
}

# Ejecuta un script solamente si existe y es ejecutable.
# Se usa al final para activar los checks nmon.
run_if_executable() {
    local script="$1"

    [[ -x "$script" ]] || die "No existe o no es ejecutable: $script"

    log "Ejecutando: $script"
    "$script"
}

main() {
    # Precheck de privilegios.
    require_root

    # Valida que el paquete fuente exista antes de cambiar nada.
    [[ -d "$SRC_DIR" ]] || die "No existe el directorio origen: $SRC_DIR"

    # Muestra el contenido actual del destino como referencia operativa.
    log "Verificando contenido actual de $DEST_DIR"
    ls -l "$DEST_DIR" || true

    # Copia el paquete fuente al destino manteniendo atributos basicos.
    log "Copiando scripts desde $SRC_DIR hacia $DEST_DIR"
    cp -a "$SRC_DIR"/. "$DEST_DIR"/

    # Aplica modo 500 a familias conocidas de scripts de ejecucion.
    log "Asignando permisos a ges_a*, nmon_* y script*"
    while IFS= read -r -d '' file; do
        chmod 500 "$file"
        log "Permiso 500 aplicado a $file"
    done < <(find "$DEST_DIR" -maxdepth 1 -type f \( -name 'ges_a*' -o -name 'nmon_*' -o -name 'script*' \) -print0)

    # Ajustes puntuales para archivos y directorios con permisos especiales.
    log "Asignando permisos especiales"
    set_mode_if_exists 700 "$DEST_DIR/nmon" "$DEST_DIR/foto.sh"
    set_mode_if_exists 755 "$DEST_DIR/ges_script_p" "$DEST_DIR/ges_script_u"
    set_mode_if_exists 500 "$DEST_DIR/cargaTWS.sh"

    # Si existe ges_script_p, sus archivos internos quedan como 500.
    if [[ -d "$DEST_DIR/ges_script_p" ]]; then
        find "$DEST_DIR/ges_script_p" -maxdepth 1 -type f -exec chmod 500 {} +
        log "Permiso 500 aplicado a archivos de $DEST_DIR/ges_script_p"
    else
        warn "No existe el directorio $DEST_DIR/ges_script_p"
    fi

    # Si existe ges_script_u, sus archivos internos quedan como 500.
    if [[ -d "$DEST_DIR/ges_script_u" ]]; then
        find "$DEST_DIR/ges_script_u" -maxdepth 1 -type f -exec chmod 500 {} +
        log "Permiso 500 aplicado a archivos de $DEST_DIR/ges_script_u"
    else
        warn "No existe el directorio $DEST_DIR/ges_script_u"
    fi

    # Lista el estado final de permisos para una revision manual rapida.
    log "Verificando permisos finales"
    ls -l "$DEST_DIR" || true
    [[ -d "$DEST_DIR/ges_script_p" ]] && ls -l "$DEST_DIR/ges_script_p" || true
    [[ -d "$DEST_DIR/ges_script_u" ]] && ls -l "$DEST_DIR/ges_script_u" || true

    # Respaldar el crontab actual de root antes de cualquier cambio.
    log "Respaldando crontab actual en $CRON_BACKUP"
    if crontab -l > "$CRON_BACKUP" 2>/dev/null; then
        log "Backup del crontab realizado"
    else
        : > "$CRON_BACKUP"
        warn "No existia crontab previo para root"
    fi

    # Carga el crontab actual a un archivo temporal; si no existe, sigue vacio.
    crontab -l > "$TMP_CRON" 2>/dev/null || true

    # Lista declarativa de entradas cron requeridas.
    # Formato:
    #   ruta_comando|linea_cron_completa
    declare -a CRON_ITEMS=(
        "/usr/local/bin/nmon_diario.sh|0 0 * * * /usr/local/bin/nmon_diario.sh # NMON Diario"
        "/usr/local/bin/nmon_diario_check.sh|1 * * * * /usr/local/bin/nmon_diario_check.sh >/dev/null 2>&1"
        "/usr/local/bin/nmon_mensual.sh|0 0 1 * * /usr/local/bin/nmon_mensual.sh # NMON Mensual"
        "/usr/local/bin/nmon_mensual_check.sh|1 * * * * /usr/local/bin/nmon_mensual_check.sh >/dev/null 2>&1"
        "/usr/local/bin/nmon_del_90days.sh|0 3 * * 0 /usr/local/bin/nmon_del_90days.sh"
    )

    # Evita duplicar entradas: si el comando ya esta en el crontab, no lo agrega.
    log "Validando entradas de crontab"
    for item in "${CRON_ITEMS[@]}"; do
        cmd="${item%%|*}"
        line="${item#*|}"

        if grep -Fq "$cmd" "$TMP_CRON"; then
            log "Ya existe en crontab: $cmd"
        else
            echo "$line" >> "$TMP_CRON"
            log "Agregada al crontab: $line"
        fi
    done

    # Instala el crontab resultante.
    crontab "$TMP_CRON"

    # Muestra el crontab final como evidencia operativa.
    log "Crontab final"
    crontab -l

    # Asegura que exista el directorio operativo de nmon.
    if [[ ! -d "$NMONDIR" ]]; then
        log "No existe $NMONDIR. Creando directorio..."
        mkdir -p "$NMONDIR"
    fi

    # Verifica que no haya procesos nmon activos para no generar duplicados.
    log "Verificando que no haya procesos nmon corriendo"
    RUNNING_NMON="$(ps -fea | grep -i '[n]mon' | grep -v -F "$0" || true)"

    if [[ -n "$RUNNING_NMON" ]]; then
        warn "Se encontraron procesos relacionados con nmon:"
        printf '%s\n' "$RUNNING_NMON"
        die "Deteniendo ejecucion para evitar duplicados. Revisalos antes de reintentar."
    else
        log "No hay procesos nmon en ejecucion"
    fi

    # Ejecuta los checks iniciales para dejar la operacion activa de inmediato.
    log "Activando checks"
    run_if_executable "$DEST_DIR/nmon_diario_check.sh"
    run_if_executable "$DEST_DIR/nmon_mensual_check.sh"

    # Muestra los procesos nmon despues de activar los checks.
    log "Procesos nmon luego de activar checks"
    ps -fea | grep -i '[n]mon' || true

    # Cierre exitoso del despliegue.
    log "Proceso completado correctamente"
}

# Punto de entrada principal.
main "$@"
