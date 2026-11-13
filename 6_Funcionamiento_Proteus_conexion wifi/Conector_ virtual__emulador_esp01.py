import socket
import serial

PUERTO_SERIAL = "COM11"
BAUDIOS = 115200
PUERTO_UDP = 4210

# OPCIONAL: Escribe aqui entre las comillas la IP Wi-Fi de tu celular
# (ej. "192.168.1.15") para envio directo si tu router bloquea Broadcast.
IP_DIRECTA_CELULAR = "172.20.10.5"


def obtener_ips_wifi():
  s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  try:
    s.connect(("8.8.8.8", 80))
    ip_pc = s.getsockname()[0]
    base = ".".join(ip_pc.split(".")[:3])
    return ip_pc, f"{base}.255", f"{base}.1"
  except Exception:
    return "0.0.0.0", "255.255.255.255", "192.168.1.1"
  finally:
    s.close()


ip_pc, ip_subred_broadcast, ip_gateway = obtener_ips_wifi()

ser = serial.Serial(PUERTO_SERIAL, BAUDIOS, timeout=0.1)
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

# Vincula obligatoriamente el socket a la tarjeta Wi-Fi de tu portatil
if ip_pc != "0.0.0.0":
  sock.bind((ip_pc, 0))

print("==========================================================")
print(f" EMULADOR ACTIVO EN {PUERTO_SERIAL}")
print(f" IP Wi-Fi de tu PC    : {ip_pc}")
print(f" Broadcast de tu Casa : {ip_subred_broadcast}:{PUERTO_UDP}")
if IP_DIRECTA_CELULAR:
  print(f" Envio directo a Cel  : {IP_DIRECTA_CELULAR}:{PUERTO_UDP}")
print("==========================================================")

while True:
  linea = ser.readline().decode("utf-8", errors="ignore").strip()
  if not linea:
    continue

  print(f"[PIC -> ESP]: {linea}")

  if linea.startswith("AT+CIPSEND"):
    ser.write(b"\r\n>\r\n")
  elif linea.startswith("AT"):
    ser.write(b"\r\nOK\r\n")
  elif linea.startswith("D:"):
    mensaje = (linea + "\n").encode("utf-8")

    # Envia al Broadcast de la red de tu casa y al global
    sock.sendto(mensaje, (ip_subred_broadcast, PUERTO_UDP))
    sock.sendto(mensaje, ("255.255.255.255", PUERTO_UDP))

    # Si pusiste la IP del celular arriba, le envia un paquete directo Unicast
    if IP_DIRECTA_CELULAR:
      sock.sendto(mensaje, (IP_DIRECTA_CELULAR, PUERTO_UDP))

    print(f"  -> UDP enviado por Wi-Fi ({ip_subred_broadcast}:{PUERTO_UDP})")