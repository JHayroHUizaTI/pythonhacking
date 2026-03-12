#!/usr/bin/env python3
"""
number.py — Herramienta OSINT para números telefónicos peruanos.

Obtiene: operador, región/departamento, tipo de línea (fijo/móvil),
validación de formato, metadata vía phonenumbers, y búsqueda de
propietario vía Truecaller (requiere login previo con OTP).

Uso:
    python number.py                  # Modo interactivo
    python number.py 987654321        # Consulta directa
    python number.py +51987654321     # Con código de país
    python number.py --login          # Login de Truecaller (una sola vez)
"""

import sys
import re
import os
import json
import asyncio
from pathlib import Path

try:
    import phonenumbers
    from phonenumbers import (
        geocoder,
        carrier,
        timezone,
        number_type,
        PhoneNumberType,
    )
    HAS_PHONENUMBERS = True
except ImportError:
    HAS_PHONENUMBERS = False

try:
    from truecallerpy import login, verify_otp, search_phonenumber
    HAS_TRUECALLER = True
except ImportError:
    HAS_TRUECALLER = False

# Ruta donde se almacena el installationId de Truecaller
TRUECALLER_ID_FILE = Path.home() / ".truecaller_id"


# ═══════════════════════════════════════════════════════════════════════════════
#  DATOS DE NUMERACIÓN PERUANA (fuente: OSIPTEL / MTC)
# ═══════════════════════════════════════════════════════════════════════════════

# Prefijos de área para telefonía fija (sin el 0 de discado nacional)
AREA_CODES = {
    "1":  "Lima y Callao",
    "41": "Amazonas (Chachapoyas)",
    "43": "Áncash (Huaraz)",
    "44": "La Libertad (Trujillo)",
    "42": "San Martín (Moyobamba)",
    "51": "Puno (Juliaca)",
    "52": "Tacna",
    "53": "Moquegua",
    "54": "Arequipa",
    "56": "Ica",
    "61": "Ucayali (Pucallpa)",
    "62": "Huánuco",
    "63": "Junín (Huancayo)",
    "64": "Junín (Huancayo)",
    "65": "Loreto (Iquitos)",
    "66": "Ayacucho",
    "67": "Madre de Dios (Puerto Maldonado)",
    "72": "Apurímac (Abancay)",
    "73": "Piura",
    "74": "Lambayeque (Chiclayo)",
    "76": "Cajamarca",
    "82": "Cusco",
    "83": "Huancavelica",
    "84": "Cusco",
}

# Rangos de prefijos móviles por operador (primeros 3 dígitos del número de 9 cifras)
# Fuente: Plan Técnico Fundamental de Numeración – OSIPTEL
MOBILE_OPERATORS = {
    # Movistar (Telefónica del Perú)
    "movistar": [
        range(940, 950),   # 940-949
        range(950, 960),   # 950-959
        range(960, 970),   # 960-969
    ],
    # Claro (América Móvil)
    "claro": [
        range(970, 980),   # 970-979
        range(980, 990),   # 980-989
        range(990, 1000),  # 990-999
    ],
    # Entel Perú
    "entel": [
        range(900, 910),   # 900-909
        range(910, 920),   # 910-919
    ],
    # Bitel (Viettel Perú)
    "bitel": [
        range(920, 940),   # 920-939
    ],
}

# Nombres completos y colores para la presentación
OPERATOR_INFO = {
    "movistar":  {"nombre": "Movistar (Telefónica)",     "color": "\033[34m"},  # azul
    "claro":     {"nombre": "Claro (América Móvil)",      "color": "\033[31m"},  # rojo
    "entel":     {"nombre": "Entel Perú",                 "color": "\033[33m"},  # amarillo
    "bitel":     {"nombre": "Bitel (Viettel Perú)",       "color": "\033[32m"},  # verde
    "desconocido": {"nombre": "Operador desconocido",     "color": "\033[90m"},  # gris
}


# ═══════════════════════════════════════════════════════════════════════════════
#  FUNCIONES DE ANÁLISIS
# ═══════════════════════════════════════════════════════════════════════════════

class PhoneResult:
    """Almacena el resultado del análisis de un número telefónico."""

    def __init__(self):
        self.numero_original: str = ""
        self.numero_normalizado: str = ""
        self.es_valido: bool = False
        self.tipo_linea: str = ""          # "Móvil" | "Fijo" | "Desconocido"
        self.operador: str = ""
        self.region: str = ""
        self.formato_internacional: str = ""
        self.formato_nacional: str = ""
        self.zonas_horarias: list[str] = []
        self.errores: list[str] = []
        # Truecaller
        self.tc_nombre: str = ""
        self.tc_email: str = ""
        self.tc_direccion: str = ""
        self.tc_foto_url: str = ""
        self.tc_score: str = ""
        self.tc_tipo: str = ""             # "PERSONAL" | "BUSINESS" etc.
        self.tc_tags: list[str] = []


def normalizar_numero(raw: str) -> str:
    """
    Limpia y normaliza la entrada del usuario.
    Acepta formatos: 987654321, 01-4567890, +51987654321, 51987654321, etc.
    """
    limpio = re.sub(r"[\s\-\.\(\)]+", "", raw.strip())

    # Si empieza con +51 o 51 y tiene suficientes dígitos, lo dejamos
    if limpio.startswith("+51"):
        return limpio
    if limpio.startswith("51") and len(limpio) >= 11:
        return "+" + limpio

    # Si empieza con 0 (discado nacional fijo: 01-xxx, 044-xxx)
    if limpio.startswith("0"):
        return "+51" + limpio[1:]

    # Número local puro (9 dígitos móvil o 7-8 dígitos fijo de Lima)
    if limpio.isdigit():
        return "+51" + limpio

    return limpio  # fallback


def detectar_operador_movil(numero_9d: str) -> str:
    """
    Detecta el operador móvil a partir de los primeros 3 dígitos
    del número de 9 cifras (sin código de país).
    """
    if len(numero_9d) < 3 or not numero_9d[0] == "9":
        return "desconocido"

    prefijo = int(numero_9d[:3])
    for operador, rangos in MOBILE_OPERATORS.items():
        for rango in rangos:
            if prefijo in rango:
                return operador
    return "desconocido"


def detectar_region_fijo(numero_sin_pais: str) -> str:
    """
    Detecta la región/departamento de un número fijo peruano.
    El número debe llegar sin el +51 y sin el 0 de discado nacional.
    """
    # Lima: código de área "1" + 7 dígitos = 8 dígitos
    if numero_sin_pais.startswith("1") and len(numero_sin_pais) == 8:
        return AREA_CODES.get("1", "Desconocido")

    # Provincias: código de área 2 dígitos + 6 dígitos = 8 dígitos
    if len(numero_sin_pais) >= 8:
        cod2 = numero_sin_pais[:2]
        if cod2 in AREA_CODES:
            return AREA_CODES[cod2]

    return "Desconocido"


def analizar_numero(raw: str) -> PhoneResult:
    """Análisis completo de un número telefónico peruano."""
    resultado = PhoneResult()
    resultado.numero_original = raw

    normalizado = normalizar_numero(raw)
    resultado.numero_normalizado = normalizado

    # ── Análisis con phonenumbers (si está disponible) ──
    if HAS_PHONENUMBERS:
        try:
            parsed = phonenumbers.parse(normalizado, "PE")
            resultado.es_valido = phonenumbers.is_valid_number(parsed)

            # Formatos
            resultado.formato_internacional = phonenumbers.format_number(
                parsed, phonenumbers.PhoneNumberFormat.INTERNATIONAL
            )
            resultado.formato_nacional = phonenumbers.format_number(
                parsed, phonenumbers.PhoneNumberFormat.NATIONAL
            )

            # Región (geocoder)
            region_pn = geocoder.description_for_number(parsed, "es")
            if region_pn:
                resultado.region = region_pn

            # Operador (carrier)
            carrier_name = carrier.name_for_number(parsed, "es")
            if carrier_name:
                resultado.operador = carrier_name

            # Zonas horarias
            tz_list = timezone.time_zones_for_number(parsed)
            resultado.zonas_horarias = list(tz_list) if tz_list else []

            # Tipo de línea
            nt = number_type(parsed)
            tipo_map = {
                PhoneNumberType.MOBILE: "Móvil",
                PhoneNumberType.FIXED_LINE: "Fijo",
                PhoneNumberType.FIXED_LINE_OR_MOBILE: "Fijo o Móvil",
                PhoneNumberType.TOLL_FREE: "Línea gratuita",
                PhoneNumberType.PREMIUM_RATE: "Tarifa premium",
                PhoneNumberType.SHARED_COST: "Costo compartido",
                PhoneNumberType.VOIP: "VoIP",
                PhoneNumberType.PERSONAL_NUMBER: "Personal",
            }
            resultado.tipo_linea = tipo_map.get(nt, "Desconocido")

        except phonenumbers.NumberParseException as e:
            resultado.errores.append(f"Error de parseo: {e}")
            resultado.es_valido = False
    else:
        # ── Análisis offline sin phonenumbers ──
        solo_digitos = re.sub(r"\D", "", normalizado)

        # Remover código de país 51
        if solo_digitos.startswith("51"):
            solo_digitos = solo_digitos[2:]

        if len(solo_digitos) == 9 and solo_digitos.startswith("9"):
            resultado.es_valido = True
            resultado.tipo_linea = "Móvil"
            resultado.formato_internacional = f"+51 {solo_digitos[:3]} {solo_digitos[3:6]} {solo_digitos[6:]}"
            resultado.formato_nacional = f"{solo_digitos[:3]} {solo_digitos[3:6]} {solo_digitos[6:]}"
        elif 7 <= len(solo_digitos) <= 8:
            resultado.es_valido = True
            resultado.tipo_linea = "Fijo"
            resultado.formato_internacional = f"+51 {solo_digitos}"
            resultado.formato_nacional = f"(0{solo_digitos[:1]}) {solo_digitos[1:]}" if len(solo_digitos) == 8 else solo_digitos
        else:
            resultado.es_valido = False
            resultado.errores.append("Longitud de número no válida para Perú.")

    # ── Enriquecer con datos locales (OSIPTEL) ──
    solo_digitos = re.sub(r"\D", "", normalizado)
    if solo_digitos.startswith("51"):
        solo_digitos = solo_digitos[2:]

    if resultado.tipo_linea in ("Móvil", "Fijo o Móvil") and len(solo_digitos) == 9:
        op_local = detectar_operador_movil(solo_digitos)
        if op_local != "desconocido":
            resultado.operador = OPERATOR_INFO[op_local]["nombre"]
        elif not resultado.operador:
            resultado.operador = OPERATOR_INFO["desconocido"]["nombre"]

    if resultado.tipo_linea == "Fijo":
        region_local = detectar_region_fijo(solo_digitos)
        if region_local != "Desconocido":
            resultado.region = region_local
        elif not resultado.region:
            resultado.region = region_local

    return resultado


# ═══════════════════════════════════════════════════════════════════════════════
#  TRUECALLER — Login, credentials & búsqueda
# ═══════════════════════════════════════════════════════════════════════════════

def guardar_installation_id(installation_id: str) -> None:
    """Guarda el installationId en archivo local."""
    TRUECALLER_ID_FILE.write_text(json.dumps({"installationId": installation_id}))


def cargar_installation_id() -> str | None:
    """Carga el installationId guardado. Retorna None si no existe."""
    if TRUECALLER_ID_FILE.exists():
        try:
            data = json.loads(TRUECALLER_ID_FILE.read_text())
            return data.get("installationId")
        except (json.JSONDecodeError, KeyError):
            return None
    return None


def manual_set_installation_id() -> bool:
    """
    Permite al usuario ingresar manualmente un installationId.
    Útil si ya tiene uno desde la CLI de truecallerpy o la app.
    """
    print(f"\n  {CY}═══ Configurar installationId manualmente ═══{R}")
    print(f"  {GY}Si ya tienes tu installationId, pégalo aquí.{R}")
    print(f"  {GY}Puedes obtenerlo con: truecallerpy -i -r{R}\n")

    iid = input(f"  {CY}installationId: {R}").strip()
    if not iid:
        print(f"  {RD}✘ Vacío. Cancelado.{R}")
        return False

    guardar_installation_id(iid)
    print(f"  {GR}✔ installationId guardado en {TRUECALLER_ID_FILE}{R}")
    print(f"  {GY}Ya puedes buscar propietarios de números.{R}\n")
    return True


async def truecaller_login_flow() -> bool:
    """
    Flujo interactivo de login con Truecaller.
    1. Pide número de teléfono del usuario.
    2. Envía OTP.
    3. Verifica OTP y guarda installationId.
    Retorna True si fue exitoso.
    """
    print(f"\n  {CY}═══ Login de Truecaller ═══{R}")
    print(f"  {GY}Se enviará un OTP a tu número para autenticarte.{R}")
    print(f"  {GY}Este paso solo se realiza UNA VEZ.{R}")
    print(f"  {GY}REQUIERE: tener la app Truecaller instalada en tu celular.{R}\n")

    phone = input(f"  {CY}Tu número (formato intl, ej: +51987654321): {R}").strip()
    if not phone:
        print(f"  {RD}✘ Número vacío. Cancelado.{R}")
        return False

    print(f"  {GY}Enviando OTP a {phone}...{R}")
    try:
        login_response = await login(phone)
    except Exception as e:
        print(f"  {RD}✘ Error al enviar OTP: {e}{R}")
        return False

    # ── Debug: mostrar detalles de la respuesta ──
    status_code = login_response.get("status_code", 0)
    print(f"\n  {YW}── Debug: Respuesta de Truecaller ──{R}")
    print(f"  {GY}  Status code : {status_code}{R}")
    print(f"  {GY}  Status      : {login_response.get('status', 'N/A')}{R}")
    print(f"  {GY}  Mensaje     : {login_response.get('message', 'N/A')}{R}")
    print(f"  {GY}  Método OTP  : {login_response.get('method', 'N/A')}{R}")
    print(f"  {GY}  TTL (seg)   : {login_response.get('tokenTtl', 'N/A')}{R}")
    print(f"  {GY}  Dominio     : {login_response.get('domain', 'N/A')}{R}")
    print(f"  {GY}  Request ID  : {login_response.get('requestId', 'N/A')}{R}")
    print(f"  {GY}  País        : {login_response.get('parsedCountryCode', 'N/A')}{R}")
    print(f"  {GY}  Número      : {login_response.get('parsedPhoneNumber', 'N/A')}{R}")
    print(f"  {YW}──────────────────────────────────{R}\n")

    if status_code not in (200, 201):
        print(f"  {RD}✘ Truecaller respondió con error (status {status_code}).{R}")
        print(f"  {GY}  Intenta en unos minutos o usa: python number.py --set-id{R}")
        return False

    metodo = login_response.get("method", "sms").lower()
    if "call" in metodo or "flash" in metodo:
        print(f"  {YW}📞 El OTP se enviará por LLAMADA telefónica, no SMS.{R}")
    else:
        print(f"  {GR}📩 El OTP se envió por SMS.{R}")

    ttl = login_response.get("tokenTtl", 60)
    print(f"  {GY}Tienes {ttl} segundos para ingresar el código.{R}\n")

    otp = input(f"  {CY}Ingresa el OTP recibido (o 'c' para cancelar): {R}").strip()
    if not otp or otp.lower() == "c":
        print(f"  {RD}✘ Cancelado.{R}")
        print(f"  {GY}  Tip: si no llega el OTP, prueba con: python number.py --set-id{R}\n")
        return False

    print(f"  {GY}Verificando OTP...{R}")
    try:
        verify_response = await verify_otp(phone, login_response, otp)
    except Exception as e:
        print(f"  {RD}✘ Error en verificación: {e}{R}")
        return False

    # ── Debug: respuesta de verificación ──
    print(f"\n  {YW}── Debug: Respuesta de verificación ──{R}")
    for k, v in verify_response.items():
        if k != "phones":
            print(f"  {GY}  {k}: {v}{R}")
    print(f"  {YW}──────────────────────────────────────{R}\n")

    installation_id = verify_response.get("installationId")
    if not installation_id:
        print(f"  {RD}✘ No se obtuvo installationId.{R}")
        print(f"  {GY}  Prueba con: python number.py --set-id{R}")
        return False

    guardar_installation_id(installation_id)
    print(f"  {GR}✔ Login exitoso. installationId guardado en {TRUECALLER_ID_FILE}{R}")
    print(f"  {GY}Ya puedes buscar propietarios de números.{R}\n")
    return True


async def buscar_truecaller(numero_intl: str, installation_id: str) -> dict | None:
    """
    Busca información del propietario de un número vía Truecaller.
    Retorna el dict de respuesta o None en caso de error.
    """
    # Extraer solo dígitos, sin +
    limpio = re.sub(r"\D", "", numero_intl)
    try:
        response = await search_phonenumber(f"+{limpio}", "PE", installation_id)
        return response
    except Exception:
        return None


def enriquecer_con_truecaller(resultado: PhoneResult, tc_data: dict) -> None:
    """Extrae campos relevantes de la respuesta de Truecaller."""
    if not tc_data or "data" not in tc_data:
        return

    data = tc_data["data"]
    if isinstance(data, list) and len(data) > 0:
        entry = data[0]
    elif isinstance(data, dict):
        entry = data
    else:
        return

    # Nombre
    name_obj = entry.get("name", {})
    if isinstance(name_obj, dict):
        parts = [name_obj.get("first", ""), name_obj.get("last", "")]
        resultado.tc_nombre = " ".join(p for p in parts if p).strip()
    elif isinstance(name_obj, str):
        resultado.tc_nombre = name_obj

    # Email
    emails = entry.get("internetAddresses", [])
    if isinstance(emails, list) and emails:
        resultado.tc_email = emails[0].get("id", "")

    # Dirección
    addresses = entry.get("addresses", [])
    if isinstance(addresses, list) and addresses:
        addr = addresses[0]
        parts = [addr.get("city", ""), addr.get("countryCode", "")]
        resultado.tc_direccion = ", ".join(p for p in parts if p)

    # Foto
    resultado.tc_foto_url = entry.get("image", "")

    # Tipo y score
    resultado.tc_tipo = entry.get("type", "")
    score = entry.get("score", "")
    resultado.tc_score = str(score) if score else ""

    # Tags / badges
    badges = entry.get("badges", [])
    if isinstance(badges, list):
        resultado.tc_tags = [b if isinstance(b, str) else str(b) for b in badges]


# ═══════════════════════════════════════════════════════════════════════════════
#  PRESENTACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

# Colores ANSI
R  = "\033[0m"     # Reset
B  = "\033[1m"     # Bold
RD = "\033[31m"    # Red
GR = "\033[32m"    # Green
YW = "\033[33m"    # Yellow
BL = "\033[34m"    # Blue
CY = "\033[36m"    # Cyan
GY = "\033[90m"    # Gray

MG = "\033[35m"    # Magenta

BANNER = f"""
{CY}╔══════════════════════════════════════════════════════════════╗
║  {B}📞  OSINT — Consulta de Números Telefónicos Peruanos{R}{CY}       ║
║  {GY}Operador · Región · Propietario · Truecaller{R}{CY}              ║
╚══════════════════════════════════════════════════════════════╝{R}
"""


def color_operador(nombre: str) -> str:
    """Devuelve el nombre del operador con su color característico."""
    nombre_lower = nombre.lower()
    for key, info in OPERATOR_INFO.items():
        if key in nombre_lower:
            return f"{info['color']}{B}{nombre}{R}"
    return f"{GY}{nombre}{R}"


def mostrar_resultado(res: PhoneResult) -> None:
    """Imprime el resultado formateado en consola."""

    if res.errores:
        for err in res.errores:
            print(f"  {RD}✘ {err}{R}")
        return

    estado = f"{GR}✔ Válido{R}" if res.es_valido else f"{RD}✘ No válido{R}"

    # Bloque base
    lineas = f"""
{CY}┌──────────────────────────────────────────────────────────────┐{R}
{CY}│{R}  {B}Número original:{R}     {res.numero_original}
{CY}│{R}  {B}Estado:{R}              {estado}
{CY}│{R}  {B}Formato intl:{R}       {res.formato_internacional or GY + 'N/A' + R}
{CY}│{R}  {B}Formato nacional:{R}   {res.formato_nacional or GY + 'N/A' + R}
{CY}├──────────────────────────────────────────────────────────────┤{R}
{CY}│{R}  {B}Tipo de línea:{R}      {YW}{res.tipo_linea or 'Desconocido'}{R}
{CY}│{R}  {B}Operador:{R}           {color_operador(res.operador) if res.operador else GY + 'No identificado' + R}
{CY}│{R}  {B}Región:{R}             {BL}{res.region or 'No identificada'}{R}
{CY}│{R}  {B}Zona horaria:{R}       {GY}{', '.join(res.zonas_horarias) if res.zonas_horarias else 'America/Lima'}{R}"""

    # Bloque Truecaller (si hay datos)
    if res.tc_nombre:
        lineas += f"""
{CY}├──────────────────────────────────────────────────────────────┤{R}
{CY}│{R}  {MG}{B}🔍 Truecaller{R}
{CY}│{R}  {B}Propietario:{R}        {MG}{B}{res.tc_nombre}{R}"""
        if res.tc_email:
            lineas += f"\n{CY}│{R}  {B}Email:{R}              {res.tc_email}"
        if res.tc_direccion:
            lineas += f"\n{CY}│{R}  {B}Dirección:{R}          {res.tc_direccion}"
        if res.tc_tipo:
            lineas += f"\n{CY}│{R}  {B}Tipo cuenta:{R}        {res.tc_tipo}"
        if res.tc_score:
            lineas += f"\n{CY}│{R}  {B}Score:{R}              {res.tc_score}"
        if res.tc_foto_url:
            lineas += f"\n{CY}│{R}  {B}Foto:{R}               {GY}{res.tc_foto_url}{R}"
        if res.tc_tags:
            lineas += f"\n{CY}│{R}  {B}Tags:{R}               {', '.join(res.tc_tags)}"

    lineas += f"\n{CY}└──────────────────────────────────────────────────────────────┘{R}\n"
    print(lineas)


# ═══════════════════════════════════════════════════════════════════════════════
#  PUNTO DE ENTRADA
# ═══════════════════════════════════════════════════════════════════════════════

def consultar_con_truecaller(resultado: PhoneResult, installation_id: str) -> None:
    """Busca en Truecaller y enriquece el resultado."""
    numero = resultado.numero_normalizado or resultado.numero_original
    print(f"  {GY}🔍 Consultando Truecaller...{R}", end="", flush=True)
    tc_data = asyncio.run(buscar_truecaller(numero, installation_id))
    if tc_data:
        enriquecer_con_truecaller(resultado, tc_data)
        if resultado.tc_nombre:
            print(f"\r  {GR}✔ Truecaller: datos encontrados.       {R}")
        else:
            print(f"\r  {YW}⚠ Truecaller: número no registrado.    {R}")
    else:
        print(f"\r  {RD}✘ Truecaller: error en la consulta.     {R}")


def main():
    print(BANNER)

    # ── Estado de dependencias ──
    if not HAS_PHONENUMBERS:
        print(f"  {YW}⚠  Librería 'phonenumbers' no instalada.{R}")
        print(f"  {GY}   pip install phonenumbers{R}\n")

    if not HAS_TRUECALLER:
        print(f"  {YW}⚠  Librería 'truecallerpy' no instalada.{R}")
        print(f"  {GY}   pip install truecallerpy{R}")
        print(f"  {GY}   Sin ella no se podrá identificar al propietario.{R}\n")

    # ── Comando --login ──
    if "--login" in sys.argv:
        if not HAS_TRUECALLER:
            print(f"  {RD}✘ Instala truecallerpy primero: pip install truecallerpy{R}")
            return
        asyncio.run(truecaller_login_flow())
        return

    # ── Comando --set-id (manual) ──
    if "--set-id" in sys.argv:
        manual_set_installation_id()
        return

    # ── Cargar installationId de Truecaller ──
    tc_id = None
    if HAS_TRUECALLER:
        tc_id = cargar_installation_id()
        if tc_id:
            print(f"  {GR}✔ Truecaller activo{R} {GY}(propietario disponible){R}")
        else:
            print(f"  {YW}⚠ Truecaller no configurado.{R}")
            print(f"  {GY}   Ejecuta: python number.py --login{R}\n")

    # ── Consulta directa por argumento ──
    args_numeros = [a for a in sys.argv[1:] if not a.startswith("--")]
    if args_numeros:
        numero = " ".join(args_numeros)
        resultado = analizar_numero(numero)
        if tc_id and resultado.es_valido:
            consultar_con_truecaller(resultado, tc_id)
        mostrar_resultado(resultado)
        return

    # ── Modo interactivo ──
    print(f"\n  {GY}Escribe un número peruano para consultar.{R}")
    print(f"  {GY}Formatos válidos: 987654321, +51987654321, 01-4567890, 044-234567{R}")
    print(f"  {GY}Escribe 'salir' o 'q' para terminar.{R}\n")

    while True:
        try:
            entrada = input(f"  {CY}📞 Número → {R}").strip()
        except (KeyboardInterrupt, EOFError):
            print(f"\n  {GY}¡Hasta luego!{R}\n")
            break

        if not entrada:
            continue
        if entrada.lower() in ("salir", "exit", "q", "quit"):
            print(f"\n  {GY}¡Hasta luego!{R}\n")
            break

        resultado = analizar_numero(entrada)
        if tc_id and resultado.es_valido:
            consultar_con_truecaller(resultado, tc_id)
        mostrar_resultado(resultado)


if __name__ == "__main__":
    main()
