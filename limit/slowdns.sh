#!/usr/bin/env bash
# Simple SlowDNS installer with Readline & Backspace fix
set -euo pipefail

stty erase '^?' 2>/dev/null || stty erase '^H' 2>/dev/null || true

INSTALL_DIR=/etc/slowdns
SERVICE=slowdns.service
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail() {
  echo "Error: $*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || fail "Jalankan dengan sudo"
command -v systemctl >/dev/null || fail "systemd tidak ditemukan"
command -v install >/dev/null || fail "Command install tidak ditemukan"
command -v iptables >/dev/null || fail "iptables tidak ditemukan; install dahulu dengan: apt install -y iptables"

IPTABLES_BIN="$(command -v iptables)"

# Cari binary di folder yang sama dengan installer.
if [ -f "$SCRIPT_DIR/slowdns" ]; then
  SOURCE_BINARY="$SCRIPT_DIR/slowdns"
elif [ -f "/root/slowdns/slowdns" ]; then
  SOURCE_BINARY="/root/slowdns/slowdns"
else
  case "$(uname -m)" in
    x86_64) SOURCE_BINARY="$SCRIPT_DIR/slowdns-amd64" ;;
    aarch64|arm64) SOURCE_BINARY="$SCRIPT_DIR/slowdns-arm64" ;;
    armv7l) SOURCE_BINARY="$SCRIPT_DIR/slowdns-arm" ;;
    i?86) SOURCE_BINARY="$SCRIPT_DIR/slowdns-386" ;;
    *) fail "Arsitektur VPS tidak didukung: $(uname -m)" ;;
  esac
fi

[ -f "$SOURCE_BINARY" ] || fail "Binary SlowDNS tidak ditemukan di: $SOURCE_BINARY"

# Cek apakah multiplexer aktif di port 10053
DEFAULT_UPSTREAM="127.0.0.1:10053"
if ! systemctl is-active --quiet slowdns-mux.service 2>/dev/null && [ ! -f /etc/systemd/system/slowdns-mux.service ]; then
  DEFAULT_UPSTREAM="127.0.0.1:22"
fi

read -e -r -p "IP listener [auto]: " LISTENER_IP
read -e -r -p "Port UDP [53]: " UDP_PORT
read -e -r -p "Domain SlowDNS (contoh: dns.example.com): " DOMAIN
read -e -r -p "Upstream [$DEFAULT_UPSTREAM]: " UPSTREAM

LISTENER_IP="${LISTENER_IP:-auto}"
UDP_PORT="${UDP_PORT:-53}"
UPSTREAM="${UPSTREAM:-$DEFAULT_UPSTREAM}"

[[ "$UDP_PORT" =~ ^[0-9]{1,5}$ ]] && (( UDP_PORT >= 1 && UDP_PORT <= 65535 )) || fail "Port UDP tidak valid"
[[ "$DOMAIN" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$ ]] || fail "Domain tidak valid"
[[ "$UPSTREAM" =~ ^[A-Za-z0-9._:-]+:[0-9]{1,5}$ ]] || fail "Upstream harus format host:port"

# auto = SlowDNS listen IPv4/IPv6. IPv6 literal wajib memakai [alamat].
case "$LISTENER_IP" in
  auto) UDP_LISTEN=":$UDP_PORT" ;;
  *:*) UDP_LISTEN="[$LISTENER_IP]:$UDP_PORT" ;;
  *) UDP_LISTEN="$LISTENER_IP:$UDP_PORT" ;;
esac

install -d -m 700 "$INSTALL_DIR"
install -m 755 "$SOURCE_BINARY" "$INSTALL_DIR/slowdns"

if [ ! -f "$INSTALL_DIR/server.key" ]; then
  "$INSTALL_DIR/slowdns" -gen-key \
    -privkey-file "$INSTALL_DIR/server.key" \
    -pubkey-file "$INSTALL_DIR/server.pub"
  chmod 600 "$INSTALL_DIR/server.key"
  chmod 644 "$INSTALL_DIR/server.pub"
fi

cat > "$INSTALL_DIR/slowdns.env" <<EOF
SLOWDNS_UDP="$UDP_LISTEN"
SLOWDNS_DOMAIN="$DOMAIN"
SLOWDNS_UPSTREAM="$UPSTREAM"
SLOWDNS_KEY="$INSTALL_DIR/server.key"
EOF
chmod 600 "$INSTALL_DIR/slowdns.env"

# Symlink agar kompatibel dengan script yang membaca /root/slowdns
mkdir -p /root/slowdns
ln -sf "$INSTALL_DIR/server.key" /root/slowdns/server.key 2>/dev/null || true
ln -sf "$INSTALL_DIR/server.pub" /root/slowdns/server.pub 2>/dev/null || true
ln -sf "$INSTALL_DIR/slowdns.env" /root/slowdns/slowdns.env 2>/dev/null || true
echo "$DOMAIN" > /etc/xray/dns 2>/dev/null || true

cat > "/etc/systemd/system/$SERVICE" <<EOF
[Unit]
Description=SlowDNS Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/slowdns.env
ExecStartPre=/bin/bash -c '$IPTABLES_BIN -w -C INPUT -p udp --dport $UDP_PORT -j ACCEPT 2>/dev/null || $IPTABLES_BIN -w -I INPUT -p udp --dport $UDP_PORT -j ACCEPT'
ExecStart=$INSTALL_DIR/slowdns -udp \${SLOWDNS_UDP} -privkey-file \${SLOWDNS_KEY} \${SLOWDNS_DOMAIN} \${SLOWDNS_UPSTREAM}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$SERVICE"
systemctl is-active --quiet "$SERVICE" || {
  journalctl -u "$SERVICE" -n 30 --no-pager
  fail "Service gagal berjalan"
}

echo
echo "SlowDNS berhasil aktif"
echo "Listener  : $UDP_LISTEN"
echo "Domain    : $DOMAIN"
echo "Upstream  : $UPSTREAM"
echo "Public key: $INSTALL_DIR/server.pub"
echo
echo "Cek status: systemctl status $SERVICE"
echo "Lihat log : journalctl -u $SERVICE -f"
