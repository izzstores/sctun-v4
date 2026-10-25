#!/usr/bin/env python3
"""
Universal Multi-Architecture WebSocket Proxy for SSH & OpenVPN Tunneling
Compatible with tun.conf (x86_64, aarch64, armhf, i386)
"""
import sys
import os
import socket
import select
import threading

def parse_config(cfg_path):
    listeners = []
    if not os.path.exists(cfg_path):
        return [
            {"listen_port": 10015, "target_host": "127.0.0.1", "target_port": 143},
            {"listen_port": 10012, "target_host": "127.0.0.1", "target_port": 1194}
        ]
    with open(cfg_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    cur = {}
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith('-'):
            if cur and "listen_port" in cur and "target_port" in cur:
                listeners.append(cur)
            cur = {"target_host": "127.0.0.1", "target_port": 0, "listen_port": 0}
            line = line.lstrip('-').strip()
            if not line:
                continue
        if ':' in line:
            k, v = line.split(':', 1)
            k = k.strip().lower()
            v = v.strip()
            if k == 'target_host':
                cur['target_host'] = v
            elif k == 'target_port':
                cur['target_port'] = int(v)
            elif k == 'listen_port':
                cur['listen_port'] = int(v)
    if cur and "listen_port" in cur and "target_port" in cur:
        listeners.append(cur)
    return listeners

def handle_client(client_sock, target_host, target_port):
    target_sock = None
    try:
        req = b""
        client_sock.settimeout(15.0)
        while b"\r\n\r\n" not in req:
            chunk = client_sock.recv(4096)
            if not chunk:
                client_sock.close()
                return
            req += chunk
            if len(req) > 65536:
                client_sock.close()
                return

        target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target_sock.settimeout(10.0)
        target_sock.connect((target_host, target_port))

        for s in (client_sock, target_sock):
            s.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
            s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            try:
                s.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPIDLE, 30)
                s.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPINTVL, 10)
                s.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPCNT, 5)
            except Exception:
                pass

        client_sock.sendall(b"HTTP/1.1 101 Switching Protocols\r\n\r\n")

        header_end = req.find(b"\r\n\r\n") + 4
        payload = req[header_end:]
        if payload:
            target_sock.sendall(payload)

        client_sock.setblocking(True)
        target_sock.setblocking(True)

        sockets = [client_sock, target_sock]
        while True:
            r, _, x = select.select(sockets, [], sockets, 300)
            if x:
                break
            if not r:
                continue
            for s in r:
                data = s.recv(16384)
                if not data:
                    return
                peer = target_sock if s is client_sock else client_sock
                peer.sendall(data)
    except Exception:
        pass
    finally:
        try: client_sock.close()
        except: pass
        if target_sock:
            try: target_sock.close()
            except: pass

def start_listener(listen_port, target_host, target_port):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(('0.0.0.0', listen_port))
        server.listen(1024)
        while True:
            client, _ = server.accept()
            t = threading.Thread(target=handle_client, args=(client, target_host, target_port), daemon=True)
            t.start()
    except Exception as e:
        print(f"[!] Error on port {listen_port}: {e}", file=sys.stderr)

def main():
    cfg_file = "/usr/bin/tun.conf"
    if "-f" in sys.argv:
        idx = sys.argv.index("-f")
        if idx + 1 < len(sys.argv):
            cfg_file = sys.argv[idx + 1]
    listeners = parse_config(cfg_file)
    if not listeners:
        sys.exit(1)
    threads = []
    for l in listeners:
        t = threading.Thread(target=start_listener, args=(l["listen_port"], l["target_host"], l["target_port"]), daemon=False)
        t.start()
        threads.append(t)
    for t in threads:
        t.join()

if __name__ == '__main__':
    main()
