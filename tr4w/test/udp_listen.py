"""
udp_listen.py — Listen for TR4W UDP contact broadcasts and print them.

Default port: 12060 (UDP BROADCAST PORT CONTACT)
Default address: 0.0.0.0 (all interfaces, including 127.0.0.1)

Usage:
   python udp_listen.py [port]

Example:
   python udp_listen.py
   python udp_listen.py 12060
"""

import socket
import sys
from datetime import datetime

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 12060
BIND_ADDRESS = '0.0.0.0'   # listen on all interfaces including localhost

def main():
   sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
   sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
   sock.bind((BIND_ADDRESS, PORT))

   print(f'Listening for TR4W UDP contact broadcasts on {BIND_ADDRESS}:{PORT}')
   print('-' * 60)

   while True:
      data, addr = sock.recvfrom(65535)
      timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]
      print(f'[{timestamp}] from {addr[0]}:{addr[1]}')
      print(data.decode('utf-8', errors='replace'))
      print('-' * 60)

if __name__ == '__main__':
   main()
