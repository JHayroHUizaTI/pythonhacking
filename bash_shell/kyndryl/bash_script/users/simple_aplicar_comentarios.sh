#!/usr/bin/env bash

###############################################################################
# simple_aplicar_comentarios.sh
#
# Utilidad de apoyo para validar y aplicar comentarios (GECOS) en usuarios.
#
# Casos de uso:
# - Aplicar comentarios a usuarios existentes usando `usermod -c`
# - Comparar una fuente de usuarios contra un archivo passwd
# - Detectar usuarios sin comentario en un passwd real o exportado
#
# Modos principales:
# - apply:
#     Toma un archivo fuente y actualiza el comentario de cada usuario.
# - apply-system:
#     Genera un CSV simple desde passwd para usuarios del sistema, aplica
#     un comentario fijo y luego valida el resultado, incluyendo a root,
#     nobody y nfsnobody si existen.
#     En este flujo se excluyen cuentas con shell /bin/sh o /bin/bash
#     para no comentar usuarios interactivos, salvo root.
# - check-source:
#     Compara lo esperado desde el archivo fuente contra un archivo passwd.
# - check-passwd:
#     Revisa un archivo passwd y reporta usuarios que no tienen comentario.
#
# Formatos de entrada soportados:
# - csv:
#     usuario,comentario
# - roster:
#     usuario,codigo,grupo,nombre
#
# Nota:
# Este script esta pensado como herramienta simple de validacion/aplicacion.
# A diferencia de SVprovision_users.sh, aqui el foco esta solo en comentarios
# y validaciones relacionadas con el campo GECOS.
###############################################################################
set -u

# Nombre del script para reutilizarlo en mensajes de ayuda.
SCRIPT_NAME="$(basename "$0")"

# Valores por defecto que pueden sobrescribirse por parametros.
DEFAULT_PASSWD_FILE="/etc/passwd"
DEFAULT_COMMENT_PREFIX="815/K"
DEFAULT_COMPANY="Kyndryl"
DEFAULT_USER_PREFIX="kynd"
DEFAULT_SYSTEM_SOURCE_FILE="usuarios_sistema_simple.csv"
DEFAULT_SYSTEM_UID_LIMIT=1000

# Variables de ejecucion. Se inicializan con defaults y luego parse_args
# las ajusta segun el modo y las opciones indicadas por el usuario.
mode=""
source_file=""
passwd_file="$DEFAULT_PASSWD_FILE"
format="auto"
comment_prefix="$DEFAULT_COMMENT_PREFIX"
company="$DEFAULT_COMPANY"
user_prefix="$DEFAULT_USER_PREFIX"
min_uid=""
do_backup=1
name_mode="raw"
system_comment=""
generated_source_file="$DEFAULT_SYSTEM_SOURCE_FILE"

# Muestra ayuda de uso, modos y ejemplos.
usage() {
  cat <<EOF
Uso:
  $SCRIPT_NAME apply <archivo_fuente> [opciones]
  $SCRIPT_NAME apply-system --comment TEXTO [opciones]
  $SCRIPT_NAME check-source <archivo_fuente> [opciones]
  $SCRIPT_NAME check-passwd [opciones]

Modos:
  apply         Aplica comentarios con usermod a usuarios existentes.
  apply-system  Genera, aplica y valida un comentario fijo en usuarios con UID < $DEFAULT_SYSTEM_UID_LIMIT, root, nobody y nfsnobody.
  check-source  Valida los usuarios del archivo fuente contra un archivo passwd.
  check-passwd  Escanea un archivo passwd y reporta usuarios sin comentario.

Opciones:
  --passwd FILE            Archivo passwd a validar. Default: $DEFAULT_PASSWD_FILE
  --comment TEXTO          Comentario fijo para apply-system
  --system-comment TEXTO   Alias de --comment para apply-system
  --format auto|csv|roster Formato del archivo fuente. Default: auto
  --comment-prefix TEXTO   Prefijo del comentario para formato roster. Default: $DEFAULT_COMMENT_PREFIX
  --company TEXTO          Empresa para formato roster. Default: $DEFAULT_COMPANY
  --user-prefix TEXTO      Prefijo del usuario para formato roster. Default: $DEFAULT_USER_PREFIX
  --output FILE            Archivo CSV a generar en apply-system. Default: $DEFAULT_SYSTEM_SOURCE_FILE
  --min-uid NUMERO         Solo revisa usuarios con UID mayor o igual al indicado
  --swap-name-order        Reordena nombres tipo "Apellido1 Apellido2 Nombre1" a "Nombre1 Apellido1 Apellido2"
  --no-backup              No genera backup de /etc/passwd antes de aplicar
  -h, --help               Muestra esta ayuda

Formatos soportados:
  csv     usuario,comentario
  roster  usuario,codigo,grupo,nombre

Ejemplos:
  $SCRIPT_NAME apply usuarios.csv
  $SCRIPT_NAME apply-system --comment "815/S/*PSMLNX/PE_SUPERMERCADOSPERUANOS_LINUX"
  $SCRIPT_NAME check-source "SVusuarios-activacion 5.txt" --format roster --passwd /etc/passwd
  $SCRIPT_NAME check-passwd --passwd /etc/passwd --min-uid 1000

Notas:
  - apply-system solo considera usuarios con UID menor a $DEFAULT_SYSTEM_UID_LIMIT.
  - apply-system tambien incluye explicitamente al usuario root.
  - apply-system tambien incluye explicitamente al usuario nobody.
  - apply-system tambien incluye explicitamente al usuario nfsnobody si existe.
  - apply-system excluye usuarios cuyo shell sea /bin/sh o /bin/bash, salvo root.
  - Los usuarios con UID mayor o igual a $DEFAULT_SYSTEM_UID_LIMIT no se modifican en ese flujo.
EOF
}

# Elimina espacios al inicio y al final de un texto.
trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

# Elimina el retorno de carro final.
# Sirve para procesar archivos editados en Windows.
strip_cr() {
  printf '%s' "${1%$'\r'}"
}

# Aborta la ejecucion mostrando un error.
fail() {
  echo "ERROR: $*" >&2
  exit 1
}

# Mensajes auxiliares de salida.
info() {
  echo "INFO: $*"
}

warn() {
  echo "WARN: $*"
}

# Detecta automaticamente si la fuente parece:
# - csv (2 columnas)
# - roster (4 o mas columnas)
detect_format() {
  local file="$1"
  local line columns

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(strip_cr "$line")"
    line="$(trim "$line")"
    [[ -z "$line" || "$line" == \#* ]] && continue

    IFS=',' read -r -a columns <<< "$line"
    if [[ ${#columns[@]} -eq 2 ]]; then
      echo "csv"
      return 0
    fi
    if [[ ${#columns[@]} -ge 4 ]]; then
      echo "roster"
      return 0
    fi
    break
  done < "$file"

  fail "No se pudo detectar el formato de $file"
}

# Valida que el usuario haya elegido uno de los modos soportados.
ensure_mode() {
  [[ -n "$mode" ]] || fail "Debes indicar un modo: apply, apply-system, check-source o check-passwd"
}

# Procesa argumentos de linea de comandos.
# La primera palabra clave define el modo y el resto ajusta comportamiento.
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      apply|apply-system|check-source|check-passwd)
        [[ -z "$mode" ]] || fail "Solo puedes indicar un modo"
        mode="$1"
        shift
        ;;
      --comment|--system-comment)
        [[ $# -ge 2 ]] || fail "Falta valor para $1"
        system_comment="$2"
        shift 2
        ;;
      --passwd)
        [[ $# -ge 2 ]] || fail "Falta valor para --passwd"
        passwd_file="$2"
        shift 2
        ;;
      --output)
        [[ $# -ge 2 ]] || fail "Falta valor para --output"
        generated_source_file="$2"
        shift 2
        ;;
      --format)
        [[ $# -ge 2 ]] || fail "Falta valor para --format"
        format="$2"
        shift 2
        ;;
      --comment-prefix)
        [[ $# -ge 2 ]] || fail "Falta valor para --comment-prefix"
        comment_prefix="$2"
        shift 2
        ;;
      --company)
        [[ $# -ge 2 ]] || fail "Falta valor para --company"
        company="$2"
        shift 2
        ;;
      --user-prefix)
        [[ $# -ge 2 ]] || fail "Falta valor para --user-prefix"
        user_prefix="$2"
        shift 2
        ;;
      --min-uid)
        [[ $# -ge 2 ]] || fail "Falta valor para --min-uid"
        min_uid="$2"
        shift 2
        ;;
      --swap-name-order)
        name_mode="swap_spanish"
        shift
        ;;
      --no-backup)
        do_backup=0
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        fail "Opcion no reconocida: $1"
        ;;
      *)
        [[ -z "$source_file" ]] || fail "Argumento inesperado: $1"
        source_file="$1"
        shift
        ;;
    esac
  done
}

# Genera un CSV simple con el formato usuario,comentario a partir de passwd.
# Replica internamente este filtro:
#   awk -F: '$3 < 1000 {print $1","COM}' /etc/passwd
#
# Ademas incluye explicitamente a los usuarios root, nobody y nfsnobody
# aunque root use un shell interactivo o alguno de ellos tenga UID mayor.
# Tambien excluye cuentas cuyo shell sea /bin/sh o /bin/bash, salvo root.
# Los usuarios con UID >= 1000 quedan fuera de este flujo y conservan el
# comportamiento actual del resto del script.
# La salida se reutiliza tanto para aplicar como para validar el resultado.
generate_system_source() {
  local line user uid shell count=0 skipped_by_shell=0

  [[ -n "$system_comment" ]] || fail "apply-system requiere --comment o --system-comment"
  [[ -f "$passwd_file" ]] || fail "No existe archivo passwd: $passwd_file"

  : > "$generated_source_file" || fail "No se pudo crear $generated_source_file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(strip_cr "$line")"
    [[ -z "$line" ]] && continue

    IFS=':' read -r user _ uid _ _ _ shell <<< "$line"
    [[ -z "$user" ]] && continue

    if [[ "$user" == "root" ]]; then
      printf '%s,%s\n' "$user" "$system_comment" >> "$generated_source_file"
      ((count++))
      continue
    fi

    if shell_is_excluded_from_system_comment "$shell"; then
      ((skipped_by_shell++))
      continue
    fi

    if [[ "$user" == "nobody" || "$user" == "nfsnobody" ]]; then
      printf '%s,%s\n' "$user" "$system_comment" >> "$generated_source_file"
      ((count++))
    elif [[ "$uid" =~ ^[0-9]+$ ]] && (( uid < DEFAULT_SYSTEM_UID_LIMIT )); then
      printf '%s,%s\n' "$user" "$system_comment" >> "$generated_source_file"
      ((count++))
    fi
  done < "$passwd_file"

  info "Archivo generado: $generated_source_file"
  info "Usuarios incluidos (UID < $DEFAULT_SYSTEM_UID_LIMIT + root/nobody/nfsnobody, excluyendo /bin/sh y /bin/bash salvo root): $count"
  info "Usuarios excluidos por shell interactivo: $skipped_by_shell"

  source_file="$generated_source_file"
  format="csv"
}

# Valida que una etiqueta/comentario empiece con el prefijo corporativo
# esperado para comentarios estandar.
comment_has_default_prefix() {
  local comment="$1"
  [[ "$comment" == "${DEFAULT_COMMENT_PREFIX}"* ]]
}

# Excluye shells interactivos comunes del flujo apply-system para evitar
# sobrescribir comentarios de cuentas de acceso con shell real.
shell_is_excluded_from_system_comment() {
  local shell_path="$1"
  [[ "$shell_path" == "/bin/sh" || "$shell_path" == "/bin/bash" ]]
}

# Limpia estructuras cargadas desde passwd para recargar un estado actual.
reset_passwd_cache() {
  passwd_comments=()
  passwd_uids=()
}

# Estructuras en memoria con datos del archivo passwd:
# - passwd_comments[user] => comentario/GECOS
# - passwd_uids[user]     => UID
declare -A passwd_comments
declare -A passwd_uids

# Carga el archivo passwd en arreglos asociativos para poder consultar
# usuarios rapidamente durante los modos de validacion.
load_passwd() {
  local line user uid comment

  [[ -f "$passwd_file" ]] || fail "No existe archivo passwd: $passwd_file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(strip_cr "$line")"
    [[ -z "$line" ]] && continue

    IFS=':' read -r user _ uid _ comment _ <<< "$line"
    passwd_comments["$user"]="$comment"
    passwd_uids["$user"]="$uid"
  done < "$passwd_file"
}

# Indica si un usuario pasa el filtro de UID minimo.
uid_matches_filter() {
  local user="$1"
  local uid="${passwd_uids[$user]:-}"

  [[ -z "$min_uid" ]] && return 0
  [[ -n "$uid" ]] || return 1
  [[ "$uid" =~ ^[0-9]+$ ]] || return 1
  (( uid >= min_uid ))
}

# Construye el comentario esperado para lineas tipo roster.
# Ejemplo:
#   815/K/000794/Kyndryl/Jorge Luis Ferreyra Mucha
build_roster_comment() {
  local code="$1"
  local full_name="$2"
  printf '%s/%s/%s/%s' "$comment_prefix" "$code" "$company" "$full_name"
}

# Permite normalizar el nombre cuando la fuente viene en orden hispano
# (apellidos primero) y se quiere reordenar a "Nombre Apellido".
# Solo actua si se usa --swap-name-order.
normalize_roster_name() {
  local full_name="$1"
  local -a parts
  local given_names=""
  local surnames=""
  local i

  if [[ "$name_mode" != "swap_spanish" ]]; then
    printf '%s' "$full_name"
    return 0
  fi

  read -r -a parts <<< "$full_name"

  case "${#parts[@]}" in
    0|1)
      printf '%s' "$full_name"
      ;;
    2)
      printf '%s %s' "${parts[1]}" "${parts[0]}"
      ;;
    3)
      printf '%s' "$full_name"
      ;;
    *)
      surnames="${parts[0]} ${parts[1]}"
      for ((i = 2; i < ${#parts[@]}; i++)); do
        if [[ -n "$given_names" ]]; then
          given_names+=" "
        fi
        given_names+="${parts[i]}"
      done
      printf '%s %s' "$given_names" "$surnames"
      ;;
  esac
}

# Procesa el archivo fuente en modo apply o check-source.
# Flujo general:
# - detecta/parsa cada linea
# - construye el comentario esperado
# - aplica cambios o compara contra passwd
# - acumula estadisticas de resultado
process_source() {
  local action="$1"
  local line raw_user raw_comment raw_code raw_group raw_name
  local user expected current_comment
  local total=0 ok=0 missing=0 different=0 failed=0

  [[ -n "$source_file" ]] || fail "Debes indicar un archivo fuente"
  [[ -f "$source_file" ]] || fail "No existe archivo fuente: $source_file"

  if [[ "$format" == "auto" ]]; then
    format="$(detect_format "$source_file")"
    info "Formato detectado: $format"
  fi

  [[ "$format" == "csv" || "$format" == "roster" ]] || fail "Formato no soportado: $format"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(strip_cr "$line")"
    line="$(trim "$line")"
    [[ -z "$line" || "$line" == \#* ]] && continue

    case "$format" in
      csv)
        # Formato simple: usuario,comentario
        IFS=',' read -r raw_user raw_comment <<< "$line"
        user="$(trim "$raw_user")"
        expected="$(trim "$raw_comment")"
        [[ "${user,,}" == "usuario" ]] && continue
        ;;
      roster)
        # Formato roster: usuario_base,codigo,grupo,nombre
        # Se agrega el prefijo corporativo al usuario y se arma el comentario.
        IFS=',' read -r raw_user raw_code raw_group raw_name <<< "$line"
        user="$(trim "$raw_user")"
        raw_code="$(trim "$raw_code")"
        raw_name="$(normalize_roster_name "$(trim "$raw_name")")"
        [[ -z "$user" || -z "$raw_code" || -z "$raw_name" ]] && {
          warn "Linea invalida: $line"
          ((failed++))
          continue
        }
        user="${user_prefix}${user}"
        expected="$(build_roster_comment "$raw_code" "$raw_name")"
        ;;
    esac

    [[ -z "$user" ]] && continue
    ((total++))

    if [[ "$action" == "apply" ]]; then
      # Solo aplica comentario si el usuario existe localmente.
      if id "$user" >/dev/null 2>&1; then
        if usermod -c "$expected" "$user"; then
          echo "OK: $user -> $expected"
          ((ok++))
        else
          echo "ERROR: no se pudo actualizar $user"
          ((failed++))
        fi
      else
        echo "WARN: Usuario no existe: $user"
        ((missing++))
      fi
      continue
    fi

    # En modo check, compara lo esperado contra el comentario actual cargado
    # desde el archivo passwd.
    # `[[ -v assoc[key] ]]` falla en Bash antiguos usados en algunos Linux
    # corporativos. Esta forma es mas portable y segura con `set -u`.
    if [[ -n "${passwd_comments[$user]+_}" ]]; then
      current_comment="${passwd_comments[$user]}"
      if [[ -n "$current_comment" ]]; then
        if [[ "$current_comment" == "$expected" ]]; then
          echo "OK: $user tiene comentario esperado"
          ((ok++))
        else
          echo "DIFF: $user"
          echo "  actual   : $current_comment"
          echo "  esperado : $expected"
          ((different++))
        fi
      else
        echo "MISSING: $user no tiene comentario"
        ((missing++))
      fi
    else
      echo "WARN: $user no existe en $passwd_file"
      ((missing++))
    fi
  done < "$source_file"

  echo
  echo "Resumen:"
  echo "  procesados : $total"
  echo "  ok         : $ok"
  echo "  faltantes  : $missing"
  echo "  diferentes : $different"
  echo "  errores    : $failed"

  [[ $missing -eq 0 && $different -eq 0 && $failed -eq 0 ]]
}

# Recorre todo el passwd cargado y reporta usuarios sin comentario.
# Puede limitarse a UIDs mayores o iguales a un umbral.
check_passwd() {
  local user comment uid
  local total=0 ok=0 missing=0 invalid_prefix=0

  for user in "${!passwd_comments[@]}"; do
    uid="${passwd_uids[$user]:-}"
    uid_matches_filter "$user" || continue

    comment="${passwd_comments[$user]}"
    ((total++))

    if [[ -n "$comment" ]]; then
      if comment_has_default_prefix "$comment"; then
        ((ok++))
      else
        echo "INVALID_PREFIX: $user (comentario=${comment})"
        ((invalid_prefix++))
      fi
    else
      echo "MISSING: $user (uid=${uid:-desconocido})"
      ((missing++))
    fi
  done

  echo
  echo "Resumen:"
  echo "  usuarios revisados : $total"
  echo "  con prefijo valido : $ok"
  echo "  sin comentario     : $missing"
  echo "  prefijo invalido   : $invalid_prefix"

  [[ $missing -eq 0 && $invalid_prefix -eq 0 ]]
}

# Genera backup de /etc/passwd antes de aplicar cambios, salvo que:
# - se use --no-backup
# - el archivo indicado con --passwd no sea /etc/passwd
backup_passwd_if_needed() {
  if [[ $do_backup -eq 0 ]]; then
    info "Backup omitido por --no-backup"
    return 0
  fi

  [[ "$passwd_file" == "$DEFAULT_PASSWD_FILE" ]] || {
    info "No se genera backup porque --passwd apunta a un archivo distinto de $DEFAULT_PASSWD_FILE"
    return 0
  }

  cp -a "$DEFAULT_PASSWD_FILE" "${DEFAULT_PASSWD_FILE}.backup_$(date +%F_%H%M%S)" \
    || fail "No se pudo generar backup de $DEFAULT_PASSWD_FILE"
}

# Punto de entrada principal.
# Decide el modo de trabajo y ejecuta solo la ruta necesaria.
main() {
  parse_args "$@"
  ensure_mode

  case "$mode" in
    apply)
      [[ -n "$source_file" ]] || fail "apply requiere archivo fuente"
      backup_passwd_if_needed
      process_source "apply"
      ;;
    apply-system)
      backup_passwd_if_needed
      generate_system_source
      echo
      info "Aplicando comentario en usuarios del sistema"
      process_source "apply"
      echo
      info "Validando comentario en usuarios del sistema"
      reset_passwd_cache
      load_passwd
      process_source "check"
      ;;
    check-source)
      [[ -n "$source_file" ]] || fail "check-source requiere archivo fuente"
      load_passwd
      process_source "check"
      ;;
    check-passwd)
      [[ -z "$source_file" ]] || warn "Se ignora archivo fuente en modo check-passwd"
      load_passwd
      check_passwd
      ;;
  esac
}

main "$@"
