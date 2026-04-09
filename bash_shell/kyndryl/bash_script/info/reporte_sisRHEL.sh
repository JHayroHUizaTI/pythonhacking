#!/bin/bash

set -u

OUTPUT="${1:-informe_sistema.txt}"

OS_FAMILY="DESCONOCIDO"
OS_ID="desconocido"
OS_VERSION="desconocida"
OS_PRETTY_NAME="Desconocido"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

write_line() {
    printf '%s\n' "$1" >> "$OUTPUT"
}

write_blank() {
    printf '\n' >> "$OUTPUT"
}

write_section() {
    write_line "=== $1 ==="
}

write_kv() {
    printf '%-24s: %s\n' "$1" "$2" >> "$OUTPUT"
}

sanitize_value() {
    if [ -n "${1:-}" ]; then
        printf '%s' "$1"
    else
        printf 'No disponible'
    fi
}

detect_os() {
    local id=""
    local version=""
    local pretty=""
    local release_line=""

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        id="${ID:-}"
        version="${VERSION_ID:-}"
        pretty="${PRETTY_NAME:-}"
    elif [ -r /etc/lsb-release ]; then
        # shellcheck disable=SC1091
        . /etc/lsb-release
        id="${DISTRIB_ID:-}"
        version="${DISTRIB_RELEASE:-}"
        pretty="${DISTRIB_DESCRIPTION:-}"
    elif [ -r /etc/redhat-release ]; then
        release_line="$(cat /etc/redhat-release 2>/dev/null)"
        id="$(printf '%s\n' "$release_line" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')"
        version="$(printf '%s\n' "$release_line" | grep -Eo '[0-9]+([.][0-9]+)?' | head -n 1)"
        pretty="$release_line"
    fi

    if [ -z "$id" ] && [ -r /etc/redhat-release ]; then
        release_line="$(cat /etc/redhat-release 2>/dev/null)"
        case "$release_line" in
            *Rocky*) id="rocky" ;;
            *AlmaLinux*) id="almalinux" ;;
            *CentOS*) id="centos" ;;
            *Red\ Hat*|*RedHat*) id="rhel" ;;
        esac
        [ -z "$version" ] && version="$(printf '%s\n' "$release_line" | grep -Eo '[0-9]+([.][0-9]+)?' | head -n 1)"
        [ -z "$pretty" ] && pretty="$release_line"
    fi

    OS_ID="$(printf '%s' "$id" | tr '[:upper:]' '[:lower:]')"
    [ -z "$OS_ID" ] && OS_ID="desconocido"
    OS_VERSION="$(sanitize_value "$version")"
    OS_PRETTY_NAME="$(sanitize_value "$pretty")"

    case "$OS_ID" in
        ubuntu)
            OS_FAMILY="UBUNTU"
            ;;
        rhel|redhat|centos|rocky|almalinux|ol|oracle)
            OS_FAMILY="RHEL_FAMILY"
            ;;
        *)
            OS_FAMILY="DESCONOCIDO"
            ;;
    esac
}

get_hostname_value() {
    if command_exists hostname; then
        hostname -f 2>/dev/null || hostname 2>/dev/null || true
    elif [ -r /etc/hostname ]; then
        head -n 1 /etc/hostname
    fi
}

get_kernel_value() {
    if command_exists uname; then
        uname -r 2>/dev/null
    fi
}

get_arch_value() {
    if command_exists uname; then
        uname -m 2>/dev/null
    fi
}

get_cpu_model() {
    if command_exists lscpu; then
        lscpu 2>/dev/null | awk -F: '/Model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}'
    elif [ -r /proc/cpuinfo ]; then
        awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo
    fi
}

get_cpu_count() {
    if command_exists lscpu; then
        lscpu 2>/dev/null | awk -F: '/^CPU\(s\)/ {gsub(/^[ \t]+/, "", $2); print $2; exit}'
    elif [ -r /proc/cpuinfo ]; then
        awk '/^processor/ {count++} END {if (count > 0) print count}' /proc/cpuinfo
    fi
}

write_memory_section() {
    local total=""
    local used=""
    local available=""

    write_section "MEMORIA"

    if command_exists free; then
        total="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')"
        used="$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')"
        available="$(free -h 2>/dev/null | awk '/^Mem:/ {print $7}')"

        write_kv "RAM total" "$(sanitize_value "$total")"
        write_kv "RAM usada" "$(sanitize_value "$used")"
        write_kv "RAM disponible" "$(sanitize_value "$available")"
    elif [ -r /proc/meminfo ]; then
        total="$(awk '/^MemTotal:/ {printf "%.2f GiB", $2 / 1024 / 1024}' /proc/meminfo)"
        write_kv "RAM total" "$(sanitize_value "$total")"
    else
        write_kv "RAM" "No se pudo obtener la informacion"
    fi

    write_blank
}

write_storage_section() {
    write_section "ALMACENAMIENTO"

    if command_exists lsblk; then
        write_line "Resumen de discos:"
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null >> "$OUTPUT"
    elif command_exists df; then
        write_line "Uso de sistemas de archivos:"
        df -hP 2>/dev/null >> "$OUTPUT"
    else
        write_line "No hay una herramienta disponible para obtener informacion de discos."
    fi

    write_blank
}

generate_report() {
    local hostname_value=""
    local kernel_value=""
    local arch_value=""
    local cpu_model=""
    local cpu_count=""

    detect_os

    : > "$OUTPUT"

    hostname_value="$(sanitize_value "$(get_hostname_value)")"
    kernel_value="$(sanitize_value "$(get_kernel_value)")"
    arch_value="$(sanitize_value "$(get_arch_value)")"
    cpu_model="$(sanitize_value "$(get_cpu_model)")"
    cpu_count="$(sanitize_value "$(get_cpu_count)")"

    write_line "===== INFORME DEL SISTEMA ====="
    write_kv "Fecha" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    write_blank

    write_section "SISTEMA OPERATIVO"
    write_kv "Nombre detectado" "$OS_PRETTY_NAME"
    write_kv "Familia" "$OS_FAMILY"
    write_kv "ID" "$OS_ID"
    write_kv "Version" "$OS_VERSION"
    write_blank

    write_section "RESUMEN DEL SISTEMA"
    write_kv "Hostname" "$hostname_value"
    write_kv "Kernel" "$kernel_value"
    write_kv "Arquitectura" "$arch_value"
    write_blank

    write_section "CPU"
    write_kv "Modelo" "$cpu_model"
    write_kv "CPU(s)" "$cpu_count"
    write_blank

    write_memory_section
    write_storage_section

    write_line "=== FIN DEL INFORME ==="
}

generate_report
printf 'Informe generado en: %s\n' "$OUTPUT"
