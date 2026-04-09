#!/bin/bash
# =============================================================================
# Script       : crear_ipat.sh
# Descripcion  : Provisiona usuarios IPAT (Integrated Process Automation Tool)
#                en servidores Linux administrados por Kyndryl Peru.
#
#                IPAT es el usuario de servicio que utilizan las herramientas de
#                automatizacion (Dynamic Automation) para conectarse a los
#                servidores de cada cuenta/cliente. Cada cliente de Intercorp
#                tiene su propio usuario IPAT con un identificador unico
#                (ej. s2pipat1 -> Supermercados Peruanos).
#
# Alcance      : Servidores CentOS/RHEL 7+, Rocky/Alma 8+, Ubuntu 18+, Debian 10+
#                pertenecientes a la CU2 (Customer Unit 2) de Kyndryl Peru.
#
# Que hace     :
#   1. Verifica privilegios root y valida el usuario solicitado.
#   2. Detecta la familia de SO (RHEL-like o Debian-like).
#   3. Asegura la existencia del grupo de servicio "automata".
#   4. Crea o actualiza el usuario con shell, home y GECOS estandar.
#   5. Configura la contrasena inicial con el metodo apropiado al SO.
#   6. Aplica politica de no-expiracion para la contrasena.
#   7. Inyecta la clave publica SSH del Jump Host de automatizacion.
#
# Prerequisitos:
#   - Ejecutar como root (sudo su -).
#   - Acceso de red al servidor destino (SSH desde Jump Host).
#   - El servidor debe tener /etc/os-release o /etc/redhat-release.
#
# Uso          : ./crear_ipat.sh <usuario_ipat>
# Ejemplo      : ./crear_ipat.sh s2pipat1
#
# Autor        : Equipo SRE / Innovation - Kyndryl Peru (CU2)
# Mantenido por: Cloud Engineering & Automation Team
# Creado       : 2024
# Modificado   : 2026-04-08
#
# Notas de seguridad:
#   - DEFAULT_PASSWORD es la credencial inicial temporal. Debe rotarse via
#     el proceso corporativo de gestion de secretos tras el primer login.
#   - SSH_PUBLIC_KEY pertenece al Jump Host de Dynamic Automation (IBM LMJ).
#     Cualquier cambio en el par de claves del Jump Host requiere actualizar
#     esta variable.
# =============================================================================

set -euo pipefail
# -e : Aborta inmediatamente ante cualquier comando con exit code != 0.
# -u : Trata variables no definidas como error.
# -o pipefail : Propaga el primer error dentro de un pipeline.

# ---------------------------------------------------------------------------
# CONFIGURACION GLOBAL
# ---------------------------------------------------------------------------

# Grupo Unix primario al que pertenecen todos los usuarios IPAT.
# "automata" es el grupo estandar para cuentas de automatizacion en CU2.
GROUP_NAME="automata"

# Shell por defecto. bash es requerido por los scripts de Dynamic Automation.
DEFAULT_SHELL="/bin/bash"

# Contrasena inicial temporal asignada al usuario IPAT.
# IMPORTANTE: Este valor debe rotarse tras el primer despliegue.
DEFAULT_PASSWORD="CGAupc33"

# Campo GECOS (comentario) del usuario. Sigue el formato corporativo:
#   <CU_ID>/<Tipo>/<Cuenta>/<Empresa>/<Equipo>
# Permite identificar al usuario en auditorias y reportes de IAM.
BASE_GECOS="815/S/*PCU2IN/KYNDRYL/PE_CU2_INNOVATION"

# Clave publica RSA del Jump Host de automatizacion (IBM LMJ).
# Se inyecta en ~/.ssh/authorized_keys para permitir conexion SSH
# sin contrasena desde la plataforma de Dynamic Automation.
SSH_PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxIz4Um0wvTH5vdtH8qAkMaxkIRxnryvsbymgwa8wXrSmRj3cpsH0vyYxtZamQJSgrC2AqC8hKTrFstaG9j/cR9Mst7KPSUD1gkxK4vs0Vq4eQ2413UnJWt+QAL8Z8F0bYymkxUmyq4VlvJA7nePbO/yxpMkP2kwmhGU885uBuK4Mkz8sk4HIbspfB3njVnIj4DVE6fGpHMrGAXvcQd3dGWP85Y1g8vGykekBtOZ3maj9GZqQv4ZWU5IlCFZ72sHpV9yQ6H6mXH/B/sMEr/PgH1giDgjym+Noj8UtsRhXDpGSyMa1eqy53qWUSxs4bGobOTTvg7o8ZuYvwmp2jUGdXQ== !!631/S/*MADYAN/IBM/MANAGER_DYNAMIC_AUTOMATION!! Ibmlmjumphostspp'

# ---------------------------------------------------------------------------
# REGISTRO DE USUARIOS IPAT AUTORIZADOS
# ---------------------------------------------------------------------------
# Mapa asociativo [usuario_ipat] -> "Nombre del Cliente".
# Solo los usuarios definidos aqui pueden ser provisionados.
# El prefijo de 3 caracteres (ej. s2p, hc8) es el codigo de cuenta
# asignado por Kyndryl al cliente. "ipat1" indica el primer usuario
# de automatizacion de esa cuenta.
#
# Para agregar un nuevo cliente:
#   1. Obtener el codigo de cuenta del sistema IAM.
#   2. Agregar la entrada: [<codigo>ipat1]="Nombre del Cliente"
#   3. Actualizar la seccion usage() con la nueva entrada.
get_company_name() {
  local user_name="$1"

  case "${user_name}" in
    s2pipat1) echo "Supermercados Peruanos" ;;  # Retail - Supermercados
    hc8ipat1) echo "Homecenter Peruanos" ;;     # Retail - Mejoramiento del hogar
    tpeipat1) echo "Tiendas Peruanas" ;;        # Retail - Tiendas por departamento
    qusipat1) echo "Quimica Suiza" ;;           # Farmaceutica / Distribucion
    ekeipat1) echo "Farmacias Peruanas" ;;      # Retail - Farmacias (InkaFarma/MiFarma)
    irtipat1) echo "Intercorp Retail" ;;        # Holding - Retail corporativo
    n6ripat1) echo "NG restaurantes" ;;         # Alimentos - Restaurantes
    iotipat1) echo "intralot" ;;                # Tecnologia - Loterias/Apuestas
    it7ipat1) echo "interseguro" ;;             # Financiero - Seguros
    f1oipat1) echo "Financiera Oh" ;;           # Financiero - Creditos de consumo
    u7pipat1) echo "Universidad UTP" ;;         # Educacion - Universidad
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# FUNCIONES DE LOGGING
# ---------------------------------------------------------------------------
# Formato estandar: [NIVEL] mensaje
# INFO y OK van a stdout (flujo normal de ejecucion).
# WARN y ERROR van a stderr para facilitar redireccion y filtrado.
log_info()  { printf '[INFO]  %s\n' "$*"; }
log_ok()    { printf '[OK]    %s\n' "$*"; }
log_warn()  { printf '[WARN]  %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

# Muestra la ayuda del script: sintaxis, ejemplo y lista de usuarios validos.
usage() {
  cat <<EOF
Uso:
  $0 <usuario_ipat>

Ejemplo:
  $0 s2pipat1

Usuarios permitidos:
  s2pipat1  - Supermercados Peruanos
  hc8ipat1  - Homecenter Peruanos
  tpeipat1  - Tiendas Peruanas
  qusipat1  - Quimica Suiza
  ekeipat1  - Farmacias Peruanas
  irtipat1  - Intercorp Retail
  n6ripat1  - NG restaurantes
  iotipat1  - intralot
  it7ipat1  - interseguro
  f1oipat1  - Financiera Oh
  u7pipat1  - Universidad UTP
EOF
}

# Trap handler: captura cualquier error no controlado.
# Reporta la linea exacta y el codigo de salida para facilitar el debug.
cleanup_on_error() {
  local exit_code=$?
  log_error "Fallo la ejecucion en la linea ${BASH_LINENO[0]} con codigo ${exit_code}."
  exit "${exit_code}"
}

# Registra el handler para la senal ERR (cualquier comando que falle).
trap cleanup_on_error ERR

# ---------------------------------------------------------------------------
# VALIDACIONES PREVIAS (Pre-flight checks)
# ---------------------------------------------------------------------------

# Verifica que el script se ejecute con privilegios de superusuario.
# Operaciones como useradd, passwd, chown requieren root.
require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    log_error "Este script debe ejecutarse como root."
    exit 1
  fi
}

# Valida que se reciba exactamente un argumento y que el usuario
# solicitado exista en el registro de usuarios permitidos.
# Esto previene la creacion accidental de usuarios no autorizados.
validate_args() {
  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  local user_name="$1"
  if ! get_company_name "${user_name}" >/dev/null; then
    log_error "Usuario no permitido: ${user_name}"
    usage
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# DETECCION DEL SISTEMA OPERATIVO
# ---------------------------------------------------------------------------
# Determina la familia del SO para seleccionar el metodo correcto de
# configuracion de contrasena (passwd --stdin en RHEL vs chpasswd en Debian).
#
# Estrategia de deteccion (en orden de prioridad):
#   1. /etc/os-release -> campo ID (estandar systemd/freedesktop).
#   2. /etc/os-release -> campo ID_LIKE (derivados no directos).
#   3. /etc/redhat-release (fallback para RHEL 6 y derivados legacy).
detect_os_family() {
  # --- Intento 1: /etc/os-release (presente en la mayoria de distros modernas) ---
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release

    # Coincidencia directa por ID de la distribucion.
    case "${ID:-}" in
      rhel|centos|rocky|almalinux|ol)  # ol = Oracle Linux
        echo "rhel"
        return 0
        ;;
      ubuntu|debian)
        echo "debian"
        return 0
        ;;
      *)
        # Coincidencia por ID_LIKE para derivados (ej. Amazon Linux -> fedora).
        case "${ID_LIKE:-}" in
          *rhel*|*fedora*|*centos*)
            echo "rhel"
            return 0
            ;;
          *debian*|*ubuntu*)
            echo "debian"
            return 0
            ;;
        esac
        ;;
    esac
  fi

  # --- Intento 2: /etc/redhat-release (fallback para sistemas legacy/RHEL 6) ---
  if [[ -r /etc/redhat-release ]]; then
    local redhat_release
    redhat_release="$(tr '[:upper:]' '[:lower:]' < /etc/redhat-release)"

    case "${redhat_release}" in
      *red\ hat*|*centos*|*rocky*|*alma*|*oracle*linux*)
        echo "rhel"
        return 0
        ;;
    esac
  fi

  # Si ninguna fuente produce resultado, abortamos.
  log_error "No se pudo detectar una distribucion soportada. Se reviso /etc/os-release y /etc/redhat-release."
  exit 1
}

# ---------------------------------------------------------------------------
# PROVISIONAMIENTO: Grupo, Usuario, Contrasena, SSH
# ---------------------------------------------------------------------------

# Asegura que el grupo de servicio exista. Operacion idempotente:
# si el grupo ya existe, no hace nada; si no, lo crea.
ensure_group() {
  if getent group "${GROUP_NAME}" >/dev/null 2>&1; then
    log_ok "El grupo '${GROUP_NAME}' ya existe."
  else
    groupadd "${GROUP_NAME}"
    log_ok "Grupo '${GROUP_NAME}' creado."
  fi
}

# Crea el usuario o ajusta su configuracion si ya existe. Idempotente.
#   - Si el usuario NO existe: useradd con home, shell, grupo y GECOS.
#   - Si el usuario YA existe: usermod para normalizar su configuracion.
#   - Verifica que el home directory exista y tenga ownership correcto.
ensure_user() {
  local user_name="$1"
  local gecos="$2"
  local home_dir="/home/${user_name}"

  if id "${user_name}" >/dev/null 2>&1; then
    # Usuario existente: forzar grupo primario, shell, home y GECOS
    # al estandar. Corrige configuraciones previas incorrectas.
    log_info "El usuario '${user_name}' ya existe. Se ajustara su configuracion."
    usermod -g "${GROUP_NAME}" -s "${DEFAULT_SHELL}" -d "${home_dir}" -c "${gecos}" "${user_name}"
    log_ok "Usuario '${user_name}' actualizado."
  else
    # -m : Crea el directorio home automaticamente.
    # -g : Grupo primario = automata.
    useradd -m -d "${home_dir}" -s "${DEFAULT_SHELL}" -g "${GROUP_NAME}" -c "${gecos}" "${user_name}"
    log_ok "Usuario '${user_name}' creado."
  fi

  # Safeguard: en algunos sistemas el home no se crea con useradd -m
  # si el directorio base (/home) tiene permisos restrictivos.
  if [[ ! -d "${home_dir}" ]]; then
    mkdir -p "${home_dir}"
    log_warn "El home no existia y fue creado manualmente: ${home_dir}"
  fi

  # Asegura ownership correcto del home (usuario:grupo_automata).
  chown "${user_name}:${GROUP_NAME}" "${home_dir}"
}

# Configura la contrasena del usuario usando el metodo apropiado al SO.
#   - RHEL/CentOS: prefiere 'passwd --stdin' (mas eficiente).
#     Si no esta disponible (RHEL 9+), cae a 'chpasswd'.
#   - Debian/Ubuntu: usa 'chpasswd' directamente (no soporta --stdin).
set_password() {
  local os_family="$1"
  local user_name="$2"
  local password="$3"

  case "${os_family}" in
    rhel)
      # passwd --stdin es eficiente pero fue removido en algunas versiones.
      # Verificamos su disponibilidad antes de usarlo.
      if passwd --help 2>&1 | grep -q -- '--stdin'; then
        printf '%s\n' "${password}" | passwd --stdin "${user_name}" >/dev/null
        log_ok "Contrasena configurada con passwd --stdin para '${user_name}'."
      else
        # Fallback: chpasswd acepta formato 'user:password' via stdin.
        printf '%s:%s\n' "${user_name}" "${password}" | chpasswd
        log_warn "passwd --stdin no disponible. Se uso chpasswd para '${user_name}'."
      fi
      ;;
    debian)
      # Debian/Ubuntu siempre usa chpasswd (estandar POSIX-like).
      printf '%s:%s\n' "${user_name}" "${password}" | chpasswd
      log_ok "Contrasena configurada con chpasswd para '${user_name}'."
      ;;
    *)
      log_error "Familia de sistema operativo no soportada: ${os_family}"
      exit 1
      ;;
  esac
}

# Aplica politica de NO expiracion de contrasena.
# Los usuarios IPAT son cuentas de servicio que no deben expirar.
#   -m 0     : Dias minimos entre cambios de contrasena = 0 (sin restriccion).
#   -M 99999 : Dias maximos de validez = 99999 (~274 anos, efectivamente nunca).
#   -I -1    : Dias de inactividad antes de bloqueo = deshabilitado.
#   -E -1    : Fecha de expiracion de la cuenta = nunca.
set_password_policy() {
  local user_name="$1"
  chage -m 0 -M 99999 -I -1 -E -1 "${user_name}"
  log_ok "Politica de expiracion aplicada a '${user_name}'."
}

# Configura el directorio ~/.ssh y authorized_keys con la clave publica
# del Jump Host de automatizacion. Idempotente: no duplica la clave si
# ya esta presente.
#
# Permisos requeridos por OpenSSH:
#   ~/.ssh            -> 700 (rwx------)
#   authorized_keys   -> 600 (rw-------)
# Si estos permisos no son correctos, sshd rechazara la autenticacion.
ensure_ssh_files() {
  local user_name="$1"
  local home_dir="/home/${user_name}"
  local ssh_dir="${home_dir}/.ssh"
  local auth_keys="${ssh_dir}/authorized_keys"

  mkdir -p "${ssh_dir}"
  touch "${auth_keys}"

  # Ownership y permisos estrictos exigidos por OpenSSH.
  chown "${user_name}:${GROUP_NAME}" "${ssh_dir}" "${auth_keys}"
  chmod 700 "${ssh_dir}"
  chmod 600 "${auth_keys}"

  # grep -qxF: busqueda exacta (Fixed string, linea completa).
  # Evita inyeccion duplicada en ejecuciones repetidas.
  if grep -qxF "${SSH_PUBLIC_KEY}" "${auth_keys}"; then
    log_ok "La clave SSH ya existe en '${auth_keys}'."
  else
    printf '%s\n' "${SSH_PUBLIC_KEY}" >> "${auth_keys}"
    log_ok "Clave SSH agregada a '${auth_keys}'."
  fi
}

# ---------------------------------------------------------------------------
# PUNTO DE ENTRADA PRINCIPAL
# ---------------------------------------------------------------------------
# Orquesta todo el flujo de provisionamiento en orden secuencial.
# El flujo completo es:
#   pre-flight -> deteccion SO -> grupo -> usuario -> password -> politica -> SSH
main() {
  # --- Pre-flight checks ---
  require_root
  validate_args "$@"

  # --- Variables de contexto ---
  local user_name="$1"
  local company_name
  local gecos="${BASE_GECOS}"
  local os_family

  # --- Deteccion del SO ---
  company_name="$(get_company_name "${user_name}")"  # Solo informativo (logging).
  os_family="$(detect_os_family)"
  log_info "Sistema detectado: ${os_family}"
  log_info "Usuario solicitado: ${user_name}"
  log_info "Empresa asociada: ${company_name}"

  # --- Provisionamiento secuencial ---
  ensure_group                                               # 1. Grupo automata
  ensure_user "${user_name}" "${gecos}"                      # 2. Usuario + home
  set_password "${os_family}" "${user_name}" "${DEFAULT_PASSWORD}"  # 3. Contrasena
  set_password_policy "${user_name}"                         # 4. No-expiracion
  ensure_ssh_files "${user_name}"                            # 5. Clave SSH

  log_ok "Proceso finalizado correctamente para '${user_name}'."
}

# Invocacion del punto de entrada pasando todos los argumentos de CLI.
main "$@"
